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
| XMX | 183 TFLOP/s fp16, 367 TOPS int8 **[M]** (`b70-bench`; integer DPAS measured at 366.92 TOPS = 100 % of spec, and `dpas.hpp` allows u8×s8→int32) | against the measured 674 GB/s copy peak that is **272 MAC per byte** *for a 1-byte-per-weight format* — at our 0.375 B/weight with 4 byte-MACs per weight-token (b70-kernels.md §2c item 13b) the same arithmetic gives **~26 rows per expert**, or ~59 against the 292 GB/s the GEMV really gets; §4a carried the 272 number into a prefill eligibility claim and needs re-running, while decode is unaffected because at 5–6 rows/expert the limiter is instructions per row, not the matrix unit (§3b) |
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

## 2a. What the shipped kernels spend per weight — read this before writing another GEMV

`probe_gemv.cpp` runs the real operation (checkpoint trellis bytes, the `moe_mul1.h` identity, output
bit-exact against `tests/testlib/trellis.py`) and it says the model in §1 was wrong about which resource
binds. Two revisions, both measured at 512 experts / 300 MiB / R = 1 (**[M]**, `out_gemv.txt`):

| inner loop | lane-ops per weight | GB/s | instruction model (1.43·10¹² SIMD inst/s ÷ ops per byte) |
|---|---|---|---|
| rev A: per-window address math, 64-bit shift, manual 3-shift/3-add byte sum | ~17 | **27.9** | 31.6 |
| rev B: grouped dword-pair extraction + `dot_acc` byte sum | ~8 | **61.4** | 67.2 |
| the byte stream itself (`probe_rates`, same tiles, no arithmetic) | ~0 | **287–292** | — |

The model tracks the measurement to within 10 % at both points, and the 250–292 GB/s figure the whole
decode budget rests on is the *third* row — reachable only by a kernel that spends almost nothing per
weight. That is exactly what the CUDA and CPU paths do:

* **CUDA** (`quant/exl3_gemv_int8_kernel.cuh`, `ext4w`/`ext8w` + the accumulator loop): two dword loads
  serve 4–8 consecutive ring windows, each generated by one `fshift(b, a, s + k·bits)` with the address
  math hoisted and the bit offsets compile-time constants; the window becomes
  `prod = window * 0x83DCD12D`, and **each token row costs exactly one
  `dp4a_us(prod, splat(a_int8), acc)`** where `splat` is `0x01010101 * x8` precomputed in shared memory
  (line 274). Byte-sum, multiply and accumulate are one instruction; nothing is ever materialised.
* **CPU** (`cpu/moe_mul1.cpp`): same identity, `vpdpbusd` per 16 weights; for multi-row it first folds
  byte-sums into i16 lanes so one `vpmaddwd` returns `bytesum × x` for **two rows** (lines 322, 1038,
  1146) — a cheaper per-row marginal cost than one dot per row, and the model for what to do at b ≥ 2.
* **ROCm** keeps a third variant worth reading before committing (`rocm/quant/exl3_gemv_tiles_rdna.cuh`),
  since RDNA's dot-product support differs from both.

Transplant to Xe2, in order of value:

1. **Stop materialising byte-sums.** rev B stages `bs[]` into SLM and then does load+load+mul+add per
   (weight, row) — which is why its rate falls 61 → 13.8 → 4.6 GB/s at R = 1 → 8 → 32 and collapses to
   0.2 at R = 128 (register spill from the accumulator array). Hold `prod` in a register and do one
   `sycl::ext::oneapi::dot_acc(prod, splat_row, acc)` per (weight, row): that is ~2 + R instructions
   per weight instead of ~8 + 4R. This toolchain *does* have the primitive —
   `sycl/ext/oneapi/dot_product.hpp` provides `dot_acc(uint32_t, uint32_t, int32_t)` plus the mixed-sign
   `vec<uint8_t,4>`/`vec<int8_t,4>` overloads, which is what `dot_4x8packed_us_int` is sugar for on
   newer drivers.
2. **Pre-splat activations** into `0x01010101 * x8` (uint32) in SLM, exactly as CUDA does, so the dot
   needs no separate scale step. Cost is 4× the SLM bytes for `x`, which §1 says is free.
3. **Grouped extraction with constant shifts**, as rev B now does: ~10 ring positions share one dword
   pair at K = 3 (`while off + 16 + 3t <= 64`), one address computation per group. SYCL has no funnel
   shift (`grep -l funnel $SYCL_INC` → nothing), so write the idiom `(hi << s) | (lo >> (32 - s))` and
   let LLVM form `fshr`, or copy CUDA's chain (`w6 = w7 >> (KA+1); w5 = w6 >> KA; …`) which needs no
   funnel at all.
4. **Then, and only then, does ordering matter.** At rev A/rev B instruction counts the clustered and
   scattered grids measure the same within 1.5 %; §3a's locality rules are still right, but they are the
   *second* problem. E4b must be judged after E4's instruction budget is met.

This also retracts two claims that §1 and `b70-architecture.md` §12 previously carried as settled: the
dot-instruction question was **not** answered behaviourally by `probe_rates` (a proxy that computes no
weights cannot bound the cost of the arithmetic it omits — it walked the same bytes at ~1 op per weight
and reported 292 GB/s), and "decode is bandwidth-bound" is a property of the *byte stream*, not of the
kernel. Both are open again, behind E4.

## 2b. Rules lifted from `doc/b70/llm-scaler` — Intel's own XPU MoE kernels, with their perf post-mortems

`doc/b70/llm-scaler/sglang/custom-esimd-kernels/csrc/` contains production ESIMD MoE kernels for the
same hardware generation (Q4_K/Q5_K/Q6_K grouped GEMV, batched decode GEMV, DPAS prefill, fused
bucket/topk), and several files carry annotated *why the first version was slow* notes with numbers.
What they say that changes our design:

