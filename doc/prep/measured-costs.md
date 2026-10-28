# MoE CPU offload: measured costs

Every number in the companion documents (`moe-cpu-offload-data-paths.md`, `tuning-knobs.md`) that
looks like a duration comes from here. Raw logs are in `notes/m_*.txt`, produced by the scripts in
`notes/` (`bench_cpu_moe.py`, `bench_handoff.py`, `bench_link.py`, `prof_e2e.py`, `run_e2e.sh`,
`geom.py`); rerun them to reproduce. They are dev scaffolding, not part of the library.

## 0. Machine and method

| | |
|---|---|
| GPU | NVIDIA GeForce RTX 3090 (sm_86, 24 GiB), one device, `torch 2.14.1+cu130` |
| CPU | AMD Ryzen 9 5950X, 16 physical / 32 logical cores, 2 CCD × 32 MiB L3, **AVX2 tier only** (no AVX-512/BW/VNNI/VBMI) |
| DRAM | 125 GB, dual-channel DDR4 |
| Link | PCIe **Gen 4 × 8** (sysfs `current_link_speed=16.0 GT/s`, `current_link_width=8`, max `x16`) — `notes/bench_link.py` |
| Driver state note | with the GPU idle the link reports Gen3; it trains to Gen4 x8 under load and stays there |

Models: `/home/treo/projects/vendor/tabbyAPI/models/Qwen3.5-35B-A3B-3bpw-hq2` (40 MoE layers,
256 experts, top-8, H=2048, I=512, experts at **K=3**) and
`…/Qwen3.8-Flash-Next-exl3-2.68bpw_h6_ng8` (48 MoE layers, 512 experts, top-10, H=2560, I=640,
experts at **K=2.5** in most layers). Qwen3.5 is small enough to also load entirely on the GPU, so
it provides an all-GPU reference for the same weights.

Method notes / caveats:

* Wall-clock (`time.perf_counter`) around host calls; CUDA **events** for device-side spans; the
  torch profiler (`notes/prof_e2e.py`) for per-kernel self time.
* The worker is run *in-process* by `notes/bench_handoff.py` via the bound
  `exl3_moe_cpu_worker_run` (same entry point the child process uses), on a real pinned
  `SharedMemory` segment built by `tests/testlib/moe_handoff.py`. Numbers therefore exclude
  process-spawn and pipe effects but include everything else.
* Cold-expert discipline: the CPU-GEMM sweep rotates over 64 different random expert selections so
  the trellis bytes are not served from the 64 MiB L3. A single repeated selection measures ~2×
  faster and is meaningless.
* Both `EXL3_SPLIT_PROF` and `EXL3_MOE_HANDOFF_PROF` add per-layer cost of their own: the profiled
  run measured 67 tok/s where the same configuration without profilers measured 93-98 tok/s
  (§8). Treat the *ratios* inside those logs as indicative, their absolute levels as inflated.
* `notes/prof_e2e.py` feeds **random** token ids, so its routing (and therefore how many experts
  cross `stream_t` in the prefill measurement) differs from real text: the profiled prefill streamed
  3 571 of 7 680 CPU experts. Where a byte count matters it is recomputed from the
  `EXL3_MOE_STREAM_DEBUG` batch lines of the same run (`notes/m_prof_e2e_sd.txt`).
* Everything here is one AVX2 host + one Ampere GPU. Sections marked *(arch)* are the numbers that
  will move on a different CPU tier; the protocol for re-measuring is the point of the harnesses.

## 1. Weights per unit of work

From the checkpoint headers and `register_layer`'s byte layout (`moe_cpu_host.py:1158-1164`),
i.e. `proj_bytes = (k/16)·(n/16)·16K·2` per projection:

| model / rate | gate = up = down | expert block `g+u+d` | layer | all MoE layers |
|---|---|---|---|---|
| Qwen3.5-35B, K=3 (all 40 layers) | 393 216 B | **1 179 648 B (1.125 MiB)** | 0.28 GiB (256 experts) | 11.25 GiB |
| Qwen3.8-FN, K=2.5 (layers 4-43) | 512 000 B | **1 536 000 B (1.465 MiB)** | 0.73 GiB (512 experts) | 29.2 GiB |
| Qwen3.8-FN, K=3 (layers 0-3, 44-47) | 614 400 B | 1 843 200 B (1.758 MiB) | 0.88 GiB | 7.0 GiB |
| Qwen3.8-FN, all 48 MoE layers (header sum) | | | | **36.33 GiB** |

