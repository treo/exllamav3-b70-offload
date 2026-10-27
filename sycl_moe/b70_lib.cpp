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
#include <atomic>
#include <chrono>
#include <thread>
#include <unordered_map>
#include "moe_sycl.hpp"
using moe_sycl::g_alloc_bytes;
using moe_sycl::g_ws_bytes;

namespace {

struct Upload
{
    // ONE DEVICE ARENA per layer (the CUDA-tier handoff-segment philosophy: geometry known
    // up front, everything is an offset, no allocator in the hot path). Per-expert blocks
    // are REGULAR - same size, same field offsets - so a dynamic-placement install
    // (b70_update_expert, always live with -mcpa) OVERWRITES the block in place: no free,
    // no realloc, no d_tab repoint (bias presence is the only table change), and a failure
    // during the host-side fill leaves the device untouched (the copy is atomic per expert).
    // Registration is ONE H2D memcpy + ONE wait instead of ~2.4k synchronous per-tensor
    // copies, and rollback / teardown accounting is one size. The old scheme's ~115k
    // individual malloc_device calls were driver-bookkeeping and fragmentation pressure
    // right where the ~300MB workspace pool needs to grow late in a near-full run.
    char*   arena = nullptr;
    size_t  arena_bytes = 0;
    size_t  block = 0;             // bytes per expert block (64-aligned end)
    size_t  cat_base[3] = {};      // cat 0 gate / 1 up / 2 down -> offset inside a block
    size_t  off[3][4] = {};        // field 0 trellis / 1 suh / 2 svh / 3 bias -> block offset
    size_t  sz[3][4] = {};
    int     gated = 1;
    int     n_sub = 0;             // B70-tier expert count; e >= n_sub alias block 0
    size_t  tiles_k[3] = {};       // k tiles per cat (stream layout permutation): gu H/16, down I/16
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
    // Poison latch: after any device fault (UR_RESULT_ERROR_DEVICE_LOST and friends) the
    // queue is dead - every later submit hangs or throws, and a compute thread stuck in a
    // dead-queue wait never sets the job's done flag => the parent spins forever (observed
    // hang at EXL3_MOE_CPU_SLOT_ROWS=512). Once poisoned, forwards fail instantly so the
    // worker pins layers to CPU and jobs complete.
    std::atomic<bool> poison{false};
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
        MOE_ALOG_ALLOC(nx, (size_t)want * H * 2, "bounce_x");
        MOE_ALOG_ALLOC(no, (size_t)want * H * 4, "bounce_out");
        if (!nx || !no)
        {
            if (nx) sycl::free(nx, *g.q);
            if (no) sycl::free(no, *g.q);
            throw std::runtime_error("b70moe: bounce growth failed (OOM)");
        }
        g.q->memset(nx, 0, (size_t)want * H * 2);
        g.q->memset(no, 0, (size_t)want * H * 4);
        g.q->wait();
        if (g_bounce.d_x) { MOE_ALOG_FREE(g_bounce.d_x, g_bounce.cap_rows * (size_t)H * 2, "bounce_x"); sycl::free(g_bounce.d_x, *g.q); }
        if (g_bounce.d_out) { MOE_ALOG_FREE(g_bounce.d_out, g_bounce.cap_rows * (size_t)H * 4, "bounce_out"); sycl::free(g_bounce.d_out, *g.q); }
        g_bounce.d_x = nx; g_bounce.d_out = no; g_bounce.cap_rows = want;
        cap = want;
    }
    if ((size_t)rows * H * 4 > g_stage.stage_cap)
    {
        const size_t want = g_stage.stage_cap * 2 > (size_t)rows * H * 4
                                ? g_stage.stage_cap * 2 : (size_t)rows * H * 4;
        void* ns = sycl::malloc_host(want, *g.q);
        void* nu = sycl::malloc_host(want / 2, *g.q);   // fp16 mirror needs rows*H*2 bytes
        MOE_ALOG_ALLOC(ns, want, "stage");
        MOE_ALOG_ALLOC(nu, want / 2, "stage_u16");
        if (!ns || !nu)
        {
            if (ns) sycl::free(ns, *g.q);
            if (nu) sycl::free(nu, *g.q);
            throw std::runtime_error("b70moe: pinned stage growth failed (OOM)");
        }
        if (g_stage.stage) { MOE_ALOG_FREE(g_stage.stage, g_stage.stage_cap, "stage"); sycl::free(g_stage.stage, *g.q); }
        if (g_stage.stage_u16) { MOE_ALOG_FREE(g_stage.stage_u16, g_stage.stage_cap / 2, "stage_u16"); sycl::free(g_stage.stage_u16, *g.q); }
        g_stage.stage = (float*)ns; g_stage.stage_u16 = (uint16_t*)nu; g_stage.stage_cap = want;
        memset(g_stage.stage, 0, want);
        memset(g_stage.stage_u16, 0, want / 2);
    }
}

