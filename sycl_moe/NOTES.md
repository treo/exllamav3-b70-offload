# SYCL / Level Zero MoE offload — notes

Offload the CPU MoE expert worker to an Intel Arc Pro B70 (SYCL/Level Zero) behind a dlopened
plugin; main model stays on the RTX 3090. **Usage, env knobs, build, benchmarks: `README.md`.
Code map: `README.md` "Design map". Everything else — the derivation log, evidence, lab
inventory — lives in [`archive/`](archive/INDEX.md). This file is only what you must know before
editing: current state, standing rules, traps, decisions, levers.**

## State (2026-10-28, night)

Shipped and gated: fp32 scalar-semantics tier (`GemvK`, all 11 contract rates compile-time
specialized) + int8/XMX DPAS tier (auto for rows≥2) + per-layer weight ARENA with threaded upload
+ process-wide workspace pool + three-tier placement (`SUB`) + `-mcpa` hot-pick streaming
(replaces the old anti-theft block, see Standing decisions) + I8RING A
staging + MAXM=8 chunks + **fragment bucketing** (`BUCKET`, CUDA m-tile-ladder doctrine)
+ slim decode kernel + fused prep/quant + owner-gather K6 + counter-fed
fused DOWN (`COOP`, default on) + poison-latch fault containment + full-rate specialization
+ **n-major arena tile order** + all chunk/fragment geometry derived from one header
(`moe_layout.hpp`) + **device-tier prefill split** (`STREAM_T_DEV`/`SLOT_ROWS_DEV`: the B70 takes
the cold experts as few large jobs while the 3090 streams the hot ones).

2.05bpw prefill, same box, same flags (`-mcs 256 -ngr -mct 15 -mcpa`, `perf.py --max_length 4096`),
reps in `archive/measurements-ledger.md`:

| arm | prefill 256 / 512 / 1024 / 2048 / 4096 | decode |
|---|---|---|
| CPU worker (the bar to beat) | – / – / 1179-1180 / 1559-1616 / 1840-1960 | 64 |
| B70, classic anti-theft (fully registered ⇒ nothing streams) | – / – / 971-986 / 1102-1114 / 1197-1202 | 67 |
| B70, hot-pick streaming + n-major + bucketing | – / – / 1230-1247 / 1604-1605 / 1969-2014 | 67 |
| **B70, + device-tier split (`STREAM_T_DEV` 24 / `SLOT_ROWS_DEV` 1024) — default now** | **624 / 915 / 1343 / 1816 / 2005** | **67.7** |
| └ same box, previous policy re-measured interleaved (`perfab.sh policy`, best of 2 rounds) | 567 / 837 / 1256 / 1695 / 1943 | 67.6 |

i.e. the -mcpa prefill regression (B70 37% BEHIND the CPU worker) is fixed and the B70's decode
edge survives, because streaming hot picks on the 3090 and leaving the sparse tail on the B70 is
cooperation, not theft: the arena copy stays resident, so decode is untouched. The last row is the
only comparison run *interleaved* against the arm it replaces (`sycl_moe/perfab.sh policy`, 2 arms
x 2 rounds, one process each): +10/+9/+7/+7/+3% prefill, decode 67.7 vs 67.6 (neutral). Comparing
different days' single `perf.py` runs (2014 vs 1968) moved more than the effect in the wrong
direction - box drift is ±3-5% and both metrics are one-shot per length.

### What actually bounds prefill (measured 2026-10-28, `sycl_moe/SESSION_20261028.md`)

**The main GPU, not the link, and not the B70.** One 4096-row prefill at the default policy,
kineto + `dmon` + `xpu-smi` (tools: `pb.py -prof`, `tl_analyze.py`, `mon.py`):

| resource | used |
|---|---|
| 3090 compute stream | 1649 ms busy of a 2159 ms span (81%); union of both streams **91%** |
| 3090 copy stream (weight DMA) | 475 ms = 22%; link mean **3.2 GB/s** of 12.8 measured capacity |
| 3090 non-MoE kernels (attention/GDN/dense/resident experts) | ~1.05 s — the floor no offload knob can move |
| 3090 streamed-MoE kernels | ~0.6 s (`exl3_moe_kernel` mt64/32/16 + reconstruct + gather) |
| B70 | 592 ms/rep of plugin time for ~16 k tail picks at **21-28% compute util, 70 W of 275 W** |

The earlier 'Gen4 x8 link ceiling ⇒ ~2000 tok/s plateau' inference is superseded: it was computed
from `2.46 MB` per expert (real `expert_bytes` on this model is **1 228 800 B**, so one DMA is
~92 us not ~184 us) and from a first-forward workload (before promote-on-miss converges, the
worker tier holds ~20.8 k picks/layer; converged it holds ~5-7 k). The prefill knobs that matter
are (a) which picks each leg computes and (b) how full each leg's tiles/fragments are - and the
B70 has ~3x more capacity than the old policy used.

| model | config | CPU worker | B70 |
|---|---|---|---|
| 2.05bpw | `-mcs256` **no** `-mcpa` | ~1456-1511 pre / 68-70 dec | 1850-1886 pre (+25%) / 70-72 dec |
| 2.68bpw | guarded auto, `-mcs384-448` | 40.2 dec | 59-60 dec (+47%) / 512-562 pre (pre-guard regime: 748/53.3) |
| 4.05bpw | `-mcs448 SUB=0.5 st4` | 226 pre / 24.9 dec (37.5 with pinned streaming) | 598-606 pre / 54-58 dec (**dec ~2.1-2.3x**, 19-21 of 48 layers resident) |
| 4.18bpw hybrid K2{8,10} | `SUB=0.5` warm | — | 807 pre / 43.5 dec |

Accuracy: float tier xval **6.04e-7** rms vs the real CPU scalar ext (6.53e-7 with coop-D),
int8 tier **1.36e-3**, ppl Δ ≤ 0.25% on all three models (`archive/measurements-ledger.md`).
Decode is not MoE-bound on 2.05: the whole b70 path is ~10% of the 14.2 ms/token budget.

