// SYCL MoE expert forward: device-resident mul1 EXL3 expert weights + fp32 forward that
// mirrors the scalar tier of exllamav3/exllamav3_ext/cpu/moe_mul1.cpp.
#pragma once

#include <sycl/sycl.hpp>
#include <cstdint>
#include <vector>
#include <algorithm>
#include "moe_layout.hpp"

namespace moe_sycl {

// All chunk/fragment geometry constants (see moe_layout.hpp) are visible unqualified
// inside this namespace, and as moe_sycl::<name> through this directive.
using namespace moe_layout;

extern size_t g_alloc_bytes;
extern size_t g_ws_bytes;   // shared workspace pool (ensure_ws): physical VRAM, but NOT
                           // weights - excluded from the registration budget so a big
                           // prefill's pool growth cannot starve runtime expert installs

// Host helper: convert a native mul1 trellis (u16 array, tiles of 8*K2 u16 = 4*K2 u32 words)
// into the GPU "stream" layout: state t's 16-bit window lives at bit
// P0 - ((K2*t + (K2&1)) >> 1) of a plain ascending bitstream whose k-th word is the native
// ring's (-k mod W)-th u32 word. The conversion itself is just a per-tile u32 word reversal.
// ------------------------------------------------------------------ arena tile order
// Native (checkpoint) tile order is k-major: tile (tk, tn) of a matrix with tiles_n column
// tiles sits at (tk*tiles_n + tn). Every gemv reader owns ONE column tile and walks tk, so in
// that order each k step strides tiles_n*W bytes while consuming only W*4 = 128 B. The pure
// read probe t47 measured that pattern at 305 GB/s against 781 GB/s for a sequential walk of
// the same 1.7 GB footprint (P3 = 781 GB/s, i.e. the stride, not the byte count, was the cap).
// Storing the arena n-major - tile (tk, tn) at (tn*tiles_k + tk) - makes each reader's k walk
// sequential. It is a PERMUTATION OF TILES ONLY; the per-tile u32 word reversal (and hence
// every bit law in archive/mul1-trellis-spec.md) is unchanged, so only the tile index
// function moves. MOE_STREAM_NMAJOR=0 rebuilds the classic layout (labs t27..t31 assume it).
// Measured on the shipped build (bit-exact: xval 6.530e-07, i8trace B..G OK, arena T1-T3):
// E260/rows128 int8 3320 -> 3092 us (-6.9%), E260/rows1 float 179 -> 165 us (-7.8%),
// E260/rows512 8934 -> 8531 (-4.5%). The kernel is far more issue-bound than this pattern's
// share, which is why 2.6x of read headroom bought 7% of run time - see archive/int8-dpas-tier.md.
#ifndef MOE_STREAM_NMAJOR
#define MOE_STREAM_NMAJOR 1
#endif

// words to advance per k tile inside one column tile
constexpr inline size_t moe_stream_row_step(size_t W, size_t tiles_n)
{ return MOE_STREAM_NMAJOR ? W : tiles_n * W; }
// words spanned by one column tile (the base offset multiplier)
constexpr inline size_t moe_stream_col_span(size_t W, size_t tiles_k)
{ return MOE_STREAM_NMAJOR ? tiles_k * W : W; }

// tiles_k = k tiles of THIS matrix ((K/16): hidden/16 for gate/up, interm/16 for down).
// It is only used for the permutation, but it is MANDATORY: the stream layout is undefined
// without it, and a caller that forgets it would silently write the wrong order.
inline void repack_native_to_stream_words(uint32_t* dst, const uint32_t* src, size_t ntiles, int K2,
                                          size_t tiles_k)
{
    const size_t W = 4 * (size_t)K2;
    const size_t tiles_n = tiles_k ? ntiles / tiles_k : 1;
    for (size_t i = 0; i < ntiles; ++i)
    {
        const size_t d = (!MOE_STREAM_NMAJOR || !tiles_k) ? i
                         : (i % tiles_n) * tiles_k + (i / tiles_n);
        for (size_t k = 0; k < W; ++k)
            dst[d * W + k] = src[i * W + ((W - k) % W)];
    }
}

// One expert matrix's packed weights + scales, already resident on the device.
struct MatrixSrc
{
    const uint16_t* trellis = nullptr;   // [k/16, n/16, tile_u16] native order
    const uint16_t* suh = nullptr;       // k fp16
    const uint16_t* svh = nullptr;       // n fp16
    const uint16_t* bias = nullptr;      // n fp16 or null
};

struct LayerParams
{
    int num_experts = 0;
    int hidden = 0;              // H
    int interm = 0;              // I
    int bits = 2;                // mul1 integer bits
    int hb = 0;                  // half-bit flag (rate = bits + 0.5)
    int activation = 0;          // 0 silu, 1 gelu, 2 relu2 (gateless), 3 swiglu_oai
    float act_limit = 0.f;
    bool gated = true;
};

// Chunk = up to MOE_MAXM token rows routed to one expert (int8/DPAS tier; the fp32 tier caps
// at MOE_MAXM_F rows host-side because GemvK carries exactly 4 accumulator chains). MOE_MAXM
// is the layout stride EVERYWHERE (tin/tout/tind/toutd row blocks, TokenMap entry encoding
// j*MOE_MAXM+r, the int8 a8/acc/qsx row stride I8R), so readers must never assume a chunk
// actually fills it - and the geometry constants live in moe_layout.hpp, shared with the host
// reference, so a wide-M build is a one-line (-DMOE_WIDEM_MAXM=16) experiment.
struct ChunkDev
{
    int expert;
    int m;
    int token[MOE_MAXM];
    float weight[MOE_MAXM];
};

// Stable partition of a chunk list so every NARROW chunk (m <= I8_TOK_PER_FRAG, i.e. one m8
// fragment covers it) precedes every WIDE chunk; returns the narrow count. The DPAS cost
// tracks the NUMBER OF FRAGMENTS RUN, not the tokens used: an m16 build measured 1.20x the
// m8 time at rows=1024 exactly matching its 1.2x fragment count, and 1.95x at rows=128 where
// half-empty 16-token chunks still ran four fragments. So instead of padding every chunk to
// I8_FRAGS fragments, forward() splits the launch at this boundary - the CUDA tier's m-tile
// ladder doctrine (exl3_moe_kernel.cuh: 64 -> 32 -> 16, "the largest smaller tile that
// covers it").
//
// BOTH host chunkers (the plugin's b70_lib fill and bench_layer's i8trace/reference) must
// call this before building the TokenMap, because the entry encoding carries the chunk index:
// a chunk list that is ordered on one side and not the other silently verifies a different
// schedule than the device ran.
template <typename Vec>
inline int moe_bucket_chunks(Vec& chunks)
{
    return (int)(std::stable_partition(chunks.begin(), chunks.end(),
                                       [](const ChunkDev& c) { return c.m <= I8_TOK_PER_FRAG; })
                 - chunks.begin());
}

// CSR of active chunk-slots per token row (for the final weighted gather)
struct TokenMap
{
    std::vector<int> begin;      // rows+1 (prefix counts)
    std::vector<int> entry;      // j * MOE_MAXM + slot per active (token, topk slot)
};

class MoeSyclLayer
{
public:
    // MatrixSrc pointers are DEVICE pointers owned by the caller, alive for the layer's life.
    // Dynamic placement: repoint one expert's device weights (cat 0 gate, 1 up, 2 down) to
    // a NEW device-resident MatrixSrc. Requires a quiesced layer (installs run after a full
    // stream sync). The CALLER owns freeing the previous allocation.
    void update_expert(int cat, int e, const MatrixSrc& m);
    void init(sycl::queue* q, const LayerParams& p, const std::vector<MatrixSrc>& gates,
              const std::vector<MatrixSrc>& ups, const std::vector<MatrixSrc>& downs);
    ~MoeSyclLayer();

