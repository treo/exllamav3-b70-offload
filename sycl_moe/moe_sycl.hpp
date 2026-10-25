// SYCL MoE expert forward: device-resident mul1 EXL3 expert weights + fp32 forward that
// mirrors the scalar tier of exllamav3/exllamav3_ext/cpu/moe_mul1.cpp.
#pragma once

#include <sycl/sycl.hpp>
#include <cstdint>
#include <vector>

namespace moe_sycl {

extern size_t g_alloc_bytes;

// Host helper: convert a native mul1 trellis (u16 array, tiles of 8*K2 u16 = 4*K2 u32 words)
// into the GPU "stream" layout: state t's 16-bit window lives at bit
// P0 - ((K2*t + (K2&1)) >> 1) of a plain ascending bitstream whose k-th word is the native
// ring's (-k mod W)-th u32 word. The conversion itself is just a per-tile u32 word reversal.
inline void repack_native_to_stream_words(uint32_t* dst, const uint32_t* src, size_t ntiles, int K2)
{
    const int W = 4 * K2;
    for (size_t i = 0; i < ntiles; ++i)
        for (int k = 0; k < W; ++k)
            dst[i * W + k] = src[i * W + ((W - k) % W)];
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

// Chunk = up to 8 token rows routed to one expert (int8/DPAS tier; the fp32 tier caps at
// 4 rows host-side because GemvK carries exactly 4 accumulator chains). MAXM is the layout
// stride EVERYWHERE (tin/tout/tind/toutd row blocks, TokenMap entry encoding j*MOE_MAXM+r),
// so readers must never assume a chunk actually uses all 8.
struct ChunkDev
{
    int expert;
    int m;
    int token[8];
    float weight[8];
};

inline constexpr int MOE_MAXM   = 8;   // chunk width cap, int8/DPAS tier (= 2 m8 fragments)
inline constexpr int MOE_MAXM_F = 4;   // chunk width cap, fp32 scalar tier

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
    void init(sycl::queue* q, const LayerParams& p, const std::vector<MatrixSrc>& gates,
              const std::vector<MatrixSrc>& ups, const std::vector<MatrixSrc>& downs);
    ~MoeSyclLayer();

    // x [rows,H] fp16 device; out [rows,H] fp32 device (written exhaustively by K6).
    // Returns the final queue event; callers doing further queue ops (e.g. D2H readback)
    // MUST depends_on it: this stack does not reliably serialize plain q->memcpy on
    // preceding q.submit kernels within an in-order queue (root-caused, see NOTES.md).
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

    // Tier choice for a forward of `rows` token rows (EXL3_MOE_B70_INT8 override, auto =
    // rows >= 2, stream-layout only). The HOST CHUNKER must call this BEFORE grouping:
    // it fixes the chunk width cap (MOE_MAXM vs MOE_MAXM_F). forward() re-derives use8_
    // through the same function so the two can never disagree.
    bool pick_int8(int rows) const;

private:
    sycl::queue* Q = nullptr;
    LayerParams P;
    int cap_nc = 0, cap_rows = 0;
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
    // int8 / XMX DPAS tier (mirrors CPU VNNI semantics): operand slabs + i32 accumulators.
    // a8 layout [slot][k/8][8 rows][8 i32]; row r = 2*token + part (always-wide vh/vl pair),
    // word = x8 * 0x01010101 (one DPAS A fragment = 8 rows x 8 splat dwords, row stride 32B).
    int32_t *w_a8u = nullptr;        // (nc*nm) x (H/8) x 64
    int32_t *w_a8d = nullptr;        // nc x (I/8) x 64
    float *w_qsxu = nullptr;         // (nc*nm) x 8 x {A,B} epilogue affine
    float *w_qsxd = nullptr;         // nc x 8 x {A,B}
    int32_t *w_accgu = nullptr;      // (nc*nm) x 8 x I   raw i32 (nsl = 1)
    int32_t *w_accd = nullptr;       // nc x 8 x H
    bool int8_ok = false;            // rate/geometry supports the DPAS tier
    bool use8_ = false;              // tier resolved for the last forward (read by ensure_ws)
    int nm_ws_ = 1;                  // gated ? 2 : 1, cached for ensure_ws sizing
    int nsl8_gu_ = 1, nsl8_d_ = 1;   // int8 split-K degrees of the last forward
    int i8_slim_ = 1;                // 1 = fat kernel (frag1 live); 0 = slim decode pass
    int *w_tokb = nullptr;           // rows+1
    int *w_toke = nullptr;           // rows * topk (cap by alloc size)

    void ensure_ws(int nc, int rows);
};

// Shared implementation behind MoeSyclLayer::pick_int8 and the harness chunkers:
// rate_ok = stream-layout K2 in {4,5,8}; reads EXL3_MOE_B70_INT8 once. Fixes the
// chunk width cap (MOE_MAXM vs MOE_MAXM_F), so it MUST agree with the tier forward()
// will take.
bool int8_pick(bool rate_ok, int rows);

// Chunk width cap for the HOST CHUNKER (see moe_sycl.cpp for the measured policy and
// the EXL3_MOE_B70_MCAP lab override). int8_selected must come from int8_pick/pick_int8.
int int8_mcap_pick(bool int8_selected, int rows, int assigned, int experts);

} // namespace moe_sycl