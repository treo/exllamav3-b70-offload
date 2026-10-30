# `notes/b70/` — Arc Pro B70 capability probes

Dev scaffolding for the B70 MoE-offload port (design in [`../../doc/port/README.md`](../../doc/port/README.md)).
Nothing here is library code. Every number below was measured on this box on 2026-10-28 with
oneAPI 2026.2 (`icpx -fsycl`), Level Zero 1.18, driver 26.35 (`neovega` on the `xe` driver), an
Arc Pro B70 (BMG-G31, 32 Xe cores / 256 vector engines, 31.9 GiB) behind a PCIe switch at
`0000:0f:00.0`, next to an RTX 3090 at `0000:0c:00.0` on a Ryzen 9 5950X.

Build everything, then run the Python probe with the repo venv as well:

```
bash build.sh                                     # setvars.sh is sourced inside
source ../env.sh && python -u probe_cross.py      # needs torch + exllamav3_ext (CUDA)
```

Each probe's raw output is kept next to it (`out_*.txt`) and is what the tables below quote. They
were re-run after the fact to confirm reproducibility: the flag-poll job cost came back at 5.0–6.3 µs
across runs, the 1 MiB DMA at 13.1 GB/s, and both cross-vendor probes at their recorded pass counts.

| file | what it answers |
|---|---|
| `probe_transport.cpp` | device properties; pinned↔device copy bandwidth vs size; what a submission costs when completion is taken with `.wait()`; what a kernel paying attention to host memory costs |
| `probe_notify.cpp` | the same job shapes completed by **polling a flag the device wrote** instead of `.wait()` — the number the protocol actually pays |
| `probe_doorbell.cpp` | the minimal correct parked-kernel poll loop (three mechanisms, one work-item) |
| `probe_resident.cpp` | resident engine sizing: groups × lanes × poll backoff × payload, with SIMD-uniform polling |
| `b70_shim.cpp` + `probe_cross.py` | cross-vendor sharing: one page-locked region used by the 3090 *and* the B70, in both directions, including stream memops (8/9 — the one failure is by design: `cudaHostRegister` refuses xe-pinned memory, `LESSONS` 8) |
| `probe_crossproc.py` | the same, with the B70 engine in a **child process** on a `multiprocessing.shared_memory` segment the parent registered with CUDA — 10/10, so the engine may be a separate process |
| `probe_stores.cpp`, `probe_stores2.cpp`, `probe_unreg.cpp` | which store pattern actually reaches host memory (answer: plain stores do, 100/100; `sycl::atomic_ref` on a registered pointer does not, and costs the device) |
| `probe_coherency.cpp` | the disproved theory: it is not CPU-vs-GPU cache staleness (kept because the reasoning that led to it is the useful part) |
| `probe_rates.cpp` | what the card sustains on the **real decode tile walk**: native vs banded layout, no-arithmetic vs realistic arithmetic density, locality regimes, and the footprint sweep that the rate brackets come from |
| `probe_gemv.cpp` + `dump_gemv_case.py` | the **real** mul1 trellis decode GEMV: checkpoint trellis bytes (Qwen3.8 layer 0, K = 3.0), output **bit-exact** against `tests/testlib/trellis.py`, two grid orders bit-identical, rates across experts × rows (`out_gemv.txt`) |
| `probe_rates.cpp` | what the card sustains on the **real decode tile walk**: native vs banded layout, no-arithmetic vs realistic arithmetic density, scattered vs clustered work-item ordering; plus the four measurement traps this probe had to overcome (see its header and `LESSONS` 15) |
| `plan_operating_point.py` | where decode actually sits: distinct experts touched per layer vs batch (Monte-Carlo over real selection counts, `topk` from `config.json`) × `h`, sampled against the measured rate-vs-footprint curve → µs/layer, ms/token, crossover batch (`out_operating_point.txt`) |
| `plan_parent_budget.py` | the 3090's two bills — **capacity** (what must be resident) vs **traffic** (what a token streams) — plus the `P_order` vs `P_lpt` placement comparison behind `doc/port` §2.1a and gates E18/E19/E20 (`out_parent_budget.txt`) |
| `plan_quant_scaling.py` | does §2.1a survive the bigger recipes: five Qwen3.8 checkpoints (2.05–6.05 bpw), capacity/residency/decode time per quant, against **newly measured** K = 4/5/6 tile rates (`out_quant_scaling.txt`) |
| `plan_placement.py` | joins the safetensors census to the **real per-layer expert-selection counts** persisted by dynamic placement and answers, per model and per home-size: `h` (device-resident pick share), `\|res\|` (the migration set), one-time `fill` seconds, `σ`, and the CPU residue in ms/token (`out_placement.txt`) |
| `probe_dpas4..dpas9.cpp` | the integer-DPAS decode lineage: rev G (tokens on M, experts in grid) → rev H (ESIMD `xmx::dpas` from registers) → rev I (`lsc` gather for B, ~2x) → rev J (transposed tiles, another 1.3-1.5x) → rev K (fusion-of-combine ablations) → **rev L (`probe_dpas9.cpp`): the clean main path and the kernel the close-out recommends the engine implement** (`out_dpas.txt`, `out_revl.txt`) |
| `probe_permute.cpp` | what the intra-tile permuted device layout actually costs, on the whole 512 MiB resident set: device permute vs copy, host permute vs copy, and the readmit path (`out_permute.txt`) |
| `probe_combine.cpp` | the two combine schedules **standalone** (no gemm ahead of them in the stream), plus a producer pass and a 32 MB eviction pass — the instrument that showed the merged combine's in-situ loss was not L2 state (`out_e25b_combine.txt`) |
| `gate_dpas.py` | the exactness gate: 206 comparisons, 0 failures, 0 skips — dp4a and rev L on synthetic cases, native and parent-staged inputs with negative controls, the fused launch's two outputs, and **every shipped Qwen3.8 quantization (expert K = 2..6) dumped from real checkpoints** (`out_gate_dpas.txt`) |
| `sweep_ks_grid.py` | per-KS cost for the fused and separate schedules across E = 2..96, carrying a self-warming anchor between cells → the joint (fusion, split-K) tables in `plan_decode_cost.best_launch()` (`out_ks_grid.txt`; re-run with `--rows 1,8,16` it is also the rows-dependence instrument, `out_fusion_rows.txt`). A failed probe cell now prints `FAILED` and the sweep exits 1 — it used to print 0.000 µs, which is how a missing oneAPI runtime once produced a full table of confident zeros |
| `../../notes/bench_engine_step.py` | profiles the **real engine's** decode step (model_init + model.forward at b=1) and buckets device time by kernel name → the parent's measured non-expert cost, and the hyper-connection discovery (`out_engine_step.txt`) |
| `../../notes/bench_live_trace.py` | real generator on real text: aggregate throughput (with `--jobs N` concurrent sessions), per-token expert sets by histogram-diffing the CPU split's counters, and placement-migration counters (`out_live_trace.txt`) |
| `analyze_live_trace.py` | turns a trace into the plan's statistics four ways — consecutive, random-window, independence-on-measured-p, and the planner's own numbers — plus the residency curve h(N); `--emit-profile` writes an expert_stats file the planners consume via `B70_PROFILE_DIR` |
| `run_home_matrix.sh`, `run_mcpa_arms.sh`, `run_mcpa_migration.sh`, `run_ladder_fill.sh` | the arm scripts: two passes per arm through one profile directory (warmth is a variable, so it is controlled, not hoped for), the `-mcpa`/thread arms, and the E-ladder fill |
| `profiles/live/` | the traced routing profiles (5 Qwen3.8 quants × 48 layers × 512 experts, 91,680 picks each) plus stored fallbacks, so `B70_PROFILE_DIR=$PWD/profiles/live` reproduces the committed planner output exactly |
| `probe_barrier.cpp` | the E25c go/no-go: what a device-wide (atomic spin) barrier costs as a function of resident work-items, measured with matched work so the delta is the barrier alone — 1.6 µs at 256, 2.5 at 1024, 6.2 at the device's 2048 capacity, which is what killed "all three projections in one launch" without building it (`out_e25c_barrier.txt`) |
| `plan_decode_cost.py` | the measured B70 decode cost model that replaced `bytes / GB-per-second`: per-(expert, projection) costs by family and rows, the fused schedule, per-KS launch choice, the rows>16 bucket law, and D8's fill predicate (`out_decode_cost.txt`) |

