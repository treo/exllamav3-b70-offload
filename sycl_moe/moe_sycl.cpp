// SYCL MoE expert forward implementation. Mirrors the fp/scalar semantics of
// exllamav3/exllamav3_ext/cpu/moe_mul1.cpp: prep (suh + block hadamard) -> GEMV over packed
// mul1 tiles -> out transform (hadamard + svh + bias) -> activation -> down GEMV -> weighted
// gather.
//
// All control data (chunks, token CSR) travels in ONE host->device blob memcpy. Every kernel
// is chained with explicit depends_on events (required on this L0 stack: NOTES, and
// archive/platform-pitfalls.md P1).
// GEMV: work group = (chunk, matrix, 128-column block); each 16-lane sub-group owns one
// 16x16 tile column strip; packed tile words are staged through shared memory, double
// buffered over k.
#include "moe_sycl.hpp"
#include <sycl/ext/intel/experimental/cache_control_properties.hpp>
#include <sycl/ext/oneapi/experimental/annotated_ptr/annotated_ptr.hpp>
namespace expe = sycl::ext::oneapi::experimental;
namespace inte = sycl::ext::intel::experimental;
#ifdef MOE_GEMV_CACHEHINT
// weights are read exactly once per gemv: stream through L1/L2
inline constexpr auto g_read_hint = inte::read_hint<inte::cache_control<
    inte::cache_mode::streaming, expe::cache_level::L1, expe::cache_level::L2>>;
using AP_W = expe::annotated_ptr<const uint32_t, decltype(expe::properties{g_read_hint})>;
#endif
#include <cmath>
#include <cstdarg>
#include <cstdio>
#include <ctime>
#include <cstdlib>
#include <cstring>
#include <stdexcept>
#include <unistd.h>
#include <sys/time.h>

namespace moe_sycl {

size_t g_alloc_bytes = 0;
size_t g_ws_bytes = 0;   // see moe_sycl.hpp: pool bytes are physical but not budget-bearing

// ---- fault-attribution log (see hpp): USM map + per-forward geometry for the
// DEVICE_LOST-at-large-cap_rows investigation. All records wall-clock stamped so they
// bracket the xe driver "Faulted Address" lines from journalctl -k.
FILE* alog()
{
    static FILE* f = []{
        const char* p = std::getenv("EXL3_MOE_B70_ALLOCLOG");
        if (!p || !*p) return (FILE*)nullptr;
        FILE* r = fopen(p, "ae");
        if (!r) fprintf(stderr, "[b70moe] alloclog: cannot open %s\n", p);
        return r;
    }();
    return f;
}

void alog_msg(const char* fmt, ...)
{
    FILE* f = alog();
    if (!f) return;
    struct timeval tv; gettimeofday(&tv, nullptr);
    fprintf(f, "%ld.%06ld %d ", (long)tv.tv_sec, (long)tv.tv_usec, (int)getpid());
    va_list ap; va_start(ap, fmt);
    vfprintf(f, fmt, ap);
    va_end(ap);
    fputc('\n', f);
    fflush(f);
}

namespace {

// Host-side submission profiler (EXL3_MOE_B70_HOSTPROF=1). HOST code only - no in-kernel state
// (NOTES verification rule 3) and no device-visible effect when off. It answers the question the
// --v spans can only imply: what is the submitting thread doing while the device sits idle?
// Per stage (ordinal: 0 = job-blob H2D, then one per launch in submit order) it accumulates
//   gap = host time from the previous stage's end to this stage's submit start,
//   sub = duration of the submit/memcpy CALL itself.
// Means print every 256 forwards; the gettimeofday pair costs ~1-2 us per stage, so these numbers
// are diagnostic, not an A/B result. (Original version reset `mark` but not `idx` in begin(), so
// only the first ~2 forwards of the first window ever accumulated and every later window printed
// nothing - which read as "submits are free" and was used to reject command graphs. `n` and the
// always-printed totals are here so that class of silence cannot recur.)
struct HostProf
{
    static double now_us()
    { struct timeval tv; gettimeofday(&tv, nullptr); return tv.tv_sec * 1e6 + tv.tv_usec; }
    // Per-stage host attribution of ONE forward, in submission order, KEPT SEPARATE PER JOB CLASS.
    // "pre" = host work before the region starts (prologue logic, blob packing, whatever runs
    // between two submits); "enq" = the queue call itself. Classes matter: a decode job (rows=1,
    // float tier) and a prefill job (rows>1, int8 tier) issue DIFFERENT launch sequences, and with
    // one shared slot array stage 2 of a prefill forward silently inherits the label of stage 2 of
    // a decode forward - which is exactly how an early cut of this instrument billed 15 us to
    // "K1-prep" for a kernel that costs 5 us.
    static constexpr int NSLOT = 14, NCLS = 3;
    static const char* cls_name(int c) { return c == 0 ? "decode-float" : c == 1 ? "int8" : "rows>1-float"; }
    // Per stage we separate THREE numbers: "pre" (host work before the region), "enq" (the whole
    // queue call) and "body" (the part of it that is OUR handler lambda, i.e. accessor creation +
    // cgh.parallel_for, which the runtime invokes synchronously inside submit). enq-body is what
    // the runtime's own bookkeeping costs; a stage whose cost is all "body" is a marshalling or
    // dispatch cost of THAT kernel, not a queue cost.
    double mark = 0.0, gap[NCLS][NSLOT] = {}, sub[NCLS][NSLOT] = {}, tailv[NCLS] = {};
    double body[NCLS][NSLOT] = {};
    double bmark = 0.0;
    // MIN per stage per window. The MEAN alone proved unusable for attribution: the same binary
    // reported prologue 0.7 us in one 256-forward window and 5.7 us in another, and K1 anywhere from
    // 5.3 to 17.3, while the per-forward total held at 30-34 us. A handful of preemption-length
    // samples moves a mean by microseconds; the minimum over a window is what EVERY layer job
    // demonstrably pays, so quote min when arguing where the fixed cost sits and mean when adding up.
    double smin[NCLS][NSLOT];
    // MAX and a >10us counter per stage, next to min and mean. Together they are what turned this
    // instrument from a liar into an answer: K1-prep reads min 5.0 / mean 13.8, which is not a stage
    // that costs 14 us - it is a stage that usually costs 5 and sometimes costs a lot. Mean alone
    // hid that; min+mean alone only hinted at it.
    double smax[NCLS][NSLOT];
    unsigned slowcnt[NCLS][NSLOT];
    HostProf() { reset_windows(); }
    const char* lbl[NCLS][NSLOT] = {};
    int idx = 0, cls = 0, n = 0, nsamp[NCLS] = {}, stages[NCLS] = {};
    static HostProf& me() { static HostProf h; return h; }
    void begin(int c) { mark = now_us(); idx = 0; cls = c; ++n; ++nsamp[c]; }
    void reset_windows()
    { for (int c = 0; c < NCLS; ++c) for (int i = 0; i < NSLOT; ++i)
      { smin[c][i] = 1e30; smax[c][i] = 0.0; slowcnt[c][i] = 0u; } }
    double start_region(const char* nm = nullptr)
    { const double t = now_us(); if (idx < NSLOT) { gap[cls][idx] += t - mark;
                                                    if (nm && !lbl[cls][idx]) lbl[cls][idx] = nm; }
      return t; }
    void end_region(double t0)
    { const double t = now_us();
      if (idx < NSLOT) { const double d = t - t0; sub[cls][idx] += d;
                         if (d < smin[cls][idx]) smin[cls][idx] = d;
                         if (d > smax[cls][idx]) smax[cls][idx] = d;
                         if (d > 10.0) ++slowcnt[cls][idx]; }
      mark = t; ++idx; }
    void body_begin() { bmark = now_us(); }
    void body_end() { if (idx > 0 && idx <= NSLOT) body[cls][idx - 1] += now_us() - bmark; }
    void end()
    {
        stages[cls] = std::max(stages[cls], idx);
        tailv[cls] += now_us() - mark;
        if ((n % 256) != 0) return;
        for (int c = 0; c < NCLS; ++c)
        {
            if (!nsamp[c]) continue;
            double tg = 0.0, ts = 0.0;
            printf(" -- hostprof[%s] (%d fwd; per stage pre|enqueue us):", cls_name(c), nsamp[c]);
            for (int i = 0; i < NSLOT; ++i)
            {
                if (sub[c][i] + gap[c][i] <= 0.0) continue;
                tg += gap[c][i]; ts += sub[c][i];
                printf(" [%d %s mean %.2f min %.2f|max %.0f|slow %u]", i, lbl[c][i] ? lbl[c][i] : "-",
                       sub[c][i] / nsamp[c], smin[c][i] > 1e29 ? 0.0 : smin[c][i],
                       smax[c][i], slowcnt[c][i]);
            }
            printf("  || pre %.2f + enqueue %.2f + tail %.2f = host %.2f us/fwd (%d stages)\n",
                   tg / nsamp[c], ts / nsamp[c], tailv[c] / nsamp[c],
                   (tg + ts + tailv[c]) / nsamp[c], stages[c]);
            fflush(stdout);
            for (int i = 0; i < NSLOT; ++i)
            { gap[c][i] = sub[c][i] = body[c][i] = 0.0; lbl[c][i] = nullptr; smin[c][i] = 1e30;
              smax[c][i] = 0.0; slowcnt[c][i] = 0u; }
            tailv[c] = 0.0; nsamp[c] = 0; stages[c] = 0;
        }
    }
};
struct HpScope
{
    const bool on;
    ~HpScope() { if (on) HostProf::me().end(); }
};

} // namespace

namespace {

constexpr float KDQ = 0.00676727294921875f;   // k_inv = fp16(0x1eee)
constexpr float HAD_SCALE = 0.088388347648f;  // 1/sqrt(128)
// All int8 operand geometry derives from MOE_MAXM in moe_sycl.hpp (wide-M block): MAXM aliases
// it for the fp32-tier layout maths, I8R is the rows-per-gemv-slot stride, I8_A8BLK the a8
// words per (slot, k/8) block, I8_ROWPAIRS the fused-quant WGs per slot. Do NOT re-hardcode
// 8/16/128 here: a wide-M experiment must be a one-line change in the header.
constexpr int MAXM = MOE_MAXM;
constexpr int I8_FRAG_WORDS = I8_ROWS_PER_FRAG * I8_A8W;          // i32 per fragment slab (64)
constexpr int I8_FRAG_BYTES = I8_FRAG_WORDS * 4;                  // bytes per fragment slab
constexpr int I8_RING_TILE_BYTES = I8_KSLABS * I8_A8BLK * 4;      // bytes per k tile in the A ring
constexpr int I8_RING_BYTES = 4 * I8_RING_TILE_BYTES;             // 4-tile rotation region
constexpr int I8_RING_HALFW = 2 * I8_KSLABS * I8_A8BLK / 4;       // uint4 words per half region
constexpr int I8_BAND_BYTES  = 1024;   // one ping-pong packed-B band (2 x 512 B fk sub-bands)
constexpr int I8_SLAB_SUB    = 2 * I8_BAND_BYTES;                 // SLM bytes per sub-group
constexpr int I8_RING_REGIONS = 4;     // rotating A regions (reads trail writes by 2)
constexpr int I8_SLM_BYTES   = 8 * I8_SLAB_SUB + I8_RING_REGIONS * I8_RING_BYTES;

// pointer table categories (d_tab): layout [field][cat][expert]
enum { CAT_GATE = 0, CAT_UP = 1, CAT_DOWN = 2 };
enum { F_TRI = 0, F_SUH = 1, F_SVH = 2, F_BIAS = 3 };

inline float f16(uint16_t h)
{
    _Float16 f;
    std::memcpy(&f, &h, 2);
    return (float)f;
}

// 128-wide sequentia hadamard in shared memory, same op order as the CPU scalar butterfly
template <typename Item>
inline void hadamard128(Item& it, int tid, sycl::local_ptr<float> v)
{
    for (int width = 1; width < 128; width *= 2) {
        sycl::group_barrier(it.get_group());
        if (tid < 64) {
            const int base = (tid / width) * 2 * width + (tid % width);
            const float a = v[base], b = v[base + width];
            v[base] = a + b;
            v[base + width] = a - b;
        }
    }
    sycl::group_barrier(it.get_group());
}

// L1-bypass scalar load for data another WORK-GROUP wrote EARLIER IN THE SAME LAUNCH.
// Xe2 L1 is per-slice and NOT coherent: after an arrival-counter edge the data is certain
// in L2, but a stale line in THIS slice's L1 would still be served by a normal load (the
// counter's acquire covers ordering, not L1 freshness). ATOMIC_REF relaxed@device is the
// form that demonstrably resolves in L2 on this stack - the annotated_ptr read_hint
// spelling was tried FIRST and is INEFFECTIVE here: the GU+D fused pipeline reproduced a
// byte-exact previous-forward `out` under alternating datasets (the reader slice kept the
// earlier forward's tsw lines in L1; only the extra K34 kernel between launches in the
// split pipeline evicted them, which is why each fusion ALONE passed). NB a static-data
// bench CANNOT see this class of bug (stale bytes == correct bytes) - always stress with
// --alt.
template <typename T>
inline T coop_load(const T* p)
{
    sycl::atomic_ref<T, sycl::memory_order::relaxed, sycl::memory_scope::device,
                     sycl::access::address_space::global_space>
        ar(*const_cast<T*>(p));
    return ar.load(sycl::memory_order::relaxed);
}

// Barrier-free 128-point sequentia hadamard in ONE 16-lane sub-group, strided
// distribution v[p] = value at index 16p+lane. Widths 1,2,4,8 pair indices whose low
// (lane) bits differ -> sub-group shuffles (xor 1,2,4,8); widths 16,32,64 pair indices
// whose HIGH (slot) bits differ -> in-register slot xors. The level ORDER of the SLM
// version (width 1..64 sequentially) is preserved and every pair executes the same
// (a+b, a-b) ops on the same operands, so results are BIT-IDENTICAL to hadamard128 -
// verified by the fused-down pipeline printing byte-identical check/rms vs the host
// reference (1.740e-06 / 1.134e-06 at the default seed) while dropping 8 group barriers
// per transformed row.
static inline void had128_strided(sycl::sub_group sg, float v[8])
{
    const int ln = (int)sg.get_local_linear_id();
#pragma unroll
    for (int bit = 1; bit <= 8; bit <<= 1) {
        float o[8];
#pragma unroll
        for (int p = 0; p < 8; ++p) o[p] = sycl::select_from_group(sg, v[p], ln ^ bit);
#pragma unroll
        for (int p = 0; p < 8; ++p) v[p] = (ln & bit) ? (o[p] - v[p]) : (v[p] + o[p]);
    }
#pragma unroll
    for (int bit = 1; bit <= 4; bit <<= 1) {
        float o[8];
#pragma unroll
        for (int p = 0; p < 8; ++p) o[p] = v[p ^ bit];
#pragma unroll
        for (int p = 0; p < 8; ++p) v[p] = (p & bit) ? (o[p] - v[p]) : (v[p] + o[p]);
    }
}

} // namespace

// ------------------------------------------------------------------ lifecycle

void MoeSyclLayer::init(sycl::queue* q, const LayerParams& p,
                        const std::vector<MatrixSrc>& gates,
                        const std::vector<MatrixSrc>& ups,
                        const std::vector<MatrixSrc>& downs)
{
    Q = q;
    P = p;
    const int E = P.num_experts;
    std::vector<uintptr_t> tab((size_t)4 * 3 * E, 0);
    const std::vector<MatrixSrc>* by_cat[3] = { &gates, &ups, &downs };
    for (int c = 0; c < 3; ++c)
        for (int e = 0; e < E; ++e) {
            const MatrixSrc& m = (*by_cat[c])[e];
            tab[((F_TRI * 3 + c) * E) + e]  = (uintptr_t)m.trellis;
            tab[((F_SUH * 3 + c) * E) + e]  = (uintptr_t)m.suh;
            tab[((F_SVH * 3 + c) * E) + e]  = (uintptr_t)m.svh;
            tab[((F_BIAS * 3 + c) * E) + e] = (uintptr_t)m.bias;
        }
    nsl = getenv("MOE_NSL") ? atoi(getenv("MOE_NSL")) : 0;  // 0 = auto per matrix class
    const int k2 = 2 * p.bits + p.hb;
    // DPAS tier: stream-layout window decode is instantiated for the CONTRACT rates
    // (moe_k2_dpas; geometry divisibility - tiles of 16, k-frags of 8 - holds for the
    // Qwen3.8-Flash-Next shapes H 2560, I 640). The product-word identity and the t29
    // stream windows are rate-agnostic: this gate is instantiation coverage, and the
    // list is single-sourced with the trace harness (see hpp 'bitrate contract').
    int8_ok = moe_k2_dpas(k2) && (p.hidden % 16 == 0) && (p.interm % 16 == 0)
              && (p.hidden % 8 == 0) && (p.interm % 8 == 0);
    nm_ws_ = p.gated ? 2 : 1;
    d_tab = sycl::malloc_device<uintptr_t>(tab.size(), *q);
    MOE_ALOG_ALLOC(d_tab, tab.size() * sizeof(uintptr_t), "d_tab");
    q->memcpy(d_tab, tab.data(), tab.size() * sizeof(uintptr_t)).wait();
}

// Swap-in for dynamic placement (see hpp): four table entries, one small async memcpy each,
// waited before return. Jobs must be quiesced; the next forward's table load sees the new
// pointers (d_tab is read at kernel time, never cached host-side).
void MoeSyclLayer::update_expert(int cat, int e, const MatrixSrc& m)
{
    const int E = P.num_experts;
    const uintptr_t ent[4] = { (uintptr_t)m.trellis, (uintptr_t)m.suh,
                               (uintptr_t)m.svh, (uintptr_t)m.bias };
    for (int f = 0; f < 4; ++f)
        Q->memcpy(d_tab + ((f * 3 + cat) * E) + e, &ent[f], sizeof(uintptr_t));
    Q->wait();
}

MoeSyclLayer::~MoeSyclLayer()
{
    auto freep = [&](auto*& p) { if (p) { sycl::free(p, *Q); p = nullptr; } };
    freep(d_tab);
    freep(coop_dbg_buf);
    freep(w_chunk);   // scratch buffers belong to the process-wide pool
}

// Process-wide workspace pool: the worker forwards one layer at a time, so all layers share
// one set of scratch buffers (per-layer ws blew the B70 budget: 31 layers x ~600 MB).
// Slots 0..4 float tier, 5..10 int8 tier (a8u a8d qsxu qsxd accgu accd).
namespace {
struct WsPool { void* buf[12] = {}; size_t cap[12] = {}; };
WsPool g_ws;
}

void MoeSyclLayer::ensure_ws(int nc, int rows)
{
    if (getenv("EXL3_MOE_WSDBG")) {
        static bool done_once = false;
        if (!done_once) {
            done_once = true;
            fprintf(stderr, "[wsdbg] caps:");
            for (int i = 0; i < 12; ++i) fprintf(stderr, " %zu", g_ws.cap[i]);
            fprintf(stderr, "\n[wsdbg] ptrs:\n");
            for (int i = 0; i < 12; ++i) fprintf(stderr, "  [%d] %p\n", i, g_ws.buf[i]);
            for (int i = 0; i < 12; ++i) for (int j = i + 1; j < 12; ++j)
                if (g_ws.buf[i] && g_ws.buf[j]) {
                    char* a = (char*)g_ws.buf[i]; char* b = (char*)g_ws.buf[j];
                    size_t ba = g_ws.cap[i] * 4, bb = g_ws.cap[j] * 4;   // caps in floats? slots hold mixed types - print raw span overlap by address only
                    if (a < b ? (a + 1 < b) : (b + 1 < a)) {} // noop
                    (void)a; (void)b; (void)ba; (void)bb;
                }
        }
    }
    auto grow_p = [&](int slot, auto*& p, size_t count) {
        using T = std::remove_pointer_t<std::remove_reference_t<decltype(p)>>;
        if (count == 0) { p = nullptr; return; }   // zero-size job: not an OOM (malloc(0)->null)
        if (g_ws.buf[slot] && count <= g_ws.cap[slot]) { p = (T*)g_ws.buf[slot]; return; }
        if (g_ws.buf[slot]) { MOE_ALOG_FREE(g_ws.buf[slot], g_ws.cap[slot] * sizeof(T), "pool"); sycl::free(g_ws.buf[slot], *Q); g_ws_bytes -= g_ws.cap[slot] * sizeof(T); }
        T* np = sycl::malloc_device<T>(count, *Q);
        MOE_ALOG_ALLOC(np, count * sizeof(T), "pool");
        alog_msg("   pool-slot %d count %zu x %zu B", slot, count, sizeof(T));
        if (!np)
        {
            fprintf(stderr, "[b70moe] OOM workspace alloc %zu x %zu\n", count, sizeof(T));
            throw std::runtime_error("b70 workspace OOM");   // caught by b70_forward/_layer: clean pin, never a null-deref device fault
        }
        g_ws.buf[slot] = np;
        g_ws.cap[slot] = np ? count : 0;
        g_ws_bytes += np ? count * sizeof(T) : 0;
        p = np;
        if (!p) return;
        // prefault so device page tables are populated before the kernel pipeline runs
        Q->memset(p, 0, count * sizeof(T));
        Q->wait();
    };
    // ⚠ ALWAYS call grow_p for EVERY slot on EVERY forward - never gate on this layer's
    // cap_nc. THE POOL IS PROCESS-WIDE: another layer growing a slot FREES the buffer this
    // layer's member pointers point at, so a skipped rebind leaves them DANGLING and the
    // next (smaller!) job reads/writes freed device memory. Root cause of the
    // "DEVICE_LOST / forward failed; layer pinned to CPU" bug at EXL3_MOE_CPU_SLOT_ROWS=512
    // (fault forensics 2026-10-27: kernels walked the first 400KB of a freed 335MB toutd
    // 10s after a 521-chunk job of ANOTHER layer grew the pool). grow_p with count<=cap is
    // a pure pointer rebind - exactly what staleness needs. The int8 slots below were
    // always uncondional, which is why only float-tier jobs faulted.
    // Step the growth: size for nc rounded up to 64 chunks. Pool sizes are LINEAR in nc,
    // so without this every new nc high-water mark (341 -> 405 -> 417 -> 521 ...) frees and
    // re-prefaults up to ~335 MB; with it a run typically sees ONE grow per slot. Bounded
    // waste (<= 64 chunks ~ 120 MB across all slots), and deliberately NOT a startup
    // worst-case reservation: the naive nc bound (rows*topk under skew) is ~11 GB of pool
    // at SLOT_ROWS=512, which would evict half the resident weights - see
    // archive/memory-and-registration.md (warm-pool inflation / STALE POOL POINTER).
    const int ncg = (nc + 63) & ~63;
    grow_p(0, w_tin,   (size_t)ncg * 2 * MAXM * P.hidden);
    grow_p(1, w_tout,  (size_t)ncg * 2 * MOE_NSL_MAX * MAXM * P.interm);
    grow_p(2, w_h,     (size_t)ncg * MAXM * P.interm);
    grow_p(3, w_tind,  (size_t)ncg * MAXM * P.interm);
    grow_p(4, w_toutd, (size_t)ncg * MOE_NSL_MAX * MAXM * P.hidden);
    if (coop_) grow_p(11, w_tsw, (size_t)ncg * MAXM * P.hidden);   // fused-down staging (float coop)
    if (nc > cap_nc) cap_nc = nc;
    // int8 slabs: grow_p no-ops when the existing cap already fits; sizing must happen on
    // EVERY nc/nsl combination the layer may see (warm batches use nsl=1, decode up to 8).
    if (use8_) {
        grow_p(5, w_a8u,   (size_t)ncg * nm_ws_ * (P.hidden / I8_A8W) * I8_A8BLK);
        grow_p(6, w_a8d,   (size_t)ncg * (P.interm / I8_A8W) * I8_A8BLK);
        grow_p(7, w_qsxu,  (size_t)ncg * nm_ws_ * I8R * 2);
        grow_p(8, w_qsxd,  (size_t)ncg * I8R * 2);
        grow_p(9, w_accgu, (size_t)ncg * nm_ws_ * I8R * P.interm * nsl8_gu_);
        grow_p(10, w_accd, (size_t)ncg * I8R * P.hidden * nsl8_d_);
        if (nc > cap_nc8) cap_nc8 = nc;
    }
    (void)rows;
}

// ------------------------------------------------------------------ gemv functor
//
// K2 = 2*bits+hb as a compile-time constant (0 = runtime fallback). One lane owns one
// output column; its 16 per-row ring addresses are computed once into apack (2x24-bit
// entries per u64; anything with a dynamic index spills and tanks perf).

struct GemvBase
{
    static constexpr int MAXM_ = 4;
    const uintptr_t* tab;
    const ChunkDev* chunks;
    const float *tin, *tind;
    float *tout, *toutd;
    int E, nc, nm, H, I, nbk, tiles_n, tiles_k, gated, down;
    int nsl;                 // k-slices per unit
    int ncwg = 128;          // columns per workgroup (nbk = N/ncwg); 128 == the classic geometry
};

// Pull a job blob from PINNED HOST memory into device memory on the compute engine, so a decode
// forward can issue NO memory command at all. Used only by EXL3_MOE_B70_BLOB_BY_KERNEL=1; see the
// call site for why (the tail lives behind the copy, not in the kernel that follows it). Reads over
// PCIe are the same mechanism the arena uploader already uses, and the blob is a few hundred bytes
// at rows=1, so the device-side cost is a handful of 16 B loads.
struct BlobPull
{
    const sycl::uint4* src;
    sycl::uint4* dst;
    int n;                       // 16-byte words (caller over-allocates both sides by 16 B)
    void operator()(sycl::item<1> i) const
    {
        const size_t k = i.get_id(0);
        if ((int)k < n) dst[k] = src[k];
    }
};

template <int K2V, bool MMA>
struct GemvK
{
    // Column-window GEMV on the stream-repacked layout (see moe_sycl.hpp repack note):
    // state(rk, cin) = 16 ascending bits at P0 - adv(tmin+d(rk)); each lane loads the NW
    // words covering its column's 16 windows once per k-step, builds a pre-shifted bit
    // stream and extracts with compile-time shifts and pair selections only.
    GemvBase b;

