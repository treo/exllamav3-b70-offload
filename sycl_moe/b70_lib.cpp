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
#include <stdexcept>
#include <vector>
#include <array>
#include <unordered_map>
#include "moe_sycl.hpp"
using moe_sycl::g_alloc_bytes;
using moe_sycl::g_ws_bytes;

namespace {

struct Upload
{
    std::vector<uint16_t*> keep;   // device allocations owned here
    // Per (expert*3+cat) {trellis,suh,svh,bias} currently published in the layer's d_tab;
    // b70_update_expert frees these, re-uploads, and repoints (dynamic placement installs)
    std::vector<std::array<uint16_t*, 4>> slots;
    // Three-tier placement: only slots [0, n_sub) own real device weights (B70 tier); the
    // rest alias slot 0's buffers in the lookup table and are NEVER addressed by a job
    // (the child filters sel by membership) nor updated (b70_update_expert no-ops).
    int n_sub = 0;
};

struct Global
{
    sycl::queue* q = nullptr;
    std::mutex mu;
    // Serializes queue+buffer use of the SHARED bounce/staging memory: b70_warm runs on the
    // child's main thread during layer registration while the worker compute thread may be
    // running real forwards of already-registered layers (the parent's autosplit-measure
    // forwards start mid-load). Lock order: g.mu -> exec_mu (register/update hold mu and
    // reach warm; the forward path takes exec_mu only).
    std::mutex exec_mu;
    std::vector<Upload*> uploads;
    bool ok = false;
    size_t budget = ~(size_t)0;  // device bytes we allow ourselves to hold
    bool dev_full = false;       // a registration failed; stop trying (CPU covers the rest)
    std::unordered_map<const void*, Upload*> by_layer;   // MoeSyclLayer* -> its Upload
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
        // 0.82 fits 384-of-512 expert placement on a 32 GB card (23.9 GB weights) with
        // ~5 GB of driver/workspace margin; 0.70 used to refuse the last layers outright
        double frac = 0.82;
        if (const char* fb = getenv("EXL3_MOE_B70_BUDGET")) { double v = atof(fb); if (v > 0.05 && v < 0.98) frac = v; }
        g.budget = (size_t)(g.q->get_device().get_info<sycl::info::device::global_mem_size>() * frac);
        g.ok = true;
    } catch (const std::exception& e) {
        fprintf(stderr, "[b70moe] no SYCL GPU: %s\n", e.what());
        return false;
    }
    return true;
}