Plateau: with the split tuned, prefill at 4096 rows is bounded by the 3090's own queue (its
non-MoE work is ~1.05 s of a ~2.0 s pass and it is 91% busy overall). Software knobs (mcs,
stream_t, stream_t_dev, slot_rows_dev, WSLOTS, guards, overlap) are all at measured optima — see
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
9. **Sweep interacting knobs together.** `stream_t` × `cap_rows` (2026-10-28): each looked 'flat'
   when swept alone inside the other's dead zone, and the pair is worth +8-10%. Before believing a
   recorded 'knob is flat', ask what regime the *other* knobs pinned it in.
10. **Measure the converged placement, not the first forward.** Promote-on-miss moves hot experts
    out of the worker tier as forwards proceed (2.05bpw: 20.8 k worker picks/layer on the first
    pass, 5-7 k afterwards; streamed experts 260 → ~70-110, tail rows 0 → ~300-770). Every
    policy/threshold experiment run on cold state measures a different workload. `pb.py`'s reps
    (or perf.py run 2) are the steady state; `split_report.py` shows the split per forward.
11. **An instrument that prints nothing may be BROKEN, not silent.** The first version of
    `EXL3_MOE_B70_HOSTPROF` never reset its stage counter in `begin()`, so after ~2 forwards
    nothing accumulated and every later window printed an empty line. I read that silence as
    "submits cost <0.05 us", published it as proof that command submission is not decode's problem,
    and used it to close the graph question. With the counter fixed, the same submits measure 2.6 us
    (isolated lab), ~5.4 us (model), ~21 us (harness). Rule: a diagnostic must print its own
    denominator and emit at least one unconditional line per window, so that "zero" is always a
    measured zero rather than an absent one.

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
8. **Geometry literals are THREE-sided.** Any change to chunk/fragment layout must move the
   device kernels (`moe_sycl.cpp`), the host reference (`moe_host_ref.hpp`) AND the i8trace
   harness (`bench_layer.cpp`) together - they now all include `moe_layout.hpp`, which derives
   I8R/I8_A8BLK/shifts from `MOE_WIDEM_MAXM`, so one -D flips all three. Measured cost of getting
   it wrong: three stale harness literals produced "the m16 DEVICE build is broken" twice and a
   SIGSEGV once, while the device was right all along (the harness read `qsxu` with a `slot*32`
   float stride, collapsed split-K slices over only 16 rows, and decoded token-map entries with a
   literal `>> 3`). A verification tool that hardcodes the layout it verifies proves nothing.

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
  use the edit tool (2026-10-27 reminder: three scripted multi-line patches left a duplicated
  `struct ChunkDev`, a stray `(4 acc chains)` fragment and a truncated expression; each cost a
  debug cycle the edit tool would have caught at apply time).
- **P16 host→device pinned-USM stores are NOT a dependable doorbell.** A resident kernel RMW-polling
  a `malloc_host` line stops observing host writes - warm after a few dozen pings, permanently after
  ~10 ms of device idle - and neither an atomic RMW on the device side, nor a non-temporal host store
  (`_mm_stream_si32`+`sfence`), nor `clflush`, nor background traffic fixes it (measured 68-100% of
  pings > 5 ms; `lab_resident_bw B`, plan §11.4). Diagnostic that found it: have the poller count its
  own polls and publish the count; ~1.2e7 polls with no observation = visibility failure, not latency.
  Dependable alternative: a 4-byte H2D `memcpy` into DEVICE memory per job (0 stalls), i.e. a command.
  Root cause is advertised capability: this device has neither `usm_atomic_host_allocations` nor
  `usm_atomic_shared_allocations`.
- **P17 a poll-COUNT bail bound is not a time bound here.** A system-scope atomic RMW on pinned host
  memory runs at ~60 ns (1.7e7/s), not the ~1.5-2 µs PCIe round trip `lab_doorbell` assumed. A
  "1e6 polls ≈ 1.5-3 s" bound was really 60 ms, and the resident kernel was quietly killing itself
  mid-measurement while the log blamed the interconnect. Bound lifetimes by measured rate (≈2e7 polls
  for ~1.2 s), and print the rate so the number is falsifiable.
- **P18 the B70 has an idle cliff on the submission path.** The same 4-command chain costs 56 µs warm,
  70 µs after 10 ms idle, 247 µs after 20 ms, 410 µs after 100 ms; a trivial-kernel drip every 0.5-2 ms
  flattens it to ~91-105 µs. Separate from ULLS: with `EnableDirectSubmission=0` the cliff is still
  there (134 µs warm → 412 µs cold). Decode's ~300 µs inter-job cadence is in the flat zone, so do not
  blame it for decode's fixed cost - but it dominates any benchmark that pauses, and the first B70 call
  after a real user/input pause.
- **P15 int8 fragment ceiling**: Xe2 joint_matrix has NO int8 m16 accumulator - requesting
  `joint_matrix<sycl::sub_group, int, use::accumulator, 16, 16>` throws at launch ("...Rows=16,
  Cols=16 is not supported on this device", lab_jm9_m16.cpp, and note stdout was buffered so the
  lab printed nothing before dying). So 8 rows = 4 tokens (vh/vl) is the widest DPAS operand
  pair available and per-pick fragment work cannot be reduced by widening.

## Format facts at hand (full spec: [`archive/mul1-trellis-spec.md`](archive/mul1-trellis-spec.md))

- `K2 = 2*bits + hb`; contract universe `{2,3,4,5,6,7,8,10,12,14,16}` (halves only ≤3.5, bits ≤8);
  both tiers specialize all 11; out-of-contract → `GemvFallback`; int8 never silently misses a kernel.
