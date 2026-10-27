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