1. **Wide, LSC-granular loads; one flat accumulator; fold once.** `moe_kquant_GEMV.h`: the original
   "stepped 32 at a time, issuing 16-byte nibble loads (below LSC granularity) and re-reading a scalar
   scale/min per block", and folding "a full horizontal sum … into a serial `dot` chain every block" —
   it "only reached ~180 GB/s"; widening the tile and removing the per-block reduction is what fixed it.
   `q8_0_GEMV.h` states the reason outright: a per-iteration `reduce<>()` would cost
   "M × K_ITERS cross-lane reductions (128 per work-item at M=4, K=2048) whose shuffles do not produce
   useful FLOPs, and **this kernel is ALU bound, not bandwidth bound**" — an independent confirmation of
   what `probe_gemv` measured on our trellis.
   → Rev C: `simd`-width tiles (≥32 B per load), accumulate lane-parallel into `simd<int32_t, VL>`,
     one `reduce` per output at the very end. Never reduce inside the k loop.
2. **~180 GB/s is the realistic ceiling for a mature MoE GEMV on this class of card**, not the
   292 GB/s bare-stream rate. → **Superseded by measurement, and the units were wrong.** Rev C reaches
   116.4 GB/s at E=512/R=1 and 76.6 GB/s at the b=1 shape (§2b item 9). At 3.0 bpw those are **309.5 and
   204 G-weights/s**, against Intel's q8_0 GEMV at ~470 G-w/s (1 B/weight) and their narrow K-quant
   shapes at 120–180 G-w/s — so the trellis kernel already sits above their narrow-shape rates, and
   GB/s was never comparable across formats with different bytes-per-weight. At 165 GB/s the planning
   figure had been 91 µs/layer for Qwen3.8 b=1; at the measured 76.6 it is ~195 µs.
3. **Amortise the activation load across output columns.** `moe_kquant_GEMV.h`: with one column per
   work-item, "every work-item re-reads `inter` in full (N=2048 work-items × 512 B = 1 MB of cache
   traffic per route for a 4 KB tensor)"; handling `ROWS>1` columns per work-item removed it. My rev B
   has the same defect in SLM form (each item reloads `xs[]` per weight).
4. **Grid order for L2 reuse across row-tiles**: `q8_0_GEMV.h` lays groups out **M-tile-fastest** "so the
   MT groups that share a weight row block are adjacent: tile mt+1 then finds that block still in L2
   instead of re-pulling it from memory." Same family of rule as §3a, and it applies to our
   multi-row/multi-chunk decomposition too.
5. **Row tiling is bounded by GRF, and by the compiler, not by taste**: "M=4/VL=256 fits;
   M=8/VL=256 is what the AOT gen compiler refuses to lower", and the m-loop "must stay fully unrolled
   (`vacc[m]` needs a compile-time index)". This matches `probe_gemv`'s collapse at R = 128 — the answer
   is to tile rows **in the grid** (their `MT`) with M ≤ 4 in-kernel, not to widen the accumulator array.
6. **They bucket by expert and fold the gather into the load.** `moe_q4k_ggemv.h` takes
   `chunks = {eid, t0, nt}` (route-sorted ranges) and an optional `tok_ids` permutation so the kernel
   "reads the activation directly from `expert_states` at row `tok_ids[t0+m]` — folding the per-expert
   input gather INTO the load (no `index_select` round-trip)". Two consequences for us: the §3b schedule
   should look like this, and — important — their *decode* GEMVs are **per-route**
   (`grid = (n_routed, n_col)`), i.e. they do **not** dedup an expert across routes and rely on L2.
   Our entire concurrency model assumes the union (`bytes = union(rows) · expert_bytes`); that is only
   true if we bucket, so bucketing is a *correctness precondition* of the byte model, not an optimisation
   — without it the b=8 footprint is 8× worse than modelled.
7. **Repack for dequant ergonomics is a different question from repacking for locality.** Their formats
   are stored as an interleaved nibble plane plus a *plain* high-bit plane (`qh`, "byte j bit b = elem
   8j+b") plus fp16 scale/min per 32, specifically so the inner loop is wide and mask-free
   (`v5 = nibble | (qh << 4)`). `b70-architecture.md` §2.2's null result (banded/native 0.96–1.05×)
   tested locality-driven repacking only; a dequant-driven repack is untested and is the kind Intel chose.
8. **DPAS tiles are chosen by wasted lanes, not by arithmetic intensity.** `moe_q4k_ggemv.h` is
   instantiated at `MS_=4` (64-token tiles) for prefill and `MS_=1` (16-token) precisely because "for
   SMALL M (e.g. MTP verify M=4) the 64-row DPAS wastes ~60/64 rows". So the real rule for our §4 is
   *tile height ≤ rows per expert*, with the GEMV preferred below ~16 — which is much more aggressive than
   the 272-row arithmetic-intensity crossover, and consistent with the `…CACHE-MISS / JIT-recompile`
   warning in `q8_0_GEMV.h` about falling back to oneDNN `jit:gemm:any` per new `(M,K,N)` shape. Our
   engine must own every shape it uses, and the XMX/GEMV decision is a per-(M,K,N) table, not one number.
9. **Two driver-level hazards, both already biting us.** Cross-subgroup SLM exchange needs the full
   barrier: "a named barrier only orders execution, it does not make the SLM stores visible to the other
   subgroups, so the split arrive/wait form leaves the exchange racy; `barrier()` carries the required
   memory fence" — our groups are 64 items = 2 subgroups sharing `bs[]`, so this is live, not theoretical.
   And unclamped tail addressing "is an out-of-bounds device read (observed as
   `UR_RESULT_ERROR_DEVICE_LOST`)" — same failure signature as `LESSONS` 4, reached from a different
   direction: on this driver an OOB *read* does not fault verbosely, it kills the device.

