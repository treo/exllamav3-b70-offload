# The int8 / XMX DPAS tier: full arc

The multi-session arc from "DPAS should be 2x faster" to the shipped auto-tier. Read with
`platform-pitfalls.md` P9 (joint_matrix facts) and `measurement-discipline.md` (why early
tables lied). Formula/identity basis in `mul1-trellis-spec.md`.

## Dead ends, in order (each a real trap)

1. **esimd `dp4a<...>` in generic kernels** — scalar `simd<,1>` ops cost ~2.5x the 5-op mask
   chain AND `dp4a<i32>` on `(u32,u32)` silently lowers to the SIGNED-src `sudp4a` → wrong
   bytesums.
2. **`xmx::dpas<C,B,A>` in generic `parallel_for`** — operand simds must be full-matrix sized;
   uniform fills materialize 512 B/lane (lab3: 770 scalar loads); slice-writes into operand
   simds are undefined-ish (partial zeros, DCE, wrong slots). Aggravated by a `q.copy()`
   argument-order blunder (copies HOST→DEVICE) that produced "GPU faults" which were really
   self-clobbered result readbacks.
3. **`single_task` launch** made generic-kernel dpas numerically correct (VC replicated model)
   but operand refills per step stayed expensive.
4. **`joint_matrix` with row/col-major B from SLM** — PASSES but ~150 mov/join fixup ops per
   fragment; the layout transform eats XMX's whole budget. `bench.cpp` reaches 367 TOPS only
   because it reuses fragments over 8192 mads; here B is regenerated every step, so the fixup
   is per-mad. col-major == VC ordinal order (why it was numerically right) but still slow.

## THE KEY: `layout::ext_intel_packed` B operand

Found in `vendor/llvm/sycl/doc` + `test-e2e/Matrix/joint_matrix_su_int8.cpp` (e2e tests live
at `vendor/llvm/sycl/test-e2e/Matrix` — a goldmine for exact API usage).

B declared `ext_intel_packed` = VNNI 4-row-block packing:

    addr(k,c) = (k>>2)*(N*4) + c*4 + (k&3)   bytes,   stride arg = N*4 (u8)

In u32 units that is `sl32[(k>>2)*N + c] = product_word` — EXACTLY the per-(wq,col) dword
stores the mul1 decoder already produces, one per product, ZERO scatter. The mul1 product word
IS a VNNI quad: 4 bytes of `state*M` = 4 hw-k slots. A side = x8 activation replicated x4 per
real k (row-major, stride K=32) — loads lower to a single `load_block2d.ugm.d16`.

`lab_jm7` (production-shaped probe: NJ x KS fragments; per SG unpack 2 u32 word-pairs → 8
muls → 2 vector dword STS → barrier → `jm_load` a(global block2d) + b(SLM packed) → dpas →
barrier): PASS exact vs the scalar model, 1.4 ns/fragment(128 weights) while hammering DRAM
with non-reused A bytes. ISA per fragment: 8 LDG + 8 mul + 8 shr + 2 vec-STL + 1 block2d +
1 `dpas.8x8` + syncs ≈ 0.27 lane-instructions/weight vs float tier 0.6-1.0.

`lab_jm8`: twin-fragment-per-tile SLM staging (16 bands x 16 dwords, fk bases at +0/+512,
stride 64, 2 loads + 2 mads) is bit-exact with the scalar reference. **Production staging must
mirror lab_jm8's addressing verbatim: `sl32[quad*16 + col]` per fragment slab.**

Externally/doubly verified knowledge carried into the re-port (do not re-derive):
1. joint_matrix int8 m8n16k32, B `ext_intel_packed`, packed byte addressing above: bit-exact
   vs scalar (lab_jm7, lab_jm8, LLVM e2e) on B70.
