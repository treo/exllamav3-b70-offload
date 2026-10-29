# B70 offload: expert kernels

What has to be written for the arithmetic itself. Two references carry the requirements:
[`doc/prep/mul1-trellis.md`](../prep/mul1-trellis.md) (the format, its invariants and the integer
fusion identity) and [`doc/b70/EXL3 mul1 Trellis Unpacking on Arc Pro B70 — Cheat Sheet.md`](../b70/)
(the Xe2 recipes, which were re-derived from `cpu/moe_mul1.cpp` and checked exhaustively). Facts
about the card are from `notes/b70/` **[M]** or from `b70-bench`'s measured peaks; anything marked
**[P]** is a budget, not a measurement.

## 0. Contract

One job = one layer's routed-expert contribution for `rows` tokens, exactly the CPU worker's
contract (`exl3_moe_cpu_forward_raw`, `cpu/moe_mul1.cpp:3801`):

```
in   x8[rows(or 2·rows wide), hi] int8   q[], sum_x8[], wide[]        (produced by the 3090, §5)
     sel[rows·topk] i32 (-1 = handled by the parent GPU)   w[rows·topk] fp16
     per expert, per projection: trellis tiles in B70 VRAM (§2.2 layout rule), suh/svh/bias
out  out[rows, ho] fp32  (accumulated, weighted, in place — the slot is not read by anyone else)
```

Invariants carried over verbatim, asserted at load rather than assumed (`doc/prep/mul1-trellis.md`
§1, §6, A7): tile = 16×16 weights; ring = `256·K` bits in `16·K` `uint16`, `uint32` words little-
endian with bit 0 at word 0's MSB; window = 16 bits ending at `S(i)`, tail-biting; element order =
`tile_perm`; `k`/`n` multiples of 128 after padding; every expert inside a layer shares one rate
(assert it — the prep README notes nothing currently enforces it); `k ≤ 8192` for the int32
accumulator bound (Xe2 is actually safe to 16 825, keep the stricter cap so both backends see the
same inputs).

## 1. Budget that decides every design choice here

| resource | figure | consequence |
|---|---|---|
| VRAM read, measured on this exact access pattern | **132–292 GB/s scattered, 216–558 GB/s clustered** (608 GB/s spec; `probe_rates`, **[M]**; the range is working-set size, 64 MiB–2 GiB — `out_rates_footprint.txt`) | 351–919 G-weights/s scattered at K = 2.5–3.0; the spread is *ordering* and *footprint*, not layout — §3a |
| lanes × clock | 4096 × 2.8 GHz = 1.15·10¹³ lane-ops/s | the real unpack density (+47 lane-inst per 32-lane word) costs 0.1–4.4 % of bandwidth at decode-like footprints, 14 % at a 64 MiB one — decode sits on the bandwidth side of that line, with less margin than the first measurement suggested |
| XMX | 183 TFLOP/s fp16, 367 TOPS int8 **[M]** (`b70-bench`) | prefill is XMX-bound only above ~64 rows/expert |
| SLM / L1 | 128 KiB per Xe core (driver-reported **[M]**), 18 MiB L2 | a Qwen3.8 decode job reads ~12 MiB, comparable to L2 — see §3a item 4 |
| subgroup | 16 and 32; DPAS wants 16 | lane = output column = exactly the trellis permutation (§2.3) |

The earlier draft of this table said the decode kernel "lives or dies on ops per weight" and made
verifying the int8 dot's instruction count a phase-1 gate. Measurement overturned that: at realistic
density (extract + multiply + accumulate, ~10 weights per u32, **+47 lane-instructions per 32-lane
word = per 128 B of stream**) the loop loses **4.4 %** of bandwidth on Qwen3.8's geometry and **0.1 %**
on GLM's versus the same reads with no arithmetic, and `dot_acc` versus a manual 3-mask/3-shift/3-add
byte sum differ by **0.2–0.4 % — not measurably** (**[M]**, `probe_rates` R6/R7, reproduced across
three independent runs in `out_rates_repeat.txt`). Breaking the accumulator into 8 independent chains
makes it 1.2–1.4 % *worse*, so the residual is instruction count and register pressure, not dependency
latency. Decode on this card is bandwidth-bound, so
the dot earns its place on instruction count and energy, not on throughput, and it is no longer a
design risk. Op count still matters where arithmetic is heavy against bytes: the XMX routes (§4), and
Recipe A (~6 ops/weight) versus Recipe B (~4) on the half-rate layers, where 3.2 weights per byte
leave less headroom — re-measure at real density in phase 2 rather than assuming either.

