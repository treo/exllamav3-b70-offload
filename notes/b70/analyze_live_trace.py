#!/usr/bin/env python3
"""Where does union(rows) come from? Decompose the planner's distinct-expert prediction against a live trace.

    python3 notes/b70/analyze_live_trace.py /tmp/trace.json [--planned 1,1.99,3.88,7.27,13.12,21.91]

notes/bench_live_trace.py produces a real per-token expert trace. The plan's `union(rows)` (multipliers
1 / 1.99 / 3.88 / 7.27 / 13.12 / 21.91 on topk, from out_parent_calib-era placement profiles plus an independence
approximation) drives every batch-scaling conclusion in the chapter: "distinct experts grow ~linearly with rows",
the b=8 binding boundary, and how much work the B70 and CPU homes get at batch. Architecture.md section 12 flags
those profile numbers as "upper bounds, not promises" and names E13/E14 (real trace, real co-occurrence) as the
way to close them.

A single measured union(b) would not settle it, because "b" means different things in the two places: the plan
means b CONCURRENT sequences, while a trace is one stream over time. So this computes the same statistic four
ways on one dataset and attributes the gap:

  consecutive   union over b ADJACENT tokens of the trace          - full temporal locality (what one stream does)
  random        union over b tokens sampled without replacement     - topic/session locality only
  indep(empirical) Monte Carlo: b synthetic tokens, each drawing topk DISTINCT experts from the trace's own
                per-layer frequency distribution                   - popularity only, no locality
  planner       topk x the plan's multiplier                       - popularity from the PROFILE, no locality

If consecutive << random ≈ indep, the shortfall is temporal locality (concurrent sequences would NOT inherit it).
If indep << planner, the profile's popularity distribution is flatter/sharper than reality. Both are reported
per layer and averaged, with the residency curve h(N) the placement decision actually consumes.
"""
import argparse
import json
import math
import random
import statistics

BS = (1, 2, 4, 8, 16, 32, 64)


def union_of(sets):
    u = set()
    for s in sets:
        u.update(s)
    return len(u)