2. Mul1 identity: `bs(k,n) = 510 + w(k,n)/k_inv` exactly; a raw int8 dot with A bytes = x8(k)
   replicated x4 gives `C = Σ x8·bs = w-dot + 510·Σx8`, so `-510·Σx8` folds into the epilogue
   affine `{A,B} = {KDQ*q, -510*KDQ*q*sx}`.
3. CPU quant semantics (single + wide) as in `mul1-trellis-spec.md`.
4. fp32 and int8 paths share K1 prep + `tin`/`tind` layouts — do not touch `tin` layout.
5. The old "got = 1.014*want - 475925, corr 0.9996" stage-C fingerprint pointed at bs/-510
   bookkeeping (byte-sum vs per-byte pairing), NOT addressing. (Root cause below.)

## Why the first attempt was abandoned (baseline reset)

`moe_sycl.{cpp,hpp}` was restored to the float-only, production-verified commit (aa5cf203:
xval 6.06e-7, full synthetic battery ≤2.9e-6, plugin builds) rather than continue debugging
in-place; the last unverified int8 implementation lives in git at `88c3e781`. Reasons: in-kernel
probe scaffolding repeatedly polluted what it measured (flag-slot clobbering by dump regions;
probes bypassing the datapath under test), and several "fixes" (wide-pair rows, ±64 clamp,
ping-pong slabs) had been adopted without proof. Rule adopted with the reset: **kernels
contain ZERO debug hooks; verification is external readback + host emulation per stage, each
stage fed from device readbacks of its OWN inputs.** Increments I1 (QuantIn+Gemv8 GU),
I2 (staging == lab_jm8), I3 (K34i8 + QuantIn down + Gemv8 down), I4 (K6i8), each green under
`--i8trace` before the next.

## ROOT CAUSE of the old `1.014*want - 475925` fingerprint: negative splat

**`x8 * 0x01010101` does NOT splat negatives.** `-1 * 0x01010101 = 0xFEFEFEFF`, not
`0xFFFFFFFF`. The DPAS A bytes must be `(x8 & 0xff) * 0x01010101` (the cheat-sheet / CPU
`store_x8` spelling masks first: `(uchar)x8 * 0x01010101`).

Both the old kernel AND the old harness's stage-B expectation carried the same bug, so stage B
"passed" while stage C drifted — only three of four bytes of each negative activation word were
wrong, which is exactly a small-scale + constant-offset distortion of the dot products. The t30
`rnd` mode (random SIGNED A) reproduced it in 10 minutes where weeks of pipeline tracing did
not, because t30 computes its reference from low-byte semantics on random-signed data.

→ Rule: any splat/mask expression on signed bytes gets an explicit `& 0xff` and a lab mode with
negative values including -1 and -(1..8) mixes.

Second trap of the same session (measurement): see `measurement-discipline.md` "ablation
variants". Third trap: fp flags (`-ffp-contract=off -foffload-fp32-prec-div`) — device
approx-div + FMA contraction flip quantization ties vs host (`x*rq` then ±0.5 rounding);
without them `--i8trace` stage B fails sporadically by ±1 x8 on random data.

## As shipped (design + invariants)

Pipeline: `K1 rot -> Q1 quantize -> K2p GU int8 gemm -> i32 accs -> K3 act (apply kinv*q,
-510*sx) -> K4q quantize down input -> K5p DOWN int8 gemm -> K6 gather (apply q2/sx2 scalars)`,
with prep+quant fused (`PrepQuantI8`) and owner-gather K6 (see `decode-command-latency.md`).

- QuantIn is **always-wide @8192 levels** (|vh|,|vl| ≤ 64 — chosen for DPAS i16 pair safety,
  NOT actually proven necessary: uniform sat=127 passed, mixed ±127 not tested).
- `a8` layout `[slot][k/8][8r x 8i32]`; `Affine{A = KDQ*q_eff, B = -510*A*sx}` per DPAS row,
  folded as `+128*B` at element 0 AFTER the Hadamard (== `H*(B*ones)`).
