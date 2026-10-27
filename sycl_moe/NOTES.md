# SYCL / Level Zero MoE offload — notes

Offload the CPU MoE expert worker to an Intel Arc Pro B70 (SYCL/Level Zero) behind a dlopened
plugin; main model stays on the RTX 3090. **Usage, env knobs, build, benchmarks: `README.md`.
Code map: `README.md` "Design map". Everything else — the derivation log, evidence, lab
inventory — lives in [`archive/`](archive/INDEX.md). This file is only what you must know before
editing: current state, standing rules, traps, decisions, levers.**

## State (2026-10-27)

Shipped and gated: fp32 scalar-semantics tier (`GemvK`, all 11 contract rates compile-time
specialized) + int8/XMX DPAS tier (auto for rows≥2) + per-layer weight ARENA with threaded upload
+ process-wide workspace pool + three-tier placement (`SUB`) + `-mcpa` anti-theft + I8RING A
staging + MAXM=8 chunks + slim decode kernel + fused prep/quant + owner-gather K6 + counter-fed
fused DOWN (`COOP`, default on) + poison-latch fault containment + full-rate specialization.

| model | config | CPU worker | B70 |
|---|---|---|---|
| 2.05bpw | `-mcs256` | ~1456-1511 pre / 68-70 dec | 1850-1886 pre (+25%) / 70-72 dec |
| 2.68bpw | guarded auto, `-mcs384-448` | 40.2 dec | 59-60 dec (+47%) / 512-562 pre (pre-guard regime: 748/53.3) |
| 4.05bpw | `-mcs448 SUB=0.5 st4` | 226 pre / 24.9 dec (37.5 with pinned streaming) | 598-606 pre / 54-58 dec (**dec ~2.1-2.3x**, 19-21 of 48 layers resident) |
| 4.18bpw hybrid K2{8,10} | `SUB=0.5` warm | — | 807 pre / 43.5 dec |

Accuracy: float tier xval **6.04e-7** rms vs the real CPU scalar ext (6.53e-7 with coop-D),
int8 tier **1.36e-3**, ppl Δ ≤ 0.25% on all three models (`archive/measurements-ledger.md`).
Decode is not MoE-bound on 2.05: the whole b70 path is ~10% of the 14.2 ms/token budget.

Plateau: prefill is bounded by the **Gen4 x8 link (13.4 GB/s measured, both cards)** and the
3090's streamed reconstruct; decode by 3090 graph-replay overhead. Software knobs (mcs,
stream_t, WSLOTS, guards, overlap) are all at measured optima — see
`archive/placement-policy.md` before proposing a new one.

## Environment

- Host: 5950X (AVX2 only) + RTX 3090 + Arc Pro B70 (32 GB, 608 GB/s, 32 Xe2, subgroup 16, XMX).
- **`source sycl_moe/env.sh` before ANY torch-ext python** (JIT hash consistency + gcc-15 shim;
  without it a full 190-file CUDA rebuild dies in ninja — system g++ 16 vs nvcc ≤15).
- Build flags are *correctness*, not speed: `-O3 -ffp-contract=off -foffload-fp32-prec-div`.
  Otherwise device approx-div + FMA contraction flip int8 quant ties vs host (±1 x8; uniform
  probes hide it, `--i8trace` stage B catches it).

## Measurement rules (violating any of these produced a false result here)

1. **Clock ramp inverts Xe2 rankings.** Burn in ≥1.5 s, interleave variants, min-of-3, and use
   ≥1000 iterations in-process for anything profiled. Short benches lie.
2. **Never A/B under a profiler** (`--v`, `enable_profiling`, VTune spans): ~40 µs inflation per
   6-kernel pipeline. Spans are for diagnosis; sum-of-spans ≠ reachable time (~8 µs/boundary).
3. **Pin the auto tier** (`EXL3_MOE_B70_INT8=0/1`) in tier A/Bs; with auto on, controls silently
   ran the treatment.
4. **Ablations must not delete work.** `#if`-gated variant blocks skipped half the loop and
   "won" by 40%. Toggle a runtime flag in always-coded source, or diff the asm.
5. Anything measured through `b70_forward` before the wake-first wait fix (`efc7244d`) carries
   ±70 µs of poll slop — re-measure before trusting deltas <15%.
6. **Model gates run TWICE, score the second.** VRAM-reclaim lag under-registers (first run after
   a big GPU job loses tens of GB → layers silently on CPU); 90-120 s gaps do not prevent it.
   Check `registered=/fallback=` per run. If decode is ~0.6x of record but registrations match,
   that is thermal throttling: cool 3 min, rerun.
7. Noise floors: decode ±3% (≥1 t/s is real), prefill ±3.5% (needs 3 reps), synthetic <10 µs = air.
8. Never trust a piped build rc or a log you did not confirm exists; two "results" came from
   stale binaries, one campaign narrated a sweep that had not run.

## Verification rules

