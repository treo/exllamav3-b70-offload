# Platform pitfalls: oneAPI 2026.2 / L0 / NEO / Xe2 (B70)

Everything here is a property of THIS stack (or at least was measured on it), not of the
algorithm. Reread before touching anything async. Environment: oneAPI 2026.2, NEO 2.41+/CR
26.35, DG2+/BMG-G31, in-order `sycl::queue`, `xe` kernel driver.

## P1 — Queue ordering: only explicit dependency edges are honored (the one-day bug)

Within an **in-order** `sycl::queue`, `q.memcpy()` does NOT wait for kernels submitted
earlier via `q.submit()`, and an event `.wait()` can complete before the data is
host-readable. Consumers read STALE data (usually zeros). Barriers
(`ext_oneapi_submit_barrier`) and empty separator kernels did NOT help; only true event
dependencies do.

- Fix (permanent, `moe_sycl.cpp`): EVERY op — H2D, kernel, D2H — is chained through
  returned events (`cgh.depends_on(prev)` / `memcpy(..., {deps})`); `b70_forward` keeps
  `g_last_ev` across calls. Handler signatures return the event for this reason.
- Symptom catalogue, all ONE cause: "first forward wrong, later forwards right",
  "retry fixes it", "adding a probe fixes it", "the second call is correct" — extra queue
  ops acted as implicit syncs.
- Corollary for harnesses: any lab that submits queue work MUST chain with `depends_on` /
  `pre_dep` exactly like production. "Fails deterministically until I add a sync" ==
  ordering race, full stop. This bit the port twice, the second time in our own bench
  (`--alt` fired forward N+1's blob memcpy — which zeroes the coop counter zone —
  unchained behind forward N's kernels; the fused epilogue flag never fired and `out` came
  back BYTE-IDENTICAL to the previous dataset. Kernels were correct all along).
- Unchained repeated launches of a publication microbench produced ~58% "failures"
  INCLUDING reads of FUTURE launches' values (physically impossible under serialized
  execution → the giveaway that launches overlapped). Once chained: 0/1.23M mismatches for
  plain store + `it.barrier(global_space)` + acq_rel `fetch_add` + device atomic loads.
  That publication chain IS sound on this stack, single-kernel; kernel boundaries handle
  cross-kernel visibility.

## P2 — Probe reads are queue ops

Device readbacks serialize and change what later probes see. When chasing nondeterminism,
dump state ONCE right after `q.wait`; beware summing big probe buffers that span memory
written by other kernels (false positives). Worse: in-kernel probe scaffolding repeatedly
polluted what it measured (dump regions clobbering flag slots; probes that bypass the very
datapath under test). Policy now: **kernels contain zero debug hooks**, all verification is
external readback + per-stage host emulation fed from device readbacks of that stage's OWN
inputs.

## P3 — Device allocation governance near VRAM capacity

NEO/L0 does NOT reliably return null from `malloc_device` near capacity; the failure surfaces
LATER as an async `UR_RESULT_ERROR_OUT_OF_DEVICE_MEMORY` (39) throw from `memcpy().wait()` or
a kernel launch — which crossed the plugin's C ABI and killed the worker. Governance in
`b70_lib.cpp`:
1. soft budget (fraction of `global_mem_size`, `EXL3_MOE_B70_BUDGET`) checked BEFORE every alloc;
2. every device alloc recorded in `Upload.keep` BEFORE its copy, so any throw still rolls back;
3. `b70_register_layer` catches all exceptions → returns -1 (layer stays on CPU) and sets `dev_full`;
4. `b70_forward` returns int; nonzero → `moe_mul1` pins the layer to CPU for good;
5. `grow_p` OOM must THROW (caught → clean pin), not produce null-pointer device faults.
Plus the `g.poison` latch: first forward exception latches the plugin and every later
forward returns 3 instantly (never touches the dead queue); completion wait is bounded
(15 s deadline polling `get_info<command_execution_status>`; DPC++ has no
`event::poll`/timed `wait_and_throw`). Before this, one fault meant an infinite parent spin.

## P4 — Host writes into `malloc_device` memory SEGFAULT

On L0/B70 + oneAPI 2026.2, writing device-USM from the host faults. The "skip the H2D
memcpy by writing the blob directly" idea is dead. `malloc_shared` would page-migrate per
access and lose worse.

## P5 — `q.copy` argument order and stability

`q.copy(host.data(), dev_ptr, n)` copies HOST→DEVICE (`Source, Dest`) — an intuitive-looking
readback silently clobbers results ("GPU faults" that were really self-inflicted). Also
`q.copy()` H2D from pageable host memory SEGVs inside NEO staging in standalone labs: use
`q.memcpy`.