9. **Decode rate is now measured on the real kernel, and the grid-size story was wrong.** Rev C passes
   the gate (bit-exact vs rev B in 88/88 configs: E ∈ {2,10,96,512} × rows {1,4,8} × k-split {1,4,8,16}
   × both orders) and supersedes the inherited 150–180 GB/s assumption. Min of 7 interleaved repeats:

   | shape (per layer) | rev B | rev C best | rate |
   |---|---|---|---|
   | E=10, R=1 — the b=1 decode shape | 261.2 µs | 80.2 µs at ks=1, **×3.26** | **76.6 GB/s** |
   | E=96, R=1 | 990.3 µs | 550.0 µs at ks=1, ×1.80 | 107 GB/s |
   | E=512, R=1 | 5131 µs | 2702 µs at ks=1, ×1.90 | 116.4 GB/s |
   | E=512, R=4 and R=8 | — | 60.5 and 31.1 GB/s at ks=4 | rows cost ~linearly |

   * The gain came from the *structure* — prod in registers, one dot per (weight, row), no materialised
     byte-sums — **not** from split-K. At E=10/R=1, 400 work-groups and the sparsest realistic decode,
     ks=1 was the best configuration measured; every increase in ks lost throughput. The claim this
     entry used to make ("decode MUST split K, which recovers ~5×") was read off noise: identical
     configs measured 38.7, 45.7 and 52.5 GB/s back-to-back. `out_gemv.txt` carries the methodology note.
   * Split-K pays only once row-tiling has consumed the grid dimension: at E=10/R=4, ks=4 gives ×1.72
     while ks=1 is *slower than rev B* (×0.76). At E ≥ 96 it never pays. So `ks` is a joint function of
     (E, tn, rows, M) chosen at launch time, defaulting to 1; it costs ~10–25 % when unneeded.
   * Rows cost throughput roughly linearly in accumulator count (116 → 60 → 31 GB/s for R = 1/4/8),
     consistent with the ~2+M-instructions-per-weight model and not with a bandwidth bound.
   * **Planning consequence:** the b=1 rate is **~77 GB/s**, about half the 150–180 assumed and a quarter
     of what the byte-stream proxy gave at the same footprint (132–292). Qwen3.8 b=1 expert work per
     layer moves from ~91 µs to ~195 µs, and `plan_operating_point.py` plus everything downstream of it
     must be re-run against the measured curve before any token/s figure is quoted again.
10. **`dot_acc` overload signedness is silent.** `dot_acc(uint32_t, uint32_t, int32_t)` is
    unsigned×unsigned; the CUDA `dp4a_us` equivalent is `dot_acc(uint32_t, int32_t, int32_t)`
    (unsigned prod × signed activation splat). Casting the splat to `uint32_t` reads negative
    activations as 128…255 and produces plausible-looking garbage — caught only by the bit-exactness
    gate, which is exactly why Gate A is bit-exact rather than tolerance-based.
11. **Pre-splat activations: mask the byte, never multiply a signed value.** `(int8_t)x * 0x01010101`
    gives bytes `(x, x−1, x−1, x−1)` for negative `x` — the borrow from the two's-complement negate — so
    every negative activation under-contributes by ~0.75·bytesum. That presents as a near-constant
    offset in the output, which is the least suspectable shape a data bug can take. Correct form:
    `(uint32_t)(uint8_t)x * 0x01010101u`. CUDA avoids the trap structurally by splatting with byte
    permutes. This one line was the entire rev C numerics bug; `out_gemv.txt` has the autopsy and the
    two synthetic-input controls (x ≡ 0, x ≡ 1, both exact) that proved it.

12. **Measured on every MoE checkpoint on disk (nine of them; two more are dense).**
    `sweep_models.py` + `out_gemv_models.txt` cover model × projection × experts × rows, with rev C
    bit-exact against a NumPy reference at **every trellis recipe K = 2, 3, 4, 5, 6** — relaxing the
    probe's `K == 3` guard was safe because `step_widths(K) == K` and `ring_ends(i) == i·K` hold for all
    integer K (checked against `tests/testlib/trellis.py`), and the mul1 magic multiplier 0x83DCD12D is
    a property of the codebook, not of K.
    * Per-layer decode time is **recipe-independent**: the six Qwen3.8 recipes span 11.72–35.16 MiB and
      measure 229.1–239.6 µs (flat within 0.5 % above K=2) at a constant **205–206 G-weights/s**.
      Weights cost, bytes don't — so GB/s is not comparable across recipes (GB/s = G-w/s × K/8) and
      `plan_quant_scaling.py`'s byte-driven time model belongs to the transfer tiers only.
    * rev C over rev B at the operating shapes: median **×1.82** (×2.18 at R=1; range ×0.97–4.22, n=36).
    * Pooled throughput tracks grid width: 76.5/109/126/135/203 G-w/s for `tn` = 32/40/128/160/256
      (directional — `tn` is confounded with per-item tile count here).
13. **Two timing modes, and they are not interchangeable.** The probe now reports burst-of-16 sustained
   throughput *and* single-launch round trip. The round trip is only ~5 µs above sustained at these
   shapes (so the ~80 µs measured at E=10 is kernel time, not launch tax — that check mattered, because
   E=10 took the same 80 µs for 3.9 MiB and 5.86 MiB and looked exactly like an overhead floor).
   Sustained mode is the *slower* one at large shapes (E=512: 2771 vs 2704 µs) because a 16-launch burst
   of 2.7 ms kernels loads the card continuously and droops clocks, while single launches ride boost
   clocks. Decode at b=1 has a few-percent duty cycle, so **plan decode on the single-launch number**
   (conservative: it also carries the completion tax) and prefill/batched on the sustained number.

## 2c. Second harvest from `doc/b70/llm-scaler` — mapped to the weaknesses we just measured

Every item below is **[source]** (their claim or their code), not measured here; the right-hand column
is the gate that would make it ours. Paths are relative to
`doc/b70/llm-scaler/sglang/custom-esimd-kernels/csrc/`. The ordering is by expected payoff against §2b
item 9's numbers (205 G-w/s at R=1 falling to ~137 at R=4; 76.5 G-w/s at `tn`=32; 239 µs/layer = parity
with the parent), not by elegance.

