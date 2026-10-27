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

## Levers, ranked (with what's already known)

1. **Counter-fed GU fusion** (`CoopGuK` built, parked neutral): retry only bundled with an NSL_GU
   retune measured on real 4.05 decode (C-ABI prefers 2, bench prefers 7 — a wave cliff at 3) and
   per-(entry) 2-arrival units. Summation order must stay bit-identical.
2. **Native-L0 submission** — `PLAN_L0.md`, feasibility proven, single blocker (SLM binding for the
   `local_accessor` arg is invisible on the public ze surface); first move is a `-DMOE_L0_NO_SLM`
   global-scratch SPV variant, measured. Worth less than it looked after the polling fix.
3. **Per-fragment DPAS efficiency** (was "DPAS kernel-side prefill gap"). The cost model is now
   measured, not guessed: **run time is proportional to the number of m8 FRAGMENTS executed**
   (MAXM=16 ran 1.2x the fragments of MAXM=8 at E260/rows1024 and took 1.20x the time, while
   doing 1.67x FEWER weight traversals; at rows128 it ran 2x the fragments and took 1.95x).
   Weight streaming is therefore NOT the limiter (the int8 gemv runs at ~200 GB/s of 608), and
   wide-M is a dead end - see `moe_layout.hpp`. Fragments/token is also near a floor: m8 rows
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
       picks each (padding to the 64-row tile is ~1.5x, and the tier ladder only offers 16/32/64).

7. **Coupled-knob sweeps only.** `stream_t` and `cap_rows` interact multiplicatively (measured:
   `stream_t` 11→24 gains nothing at `cap_rows` 128, +8% at 1024; `cap_rows` 128→1024 gains
   nothing at `stream_t` 11, +8-10% at 24). Sweeping one inside the dead zone of the other is how
   both got recorded as 'flat'. Related: measure the **converged** placement (pb.py reps 2+, or
   perf.py's second run) - on the first forward the worker tier still holds the hot experts, which
   inverts the streamed/tail split (20.8 k picks/layer vs 5-7 k converged).

Dead ends — do not re-litigate (evidence in `archive/kernel-microopt.md`, `archive/int8-dpas-tier.md`,
`archive/decode-command-latency.md`): dp4a/esimd in generic kernels, `dot_acc` ext, col-major
joint_matrix B, coalesced word loads + `select_from_group`, megakernel-with-grid-barriers, flat
bytesum tree, `-510` folding, large GRF, annotated_ptr hints, 128-lane WGs without ring,
`(tk&3)`-array depth-4 prefetch, worst-case pool preallocation, hot-expert→B70 placement,
`-mcs 512`, `std::async` mixed-job overlap at small tiers, **wide-M (MOE_MAXM 16/32)**, **A-ring
for the all-narrow slim kernel (`EXL3_MOE_I8SLIMRING=1`: +14..+18% at rows 1-8, lever 6 closed)**,
**int8 m16 joint_matrix accumulator (not supported by the device)**, **blocking the streamed tier
on fully B70-registered layers** (the 2026-10-27 prefill regression; see Standing decisions).

## Also

- `PLAN_L0.md` — scoped native-L0 v1 (int8 decode chain), gates and footguns.
- `archive/INDEX.md` — what's where, symptom→page lookup, provenance of this rewrite.