// SYCL MoE expert forward: device-resident mul1 EXL3 expert weights + fp32 forward that
// mirrors the scalar tier of exllamav3/exllamav3_ext/cpu/moe_mul1.cpp.
#pragma once

#include <sycl/sycl.hpp>
#include <cstdint>
#include <vector>

namespace moe_sycl {

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

    // x [rows,H] fp16 device; out [rows,H] fp32 device (zeroed then written).
    void forward(const ChunkDev* chunks_host, int num_chunks, const TokenMap& tmap,
                 const uint16_t* x, float* out, int rows);

    const LayerParams& params() const { return P; }

    // profiling: keep an event per submitted kernel (memcpys stay chained but untracked)
    bool prof = false;
    bool int8 = true;                // int8-accumulate GEMV (mirrors CPU VNNI/AVX2 tiers)
    const std::vector<sycl::event>& events() const { return pev; }

    // debug access to workspaces (device pointers)
    float* ws(int i) { return i == 0 ? w_tin : i == 1 ? w_tout : i == 2 ? w_h : i == 3 ? w_tind : w_toutd; }

private:
    sycl::queue* Q = nullptr;
    LayerParams P;
    int cap_nc = 0, cap_rows = 0;
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