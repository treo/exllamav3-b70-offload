# Measurements ledger

Canonical numbers, newest first, each with config + validity. Numbers in the other archive files
are the evidence for a decision; this file is what to quote.

Legend: **pre** = prefill tok/s @1024 unless noted, **dec** = decode tok/s at ctx 0 unless
noted, "VOID" = invalidated by a confounder listed in `measurement-discipline.md`.

## Device constants (b70-bench manual pass)

| quantity | value |
|---|---|
| B70 memcpy (D2D/VRAM) | 674 GB/s (spec 608 GB/s panel BW; ~8.2 MB unique gu working set = 13.5 µs floor) |
| B70 XMX int8 | 367 TOPS (achievable only with fragment reuse over ~8192 mads) |
| B70 FP32 vector | 22.7 TFLOPS |
| RTX 3090 link | Gen4 **x8**, pinned→device 13.4 GB/s (92% of link) |
| B70 link | pinned H2D/D2H 12.9-14.5 GB/s (sysfs reports x1 — wrong) |
| per-command host cost | SYCL submit ~3.7 µs; raw ze append ~2 µs (12-15 µs for a 6-kernel chain) |
| per-command GPU cost at decode | ~8-15 µs per chained queue op; `--bare` barrier round trip 33 µs |

## Model end state (current build: coop-D + ring + MAXM8 + full rate specialization)

| model | config | pre / dec (CPU worker) | pre / dec (B70) |
|---|---|---|---|
| 2.05bpw | `-mcs256`, auto | ~1456-1511 / 67.9-70 | 1852-1886 / 70.2-72.6 |
| 2.68bpw | guarded auto, `-mcs384-448` | —/40.2 | 512-562 / 58.7-60.0 (pre-guard regime 748 / 53.3) |
| 4.05bpw | `-mcs448`, SUB=0.5 + st4 | 226 / 24.9-25.7 (37.5 dec with pinned streaming, no B70) | 598-606 / 54.2-57.9 (classic full-layer tier earlier: 590 / 48.1; 20-21 layers resident @budget 0.70) |
| 4.18bpw (HYBRID) | SUB=0.5, warm profile | — | 807-854 / 42-43.5 |

Headline claims safe to repeat: **4.05bpw decode ~2.1-2.4x the CPU worker**, 2.68 ~1.4-1.5x,
2.05 decode flat / prefill +25-28%; win scales with offload share (see `placement-policy.md`).

## Quality gates

wikitext-2 ppl, `-r 20 -l 2048`, `-mcs` per model, float tier (original gate):

| model | mcs | CPU | B70 |
|---|---|---|---|
| 2.05bpw_h4_ng4 | 384 | 3.960071 | 3.968360 |
| 2.68bpw_h6_ng8 | 384 | 3.824000 | 3.822094 |
| 4.05bpw_h6_ng6 | 448 | 3.730495 | 3.730074 | ← 17/48 layers resident

int8 auto tier (fresh CPU baselines, same session):

| model | config | CPU | B70 int8 | Δ |
|---|---|---|---|---|
| 2.05bpw | -mcs384 | 3.963241 | 3.972811 | +0.24% |
| 2.68bpw | -mcs384 | 3.823990 | 3.820485 | -0.09% (partial residency) |
| 4.05bpw | -mcs448 | 3.732906 | 3.739851 | +0.19% (27 layers fell back) |

Other accuracy references:
- qbench-trace ppl (8 rows, 15874 tok), 2.05bpw: CPU 1.479306 vs B70 1.479269.
- 2.05 mcs384 r8 after coop-D: 2.524839 (coop) == 2.524839 (split).
- xval vs the real CPU scalar extension: **float tier 6.043e-07 rms** (6.5295e-07 with coop-D
  nsl_d=1 slice rounding), **int8 tier 1.355e-3**, gateless-vs-scalar 4.99e-07.