    // Xe2: prefer 16-lane subgroups (2x GRF per lane for the load pipeline); IGC's
    // auto pick lands on SIMD32 otherwise. Override with MOE_SG32=1 to A/B.
    auto get(sycl::ext::oneapi::experimental::properties_tag) const
    {
#ifdef MOE_SG32
        return sycl::ext::oneapi::experimental::properties{};
#else
        return sycl::ext::oneapi::experimental::properties{
            sycl::ext::oneapi::experimental::sub_group_size<16>};
#endif
    }

    static constexpr int W = 4 * K2V;
    static constexpr int KE = K2V & 1;
    static constexpr int AD27 = (27 * K2V + KE) >> 1;
    static constexpr int NW = (AD27 + 16 + 31 + 31) / 32 + 1;

    void operator()(sycl::nd_item<1> it) const
    {
        const int unit = (int)it.get_group(0);
        const int tid = (int)it.get_local_id(0);
        const int sl = unit % b.nsl;
        const int ub = unit / b.nsl;
        const int blk = ub % b.nbk;
        const int jmu = ub / b.nbk;
        const bool down = b.down != 0;
        const int j = down ? jmu : jmu / b.nm;
        const int lmu = down ? CAT_DOWN : jmu % b.nm;
        const int cat = down ? CAT_DOWN : (b.gated ? lmu : CAT_UP);
        const int mu = down ? 0 : (b.gated ? lmu : 0);
        const int e = b.chunks[j].expert;
        const int m = b.chunks[j].m;
        const uint32_t* w32 = (const uint32_t*)(uintptr_t)b.tab[(F_TRI * 3 + cat) * b.E + e];
        const float* src_tin = down ? b.tind + (size_t)j * MAXM * b.I
                                    : b.tin + ((size_t)(j * 2 + mu) * MAXM) * b.H;
        const int K = down ? b.I : b.H;
        const int N = down ? b.H : b.I;

        const int cG = blk * b.ncwg + tid;      // ncwg==128 reproduces the classic geometry
        const int tile_n = cG >> 4, cin = cG & 15;
        const int A2 = (K2V * (32 * (cin & 7) + 4 * ((cin >> 3) & 1))) >> 1;
        const int G = (32 - (K2V >> 1)) - A2 - AD27;
        const int wb = G >> 5;
        const int pre = G - (wb << 5);
        int widx[NW];
#pragma unroll
        for (int i = 0; i < NW; ++i) widx[i] = ((wb + i) % W + W) % W;

        float acc0 = 0, acc1 = 0, acc2 = 0, acc3 = 0;
        float accB0 = 0, accB1 = 0, accB2 = 0, accB3 = 0;
        const size_t row_step = moe_stream_row_step((size_t)W, b.tiles_n);
        const int tk_lo = (b.tiles_k * sl) / b.nsl;
        const int tk_hi = (b.tiles_k * (sl + 1)) / b.nsl;
        const uint32_t* wp = w32 + (size_t)tile_n * moe_stream_col_span((size_t)W, b.tiles_k)
                                 + (size_t)tk_lo * row_step;
        const float* tp = src_tin + tk_lo * 16;
        // depth-2 software pipeline: the next tile's NW row words are loaded before the
        // current tile's 16 state decodes run, doubling outstanding memory requests/thread
        uint32_t g[NW], gn[NW];
#ifdef MOE_GEMV_CACHEHINT
        { AP_W ap(wp);
#pragma unroll
          for (int i = 0; i < NW; ++i) g[i] = *(ap + widx[i]); }
#else
#pragma unroll
        for (int i = 0; i < NW; ++i) g[i] = wp[widx[i]];
#endif
        for (int tk = tk_lo; tk < tk_hi; ++tk, wp += row_step, tp += 16) {
#ifdef MOE_GEMV_CACHEHINT
            if (tk + 1 < tk_hi) { AP_W ap(wp + row_step);
#pragma unroll
              for (int i = 0; i < NW; ++i) gn[i] = *(ap + widx[i]); }
#else
            if (tk + 1 < tk_hi) { const uint32_t* wpn = wp + row_step;
#pragma unroll
              for (int i = 0; i < NW; ++i) gn[i] = wpn[widx[i]]; }
#endif
            uint32_t h[NW];
            if (pre == 0) {
#pragma unroll
                for (int i = 0; i < NW; ++i) h[i] = g[i];
            } else {
#pragma unroll
                for (int i = 0; i + 1 < NW; ++i)
                    h[i] = (g[i] >> pre) | (g[i + 1] << (32 - pre));
                h[NW - 1] = g[NW - 1] >> pre;
            }
#pragma unroll
            for (int rk = 0; rk < 16; ++rk) {
                const int d = 8 * ((rk >> 1) & 3) + (rk & 1) + 2 * ((rk >> 3) & 1);
                const int rel = AD27 - ((K2V * d + KE) >> 1);
                // 32-bit funnel instead of a 64-bit merged shift: ~2.8% off decode gemvs
                // (10-pair A/B); UB-free by construction (no shift ever reaches 32).
                const uint32_t lo4 = h[rel >> 5], hi4 = h[(rel >> 5) + 1];
                const uint32_t st16 = ((lo4 >> (rel & 31)) | ((hi4 << 1) << (31u - (rel & 31)))) & 0xffffu;
                const uint32_t xm = st16 * 0x83DCD12Du;
                const uint32_t t1 = (xm & 0x00ff00ffu) + ((xm >> 8) & 0x00ff00ffu);
                const uint32_t bs = (t1 & 0xffffu) + (t1 >> 16);
                const float wcomb = (float)(int)bs - 510.0f;
                const float* xr = tp + rk;
                // two chains per output row (rk parity) to break the serial-FMA latency.
                // MMA=false (single-slot chunks, i.e. decode) drops the other rows: at m=1
                // they were predicated off but still issued (VTune: ~30% of the loop body).
                if (rk & 1) { accB0 = sycl::fma(wcomb, xr[0], accB0);
                    if (MMA) {
                        if (m > 1) accB1 = sycl::fma(wcomb, xr[K], accB1);
                        if (m > 2) accB2 = sycl::fma(wcomb, xr[2 * K], accB2);
                        if (m > 3) accB3 = sycl::fma(wcomb, xr[3 * K], accB3);
                    }
                } else { acc0 = sycl::fma(wcomb, xr[0], acc0);
                    if (MMA) {
                        if (m > 1) acc1 = sycl::fma(wcomb, xr[K], acc1);
                        if (m > 2) acc2 = sycl::fma(wcomb, xr[2 * K], acc2);
                        if (m > 3) acc3 = sycl::fma(wcomb, xr[3 * K], acc3);
                    }
                }
            }
#pragma unroll
            for (int i = 0; i < NW; ++i) g[i] = gn[i];
        }
        acc0 += accB0;
        float* dst = down ? b.toutd + ((size_t)j * b.nsl + sl) * MAXM * N
                          : b.tout + ((size_t)(j * 2 + mu) * b.nsl + sl) * MAXM * N;
        dst[cG] = acc0 * KDQ;
        if (MMA) {
            acc1 += accB1; acc2 += accB2; acc3 += accB3;
            if (m > 1) dst[N + cG] = acc1 * KDQ;
            if (m > 2) dst[2 * N + cG] = acc2 * KDQ;
            if (m > 3) dst[3 * N + cG] = acc3 * KDQ;
        }
    }
};

// runtime-rate fallback (apack addressing, native layout) for exotic K2
struct GemvFallback
{
    GemvBase b;
    int rt_k2 = 0;

    void operator()(sycl::nd_item<1> it) const
    {
        const int k2 = rt_k2;
        const int tile_u32 = 4 * k2;
        const int unit = (int)it.get_group(0);
        const int tid = (int)it.get_local_id(0);
        const int sl = unit % b.nsl;
        const int ub = unit / b.nsl;
        const int blk = ub % b.nbk;
        const int jmu = ub / b.nbk;
        const int tk_lo = (b.tiles_k * sl) / b.nsl;
        const int tk_hi = (b.tiles_k * (sl + 1)) / b.nsl;
        const bool down = b.down != 0;
        const int j = down ? jmu : jmu / b.nm;
        const int lmu = down ? CAT_DOWN : jmu % b.nm;
        const int cat = down ? CAT_DOWN : (b.gated ? lmu : CAT_UP);
        const int mu = down ? 0 : (b.gated ? lmu : 0);
        const int e = b.chunks[j].expert;
        const int m = b.chunks[j].m;
        const uint32_t* w32 = (const uint32_t*)(uintptr_t)b.tab[(F_TRI * 3 + cat) * b.E + e];
        const float* src_tin = down ? b.tind + (size_t)j * MAXM * b.I
                                    : b.tin + ((size_t)(j * 2 + mu) * MAXM) * b.H;
        const int K = down ? b.I : b.H;
        const int cG = blk * 128 + tid;
        const int tile_n = cG >> 4, cin = cG & 15;
        unsigned long long apack[8] = {0,0,0,0,0,0,0,0};
#pragma unroll
        for (int rk = 0; rk < 16; ++rk) {
            const int bb = ((cin & 7) << 2) | ((rk >> 1) & 3);
            const int jj = (rk & 1) | ((rk & 8) ? 2 : 0) | ((cin & 8) ? 4 : 0);
            const int t = (bb << 3) | jj;
            const int b1 = (((t + 1) * k2) >> 1) + 128 * k2;
            const int b0 = b1 - 16;
            const int w0 = (b0 >> 5) % tile_u32;
            const int w1 = ((b1 - 1) >> 5) % tile_u32;
            const int sh = (((b1 - 1) >> 5) + 1) * 32 - b1;
            apack[rk >> 1] |= (unsigned long long)(w0 | (w1 << 8) | (sh << 16)) << ((rk & 1) * 24);
        }
#define MOE_GETADDR(rkc) ((unsigned)((apack[(rkc) >> 1] >> (((rkc) & 1) * 24)) & 0xffffffu))
        float acc0 = 0, acc1 = 0, acc2 = 0, acc3 = 0;
        const uint32_t* wp = w32 + (size_t)tile_n * moe_stream_col_span(tile_u32, b.tiles_k)
                                 + (size_t)tk_lo * moe_stream_row_step(tile_u32, b.tiles_n);
        const float* tp = src_tin + tk_lo * 16;
        const int tn_stride = (int)moe_stream_row_step(tile_u32, b.tiles_n);
        for (int tk = tk_lo; tk < tk_hi; ++tk, wp += tn_stride, tp += 16) {
#pragma unroll
            for (int rk = 0; rk < 16; ++rk) {
                const unsigned a = MOE_GETADDR(rk);
                const unsigned i0 = (tile_u32 - (a & 0xff)) % tile_u32;
                const unsigned i1 = (tile_u32 - ((a >> 8) & 0xff)) % tile_u32;
                const uint32_t v0 = wp[i0], v1 = wp[i1];
                // sh = 32 - (position of b1 in its word) in 0..31. v1 carries the window top;
                // v0 contributes only when sh > 16 (higher bits are masked away). The
                // (v0<<1)<<(31-sh) form avoids UB at sh == 0. Bit-identical to the 64-bit merge.
                const uint32_t sh = a >> 16;
                const uint32_t st16 = ((v1 >> sh) | ((v0 << 1) << (31u - sh))) & 0xffffu;
                const uint32_t xm = st16 * 0x83DCD12Du;
                const uint32_t t1 = (xm & 0x00ff00ffu) + ((xm >> 8) & 0x00ff00ffu);
                const uint32_t bs = (t1 & 0xffffu) + (t1 >> 16);
                const float wcomb = (float)(int)bs - 510.0f;
                const float* xr = tp + rk;
                acc0 = sycl::fma(wcomb, xr[0], acc0);
                if (m > 1) acc1 = sycl::fma(wcomb, xr[K], acc1);
                if (m > 2) acc2 = sycl::fma(wcomb, xr[2 * K], acc2);
                if (m > 3) acc3 = sycl::fma(wcomb, xr[3 * K], acc3);
            }
        }
#undef MOE_GETADDR
        const int N = down ? b.H : b.I;
        float* dst = down ? b.toutd + ((size_t)j * b.nsl + sl) * MAXM * N
                          : b.tout + ((size_t)(j * 2 + mu) * b.nsl + sl) * MAXM * N;
        dst[cG] = acc0 * KDQ;
        if (m > 1) dst[N + cG] = acc1 * KDQ;
        if (m > 2) dst[2 * N + cG] = acc2 * KDQ;
        if (m > 3) dst[3 * N + cG] = acc3 * KDQ;
    }
};

// ------------------------------------------------------------------ counter-fed fused GU
//
// K2 + K34 in one launch, same doctrine as CoopDownK (see its header comment): every
// (chunk, mu, 128-col blk, slice) WG stores its tout slice exactly like GemvK, publishes,
// and bumps ctrG[(j, blk)]; the LAST arrival of a (j, blk) unit (expected = nm x NSL_GU,
// both projections feed one unit) runs the K34 body INLINE for that 128-column block:
// fixed-order slice sums (coop_load) over both cats, Hadamard+svh+bias transforms,
// activation, fused down-prep (suhd scale + Hadamard), tind store. The block is already
// L2-hot for its owner, K34 disappears as a queue command, and the whole epilogue is
// bit-identical to the split K34 (op order copied verbatim).
// K1 (input prep) stays a separate command for now - folding it in means every WG
// rotates its own x span (bounded redundancy) and constrains NSL_GU to 128-block-aligned
// slices; measured follow-up candidate, keep the pipeline honest first.
template <int K2V, bool MMA>
struct CoopGuK
{
    GemvBase b;                    // gu conventions: tin/tout, tiles_n=I/16, nbk=I/128, nsl=NSL_GU
    int* ctr;
    int* dbg;                        // [0] gu epilogue fires (dbg build only, else null)
    float* tindw;                    // writable tind (GemvBase::tind is const-in)
    int act;
    float lim;
    int lab = 0;                     // EPHEMERAL ablation (EXL3_MOE_B70_COOP_LAB): 1 = arrive
                                     // but skip the K34 epilogue, 2 = skip all coordination
    sycl::local_accessor<float, 1> sh;    // 256: K34's g/u pair + down-prep reuse
    sycl::local_accessor<int, 1> flg;