// Grow the shared device bounce and pinned host staging to serve forwards of `rows` token
// rows (registration primes these at 64; jobs can legitimately be larger - EXL3_MOE_CPU
// _SLOT_ROWS). Growth is geometric and primed with a queue memset: first-touch transfers on
// this stack can otherwise read back stale zeros despite completed events. On allocation
// failure this THROWS - b70_forward converts that to a nonzero return, the worker logs and
// pins the layer to the CPU path, and the job is RE-RUN there rather than consumed as the
// silent garbage a logged-and-returned refusal would produce (the original bug: FATAL line,
// out[] left holding the slot's previous contents, success returned).
void ensure_capacity(int rows, int H)
{
    static int cap = 0;
    if (rows > cap)
    {
        const int want = 2 * cap > rows ? 2 * cap : rows;
        uint16_t* nx = (uint16_t*)sycl::malloc_device<uint16_t>((size_t)want * H * 2, *g.q);
        float* no = (float*)sycl::malloc_device<float>((size_t)want * H, *g.q);   // rows x H fp32
        if (!nx || !no)
        {
            if (nx) sycl::free(nx, *g.q);
            if (no) sycl::free(no, *g.q);
            throw std::runtime_error("b70moe: bounce growth failed (OOM)");
        }
        g.q->memset(nx, 0, (size_t)want * H * 2);
        g.q->memset(no, 0, (size_t)want * H * 4);
        g.q->wait();
        if (g_bounce.d_x) sycl::free(g_bounce.d_x, *g.q);
        if (g_bounce.d_out) sycl::free(g_bounce.d_out, *g.q);
        g_bounce.d_x = nx; g_bounce.d_out = no; g_bounce.cap_rows = want;
        cap = want;
    }
    if ((size_t)rows * H * 4 > g_stage.stage_cap)
    {
        const size_t want = g_stage.stage_cap * 2 > (size_t)rows * H * 4
                                ? g_stage.stage_cap * 2 : (size_t)rows * H * 4;
        void* ns = sycl::malloc_host(want, *g.q);
        void* nu = sycl::malloc_host(want / 2, *g.q);   // fp16 mirror needs rows*H*2 bytes
        if (!ns || !nu)
        {
            if (ns) sycl::free(ns, *g.q);
            if (nu) sycl::free(nu, *g.q);
            throw std::runtime_error("b70moe: pinned stage growth failed (OOM)");
        }
        if (g_stage.stage) sycl::free(g_stage.stage, *g.q);
        if (g_stage.stage_u16) sycl::free(g_stage.stage_u16, *g.q);
        g_stage.stage = (float*)ns; g_stage.stage_u16 = (uint16_t*)nu; g_stage.stage_cap = want;
        memset(g_stage.stage, 0, want);
        memset(g_stage.stage_u16, 0, want / 2);
    }
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

const uint16_t* upload_u16(const uint16_t* host, size_t n, bool required);

// One expert matrix: upload trellis (repacked native->stream) + scales + optional bias.
// Shared by registration and the dynamic-placement update path. NOTE the keep push targets
// the CURRENT back Upload - during b70_update_expert that is the last-registered layer's
// list, whose entries are never individually freed (teardown keeps weights by design), so
// the extra record is inert; the authoritative per-expert tracking is Upload::slots.
bool fill_one(moe_sycl::MatrixSrc& m, const uint64_t* tr, const uint64_t* suh,
              const uint64_t* svh, const uint64_t* bias, int e, int tri_sz, int k, int n, int k2)
{
    m.trellis = upload_trellis((const uint16_t*)tr[e], tri_sz, k2);
    m.suh = (const uint16_t*)upload_u16((const uint16_t*)suh[e], (size_t)k, true);
    m.svh = (const uint16_t*)upload_u16((const uint16_t*)svh[e], (size_t)n, true);
    m.bias = bias && bias[e] ? (const uint16_t*)upload_u16((const uint16_t*)bias[e], (size_t)n, true) : nullptr;
    return m.trellis && m.suh && m.svh;
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
    const uint64_t* down_trellis, const uint64_t* down_suh, const uint64_t* down_svh, const uint64_t* down_bias,
    int n_sub
)
{
    if (!ensure_ctx()) return -1;
    std::lock_guard<std::mutex> lk(g.mu);
    g.uploads.push_back(new Upload());
    const int E = num_experts;
    if (n_sub <= 0 || n_sub > E) n_sub = E;
    const int H = hidden, I = interm;
    const int pu_gu = (H / 16) * (I / 16) * 8 * (2 * bits + hb);
    const int pu_d  = (I / 16) * (H / 16) * 8 * (2 * bits + hb);
    std::vector<moe_sycl::MatrixSrc> gs(E), us(E), ds(E);
    g.uploads.back()->slots.assign((size_t)E * 3, {});
    auto fill = [&](moe_sycl::MatrixSrc& m, const uint64_t* tr, const uint64_t* suh,
                    const uint64_t* svh, const uint64_t* bias, int e, int tri_sz, int k, int n,
                    int cat) {
        m.trellis = upload_trellis((const uint16_t*)tr[e], tri_sz, 2 * bits + hb);
        m.suh = (const uint16_t*)upload_u16((const uint16_t*)suh[e], (size_t)k, true);
        m.svh = (const uint16_t*)upload_u16((const uint16_t*)svh[e], (size_t)n, true);
        m.bias = bias && bias[e] ? (const uint16_t*)upload_u16((const uint16_t*)bias[e], (size_t)n, true) : nullptr;
        if (!m.trellis || !m.suh || !m.svh) return false;
        std::array<uint16_t*, 4>& sl = g.uploads.back()->slots[(size_t)e * 3 + cat];
        sl = { (uint16_t*)m.trellis, (uint16_t*)m.suh, (uint16_t*)m.svh, (uint16_t*)m.bias };
        return true;
    };
    for (int e = 0; e < n_sub; ++e) {
        if ((gated && !fill(gs[e], gate_trellis, gate_suh, gate_svh, gate_bias, e, pu_gu, H, I, 0)) ||
            !fill(us[e], up_trellis, up_suh, up_svh, up_bias, e, pu_gu, H, I, 1) ||
            !fill(ds[e], down_trellis, down_suh, down_svh, down_bias, e, pu_d, I, H, 2)) {
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
    // non-members share slot 0's device buffers: a stray chunk would read finite weights
    // instead of unmapped memory, and the table stays dense (zero kernel-side changes)
    for (int e = n_sub; e < E; ++e) { gs[e] = gs[0]; us[e] = us[0]; ds[e] = ds[0]; }
    g.uploads.back()->n_sub = n_sub;
    moe_sycl::LayerParams p;
    p.num_experts = E; p.hidden = H; p.interm = I; p.bits = bits; p.hb = hb;
    p.activation = activation; p.act_limit = act_limit; p.gated = gated != 0;
    auto* layer = new moe_sycl::MoeSyclLayer();
    layer->init(g.q, p, gs, us, ds);
    g.by_layer[(const void*)(intptr_t)layer] = g.uploads.back();
    fprintf(stderr, "[b70moe] registered layer: E %d (B70 tier %d), B70 weights so far %.2f GB, pool %.1f MB\n",
            E, n_sub, g_alloc_bytes / 1e9, moe_sycl::g_ws_bytes / 1e6);
    // budget gate is WEIGHTS-only by design (g_ws_bytes pool excluded): a large-prefill
    // workspace peak (~1-2 GB at EXL3_MOE_CPU_SLOT_ROWS=256) must not starve runtime
    // installs; physical headroom comes from the budget fraction itself
    // pre-size for typical handoff geometries (slot cap rows x topk)
    b70_warm((int64_t)(intptr_t)layer, 2048, 1024);
    b70_warm((int64_t)(intptr_t)layer, 1, 16);
    return (int64_t)(intptr_t)layer;
}

// Three-tier variant: upload only the first n_sub experts ([0, n_sub) = the B70 tier);
// remaining slots alias slot 0 and must never be addressed by a job (child-side filter)
// or updated (no-op below). n_sub <= 0 = full registration.
int64_t b70_register_layer_n
(
    int num_experts,
    int hidden, int interm,
    int bits, int hb,
    int activation, float act_limit, int gated,
    const uint64_t* gate_trellis, const uint64_t* gate_suh, const uint64_t* gate_svh, const uint64_t* gate_bias,
    const uint64_t* up_trellis,   const uint64_t* up_suh,   const uint64_t* up_svh,   const uint64_t* up_bias,
    const uint64_t* down_trellis, const uint64_t* down_suh, const uint64_t* down_svh, const uint64_t* down_bias,
    int n_sub
)
{
    if (!ensure_ctx()) return -1;
    size_t ups0 = g.uploads.size();
    try {
        return register_impl(num_experts, hidden, interm, bits, hb, activation, act_limit, gated,
            gate_trellis, gate_suh, gate_svh, gate_bias,
            up_trellis, up_suh, up_svh, up_bias,
            down_trellis, down_suh, down_svh, down_bias, n_sub);
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

// Budget introspection for child-side auto tier sizing
int64_t b70_budget_left()
{
    return (int64_t)(g.budget > g_alloc_bytes ? g.budget - g_alloc_bytes : 0);
}

int64_t b70_expert_bytes(int hidden, int interm, int bits, int hb, int gated)
{
    const int k2 = 2 * bits + hb;
    const size_t gu = (size_t)(hidden / 16) * (interm / 16) * 8 * k2 * 2;
    const size_t dn = (size_t)(interm / 16) * (hidden / 16) * 8 * k2 * 2;
    const size_t scales = (size_t)(hidden + 2 * interm) * 2;
    return (int64_t)(gated ? 2 * gu + dn + 3 * scales : gu + dn + 3 * scales);
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
            down_trellis, down_suh, down_svh, down_bias, 0);
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
    std::lock_guard<std::mutex> exec_lk(g.exec_mu);
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
    ensure_capacity(rows, H);
    uint16_t* dx = g_bounce.d_x;
    float* dout = g_bounce.d_out;
    sycl::event e0 = g.q->memcpy(dx, g_stage.stage_u16, (size_t)rows * H * 2);
    sycl::event e1 = layer->forward(chunks.data(), max_chunks, tmap, dx, dout, rows, &e0);
    sycl::event e2 = g.q->memcpy(g_stage.stage, dout, (size_t)rows * H * 4, {e1});
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
    std::lock_guard<std::mutex> exec_lk(g.exec_mu);   // shared bounce/stage + growth
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
    // width cap follows the tier the forward will take: the fp32 GemvK has exactly 4
    // accumulator chains, the DPAS tier carries 8 tokens in two m8 fragments
    const int mcap = moe_sycl::int8_mcap_pick(layer->pick_int8(rows), rows, rows * topk, E);
    for (int e = 0; e < E; ++e) {
        auto& lst = per_expert[e];
        for (size_t i = 0; i < lst.size(); i += mcap) {
            ChunkDev ch{};
            ch.expert = e;
            ch.m = (int)std::min<size_t>(mcap, lst.size() - i);
            for (int r = 0; r < ch.m; ++r) {
                ch.token[r] = lst[i + r].first;
                const uint16_t wv = ((const uint16_t*)w)[(size_t)lst[i + r].first * topk + lst[i + r].second];
                _Float16 h;
                std::memcpy(&h, &wv, 2);
                ch.weight[r] = (float)h;
                tokentries[ch.token[r]].push_back((int)chunks.size() * moe_sycl::MOE_MAXM + r);
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
    if ((size_t)rows > g_bounce.cap_rows) ensure_capacity(rows, H);   // grows (or throws)
    d_x = g_bounce.d_x; d_out = g_bounce.d_out;   // re-read: growth replaced the buffers
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
    std::lock_guard<std::mutex> exec_lk(g.exec_mu);   // no forward may run on the dying layer
    g.by_layer.erase((const void*)(intptr_t)handle);
    delete layer;
    // note: weight uploads stay allocated (layers are freed only at teardown)
}

// Dynamic placement sync: the worker replaced expert `e` of this layer in its arena
// (install); re-upload it and repoint the device table so B70 jobs never run on stale
// weights. Must be called with the layer quiesced. 0 = ok; nonzero = the new tensors could
// not be uploaded (slot keeps its old content; the caller must demote the layer to CPU).
int b70_update_expert
(
    int64_t handle, int e,
    const uint64_t* gate_trellis, const uint64_t* gate_suh, const uint64_t* gate_svh, const uint64_t* gate_bias,
    const uint64_t* up_trellis,   const uint64_t* up_suh,   const uint64_t* up_svh,   const uint64_t* up_bias,
    const uint64_t* down_trellis, const uint64_t* down_suh, const uint64_t* down_svh, const uint64_t* down_bias
)
{
    auto* layer = (moe_sycl::MoeSyclLayer*)(intptr_t)handle;
    if (!layer || e < 0 || e >= layer->params().num_experts) return 1;
    std::lock_guard<std::mutex> lk(g.mu);
    auto it = g.by_layer.find((const void*)(intptr_t)handle);
    if (it == g.by_layer.end()) return 1;
    Upload* u = it->second;
    if (e >= u->n_sub) return 0;   // non-member slot: arena-only, nothing published on device
    std::lock_guard<std::mutex> exec_lk(g.exec_mu);   // robust even against a violated quiesce contract
    const auto& p = layer->params();
    const int E = p.num_experts, H = p.hidden, I = p.interm;
    const int k2 = 2 * p.bits + p.hb;
    const int pu_gu = (H / 16) * (I / 16) * 8 * k2;
    const int pu_d  = (I / 16) * (H / 16) * 8 * k2;
    // the thirteen pointer arrays carry ONE expert (index 0); e selects the layer slot
    moe_sycl::MatrixSrc nm[3];
    if ((p.gated && !fill_one(nm[0], gate_trellis, gate_suh, gate_svh, gate_bias, 0, pu_gu, H, I, k2)) ||
        !fill_one(nm[1], up_trellis, up_suh, up_svh, up_bias, 0, pu_gu, H, I, k2) ||
        !fill_one(nm[2], down_trellis, down_suh, down_svh, down_bias, 0, pu_d, I, H, k2))
    {
        // partial upload: free the just-allocated pieces and undo their budget accounting
        const size_t tb = (size_t)pu_gu * 2, db = (size_t)pu_d * 2;
        for (int c = 0; c < 3; ++c)
        {
            const bool isg = c < 2;
            uint16_t* x[4] = { (uint16_t*)nm[c].trellis, (uint16_t*)nm[c].suh,
                               (uint16_t*)nm[c].svh, (uint16_t*)nm[c].bias };
            size_t by[4] = { isg ? tb : db, (size_t)H * 2, (size_t)I * 2, (size_t)I * 2 };
            if (c == 2) { by[1] = (size_t)I * 2; by[2] = (size_t)H * 2; by[3] = (size_t)H * 2; }
            for (int f = 0; f < 4; ++f)
                if (x[f]) { sycl::free(x[f], *g.q); g_alloc_bytes -= by[f]; }
        }
        return 1;
    }
    for (int c = 0; c < 3; ++c)
    {
        std::array<uint16_t*, 4>& sl = u->slots[(size_t)e * 3 + c];
        for (uint16_t* old : sl) if (old) sycl::free(old, *g.q);      // quiesced: safe
        sl = { (uint16_t*)nm[c].trellis, (uint16_t*)nm[c].suh,
               (uint16_t*)nm[c].svh, (uint16_t*)nm[c].bias };
        for (uint16_t* x : sl) if (x) u->keep.push_back(x);
        layer->update_expert(c, e, nm[c]);
    }
    return 0;
}

} // extern "C"
