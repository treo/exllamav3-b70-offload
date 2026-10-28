# Decode = command latency, not math (fusion, counters, native L0)

At rows=1 the work is irrelevant: time is work-INDEPENDENT (topk 1..10 all measure the same).
The `--bare` per-iter barrier round trip alone is 33 µs and every chained queue op adds
~8-15 µs. Everything in this file is about removing commands and dependency edges.

## Floor budget (rows=1, before coop-D)

int8 183 µs / float 168 µs ≈ memcpy ~10 + per-command chain (7 int8 / 6 float commands incl.
barriers) ~60-80 + real kernel spans ~90. The remaining big int8 cut would be K34i8+Q2 (needs
5-block-wide WGs for the row amax, same register-carry trick), worth maybe -10 µs; below that
it is one fused megakernel or stop. (Megakernel: tried, see below. Stop, then: the counter-fed
fusion below is what actually paid.)

## Shipped: owner-gather K6 (both tiers)

One WG per (128-col block, token) walks its token's tmap entries in ASCENDING order. Kills the
`out` memset command AND the fp32 atomic scatter; sums now match the CPU reference's order
exactly (the atomics did not — that was the source of the 6e-4 ppl run-to-run spread).
rows=1 spans GROW (5 → 21 µs: only `nbk*rows` WGs) but the SUSTAINED total drops ~18 µs anyway:
launch latency outranks span time at decode. rows32+ improved too (660 → 635: no atomic storm).

## Shipped: fused prep+quant, int8 (`PrepQuantI8` = K1+Q1)

256-thread WG per (slot, token row-pair); two 128-thread teams Hadamard 10 blocks each with
results kept in registers (`vals[10]`) across the shared amax, then quantize BOTH vh and vl rows
from the same values — one stage-P per token per matrix, `tin` never written. f32 spellings
identical to K1→Q1 (trace bit-exact everywhere). Combined with owner-gather: rows1 222 → 183 µs;
E128/rows128 3599 → 3457; xval 1.355e-3. Lab split switch `EXL3_MOE_I8FUSE=0`.

## Shipped: counter-fed fused DOWN, float tier (`CoopDownK` = K5+K6)

`EXL3_MOE_B70_COOP` default ON (float tier, specialized rates, rows ≤ 8). Design copied from
CUDA `exl3_moe_coop` (see the doctrine section below): arrival counters, no barriers, no
cooperative grid.

- Default `NSL_D=1` register-accumulator variant: the single slice's gemv exit IS the full k-sum,
  so `toutd` never goes to global; ONE counter tier (`ctr2` per (token, 128-col blk)), one
  `it.barrier(global)` per transformer, and the last entry-arrival sums tsw rows in ASCENDING
  entry order and writes `out` — reproducing the old K6's exact accumulation order. The NSL>1
  two-tier fallback keeps slice-slot sums in fixed order too; **zero float atomics anywhere**.
- Zero-entry tokens are written by tail owner WGs (grid += rows*nbk); the `nc==0` degenerate job
  needs NO memset command anymore (bench `--skew -1` covers it; also fixed: `grow_p(size 0)`
  threw fake-OOM, and bench chunkers indexed `per_expert[-1]`).
- Counters ride the control blob (host zeroes the zone; blob H2D precedes consumers) AND K1
  re-zeroes them on the render engine (extra grid rows) — belt-and-braces after the cross-engine
  scare (which turned out to be harness races; the render-side reset costs ~nothing and makes
  the first-arrival-vs-DMA question moot by construction).
- `had128_strided` (see `platform-pitfalls.md` P10) makes the fused epilogue barrier-free.
- `coop_load` for same-launch cross-WG reads = device-scope relaxed atomic load, NOT the
  annotated_ptr read_hint spelling.
- Measured: bench split 170.2 → coop-D 158.8 (-6.7%); NSL_D=1 is part of it (split@NSLD=1 is
  160.3, so fusion itself nets ~1.5 in bench) — but **C-ABI 113.6 → 101.5/102.0 µs**, and
  models: 4.05 -mcs448 60.5 dec / 606 pre vs split-with-new-wait 59.3 / 537. 2.05 -mcs256
  decode 70.2-70.6 either way (flat, exactly as the decode anatomy predicts). ppl 2.05 mcs384
  r8: 2.524839 coop == 2.524839 split. xval rms 6.043e-07 → 6.5295e-07 (legit nsl_d=1
  slice-rounding shift, same class). `EXL3_MOE_B70_WAIT=1` = plain event `.wait()` (lab).
- **CoopGuK** (K2+K34 fused via `ctrG` per (chunk,blk)): implemented, bit-identical, battery
  green, PARKED default OFF (`EXL3_MOE_B70_COOPGU=1`). On the C-ABI decode shape it is at best a
  wash (D-fused 98.9 vs D+GU 100.6 at NSLG=2; at auto NSLG=7, 101.5 vs 109). The arrival+fence
  tax scales with unit count (`nc*nm*nbk*NSL_GU`) and the epilogue tail serializes the fused
  kernel's end. Retry only bundled with an NSL_GU retune and/or per-(entry) 2-arrival units.
