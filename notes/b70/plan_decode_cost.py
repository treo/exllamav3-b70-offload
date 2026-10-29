#!/usr/bin/env python3
"""
plan_decode_cost.py - the measured B70 decode cost model that replaces "bytes / GB-per-second".

Why this module exists. plan_operating_point.py and plan_concurrency.py computed B70 decode time as
`expert_bytes / rate(matched footprint)`, sampling a rate curve measured with memcpy-shaped launches. That
model was retired by measurement: the real GEMV is instruction-bound, not bandwidth-bound, and its time is
independent of the quantization recipe (Qwen3.8 across K=2..6: 73.6-74.8 us for identical weight counts,
b70-kernels.md 2b/2c). Two kernel families now exist, both bit-exact against a Python reference:

  dp4a   probe_gemv.cpp rev C with -DGEMV_KCONST  (compile-time trellis K)
  dpas   probe_dpas4.cpp rev G with DPAS_X=1      (tokens on M, experts in the grid)

and the engine dispatches between them by row count, which is why the tables below are indexed by rows.

Every number is microseconds per (expert, projection) on Qwen3.8@2.68bpw, E=10, measured as the reported
projection time divided by E, warm (>=15 s sustained load) and interleaved min-of-N, best split-K per
configuration. Two windows were kept where they disagree, because they sometimes disagree by 20 %:
see `SPREAD`. Cost is per weight, not per byte: these are the same weights at any trellis K.

Provenance: notes/b70/out_gemv.txt (rev C / KCONST), notes/b70/out_dpas.txt (rev F, rev G, DPAS_X).
Usage: python3 plan_decode_cost.py           # prints the tables and the dispatch
"""

# rows -> us per (expert, projection). Reference geometry: k x n = 2560 x 640 = 1.6384 M weights,
# i.e. gate/up of Qwen3.8@2.68 (down_proj is the transposed 640 x 2560 and measures the same within noise).
DP4A = {          # probe_gemv rev C + GEMV_KCONST, best ks per rows
    1: 3.92,      # 39.2 us at E=10, ks=4
    2: 5.41,
    4: 10.33,
    8: 23.09,
    16: 44.99,
}
DPAS = {          # probe_dpas4 rev G + DPAS_X, ks=2 (gate) / ks=1 (down); window-to-window spread below
    1: (3.61, 4.37),
    2: (3.70, 3.70),
    4: (3.73, 3.73),
    8: (4.11, 4.11),
    16: (5.65, 5.65),
}
# down_proj measures a little dearer than gate/up at the same weight count (transposed geometry, tn=160):
DPAS_DOWN_FACTOR = {1: 1.15, 2: 1.16, 4: 1.14, 8: 1.26, 16: 1.28}
DP4A_DOWN_FACTOR = {r: 1.0 for r in DP4A}      # dp4a is within noise of gate at every rows measured

SPREAD = "two warm windows differ by up to ~20 % (rev G+X, down_proj, rows=1: 41.5 vs 50.9 us at E=10)"

PROJS = ("gate_proj", "up_proj", "down_proj")
MEASURED_ROWS = tuple(sorted(DP4A))             # do not extrapolate past this without a new measurement
PEAK_GBPS = 674.0                               # measured copy peak, for the DRAM floor check
REF_WEIGHTS_3PROJ = 3 * 2560 * 640              # 4,915,200 weights per expert-layer in the measured model


def scale_from_eb(eb_mib, bpw):
    """Weight-count ratio to the reference expert, from the planner's (expert MiB, bits-per-weight).

    Cost is per weight, not per byte - that is the central finding behind this module - so the conversion
    must divide bytes by bits/weight rather than comparing bytes across recipes. Qwen3.8@2.68 comes out at
    ~0.89 of the reference because the reference geometry assumed 3 bits/weight for the same tensors.
    """
    w = eb_mib * 1048576.0 * 8.0 / bpw
    return w / REF_WEIGHTS_3PROJ


def per_proj_us(rows, kernel, proj="gate_proj"):
    """us per (expert, proj) at `rows`. Raises for rows outside the measured range."""
    if rows not in MEASURED_ROWS:
        raise ValueError(f"rows={rows} is outside the measured set {MEASURED_ROWS}; "
                         "extrapolating across the M=8 fragment boundary or past 16 tokens is not "
                         "supported by any measurement here")
    f = DPAS_DOWN_FACTOR[rows] if proj == "down_proj" else 1.0
    if kernel == "dp4a":
        return DP4A[rows] * (DP4A_DOWN_FACTOR[rows] if proj == "down_proj" else 1.0)
    if kernel == "dpas":
        lo, hi = DPAS[rows]
        return ((lo + hi) / 2.0) * f
    raise KeyError(kernel)


def layer_us(picks, rows, scale=1.0, kernel=None):
    """Per MoE layer time on one B70 for `picks` = h * |union(rows)| owned experts.

    Each owned expert runs three projections (gate, up, down). `scale` converts the reference weight count
    to the model's: pass expert_weights / 1.6384e6, or expert_bytes*K/8/1.6384e6. kernel=None dispatches.
    """
    ks = ("dp4a", "dpas") if kernel is None else (kernel,)
    best = None
    for k in ks:
        t = sum(per_proj_us(rows, k, p) for p in PROJS) * picks * scale
        if best is None or t < best[0]:
            best = (t, k)
    return best


def floor_us(picks, expert_bytes, scale=1.0):
    """DRAM floor for the same work, for sanity: bytes actually read at peak copy bandwidth."""
    return picks * expert_bytes * 1048576.0 / (PEAK_GBPS * 1000.0)


def main():
    print(__doc__.split("Usage:")[0].strip())
    print(f"\ncost spread note: {SPREAD}\n")
    print(f"{'rows':>5} {'dp4a us/expert-layer':>21} {'dpas us/expert-layer':>21} {'dispatch':>10} "
          f"{'dpas/dp4a':>10}")
    for r in MEASURED_ROWS:
        a = sum(per_proj_us(r, "dp4a", p) for p in PROJS)
        b = sum(per_proj_us(r, "dpas", p) for p in PROJS)
        print(f"{r:5d} {a:21.2f} {b:21.2f} {'dp4a' if a < b else 'dpas':>10} {b / a:9.2f}x")
    print("\nCrossover: dp4a wins at rows=1 by ~5 %; the DPAS path wins from rows=2. Per-expert-layer cost is")
    print("flat in rows for the DPAS path (11.2 -> 17.8 us from 1 to 16 tokens) and grows ~11x for dp4a,")
    print("which is the whole reason the schedule exists.")
    print("\nrows > 16 is outside the measured set; the DPAS path uses two M=8 fragments above 8 rows and its")
    print("cost slope is still rising at 16, so quoting a 64- or 256-token decode number from this table")
    print("would be an extrapolation, not a measurement.")


if __name__ == "__main__":
    main()