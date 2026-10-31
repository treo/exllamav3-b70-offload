#!/usr/bin/env python3
"""Hot-set DWELL time from a raw per-token routing trace: does a static resident tier beat dynamic promotion?

Why this is the question worth answering (D16 in doc/port/b70-decisions.md). Two mechanisms compete for the same
term: `-mcpa` promotes hot experts CPU->GPU (measured +30/+50 % on Qwen prefill, but a FIXED ~8-experts-per-layer
window whose relief saturates - 390/383/384 promotions at every -mcs, i.e. capacity-bound), and the B70 could
hold a large STATIC tail instead (84 of 288 GLM experts per layer, or any Qwen model's half-mass tail for
1.4-5.3 GiB). Which one wins depends entirely on how fast the hot set CHANGES. If the top-K set has a half-life
of thousands of tokens, freeze it and never move anything; if it churns every few hundred, a static tier leaks
picks to the slowest home and promotion (or a card-side copy policy) is doing real work.

Nothing measured so far could answer it: profiles/live/*.json store per-expert TOTALS, and totals are invariant
under reordering in time. This script consumes the raw trace that bench_live_trace.py --dump-snaps now writes.

Metrics, all computed per MoE layer and then summarised:
  jaccard(i, i+1)     overlap of consecutive windows' top-K sets - the instantaneous churn rate.
  survival(t)         |topK(window 0) & topK(window t)| / K - the decay curve; its half-life is the dwell time.
  frozen_miss(t)      fraction of picks in window t served by an expert NOT in window 0's top-K. THIS is what a
                      static tier pays: those picks go to whatever home is left (CPU / 3090 / upload).
  refresh_miss(t)     the same fraction for a tier refreshed at window 0 only... i.e. evaluated at lag t, which
                      is the promotion loop's own reaction time. frozen_miss - refresh_miss is the value of
                      adapting at all, in picks per token.

K defaults to capacities the plan actually cares about, so the output is directly consumable: 84 = GLM experts
that fit one B70 layer's worth of VRAM headroom, 64/128 for Qwen, 8 = the measured -mcpa window.

Usage:
    python3 notes/b70/analyze_dwell.py notes/b70/profiles/live/dwell_205.json --k 8,64,84,128 --window 32
"""
from __future__ import annotations

import argparse
import collections
import json
import statistics


def topk_sets(windows, k):
    """top-K expert ids per window, ordered by count (ties broken by expert id so the set is deterministic)."""
    out = []
    for w in windows:
        out.append({e for e, _ in sorted(w.items(), key=lambda kv: (-kv[1], kv[0]))[:k]})
    return out


def bin_windows(steps, layer, window):
    """Sum this layer's per-token (expert -> picks) dicts into windows of `window` tokens."""
    out, cur, n = [], collections.Counter(), 0
    for step in steps:
        for e, v in step[layer]:
            cur[e] += v
        n += 1
        if n >= window:
            out.append(dict(cur))
            cur, n = collections.Counter(), 0
    if cur and out:                                        # keep the tail only if it is a full-ish window
        out.append(dict(cur))
    return out


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("trace")
    ap.add_argument("--k", default="8,64,84,128", help="comma list of resident-tier sizes to evaluate")
    ap.add_argument("--window", type=int, default=32, help="tokens per window (one adaptation interval)")
    ap.add_argument("--layers", type=int, default=8, help="analyse the first N MoE layers (0 = all)")
    ap.add_argument("--min-hits", type=int, default=1, help="ignore windows where a layer saw fewer picks than "
                    "this (a cold layer's top-K is noise and would inflate churn)")
    args = ap.parse_args()

    d = json.load(open(args.trace))
    steps, layers = d["steps"], d["layers"]
    sel = range(len(layers)) if args.layers == 0 else range(min(args.layers, len(layers)))
    ks = [int(x) for x in args.k.split(",")]
    print(f"dwell analysis: {d.get('model_dir', '?')}  {len(steps)} steps x {len(layers)} layers  "
          f"window {args.window} tokens  k={ks}  mcpa={d.get('mcpa')}")
    if len(steps) < 4 * args.window:
        print(f"  WARNING: only {len(steps)} traced steps - decay curves past lag {len(steps)//args.window} "
              f"windows do not exist. Raise --decode on the tracer before drawing conclusions from half-lives.")

    for k in ks:
        jac, half, froz_last, refl_last, usable = [], [], [], [], 0
        for L in sel:
            wins = bin_windows(steps, L, args.window)
            wins = [w for w in wins if sum(w.values()) >= args.min_hits * k]
            if len(wins) < 3:
                continue
            usable += 1
            ts = topk_sets(wins, k)
            jac.append(statistics.mean(len(a & b) / max(len(a | b), 1) for a, b in zip(ts, ts[1:])))
            base = ts[0]
            tot0 = sum(wins[0].values()) or 1
            # decay of the ORIGINAL set's membership, and the pick-weighted misses it causes
            surv = [len(base & t) / max(len(base), 1) for t in ts]
            below = [i for i, s in enumerate(surv) if s <= 0.5]
            half.append(below[0] * args.window if below else None)
            misses = [sum(v for e, v in w.items() if e not in base) / (sum(w.values()) or 1)
                      for w in wins[1:]]
            froz_last.append(misses[-1])
            # a tier allowed to refresh once, one full window before the evaluated one: the promotion loop's lag
            refl = []
            for i in range(2, len(ts)):
                b2 = ts[i - 1]
                refl.append(sum(v for e, v in wins[i].items() if e not in b2) / (sum(wins[i].values()) or 1))
            refl_last.append(refl[-1] if refl else None)
        if not jac:
            print(f"  k={k:>4}: no layer had >=3 usable windows at this granularity")
            continue
        hl = [h for h in half if h is not None]
        bound = (len(steps) // args.window) * args.window          # longest lag the trace can even show
        hws = (f">= {bound} tok ({len(hl)}/{len(half)} layers halved)" if len(hl) < len(half)
               else f"median {statistics.median(hl):.0f} tok (max {max(hl)})")
        print(f"  k={k:>4} ({usable} layers): jaccard(adj) {statistics.mean(jac):.3f}   "
              f"dwell half-life {hws}   "
              f"frozen-tier misses {100*statistics.mean(froz_last):.1f} % of picks   "
              + (f"lag-1-refresh misses {100*statistics.mean(refl_last):.1f} %  -> adapting is worth "
                 f"{100*(statistics.mean(froz_last)-statistics.mean(refl_last)):.1f} pts of picks"
                 if any(r is not None for r in refl_last) else ""))
        print(f"        reading: if 'adapting is worth' is small, freeze the tier (D16 holds); if it is tens of "
              f"percent, promotion earns its churn and the card should be a MOVING home, not a static tail.")


if __name__ == "__main__":
    main()