- Synthetic battery: ≤2.9e-6 max_rel vs the fp32 host reference across E/rows/topk/bits/hb/act.
- Soak: 2x heavy ppl passes on 4.05bpw @mcs448 partially resident: rc=0, no registration/forward
  failures, ppl spread 3.39274/3.39073 = 6e-4 rel, from K6 relaxed fp32 atomics (nondeterministic
  order — acceptable, matches CUDA-backend norms; superseded for the coop path by fixed-order
  owner sums).

## Sustained-clock tier A/B (THE honest table; rows=1..64, min-of-3 interleaved, iters=1200)

VTune under a 30k-iteration sustained run: int8 layer G2 48 µs / G5 30 µs, Spill 0, XMX ~2-3%
busy, XVE idle ~77%; float layer GemvK gu 52 µs / down 29 µs. So at rows=1 both tiers cost the
same IN-KERNEL (weight-traffic bound, as the roofline predicts): the earlier "int8 -20% decode"
was cold-clock inflation plus 3 extra launches in the sync-gap duty cycle.

| rows | float µs | int8 µs | speedup |
|---|---|---|---|
| 1 | 179.5 | 222.0 | 0.81 |
| 2 | 262.8 | 224.5 | 1.17 |
| 3 | 315.6 | 223.5 | 1.41 |
| 4 | 354.6 | 223.1 | 1.59 |
| 5 | 558.0 | 272.6 | 2.05 |
| 8 | 777.5 | 344.0 | 2.26 |
| 32 | 2233.5 | 865.2 | 2.58 |
| 64 | 4278.1 | 1941.8 | 2.20 |

Post-slim/fused-prep/owner-gather restatement (float-vs-int8-slim, current build): rows 1 ×0.80
→ ~×0.91 (170.9-171.4 vs 186.7-188.3 µs at K2=4), 2 ×1.17, 4 ×1.50, 8 ×2.40, 16 ×2.70,
32 ×2.98, 64 ×2.65, 128 ×2.13. Maxm8 same-binary w8/w4 A/B: rows 5 ×1.11, 6 ×1.13, 8 ×1.40,
12 ×1.34, 16 ×1.42, 32 ×1.59, 64 ×1.55, E64/r32 ×1.24, E128/r128 ×1.51, rows≤4 neutral.

## C-ABI per-forward (`bench_b70_py.py`, xval_s, rows=1)

| build/path | µs | rms vs ext | validity |
|---|---|---|---|
| fp32 tier, old 20 µs-poll wait | 110.7 | 6.05e-7 | **poll-contaminated, do not quote** |
| int8-forced, old poll wait | 124.0 | 1.36e-3 | **poll-contaminated** |
| fp32 split (fixed wait) | 113.6 | 6.043e-7 | good |
| fp32 coop-D (fixed wait) | 101.5 / 102.0 | 6.5295e-7 | **current reference** |
| int8-slim coop-era build | ~186.7 (bench rows1) | 1.355e-3 | float still wins m=1 |

Polling slop was +70 µs on nearly every call in both modes, so pre-fix C-ABI numbers are unusable
for deltas under ~15%.

## Synthetic pipeline history (E=12, topk=10, 2bit, rows=1)

343 µs (naive) → 260 (split-K) → ~172-186 (microopt pass) → 165-172 (VTune pass 2: MMA split,
fusion, nsl) → 158.8 coop-D (bench) with sustained medians 168-179 float / 183-222 int8
depending on slim and phase. CPU comparison points: CPU native-ISA 295 µs (swizzled) / 452 µs
(native layout); GPU rows=8 690 µs vs CPU 4600 µs (early "prefill-ish" measurement).

## Registration / load cost

Arena + threaded fill: 168 → 50 ms per E=256 layer (~-5.7 s across 48 layers). See
`memory-and-registration.md`.

## Sweep tables not repeated here

`placement-policy.md` holds mcs / stream_t / SUB / guard sweeps; `int8-dpas-tier.md` holds the
ring and MAXM8 A/Bs; `kernel-microopt.md` holds the per-variant µs for gemv micro-optimizations
(including the rejected ones).