    // x [rows,H] fp16 device; out [rows,H] fp32 device (written exhaustively by K6).
    // Returns the final queue event; callers doing further queue ops (e.g. D2H readback)
    // MUST depends_on it: this stack does not reliably serialize plain q->memcpy on
    // preceding q.submit kernels within an in-order queue (root-caused: NOTES, and
    // archive/platform-pitfalls.md P1).
    sycl::event forward(const ChunkDev* chunks_host, int num_chunks, const TokenMap& tmap,
                        const uint16_t* x, float* out, int rows,
                        const sycl::event* pre_dep = nullptr);

    const LayerParams& params() const { return P; }

    // profiling: keep an event per submitted kernel (memcpys stay chained but untracked)
    bool prof = false;
    bool int8 = true;                // int8/XMX DPAS tier AUTO-eligible (multi-row shapes).
                                     // EXL3_MOE_B70_INT8=1 forces on, =0 forces off; see
                                     // forward() for the measured per-shape policy.
    bool int8_active = false;        // set by forward(): the tier actually used for the last call
    const std::vector<sycl::event>& events() const { return pev; }

    // debug access to workspaces (device pointers)
    float* ws(int i) { return i == 0 ? w_tin : i == 1 ? w_tout : i == 2 ? w_h : i == 3 ? w_tind : w_toutd; }
    // control blob base + ctr zone offset (external counter readback, bench --ctrdbg)
    const void* blob() const { return (const void*)w_chunk; }
    size_t ctr_offset() const { return ctr_off_logged; }
    void read_dbg(int out[2])
    {
        if (!coop_dbg_buf) { out[0] = out[1] = -1; return; }
        peek(out, coop_dbg_buf, 8);
    }
    size_t ctr_bytes_dbg = 0;   // set by forward() when EXL3_MOE_B70_CTRDBG=1

