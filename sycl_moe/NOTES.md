# SYCL / Level Zero MoE offload — working notes

Goal: port the CPU MoE expert offload (exllamav3/exllamav3_ext/cpu/moe_mul1.cpp) so the
offloaded experts are computed on the Intel Arc Pro B70 (SYCL / Level Zero) instead of on
the CPU cores. Main model runs on the RTX 3090 (CUDA) exactly as today; the B70 takes over
the child-worker's compute role.

## Environment
- Host: AMD Ryzen 9 5950X (Zen 3 => AVX2 only), RTX 3090 + Arc Pro B70 (32 GB, 608 GB/s,
  32 Xe2 cores, subgroup 16, XMX int8/fp16; PCIe 5 x16 ~64 GB/s).
- oneAPI 2026.2 at /opt/intel/oneapi (icpx -fsycl). source setvars.sh first.
- Project venv: .venv (torch 2.14.1+cu130). Extension JIT-cached at
  ~/.cache/torch_extensions/py312_cu130/exllamav3_ext (loads fine via `from exllamav3 import ext`).
  NOTE: `python -m build` in build.sh currently fails (system g++ is 16.2, nvcc wants <=15);
  the cached JIT .so works, so don't rebuild the CUDA ext casually. Use g++-15 via
  CUDAHOSTCXX/CXX if a rebuild is ever needed.

## Target models (all Qwen3.8-Flash-Next, 512 experts, topk 10, H=2560, I=640, 48 layers)
- 2.05bpw: mul1 K=2   (bits=2, hb=0) — needs 256 experts offloaded for the 3090
- 2.68bpw: mul1 K=2.5 (bits=2, hb=1)
- 4.05bpw: mul1 K=4   (bits=4, hb=0)
Treillis tile (16x16 weights) packed size: tile_u16 = 8*(2*bits+hb) u16 (=16K+8 for hb).
256 experts x 48 layers x 3 x (640*2560) weights: ~11.3 GB @2bit, ~14.1 @2.5, ~22.6 @4bit
=> all fit (tightly at 4 bit) in 32 GB B70 VRAM if kept resident; staging fallback otherwise.

## mul1 math (spec distilled from moe_mul1.cpp scalar path)
- k2 = 2*bits + hb (bits per weight in half-units/2). Ring of tile_words32=4*k2 u32 words.
- State t (t=0..255) extraction (see decode_state_scalar):
  b1 = ((t+1)*k2)>>1 + 128*k2 ; window = [b1-16, b1); shift = ((b1-1)/32+1)*32 - b1;
  merged = (u32[(b0/32)%W] << 32) | u32[((b1-1)/32)%W]; state = merged >> shift.
- Weight index in tile: idx = perm[t] with perm from make_tc_perm();
  r = idx/16 (k within tile), c = idx%16 (n within tile).
- dequant: w = (bytesum(state * 0x83DCD12D) - 510) * k_inv, k_inv = fp16(0x1eee) as float.
- Matrix is [k -> n], trellis shape [k/16, n/16, tile_u16]; NATIVE tile order = (tile_k*tiles_n + tile_n)
  (CPU loader may band-swizzle for AVX tiers; GPU path can upload native or any repack we choose).
- Per-matrix forward (scalar tier semantics):
  1. tin[r][:] = for each 128-block: HAD_SCALE * hadamard_128( fp32(x[r][:]) .* fp32(suh[:]) )
  2. acc[r][n] = sum_k tin[r][k] * w(k,n)      (fp32)
  3. tout[r][n] = hadamard_128_block(acc) * HAD_SCALE * svh[n] (+ bias[n])   (blocks of 128 in n)
  HAD_SCALE = 0.088388347648 = 1/sqrt(128), hadamard_128 = sequentia butterfly width 1..64.
- Layer forward: chunks = token rows grouped per expert (MAX_M=4/chunk);
  g = fwd(gate_e, x_rows); u = fwd(up_e, x_rows); h = act(g,u) (silu/gelu/swiglu_oai(limit)/relu2);
  d = fwd(down_e, h); out[token] += routing_weight * d.  out zeroed first, fp32.
- Lengths: suh per-input-k fp16, svh (and optional bias) per-output-n fp16. Gateless => relu2 on up only.
- Vector (deployed) CPU tier additionally int8-quantizes tin (q = amax/127, per row, wide 2-row
  fallback if >k/16 zeros) => GPU may mirror that for perf; expect ~0.9% RMS vs fp.

## Plan
1. PoC: SYCL tile dequant vs host ref (done? see below)
2. Full layer forward kernel vs host fp32 ref (synthetic data), then vs exl3_moe_cpu_forward
   (EXL3_MOE_CPU_MAX_ISA=scalar) through torch harness.
3. Microbench real shapes (H=2560,I=640, up to 10 experts x 4-row chunks); target: weight-BW
   limited (~1 MB/expert @2bit => ~17 us per 10-expert layer decode at 600 GB/s).
4. Integration: child worker (moe_handoff) computes via B70 instead of CPU pool. Weights
   resident in B70 VRAM (uploaded at layer registration), x/out hop via USM-host bounce
   buffers. Parent CUDA side unchanged.

## Status log
- [x] PoC1 poc_dequant.cpp: tile state extraction + mul1 dequant, exact for K 1..8 incl .5 rates.
- [x] moe_sycl.{hpp,cpp}: full layer forward (K1 prep, K2 gemv gu, K3 trans+act, K4 prep d,
      K5 gemv d, K6 trans+gather), fp32 scalar-tier semantics, native tile layout, MAXM=4
      chunks, gated (silu/gelu/swiglu_oai) + gateless relu2, optional bias.
- [x] bench_layer.cpp: synthetic layer harness, checks vs moe_host_ref (fp32 transcription of
      the CPU scalar path); passes at ~3e-6 max_rel across E/rows/topk/bits/hb/act combos.
- [ ] perf: naive version runs 19-47 GB/s effective (target 300-500). Profile, optimize.
- [ ] cross-check vs real ext (exl3_moe_cpu_forward, scalar ISA).
- [ ] integrate.

## BIG LESSONS
1. STATE WINDOWS MUST BE MASKED TO 16 BITS. merged>>shift leaves up to 31 bits; the scalar
   CPU spec casts to uint16_t. A missing &0xffff gave plausible-looking garbage. Compare
   the device against the SPEC (host reference), not sim-vs-device (same bug hides).
2. ONEAPI 2026.2 / L0 / Xe2: implicit in-order queue ordering between chained q.submit()
   and H2D q.memcpy() was NOT enforced; consumer kernels read STALE data (zeros) unless the
   queue is drained (q.wait) or explicit cgh.depends_on(prev_event) chains are used.
   Symptom: first forward wrong, later forwards right. FIX: chain every op with depends_on
   (permanent in moe_sycl.cpp). Barriers (ext_oneapi_submit_barrier) and empty separator
   kernels did NOT help; only true event dependencies did.
3. Probe reads are also queue ops: they serialize and change what later probes see. When
   chasing nondeterminism, dump state ONCE right after q.wait; beware summing big probe
   buffers that span memory written by other kernels (false positives).
4. nd_range: global dim must be a multiple of local in EVERY dim; use {N*128, groups} with
   local {128,1}. get_group(dim) is the GROUP id, get_global_id the item id.
5. icpx -O3 crashed silently on poc_dequant; use -O2.
6. GEMV perf anatomy (E=12, rows=1, 10 experts, 2bit, B70):
   - apack register-addressed gemv: K2 216us / K5 56us (nsl=1), total 343.
   - split-K nsl=2 halves K2 (127us), total 260. nsl=4 adds partial-sum cost.
   - replacing per-weight apack extraction by CONSTANT addresses per rk was 3.5x
     faster (36us!) -> the per-weight address arithmetic (u64 extract + derived
     dynamic indexes + 64-bit variable shifts), NOT the loads, dominates. A
     rate-specialized path with constexpr shifts should approach ~60-70us K2+K5.
     First attempt (aligned "column window" fast path) FAILED numerically: the
     scalar spec's cross-word bit extraction is NOT the naive LSB-contiguous ring
     read (merged=(w[b0/32]<<32|w[(b1-1)/32])>>(aligned shift) mixes word halves
     when crossing a boundary). Any fast path must be validated per-window against
     decode_state_scalar first (t21.cpp does this on the host; it caught the flaw).
   - dot_acc/dp4a SYCL ext is NOT hardware accelerated on this stack (same speed
     as manual bytes); don't plan around it.
   - shared staging + per-tile WG barriers was SLOWER than plain global loads
     (barrier cost ~0.3-0.5us/iter at 128-wide groups); avoid WG barriers in hot loops.
   - K1/K3/K4/K6 together ~40us at rows=1; hadamard via shared+barriers is the
     likely cost there; a shuffle-based subgroup hadamard could cut it.
8. THE QUEUE-ORDERING BUG, FINAL FORM (took a day; reread before touching anything async):
   on oneAPI 2026.2 + NEO 2.41 + B70, within an IN-ORDER sycl::queue, q.memcpy() does NOT
   wait for kernels submitted earlier via q.submit(), and event .wait() can complete before
   the data is host-readable. Only EXPLICIT cgh.depends_on / memcpy(...,{deps}) edges are
   honored. Every op in the pipeline (H2D, kernels, D2H) is now chained through returned
   events; b70_forward keeps g_last_ev across calls. If anything ever reads back zeros or
   "stale" data again: check for a missing dependency edge FIRST, not for cache bugs.
   corollary: 'retry fixes it' / 'probe fixes it' / 'second call is right' all had the same
   cause (extra queue ops acted as implicit syncs).
9. b70 plugin: env EXL3_MOE_B70=1 (routes compute; forces swizzle off for layout parity),
   EXL3_MOE_B70_LIB=<path libb70moe.so>. Registration warms workspaces + bounce + pinned
   staging (rows cap 64, chunks cap 1024; bump in b70_register_layer if slot geometry grows).
   source sycl_moe/env.sh before ANY torch-ext python (JIT hash consistency + gcc-15 shim in
   .toolfix; without it a full 190-file CUDA rebuild explodes in ninja).
10. Current integrated numbers (E=12/topk=10/2bit/rows=1): b70 205us/layer vs CPU native 295
    (swizzled) / 452 (native layout). xval rms vs CPU scalar 1.05e-6.
11. STREAM LAYOUT (validated in t29.cpp for ALL K2 2..17 against decode_state_scalar):
    repacked tile = per-tile u32 WORD REVERSAL (R[k] = native[(W-k)%W]); then
    state(t) = 16 ascending bits at P(t) = P0 - ((K2*t + (K2&1)) >> 1), P0 = 32 - K2/2,
    plain LSB-first word bit order. GemvK<K2V> uses this for K2 in {4,5,8} (the three
    Qwen3.8-Flash-Next models); other rates ride GemvFallback (word-translated apack).
    ALWAYS verify such layouts on RANDOM data from the FIXED splitmix RNG (exl3ref::Rng);
    xorshift's slow start filled early ring words with zeros and silently vacuited tests.
    Also '0 bad' results deserve suspicion: check the reference itself is non-trivial.
