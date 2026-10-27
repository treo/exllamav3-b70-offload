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

## 2026-10-28 (night): device-tier prefill split, 2.05bpw — the shipped default

`perfab.sh policy` = `perf.py -mcs 256 -ngr -mct 15 -mcpa --max_length 4096 -dr 5`, 2 arms x 2
rounds, **interleaved** (one process per arm per round), best of rounds. This is the only
comparison of the two policies taken on the same box in the same hour with the official metric;
single runs on different evenings moved ±3-5% and inverted the sign.

| arm | pre 256 | 512 | 1024 | 2048 | 4096 | dec mean |
|---|---|---|---|---|---|---|
| previous policy (`STREAM_T_DEV=11`, `SLOT_ROWS_DEV=128` = the old behaviour) | 567 | 837 | 1256 | 1695 | 1943 | 67.6 |
| **device-tier split (`STREAM_T_DEV` 24, `SLOT_ROWS_DEV` 1024) = new default** | **624** | **915** | **1343** | **1816** | **2005** | **67.7** |
| gain | +10% | +9% | +7% | +7% | +3% | neutral |

Supporting measurements (in-process `pb.py`, min-of-3, 2 rounds interleaved; NOT interchangeable
with perf.py numbers, but same sign and bigger - the steady state favours the new policy more):

| arm | pre 1024 | 2048 | 4096 |
|---|---|---|---|
| previous policy | 1258 | 1577 | 1923 |
| device-tier split | 1322 | 1739 | 2074 |
| all worker work on B70, `cap_rows` 128 (`STREAM_T=100000`) | — | — | 1411 (1344-1475) |
| └ same, `cap_rows` 1024 | — | — | **1568** (1508-1645) — the chunk-fullness lever, +11% |

Timeline of the default arm at 4096 rows (kineto + dmon + xpu-smi): 3090 compute stream 81% busy,
union of both 3090 streams 91%, link 3.2 GB/s mean of 12.8 usable, B70 21-28% util / 70 W of
275 W. `expert_bytes` = **1 228 800 B** (one streamed expert = ~92 us of link, not the 184 us the
earlier plateau note assumed). Quality (`qa_stream.py`, 8192 tok): CPU 2.318407, new default
2.321975 (+0.15%, budget ≤0.25%; the arm it replaces was +0.16%). Method + tools:
`sycl_moe/SESSION_20261028.md`.

## 2026-10-27 (evening): prefill policy + plugin A/Bs, 2.05bpw

`perf.py -mcs 256 -ngr -mct 15 -mcpa --max_length 4096` (prefill tok/s at the stated context
length; decode = ctx 0 … 3840), reps interleaved in one batch, scored per NOTES rule 6.

| arm | pre 1024 | pre 2048 | pre 4096 | dec mean | notes |
|---|---|---|---|---|---|
| CPU worker | 1179 / 1180 | 1559 / 1616 | 1960 / 1840 | 64.4 / 64.0 | the bar; no B70 |
| B70, classic anti-theft (`STREAM_HOT=0`) | 986 / 971 | 1114 / 1102 | 1202 / 1197 | 67.3 / 67.5 | the regression this fixes |
| B70, hot-pick streaming (default) | 1247 / 1230 | 1605 / 1604 | 1984 / 1969 | 67.2 / 67.2 | shipped (bucketing + n-major) |
| B70 streaming, k-major plugin | 1240 / 1163 | 1628 / 1670 | 2006 / 1902 | 68.1 / 66.7 | n-major pair: neutral in-model |
| B70 streaming, n-major only | 1254 / 1229 | 1634 / 1707 | 1897 / 1895 | 67.6 / 67.7 | (kernel -7%, tail share too small to show) |
| B70 streaming, `STREAM_T=32` | 1298 | 1622 | 1963 | 67.0 | plateau, not a win |
| B70 no streaming, `SLOT_ROWS=512/1024` | 1077 / 1070 | 1256 / 1293 | 1411 / 1401 | — | the no-PCIe regime |

Streaming threshold sweep with the knob on (prefill @4096): st4 1690 | auto(≈11) 1857-1984 |
16 1953-2005 | 24 1912-1969 | 32 1963-2045 | 48 1878 | 64 1838 | 96 1720 → flat from 11 to 32,
worse from 48 up and much worse at 4; auto stays the default. `SUB=0.5/0.25` (leaving part of
each layer's expert set on the CPU pool): 1806 / 1857 - splitting the tail off the B70 does NOT
help here. `cap_rows` with streaming (pre-bucketing) 256/512/1024: 1925 / 1938-1957 / 1955, and
1920 with bucketing; the CPU arm is flat too (1872 at 512) ⇒ 128 stays the default.

Plugin A/B, standalone (bench_layer E=260/K2=8 int8, min-of-2 interleaved, µs/job):
rows128 k-major 3320 → n-major 3092 (-6.9%); rows1 float 179.0 → 165.0 (-7.8%); rows512
8934 → 8531. Bucketing on top of n-major: rows32 1919→1648, rows64 2630→2260, rows128
3121→2867, rows256 4834→4667, rows512 8604→8379, rows1024 15776→15539. Wide-M (MAXM=16) and
slim+A-ring are negative - tables in `moe_layout.hpp` / `int8-dpas-tier.md`.

Pure-read probe t47 (1.68 GB footprint): production [tk][nf] order 305 GB/s, n-major 781,
sequential `uint4` 781 - the pattern, not the byte count, was the cap; the kernels only convert
~7% of that into wall clock because they are fragment-bound, not DRAM-bound.

C-ABI decode shape (`bench_b70_py.py`, xval_s, rows=1): 103.6 µs (ref 101.5-102.0), rms
6.5295e-07 = the recorded reference ⇒ the geometry refactor and bucketing are value-preserving.

Quality: `qa_stream.py` (8192 tokens of chunked prefill - the only gate that engages the streamed
tier, since eval/ppl.py scores one row per forward): CPU 2.316795, B70+hot-pick 2.320494
(+0.16%), B70 anti-theft 2.317882 (+0.05%); budget ≤0.25%. `ppl.py -mcs 384 -r 20 -l 2048`
(rows < stream_min_rows, so the knob is inert there): CPU 3.969679, B70 knob on 3.975833,
knob off 3.969526.

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