#!/usr/bin/env python3
"""
plan_operating_point.py - where decode actually sits in the measured rate-vs-footprint curve.

Why this exists. plan_placement.py answers capacity ("which experts live where"); probe_rates answers
rate ("what GB/s at what footprint"). Neither answers the question the design hinges on: per token only
topk of E experts fire, so a decode layer reads topk x expert_bytes and NOTHING ELSE - which is a
working set two orders of magnitude smaller than the sweeps the rate numbers were quoted from. The
measured rate is footprint-dependent (132-292 GB/s scattered across 64 MiB-2 GiB, out_rates_footprint.txt),
so applying a rate measured at one footprint to a computation that presents another is exactly the
error that this file removes.

Method:
  * distinct experts touched per layer at batch B: Monte-Carlo over the real per-layer selection
    counts (sample topk per row, union over rows). Independence across rows is the same approximation
    used for sigma in plan_placement.py; with peaked routing it is conservative (correlated picks
    would shrink the union, so the footprints below are upper bounds).
  * the DEVICE only owns a fraction h of the picks (three disjoint homes, no replication), so what one
    B70 reads per layer is h * |union| * expert_bytes. Sampling the rate curve at the all-picks
    footprint overstates the working set by 1/h and, because the curve is not flat, misstates the rate.
  * rate/footprint columns are LOCALITY DIAGNOSTICS only. The time column now comes from plan_decode_cost.py:
    measured us per (expert, projection) per row count, dispatching dp4a (rows=1) vs DPAS (rows>=2). The old
    `us/layer = footprint * 1048.576 / GB_per_s` model was retired by measurement - decode is instruction-bound
    and recipe-independent - and it was 2.4x OPTIMISTIC at b=1 (42-51 us/layer modelled vs 107 us measured).

Upper bound, not a prediction: probe_rates runs 10^3-10^5 items per launch, so it shows what the card
can do with the pipe full. A b=1 decode launch is far smaller; E4 measures the real thing.

Usage: python3 plan_operating_point.py            # both reference models
"""
import glob
import json
import os
import random

# out_rates_footprint.txt, measured: (footprint MiB, scattered GB/s, clustered GB/s)
BANDS = {
    "Qwen3.8@2.68": [(64, 291.8, 558.3), (128, 200.1, 278.4), (256, 229.8, 346.9),
                     (512, 248.6, 364.9), (1024, 274.0, 545.8), (2048, 257.0, 369.5)],
    "GLM@3.05":     [(64, 131.6, 215.6), (128, 208.0, 224.9), (256, 231.6, 293.1),
                     (512, 252.4, 300.0), (1024, 254.7, 321.3), (2048, 260.3, 321.9)],
}
MODELS = [("Qwen3.8@2.68", "2.68bpw", 512, 1.465, 48, 250.0, 0.976,
           "Qwen3.8-Flash-Next-exl3-2.68bpw_h6_ng8", None),   # tiles_n resolved from plan_decode_cost below
          ("GLM@3.05", "3.05bpw", 288, 9.000, 42, None, 0.708,
           "GLM-5.3-Flash-exl3@3.05bpw", None)]               # no measured gate geometry -> fusion not evaluated
ROOT = "/home/treo/projects/vendor/tabbyAPI/models"
L2_MIB = 18.0

import importlib.util as _ilu                      # measured decode cost model (see plan_decode_cost.py)
_spec = _ilu.spec_from_file_location("pdc", os.path.join(os.path.dirname(__file__), "plan_decode_cost.py"))
pdc = _ilu.module_from_spec(_spec)
_spec.loader.exec_module(pdc)


def config_for(dirname):
    """topk / layers / H straight from the checkpoint - never hardcoded (Qwen3.8 is topk 10, GLM 8)."""
    p = os.path.join(ROOT, dirname, "config.json")
    c = json.load(open(p))
    tc = c.get("text_config", c)
    topk = tc.get("num_experts_per_tok") or tc.get("topk")
    layers = tc.get("num_hidden_layers")
    return topk, layers, tc.get("hidden_size")


def counts_for(sub, E):
    for f in glob.glob(os.path.expanduser("~/.cache/exllamav3/expert_stats/*.json")):
        d = json.load(open(f))
        if sub in str(d.get("model_dir", "")) and isinstance(d.get("layers"), dict):
            L = d["layers"]
            if len(L[sorted(L)[0]]) == E:
                return [c for c in L[sorted(L)[0]]]
    raise SystemExit(f"no profile for {sub} with E={E}")