Handoff region sizes (`notes/geom.py`): control 333 KiB (of which the 256-entry job ring is
270 KiB, 1056 B/descriptor); compute slot at `cap_rows=64, topk=10, H=2560`:
`x` 320 KiB + `sel` 2.5 KiB + `w` 1.25 KiB + `out` 640 KiB = 963.8 KiB/slot; 4 slots = 3.76 MiB;
weight-staging ring 2 × 32 MiB. Total pinned footprint ≈ 68 MiB (`region=68.1 MiB` in the logs).

## 2. Link and memory ceilings

| what | measured | note |
|---|---|---|
| pinned H2D, 256 MiB sustained | **13.3 GB/s** | Gen4 ×8 ⇒ ~84% of the 15.75 GB/s payload ceiling |
| pinned D2H, 64 MiB | 12.6 GB/s | |
| same, on the model's own probe | 13.4 GB/s | `EXL3_MOE_STREAM_DEBUG` prints `stream state cuda:0: pinned->device 13.4 GB/s, stream_t 11` |
| copy latency floor (any size ≤ 16 KiB, pinned) | 3.5-4.7 µs | per `copy_`, stream time |
| D2H 256 KiB / H2D 512 KiB (a `cap_rows=64` slot at H=2048) | 21.6 / 41.3 µs | 12.2 / 12.7 GB/s |
| single-thread host copy (read+write) of a 0.38 MiB block | 37.8 GB/s | reference for "one core's memcpy" |
| CPU GEMV stream rate, 15 threads, K=3 packed | 47.4 GB/s | at the dual-channel DDR4 wall |
| CPU GEMV stream rate, 15 threads, K=2.5 native | 31.1 GB/s *(arch)* | the AVX2 tier leaves half rates unpacked |

## 3. Flags and the handshake

`ext.exl3_moe_flag_write` / `flag_wait` with `EXL3_MOE_MEMOPS=1` (stream memory operations)
vs `=0` (spin-wait kernels), RTX 3090:

| quantity | memops | kernels |
|---|---|---|
| host enqueue of one write / one satisfied wait | 1.8 / 1.9 µs | 2.9 / 2.5 µs |
| host→GPU→host round trip, stream recently used | 6.4 µs med (p90 14.9) | 10.7 µs med (p90 13.2) |
| same, stream idle 2 ms beforehand | 10.5-18.6 µs med, max 248 | 14.8 µs med, max 214 |
| GPU write visible to a host spin loop | 4.3-5.1 µs med | 7.4 µs med |

The "idle stream" penalty is the dominant term and is a property of the box (front-end clock
ramp), not of the protocol. Nothing here is per-byte; the whole handshake is a fixed ~20 µs.

## 4. Decode path (P1) end to end

`notes/bench_handoff.py … --skip copies,stage,unswizzle`: one real job (issue kernel → worker
compute → collect kernel) with the stream otherwise idle, so the number is the *worst-case exposed*
cost; in a real forward the GPU's own expert work hides part of it (§7).

Qwen3.5-35B, `-mcs`-style split (all 256 experts in the worker), 15 worker threads:

| rows | host enqueue (issue+collect) | serial layer, med | 48-job pipeline | CPU experts/job |
|---|---|---|---|---|
| 1 | 14.3 µs | 162.9 µs | 185.3 µs/layer | 8 |
| 2 | 20.0 µs | 281.6 µs | 271.3 µs/layer | 15 |
| 4 | 20.7 µs | 496.1 µs | 470.8 µs/layer | 29 |
| 8 | 23.7 µs | 957.1 µs | 960.7 µs/layer | 53 |
| 16 | 34.8 µs | 1967.9 µs | 1992.4 µs/layer | 97 |
| 32 | 34.1 µs | 4211.1 µs | 4257.8 µs/layer | 150 |

Qwen3.8-Flash-Next (K=2.5 experts, 1.465 MiB each, topk 10, 15 threads):

| rows | serial layer, med | 48-job pipeline |
|---|---|---|
| 1 (empty job) | **20.2-25.6 µs** | 13-19 µs/layer |
| 1 | 403.0 µs | 401.6 µs/layer |
| 4 | 1508.7 µs | 1515.6 µs/layer |
| 32 | 11711 µs | 11744 µs/layer |

Reading: the layer cost is (experts touched × expert bytes) ÷ (CPU stream rate) plus a ~20-35 µs
handshake+enqueue tax, and it is *identical* whether jobs are pipelined or serial, i.e. at these
sizes the worker is saturated by one job and gets no benefit from queue depth. An all-`-1` job
costs 20 µs, which is the floor any port must beat or match.