12. VRAM budget: per-layer workspace allocation is a trap; the ws pool is now process-wide
    (layers run one at a time). 2.05bpw @256 experts x 31 split layers ~= 8GB B70.
13. End-to-end 2.05bpw -mcs 256 (max_len 2048 eval): decode 69.6-71.8 t/s vs CPU 67.5-70.3,
    prefill @2048 1883 vs 1511 t/s (+25%). Decode gains need faster gemv (DPAS int8 path is
    the next big lever: weight bytesum stays per-weight on vector unit, but MACs move to XMX)
    AND/OR slimmer handoff. TODO.)
7. State of play: GPU decode 260us vs CPU-native-ISA 295us (both 10 experts/layer);
   GPU prefill-ish rows=8 690us vs CPU 4600us. Integration is the next milestone;
   revisit gemv instruction diet afterwards (target K2+K5 <= 90us).

## Findings / gotchas
- Xe2 sub-group = 16 lanes; prefer explicit nd_range with local_size 16/32/64 multiples.
- Bench harness build: source /opt/intel/oneapi/setvars.sh && icpx -fsycl -O2 x.cpp -o x
- b70-bench measured: mem copy 674 GB/s, XMX int8 367 TOPS, FP32 vector 22.7 TFLOPS.
- k_inv = fp16(0x1eee) = 0.00676727294921875 exactly (mantissa field 0x2EE = 750, not 766).
- [SUPERSEDED] 'icpx -O3 crashes on this codebase' — could not reproduce: same poc_dequant.cpp,
  same flags, 8/8 clean; full suite builds at -O3, bit-identical results, microbench -2.6%.
  Likely a transient toolchain hiccup under memory pressure (parallel builds), not the source.
  Standard builds now use -O3; drop to -O2 only if the compiler ever starts dying on these TUs.
  Build microbenches with -O2 until proven otherwise.
- PoC1 (poc_dequant.cpp): GPU state extraction + mul1 dequant bit-exact vs host ref for
  K=1,1.5,2,2.5,3,3.5,4,6,8. Runtime-parameterized ring math works; perm(t) closed form:
  b=t>>3, j=t&7 -> row=((b&3)*2)+(j&1)+((j&2)?8:0), col=(b>>2)+((j&4)?8:0).

## Quality gates (wikitext-2 ppl, -r 20 -l 2048, -mcs per model)
| model            | mcs | CPU      | B70      |
|------------------|-----|----------|----------|
| 2.05bpw_h4_ng4   | 384 | 3.960071 | 3.968360 |
| 2.68bpw_h6_ng8   | 384 | 3.824000 | 3.822094 |
| 4.05bpw_h6_ng6   | 448 | 3.730495 | 3.730074 |  (17/48 layers resident on B70)

## Device-memory governance (learned the hard way)
- NEO/L0 does NOT reliably return null from malloc_device near capacity; the failure surfaces
  LATER as an async UR_RESULT_ERROR_OUT_OF_DEVICE_MEMORY (39) throw from memcpy().wait() or
  kernel launch, which crossed the plugin's C ABI and killed the worker.
- Fixes (b70_lib.cpp): (1) soft budget = 0.60 x global_mem_size checked BEFORE every alloc,
  (2) every device alloc recorded in Upload.keep BEFORE its copy so any throw still rolls back,
  (3) b70_register_layer catches all exceptions -> -1 (layer stays on CPU) and sets dev_full,
  (4) b70_forward returns int; nonzero -> moe_mul1 pins the layer to CPU for good.
