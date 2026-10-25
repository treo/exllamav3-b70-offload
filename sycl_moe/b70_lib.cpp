// libb70moe: Level Zero / SYCL expert-compute backend for the CPU-offload MoE path.
// Plain C ABI, no torch. The exllamav3 child worker dlopens this library when
// EXL3_MOE_B70=1 and routes registered layers' compute jobs here; expert weights
// (native mul1 layout, no band swizzle) are uploaded to the Arc B70 once at layer
// registration, token rows and outputs cross PCIe per job.
//
// Build: icpx -fsycl -O2 -fPIC -shared b70_lib.cpp moe_sycl.cpp -o libb70moe.so \
//        -Xlinker -rpath -Xlinker /opt/intel/oneapi/compiler/2026.2/lib
#include <sycl/sycl.hpp>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <algorithm>
#include <mutex>
#include <exception>
#include <vector>
#include "moe_sycl.hpp"
using moe_sycl::g_alloc_bytes;

namespace {

struct Upload
{
    std::vector<uint16_t*> keep;   // device allocations owned here
};

struct Global
{
    sycl::queue* q = nullptr;
    std::mutex mu;
    std::vector<Upload*> uploads;
    bool ok = false;
    size_t budget = ~(size_t)0;  // device bytes we allow ourselves to hold
    bool dev_full = false;       // a registration failed; stop trying (CPU covers the rest)
};

Global g;

struct StageGlob { float* stage = nullptr; uint16_t* stage_u16 = nullptr; size_t stage_cap = 0; sycl::event stage_ev; } g_stage;
sycl::event g_last_ev;   // completes the previous job before its outputs/bounce are reused

struct { uint16_t* d_x = nullptr; float* d_out = nullptr; size_t cap_rows = 0; } g_bounce;

bool ensure_ctx()
{
    if (g.ok) return true;
    std::lock_guard<std::mutex> lk(g.mu);
    if (g.ok) return true;
    try {
        // NOTE the explicit async_handler: the DEFAULT one calls std::terminate, and this
        // stack routes some device-selector/adapter init failures through the async path
        // (e.g. a malformed ONEAPI_DEVICE_SELECTOR kills the worker despite try/catch).
        static sycl::queue queue{sycl::gpu_selector_v,
                                 sycl::async_handler{[](sycl::exception_list el) {
                                     for (auto& e : el) {
                                         try { std::rethrow_exception(e); }
                                         catch (const sycl::exception& se) {
                                             fprintf(stderr, "[b70moe] async: %s\n", se.what());
                                         } catch (...) {}
                                     }
                                 }}};
        g.q = &queue;
        printf("[b70moe] device: %s\n",
               g.q->get_device().get_info<sycl::info::device::name>().c_str());
        // Leave a fat margin for scratch pools, queue/page-table allocations and driver
        // bookkeeping; running right up to physical VRAM makes LAUNCHES fault asynchronously
        // with UR_RESULT_ERROR_OUT_OF_DEVICE_MEMORY instead of failing an allocation cleanly.
        double frac = 0.70;
        if (const char* fb = getenv("EXL3_MOE_B70_BUDGET")) { double v = atof(fb); if (v > 0.05 && v < 0.98) frac = v; }
        g.budget = (size_t)(g.q->get_device().get_info<sycl::info::device::global_mem_size>() * frac);
        g.ok = true;
    } catch (const std::exception& e) {
        fprintf(stderr, "[b70moe] no SYCL GPU: %s\n", e.what());
        return false;
    }
    return true;
}

// repacked upload: per-tile u32 word reversal (native ring -> column-window stream)
const uint16_t* upload_trellis(const uint16_t* host, size_t n_u16, int K2)
{
    if (g.dev_full || g_alloc_bytes + n_u16 * 2 > g.budget) return nullptr;
    std::vector<uint32_t> tmp(n_u16 / 2);
    moe_sycl::repack_native_to_stream_words(tmp.data(), (const uint32_t*)host, n_u16 / (2 * 4 * (size_t)K2), K2);
    uint32_t* p = sycl::malloc_device<uint32_t>(tmp.size(), *g.q);
    if (!p) { fprintf(stderr, "[b70moe] OOM trellis upload %zu words\n", tmp.size()); return nullptr; }
    g.uploads.back()->keep.push_back((uint16_t*)p);   // recorded before the copy so a throwing
    g_alloc_bytes += tmp.size() * 4;                  // wait() still rolls back cleanly
    g.q->memcpy(p, tmp.data(), tmp.size() * 4).wait();
    return (const uint16_t*)p;
}

const uint16_t* upload_u16(const uint16_t* host, size_t n, bool required)
{
    if (!host) return nullptr;
    if (g.dev_full || g_alloc_bytes + n * 2 > g.budget) return nullptr;
    uint16_t* p = sycl::malloc_device<uint16_t>(n, *g.q);
    if (!p) { fprintf(stderr, "[b70moe] OOM allocating %zu u16\n", n); return nullptr; }
    g.uploads.back()->keep.push_back(p);
    g_alloc_bytes += n * 2;
    g.q->memcpy(p, host, n * 2).wait();
    (void)required;
    return p;
}

} // namespace