With `EXL3_MOE_MEMOPS=0` the same Qwen3.5 rows measure 171.9 / 285.9 / 507.4 / 977.9 / 1982 /
4240 µs — within noise of the memops numbers, because the 190 µs of compute dwarfs the ~10 µs
difference in handshake. The knob only matters for layers where the CPU job is small.

## 5. Worker-side compute (the shape of the CPU cost curve)

`notes/bench_cpu_moe.py`, real experts registered into one layer, cold selections, µs per
`exl3_moe_cpu_forward` call (one layer's routed experts for `rows` tokens, `topk` picks each):

Qwen3.5-35B (K=3 packed band-2+planar, 1.125 MiB/expert, topk 8):

| rows | 1 thr | 4 thr | 8 thr | 12 thr | 16 thr | GiB/s @16 |
|---|---|---|---|---|---|---|
| 1 | 1481 | 444 | 261 | 214 | 196 | 47.4 |
| 4 | 5803 | 1574 | 946 | 846 | 783 | 45.8 |
| 16 | 20368 | 5470 | 3115 | 2729 | 2691 | 44.3 |
| 64 | 59070 | 15895 | 8503 | 6842 | 6659 | 39.1 |
| 128 | 99736 | 27853 | 14545 | 10532 | 9740 | 30.4 |

Per token: 196 µs at 1 row → 76 µs at 128 rows, because ≥2 assignments increasingly share an expert
(4.1 assignments/expert at 128 rows) and the trellis read is amortized. Scaling is bandwidth-bound
beyond ~8 threads (45-47 GB/s ≈ the DRAM wall), so extra cores buy little on this host; the
`EXL3_MOE_CPU_THREADS` sweep in §8 confirms it end to end.

Qwen3.8-Flash-Next, µs/call at 15 threads, rows 1 / 4 / 16 / 64:

| experts at | K=2 (packed) | K=2.5 (native) |
|---|---|---|
| 10 (rows 1) | 305 | 490 |
| 38 (rows 4) | 1144 | 1869 |
| 138 (rows 16) | 4150 | 6834 |
| 365 (rows 64) | 11959 | 20561 |
| rate | 40 GB/s | 31 GB/s |

*(arch)* K=2.5 with and without `EXL3_MOE_CPU_SWIZZLE` measured identically (490 vs 484 µs at
rows 1) because the AVX2 tier does not band half rates; for K=3 the same knob is worth the decode
delta in §8. Expect both columns to change on an AVX-512 (band-8) host.

Phase split: `EXL3_MOE_CPU_PROF=1` reports **cumulative** averages over the whole run (its
accumulators are never reset, `moe_mul1.cpp:3900,3977,3985`), so with prefill and decode jobs in one run
the printed per-phase numbers are a mixture that converges only slowly — from `gemv_gu 1840 µs
(33 GB/s) | gemv_d 1012 µs` early (prefill-dominated) to `154 µs (35 GB/s) | 81 µs (33 GB/s)` after
73k jobs. Usable as a *ratio* (gate/up ≈ 2× down, both at 33-35 GB/s, i.e. below the 45 GB/s the
microbenchmark reaches, because a decode job is only ~5.8 assignments over 6-8 experts and does not
fill 15 threads). The absolute decode cost should come from `EXL3_MOE_HANDOFF_PROF`, which resets
every 64 jobs: `compute 0.181-0.194 ms/job`, `spin 0.114-0.135 ms` (the worker waiting for the GPU
to publish inputs — the worker is *ahead*), `gap 0.015-0.036 ms` (queue idle).

## 6. GPU kernels on the decode path

`notes/prof_e2e.py -mcs 192 -decode 32`, 32 tokens × 40 layers = 1280 calls per layer-position
kernel; device self-time only:

| activity | calls | µs/call | share |
|---|---|---|---|
| `moe_split_issue_kernel` | 1280 | **3.89** | 2.4% |
| `moe_split_collect_add_kernel` | 1280 | **4.00** | 2.4% |
| `exl3_moe_coop_a_kernel` (GPU experts, part A) | 1280 ×2 | 18.0 / 15.6 | 20.3% |
| `exl3_moe_coop_b_kernel` (part B) | 1280 ×2 | 10.9 / 9.6 | 15.3% |
| `routing_gemv_kernel` + `routing_std_topk_kernel` | 1280 each | 3.83 / 3.31 | 4.3% |
| `exl3_mgemm_kernel<7,…>` (attention/dense GEMV) | 960 | 38.5 | 17.5% |
| total device time | | **6.61 ms/token** | |

Measured throughput for the same configuration was ~98 tok/s = **10.2 ms/token wall**, so ≈3.6
ms/token (≈90 µs/layer) of each decode step is *not* device work: it is the stream parked in the
collect wait. That is the quantity a port optimizes: the worker has 6.6/40 = 165 µs/layer of GPU
work to hide its own compute behind.

No `cudaMemcpyAsync` appears on the MoE path in this configuration (the fused path moves bytes with
the two kernels above); the 64 memcpys in the log are unrelated (sampler/state readback).

## 7. Prefill: the streamed path

Same script, one 2048-row chunk, `-mcs 192`. (`prof_e2e` feeds random token ids, so only 3 571 of
the 7 680 CPU assignments-in-range crossed `stream_t = 11` here; with real text the count is
~181 of 192 experts per layer — `notes/m_e2e_streamdbg.txt`.)

| activity | calls | µs/call | total ms | share |
|---|---|---|---|---|
| `Memcpy HtoD (Pinned → Device)` | 332 | 982.0 | 326.0 | **28.2%** |
| `aten::copy_` (self, incl. the above) | 2285 | 146.7 | 335.2 | 29.5% |
| `exl3_moe_kernel<3,128,2,64,…>` (fused tier, 64-row tile) | 207 | 460.5 | 95.3 | 8.4% |
| `f16acc::gemm_kernel` ×2 variants (batched recon / dense) | 404 | 648 / 145 | 105.9 | 9.3% |
| `moe_unswizzle_kernel` | 504 | 38.8 | 19.6 | 1.7% |
| `exl3_moe_kernel<…,32/16 tile>` | 397 | 83 / 145 | 30.2 | 2.6% |
| `reconstruct_had_batch_kernel` | 1191 | 10.6 | 12.6 | 1.1% |
| `exl3_moe_gather_kernel` (deterministic accumulation) | 40 | 134.9 | 5.4 | 0.5% |
| total | | | 1136.7 ms | |

Weight movement, not arithmetic, dominates the streamed tier. That prefill streamed 3 571 experts =
**3.92 GiB** of trellis bytes (counted from the run's own `EXL3_MOE_STREAM_DEBUG` batch lines),
which the 326 ms of `Memcpy HtoD` puts at **12.9 GB/s** — i.e. the DMA runs at the measured link
ceiling and nothing else about it can be optimized except moving fewer bytes. With real text
(`eval/perf.py`) 181 of the 192 CPU experts cross `stream_t` at 2048 rows, so the same chunk costs
8.2 GiB ≈ 610 ms of link time. Two consequences: the `stream_t` threshold exists to keep *cold*
experts off this path, and `EXL3_MOE_PINNED_ARENA=1` (which removes the intermediate worker
`memcpy` and one copy pass) is worth the +32% prefill seen in §8.

Component costs of the staged path (`notes/bench_handoff.py --skip copies,loop,empty,flags`,
Qwen3.5, 4 stage threads, 28 experts = 31.5 MiB per batch):

| hop | measured |
|---|---|
| worker `memcpy` arena → pinned slot | 2.02 ms for 31.5 MiB = **16.3 GB/s**; ~**175 µs fixed** per stage job, ~66 µs per expert marginal |
| same with `EXL3_MOE_CPU_STAGE_THREADS` = 1 / 2 / 4 / 8 | 2.13 / 2.06 / 2.02 / 2.12 ms — **no measurable effect on this host** (single-threaded memcpy already saturates; `stage_phase` also spawns fresh `std::thread`s per job, `moe_mul1.cpp:3595-3620`) |
| pinned slot → VRAM (`copy_`, contiguous) | 2.48 ms = **13.3 GB/s** (11.0 GB/s for a single 1.1 MiB expert — latency-bound) |
| `moe_unswizzle_trellis` (band-2+planar → native), 28 experts, per projection | 49-51 µs for 10.5 MiB read+write = ~440 GB/s effective (VRAM-bound) |

So the staged path costs ~2× the DMA alone (host copy + link copy + unswizzle), while the pinned
arena path costs the link copy + unswizzle only.

## 8. End-to-end effect of the knobs

`eval/perf.py` on Qwen3.5-35B: all-GPU reference, then 75% of every layer's experts on the CPU
(`-mcs 192`) and variants. Prefill = the 2048-token point of the prefill sweep (4096-token chunk
size), decode = 100 tokens at 1024 context. `notes/m_e2e_*.txt`. Tok/s.

**Read this table with a ±6% band**: four runs of the same `-mcs 192` configuration (with and
without profiler env) measured 93.2, 98.1, 98.9 and 104.2 tok/s at that decode point, and the
profiler-enabled run measured 66.9. Differences below ~10% are not resolved by single-shot runs.

| configuration | prefill | decode |
|---|---|---|
| all on GPU (reference) | 5043 | 124.4 |
| `-mcs 192` default | 1661 (2631 @4096) | 93.2 (98.1 @4096-len run) |
| `-mcs 192 -mcpa` (pinned arena + promote-on-miss) | 2195 (3261 @4096) | 78.0 |
| `-mcs 255` (all but one expert on CPU) | 1519 | 67.2 |
| `-mcl 20` (20 whole layers on CPU) | 2137 (3263 @4096) | 78.4 |
| `-mcl 40` (every MoE layer on CPU) | 1401 | 54.5 |
| `EXL3_MOE_MEMOPS=0` | 1674 | 91.7 |
| `EXL3_MOE_CPU_SLOTS=8 EXL3_MOE_CPU_SLOT_ROWS=128` | 1686 | 97.1 |
| `EXL3_MOE_CPU_SLOT_ROWS=32` | 1677 | 105.3 |
| `-mct 8` (8 worker threads) | 1751 | 98.4 |
| `EXL3_MOE_CPU_SWAP=0` (static placement) | 1611 | 99.3 |
| `EXL3_MOE_CPU_SWIZZLE=0` | 1708 | 89.3 |
| `EXL3_MOE_CPU_WIDE=0` | 1725 | 96.1 |
| `EXL3_MOE_STREAM_T=1000000` (streaming off) | **754** | 98.5 |
| `EXL3_MOE_STREAM_MIN_ROWS=4096` (streaming off ≤2048 rows) | 818 | 102.9 |
| `EXL3_MOE_STREAM_BATCH_EXPERTS=48 + WSLOT_MB=96` | 1695 | 100.2 |
| `EXL3_MOE_STREAM_BATCH_RECON=0` | 1746 | 103.6 |
| `EXL3_MOE_STREAM_DEBUG=1` (profiling overhead) | 1689 | 104.2 |

Interpretation, in the order the levers matter:

1. **Streaming decides prefill.** Disabling it (`STREAM_T` absurd, or `MIN_ROWS` above the chunk
   size) costs 2.1-2.2× at 2048 rows; everything else moves prefill by <6%.
2. **Pinned arena** buys another +32% prefill (no stager `memcpy`, direct DMA from the worker's
   weights) but appears to *cost* decode (78 vs 93-104): `-mcpa` also switches placement from the
   periodic sweep to promote-on-miss with 4 spare slots per layer, whose per-step transfers and
   bookkeeping land on the critical path.
3. **Decode is set by expert bytes × hit rate ÷ DRAM bandwidth**, and only secondarily by knobs:
   halving the pool (15→8 threads) is free, `SLOT_ROWS=32` is at the top of the range (105) and
   `-mcpa`'s promote-on-miss at the bottom (78), while static placement (99) is indistinguishable
   from dynamic (93-104) on this workload. `-mcl 40` — no
   GPU-resident experts at all — costs 56% of decode, matching the model in §4: 40 layers ×
   (8 experts × 1.125 MiB ÷ ~45 GB/s) ≈ 8.8 ms of unavoidable CPU streaming per token on top of the
   ~8.5 ms of GPU work, i.e. ~55 tok/s against the measured 54.5.
4. `STREAM_BATCH_EXPERTS`, `STREAM_BATCH_RECON` and `STREAM_FUSED_T` were inert at these shapes
   (all experts land in the fused tier with 100-160 rows each, `EXL3_MOE_STREAM_DEBUG` batch lines
   in `notes/m_e2e_streamdbg.txt`); they need hotter-skewed routing (or a larger model, e.g. the
   512-expert Qwen3.8) to show an effect.

## 9. What a port should re-measure first

1. Pinned H2D/D2H sustained bandwidth and latency floor (sets `stream_t`, `WSLOT_MB`, and whether
   the staged or arena DMA path wins): §2.
2. Cold-expert CPU read bandwidth vs thread count, for the actual ISA tier and for both packed and
   native layouts (sets `SLOT_ROWS`, `THREADS`, and whether the swizzle rule needs a new tier): §5.
3. The all-`-1` job cost, i.e. your handshake's floor without payload (must be ≪ the GPU's
   per-layer work at decode): §4.
4. Per-kernel decode budget (device ms/token vs wall ms/token) to see how much slack exists to hide
   the worker behind: §6.
5. Stage-memcpy + unswizzle cost per expert batch on your host/device pair (this is where the
   prefill budget goes): §7.