    // ---- external stage-trace support (bench --i8trace): read-only device->host copy,
    // fully synchronized; touches nothing in the pipeline. i8buf() stays null-safe so the
    // harness compiles/runs even when the int8 buffers were never allocated.
    void peek(void* host, const void* dev, size_t bytes)
    {
        Q->wait();
        Q->memcpy(host, dev, bytes).wait();
    }
    void* i8buf(int i)   // 0 a8u, 1 a8d, 2 qsxu, 3 qsxd, 4 accgu, 5 accd
    {
        switch (i) {
            case 0: return w_a8u;
            case 1: return w_a8d;
            case 2: return w_qsxu;
            case 3: return w_qsxd;
            case 4: return w_accgu;
            default: return w_accd;
        }
    }
    // accgu/accd are [slot][nsl][16][N] slice buffers; the trace must sum slices itself.
    int i8nsl(int which) const { return which ? nsl8_d_ : nsl8_gu_; }   // 0 gu, 1 down
    int i8slim() const { return i8_slim_; }   // 1 = fat dual-fragment kernel ran
    int i8fuse() const { return i8_fuse_; }    // 1 = fused PrepQuantI8 consumed x directly
    int coop_active() const { return coop_ ? 1 : 0; }  // 1 = float forward ran fused K5+K6
    int nslgu_dbg = 0, nsld_dbg = 0;   // set by forward() for stage-probe readbacks

    // Tier choice for a forward of `rows` token rows (EXL3_MOE_B70_INT8 override, auto =
    // rows >= 2, stream-layout only). The HOST CHUNKER must call this BEFORE grouping:
    // it fixes the chunk width cap (MOE_MAXM vs MOE_MAXM_F). forward() re-derives use8_
    // through the same function so the two can never disagree.
    bool pick_int8(int rows) const;

private:
    sycl::queue* Q = nullptr;
    LayerParams P;
    int cap_nc = 0, cap_rows = 0;
    size_t ctr_off_logged = 0;   // blob offset of the ctr zone (for bench --ctrdbg)
    int cap_nc8 = 0;             // separate growth mark for the int8 slabs
    int nsl = 4;               // split-K slices in the GEMV kernels
    std::vector<sycl::event> pev;

    uintptr_t* d_tab = nullptr;      // 12 x E pointer table (see TabField/cats in .cpp)
    ChunkDev* w_chunk = nullptr;   // also holds the token CSR blob behind the chunks
    size_t cap_blob = 0;           // bytes allocated for w_chunk
    char* h_blob = nullptr;        // pinned host staging for the control blob (ping-pong)
    char* h_blob2 = nullptr;
    bool h_flip = false;
    float *w_tin = nullptr;          // nc x 2 x 4 x H
    float *w_tout = nullptr;         // nc x 2 x 8(nsl) x 4 x I
    float *w_h = nullptr;            // nc x 4 x I
    float *w_tind = nullptr;         // nc x 4 x I
    float *w_toutd = nullptr;        // nc x 8(nsl) x 4 x H
    float *w_tsw = nullptr;          // nc x MAXM x H: fused-down (coop) per-entry transformed x weight
    // int8 / XMX DPAS tier (mirrors CPU VNNI semantics): operand slabs + i32 accumulators.
    // a8 layout [slot][k/8][16 rows][8 i32] (128 words per k/8 block: two m8 fragments,
    // row r = 2*token + part (always-wide vh/vl pair), word = x8*0x01010101 with (x8&0xff)
    // - the negative splat trap; one DPAS A fragment = 8 rows x 8 splat dwords, stride 32B).
    int32_t *w_a8u = nullptr;        // (nc*nm) x (H/8) x 128
    int32_t *w_a8d = nullptr;        // nc x (I/8) x 128
    float *w_qsxu = nullptr;         // (nc*nm) x 16 x {A,B} epilogue affine
    float *w_qsxd = nullptr;         // nc x 16 x {A,B}
    int32_t *w_accgu = nullptr;      // (nc*nm) x nsl8 x 16 x I  raw i32
    int32_t *w_accd = nullptr;       // nc x nsl8 x 16 x H
    int coop_dbg = 0;                 // EXL3_MOE_B70_CTRDBG: fire-counter scratch
    int* coop_dbg_buf = nullptr;      // 4 ints: [gu_fires, d_fires, reserved, reserved]
    bool int8_ok = false;             // rate/geometry supports the DPAS tier
    bool use8_ = false;              // tier resolved for the last forward (read by ensure_ws)
    bool coop_ = false;              // last float forward used the counter-fed fused down
    int nm_ws_ = 1;                  // gated ? 2 : 1, cached for ensure_ws sizing
    int nsl8_gu_ = 1, nsl8_d_ = 1;   // int8 split-K degrees of the last forward
    int i8_slim_ = 1;                // 1 = fat kernel (frag1 live); 0 = slim decode pass
    int i8_fuse_ = 0;                // 1 = K1+Q1 fused ran (tin never written)
    int *w_tokb = nullptr;           // rows+1
    int *w_toke = nullptr;           // rows * topk (cap by alloc size)