extern "C" {

void b70_warm(int64_t handle, int rows, int max_chunks);

static void forward_impl(int64_t, const void*, const int32_t*, const void*, float*, int, int);

// Wraps forward_impl: 0 = ok, nonzero = device failure (caller falls back to CPU).
int b70_forward(int64_t handle, const void* x, const int32_t* sel, const void* w, float* out, int rows, int topk)
{
    try {
        forward_impl(handle, x, sel, w, out, rows, topk);
        return 0;
    } catch (...) {
        return 1;
    }
}

// Initialize (idempotent). 0 on success.
int b70_init()
{
    return ensure_ctx() ? 0 : 1;
}

// Register one layer's expert weights. Pointers are HOST arrays (CPU arena), copied
// to the device. gate_* may be null/absent for gateless layers. Returns handle >= 0
// or -1.
static int64_t register_impl
(
    int num_experts,
    int hidden, int interm,
    int bits, int hb,
    int activation, float act_limit, int gated,
    const uint64_t* gate_trellis, const uint64_t* gate_suh, const uint64_t* gate_svh, const uint64_t* gate_bias,
    const uint64_t* up_trellis,   const uint64_t* up_suh,   const uint64_t* up_svh,   const uint64_t* up_bias,
    const uint64_t* down_trellis, const uint64_t* down_suh, const uint64_t* down_svh, const uint64_t* down_bias
)
{
    if (!ensure_ctx()) return -1;
    std::lock_guard<std::mutex> lk(g.mu);
    g.uploads.push_back(new Upload());
    const int E = num_experts;
    const int H = hidden, I = interm;
    const int pu_gu = (H / 16) * (I / 16) * 8 * (2 * bits + hb);
    const int pu_d  = (I / 16) * (H / 16) * 8 * (2 * bits + hb);
    std::vector<moe_sycl::MatrixSrc> gs(E), us(E), ds(E);
    auto fill = [&](moe_sycl::MatrixSrc& m, const uint64_t* tr, const uint64_t* suh,
                    const uint64_t* svh, const uint64_t* bias, int e, int tri_sz, int k, int n) {
        m.trellis = upload_trellis((const uint16_t*)tr[e], tri_sz, 2 * bits + hb);
        m.suh = (const uint16_t*)upload_u16((const uint16_t*)suh[e], (size_t)k, true);
        m.svh = (const uint16_t*)upload_u16((const uint16_t*)svh[e], (size_t)n, true);
        m.bias = bias && bias[e] ? (const uint16_t*)upload_u16((const uint16_t*)bias[e], (size_t)n, true) : nullptr;
        if (!m.trellis || !m.suh || !m.svh) return false;
        return true;
    };
    for (int e = 0; e < E; ++e) {
        if ((gated && !fill(gs[e], gate_trellis, gate_suh, gate_svh, gate_bias, e, pu_gu, H, I)) ||
            !fill(us[e], up_trellis, up_suh, up_svh, up_bias, e, pu_gu, H, I) ||
            !fill(ds[e], down_trellis, down_suh, down_svh, down_bias, e, pu_d, I, H)) {
            // roll back this layer's device allocations and fall back to CPU for it
            fprintf(stderr, "[b70moe] registration out of device memory; layer stays on CPU\n");
            g.dev_full = true;
            Upload* u = g.uploads.back();
            for (uint16_t* p : u->keep) { sycl::free(p, *g.q); }
            g.uploads.pop_back();
            delete u;
            return -1;
        }
    }
    moe_sycl::LayerParams p;
    p.num_experts = E; p.hidden = H; p.interm = I; p.bits = bits; p.hb = hb;
    p.activation = activation; p.act_limit = act_limit; p.gated = gated != 0;
    auto* layer = new moe_sycl::MoeSyclLayer();
    layer->init(g.q, p, gs, us, ds);
    fprintf(stderr, "[b70moe] registered layer: E %d, B70 bytes so far %.2f GB\n", E, g_alloc_bytes / 1e9);
    // pre-size for typical handoff geometries (slot cap rows x topk)
    b70_warm((int64_t)(intptr_t)layer, 64, 1024);
    b70_warm((int64_t)(intptr_t)layer, 1, 16);
    return (int64_t)(intptr_t)layer;
}

// Any SYCL throw during upload/warm (device OOM surfaces late, often from memcpy().wait() or
// the first launch) must NOT cross the C ABI: roll this layer's allocations back and leave
// the layer on the CPU path.
int64_t b70_register_layer
(
    int num_experts,
    int hidden, int interm,
    int bits, int hb,
    int activation, float act_limit, int gated,
    const uint64_t* gate_trellis, const uint64_t* gate_suh, const uint64_t* gate_svh, const uint64_t* gate_bias,
    const uint64_t* up_trellis,   const uint64_t* up_suh,   const uint64_t* up_svh,   const uint64_t* up_bias,
    const uint64_t* down_trellis, const uint64_t* down_suh, const uint64_t* down_svh, const uint64_t* down_bias
)
{
    if (!ensure_ctx()) return -1;
    size_t ups0 = g.uploads.size();
    try {
        return register_impl(num_experts, hidden, interm, bits, hb, activation, act_limit, gated,
            gate_trellis, gate_suh, gate_svh, gate_bias,
            up_trellis, up_suh, up_svh, up_bias,
            down_trellis, down_suh, down_svh, down_bias);
    } catch (const std::exception& e) {
        fprintf(stderr, "[b70moe] registration threw: %s; layer stays on CPU\n", e.what());
    } catch (...) {
        fprintf(stderr, "[b70moe] registration threw; layer stays on CPU\n");
    }
    g.dev_full = true;
    while (g.uploads.size() > ups0) {
        Upload* u = g.uploads.back();
        for (uint16_t* p : u->keep) sycl::free(p, *g.q);
        g.uploads.pop_back();
        delete u;
    }
    return -1;
}

// Routed-expert forward for one layer, blocking.
//   x [rows,hidden] fp16; sel [rows,topk] int32 expert ids; w [rows,topk] fp16 routing
//   weights; out [rows,hidden] fp32 (overwritten). All plain host pointers.
// pre-grow workspaces and prime every queue/memory path once; real jobs must never be the
// first user of a freshly allocated buffer on this stack (first-touch transfers can read back
// stale zeros even with completed events).
void b70_warm(int64_t handle, int rows, int max_chunks)
{
    auto* layer = (moe_sycl::MoeSyclLayer*)(intptr_t)handle;
    if (!layer) return;
    const int H = layer->params().hidden;
    std::vector<moe_sycl::ChunkDev> chunks((size_t)max_chunks);
    for (auto& c : chunks) { c = moe_sycl::ChunkDev{}; c.expert = 0; c.m = 1; }
    moe_sycl::TokenMap tmap;
    tmap.begin.assign(rows + 1, 0);
    tmap.entry.assign((size_t)max_chunks, 0);
    for (int t = 0; t < rows; ++t) tmap.begin[t] = std::min((size_t)max_chunks, (size_t)t * max_chunks / rows);
    tmap.begin[rows] = max_chunks;
    for (int i = 0; i < max_chunks; ++i) {
        int j = std::min(max_chunks - 1, i / std::max(1, max_chunks / std::max(1, rows)));
        tmap.entry[i] = j * 4 + (i % 4);
    }
    static uint16_t* dx = nullptr;
    static float* dout = nullptr;
    static int warm_rows = 0;
    if (rows > warm_rows) {
        if (dx) sycl::free(dx, *g.q);
        if (dout) sycl::free(dout, *g.q);
        dx = sycl::malloc_device<uint16_t>((size_t)rows * H, *g.q);
        dout = sycl::malloc_device<float>((size_t)rows * H, *g.q);
        if (!dx || !dout) fprintf(stderr, "[b70moe] OOM warm bounce\n");
        g.q->memset(dx, 0, (size_t)rows * H * 2);
        g.q->memset(dout, 0, (size_t)rows * H * 4);
        g.q->wait();
        warm_rows = rows;
    }
    g_bounce.d_x = dx; g_bounce.d_out = dout; g_bounce.cap_rows = warm_rows;
    if ((size_t)rows * H * 4 > g_stage.stage_cap) {
        if (g_stage.stage) sycl::free(g_stage.stage, *g.q);
        if (g_stage.stage_u16) sycl::free(g_stage.stage_u16, *g.q);
        g_stage.stage_cap = (size_t)rows * H * 4;
        g_stage.stage = (float*)sycl::malloc_host(g_stage.stage_cap, *g.q);
        g_stage.stage_u16 = (uint16_t*)sycl::malloc_host(g_stage.stage_cap / 2, *g.q);
        if (!g_stage.stage || !g_stage.stage_u16) fprintf(stderr, "[b70moe] OOM pinned stage\n");
        memset(g_stage.stage, 0, g_stage.stage_cap);
        memset(g_stage.stage_u16, 0, g_stage.stage_cap / 2);
    }
    sycl::event e0 = g.q->memcpy(dx, g_stage.stage_u16, (size_t)rows * H * 2);
    sycl::event e1 = layer->forward(chunks.data(), max_chunks, tmap, dx, dout, rows, &e0);
    sycl::event e2 = g.q->memcpy(g_stage.stage, dout, g_stage.stage_cap, {e1});
    e2.wait();
    g_last_ev = e2;
    fprintf(stderr, "[b70moe] warm done rows %d chunks %d; B70 bytes %.2f GB\n", rows, max_chunks, g_alloc_bytes / 1e9);
}

static void forward_impl
(
    int64_t handle,
    const void* x, const int32_t* sel, const void* w, float* out,
    int rows, int topk
)
{
    auto* layer = (moe_sycl::MoeSyclLayer*)(intptr_t)handle;
    if (!layer) return;
    using moe_sycl::ChunkDev;
    using moe_sycl::TokenMap;
    const int E = layer->params().num_experts;
    const int H = layer->params().hidden;
    std::vector<std::vector<std::pair<int, int>>> per_expert(E);   // (token, slot)
    for (int t = 0; t < rows; ++t)
        for (int k = 0; k < topk; ++k) {
            const int32_t e = sel[(size_t)t * topk + k];
            if (e >= 0 && e < E) per_expert[e].emplace_back(t, k);
        }
    std::vector<ChunkDev> chunks;
    TokenMap tmap;
    std::vector<std::vector<int>> tokentries(rows);
    for (int e = 0; e < E; ++e) {
        auto& lst = per_expert[e];
        for (size_t i = 0; i < lst.size(); i += 4) {
            ChunkDev ch{};
            ch.expert = e;
            ch.m = (int)std::min<size_t>(4, lst.size() - i);
            for (int r = 0; r < ch.m; ++r) {
                ch.token[r] = lst[i + r].first;
                const uint16_t wv = ((const uint16_t*)w)[(size_t)lst[i + r].first * topk + lst[i + r].second];
                _Float16 h;
                std::memcpy(&h, &wv, 2);
                ch.weight[r] = (float)h;
                tokentries[ch.token[r]].push_back((int)chunks.size() * 4 + r);
            }
            chunks.push_back(ch);
        }
    }
    tmap.begin.assign(rows + 1, 0);
    for (int t = 0; t < rows; ++t) {
        tmap.begin[t] = (int)tmap.entry.size();
        for (int v : tokentries[t]) tmap.entry.push_back(v);
    }
    tmap.begin[rows] = (int)tmap.entry.size();

    uint16_t* d_x = g_bounce.d_x;
    float* d_out = g_bounce.d_out;
    if ((size_t)rows > g_bounce.cap_rows) {
        fprintf(stderr, "[b70moe] FATAL: rows %d exceeds preallocated cap %zu\n", rows, g_bounce.cap_rows);
        return;
    }
    // all queue ops carry explicit event dependencies; implicit ordering is unreliable here
    memcpy(g_stage.stage_u16, x, (size_t)rows * H * 2);
    sycl::event e_x = g.q->memcpy(d_x, g_stage.stage_u16, (size_t)rows * H * 2, {g_last_ev});
    sycl::event e_done = e_x;
    if (!chunks.empty())
        e_done = layer->forward(chunks.data(), (int)chunks.size(), tmap, d_x, d_out, rows, &e_x);
    sycl::event e_rd = g.q->memcpy(g_stage.stage, d_out, (size_t)rows * H * 4, {e_done});
    e_rd.wait();
    memcpy(out, g_stage.stage, (size_t)rows * H * 4);
    g_last_ev = e_rd;
}

void b70_free_layer(int64_t handle)
{
    auto* layer = (moe_sycl::MoeSyclLayer*)(intptr_t)handle;
    if (!layer) return;
    std::lock_guard<std::mutex> lk(g.mu);
    delete layer;
    // note: weight uploads stay allocated (layers are freed only at teardown)
}

} // extern "C"
