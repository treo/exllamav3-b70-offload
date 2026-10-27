# mul1 / trellis format spec, rates, and the GPU stream layout

Reference material distilled from `exllamav3_ext/cpu/moe_mul1.cpp` (scalar tier) and the
CUDA kernel map. Code-level truth lives in `moe_sycl.hpp` (`repack_native_to_stream_words`),
`exl3_ref.h`, `moe_host_ref.hpp`.

## Why the B70

Port the CPU MoE expert offload (`exllamav3_ext/cpu/moe_mul1.cpp`) so offloaded experts run
on an Intel Arc Pro B70 (SYCL / Level Zero) instead of CPU cores. Main model stays on the
RTX 3090 (CUDA) exactly as before; the B70 takes over the child worker's compute role.

## Target models (all Qwen3.8-Flash-Next: 512 experts, topk 10, H=2560, I=640, 48 layers)

| model | mul1 K2 (bits, hb) | note |
|---|---|---|
| 2.05bpw | 2 (2, 0) | needs 256 experts offloaded to fit the 3090 |
| 2.68bpw | 5 (2, 1) | |
| 4.05bpw | 8 (4, 0) | |
| 4.18bpw | HYBRID: k2 in {8, 10} per layer | "quantize bits=4.16"; K2=10 layers ride whatever tier covers them |

Treillis tile (16x16 weights) packed size: `tile_u16 = 8*(2*bits+hb)` u16 (= 16K+8 for hb).
256 experts x 48 layers x 3 matrices x (640*2560) weights ≈ 11.3 GB @2bit, 14.1 @2.5,
22.6 @4bit → all fit (tightly at 4 bit) in 32 GB B70 VRAM if resident; staging otherwise.

## mul1 state extraction (scalar-path semantics)

- `k2 = 2*bits + hb` (bits per weight in half-units / 2). Ring of `tile_words32 = 4*k2` u32 words.
- State `t` (t = 0..255) extraction, from `decode_state_scalar`:
  `b1 = ((t+1)*k2)>>1 + 128*k2`, window `[b1-16, b1)`,
  `shift = ((b1-1)/32+1)*32 - b1`,
  `merged = (u32[(b0/32)%W] << 32) | u32[((b1-1)/32)%W]`, `state = merged >> shift`.
- **MASK TO 16 BITS.** `merged>>shift` leaves up to 31 bits; the CPU spec casts to `uint16_t`.
  A missing `&0xffff` produced plausible-looking garbage early in the port.
- Weight index in tile: `idx = perm[t]` (from `make_tc_perm()`), `r = idx/16` (k within tile),
  `c = idx%16` (n within tile). Closed form (`b=t>>3, j=t&7`):
  `row = ((b&3)*2) + (j&1) + ((j&2)?8:0)`, `col = (b>>2) + ((j&4)?8:0)`.
- Dequant: `w = (bytesum(state * 0x83DCD12D) - 510) * k_inv`,
  `k_inv = fp16(0x1eee) = 0.00676727294921875` exactly (mantissa field 0x2EE = 750, not 766).
- Matrix is `[k -> n]`, trellis shape `[k/16, n/16, tile_u16]`. NATIVE tile order =
  `(tile_k*tiles_n + tile_n)`. The CPU loader may band-swizzle for AVX tiers; the GPU path
  uploads native (stream-repacked, below).

## GPU stream layout (what `repack_native_to_stream_words` does)

Validated in `t29.cpp` for **all** K2 2..17 against `decode_state_scalar`:

- repacked tile = per-tile **u32 word reversal**: `R[k] = native[(W-k) % W]`;
- then `state(t)` = the 16 ascending bits at `P(t) = P0 - ((K2*t + (K2&1)) >> 1)`,
  `P0 = 32 - K2/2`, in plain LSB-first word bit order.