- Split-K: acc `[slot][nsl][16][N]` i32, slice sums in K34i8/K6i8; auto nsl by the float
  lane-target heuristic (cap 8 gu / 4 down, halved for multi-row); `MOE_NSL` override clamped
  to 8 for this tier; nsl=1 stays exact for tiny shapes. NSL for the plain int8 design was
  originally 1 (job counts already ≥3840; slice-sum buffers and K3 slice loops disappear) —
  the always-wide/16-row layout reintroduced them.
- No weight expansion: weights stay the packed native stream (0.5 B/weight).
- Verification: 13-config → now 24-config `--i8trace` battery green (all rate families,
  gateless, act 0/1/3, rows 1..64, incl. first-ever m>4 chunk coverage); per-token integer math
  is chunking-invariant, so outputs are BITWISE equal across MAXM widths — a free check.
- `t30.cpp` = single-hot-A Gemv8 isolation lab (modes hot/one/rnd/sat/q25/rneg/…; `tm`/`tq` =
  timing with production geometry); every probe EXACT at K2560xN640x20slots.

Tier semantics: CPU-VNNI-equivalent int8 (documented ~0.9% rms on the CPU side). Gate policy
was rms ≤ 3% (NOT max_rel, which cancels pathologically) then ppl on all three models.

## TIER POLICY (auto) — history and current rule

- First rule: int8 iff `K2 ∈ {4,5,8}` AND some chunk has m≥2. Based on cold bench runs.
- Corrected by the sustained table (`measurements-ledger.md`): **int8 iff total rows ≥ 2.**
  Float pays per (chunk × row) while DPAS pays per chunk with the 8 fragment rows free, so
  even 2 tokens spread over single-row chunks already favors int8 (×1.17).
- After slim + fused prep-quant + owner-gather, rows=1 int8 sits ~9% behind float (sustained
  interleaved min-of-3: float 170.9/171.4/170.9 vs int8-slim 186.7/188.1/188.3 at K2=4; K2=8
  +8%); model best-of-2 agrees (71.39 auto/float vs 69.61 forced int8). **The old "~24%
  behind" number is obsolete.** Float stays the m=1 choice; the remaining gap is DPAS geometry
  (joint_matrix always fetches all 8 A rows = 1 KB/kf block whether 1 or 8 tokens are live)
  plus chain length, not fixable inside joint_matrix.
- `EXL3_MOE_B70_INT8=1/0` forces (the trace harness relies on `=1`). Forced int8 on
  non-DPAS rates falls back safely.
- Note the synthetic rows=1 int8 penalty largely VANISHES through the real handoff path (fixed
  ~40 µs of submit/handoff amortized), but auto keeps m=1 on fp32 as cheap insurance.
- Both tiers are WEIGHT-TRAFFIC bound at 2bit mul1 (identical weight bytes for both tiers!), so
  DPAS wins where the vector-ALU term matters: rows≥4 int8 flat-vs-float-grows; real-model
  prefill +8-10% (1711 → 1853..1880).

## MAXM=8 (8 tokens per chunk = 16 QuantIn rows = two m8 fragments)

Scoping first: `ChunkDev{x,sel,w}` never crosses the worker ABI — `b70_forward` receives raw
`(x, sel, wts, rows, topk)` and `b70_lib.cpp::forward_impl` does expert grouping/chunking
HOST-SIDE. So MAXM is contained entirely in `sycl_moe/`. Value proposition: mcs256/384 prefill
chunks average 2.5-3 tokens, so 8-slot chunks ~halve weight passes in the traffic-bound gemvs
(both tiers benefit, int8 most); decode (m=1) unaffected.