    auto get(sycl::ext::oneapi::experimental::properties_tag) const
    {
        return sycl::ext::oneapi::experimental::properties{
            sycl::ext::oneapi::experimental::sub_group_size<16>};
    }

    static constexpr int W = 4 * K2V;
    static constexpr int KE = K2V & 1;
    static constexpr int AD27 = (27 * K2V + KE) >> 1;
    static constexpr int NW = (AD27 + 16 + 31 + 31) / 32 + 1;

    void operator()(sycl::nd_item<1> it) const
    {
        // ---- gemv body: verbatim GemvK<K2V, MMA> for gate/up
        const int unit = (int)it.get_group(0);
        const int tid = (int)it.get_local_id(0);
        const int sl = unit % b.nsl;
        const int ub = unit / b.nsl;
        const int blk = ub % b.nbk;
        const int jmu = ub / b.nbk;
        const int j = jmu / b.nm;
        const int lmu = jmu % b.nm;
        const int cat = b.gated ? lmu : CAT_UP;
        const int mu = b.gated ? lmu : 0;
        const int e = b.chunks[j].expert;
        const int m = b.chunks[j].m;
        const uint32_t* w32 = (const uint32_t*)(uintptr_t)b.tab[(F_TRI * 3 + cat) * b.E + e];
        const float* src_tin = b.tin + ((size_t)(j * 2 + mu) * MAXM) * b.H;
        const int K = b.H;
        const int N = b.I;

        const int cG = blk * 128 + tid;
        const int tile_n = cG >> 4, cin = cG & 15;
        const int A2 = (K2V * (32 * (cin & 7) + 4 * ((cin >> 3) & 1))) >> 1;
        const int G = (32 - (K2V >> 1)) - A2 - AD27;
        const int wb = G >> 5;
        const int pre = G - (wb << 5);
        int widx[NW];
#pragma unroll
        for (int i = 0; i < NW; ++i) widx[i] = ((wb + i) % W + W) % W;

        float acc0 = 0, acc1 = 0, acc2 = 0, acc3 = 0;
        float accB0 = 0, accB1 = 0, accB2 = 0, accB3 = 0;
        const size_t row_step = moe_stream_row_step((size_t)W, b.tiles_n);
        const int tk_lo = (b.tiles_k * sl) / b.nsl;
        const int tk_hi = (b.tiles_k * (sl + 1)) / b.nsl;
        const uint32_t* wp = w32 + (size_t)tile_n * moe_stream_col_span((size_t)W, b.tiles_k)
                                 + (size_t)tk_lo * row_step;
        const float* tp = src_tin + tk_lo * 16;
        uint32_t g[NW], gn[NW];
#pragma unroll
        for (int i = 0; i < NW; ++i) g[i] = wp[widx[i]];
        for (int tk = tk_lo; tk < tk_hi; ++tk, wp += row_step, tp += 16) {
            if (tk + 1 < tk_hi) { const uint32_t* wpn = wp + row_step;
#pragma unroll
              for (int i = 0; i < NW; ++i) gn[i] = wpn[widx[i]]; }
            uint32_t h[NW];
            if (pre == 0) {
#pragma unroll
                for (int i = 0; i < NW; ++i) h[i] = g[i];
            } else {
#pragma unroll
                for (int i = 0; i + 1 < NW; ++i)
                    h[i] = (g[i] >> pre) | (g[i + 1] << (32 - pre));
                h[NW - 1] = g[NW - 1] >> pre;
            }
#pragma unroll
            for (int rk = 0; rk < 16; ++rk) {
                const int d = 8 * ((rk >> 1) & 3) + (rk & 1) + 2 * ((rk >> 3) & 1);
                const int rel = AD27 - ((K2V * d + KE) >> 1);
                const uint32_t lo4 = h[rel >> 5], hi4 = h[(rel >> 5) + 1];
                const uint32_t st16 = ((lo4 >> (rel & 31)) | ((hi4 << 1) << (31u - (rel & 31)))) & 0xffffu;
                const uint32_t xm = st16 * 0x83DCD12Du;
                const uint32_t t1 = (xm & 0x00ff00ffu) + ((xm >> 8) & 0x00ff00ffu);
                const uint32_t bs = (t1 & 0xffffu) + (t1 >> 16);
                const float wcomb = (float)(int)bs - 510.0f;
                const float* xr = tp + rk;
                if (rk & 1) { accB0 = sycl::fma(wcomb, xr[0], accB0);
                    if (MMA) {
                        if (m > 1) accB1 = sycl::fma(wcomb, xr[K], accB1);
                        if (m > 2) accB2 = sycl::fma(wcomb, xr[2 * K], accB2);
                        if (m > 3) accB3 = sycl::fma(wcomb, xr[3 * K], accB3);
                    }
                } else { acc0 = sycl::fma(wcomb, xr[0], acc0);
                    if (MMA) {
                        if (m > 1) acc1 = sycl::fma(wcomb, xr[K], acc1);
                        if (m > 2) acc2 = sycl::fma(wcomb, xr[2 * K], acc2);
                        if (m > 3) acc3 = sycl::fma(wcomb, xr[3 * K], acc3);
                    }
                }
            }
#pragma unroll
            for (int i = 0; i < NW; ++i) g[i] = gn[i];
        }
        acc0 += accB0;
        float* dst = b.tout + ((size_t)(j * 2 + mu) * b.nsl + sl) * MAXM * N;
        dst[cG] = acc0 * KDQ;
        if (MMA) {
            acc1 += accB1; acc2 += accB2; acc3 += accB3;
            if (m > 1) dst[N + cG] = acc1 * KDQ;
            if (m > 2) dst[2 * N + cG] = acc2 * KDQ;
            if (m > 3) dst[3 * N + cG] = acc3 * KDQ;
        }

        // ---- arrival: one bump per WG; the last arrival of nm x nsl runs the unit's K34.
        // NOTE the slot stride is 2 (gate/up pair) even when gateless dispatches nm=1 -
        // the arrival COUNT is nm, the tout STRIDE is 2 (tg/tu base split below).
        if (lab >= 2) return;
        it.barrier(sycl::access::fence_space::global_space);
        const int expected = b.nm * b.nsl;
        if (tid == 0) {
            sycl::atomic_ref<int, sycl::memory_order::acq_rel, sycl::memory_scope::device,
                             sycl::access::address_space::global_space>
                ar(ctr[(size_t)j * b.nbk + blk]);
            flg[0] = (ar.fetch_add(1, sycl::memory_order::acq_rel) == expected - 1) ? 1 : 0;
        }
        sycl::group_barrier(it.get_group());
        if (!flg[0]) return;
        if (dbg) sycl::atomic_ref<int, sycl::memory_order::relaxed, sycl::memory_scope::device,
                                  sycl::access::address_space::global_space>(*dbg)
                   .fetch_add(1, sycl::memory_order::relaxed);
        if (lab == 1) return;

        // ---- K34 semantics on the barrier-free strided Hadamard: same per-column op
        // tree as the split kernel (slice sums ascending, sequentia butterfly, act, fused
        // down-prep), but each of the 8 sub-groups transforms the full 128-column block
        // redundantly (v[p] = column 16p+lane) - 2 SLM handoffs + 3 shuffle networks
        // instead of ~24 group barriers, which is what made the SLM-body version cost
        // MORE than the command it saved (tail serialized on the last arrivals).
        const uint16_t* suhd = (const uint16_t*)b.tab[(F_SUH * 3 + CAT_DOWN) * b.E + e];
        const uint16_t* svhu = (const uint16_t*)b.tab[(F_SVH * 3 + CAT_UP) * b.E + e];
        const uint16_t* bu   = (const uint16_t*)b.tab[(F_BIAS * 3 + CAT_UP) * b.E + e];
        const uint16_t* svhg = (const uint16_t*)b.tab[(F_SVH * 3 + CAT_GATE) * b.E + e];
        const uint16_t* bg   = (const uint16_t*)b.tab[(F_BIAS * 3 + CAT_GATE) * b.E + e];
        const int mu_up = b.gated ? 1 : 0;
        const float* tg = b.tout + (size_t)(j * 2) * b.nsl * MAXM * N;
        const float* tu = b.tout + (size_t)(j * 2 + mu_up) * b.nsl * MAXM * N;
        sycl::sub_group sg16 = it.get_sub_group();
        const int ln = (int)sg16.get_local_linear_id();
        const int sgi = tid >> 4;                       // sub-group index in WG
        const int cL = blk * 128 + 16 * sgi + ln;       // column this lane stores round-1->2
        const float hu = HAD_SCALE * f16(svhu[cL]);
        const float bj = bu ? f16(bu[cL]) : 0.0f;
        const float sd = f16(suhd[cL]);
        float hg = 0.f, bi = 0.f;
        if (b.gated) {
            hg = HAD_SCALE * f16(svhg[cL]);
            bi = bg ? f16(bg[cL]) : 0.0f;
        }
        for (int r = 0; r < m; ++r) {
            float vg[8], vu[8];
            if (b.gated) {
                float sg = 0.f, su = 0.f;
                for (int qq = 0; qq < b.nsl; ++qq) {
                    sg += coop_load(tg + ((size_t)qq * MAXM + r) * N + cG);
                    su += coop_load(tu + ((size_t)qq * MAXM + r) * N + cG);
                }
                sh[tid] = sg; sh[128 + tid] = su;
                sycl::group_barrier(it.get_group());
#pragma unroll
                for (int p = 0; p < 8; ++p) { vg[p] = sh[16 * p + ln]; vu[p] = sh[128 + 16 * p + ln]; }
                had128_strided(sg16, vg);
                had128_strided(sg16, vu);
                float rg = 0.f, ru = 0.f;
#pragma unroll
                for (int q = 0; q < 8; ++q) if (sgi == q) { rg = vg[q]; ru = vu[q]; }
                const float gv = rg * hg + bi;
                const float uv = ru * hu + bj;
                float av;
                switch (act) {
                    case 0: {
                        const float eg = std::exp(std::min(-gv, 80.0f));
                        av = std::min(gv / (1.0f + eg), lim) * sycl::clamp(uv, -lim, lim);
                        break; }
                    case 1: {
                        const float cdf = 0.5f * (1.0f + erff(gv * 0.70710678f));
                        av = std::min(gv * cdf, lim) * sycl::clamp(uv, -lim, lim);
                        break; }
                    case 3: {
                        const float gvc = std::min(gv, lim);
                        const float uvc = sycl::clamp(uv, -lim, lim);
                        av = (uvc + 1.0f) * gvc / (1.0f + std::exp(std::min(-1.702f * gvc, 80.0f)));
                        break; }
                    default: av = gv; break;
                }
                sh[16 * sgi + ln] = av * sd;   // fused down-prep (scatter: distinct banks)
            } else {
                float su = 0.f;
                for (int qq = 0; qq < b.nsl; ++qq)
                    su += coop_load(tu + ((size_t)qq * MAXM + r) * N + cG);
                sh[tid] = su;
                sycl::group_barrier(it.get_group());
#pragma unroll
                for (int p = 0; p < 8; ++p) vu[p] = sh[16 * p + ln];
                had128_strided(sg16, vu);
                float ru = 0.f;
#pragma unroll
                for (int q = 0; q < 8; ++q) if (sgi == q) ru = vu[q];
                const float uv = ru * hu + bj;
                const float rv = uv > 0.0f ? uv : 0.0f;
                sh[16 * sgi + ln] = rv * rv * sd;
            }
            sycl::group_barrier(it.get_group());
#pragma unroll
            for (int p = 0; p < 8; ++p) vg[p] = sh[16 * p + ln];
            had128_strided(sg16, vg);
            float res = 0.f;
#pragma unroll
            for (int q = 0; q < 8; ++q) if (sgi == q) res = vg[q];
            tindw[(size_t)j * MAXM * N + (size_t)r * N + cL] = res * HAD_SCALE;
            sycl::group_barrier(it.get_group());
        }
    }
};

// ------------------------------------------------------------------ counter-fed fused DOWN
//
// CUDA exl3_moe_coop doctrine (archive/decode-command-latency.md): at decode sizes the float
// pipeline is COMMAND-bound, not math-bound, so K5+K6 fuse into ONE launch with NO barriers
// and NO cooperative grid: every (chunk, 128-col blk, slice) WG stores its slice partial
// exactly like GemvK, publishes with a global-space barrier, and bumps a completion counter
// for EACH of its live rows' (token, blk) units. The WG that lands LAST on a unit runs that
// unit's whole K6 epilogue inline (fixed-order slice sums + Hadamard + svh + bias + routing-
// weight accumulation over the token's entries in ascending order). No float atomics on
// data (counters are integers; the sums read per-slice slots in the SAME order as the old
// K6, so outputs are bit-identical). Counters ride the control blob and are zeroed by its
// H2D every forward (blob upload precedes both gemv WGs' parents in queue order, so
// zero-and-reuse is race-free even with several layers sharing the queue).
// Tail WGs (rows x nbk) own tokens with ZERO entries and write their out rows directly -
// nothing else would (no arrivals, so no last-arriver). Early-exit cost for the non-empty
// ones is one dispatch slot each (grid oversize is free on Xe).
// Counter-fed fused DOWN (float tier, CUDA exl3_moe_coop doctrine). Two-level arrival
// chain, three roles per WG:
//   1. every (chunk, blk, slice) WG stores its slice partial (layout as GemvK/K5) and
//      bumps ctr1[(entry, blk)]; the LAST slice-arrival for an entry-block transforms
//      that entry's row (fixed-order slice sums + Hadamard + svh + bias, exactly the old
//      K6 per-entry body) and writes the routing-weighted value to tsw - transformation
//      parallelism is nc*nbk WGs, not nbk.
//   2. the transforming WG then bumps ctr2[(token, blk)]; the last arrival there sums the
//      token's tsw rows in ASCENDING entry order - the old K6's exact accumulation order -
//      so OUT IS BIT-IDENTICAL to the split pipeline (single-level variant tried first:
//      whole topk chain inside ONE last-arriver WG = +16us epilogue tail, net -2us).
//      (c) Tail WGs (rows x nbk) own tokens with ZERO entries and write their out rows
//      directly (no arrivals would ever happen for them). Early-exit cost for non-empty
//      tokens is one dispatch slot each (grid oversize is free on Xe).
// Counters ride the control blob and are zeroed by its H2D every forward (blob upload
// precedes the kernel in queue order, so zero-and-reuse is race-free even with several
// layers sharing the queue).
template <int K2V, bool MMA, bool NSL1>
struct CoopDownK
{
    GemvBase b;                  // down=1: toutd/tind/tiles/nsl/nbk per GemvK conventions
    int* ctr1;                   // nent * nbkH entry-level counters (blob-zeroed)
    int* ctr2;                   // rows * nbkH token-level counters (blob-zeroed)
    float* tsw;                  // (nc x MAXM x H) transformed x weight staging
    int* dbg;                    // [1] D level-2 fires (lab build only, else null)
    const int* tokb;
    const int* toke;
    float* out;
    int nUnits;                  // nc * nbk * nsl gemv WGs; beyond them live the owners
    int rows;
    int lab = 0;                 // EPHEMERAL ablation (EXL3_MOE_B70_COOP_LAB): 1 = skip
                                 // transform+level2 (arrival/fence cost only), 2 = skip ALL
                                 // post-gemv coordination. Gates are OUTSIDE the gemv loop.
    // NSL1 (the DEFAULT for coop): one slice covers the whole k range, so the row's full
    // sum is already in REGISTERS at gemv exit - toutd never goes to global, the level-1
    // counter disappears, and only the tsw publish (one fence + one ctr2 atomic per
    // (entry, blk)) remains. Measured: this is what turns the fusion from break-even
    // into the ~-10us win (nsl=1 also beat nsl=2 for the plain K5 at decode shapes).
    sycl::local_accessor<float, 1> sh;
    sycl::local_accessor<int, 1> flg;

    auto get(sycl::ext::oneapi::experimental::properties_tag) const
    {
        return sycl::ext::oneapi::experimental::properties{
            sycl::ext::oneapi::experimental::sub_group_size<16>};
    }

    static constexpr int W = 4 * K2V;
    static constexpr int KE = K2V & 1;
    static constexpr int AD27 = (27 * K2V + KE) >> 1;
    static constexpr int NW = (AD27 + 16 + 31 + 31) / 32 + 1;