// repacked upload: per-tile u32 word reversal (native ring -> column-window stream)
//
// Arena geometry. Sections are 64B-aligned so every trellis word offset stays 4B-aligned
// (the gemvs read u32s) and every section start is cacheline-clean for the DMA. Gateless
// layers SKIP the gate cat: the block is up+down only (the old per-tensor scheme never
// allocated gate buffers either).
static void upload_layout(Upload& u, int H, int I, int k2, int gated)
{
    const auto al64 = [](size_t x) { return (x + 63) & ~(size_t)63; };
    const size_t tri_gu = al64((size_t)(H / 16) * (I / 16) * 8 * (size_t)k2 * 2);   // bytes
    const size_t tri_d  = al64((size_t)(I / 16) * (H / 16) * 8 * (size_t)k2 * 2);
    const size_t cat[3][4] = {
        { tri_gu, al64((size_t)H * 2), al64((size_t)I * 2), al64((size_t)I * 2) },  // gate
        { tri_gu, al64((size_t)H * 2), al64((size_t)I * 2), al64((size_t)I * 2) },  // up
        { tri_d,  al64((size_t)I * 2), al64((size_t)H * 2), al64((size_t)H * 2) },  // down
    };
    size_t cb = 0;
    for (int c = (gated ? 0 : 1); c < 3; ++c) {
        u.cat_base[c] = cb;
        size_t o = 0;
        for (int f = 0; f < 4; ++f) { u.off[c][f] = cb + o; u.sz[c][f] = cat[c][f]; o += cat[c][f]; }
        cb = al64(cb + o);
    }
    u.block = cb;
    u.gated = gated;
    u.tiles_k[0] = u.tiles_k[1] = (size_t)H / 16;   // gate/up contract: K = hidden
    u.tiles_k[2] = (size_t)I / 16;                  // down contract:      K = interm
}

// one cat's source arrays (expert-indexed pointer arrays into the worker's arena)
struct CatSrc { const uint64_t *tr = nullptr, *suh = nullptr, *svh = nullptr, *bias = nullptr; };

// Fill ONE expert block into a host staging buffer: trellis repacked native->stream, then
// scales/bias verbatim. Absent matrices (gate on gateless layers, null arrays) make it
// return false BEFORE any device-side action; absent bias leaves that section stale (never
// read - the d_tab entry is null).
static bool fill_block(char* dst, const Upload& u, const CatSrc src[3], size_t e_idx, int k2)
{
    for (int c = (u.gated ? 0 : 1); c < 3; ++c) {
        if (!src[c].tr || !src[c].tr[e_idx] || !src[c].suh[e_idx] || !src[c].svh[e_idx]) return false;
        moe_sycl::repack_native_to_stream_words(
            (uint32_t*)(dst + u.off[c][0]), (const uint32_t*)src[c].tr[e_idx],
            u.sz[c][0] / (16 * (size_t)k2), k2,
            u.tiles_k[c]);                             // tile = 8*K2 u16 = 16*K2 bytes
        memcpy(dst + u.off[c][1], (const void*)src[c].suh[e_idx], u.sz[c][1]);
        memcpy(dst + u.off[c][2], (const void*)src[c].svh[e_idx], u.sz[c][2]);
        if (src[c].bias && src[c].bias[e_idx]) memcpy(dst + u.off[c][3], (const void*)src[c].bias[e_idx], u.sz[c][3]);
    }
    return true;
}