## P6 — nd_range arithmetic

Global dim must be a multiple of local in EVERY dim; use `{N*128, groups}` with local
`{128,1}`. `get_group(d)` is the GROUP id, `get_global_id` the item id.
**groups = global/local, not global.** An apparent "16x grid-inflation bug"
(`g0 = (N/16)*16*nsl`) was never a bug: the `*16` is the local size. "Fixing" it amputated
15/16 of the slices; the I8DUMP showing only slice 0 alive is what caught it. Confirmations
that it was the fake fix: nsl=1 immune, nsl≥2 broken, 40-60% values missing, pad-zeros intact.

## P7 — Work-group barriers are not memory fences

At device scope, `item.barrier()` does NOT publish other WGs' stores. Symptom:
deterministic-looking "partial sum" corruptions (ratios 0.72/0.16...) in a multi-phase
kernel. Fix: `it.barrier(sycl::access::fence_space::global_space)` around arrival/spin.
`sycl::atomic_thread_fence` does not exist in 2026.2. Split kernels never show this because
kernel boundaries flush implicitly.

## P8 — Alignment for `joint_matrix` 2D block loads

`jm_load` from global faults the 2D block engine (device loss, same symptom as a Gemv8P OOB
read) unless the address is 64B-clean: nsl values where `(slot*nsl+sl)*nfl*512 % 64 != 0`
crash. Watch SLM/global alignment for anything jm-loaded. Also `stride*sizeof(T) % 8 == 0`
is required for joint_matrix operands.

## P9 — joint_matrix / DPAS facts

- B operand must be `layout::ext_intel_packed` (VNNI 4-row-block packing), else ~150
  mov/join fixup ops per fragment eat XMX's whole budget. Row/col-major B from SLM is
  numerically right (col-major == VC ordinal order) but slow.
- `joint_matrix` collectives need CONVERGENT control flow (no divergent barriers).
- The GLOBAL A load lowers to a per-lane byte gather: it cost ~2.8x the whole gemv
  (see `int8-dpas-tier.md`, labs t39/t40). joint_matrix cannot take a packed i8 A operand
  (no IGL builtin — the compiler error even prints the intended `v8i8` lowering name).
- BMG-G31 supports s8xu8→i32 M≤8, N16, K32. Xe2 DPAS minimum m=8: at m=1, 15/16 A rows are
  wasted and the A fetch is 1 KB per kf block whether 1 or 8 tokens are live.
- `xmx::dpas<C,B,A>` in GENERIC `parallel_for` kernels is a dead end: operand simds must be
  FULL-matrix sized (static_asserts), uniform fills materialize 512B/lane (lab3: 770 scalar
  loads), and slice-writes `b[lane*32+i]=..` are undefined-ish (partial zeros, DCE, wrong
  slots). A `single_task` launch made it numerically correct (VC replicated model) but operand
  refills per step stayed expensive.
- `ext::oneapi::experimental::dot` / `dp4a` SYCL ext is NOT hardware-accelerated here (same
  speed as manual bytes) — don't plan around it.
- esimd `dp4a<i32>` on `(u32,u32)` silently lowers to the SIGNED-operand sibling
  (`llvm.genx.sudp4a`) → WRONG bytesums, and `simd<,1>` scalar use in generic kernels is
  ~2.5x slower than the 5-op mask chain. Do not touch esimd outside esimd kernels.
  Inside esimd kernels, per-thread `xmx::dpas<8,8,int>(acc,b,a)` with s8/u8 works TODAY
  (`t40_esimd.cpp`, operand layouts verified by impulse probes) — that is the endgame.
- `IGC_JointMatrixLoadStoreOpt=1` exists and forces the SLOWER path. Do not set.
- ISA check: no spills in GemvK paths (`-abortOnSpill 4` in effect; `scr.*` absent from dump).

## P10 — Cache hints and compiler switches that do nothing (or hurt)

- `annotated_ptr` + `read_hint` (streaming L1/L2, or `uncached,L1`): never demonstrated an
  effect on this stack; kept behind `MOE_GEMV_CACHEHINT=define` for completeness. For
  same-launch cross-WG reads use a **device-scope relaxed atomic load** (`coop_load`), which
  demonstrably hits L2. A static-data bench CANNOT see missing L1 bypasses — use
  `bench_layer --alt`. Correct hint spelling, for the record:
  `expe::annotated_ptr<const uint32_t, decltype(expe::properties{inte::read_hint<inte::cache_control<inte::cache_mode::streaming, cache_level::L1, cache_level::L2>}>)>`.