def distinct_experts(counts, topk, B, trials=3000, rng=random):
    """Mean number of distinct experts touched by B rows, each drawing topk without replacement."""
    tot = sum(counts) or 1.0
    p = [c / tot for c in counts]
    n = len(counts)
    out = 0
    for _ in range(trials):
        seen = [False] * n
        k = 0
        for _b in range(B):
            for _ in range(topk):
                r, acc, choice = rng.random(), 0.0, n - 1
                for i in range(n):
                    if seen[i]:
                        continue
                    acc += p[i]
                    if acc >= r:
                        choice = i
                        break
                if not seen[choice]:
                    seen[choice] = True
                    k += 1
        out += k
    return out / trials


def interp(band, mib, col):
    if mib <= band[0][0]:
        return band[0][col]
    if mib >= band[-1][0]:
        return band[-1][col]
    for (x0, s0, c0), (x1, s1, c1) in zip(band, band[1:]):
        if x0 <= mib <= x1:
            f = (mib - x0) / (x1 - x0)
            return (s0 + f * (s1 - s0)) if col == 1 else (c0 + f * (c1 - c0))
    return band[-1][col]


def main():
    rng = random.Random(11)
    print(__doc__.split("Usage:")[0].replace("plan_operating_point.py -", "plan_operating_point.py", 1).strip())
    print(f"\nL2 is {L2_MIB:.0f} MiB, so a per-layer footprint under that can be served with reuse across tokens;")
    print("above it every token starts cold. The two reference models fall on opposite sides.\n")
    for name, sub, E, eb, layers_hint, tlayer, h, dirname, tiles_n in MODELS:
        cnt = counts_for(sub, E)
        topk, cfg_layers, H = config_for(dirname)
        layers = layers_hint          # MoE layers, counted from the profile (GLM: 42 of 45 have experts)
        band = BANDS[name]
        tiles_n = tiles_n or pdc.GATE_TILES_N.get(name.split("@")[0])   # one shared source for gate geometry
        fused_any = False                          # did E25a pricing apply anywhere in this model's table?
        print(f"{name}:  topk={topk} (config.json), expert block {eb:.3f} MiB, {E} experts/layer, "
              f"{layers} MoE layers ({cfg_layers} total, H={H}), "
              f"all-experts set {E*eb/1024:.2f} GiB, h={h:.3f} [profile upper bound]")
        if tlayer:
            print(f"parent window per layer ~{tlayer:.0f} us at b=1 [M, doc/prep] (scales weakly with b until KV dominates)")
        print("  'device picks' = the fraction of the union this card owns, h*|union|; the footprint column")
        print("  is what IT actually reads per layer, which is the only footprint the rate curve should be")
        print("  sampled at. The all-picks row (h=1) is printed as the upper bound a 3090-sized S_g would see.")
        hdr = (f"{'rows':>5s} {'union':>7s} {'dev picks':>10s} {'footprint':>10s} {'in L2?':>7s} {'GB/s':>6s} "
               f"{'us/layer':>9s} {'x b=1':>6s} {'clust':>6s} {'ms/token':>9s} {'cards':>6s}")
        print(hdr)
        base = None
        bpw_note = float(sub.replace("bpw", ""))
        for B in (1, 2, 4, 8, 16):
            d = distinct_experts(cnt, topk, B, rng=rng)
            dev = d * h
            mib = dev * eb
            s = interp(band, mib, 1)
            c = interp(band, mib, 2)
            # Measured decode cost replaces bytes/rate. Priced PER EXPERT at the rows that expert actually
            # sees - B*topk/distinct(B) - not at the global batch: with topk=8 a b=8 step touches ~65 experts
            # and gives each of them ~1 row, so charging every one of them 8 (or 16) rows inflated the device
            # term. Above 16 rows per expert the cost buckets additively (out_rows_gt16.txt); the footprint
            # curve below is kept only as a locality diagnostic.
            rpe = B * topk / max(d, 1.0)
            rr = next((m for m in pdc.MEASURED_ROWS if m >= rpe), rpe)
            us_layer, kern = pdc.layer_us(dev, rr, pdc.scale_from_eb(eb, float(sub.replace("bpw", ""))))
            # E25a/E25b/D8: price the layer with the MEASURED joint choice (fusion AND split-K), instead of the
            # old "fuse at KS=1 if the grid is empty" test, which could not express e.g. fused+KS=4 at low E.
            # Needs a measured gate geometry (tiles_n) and rows inside the fused measurement set.
            if tiles_n and rr in (1, 2, 4, 8, 16):
                try:
                    j_us, j_shape, j_ks, j_note = pdc.layer_us_joint(
                        dev, rr, tiles_n, eb / 3.0, pdc.scale_from_eb(eb, float(sub.replace("bpw", ""))))
                except ValueError:
                    # The joint tables cover the cells that were measured (rows 1/8/16, E 2..96). Outside them we
                    # fall back to the older per-projection tables rather than borrowing a neighbouring row count
                    # or expert count - which is what out_fusion_penalty_k.txt showed is unsafe to guess about.
                    j_us = None
                if j_us is not None and j_us < us_layer:
                    us_layer, kern = j_us, f"joint-{j_shape}-KS{j_ks}"
                    fused_any = True
            usc = c            # clustered-rate column is now diagnostic only
            us = us_layer
            if B == 1:
                base = us
            cards = f"{us / tlayer:.1f}" if tlayer else "   ?"
            print(f"{B:5d} {d:7.1f} {dev:10.1f} {mib:9.1f}M {'yes' if mib < L2_MIB else 'no':>7s} {s:6.0f} "
                  f"{us:9.0f} {us/base:5.1f}x {usc:6.0f} {us*layers/1000:9.2f} {cards:>6s}")
        print(f"  fusion/split-K (D8 joint rule): " + (f"joint table consulted where a gate geometry is measured "
              f"(gate tiles_n={tiles_n}); the choice is (fused?, KS) together, not fuse-at-KS=1"
              if tiles_n else
              "not evaluated - no measured gate geometry for this model"))
        d1 = distinct_experts(cnt, topk, 1, rng=rng)
        mib1 = d1 * h * eb
        us1, kern1 = pdc.layer_us(d1 * h, 1, pdc.scale_from_eb(eb, bpw_note))
        if tiles_n:
            try:
                j1, sh1, ks1, _n1 = pdc.layer_us_joint(d1 * h, 1, tiles_n, eb / 3.0,
                                                       pdc.scale_from_eb(eb, bpw_note))
            except ValueError:
                j1 = None
            if j1 is not None and j1 < us1:
                us1, kern1 = j1, f"joint-{sh1}-KS{ks1}"
        print(f"  b=1: {layers} layers x {us1:.0f} us = {layers*us1/1000:.2f} ms/token of B70 time "
              f"({mib1:.1f} MiB/layer read while doing {d1*h:.1f} expert-projection-layers of work; "
              f"dispatch picks {kern1})")
        print(f"  upper bound if this card owned every pick: {d1*eb*1048.576/interp(band, d1*eb, 1):.0f} us/layer\n")
    print("""Reading it:
* A decode layer reads h*topk experts, not topk, and not the checkpoint. The footprint that the rate
  curve must be sampled at is therefore ~12 MiB (Qwen3.8 b=1) and ~51 MiB (GLM b=1) - one to two
  orders of magnitude below the 1-2 GiB sweeps the rate figures were first quoted from, which is the
  whole reason this file exists.
* Qwen3.8 decode lands on the good part of the curve and inside L2's reach at b=1; GLM lands on the
  worst measured point (132 GB/s at 64 MiB, its geometry has no locality to exploit) and its per-layer
  time is 10x Qwen's for 6x the bytes because the rate is half.
* BATCH IS THE REAL VARIABLE. Distinct experts per layer grow almost linearly with rows until routing's
  effective support saturates, so per-layer device time grows ~8x from b=1 to b=8 (Qwen3.8: 42 -> 355
  us) while the parent's per-layer window grows much more slowly (at b=1 it is bound by *weight* reads,
  which are batch-independent). Offload hiding is therefore a small-batch property. This is the
  quantitative version of why prefill, not decode, is where the XMX routes earn their keep.
* GLM needs more than one B70 for RATE, not only for hit rate - a conclusion the capacity-only view
  could not reach. At b=1 one card reads 50.9 MiB/layer and, at the 132 GB/s its geometry sustains at
  that footprint, that is 405 us/layer = 17.0 ms/token: an order of magnitude more than any plausible
  parent window. Expert bytes divide linearly across cards because each pick is computed in exactly one
  home, so 2 cards give ~202 us/layer and 3 give ~135 us - the first number at which GLM's offload could
  hide at all. The capacity sweep in the plan ("2 cards -> h = 89.7 %") was only ever about hit rate;
  the byte side demands cards on its own, and the two requirements happen to point the same way.
* WHAT THIS CANNOT SAY. The probe's grids are 10^3-10^5 items, where the card has every chance to fill
  the memory pipe; a b=1 decode launch is a few thousand items at most. The rates above are therefore
  UPPER BOUNDS for decode, and the small-footprint rows hint at exactly the risk (GLM's 132 GB/s at
  64 MiB). E4 on the real GEMV at real grids is the arbiter; if it comes in far below these numbers,
  the fix is job composition (batching several tokens' picks into one launch), not the layout.""")


if __name__ == "__main__":
    main()