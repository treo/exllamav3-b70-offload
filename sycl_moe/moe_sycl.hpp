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

// Chunk = up to 4 token rows routed to one expert (same grouping as the CPU path)
struct ChunkDev
{
    int expert;
    int m;
    int token[4];
    float weight[4];
};

// CSR of active chunk-slots per token row (for the final weighted gather)
struct TokenMap
{
    std::vector<int> begin;      // rows+1 (prefix counts)
    std::vector<int> entry;      // j * 4 + slot per active (token, topk slot)
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
    bool int8 = true;                // int8-accumulate GEMV (mirrors CPU VNNI/AVX2 tiers)
    const std::vector<sycl::event>& events() const { return pev; }

    // debug access to workspaces (device pointers)
    float* ws(int i) { return i == 0 ? w_tin : i == 1 ? w_tout : i == 2 ? w_h : i == 3 ? w_tind : w_toutd; }

    // ---- external stage-trace support (bench --i8trace). The int8 pipeline is being
    // re-ported from scratch on top of this float baseline (see NOTES 'Reset baseline');
    // getters stay null-safe so the harness compiles/runs at every step.
    void peek(void* host, const void* dev, size_t bytes)
    {
        Q->wait();
        Q->memcpy(host, dev, bytes).wait();
    }
    void* i8buf(int /*i*/) { return nullptr; }   // a8u a8d qsxu qsxd accgu accd (TODO as ported)

private:
    sycl::queue* Q = nullptr;
    LayerParams P;
    int cap_nc = 0, cap_rows = 0;
    int nsl = 4;               // split-K slices in the GEMV kernels
    std::vector<sycl::event> pev;

    uintptr_t* d_tab = nullptr;      // 12 x E pointer table (see TabField/cats in .cpp)
    ChunkDev* w_chunk = nullptr;   // also holds the token CSR blob behind the chunks
    size_t cap_blob = 0;           // bytes allocated for w_chunk
    char* h_blob = nullptr;        // pinned host staging for the control blob (ping-pong)
    char* h_blob2 = nullptr;
    bool h_flip = false;
    float *w_tin = nullptr;          // nc x 2 x 4 x H
    int32_t* w_tinq = nullptr;       // nc x 2 x 4 x H, int8 in low byte of each i32
    int32_t* w_rowc = nullptr;       // nc x 2 x 4 x 2: {q, sum_x8} per gemv row
    int32_t* w_tindq = nullptr;      // nc x 4 x I quantized
    int32_t* w_rowcd = nullptr;      // nc x 4 x 2
    float *w_tout = nullptr;         // nc x 2 x 4 x I
    float *w_h = nullptr;            // nc x 4 x I
    float *w_tind = nullptr;         // nc x 4 x I
    float *w_toutd = nullptr;        // nc x 4 x H
    int *w_tokb = nullptr;           // rows+1
    int *w_toke = nullptr;           // rows * topk (cap by alloc size)

    void ensure_ws(int nc, int rows);
};

} // namespace moe_sycl