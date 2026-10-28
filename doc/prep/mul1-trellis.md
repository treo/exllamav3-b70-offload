# The mul1 trellis specification

What an EXL3 tensor actually contains, written for someone implementing a new consumer of it.
Every numbered claim below is checked against real checkpoint data by
`python notes/verify_trellis.py` (branch history) — the tail-biting property, the exact match of
the independent NumPy dequantizer with `ext.reconstruct`, the codebook's value set, the packed
layout round-trips and the integer-fusion identity.

"mul1" is one of three EXL3 codebooks (`3inst`, `mcg`, `mul1`) layered on the same trellis
container. The container is what makes the format unusual: **weights are not stored as indices
into a codebook, they are stored as the 16-bit sliding windows of a bit ring**, and the codebook is
a pure function of that 16-bit window.

---

## 1. Tensor inventory of one quantized linear

A quantized `Linear` (dense, shared expert, or one routed expert) is a set of same-named tensors
next to the module key:

| tensor | dtype | shape | meaning |
|---|---|---|---|
| `<key>.trellis` | `int16` (read as `uint16`) | `(k/16, n/16, 16·K)` | the packed bit rings, one 16×16 tile per `(i,j)` |
| `<key>.suh` | `fp16` | `(k,)` | per input-channel scale (applied before the input Hadamard) |
| `<key>.svh` | `fp16` | `(n,)` | per output-channel scale |
| `<key>.bias` | `fp16` | `(n,)` | optional, per output channel |
| `<key>.mul1` / `<key>.mcg` | `int32` scalar | `()` | codebook marker; only its **presence** is read (`quantize.py:32`) |
| `<key>.su` / `<key>.sv` | `int16` bitfield | `(k/16,)` | legacy: packed ±1 sign bits, unpacked to `suh`/`svh` by `LinearEXL3.unpack_bf` |

`k`/`n` are the **padded** dimensions: `Linear` rounds both up to `pad_to = 128`
(`modules/linear.py:54-77`, and `BlockSparseMLP.intermediate_size_padded`), so `k/16` and `n/16`
are whole numbers of tiles and every dimension is a whole number of 128-wide Hadamard blocks.
Narrower runtime inputs are zero-extended to the padded width — this is the `hi != h_` padding seen
in the CPU offload path.

The bitrate comes from the tile width alone (`block_sparse_mlp_cpu.trellis_rate`,
`modules/block_sparse_mlp_cpu.py:381`, `modules/quant/exl3.py:67`):

```
K = tile_width / 16            # 16*K uint16 words per tile, always a whole number of words
integer 1..8 bpw  -> width 16, 32, 48, 64, 80, 96, 112, 128
half  1.5/2.5/3.5 -> width 24, 40, 56                (mul1 codebook only)
```

Observed in the shipped checkpoints (`notes/scan_widths.py`, `notes/scan_mixed_rates.py`):
Qwen3.8-Flash-Next @2.68 bpw stores routed experts at **2.5 bpw** (width 40) in layers 4-43 and at
**3 bpw** (width 48) in layers 0-3 and 44-47, its MTP head's experts at 2.5 bpw, its attention and
shared experts at 6 bpw, and `lm_head` at 6 bpw; Qwen3.5-35B-A3B @3.17 stores routed experts at
3 bpw, its MTP experts at 4 bpw, shared experts and attention at 7 bpw, `lm_head` at 6 bpw. Across
the whole local Qwen3.8-Flash-Next family the routed experts are uniform *within* every layer
(2.05/4.05/5.05/6.05 bpw quants use one rate everywhere; 2.68 mixes 2.5 bpw — layers 4-43 — with
3 bpw in layers 0-3 and 44-47; 4.18 mixes 4 bpw with 5 bpw in layers 0, 1 and 47). Rates therefore vary **per layer** (0.73 vs 0.88 GiB of expert trellis per layer, 36.33
GiB for the 48 MoE layers of Qwen3.8 @2.68), but every expert *inside* one layer shares a single
rate in all local checkpoints — which is what the staging byte layout assumes. The CPU worker
nevertheless keeps `bits`/`hb` per matrix (`MoeCpuMatrix`, `cpu/moe_mul1.h:24-41`), while
`register_layer`'s `proj_bytes` and `stage_phase` derive the per-expert block from **expert 0's**
dimensions (`moe_cpu_host.py:1158-1164`, `moe_mul1.cpp:3570`): a checkpoint that ever did mix rates
inside a layer would stage wrong offsets, so a port should assert uniformity at load rather than
rely on the observation. (An earlier revision of this note claimed layer 0 of Qwen3.8 @2.68 was
mixed; that was a scan artifact — the pattern conflated `model.language_model.layers.0` with
`mtp.layers.0`.)