Three rules from the probes, because all three fail silently: index with `i[0]` and cast
explicitly (`p[i] = seed + i` on a `sycl::id<1>` compiles, runs, reports success and stores nothing —
`notes/b70/LESSONS.md` 4a), and no `sycl::atomic_ref` on the shared region at any scope (it loses the
device, `LESSONS` 4). Publish results as: stores → `sycl::atomic_fence(acq_rel, system)` → flag store.

## 2. Trellis decode

### 2.1 Recipe A — universal, all rates
The `funnel_r` form from the cheat sheet: end bit `e = ((t+1)·(2K+hb))>>1`, first bit wraps via
`e + L − 16` when `e < 16`, and the two-word funnel never shifts by 32. Use it for
`K ∈ {1.5, 2.5, 3.5}` (half rates break the word alignment Recipe B needs) and as the *reference
implementation* every other path is diffed against. Qwen3.8's 2.5 bpw layers — the majority of that
model — are in this class, so Recipe A is not a fallback corner: it needs its own throughput number.

### 2.2 The three traps, each as a test
1. **shift by 32**: OpenCL masks the count, C++ is UB; the naive `(lo>>s)|(hi<<(32−s))` corrupts
   8/256 states at odd K, 32/256 at K=4, 64/256 at K=8. Test: every state of every K, against
   `tests/testlib/trellis.py`.
2. **tail-biting wrap**: state 0 borrows the tile's last bits; index `mod 8·K`, never clamp. Test:
   `is_tail_biting` on real expert tensors (Level A1).
3. **byte/half order** inside DPAS operands and inside the `uint16` pairs. Test: the K=4 vector
   table in the cheat sheet (six `(r,c)` triples with their state, product, byte-sum and weight),
   as a device unit test, plus `(0,0)` being the wrap case.

### 2.3 Recipe B — integer K, SG16, lane = column
`trellis_column()` loads `K+2` words per lane, realigns once by `4K·h` bits, then extracts 16 states
with compile-time indices/shifts (~4 ops/state). Two things make it worth more than the ops saved:
the produced column-per-lane layout **is** the DPAS B-operand layout, so the prefill path consumes
it without a shuffle or an SLM round trip, and `raw[]`/`a[]` stay in registers — which is only true
if `zeKernelGetProperties.spillMemSize == 0`, checked by the harness at build time for every shipped
kernel and every K (the cheat sheet warns K=8 is where it breaks).

### 2.4 Weight value
Never materialise a float weight. `bytesum(state · 0x83DCD12D)` is accumulated as an integer; the
affine epilogue `k_inv·q·(acc − 510·Σx8)` is applied once per output. Two consequences: the −510
correction needs the per-row `Σx8` (§5), and the fp16 form `(half)(bytesum − 510)` is *exact*
(|v| ≤ 510 < 2048 with 11 mantissa bits), which is what licenses the XMX routes in §4.

## 3. Decode kernel (`rows ≤ 8`, i.e. the whole of token generation)

Unit of work: `(expert, projection, 128-output-column band, k-slice, chunk of ≤4 tokens)`. At decode
shapes the parallel axis has to come from somewhere, and unlike the CPU (split-K only on VBMI,
`P ≤ 4`) the GPU wants *many* slices: Qwen3.8 gate/up is `tiles_n = 5 × tiles_k = 20 = 100` units
per projection, down another 100, so 400 units per expert and ~3200 per decode layer — comfortable
for 256 vector engines even at 4 slots.

* Partial sums from k-slices go to a scratch tile, reduced by a fixed, work-item-indexed second
  kernel. **No atomics**: Gate B3 (bit-identical repeated calls) is a real invariant here, not a
  nicety — the CPU path earns it by having no work stealing across reductions, and the GPU path can
  easily lose it. Where a slice count varies with load, it must vary with *shape* only.