- Command count recap (correction to older notes): the "6-kernel float pipeline" was really 5
  kernels + blob; coop-D makes it 4 kernels + blob + x/D2H = **6 queue ops** per decode forward;
  GU fusion would make it 5.

## CUDA small-m doctrine (study of `exl3_gemv*.cu/.cuh`, `exl3_moe_coop*`)

1. m≤8 gets a DEDICATED path (QTIP-structured "gemv" kernels), NOT the prefill GEMM — and it
   STILL USES TENSOR CORES: m16n8k16 with FP16 accumulate folded to fp32 every `FOLD=4` steps,
   `MMODE 0` = m==1 fast path, `MMODE 1` = row-guarded 2..8. Their m=1 fragment waste is tiny
   because the tile is small and the path specialized; OUR m8 DPAS (1/8 filled + 1 KB/kf A
   fetches) has no equivalent escape (Xe2 DPAS min m=8). That asymmetry, not the math, is why
   their answer at m=1 is "small-MMA" and ours must be "SIMT float" (which is what auto picks).
2. The QTIP part is pure memory/scheduling: warps split k with NO barriers in the main loop
   (16-way k-split inside a block, one smem cross-warp reduce at the end), register prefetch ring
   depth 4, evict-first streaming loads, and dispatch heuristics explicitly WAVE-QUANTIZATION
   aware (narrow config only while its grid fits a single co-resident wave; the 1..2-wave zone
   loses the gain; per-arch measured gates everywhere — e.g. the int8 GEMV is enabled exactly
   where the FP pipeline is compute/latency-bound: Ampere K≤5, Hopper/Blackwell K≤6 — NOT where
   DRAM-binds).
3. THE BIG ONE — `exl3_moe_coop`: decode-shape MoE layer forward in TWO ORDINARY LAUNCHES (no
   cooperative launch, no persistent grid, no `grid.sync`, no barrier anywhere): blocks write
   their slice to scratch and bump an ATOMIC COMPLETION COUNTER; the block that lands LAST for a
   unit runs that unit's whole downstream chain inline. Extra blocks past the actual work exit
   immediately. Slots with the same expert run as one multi-row m16 tile inside a block ("weights
   read once per run, not per slot"). bsz=1 skips the rotation launch entirely (done in-block
   into smem).
   This resolved the megakernel restart condition: we had required a "grid-sync primitive" —
   WRONG REQUIREMENT. Arrival counters chain stages without any barrier, so there is no
   co-residency ceiling and no phase starvation (the exact killers in our megakernel
   post-mortem: OUR version synced on phases, THEIRS chains on completions).
4. Precision: their int8 mode 1 pairs the int8 dot with an error-feedback residual pass for
   ~15-16-bit effective activations at fp16-KL parity (recorded as the known alternative to
   always-wide vh/vl if int8 decode-quality headroom is ever needed).

## Megakernel experiment: worked, then lost on its own premise (ripped out)

Built the single-launch int8 forward (`moe_mega.inl`, since removed): six pipeline stages as
phases of one persistent kernel with grid-wide arrival barriers, virtualized group coords reusing
the real kernel bodies. Fully reverted (the `exec()`/`exec_cluster` virtualization seam is not
needed by the split path).

Hard-won facts, worth keeping even though the thing is gone:
1. **wg barriers are not memory fences** — see `platform-pitfalls.md` P7.
2. **Pair-symmetric loops are mandatory** wherever two 128-thread halves run different units
   inside one 256-WG: ANY conditional `group_barrier` (hadamard128's seven, K6's WAR guard) must
   execute the same number of times in both halves — pair-max iteration counts with
   replay-and-skip-stores is the pattern that works.
3. **The F1 polarity trap**: Gemv8's third template parameter is F1 (frag1 ENABLED), not "slim".
   Mega passed SLIM straight through and silently zero-filled frag1 at m>4. The rows≤4 battery
   passed; rows≥16 caught it. (Same bug shape as the frag1 peeling poison.)
4. **Performance verdict (the reason to rip it out)**: barrier mechanics cost what t38 predicted
   (~2-5 µs/barrier at 32-128 WGs), but PHASING SERIALIZES the device. The gemv phases want the
   whole machine (rows=4/tk=8: 1240 tile-units); a megakernel grid must be ≤ co-residency, and
   DPAS WGs are register-fat: GRID=96 never completed (t38's thin-kernel ceiling of 160-280 does
   NOT transfer), and at safe grids (16-32) mega measured 2.5-6x SLOWER than the split pipeline
   at every shape including rows=1 decode (466 µs vs 183). The per-command overhead it removed
   (~5 x 4-10 µs) was never the dominant cost — starvation is.
5. An unresolved cluster-B store anomaly (one unit's stores landing in the wrong slice region at
   dual-cluster gemv-down; sentinel-probed, not root-caused before removal) — would need
   t37-style native dispatch to dig out; moot unless (4) changes.
Restart conditions: only with (a) native-L0 submission landing most of the command-cost win
anyway, or (b) an actual grid-sync primitive (cooperative launch / CLC) allowing full-size
disjoint grids per phase. Keep `t38_bar` as the barrier lab.