// device MatrixSrc for ARENA block e given source arrays indexed arr_idx (registration:
// arr_idx==e; the update path passes one-expert arrays with arr_idx==0 and the layer slot e)
static moe_sycl::MatrixSrc ms_at(const Upload& u, const CatSrc& sp, size_t arr_idx, int e, int c)
{
    moe_sycl::MatrixSrc m;
    if (!sp.tr || !sp.tr[arr_idx]) return m;
    const char* b = u.arena + (size_t)e * u.block;
    m.trellis = (const uint16_t*)(b + u.off[c][0]);
    m.suh     = (const uint16_t*)(b + u.off[c][1]);
    m.svh     = (const uint16_t*)(b + u.off[c][2]);
    m.bias    = (sp.bias && sp.bias[arr_idx]) ? (const uint16_t*)(b + u.off[c][3]) : nullptr;
    return m;
}

// Process-stable upload staging (pageable: registration is one big copy per layer, wire-
// time bound, and this must NOT compete with the worker's pinned-arena budget). Grows but
// never shrinks, ForwardArena-style.
static std::vector<uint8_t> g_up_stage;

// Free a half-built layer's device memory and undo its budget accounting. Normal teardown
// never frees arenas (weights stay, matching the old design and its NOTES rule).
static void rollback_upload(Upload* u)
{
    if (!u) return;
    if (u->arena) {
        MOE_ALOG_FREE(u->arena, u->arena_bytes, "arena");
        sycl::free(u->arena, *g.q);
        g_alloc_bytes -= u->arena_bytes;
        u->arena = nullptr;
    }
}

} // namespace