* The GEMV body: per k-tile, `trellis_column()` (Recipe B) or Recipe A, then
  `acc += dot_4x8packed_us_int(state·MUL1, x8splat)` for each of the 16 rows, accumulating one
  int32 per (output column, token row). Activations are pre-splatted (`(uint)(uchar)x8 · 0x01010101`,
  the cheat sheet's warning: a signed `(uint)x8` splat is wrong for negatives).
* Wide rows: the 15-bit split row pair is just two GEMV rows whose results add, exactly as on the
  CPU; scratch is sized `2 × MAX_M = 8` rows.
* Weight reads: evict-first cache control via `annotated_ptr` (`sycl_ext_intel_cache_controls`) —
  a decode job reads 12 MB of weights that no one else will reuse, and polluting an
  18 MiB L2 with it measurably hurts the next layer. Compare with the default policy in the
  harness; this is the B70 analogue of the CPU's banding question and should be answered by
  measurement, not by analogy.
* Traffic model to check against: `experts × expert_bytes / 250 GB/s` (mid-band scattered) + `~10 µs`
  handshake, i.e. ~58 µs for 8 experts at 1.465 MiB; at the clustered end the same job is ~33 µs.
  Gate E4 replaces the rate with the real kernel's own measurement at a matched footprint.

## 3a. Locality: the one lever the measurements actually found

`probe_rates` compared, on identical bytes and identical tile geometry, a work-item→tile mapping that
spreads consecutive items across the tier against one that keeps them adjacent: **1.08–1.99×, measured
across two geometries and six working-set sizes, never negative** (Qwen3.8 at 1 GiB: 274→546 GB/s;
GLM at 1 GiB: 255→321; the weakest case is GLM at 128 MiB, 208→225). By contrast the tile *permutation*
(`b70-architecture.md` §2.2) measures 0.96–1.05× with no consistent sign. Nothing about the trellis
layout changed here. So the kernel and the allocator, not a swizzle, carry this:

1. **Grid order = memory order.** Schedule so that concurrently running work-items are consecutive
   fragments of the *same* expert (item id innermost in `kt`, then band, then expert). The reverse —
   expert innermost, the natural shape for a work-stealing queue — is precisely the scattered case the
   probe measured.
2. **A layer's experts are one contiguous block in B70 VRAM**, laid out in expert order at upload, not
   allocated per expert (which scatters a job's 8 experts across a 32 GiB heap and forfeits the win
   even when the kernel orders itself perfectly). A loader constraint, and a free one.
3. **One work-group per (expert, band range)** so its items walk a contiguous k-major run: groups,
   not lanes, are the locality unit.
4. **Hot-set reuse is plausible and unmeasured.** A Qwen3.8 decode job reads ~12 MiB against an 18 MiB
   L2, so a token reusing much of the previous token's expert set could be served partly from cache,
   putting the achieved rate *above* the clustered figure. E4 therefore reports the real GEMV under
   both first-touch and repeated-expert conditions.
5. Cache-control hints (`annotated_ptr`, evict-first weight reads, `sycl::prefetch`) are
   **second-order** to 1–3 and are measured as an increment on top of them, never instead of them.

The failure mode this section exists to prevent: writing the GEMV first, measuring ~200 GB/s in phase
2, and finding the cause was one line of grid ordering. E4 is judged against the footprint-matched
bracket in `notes/b70/out_rates_footprint.txt` rather than a single number: for Qwen3.8-class geometry
that is 200–292 GB/s scattered and 278–558 clustered, so landing near the bottom of the scattered band
means the ordering rules above are not implemented, and exceeding the clustered band is evidence that
locality *and* something unmodelled (L2 reuse across a repeated-expert stream, which decode actually
presents) are working.

## 4. Prefill kernels (`rows ≥ 32`): feeding XMX

Weights must reach DPAS. `mul1` values are not storable int8 (range −510…495 needs 11 bits), so both
routes carry the value in a wider or split form, and `k_inv·q` stays in the epilogue:

| route | A | B | per-weight ALU | XMX cost | notes |
|---|---|---|---|---|---|
| R1 `fp16` | fp16 activations (int8 dequantised, or keep fp16 activations and skip int8 entirely) | `(half)(bytesum − 510)`, one column per lane from Recipe B | mul, dot, cvt | 1× fp16 GEMM, K=16/32 | simplest numerics; the value is exact, the scale is folded out |
| R2 `u8·s8` | int8 activations, `i8_u8_matrix_mad_k32` | the four bytes of `state·MUL1` **are** four u8 B elements | mul only | 4× the K of an int8 GEMM = ½ the fp16 GEMM time | no conversion, no per-weight cvt; the −510·Σx8 correction rides along in the epilogue |
| R3 dequantise to fp16 scratch, then a plain GEMM | fp16 | fp16 scratch (`k·n` per expert) | mul, dot, cvt, store | 1× + scratch traffic | the "make it look like the existing GPU tiers" option: it is what `reconstruct` does on the 3090; costs `2·k·n` bytes of scratch traffic per expert per use |

R2 is the interesting one (it removes the per-weight conversion, which is what the ALU budget is
tight for) and it is also the one with the unverified detail: the DPAS spec's byte order inside a
`uint32` B component and the fp16 half order are **not** stated, so the cheat sheet's own advice
applies — confirm both against the vectors before trusting a number. R1 and R2 should both exist
behind `EXL3_MOE_B70_PREFILL_ROUTE`, chosen per rate by measurement at 32/128/512 rows, because the
crossover is model-dependent.

Shape constraints on `intel_gpu_bmg_g31`: int8 is M ≤ 8, N = 16, K = 32; fp16/bf16 reach M = 16/32
or N = 64 (multi-DPAS tiles); `joint_matrix` load/store needs `stride·sizeof(T)` a multiple of 8 B,
4-byte-aligned base, and (offset form) a row index that is a multiple of `4/sizeof(T)` — so the
activation and weight scratch pitches are chosen to satisfy these, not to be "nice round numbers".
If the Intel-only coordinate-aware `joint_matrix_apply` is unavailable in the installed runtime
(`LESSONS` 10 — the aspect is missing in 2026.2), the epilogue becomes store-then-fixup, or ESIMD
`xmx::dpas` with an explicit accumulator, which the manual documents for `bmg_g31`.

Row grouping: as on the CPU, tokens are bucketed per expert and chunks of ≤4 (≤8 with wide rows)
share a GEMV; above ~16 rows per expert switch to the DPAS path with M = 16/32 tiles; between the
two, the decode kernel with several token rows is usually better than XMX at N=16, so the tier
boundary is a measured constant (`EXL3_MOE_B70_DPAS_T`, tentatively 16) rather than an inherited one.

## 5. Transforms, activation, quantisation

Pipeline per job, matching the CPU phase order (`doc/prep/moe-cpu-offload-data-paths.md` §5) because
the order is fixed by data flow, not by performance: `gate/up` GEMV → inverse Hadamard-128 per
128-output block + `svh` (+bias) → activation → *forward* Hadamard-128 + `suh` on the intermediate +
int8 quantisation (per whole row: the down projection's scale needs the complete activated row) →
`down` GEMV → inverse Hadamard + `svh` → `out[token] += w·value`.

* The **input** transform for `x` (`suh` + Hadamard + `1/√128` + int8) runs on the 3090 in the issue
  kernel by default (`EXL3_MOE_B70_QUANT_INPUT=1`), because it halves the payload and the 3090
  already has `had_r_128`. The B70 needs its own Hadamard anyway for the *intermediate*, so both
  implementations exist; `QUANT_INPUT=2` moves `x`'s transform to the B70 and the harness then
  compares the two **quantised tensors bit-for-bit** — a strong, cheap cross-check that catches
  Hadamard normalisation, `suh` indexing and rounding-mode drift, which are otherwise invisible
  inside a 2e-2 output RMS budget.
* Scale/rounding must match the CPU rule, including the tie-breaking of `round-to-nearest` in the
  int8 cast and the `WIDE_ZERO_DIV = 16` test, or Gate B′ (agreement with the CPU tier at fixed
  inputs) becomes unachievable and every later diff is ambiguous.
* Intermediate dtype: fp32 internally, quantised on write like the CPU path; `interm_fp32` handling
  in the layer spec carries over.

## 6. VRAM budget

```
weights   = bytes(S_b)                                   up to ~28 GiB usable of 31.9
staging   = slots × slot_rows × (hi + 2·ho)              4 × 256 × 7.7 KiB  ≈ 8 MiB
gemv in   = slots × 8 × k                                int8,  ≈ 0.2 MiB
gemv out  = slots × 8 × (2I + ho) fp32                   Qwen3.8: ≈ 0.2 MiB
partials  = bands × k-slices × rows × 4 B                the only term that grows with parallelism
scratch   = XMX A/B tiles + fp16 weight scratch (R3 only: k·n per projection)
```
Well under 1 % of the card — worth stating because the CPU path's VRAM-pressure reasoning (fused
temp buffers ∝ `STREAM_FUSED_T`) simply does not transfer.

## 7. Kernel inventory (names, not signatures)

| kernel | replaces | tested by |
|---|---|---|
| `b70_trellis_state_ref` (Recipe A, scalar) | — | Level A vectors; the oracle inside the B-level harness |
| `b70_bucket_sel` | the CPU job's token/expert bucketing + `MAX_M` chunking | unit: permutation is stable and `Σcounts = picks ≥ 0` |
| `b70_quant_rows` | `prepare_rows` / `quantize_row_wide_avx2` | bit-diff against the CUDA issue-kernel quantiser (§5) |
| `b70_gemv_gu[_recipeA/_B]` | the `avx2_swz2_pair` GEMVs | B′ vs fp64 oracle + vs CPU tier at fixed inputs |
| `b70_transform_act` | `transform_out` + `_act` | unit vs `ext.activation` and `had_r_128` |
| `b70_gemv_d` | same, down projection | as `b70_gemv_gu` |
| `b70_accum_out` | `fold_rows` + weighted accumulate | Gate B3 determinism |
| `b70_dpas_{r1,r2}` | `exl3_moe` fused tier, prefill | B′ + E5/E7′ throughput |
| `b70_upload_experts` | the arena's role for `S_b` | `memcmp` against source bytes after upload (Level A) |