## Native-L0 submission: feasibility PROVEN, one blocker left

Question: can forwards be raw `ze` appends on ONE immediate command list (host cost ~2 µs/append)
instead of N SYCL submits (~4-6 µs host each + RT bookkeeping)?

Measured on this stack (CR 26.35, UR v2 adapter, oneAPI 2026.2):
- SYCL queue submits: ~3.7 µs each HOST; a 6-kernel chain + wait = 23-44 µs.
- Raw ze appends: 12-15 µs for the same 6-kernel chain (+wait). Immediate command lists are
  ALREADY the RT default on DG2+ (`UR_L0_USE_IMMEDIATE_COMMANDLISTS`, device default PerQueue),
  so the delta is handler/event-pool/capture overhead, not the lists.
- `level-zero-devel` installed; compile interop with `-lze_loader`. Current `ze_group_count_t` =
  3 fields; local size via `zeKernelSetGroupSize` OR `zeCommandListAppendLaunchKernelWithArguments`
  (args = `void*[]` of pointers to values; NULL `pParams` unused there). `zeModuleCreate` takes
  `hDevice` (1.16+).

Traps found the hard way:
1. `sycl::get_native(kernel)` handles from RT-JIT bundles ACCEPT raw launches (all rc=0,
   timestamps fire) but NEVER execute — not even a no-builtin `single_task`. RT-module kernel
   handles are not for external consumption. (t35)
2. Appends to a `zeCommandListCreateImmediate` list built on `get_native(context)` appeared to
   execute: they FAULTED SILENTLY and later segfaulted NEO's staging copies. Lesson: one list,
   the queue's own.
3. **WORKING COMBINATION (t36/t37)**: OWN module from OWN SPIR-V inside the SYCL context
   (`get_native<context>`) executed on the queue's OWN immediate list
   (`get_native<queue>` holds the `ze_command_list_handle_t` when in-order+immediate): correct
   args, correct `get_global_id/get_group/get_local_id`, correct subgroup collectives. Verified
   with `nd_item` + `reduce_over_group` kernels.

SPV pipeline for SYCL-flavored kernels (t37; needed for joint-matrix kernels):

    icpx -fsycl -fsycl-targets=spir64 -save-temps -c k.cpp      # device bc
    sycl-post-link <...spir64...>.bc -ir-output-only -spec-const=native -o tl
    llvm-spirv tl -o k.spv                                      # entries: _ZTS2nk etc.

Entry names = mangled typeinfo of the kernel-name class, stable for a given build. `ocloc`
(`-device bmg`) is the fallback for plain kernels (emits both .bin and .spv).

Verified on the PRODUCTION TU (t42/t43, not toy kernels):
1. `moe_sycl.cpp -c -save-temps` → `sycl-post-link -ir-output-only -spec-const=native` →
   `llvm-spirv -spirv-ext=+SPV_KHR_cooperative_matrix` ⇒ VALID 243 KB SPV; the `erff`
   undefined-symbol warning is harmless (`zeModuleCreate` accepts the module; 27 kernels, names
   are `_ZTS...` mangled, `strstr`-selectable). Completion via plain `q.wait()`.
2. Functor kernel ABI via `zeKernelSetArgumentValue` probing: args are EXACTLY
   `{captured ptrs..., by-value capture struct, local_accessor as one 8B ptr}`; `nd_item` adds NO
   visible args. `WithArguments` validates count strictly — a short array memmove-segfaults
   INSIDE NEO, so never probe counts by crashing.
3. **BLOCKER = SLM binding for the accessor arg.** Module metadata says `localMemSize=0`; any
   host/device pointer passed as the local arg does NOT bind shared memory (kernel completes
   rc=0, writes vanish); nullptr + barriers deadlocks the queue. The SYCL runtime uses
   driver-internal local binding invisible on the public ze surface.

Next step (sanest path first, per `../PLAN_L0.md`): build an SPV variant with `-DMOE_L0_NO_SLM`
that points the band/ring slabs at per-layer GLOBAL USM scratch (kernels become pure-global,
trivially `WithArguments`-launchable; slim-path bands are tiny so SLM→global cost should be
small — MEASURE on bench shapes); only if that regresses, reverse-engineer the UR/L0 `KernelImp`
local-arg trick. Upside if achieved: ~20-45 µs/layer x 48 at decode — though note the polling
fix (`measurement-discipline.md`) already removed the fattest slice of per-command slop, so the
honest remaining estimate is ~4-6 µs/submit host-side.
---

# Research 2026-10-28 (late night): the SYCL/L0 stack's own options for decode

Sources: the vendor runtime tree (`~/projects/vendor/llvm/sycl`, docs in `doc/syclgraph/` +
`doc/design/CommandGraph.md` + `doc/EnvironmentVariables.md`), the installed 2026.2 headers, a
driver-extension enumeration against *this* GPU (`lab_graph*` below, `/tmp/l0probe/exts.cpp`), and
the Level Zero spec for the extension pages. Labs: `sycl_moe/lab_graph.cpp`, `lab_graph3.cpp`
(`icpx -fsycl -O2 <f>.cpp -o <f>`, no profiler, burn-in, min-of-3).