## 2. The trellis container

Written by the converter as `quantize_tiles` → `pack_trellis` (`quantize.py:1117`), read by
`unpack_trellis` / `reconstruct` / the GEMV kernels. Per tile (256 weights):

* Position `i ∈ [0,256)` contributes `D(i)` new bits: `D(i) = K` at integer rates; at a
  half-integer rate `K = KA + 0.5`, `D(i) = KA + bit(i mod 16) of MASK`, `MASK = 0xAAAA`
  (alternating `KA`/`KA+1`, so every 16 positions consume exactly `16·KA + 8` bits).
* `S(i) = Σ_{j ≤ i} D(j)`, and the ring holds `R = Σ D = 256·K` bits.
* Position `i`'s **16-bit window** (its "state", the codebook index) is ring bits
  `[S(i)-16, S(i))`, read MSB first, indices taken `mod R` — a *tail-biting* ring: a window's low
  `D(i)` bits are its own new bits, its high `16 - D(i)` bits are the previous window's leftovers
  (`frac.cu:9-13`, `testlib/trellis.py:5-19`). Verified true on real expert tensors.
* Packed form: the ring as 32-bit words with ring bit 0 at the **MSB of word 0**, each word stored
  little-endian as two `uint16` (so `uint16[2j]` is the low half of word `j`).
* Element order inside a tile is *not* row-major: ring position `i` holds row-major element
  `tile_perm(i)`, the tensor-core fragment order

  ```
  for t in 0..31, j in 0..7:  r = (t % 4) * 2 + (j & 1) + 8 * ((j >> 1) & 1)
                              c = t // 4 + 8 * ((j >> 2) & 1)      # element = r * 16 + c
  ```

  (`quantize.py:44-68`, `moe_mul1.cpp:129-146`, `moe_unswizzle.cu:38-45`, `frac.cu:37-45` all
  encode the same permutation; `testlib/trellis.py:tile_perm` is the independent reference.)

So decoding a tile is: read the ring, take 256 overlapping 16-bit windows, map each through the
codebook, scatter with `tile_perm` into a 16×16 block.

## 3. The mul1 codebook (cb 2)

```
x(s) = (uint32)(s * 0x83DCD12D)                       # s = the 16-bit window
bytesum(s) = (x & 0xff) + ((x>>8) & 0xff) + ((x>>16) & 0xff) + (x>>24)
w(s) = fp16( (1024 + bytesum(s)) * k_inv + k_bias )   # computed as one hfma in fp16
       k_inv  = fp16 bits 0x1eee = 0.0067672729...    (~1/147.7)
       k_bias = fp16 bits 0xc931 = -10.388...         (= (-1024 - 510) * k_inv)
   ≡ (bytesum(s) - 510) * k_inv   in exact arithmetic
```

(`quant/codebook.cuh:36-50,80-104`; the multiplier is also the marker value stored in
`<key>.mul1`, `exl3_lib/quantize.py:19`.)

Measured properties (`notes/verify_trellis.py` section [3], on the full 65536-state space):