def indep_union(picks_probs, topk, b, trials, rng):
    """b independent sequences, each drawing `topk` distinct experts from `picks_probs` (weighted sampling
    without replacement) - the plan's independence model, but fed the MEASURED distribution."""
    tot = 0
    for _ in range(trials):
        chosen = set()
        for _t in range(b):
            pool = list(range(len(picks_probs)))
            w = list(picks_probs)
            for _k in range(topk):
                if not pool:
                    break
                r = rng.random() * sum(w)
                acc, i = 0.0, 0
                for i, wi in enumerate(w):
                    acc += wi
                    if r <= acc:
                        break
                chosen.add(pool[i])
                pool.pop(i)
                w.pop(i)
        tot += len(chosen)
    return tot / trials


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("trace")
    ap.add_argument("--planned", default="1,1.99,3.88,7.27,13.12,21.91")
    ap.add_argument("--trials", type=int, default=200)
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--emit-profile", default=None,
                    help="write an expert_stats-format JSON built from THIS trace only (the engine's own profile "
                         "file accumulates across sessions, so pointing a planner at it would mix old history into "
                         "a 'live' comparison)")
    a = ap.parse_args()

    d = json.load(open(a.trace))
    trace, topk, E = d["trace"], d["topk"], d["E"]
    planned = [float(x) for x in a.planned.split(",")]
    rng = random.Random(a.seed)
    nl = len(trace)
    ntok = min(len(tl) for tl in trace)
    print(f"trace: {d['model'].split('/')[-1]}  {nl} layers x {ntok} tokens  topk {topk}  E {E}  "
          f"measured throughput {1e6/d['us_per_token_median']:.1f} tok/s incl. head/sampler")
    picks = sum(len(x) for tl in trace for x in tl[:ntok])
    print(f"  audit: {picks} picks recorded; expected ~{nl*ntok*topk} "
          f"({picks/(nl*ntok*topk):.3f} of it, so topk extraction is {'consistent' if 0.97 < picks/(nl*ntok*topk) < 1.03 else 'INCONSISTENT'})")

    # per-layer empirical frequency distribution from the trace
    freqs, conc = [], []
    for tl in trace:
        cnt = {}
        for row in tl[:ntok]:
            for e in row:
                cnt[e] = cnt.get(e, 0) + 1
        tot = sum(cnt.values()) or 1
        p = sorted((c / tot for c in cnt.values()), reverse=True)
        p += [0.0] * (E - len(p))
        freqs.append(p)
        cum, half = 0.0, E
        for i, pi in enumerate(p):
            cum += pi
            if cum >= 0.5:
                half = i + 1
                break
        ent = -sum(x * math.log(x) for x in p if x > 0)
        conc.append((half, math.exp(ent), sum(1 for x in p if x > 0)))
    print(f"  concentration: experts for half the picks {statistics.mean(c[0] for c in conc):.1f}; "
          f"effective support {statistics.mean(c[1] for c in conc):.1f}; "
          f"ever seen {statistics.mean(c[2] for c in conc):.1f} of {E}")

    print(f"\n  {'b':>4} {'consecutive':>12} {'random':>9} {'indep(empr)':>12} {'planner':>9} "
          f"{'cons/planner':>13} {'indep/planner':>14}")
    rows = []
    for bi, b in enumerate(BS):
        if b > ntok or bi >= len(planned):
            break
        cons = statistics.mean(union_of(tl[s:s + b]) for tl in trace
                               for s in range(0, ntok - b + 1, max(1, b // 4)))
        rnd = statistics.mean(union_of([tl[s] for s in rng.sample(range(ntok), b)]) for tl in trace
                              for _ in range(60))
        ind = statistics.mean(indep_union(freqs[L], topk, b, max(20, a.trials // (bi + 1)), rng)
                             for L in range(nl))
        pl = planned[bi] * topk
        rows.append((b, cons, rnd, ind, pl))
        print(f"  {b:4d} {cons:12.1f} {rnd:9.1f} {ind:12.1f} {pl:9.1f} {cons/pl:13.2f}x {ind/pl:14.2f}x")

    print("\n  residency curve h(N): share of picks covered by the N hottest experts (placement consumes this)")
    for frac in (0.25, 0.5, 0.75, 1.0):
        N = max(1, int(round(E * frac)))
        h = statistics.mean(sum(sorted(freqs[L], reverse=True)[:N]) for L in range(nl))
        print(f"    N = {N:4d} experts/layer ({frac*100:3.0f}% of {E}):  h_live = {h*100:6.2f}%")
    print("  Compare against the (res, h) pairs in notes/b70/out_placement.txt: if h_live at the planned |res| is "
          "below the planned h, the plan is optimistic about residence hit rate (E14's predicted direction).")

    # Sample-size honesty check. A union(b) measured on a SHORT session is not directly comparable to a profile
    # accumulated over a long one: rare experts only show up with exposure, so the long profile is flatter and its
    # union(b) larger by construction. Stratifying the same statistic along the session separates "the plan's
    # profile is flatter" from "my trace is too short" - if early and late windows agree, session length is not
    # what is driving the difference within this trace.
    bmax = [b for b, *_ in rows][-1]
    third = max(1, ntok // 3)
    seg = {}
    for name, lo, hi in (("first", 0, third), ("middle", third, 2 * third), ("last", 2 * third, ntok)):
        starts = list(range(lo, min(hi, ntok - bmax + 1)))
        if not starts:
            continue
        pick = starts[::max(1, len(starts) // 4)][:4]
        seg[name] = statistics.mean(union_of(tl[s:s + bmax]) for tl in trace for s in pick)
    print(f"\n  session-length check, union({bmax}) by position in the trace: " +
          ", ".join(f"{k} {v:.1f}" for k, v in seg.items()) +
          "  - flat means exposure, not position, drives the planner gap")
    print(f"  whole-session distinct experts per layer (mean): "
          f"{statistics.mean(len({e for row in tl for e in row}) for tl in trace):.1f} of {E}")

    if a.emit_profile:
        # Same schema the engine writes, so notes/b70/plan_parent_budget.py's counts_for() picks it up unchanged
        # when B70_PROFILE_DIR points here. Counts are raw picks from the trace, not decayed.
        layers = {}
        for L, tl in enumerate(trace):
            cnt = [0] * E
            for row in tl:
                for e in row:
                    cnt[e] += 1
            layers[f"model.language_model.layers.{L}.mlp"] = cnt
        json.dump({"model_dir": d["model"], "layers": layers}, open(a.emit_profile, "w"))
        print(f"\n  live-only profile (raw picks, {nl} layers x {E} experts) -> {a.emit_profile}")


if __name__ == "__main__":
    main()