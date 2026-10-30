#!/usr/bin/env python3
"""
plan_decode_cost.py - the measured B70 decode cost model that replaces "bytes / GB-per-second".

Why this module exists. plan_operating_point.py and plan_concurrency.py computed B70 decode time as
`expert_bytes / rate(matched footprint)`, sampling a rate curve measured with memcpy-shaped launches. That
model was retired by measurement: the real GEMV was instruction-bound for every kernel up to rev H, and its
time is independent of the quantization recipe (Qwen3.8 across K=2..6: 73.6-74.8 us for identical weight
counts,
b70-kernels.md 2b/2c). Two kernel families now exist, both bit-exact against a Python reference:

  dp4a   probe_gemv.cpp rev C with -DGEMV_KCONST  (compile-time trellis K)
  dpas   probe_dpas4.cpp rev G with DPAS_X=1      (tokens on M, experts in the grid)

and the engine dispatches between them by row count, which is why the tables below are indexed by rows.

Every number is microseconds per (expert, projection) on Qwen3.8@2.68bpw, E=10, measured as the reported
projection time divided by E, warm (>=15 s sustained load) and interleaved min-of-N, best split-K per
configuration. Two windows were kept where they disagree, because they sometimes disagree by 20 %:
see `SPREAD`. Cost is per weight, not per byte: these are the same weights at any trellis K.

Provenance: notes/b70/out_gemv.txt (rev C / KCONST), notes/b70/out_dpas.txt (rev F, rev G, DPAS_X, rev H, and
rev I = probe_dpas6.cpp, the current fastest at every measured point). Dispatch is by recipe as well as rows:
the DPAS families require K <= 5, so denser recipes fall back to dp4a.
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
# Third family: rev H (probe_dpas5.cpp) + DPAS_X - ESIMD xmx::dpas fed straight from registers, no SLM, no
# barriers, no B operand loads. Best at ks2 everywhere once the expert grid was ported onto it. It is
# slightly behind rev G at rows 1-8 and clearly ahead at rows=16 (gate 44.2 vs 56.4 us, down 64.7 vs 92.7).
# Source: notes/b70/out_dpas.txt, "REV H + EXPERT GRID".
DPAS_REG = {
    1: 3.91,
    2: 3.91,      # interpolated between the measured rows=1 and rows=4 (within 1 % of both)
    4: 3.94,
    8: 4.11,
    16: 4.42,
}
DPAS_REG_DOWN_FACTOR = {1: 1.10, 2: 1.19, 4: 1.18, 8: 1.32, 16: 1.46}
MEASURED_ROWS_REG = (1, 4, 8, 16)   # rows=2 is interpolated, not measured

# Fourth family, and the one that wins everywhere it applies: rev I (probe_dpas6.cpp) - rev H's structure
# with the ring words pulled by esimd::gather (one LSC message per position, per lane) instead of
# t.iselect() on a block-loaded vector. Gen cannot index registers at run time, so those iselects were the
# dominant cost: doubling the extraction arithmetic cost +86 % on rev H and only +42 % here. ~2x faster than
# rev G and rev H at every measured (projection, rows) point, bit-exact for K = 2/3/5.
# Source: notes/b70/out_dpas.txt, "REV I".
DPAS_GATHER = {          # us per (expert, gate/up projection); rows=2 interpolated between 1 and 4
    1: 1.94,
    2: 1.99,
    4: 2.04,
    8: 2.17,
    16: 2.57,
}
DPAS_GATHER_DOWN_FACTOR = {1: 1.16, 2: 1.25, 4: 1.29, 8: 1.47, 16: 1.67}
MEASURED_ROWS_GATHER = (1, 4, 8, 16)
K_LIMIT_GATHER = 5       # rev G/H/I unpack needs K <= 5; the 6.05 bpw recipe has no DPAS path

# Fifth family, current best: rev J (probe_dpas7.cpp) - transposed tiles, so a column's ring words are plain
# register rows and the shift amounts are compile-time constants. No iselect (rev H), no gather (rev I).
# 1.27-1.46x over rev I at every point, bit-exact at rows 1/4/8/16 on both projections, and it runs at 437 GB/s
# effective against a 484 GB/s measured stream slope - i.e. at the memory wall. Requires the device copy of the
# weights to be intra-tile permuted (see b70-kernels.md 13v): same bytes, same DRAM traffic, same output bits,
# but the device tensor is no longer byte-identical to the checkpoint.
# Source: notes/b70/out_dpas.txt, "REV J".
DPAS_TRANSPOSED = {      # us per (expert, gate/up projection); rows=2 interpolated
    1: 1.40,
    2: 1.42,
    4: 1.45,
    8: 1.68,
    16: 2.02,
}
DPAS_TRANSPOSED_DOWN_FACTOR = {1: 1.11, 2: 1.20, 4: 1.29, 8: 1.38, 16: 1.51}
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


BUCKET_ROWS = 16       # rev J (and revs G/H/I) cover XROWS = 16 token rows per launch


def n_buckets(rows):
    """Buckets needed above BUCKET_ROWS, and the law that prices them. Measured (out_rows_gt16.txt):
    16-row buckets over the SAME experts are ADDITIVE to within 1-2 % - no L2 sharing between buckets, so
    each bucket re-pays the whole weight stream. DPAS families only; dp4a above 16 rows is unmeasured."""
    return -(-rows // BUCKET_ROWS)


def per_proj_us(rows, kernel, proj="gate_proj", K=3):
    """us per (expert, proj) at `rows`. Raises for rows outside the measured range.

    The DPAS families cannot serve K > K_LIMIT_GATHER (their unpack reads four windows from one 32-bit
    funnel-shifted word, which needs 3K + 16 <= 32), so for those recipes dispatch() falls back to dp4a
    rather than extrapolating.

    Above BUCKET_ROWS the cost follows the measured additive bucket law, not an extrapolation of the rows
    curve: the engine runs ceil(rows/16) launches over the same experts and each re-streams the weights.
    """
    if rows > BUCKET_ROWS:
        if kernel == "dp4a":
            raise ValueError(f"rows={rows} is above 16, where dp4a was never measured")
        return n_buckets(rows) * per_proj_us(BUCKET_ROWS, kernel, proj, K)
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
    if kernel == "dpas_reg":
        return DPAS_REG[rows] * (DPAS_REG_DOWN_FACTOR[rows] if proj == "down_proj" else 1.0)
    if kernel == "dpas_gather":
        if K > K_LIMIT_GATHER:
            raise ValueError(f"K={K} has no DPAS path (limit {K_LIMIT_GATHER}); use dp4a")
        return DPAS_GATHER[rows] * (DPAS_GATHER_DOWN_FACTOR[rows] if proj == "down_proj" else 1.0)
    if kernel == "dpas_transposed":
        # Rev J is compiled for K_MIN..K_MAX (2..16) and its unpack reads K dwords per column group, so unlike
        # revs G/H/I it serves the dense recipes too - but it needs the permuted device layout.
        return DPAS_TRANSPOSED[rows] * (DPAS_TRANSPOSED_DOWN_FACTOR[rows] if proj == "down_proj" else 1.0)
    raise KeyError(kernel)


def layer_us(picks, rows, scale=1.0, kernel=None):
    """Per MoE layer time on one B70 for `picks` = h * |union(rows)| owned experts.

    Each owned expert runs three projections (gate, up, down). `scale` converts the reference weight count
    to the model's: pass expert_weights / 1.6384e6, or expert_bytes*K/8/1.6384e6. kernel=None dispatches.
    """
def layer_us(picks, rows, scale=1.0, kernel=None, K=3):
    """Per MoE layer time on one B70 for `picks` = h * |union(rows)| owned experts.

    Each owned expert runs three projections (gate, up, down). `scale` converts the reference weight count
    to the model's: pass expert_weights / 1.6384e6, or expert_bytes*K/8/1.6384e6. kernel=None dispatches
    across every family that can serve the recipe.
    """
    fams = ["dp4a"] + (["dpas", "dpas_reg", "dpas_gather"] if K <= K_LIMIT_GATHER else [])
    fams.append("dpas_transposed")   # rev J: needs the permuted layout, serves every recipe
    ks = fams if kernel is None else (kernel,)
    best = None
    for k in ks:
        t = sum(per_proj_us(rows, k, p, K) for p in PROJS) * picks * scale
        if best is None or t < best[0]:
            best = (t, k)
    return best


def floor_us(picks, expert_bytes, scale=1.0):
    """DRAM floor for the same work, for sanity: bytes actually read at peak copy bandwidth."""
    return picks * expert_bytes * 1048576.0 / (PEAK_GBPS * 1000.0)


def main():
    print(__doc__.split("Usage:")[0].strip())
    print(f"\ncost spread note: {SPREAD}\n")
    print(f"{'rows':>5} {'dp4a':>9} {'rev G+X':>9} {'rev H+X':>9} {'rev I':>9} {'rev J':>9} {'dispatch':>13}")
    for r in MEASURED_ROWS:
        a = sum(per_proj_us(r, "dp4a", p) for p in PROJS)
        b = sum(per_proj_us(r, "dpas", p) for p in PROJS)
        h = sum(per_proj_us(r, "dpas_reg", p) for p in PROJS)
        i = sum(per_proj_us(r, "dpas_gather", p) for p in PROJS)
        j = sum(per_proj_us(r, "dpas_transposed", p) for p in PROJS)
        win = min((a, "dp4a"), (b, "rev G+X"), (h, "rev H+X"), (i, "rev I"), (j, "rev J"))
        print(f"{r:5d} {a:>9.2f} {b:>9.2f} {h:>9.2f} {i:>9.2f} {j:>9.2f} {win[1]:>13}")
    print("\nOne kernel wins at every measured batch now: rev J (transposed tiles) beats rev I by 1.27-1.46x and\n"
          "dp4a by ~8x at rows=16. Dispatch is a single family, with one caveat that is a design decision rather\n"
          "than a tuning knob: rev J needs the device copy of the weights intra-tile permuted (dword q*K+i ->\n"
          "i*8+q). Same bytes, same DRAM traffic, same output bits, ~1.5 ms one-time device permute for a 512 MB\n"
          "resident set - but the device tensor stops being byte-identical to the checkpoint, which is the\n"
          "property the 'native layout, no repack' constraint was protecting. If that constraint is kept\n"
          "literally the fallback is dpas_gather (rev I) at +27-46%, still one kernel; dp4a is the only option\n"
          "where no permutation is possible at all. Revs G/H carry no advantage now and remain for provenance.\n"
          "Rows=2 is interpolated; nothing here extrapolates past the measured set 1/2/4/8/16.")
    print("\nBinding constraint now: rev J runs the gate projection at 437 GB/s effective (5.86 MiB in 14.0 us)\n"
          "against measured ceilings of 484 GB/s (stream slope) and 674 GB/s (copy peak) - ~90% of the\n"
          "achievable streaming rate, so decode is bandwidth-bound in the sense the earliest design notes\n"
          "assumed, which no kernel in this line achieved until now. Its own diagnostics say balanced rather\n"
          "than dominated: NO_MAD (12.5) sits above both FETCH_ONLY (8.9) and ALU_ONLY (10.9), and the\n"
          "components sum to 21.3 against a full 14.0 (~35% overlap). The remaining levers are bytes and\n"
          "locality - placement, ordering, the 18.35 GiB threshold - not instructions.")
    print("\nrows > 16 - measured, not clamped (out_rows_gt16.txt). Above the kernel's 16-row coverage the")
    print("engine buckets, and bucketing is ADDITIVE: x2.00 / x2.98 / x3.96 at 32 / 48 / 64 rows, on both")
    print("projections - no L2 sharing between buckets of the same expert, so each re-pays the stream.")
    for r in (32, 64, 128, 256):
        j = sum(per_proj_us(r, "dpas_transposed", p) for p in PROJS)
        nb = n_buckets(r)
        ideal = sum(per_proj_us(1, "dpas_transposed", p)
                    + nb * (per_proj_us(16, "dpas_transposed", p) - per_proj_us(1, "dpas_transposed", p))
                    for p in PROJS)
        print(f"  rows={r:<4} ({nb:>2} buckets)  bucketed schedule {j:8.2f} us/expert-layer   "
              f"shared-stream kernel ~{ideal:7.2f} us   (worth x{j / ideal:.2f})")
    print("The bucketed column is what the engine does today. The shared-stream column was a PROJECTION that")
    print("E29 then BUILT AND TESTED, and it loses in every shape - gate rows=32: 41.5 us for two separate")
    print("16-row launches, 53.7 us sharing 2x16, 60.5 us sharing 4x8, and 64.8 us for a NATIVE single 32-row")
    print("launch (NF=4, also implemented and bit-exact). Reason: this kernel's 128-GRF budget holds exactly 16")
    print("rows spill-free, and every wider shape spills 1856-3584 B/thread to scratch, which costs more than")
    print("re-reading weights at the ~450 GB/s the kernel already achieves. So do NOT widen the row dimension;")
    print("fuse columns/projections instead (E25). And never pad a bucket: 24 rows as one padded NF=4 launch")
    print("costs 61.8 us, while 16+8 as two buckets costs ~38 us (b70-decode-closeout.md, E29 RESULT).")


if __name__ == "__main__":
    main()