    void operator()(sycl::nd_item<1> it) const
    {
        const int unit = (int)it.get_group(0);
        const int tid = (int)it.get_local_id(0);
        if (unit >= nUnits) {
            // owner WG for (token, blk): only tokens WITHOUT entries do work - a token with
            // entries has its out rows written by its last-arrivers. Cheap re-check keeps
            // the grid simple (no host-side empty-token list needed).
            const int q = unit - nUnits;
            const int t = q / b.nbk;
            if (t >= rows) return;
            const int cG = (q % b.nbk) * 128 + tid;
            if (tokb[t] == tokb[t + 1]) out[(size_t)t * b.H + cG] = 0.f;
            return;
        }
        // ---- gemv body: verbatim GemvK<K2V, MMA> for one down-slice (kept as a separate
        // instantiation on purpose: hot-loop branches poison the schedule, NOTES frag1 saga)
        const int sl = unit % b.nsl;
        const int ub = unit / b.nsl;
        const int blk = ub % b.nbk;
        const int j = ub / b.nbk;
        const int e = b.chunks[j].expert;
        const int m = b.chunks[j].m;
        const uint32_t* w32 = (const uint32_t*)(uintptr_t)b.tab[((F_TRI * 3 + CAT_DOWN) * b.E) + e];
        const float* src_tin = b.tind + (size_t)j * MAXM * b.I;
        const int K = b.I;
        const int N = b.H;

        const int cG = blk * 128 + tid;
        const int tile_n = cG >> 4, cin = cG & 15;
        const int A2 = (K2V * (32 * (cin & 7) + 4 * ((cin >> 3) & 1))) >> 1;
        const int G = (32 - (K2V >> 1)) - A2 - AD27;
        const int wb = G >> 5;
        const int pre = G - (wb << 5);
        int widx[NW];
#pragma unroll
        for (int i = 0; i < NW; ++i) widx[i] = ((wb + i) % W + W) % W;

        float acc0 = 0, acc1 = 0, acc2 = 0, acc3 = 0;
        float accB0 = 0, accB1 = 0, accB2 = 0, accB3 = 0;
        const size_t row_step = moe_stream_row_step((size_t)W, b.tiles_n);
        const int tk_lo = (b.tiles_k * sl) / b.nsl;
        const int tk_hi = (b.tiles_k * (sl + 1)) / b.nsl;
        const uint32_t* wp = w32 + (size_t)tile_n * moe_stream_col_span((size_t)W, b.tiles_k)
                                 + (size_t)tk_lo * row_step;
        const float* tp = src_tin + tk_lo * 16;
        uint32_t g[NW], gn[NW];
#pragma unroll
        for (int i = 0; i < NW; ++i) g[i] = wp[widx[i]];
        for (int tk = tk_lo; tk < tk_hi; ++tk, wp += row_step, tp += 16) {
            if (tk + 1 < tk_hi) { const uint32_t* wpn = wp + row_step;
#pragma unroll
              for (int i = 0; i < NW; ++i) gn[i] = wpn[widx[i]]; }
            uint32_t h[NW];
            if (pre == 0) {
#pragma unroll
                for (int i = 0; i < NW; ++i) h[i] = g[i];
            } else {
#pragma unroll
                for (int i = 0; i + 1 < NW; ++i)
                    h[i] = (g[i] >> pre) | (g[i + 1] << (32 - pre));
                h[NW - 1] = g[NW - 1] >> pre;
            }
#pragma unroll
            for (int rk = 0; rk < 16; ++rk) {
                const int d = 8 * ((rk >> 1) & 3) + (rk & 1) + 2 * ((rk >> 3) & 1);
                const int rel = AD27 - ((K2V * d + KE) >> 1);
                const uint32_t lo4 = h[rel >> 5], hi4 = h[(rel >> 5) + 1];
                const uint32_t st16 = ((lo4 >> (rel & 31)) | ((hi4 << 1) << (31u - (rel & 31)))) & 0xffffu;
                const uint32_t xm = st16 * 0x83DCD12Du;
                const uint32_t t1 = (xm & 0x00ff00ffu) + ((xm >> 8) & 0x00ff00ffu);
                const uint32_t bs = (t1 & 0xffffu) + (t1 >> 16);
                const float wcomb = (float)(int)bs - 510.0f;
                const float* xr = tp + rk;
                if (rk & 1) { accB0 = sycl::fma(wcomb, xr[0], accB0);
                    if (MMA) {
                        if (m > 1) accB1 = sycl::fma(wcomb, xr[K], accB1);
                        if (m > 2) accB2 = sycl::fma(wcomb, xr[2 * K], accB2);
                        if (m > 3) accB3 = sycl::fma(wcomb, xr[3 * K], accB3);
                    }
                } else { acc0 = sycl::fma(wcomb, xr[0], acc0);
                    if (MMA) {
                        if (m > 1) acc1 = sycl::fma(wcomb, xr[K], acc1);
                        if (m > 2) acc2 = sycl::fma(wcomb, xr[2 * K], acc2);
                        if (m > 3) acc3 = sycl::fma(wcomb, xr[3 * K], acc3);
                    }
                }
            }
#pragma unroll
            for (int i = 0; i < NW; ++i) g[i] = gn[i];
        }
        acc0 += accB0;
        if (MMA) { acc1 += accB1; acc2 += accB2; acc3 += accB3; }
        if (!NSL1) {
            float* dst = b.toutd + ((size_t)j * b.nsl + sl) * MAXM * N;
            dst[cG] = acc0 * KDQ;
            if (MMA) {
                if (m > 1) dst[N + cG] = acc1 * KDQ;
                if (m > 2) dst[2 * N + cG] = acc2 * KDQ;
                if (m > 3) dst[3 * N + cG] = acc3 * KDQ;
            }
        }

        // ---- arrival
        if (lab >= 2) return;
        if (!NSL1) it.barrier(sycl::access::fence_space::global_space);
        const int nbkH = b.nbk;
        for (int r = 0; r < m; ++r) {
            const int t = b.chunks[j].token[r];
            const int eb = tokb[t], ee = tokb[t + 1];
            bool transform;
            if (NSL1) {
                transform = true;                 // this WG owns the ENTIRE k sum for row r
            } else {
                const int want = j * MOE_MAXM + r;
                int pos = eb;
                while (pos < ee && toke[pos] != want) ++pos;   // WG-uniform scan (topk <= 32)
                if (tid == 0) {
                    flg[1] = 0;
                    sycl::atomic_ref<int, sycl::memory_order::acq_rel, sycl::memory_scope::device,
                                     sycl::access::address_space::global_space>
                        ar(ctr1[(size_t)pos * nbkH + blk]);
                    flg[0] = (ar.fetch_add(1, sycl::memory_order::acq_rel) == b.nsl - 1) ? 1 : 0;
                }
                sycl::group_barrier(it.get_group());
                transform = flg[0];
            }
            if (transform) {
                // ---- the old K6 per-entry transform (fixed-order sums, svh/bias/weight),
                // Hadamard on the barrier-free sub-group network: each of the 8 subgroups
                // transforms the full 128-column block redundantly (strided v[p] = column
                // 16p+lane, bit-identical op tree to hadamard128) and publishes its own 16
                // columns - ~90 ALU/shuffle instead of 8 group barriers.
                const int je = j, s = r;   // the transforming WG is always a slice WG of
                                            // THIS chunk/row (ctr1 unit = (entry, blk))
                const int ed = b.chunks[je].expert;
                const float wgt = b.chunks[je].weight[s];
                const uint16_t* svhe = (const uint16_t*)b.tab[(F_SVH * 3 + CAT_DOWN) * b.E + ed];
                const uint16_t* be = (const uint16_t*)b.tab[(F_BIAS * 3 + CAT_DOWN) * b.E + ed];
                float sv;
                if (NSL1) {
                    const float raw = (r == 0) ? acc0 : (r == 1) ? acc1 : (r == 2) ? acc2 : acc3;
                    sv = raw * KDQ;
                } else {
                    sv = 0.f;
                    for (int qq = 0; qq < b.nsl; ++qq)
                        sv += coop_load(b.toutd + (((size_t)(j * b.nsl + qq) * MAXM + r) * b.H) + cG);
                }
                sh[tid] = sv;
                sycl::group_barrier(it.get_group());
                sycl::sub_group sg = it.get_sub_group();
                const int ln = (int)sg.get_local_linear_id();
                const int sgi = tid >> 4;                       // sub-group index in WG
                float v8[8];
#pragma unroll
                for (int p = 0; p < 8; ++p) v8[p] = sh[16 * p + ln];
                had128_strided(sg, v8);
                float res = 0.f;
#pragma unroll
                for (int q = 0; q < 8; ++q) if (sgi == q) res = v8[q];   // column 16q+lane
                const int cLoc = blk * 128 + 16 * sgi + ln;
                float val = res * (HAD_SCALE * f16(svhe[cLoc]));
                if (be) val += f16(be[cLoc]);
                tsw[((size_t)je * MAXM + s) * b.H + cLoc] = wgt * val;
                // publish the tsw row device-wide, then arrive at the token's unit
                it.barrier(sycl::access::fence_space::global_space);
                if (tid == 0) {
                    sycl::atomic_ref<int, sycl::memory_order::acq_rel, sycl::memory_scope::device,
                                     sycl::access::address_space::global_space>
                        ar2(ctr2[(size_t)t * nbkH + blk]);
                    flg[1] = (ar2.fetch_add(1, sycl::memory_order::acq_rel) == (ee - eb) - 1) ? 1 : 0;
                }
            }
            sycl::group_barrier(it.get_group());
            // ---- level 2: last entry of (token, blk) sums the tsw rows in ASCENDING
            // entry order - the old K6's exact accumulation order - and writes out
            if (flg[1]) {
                if (dbg && tid == 0) sycl::atomic_ref<int, sycl::memory_order::relaxed,
                        sycl::memory_scope::device, sycl::access::address_space::global_space>(dbg[1])
                        .fetch_add(1, sycl::memory_order::relaxed);
                float aacc = 0.f;
                for (int p = eb; p < ee; ++p)
                    aacc += coop_load(tsw + (size_t)toke[p] * b.H + cG);
                out[(size_t)t * b.H + cG] = aacc;
            }
            sycl::group_barrier(it.get_group());       // sh/flg WAR before next row
        }
    }
};

// ------------------------------------------------------------------ int8 / XMX DPAS tier
//
// Mirrors the CPU VNNI tier (moe_mul1.cpp): quantize each transformed row into ONE int8
// GEMV row pair (always-wide: value v in steps of amax/8192 splits into vh = (v+64)>>7 and
// the remainder vl = v - 128*vh; the two rows' outputs simply add), stream the packed mul1
// words exactly like GemvK, and turn each 16-bit state into the product word
// p = st16 * 0x83DCD12D whose four bytes ARE four VNNI hw-k slots of the DPAS B operand:
//   C[r][c] = sum_k A_s8[r][k] * B_u8[k][c]  =  sum_tileRow x8(r,k) * bytesum(p(k,c))
// exactly the integer identity the CPU computes with vpdpbusd. The epilogue affine
//   out = A * acc + B,  A = KDQ * q_eff, B = -510 * A * sum_x8
// folds k_inv, the row scale and the -510 centre; K34i8/K6i8 apply it AFTER the 128-block
// Hadamard by adding 128*B to element 0 (H*ones = 128*e0), so consumers pay one FADD.
//
// Fragment geometry (verified bit-exact on B70 by lab_jm7/lab_jm8):
//   A: joint_matrix<signed char, use::a, 8, 32, row_major>,  loaded from GLOBAL with the
//      fragment-slab base pointer and stride 32 (bytes); one slab = 8 rows x 8 splat dwords.
//   B: joint_matrix<unsigned char, use::b, 32, 16, ext_intel_packed>, staged in SLM: the
//      product dword for tile row rk, column c goes to sl32[(rk>>3)*128 + (rk&7)*16 + c]
//      (packed byte addr(k,c) = (k>>2)*(N*4) + c*4 + (k&3), N=16 -> 64B bands), stride arg 64.
//   C: joint_matrix<int, use::accumulator, 8, 16>, stored row-major to acc[slot][8][N].
// NSL is 1 for this tier: job counts are already >= nfl*slots*16 lanes at decode shapes.

namespace mx8 = sycl::ext::oneapi::experimental::matrix;

struct Affine { float A, B; };

// amax + always-wide 127*64 quantization of one gemv input row, CPU quantize_row_wide
// semantics at HALF range (|vh|,|vl| <= 64: Xe DPAS forms i16 pair sums of u8 products,
// 2*255*64 = 32640 < 32767 stays unsaturated; full +-127 does not). Row r = 2*tok + part.
// Writes splat32 words into the lab_jm8-layout A slab and the affine pair {A,B}.
struct QuantIn
{
    const float* __restrict__ tin;     // [tslot][MAXM][k] float (K1 output layout)
    int32_t* __restrict__ a8;          // [slot][k/8][8 rows][8 i32]
    Affine* __restrict__ qsb;          // [slot][8]
    const ChunkDev* chunks;
    int k, nm, tsmul;                  // tin tslot = slot * tsmul (gateless gu rows live at j*2)
    int f1;                            // 0 = slim pass: frag1 (rows 8..15) is never READ by
                                       // the F1=false Gemv8, so skip its zero-fill entirely
                                       // (rows >= m of frag0 still zero: they ARE loaded)
    sycl::local_accessor<float, 1> red;

    void operator()(sycl::nd_item<2> it) const
    {
        const int slot = (int)it.get_group(1) >> I8R_SHIFT;   // launch: group(1) = slot*I8R + row
        const int r = (int)it.get_group(1) & (I8R - 1);
        const int tid = (int)it.get_local_id(0);       // 256
        const int m = chunks[slot / nm].m;
        const int frag = r >> I8_FRAGROWS_SHIFT;       // which m8 fragment this row sits in
        const int tok = frag * I8_TOK_PER_FRAG + ((r >> 1) & (I8_TOK_PER_FRAG - 1)),
                  part = r & 1;                        // token -> rows 2t (vh), 2t+1 (vl)
        const int kf = k / I8_A8W;
        int32_t* aout = a8 + (size_t)slot * kf * I8_A8BLK + r * I8_A8W;
        if (tok >= m) {
            if (!f1 && frag) return;   // slim: stale bytes in unread high-fragment rows are fine
            for (int i = tid; i < kf * I8_A8W; i += 256)
                aout[(i >> I8_A8W_SHIFT) * I8_A8BLK + (i & (I8_A8W - 1))] = 0;
            if (tid == 0) qsb[slot * I8R + r] = Affine{ 0.f, 0.f };
            return;
        }
        const float* xr = tin + (((size_t)slot * tsmul) * MAXM + tok) * k;
        float am = 0.f;
        for (int i = tid; i < k; i += 256) am = sycl::max(am, sycl::fabs(xr[i]));
        red[tid] = am;
        sycl::group_barrier(it.get_group());
        for (int s = 128; s; s >>= 1) {
            if (tid < s) red[tid] = sycl::max(red[tid], red[tid + s]);
            sycl::group_barrier(it.get_group());
        }
        const float am0 = red[0];
        sycl::group_barrier(it.get_group());           // before overwriting red[] with sx partials
        // exact float spellings of the host reference (and of moe_mul1's quantize_row_wide,
        // at 8192 levels instead of 127*128 - see the DPAS range note above):
        const float qw = am0 > 0.f ? am0 * (1.0f / 8192.0f) : 1.0f;
        const float rq = am0 > 0.f ? 8192.0f / am0 : 1.0f;
        float sacc = 0.f;                              // exact: |partial| < 127*2560 < 2^24
        for (int i = tid; i < k; i += 256) {
            const float vf = xr[i] * rq;
            int v = (int)(vf >= 0.f ? sycl::floor(vf + 0.5f) : sycl::ceil(vf - 0.5f));
            v = sycl::clamp(v, -8128, 8128);
            const int vh = (v + 64) >> 7;
            const int x8 = part ? (v - (vh << 7)) : vh;
            sacc += (float)x8;
            // word (i>>3 selects the fragment slab, i&7 the A-row dword): its 4 bytes ARE
            // hw-k 4q..4q+3, all carrying the same x8 (replication is what buys bytesum).
            // (x8 & 0xff) * 0x01010101 == the uchar splat of the CPU store_x8 path: plain
            // x8*0x01010101 does NOT replicate negatives (arith wrap leaks into the top
            // byte, e.g. -1 -> 0xFEFEFEFF) - that was the stage-C scale+offset fingerprint.
            aout[(i >> I8_A8W_SHIFT) * I8_A8BLK + (i & (I8_A8W - 1))] = (int32_t)((x8 & 0xff) * 0x01010101);
        }
        red[tid] = sacc;
        sycl::group_barrier(it.get_group());
        for (int s = 128; s; s >>= 1) {
            if (tid < s) red[tid] += red[tid + s];
            sycl::group_barrier(it.get_group());
        }
        if (tid == 0) {
            const float q_eff = part ? qw : qw * 128.0f;
            const float Aq = KDQ * q_eff;
            qsb[slot * I8R + r] = Affine{ Aq, -510.0f * Aq * red[0] };
        }
    }
};

// Fused K1+Q1 for the int8 tier (one queue command less; at rows=1 the pipeline is
// command-latency bound, so this is worth ~10us of the ~200us decode floor, and it
// removes the tin round-trip entirely). One WG of 256 threads per (slot, DPAS row):
// two 128-thread teams each run 10 of the 20 Hadamard blocks of the row, holding the
// transformed values in registers (10 per thread) through the amax reduction and the
// x8 quantization - the position of every value is fixed by (block, lane).
// Bit-identical to K1-then-Q1: same f32 spellings (x*suh -> hadamard -> *HAD_SCALE),
// same quantization math, row order irrelevant to a max/sum reduction.
template <int = 0>
struct PrepQuantI8
{
    const uint16_t* __restrict__ x;    // fp16 activations [token][H]
    const uintptr_t* tab;
    const ChunkDev* chunks;
    int32_t* __restrict__ a8;
    Affine* __restrict__ qsb;
    int k, nm, E, gated, f1;
    sycl::local_accessor<float, 1> red;
    sycl::local_accessor<float, 1> sh;

    void operator()(sycl::nd_item<2> it) const
    {
        // One WG of 256 per (slot, token-pair-row rp): rp = r>>1, so BOTH the vh (2rp)
        // and vl (2rp+1) DPAS rows are produced from ONE rotated+Hadamarded row - the
        // exact work K1 used to do once per (slot, token), now shared by both parts.
        const int g1 = (int)it.get_group(1);
        const int slot = g1 >> I8_ROWPAIRS_SHIFT, rp = g1 & (I8_ROWPAIRS - 1);
        const int tid = (int)it.get_local_id(0);          // 256
        const int j = slot / nm, lmu = slot % nm;
        const int m = chunks[j].m;
        const int frag = rp / I8_TOK_PER_FRAG;
        const int tok = frag * I8_TOK_PER_FRAG + (rp % I8_TOK_PER_FRAG);   // r = 2rp
        const int kf = k / I8_A8W;
        int32_t* aout = a8 + (size_t)slot * kf * I8_A8BLK + (rp * 2) * I8_A8W;   // rows 2rp, 2rp+1
        if (tok >= m) {
            if (!f1 && frag) return;                       // slim pass (see QuantIn)
            for (int i = tid; i < kf * I8_A8W; i += 256) {
                const size_t w = (size_t)(i >> I8_A8W_SHIFT) * I8_A8BLK + (i & (I8_A8W - 1));
                aout[w] = 0; aout[w + I8_A8W] = 0;
            }
            if (tid == 0) {
                qsb[slot * I8R + rp * 2] = Affine{ 0.f, 0.f };
                qsb[slot * I8R + rp * 2 + 1] = Affine{ 0.f, 0.f };
            }
            return;
        }
        const int team = tid >> 7, sub = tid & 127;
        const int e = chunks[j].expert;
        const int cat = gated ? lmu : CAT_UP;
        const uint16_t* suh = (const uint16_t*)tab[(F_SUH * 3 + cat) * E + e];
        const int gtok = chunks[j].token[tok];             // DPAS row pair -> token tok
        const uint16_t* xr = x + (size_t)gtok * k;
        float* mine = sh.get_pointer().get() + team * 128;
        float vals[10];
#pragma unroll
        for (int kk = 0; kk < 10; ++kk) {
            const int blk = kk * 2 + team;
            mine[sub] = f16(xr[blk * 128 + sub]) * f16(suh[blk * 128 + sub]);
#pragma unroll
            for (int width = 1; width < 128; width *= 2) {
                sycl::group_barrier(it.get_group());
                if (sub < 64) {
                    const int base = (sub / width) * 2 * width + (sub % width);
                    const float a = mine[base], b2 = mine[base + width];
                    mine[base] = a + b2;
                    mine[base + width] = a - b2;
                }
            }
            sycl::group_barrier(it.get_group());
            vals[kk] = mine[sub] * HAD_SCALE;
        }
        float am = 0.f;
#pragma unroll
        for (int kk = 0; kk < 10; ++kk) am = sycl::max(am, sycl::fabs(vals[kk]));
        red[tid] = am;
        sycl::group_barrier(it.get_group());
        for (int s = 128; s; s >>= 1) {
            if (tid < s) red[tid] = sycl::max(red[tid], red[tid + s]);
            sycl::group_barrier(it.get_group());
        }
        const float am0 = red[0];
        sycl::group_barrier(it.get_group());               // before reusing red[] for sums
        const float qw = am0 > 0.f ? am0 * (1.0f / 8192.0f) : 1.0f;
        const float rq = am0 > 0.f ? 8192.0f / am0 : 1.0f;
        float s0 = 0.f, s1 = 0.f;
#pragma unroll
        for (int kk = 0; kk < 10; ++kk) {
            const float vf = vals[kk] * rq;
            int v = (int)(vf >= 0.f ? sycl::floor(vf + 0.5f) : sycl::ceil(vf - 0.5f));
            v = sycl::clamp(v, -8128, 8128);
            const int vh = (v + 64) >> 7;
            const int vl = v - (vh << 7);
            s0 += (float)vh; s1 += (float)vl;
            const size_t ki = (size_t)(kk * 2 + team) * 128 + sub;      // k position of this value
            const size_t w = (ki >> I8_A8W_SHIFT) * I8_A8BLK + (ki & (I8_A8W - 1));
            aout[w] = (int32_t)((vh & 0xff) * 0x01010101);
            aout[w + 8] = (int32_t)((vl & 0xff) * 0x01010101);
        }
        // x8 row sums (the -510 offset fold), one reduction per part
        red[tid] = s0;
        sycl::group_barrier(it.get_group());
        for (int s = 128; s; s >>= 1) {
            if (tid < s) red[tid] += red[tid + s];
            sycl::group_barrier(it.get_group());
        }
        const float sum0 = red[0];
        sycl::group_barrier(it.get_group());
        red[tid] = s1;
        sycl::group_barrier(it.get_group());
        for (int s = 128; s; s >>= 1) {
            if (tid < s) red[tid] += red[tid + s];
            sycl::group_barrier(it.get_group());
        }
        if (tid == 0) {
            const float A0 = KDQ * (qw * 128.0f), A1 = KDQ * qw;
            qsb[slot * I8R + rp * 2] = Affine{ A0, -510.0f * A0 * sum0 };
            qsb[slot * I8R + rp * 2 + 1] = Affine{ A1, -510.0f * A1 * red[0] };
        }
    }
};

// DPAS GEMV over the stream-repacked mul1 tiles. One sub-group per (16-column fragment,
// gemv slot): 16 lanes = the 16 columns of one trellis tile column, each keeping its own
// compile-time window exactly like GemvK. Per k-tile a lane decodes its 16 states, forms
// the product words and drops them into two 512B packed-B bands (SLM); two m8n16k32 mads
// consume them against the two A fragments (8 tile rows each). Full k range, nsl = 1.
struct Gemv8Base
{
    const uintptr_t* tab;
    const ChunkDev* chunks;
    const int32_t* a8;       // operand slabs from QuantIn
    int32_t* acc;            // [slot][nsl][8][N] raw i32 slices (KDQ/q/-510 folded later via Affine)
    int E, nc, nm, H, I, nfl, down, nsl;
    // Fragment-bucketed launches split the chunk list into [0, nN) narrow (m <=
    // I8_TOK_PER_FRAG) and [nN, nc) wide, each run by its own instantiation. Everything
    // downstream (a8 / acc / qsx / chunks indexing) is by SLOT, so a bucket only needs its
    // base slot index - the token map, K34i8 and K6i8 stay untouched.
    int slot_base = 0;
};

template <int K2V, int NSUB, int NF = I8_FRAGS, bool RING = false>
struct Gemv8
{
    Gemv8Base b;
    sycl::local_accessor<unsigned char, 1> slab;   // 2048B x NSUB: per sub-group ping-pong bands