| # | Idea, as they implement it | Which measured weakness it attacks | Gate |
|---|---|---|---|
| 1 | **M-tiled XMX DPAS instead of one dot per (weight, row)**: `MC=8` weight rows × `NTOK=16` tokens per tile, dequant the weight block **once for all M tokens** (`q8_0_GEMV.h:231-241`, `:281`), and `NTOK=16` "covers the whole MTP verify batch (M≤16) in one tile" | the rows collapse: our cost is ~3+M instructions per weight, so R=4 already costs ~1.5× and R=8 ~3× per weight; theirs is ~unpack + M/16 of a DPAS | **E24** |
| 2 | **Templated M-tile size from one body**: `MS_=4` → 64-token tile for prefill, `MS_=1` → 16-row tile because "the 64-row DPAS wastes ~60/64 rows" at M=4 — "much less matmul + smaller acc + the same b_tile gather" (`moe_q4k_ggemv.h:38-41`) | if we add a DPAS path, one tile size will not serve R=1…64; instantiate the family, don't branch inside | folds into E24 |
| 3 | **Fuse gate+up into one launch with the tensors kept separate**: "gate/up weights passed SEPARATELY (zero extra memory — reuses the decode reps; no `[E,2*IM,…]` concat copy)", output-column range picking which (`moe_q4k_ggemv.h:24-27`) | gate and up are 80.7 µs each at Qwen3.8 b=1 and read *identical activations*; fusing removes one activation pass and one launch | **E25** |
| 4 | **Fuse routed-down + finalize**: give one work-item the whole top_k reduction so it accumulates in registers, which deletes both the extra launch *and* the `[M·top_k, hidden]` scratch round-trip (`moe_down_fin_fused.h:1-20`) | our down is 77.8 µs and is followed by a weighted sum over experts plus the shared expert | folds into E25 |
| 5 | **Fold the per-expert activation gather into the load**: pass `tok_ids` and read row `tok_ids[t0+m]` directly, "folding the per-expert input gather INTO the load (no `index_select` round-trip; saves the IndexKernel)" (`moe_q4k_ggemv.h:34`) | per-layer, per-expert-batch activation staging; also removes a kernel from the critical path | folds into E25 |
| 6 | **Host cost is first-order at decode**: they measure **~48 µs of host per enqueue against ~10–30 µs of GPU per kernel**, and conclude "trading work-item count for one fewer launch is the right side of the deal even though the grid shrinks by top_k" (`moe_down_fin_fused.h:15-17`) | validates our handoff design from the other side: our pinned-flag completion is 5–6.3 µs and the doorbell 3.2 µs, so **B70 GEMVs must never be routed through torch dispatch at decode** | harness rule, E26 |
| **7** | **Fill-the-machine as an explicit target, not folklore**: `MOE_DF_WI_TARGET = 8192` work-items, with the per-item granularity halved until the grid reaches it (`moe_down_fin_fused.h:65, 88-89`), and a shape-keyed split-K selector with a divisibility guard (`select_ks_q8_0`, `q8_0_GEMV.h:28-36`: ks=8 if N≤128 & K≥2048, 4 if N≤512, then shrink ks until `K/ks % GROUP == 0`) | our launch policy is a hand-fit rule from three data points; note their `N` counts *work-items*, which is why their thresholds look aggressive next to our "400 groups of 32 lanes needed no split-K" | **E27** |
| 8 | **Occupancy cure for narrow shapes is per-lane contiguous k-partitions + SLM reduce**: `blk0 = lid*bpart` then reduce through SLM (`q4_0_GEMV.h:101-106`), chosen *instead of* a ROWS=4 layout precisely because "grid=N gives only 32 WGs" for their N=32 tensors (`q8_0_GEMV.h:15-17`) | the worst case we measured: `tn`=32 (Qwen3.5/3.6 gate_proj) at 76.5 G-w/s vs 203 at `tn`=256 | folds into E27 |
| 9 | **Clamp, don't mask, tail token lanes**: "Token lanes past M are clamped onto the last valid row so the gather stays in bounds; their accumulator columns are simply never stored" (`q8_0_GEMV.h:271-275`) | our OOB device *read* faulted the context (`UR_RESULT_ERROR_DEVICE_LOST`); this is branch-free and fault-free | adopt now |
| 10 | **Feed DPAS with `lsc_gather`, don't reassemble in registers**: one gather yields the VNNI B operand directly because SoA ordering already matches, and "assembling it with strided register moves instead cost more than the DPAS itself saved" (`q8_0_GEMV.h:294-300`) | if E24 adopts DPAS, the operand-prep route decides whether it pays | folds into E24 |
| 11 | **On-device bucketing recipe**: counts → exclusive scan → scatter into `sorted_token_ids` grouped by expert with `expert_idx[e]` offsets, and the whole thing fused into one kernel that "replaces CPU build_sorted_token_ids + old Scatter kernel" (`moe_ops.h:235-260, 430`); chunks carry `{eid, t0, nt}` (`moe_q4k_ggemv.h:26`) | E23's precondition — the `union(rows)·expert_bytes` byte model only holds if rows are bucketed by expert — and their grouped kernels are exactly the ones that do it | strengthens E23 |
| 12 | **Envelope for fused decode paths**: `SGL_XPU_GGUF_FUSE_MAX_M` defaults to **64** (sglang/README.md:226), and "each verify step runs at `num_draft_tokens × concurrency` rows, which is the batch the M-tiled ESIMD GEMVs are tuned for — measure at the intended concurrency" (`:166-171`) | tells us where the GEMV-shaped path stops and a GEMM path must start; and that quoting a decode rate at the wrong M is a known failure mode | feeds E21 |