## 1. SYCL command graphs — measured win, no kernel-image surgery, RECOMMENDED NEXT STEP

`sycl::ext::oneapi::experimental::command_graph` (aspect `ext_oneapi_graph` = **supported** on the
B70) maps to UR command buffers, which on Level Zero use
`zeCommandListImmediateAppendCommandListsExp` (the driver advertises
`ZE_experimental_immediate_command_list_append`) — the whole captured chain becomes ONE immediate
append with one wait event and one signal event, instead of N submits through UR→PI→L0. UR also
splits captured memory ops onto a copy queue and kernels onto the compute queue.

| chain (each = one decode-shaped forward, host waits at the end) | submits | graph replay | ratio |
|---|---|---|---|
| H2D + 6 kernels + D2H (`lab_graph`, 8 commands) | 22.98 us | 14.22 us | **1.62x** |
| same, 8 replays in flight before one wait | 22.98 us | 13.68 us | 1.68x |
| H2D job block + 3 kernels (`lab_graph3`, 4 commands) | 15.37 us | 10.49 us | **1.47x** |
| one `single_task` + wait = the 1-command floor | — | 5.90 us | — |

So ~2.1 us per command through submits, ~1.0 us per command inside a graph, plus a ~6 us fixed
round trip. Decode's float-tier chain is 3-5 commands + 2-3 copies ⇒ expect **~5-9 us off every
B70 forward** (~250-430 us per token over 48 layers: roughly +2-4% decode on 2.05bpw, more for the
6-7-command int8 chain that spec-decode/batched rows 2-8 run).

**The design problem is that a graph bakes in kernel arguments and grid sizes.** Solved without
`dynamic` machinery, and validated in `lab_graph3.cpp`: put the per-job values (rows, nc, chunk
bytes…) in a **pinned host "job block"** whose H2D copy is *inside* the graph — a replay re-reads
the host buffer (500/500 trials with changing values, bit-exact against a host-computed
recurrence), so the host just writes bytes and replays. Grids then need a bucket: capture a graph
per (layer, tier, nc-bucket) with the kernels early-exiting on `chunk >= nc_from_job_block`
(the chunk list already lives in the control blob, and the extra workgroups are ~free at these
sizes). Alternative if buckets get awkward: `sycl_ext::property::graph::updatable` +
`dynamic_parameter`/`dynamic_command_group` + `execGraph.update(node)` — present in the 2026.2
headers, but `update()` host-synchronises per the usage guide, so it is for occasional changes
(a new expert pointer after `b70_update_expert`), not the hot path.

Caveats to gate on: graph objects are per-layer-persistent (build at registration, ~48+ objects);
`q.ext_oneapi_graph(g)` is deprecated in favour of `q.graph_exec(g)` (same call); the extension is
experimental so keep a runtime fallback (if finalize/first replay throws, stay on submits — same
posture as the .so/`dlopen` fallback); correctness gate = the usual `--i8trace` battery *plus* a
model decode A/B, and any pointer that can move (`ensure_capacity` growth, `grow_p` rebinds) must
trigger a re-capture — that is the same footgun class as the stale-pool-pointer incident.

## 2. Runtime environment knobs — screened for decode, ALL NEGATIVE (do not retry)

`perfab.sh decenv`, `perf.py -spf -dr 3` (decode averaged over ctx 0…3840), one round per arm,
control bracketing: control = **68.3 t/s**.

| env (in the worker process, which owns the SYCL queue) | dec | Δ |
|---|---|---|
| `SYCL_UR_USE_LEVEL_ZERO_V2=0` (old adapter; V2 is default on Xe2+) | 65.9 | **-3.6%** |
| `SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS=0` (batched command lists) | 65.1 | **-4.6%** |
| `SYCL_PI_LEVEL_ZERO_USE_COPY_ENGINE=1` | 61.8 | **-9.5%** |
| `SYCL_PI_LEVEL_ZERO_USE_COPY_ENGINE_FOR_H2D=1 _FOR_D2H=1` | 64.1 | **-6.1%** |
| `SYCL_PI_LEVEL_ZERO_IMMEDIATE_COMMANDLISTS_EVENT_CLEANUP_THRESHOLD=64` | 66.5 | -2.7% |
| `SYCL_PI_LEVEL_ZERO_USE_COMPUTE_ENGINE=1` | 67.4 | -1.3% |

Conclusion: today's defaults (V2 adapter + immediate command lists + copies on the compute engine)
are the optimum; copy-engine offload is actively bad for this workload (extra queue + cross-queue
event per copy). Those numbers are also evidence that the remaining decode cost is *per-command
driver work*, which is exactly what graphs reduce — a different mechanism than queue choice.

## 3. Not available on this hardware/driver (measured, saves someone a week)

Enumerated the 63 extensions of the loaded driver (`zeDriverGetExtensionProperties`, loader 1.33.1,
driver 259.39758, runtime 26.35):

* **No IPA / ML-IPA** (no `ZE_experimental_ipa*`, no IPA symbols in `libze_intel_gpu.so`) — the
  "instruction prefetch agent" trick for many-small-kernel chains does not exist on Battlemage.