- GOTCHA: python .replace() patch scripts silently no-op when the anchor text is hallucinated.
  Always assert anchor presence (this burned a whole debugging cycle: "the guard exists but
  didn't fire" - it never got inserted).

## Performance: Qwen3.8-Flash-Next-4.05bpw -mcs 448 (heavy offload, decode CPU-bound)
  decode  S=0-768: CPU 24.9-25.7  ->  B70 44.7-48.7 tok/s   (+89%)
  (17 of 48 layers weight-resident on B70 at 0.60 x VRAM budget; rest CPU fallback)
  2.05bpw -mcs 256 remains roughly at parity-to-+3% decode, +25% prefill: that config is
  NOT MoE-CPU-bound at decode, so the ceiling there is small. The bigger the CPU-offload
  share, the bigger the B70 win.

## More perf (decode, -max_length 1024 -cs 8192 -dr 2)
- 2.68bpw -mcs 448: CPU 40.2 -> B70 54.1 tok/s (+35%)
- 4.05bpw -mcs 448 budget sweep (EXL3_MOE_B70_BUDGET fraction of VRAM resident):
  0.60 (17 layers) 46.9 tps | 0.75 (21-22 layers) 50.4 tps. Stable at 0.75; default set 0.70.
- Combined: offload-share-driven win; budget knob trades B70 VRAM for decode speed.

## Microbenchmarking + tuning lessons (b70-bench manual pass)
- enable_profiling events INFLATE the 6-kernel pipeline by ~40us (NEO timestamp patches).
  A/B decisions must be made UNPROFILED, interleaved, 3+ reps, min/median; per-kernel spans
  only for diagnosis. "span" = command_start->end of the submit event; inter-kernel 'gap'
  shows host submit latency (K1->K2 gap ~17us under profiler; near 0 in production where
  submits are pipelined ahead of the GPU).
- DPC++ handler::parallel_for returns VOID (not event) -> cannot build a multi-kernel DAG
  inside one submit; a single command group per layer-forward would require native L0
  zeCommandListAppendLaunchKernel with manual param buffers. (Future work.)
- Large-GRF (-ze-intel-enable-auto-large-GRF-mode): -25% on the gemvs. Don't.
- annotated_ptr read_hint streaming L1/L2 on weight loads: no measurable effect on this
  stack (kept behind MOE_GEMV_CACHEHINT=define). Correct spelling (hard-won):
  `expe::annotated_ptr<const uint32_t, decltype(expe::properties{inte::read_hint<inte::cache_control<inte::cache_mode::streaming, cache_level::L1, cache_level::L2>}>)>`.
- Split-K auto cap 4 beats 8 by ~10us at decode shapes (partial-sum traffic vs latency).
  Steady decode/layer now ~172-186us synthetic (E=12 topk=10 2bit) vs 295 CPU native.
- K3+K4 fusion: activation tile never leaves SLM; saves a submit, a barrier round and ~256KB
  global roundtrip per chunk; fused span 3.6us, results identical to 1.8e-6.
- Remaining big-ticket items (from the manuals' roofline, decode is nowhere near 608 GB/s):
  (1) native-L0 single immediate command list per forward (kills all submit gaps),
  (2) XMX DPAS int8/s4 tier (moves MACs off the vector unit; needs int8 activation tier),
  (3) K6 (15us at rows=1) parallelize over (chunk,blk) with atomics.

## VTune pass 2 (gpu-hotspots on bench_layer; recipe in README/cheat-sheet)
- Pre-fix gemv_gu: ~61B lane-instructions per 3006 launches; at 4096 lanes x 2.8GHz the
  ISSUE RATE was the wall (56us floor vs 70us measured, XVE active only 40%, 52% idle).
  Culprit: predicated-but-issued FMA chains for chunk slots 2..4 at m=1 (~30% of body).
  -> template GemvK<K2V, MMA>; single-slot decode jobs take MMA=false. Inst/launch -42%.
- gemv at rows=1 is now latency/idle-bound (~65% idle): split-K beyond 8 needs the ws pool
  resized (tout/toutd sized for nsl<=8; MOE_NSL>12 CRASHES today — guard if extending).
  nsl 4/6/8 indistinguishable at decode shapes (165-175us band, run noise dominates).
- K6 real cost ~7us (earlier 15us reading was profiler bubble inflation, not kernel time).
- Final synthetic steady decode/layer ~165-172us; production per-forward via C ABI ~130us.
- Windows safety of the hooks reviewed: dlfcn/dlopen and all plugin calls sit under
  __linux__; struct decls use portable types only.
- Final quality: qbench-trace ppl 1.479306 (CPU) vs 1.479269 (B70) on the 2.05 model.

## Robustness audit (session end)
- Invalid ONEAPI_DEVICE_SELECTOR values (e.g. `opencl:none`) abort (terminate) inside the
  oneAPI adapter's dlopen-time static init - uncatchable from a plugin. Valid no-GPU
  selectors (level_zero:cpu / opencl:cpu / host:0) fall back cleanly ('no SYCL GPU', rc=1).
- Queue must be built with an explicit async_handler (default = std::terminate).
- Soak: 2x heavy ppl passes on 4.05bpw @mcs448 (partially resident B70): rc=0, no
  registration/forward failures, ppl spread 3.39274/3.39073 = 6e-4 rel from K6 relaxed
  fp32 atomics (nondeterministic order - acceptable, matches CUDA-backend norms).

## Trellis cheat-sheet microbench session (lab_dot.cpp)
- Harness lesson (bit me twice): Xe2 clock ramp on light-duty microbenches INVERTS
  rankings. A cold run said flat-bytesum beats mask-chain 2.6x; with 1.5s burn-in the
  effect flips. ALWAYS burn in (>=1.5s continuous launch) and interleave variants, x2 rounds.
- Recipe B (native layout) extraction + funnel helpers validated bit-exact against the
  cheat-sheet K=4 test vectors on B70 (incl tail-bit wrap state 0 and edge states).
- ADOPTED: GemvK/GemvFallback 16-bit windows extracted with 32-bit funnel shifts
  (lo>>s | ((hi<<1)<<(31-s))) instead of (uint64(hi)<<32|lo)>>s: decode 174.0->169.2us
  mean (10 paired runs, funnel better 8/10); fallback also drops the 64-bit merge.
  Results bit-identical (xval 6.06e-7 unchanged; every max_rel family unchanged).
- REJECTED esimd dp4a: dp4a<i32> on (u32,u32) lowers to SIGNED-operand uudp4a sibling
  (llvm.genx.sudp4a) => WRONG bytesums, and simd<,1> scalar use in generic kernels is
  ~2.5x slower than the 5-op mask chain regardless. Do not touch esimd outside esimd kernels.
- REJECTED flat byte tree ((x&0xff)+(x>>8&0xff)+...): at stable clocks IGC's pair-chain
  selection (it fuses masks into dual-issued and/add pairs, see asm '$' numbering) is
  already optimal; flat = +6%.
- REJECTED -510 folding (acc += bs*x, nx -= 510*x per k): cold-run artifact; neutral-to-worse
  at stable clocks, and perturbs the fp32-tier rounding for nothing.
- ISA note: no spills in GemvK paths (-abortOnSpill 4 in effect; scr.* absent from dump).
  Inner loop per state: ~9 int ALU (mul, 2x(and+add fused), shr, funnel pair) + cvt + fma.
  We are at the instruction-issue floor for the FLOAT-tier formulation; only an int8/DPAS
  tier redesign moves it further.

## int8 / XMX DPAS quest (multi-session arc) - SOLVED via joint_matrix packed layout
Timeline of what didn't work (each a real trap, keep this as reference):
1. esimd dp4a<...> in generic kernels: scalar simd<,1> ops cost ~2.5x the mask chain AND
   dp4a<i32> on (u32,u32) silently lowers to SIGNED-src sudp4a -> wrong bytesums. Dead end.
2. xmx::dpas<C,B,A> in generic parallel_for kernels: operand simds must be FULL-matrix
   sized (static_asserts); uniform fills materialize 512B/lane (lab3: 770 scalar loads);
   slice-writes `b[lane*32+i]=..` are undefined-ish (partial zeros, DCE, wrong slots).
   Also q.copy(host.data(), dev_ptr, n) COPIES HOST->DEVICE (arg order Source,Dest) -
   burned an hour chasing "GPU faults" that were my own result-clobbering readbacks.
3. single_task launch made generic-kernel dpas numerically correct (VC replicated model)
   but operand refills per step stayed expensive.
4. joint_matrix (ext::oneapi::experimental::matrix) with row/col-major B from SLM: PASS
   but ~150 mov/join fixup ops per fragment - the layout transform eats XMX's whole budget.
   bench.cpp reaches 367 TOPS only because it reuses fragments over 8192 mads; we regen B
   every step, so the fixup is per-mad. col-major == VC ordinal order (that's why it was
   numerically right) but STILL slow.
THE KEY (from vendor/llvm/sycl/doc + test-e2e/Matrix/joint_matrix_su_int8.cpp):
  B operand declared `layout::ext_intel_packed` = VNNI 4-row-block packing:
    addr(k,c) = (k>>2)*(N*4) + c*4 + (k&3) bytes; stride arg = N*4 (u8).
  In u32 units it's `sl32[(k>>2)*N + c] = product_word` - EXACTLY our per-(wq,col) dword
  stores, one per product, zero scatter. mul1's product word IS a VNNI quad: 4 bytes of
  state*M = 4 hw-k slots; A side = x8 activation replicated x4 per real k (row-major,
  stride K=32, loads lower to a single `load_block2d.ugm.d16`!).
  BMG-G31 supports s8xu8->i32 M<=8 N16 K32 (spec table). Stride*sizeof(T) %8 == 0 required.
  joint_matrix collectives need CONVERGENT control flow (no divergent barriers!).
lab_jm7 = production-shaped probe: NJ x KS fragments, per SG: unpack 2 u32 word-pairs ->
  8 muls -> 2 vector dword STS -> barrier -> jm_load a(global block2d)+b(SLM packed) ->
  dpas -> barrier. RESULTS: PASS exact vs scalar model; 1.4 ns/fragment(128 wt) while the
  lab hammers DRAM with non-reused A bytes; ISA per fragment: 8 LDG + 8 mul + 8 shr +
  2 vec-STL + 1 block2d + 1 dpas.8x8 + syncs ~= 0.27 lane-instructions/weight vs float
  tier ~0.6-1.0 -> predicted K2/K5 ~2x faster on real shapes once A staging reuses L2/SLM.
Production design (in progress):
  pipeline becomes K1 rot -> K1q quantize (amax per row -> x8, q, sum_x8; replicate x4;
  rows 4..7 zero) -> K2p GU int8 gemm (same stream windows as GemvK, lane owns 8 cols x
  2 wq per tile row -> 16 products = 2 frags) -> i32 accs -> K3 act (apply kinv*q, -510sx)
  -> K4q quantize down input -> K5p DOWN int8 gemm -> K6 gather (apply q2/sx2 scalars).
  Tier becomes CPU-VNNI-equivalent int8 (documented ~0.9% rms) -> gate: rms<=3% vs float
  ref in bench, then ppl on all three models, EXL3_MOE_B70_INT8 env (default ON after).
  New pooled ws: a8u/a8d operand slabs + i32 acc buffers; no weight expansion, weights
  stay the packed native stream (0.5 B/weight).
Follow-ups flagged by boss (post-integration experiments):
  - exllamav3 sizes CPU offload assuming CPU is slow; B70 is not. Re-sweep -mcs upward
    (2.05: 256 -> 384/512) once int8 path lands; expect free perf.
  - MAXM=4 (chunk rows) is a CPU-kernel register budget (MAX_SLOTS). DPAS m8 fragments
    process 8 rows for the price of ~4: raising MAXM to 8 (b70-side chunker variant +
    ChunkDev.token[8]) would nearly halve prefill jobs and fill the idle fragment rows.
    Chunking is host-side protocol -> do as its own change after v1 lands.
  - quantize semantics to mirror (moe_mul1.cpp quantize_row): q = amax>0? amax/127 : 1;
    x8 = clamp(lround(x/q), +-127); sum_x8 exact int; splat32[i] = x8*0x01010101 == the
    DPAS A row bytes for that real-k slot (4 hw-k bytes = same x8: replication free).
    Wide rows (amax/128 hi + lo residual pair, outputs summed) = v2: v1 runs plain-int8
    (CPU's EXL3_MOE_CPU_WIDE=0 mode), gated by ppl. NSL for int8 path = 1 (job counts are
    already >=3840; slice-sum buffers and K3 slice loops disappear).
Trap reminders learned this session:
  - Xe2 clock ramp INVERTS microbench rankings: 1.5s burn-in before timing, always.
  - local_accessor is per-work-group: fine for the 512B slab, but barriers = sync.nop x3-4
    per frag; ping-pong two slabs later to halve barrier count.
  - IGC_JointMatrixLoadStoreOpt=1 env EXISTS (docs): forces the SLOWER path; do not set.
  - e2e tests live at vendor/llvm/sycl/test-e2e/Matrix - goldmine for exact API usage.

## Benchmarking gotcha: first run after a heavy GPU job under-registers B70 layers

Observed 4.05bpw mcs448: run immediately after a finished 2.05 run OOM'd the plugin at
9.5GB (27 layers -> CPU, 36 t/s); identical rerun minutes later hit the normal 23.91GB
residency (54 fallback lines, 49-51 t/s). Driver/page-reclaim lag steals apparent VRAM.
=> When testing memory-heavy configs, discard the first run after another big GPU job,
   or leave ~30s. The graceful-fallback machinery did its job (no crash, correct output).
Also note: the parent process ALSO creates a plugin context (tiny, queue-only) via the
swizzle gate -> two `[b70moe] device:` lines per run is NORMAL, not double-upload.

## int8 v1 debug post-mortem (the bug that wasn't)
- The 12x rms_rel on e1/e12 came from the DEBUG SCAFFOLDING, not the pipeline: the float
  fingerprint dumper matched every unit with jmu==0 && blk==0 (all NSL slices), and slices
  end at DIFFERENT tile rows (tk_hi-1), so dbg[70..77] held slice-7's tail row. Judging
  "float vs int8 states differ" from that was an artifact; with tk==0 && unit==0 gating the
  rows are IDENTICAL (7169 c5a4 30f3 ... both). KS1 C matched manual sum to 7 counts.
- Companion probe design that DID work and is worth keeping in the toolbox:
  uniform-A (x8=+1) => C = sum(bs); uniform-B=1 => C = 4*sum(x8); A=q+1 with
  B=1-only-quad0 => C must be exactly n_frags*4 (permutation-sensitive!).
- Lesson on manual references: do NOT recompute the reference from the kernel's OWN dumped
  states and call it ground truth - circular. Compare states across pipelines or against
  the CPU extension instead (which is what xval is for).
- int8 v1 remaining real gap vs CPU tier: wide-row 2-slot quantization not implemented
  (rows needing it fall back to plain int8 -> local degradation; e1 h-stage off). v2:
  quantize_row_wide mirror + row pairing (m4->8 rows exactly fits when <=2 tokens wide).

## Reset baseline: int8 re-port starts from float-only (this commit)
moe_sycl.{cpp,hpp} restored to aa5cf203 (float-only, production-verified: xval 6.06e-7,
full synthetic battery <=2.9e-6, plugin builds). All int8 kernel code REMOVED from the
shipping path; the last (unverified) int8 implementation lives in git at 88c3e781 for
reference. The external `--i8trace` harness (bench_layer) stays, null-guarded.

Why: today's session showed in-kernel probe scaffolding repeatedly polluted what it
measured (flag-slot clobbering by dump regions; probes that bypass the very datapath
under test). Also several "fixes" (wide-pair rows, +-64 clamp, ping-pong slabs) were
adopted without proof and muddied the baseline. Rule going forward: kernels contain ZERO
debug hooks; all verification is external readback + host emulation per stage, each stage
fed from device readbacks of its OWN inputs.

Established knowledge to carry into the re-port (all externally or doubly verified):
1. joint_matrix int8 m8n16k32, B `ext_intel_packed`, stride arg = N*VNNI bytes, packed
   byte addr(k,c) = (k>>2)*(N*4) + c*4 + (k&3): bit-exact vs scalar (lab_jm7, lab_jm8,
   LLVM e2e joint_matrix_su_int8 PASSES on B70).
2. lab_jm8: twin-fragment-per-tile SLM staging (16 bands x 16 dwords, fk bases at +0/+512,
   stride 64, 2 loads + 2 mads) is bit-exact with scalar reference. Production staging
   MUST mirror lab_jm8's addressing verbatim: sl32[quad*16 + col] per fragment slab.
3. Mul1 identity (exl3_ref decode_mul1): for product word p = st16*0x83DCD12D,
   w = k_inv * (bytesum(p) - 510). So bs(k,n) = 510 + w(k,n)/k_inv EXACTLY, and a raw
   int8 dot with A bytes = x8(k) replicated x4 gives C = sum_k x8(k)*bs = w-dot + 510*sum_x8.
   The SAME -510*sum_x8 must be folded in the epilogue affine ({A,B} = {KDQ*q, -510*KDQ*q*sx}).
4. CPU quant semantics (moe_mul1.cpp): single-slot q = amax/127 (mirror exactly:
   round-half-away, clamp +-127, splat x8*0x01010101); wide rows split v = 128*vh + vl
   with q_wide = amax/(127*128), s_out per half, scales {q*128, q}.
5. Final gemv-gu localization from the external trace (e1, always-wide variant, commit
   c7267868): stage B quant bit-exact OK; C: got = 1.014*want - 475925, corr 0.9996,
   max resid ~9k -> accumulator is near-right but has a column-independent offset and a
   small scale distortion. That offset/scale pattern points at the bs/-510 bookkeeping
   (byte-sum vs per-byte pairing of mul1 words), NOT at addressing. Re-verify first with
   SIMPLE quant (127, no wide pairing) and lab_jm8-exact staging.
6. fp32 path and int8 path share K1 prep + tin/tind layouts; do not touch tin layout.

Re-port increments (each ends green under --i8trace before the next starts):
  I1  QuantIn (plain 127-quant, splat32, one row per token, Affine {A,B}) + buffers.
  I2  Gemv8 GU staging == lab_jm8 byte-for-byte, single fragment per load pair, real
      window decode + prod words; trace stage C bit-exact (integers!).
  I3  K34i8 act-fused + QuantIn down + Gemv8 down: stages E/F.
  I4  K6i8 gather: stage G. Then quality (add wide-pair rows IF trace-clean), speed, ppl.

## int8 re-port session (this commit) — DONE, shipped as auto tier

Increments I1..I4 landed together and went green: QuantIn + Gemv8 GU (stages B,C), then
K34i8/QuantIn-down/Gemv8-down (D,E,F), then K6i8 (G). 13-config --i8trace battery green
(all three rate families, gateless, act 0/1/3, rows 1..32). t30.cpp = single-hot-A Gemv8
isolation lab (modes hot/one/rnd/sat/q25/rneg/...; 'tm/tq' = timing with production
geometry; every probe now EXACT at K2560xN640x20slots).

THE ROOT CAUSE of the old 1.014*want-475925 stage-C fingerprint, finally:
  x8 * 0x01010101 DOES NOT SPLAT NEGATIVES. -1 * 0x01010101 = 0xFEFEFEFF, not 0xFFFFFFFF.
  The DPAS A bytes must be (x8 & 0xff) * 0x01010101 (the cheat-sheet/CPU store_x8 spellings
  mask first: (uchar)x8 * 0x01010101). Both the old kernel AND the old harness stage-B
  expectation carried the same bug, so stage B "passed" while stage C drifted; only the
  three other bytes of each negative activation word were wrong, which is exactly a
  small-scale + constant-offset distortion of the dot products. The t30 'rnd' mode
  (random SIGNED A) reproduced it in 10 minutes where weeks of pipeline tracing did not,
  because t30 computes its reference from low-byte semantics and random-signed data.
  Trap cost: HIGH. Rule: any splat/mask expression on signed bytes gets an explicit
  & 0xff and a lab mode with negative values including -1 and -(1..8) mixes.

SECOND TRAP (measurement): the t31 ablation "wins" (V6/V8/V9 at 37us vs 62us) were an
artifact — the bandb-store and second-mad blocks were gated by `#if VARIANT == 0||1||4`,
so VARIANT 6/8/9 silently SKIPPED HALF THE WORK (second tile of every pair). Always make
removed-work variants by TOGGLING A RUNTIME FLAG INSIDE ALWAYS-CODED SOURCE, or diff the
generated asm, before believing an ablation delta. Honest numbers (t31 V0/V12 + t30 tq):
  full pair-loop ~= single-tile ping-pong ~= 55-62us for the gu lab shape; PKA pair-decode
  helps in the pair-loop shape (-19%, V12 vs V0), ~neutral in single-tile (kept anyway).
Rejected for real: depth-4 rotated word pipeline (105->149us, the (tk&3)-indexed register
array defeats the unroller); jb-from-global scratch (slower AND alignment-crashy: nsl
values where (slot*nsl+sl)*nfl*512 % 64 != 0 fault the 2D block engine — device loss, the
same symptom as the Gemv8P OOB read; watch SLM/global alignment for anything jm-loaded).

THIRD TRAP: device approx-div + FMA contraction flip quantization ties vs host (x*rq then
+-0.5 rounding). Fixed by building EVERYTHING (bench + plugin) with -ffp-contract=off
-foffload-fp32-prec-div (now in the README build line; without them --i8trace stage B
fails sporadically by +-1 x8 on random data — 'CONSTW' uniform probes hide it).

Harness fixes (bench_layer i8_trace was NOT the innocent arbiter it pretended to be):
  * stage D/G folded -510*B with an EXTRA x128 (gb already summed B over the 128 i-iters)
    — would have demanded a 16384x fold from the kernel;
  * gateless tin readback was half-size (K1 writes ts=2j slots even when nm=1) -> NaN garbage
    compared as 'want 00000000';
  * swiglu_oai applied uv twice (av=(uv+1)*sigmoid*gv, then hv=av*uv);
  * stage G gate loosened to rel 1e-3/abs 1e-6 (fp32 endpoint + atomic ordering ulp noise);
  * check gate: int8 tier judged by rms<=3% (NOT max_rel, which cancels-pathologically);
  * float stage-check block skipped when int8_active;
  * trace collapses [slot][nsl][8][N] split-K acc buffers via layer.i8nsl().

Production design as shipped: QuantIn always-wide @8192 levels (|vh|,|vl|<=64 — DPAS i16
pair-safety, NOT actually proven necessary: uniform sat=127 passed, mixed +-127 not),
a8 [slot][k/8][8r x 8i32] slabs, Affine{A=KDQ*q_eff, B=-510*A*sx} per DPAS row folded as
+128*B at element 0 after the Hadamard (== H*(B*ones)); split-K: acc [slot][nsl][8][N]
i32, slice sums in K34i8/K6i8, auto nsl by the float lane-target heuristic (cap 8 gu /
4 d, halved for multi-row), MOE_NSL override clamped to 8 for this tier; nsl=1 stays
exact for tiny shapes.

TIER POLICY (auto): int8 iff K2 in {4,5,8} AND some chunk has m>=2. Rationale (min-of-3
interleaved, bench E12/16 topk10-12): rows=1 float 172-186 vs int8 205-223 (m8 fragment
runs 25% full at m=1 + quant/pass overhead); rows>=4 int8 wins or ties, and real-model
prefill gains 10-25%. EXL3_MOE_B70_INT8=1/0 forces (the trace harness relies on =1).

MEASURED GATES (real models, this box):
  ppl r20 l2048 (auto tier; fresh CPU baselines same session):
    2.05bpw -mcs384  CPU 3.963241 -> B70 int8 3.972811  (+0.24%)
    2.68bpw -mcs384  CPU 3.823990 -> B70 int8 3.820485  (-0.09%, partial residency)
    4.05bpw -mcs448  CPU 3.732906 -> B70 int8 3.739851  (+0.19%, 27 layers fell back)
  perf -mcs256 2.05: prefill2048 CPU 1456 | B70-float 1711 | B70-int8 1880 tok/s;
    decode ctx0: CPU 67.9 | B70-float 72.2 | B70-int8-forced 72.3 (auto: float path) —
    NOTE the synthetic rows=1 int8 regression does NOT show on the real model, but auto
    keeps fp32 for m=1 anyway (cheap insurance).
  4.05 -mcs448 decode auto: 49.4-50.4 t/s (matches float-tier's 49-51 record).

NEXT levers (not this session):
  - MAXM=8 chunker (host protocol change; m8 fragments want 8 rows; NOTES 'boss followups').
  - in-bench G2/G5 still ~1.7x the lab-alone time: interposition of Q1/K34i8 evicts the
    8MB gu working set between gemvs; consider wider WGs (128 lanes, 8 frags/WG, per-SG
    2KB slabs) to co-schedule staging with the fp32 kernels' block order, or interleave
    gu+down gemvs of DIFFERENT experts in one kernel launch (L2 locality per expert run).
  - m=1 decode int8 mode: single-slot (127) quantization when m==1 && no wide rows, nsl
    tuning for the 8-kernel pipeline, and skip the vl half of the affine at m=1 (2 of 8
    fragment rows instead of 8).

Production C-ABI per-forward (bench_b70_py.py on xval_s, rows=1, this build):
  fp32 tier 110.7 us (rms 6.05e-7 vs ext) | int8-forced 124.0 us (rms 1.36e-3).
The synthetic bench_layer rows=1 penalty (-20~35%) largely vanishes through the real
handoff path (fixed ~40us of submit/handoff amortized); auto still keeps m=1 on fp32.

## Placement/streaming constants under B70 (user hint: exl3 assumes offload << main device)

Swept 2.05bpw B70-auto (perf.py -max_length 2048 -cs 8192 -dr 2, resident=48/48 fallback=0):
  mcs  st   prefill1024 prefill2048 decode0
  256  def     1365        1853       71.1
  256  32      1328        1539       69.8
  256  64      1323        1493       69.7
  320  def     1385        1655       70.8
  320  2        894        1216       70.2
  320  32      1242        1559       71.2
  320  64      1202        1344       (33 = under-registration artifact, see below)
  384  def     1120        1352       72.4   (B70 23.6GB, still 0 fallbacks at budget 0.70)
  512  *** NOT SUPPORTED *** (all experts offloaded = zero GPU-resident experts; runs but
  falls apart: B70 53 / CPU 39 dec, 1036/822 prefill — and >VRAM. Boss: don't offload all.)
Conclusions:
  * EXL3_MOE_STREAM_T default (~8, bandwidth-scaled) is STILL the optimum with B70+int8: both
    tightening (t=2, +PCIe thrash) and loosening (t=32/64) lose prefill. No rebalance needed —
    the streaming decision is about PCIe vs main-GPU, and B70-side speed mostly cancels.
  * Raising -mcs buys nothing on 2.05 (decode flat ~70-72, prefill drops monotonically): at
    256 offloaded experts the per-token routed work already covers topk=10; extra CPU->B70
    headroom does not convert. mcs384 decode +1.7% (72.4) at -27% prefill: not a trade to
    bake in. KEEP -mcs defaults; the win scales with offload-share only on heavy models
    (4.05@mcs448 unchanged story).
  * RECONFIRMED TRAP: back-to-back big-GPU runs under-register B70 (the mcs320/st64 run
    showed decode 33 = layers on CPU: 20GB freed one second earlier). Always leave ~30s
    between model-sized runs or discard the first (sweep logs: resident=48 fallback=0 for
    every other config, so only that point is invalid).
  * int8-vs-float layers at rows>=2 (bench, same-block min-of-3): both tiers are WEIGHT-TRAFFIC
    bound at 2bit mul1 (weights identical bytes for both tiers!), so DPAS only wins where the
    vector-ALU term matters: m=1 rows float -20%, rows>=4 int8 ~flat-vs-float-grows, real-model
    prefill +8-10% (1711->1853..1880). The auto policy (float iff maxm==1) is exactly right.

## Next structural lever (identified, not yet built): coalesced weight-word loads
t31 ablation buckets (gu lab shape, nsl4, full work): skeleton 18us, +5-lane-word loads ~15,
+STS ~11, +ja/jb operand moves ~23, +mads ~10. Every lane loads 5 of the 16 tile-row words
and 16 lanes overlap ~5x on the same 64B row (L1 traffic, not DRAM: unique 8.2MB = 13.5us).
PoC idea: lane l loads word l (64B coalesced), rebuild windows with select_from_group (5
SG-shuffles replace 4 LDGs, register-side). Applies to BOTH tiers (GemvK too). Must be a lab
A/B first (t31 VARIANT 20), adoption bar >=15% on the isolated gemv.

## Coalesced-load + shuffle variant: REJECTED (t31 VARIANT 20, checker /tmp/p20chk pattern)

Lane-l-loads-word-l (1 fully coalesced 64B row fetch per SG per tile) + rebuild the 5-word
window with select_from_group(sg, word, src_lane): CORRECT (bit-exact vs an independent
ring-normalized host checker) but 77-104us vs V0's 57-62 at the gu lab shape (nsl 1..8).
Indirect-lane shuffles lower to something worse than the redundant overlapped L1 loads they
replace — the 5x word overlap was NOT the wall. Killed. (Checker lesson came out of this
too: GemvK's G is NEGATIVE (ring slack); any host-side window formula must ring-normalize
P = G + rel mod (W*32) BEFORE word/split extraction, or it flags correct kernels. The t30
lab harness encodes the kernel formula and thus could not catch a shared misconception -
independent checkers must be written from the FORMAT spec, not from the kernel.)

## MAXM=8 scoping (for the next session's own-change increment)
ChunkDev{x,sel,w} never crosses the worker ABI: b70_forward receives raw (x, sel, wts, rows,
topk) and b70_lib.cpp::forward_impl does the expert grouping/chunking HOST-SIDE. So MAXM=8
is contained in sycl_moe/: ChunkDev{token[8],weight[8]}, the b70_lib + harness chunkers,
moe_sycl MAXM and every [.. MAXM ..] stride, GemvK/GemvFallback accumulator chains
(acc0..3/accB0..3 exist for 4 rows; +4 chains, or chunk-split for the float tier), K1/K34
row loops, b70_warm geometry. Value: mcs256/384 prefill chunks average 2.5-3 tokens ->
8-slot chunks ~halve weight passes in the traffic-bound gemvs (both tiers benefit, int8
most). Decode (m=1) unaffected; do NOT bother before it shows in a profiled prefill trace.

## SUSTAINED-CLOCK TIER A/B — the real numbers (and why every earlier table was wrong)

VTune gpu-hotspots under a 30k-iteration sustained run (spawned, not attached; hot clocks):
  int8 layer: G2 gemv8 = 48us, G5 = 30us, Spill = 0, XMX ~2-3% busy, XVE idle ~77%
  float layer: GemvK gu = 52us, down = 29us.
So at rows=1 both tiers cost the SAME in-kernel (weight-traffic bound, exactly as the
roofline predicts) — the "int8 -20% decode" from short bench runs was mostly cold-clock
inflation plus 3 extra launches in the sync-gap duty cycle. VTune attach (-target-pid)
captures NO compute-task data for Intel GPU (must spawn); a background heater process
starves the PMU (single client) — neither workaround works; just run >=1000 iterations
inside the measured process and trust min-of-3 interleaved.

Tier A/B, sustained, min-of-3 interleaved, iters=1200, EXL3_MOE_B70_INT8=0/1 (the ONLY
honest table — note the auto rule itself corrupted earlier ones: with auto default ON,
'control' runs at rows>=2 silently ran the int8 tier and showed ratio 1.000):
  rows  float   int8   speedup
  1     179.5   222.0   0.81   (float: m8 fragments 25% full + quant/slice overhead)
  2     262.8   224.5   1.17
  3     315.6   223.5   1.41
  4     354.6   223.1   1.59
  5     558.0   272.6   2.05
  8     777.5   344.0   2.26
  32    2233.5  865.2   2.58
  64    4278.1  1941.8  2.20
AUTO RULE CHANGED accordingly: int8 iff rows >= 2 (TOTAL rows), not 'some chunk m>=2':
float pays per (chunk x row) while DPAS pays per chunk with the 8 fragment rows free, so
even 2 tokens spread over single-row chunks already favors int8 (x1.17).

Depth-4 prefetch, done RIGHT (four NAMED word sets + 4x-unrolled group loop, t31 P22/V22,
bit-exact vs ring-normalized checker): G2 lab 55-62 -> 54-56 (nsl2 -7%), shipped in
Gemv8 for all K2. The earlier depth-4 DISASTER (149us) was the (tk&3)-indexed array
spilling, not the idea. The '4 outstanding load sets' theory explains the Send-wait
dominance from the cold run; the sustained profile then showed both tiers traffic-bound
at rows=1 — MLP mainly bought multi-row stability.

Model-level end state (final plugin, spaced runs, 30s+ gaps to dodge the reclaim trap):
  2.05 -mcs256: prefill2048 1852, dec 70.7-71.1 (CPU 1456/67.9; B70-float 1711/72.2)
  4.05 -mcs448: dec 50.0/47.7 ctx0/768, 20-21 layers resident at budget 0.70 (23.1GB)
  The 39.7-decode 4.05 run was UNDER-REGISTRATION (20 registered/28 fallback after only
  ~90s... no: that run got 20 registered and 50.0; the bad run followed a 16GB job with
  30s gap and got fewer). 90s+ spacing or discard-first is now the standing recipe.

## MAXM=8 shipped (two-fragment slots) + the two measurement ghosts that haunted it

What: chunks carry up to 8 tokens = 16 QuantIn rows = TWO m8 fragments; Gemv8 stages the
B band ONCE per tile and fires it at both accumulators (one weight stream per 8 tokens).
Frag1 load+mad skipped uniformly when m<=4 (jc1 stays 0 and is still stored -> acc pad
rows remain verifiably zero); QuantIn skips the frag1 zero-fill iff m<=4 (never read).
Layouts that grew: ChunkDev[8], tin/tout/tind/toutd row blocks (MAXM=8 stride), a8 slabs
(kf block = 128 words, frag f at +(2tk+fk)*128 + f*64), qsx (32 floats/slot), acc
([slot][nsl][16][N]), TokenMap entries (j*8+r, decoded >>3/&7 in BOTH K6s), worker +
bench chunkers (cap = int8_mcap_pick: 8 for int8 - fp32 GemvK still has exactly 4 chains,
capped at 4 by the same helper). Lab override EXL3_MOE_B70_MCAP=4|8.

Same-binary sustained A/B (min-of-2, iters 1000/500), w8/w4: rows 5: x1.11, 6: x1.13,
8: x1.40, 12: x1.34, 16: x1.42, 32: x1.59, 64: x1.55, E64-rows32: x1.24, E128-rows128
x1.51; rows<=4 neutral. Policy = always 8 under int8. Final int8 tier vs float:
rows 1 x0.80 | 2 x1.17 | 4 x1.50 | 8 x2.40 | 16 x2.70 | 32 x2.98 | 64 x2.65 | 128 x2.13.
(rows=4 initially REGRESSED +6.5% vs the old w4 binary - the unconditional frag1 mad on
padded slots; the has1 skip erased it: 238 -> 223.5us.)

Verification: i8trace battery 24 configs x {auto, MCAP=4, MCAP=8} bit-exact (includes
first-ever m>4 chunk coverage: rows 5,6,7,8,10,32,64 + gateless/act3/2.5bit/4bit); xval
unchanged (int8 1.355e-3, float 6.05e-7) - per-token integer math is chunking-invariant,
so outputs are BITWISE equal across widths (nice property, exploited as a free check).

Ghost #1: the act3 stage-D 'failure' (1 column, abs 1.4e-8 at a |gv|~1e-4 cancellation)
was the HARNESS accumulating gb += B over 128 float iterations instead of the kernel's
one-shot 128.0f*(B0+B1); sequential-add drift ~1e-4 RELATIVE on the fold. Harness now
folds it the kernel's way (D and G). Deterministic, seed-stable, NOT a device bug.

Ghost #2: model gates went 1401 t/s (2.05, zero layers registered) and 29 t/s decode
(4.05, same 19 registrations as the 50 t/s run!). Causes respectively: VRAM-reclaim lag
(90s+ spacing / discard first - standing rule) and POWER/THERMAL throttling of the B70
after ~40 min of sustained benching (3-minute idle restored 29.25 -> 49.13 with identical
registration counts and placement profiles). DIAGNOSTIC: if decode is ~0.6x of record but
'registered layer' count matches, cool down and re-run before believing any regression.
Placement also persists in ~/.cache/exllamav3/expert_stats/*.json ("placement from saved
profile") - profile churn across short runs changes the B70/CPU expert split between runs.

Model end state (MAXM8 plugin, spaced + cooled runs): 2.05 -mcs256 prefill2048 1871
(best yet; CPU 1456), decode ~69-71; 4.05 -mcs448 prefill 360, decode 49.1/46.5 ctx0/768
(CPU 24.9); 48/48 and 19-20/48 registered respectively.

## nsl8 retune + the frag1-skip REVERSAL (unconditional dual-mad wins)

Post-MAXM8 nsl sweep (sustained, EXL3_MOE_I8NSLU/I8NSLD per-kernel overrides added):
gu optimum moved with the halved nc - rows=64 (lanes ~132k) wants nsl=2 where the old
80k-lane target picked 1 (-13%). New gu fill target 136000 separates it from the 61-70k
shapes that want 2 (nsl=3 costs them +0.8%). Down heuristic already tracked the per-kernel
optimum (checked with overrides; d in {1,2,4}).

FRAG1 SKIP TRIED AND REVERTED: skipping frag1 load+mad for m<=4 slots (runtime break, or
template<bool> peel with runtime dispatch) speeds the NARROW path ~22% but costs the FULL-
slot path ~20% (E128/rows128 w8: 3605 unconditional -> 4325 break / 4389 peel; Spill=0 in
VTune for all variants - it is scheduling quality, not spills; both the sibling-branch
duplication and the in-loop break poison the straight-line unrolled schedule). Production
policy is width-8 everywhere, so the fat path is the one that must stay monolithic: the
kernel ALWAYS runs both fragments and QuantIn ALWAYS zero-fills 16 rows. The MCAP=4 lab
override therefore runs ~50% slower than MCAP=8 at chunk-rich shapes (5432 vs 3599 at
E128/rows128) - that gap is the wasted frag1 mads on padded slots, known and accepted.
If narrow-slot execution ever matters again, the RIGHT shape is a compile-time SEPARATE
kernel (own parallel_for, no shared function), not a branch inside this one.

Registration trap HARDENED: 120s idle did NOT prevent it (1380 t/s, layers lost); the run
IMMEDIATELY after always registers fully (48/48, 1861). New rule: model gates run TWICE,
scored off the second run; time gaps are not a control.

## The m=1 / decode study (and the slim kernel it produced)

VTune rows=1 int8 vs float spans: G2 131 vs K2 51, G5 70 vs K5 27, plus Q1+Q2 18 and
K34i8 17 (float K34 4). m=1 DPAS wastes 15/16 A rows, pays the slab round-trip, and
K34i8/K6i8 serialize slice sums on 6k threads. Three interventions:

1. NARROW-SLOT SLIM KERNEL (SHIPPED, default on when max chunk m <= 4, EXL3_MOE_I8SLIM=0
   lab-forces fat): Gemv8 gains template<bool F1>; F1=false drops frag1 load/mad/store
   entirely and QuantIn(f1=0) stops zero-writing frag1 rows (acc rows 8..15 are STALE BY
   DESIGN on slim passes - K34/K6 index rr=(r>>2)*8+2*(r&3) <= 7 for m<=4, and the trace
   skips those pad assertions via layer.i8slim()). Selected as a SEPARATE parallel_for -
   the correct form of the frag1 skip after the branch/peel poison saga. Sustained: rows4
   E16 241 vs 287 (-16%), rows2 224 (was 223-229 flat), single-iter spans G2 121->79,
   G5 65->46, Q1 12->9. rows 5-8 untouched (fat dormant), all traces bit-exact.
2. 128-LANE WIDE WG (NSUB=8 sub-groups/WG, EXL3_MOE_I8W=1): NEGATIVE. Bit-exact, but
   rows=1 unchanged and rows=64 -8%; the 23% thread occupancy was not the binding
   constraint (weight-stream latency is). Kept behind the env off-switch as documentation.
3. THE rows=1 VERDICT: int8 at m=1 stays ~25% behind float (sustained 222 vs 179) even
   slim. The remaining delta is launch-chain + structural 8x-row waste; float remains the
   auto choice for rows=1. Slim's payoff zone is rows 2-4 (light batching, speculative
   decode) where int8 now runs x1.2 over float instead of ~x1.17.

Measurement traps hit during this study, both real:
- SUSTAINED-MEDIAN vs SUM-OF-SPANS at rows=1 differ by ~60us (222 vs 160): every kernel
  boundary in the per-iter-synced chain costs ~8us of dispatch that spans do not show.
  Do not "spend" span sums as reachable sustained time at decode shapes.
- I "found" a 16x grid-inflation bug in the int8 gemv launches (g0 = (N/16)*16*nsl while
  the kernel decodes nfl*nsl workgroups). IT WAS NEVER A BUG: nd_range GLOBAL sizes
  divide by LOCAL (16) to get group counts; the *16 is the local size. "Fixing" it
  silently amputated 15/16 of the slices - the resulting I8DUMP showing only slice 0
  alive is what caught it. Double ghost confirmed by: nsl=1 immune, nsl>=2 broken,
  ~40-60% missing values, pad-zeros intact. Rule: before claiming a grid bug, compute
  groups = global/local, not global.

## Command-latency engineering for decode (fused prep+quant, owner-gather K6)

The rows=1 wall is COMMANDS, not math: time is work-INDEPENDENT (topk 1..10 all measure
the same), the --bare per-iter barrier round trip alone is 33us, and every chained queue
op adds ~8-15us. Two structural cuts, both tiers:

1. OWNER-GATHER K6 (both tiers): one WG per (128-col block, token) walks its token's tmap
   entries in ASCENDING order. Kills the out memset command AND the fp32 atomic scatter;
   sums now match the CPU reference's order exactly (atomics did not). rows1 spans grow
   (5->21us: only nbk*rows WGs) but the SUSTAINED total drops ~18us anyway - launch
   latency outranks span time at decode. rows32+ improved too (660->635: no atomic storm).
2. FUSED PREP+QUANT (int8): PrepQuantI8 replaces K1+Q1 - 256-thread WG per (slot, token
   row-pair), two 128-threads teams Hadamard 10 blocks each with results kept in
   registers (vals[10]) across the shared amax, then quantize BOTH vh and vl rows from
   the same values (one stage-P per token per matrix, tin never written). f32 spellings
   identical to K1->Q1 (trace bit-exact everywhere). rows1 222->183 cumulative with (1);
   E128/rows128 3599->3457; xval 1.355e-3; forced model int8 decode 67.8 vs float 70.9
   (auto keeps float for rows=1 - the 9% m=1 gap is DPAS geometry + chain, not fixable
   without abandoning joint_matrix loads, which always fetch all 8 A rows = 1KB/kf block
   whether 1 or 8 tokens live).

Two traps met again: (a) fused kernel indexed chunks[j].token[r] (DPAS row) instead of
token[tok] - invisible at rows=1 (r=0 only live row), caught by the rows=2 trace; and the
rp decode is tok = frag*4 + (rp&3), NOT (rp>>1)&3 - the r>>1 already happened. (b) The
struct-insertion edit silently deleted QuantIn's final qsb write (oldText/newText tail
mismatch) - symptoms were qsxu={0,0} and a wild-goose "adding a struct breaks other
kernels" bisect that ended at `diff moe_sycl_min3.cpp moe_sycl.cpp`, not a compiler bug.
Lesson: after ANY newText rewrite of a block, diff the RESULT against intent, don't
trust the anchor echoed back.

Probe result: host writes to sycl::malloc_device memory SEGFAULT on this driver
(L0/B70, oneAPI 2026.2) - the "skip the H2D memcpy by writing the blob directly" idea
is dead; malloc_shared would page-migrate per access and lose worse.

Current sustained floor budget at rows=1 (int8 183 / float 168): memcpy ~10 + per-command
chain (7 int8 / 6 float commands incl. barriers) ~60-80 + real kernel spans ~90. The
remaining big int8 cut would be K34i8+Q2 (needs 5-block-wide WGs for the row amax, same
register-carry trick), worth maybe -10us; below that it is one fused megakernel or stop.

## End-to-end speed sweep: everything is at a measured optimum (and why)

With the profiling umbrella (EXL3_MOE_PROF) in place, swept the whole offload stack on
2.05bpw. Baseline auto/B70: prefill 1886, decode ~70.5 (noise band to 73 run-to-run;
score runs twice, mind 3090 SW-power-cap counters - it boosts down under sustained load).

Hardware truth (nvidia-smi + /sys/bus/pci + direct probes):
  - main GPU = RTX 3090, link trains Gen4 **x8** (max x16 - the board bifurcates the
    5950X's 24 lanes); pinned->device probe 13.4 GB/s = 92% of link
  - B70 pinned H2D/D2H 12.9-14.5 GB/s (same physical class of link). sysfs lies for the
    Arc: shows x1/max-x1 - ignore it, trust measured copies
  - both facts mean the streamed-prefill weight DMA is HARD link-bound; no software knob
    can beat ~13.5 GB/s. A chassis that gives the 3090 x16 would lift prefill directly.

Sweep results (min-of-2 unless noted; auto = the incumbent):
  - mcs (worker-share experts): 256 = the FLOOR on this box - 224/192 die in
    _load_autosplit with "Insufficient VRAM in split" (3090 is full); 320 prefill 1480
    (-22%), 384 prefill ~1300 + only 46/48 registrations (B70 VRAM edge). Balanced.
  - EXL3_MOE_STREAM_T (hot-expert threshold): 8 -> 1779, auto (=11 via the live
    bandwidth probe) -> 1886, 16 -> 1757, 32 -> 1590, off -> 1493. The probe nails the
    peak; it is bandwidth-scaled, so the x8 link is already priced in.
  - WSLOTS/WSLOT_MB/STAGE_THREADS/BATCH_EXPERTS/FUSED_ROWS: all defaults win
    (1735-1880 range, none above noise).
  - CPU_SWAP=0 (static placement, kills the 3.7 s/run stager): decode identical, prefill
    -1.5% - the staging churn pays for itself.

Decode anatomy (why decode won't move): 14.2 ms/token; rows1 b70 compute 18 us x 48
= 0.86 ms + exposed collect ~10 us x 48 = 0.5 ms - the offload path is ~10% of the
budget; the rest is the 3090's captured-graph replay floor. Force-int8 stays WORSE at
rows=1 in the real model (67.8 vs 70.9) - auto-float for m=1 is right, end of debate.

Verdict: prefill is limited by (a) 3090 expert GEMV + streamed recon throughput and
(b) the 13.4 GB/s link; decode by 3090 replay overhead. Offload-path software is at its
plateau; further gains need kernel-level work on one side (b70 prefill job 11 us/row,
bench-side) or the lane bifurcation fix (hardware-side).

## Placement-policy campaign v2: the "hot experts love B70" theory was an artifact

With the honest plugin (real >64-row jobs, exec_mu, growth fix), moving hot experts to the
worker device LOSES ~18% prefill (invert/hot2 1375-1526 vs base 1645-1882) while B70
utilization rises 20%->30% and power 91W->111W. Campaign v1's invert "+21% prefill" was
entirely the FATAL-refusal bug: big tail jobs returned instantly with stale slot contents,
so the "winning" runs simply skipped the work. Decode: all policies 67-73, no separation
(the +/-3% run-to-run noise band is real; scoring rounds matter more than spacing - sleeps
between runs were LONGER than whole evals; cache-warm load+run is ~40 s).

Why B70 loses hot work: at model shapes a prefill tail job costs ~11-13 us/ROW (~2.2
us/pick-row) - vs the 3090's streamed reconstruct at ~1.5-2 us/pick-row once the 93 us/expert
PCIe stage amortizes over >=11 rows. So per hot pick the 3090 path wins ~5x, and only
overlap makes it palatable. B70 wins where picks are SPARSE (cold experts: read once,
few rows, and crucially no PCIe at all) - which is exactly what the default placement
gives it. Verdict: default placement is not laziness of the split, it is the economic
optimum of the current kernel speeds.

The real lever for B70 share (and utilization) is therefore KERNEL-SIDE, not placement:
bench E128/rows128 = 3457 us against a ~250 us distinct-expert DRAM floor (13x off) - the
DPAS path is latency/scheduling-bound at m8n16k32 with 8-token chunks, not bandwidth-bound.
Closing that gap (bigger m per DPAS chain, more co-resident WGs, 128-lane groups revisited
NOW that the pipeline is DRAM-latency-clean) is what would let hot2/invert pay off.

## Native-L0 submission: feasibility PROVEN (t35/t36/t37 labs)

Question: can forwards be raw ze appends on ONE immediate command list (host cost
~2 us/append) instead of N SYCL submits (~4-6 us host each + RT bookkeeping)?

Measured on this stack (CR 26.35, UR v2 adapter, oneAPI 2026.2):
- SYCL queue submits: ~3.7 us each HOST; a 6-kernel chain + wait = 23-44 us.
- Raw ze appends: 12-15 us for the same 6-kernel chain (+wait). Immediate command
  lists are ALREADY the RT default on DG2+ (UR_L0_USE_IMMEDIATE_COMMANDLISTS, device
  default PerQueue), so the delta is handler/event-pool/capture overhead, not lists.
- level-zero-devel now installed; compile interop with -lze_loader.
  Current ze_group_count_t = 3 fields; local size via zeKernelSetGroupSize OR the
  ByValue launch zeCommandListAppendLaunchKernelWithArguments (args = void*[] of
  pointers to values; NULL pParams unused there). zeModuleCreate takes hDevice (1.16+).

Traps found the hard way:
1. sycl::get_native(kernel) handles from RT-JIT bundles ACCEPT raw launches (all rc=0,
   timestamps fire) but NEVER execute - not even a no-builtin single_task. RT-module
   kernel handles are not for external consumption. (t35)
2. Appends to a zeCommandListCreateImmediate list built on get_native(context) DID
   execute kernels?? No - they FAULTED SILENTLY and later segfaulted NEO's staging
   copies. Lesson: one list, the queue's own.
3. WORKING COMBINATION (t36/t37): OWN module from OWN SPIR-V in the SYCL context
   (get_native<context>) executed on the queue's own immediate list
   (get_native<queue> variant holds ze_command_list_handle_t when in-order+immediate):
   correct args, correct get_global_id/get_group/get_local_id, correct subgroup
   collectives. Verified with nd_item + reduce_over_group kernels.

SPV pipeline for SYCL-flavored kernels (t37, needed for joint-matrix kernels):
  icpx -fsycl -fsycl-targets=spir64 -save-temps -c k.cpp     # device bc
  sycl-post-link <...spir64...>.bc -ir-output-only -spec-const=native -o tl
  llvm-spirv tl -o k.spv                                     # entries: _ZTS2nk etc.
Entry names = mangled typeinfo of the kernel-name class, stable for a given build.
ocloc (`-device bmg`) is the fallback for plain kernels (emits both .bin and .spv).

Integration sketch (b70_lib): build-time SPV extraction of the moe_sycl kernel set ->
embedded blob; module+kernel table at b70_init; forward = WithArguments appends on the
queue list + one trailing signal event; SYCL remains for allocation/upload/registration.
Estimated win: ~15-30 us/forward host-side, more if RT event pools show up in the tail;
gate with EXL3_MOE_B70_NATIVE, verify bit-exact with the i8trace battery.

## Megakernel experiment: worked, then lost on its own premise (ripped out)

Built the single-launch int8 forward (moe_mega.inl, now removed): six pipeline stages
as phases of one persistent kernel with grid-wide arrival barriers, virtualized group
coords reusing the real kernel bodies (exec/exec_cluster entries kept? NO - fully
reverted; labs and lessons below).

Hard-won facts:
1. BARRIER CORRECTNESS: wg barriers are NOT memory fences at device scope. The first
   "partial sum" corruptions (deterministic-looking ratios 0.72/0.16...) were other
   WGs' stores unpublished, fixed by it.barrier(sycl::access::fence_space::global_space)
   around the arrival/spin (sycl::atomic_thread_fence does not exist in 2026.2).
   Split kernels never show this because kernel boundaries flush implicitly.
2. Pair-symmetric loops are mandatory wherever two 128-threads halves run different
   units inside one 256-WG: ANY conditional group_barrier (hadamard128's seven, K6's
   WAR guard) must execute the same number of times in both halves - pair-max
   iteration counts with replay-and-skip-stores is the pattern that works.
3. The F1 polarity trap: Gemv8's third template parameter is F1 (frag1 ENABLED), not
   "slim". Mega passed SLIM straight through and silently zero-filled frag1 at m>4.
   rows<=4 battery passed; rows>=16 caught it. (Same bug shape as the historical
   frag1 peeling poison - see the F1 notes above.)
4. PERFORMANCE VERDICT (the real reason to rip it out): the barrier mechanics cost
   what t38 predicted (~2-5 us/barrier at 32-128 WGs), but phasing serializes the
   device. The gemv phases want the whole machine (rows=4/tk=8: 1240 tile-units); a
   megakernel grid must be <= co-residency, and the DPAS WGs are register-fat:
   GRID=96 never completed (t38's thin-kernel ceiling of 160-280 does NOT transfer),
   and at the safe grids (16-32) mega measured 2.5-6x SLOWER than the split pipeline
   at every shape including rows=1 decode (466 us vs 183). The per-command overhead
   it removes (~5 x 4-10 us) was never the dominant cost - starvation is.
5. An unresolved cluster-B store anomaly (one unit's stores landing in the wrong
   slice region at dual-cluster gemv-down; sentinel-probed, not root-caused before
   removal) - would need t37-style native dispatch to dig out; moot unless (4) changes.

Restart conditions: only worth revisiting with (a) native-L0 submission landing most
of the command-cost win anyway (see lab entries above), or (b) an actual grid-sync
primitive (cooperative launch/CLC) that lets phases use full-size disjoint grids.
Keep t38_bar as the barrier lab. The exec()/exec_cluster virtualization seam is not
needed by the split path and was reverted with it.

## Prefill roofline, corrected: it was the A-operand gather all along (labs t39/t40 -> I8RING)

The "E128/rows128 is 13x off the DRAM floor" note was WRONG twice over: (a) the floor
was computed with a 3.3MB B matrix - the int8 tier streams the native K2-bit trellis
(~410-520KB per gu matrix at 2bpw), and (b) per-slot cost was attributed to B re-reads.
The t39 sweep over (E, rows) shapes fits time ~= F x chunks + V x assignments with
F ~ 8/16 us (slim/fat slot) and V ~ 0.03 us: cost is per slot (per matrix traversal),
per-token DPAS is free; and MORE chunks per expert (10x B re-read at E16/rows128) made
per-token cost LOWER, not higher. Re-reads are a ~1.5-2x secondary term at most shapes.

t39_stream.cpp replays the real Gemv8 B-ladder + band + fragment pipeline standalone
with the DPAS segment stage-gated (compile-time stages 1..18). At production footprint:
loads alone 581 GB/s (saturated), +band stores 577, +jb SLM loads 576, +global ja
fragment loads + mads 141 (!!), +mads with ja loads removed 517. The joint_matrix
GLOBAL A load is the entire regression: it lowers to a per-lane byte gather. Feeding
the identical bytes with per-lane contiguous 16B vector loads (fragment stale) runs at
the no-A ceiling (st18 == st6): 2.76x of the whole kernel recovered by memory form
alone. joint_matrix cannot take a packed i8 A operand (no IGL builtin - the error even
prints the intended v8i8 lowering name). SLM-ring delivery works (st12 local-ja ~=
free; st14 wide-WG + 4-region group ring: 1.67x) but its WG barrier/copy tax leaves
~40% on the table vs the ceiling.

Production fix shipped behind EXL3_MOE_I8RING=1 (fat gemvs only): wide 128-lane WGs +
4 KB contiguous cooperative A copy per k-group into 4 rotating SLM regions + one group
barrier per group + local ja loads. Bit-exact by construction (same values, new
delivery; full i8trace + fingerprint battery agree to the digit). E128/rows128 3445 ->
2354 us (-32%), E512/rows128 8181 -> 4695 (-43%), rows32 -21..-24%, decode untouched
(slim path not gated). Default stays OFF pending the model eval gate, then flip.

t40_esimd.cpp proves the endgame for later: per-thread xmx::dpas<8,8,int>(acc,b,a) with
s8/u8 works TODAY - operand layouts verified by impulse probes (A: per-thread row-major
8x32B blocks via load_2d; B: VNNI byte order ((k>>2)*16+n)*4+(k&3), 512B per k32 panel);
random-regression bit-exact both u8 and s8 (bias-128) weight modes; DRAM-regime perf
1280 threads x 41KB panels = 62 ns/unit, on par with the fixed SIMT pattern - ESIMD's
prize is removing the gather AND the SLM-ring barriers in one move when we rewrite the
tier (likely together with MAXM 16/32 wide-row instantiation, CUDA m32/m64-style).

Traps recorded this session: (1) q.copy() H2D SEGVs inside NEO staging on this stack -
use q.memcpy (everything already did; the lab was the exception). (2) A failed SYCL
kernel build fails at first LAUNCH, and piped icpx rc hides build death - ALWAYS check
the log, never just grep the last line (two "results" this session came from stale
binaries). (3) runtime stage-gates let LLVM DCE the loads being benchmarked - gate at
compile time. (4) probe K must be a multiple of the dpas k-step or windows alias.

## Three-tier B70 placement campaign (4.05bpw -mcs 420, pinned arena, ring, budget 0.70)

Columns: prefill tok/s @1024 / decode S=1 @ctx0. All rows are real log extractions
(/tmp/tt_grid*.csv), interleaved, one pass.

| placement                             | pre   | dec  |
|---------------------------------------|-------|------|
| no B70 (pure CPU + pinned streaming)  | 226   | 37.5 |
| classic full-layer (21/48 registered) | 590   | 48.1 |
| SUB=0.20 (48/48, tier 84)             | 447   | 46.9 |
| SUB=0.35 (tier 148)                   | ~495  | 54.0 |
| SUB=0.50 (tier 212)                   | 532   | 54.2 |
| SUB=0.70 (tier 294)                   | 558   | 51.4 |
| SUB=auto (fair share, tier 201)       | 577   | 51.0 |

Readings:
- Decode is where three-tier pays: +6 t/s (+13%) over full-layer at SUB 0.35-0.5; the
  hot experts of ALL layers hit device VRAM instead of 27 layers' CPU compute. The
  -mcpa anti-theft masks (streaming + promote-on-miss skip B70-tier slots) are a
  necessary half: without them the pinned arena strips the B70 of exactly that work.
- Prefill wants BIG device tiers (monotone in SUB): mixed jobs put the CPU-tier tail
  through the CPU pool, and the pool is slower than either GPU. Full-layer + aggressive
  streamed prefill still wins prefill by ~8% at equal budget.
- auto (deferred fair-share at worker start; also kills the load-time register/forward
  race entirely) lands prefill-best of any three-tier config (577) with dec 51.
- std::async overlap of the mixed-job halves: +/-0 at tier 0.5, -1.5 at 0.2 (thread
  handoff + a core outside the pinned pool). REMOVED. The serial cost was elsewhere.
- budget 0.82 + subsets: registration fault storm gone (footprint now bounded per
  layer); keep 0.70 as the sane default anyway.
- Trap recounted: I again reasoned from "measurements" that had never run (round5 died
  on a missing chmod +x while I narrated its results). CHECK THE CSV EXISTS BEFORE
  BELIEVING A NUMBER. The commit carrying the phantom async numbers was amended.

Open: stream_t sweep at SUB=0.5 (round 7) - the pinned-arena stream to the 3090 is
26 ms/layer of pure PCIe at st=auto during 1024-token prefill; larger tiers shrink
the streamed SET (fewer, hotter streamed experts), smaller tiers grow it; the
interaction may dominate the remaining prefill gap. Then: 2.68bpw sweep.

## Rounds 7-9 verdict: stream_t interacts strongly with the tier size

4.05/SUB=0.5 prefill: st auto(11) 530 | st6 575 | st16 495 | st24 444. With three tiers
the streamed SET is only CPU-tier experts, so the classic conservative threshold starves
the fast path; lowering it streams more, colder experts and still wins (they'd cost the
CPU pool more). But optima are model/depth-specific: 4.05 st3+auto-tier COLLAPSED to 452
(deep oversubscription: streamed bytes outrun the DMA), while 2.68 auto-tier runs 748
prefill / 53.3 decode WITHOUT any stream_t override (+43% prefill vs classic full-layer).
=> keep the adaptive auto probe as default; SUB=auto is the recommended setting for any
model whose expert bytes exceed 3090+B70; explicit stream_t is a per-model trim knob,
worth ~8% on 4.05 (st4: 599/53.8 - beats classic on BOTH axes). no-mcpa pays only ~9%
prefill at auto-tier on 2.68: the tier wins even without page-locked streaming.

## Round 10 + confirmations: overlap verdict and prefill noise floor

Prefill repeats of ONE config (4.05, SUB=0.5, st4, overlap on): 608 / 568 / 576 (±3.5%,
overnight thermal?). Decode is rock stable (54.7/54.2/53.6/54.6). Lesson: single-digit
percent PREFILL deltas need 3 reps or a cooled interleaved pair; decode deltas >=1 t/s
are trustworthy from one run. Overlap stands at "0-4%, noise-bound, mechanistically
sound" - kept default-on for rows>=16, kill switch EXL3_MOE_B70_OVERLAP=0.
Final headline configs measured this session (pre/dec tok/s):
  2.68bpw auto-tier+pinned+ring: 748/53.3 (classic tier 525/47.6, CPU-only -)
  4.05bpw SUB=0.5+st4+pinned+ring: ~580-600/54 (classic 590/48.1, CPU-only 226/37.5)
2.05bpw regression trio running (full-tier registration + anti-theft rule = streaming
blocked on fully registered layers by design; must confirm no prefill loss there).

## Guard trade-off finale (rounds 15-17): placement regime is a real fork

2.68bpw same-build comparisons, pre/dec:
  pre-guard  (SWAP_TIER=0-era, r9): 748 / 53.3   <- prefill king
  hard guard (tier-only sources):          484 / 58.7
  soft guard (HOTMULT=4):                  512 / 59.2
  soft guard + st2:                        558 / 59.1  (st4: 528/58.3, sub0.7+st4: 562/56.5)
4.05: pre-guard auto 577/51.0 -> guarded default 491-508/57.3-57.9; SUB=0.5+st4 guarded 598/54.7.
Keeping hot experts B70-resident (guard) buys +5..6 decode t/s and costs prefill proportionally
to how much hot mass the sweep would have moved to the 3090 - streaming can partly compensate
(st2 recovers ~46 on 2.68) but the ~750 prefill number belongs to the steal-from-B70 regime.
HOTMULT 8 vs 4 vs 2: no material prefill difference (outliers are rare); 2 kept decode best.
RECOMMENDED DEFAULTS STAND as shipped: guard on (decode-weighted; this box is decode-poor),
stream_t auto probe, tier auto. Prefill-priority deployments: EXL3_MOE_CPU_SWAP_TIER=0
(+ optionally pinned streaming) reverts to the 748-era behavior; documented knob, not default.
Every model on every axis this session (best measured, pre/dec):
  2.05: 1886 / 72.6   (pure defaults, self-tuned full tier)
  2.68: 748 / 60.0    (TIER=0 era max prefill | guard+st2/HOTMULT=2 for decode-first 556/60)
  4.05: 599 / 57.9    (SUB=0.5+st4 prefill | default guarded for 494/57.9, +165%/+54% vs no-B70)

## Deliberately parked (with reasons), candidates ordered
1. Native-L0 decode submission chain -> PLAN_L0.md (biggest remaining decode lever,
   scoped + all feasibility probes already done; fatigue-appropriate for a fresh session).
2. RING for the slim kernels: implemented only in the F1(fat) branch; slim+j ring needs
   ~10 lines (same ring, fk-only offsets) - affects rows2-4 int8 only, niche.
3. Split-K retune under ring: NSLU=2 wins ~5% at r32-class but loses at r2/r128; the
   rows-dependent rule isn't worth the config risk now (auto caps already route r128
   correctly). Revisit AFTER any kernel-side change (ring shifted the whole landscape once).
4. B70-side weight streaming for hot CPU-tier experts (stream INTO tier slots via
   update+evict protocol): the only way to beat 748-era prefill WITH the decode gains;
   real cache-protocol work, next-tier effort.
5. MAXM 16/32 wide prefill tier: still valid, orthogonal, separate instantiations only.

## L0 native submission: how far the probe got (t42/t43 + arg-count probes)
VERIFIED on the PRODUCTION TU (not toy kernels):
1. moe_sycl.cpp -c -save-temps -> sycl-post-link -ir-output-only -spec-const=native ->
   llvm-spirv -spirv-ext=+SPV_KHR_cooperative_matrix => VALID 243KB SPV; the erff
   undefined-symbol warning is harmless (zeModuleCreate accepts the module; 27 kernels,
   names are _ZTS... mangled, strstr-selectable). Completion via plain q.wait().
2. Functor kernel ABI via zeKernelSetArgumentValue probing: args are EXACTLY
   {captured ptrs..., by-value capture struct, local_accessor as one 8B ptr}; nd_item
   adds NO visible args; WithArguments validates count strictly (short array = memmove
   segfault INSIDE NEO - never probe counts by crashing).
3. BLOCKER = SLM binding for the accessor arg: module metadata says localMemSize=0;
   any host/device pointer passed as the local arg does NOT bind shared memory (kernel
   completes rc=0, writes vanish), nullptr + barriers deadlocks the queue. The SYCL
   runtime clearly uses driver-internal local binding invisible on the public ze surface.
   NEXT STEP (sanest path first): build an SPV variant with -DMOE_L0_NO_SLM that points
   the band/ring slabs at per-layer GLOBAL USM scratch (kernels become pure-global,
   trivially WithArguments-launchable; slim-path bands are tiny so SLM->global cost
   should be small - MEASURE on bench shapes); only if that regresses, reverse-engineer
   the UR/L0 KernelImp local-arg trick. Upside if achieved: ~20-45us/layer x 48 decode.

## EXL3_MOE_CPU_SLOT_ROWS anatomy (the question: is it the MoE chunk size?)
Hierarchy of "chunk" on this path (do not conflate):
- cap_rows (SLOT_ROWS, python TUNING:101 -> _issue_compute `for a in range(0,rows,cap)`):
  TOKEN ROWS PER WORKER JOB. Sizes the pinned handoff slot (x/sel/w/out block layout is
  single-sourced from cap_rows in BOTH moe_cpu_host.py:1245-1294 and moe_handoff.cu:470),
  the collect window (= num_slots jobs), the b70 bounce/stage via ensure_capacity, and the
  tmap blob. It is the knob analogous to a micro-batch, NOT the DPAS tile.
- MOE_MAXM=8 (ChunkDev rows): the DPAS chunk width = the true analogue of CUDA's
  MOE_TILESIZE_M. Raising it is the wide-M tier project (new instantiations, acc/a8 layout
  constants derive from it), separate from cap_rows.
Why bigger cap_rows wins prefill (measured, E512 bench, us/token-row): 54.6@64 -> 36.5@128
-> 22.7@256 -> 18.3@512 -> 15.9@1024: sublinear because slots fill toward 8 rows and the
per-job chain (stage D2H + 6-kernel chain + readback + collect) amortizes over more rows.
e2e tables in doc/env_vars.md. Memory management needed for the raise: NONE functionally
(all device buffers grow on demand: ensure_ws by nc, ensure_capacity by rows), but two
real fixes came out of it: registration warm (2048,1024) pre-inflated the SHARED pool
~1.2 GB underneath the whole weight set (widest-slice models then failed the first real
pool grow near VRAM-full -> pin -> wedged staging ring (observed: 100% CPU spin in parent
at warmup)); warm now (512,512), and grow_p OOM THROWS (b70_forward catch -> clean pin)
instead of null-pointer device faults. Pool bytes no longer count in the registration
budget (commit 0d420807) so large pools cannot starve runtime installs.
Default raised 64 -> 512 (not 1024: +5% prefill traded for the regime that surfaced the
wedging bug; retest 1024 after the warm/OOM fixes if desired). Decode unaffected by
construction (rows << cap); 2.68/4.05 decode measured UNCHANGED-to-better at 512.

## OPEN BUG: DEVICE_LOST at cap_rows>=512 on the h4/DPAS tier under skewed worker jobs
Repro: 2.05bpw, EMPTY expert_stats dir (fresh identity placement => hot experts on the
worker side => skewed per-expert m in every job), EXL3_MOE_CPU_SLOT_ROWS=512, default
auto tier: first 2048-prefill pass -> every layer logs 'forward sycl error:
UR_RESULT_ERROR_DEVICE_LOST' once (message now surfaces via b70_forward catch upgrade).
2/2 deterministic + same matrix CLEAN: warmed profile (any cap), fresh x cap<=128,
fresh x h6 models (float tier), bench shapes E256/512 rows512 tk10 uniform (int8 AND
fp32 tier, single layer). Budget 0.60 (15GB weights, <75% VRAM) STILL faults => NOT
pressure; it is an address fault in the fat int8 path (ring? prep-quant? gemv?) that
only SKEW reaches (large per-expert m => deep chunk chains per expert, nc up to ~3.5k).
DEFAULT RESTORED TO 128. Next move: --skew (zipf) assignment mode in bench_layer to
reproduce standalone, then bisect EXL3_MOE_I8RING=0/1 and slim; suspect a8/qsx or ring
copy addressing when chunk slots per expert >> warm-case counts.

## Fault forensics round 2 + poison latch (the hang is DEAD, the fault is alive)
- NOT memory pressure: 17.78 GiB constant at fault (user-measured), budget 0.35 still
  faults => address/context fault in float-tier 512-row jobs under (only partly modeled)
  skew; bench cannot reproduce even at zipf 3.0 (single-layer, serial). Pipeline-only
  ingredients remain: 48 layers + ring staging + multi-thread job arrival.
- THE FIX THAT MATTERS REGARDLESS (b70_lib): g.poison latch. First forward exception
  latches the plugin; every later forward returns 3 instantly (never touches the dead
  queue). Completion wait is bounded (15 s deadline polling
  get_info<command_execution_status>; DPC++ has no event::poll/timed wait_and_throw).
  Verified on the previously-UNHELLABLE config (fresh+float+512): one fault, clean
  pinning cascade, full eval completes (exit 0). Before: infinite parent spin.
- Cap default stays 128 (clean everywhere incl. all fresh-profile arms). 512 is safe on
  the h6 float tier (x268/x268_512/y405_512b: hundreds of 512-row float jobs clean) and
  on ANY model with warmed profiles + int8; forbidden regime today = h4 shapes, fresh
  placement, big jobs. bench_layer gained --skew <exp> (zipf selection; <0 = all-minus-1
  degenerate job probe).