`GemvK<K2V>` uses this directly; other rates ride `GemvFallback` (word-translated apack).
Note `GemvK`'s `G` (ring slack) is **negative**: any host-side window formula must
ring-normalize `P = G + rel mod (W*32)` BEFORE word/split extraction, or it flags correct
kernels as broken (this cost a whole "coalesced load" experiment's verdict credibility).

The naive fast path `merged = (w[b0/32]<<32 | w[(b1-1)/32]) >> aligned_shift` is **not**
equivalent: the scalar spec's cross-word extraction mixes word halves when crossing a
boundary. Any fast path must be validated per-window against `decode_state_scalar`
(`t21.cpp` does this on the host and caught the flaw).

## Layer forward (scalar tier semantics)

Per matrix:
1. `tin[r][:] =` per 128-block: `HAD_SCALE * hadamard_128( fp32(x[r][:]) .* fp32(suh[:] ) )`
2. `acc[r][n] = sum_k tin[r][k] * w(k,n)` (fp32)
3. `tout[r][n] = hadamard_128_block(acc) * HAD_SCALE * svh[n] (+ bias[n])`, blocks of 128 in n

`HAD_SCALE = 0.088388347648 = 1/sqrt(128)`; `hadamard_128` = sequentia butterfly width 1..64.

Layer: chunks = token rows grouped per expert (`MAX_M` per chunk);
`g = fwd(gate_e, x_rows); u = fwd(up_e, x_rows); h = act(g,u)` (silu / gelu / swiglu_oai(limit)
/ relu2); `d = fwd(down_e, h)`; `out[token] += routing_weight * d` (out zeroed first, fp32).
Lengths: `suh` per input-k fp16, `svh` (+ optional bias) per output-n fp16.
Gateless ⇒ relu2 on the up projection only.

The deployed CPU (vector) tier additionally int8-quantizes `tin` (`q = amax/127` per row,
wide 2-row fallback if `>k/16` zeros) → expect ~0.9% RMS vs fp32 there; the B70 int8 tier
mirrors the CPU VNNI identity (see `int8-dpas-tier.md`).

## Integer (DPAS) identities on top of mul1

From `exl3_ref::decode_mul1`: for product word `p = st16 * 0x83DCD12D`,
`w = k_inv * (bytesum(p) - 510)`, therefore

    bs(k,n) = 510 + w(k,n) / k_inv      EXACTLY

and a raw int8 dot whose A bytes are `x8(k)` replicated x4 gives
`C = sum_k x8(k)*bs = w-dot + 510*sum_x8` — the `-510*sum_x8` term must be folded into the
epilogue affine (`{A,B} = {KDQ*q, -510*KDQ*q*sx}`).

CPU quant semantics to mirror (`moe_mul1.cpp::quantize_row`):
- single slot: `q = amax>0 ? amax/127 : 1`, round-half-away, clamp ±127,
  splat `x8 * 0x01010101` == the DPAS A row bytes for that real-k slot (4 hw-k bytes = the
  same x8, so replication is free) — **but see the negative-splat trap in
  `int8-dpas-tier.md`: the store must mask to the low byte**;
- wide rows: `v = 128*vh + vl` with `q_wide = amax/(127*128)`, per-half `s_out`,
  scales `{q*128, q}`.

## THE BITRATE CONTRACT (what rates can ever exist)

`exllamav3_ext/quant/bits_k.cuh` + `exl3_kernel_map.cu::get_gemm_kernel_ptr` define the
universe of EXL3 mul1 rates the platform can produce: integer `K = bits 1..8` for every
codebook; HALF-integer rates ONLY 1.5/2.5/3.5 (`TORCH_CHECK K<=3 && cb==mul1`). No 4.5+,
nothing above 8 bit. Required `K2 = 2*bits + hb` set:

    {2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16}     (eleven values)

The old README "4.5bpw family" comment == K2 14 == plain 7-bit (naming drift). The 4.18bpw
HYBRID's `bits=5` layers are K2=10. Note `--bits 4 --hb 1` synthetic == 4.5bpw K2=9, which
is NOT a model rate and the CPU ext refuses it ("unsupported trellis tile width 72") — so an
xval of that shape is meaningless, don't use it as coverage.

## Coverage and specialization (as shipped 2026-10-27)

Both tiers are compile-time specialized for **every** contract rate K2 ∈ {2,3,4,5,6,7,8,10,
12,14,16}:
- `moe_sycl.hpp` X-macro lists `MOE_FOREACH_K2_FLOAT` / `MOE_FOREACH_K2_DPAS` drive BOTH the
  predicates (`moe_k2_float`/`moe_k2_dpas`, used by `int8_ok` and by bench/trace via
  `int8_pick`) AND the runtime→template dispatchers (`k2_float`/`k2_dpas` over
  `std::integral_constant`). Single source: plugin and harness can no longer disagree.
- `GemvFallback` stays as the out-of-contract safety net (correct, slow). The int8 launch
  sites **throw** (clean pin, never a silently missing kernel) if a future policy picks DPAS
  for an unlisted rate.
- `EXL3_MOE_I8W` (wide, documented-negative lab variant) is FROZEN to the legacy trio
  (k2 ∈ {4,5,8}) so new rates don't double instantiation count for a path nobody runs.
- Full-contract battery 2026-10-27: all 11 rates PASS (float ~1.3e-6 max_rel vs host ref;
  DPAS rates 1.2-2.5e-3 auto tier; forced `EXL3_MOE_B70_INT8=1` on non-DPAS rates falls back
  SAFELY at ~1.2e-6). `--i8trace`: 33 traces, every stage B..G exact.

Specialization cost model (why not blindly instantiate more): the int8 product-word identity
IS rate-agnostic (state = 16 bits at every rate, 4 bytes = 4 hw-k slots, k32 frag = 8 states)
and the stream window was validated for K2 2..17. What is rate-SPECIFIC is performance:
`K2V` as a template param buys the compile-time shifts / pair-decode that made the gemv fast.
Each new rate costs {slim, fat-ring, fat-wide} × {gu, down} Gemv8 instantiations + a full
`--i8trace` family + a sustained A/B. **Measured**: full 11-rate specialization added ~10 s
to the plugin build — measure the compiler before taxing it.

The cost-model hunch "DPAS margin shrinks at high K2" was WRONG at rows≥2: the win comes from
per-CHUNK economics (MAXM=8, two m8 fragments per weight stream), which is rate-agnostic; the
rate term only matters at m=1, where auto keeps float anyway. Hence {14,16} got full DPAS,
overriding this entry's provisional plan. Sustained tier A/B at rows=32: int8 wins EVERY rate
×3.0-3.3 (K2=2 620 vs 2026 µs; K2=10 719 vs 2260; K2=12 731 vs 2244); rows=2 still ×1.3.

Model evidence: 4.18bpw (HYBRID K2{8,10}, warm profile, SUB=0.5) prefill 807 / dec 43.5, and
100 rows≥2 jobs ran `use8=1` on k2-10 layers in the real model, zero faults/pins/update
failures. First-ever K2=10 `GemvFallback` traffic at model scale appeared here (J-line log:
70887 k2-8 forwards vs 3300 k2-10 before specialization).

## Historical PoC (still true, still the base of everything)

`poc_dequant.cpp`: GPU state extraction + mul1 dequant bit-exact vs host ref for
K = 1, 1.5, 2, 2.5, 3, 3.5, 4, 6, 8. Runtime-parameterized ring math works.