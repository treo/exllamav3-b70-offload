#!/usr/bin/env python3
"""
plan_decode_cost.py - the measured B70 decode cost model that replaces "bytes / GB-per-second".

Why this module exists. plan_operating_point.py and plan_concurrency.py computed B70 decode time as
`expert_bytes / rate(matched footprint)`, sampling a rate curve measured with memcpy-shaped launches. That
model was retired by measurement: the real GEMV was instruction-bound for every kernel up to rev H, and its
time is independent of the quantization recipe (Qwen3.8 across K=2..6: 73.6-74.8 us for identical weight
counts,
b70-kernels.md 2b/2c). Families, all bit-exact against a Python reference:

  dp4a             probe_gemv.cpp rev C with -DGEMV_KCONST  (compile-time trellis K; niche: unpermutable AND K>5)
  dpas (rev G)     probe_dpas4.cpp with DPAS_X=1  (tokens on M, experts in the grid) - superseded
  dpas_reg / _gather (revs H, I)                 register and gather operand routing - superseded
  dpas_transposed  rev J (probe_dpas7.cpp) / rev L (probe_dpas9.cpp): transposed tiles, the current kernel and
                   the one the close-out recommends the engine implement; needs the permuted device layout (D3)
  fused (E25a/b)   gate+up in ONE gemm launch at the KS that fills the grid, plus ONE combine_both launch

The engine dispatches by row count AND by grid occupancy, which is why the tables are indexed by rows and by E.

and the engine dispatches between them by row count, which is why the tables below are indexed by rows.

Every number is microseconds per (expert, projection) on Qwen3.8@2.68bpw, E=10, measured as the reported
projection time divided by E, with >= 1 s of CONTINUOUS executed work in the timing process (WARM_S; LESSONS 53)
and min-of-N interleaved with an anchor that warms itself (LESSONS 54 - >= 2000 reps, or the device is still at
its 1200 MHz idle clock and every number is ~2.2x off). Two windows were kept where they disagree, because they
sometimes disagree by 20 %. Cost is per weight, not per byte: these are the same weights at any trellis K, and
the quantization ladder measured that directly (3x bytes for +3% time at a small resident set,
out_quant_ladder.txt).

Provenance: notes/b70/out_gemv.txt (rev C / KCONST), notes/b70/out_dpas.txt (revs F/G/H and rev I =
probe_dpas6.cpp), out_revl.txt + out_dpas.txt (rev J = probe_dpas7.cpp and rev L = probe_dpas9.cpp, the current
fastest and the kernel the close-out recommends the engine implement), out_e25_fuse.txt (E25a gate+up fusion),
out_e25b_combine.txt (the single combine_both launch it enabled), out_ks_grid.txt (the per-KS joint choice), and
out_egrid.txt / out_low_e_grid.txt (E = 2..96). Dispatch is by recipe as well as rows:
the GATHER-family DPAS revisions (G/H/I) require K <= 5, so for those denser recipes fall back to dp4a; the
transposed family (rev J/L) does not - it serves K = 2..6 verified, 2..16 compiled.
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
K_LIMIT_GATHER = 5       # rev G/H/I ONLY: their unpack reads 4 windows from one 32-bit word (3K+16<=32). Rev J/L
                         # reads K dwords per column group and serves the dense recipes - K=6 measured bit-exact
                         # on real data (out_quant_ladder.txt), so 6.05 bpw is NOT a dp4a-only recipe any more.

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

# WHAT THESE PER-EXPERT NUMBERS DO AND DO NOT ENCODE (both learned after the tables were written).
#  * Cost per WEIGHT, not per byte - and the quantization ladder confirms it: across K = 2..6 (0.39 -> 1.17
#    MiB/expert) rows=1 time moves 17.2 -> 17.7 us (+3%) at fixed weight count (out_quant_ladder.txt). So one
#    table serves every recipe, which is why the model never needed a K dimension.
#  * Derived at E=10, where a launch's fixed cost is spread over only 10 experts. Measured per-expert cost at
#    E=96 is 1.25 us (rows=1) and 1.86 us (rows=16) against these 1.40 / 2.02 (out_egrid.txt), so the table is
#    ~10-20% PESSIMISTIC for large resident sets and correct-to-conservative at small ones. Not adjusted: the
#    E=10 numbers come from certified windows, the E=96 ones from a window whose anchor read 23.8 us (unhealthy,
#    shared render node), so revising them now would trade a small conservatism for an uncontaminated error.
#  * The "437 GB/s ~ 90% of the memory wall" framing attached to rev J is partly L2 bandwidth: L2 is 24 MiB and
#    an E=10 set is 5.9 MiB, re-read every timed iteration. DRAM-regime rates are the large-E ones
#    (E=96: 492 GB/s at rows=1, 287-292 at rows=16).

# Sixth family, and the fastest at every row count: E25a - gate+up in ONE launch at KS=1, down separate at
# KS=1. Grid-level fusion costs no extra registers (a thread still serves one projection), so unlike E29's row
# bucketing it does not have to be paid for in prefetch depth. Measured per (expert, gate+up PAIR) and per
# (expert, down):
# Source: notes/b70/out_e25_fuse.txt (fused, ks1) and out_dpas.txt (down, ks1).
DPAS_FUSE_GU = {1: 2.080, 2: 2.263, 4: 2.447, 8: 2.630, 16: 3.370}
# ^ refreshed from out_ks_grid.txt (certified window, fused schedule WITH E25b's single combine_both). The values
#   this replaces (2.57 / 2.87 / 3.50 at rows 1/8/16) came from E25a, when the fused schedule still ran two
#   combine launches, so they overstated fused cost by up to 19%. rows=2 and rows=4 are log-linear interpolations
#   between the measured rows=1 and rows=8 points, not measurements.
DPAS_FUSE_DOWN = {1: 1.52, 2: 1.62, 4: 1.84, 8: 2.29, 16: 2.98}
HW_THREADS = 2048        # B70 slots reported by the probe banner (32 Xe cores x 8 vector engines x 8 threads)

# Gate/up column-tile count per model, needed by should_fuse(). DERIVED FROM DUMPED GEOMETRY, not assumed:
# Qwen3.8 gate/up is n=640 -> tiles_n = 640/16 = 40 (notes/b70/out_gemv.txt; /tmp/gemv_R64 meta tk=160 tn=40).
# Models are absent until their projection widths are actually read from a checkpoint dump - a missing entry
# means "fusion not evaluated", and planners must say so rather than guess.
GATE_TILES_N = {"Qwen3.8": 40}

# --- per-KS launch tables (out_ks_grid.txt; measured in a certified-healthy window, anchor 19.0-19.3 us on all
# 27 cells, every fused cell bit-exact for both projections at KS = 2/4/8) ------------------------------------
# us per (expert, SINGLE projection), and us per (expert, gate+up PAIR), keyed [E][rows][KS]. E is the number of
# experts in the launch grid - what the planners call `picks` when all owned experts run on this device.
KS_SEP = {
    2:  {1: {1: 8.225, 2: 4.975, 4: 3.525}, 8: {1: 8.975, 2: 5.675, 4: 4.200}, 16: {1: 9.575, 2: 5.875, 4: 4.450}},
    4:  {1: {1: 4.088, 2: 2.537, 4: 1.900}, 8: {1: 4.613, 2: 2.900, 4: 2.225}, 16: {1: 5.013, 2: 3.250, 4: 2.787}},
    10: {1: {1: 1.685, 2: 1.170, 4: 1.375}, 8: {1: 2.000, 2: 1.490, 4: 1.755}, 16: {1: 2.290, 2: 1.890, 4: 2.360}},
    # E=16..64 measured at rows=1 only, to locate the fusion penalty band (out_ks_grid.txt); asking them for
    # rows=8/16 raises rather than borrowing a neighbouring row count.
    16: {1: {1: 1.159, 2: 1.403}},
    20: {1: {1: 0.980, 2: 1.123}},
    24: {1: {1: 0.910, 2: 0.952}},
    32: {1: {1: 1.258, 2: 1.005}, 8: {1: 1.594, 2: 1.448}, 16: {1: 1.878, 2: 1.794}},
    64: {1: {1: 1.284, 2: 1.252}},
    96: {1: {1: 1.249, 2: 1.311}, 8: {1: 1.509, 2: 1.680}, 16: {1: 1.857, 2: 2.122}},
}
KS_FUSED = {
    2:  {1: {1: 8.800, 2: 5.850, 4: 4.750}, 8: {1: 9.800, 2: 6.650, 4: 5.350}, 16: {1: 10.500, 2: 6.900, 4: 5.700}},
    4:  {1: {1: 4.500, 2: 3.025, 4: 3.750}, 8: {1: 5.125, 2: 3.625, 4: 4.300}, 16: {1: 5.725, 2: 4.375, 4: 5.725}},
    10: {1: {1: 2.080, 2: 2.370, 4: 2.450}, 8: {1: 2.630, 2: 2.990, 4: 3.370}, 16: {1: 3.370, 2: 3.870, 4: 4.400}},
    16: {1: {1: 2.856, 2: 2.175}},
    20: {1: {1: 2.330, 2: 2.325}},
    24: {1: {1: 2.262, 2: 2.279}},
    32: {1: {1: 2.609, 2: 2.544}, 8: {1: 3.044, 2: 3.241}, 16: {1: 3.775, 2: 3.956}},
    64: {1: {1: 2.447, 2: 2.538}},
    96: {1: {1: 2.507, 2: 2.481}, 8: {1: 3.050, 2: 3.264}, 16: {1: 3.765, 2: 4.305}},
}
DEVICE_L2_MIB = 24.0      # `devinfo` -> global cache (L2): 24.0 MiB


def best_launch(E, rows, tn=40, hw_threads=HW_THREADS, bytes_per_expert=None, l2_mib=DEVICE_L2_MIB,
                enforce_cache_rule=False):
    """Joint (fusion, split-K) choice: the measured schedule that minimises us per (expert, gate+up pair).

    Two conditions, both measured (out_ks_grid.txt):
      (a) OCCUPANCY - fusion buys concurrency, so it wins big only while the separate launches leave slots empty;
      (b) CACHE  - a fused launch's weight footprint is the UNION of both projections' streams, so it loses its
          locality advantage once 2*E*bytes > L2 while a single stream E*bytes still fits (the penalty band, up
          to 1.27x the wrong way at E=32 here). Above the band for both shapes the levers wash.
    Pass bytes_per_expert (per single projection, MiB) to apply (b); without it the choice is table-only, which
    is correct at the measured E values and unguarded between them.

    Returns (us_per_pair, fused, KS, note). Refuses to invent: E uses the nearest measured point below and says
    so; rows must be a measured bucket for that E.
    """
    es = sorted(KS_SEP)
    e_used, note = E, ""
    if E not in KS_SEP:
        if E < es[0]:
            raise ValueError(f"E={E} is below the smallest measured expert count {es[0]}")
        e_used = max(e for e in es if e <= E)
        note = f"E={E} not measured; using nearest measured point below (E={e_used})"
    if rows not in KS_SEP[e_used]:
        raise ValueError(f"E={e_used} was measured at rows {sorted(KS_SEP[e_used])}, not rows={rows}; "
                         "do not borrow a neighbouring row count")
    cands = [(2.0 * v, KS, False) for KS, v in KS_SEP[e_used][rows].items()] \
        + [(v, KS, True) for KS, v in KS_FUSED[e_used][rows].items()]
    if bytes_per_expert:
        one, both = e_used * bytes_per_expert, 2.0 * e_used * bytes_per_expert
        if one <= l2_mib < both:
            # Warn, do not exclude. The band is real at K=3 (measured: fused up to 1.27x worse in it), and it
            # gets deeper as bits per weight grow (K=6: 1.6-1.9x, out_fusion_penalty_k.txt) - but it does NOT
            # predict the sign near the edges: K=2 at E=32 sits in the band by this arithmetic and fusion still
            # WON there by 1.32x. So the byte test is a flag for the caller, and only `enforce_cache_rule` (which
            # should be set only where a measurement backs it) drops fused candidates.
            note += (f"; cache warning: fused footprint {both:.1f} MiB exceeds L2 {l2_mib:.0f} while one stream "
                     f"({one:.1f} MiB) still fits - fusion is penalised in this band at K=3/K=6, but the sign "
                     f"near the edges is not predictable from bytes alone")
            if enforce_cache_rule:
                only = [c for c in cands if not c[2]]
                if only:
                    cands = only
                    note += "; EXCLUDED fused shapes (enforce_cache_rule=True)"
        elif both > l2_mib:
            note += f" both shapes exceed L2 ({both:.1f} MiB pair): levers within a few percent;"
    us, KS, fused = min(cands)
    grid = (2 * tn if fused else tn) * KS * 2 * e_used
    note += f" grid {grid} threads ({100.0 * grid / hw_threads:.0f}% of HW)"
    alt = sorted(c for c in cands if c[0] > us)
    if alt and (alt[0][0] - us) / us < 0.03:
        a = alt[0]
        note += (f"; INDIFFERENT - {'' if a[2] else 'sep '}KS={a[1]} "
                 f"{'fused ' if a[2] else ''}at {a[0]:.2f} is within 3% (measurement noise floor)")
    return us, fused, KS, note.strip()


def selftest_launch():
    """Assertions on the joint-chooser so a table edit cannot silently change a schedule decision."""
    assert abs(best_launch(10, 1)[0] - 2.080) < 1e-9, best_launch(10, 1)
    assert best_launch(2, 1)[1] and best_launch(2, 1)[2] == 4, best_launch(2, 1)      # fused, KS=4
    assert best_launch(4, 1)[1] and best_launch(4, 1)[2] == 2, best_launch(4, 1)      # fused, KS=2
    assert not best_launch(32, 1)[1] and best_launch(32, 1)[2] == 2, best_launch(32, 1)  # separate, KS=2
    assert best_launch(16, 1)[1], best_launch(16, 1)                                  # fused still wins at E=16
    assert not best_launch(24, 1)[1], best_launch(24, 1)                              # penalty band by E=24
    # The byte test must be INFORMATIONAL by default: passing bytes may add a note but must never change which
    # candidate wins (out_fusion_penalty_k.txt shows the sign near the band edges is not derivable from bytes).
    plain = best_launch(28, 1)[:3]
    withb = best_launch(28, 1, bytes_per_expert=0.585)[:3]
    assert plain == withb, (plain, withb)
    assert "cache warning" in best_launch(28, 1, bytes_per_expert=0.585)[3]
    # opting in does constrain the choice: a banded cell must come back non-fused
    assert not best_launch(28, 1, bytes_per_expert=0.585, enforce_cache_rule=True)[1]
    # ...and no false warning where both shapes are well past L2
    _, _, _, n_cold = best_launch(64, 1, bytes_per_expert=0.585)
    assert "cache warning" not in n_cold and "exceed L2" in n_cold, n_cold
    for bad in (0, 1):
        try:
            best_launch(bad, 1)
            raise AssertionError(f"E={bad} should be refused (below the measured range)")
        except ValueError:
            pass
    try:
        best_launch(64, 8)          # E=64 measured at rows=1 only
        raise AssertionError("E=64 rows=8 should be refused; it was never measured")
    except ValueError:
        pass
    us, fused, KS, note = best_launch(12, 8)      # unmeasured E -> nearest below, flagged
    assert fused and KS == 1 and "nearest measured point below" in note, (us, fused, KS, note)
    return True


def should_fuse(tn, KS, E, hw_threads=HW_THREADS):
    """E25/D8: fuse projections only when the separate launches under-fill the device.

    Fusion and split-K draw on the same resource (parallelism), so this predicate is a *fill* test, not a
    preference. Matched-KS measurements (out_ks_grid.txt) give the gain when the test passes: 1.62-1.87x at E=2
    and E=4 KS=1, against 0.96-1.12x once the separate launches already fill the machine - i.e. fusion buys
    concurrency and nothing else. Earlier wording here claimed "fusing at KS=1" was the rule; that was an
    artifact of an E=10-only sweep: at E=2/4 the best schedule is fused AND split-K (KS=4 / KS=2), because
    neither lever alone fills the device. Prefer best_launch() for a schedule choice; this remains for the
    narrow question 'does fusing at this KS fill anything?'.
    """
    return tn * KS * 2 * E < 0.6 * hw_threads


def layer_us_fused(picks, rows, scale=1.0):
    """Per MoE layer time with the E25a schedule: gate+up fused (KS=1) + down separate (KS=1)."""
    if rows not in DPAS_FUSE_GU:
        raise ValueError(f"rows={rows} outside the fused measurement set {sorted(DPAS_FUSE_GU)}")
    return (DPAS_FUSE_GU[rows] + DPAS_FUSE_DOWN[rows]) * picks * scale
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

    The GATHER-family revisions (G/H/I) cannot serve K > K_LIMIT_GATHER: their unpack reads four windows from one
    32-bit funnel-shifted word, which needs 3K + 16 <= 32, so for those recipes dispatch() falls back to dp4a
    rather than extrapolating. dpas_transposed (rev J/L) is not subject to that bound and is certified to K = 6.

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
            raise ValueError(f"K={K} has no GATHER-family path (limit {K_LIMIT_GATHER}); "
                             "use dpas_transposed (rev J/L, certified to K=6) or dp4a")
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
    assert selftest_launch(), "joint-launch chooser selftest failed"
    print("joint (fusion, split-K) choice - us per (expert, gate+up pair), from measured cells")
    print(f"{'E':>5} " + " ".join(f"{'rows=' + str(r):>20}" for r in (1, 8, 16)))
    for E in sorted(KS_SEP):
        cells = []
        for r in (1, 8, 16):
            if r not in KS_SEP[E]:
                cells.append("      not measured")
                continue
            us, fused, KS, n = best_launch(E, r)
            tag = "~tie" if "INDIFFERENT" in n else ""
            cells.append(f"{us:6.2f} {'fused' if fused else 'sep   '} KS={KS} {tag}")
        print(f"{E:5d} " + " ".join(f"{c:>26}" for c in cells))
    print("\nfamilies, per (expert, all three projections):")
    print(f"{'rows':>5} {'dp4a':>9} {'rev G+X':>9} {'rev H+X':>9} {'rev I':>9} {'rev J':>9} {'E25a':>9} {'dispatch':>13}")
    for r in MEASURED_ROWS:
        a = sum(per_proj_us(r, "dp4a", p) for p in PROJS)
        b = sum(per_proj_us(r, "dpas", p) for p in PROJS)
        h = sum(per_proj_us(r, "dpas_reg", p) for p in PROJS)
        i = sum(per_proj_us(r, "dpas_gather", p) for p in PROJS)
        j = sum(per_proj_us(r, "dpas_transposed", p) for p in PROJS)
        win = min((a, "dp4a"), (b, "rev G+X"), (h, "rev H+X"), (i, "rev I"), (j, "rev J"))
        fu = sum(per_proj_us(r, "dpas_transposed", p) for p in PROJS)
    la = layer_us_fused(1, r)
    note = f"   fused gate+up + down = x{fu / la:.2f} vs three separate launches" if la < fu else ""
    print(f"{r:5d} {a:>9.2f} {b:>9.2f} {h:>9.2f} {i:>9.2f} {j:>9.2f} {la:>9.2f} {win[1]:>13}{note}")
    print("\nOne kernel wins at every measured batch now: rev J (transposed tiles) beats rev I by 1.27-1.46x and\n"
          "dp4a by ~8x at rows=16. Dispatch is a single family, with one caveat that is a design decision rather\n"
          "than a tuning knob: rev J needs the device copy of the weights intra-tile permuted (dword q*K+i ->\n"
          "i*8+q). Same bytes, same DRAM traffic, same output bits, ~1.5 ms one-time device permute for a 512 MB\n"
          "resident set - but the device tensor stops being byte-identical to the checkpoint, which is the\n"
          "property the 'native layout, no repack' constraint was protecting. If that constraint is kept\n"
          "literally the fallback is dpas_gather (rev I) at +27-46%, still one kernel; dp4a is the only option\n"
          "where no permutation is possible at all. Revs G/H carry no advantage now and remain for provenance.\n"
          "Rows=2 is interpolated; nothing here extrapolates past the measured set 1/2/4/8/16.")
    print("\nE25a (last column): gate+up in ONE launch at KS=1 plus down separate. Faster than three separate\n"
          "projections at every measured rows (x1.06 at rows=1, x1.17 at rows=16) and it halves the gemm launch\n"
          "count - but it is CONDITIONAL (D8): it wins because the separate launches under-fill ~2048 hardware\n"
          "thread slots. Use should_fuse(tn, KS, E); once one launch fills the machine, fusion costs ~7 %.")
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