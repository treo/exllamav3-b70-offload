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
- icpx 2026.2 CRASHES silently (exit 3, no diagnostic) on -O3 for poc_dequant.cpp; -O2 fine.
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
