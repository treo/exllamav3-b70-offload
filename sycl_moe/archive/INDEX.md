# Archive index

Detailed working log for the B70 MoE offload, split out of `../NOTES.md` (which now holds only
what you must know before editing). Nothing here is required reading; each file is the evidence
trail behind a decision, a trap, or a number.

| file | contents | read it when |
|---|---|---|
| [`mul1-trellis-spec.md`](mul1-trellis-spec.md) | target models + VRAM math, trellis tile packing, `decode_state` bit law, dequant identity, layer-forward semantics, the GPU **stream layout** proof, integer/DPAS identities, CPU quant semantics, **the bitrate contract** (K2 set), rate-coverage + specialization cost model | touching bit extraction, repack, a new rate, or a quantization scale |
| [`platform-pitfalls.md`](platform-pitfalls.md) | P1-P14: queue ordering (the one-day bug), probe-as-queue-op, device-OOM governance, USM host-write segfault, `q.copy` order, nd_range math, barrier ≠ fence, jm alignment, joint_matrix/DPAS facts, useless hints & switches, nsl bounds, adapter ergonomics (`ONEAPI_DEVICE_SELECTOR`, `async_handler`, `parallel_for` returns void), editing/harness traps, Windows notes | anything async, any "impossible" result, any allocation or barrier change |
| [`measurement-discipline.md`](measurement-discipline.md) | clock ramp, profiler inflation, spans vs sustained, the 20 µs **polling quantum** (+70 µs everywhere), VTune spawn/PMU constraints, ablation-with-toggles, VRAM-reclaim + thermal ghosts, noise floors, reference-provenance rules, bookkeeping habits | before quoting, believing, or acting on a number |
| [`kernel-microopt.md`](kernel-microopt.md) | float-gemv cost anatomy (address arithmetic > loads, issue-rate wall, `MMA` template), adopted changes (funnel shifts, K3+K4 fusion, split-K caps + fill targets, depth-4 done right, PKA pair-decode), the rejected list with numbers (coalesced loads + shuffles, flat bytesum, -510 fold, wide WGs, jb-from-global), plateau analysis | optimizing either gemv, or re-proposing a micro-optimization |
| [`int8-dpas-tier.md`](int8-dpas-tier.md) | the whole DPAS arc: dead ends, the `ext_intel_packed` VNNI key, lab_jm7/jm8 invariants, the baseline reset + "zero debug hooks" policy, the **negative-splat root cause**, design as shipped (a8/qsx/acc layouts, always-wide quant, affine fold, split-K), tier-policy history + current rule, MAXM=8 (+ the frag1-skip reversal), the slim kernel, the corrected prefill roofline → **I8RING**, esimd endgame, remaining gaps vs the CPU tier | working on the int8 tier, staging, chunk width, or tier selection |
| [`decode-command-latency.md`](decode-command-latency.md) | why rows=1 time is work-independent, floor budget breakdown, owner-gather K6, fused prep+quant, counter-fed fused DOWN (shipped) + parked CoopGuK, **CUDA small-m doctrine** (QTIP gemv, `exl3_moe_coop` two-launch chaining), megakernel post-mortem (why phase-sync starves), native-L0 feasibility + the SLM-binding blocker | reducing decode latency, merging/splitting kernels, or starting `PLAN_L0.md` |
| [`placement-policy.md`](placement-policy.md) | hardware link truths, `cap_rows` vs `MAXM` vs micro-batch hierarchy, why default placement is the economic optimum (hot→B70 loses 18%), the three-tier `SUB` campaign, `stream_t` × tier interaction, the guard trade-off fork + recommended defaults, the mcs/stream_t/WSLOTS sweeps that confirmed them, per-class recipes | changing placement, tiers, streaming, or `-mcs` recommendations |
| [`memory-and-registration.md`](memory-and-registration.md) | budget/rollback/poison-latch design, budget calibration, CUDA-inspired **per-layer arena** + threaded fill (phase timings, the by-reference capture trap), why the pool is NOT preallocated, the **STALE POOL POINTER** root-cause writeup + `attrib_faults.py` forensics method, precursor open-bug entries, arena verification matrix | touching allocation, registration, updates, workspace sizing, or a DEVICE_LOST/pin cascade |
| [`measurements-ledger.md`](measurements-ledger.md) | device constants, model end-state table, ppl quality gates (float + int8), xval numbers, sustained tier A/B tables, C-ABI per-forward table (incl. which entries are VOID), synthetic pipeline history, registration cost | picking a number to quote |
| [`tools-and-harness.md`](tools-and-harness.md) | production file roles, `bench_layer` flags + **the harness bugs** (the trace was not an innocent arbiter), python tools table, lab-by-lab inventory (what t3..t46 / lab_* each settled), build recipes | running anything, or wondering whether a lab already exists |