    auto get(sycl::ext::oneapi::experimental::properties_tag) const
    {
        return sycl::ext::oneapi::experimental::properties{
            sycl::ext::oneapi::experimental::sub_group_size<16> };
    }

    static constexpr int W = 4 * K2V;
    static constexpr int KE = K2V & 1;
    static constexpr int AD27 = (27 * K2V + KE) >> 1;
    static constexpr int NW = (AD27 + 16 + 31 + 31) / 32 + 1;   // same window as GemvK

    void operator()(sycl::nd_item<2> it) const
    {
        const int gid = (int)it.get_group(0);      // (nf-group, slice) flattened, slice-major
        const int slot = (int)it.get_group(1) + b.slot_base;   // gu: j*nm + lmu; down: j
        // NSUB>1: a WG carries NSUB sub-groups, each owning ONE consecutive column tile
        // (nf). Motivation (VTune rows=1): 16-thread WGs cap thread occupancy at ~23% and
        // every WG re-reads the same A slab rows; a fat WG schedules 8x threads per slot
        // and hits A in L1 across its tiles. The mapping is a pure permutation of
        // (nf, sl) -> WG, so acc layout and everything downstream is untouched.
        const int lid = (int)it.get_local_id(0);
        const int tid = lid & 15;                  // == lane within the sub-group
        const int sgid = lid >> 4;
        const int nf = (gid % (b.nfl / NSUB)) * NSUB + sgid;
        const int sl = gid / (b.nfl / NSUB);
        const bool down = b.down != 0;
        const int j = down ? slot : slot / b.nm;
        const int lmu = down ? 0 : slot % b.nm;
        const int cat = down ? CAT_DOWN : (b.nm == 2 ? lmu : CAT_UP);
        const int e = b.chunks[j].expert;
        const int K = down ? b.I : b.H;
        const int N = down ? b.H : b.I;
        const int tiles_k = K / 16;
        const uint32_t* w32 = (const uint32_t*)(uintptr_t)b.tab[(F_TRI * 3 + cat) * b.E + e];

        // column window setup, identical math to GemvK<K2V> (cin = lane, tile_n = nf)
        const int cin = tid & 15;
        const int A2 = (K2V * (32 * (cin & 7) + 4 * ((cin >> 3) & 1))) >> 1;
        const int G = (32 - (K2V >> 1)) - A2 - AD27;
        const int wb = G >> 5;
        const int pre = G - (wb << 5);
        int widx[NW];
#pragma unroll
        for (int i = 0; i < NW; ++i) widx[i] = ((wb + i) % W + W) % W;

        unsigned char* const slb = slab.get_pointer().get() + (size_t)sgid * 2048;
        uint32_t* const sl32 = (uint32_t*)slb;
        const int32_t* const pa0 = b.a8 + (size_t)slot * (K / I8_A8W) * I8_A8BLK;  // [kfrag][I8_A8BLK]
        const size_t row_step = moe_stream_row_step((size_t)W, b.nfl);
        // split-K: this slice covers [tk_lo, tk_hi); slice sums happen in K34i8/K6i8
        const int tk_lo = (tiles_k * sl) / b.nsl;
        const int tk_hi = (tiles_k * (sl + 1)) / b.nsl;
        const uint32_t* wp = w32 + (size_t)nf * moe_stream_col_span((size_t)W, tiles_k)
                                 + (size_t)tk_lo * row_step;

        sycl::sub_group sg = it.get_sub_group();
        mx8::joint_matrix<sycl::sub_group, signed char, mx8::use::a, 8, 32,
                          mx8::layout::row_major> ja;
        mx8::joint_matrix<sycl::sub_group, unsigned char, mx8::use::b, 32, 16,
                          mx8::layout::ext_intel_packed> jb;
        // One m8n16k32 accumulator PER FRAGMENT (NF of them); every fragment mad's against
        // the SAME staged B band, which is the entire point of a wide chunk: one weight
        // fetch + decode serves NF x I8_TOK_PER_FRAG tokens.
        // NF=1 is the SLIM kernel, host-selected when EVERY chunk has m <= I8_TOK_PER_FRAG
        // (decode). The unread fragments' A rows are then never written by QuantIn-slim and
        // their acc rows keep stale bytes - K34/K6 index rows with i8_row_of(r) and r <= 3
        // never touches them. This is the RIGHT form of the narrow-slot skip: NOTES - a
        // runtime branch or a sibling-branch peel INSIDE the fat kernel costs the full path
        // ~20% (E128/rows128 w8: 3605 -> 4325/4389); a separate instantiation is free.
        mx8::joint_matrix<sycl::sub_group, int, mx8::use::accumulator, 8, 16> jc[NF];
#pragma unroll
        for (int f = 0; f < NF; ++f) mx8::joint_matrix_fill(sg, jc[f], 0);

        // FOUR NAMED word sets, one group of 4 tiles per refill: loads for tiles
        // t..t+3 are all issued before tile t is consumed, the next group's loads go
        // out right after the group stages. VTune (attached, sustained): G2 ran 1.9
        // threads/XVE with 88% of active time in Send waits - per-thread MLP is the
        // lever. A (tk&3)-INDEXED 4-buffer array was the real earlier disaster (spills,
        // 149us); named sets + unrolled group cost ~nothing (lab t31 V22 vs V0: -2..6%
        // at the gu shape, bit-exact). Depth-2 kept for reference below the loop.
        const int cnt = tk_hi - tk_lo;
        // RING (lab t39 st14): cooperative A staging. The joint_matrix global A load
        // lowers to a per-lane byte gather costing ~2.8x the whole kernel (t39 st4 vs
        // st18); the same bytes delivered via SLM and loaded LOCALLY run at the no-A-cost
        // ceiling (st12 ~= st6). One 4 KB contiguous copy per k-group (a8 rows are dense
        // over (tk,fk,f)) into 4 rotating regions + one group barrier per group; reads
        // trail writes by >= 2 groups. A is nf-independent: all subgroups share one copy.
        unsigned char* const ring = slab.get_pointer().get() + (size_t)NSUB * 2048;
        auto copygrp = [&](int g) {
            const int tq0 = tk_lo + g * I8_RING_GROUP;
            if (tq0 >= tk_hi) return;
            // k slabs are contiguous over (tk, fk), so one group is a single linear span
            const sycl::uint4* s = (const sycl::uint4*)(pa0 + (size_t)(I8_KSLABS * tq0) * I8_A8BLK);
            sycl::uint4* d = (sycl::uint4*)(ring + (g % I8_RING_REGIONS) * I8_RING_BYTES);
            const int nw = (int)it.get_local_range(0);
            constexpr int full4 = I8_RING_BYTES / 16;      // uint4 words in a whole region
            const int nq = sycl::min(tk_hi - tq0, I8_RING_GROUP);
            if (nq == I8_RING_GROUP) {
                // full group: compile-time trip count, so the copy stays unrolled exactly
                // like the hand-written 2-store version it replaces
#pragma unroll
                for (int o = 0; o < full4; o += 128) {
                    if (o >= full4 || lid + o >= full4) break;
                    d[lid + o] = s[lid + o];
                }
                (void)nw;
            } else {
                const int n4 = nq * I8_RING_TILE_BYTES / 16;
                for (int i = lid; i < n4; i += nw) d[i] = s[i];
            }
        };
        if constexpr (RING)
        {
            copygrp(0); copygrp(1);   // reads trail writes by two groups (I8_RING_REGIONS=4)
            sycl::group_barrier(it.get_group());
        }
        uint32_t gA[NW], gB[NW], gC[NW], gD[NW];
#pragma unroll
        for (int i = 0; i < NW; ++i) {
            gA[i] = wp[widx[i]];
            gB[i] = (cnt > 1) ? wp[row_step + widx[i]] : 0u;
            gC[i] = (cnt > 2) ? wp[2 * row_step + widx[i]] : 0u;
            gD[i] = (cnt > 3) ? wp[3 * row_step + widx[i]] : 0u;
        }
        for (int t = 0; t < cnt; t += 4) {
            if constexpr (RING)
            {
                copygrp((t >> 2) + 2);
                sycl::group_barrier(it.get_group());
            }
#pragma unroll
            for (int q = 0; q < 4; ++q) {
                if (t + q >= cnt) break;
                const int tk = tk_lo + t + q;   // fragment index (pa0) only; band parity is q&1
                const uint32_t* gsrc = (q == 0) ? gA : (q == 1) ? gB : (q == 2) ? gC : gD;
                uint32_t h[NW];
                if (pre == 0) {
#pragma unroll
                    for (int i = 0; i < NW; ++i) h[i] = gsrc[i];
                } else {
#pragma unroll
                    for (int i = 0; i + 1 < NW; ++i)
                        h[i] = (gsrc[i] >> pre) | (gsrc[i + 1] << (32 - pre));
                    h[NW - 1] = gsrc[NW - 1] >> pre;
                }
                uint32_t* const band = sl32 + (q & 1) * 256;
                // Window extraction. For K2=4 the state windows PAIR: rows (rk, rk+2) for
                // rk in {0,1,4,5,8,9,12,13} sit exactly 16 bits apart, so one 32-bit funnel
                // per pair yields both states (hi16=row A, lo16=row B): ~4.5 ops/state vs ~7.
                // t31 full-work A/B (V12 vs V0, both tiles processed): -19% tile-loop time.
                // Other rates (K2=5 half-bit stagger, K2=8 32-bit steps) keep the generic
                // extractor; a K2=8 variant was not tried (rel steps are multiples of 4).
                if constexpr (K2V == 4) {
                    static constexpr int PKA[8] = {0, 1, 4, 5, 8, 9, 12, 13};
#pragma unroll
                    for (int p = 0; p < 8; ++p) {
                        const int rk = PKA[p], rkB = rk + 2;
                        const int dA = 8 * ((rk >> 1) & 3) + (rk & 1) + 2 * ((rk >> 3) & 1);
                        const int relA = AD27 - ((K2V * dA + KE) >> 1);
                        const int relB = relA - 16;
                        const int a = relB >> 5, s = relB & 31;
                        const uint32_t w = s ? ((h[a] >> s) | (h[a + 1] << (32 - s))) : h[a];
                        band[(rk >> 3) * 128 + (rk & 7) * 16 + cin] = (w >> 16) * 0x83DCD12Du;
                        band[(rkB >> 3) * 128 + (rkB & 7) * 16 + cin] = (w & 0xffffu) * 0x83DCD12Du;
                    }
                } else {
#pragma unroll
                    for (int rk = 0; rk < 16; ++rk) {
                        const int d = 8 * ((rk >> 1) & 3) + (rk & 1) + 2 * ((rk >> 3) & 1);
                        const int rel = AD27 - ((K2V * d + KE) >> 1);
                        const uint32_t lo4 = h[rel >> 5], hi4 = h[(rel >> 5) + 1];
                        const uint32_t st16 = ((lo4 >> (rel & 31)) | ((hi4 << 1) << (31u - (rel & 31)))) & 0xffffu;
                        // packed-VNNI dword store, lab_jm8 addressing: band (rk>>3), quad (rk&7), col cin
                        band[(rk >> 3) * 128 + (rk & 7) * 16 + cin] = st16 * 0x83DCD12Du;
                    }
                }
                sg.barrier();
                unsigned char* const bnd = slb + (q & 1) * 1024;
#pragma unroll
                for (int fk = 0; fk < 2; ++fk) {
                    mx8::joint_matrix_load(sg, jb,
                        sycl::address_space_cast<sycl::access::address_space::local_space,
                                                 sycl::access::decorated::yes>(bnd + fk * 512),
                        16 * 4);   // packed stride = N * VNNI bytes
                    {
#pragma unroll
                        for (int f = 0; f < NF; ++f) {
                            // UNCONDITIONAL all-fragment mad on the fat path. Do NOT add a
                            // runtime narrow-slot skip here (see the accumulator note).
                            if constexpr (RING) {
                                const signed char* asrc = (const signed char*)
                                    (ring + ((t >> 2) & 3) * I8_RING_BYTES
                                       + q * I8_RING_TILE_BYTES
                                       + (fk * I8_FRAGS + f) * I8_FRAG_BYTES);
                                auto pal = sycl::address_space_cast<sycl::access::address_space::local_space,
                                                                    sycl::access::decorated::yes>(asrc);
                                mx8::joint_matrix_load(sg, ja, pal, 32);
                            } else {
                            auto pag = sycl::address_space_cast<sycl::access::address_space::global_space,
                                                                sycl::access::decorated::yes>(
                                (const signed char*)(pa0 + (size_t)(tk * I8_KSLABS + fk) * I8_A8BLK
                                                     + f * I8_FRAG_WORDS));
                            mx8::joint_matrix_load(sg, ja, pag, 32);
                            }
                            mx8::joint_matrix_mad(sg, jc[f], ja, jb, jc[f]);
                        }
                    }
                }
            }
            // issue the next group's 4xNW loads now (consumed only after this group's mads)
            const uint32_t* p4 = wp + (size_t)(t + 4) * row_step;
#pragma unroll
            for (int i = 0; i < NW; ++i) {
                gA[i] = (t + 4 < cnt) ? p4[widx[i]] : 0u;
                gB[i] = (t + 5 < cnt) ? p4[row_step + widx[i]] : 0u;
                gC[i] = (t + 6 < cnt) ? p4[2 * row_step + widx[i]] : 0u;
                gD[i] = (t + 7 < cnt) ? p4[3 * row_step + widx[i]] : 0u;
            }
        }
        auto pcg = sycl::address_space_cast<sycl::access::address_space::global_space,
                                            sycl::access::decorated::yes>(
            b.acc + ((size_t)slot * b.nsl + sl) * I8R * N + nf * 16);
#pragma unroll
        for (int f = 0; f < NF; ++f)
            mx8::joint_matrix_store(sg, jc[f], pcg + (size_t)f * I8_ROWS_PER_FRAG * N, N,
                                    mx8::layout::row_major);
    }
};

// ------------------------------------------------------------------ forward

// runtime k2 -> compile-time rate specialization. Lists live in moe_sycl.hpp and drive
// BOTH the predicates and these dispatchers, so 'specialized' and 'dispatchable' cannot
// drift. V == -1 reaches only non-specialized (contract-violating) rates: float callers
// fall through to GemvFallback; int8 launch sites are unreachable for them because the
// tier itself is gated on moe_k2_dpas (assert catches a future policy bug as a crash,
// never as a silently missing kernel).
#define MOE_K2D(V) case V: f(std::integral_constant<int, V>{}); return;
template <typename F> static inline void k2_dpas(int k2, F&& f)
{
    switch (k2) { MOE_FOREACH_K2_DPAS(MOE_K2D) default: f(std::integral_constant<int, -1>{}); }
}
template <typename F> static inline void k2_float(int k2, F&& f)
{
    switch (k2) { MOE_FOREACH_K2_FLOAT(MOE_K2D) default: f(std::integral_constant<int, -1>{}); }
}
#undef MOE_K2D

static int int8_env()
{
    static const int v = []{
        const char* e = std::getenv("EXL3_MOE_B70_INT8");
        return !e ? -1 : (e[0] == '0' ? 0 : e[0] == '1' ? 1 : -1);
    }();
    return v;
}

bool int8_pick(bool rate_ok, int rows)   // harness view (member 'int8' eligibility assumed true)
{
    const int env = int8_env();
    if (env == 0) return false;
    if (env == 1) return rate_ok;
    return rate_ok && (rows >= 2);
}

bool MoeSyclLayer::pick_int8(int rows) const
{
    const int env = int8_env();
    if (env == 0) return false;
    if (env == 1) return int8_ok;
    return int8_ok && int8 && (rows >= 2);
}

// Lab knob: EXL3_MOE_B70_MCAP=4|8 overrides the chunk width cap (default: width 8 only
// when the forward is multi-token-rich enough to pay for the lost gemv parallelism).
// Consulted by host chunkers ONLY when a layer pick already selected int8.
int int8_mcap_pick(bool int8_selected, int rows, int assigned, int experts)
{
    if (!int8_selected) return MOE_MAXM_F;
    static const int envm = []{
        const char* e = std::getenv("EXL3_MOE_B70_MCAP");
        return (!e || (e[0] != '4' && e[0] != '8')) ? 0 : (e[0] - '0');
    }();
    if (envm) return envm;
    // Same-binary A/B (sustained, min-of-2 interleaved, MCAP env): width 8 wins x0.63-0.81
    // for rows>=5, neutral at rows<=4 (chunks rarely exceed 4 there anyway). The apparent
    // small-shape 'regression' vs the OLD 4-row binary was that binary's unpadded width-4
    // path being cheaper than the new kernel's padded frag1 - irrelevant once width 8 runs.
    (void)rows; (void)assigned; (void)experts;
    return MOE_MAXM;
}

sycl::event MoeSyclLayer::forward(const ChunkDev* chunks_host, int num_chunks, const TokenMap& tmap,
                           const uint16_t* x, float* out, int rows, const sycl::event* pre_dep)
{
    const int H = P.hidden, I = P.interm;
    const int k2 = 2 * P.bits + P.hb;
    // Whole-forward host window: the prologue (tier policy, split-K auto rule, coop eligibility,
    // workspace rebind, offset maths) is INSIDE the ALLOCLOG `sub` phase, so leaving it outside the
    // instrument would silently bill it to whoever came last.
    static const int hpf = []{ const char* e = std::getenv("EXL3_MOE_B70_HOSTPROF");
                               return e && e[0] == '1'; }();
    const HpScope hp_scope{hpf != 0};
    if (hpf) HostProf::me().begin(use8_ ? 1 : (rows > 1 ? 2 : 0));
    const double hpk0 = hpf ? HostProf::me().start_region("prologue") : 0.0;
    // Tier policy. Sustained-clock A/B (bench_layer, min-of-3 interleaved, iters 1200 —
    // earlier short-run tables were cold-clock garbage and one had the tiers swapped by
    // the auto rule itself, see NOTES): rows=1 float 179 vs int8 222 (float wins: m8
    // fragments run 25% full and QuantIn/slice costs are not amortized); rows=2 262->224
    // (x1.17); 3->x1.41; 4->x1.59; 8->x2.26; 32->x2.58; 64->x2.20. The predictor is TOTAL
    // rows, not max chunk width: float pays per (chunk x row), DPAS pays per chunk with
    // the m8 fragment free. So AUTO = DPAS iff rows >= 2. EXL3_MOE_B70_INT8: =1 force
    // int8 (lab), =0 force float; unset -> auto (member int8 = true enables auto). Only
    // stream-layout rates can use the DPAS tier at all (int8_ok, from init()).
    // Lives in pick_int8() because the HOST CHUNKER needs the same answer for the width cap.
    use8_ = pick_int8(rows);
    int8_active = use8_;
    int maxm_scan = 1;
    for (int j = 0; j < num_chunks; ++j) maxm_scan = std::max(maxm_scan, (int)chunks_host[j].m);
    const int E = P.num_experts;
    const int tile_u32 = 4 * k2;                    // u32 words per tile
    const bool gated = P.gated;
    const int nm = gated ? 2 : 1;
    const int act = P.activation;
    const float lim = P.act_limit != 0.0f ? P.act_limit : INFINITY;
    // int8 split-K degrees (must be resolved BEFORE ensure_ws: the acc buffers are sized
    // by them). Same lane-target heuristic as the float tier: the DPAS gemv runs one
    // sub-group per (fragment,slice,slot), so unsliced decode shapes run far below the
    // 2048-thread fill; slice-sum consumers are K34i8/K6i8 (multi-row: slices cost traffic).
    int nsl8_gu = 1, nsl8_d = 1;
    if (use8_) {
        const int mxm = maxm_scan;
        const int lanes_u = num_chunks * nm * I;
        const int lanes_d = num_chunks * H;
        if (nsl > 0) { nsl8_gu = std::min(8, nsl); nsl8_d = nsl8_gu; }
        else {
            // fill target 136000 lanes (was 80000): MAXM=8 halved nc, and the post-MAXM8
            // sustained sweep with per-kernel overrides puts gu at nsl=2 for lanes~132k
            // where the old target picked 1 (-13% at rows=64), while 61-70k-lane shapes
            // want 2 (nsl3 costs +0.8%). ~66 waves of 16-lane WGs = full latency hiding.
            while (nsl8_gu < 8 && lanes_u * nsl8_gu < 136000) ++nsl8_gu;
            if (mxm > 1 && nsl8_gu > 4) nsl8_gu = 4;
            while (nsl8_d < 8 && lanes_d * nsl8_d < 80000) ++nsl8_d;
            if (nsl8_d > 4) nsl8_d = 4;               // down has more fragments: softer cap
            if (mxm > 1 && nsl8_d > 2) nsl8_d = 2;
        }
        // lab: independent per-kernel overrides AFTER the shared MOE_NSL path
        static const int env_gu = []{ const char* e = getenv("EXL3_MOE_I8NSLU"); return e ? atoi(e) : 0; }();
        static const int env_d  = []{ const char* e = getenv("EXL3_MOE_I8NSLD"); return e ? atoi(e) : 0; }();
        if (env_gu >= 1 && env_gu <= 8) nsl8_gu = env_gu;
        if (env_d  >= 1 && env_d  <= 8) nsl8_d  = env_d;
    }
    nsl8_gu_ = nsl8_gu; nsl8_d_ = nsl8_d;
    // Counter-fed fused down (float tier, decode shapes) eligibility + counter layout.
    // Set BEFORE ensure_ws (tsw slot) and before NSL_D (coop defaults to nsl=1).
    static const int coop_env = []{
        const char* e = std::getenv("EXL3_MOE_B70_COOP");
        return !e || e[0] != '0';
    }();
    static const int coop_dn_env = []{
        const char* e = std::getenv("EXL3_MOE_B70_COOPDN");   // =0: classic K5+K6 (lab/debug)
        return !e || e[0] != '0';
    }();
    const bool coopBase = coop_env && !use8_ && moe_k2_float(k2) && rows <= 8;
    const bool coopD = coopBase && coop_dn_env;
    // GU-side fusion (K2+K34): OPT-IN lab (EXL3_MOE_B70_COOPGU=1). Measured on the C-ABI
    // decode shape: D-fused 102, D+GU-fused(auto NSL) 109, D+GU(NSLG=2) 100.6 vs
    // D-fused(NSLG=2) 98.9 - removing the K34 command is paid for by the arrival chain on
    // 700 WGs and the fused kernel's tail; it is at best a wash, and the K2-kernel arrival
    // tax scales with NSL_GU (NSLG=3 wave-cliff). Kept instantiated + env-gated for a
    // future retune; default OFF.
    static const int coop_gu_env = []{
        const char* e = std::getenv("EXL3_MOE_B70_COOPGU");
        return e && e[0] == '1';
    }();
    const bool coopGU = coopBase && coop_gu_env;
    coop_ = coopD;
    static const int coop_dbg_env = []{
        const char* e = std::getenv("EXL3_MOE_B70_CTRDBG");
        return e && e[0] == '1';
    }();
    coop_dbg = coop_dbg_env;
    const int nc = num_chunks;
    int maxm_rows = 1, maxm_nm = 1;
    for (int j = 0; j < nc; ++j) maxm_rows = std::max(maxm_rows, (int)chunks_host[j].m);
    maxm_nm = maxm_rows;   // (kept separate for future per-class relaxation)
    const int NSL_GU = [&]{
        int base = nc * nm * (I / 128), w = nsl;
        // auto up to 8: real-model decode (few rows, latency-bound) wants the extra
        // parallelism; synthetic E=12 benches disagreed, the model won the argument.
        if (w == 0) { w = 1; while (w < 8 && base * w * 128 < 80000) ++w;
                      if (maxm_rows > 1 && w > 4) w = 4; }   // multi-row: slice-sum traffic dominates
        static const int env_g = []{ const char* e = getenv("EXL3_MOE_NSLG"); return e ? atoi(e) : 0; }();
        if (env_g >= 1 && env_g <= 8) w = env_g;
        return w;
    }();
    const int NSL_D = [&]{
        int base = nc * (H / 128), w = nsl;
        if (w == 0) {
            // coop default is nsl=1: the single slice keeps the row sum in REGISTERS at
            // gemv exit - no toutd round-trip, no level-1 counters (see CoopDownK).
            if (coopD) w = 1;
            else { w = 1; while (w < 8 && base * w * 128 < 80000) ++w; if (w > 2) w = 2; }
        }
        // float-tier per-kernel overrides (mirror of the int8 EXL3_MOE_I8NSLU/NSLD)
        static const int env_d = []{ const char* e = getenv("EXL3_MOE_NSLD"); return e ? atoi(e) : 0; }();
        if (env_d >= 1 && env_d <= 8) w = env_d;
        return w;
    }();
    nslgu_dbg = NSL_GU; nsld_dbg = NSL_D;
    sycl::queue& q = *Q;
    ensure_ws(num_chunks, rows);
    if (alog()) {
        static const int a_ring = []{ const char* e = getenv("EXL3_MOE_I8RING"); return !e || e[0] != '0'; }();
        static const int a_slim = []{ const char* e = getenv("EXL3_MOE_I8SLIM"); return !e || e[0] != '0'; }();
        static const int a_fuse = []{ const char* e = getenv("EXL3_MOE_I8FUSE"); return !e || e[0] != '0'; }();
        alog_msg("J rows %d nc %d E %d H %d I %d k2 %d gated %d use8 %d maxm %d "
                 "nsl8 %d/%d slim %d fuse %d ring %d | ws %p %p %p %p %p %p %p %p %p %p %p",
                 rows, num_chunks, P.num_experts, H, I, k2, (int)P.gated, (int)use8_, maxm_scan,
                 nsl8_gu, nsl8_d, (int)(maxm_scan <= 4 && a_slim), (int)(use8_ && a_fuse),
                 (int)(a_ring && maxm_scan > 4),
                 (void*)g_ws.buf[0], (void*)g_ws.buf[1], (void*)g_ws.buf[2], (void*)g_ws.buf[3],
                 (void*)g_ws.buf[4], (void*)g_ws.buf[5], (void*)g_ws.buf[6], (void*)g_ws.buf[7],
                 (void*)g_ws.buf[8], (void*)g_ws.buf[9], (void*)g_ws.buf[10]);
        alog_msg("   poolcap %zu %zu %zu %zu %zu %zu %zu %zu %zu %zu %zu (B)",
                 g_ws.cap[0]*4, g_ws.cap[1]*4, g_ws.cap[2]*4, g_ws.cap[3]*4, g_ws.cap[4]*4,
                 g_ws.cap[5]*4, g_ws.cap[6]*4, g_ws.cap[7]*4, g_ws.cap[8]*4, g_ws.cap[9]*4, g_ws.cap[10]*4);
    }

    // one H2D blob: [chunks][pad64][tokb][pad64][toke][pad64][ctr1|ctr2 (coop)]
    const size_t off_chunk = 0;
    const size_t off_tokb = ((size_t)nc * sizeof(ChunkDev) + 63) & ~(size_t)63;
    const size_t off_toke = (off_tokb + ((size_t)rows + 1) * sizeof(int) + 63) & ~(size_t)63;
    // completion counters ride the blob, so the SAME H2D that uploads the chunks zeroes
    // them (race-free reset, no extra command; see CoopDownK). Layout: [ctrG nc*nbkI]
    // [ctr1 nent*nbkH] [ctr2 rows*nbkH] (GU zones only when coopGU; D zones when coopD).
    const size_t off_ctr = (off_toke + tmap.entry.size() * sizeof(int) + 63) & ~(size_t)63;
    const size_t ctrG_n = coopGU ? (size_t)nc * (I / 128) : 0;   // one per (chunk, 128-col block of I)
    const size_t ctr1_n = coopD && NSL_D != 1 ? tmap.entry.size() * (H / 128) : 0;
    const size_t ctr2_n = coopD ? (size_t)rows * (H / 128) : 0;
    const size_t ctr_bytes = (coopD || coopGU) ? (ctrG_n + ctr1_n + ctr2_n) * sizeof(int) : 0;
    static const int ctrdbg = []{ const char* e = getenv("EXL3_MOE_B70_CTRDBG"); return e && e[0] == '1'; }();
    ctr_bytes_dbg = ctrdbg ? ctr_bytes : 0;
    ctr_off_logged = coopD ? off_ctr : 0;
    const size_t blob_sz = (coopD || coopGU) ? off_ctr + ctr_bytes
                                 : off_toke + tmap.entry.size() * sizeof(int);
    if (blob_sz > cap_blob) {
        if (h_blob) { MOE_ALOG_FREE(h_blob, cap_blob, "h_blob"); sycl::free(h_blob, q); }
        if (h_blob2) { MOE_ALOG_FREE(h_blob2, cap_blob, "h_blob2"); sycl::free(h_blob2, q); }
        // +16 B slack in every blob allocation: EXL3_MOE_B70_BLOB_BY_KERNEL rounds the copy up to
        // 16-byte words, so the pull kernel must be allowed to read/write one word past blob_sz.
        const size_t alloc_sz = blob_sz + 16;
        h_blob = (char*)sycl::malloc_host(alloc_sz, q);
        h_blob2 = (char*)sycl::malloc_host(alloc_sz, q);
        MOE_ALOG_ALLOC(h_blob, blob_sz, "h_blob");
        MOE_ALOG_ALLOC(h_blob2, blob_sz, "h_blob2");
        if (w_chunk) { MOE_ALOG_FREE(w_chunk, cap_blob, "w_chunk"); sycl::free(w_chunk, q); }
        w_chunk = (ChunkDev*)sycl::malloc_device<char>(alloc_sz, q);
        MOE_ALOG_ALLOC(w_chunk, blob_sz, "w_chunk");
        alog_msg("   blob chunk_sz %zu tokb %zu toke %zu offs %zu/%zu/%zu",
                 (size_t)nc * sizeof(ChunkDev), ((size_t)rows + 1) * sizeof(int),
                 tmap.entry.size() * sizeof(int), off_chunk, off_tokb, off_toke);
        q.memset(w_chunk, 0, blob_sz);
        q.wait();
        cap_blob = blob_sz;
    }
    h_flip = !h_flip;
    char* hb = h_flip ? h_blob : h_blob2;
    if (hpf) HostProf::me().start_region("blob-pack");
    std::memcpy(hb + off_chunk, chunks_host, nc * sizeof(ChunkDev));
    std::memcpy(hb + off_tokb, tmap.begin.data(), tmap.begin.size() * sizeof(int));
    std::memcpy(hb + off_toke, tmap.entry.data(), tmap.entry.size() * sizeof(int));
    if (coopD || coopGU) std::memset(hb + off_ctr, 0, ctr_bytes);
    if (hpf) HostProf::me().end_region(hpk0);

    // NOTE: implicit in-order ordering between chained submits/memcpys is NOT enforced on
    // this stack (oneAPI 2026.2 + L0 + Xe2); explicit depends_on chains are required.
    const double ht0 = hpf ? HostProf::me().start_region("blob-h2d") : 0.0;
    // EXPERIMENT (EXL3_MOE_B70_BLOB_BY_KERNEL=1). The per-stage instrument localized the decode
    // forward's fixed cost to a TAIL on whichever submit is the first KERNEL after the H2D copies
    // (K1: min 5.0 / mean 14.0 / 98 of 256 forwards > 10 us), and a no-op kernel placed first
    // inherits that tail (mean 12.7, 107/256) while K1 drops to 7.3 - i.e. the delay is the copy
    // path's cold fast-submission route being paid by the command behind the copy. This knob tests
    // the structural fix the same finding implies: issue NO memory command at all, and let a
    // compute-engine kernel pull the few hundred blob bytes straight from pinned host memory over
    // PCIe (the arena uploader already reads pinned host memory this way). Correctness must be
    // bit-identical: same bytes, same destination, same dependency.
    static const int blob_by_kernel = []{
        const char* e = getenv("EXL3_MOE_B70_BLOB_BY_KERNEL");
        return e && e[0] == '1';
    }();
    sycl::event dep;
    if (blob_by_kernel) {
        const int words = (int)((blob_sz + 15) / 16);
        dep = q.submit([&](sycl::handler& cgh) {
            if (pre_dep) cgh.depends_on(*pre_dep);
            cgh.parallel_for(sycl::range<1>{(size_t)words},
                             BlobPull{(const sycl::uint4*)hb, (sycl::uint4*)w_chunk, words});
        });
    } else {
        dep = pre_dep ? q.memcpy(w_chunk, hb, blob_sz, {*pre_dep})
                      : q.memcpy(w_chunk, hb, blob_sz);
    }
    if (hpf) HostProf::me().end_region(ht0);
    if (prof) { pev.clear(); pev.push_back(dep); }
    auto launch = [&](auto&& fn, const char* nm = nullptr) {
        const double htl = hpf ? HostProf::me().start_region(nm) : 0.0;
        dep = q.submit([&](sycl::handler& cgh) {
            if (hpf) HostProf::me().body_begin();
            cgh.depends_on(dep);
            fn(cgh);
            if (hpf) HostProf::me().body_end();
        });
        if (hpf) HostProf::me().end_region(htl);
        if (prof) pev.push_back(dep);
    };
    auto launchN = [&](const char* nm, auto&& fn) { launch(std::forward<decltype(fn)>(fn), nm); };

    const uintptr_t* tab = d_tab;
    const ChunkDev* chunks = w_chunk;
    const int* d_tokb = (const int*)((const char*)w_chunk + off_tokb);
    const int* d_toke = (const int*)((const char*)w_chunk + off_toke);
    float* tin = w_tin;
    float* tout = w_tout;
    float* hbuf = w_h;
    float* tind = w_tind;
    float* toutd = w_toutd;

    // ---- K1: prep gate/up inputs (suh scale + 128-block hadamard), from fp16 x.
    // The int8 tier normally skips this: PrepQuantI8 (below) folds it into Q1.
    static const int nofuse_env = []{
        const char* e = std::getenv("EXL3_MOE_I8FUSE");
        return e && e[0] == '0';
    }();
    const bool fuse_k1 = use8_ && !nofuse_env;
    i8_fuse_ = fuse_k1 ? 1 : 0;
    if (!fuse_k1) {
        const int nbk = H / 128;
        // coop float path: K1 ALSO resets the arrival counters - render-engine stores,
        // so the cells enter the same cache domain that the epilogue atomics RMW later.
        // Zeroing them only in the blob H2D (copy engine) proved NOT visible to the first
        // render-side fetch_add under the GU fusion (stale prior-forward values: the
        // epilogue never fired and `out` stayed byte-exact from the previous forward);
        // the host-side blob zeroing remains as belt-and-braces for the very first use.
        int* const ctr_zone = coopD || coopGU ? (int*)((char*)w_chunk + off_ctr) : nullptr;
        const int ctr_cells = coopD || coopGU
            ? (int)(ctrG_n + ctr1_n + ctr2_n) : 0;
        const int clr_rows = ctr_cells ? (ctr_cells + nbk * 128 - 1) / (nbk * 128) : 0;
        // DIAGNOSTIC ONLY (EXL3_MOE_B70_PROBE_FIRST=1). K1 measures ~13 us in the model where every
        // other submit measures ~5, and its own handler body is only ~0.35 us - so the extra ~8 us is
        // the runtime's bookkeeping for THAT launch. Two candidate reasons, distinguishable only by
        // experiment: POSITIONAL (it is the first KERNEL after the two host->device copies, so it is
        // whoever closes the copy->compute edge) or INTRINSIC (something about this kernel's
        // dispatch). Submitting a trivial 1-WG kernel with no local_accessor immediately before K1
        // moves the edge to the probe: if the ~8 us follows it, the cost is positional.
        // Timing-only knob: it writes tin[0], which K1 overwrites in the same forward.
        static const int probe_first = []{ const char* e = std::getenv("EXL3_MOE_B70_PROBE_FIRST");
                                          return e && e[0] == '1'; }();
        if (probe_first)
            launchN("probe-first", [&](sycl::handler& cgh) {
                cgh.single_task([=] { tin[0] += 1.0f; });
            });
        launchN("K1-prep", [&](sycl::handler& cgh) {
            sycl::local_accessor<float, 1> sh({128}, cgh);
            cgh.parallel_for(sycl::nd_range<2>({(size_t)nbk * 128, (size_t)(nc * nm + clr_rows)}, {128, 1}),
                [=](sycl::nd_item<2> it) {
                const int blk = (int)it.get_group(0);
                const int unit = (int)it.get_group(1);
                const int tid = (int)it.get_local_id(0);
                if (unit >= nc * nm) {
                    const int cid = (unit - nc * nm) * nbk + blk;
                    const int ncid = clr_rows * nbk;
                    for (int i = cid * 128 + tid; i < ctr_cells; i += ncid * 128)
                        ctr_zone[i] = 0;
                    return;
                }
                const int j = unit / nm, lmu = unit % nm;
                const int cat = gated ? lmu : CAT_UP;
                const int mu = gated ? lmu : 0;
                const int e = chunks[j].expert;
                const int m = chunks[j].m;
                const uint16_t* suh = (const uint16_t*)tab[(F_SUH * 3 + cat) * E + e];
                float* dst_base = tin + ((size_t)(j * 2 + mu) * MAXM) * H;
                for (int r = 0; r < m; ++r) {
                    const int tok = chunks[j].token[r];
                    sh[tid] = f16(x[(size_t)tok * H + blk * 128 + tid]) * f16(suh[blk * 128 + tid]);
                    hadamard128(it, tid, sh.get_pointer());
                    dst_base[(size_t)r * H + blk * 128 + tid] = sh[tid] * HAD_SCALE;
                    sycl::group_barrier(it.get_group());
                }
            });
        });
    }

    // ---- int8 / XMX DPAS pipeline (K2, K5 replace the fp gemvs; K1 above is shared).
    // Exact-i32 accumulators, nsl = 1; {KDQ*q, -510*KDQ*q*sx} folds into the act/gather
    // epilogues as the affine {A,B} per DPAS row (see QuantIn/Gemv8 above).
    if (use8_) {
        int32_t* const accgu = w_accgu;
        int32_t* const accd8 = w_accd;
        Affine* const qsxu = (Affine*)w_qsxu;
        Affine* const qsxd = (Affine*)w_qsxd;
        const int slots = nc * nm;
        Gemv8Base g8{ d_tab, w_chunk, nullptr, nullptr, E, nc, nm, H, I, 0, 0, 1 };

        // DECODE SHAPE: when no chunk exceeds 4 tokens, frag1 contributes nothing and the
        // whole pipeline runs the SLIM instantiation (see Gemv8 F1 and QuantIn f1).
        static const int noslim_env = []{
            const char* e = std::getenv("EXL3_MOE_I8SLIM");
            return e && e[0] == '0';
        }();
        const bool slim = (maxm_rows <= I8_TOK_PER_FRAG) && !noslim_env;
        i8_slim_ = slim ? 1 : 0;
        // Fragment bucketing: the host chunker (moe_bucket_chunks) puts every chunk that one
        // m8 fragment can cover first. Those run NF=1, the rest at full width - instead of
        // padding all of them to I8_FRAGS fragments. No-op when the split is degenerate (all
        // narrow = the slim path above, all wide = the fat path), and EXL3_MOE_B70_BUCKET=0
        // restores the single padded launch everywhere.
        static const int bucket_ok = []{
            const char* e = std::getenv("EXL3_MOE_B70_BUCKET");
            return !e || e[0] != '0';
        }();
        int n_narrow = 0;
        while (n_narrow < num_chunks && chunks_host[n_narrow].m <= I8_TOK_PER_FRAG) ++n_narrow;
        const bool bucketed = bucket_ok && n_narrow > 0 && n_narrow < num_chunks;
        // EXL3_MOE_I8SLIMRING=1 opts the ALL-narrow (slim) kernel into A staging as well.
        // Measured NEGATIVE on every all-narrow shape (E260 int8, min-of-2: rows1 197.6 ->
        // 225.3, rows2 266 -> 316, rows4 411 -> 487, rows8 714 -> 793 us): with one fragment
        // per slot the SLM round trip costs more than the per-lane global A gather it avoids,
        // so lever 6 stays parked. This is NOT the mixed-job narrow bucket - that one shares
        // the wide launch's ring decision and IS worth staging (see moe_bucket_chunks: E260
        // rows64 2647 -> 2252 us, rows128 3112 -> 2850 us).
        static const int slim_ring_ok = []{
            const char* e = std::getenv("EXL3_MOE_I8SLIMRING"); return e && e[0] == '1';
        }();

        // Q1 (+K1 fused): rotate, Hadamard, amax-quantize straight from x into the A slab
        launchN("i8-prepq", [&](sycl::handler& cgh) {
            sycl::local_accessor<float, 1> red({256}, cgh);
            if (fuse_k1) {
                sycl::local_accessor<float, 1> sh({256}, cgh);
                cgh.parallel_for(sycl::nd_range<2>({256, (size_t)I8_ROWPAIRS * slots}, {256, 1}),
                    PrepQuantI8<> { x, tab, chunks, w_a8u, qsxu, H, nm, E, gated ? 1 : 0,
                                 slim ? 0 : 1, red, sh });
                return;
            }
            cgh.parallel_for(sycl::nd_range<2>({256, (size_t)I8R * slots}, {256, 1}),
                QuantIn{ tin, w_a8u, qsxu, chunks, H, nm, gated ? 1 : 2, slim ? 0 : 1, red });
        });

        // K2p: gate/up DPAS gemm, one sub-group per (16-col fragment, slice, slot)
        {
            g8.a8 = w_a8u; g8.acc = accgu; g8.nfl = I / 16; g8.down = 0; g8.nsl = nsl8_gu;
            static const int wide_ok = []{
                const char* e = std::getenv("EXL3_MOE_I8W");
                return e && e[0] == '1';
            }();
            static const int ring_ok = []{
                const char* e = std::getenv("EXL3_MOE_I8RING");
                return !e || e[0] != '0';   // default ON since -21..-43% prefill bit-exact; =0 opts out
            }();
            const bool wide = wide_ok && (I / 16) % 8 == 0 && (k2 == 4 || k2 == 5 || k2 == 8);  // I8W lab variant frozen to the trio
            const bool ring = ring_ok && (I / 16) % 8 == 0 && (!slim || slim_ring_ok);
            const size_t g0 = (wide || ring) ? (size_t)(I / 16 / 8) * 128 * nsl8_gu
                                   : (size_t)(I / 16) * 16 * nsl8_gu;
            // Mixed buckets: ONE narrow (NF=1) launch over the first nN_narrow slots plus ONE
            // wide (NF=I8_FRAGS) launch over the rest. See moe_bucket_chunks() for why.
            if (bucketed) {
                const int ns_narrow = n_narrow * nm;
                launchN("i8-gemv-gu", [&](sycl::handler& cgh) {
                    sycl::local_accessor<unsigned char, 1> slm({ring ? (size_t)I8_SLM_BYTES : (size_t)I8_SLAB_SUB}, cgh);
                    Gemv8Base g = g8; g.slot_base = 0;
                    const size_t gn = ring ? (size_t)(I / 16 / 8) * 128 * nsl8_gu
                                           : (size_t)(I / 16) * 16 * nsl8_gu;
                    k2_dpas(k2, [&](auto R) {
                        constexpr int V = decltype(R)::value;
                        if constexpr (V > 0) {
                            if (ring)
                                cgh.parallel_for(sycl::nd_range<2>({gn, (size_t)ns_narrow}, {128, 1}),
                                                 Gemv8<V, 8, 1, true>{g, slm});
                            else
                                cgh.parallel_for(sycl::nd_range<2>({gn, (size_t)ns_narrow}, {16, 1}),
                                                 Gemv8<V, 1, 1>{g, slm});
                        } else throw std::logic_error("k2_dpas: tier chosen for an un-specialized rate");
                    });
                });
                launchN("i8-gemv-gu", [&](sycl::handler& cgh) {
                    sycl::local_accessor<unsigned char, 1> slm({ring ? (size_t)I8_SLM_BYTES : (size_t)I8_SLAB_SUB}, cgh);
                    Gemv8Base g = g8; g.slot_base = ns_narrow;
                    const size_t gw = ring ? (size_t)(I / 16 / 8) * 128 * nsl8_gu
                                           : (size_t)(I / 16) * 16 * nsl8_gu;
                    k2_dpas(k2, [&](auto R) {
                        constexpr int V = decltype(R)::value;
                        if constexpr (V > 0) {
                            if (ring)
                                cgh.parallel_for(sycl::nd_range<2>({gw, (size_t)(slots - ns_narrow)}, {128, 1}),
                                                 Gemv8<V, 8, I8_FRAGS, true>{g, slm});
                            else
                                cgh.parallel_for(sycl::nd_range<2>({gw, (size_t)(slots - ns_narrow)}, {16, 1}),
                                                 Gemv8<V, 1, I8_FRAGS, false>{g, slm});
                        } else throw std::logic_error("k2_dpas: tier chosen for an un-specialized rate");
                    });
                });
            } else
            launchN("i8-gemv-gu", [&](sycl::handler& cgh) {
                sycl::local_accessor<unsigned char, 1> slm({ring ? (size_t)I8_SLM_BYTES
                                                          : (wide ? 8u * I8_SLAB_SUB : 1u * I8_SLAB_SUB)}, cgh);
                if (ring) {
                    k2_dpas(k2, [&](auto R) {
                        constexpr int V = decltype(R)::value;
                        if constexpr (V > 0)
                            cgh.parallel_for(sycl::nd_range<2>({g0, (size_t)slots}, {128, 1}), Gemv8<V, 8, I8_FRAGS, true>{g8, slm});
                        else throw std::logic_error("k2_dpas: tier chosen for an un-specialized rate");
                    });
                    return;
                }
                if (slim) {
                    k2_dpas(k2, [&](auto R) {
                        constexpr int V = decltype(R)::value;
                        if constexpr (V > 0)
                            cgh.parallel_for(sycl::nd_range<2>({g0, (size_t)slots}, {16, 1}), Gemv8<V, 1, 1>{g8, slm});
                        else throw std::logic_error("k2_dpas: tier chosen for an un-specialized rate");
                    });
                    return;
                }
                if (wide) {
                    switch (k2) {
                        case 4: cgh.parallel_for(sycl::nd_range<2>({g0, (size_t)slots}, {128, 1}), Gemv8<4, 8>{g8, slm}); break;
                        case 5: cgh.parallel_for(sycl::nd_range<2>({g0, (size_t)slots}, {128, 1}), Gemv8<5, 8>{g8, slm}); break;
                        default: cgh.parallel_for(sycl::nd_range<2>({g0, (size_t)slots}, {128, 1}), Gemv8<8, 8>{g8, slm}); break;
                    }
                    return;
                }
                k2_dpas(k2, [&](auto R) {
                    constexpr int V = decltype(R)::value;
                    if constexpr (V > 0)
                        cgh.parallel_for(sycl::nd_range<2>({g0, (size_t)slots}, {16, 1}), Gemv8<V, 1>{g8, slm});
                    else throw std::logic_error("k2_dpas: tier chosen for an un-specialized rate");
                });
            });
        }

        // K34i8: affine-folded out transform + activation + fused down-prep (the int8 twin
        // of the fp32 K34; B enters as +128*B at element 0 after the Hadamard, which is
        // exactly H*(B*ones)).
        {
            const int nbk = I / 128;
            launchN("i8-gemv-gu", [&](sycl::handler& cgh) {
                sycl::local_accessor<float, 1> sh({256}, cgh);
                cgh.parallel_for(sycl::nd_range<2>({(size_t)nbk * 128, (size_t)nc}, {128, 1}),
                    [=](sycl::nd_item<2> it) {
                    const int blk = (int)it.get_group(0);
                    const int j = (int)it.get_group(1);
                    const int tid = (int)it.get_local_id(0);
                    const int e = chunks[j].expert;
                    const int m = chunks[j].m;
                    const int cG = blk * 128 + tid;
                    const uint16_t* suhd = (const uint16_t*)tab[(F_SUH * 3 + CAT_DOWN) * E + e];
                    const float sd = f16(suhd[blk * 128 + tid]);
                    const uint16_t* svhu = (const uint16_t*)tab[(F_SVH * 3 + CAT_UP) * E + e];
                    const uint16_t* bu   = (const uint16_t*)tab[(F_BIAS * 3 + CAT_UP) * E + e];
                    const int slotg = gated ? j * 2 : j;      // int8 slots: gateless uses j
                    const int slotu = gated ? j * 2 + 1 : j;
                    const int nq = nsl8_gu;
                    const int32_t* ag = accgu + (size_t)slotg * nq * I8R * I;
                    const int32_t* au = accgu + (size_t)slotu * nq * I8R * I;
                    // slice sums are exact i32 (partials bounded by the same |C| limit)
                    auto accsum = [&](const int32_t* base, size_t row) -> int {
                        int s = 0;
                        for (int qq = 0; qq < nq; ++qq) s += base[((size_t)qq * I8R + row) * I + cG];
                        return s;
                    };
                    const Affine* qg = qsxu + slotg * I8R;
                    const Affine* qu = qsxu + slotu * I8R;
                    const float hu = HAD_SCALE * f16(svhu[cG]);
                    const float bj = bu ? f16(bu[cG]) : 0.0f;
                    float hgv = 0.f, biv = 0.f;
                    if (gated) {
                        const uint16_t* svhg = (const uint16_t*)tab[(F_SVH * 3 + CAT_GATE) * E + e];
                        const uint16_t* bg = (const uint16_t*)tab[(F_BIAS * 3 + CAT_GATE) * E + e];
                        hgv = HAD_SCALE * f16(svhg[cG]);
                        biv = bg ? f16(bg[cG]) : 0.0f;
                    }
                    for (int r = 0; r < m; ++r) {
                        // token r lives in fragment (r>>2) at rows rr, rr+1 of its slot
                        const int rr = i8_row_of(r);
                        float bfold_g = 0.f, bfold_u = 0.f;
                        const Affine up0 = qu[rr], up1 = qu[rr + 1];              // up parts
                        if (gated) {
                            const Affine gt0 = qg[rr], gt1 = qg[rr + 1];          // gate parts
                            sh[tid]       = gt0.A * (float)accsum(ag, rr)
                                          + gt1.A * (float)accsum(ag, rr + 1);
                            sh[128 + tid] = up0.A * (float)accsum(au, rr)
                                          + up1.A * (float)accsum(au, rr + 1);
                            bfold_g = 128.0f * (gt0.B + gt1.B);
                            bfold_u = 128.0f * (up0.B + up1.B);
                        } else {
                            sh[tid] = up0.A * (float)accsum(au, rr)
                                    + up1.A * (float)accsum(au, rr + 1);
                            bfold_u = 128.0f * (up0.B + up1.B);
                        }
                        if (gated) {
                            hadamard128(it, tid, sh.get_pointer());
                            hadamard128(it, tid, sh.get_pointer() + 128);
                            if (tid == 0) { sh[0] += bfold_g; sh[128] += bfold_u; }
                            const float gv = sh[tid] * hgv + biv;
                            const float uv = sh[128 + tid] * hu + bj;
                            float av;
                            switch (act) {
                                case 0: {
                                    const float eg = std::exp(std::min(-gv, 80.0f));
                                    av = std::min(gv / (1.0f + eg), lim) * sycl::clamp(uv, -lim, lim);
                                    break; }
                                case 1: {
                                    const float cdf = 0.5f * (1.0f + erff(gv * 0.70710678f));
                                    av = std::min(gv * cdf, lim) * sycl::clamp(uv, -lim, lim);
                                    break; }
                                case 3: {
                                    const float gvc = std::min(gv, lim);
                                    const float uvc = sycl::clamp(uv, -lim, lim);
                                    av = (uvc + 1.0f) * gvc / (1.0f + std::exp(std::min(-1.702f * gvc, 80.0f)));
                                    break; }
                                default: av = gv; break;
                            }
                            sh[tid] = av * sd;   // fused down-prep: scale then SLM Hadamard
                        } else {
                            hadamard128(it, tid, sh.get_pointer());
                            if (tid == 0) sh[0] += bfold_u;
                            const float uv = sh[tid] * hu + bj;
                            const float rv = uv > 0.0f ? uv : 0.0f;
                            sh[tid] = rv * rv * sd;
                        }
                        sycl::group_barrier(it.get_group());
                        hadamard128(it, tid, sh.get_pointer());
                        tind[(size_t)j * MAXM * I + (size_t)r * I + cG] = sh[tid] * HAD_SCALE;
                        sycl::group_barrier(it.get_group());
                    }
                });
            });
        }

        // Q2 + K5p: quantize the down input, DPAS gemm over the down matrices
        launchN("i8-k34", [&](sycl::handler& cgh) {
            sycl::local_accessor<float, 1> red({256}, cgh);
            cgh.parallel_for(sycl::nd_range<2>({256, (size_t)I8R * nc}, {256, 1}),
                QuantIn{ tind, w_a8d, qsxd, chunks, I, 1, 1, slim ? 0 : 1, red });
        });
        {
            g8.a8 = w_a8d; g8.acc = accd8; g8.nfl = H / 16; g8.down = 1; g8.nsl = nsl8_d;
            static const int wide_ok_d = []{
                const char* e = std::getenv("EXL3_MOE_I8W");
                return e && e[0] == '1';
            }();
            static const int ring_ok_d = []{
                const char* e = std::getenv("EXL3_MOE_I8RING");
                return !e || e[0] != '0';   // default ON (see gu launcher)
            }();
            const bool wide = wide_ok_d && (H / 16) % 8 == 0 && (k2 == 4 || k2 == 5 || k2 == 8); // I8W lab variant frozen to the trio
            const bool ring = ring_ok_d && (H / 16) % 8 == 0 && (!slim || slim_ring_ok);
            const size_t g0 = (wide || ring) ? (size_t)(H / 16 / 8) * 128 * nsl8_d
                                   : (size_t)(H / 16) * 16 * nsl8_d;
            if (bucketed) {                                  // see the gu launcher above
                launchN("i8-gemv-dn", [&](sycl::handler& cgh) {
                    sycl::local_accessor<unsigned char, 1> slm({ring ? (size_t)I8_SLM_BYTES : (size_t)I8_SLAB_SUB}, cgh);
                    Gemv8Base g = g8; g.slot_base = 0;
                    const size_t gn = ring ? (size_t)(H / 16 / 8) * 128 * nsl8_d
                                           : (size_t)(H / 16) * 16 * nsl8_d;
                    k2_dpas(k2, [&](auto R) {
                        constexpr int V = decltype(R)::value;
                        if constexpr (V > 0) {
                            if (ring)
                                cgh.parallel_for(sycl::nd_range<2>({gn, (size_t)n_narrow}, {128, 1}),
                                                 Gemv8<V, 8, 1, true>{g, slm});
                            else
                                cgh.parallel_for(sycl::nd_range<2>({gn, (size_t)n_narrow}, {16, 1}),
                                                 Gemv8<V, 1, 1>{g, slm});
                        } else throw std::logic_error("k2_dpas: tier chosen for an un-specialized rate");
                    });
                });
                launchN("i8-gemv-dn", [&](sycl::handler& cgh) {
                    sycl::local_accessor<unsigned char, 1> slm({ring ? (size_t)I8_SLM_BYTES : (size_t)I8_SLAB_SUB}, cgh);
                    Gemv8Base g = g8; g.slot_base = n_narrow;
                    const size_t gw = ring ? (size_t)(H / 16 / 8) * 128 * nsl8_d
                                           : (size_t)(H / 16) * 16 * nsl8_d;
                    k2_dpas(k2, [&](auto R) {
                        constexpr int V = decltype(R)::value;
                        if constexpr (V > 0) {
                            if (ring)
                                cgh.parallel_for(sycl::nd_range<2>({gw, (size_t)(nc - n_narrow)}, {128, 1}),
                                                 Gemv8<V, 8, I8_FRAGS, true>{g, slm});
                            else
                                cgh.parallel_for(sycl::nd_range<2>({gw, (size_t)(nc - n_narrow)}, {16, 1}),
                                                 Gemv8<V, 1, I8_FRAGS, false>{g, slm});
                        } else throw std::logic_error("k2_dpas: tier chosen for an un-specialized rate");
                    });
                });
            } else
            launchN("i8-gemv-dn", [&](sycl::handler& cgh) {
                sycl::local_accessor<unsigned char, 1> slm({ring ? (size_t)I8_SLM_BYTES
                                                          : (wide ? 8u * I8_SLAB_SUB : 1u * I8_SLAB_SUB)}, cgh);
                if (ring) {
                    k2_dpas(k2, [&](auto R) {
                        constexpr int V = decltype(R)::value;
                        if constexpr (V > 0)
                            cgh.parallel_for(sycl::nd_range<2>({g0, (size_t)nc}, {128, 1}), Gemv8<V, 8, I8_FRAGS, true>{g8, slm});
                        else throw std::logic_error("k2_dpas: tier chosen for an un-specialized rate");
                    });
                    return;
                }
                if (slim) {
                    k2_dpas(k2, [&](auto R) {
                        constexpr int V = decltype(R)::value;
                        if constexpr (V > 0)
                            cgh.parallel_for(sycl::nd_range<2>({g0, (size_t)nc}, {16, 1}), Gemv8<V, 1, 1>{g8, slm});
                        else throw std::logic_error("k2_dpas: tier chosen for an un-specialized rate");
                    });
                    return;
                }
                if (wide) {
                    switch (k2) {
                        case 4: cgh.parallel_for(sycl::nd_range<2>({g0, (size_t)nc}, {128, 1}), Gemv8<4, 8>{g8, slm}); break;
                        case 5: cgh.parallel_for(sycl::nd_range<2>({g0, (size_t)nc}, {128, 1}), Gemv8<5, 8>{g8, slm}); break;
                        default: cgh.parallel_for(sycl::nd_range<2>({g0, (size_t)nc}, {128, 1}), Gemv8<8, 8>{g8, slm}); break;
                    }
                    return;
                }
                k2_dpas(k2, [&](auto R) {
                    constexpr int V = decltype(R)::value;
                    if constexpr (V > 0)
                        cgh.parallel_for(sycl::nd_range<2>({g0, (size_t)nc}, {16, 1}), Gemv8<V, 1>{g8, slm});
                    else throw std::logic_error("k2_dpas: tier chosen for an un-specialized rate");
                });
            });
        }

        // K6i8: down out-transform + weighted gather. OWNER-GATHER layout: one workgroup
        // per (128-column block, token); the owner walks its token's tmap entries, so
        // `out` needs NO pre-zeroing (a memset command used to lead this stage) and no
        // fp atomics - and the ascending-entry accumulation order now MATCHES the CPU
        // reference exactly instead of racing. Sum per entry is identical to the old
        // scatter kernel; only the combining schedule changed.
        {
            const int nbk = H / 128;
            const int nent = (int)tmap.entry.size();
            if (nent) {
                launchN("i8-gemv-dn", [&](sycl::handler& cgh) {
                    sycl::local_accessor<float, 1> sh({128}, cgh);
                    cgh.parallel_for(sycl::nd_range<2>({(size_t)nbk * 128, (size_t)rows}, {128, 1}),
                        [=](sycl::nd_item<2> it) {
                        const int blk = (int)it.get_group(0);
                        const int t = (int)it.get_group(1);
                        const int tid = (int)it.get_local_id(0);
                        const int cG = blk * 128 + tid;
                        const int eb = d_tokb[t], ee = d_tokb[t + 1];
                        float acc = 0.f;
                        for (int p = eb; p < ee; ++p) {
                            const int ent = d_toke[p];
                            const int j = ent >> MOE_MAXM_SHIFT, s = ent & (MOE_MAXM - 1);
                            const int e = chunks[j].expert;
                            const float wgt = chunks[j].weight[s];
                            const uint16_t* svhe = (const uint16_t*)tab[(F_SVH * 3 + CAT_DOWN) * E + e];
                            const uint16_t* be = (const uint16_t*)tab[(F_BIAS * 3 + CAT_DOWN) * E + e];
                            const int rs = i8_row_of(s);                 // token -> I8R-row slot rows
                            const Affine cd0 = qsxd[j * I8R + rs], cd1 = qsxd[j * I8R + rs + 1];
                            const int nq = nsl8_d;
                            const int32_t* ad = accd8 + (size_t)j * nq * I8R * H;
                            int s0 = 0, s1 = 0;
                            for (int qq = 0; qq < nq; ++qq) {
                                s0 += ad[((size_t)qq * I8R + rs) * H + cG];
                                s1 += ad[((size_t)qq * I8R + rs + 1) * H + cG];
                            }
                            if (p > eb) sycl::group_barrier(it.get_group());   // sh WAR guard
                            sh[tid] = cd0.A * (float)s0 + cd1.A * (float)s1;
                            hadamard128(it, tid, sh.get_pointer());
                            if (tid == 0) sh[0] += 128.0f * (cd0.B + cd1.B);
                            float v = sh[tid] * (HAD_SCALE * f16(svhe[cG]));
                            if (be) v += f16(be[cG]);
                            acc += wgt * v;
                        }
                        out[(size_t)t * H + cG] = acc;
                    });
                });
            } else {
                dep = q.memset(out, 0, (size_t)rows * H * sizeof(float), {dep});
                if (prof) pev.push_back(dep);
            }
        }
        return dep;
    }

    // ---- K2/K5: GEMV over mul1 tiles for one matrix class
    // Column-block width for the single-slot (decode) path. lab_gemv_shape measured, at fixed
    // total lanes and fixed bytes: NCWG 128 -> 64.9 us, 64 -> 33.2, 32 -> 18.0, 16 -> 10.9,
    // 256 -> 130.3, while pipeline DEPTH 1/2/4 was within 0.2 us. Inverse-proportional to the
    // WORKGROUP COUNT at constant work = work DISTRIBUTION granularity, not per-lane latency.
    // Narrowing N is free where splitting K (nsl) is not: no partial sums, no second reduction,
    // and each column's k accumulation order is untouched, so output is bit-identical per column.
    // 128 == shipped behaviour; MOE_GEMV_NC is the A/B knob.
    static const int gemv_nc_req = []{ const char* e = getenv("MOE_GEMV_NC");
                                      return e ? atoi(e) : 128; }();
    GemvBase gb;
    gb.tab = d_tab; gb.chunks = w_chunk;
    gb.tin = w_tin; gb.tout = w_tout; gb.tind = w_tind; gb.toutd = w_toutd;
    gb.E = E; gb.nc = nc; gb.nm = nm; gb.H = H; gb.I = I; gb.gated = gated ? 1 : 0;
    gb.nsl = nsl;
    auto gemv = [&](bool down) {
        gb.tiles_n = (down ? H : I) / 16;
        gb.tiles_k = (down ? I : H) / 16;
        gb.down = down ? 1 : 0;
        gb.nsl = down ? NSL_D : NSL_GU;
        // single-slot chunks (decode) take the MMA=false specialization: the m>1 FMA chains
        // were predicated off but still issued ~30% of the inner loop (VTune, Xe2)
        const bool single = down ? (maxm_rows == 1) : (maxm_nm == 1);
        const int Nx = down ? H : I;
        int ncwg = gemv_nc_req;
        // narrow only the GemvK single-slot path: GemvFallback and the MMA variant hardcode 128,
        // and ncwg must split N into whole 16-column trellis tiles.
        if (!single || !moe_k2_float(k2) || ncwg < 16 || (ncwg & 15) || (Nx % ncwg) != 0) ncwg = 128;
        gb.ncwg = ncwg;
        gb.nbk = Nx / ncwg;
        const int units = (down ? nc * gb.nbk : nc * nm * gb.nbk) * gb.nsl;
        const size_t gn = (size_t)units * ncwg;
        if (hpf) { static int geo_logged[2] = {};   // one-time geometry echo (host-only diagnostic)
            if (!geo_logged[down ? 1 : 0]) { geo_logged[down ? 1 : 0] = 1;
                printf(" -- gemv geometry: down=%d single=%d ncwg=%d nbk=%d units=%d nsl=%d gn=%zu\n",
                       down, single, ncwg, gb.nbk, units, gb.nsl, gn); } }
        launchN("gemv", [&](sycl::handler& cgh) {
            k2_float(k2, [&](auto R) {
                constexpr int V = decltype(R)::value;
                if constexpr (V > 0) {
                    if (single) cgh.parallel_for(sycl::nd_range<1>({gn}, {(size_t)ncwg}), GemvK<V, false>{gb});
                    else        cgh.parallel_for(sycl::nd_range<1>({gn}, {128}), GemvK<V, true>{gb});
                } else
                    cgh.parallel_for(sycl::nd_range<1>({gn}, {128}), GemvFallback{gb, k2});
            });
        });
    };

    int* d_dbg = nullptr;
    static const int coop_lab = []{ const char* e = getenv("EXL3_MOE_B70_COOP_LAB"); return e ? atoi(e) : 0; }();
    if (coop_dbg && (coopGU || coopD)) {
        if (!coop_dbg_buf) { coop_dbg_buf = sycl::malloc_device<int>(8, q); q.memset(coop_dbg_buf, 0, 32); q.wait(); }
        dep = q.memset(coop_dbg_buf, 0, 32, {dep});   // lab-only extra memset, chained
        d_dbg = coop_dbg_buf;
    }
    if (coopGU) {
        // K1 stays; K2 + K34 fuse via ctrG[(j, blkI)] arrivals (see CoopGuK)
        gb.tiles_n = I / 16; gb.tiles_k = H / 16; gb.nbk = I / 128;
        gb.down = 0; gb.nsl = NSL_GU;
        const int units = nc * nm * gb.nbk * NSL_GU;
        const size_t gn = (size_t)units * 128;
        int* d_ctrG = (int*)((char*)w_chunk + off_ctr);
        const int a_ = P.activation;
        const float l_ = lim;
        launchN("coopgu", [&](sycl::handler& cgh) {
            sycl::local_accessor<float, 1> sh({256}, cgh);
            sycl::local_accessor<int, 1> flg({2}, cgh);
            k2_float(k2, [&](auto R) {
                constexpr int V = decltype(R)::value;
                if constexpr (V > 0) {
                    if (maxm_nm == 1)
                        cgh.parallel_for(sycl::nd_range<1>({gn}, {128}),
                            CoopGuK<V, false>{gb, d_ctrG, d_dbg, w_tind, a_, l_, coop_lab, sh, flg});
                    else
                        cgh.parallel_for(sycl::nd_range<1>({gn}, {128}),
                            CoopGuK<V, true>{gb, d_ctrG, d_dbg, w_tind, a_, l_, coop_lab, sh, flg});
                }
            });
        });
    } else {
        gemv(false);

        // ---- K3+K4 fused: out transform (hadamard + svh + bias) + activation + down-prep
        // (activation h never leaves the workgroup: down-side suh/Hadamard run on the same
        // 128-column tile while it is in SLM; saves a global roundtrip and a submit)
        {
            const int nbk = I / 128;
        launchN("K34-act", [&](sycl::handler& cgh) {
            sycl::local_accessor<float, 1> sh({256}, cgh);
            cgh.parallel_for(sycl::nd_range<2>({(size_t)nbk * 128, (size_t)nc}, {128, 1}),
                [=](sycl::nd_item<2> it) {
                const int blk = (int)it.get_group(0);
                const int j = (int)it.get_group(1);
                const int tid = (int)it.get_local_id(0);
                const int e = chunks[j].expert;
                const int m = chunks[j].m;
                const int cG = blk * 128 + tid;
                const uint16_t* suhd = (const uint16_t*)tab[(F_SUH * 3 + CAT_DOWN) * E + e];
                const float sd = f16(suhd[blk * 128 + tid]);
                const uint16_t* svhu = (const uint16_t*)tab[(F_SVH * 3 + CAT_UP) * E + e];
                const uint16_t* bu   = (const uint16_t*)tab[(F_BIAS * 3 + CAT_UP) * E + e];
                const int mu_up = gated ? 1 : 0;   // gateless gemv stored up at slot j*2+0
                const float* tg = tout + (size_t)(j * 2) * NSL_GU * MAXM * I;
                const float* tu = tout + (size_t)(j * 2 + mu_up) * NSL_GU * MAXM * I;
                float hg = 0.f, bi = 0.f;
                if (gated) {
                    const uint16_t* svhg = (const uint16_t*)tab[(F_SVH * 3 + CAT_GATE) * E + e];
                    const uint16_t* bg = (const uint16_t*)tab[(F_BIAS * 3 + CAT_GATE) * E + e];
                    hg = HAD_SCALE * f16(svhg[cG]);
                    bi = bg ? f16(bg[cG]) : 0.0f;
                }
                const float hu = HAD_SCALE * f16(svhu[cG]);
                const float bj = bu ? f16(bu[cG]) : 0.0f;
                for (int r = 0; r < m; ++r) {
                    if (gated) {
                        {
                            float sg = 0.f, su = 0.f;
                            for (int qq = 0; qq < NSL_GU; ++qq) {
                                sg += tg[(size_t)qq * MAXM * I + (size_t)r * I + cG];
                                su += tu[(size_t)qq * MAXM * I + (size_t)r * I + cG];
                            }
                            sh[tid] = sg; sh[128 + tid] = su;
                        }
                        hadamard128(it, tid, sh.get_pointer());
                        hadamard128(it, tid, sh.get_pointer() + 128);
                        const float gv = sh[tid] * hg + bi;
                        const float uv = sh[128 + tid] * hu + bj;
                        float av;
                        switch (act) {
                            case 0: {
                                const float eg = std::exp(std::min(-gv, 80.0f));
                                av = std::min(gv / (1.0f + eg), lim) * sycl::clamp(uv, -lim, lim);
                                break; }
                            case 1: {
                                const float cdf = 0.5f * (1.0f + erff(gv * 0.70710678f));
                                av = std::min(gv * cdf, lim) * sycl::clamp(uv, -lim, lim);
                                break; }
                            case 3: {
                                const float gvc = std::min(gv, lim);
                                const float uvc = sycl::clamp(uv, -lim, lim);
                                av = (uvc + 1.0f) * gvc / (1.0f + std::exp(std::min(-1.702f * gvc, 80.0f)));
                                break; }
                            default: av = gv; break;
                        }
                        sh[tid] = av * sd;   // fused down-prep: scale then SLM Hadamard
                    } else {
                        {
                            float su = 0.f;
                            for (int qq = 0; qq < NSL_GU; ++qq)
                                su += tu[(size_t)qq * MAXM * I + (size_t)r * I + cG];
                            sh[tid] = su;
                        }
                        hadamard128(it, tid, sh.get_pointer());
                        const float uv = sh[tid] * hu + bj;
                        const float rv = uv > 0.0f ? uv : 0.0f;
                        sh[tid] = rv * rv * sd;
                    }
                    sycl::group_barrier(it.get_group());
                    hadamard128(it, tid, sh.get_pointer());
                    tind[(size_t)j * MAXM * I + (size_t)r * I + cG] = sh[tid] * HAD_SCALE;
                    sycl::group_barrier(it.get_group());
                }
            });
        });
    }
    }   // !coopGU

    // ---- K5+K6 fused (coop float tier) or classic gemv + owner-gather K6
    if (coopD) {
        gb.tiles_n = H / 16; gb.tiles_k = I / 16; gb.nbk = H / 128;
        gb.down = 1; gb.nsl = NSL_D;
        const int units = nc * gb.nbk * NSL_D;
        const size_t gn = (size_t)(units + rows * gb.nbk) * 128;
        int* d_ctr1 = (int*)((char*)w_chunk + off_ctr) + ctrG_n;
        int* d_ctr2 = d_ctr1 + (NSL_D == 1 ? 0 : (int)tmap.entry.size() * gb.nbk);
        float* d_tsw = w_tsw;
        static const int coop_lab = []{ const char* e = getenv("EXL3_MOE_B70_COOP_LAB"); return e ? atoi(e) : 0; }();
        const bool nsl1 = (NSL_D == 1);
        launchN("K56-coopdn", [&](sycl::handler& cgh) {
            sycl::local_accessor<float, 1> sh({128}, cgh);
            sycl::local_accessor<int, 1> flg({2}, cgh);
            k2_float(k2, [&](auto R) {
                constexpr int V = decltype(R)::value;
                if constexpr (V > 0) {
                    if (maxm_rows == 1) {
                        if (nsl1) cgh.parallel_for(sycl::nd_range<1>({gn}, {128}),
                            CoopDownK<V, false, true>{.b = gb, .ctr1 = d_ctr1, .ctr2 = d_ctr2, .tsw = d_tsw, .dbg = d_dbg,
                                .tokb = d_tokb, .toke = d_toke, .out = out, .nUnits = units,
                                .rows = rows, .lab = coop_lab, .sh = sh, .flg = flg});
                        else cgh.parallel_for(sycl::nd_range<1>({gn}, {128}),
                            CoopDownK<V, false, false>{.b = gb, .ctr1 = d_ctr1, .ctr2 = d_ctr2, .tsw = d_tsw, .dbg = d_dbg,
                                .tokb = d_tokb, .toke = d_toke, .out = out, .nUnits = units,
                                .rows = rows, .lab = coop_lab, .sh = sh, .flg = flg});
                    } else {
                        if (nsl1) cgh.parallel_for(sycl::nd_range<1>({gn}, {128}),
                            CoopDownK<V, true, true>{.b = gb, .ctr1 = d_ctr1, .ctr2 = d_ctr2, .tsw = d_tsw, .dbg = d_dbg,
                                .tokb = d_tokb, .toke = d_toke, .out = out, .nUnits = units,
                                .rows = rows, .lab = coop_lab, .sh = sh, .flg = flg});
                        else cgh.parallel_for(sycl::nd_range<1>({gn}, {128}),
                            CoopDownK<V, true, false>{.b = gb, .ctr1 = d_ctr1, .ctr2 = d_ctr2, .tsw = d_tsw, .dbg = d_dbg,
                                .tokb = d_tokb, .toke = d_toke, .out = out, .nUnits = units,
                                .rows = rows, .lab = coop_lab, .sh = sh, .flg = flg});
                    }
                }   // k2_float(V==-1) cannot reach here: coopD requires moe_k2_float(k2)
            });
        });
        return dep;
    }

    gemv(true);

    // ---- K6: down out-transform + weighted gather into out. OWNER-GATHER (see the K6i8
    // comment): one workgroup per (128-column block, token); no `out` memset, no atomics,
    // and the accumulation order matches the CPU reference.
    {
        const int nbk = H / 128;
        const int nent = (int)tmap.entry.size();
        if (nent) {
            launchN("K6-gather", [&](sycl::handler& cgh) {
                sycl::local_accessor<float, 1> sh({128}, cgh);
                cgh.parallel_for(sycl::nd_range<2>({(size_t)nbk * 128, (size_t)rows}, {128, 1}),
                    [=](sycl::nd_item<2> it) {
                    const int blk = (int)it.get_group(0);
                    const int t = (int)it.get_group(1);
                    const int tid = (int)it.get_local_id(0);
                    const int cG = blk * 128 + tid;
                    const int eb = d_tokb[t], ee = d_tokb[t + 1];
                    float acc = 0.f;
                    for (int p = eb; p < ee; ++p) {
                        const int ent = d_toke[p];
                        const int j = ent >> MOE_MAXM_SHIFT, s = ent & (MOE_MAXM - 1);   // MOE_MAXM=8 encoding (host chunker)
                        const int e = chunks[j].expert;
                        const float wgt = chunks[j].weight[s];
                        const uint16_t* svhe = (const uint16_t*)tab[(F_SVH * 3 + CAT_DOWN) * E + e];
                        const uint16_t* be = (const uint16_t*)tab[(F_BIAS * 3 + CAT_DOWN) * E + e];
                        float sv = 0.f;
                        for (int qq = 0; qq < NSL_D; ++qq)
                            sv += toutd[((size_t)(j * NSL_D + qq) * MAXM + s) * H + cG];
                        if (p > eb) sycl::group_barrier(it.get_group());   // sh WAR guard
                        sh[tid] = sv;
                        hadamard128(it, tid, sh.get_pointer());
                        float v = sh[tid] * (HAD_SCALE * f16(svhe[cG]));
                        if (be) v += f16(be[cG]);
                        acc += wgt * v;
                    }
                    out[(size_t)t * H + cG] = acc;
                });
            });
        } else {
            dep = q.memset(out, 0, (size_t)rows * H * sizeof(float), {dep});
            if (prof) pev.push_back(dep);
        }
    }
    return dep;
}

} // namespace moe_sycl