Shipped: Gemv8 stages the B band ONCE per tile and fires it at both accumulators (one weight
stream per 8 tokens). Layouts that grew: `ChunkDev[8]`, `tin/tout/tind/toutd` row blocks
(MAXM=8 stride), a8 slabs (kf block = 128 words, frag f at `+(2tk+fk)*128 + f*64`), `qsx`
(32 floats/slot), acc `[slot][nsl][16][N]`, TokenMap entries (`j*8+r`, decoded `>>3 / &7` in
BOTH K6s), worker + bench chunkers (cap = `int8_mcap_pick`: 8 for int8 — fp32 `GemvK` still has
exactly 4 chains, capped at 4 by the same helper), `b70_warm` geometry. Lab override
`EXL3_MOE_B70_MCAP=4|8`.

Same-binary sustained A/B (w8/w4): rows 5 ×1.11, 6 ×1.13, 8 ×1.40, 12 ×1.34, 16 ×1.42,
32 ×1.59, 64 ×1.55, E64/rows32 ×1.24, E128/rows128 ×1.51; rows≤4 neutral. Policy = always 8
under int8. Final int8-vs-float after MAXM8: rows 1 ×0.80 | 2 ×1.17 | 4 ×1.50 | 8 ×2.40 |
16 ×2.70 | 32 ×2.98 | 64 ×2.65 | 128 ×2.13.

**frag1-skip: tried and REVERTED.** Rows=4 initially REGRESSED +6.5% vs the old w4 binary
(unconditional frag1 mad on padded slots); the runtime `has1` skip erased it (238 → 223.5 µs)
— and then the full post-nsl-retune A/B reversed the verdict: skipping frag1 for m≤4 (runtime
break, or `template<bool>` peel with runtime dispatch) speeds the NARROW path ~22% but costs the
FULL-slot path ~20% (E128/rows128 w8: 3605 unconditional → 4325 break / 4389 peel; Spill=0 in
VTune for all variants — it is SCHEDULING quality, not spills: sibling-branch duplication and
in-loop breaks poison the straight-line unrolled schedule). Production policy is width-8
everywhere, so the fat path must stay monolithic: **the kernel ALWAYS runs both fragments and
QuantIn ALWAYS zero-fills 16 rows.** Consequence: the `MCAP=4` lab override runs ~50% slower
than MCAP=8 at chunk-rich shapes (5432 vs 3599 at E128/rows128) — known, accepted. If narrow
execution ever matters, the right shape is a compile-time SEPARATE kernel (own `parallel_for`),
not a branch inside this one. Which is exactly what the slim kernel is.

## Slim kernel (shipped; default when max chunk m ≤ 4)

`EXL3_MOE_I8SLIM=0` lab-forces fat. `Gemv8` gained `template<bool F1>`; `F1=false` drops frag1
load/mad/store entirely and `QuantIn(f1=0)` stops zero-writing frag1 rows. Acc rows 8..15 are
STALE BY DESIGN on slim passes — K34/K6 index `rr = (r>>2)*8 + 2*(r&3) ≤ 7` for m≤4, and the
trace skips those pad assertions via `layer.i8slim()`. Selected as a SEPARATE `parallel_for`
(the correct form of the frag1 skip after the branch/peel poison saga).
Sustained: rows4 E16 241 vs 287 µs (-16%), rows2 224 (flat), single-iter spans G2 121→79,
G5 65→46, Q1 12→9. Rows 5-8 untouched (fat dormant). Payoff zone is rows 2-4 (light batching,
speculative decode): int8 now runs ×1.2 over float there.

Related root-caused subtleties: the fused prep+quant kernel must index `chunks[j].token[tok]`
(DPAS row) not `token[r]`, and the rp decode is `tok = frag*4 + (rp&3)`, NOT `(rp>>1)&3` (the
`r>>1` already happened) — invisible at rows=1, caught by the rows=2 trace.

## The prefill roofline was wrong twice: it was the A-operand gather