extern "C" {

void b70_warm(int64_t handle, int rows, int max_chunks);

static void forward_impl(int64_t, const void*, const int32_t*, const void*, float*, int, int);

// Wraps forward_impl: 0 = ok, nonzero = device failure (caller falls back to CPU).
int b70_forward(int64_t handle, const void* x, const int32_t* sel, const void* w, float* out, int rows, int topk)
{
    if (g.poison.load(std::memory_order_relaxed)) return 3;   // device dead: instant fail, never touch the queue
    if (moe_sycl::alog()) moe_sycl::alog_msg("FWD enter h %lld rows %d topk %d", (long long)handle, rows, topk);
    try {
        forward_impl(handle, x, sel, w, out, rows, topk);
        return 0;
    } catch (const sycl::exception& e) {
        fprintf(stderr, "[b70moe] forward sycl error: %s\n", e.what());
        moe_sycl::alog_msg("FWD THROW sycl: %s", e.what());
        g.poison.store(true);
        return 1;
    } catch (const std::exception& e) {
        fprintf(stderr, "[b70moe] forward error: %s\n", e.what());
        moe_sycl::alog_msg("FWD THROW std: %s", e.what());
        g.poison.store(true);
        return 1;
    } catch (...) {
        g.poison.store(true);
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
    const int E = num_experts;
    if (n_sub <= 0 || n_sub > E) n_sub = E;
    const int H = hidden, I = interm;
    const int k2 = 2 * bits + hb;
    Upload* u = new Upload();
    u->n_sub = n_sub;
    upload_layout(*u, H, I, k2, gated);
    u->arena_bytes = (size_t)n_sub * u->block;
    if (g.dev_full || g_alloc_bytes + u->arena_bytes > g.budget) {
        fprintf(stderr, "[b70moe] registration out of device memory; layer stays on CPU\n");
        g.dev_full = true;
        delete u;
        return -1;
    }
    u->arena = (char*)sycl::malloc_device<char>(u->arena_bytes, *g.q);
    MOE_ALOG_ALLOC(u->arena, u->arena_bytes, "arena");
    if (!u->arena) {
        fprintf(stderr, "[b70moe] OOM arena alloc %zu B; layer stays on CPU\n", u->arena_bytes);
        g.dev_full = true;
        delete u;
        return -1;
    }
    g_alloc_bytes += u->arena_bytes;
    g.uploads.push_back(u);   // owned from here: every later throw unwinds via rollback_upload
    std::vector<moe_sycl::MatrixSrc> gs(E), us(E), ds(E);
    const CatSrc src[3] = {
        CatSrc{ gate_trellis, gate_suh, gate_svh, gate_bias },
        CatSrc{ up_trellis,   up_suh,   up_svh,   up_bias   },
        CatSrc{ down_trellis, down_suh, down_svh, down_bias },
    };
    try {
        if (g_up_stage.size() < u->arena_bytes) g_up_stage.resize(u->arena_bytes);
        char* stage = (char*)g_up_stage.data();
        // Parallel fill: the repack is pure per-tile word reversal, independent across
        // experts, and single-threaded it DOMINATES model load (~100 ms/layer at E=256
        // 2bit - t44_upload phase timings). Half the cores: registration runs alongside
        // the still-loading parent, and the copy below is wire-bound anyway.
        const unsigned hc = std::thread::hardware_concurrency();
        const int nthr = (int)std::max(1u, std::min<unsigned>(hc / 2, (unsigned)n_sub));
        std::atomic<int> bad{0};
        std::vector<std::thread> thr;
        thr.reserve((size_t)nthr);
        for (int t = 0; t < nthr; ++t)
            thr.emplace_back([&, t]{   // t BY VALUE (by-reference capture = every thread
                for (int e = t; e < n_sub && !bad.load(std::memory_order_relaxed); e += nthr)   // reads the racing loop var
                    if (!fill_block(stage + (size_t)e * u->block, *u, src, e, k2)) bad.store(1);
            });
        for (auto& th : thr) th.join();
        if (bad.load()) throw std::runtime_error("expert weights missing in arena sources");
        // ONE contiguous H2D pass for the whole layer (the only queue op of a fill; the
        // in-order queue + .wait keep it fully ordered against concurrent forwards)
        g.q->memcpy(u->arena, stage, u->arena_bytes).wait();
    } catch (const std::exception& e) {
        fprintf(stderr, "[b70moe] registration upload failed: %s; layer stays on CPU\n", e.what());
        g.dev_full = true;
        rollback_upload(u);
        g.uploads.pop_back();
        delete u;
        return -1;
    }
    for (int e = 0; e < n_sub; ++e) {
        if (gated) gs[e] = ms_at(*u, src[0], e, e, 0);
        us[e] = ms_at(*u, src[1], e, e, 1);
        ds[e] = ms_at(*u, src[2], e, e, 2);
    }
    // non-members share block 0: a stray chunk would read finite weights instead of
    // unmapped memory, and the table stays dense (zero kernel-side changes)
    for (int e = n_sub; e < E; ++e) { gs[e] = gs[0]; us[e] = us[0]; ds[e] = ds[0]; }
    moe_sycl::LayerParams p;
    p.num_experts = E; p.hidden = H; p.interm = I; p.bits = bits; p.hb = hb;
    p.activation = activation; p.act_limit = act_limit; p.gated = gated != 0;
    auto* layer = new moe_sycl::MoeSyclLayer();
    layer->init(g.q, p, gs, us, ds);
    g.by_layer[(const void*)(intptr_t)layer] = u;
    fprintf(stderr, "[b70moe] registered layer: E %d (B70 tier %d), B70 weights so far %.2f GB, pool %.1f MB\n",
            E, n_sub, g_alloc_bytes / 1e9, moe_sycl::g_ws_bytes / 1e6);
    // budget gate is WEIGHTS-only by design (g_ws_bytes pool excluded): a large-prefill
    // workspace peak (~1-2 GB at EXL3_MOE_CPU_SLOT_ROWS=256) must not starve runtime
    // installs; physical headroom comes from the budget fraction itself
    // pre-size for typical handoff geometries. MODERATE on purpose: this runs UNDER the
    // whole weight set (registration), and the warm primes the SHARED pool to the warm's
    // chunk count - at (2048,1024) that inflated the pool ~1.2 GB before the last layers
    // registered, and on the widest slices the first real-job pool grow then collided with
    // near-full VRAM (failed forward -> mid-job pin -> wedged staging ring). Larger jobs
    // still grow the pool on demand through ensure_ws (now a clean throw, see below).
    b70_warm((int64_t)(intptr_t)layer, 512, 512);
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
        rollback_upload(u);
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
        rollback_upload(u);
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
    const bool int8 = layer->pick_int8(rows);
    // width cap follows the tier the forward will take: the fp32 GemvK has exactly 4
    // accumulator chains, the DPAS tier carries MOE_MAXM tokens in I8_FRAGS m8 fragments
    const int mcap = moe_sycl::int8_mcap_pick(int8, rows, rows * topk, E);
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
            }
            chunks.push_back(ch);
        }
    }
    // Bucket by fragment fill BEFORE the token map is built: the entry encoding carries the
    // chunk index, so the order the device sees is part of the contract (see
    // moe_bucket_chunks). float-tier chunks are all narrow, so this is int8-only by nature.
    if (int8) moe_sycl::moe_bucket_chunks(chunks);
    for (int j = 0; j < (int)chunks.size(); ++j)
        for (int r = 0; r < chunks[j].m; ++r)
            tokentries[chunks[j].token[r]].push_back(j * moe_sycl::MOE_MAXM + r);
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
    // bounded completion: a kernel wedged on a dead context must not strand the worker
    // thread holding exec_mu (parent would spin on the job's done flag forever).
    // sycl::event has no timed wait in DPC++ - poll with a deadline.
    {
        static const int wait_mode = []{
            const char* e = getenv("EXL3_MOE_B70_WAIT");   // =1: event .wait() instead of poll (lab)
            return e && e[0] == '1';
        }();
        if (!wait_mode) {
            const auto t0 = std::chrono::steady_clock::now();
            const auto dl = t0 + std::chrono::milliseconds(15000);
            while (e_rd.get_info<sycl::info::event::command_execution_status>()
                   != sycl::info::event_command_status::complete)
            {
                if (std::chrono::steady_clock::now() > dl)
                {
                    g.poison.store(true);
                    throw std::runtime_error("b70 forward completion timeout (device wedged)");
                }
                // Bounded, but WAKE-FIRST: pure sleep-polling cost ~70us per decode job
                // on this box (measured: median 183 vs 108 with event .wait() - the status
                // query can lag completion by a whole sleep quantum and EVERY layer job
                // pays it). Busy-yield for the first ~1 ms (the worker thread has nothing
                // else to do while a decode-shape job runs), then sleep so huge prefill
                // jobs do not burn a core. Deadline/poison semantics unchanged.
                const auto age = std::chrono::steady_clock::now() - t0;
                if (age < std::chrono::milliseconds(1))
                    std::this_thread::yield();
                else if (age < std::chrono::milliseconds(5))
                    std::this_thread::sleep_for(std::chrono::microseconds(100));
                else
                    std::this_thread::sleep_for(std::chrono::microseconds(500));
            }
        } else {
            e_rd.wait();
        }
    }
    memcpy(out, g_stage.stage, (size_t)rows * H * 4);
    g_last_ev = e_rd;
    if (moe_sycl::alog()) moe_sycl::alog_msg("FWD exit h %lld rows %d nc %d", (long long)handle, rows, (int)chunks.size());
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
    const int k2 = 2 * p.bits + p.hb;
    // the thirteen pointer arrays carry ONE expert (index 0); e selects the ARENA BLOCK.
    // The block fills in host staging first, so the device changes only via ONE in-place
    // memcpy: no free, no realloc, no budget motion, and a fill failure keeps the previous
    // weights byte-intact (the old path could leave a half-installed mix of old/new).
    const CatSrc src[3] = {
        CatSrc{ gate_trellis, gate_suh, gate_svh, gate_bias },
        CatSrc{ up_trellis,   up_suh,   up_svh,   up_bias   },
        CatSrc{ down_trellis, down_suh, down_svh, down_bias },
    };
    try {
        if (g_up_stage.size() < u->block) g_up_stage.resize(u->block);
        char* stage = (char*)g_up_stage.data();
        if (!fill_block(stage, *u, src, 0, k2)) return 1;   // incomplete source: keep old weights
        g.q->memcpy(u->arena + (size_t)e * u->block, stage, u->block).wait();
        // data pointers are UNCHANGED by the in-place overwrite; only BIAS presence can
        // toggle with the new tensors, so just republish the table rows (cheap, idempotent)
        for (int c = (u->gated ? 0 : 1); c < 3; ++c)
            layer->update_expert(c, e, ms_at(*u, src[c], 0, e, c));
        if (moe_sycl::alog()) moe_sycl::alog_msg("UPD ok h %lld e %d block %zu", (long long)handle, e, u->block);
        return 0;
    } catch (const std::exception& ex) {
        fprintf(stderr, "[b70moe] expert update threw: %s\n", ex.what());
        return 1;
    }
}

} // extern "C"