- Stream repack = per-tile u32 WORD REVERSAL **into an n-major tile order** (arena tile
  (tk,tn) lives at `tn*tiles_k + tk`, `moe_sycl.hpp`): a reader that owns one column tile walks
  k sequentially instead of striding `tiles_n*W`. `repack_native_to_stream_words` now REQUIRES
  `tiles_k` (hidden/16 for gate/up, interm/16 for down) - pass it, or the permutation is wrong.
  `MOE_STREAM_NMAJOR=0` rebuilds the classic k-major arena (old labs assume it).
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
EXL3_MOE_B70_INT8=1 ./bench_layer --e 32 --rows 64 --bits 2 --hb 4 --i8trace   # MIXED buckets
EXL3_MOE_B70_INT8=1 ./bench_layer --e 64 --rows 128 --skew 1.0 --bits 2 --hb 4 --i8trace
./bench_layer --e 12 --rows 33 --gateless --i8trace           # and a foreign rate (--bits 4 --hb 6)
./bench_layer --load xval_s                                   # rms vs the real extension
python3 test_arena_update.py ../xval_s                        # only after upload/C-ABI changes
python3 bench_b70_py.py ../xval_s                             # C-ABI µs/call + rms (~102-104 us)
```

The mixed-bucket traces are not optional after any chunker/geometry edit: bucketing changes the
ORDER of the chunk list, so a harness that fails to bucket verifies a schedule the device never
ran. For a policy change on the python side, the gate is `bash qa_gate.sh` (streamed tier
engaged; eval/ppl.py cannot reach it).

Then, if perf-relevant: sustained interleaved A/B (burn-in, min-of-3, pinned tier); if
model-visible: `ppl.py` + `perf.py` run TWICE, scored off the second. Flags + tool details:
`archive/tools-and-harness.md`.

## Standing decisions

- **Prefill split policy (2026-10-27): the streamed tier MAY take hot picks from B70-resident
  slots** (`EXL3_MOE_B70_STREAM_HOT=1`, default; `=0` restores the classic steal-proofing rule).
  The old rule ("a fully registered layer streams nothing - that is correct, not a bug") cost
  37% prefill vs the CPU worker on 2.05bpw, because the B70 re-reads an expert once per
  8-pick chunk per cap_rows JOB (32 jobs × 142 chunks per 4096-token layer) while a streamed
  expert pays ONE PCIe DMA for the whole chunk. Attribution (fwd_stats.py on an ALLOCLOG run):
  in-plugin weight streams 3361 GB → 202 GB, in-plugin prefill 16.1 s → 0.7 s, model prefill
  1202 → 1975. It is cooperation, not theft: masked picks leave the job (`sel=-1`, both tier
  chunkers skip them), the arena copy stays resident, and streaming is gated to
  rows ≥ stream_min_rows so decode never uses it (dec measured unchanged 65-68).
  Threshold: **split by tier**. With a CPU tail the break-even is the old probe-scaled ≈11
  (`EXL3_MOE_STREAM_T`). With a DEVICE tail the streamed leg amortises a whole 1.17 MB expert DMA
  per streamed expert while the B70 already holds the weights, so the break-even is an absolute
  ~24 picks here: `EXL3_MOE_STREAM_T_DEV` (default 24, scaled by 13.4/probed_GBs, used whenever
  `layer_b70n[L] > 0`). 16/24/32 were within a few % of each other at 24 +/- but 24 took every
  round; below it the 3090 pays a DMA+launch per 1-2-pick expert, above it the B70 pays full
  fragments for half-empty chunks. Both legs' fixed costs are per *expert*, which is why the
  optimum is a count and not a fraction of rows (24 is right at 1024, 2048 and 4096 rows alike).
- Tier auto: **int8 iff rows ≥ 2**, float at rows=1 (float ~9% ahead at m=1: Xe2 DPAS min m=8,
  15/16 rows wasted, and joint_matrix fetches all 8 A rows regardless). Do not "fix" m=1 int8.
- Fat int8 kernel always runs BOTH m8 fragments and always zero-fills 16 rows — a branch/peel to
  skip frag1 poisons the unrolled schedule (-20% on the fat path to gain 22% narrow). Narrow-only
  work means a separate compile-time kernel (that's the slim one, `EXL3_MOE_I8SLIM`).
- Weights: one arena per layer, native tile layout stream-repacked at upload, never expanded
  (0.5 B/weight); installs are atomic in-place block overwrites; data pointers never move.
- Workspace pool: process-wide, rebound on EVERY forward (`grow_p` is a pure rebind when it fits),
  grown in 64-chunk steps, excluded from the registration budget, and deliberately NOT
  preallocated to the worst case. `cap_rows` default 128 for CPU-compute layers: the cool-box A/B
  ran (2026-10-27, streamed regime, plugin with bucketing) - 256/512/1024 give 1925/1938-1957/1955
  and 1920 at 512 with bucketing, i.e. FLAT against 128's 1857-1984, with no faults at any
  setting. **That 'flat' was an artifact of measuring a regime with no tail at all.** For a
  DEVICE-tier layer the job IS the chunking unit - a DPAS fragment costs ~5.9 us whether or not
  its 4 token slots are used - so 128-row jobs re-pay whole fragments for every job an expert's
  picks touch, and `SLOT_ROWS_DEV=1024` is worth +11% on the all-B70 arm (1411 → 1568) and part
  of the +8% shipped split. Device-tier layers therefore use `EXL3_MOE_CPU_SLOT_ROWS_DEV`
  (default 1024, clamped by `EXL3_MOE_CPU_SLOT_BYTES`=256 MiB of pinned handoff segment);
  CPU-tier layers keep 128, where small jobs pipeline better with the pool.
- Placement: default = cold/sparse experts on B70 (`SUB=auto` when oversubscribed), guard on
  (decode-weighted), stream_t auto probe. Hot experts on B70 measured WORSE (-18% prefill):
  per hot pick the 3090's streamed path is ~5x cheaper. `EXL3_MOE_CPU_SWAP_TIER=0` is the
  documented prefill-priority escape hatch.
- Never offload all experts (`-mcs 512` on this box = unsupported: zero GPU-resident experts).

- Fragment bucketing (`EXL3_MOE_B70_BUCKET=1`, default): chunks that one m8 fragment can
  cover (m ≤ I8_TOK_PER_FRAG) are partitioned to the FRONT of the chunk list by
  `moe_bucket_chunks` and run as a separate NF=1 launch, instead of every chunk paying
  I8_FRAGS fragments. CUDA doctrine, not invention: exl3_moe_kernel.cuh finishes an expert's
  remainder with "the largest smaller tile that covers it (64 -> 32 -> 16)". Both host
  chunkers (b70_lib and bench_layer) MUST bucket, because the token-map entry encoding
  carries the chunk index. E260 int8: rows32 1919→1648 µs, rows64 2630→2260, rows128
  3121→2867, rows512 8604→8379; all-narrow (decode) shapes take the single slim launch as
  before. Staging A for the narrow bucket is REQUIRED (it shares the wide launch's ring
  decision): the 16-lane no-ring narrow launch gave back everything (+1% vs no bucketing).

## The decode budget, measured IN THE MODEL (2026-10-29) — read this before optimizing decode

ALLOCLOG now carries four (then six) host phases per forward and microsecond timestamps, so the
model was measured directly (2.05bpw, decode-only pass, 29.4k rows=1 jobs, `/tmp/dec_c.log`):

| phase | p50 us | what it is |
|---|---|---|
| prep | 0.8 | expert lookup + chunk/token-map building |
| h2d | 3.2 | x host copy + x H2D submit (carries the PREVIOUS forward's dep) |
| **sub** | **27.2** | **`moe_sycl::forward`: job-blob H2D + 4 kernel submits - parent-thread time** |
| d2h | 2.9 | out D2H submit |
| wait | 28.6 | blocked until the last command is observed complete |
| cp | 0.4 | copy out to the caller's buffer |
| **total** | **66.1** | p90 88.7, mean 72.7 |

By job size the fit is **t(nc) = 57.6 + 6.3 x nc** (medians: nc=1 63.9, 2 67.0, 4 82.0, 6 88.2,
9 114.0). Three consequences, each of which invalidated a prior belief:

* **The marginal expert costs 6.3 us = 195 GB/s of packed bytes**, close to the isolated-lab
  ceiling (254 GB/s) - weight *streaming* is basically fine. ~87% of a decode forward is FIXED
  cost, and 41% of the forward is host time spent enqueueing.
* **`bench_layer`'s "decode forward = 161 us / 76 GB/s" is not the model's number.** The harness
  pays ~21 us per submit (HOSTPROF host total 110 us/fwd) where the model pays ~5.4, so the
  harness's decode wall is ~2.4x the model's 66 us and is mostly submission. Every decode
  conclusion previously drawn from the harness wall - including "the gemv is 46% of decode" - needs
  re-deriving from the model budget above.
* Kernel-level wins under ~30 us per forward are invisible at the model level. Measured directly:
  `MOE_GEMV_NC=16` halved the gu kernel (span 51.5 -> 31.7 us) and the model got 1.6% WORSE.

## Levers, ranked (with what's already known)

1. **Per-action host submission cost - 27.2 us of every 66.1 us decode forward.** ~5.4 us per
   action x 5 actions (job-blob H2D + K1 + K2 + K34 + K56), on the parent thread, ahead of ~29 us
   of device work. This is the only decode lever of remaining size: ~0.9-1.2 ms of the 14.7 ms
   token, 6-8%, if it went away. Three candidate answers are already measured NO: command graphs
   (see 5), kernel fusion (`CoopGuK`: a wash - the device-side arrival chain costs what the dropped
   command saved), and **bypassing the runtime's command-group handler** - the promising one from
   `test-e2e/EnqueueFunctions/nd_launch_kernel_obj_direct.cpp` ("no handler is created for these"),
   which measures identical to the handler path (2.66-2.67 vs 2.63 us, regimes K-O of
   `lab_submit_busy.cpp`), i.e. the cost is the L0 commit itself, not SYCL bookkeeping. That also
   predicts PLAN_L0 would not deliver its headline benefit, so the raw
   `zeCommandListAppendLaunchKernel` experiment is deprioritized. Still unexplained: the *same*
   `q.submit` costs 2.6 us in the lab (flat across drained/busy/no-dep/barrier-bracket regimes and
   across `local_accessor` / runtime-sized SLM / `nd_range<2>` / 40-word-functor / SIMD16-property
   shapes), ~5.4 us inside the plugin, ~21 us under `bench_layer`; the lab also drifts ~15% run to
   run, so read 2.6-3.5 us as one number. ~~Consequence: 1b is the only route left.~~ **Consequence
   re-checked: 1b is now closed too (see 1b), so per-action submission cost has no remaining route on
   this stack. What the same budget says IS still open is the child's work-rate term (6.3 us/expert,
   rows>1 DPAS batching) and the placement/overlap question - not the command path.**
1c. **Placement is 100% STATIC in the shipped config, and the B70 cannot be given more hot work —
    measured, with the mechanism checked.** Facts, each verified this session:
    * With `-mcs 256` on 2.05bpw, every layer registers `E 260` on the B70 (256-slice + 4 spares)
      and `b70n == E`: the B70 already holds the **whole** worker slice. The arena math agrees
      (326 476 800 B/layer = 260 x 1.258 MB) and the budget is not binding (15.7 GB of 26.8 GB).
    * Therefore promote-on-miss has **no candidates**: `misses = ... & ((mp - first) >= b70n)`
      (`block_sparse_mlp_cpu.py:302`) is the empty set when `b70n == E`. Confirmed by **zero `UPDATE`
      lines** (no `b70_update_expert` call) across two full decode runs.
    * `EXL3_MOE_CPU_SWAP_POLICY=hot2` and `EXL3_MOE_CPU_SWAP_INVERT=1` are read only inside
      `_split_sweep_layer` (:1036, :1069), and `_split_swap_tick` returns before the sweep whenever
      the layer has spares (:990-994) - it does (4/layer). So both envs are INERT here: measured `nc`
      curves are identical with and without them (2.37/2.27/3.57/1.87/1.66/1.50 vs
      2.36/2.25/3.57/1.91/1.66/1.50). Anyone concluding "the policy did not help" from those arms is
      concluding nothing: the code path never ran.
    * Consequently the within-run `nc` falloff is NOT migration (nothing can migrate) - it is workload
      phase composition. My own earlier statement that it was "experts migrating off the B70" was
      wrong and is retracted.
    * Giving the B70 MORE work does engage (raising `-mcs` widens the worker slice, and `b70n` follows
      it to `E`), and it is measured, mechanism-checked, and slightly NEGATIVE for decode:
      | mcs | mean nc | forward p50 us | decode t/s (2 reps) |
      |---|---|---|---|
      | 256 | 2.21 | 65.7 | 67.7 / 67.1 |
      | 320 | 2.60 | 67.5 | 67.0 / 66.7 |
      | 384 | 3.11 | 68.9 | 67.4 / 66.2 |
      | 448 | 4.23 | 80.7 | 67.3 / 66.4 |
      Marginal expert on the B70 leg = (80.7-65.7)/(4.23-2.21) = **7.4 us**, while the same expert on
      the 3090 costs ~1.4 us of DRAM (1.23 MB at ~900 GB/s) plus a launch. The child's work is
      ALREADY overlapped with the parent's GPU work (two-phase issue/collect: `cpu_split_submit`
      returns `(cpu_partial, cpu_pending)`, collected after the GPU's own expert pass), so the B70's
      idleness is not a wasted resource - it is slack behind the parent's critical path. Lengthening
      the child's per-layer wall past that overlap is exactly what the table above penalizes.
    * Implication: the B70 wins only where the alternative is PCIe streaming from the 3090's side
      (92 us/expert measured in prefill) - hence `-mcs 256` sitting near optimum and prefill being
      where the B70 earns its keep (+7-10% measured). To use the idle card on decode we would have to
      displace work that is on the PARENT's critical path at less than its cost there; at rows=1 and
      2.05 bpw it is ~5x slower per expert than the 3090, so it cannot.
    * What remains genuinely on the table for decode: shrink the child's fixed 57.6 us/layer (levers
      1a/1b) so more of the child's work hides under the parent's per-layer GPU time, and rows>1
      batching (DPAS tier at 129-147 GB/s) where the B70 is competitive.
    Two code paths could move hot experts onto the B70 and neither can run in the shipped config
    (`-mcs 256 -mcpa`, 2.05bpw):
    * promote-on-miss masks the B70 slot range out of its candidate set:
      `misses = routed & ~resident & ~busy & ((mp - first) >= b70n)`
      (`exllamav3/modules/block_sparse_mlp_cpu.py:302`) - promotions can only land in CPU-tier
      slots `>= b70n`, so `b70_update_expert` is never called for them.
    * the periodic sweep - the ONLY code that honours `EXL3_MOE_CPU_SWAP_POLICY=hot2` (:1036) and
      `EXL3_MOE_CPU_SWAP_INVERT=1` (:1069, whose comment says the hot expert "now travels to the
      device through b70_update_expert") - is bypassed whenever the layer has spare slots:
      `if self._split_spares: _split_promote_step(...); return` (:990-994). This config registers
      **4 spare slots per layer**, so the sweep never executes.
    Measured proof it is inert: with `hot2` on vs off, per-decode-job `nc` is identical in every
    sixth of the run (ctrl 2.37/2.27/3.57/1.87/1.66/1.50 vs hot2 2.36/2.25/3.57/1.91/1.66/1.50)
    and **zero `UPDATE` lines appear in either ALLOCLOG** - no expert ever moved onto or off the
    B70. Consequences: `EXL3_MOE_B70_SUB` only resizes a *static, cold-by-profile* prefix
    (worker slice is experts `[256..512)` = the colder half by the saved heat profile, and the B70
    holds its prefix), which is exactly why SUB=0.5 / SUB=512 measured neutral-to-worse
    (dec 68.3 / 67.0 / 67.1); and my earlier statement that the `nc` falloff during a run is
    "experts migrating off the B70" was WRONG - with zero updates it is benchmark phase
    composition, not migration.
    Still true and worth keeping in mind: the B70 leg is worth **+6.1% decode** (interleaved 3-arm:
    `EXL3_MOE_B70=1` 68.1 vs `=0` 64.2 dec_avg), so it matters - it is just starved, and the fix is
    code, not config. Ranked options:
    (i) CONFIG-ONLY approximation, unverified properly so far: enlarge the worker slice so some
        globally-hot experts fall inside it (`-mcs 384`: dec 68.8 vs 67.7 control, ONE non-
        interleaved rep = inside noise) - the B70 prefix then holds the hottest of a warmer slice.
        Needs an interleaved 3-round A/B with `nc` from ALLOCLOG as the mechanism check (expect nc
        to rise from ~2.2 toward 4-6 before believing any perf move).
    (ii) SMALL CODE CHANGE: let the invert/hot2 sweep run even when spares exist (it already knows
        how to quiesce, budget and install via `b70_update_expert`). This is the direct route to
        "half the hot set on each device".
    (iii) Teach promote-on-miss to target B70 slots (needs a spare concept inside `[0,b70n)`).

1b. **CLOSED 2026-10-28: persistent B70 worker - measured, loses, and its premise is not supported
    by this device.** Evidence + restart conditions: `PLAN_PERSISTENT_WORKER.md` §11–§12. Lab:
    `lab_resident_bw.cpp` (A = residency gate + sustained GB/s vs resident thin-gemv team count;
    C = split-path control, a "same work, one launch, no protocol" reference, and an idle-gap scan;
    B = engine with 5 trigger mechanisms × 3 fan-out styles × 2 fan-in styles, min-of-3 windows, plus
    the §2a device poll counter). Four numbers ended it:
    * **feeding itself needs half the machine, permanently:** a decode job is **200** 128-thread units,
      not the 20-40 this plan assumed (`NSL_GU` auto-saturates at 8: `nc*nm*(I/128)=20`,
      `while (w<8 && base*w*128 < 80000) ++w`; coop-D pins `NSL_D=1`), and this gemv shape only reaches
      the model's own 195 GB/s marginal rate at >= 256 co-resident teams. Co-residency ceiling for the
      shape: ~448-512; at 576 throughput collapses 25× (11.4 → 288 µs/job). The split path buys that
      occupancy per job; the engine has to hold it forever.
    * **it loses on wall clock anyway:** at the shipped geometry, engine **75.6 µs/job** on an
      under-sized grid and **97.1 µs/job** at the 200-team grid its work actually needs (p99 3.4 ms,
      4.8% stalled; at 256 teams it never answered at all) vs the split path's **28.9 µs/job** - and the
      gate was "beat it by 20 µs", i.e. < 9. Softer geometries (`LAB_SK=1/2`) give 127-190 / 84-92 vs
      96 / 56 - the engine loses by 1.5-3.4× whichever way the work is sliced. Batching jobs per trigger
      reaches 25 µs/job, but autoregressive decode cannot batch: layer k+1's input is layer k's output.
    * **the only dependable doorbell is a command:** a per-job 4-byte H2D `memcpy` into device memory
      gave 0 stalls / 60 pings (p50 18.9 µs warm, 38.1 µs after 100 ms idle). Every host-store flavour
      (release atomic, `_mm_stream_si32`+sfence, store+clflush) lost 68–100% of pings to >5 ms stalls
      against a resident poller, and a keepalive drip did not rescue it. So the design's ceiling was
      never "zero submits per layer", only "one instead of five".
    * **the stalled leg is host→device, and it is visibility not latency:** during a stalled ping,
      team 0's own counter showed ~1.2e7 polls of the doorbell line *without observing the store*.
      That is what using an unadvertised operation looks like (no `usm_atomic_host_allocations` /
      `usm_atomic_shared_allocations`, plan §10) - now measured. It is a sufficient explanation for
      `lab_doorbell`'s "20-75% of pings exceed 20 ms", and it removes the need for the clock-ramp and
      preemption stories there (both predicted a *slow* answer; what the counter shows is an answer
      that never arrives because the store is not observed).
    Still true from the earlier investigation, kept so nobody re-derives it: the 1-WG round-trip floor
    really is microseconds; `aspect::ext_oneapi_device_wait` is NOT a device-thread park (it backs the
    host-side `sycl::device::ext_oneapi_wait()`, `device.hpp:392`); and this device's L0 queue group 0
    DOES advertise `COOPERATIVE_KERNELS` (`l0_coop_probe.cpp`), so a driver-provided grid barrier is
    addressable in principle - but it is beside the point, because the engine lost *without* using any
    grid-wide barrier. Original lab trail (`lab_doorbell.cpp`, resident kernel + pinned doorbell, host
    clocks, 100 ms ceiling): round trip p50 **2.4-3.1 µs at 1 WG** and ~8-11 µs at 16-64 WGs - i.e. the
    idea's ceiling really was the whole 57.6 µs of fixed cost - but 20-75% of pings stalled past 20 ms,
    and §11.4 above is why. Three mechanism lessons, each reproducible:
    (a) polling SYSMEM with an acquire LOAD goes deaf after a few pings (legal lowering to a cached
        load) - the doorbell must be an atomic RMW;
    (b) hundreds of WGs RMW-polling one DEVICE-memory line serializes catastrophically (>20 ms per
        job from 8 WGs up) - fan-out needs per-WG slots or `device_wait`, not a shared line;
    (c) completion must be LEVEL-triggered (`done >= want`), because the device coalesces doorbells
        and an equality test waits forever for a skipped id.
    (a′) lesson (a) turned out to be only half the story: an RMW fixes the *device's* poll, but the
        *host's* store still does not reach a resident poller dependably (§11.4) - and a resident
        spinner does not starve other queues, it in fact *speeds them up* (16 MB fill on a second
        queue: 17.5 µs with a spinner vs 34.0 µs without), which is why "device is busy" was never the
        missing ingredient. The keepalive arms are implemented in `lab_resident_bw` (`LAB_KEEPALIVE_US`,
        `LAB_IDLE_US`) and they flatten the *idle cliff* but do not make a store doorbell dependable.
    **Plan written and executed: `PLAN_PERSISTENT_WORKER.md`** (§11 results, §12 closure). Its step 1
    (locate the stall with a device-side poll counter, then test arms S1-S6 including the keepalive and
    command-level parks) is what produced the four numbers above; the plan's claim that lab_doorbell
    already had keepalive arms coded was wrong - those modes were never in that file.
    Related NEW platform fact, independent of this lever and not yet exploited: `lab_resident_bw C`'s
    idle-gap scan shows the SAME 4-command chain costs 56 µs warm, 247 µs after 20 ms of B70 idleness
    and 410 µs after 100 ms (cliff unaffected by `EnableDirectSubmission`, so it is device-side idle,
    not just a dropped ULLS ring). Decode's own cadence (~300 µs between layer-jobs) is deep in the flat
    zone, so this is NOT decode's fixed cost; it bites the first B70 call after any pause (prefill→decode
    transition, first token after input arrives). A keepalive drip every 0.5-2 ms flattens it to
    ~91-105 µs. Also measured here for the first time: **ULLS/direct submission is ACTIVE on this box
    and worth ~78 µs per 4-command chain** (55.6 µs default vs 134 µs with `EnableDirectSubmission=0`;
    forcing it on changes nothing), which closes the "is the driver on the fast path?" question.
    **Evidence check (plan §10) changed three things, one of which is now itself superseded:** (1) the
    doorbell cannot be *designed* on USM-host atomics - SYCL grants host/device atomic interop only with
    `usm_atomic_host_allocations`/`usm_atomic_shared_allocations`, and this B70 advertises **neither** -
    confirmed behaviourally in §11.4, so this is no longer a documentation worry but a measured wall;
    (2) the leading stall explanation proposed there, **driver preemption/timeslicing** (timeslice 1 ms,
    preempt 640/7500 ms, i915 request timeout 20 s, xe job timeout 1-10 s), is **not supported** by the
    poll-counter evidence: the engine was spinning, not descheduled, and never saw the store - preemption
    was demoted by measurement, along with clock ramp;
    (3) "no grid-sync primitive" was too strong - L0 specifies cooperative launch and this device's
    queue group 0 advertises `COOPERATIVE_KERNELS` (`l0_coop_probe.cpp`), but the residency bound that
    motivated gate G0a turned out to be irrelevant next to the bandwidth bound.
    (The pre-closure text of this lever asked for exactly the four things that killed it - the real
    doorbell→observed-complete round trip, cross-scope flag visibility, keeping prefill and the
    poison/timeout path intact, and a resident kernel's power draw. All four are now answered in
    §11; the 256-CU geometry also explains lever 4's lab curve: 50 WGs × 8 sub-groups is ~1.6 SIMD16
    streams per EU, so the decode gemv is under-distributed - true, just not on the critical path.)
2. **Counter-fed GU fusion** (`CoopGuK` built, parked neutral): retry only bundled with an NSL_GU
   retune measured on real 4.05 decode (C-ABI prefers 2, bench prefers 7 — a wave cliff at 3) and
   per-(entry) 2-arrival units. Summation order must stay bit-identical.
3. **REFUTED, do not retry: the "nibble-aligned repack" of decode weights.** The proposal was to
   reorder the same 4 bits/weight so a lane's 16 k-values sit byte-adjacent, priced at ~2x by
   `lab_i8gemv`'s int8 rows. It is impossible at these rates: mul1 stores 16-bit trellis STATES that
   advance by K2/2 bits (2 bits/weight at K2=4 == 2.05bpw), so a lane's 16 windows overlap by 14
   bits and de-overlapping duplicates the arena by 32/K2 = **8x** at K2=4 (still 2x at K2=16). The
   lab rows that made byte-alignment look free (B == C at 535-603 GB/s) were moving 4x the bytes:
   valid about access PATTERNS, worthless as a packed-equivalent ceiling. What the honest ablation
   ladder on the real K2=4 loop (`lab_gemv_ablate.cpp`) shows instead: deleting the 16 activation
   loads per tile makes the loop *slower* (84.0 vs 64.5 us), removing bytesum buys 18% (52.7),
   removing the state extract 24% (49.2), while SLM-staged activations (66.3) and float4 activation
   loads (63.9) are neutral. A prior "we are at the instruction-issue floor" claim was really "at
   the floor of this access pattern"; the loop is latency/distribution-limited, which is what lever
   4 tested.
4. **Narrower decode workgroups - measured NEGATIVE, kept as `MOE_GEMV_NC` (default 128 = shipped
   geometry).** `lab_gemv_shape.cpp`, fixed total lanes and fixed bytes: NCWG 128 -> 64.9 us,
   64 -> 33.2, 32 -> 18.0, 16 -> 10.9, 256 -> 130.3, while software-pipeline DEPTH 1/2/4 sat inside
   0.2 us of each other. Time is inverse to the WORKGROUP COUNT at constant work: distribution
   granularity, not per-lane latency. Implemented in `GemvK` as a column-block width (`ncwg`,
   nbk = N/ncwg, grid/arg patched together, only the single-slot decode path; contract-rate check
   keeps `GemvFallback` at 128). Bit-identical by construction and verified so - max_rel 1.882e-06
   / rms_rel 1.070e-06 unchanged at 128/64/32/16 - and the kernel really did halve (gu span 51.5 ->
   31.7 us). Model: dec_avg 68.9 / 67.8 / 67.5 for NC 128 / 16 / 32 (2 interleaved rounds each,
   prefill unchanged) => 1.6-2.0% WORSE. Decode is not gemv-bound (see the budget), so the win had
   nowhere to go and the extra WGs cost scheduler work.
5. **SYCL command graphs - do not ship; now refuted on two independent axes.** Wall axis: a replay
   of the forward chain works with our real kernel shapes (`lab_graph4.cpp`: job-block H2D node +
   `nd_range<2>` + `local_accessor` + device-scope `atomic_ref` RMW + external dep event, 0 bad /
   300 replays rewriting the pinned job block) and saves ~1.2 us per command (5 commands
   14.84->13.12 us; 13 commands 36.10->27.48 us) - ~+0.7-1.4% decode, at/below noise. The
   1.47-1.62x in `lab_graph.cpp`/`lab_graph3.cpp` was a trivial-duration-kernel artifact; those labs
   stay as the correctness proof. Host axis (2026-10-29, `lab_graph4` gained a host-only arm: 50
   chains burst-submitted without waiting, device busy): **replay 12.24 us vs the 4-action chain's
   9.95 us** - a graph costs at least as much host time as the commands it replaces, so it cannot
   attack the 27 us of `sub` either. Native-L0 (`PLAN_L0.md`) is NOT the same wall: it survives or
   dies on lever 1's per-action question, not on command counting.
6. **Per-fragment DPAS efficiency** (was "DPAS kernel-side prefill gap"). The cost model is now
   measured, not guessed: **run time is proportional to the number of m8 FRAGMENTS executed**
   (MAXM=16 ran 1.2x the fragments of MAXM=8 at E260/rows1024 and took 1.20x the time, while
   doing 1.67x FEWER weight traversals; at rows128 it ran 2x the fragments and took 1.95x).
   Traversal is cheap per pass but the passes are slow - the fat int8 gemv sustains only
   ~130-147 GB/s of 608 at these shapes (measured ladder, lever 2), which is why fragment count
   and not bandwidth is the binding term *within* a launch while bandwidth is the binding term
   *across* shapes; wide-M is a dead end - see `moe_layout.hpp`. Fragments/token is also near a floor: m8 rows
   ÷ (vh,vl) = 4 tokens per fragment, and an int8 m16 accumulator does not exist on this device
   (lab_jm9_m16: the runtime rejects `joint_matrix<sint32, accumulator, 16, 16>`). What is left:
   (a) esimd `xmx::dpas<8,8,int>` (t40, operand layouts verified bit-exact there) to remove the
   joint_matrix gather + SLM barriers per fragment; (b) NOT spending two rows per token - a
   single-part int8 A operand halves the fragments but multiplies the activation quantisation
   error, so it needs a ppl gate before it is even discussed.
4. **B70-side weight streaming into tier slots** (update+evict protocol) — the only way to beat
   748-era prefill *with* the decode gains; real cache-protocol work.
5. Hardware: fix the PCIe lane bifurcation (3090 at x8) → prefill lifts directly.
6. Small/parked: split-K retune after ring; K34i8+Q2 fusion (~-10 µs decode); int8 wide-row
   pairing; error-feedback int8 for quality headroom. CLOSED today: RING for slim kernels
   (measured negative at every all-narrow shape) and "MAXM 16/32 wide-M" (see 3). Full
   rationale: `archive/int8-dpas-tier.md`, `archive/decode-command-latency.md`.
7. **Prefill balance (open, and the biggest one left).** The link is NOT the ceiling - it runs at
   a quarter of its rate while the 3090's compute stream is 81% busy and its two streams are 91%
   busy union (measured, `SESSION_20261028.md`). Floors: 3090 non-MoE work ~1.05 s of a ~2.0 s
   4096-row pass; the streamed leg is ~1.7 us/pick on the 3090 (kernel) + ~92 us/expert of link,
   vs ~1.5 us/pick best case (full chunks) and ~8-26 us/pick as the tail is actually shaped today.
   Next moves, in rough order of payoff:
   (a) make the B70 tail cheap - it is ~592 ms/rep to chew ~16 k picks (3% of the workload) at
       21-28% util; a narrow-chunk path that costs ~one weight traversal instead of two m8
       fragments, or simply better weight bandwidth on 1-2-token chunks (~50-100 GB/s effective
       today vs 608), directly buys back leg balance; the `b70_lib.forward_impl` double copy
       (x → g_stage → d_x, d_out → g_stage → slot) is ~15 KB/row of PCIe+memcpy per tail row and
       is pure overhead;
   (b) stop paying per-batch host costs on the streamed leg: ~1 k pageable HtoD copies per prefill
       (`host_to_device(torch.tensor(...))` for the fused-tier descriptor + expert counts, 33-42 ms
       of device time plus a pageable-copy stall each) could be one pinned upload per layer;
   (c) the parent still blocks in `_issue_compute`/`_collect_compute` per layer once the job ring
       (EXL3_MOE_CPU_SLOTS, max 8) is full - with big jobs there are few of them, but deeper
       ring/lookahead is untested;
   (d) the 3090 streamed fused kernel charges ~2 ms per mt64 launch for ~24 experts of ~60-80
       picks each (padding to the 64-row tile is ~1.5x, and the tier ladder only offers 16/32/64);
   (e) the residual ~400 ms of 3090 idle per 4096-row pass is NOT one big stall: besides ~143 ms
       in 46 gaps ≥400 us, ~250 ms sits in ~18 thousand sub-300 us gaps, i.e. the queue drains
       between the per-layer syncs (`counts1.tolist()` and the tail `nonzero()` are the only two,
       but the python between them and the first launch is exposed). Chasing it means either
       fewer exposed host µs per layer or fewer syncs, and it must be measured with `pb.py`
       interleaving, because it is the same order as box drift.
   RE-CHECKED 2026-10-28, all flat-or-worse at the new defaults (`ab.sh knobs`, `knobs2`):
   `CPU_WSLOTS=4` (-6% @4096), `CPU_WSLOT_MB=64 + STREAM_BATCH_EXPERTS=48` (-2%), `CPU_SLOTS=8`
   (mixed), `B70_OVERLAP=0`, `SLOT_ROWS_DEV=2048`, `STREAM_T_DEV=20` (all within ±3%), and
   `MTILE=0` (-6%, so the streamed m-tile ladder does pay). `-mcs 320` (moving 64 more experts
   per layer out of the 3090's resident tier into the B70-backed worker tier) is WORSE:
   1645-1712/2037-2078 vs 1731/2139 at 2048/4096 - the 3090's resident path is cheaper per pick
   than either offload leg, so the split line stays at 256.

Dead ends — do not re-litigate (evidence in `archive/kernel-microopt.md`, `archive/int8-dpas-tier.md`,
`archive/decode-command-latency.md`, and `PLAN_PERSISTENT_WORKER.md` §11-§12): **a persistent/resident
worker kernel fed by a host doorbell (lever 1b)** — resident thin-gemv grid needs ≥256 of ~448-512
team slots to reach 195 GB/s, measures 75.6-97.1 µs/job vs the split path's 28.9 µs/job at the shipped
split-K geometry, and its doorbell is not dependable in any host-store flavour;
`archive/decode-command-latency.md`): dp4a/esimd in generic kernels, `dot_acc` ext, col-major
joint_matrix B, coalesced word loads + `select_from_group`, megakernel-with-grid-barriers, flat
bytesum tree, `-510` folding, large GRF, annotated_ptr hints, 128-lane WGs without ring,
`(tk&3)`-array depth-4 prefetch, worst-case pool preallocation, hot-expert→B70 placement,
`-mcs 512`, `std::async` mixed-job overlap at small tiers, **wide-M (MOE_MAXM 16/32)**, **A-ring
for the all-narrow slim kernel (`EXL3_MOE_I8SLIMRING=1`: +14..+18% at rows 1-8, lever 6 closed)**,
**int8 m16 joint_matrix accumulator (not supported by the device)**, **blocking the streamed tier
on fully B70-registered layers** (the 2026-10-27 prefill regression; see Standing decisions),
**`-mcs 320` on 2.05bpw** and **`CPU_WSLOTS>2` / bigger streamed batches** (2026-10-28, all under
the new split: `ab.sh knobs`/`knobs2` in `SESSION_20261028.md`), **every Level-Zero runtime env
knob for decode** (`SYCL_UR_USE_LEVEL_ZERO_V2=0` -3.6%, immediate-commandlists=0 -4.6%, copy-engine
offload -6…-9.5%, event-cleanup threshold -2.7%, compute-engine index -1.3%: `perfab.sh decenv`),
**queue-index/low-latency-queue** (`max_compute_queue_indices == 1` on the B70), and **IPA/ML-IPA +
mutable-call resident kernels** (neither extension exists on this driver — enumerated 63 extensions;
see `archive/decode-command-latency.md` §“Research 2026-10-28”).

## Also

- `PLAN_L0.md` — scoped native-L0 v1 (int8 decode chain), gates and footguns.
- `SESSION_20261028.md` — the prefill session log behind this file's 'State' section: the timeline
  measurements (kineto/dmon/xpu-smi), the `stream_t` × `cap_rows` campaign, the negative knob
  results, the accuracy investigation, and the `pb.py` vs `perf.py` disagreement (use `perfab.sh`
  for anything you intend to ship).
- Tools: `pb.py` (in-process prefill bench, `-prof` for kineto), `tl_analyze.py` (trace busy/idle),
  `mon.py` (both cards' link/power/util), `ab.sh` / `perfab.sh` (interleaved arms),
  `split_report.py` (per-forward workload split from `EXL3_MOE_STREAM_DEBUG`).
- `archive/INDEX.md` — what's where, symptom→page lookup, provenance of this rewrite.