1. Compare the device against the **SPEC** (host reference / `moe_host_ref.hpp`), never
   sim-vs-device and never a reference recomputed from the kernel's own dumps (circular).
   Independent checkers are written from the FORMAT spec — the t30 harness encoded the kernel's
   own window formula and blessed a shared misconception.
2. Validate layouts on random data from the FIXED splitmix RNG (`exl3ref::Rng`); xorshift's slow
   start silently vacuomed tests. Treat "0 bad" as suspect until you prove the reference non-trivial.
3. **Kernels contain ZERO debug hooks.** In-kernel scaffolding measured its own pollution
   (flag-slot clobbering, probes bypassing the datapath). Verify externally: readback + host
   emulation per stage, each stage fed from device readbacks of its OWN inputs.
4. Use uniform/A=1-style algebraic probes to isolate DPAS stages (`archive/int8-dpas-tier.md`),
   and random SIGNED data to expose splat/rounding bugs fast.
5. Judge int8 by **rms ≤ 3%**, not max_rel; judge coop changes by bit-parity of the summation
   order (that is why owner-gather replaced atomics).
6. After any multi-line edit, diff the RESULT against intent — an anchor echo once deleted an
   unrelated write and cost a "the compiler broke my struct" bisect.
7. `test_arena_update.py` + `bench_b70_py.py` rms are the gate after ANY upload/C-ABI change;
   model runs never exercise `b70_update_expert` (tier guard), so nothing else does.

## Top platform traps (full list: [`archive/platform-pitfalls.md`](archive/platform-pitfalls.md))

- **P1 ordering**: on this stack an in-order queue does NOT serialize `q.memcpy` after
  `q.submit` kernels; only explicit `depends_on`/`{deps}` edges are honored. "Retry/probe/second
  call fixes it" = a missing dependency edge, check that before any cache theory. Harnesses must
  chain exactly like production.
- **P3/P4/P5 memory**: `malloc_device` does not fail near capacity (async OOM throws across the C
  ABI); host writes into device USM segfault; `q.copy(a,b)` is `(Source,Dest)`, so a "readback"
  spelled the obvious way overwrites what you meant to read.
  Budget check + alloc-before-copy rollback + catch-to-pin + poison latch are the defense.
- **P6 nd_range**: groups = global/local. The "16x grid inflation bug" was never a bug; the fake
  fix silently dropped 15/16 of the slices.
- **P7 barriers**: a wg barrier is not a device-scope fence — publication needs
  `it.barrier(access::fence_space::global_space)`. Split kernels hide this (boundaries flush).
- **P8/P9 joint_matrix**: B must be `ext_intel_packed` (VNNI) or fixups eat the budget;
  collectives need convergent control flow; **the global A load lowers to a per-lane byte gather
  worth 2.8x the kernel** (hence I8RING); operand addresses must be 64B-clean or the device dies;
  `stride*sizeof(T) % 8 == 0`.
- **P10**: cache hints (`read_hint`/annotated_ptr) never demonstrated an effect — use device-scope
  relaxed atomic loads for cross-WG same-launch reads (`coop_load`); large GRF is -25%;
  `IGC_JointMatrixLoadStoreOpt=1` forces the slower path; per-tile WG barriers lose to global loads.
- **P11/P12**: nsl>8 unsized (nsl>12 crashes); a bad `ONEAPI_DEVICE_SELECTOR` aborts in adapter
  static init (uncatchable); queue needs an `async_handler`; kernel build failures surface at
  first launch; runtime gates get DCE'd out of microbenches.
- **P13**: python `.replace()` patches silently no-op on hallucinated anchors; assert anchors, or
  use the edit tool.

## Format facts at hand (full spec: [`archive/mul1-trellis-spec.md`](archive/mul1-trellis-spec.md))

- `K2 = 2*bits + hb`; contract universe `{2,3,4,5,6,7,8,10,12,14,16}` (halves only ≤3.5, bits ≤8);
  both tiers specialize all 11; out-of-contract → `GemvFallback`; int8 never silently misses a kernel.
- Stream repack = per-tile u32 WORD REVERSAL; `state(t)` = 16 ascending bits at
  `P0 - ((K2*t + (K2&1))>>1)`, `P0 = 32-K2/2`. **Mask to 16 bits** — the original garbage bug.
- `w = k_inv*(bytesum(state*0x83DCD12D) - 510)`, `k_inv = 0.00676727294921875`;
  int8 form `bs = 510 + w/k_inv`, `C = Σx8·bs = w-dot + 510·Σx8` (fold in the epilogue affine).
- **`x8 * 0x01010101` does NOT splat negatives** (`-1*0x01010101 = 0xFEFEFEFF`): mask `& 0xff`
  first. This one cost multiple sessions (the "1.014*want - 475925" fingerprint).
- `HAD_SCALE = 1/sqrt(128)`; gateless = relu2 on up only; MAXM=8 int8 chunks vs 4 for fp32.