* **No mutable calls / resident kernels** (`zeMutableCall*` absent) — the zero-launch-doorbell
  persistent-kernel design is off the table; the megakernel-with-barriers result already showed
  phase-sync starvation anyway.
* **`max_compute_queue_indices = 1`** on the B70 (queried via
  `sycl::ext::intel::info::device::max_compute_queue_indices`) — so `property::queue::compute_index`
  (and the old L0 "low-latency queue index") offers nothing here.
* Present but **only reachable from a native-L0 path**: `ZE_experimental_mutable_command_list` 1.1
  (patch kernel args/grids of a recorded command list without re-appending — would remove the
  "pre-build the arg buffer and rebuild on every realloc" footgun in PLAN_L0),
  `ZE_experimental_event_pool_counter_based` + `ZEX_counter_based_event` (cheaper events than the
  default pool — relevant to the completion poll),
  `ZEX_intel_experimental_queue_copy_operations_offload_hint`, `ZE_experimental_scheduling_hints`
  (`zeKernelSchedulingHintExp`, introduced in L0 1.2; semantics are priority-ish hints, no CUDA-PDL
  equivalent), and `ZE_extension_record_replay_graph`/`ZE_experimental_record_replay_graph`
  (what graphs ultimately use; also allows capture directly on an *immediate* command list).

Implication for **PLAN_L0**: graphs already capture 1.3-1.6x of the command cost with zero
SPIR-V/module work, and the 1-command floor is ~6 us, so the *remaining* headroom for raw
`zeCommandListAppendLaunchKernel` appends after graphs is only a few microseconds per forward.
Recommendation: do graphs first; keep PLAN_L0 (with `ZE_experimental_mutable_command_list` as the
answer to its arg-mutation and SLM-binding problems) as the follow-up if the residual floor hurts.

## 4. Two cheap host-side items found in the headers while doing the above

1. `sycl::ext::oneapi::experimental::register_host_memory(ptr, bytes, context, flags)` — register
   a plain host allocation with the driver so USM copies DMA it directly. `b70_lib` currently does
   `memcpy(g_stage.stage_u16, x, rows*H*2)` then `q->memcpy(d_x, g_stage…)` and the mirror image on
   the way out (`d_out → g_stage → caller's slot`) — ~15 KB per row of double handling, which at
   prefill tail sizes is hundreds of MB per token-pass. Either register the caller's pinned handoff
   segment (it is already page-locked for CUDA) or make `g_stage` a `sycl::malloc_host` buffer and
   drop the intermediate memcpy entirely: one command and one CPU copy less per forward.
2. `sycl::ext::oneapi::experimental::reusable_events` (+ `event_mode`/`low_power`) — the decode
   path creates/signals/polls ~4-8 events per forward, and the completion wait polls
   `event::get_info<command_execution_status>()` (a driver call per poll). Reusing an event pool
   instead of fresh event objects is the cheap version of the counter-based-event idea above.

## Correction after the production-shaped lab (`lab_graph4.cpp`) — graphs are ~1%, not 1.5x

`lab_graph.cpp`/`lab_graph3.cpp` above used near-trivial kernels, so *submission* dominated the
measurement and the ratio looked like 1.47-1.62x. `lab_graph4.cpp` replays the chain with
production shapes (`nd_range<2>` + `local_accessor` + device-scope `atomic_ref` RMW on the blob's
counter zone + an external dependency event + a job-block H2D node) and the ratio collapses:

| commands in the forward | submits | graph | saved | saving/command |
|---|---|---|---|---|
| ~5 (memcpy + 3 kernels + gather) | 14.84 us | 13.12 us | **1.74 us** | ~1.2 us |
| 7 | 19.46 us | 16.72 us | 2.74 us | ~1.1 us |
| 9 | 25.89 us | 20.36 us | 5.53 us | ~1.2 us |
| 13 | 36.10 us | 27.48 us | 8.62 us | ~1.1 us |

Correctness result stands and is the useful part: **graphs do carry our kernel shapes** (0 bad /
300 replays with the host rewriting the pinned job block and an external dep event each time), so
the mechanism is available if it is ever needed. But the payoff is ~1.2 us per command *only when
the kernels are big enough to hide submission already* — i.e. 48 forwards/token x ~2-5 us =
+0.7-1.4% decode on 2.05bpw, at or below the ±3% / 1 t/s noise floor. **Verdict: do not spend the
complexity** (per-geometry graph caches, invalidation on every moving pointer, an experimental API
in the hot path) for that. Lesson for the archive: a command-overhead lab must use kernels with
production-like duration, or it measures the wrong thing — the same class of error as
`measurement-discipline.md`'s "short benches lie".

## What decode is actually bound by: gemv weight bandwidth at 11-24% of peak

`bench_layer --e 260 --topk 10 --iters 800` (harness prints `weights => GB/s`; sustained, this is
the same E as the model's worker tier; rms columns confirm tier/rate: float 1.1-1.4e-6, int8
1.3-1.4e-3):

