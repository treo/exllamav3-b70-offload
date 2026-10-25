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