- `-ze-intel-enable-auto-large-GRF-mode`: -25% on the gemvs. Don't.
- `icpx -O3` "crashes on this codebase" is SUPERSEDED — could not reproduce (same source,
  same flags, 8/8 clean, full suite bit-identical, microbench -2.6%). Probably transient
  memory pressure during parallel builds. Standard builds use -O3; drop to -O2 only if the
  compiler starts dying on these TUs.
- FP flags are correctness, not optimization: build everything (bench + plugin) with
  `-ffp-contract=off -foffload-fp32-prec-div`, else device approx-div + FMA contraction flip
  int8 quantization ties vs host (±1 x8 on random data; uniform `CONSTW` probes hide it).
- Shared staging + per-tile WG barriers was SLOWER than plain global loads (barrier cost
  ~0.3-0.5 µs/iter at 128-wide groups). `local_accessor` is per-work-group; barriers cost
  `sync.nop` x3-4 per fragment. Avoid WG barriers in hot loops unless the payload is real
  (the I8RING copy is).
- Hadamard via shared+barriers was the K1/K3/K4/K6 cost at rows=1; `had128_strided`
  (barrier-free 128-pt sequentia Hadamard in a 16-lane sub-group, `v[p] = index 16p+lane`,
  widths 1..8 as lane-xor shuffles, 16..64 as in-register slot xors) is BIT-EXACT vs the SLM
  version: ~90 ALU/shuffle vs 8 group barriers per transformed row.

## P11 — Split-K bounds

`tout`/`toutd` are sized for nsl ≤ 8; `MOE_NSL>12` CRASHES today (guard if extending). The
int8 tier clamps `MOE_NSL` to 8 and ignores larger values.

## P12 — Runtime/adapter ergonomics

- Invalid `ONEAPI_DEVICE_SELECTOR` values (e.g. `opencl:none`) ABORT (`terminate`) inside the
  oneAPI adapter's dlopen-time static init — uncatchable from a plugin. Valid no-GPU selectors
  (`level_zero:cpu` / `opencl:cpu` / `host:0`) fall back cleanly ("no SYCL GPU", rc=1).
- The queue must be built with an explicit `async_handler` (default = `std::terminate`).
- `handler::parallel_for` returns VOID (not event) → you cannot build a multi-kernel DAG
  inside one submit; a single command group per forward requires native L0
  `zeCommandListAppendLaunchKernel` with manual param buffers (see
  `decode-command-latency.md`).
- A failed SYCL kernel build fails at first LAUNCH, not at build: piped `icpx ... | grep`
  plus a stale binary nearly produced a phantom result round twice. Always echo rc and check
  the log/CSV exists.
- Runtime stage-gates (a runtime `if` around a block) let LLVM DCE the loads being
  benchmarked — gate ablations at compile time, or (better) toggle a runtime flag inside
  always-coded source.
- Probe K must be a multiple of the dpas k-step or windows alias.

## P13 — Editing/harness traps that masqueraded as platform bugs

- Python `.replace()` patch scripts silently no-op when the anchor text is hallucinated.
  Always assert anchor presence (burned a whole cycle: "the guard exists but didn't fire" —
  it never got inserted). Prefer the edit tool: it validates against the real file and is
  all-or-nothing by construction.
- After ANY block rewrite, diff the RESULT against intent — don't trust the echoed anchor.
  (A struct-insertion edit silently deleted `QuantIn`'s final `qsx` write; symptoms were
  `qsxu={0,0}` and a wild-goose "adding a struct breaks other kernels" bisect that ended at
  `diff moe_sycl_min3.cpp moe_sycl.cpp`.)
- A debug-code sizing bug (H floats into an I-sized vector) presented as `malloc():
  invalid size` heap corruption — looked like a plugin/ABI bug, was the bench. Audit probe
  buffers before believing device guilt.
- ctypes: the 13-array register/update args are pointers to `uint64_t` ARRAYS — pass
  `ctypes.addressof(arr)`, not the stored data pointer (a wrong marshal segfaults inside
  `fill_block` reading the tensor's first 8 bytes as a pointer; the traceback reads like a
  plugin bug, it is not).
- Identical-old-and-new results are the signature of a harness/reference artifact, not of a
  no-op change (seen with `--gateless` xval without `--scalar`: both builds matched the
  AVX2-vs-scalar 1.38e-2 to the last digit).

## P14 — Windows / portability note

`dlfcn`/`dlopen` and all plugin calls sit under `__linux__`; struct declarations use
portable types only.