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
        cells = step[layer]
        if cells is None:          # interval dropped by the tracer: the engine rotated _split_hist mid-step
            continue
        for e, v in cells:
            cur[e] += v
        n += 1
        if n >= window:
            out.append(dict(cur))
            cur, n = collections.Counter(), 0
    if cur and out:                                        # keep the tail only if it is a full-ish window
        out.append(dict(cur))
    return out


def wins_hint(steps, window_steps):
    """How many full windows the trace can show at this granularity (used only to label a lag)."""
    return max(1, len(steps) // max(1, int(window_steps)))


def validity_gate(steps, layers, batch, window_tokens, k=28):
    """Is the trace's index basis stable over its whole length? Returns (ok, overlap_early_late, expected_random).

    WHY THIS EXISTS. Two traces of the same model family, same tracer, same length produced band survivals of
    94 % and 8.6 % - and the distributions were statistically identical (top-28 share 0.115 vs 0.112). The second
    trace's early hot set overlapped its middle by 17/28 but its END by 1/28: the expert INDEX basis changed
    partway through (the engine rotates its own selection histogram; after one rotation the counts evidently came
    back in a different order). Temporal statistics on such a series measure the rotation, not the routing.
    This gate compares the top-k of the first window-sized block with the top-k of the last, against what two
    RANDOM k-subsets of E experts would share, and refuses to report dwell numbers when they are indistinguishable.
    """
    wsteps = max(1, round(window_tokens / batch))
    if len(steps) < 3 * wsteps:
        return True, None, None, k + 1               # nothing to compare; caller's window note already says so
    def topk(a, b):
        c = collections.Counter()
        for s in steps[a:b]:
            for cc in s:
                if cc:
                    for i, v in cc:
                        c[i] += v
        return set(i for i, _ in c.most_common(k)), c
    e1, _ = topk(0, wsteps)
    e2, _ = topk(len(steps) - wsteps, len(steps))
    E = 0                                            # expert count = largest index seen + 1
    for s in steps:
        for cc in s:
            if cc:
                for i, _ in cc:
                    E = max(E, i + 1)
    E = max(E, k + 1)
    expect = k * k / E                                # random overlap of two k-subsets of E
    ov = len(e1 & e2)
    return ov > 1.6 * expect, ov, expect, E


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("trace")
    ap.add_argument("--k", default="8,64,84,128", help="comma list of resident-tier sizes to evaluate")
    ap.add_argument("--window", type=int, default=32, help="tokens per window (one adaptation interval)")
    ap.add_argument("--layers", type=int, default=8, help="analyse the first N MoE layers (0 = all)")
    ap.add_argument("--sweep", default="",
                    help="comma list of window sizes; for each, print adjacency jaccard at the FIRST --k value. "
                         "This is the control that separates real hot-set churn from estimation noise: a 32-token "
                         "window sees ~320 picks spread over 512 experts, so the observed top-K is itself a noisy "
                         "estimate. If jaccard climbs with the window, much of the 'churn' is the estimator, not "
                         "the routing - and a tier refreshed every 32 tokens would be chasing noise.")
    ap.add_argument("--ignore-invalid", action="store_true", help="report dwell numbers even when the validity "
                    "gate says the trace's index basis changed mid-run (for diagnostics only; never for a "
                    "decision)")
    ap.add_argument("--bands", type=int, default=0,
                    help="split the fitted tier into this many rank bands and report each band's MEMBERSHIP "
                         "SURVIVAL at the longest lag the trace shows. Motivation: adjacency jaccard says ~half "
                         "the top-K rotates per interval, yet most layers' sets never halve against the fitted "
                         "baseline - both can be true if churn is concentrated at the tier's BOUNDARY while its "
                         "CORE persists. If so the policy is not 'static vs dynamic' (D16's framing) but "
                         "'freeze the core, let the boundary move', and the hysteresis threshold should be "
                         "rank-dependent.")
    ap.add_argument("--fit-windows", type=int, default=2, help="windows pooled to build the reference tier for "
                    "--bands (one window is a noisy tier and inflates every survival number)")
    ap.add_argument("--min-hits", type=int, default=1, help="ignore windows where a layer saw fewer picks than "
                    "this (a cold layer's top-K is noise and would inflate churn)")
    args = ap.parse_args()

    d = json.load(open(args.trace))
    steps, layers = d["steps"], d["layers"]
    # The trace has no uniform time axis unless you check it: a "step" that advanced a whole prompt (the session
    # prefill, e.g. 772 tokens x topk 10 = 7720 picks in one interval) sits in the same list as a one-token decode
    # step. Binning those together made the first dwell window 25x the others and destroyed every tier fitted
    # from it. Use the modal step size as the decode batch, drop the oversized intervals, and bin in TOKENS.
    toks = d.get("step_tokens")
    batch = 1
    if toks:
        batch = collections.Counter(toks).most_common(1)[0][0]
        keep = [i for i, t in enumerate(toks) if t <= batch]
        drop = len(toks) - len(keep)
        steps = [steps[i] for i in keep]
        print(f"  token axis: modal step = {batch} token(s); excluded {drop} prefill-contaminated intervals "
              f"(a window is {args.window} TOKENS = {max(1, round(args.window / batch))} steps)")
    wsteps = max(1, round(args.window / batch))
    ok, ov, exp_rand, _E = validity_gate(steps, layers, batch, args.window)
    if ov is not None:
        print(f"  validity gate: top-28 of the first {args.window} tok vs the last {args.window} tok share "
              f"{ov}/28 experts (two RANDOM 28-subsets of {_E} would share {exp_rand:.1f}) -> "
              + ("STABLE, temporal statistics usable" if ok else
                 "TRACE UNUSABLE: the index basis changed mid-trace, so half-life/survival here measure the "
                 "engine's histogram rotation, not routing. Re-trace shorter, or with the rotation source "
                 "disabled. Aggregates (totals per expert) remain valid."))
        if not ok and not args.ignore_invalid:
            return
    sel = range(len(layers)) if args.layers == 0 else range(min(args.layers, len(layers)))
    ks = [int(x) for x in args.k.split(",")]
    if args.bands >= 2:
        kk = ks[0]
        band = max(kk // args.bands, 1)
        print(f"  rank-band survival, tier of k={kk} fitted on the first {args.fit_windows} windows, "
              f"{args.bands} bands of ~{band} ranks, measured at the longest available lag")
        surv_last = [collections.defaultdict(list) for _ in range(args.bands)]
        miss_core = []
        for L in sel:
            wins = bin_windows(steps, L, wsteps)
            if len(wins) < args.fit_windows + 2:
                continue
            pooled = collections.Counter()
            for w in wins[:args.fit_windows]:
                pooled.update(w)
            ranked = [e for e, _ in sorted(pooled.items(), key=lambda kv: (-kv[1], kv[0]))][:kk]
            if len(ranked) < kk:
                continue
            last = topk_sets(wins[-1:], kk)[0]
            late = wins[args.fit_windows:]
            denom = sum(sum(w.values()) for w in late) or 1
            picks_out_core = sum(sum(v for e, v in w.items() if e not in set(ranked[:band])) for w in late)
            miss_core.append(picks_out_core / denom)
            for bi in range(args.bands):
                mem = set(ranked[bi * band:(bi + 1) * band])
                if mem:
                    surv_last[bi]["s"].append(len(mem & last) / len(mem))
        nw = wins_hint(steps, wsteps) - args.fit_windows
        for bi in range(args.bands):
            s = surv_last[bi].get("s", [])
            name = ("CORE" if bi == 0 else f"band {bi + 1}"
                    + (" (boundary)" if bi == args.bands - 1 else ""))
            print(f"    {name:<18} survival at lag {nw:>2} windows: "
                  + (f"{100 * statistics.mean(s):.1f} %" if s else "n/a"))
        if miss_core:
            print(f"    picks NOT served by the CORE band alone (k={band}): "
                  f"{100 * statistics.mean(miss_core):.1f} % - that is what freezing only the core would leak")
        return
    if args.sweep:
        kk = ks[0]
        print(f"  window sweep at k={kk} (jaccard of adjacent windows; rising = estimator noise, flat = real churn)")
        for wtxt in args.sweep.split(","):
            w = int(wtxt)
            js = []
            for L in sel:
                wins = [x for x in bin_windows(steps, L, max(1, round(int(wtxt) / batch)))
                        if sum(x.values()) >= args.min_hits * kk]
                if len(wins) < 3:
                    continue
                ts = topk_sets(wins, kk)
                js.append(statistics.mean(len(a & b) / max(len(a | b), 1) for a, b in zip(ts, ts[1:])))
            nw = len(steps) // max(1, round(w / batch))
            print(f"    window {w:>4} tok ({nw:>3} windows): jaccard "
                  + (f"{statistics.mean(js):.3f} over {len(js)} layers" if js else "n/a (too few windows)"))
        return
    print(f"dwell analysis: {d.get('model_dir', '?')}  {len(steps)} steps x {len(layers)} layers  "
          f"window {args.window} tokens  k={ks}  mcpa={d.get('mcpa')}")
    if d.get("hist_rotations_dropped"):
        print(f"  (tracer dropped {d['hist_rotations_dropped']} (layer,step) intervals where the engine rotated "
              f"its own histogram; those carry no picks rather than wrong ones)")
    if len(steps) < 4 * args.window:
        print(f"  WARNING: only {len(steps)} traced steps - decay curves past lag {len(steps)//args.window} "
              f"windows do not exist. Raise --decode on the tracer before drawing conclusions from half-lives.")

    for k in ks:
        jac, half, froz_last, refl_last, usable = [], [], [], [], 0
        for L in sel:
            wins = bin_windows(steps, L, wsteps)
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
        # Report what actually happened. The first version printed ">= bound" whenever ANY layer failed to halve,
        # which produced absurdities like ">= 256 tok (45/48 layers halved)" - the majority DID halve, and the
        # reader cannot tell churn from a censoring artefact.
        hws = (f"none of {len(half)} layers halved within {bound} tok" if not hl else
               f"median {statistics.median(hl):.0f} tok among {len(hl)}/{len(half)} layers that halved"
               + (f"; {len(half) - len(hl)} never did within {bound} tok" if len(hl) < len(half) else ""))
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