## Symptom → where to look

| symptom | page |
|---|---|
| first forward wrong, later right; "retry fixes it"; reads back zeros | `platform-pitfalls.md` P1 |
| results byte-identical to the previous run/dataset | P1 (harness race) — the coop counter zone was re-zeroed |
| async `UR_RESULT_ERROR_OUT_OF_DEVICE_MEMORY`, worker killed, parent spins forever | P3 (+ `memory-and-registration.md` poison latch) |
| segfault writing a buffer from host | P4 |
| results clobbered after a "readback" | P5 (`q.copy` direction) |
| only slice 0 alive / 40-60% of values missing after a grid edit | P6 |
| partial sums with deterministic-looking ratios in a multi-phase kernel | P7 |
| device loss / fault at certain nsl or jm load offsets | P8 (+ `kernel-microopt.md` jb-from-global) |
| wrong bytesums from `dp4a`; 512 B/lane materialization; slow `joint_matrix` | P9, `int8-dpas-tier.md` |
| int8 dot products off by small scale + constant offset | `int8-dpas-tier.md` (negative splat) |
| ±1 x8 quantization mismatches only on some builds | `platform-pitfalls.md` P10 (fp flags) |
| microbench winner flips between runs | `measurement-discipline.md` (clock ramp) |
| suspicious 40 µs "win" from a variant | `measurement-discipline.md` (gated blocks skip work) |
| layers registered = 0 / few; decode or prefill ~0.6x of record | `measurement-discipline.md` (reclaim lag, thermal) |
| DEVICE_LOST at `cap_rows>=512`, only after a big prefill, on a small job | `memory-and-registration.md` (STALE POOL POINTER) |
| rms 0.41 after an upload change, no error logged | `memory-and-registration.md` (by-reference lambda capture) |
| "0 bad" / too-clean verification | `measurement-discipline.md` (RNG + reference non-triviality) |
| int8 vs fp32 A/B shows ratio 1.000 | `measurement-discipline.md` (auto tier unpinned) |
| rms 1.38e-2 on a gateless xval | `tools-and-harness.md` (missing `--scalar` = AVX2 reference) |
| `malloc(): invalid size` during a probe run | `tools-and-harness.md` (probe buffer sizing) |
| hot experts on B70 "give" +21% prefill | `placement-policy.md` (that was the fatal-refusal bug) |

## Provenance

`../NOTES.md` was consolidated on 2026-10-27 from a 1430-line chronological log (104 KB). The
verbatim original — including its session ordering, which is what the commit messages cite — is
`git show 5d054061:sycl_moe/NOTES.md`. Facts were redistributed, not rewritten; anything that
contradicts this archive is a newer measurement and should be re-verified before either file is
trusted. Superseded claims are marked as such in place (e.g. `-O3` crashes, the "13x off DRAM
floor" roofline, the ~24% m=1 int8 gap, the "6-kernel" pipeline count, `int8 iff some chunk m>=2`).