    void ensure_ws(int nc, int rows);
};

// Shared implementation behind MoeSyclLayer::pick_int8 and the harness chunkers:
// rate_ok = stream-layout K2 in {4,5,8}; reads EXL3_MOE_B70_INT8 once. Fixes the
// chunk width cap (MOE_MAXM vs MOE_MAXM_F), so it MUST agree with the tier forward()
// will take.
bool int8_pick(bool rate_ok, int rows);

// THE BITRATE CONTRACT (archive/mul1-trellis-spec.md): EXL3/CUDA produces mul1 rates
// K2 = 2*bits + hb in {2,3,4,5,6,7,8,10,12,14,16} - integer bits 1..8, half-bits ONLY
// 1.5/2.5/3.5 (exl3_kernel_map.cu TORCH_CHECKs K<=3 && codebook==mul1). Rates that have
// compile-time-specialized decoders on B70. X-macro lists are the SINGLE SOURCE for the
// predicates here AND the runtime->template dispatchers in moe_sycl.cpp - plugin and the
// bench/trace harnesses can never disagree about which tier/rate is specialized.
#define MOE_FOREACH_K2_FLOAT(F) F(2) F(3) F(4) F(5) F(6) F(7) F(8) F(10) F(12) F(14) F(16)
#define MOE_FOREACH_K2_DPAS(F)  F(2) F(3) F(4) F(5) F(6) F(7) F(8) F(10) F(12) F(14) F(16)
#define MOE_K2P(V) case V: return true;
inline bool moe_k2_float(int k2) { switch (k2) { MOE_FOREACH_K2_FLOAT(MOE_K2P) default: return false; } }
inline bool moe_k2_dpas(int k2)  { switch (k2) { MOE_FOREACH_K2_DPAS(MOE_K2P)  default: return false; } }
#undef MOE_K2P

// ---- fault-attribution logging (OPEN BUG: DEVICE_LOST/pinned-CPU at large cap_rows)
// EXL3_MOE_B70_ALLOCLOG=<file> records every USM alloc/free (site,ptr,bytes) plus one
// geometry line per forward with all live pool/base pointers. The xe kernel driver logs
// faulting GPU VAs on UA faults (journalctl -k); a fault address is then attributed to
// the buffer whose [ptr,ptr+bytes) contains - or sits just below - it, telling us WHICH
// layout walks off the end. Null/no-op when the env var is unset (zero hot-path cost).
FILE* alog();
void alog_msg(const char* fmt, ...);   // no-ops when alog() is null
#define MOE_ALOG_ALLOC(p, bytes, site) \
    do { if (moe_sycl::alog()) moe_sycl::alog_msg("A %s %p %zu", site, (const void*)(p), (size_t)(bytes)); } while (0)
#define MOE_ALOG_FREE(p, bytes, site) \
    do { if (moe_sycl::alog()) moe_sycl::alog_msg("F %s %p %zu", site, (const void*)(p), (size_t)(bytes)); } while (0)

// Chunk width cap for the HOST CHUNKER (see moe_sycl.cpp for the measured policy and
// the EXL3_MOE_B70_MCAP lab override). int8_selected must come from int8_pick/pick_int8.
int int8_mcap_pick(bool int8_selected, int rows, int assigned, int experts);

} // namespace moe_sycl