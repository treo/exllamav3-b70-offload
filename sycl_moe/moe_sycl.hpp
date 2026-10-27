// SYCL MoE expert forward: device-resident mul1 EXL3 expert weights + fp32 forward that
// mirrors the scalar tier of exllamav3/exllamav3_ext/cpu/moe_mul1.cpp.
#pragma once

#include <sycl/sycl.hpp>
#include <cstdint>
#include <vector>

namespace moe_sycl {

extern size_t g_alloc_bytes;
extern size_t g_ws_bytes;   // shared workspace pool (ensure_ws): physical VRAM, but NOT
                           // weights - excluded from the registration budget so a big
                           // prefill's pool growth cannot starve runtime expert installs

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
    int i8fuse() const { return i8_fuse_; }    // 1 = fused PrepQuantI8 consumed x directly

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
    // a8 layout [slot][k/8][16 rows][8 i32] (128 words per k/8 block: two m8 fragments,
    // row r = 2*token + part (always-wide vh/vl pair), word = x8*0x01010101 with (x8&0xff)
    // - the negative splat trap; one DPAS A fragment = 8 rows x 8 splat dwords, stride 32B).
    int32_t *w_a8u = nullptr;        // (nc*nm) x (H/8) x 128
    int32_t *w_a8d = nullptr;        // nc x (I/8) x 128
    float *w_qsxu = nullptr;         // (nc*nm) x 16 x {A,B} epilogue affine
    float *w_qsxd = nullptr;         // nc x 16 x {A,B}
    int32_t *w_accgu = nullptr;      // (nc*nm) x nsl8 x 16 x I  raw i32
    int32_t *w_accd = nullptr;       // nc x nsl8 x 16 x H
    bool int8_ok = false;            // rate/geometry supports the DPAS tier
    bool use8_ = false;              // tier resolved for the last forward (read by ensure_ws)
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

// THE BITRATE CONTRACT (NOTES 'bitrate contract'): EXL3/CUDA produces mul1 rates
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