| rows | float tier | int8 tier |
|---|---|---|
| 1 | 161.3 us — **76.2 GB/s** | 185.1 us — 66.4 GB/s |
| 2 | 327.7 us — 71.2 GB/s | 225.5 us — 103.5 GB/s |
| 4 | 566.4 us — 84.6 GB/s | 370.2 us — 129.4 GB/s |
| 8 | 912.7 us — 92.9 GB/s | 578.8 us — 146.5 GB/s |
| 16 | 1664.4 us — 87.9 GB/s | 1004.5 us — 145.6 GB/s |
| 32 | 2724.7 us — 84.3 GB/s | 1615.7 us — 142.2 GB/s |

Against 608 GB/s spec (674 GB/s measured D2D in `measurements-ledger.md`), the best we ever do is
**24%**, and decode (rows=1, the shape every token pays 48 times) sits at **12-13%**. Neither the
FLOPs nor the bandwidth is saturated at rows=1: 12.3 MB of weights ~ 46 M weights x 2 flop x 1 row
= 92 MFLOP in 161 us = 0.57 TFLOP/s of 22.7, and 76 of 608 GB/s — so the kernels are
**latency/dependency bound**, not resource bound. That single fact explains both workloads'
residual cost: prefill's cold tail (11.8 us per nearly-empty chunk) and decode's floor are the same
problem, and it is the one lever left worth real effort.

Free-knob probe of the obvious hypothesis (too few workgroups in flight → deepen split-K):
**rejected, and the current auto choice is already the best** (`bench_layer --e 260`, median):

| `MOE_NSL` | rows=1 | rows=4 |
|---|---|---|
| 0 (auto) | **161.5 us / 76.1 GB/s** | **370.3 us / 129.4 GB/s** |
| 2 | 171.3 / 71.8 | 379.0 / 126.5 |
| 4 | 177.5 / 69.2 | 379.7 / 126.2 |
| 8 | 186.9 / 65.8 | 412.7 / 116.1 |
| 12 | 190.7 / 64.4 | 412.7 / 116.1 |
| 16 | 202.3 / 60.7 | 412.5 / 116.2 |

More slices cost monotonic time, so the limit is not WG count in the k dimension — it is the
per-workgroup serial k-walk (load -> trellis decode -> FMA dependency chain) not being deep enough
to keep memory busy. Which points the investigation at: outstanding-load depth per thread, the
decode/bytesum chain length between loads, and per-WG tile shape (n-subgroup count) rather than at
more split-K or at submission mechanics. (Related negative results already on file: `(tk&3)`
depth-4 prefetch array, wide 128-lane WGs without the ring, annotated_ptr hints —
`archive/kernel-microopt.md`, `archive/platform-pitfalls.md` P10.)

## 2026-10-28 (03:00-04:00): where the decode forward's 161 us actually is

Two new instruments, both host-side only (rule 3: no device hooks):
`EXL3_MOE_B70_HOSTPROF=1` (per-stage host gap|submit-cost, printed every 256 forwards) and
`lab_i8gemv.cpp` (same logical work, three weight representations, prints real and
packed-equivalent GB/s).

### Stage attribution, `bench_layer --e 260 --rows 1 --topk 10` (median 161 us, unprofiled)

| stage | span (`--v`, inflated) | packed bytes | rate |
|---|---|---|---|
| K1 prep_gu | 2.6 us | – | – |
| (gap before gemv_gu) | 18.0 us | – | – |
| K2 gemv_gu (gate+up) | **51.4 us** | 8.2 MB | **160 GB/s** |
| K34 act+prep_d | 4.1 us | – | – |
| K56 coop-down | **28.4 us** | 4.1 MB | **145 GB/s** |

**So the harness's `=> 76 GB/s` headline is an end-to-end number, not a kernel number: the two
gemvs themselves run at 145-160 GB/s.** `lab_i8gemv.cpp` reproduces exactly that for the packed
bit-window access pattern alone (variant A, 10 experts, no split-K, no pipeline: 145 GB/s), which
means *the production gemvs are at the ceiling of their own access pattern* — the remaining ~75 us
of the forward is command/wait latency (and `--v` inflates spans by ~40 us, so treat the split as
indicative, not additive).

### What the packed representation costs, and what a byte-aligned one would buy

