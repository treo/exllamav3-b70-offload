// mul1 MoE chunk/fragment geometry - single source of truth (host + device).
#pragma once
// ---------------------------------------------------------------------------
// Shared LAYOUT constants for the B70 MoE offload: one header, no SYCL, read by
//   * moe_sycl.hpp       (device code + plugin; pulls these into namespace moe_sycl)
//   * moe_host_ref.hpp   (host fp32 reference and the i8trace stage verifier)
// so that a geometry change is edited HERE ONLY and a device/host mismatch becomes a
// compile error instead of a mysterious rms. (History: the int8 operand geometry used to be
// bare 8 / 16 / 64 / 128 literals repeated across both sides.)
//
// --------------------------------------------------------------- wide-M experiment
// MOE_MAXM is the number of TOKENS one DPAS chunk (gemv "slot") carries for a single expert.
// Swept at the model's own shape (E=260, k2=8, topk 10, bench_layer --nocheck, min-of-2
// interleaved, µs per job):
//
//   rows     MAXM=8 plain   MAXM=8 bucketed   MAXM=16 (NF=4)   MAXM=4 (NF=1, ring)
//   32            1919             1648              -             -
//   64            2630             2260              -             -
//   128           3121             2867            6135            3228
//   256           4834             4667              -             -
//   512           8604             8379           11676           10259
//   1024         15776            15539           19305              -
//
//   (MAXM=4 is the clean traversal probe: same fragment count as MAXM=8, twice the weight
//   traversals - and it is only +3.4% over plain MAXM=8 at rows128 (3228 vs 3121), which is how
//   the two terms separate: ~5.9 us per FRAGMENT versus ~0.4 us per TRAVERSAL at this shape.
//   Run WITHOUT `EXL3_MOE_I8SLIMRING=1` it is a disaster (rows512: 22620 us), because MAXM=4
//   makes every chunk "slim" and the slim kernel's A operand then comes from the per-lane global
//   gather - the same 2.8x that motivated I8RING.)
//
//   `EXL3_MOE_B70_MCAP=4` on a MAXM=8 build is NOT this experiment: it also flips `slim`, i.e.
//   it silently drops the ring. Anyone re-deriving the cost model from an MCAP A/B will get it
//   wrong twice - which is exactly what the old "cost is ~12 us per chunk, so wide-M is the
//   prefill lever" note did.
//
// Cost carries two terms: weight traversals (∝ chunks = Σ_e ceil(n_e/MOE_MAXM)) and fragment
// chains (∝ Σ_chunks ceil(m/I8_TOK_PER_FRAG), padding included). Fitted on the rows128 pair
// above: ~5.9 us per fragment against ~0.4 us per traversal, so fragments dominate and padding
// is the waste worth attacking. MAXM=16 buys 1.7x fewer traversals for 1.2-2x the fragments and
// 2x the a8/acc/ring footprint (49 KB SLM ⇒ fewer co-resident WGs) and loses everywhere;
// MAXM=8 with the padding removed is the minimum.
//
// What DOES pay is not wasting fragments on partially filled chunks: see
// moe_bucket_chunks in moe_sycl.hpp (narrow chunks run NF=1 instead of NF=I8_FRAGS) -
// E260/rows128 3121 -> 2867 us, rows64 2630 -> 2260, rows32 1919 -> 1648.
//
// AND the fragment count itself is a floor, not a choice: BMG-G31 REJECTS an int8 m16
// accumulator at runtime ("joint_matrix with matrix_type::sint32, use::accumulator,
// Rows=16, Cols=16 is not supported on this device", probed 2026-10-27), so 8 rows per
// fragment is the hardware maximum and the vh/vl split makes that 4 TOKENS. Per-pick DPAS
// work is therefore irreducible under joint_matrix; only per-mad efficiency (esimd xmx::dpas,
// t40) or a single-part A operand (halves the rows, costs accuracy) can move it.
//
// Derivations (all power-of-two constrained; several index forms use shifts):
//   * one Xe2 m8n16k32 fragment covers I8_TOK_PER_FRAG tokens - its 8 matrix rows are the
//     vh/vl int8 split of those 4 tokens - so a chunk runs I8_FRAGS fragments;
//   * every fragment mad's against the SAME staged weight band: that sharing IS wide-M;
//   * I8R = rows per gemv slot = the stride of a8 / acc / qsx and of i8_row_of();
//   * I8_A8BLK = i32 words per (slot, k/8) a8 block: every staging copy and fragment base
//     is scaled by it.
// The ONE line to edit for a wide-M build (or pass -DMOE_WIDEM_MAXM=16). Kept as a macro
// precisely so the constant below has a single definition; nothing else may hardcode 8.
#ifndef MOE_WIDEM_MAXM
#define MOE_WIDEM_MAXM 8
#endif