## The measured facts that shape the design

| quantity | B70 here | CUDA/3090 reference (`doc/prep/measured-costs.md`) |
|---|---|---|
| pinned ↔ device, 256 MiB | **14.4 GB/s** both directions | 13.3 GB/s (Gen4 ×8) |
| pinned ↔ device, 1 MiB | 13.1–13.3 GB/s | — |
| pinned ↔ device, 128 KiB | 7.7–8.5 GB/s | — |
| sysfs link state (idle *and* under load) | reports `2.5 GT/s x1` — **wrong**, ignore it | trains to Gen4 ×8 |
| job = submit + `.wait()` | **24.8 µs** | `cudaMemcpy`+sync, same order |
| job = submit + flag polled by host | **5.0–6.3 µs** (empty kernel) | handshake round trip 6.4 µs (memops) |
| 16 KiB in via DMA, then flag | 7.6–8.9 µs | `copy_` 3.5–4.7 µs |
| 16 KiB in via kernel loads, 4096 lanes | 8.1–10.7 µs | — |
| 16 KiB in via kernel loads, 1 dependent lane chain | **258–283 µs** | — |
| 16 KiB out via kernel stores + flag | 7.0–9.0 µs | collect kernel 4.0 µs |
| resident kernel doorbell round trip (1 poller, fenced) | **3.2 µs** (mean, 200 rounds; best 2.8) | memop round trip 6.4 µs |
| board power at idle (no context) | 14.6 W | — |
| board power idle *with a live SYCL context* | 45.6 W | — |
| power cap | 275 W (`power1_cap`), energy counter in µJ | — |
| board power under **sustained decode** | **~285 W mean, 294–306 W peaks** at 97–100% compute, 54% of DRAM bandwidth — the part is power-capped, with ~1% clock droop; kernel time drifts **+0.5% over 150 s** | — |
| idle clock, and why it matters | idles at **1200 MHz**, needs ~40 ms of continuous work to leave it: the same kernel reads 44.0 µs at 1200 MHz and 19.2 µs once ramped (**2.2–2.3x**), which explains the historic cross-window swings | — |
| device L2 | **24 MiB** (`devinfo`) — quote working-set size next to any "effective GB/s"; an E=10 case is 5.9 MiB and its rate is partly cache | — |
| quantization vs decode **time** | nearly free at small resident sets: K = 2 → 6 (3x bytes) costs **+3%** at rows=1; it costs VRAM, admission transfer and energy instead (`out_quant_ladder.txt`) | — |
| device-wide barrier (atomic spin, all work-items) | **1.6 µs @256 · 2.5 µs @1024 · 6.2 µs @2048**; illegal-by-API beyond 2048 and 16–20 µs/barrier there — so **launches (~2.9 µs) are cheaper than in-kernel coordination** (`out_e25c_barrier.txt`) | — |
| when to fuse gate+up | two independent conditions, both implemented in `plan_decode_cost.best_launch()`: **(a)** the separate launches leave slots empty (gain 1.6–1.9x, gone at fill), and **(b)** the fused footprint `2·E·bytes` stays under L2 — between the crossovers (E ≈ 20–41 for gate at K=3) fusion **costs** up to 1.27x, because a fused launch holds both weight streams at once (`out_ks_grid.txt`) | — |
| CPU home (`S_c`) regime | **compute-bound** on Qwen3.8 (L3 residency buys 15%, 37.9 GiB/s ceiling, 39.2 → 23.0 µs per assignment over b=1..16); **bandwidth-leaning** on GLM (68 GiB/s warm, saturates at ~8 threads) (`out_cpu_worker_calib.txt`, `out_glm_cpu_calib.txt`) | — |
| `cudaHostRegister` on `sycl::malloc_host` memory | **fails** (`invalid argument`) | — |
| `sycl::atomic_ref` (any scope) on a `register_host_memory` pointer | **device lost** (`UR_RESULT_ERROR_DEVICE_LOST`); plain stores and fenced volatile stores are fine | — |
| engine in a child process, region registered in both | **works**: kernel payload visible to parent and to a 3090 DMA, 3090 memop visible to a kernel in the child | — |
| `register_host_memory` on CUDA-pinned memory | **works**, kernel reads+writes it, 3090 still DMAs it | — |
| 3090 `cuStreamWriteValue32` → B70 kernel sees it | **works** | — |
| B70 kernel store → 3090 `cuStreamWaitValue32` retires | **works** (plain volatile store + `sycl::atomic_fence(acq_rel, system)`) | — |
| device | 256 CUs reported, SG 16/32, SLM 128 KiB, 1024 max WG | — |
| **decode tile walk, native order** | **132–292 GB/s** scattered (Qwen3.8), **132–260** (GLM) — 22–48 % of 608; the spread is working-set size, not code | single-point rates are not card constants: `out_rates_footprint.txt` |
| same, consecutive work-items on consecutive tiles | **216–558 GB/s**; `LOCALITY payoff` **1.08–1.99×**, never negative | the CPU's band-8 repack exists for this reason; here the GPU analogue is grid order |
| same tiles, banded/repacked order | **0.96–1.05×** vs native, no consistent sign, and the probe's configuration variance exceeds the effect → E4c re-tests it in situ | band-2/band-8 + planar is worth ~20 % on x86 |
| mul1 decode arithmetic at real density (+47 lane-inst per 128 B of stream) | **−0.1 %** (GLM) to **−4.4 %** (Qwen3.8) of bandwidth at 1 GiB; up to **−14 %** at a 64 MiB footprint | decode is bandwidth-bound, with less margin at small footprints |
| hardware int8 dot vs manual byte-sum | **0.2–0.4 %** apart over three independent runs: not measurable | `vpdpbusd` vs `vpmaddubsw` fallback is a real gap on x86 |
| accumulator dependency | splitting into 8 chains is **1.2–1.4 % slower**, so the density cost is instruction count / register pressure, not latency | R9 exists to kill that explanation |
| what the 3090 must really hold | streamed non-expert **4.05 GiB** (Qwen3.8) / **5.67** (GLM); KV **22–24 KiB/token**; recurrent state **108–136 MiB per sequence**; Qwen3.8's **49.91 GiB** of n-gram tables are host row-gathers (`ngram_gather_cpu`), **not VRAM** → **~16.6 GiB free for experts** at 4k ctx, b=1 | the plan's 2 GiB slice was 8× too stingy |
| effect of the corrected slice | Qwen3.8@2.68 `h` 97.6 → **100.0 %** (CPU residue gone); GLM 70.8 → **81.1 %**, CPU 19.6 → 12.6 ms/token | bigger than any hot/cold ordering effect measured |
| parent bandwidth duty at b=1 | 86.4 MiB/layer of non-expert streaming = 97 µs of a ~250 µs window → **~39 %**: the 3090 is latency-bound, not bandwidth-bound, at small batch | the ~570 GB/s "spare" is inferred from the byte bill; **E18 measures it** |
| fair split vs hottest first | tie at b=1; **fair split +13 %** at Qwen3.8 b=8; **hottest-first +9…+20 %** on GLM while a CPU residue exists | the objective is the per-layer **max**, with `S_g` serial and `S_b`/`S_c` concurrent, so which rule wins depends on which term binds |
| placement across recipes | fair-split wins at b=8 for 2.05/2.68/4.05/5.05 bpw (+3…+9 %); **hottest-first wins +43 % at 6.05 bpw** — the one recipe with a real (9.6 %) CPU residue | the `EXL3_MOE_B70_BALANCE` rule picks the right side of the boundary on all five |
| parent duty is recipe-independent | 69–101 MiB/layer of streamed non-expert weights, 31–45 % bandwidth duty, at **every** Qwen3.8 quant | the recipe holds attention/embeddings near fixed width; my "duty reaches 83 % at 6.05 bpw" guess was ~2× wrong |
| higher-K tile rates | K = 4/5/6 scattered 207–295 GB/s, clustered 224–522 — same band as K = 2.5/3.0; banding turns mildly **positive** (1.06–1.07×) at K = 5/6 | one K=6 row read 754 GB/s (above the 674 copy peak) and was discarded, `LESSONS` 21 |
| concurrency: who binds | parent binds only at b ≤ 4; the **B70 binds from b≈4–8 to 256** (its bytes are already deduplicated: an expert is read once per layer per step however many rows picked it) | aggregate tok/s 83 → 307 → 435 → 1739 (2.68 bpw) and 83 → 156 → 246 → 1084 (6.05 bpw) at b = 1/8/32/256 |
| prefill is memory-bound too | XMX crossover is (367 TOPS/2)/674 GB/s = **272 rows on the same expert**; at R=2048 the hottest Qwen3.8 expert gets 41–522 rows and **0–13 of 512 experts qualify**; 60–115 qualify only at R=8192 | the `b70-kernels.md` §1 figure of "~64 rows/expert" was a projection; this is measured |
| rescue from a large-`rows` schedule | **1.54×/1.49×/1.64×/1.46×** at b = 8/32/128/256 (2.68 bpw, 307→474 … 1739→2531 tok/s); only **1.15–1.38×** at 6.05 bpw; **1.00× at b=4** because the parent already binds | the win is grid order (clustered rate), not compute: rows/expert peaks at 5–6 vs the 272-row XMX crossover |
| activation path at large b | `rows·H` int8 down + `rows·topk·H·sz_out` up at 14.4 GB/s = **31 %** of B70 time at b=256 (17 % at b=128) | this is where `OUT_F16` and B70-side partial summation (10 partials → 1) stop being optional |
| **what binds a real decode GEMV** | **instructions per weight**, not bandwidth: 17 ops → 27.9 GB/s, 8 ops → **61.4 GB/s** (R = 1, 300 MiB), against 292 GB/s for the same bytes with no arithmetic; rows cost ~4 instructions each (13.8 / 4.6 GB/s at R = 8 / 32) | an instruction-budget model (1.43·10¹² SIMD inst/s) predicts both within 10 % — so the fix is known, not hunted |
| what the shipped kernels spend | CUDA: 2 loads per 4–8 windows, 1 `fshift` per window, **1 `dp4a_us(prod, splat(a), acc)` per weight-row**; CPU: `vpdpbusd` per 16 weights, and i16 byte-sums so one `vpmaddwd` serves **2 rows** | transplant both; `sycl/ext/oneapi/dot_product.hpp` has `dot_acc` (u32×u32 + mixed-sign vec<u8,4>) in this toolchain, but SYCL has **no funnel shift** — use the `(hi<<s) \| (lo>>(32-s))` idiom or CUDA's fixed-shift chain |
| reference kernels in-tree | `doc/b70/llm-scaler/sglang/custom-esimd-kernels/csrc/` — Intel ESIMD MoE kernels for this card generation: grouped Q4_K/Q5_K/Q6_K GGEMV, batched decode GEMV, DPAS prefill, fused topk/gather, with perf post-mortem comments | their numbers: **~180 GB/s** for a fixed decode GEMV, "ALU bound, not bandwidth bound", `M=8/VL=256` won't compile, grid M-tile-fastest for L2 reuse — all in `doc/port/b70-kernels.md` §2b |
| routing breadth (from real selection counts) | Qwen3.8@2.68: 97.6 % of picks in 411/512 experts; GLM: 70.8 % in 91/288 (effective support 213–231) | the profile is a decayed cumulative, so both are upper bounds |
| **what one decode layer actually reads** | `topk` (10 Qwen3.8 / 8 GLM, from `config.json`) unioned over rows × `h`: **14.3 MiB** (Qwen3.8 b=1) and **50.9 MiB** (GLM b=1) — 2 orders below the checkpoint | this is the footprint the rate curve must be sampled at (`plan_operating_point.py`), and it is why "GB/s" alone never answered the decode question |
| decode µs/layer at the matched footprint | Qwen3.8 **51** (27 clustered, ~5× inside the 250 µs parent window); GLM **405** (247 clustered) | GLM's 9 MiB experts land on the curve's worst point (132 GB/s) |
| batch is the real variable | Qwen3.8 margin 4.9× → 1.3× → 0.5× over b = 1 → 4 → 8: distinct experts per layer grow ~linearly with rows while the parent window is weight-bound | "offload hides at decode" is a small-batch claim |
| tiers are parallel, so combine by max | GLM 1 card is CPU-bound (467 µs/layer), 2 cards parent-bound (300 µs assumed), 3 cards add **nothing** unless `T_parent` < 135 µs — and the measured Qwen parent floor (122 µs) **is** below that, so the zero is an artifact of the assumed 300, not of the hardware | summing worker ms/token double-counts and hides the ceiling |
| the fusion penalty band is rows-independent at its edges, deeper at small rows | worst gain 0.76× (E=32) at rows=1 → 0.90× at rows=16; no (E, rows) pair flipped its preference; best fused KS falls 4→2→1 as rows grow → take **one** fusion decision per (model, quant), at rows=1, which is conservative for every batch (`out_fusion_rows.txt`) | people re-decide per batch shape, or assume a rows=1 band applies equally at rows=16 |
| at b=1 the quant is invisible in throughput | all five Qwen3.8 quants give 80–81 t/s (calibrated parent) or 171 t/s (measured floor), because the B70's whole contribution is 36–42 µs of a 122–259 µs/layer step; the card only matters from b≈4–8 | quoting per-quant decode t/s at b=1 quotes the parent, not the card (`out_throughput_report.txt`) |
| at b≥16, routing concentration outranks bits-per-weight | 5.05 bpw beats 2.05 bpw (761 vs 677 t/s at b=16, 1058 vs 872 at b=32) with 2.5× the bytes/expert, because its distinct-expert union is narrower (94.8 vs 107.1 at b=16); 6.05 is CPU-capped from b=2 by placement, not hardware | assuming smaller quant ⇒ faster at batch |
| the parent's expert leg is kernel-bound, not bandwidth-bound | ~190 GB/s flat across b=1..16 (170–215); streamed reads 860 GB/s, not the 936 spec | a byte rate is an upper bound on traffic, not a rate to charge a kernel with; the spec figure is not even what the card delivers (`out_parent_leg.txt`) |
| **the parent's non-expert cost is engine-measured: 141.9 / 195.6 µs/layer** (2.05 / 2.68, b=1 ctx 4k) | supersedes both earlier estimates — the 122 µs microbench floor and the 259 µs window-calibrated figure — and explains each error: the floor missed hyper-connections and over-priced attention 3×, the calibrated figure bundles stalls and per-token overheads | charge `PARENT_ENGINE_US` (level measured, shape anchored, `^` where extrapolated); never a byte model, on this architecture (`out_engine_step.txt`, D11) |
| hyper-connections cost ~83 µs/layer and sit in no model | `hc_mix.cu` (gr_dots / gr_finalize / hc_apply) is 42–43% of the parent's own non-expert work on Qwen3.8 and ~7 µs/layer on a model without them | after the experts move, this is the biggest remaining single-stream lever — and offloading cannot touch it |
| the plan's `union(rows)` was ~2× too high by b=32 | measured 10.35× topk vs 21.91× carried; independence itself is accurate to ~1.5% on real cross-session draws, so the input distribution — not the math — was wrong | trace per layer, aggregate per layer, keep the formula (`out_live_trace.txt`, D12, LESSONS 63/64) |
| today's CPU path does not scale with concurrency | 58.3 tok/s at b=1 → 33.2 at b=2, flat to b=16 (Qwen3.8@2.68, `-mcs 384`, 15 threads) | quote gains at matched batch; a b=1 baseline against modelled b=16 is 28× mostly baseline collapse (`out_engine_step.txt` §8, D13) |
| `-mcpa` buys placement mobility, not speed; `-mct` is clamped by the pin set | plain mode: **0** expert promotions; `-mcpa`: 3,689 — and short-run decode cost (71.8 → 63.0 tok/s) is repaid by pass 2 (parity). `-mct 32` on 16 pinned LPs is 1.82× worse than `-mct 16` | judge adaptive designs on the adaptation horizon; default threads to the LP allocation minus one, never to nproc (LESSONS 66) |

Read as: the B70's link is not the problem (it is a shade faster than the 3090's on this box),
and its compute is not the problem either (roughly 10x the CPU worker's expert-read rate). Two things
are load-bearing. The first is **how a job is published and how completion is observed**: anything
that costs 24 µs (`.wait()`, or a second `register_host_memory` per job) will dominate a 25 µs compute
job, while 5 µs (flag-poll) or 3 µs (resident doorbell) hides behind the parent's ~165 µs/layer of
decode work. The second is **memory ordering inside the card**: the same bytes read at 287 or at
490 GB/s depending on how work-items map to tiles, which is a bigger effect than any layout choice
and is why `doc/port/b70-kernels.md` §3a is normative rather than advisory.