| 13 | **Integer DPAS exists, and this project already measured it at full rate on the B70.** My first claim — "no int8 DPAS anywhere in the tree" — was true only of llm-scaler's ESIMD kernels and is **retracted**: `doc/b70/b70-bench/bench.cpp:227` runs `run_matrix<int8_t, int32_t, 8, 16, 32>` and `bench-results.txt` records **XMX INT8 = 366.92 TOPS = 100 % of Intel's 367** (XMX FP16 178.54 / BF16 183.46 against 183.50). `sycl/ext/intel/esimd/xmx/dpas.hpp:243-256` gives the legal integer combos: `C = ud, d` (u32/s32) with `A, B ∈ ub, b, u4, s4, u2, s2` — i.e. **u8 × s8 → int32, the `dp4a_us` semantics natively in XMX**, no float and no 2^24 accumulator cliff | settles E24's exactness fork toward keeping bit-exactness, and turns the rows collapse from structural into fixable | **rewrites E24** |
| 13b | **The 10-bit byte-sum problem dissolves if the A operand is the *bytes*, not their sum.** mul1 gives `prod = window * 0x83DCD12D` whose four bytes sum to the weight; rather than summing them and multiplying by `x`, feed DPAS the four bytes as four K-steps against `x` replicated 4× along K. One integer DPAS then computes Σ_bytes p_j·x = bytesum·x exactly in int32, with `A = u8` (the bytes are unsigned already) and `B = s8` activations VNNI-packed — the header states "B must have the VNNI encoded layout", which is what item 10's `lsc_gather` yields. Headroom: 183.5 T MAC/s ÷ 4 byte-MACs per weight-token ≈ **46 T weight-tokens/s** vs rev C's measured 0.205 T at R=1, a factor of ~224, so the DPAS kernel is bound by unpack and operand assembly and never by row count. **Step 1 is measured** (`probe_dpas.cpp`, `out_dpas.txt`): bit-exact against `y_ref`, and the rows curve is **flat to within 3 %** — 18.3 → 18.8 µs over rows 4 → 16 at E=1, where A fits L2 — against rev C's 51 → 95 µs. The row term is real and the matrix path deletes it | was item 1's premise; now **[M]** | **steps 1 and 2 measured** — engine policy decision open |
| 13c | **XMX needs 16-lane sub-groups**: `bench.cpp:98` `constexpr int SG = 16; // XMX needs sub-groups of 16 work-items`, launched with `[[sycl::reqd_sub_group_size(SG)]]` | explains the silent 16-lane behaviour that cost a debug round (LESSONS 25) as a requirement, not compiler whim: a DPAS kernel must request SG=16, and any SYCL-level reduce must stay width-agnostic | adopt in E24 |
| 13d | **A reference-free self-check**: the bench fills A and B with 1 and asserts every accumulator equals `ITERS × K` | Gate A needs an equivalent cheap invariant for DPAS operand layouts, where a wrong VNNI stride otherwise shows up as a plausible number | used — but note it is blind to operand *signedness*, which is what actually bit us (LESSONS 31) |
| 13e | **Do not feed `joint_matrix_load` from SLM.** Measured on the same kernel with only the operand *source* changed: A/B both from SLM 372 µs, B from global 191 µs, both from global 109 µs at rows=4 (`out_dpas.txt`). Local-space loads cost ~20 slots/weight against ~2 from global — a 3.4× whole-kernel penalty for the "obviously right" design choice, since SLM is fast and adjacent to the math unit. A small **global** scratch (1 KB per sub-group, rewritten every tile) stays L2-resident and costs no DRAM traffic ~~(claimed to decide how any DPAS kernel here must be plumbed)~~ **Superseded by 13k**: the penalty was B's row-major layout (element-wise transform plus byte-wise staging) and work-group barriers, not the address space. SLM itself is fine | it did sink one design instinct, but for the wrong reason — I drew the general lesson from a single confounded axis, and the fix was in the operand's *layout tag*, not its memory tier | **[M]**, corrected in 13k |
| 13f | **The matrix path measured end to end, assembly included** (rev E: trellis bytes → registers → u32 store → matrix): 8.3–11.1 slots/weight, **flat across rows 1→16**, versus rev C's 7.0→31. Net vs rev C: ×0.79 rows=1, ×1.13 rows=4, ×2.31 rows=8, ×3.98 rows=16, bit-exact throughout. Assembly therefore costs ~2.7 slots/weight more than the dp4a path's fixed work — a fixed cost repaid once per weight instead of once per token | the answer to "is DPAS worth it": **yes from rows ≈ 4, no at rows 1**, so the engine needs both schedules keyed on rows | **[M]**; other 8 checkpoints unmeasured |
| 13i | **Dense stores: ×0.64, and the experiment was confounded.** Rearranging so 16 lanes write 64 contiguous bytes per instruction was bit-exact and slower at every row count — but the rewrite also moved the load-amortization boundary from 0.375 to 3.000 dword loads per window, so store density was never tested. The hypothesis stands unproven. Arithmetic then suggests it is nearly closed: packing 16 consecutive u32 into one instruction requires lanes to vary `a4`/low `j`, which is precisely what breaks V-pair sharing (0.75 loads/window), so the committed map already sits at the corner of that trade — 0.375 loads/window against 8-byte store runs | two cheap levers dead (alignment ×2.3 slower, dense stores ×1.6 slower), leaving only the ESIMD register-fragment route, which is the one thing neither test could touch | **[M]**, `out_dpas.txt` |
| 13k | **The B operand's *layout* was the cost, not its address space (`probe_dpas3.cpp`, rev F).** DPAS wants B VNNI-packed (4 K-bytes per dword); row-major int8 B forces `joint_matrix_load` to transform it, which a 2D block load can do from global but nothing can do from SLM. Since all four bytes of a weight multiply the same activation, the packed dword is just `x * 0x01010101` — same byte offsets and same tensor size as rev E's replicated B, only the layout tag and stride change. Measured, warm and interleaved, every combination bit-exact against rev E: packed B (`p`) alone ×1.06–1.19 on gate_proj and ×1.04–1.08 on down_proj — the only switch that pays on both; `p`+funnel-shift unpack (`u`) ×1.12–1.19, best combo `psu` 87.7 µs at rows=1 against rev E's 106.2; **prefetching the trellis dwords ahead (`f`) is ×0.58**, because this kernel is issue-bound rather than latency-bound and the unroll costs more than the stalls it hides. Consequence for 13e: with B packed and barriers scoped to the sub-group, SLM and L2-resident global become indistinguishable (95.6 / 95.6 / 95.8 / 97.1 µs across the four source combinations) | overturns 13e as an instruction; moves the dp4a→DPAS crossover from rows ≈ 5 to rows ≈ 3–4; refutes the prefetch idea that would have been the obvious next step; and leaves **partial-sum traffic** (128·KS/k bytes per weight — 0.5 B/w at k=2560/KS=8, 1.0 B/w on down_proj at KS=4, against 0.375 B/w of weights) as the largest unpriced lever. Note `u` requires K ≤ 4, so the K=5/K=6 shipped recipes get `p`(+`s`) only | **[M]**, `out_dpas.txt` |
| 13l | **Partial-sum traffic priced with a duplicate-store ablation (`DPAS_F=d`: write PART twice, read once, numerics untouched).** Marginal cost is bimodal, and the break is L2 capacity, not bandwidth theory: **0.2–0.8 µs/MiB while weights+partials fit in 24 MiB** (L2 absorbs it) versus **1.3–2.2 µs/MiB ≈ 450–770 GB/s once they don't**. Consequences: (i) removing PART + combine entirely is worth ~5–11 % on gate_proj at KS=8 and ~15–25 % on down_proj at KS=4 — real, not transformative; (ii) **PART is what caps useful split-K**, and it caps it at exactly the measured optima (gate KS=8: duplicated delta +4.8 µs vs +27.7 µs at KS=16; down_proj KS=4: +16.7 µs, KS=10: +22–49 µs) | turns item 5 from "largest unpriced lever" into a bounded one, and gives E27's policy table a bytes-per-weight constraint (`128·KS/k ≲ 0.4 B/w`) instead of pure grid-fill. The same measurement exposed a bigger fish: **the DPAS path always computes 16 token columns, so at b=1 fifteen sixteenths of the matrix work is discarded** — that, not partials, is why it loses ×2.5 to rev C at rows=1. Specializing N to the row count halves mad work and PART together; not yet implemented because N is entangled with B's tensor pitch across ~8 sites where an off-by-4 would run fast and be wrong | **[M]**, `out_dpas.txt` |
| 13h | **Optimization gains do not transfer between kernels; only bottlenecks do.** Making K compile-time gave rev C ×1.90, so the same change was built for rev E — and measured **×0.99–1.01 (nothing)**, while the lane remap that enables it made rev E **2.3× slower** (rev E is store-bound on the operand scratch: its current map has 4 lanes writing a contiguous 16-byte run, rev C's gives 8 lanes 8 different columns 64 B apart, two store transactions becoming eight). Unroll pragmas were a non-factor — none / a4 / j / both all within 0.5%, since fixed trip counts are already unrolled. Reverted; every variant was bit-exact, so the refutation is purely about performance | kills "template K for rev E too", and identifies the real lever (contiguous stores) by elimination rather than guesswork | **[M]**, `out_dpas.txt` |
| 13g | **"Prepare the operands once at load time" is measured, and it loses.** rev D *is* that design — A pre-expanded so assembly costs zero — swept to its best split-K: 135.8 / 137.2 / 138.5 / 141.8 µs at rows 1/4/8/16, against rev E's 95.5 / 99.8 / 108.8 / 122.2 µs. Its floor is pure byte movement: 62.5 MiB at its own 484 GB/s marginal is 135.4 µs, matching the 135.8 µs it registers, so the math hides entirely under streaming; even at the 674 GB/s copy peak the floor (97.2 µs) loses to rev E at every row count. Capacity forbids it independently: 4 B/weight makes Qwen3.8@2.68 ~388 GiB against 32,656 MiB of VRAM (h 0.98 → ~0.08), and L2 is 24.0 MiB, enough for ~3.8 expanded experts — so a decoded cache is not a rounding error away from working, it is three orders away. The conceptual trap: rev E *already* unpacks once per weight per launch (that is why its curve is flat), so preparing at load time buys no extra amortization — it only deletes the ~5.8-slot unpack and pays 10.7× bytes for it | settles the question with measurement rather than argument, and redirects it to item 16 | **[M]**, `out_dpas.txt` |
| 14 | **Per-SKU tuned policy as generated code, not literals**: `policies/kernel-policy-v1.json` + a JSON schema → `policy_codegen.py` → `bmg_kernel_policy_generated.h`, one `constexpr` struct per SKU passed as a **template parameter** to the kernel, plus `*CandidatePolicy` structs that inherit a SKU policy and override a single field so the autotuner can instantiate variants | our E27 fit needs exactly this home: tuned numbers out of kernel source, and "which card was this measured on" encoded in the artifact rather than in a comment | adopt as E27's output format |
| 15 | **…but the B70 column is unpopulated**: `B70KernelPolicy` is identical to `GenericBmgKernelPolicy` in all 25 fields, as is `B580KernelPolicy`, while `B60KernelPolicy` differs in 17 of 25 (adaln block 32→512, `int8_dequant_fp32_elements` 32→256, `int8_dequant_bf16` 32→128 / WG 64→16) | nothing in the way of tuned constants is borrowable for our card, and it is direct evidence that per-SKU columns stay generic in practice — the plan's insistence on measuring the B70 rather than inheriting numbers is the difference between a tuned kernel and a guessed one | — |
| 16 | **"Prepare once" needs no repack — the aligned groups are already in the layout.** Checking the premise instead of building it: extraction is cheap when a lane's window group begins on a dword boundary (constant shifts, no straddle select), so solve `K·i ≡ 16 (mod 32)`. Solutions exist for every trellis K we ship — K=2 period 16 (group span 46 bits = 2 dwords), K=3 period 32 (109 bits = 4 dwords), K=4 period 8 (44 bits), K=5 period 32 (171 bits = 6 dwords, so two 64-bit bases), K=6 period 16 (106 bits) — and every period divides 256, so the groups partition a tile cyclically with no gaps. **Zero extra bytes, zero extra DRAM, and byte-interchangeability with the 3090/CPU kernels is preserved**: the E4c price this idea was assumed to pay is not due. The idealization (`probe_gemv -DGEMV_CONSTSHIFT`; numerics deliberately wrong, timing only) puts the ceiling at **×1.52 and ×2.07 at rows=1**, ×1.17–1.26 at rows 4/8 — so ~1 to ~2 issue slots per weight of the fixed ~5.8 is extraction overhead that a re-indexing can reclaim. **RESOLVED, and cheaper than either plan.** No repack and no lane reassignment: rev C's lanes already own 32 *contiguous* positions (`p ∈ [32q0, 32q0+31]`), and the group's intra-dword offset is **lane-invariant** — `(K(8t+1)−16) & 31` with `t = 4q0 + a4` reduces to a function of `a4` alone, because `K·32·q0` is a multiple of 32 for every integer K (verified K=2..6). The only runtime quantity blocking constant shifts was **K itself**. With it as a template parameter (`-DGEMV_KCONST`, a 4-entry offset table for K=3): **gate ×1.90, down_proj ×1.89 at rows=1, output bit-identical to the default build, bit-exact against `y_ref`** — the whole idealized ceiling, 6.56 → 3.47 slots/weight, and per-layer b=1 expert time 226.0 → 126.1 µs. E28 closes positive for one `#ifdef` plus a per-recipe kernel instantiation; the aligned-group rewrite in `probe_unpack.cpp` (×1.30 apparent, kernel B has an unmapped-out checksum bug and is not believed) was never needed | the cost of "prepare the operands" turns out to be a compiler-visible constant, not a format decision | **DONE** |

**Considered and rejected for us.** `iq3_s_GEMV.h:1-12` decodes 3-bit weights from *three* parallel
arrays (`qs`, `qh`, `signs`) plus a 512-entry magnitude table — three streams and a table lookup per
group, against our one ring stream and an arithmetic byte-sum. Our trellis unpack is the cheaper shape;
the only thing worth stealing from that file is `merge()` for branchless sign/select in ESIMD.

**Step 1's other result is a design constraint, not a failure: materializing A is a dead end.** With A
pre-expanded in DRAM (4 B/weight = 10.7× the trellis bytes) the DPAS path's marginal cost is
**2.17 µs/MiB = 484 GB/s** measured across E = 1…10 (72 % of the copy peak), with a ~12 µs
byte-independent floor — which is why it loses to rev C below rows ≈ 6 at E=10 and wins only ×1.6 / ×3.1
at rows 8 / 16, *despite* having removed the row term entirely. Swapping 4 B/weight for the trellis's
0.375 removes ~135 of rev D's ~147 µs at E=10/rows=4, so the step-2 ceiling is tens of microseconds
against rev C's 112.5 µs. A shipping kernel must therefore assemble A
from trellis bytes in registers/SLM, and step 2's first reported number should be **assembly cost in
slots per weight**, not a rate: the prize (≈20–30 µs against rev C's 112.5 µs at E=10/rows=4) exists
only if that cost is under ~2 slots/weight — exactly the line llm-scaler wrote about strided register
moves. Watch the operand signedness too: declaring B `uint8_t` instead of `int8_t` compiles, runs fast,
and inflates the accumulator to the all-same-sign bound (~1.6e8 instead of ~5e5), and b70-bench's
all-ones self-check is structurally blind to it.

**Exactness: settled toward keeping it.** The fp16 route (what llm-scaler does — dequantize to fp16,
then DPAS) keeps products exact (11×11 bits fits fp32) and stays integer-exact only while
`|acc| < 2^24` ≈ 16.8 M; measured magnitudes at k=2560 are ~10^6 so it holds comfortably, but the
adversarial bound `k·510·127` = 2.7×10^8 at k=4096 does not — and it ends bit-for-bit agreement with
the 3090/CPU paths, which is the cross-check the harness leans on. The integer route (items 13/13b) has
no such cliff: s8/u8 into int32 is exact up to ±2^31, which bound-checks to ~1.3×10^8 at k=4096 with
order to spare, and it is measured at 100 % of spec on this card. So the risk moves from numerics to
**operand assembly cost** — the unpack must write bytes directly into the A layout, and item 10's
warning (register shuffling cost more than the DPAS saved) names the failure mode to measure first.
Second-order but real: replicating `x` 4× along K multiplies the activation footprint the B operand
cycles through (4·k bytes per token ≈ 10 KB at k=2560), which is SLM-sized, not DRAM-sized — so the
replication should be done once per token-batch into SLM, not per weight.

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

## 3b. Batched decode (`8 ≲ rows ≲ 256`): a schedule change, not a new arithmetic path

§3 covers `rows ≤ 8` and §4 covers chunked prefill, which leaves exactly the regime where §7's
concurrency table says the B70 becomes the binding worker. What a large-`rows` decode kernel can change
is one factor of `union(rows) · h · expert_bytes / rate`, so it is worth being precise about which:

* **bytes** — irreducible. Every touched expert's block is read once per layer per step, and the model
  already credits that reuse (it counts the *union* of picks, not `rows × topk`). No kernel goes below
  `E × expert_bytes` as rows grow.
* **rate** — addressable, by the measured clustered factor. This is the whole opportunity: with a
  bucketed grid, consecutive work-items belong to the same expert and read neighbouring tiles, which is
  the 1.08–1.99× of §3a. A `rows = 1` GEMV structurally *cannot* arrange that (too few tiles to order),
  which is why the win appears only at large b.
* **flops** — **measured, and DPAS does pay, but not at b=1.** The ~272-row figure in §1 is a
  compute-versus-bandwidth crossover; what costs us at rows > 1 is one instruction slot per
  (weight, row). Fitting `slots/weight = c0 + M·c1` to rev C's 205 (R=1) and 137 (R=4) G-w/s against the
  1.43e12 slot/s budget gives **c0 ≈ 5.8, c1 ≈ 1.15**: ~6 slots of unpack, ~1 more per token. The DPAS
  path was then built and measured (rev E, `probe_dpas2.cpp`, `out_dpas.txt`): **8.3–11.1 slots/weight,
  flat over rows 1→16**, giving ×0.79 / ×1.13 / ×2.31 / ×3.98 against rev C at rows 1 / 4 / 8 / 16. So
  the row term is removable and the crossover is rows ≈ 4 — slightly later than the model's 2.4, because
  assembling the operand is not free (~2.7 slots/weight more than the dp4a path's fixed cost). At b=1
  decode (5–6 rows per expert, and only ~10 experts) rev C still wins; the DPAS schedule earns its keep
  from batch 4 on. Revised after E28: with K compiled in, rev C's fixed cost drops to ~3.5 slots/weight, so
  the crossover moves to **rows ≈ 5** — rows 4: rev C+KCONST 103.3 µs vs rev E 99.8 µs (effectively tied);
  rows 8: 231.0 vs 108.8; rows 16: 448.2 vs 122.2.

Measured payoff (**[P]** from **[M]** rates, `plan_kernel_split.py` / `out_kernel_split.txt`), aggregating
over the parent and the link rather than quoting the card alone:

| rows | B70 µs/layer scattered | clustered | tok/s scattered | clustered | rescue | link share of B70 |
|---|---|---|---|---|---|---|
| 1 | 56 | 29 | 83 | 83 | **1.00×** (parent binds) | 7 % |
| 8 | 543 | 352 | 307 | 474 | **1.54×** | 6 % |
| 32 | 1530 | 1024 | 436 | 651 | **1.49×** | 8 % |
| 128 | 2738 | 1669 | 974 | 1597 | **1.64×** | 17 % |
| 256 | 3068 | 1765 | 1739 | 2531 | **1.46×** | **31 %** |

(2.68 bpw. At 6.05 bpw the same exercise yields 1.15–1.38×, because fatter tiles have less locality to
recover — 1.08–1.27× clustered in `out_rates_footprint_hiq.txt`.)

Three design rules fall out, and the first is the honest limit:

1. **The parent is the ceiling.** Where clustered time drops below `T_parent`, further locality is worth
   nothing — visible at b=4 (rescue 1.00×, parent already binds) and partly at b=8 (clustered 352 µs
   versus a 301 µs window). So this kernel is scored as "reach the clustered rate at large b", with a
   ~1.5–1.6× ceiling at 2.68 bpw, not as an unbounded optimisation.
2. **Bucket rows by expert; keep one unpack path.** The split is two *schedules* over the same Recipe
   A/B unpack kernel — the CPU path already does exactly this with one bucketed `mul1` and different
   thread counts — so the bit-exactness surface (gates A/B′) does not multiply. A second unpack
   implementation would, and is not what the numbers ask for.
3. **The return path becomes a large-`rows` problem.** Activation traffic is `rows·H` int8 down and
   `rows·topk·H·sz_out` up at 14.4 GB/s, which is 31 % of the B70's own time at b=256 — the point where
   `EXL3_MOE_B70_OUT_F16` stops being a knob and starts being a requirement, and where letting the B70
   sum the partials it owns (one partial per row instead of one per pick) is the larger win, since
   `topk` of 10 partials collapse to one.

## 4. Prefill kernels (`rows ≥ 32`): feeding XMX

**Eligibility first — but the bar is lower than this section has been claiming, in the same units
mistake as reading rates in GB/s across quantizations.** The ~272-row figure is
(367 TOPS / 2) ÷ 674 GB/s: MACs per *byte* at 1 byte per weight, i.e. it belongs to fp16/u8-at-1-byte
formats. Our trellis weights are 0.375 B each and the byte-replication route (item 13b) spends 4 MACs
per weight-token, so the arithmetic-intensity bar is 4 / 0.375 ≈ 10.7 MAC/byte and the crossover lands at
**~26 rows per expert at the 674 GB/s copy peak, or ~59 at the 292 GB/s this GEMV actually achieves**
[P from M — and note it depends on which bandwidth figure is used, so quote it with its basis]. Against
the real pick distributions (hottest Qwen3.8 expert sees 41–522 rows at R = 2048), that flips the
conclusion for the hot tail: at a 26-row bar a substantial share of experts qualifies, where at 272
rows essentially none did. `plan_concurrency.py`'s XMX eligibility numbers must be recomputed at the
corrected bar before §4's per-expert routing rule is used — the counts themselves (41–522 rows, 0–13 of
512 qualifying at 272) stay as recorded, but they answer the old question. The decode case is separate
and clearer: at 5–6 rows per expert the matrix unit is nowhere near arithmetic-bound, yet DPAS still
wins because it removes the per-row slot (§3b), not because it adds flops.

Weights must reach DPAS. Under the fp16 or split-operand reading this was a real obstacle — mul1 values
span −510…495, i.e. 11 bits, so they cannot be stored as int8 and both routes had to carry a wider or
two-term form. **Item 13b removes the obstacle**: the A operand is the four *bytes* of
`window * 0x83DCD12D` (each 0…255, genuinely u8) against activations replicated 4× along K, so nothing
needs 11 bits, the accumulator is int32 and exact, and `k_inv·q` stays in the epilogue as before.

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