* `bytesum` takes 913 distinct values ⇒ **the codebook has 913 distinct weights**, up to 175 states
  sharing one value. Range `[-3.4531, 3.3477]`, mean `-0.0019`, std `1.0003`, and the 1/25/50/75/99
  percentiles (`-2.256, -0.699, -0.002, 0.695, 2.244`) sit within ~3% of the equivalent Gaussian's
  — i.e. the multiplication is chosen so that a uniformly distributed state maps to an
  (approximately) unit-normal weight. That is the entire design: the "codebook" is procedural
  (see `doc/procedural_codebook.png`), needs no table, and costs one multiply plus a byte sum.
* `mcg` and `3inst` decode differently — `(x & 0x8fff8fff) ^ 0x3b603b60` split into two fp16 halves
  that are added — and are **not** affine in a byte sum, which is exactly why the int8 fast paths
  (`EXL3_INT8_GEMV`, the CPU MoE kernels, unfused MGEMM) are mul1-only
  (`model/config.py:31,77-80`).

### 3.1 Why the CPU GEMV is a dot product of integers

Because `w` is affine in `bytesum`, a whole dot product collapses:

```
Σ_k w(s_k) · x_k = k_inv · q · ( Σ_k bytesum(s_k · M) · x8_k  −  510 · Σ_k x8_k )
```

with `x8 = round(x/q)` the row's int8 activations and `q` its scale
(`cpu/moe_mul1.cpp:36-56`). `Σ x8` is a per-row constant, so the weight-side term is one
`vpdpbusd` per 16 weights on AVX-512+VNNI, or (AVX2 / AVX-512BW, no VNNI) a bytesum-first
accumulate with `vpmaddubsw` + `vpmaddwd` that keeps the activation outside the byte pair to avoid
saturation. Accuracy is stated as ~0.9% per-call output RMS (GPU int8 GEMV mode-2 class); the
identity itself is verified numerically to fp16 rounding (`[5]`, rel err 3.3e-4).

Consequence for the input side: activations must be quantized to int8 per row, and a row whose
small elements would all round to zero is carried as **two** int8 rows (15-bit split,
`EXL3_MOE_CPU_WIDE`, `moe_mul1.cpp:76-82,393-420`). Accumulators are int32, which is why the CPU
kernel caps `k <= 8192` (`moe_mul1.cpp:3674`).

## 4. Layouts on top of the container: native vs "packed"

The **native** layout above is what every GPU kernel reads. The CPU expert kernels additionally
repack tiles so a GEMV's k-stream is sequential in DRAM. Rules are the single pair
`exl3_moe_cpu_swizzle_group(K)` / `exl3_moe_cpu_planar_layout(K)` (`moe_mul1.cpp:3633-3644`),
resolved by the runtime ISA tier (`EXL3_MOE_CPU_MAX_ISA` caps it) and per rate:

| tier | integer K | half-integer K | notes |
|---|---|---|---|
| `scalar` | native | native | |
| `avx2` (this test box: Zen 3) | band **2** + **planar** dwords, all K 1..8 incl. 8 | native | `avx2_swz2_pair` kernels |
| `bw`, `vnni`, `vbmi` | band **8**, except **K8 native** | band **8** | K8 routes to the dword kernel, which gains nothing |

Both transforms are pure index permutations of the tile array (and of the dwords inside a tile):

```
band-g:   tile (kt, nt) moves to linear index (nt / g) * tiles_k * g + kt * g + (nt % g)
              i.e.  out.view(tn/g, tk, g, words) = in.view(tk, tn/g, g, words).permute(1,0,2,3)
planar:   inside a tile (integer rates only), 32-bit dword w moves to  8*(w % bits) + w // bits
              i.e. the tile's (8, bits) dword grid is transposed to (bits, 8)
```

Applied by the worker's arena loader (`_copy_repacked`, `moe_cpu_host.py:394`, from
`rehome_trellis` in `_moe_cpu_child_main`), inverted host-side for demotions (`_copy_unpacked`),
and inverted **on the GPU after each DMA** by `moe_unswizzle_trellis` (`moe_unswizzle.cu`) whenever
a layer's experts arrive packed. Round-trips verified for K = 1, 2, 2.5, 3, 8 (`[4]`). Why planar
helps on AVX2: under the tensor-core permutation a half-row's 8 source dwords then sit in one
register, so a weight gather is one `vpermd` instead of a register walk
(`doc/env_vars.md:475-490`).