Old claim: "E128/rows128 is 13x off the DRAM floor". Wrong because (a) the floor used a 3.3 MB
B matrix — the int8 tier streams the native K2-bit trellis (~410-520 KB per gu matrix at 2bpw)
— and (b) per-slot cost was attributed to B re-reads. `t39_stream.cpp` over (E, rows) fits
`time ≈ F·chunks + V·assignments` with F ≈ 8/16 µs (slim/fat slot) and V ≈ 0.03 µs: cost is per
SLOT (per matrix traversal), per-token DPAS is free, and MORE chunks per expert (10x B re-read
at E16/rows128) made per-token cost LOWER. Re-reads are a ~1.5-2x secondary term at most shapes.

`t39_stream.cpp` replays the real Gemv8 B-ladder + band + fragment pipeline standalone with the
DPAS segment stage-gated (compile-time stages 1..18). At production footprint:
loads alone 581 GB/s (saturated) → +band stores 577 → +jb SLM loads 576 → **+global ja
fragment loads + mads 141 (!!)** → +mads with ja loads removed 517. The `joint_matrix` GLOBAL A
load is the entire regression: it lowers to a per-lane byte gather. Feeding identical bytes with
per-lane contiguous 16B vector loads (fragment stale) runs at the no-A ceiling (st18 == st6):
**2.76x of the whole kernel recovered by memory form alone.** SLM-ring delivery works (st12
local-ja ≈ free; st14 wide-WG + 4-region group ring: 1.67x) but its WG barrier/copy tax leaves
~40% on the table vs the ceiling.

**Fix shipped: `EXL3_MOE_I8RING=1` (default on; fat gemvs only).** Wide 128-lane WGs + 4 KB
contiguous cooperative A copy per k-group into 4 rotating SLM regions + one group barrier per
group + local ja loads. Bit-exact by construction (same values, new delivery; full i8trace +
fingerprint battery agree to the digit). E128/rows128 3445 → 2354 µs (-32%), E512/rows128
8181 → 4695 (-43%), rows32 -21..-24%, decode untouched (slim path not gated). PARKED follow-up:
RING for the slim kernels needs ~10 lines (same ring, fk-only offsets), affects rows 2-4 only.

**Endgame recorded in `t40_esimd.cpp`**: per-thread `xmx::dpas<8,8,int>(acc,b,a)` with s8/u8
works TODAY — operand layouts verified by impulse probes (A: per-thread row-major 8x32B blocks
via `load_2d`; B: VNNI byte order `((k>>2)*16+n)*4+(k&3)`, 512 B per k32 panel); random
regression bit-exact for both u8 and s8 (bias-128) weight modes; DRAM-regime perf 1280 threads
x 41 KB panels = 62 ns/unit, on par with the fixed SIMT pattern. ESIMD's prize is removing the
gather AND the SLM-ring barriers in one move, likely together with MAXM 16/32 wide-row
instantiation (CUDA m32/m64-style).

## Cost model, fragment bucketing and the wide-M negative (2026-10-27)

The prefill gap was being reasoned about as "~12 µs per CHUNK, therefore widen chunks". Sweeping
`MOE_WIDEM_MAXM` (one -D, all three sides of the layout move together - see `moe_layout.hpp`) at
the model's own shape (E=260, H=2560, I=640, K2=8, topk 10) says otherwise; the full table with
the MCAP caveats lives in that header. Reading of it:

- cost ≈ (fragments run) × ~6.5 µs + (weight traversals) × ~1.4 µs. MAXM=16 removes 1.7x of
  traversals and adds 1.2-2x of fragments: 20% slower at rows=1024, 95% slower at rows=128 where
  chunks of 5 tokens pay four fragments. MAXM=4 is the mirror experiment (same fragments, 2x the
  traversals): 12-22% slower. MAXM=8 with the padding removed sits at the minimum.
