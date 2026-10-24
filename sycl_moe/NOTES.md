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