| `lab_i8gemv` variant (K x N x E matched to the decode job) | time | real GB/s | packed-equivalent GB/s |
|---|---|---|---|
| A packed bit-window gather (today's layout), E=10, K=2560 N=640 | 56.6 us | 145 | **145** |
| A packed, same shape, E=20 (2x workgroups) | 64.6 us | 254 | **254** |
| A packed, down-like shape (K=640 N=2560) | 31.4 us | 261 | **261** |
| B pre-decoded int8, contiguous k, pair dots, E=10 gu | 30.6 us | 535 | **268** |
| B pre-decoded int8, down-like | 27.2 us | 603 | **301** |
| C same loads as B, **math removed** | 30.6 / 27.1 us | 536 / 603 | 268 / 301 |

Three conclusions, in priority order:

> **[SUPERSEDED 2026-10-29.] Conclusion 2 below is wrong: at these rates the weights are 16-bit
> trellis states advancing K2/2 bits, so a byte-adjacent per-lane window needs 32/K2 = 8x
> duplication at K2=4 — there is no density-neutral repack to build. Conclusions 1 and 3 survive
> only as statements about access patterns; the "268-301 GB/s packed-equivalent ceiling" was bought
> with 4x the bytes and is not a ceiling for the packed tier. See the 2026-10-29 section, and note
> that the paragraph this section ends with (about host submission) is also void — broken profiler.**

1. **B ≡ C to within 0.1 us: with a byte-aligned weight layout the dot product is FREE — that
   kernel is pure memory.** So decode's gemv cost is *representation*, not arithmetic: the trellis
   bit-window read (7 overlapping u32 gathers per 16 columns per lane) is what caps us at
   ~150 GB/s, and a byte/nibble-aligned ordering runs at the machine's small-stride ceiling
   (~530-600 GB/s of bytes actually read).
2. **The clean version of the fix costs no extra VRAM**: re-order the *same* 4 bits/weight at
   upload so each lane's 16 k-values are byte-adjacent (nibble-aligned, k-contiguous per column)
   instead of bit-window-interleaved. Measured ceiling from row B/C: ~2.6-3.7x on the gemv, i.e.
   decode forward ~161 → ~100 us if it lands halfway. Requires: a second stream repack
   (`repack_native_to_stream_words` sibling), a `GemvNibble` instantiation, tier selection, and a
   host reference for the new path (the i8trace discipline applies: device + host ref + harness
   move together, `moe_layout.hpp` is the single source).
3. Keeping a *pre-decoded int8 copy* of the worker tier is **not** the answer: 4x the bytes does
   not fit (15.7 GB packed → 61 GB), and per row B/C it buys nothing over (2) once the layout is
   byte-aligned. It would only make sense as a small hot-expert cache.

### Also measured: host submission is NOT the remaining cost

`EXL3_MOE_B70_HOSTPROF=1`, steady state: every stage's host `sub` < 0.05 us/forward and `gap` ≈ 0.
(The first 256-forward window shows one 69 us `submit` at stage 2 — a first-use/one-time cost, not
a per-forward one; it vanished in every later window.) Independently confirms the `lab_graph4`
slope: there is nothing left for command graphs or host-side trimming to win here, and it retires
the last argument for PLAN_L0.

**[SUPERSEDED 2026-10-29 — this paragraph is VOID: the profiler was broken (`begin()` never reset
its stage index, so nothing accumulated after ~2 forwards and later windows printed nothing). The
same submits measure 2.6 us in an isolated lab, ~5.4 us in the model, ~21 us in the harness. See
the correction below. The `lab_graph4` *wall* slope (~1.2 us/command) still stands independently.]**

## 2026-10-29 (08:20-09:40): CORRECTION — decode's wall is per-forward FIXED cost, and 41% of it is host submission

Started as "implement the nibble-aligned repack". It died on the encoding's actual atomic unit, and
the follow-up measurement inverted the picture. All numbers below are from the MODEL (2.05bpw,
decode-only `perf.py -spf -dr 3`) with `EXL3_MOE_B70_ALLOCLOG` phase fields, except where a lab is
named.

### 1. The decode budget (29 432 rows=1 job pairs; log `/tmp/dec_c.log`)

| phase | p50 us | mean | p90 | what it is |
|---|---|---|---|---|
| prep | 0.8 | 0.8 | 1.1 | expert lookup + chunk/token-map build |
| h2d | 3.2 | 4.3 | 6.0 | x host copy + x H2D submit (dep = previous forward's D2H) |
| **sub** | **27.2** | 30.2 | 38.5 | **`moe_sycl::forward`: blob H2D + 4 kernel submits** |
| d2h | 2.9 | 3.1 | 3.8 | out D2H submit |
| wait | 28.6 | 33.8 | 50.3 | blocked until completion is observed |
| cp | 0.4 | 0.5 | 0.7 | copy out |
| **total** | **66.1** | 72.7 | 88.7 | |

By job size (medians): nc=1 63.9, 2 67.0, 3 71.0, 4 82.0, 5 87.0, 6 88.2, 7 100.9, 8 104.9, 9
114.0 → **t(nc) = 57.6 + 6.3·nc**. Per token: 48 × 66 = 3.2 ms of 14.7 ms = **22% of decode is the
B70 path, 87% of that is fixed cost**, and the *marginal* expert already runs at 1.2288 MB /
6.3 us = **195 GB/s** (isolated-lab ceiling for this access pattern: 254). Streaming is not the
problem; per-forward latency is.

Average decode job touches only **2.15 experts** (65 468 chunks / 30 432 jobs) — the harness's
`--topk 10` decode shape is 4.6x the model's real job, which is one reason harness work kept
failing to transfer.

### 2. The harness number is inflated ~2.4x by its own submission cost

`bench_layer` reports 161 us/"decode forward" (median of `e1.command_end - e0.command_end` around
one forward). With HOSTPROF fixed, that same run spends **110 us of host time in 5 submits
(~21 us each)**; the model spends ~29 us on the same 5 actions. `--bare` (two barriers, no work)
measures a 33.5 us floor for the pattern. Consequences: the harness's "76 GB/s" and "gemv = 46% of
the forward" readings are harness properties, and its `--v` spans (gu 51.4 us at 10 experts) describe
a job 4.6x bigger than the model's. Model-level A/B is the only valid arbiter for decode work.

### 3. Why a submit costs what it costs — `lab_submit_busy.cpp` (host time, 5 chained actions)

| regime | us/submit |
|---|---|
| A drained queue, chained `depends_on` | 2.70 |
| B ~1 ms kernel occupying the queue, chained | 2.81 |
| C busy queue, NO `depends_on` (in-order only) | 2.58 |
| D drained but inside the harness's barrier-bracket pattern | 2.72 |
| E + `local_accessor<float>{128}` | 2.62 |
| F + two local_accessors ({128},{2}) | 2.55 |
| G + RUNTIME-sized `local_accessor` (int8-tier shape) | 2.62 |
| H `nd_range<2>` (K1/K6 launch shape) | 2.62 |
| I 40-word functor (GemvBase bulk), no accessors | 2.54 |
| J E + requested 16-lane subgroups (GemvK's property hook) | 2.70 |
| 1 pinned-memcpy submit | 2.32 |
| **plugin `moe_sycl::forward`, in the model** | **3.4 / 10.3 / 4.8 / 5.0 / 5.9 (mean 5.4)** |
| **same code under `bench_layer`** | **21-23** |

Queue state, dependency chaining, barrier bracketing, SLM allocation, argument bulk and the subgroup
property are ALL ruled out. The 2.6 → 5.4 → 21 us progression is unexplained; it tracks neither
dependencies nor kernel shape. Next (and last) experiment on this thread: raw
`zeCommandListAppendLaunchKernel` ×4 + one `zeCommandListExecute` for the same chain — if that lands
near 2.6 us, PLAN_L0's value is "avoid the runtime's per-action cost", priced at ~20 us/forward
(~0.9 ms/token, ~6% decode), and nothing less is worth building.

### 4. Command graphs, re-priced on the HOST axis — still no

`lab_graph4.cpp` gained a host-only arm (burst of 50 chains submitted without waiting, device busy):
**submits 9.95 us vs graph replay 12.24 us** for the same production-shaped chain. A replay costs at
least as much parent-thread time as the commands it replaces, so graphs cannot attack `sub` either —
independent of the earlier wall-axis verdict (~1.2 us/command). Yesterday's "graphs are dead" was
right for the wrong reason; this is the right reason.

### 5. `MOE_GEMV_NC` (column-block width) — kernel win, model loss

`lab_gemv_shape.cpp` at fixed lanes and bytes: 128 cols → 64.9 us, 64 → 33.2, 32 → 18.0, 16 → 10.9,
256 → 130.3; DEPTH 1/2/4 within 0.2 us (so: not latency-hiding, but work distribution). Implemented
in `GemvK` (single-slot decode path only, contract rates only, `nbk = N/ncwg`, grid patched with it).
Bit-identical as predicted (max_rel 1.882e-06 / rms_rel 1.070e-06 at every width; each column's
k-order untouched, no partial sums, unlike `nsl`). gu span 51.5 → 31.7 us. Model: dec_avg 68.9
(128) / 67.8 (16) / 67.5 (32), prefill unchanged → keep default 128, knob retained.

### 6. Ablation ladder on the real K2=4 loop — `lab_gemv_ablate.cpp`

Baseline mode 0 reproduces the production inner loop faithfully (16-lane subgroups, NW=5 ring
gathers, per-tile pre-shift, depth-2 pipeline, per-weight extract+magic-multiply+bytesum+cvt+FMA,
activations read per lane per tile): 64.5 us for one 4.10 MB matrix (E=10, K=2560, N=640).

| ablation | us | reading |
|---|---|---|
| 0 full | 64.5 | reference |
| 1 no weight loads | 48.1 | loads are ~25% |
| 2 **no activation loads** | **84.0** | removing work made it SLOWER → not issue-bound |
| 3 no bytesum | 52.7 | the multiply+pairsum idiom ≈ 18% |
| 4 no state extract | 49.2 | the funnel-shift path ≈ 24% |
| 5 activations staged in SLM | 66.3 | neutral |
| 6 whole-ring `uint4` loads | 67.1 | neutral (coalescing the ring does not help) |
| 7 activations as 4 × `float4` | 63.9 | neutral |

Lab hygiene note: the first version hoisted all 16 activations into a register array before the
consume loop and came out 2.5x SLOWER than the kernel it modelled (63 vs 160 GB/s); inline-per-rk
loading, as production does, is mandatory for a faithful proxy.

### 7. Repack premise, closed

`archive/mul1-trellis-spec.md` + `moe_sycl.cpp:363-500` settled it: the stream layout stores a ring
of `W = 4·K2` u32 per 16×16 tile, and each weight's state is 16 ascending bits advancing by K2/2
bits per state. At K2=4 that is 2 bits of new information per 16-bit read. Byte-adjacent per-lane
windows therefore require 32/K2 duplication (8x at 2 bits/weight, 2x at 8 bits/weight) — i.e. the
"free math" lab rows were bought with bytes we do not have. There is no density-neutral nibble
repack to build.