Effect on measured cold-expert bandwidth on this machine (Zen 3, `EXL3_MOE_CPU_*` defaults,
15 threads, 8-10 experts per call): K=3 with band-2+planar reaches ~47 GB/s, K=2 ~40 GB/s, while
K=2.5 — which the AVX2 tier leaves **native** — reaches only ~31 GB/s (`notes/m_cpu_*.txt`). A port
to an AVX-512 or NEON/SVE target inherits the band-8 rule instead, where half rates *are* banded.

`EXL3_MOE_CPU_SWIZZLE=0` keeps native bytes everywhere (loader, kernels and GPU path all agree,
since the rule is queried, not duplicated).

## 5. Turning a tile array into a weight matrix

```
Ŵ[k, n]                # rotated-basis weights: tile (kt, tn) -> block Ŵ[16kt:16kt+16, 16tn:16tn+16]
W = diag(suh) · (H ⊗ k-blocks) · Ŵ · (H ⊗ n-blocks) · diag(svh)      # H = Sylvester H_128 / sqrt(128)
y = x · W + bias
```

Applied in the order the kernels do it (`LinearEXL3.reconstruct_hgemm`, `MoeCpuHost._dq_linear`,
`testlib/moe.py:exl3_linear_ref`): scale the input row by `suh` and Hadamard-transform each
128-column input block; multiply by the rotated-basis `Ŵ` (from `reconstruct`); Hadamard each
128-column output block and scale by `svh`; add the bias. `had_r_128(input, output, pre_scale,
post_scale, scale)` is exactly "pre-scale → transform (÷√128) → post-scale" and requires the last
dimension to be a multiple of 128 (`quant/hadamard.cu:125-149`). `reconstruct_had_slice` folds both
Hadamards and the sign/scale vectors into the dequantized weights (the "folded" mode of
`EXL3_MOE_RECON_FOLDED`), which changes rounding.

The CPU kernels apply the same transform in fp32 (`transform_out`, `prepare_block`), which is why a
CPU/GPU parity test is statistical, not bit-exact.

## 6. Consumers to reimplement, and what each needs

| consumer | layout read | note |
|---|---|---|
| `exl3_gemv` / `exl3_gemm` / `exl3_mgemv` (dense Linear) | native | codebook templated `cb ∈ {3inst, mcg, mul1}`; int8-GEMV mode is mul1-only |
| `reconstruct` / `reconstruct_had*` | native | emits fp16 `Ŵ` (or original-basis W), used by all reconstruct tiers |
| `exl3_moe`, `exl3_moe_coop` (GPU fused MoE) | native | mul1 specialization is what enables the wide `N=128` tile instances and `EXL3_MOE_MTILE` |
| `moe_unswizzle_trellis` | packed → native | one read + one write per staged batch |
| `cpu/moe_mul1.cpp` (CPU MoE) | **packed** (per tier) | the only reader of packed bytes; dequant fused into int8 dot products |
| `ngram.cu`, `exl3_lib/ngram_codec.py` | native, different container | same codebook; per-row ring with a leading fp16 **scale word**, `1 + dim·K/16` words, 160-wide tail-biting rings and per-head bias |

Invariants a port must keep: tile is 16×16 weights; ring is `256·K` bits in `16·K` `uint16` words;
`uint16` pairs form big-endian-bit-order `uint32` words stored little-endian; window = 16 bits
ending at `S(i)`; element order = `tile_perm`; dimensions are multiples of 128 after padding;
`bytesum`-based decode is exact only for mul1. `tests/testlib/trellis.py` is a self-contained
NumPy/torch reference (pack, unpack, decode, dequant, dense linear) that the kernel tests treat as
ground truth — port the tests along with the format.