## Cheapest honest check before committing a change

```bash
source sycl_moe/env.sh
# build plugin + harness with the README flags (fp flags are not optional)
./bench_layer --e 12 --rows 1 --topk 10 --iters 50            # fp32 vs host ref (~3e-6)
EXL3_MOE_B70_INT8=1 ./bench_layer --e 16 --rows 8 --i8trace   # stages B..G must all print OK
./bench_layer --load xval_s                                   # rms vs the real extension
python3 test_arena_update.py ../xval_s                        # only after upload/C-ABI changes
```

Then, if perf-relevant: sustained interleaved A/B (burn-in, min-of-3, pinned tier); if
model-visible: `ppl.py` + `perf.py` run TWICE, scored off the second. Flags + tool details:
`archive/tools-and-harness.md`.

## Standing decisions

- Tier auto: **int8 iff rows ≥ 2**, float at rows=1 (float ~9% ahead at m=1: Xe2 DPAS min m=8,
  15/16 rows wasted, and joint_matrix fetches all 8 A rows regardless). Do not "fix" m=1 int8.
- Fat int8 kernel always runs BOTH m8 fragments and always zero-fills 16 rows — a branch/peel to
  skip frag1 poisons the unrolled schedule (-20% on the fat path to gain 22% narrow). Narrow-only
  work means a separate compile-time kernel (that's the slim one, `EXL3_MOE_I8SLIM`).
- Weights: one arena per layer, native tile layout stream-repacked at upload, never expanded
  (0.5 B/weight); installs are atomic in-place block overwrites; data pointers never move.
- Workspace pool: process-wide, rebound on EVERY forward (`grow_p` is a pure rebind when it fits),
  grown in 64-chunk steps, excluded from the registration budget, and deliberately NOT
  preallocated to the worst case. `cap_rows` default 128 (512 is safe post-fix in the float/h6
  regimes; awaiting a cool-box A/B to raise it).
- Placement: default = cold/sparse experts on B70 (`SUB=auto` when oversubscribed), guard on
  (decode-weighted), stream_t auto probe. Hot experts on B70 measured WORSE (-18% prefill):
  per hot pick the 3090's streamed path is ~5x cheaper. `EXL3_MOE_CPU_SWAP_TIER=0` is the
  documented prefill-priority escape hatch.
- Never offload all experts (`-mcs 512` on this box = unsupported: zero GPU-resident experts).

## Levers, ranked (with what's already known)

1. **Counter-fed GU fusion** (`CoopGuK` built, parked neutral): retry only bundled with an NSL_GU
   retune measured on real 4.05 decode (C-ABI prefers 2, bench prefers 7 — a wave cliff at 3) and
   per-(entry) 2-arrival units. Summation order must stay bit-identical.
2. **Native-L0 submission** — `PLAN_L0.md`, feasibility proven, single blocker (SLM binding for the
   `local_accessor` arg is invisible on the public ze surface); first move is a `-DMOE_L0_NO_SLM`
   global-scratch SPV variant, measured. Worth less than it looked after the polling fix.
3. **DPAS kernel-side prefill gap**: E128/rows128 2354 µs (post-ring) vs a ~250 µs distinct-expert
   DRAM floor — latency/scheduling-bound at m8n16k32. esimd `xmx::dpas` (t40) removes the gather
   and the ring barriers in one move, best combined with MAXM 16/32 wide-M instantiation. This is
   also the precondition for hot-expert placement ever paying.
4. **B70-side weight streaming into tier slots** (update+evict protocol) — the only way to beat
   748-era prefill *with* the decode gains; real cache-protocol work.
5. Hardware: fix the PCIe lane bifurcation (3090 at x8) → prefill lifts directly.
6. Small/parked: RING for slim kernels (~10 lines, rows2-4 only); split-K retune after ring;
   K34i8+Q2 fusion (~-10 µs decode); int8 wide-row pairing; error-feedback int8 for quality
   headroom. Full rationale: `archive/int8-dpas-tier.md`, `archive/decode-command-latency.md`.

Dead ends — do not re-litigate (evidence in `archive/kernel-microopt.md`, `archive/int8-dpas-tier.md`,
`archive/decode-command-latency.md`): dp4a/esimd in generic kernels, `dot_acc` ext, col-major
joint_matrix B, coalesced word loads + `select_from_group`, megakernel-with-grid-barriers, flat
bytesum tree, `-510` folding, large GRF, annotated_ptr hints, 128-lane WGs without ring,
`(tk&3)`-array depth-4 prefetch, worst-case pool preallocation, hot-expert→B70 placement,
`-mcs 512`, `std::async` mixed-job overlap at small tiers.

## Also

- `PLAN_L0.md` — scoped native-L0 v1 (int8 decode chain), gates and footguns.
- `archive/INDEX.md` — what's where, symptom→page lookup, provenance of this rewrite.