- the fragment count per expert is already the minimum `ceil(n_e / I8_TOK_PER_FRAG)` once
  bucketing removes per-chunk padding, and it cannot go below that: BMG-G31 refuses an int8
  `joint_matrix` accumulator with Rows=16 (`lab_jm9_m16.cpp`: throws at launch - and note stdout
  was buffered away with it, so tee/flush labs before trusting their absence of output). 8 rows
  per fragment ÷ (vh,vl) = 4 tokens is the hardware floor.
- **bucketing** (`EXL3_MOE_B70_BUCKET=1`, default) is the CUDA tier's m-tile ladder
  (`exl3_moe_kernel.cuh`: finish with "the largest smaller tile that covers it, 64 → 32 → 16")
  transcribed to our chunker: `moe_bucket_chunks` stably partitions the chunk list so chunks one
  fragment can cover come first, and `forward()` issues ONE NF=1 launch for that prefix plus ONE
  full-width launch for the rest (`Gemv8Base::slot_base` keeps every downstream index - a8, acc,
  qsx, token map - on the global slot number). rows32 1919→1648, rows64 2630→2260, rows128
  3121→2867, rows512 8604→8379 µs; all-narrow jobs still take the single slim launch, so decode
  is untouched. The narrow bucket MUST share the wide bucket's ring: an identical split launched
  in the 16-lane no-ring slim geometry gave the whole saving back (rows128 3138 vs 3105
  unbucketed) - the per-lane global A gather is still ~2.8x the kernel.
- **slim + ring is a separate, negative answer** (parked lever 6 closed): with the ALL-narrow
  decode-shaped kernel staged through SLM (`EXL3_MOE_I8SLIMRING=1`) rows1/2/4/8 go
  197.6→225.3, 266→316, 411→487, 714→793 µs. One fragment does not amortise the staging.
- **n-major arena** (`moe_sycl.hpp`): readers own a column tile, so the k-major tile order made
  every k step a 128 B pickup on a 5 KB stride (t47 pure-read probe: 305 vs 781 GB/s). Permuting
  the tiles at upload - bit laws untouched - is bit-exact (xval 6.530e-07 unchanged, i8trace B..G
  OK, arena T1-T3 PASS) and buys 6.9% of the fat gemv / 7.8% of the float decode kernel. That is
  all it buys: the kernel is nowhere near DRAM-bound, so pattern fixes are worth single digits
  here and the remaining 3-4x to the read bound lives in the fragment path (esimd, t40).
- Harness lesson (three false "device is broken" rounds): the i8trace harness carried its own
  copies of the layout arithmetic - `qsxu[(size_t)slot * 32 + r * 2]` (float stride of
  `slot*I8R + r`), a split-K `collapse` that summed 16 rows, and `ent >> 3` for the token map.
  All are now expressed through `moe_layout.hpp`; a verifier with private literals verifies
  nothing about a geometry change.


## Known real gaps vs the CPU int8 tier

Wide-row 2-slot quantization: the ORIGINAL v1 plan fell back to plain int8 for rows needing it
(local degradation, e1 h-stage off). What shipped instead is always-wide @8192 levels in
QuantIn, which closes the accuracy question at the measured level (xval 1.355e-3, ppl ≤0.25%);
the CPU `quantize_row_wide` mirror + row pairing (m4→8 rows exactly fits when ≤2 tokens are
wide) remains the v2 shape if decode-quality headroom is ever needed. Alternative architecture
if headroom IS needed: CUDA's error-feedback residual pass for ~15-16-bit effective activations
at fp16-KL parity (`decode-command-latency.md` §CUDA small-m) — record only, no action.

## int8 m=1 ideas not built

Single-slot (127) quantization when m==1 && no wide rows; skip the `vl` half of the affine at
m=1 (2 of 8 fragment rows instead of 8); nsl tuning for the (then) 8-kernel pipeline. The
measured verdict stands: the deficit is launch-chain + structural 8x row waste, so these buy
little while joint_matrix fetches 8 rows unconditionally.