namespace moe_layout {

inline constexpr int MOE_MAXM     = MOE_WIDEM_MAXM;   // tokens per DPAS chunk (gemv slot)
inline constexpr int MOE_MAXM_F   = 4;         // fp32 scalar tier cap (4 accumulator chains)
// Split-K ceiling of the FLOAT tier: tout/toutd are sized (chunk, mu, nsl, MOE_MAXM, N), so
// this 8 is a split-K degree, NOT a chunk width - it used to be a bare literal next to the
// MAXM literals and read like one.
inline constexpr int MOE_NSL_MAX  = 8;

inline constexpr int I8_TOK_PER_FRAG  = 4;                       // tokens per m8n16k32 fragment
inline constexpr int I8_ROWS_PER_FRAG = 8;                       // matrix rows per fragment
inline constexpr int I8_FRAGS         = MOE_MAXM / I8_TOK_PER_FRAG;
inline constexpr int I8R              = I8_FRAGS * I8_ROWS_PER_FRAG;
inline constexpr int I8_A8W           = 8;   // i32 splat words per (row, k/8) = one 32 B A row
inline constexpr int I8_A8BLK         = I8R * I8_A8W;            // i32 words per (slot, k/8)
inline constexpr int I8_ROWPAIRS      = I8R / 2;                 // fused-quant WGs per slot
inline constexpr int I8_KSLABS        = 2;   // a8 k slabs per trellis k tile (k16 = 2 x k8)

constexpr inline int ilog2(int v) { return v <= 1 ? 0 : 1 + ilog2(v / 2); }
inline constexpr int MOE_MAXM_SHIFT    = ilog2(MOE_MAXM);
inline constexpr int I8R_SHIFT         = ilog2(I8R);
inline constexpr int I8_A8W_SHIFT      = ilog2(I8_A8W);
inline constexpr int I8_A8BLK_SHIFT    = ilog2(I8_A8BLK);
inline constexpr int I8_ROWPAIRS_SHIFT = ilog2(I8_ROWPAIRS);
inline constexpr int I8_FRAGROWS_SHIFT = ilog2(I8_ROWS_PER_FRAG);

// int8 rows of token r within a gemv slot: fragment-major, vh at rr, vl at rr+1
constexpr inline int i8_row_of(int r)
{ return (r / I8_TOK_PER_FRAG) * I8_ROWS_PER_FRAG + 2 * (r % I8_TOK_PER_FRAG); }
// inverse: which token owns I8 row r (rows beyond the chunk's m are padding)
constexpr inline int i8_tok_of_row(int r)
{ return (r / I8_ROWS_PER_FRAG) * I8_TOK_PER_FRAG + ((r / 2) % I8_TOK_PER_FRAG); }

// A-operand ring (I8RING): one region per 4-tile group, reads trail writes by two groups.
inline constexpr int I8_RING_GROUP   = 4;                        // k tiles staged per region
inline constexpr int I8_RING_REGIONS = 4;                        // rotating regions
inline constexpr int I8_RING_TILE_BYTES = I8_KSLABS * I8_A8BLK * 4;
inline constexpr int I8_RING_BYTES      = I8_RING_GROUP * I8_RING_TILE_BYTES;   // one region
inline constexpr int I8_RING_HALFW      = I8_RING_TILE_BYTES * (I8_RING_GROUP / 2) / 16;

static_assert(I8R == I8_FRAGS * I8_ROWS_PER_FRAG, "chunk width must be whole m8 fragments");
static_assert(I8R == (1 << I8R_SHIFT), "I8R must be a power of two (shift-indexed layouts)");
static_assert(I8_A8BLK == (1 << I8_A8BLK_SHIFT), "a8 block must be a power of two");
static_assert(I8_ROWPAIRS == (1 << I8_ROWPAIRS_SHIFT), "row-pair count must be a power of two");
static_assert(MOE_MAXM % I8_TOK_PER_FRAG == 0, "chunk must be a whole number of fragments");
static_assert(MOE_MAXM >= I8_TOK_PER_FRAG, "chunk narrower than one fragment: use the float tier");

}   // namespace moe_layout