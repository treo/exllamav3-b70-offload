// SYCL MoE expert forward implementation. Mirrors the fp/scalar semantics of
// exllamav3/exllamav3_ext/cpu/moe_mul1.cpp: prep (suh + block hadamard) -> GEMV over packed
// mul1 tiles -> out transform (hadamard + svh + bias) -> activation -> down GEMV -> weighted
// gather.
//
// All control data (chunks, token CSR) travels in ONE host->device blob memcpy. Every kernel
// is chained with explicit depends_on events (required on this L0 stack, see NOTES.md).
// GEMV: work group = (chunk, matrix, 128-column block); each 16-lane sub-group owns one
// 16x16 tile column strip; packed tile words are staged through shared memory, double
// buffered over k.
#include "moe_sycl.hpp"
#include <sycl/ext/oneapi/matrix/matrix.hpp>
#ifdef MOE_GEMV_CACHEHINT
#include <sycl/ext/intel/experimental/cache_control_properties.hpp>
#include <sycl/ext/oneapi/experimental/annotated_ptr/annotated_ptr.hpp>
namespace expe = sycl::ext::oneapi::experimental;
namespace inte = sycl::ext::intel::experimental;
// weights are read exactly once per gemv: stream through L1/L2
inline constexpr auto g_read_hint = inte::read_hint<inte::cache_control<
    inte::cache_mode::streaming, expe::cache_level::L1, expe::cache_level::L2>>;
using AP_W = expe::annotated_ptr<const uint32_t, decltype(expe::properties{g_read_hint})>;
#endif
#include <cmath>
#include <cstdlib>
#include <cstring>

namespace moe_sycl {

size_t g_alloc_bytes = 0;

namespace {

constexpr float KDQ = 0.00676727294921875f;   // k_inv = fp16(0x1eee)
constexpr float HAD_SCALE = 0.088388347648f;  // 1/sqrt(128)
constexpr int MAXM = 4;

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
    d_tab = sycl::malloc_device<uintptr_t>(tab.size(), *q);
    q->memcpy(d_tab, tab.data(), tab.size() * sizeof(uintptr_t)).wait();
}

MoeSyclLayer::~MoeSyclLayer()
{
    auto freep = [&](auto*& p) { if (p) { sycl::free(p, *Q); p = nullptr; } };
    freep(d_tab);
    freep(w_chunk);   // scratch buffers belong to the process-wide pool
}

// Process-wide workspace pool: the worker forwards one layer at a time, so all layers share
// one set of scratch buffers (per-layer ws blew the B70 budget: 31 layers x ~600 MB).
namespace {
struct WsPool { void* buf[12] = {}; size_t cap[12] = {}; };
WsPool g_ws;
}

void MoeSyclLayer::ensure_ws(int nc, int rows)
{
    auto grow_p = [&](int slot, auto*& p, size_t count) {
        using T = std::remove_pointer_t<std::remove_reference_t<decltype(p)>>;
        if (g_ws.buf[slot] && count <= g_ws.cap[slot]) { p = (T*)g_ws.buf[slot]; return; }
        if (g_ws.buf[slot]) { sycl::free(g_ws.buf[slot], *Q); g_alloc_bytes -= g_ws.cap[slot] * sizeof(T); }
        T* np = sycl::malloc_device<T>(count, *Q);
        if (!np) fprintf(stderr, "[b70moe] OOM workspace alloc %zu x %zu\n", count, sizeof(T));
        g_ws.buf[slot] = np;
        g_ws.cap[slot] = np ? count : 0;
        g_alloc_bytes += np ? count * sizeof(T) : 0;
        p = np;
        if (!p) return;
        // prefault so device page tables are populated before the kernel pipeline runs
        Q->memset(p, 0, count * sizeof(T));
        Q->wait();
    };
    if (nc > cap_nc) {
        grow_p(0, w_tin,   (size_t)nc * 2 * MAXM * P.hidden);
        grow_p(1, w_tout,  (size_t)nc * 2 * 8 * MAXM * P.interm);
        grow_p(2, w_h,     (size_t)nc * MAXM * P.interm);
        grow_p(3, w_tind,  (size_t)nc * MAXM * P.interm);
        grow_p(4, w_toutd, (size_t)nc * 8 * MAXM * P.hidden);
        if (use8) {
            // int8 pipeline slabs (sizes independent of the fp32 slice buffers)
            grow_p(5, w_a8u,   (size_t)nc * 2 * (P.hidden / 8) * 64);
            grow_p(6, w_a8d,   (size_t)nc * (P.interm / 8) * 64);
            grow_p(7, w_qsxu,  (size_t)nc * 2 * 8 * 2);
            grow_p(8, w_qsxd,  (size_t)nc * 8 * 2);
            grow_p(9, w_accgu, (size_t)nc * 2 * 8 * P.interm);
            grow_p(10, w_accd, (size_t)nc * 8 * P.hidden);
        }
        cap_nc = nc;
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
        const size_t row_step = (size_t)b.tiles_n * W;
        const int tk_lo = (b.tiles_k * sl) / b.nsl;
        const int tk_hi = (b.tiles_k * (sl + 1)) / b.nsl;
        const uint32_t* wp = w32 + (size_t)tile_n * W + (size_t)tk_lo * row_step;
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
        const uint32_t* wp = w32 + ((size_t)tk_lo * b.tiles_n + tile_n) * tile_u32;
        const float* tp = src_tin + tk_lo * 16;
        const int tn_stride = (int)(b.tiles_n * tile_u32);
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

// ------------------------------------------------------------------ forward

namespace mx8 = sycl::ext::oneapi::experimental::matrix;

// amax-row quantization mirroring CPU quantize_row() single-slot path exactly:
// q = amax>0 ? amax/127 : 1; x8 = clamp(lround(x/q), +-127); splat word = x8*0x01010101
// (== one DPAS A-row entry per real k). Writes the affine epilogue pair
// {A=KDQ*q, B=-510*KDQ*q*sum_x8} so consumers need one fma per element.
// per-gemv-row epilogue affine: value = A * acc + B (elementwise, pre out-transform)
struct Affine { float A, B; };

struct QuantIn
{
    const float* __restrict__ tin;     // [tslots][MAXM][k]
    int32_t* __restrict__ a8;          // [slots][k/8][8 rows][8 i32]
    Affine* __restrict__ qsb;          // [slots][8]
    const ChunkDev* chunks;
    int slots, k, nm, tsmul;           // tin slot = slot * tsmul (gateless gu rows live at j*2)
    sycl::local_accessor<float, 1> red;
    void operator()(sycl::nd_item<2> it) const
    {
        const int slot = (int)it.get_group(1) >> 3;    // QuantIn: group(1) = slot*8 + row
        const int r = (int)it.get_group(1) & 7;
        const int tid = (int)it.get_local_id(0);     // 256
        const int m = chunks[slot / nm].m;
        const int tok = r >> 1, part = r & 1;        // ALWAYS-WIDE: token -> rows 2t (vh), 2t+1 (vl)
        const int kf = k / 8;
        int32_t* aout = a8 + (size_t)slot * kf * 64 + r * 8;
        if (tok >= m) {
            for (int i = tid; i < kf * 8; i += 256) aout[(i >> 3) * 64 + (i & 7)] = 0;
            if (tid == 0) qsb[slot * 8 + r] = Affine{ 0.f, 0.f };
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
        sycl::group_barrier(it.get_group());   // before overwriting red[] with the sx partials
        // CPU quantize_row_wide semantics, HALVED range: q = amax / 8192; v = clamp(round(x/q),
        // +-8128); vh = (v+64)>>7 (|vh| <= 64), vl = v - (vh<<7) (|vl| <= 127); row scales
        // {q*128, q}. Range bound is NOT cosmetic: Xe DPAS sums byte pairs as SATURATED i16
        // (unlike AVX-512 vpdpbusd's i32 lanes), and the mul1 product bytes span the full
        // u8 range, so |x8| > ~64 clamps pair partials (bc: 127*255*2 > 32767, 64*255*2 =
        // 32640 < 32768). This was the int8-tier blowup; probes with small A never hit it.
        // Every row goes wide, so the 8 dpas rows carry exactly MAX_M tokens x {vh, vl}.
        const float qw = am0 > 0.f ? am0 * (1.0f / 8192.0f) : 1.0f;
        const float rq = am0 > 0.f ? 8192.0f / am0 : 1.0f;
        float sacc = 0.f;
        for (int i = tid; i < k; i += 256) {
            const float vf = xr[i] * rq;
            int v = (int)(vf >= 0.f ? sycl::floor(vf + 0.5f) : sycl::ceil(vf - 0.5f));
            v = sycl::clamp(v, -8128, 8128);
            const int vh = (v + 64) >> 7;
            const int x8w = part ? (v - (vh << 7)) : vh;
            sacc += (float)x8w;
            // word (i>>3 frag base) + row r (stride 8, folded into aout) + slot (i&7):
            // the 4 bytes of that word ARE hwk 4q..4q+3, all carrying the same x8
            aout[(i >> 3) * 64 + (i & 7)] = x8w * 0x01010101;
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
            qsb[slot * 8 + r] = Affine{ Aq, -510.0f * Aq * red[0] };
        }
    }
};


// DPAS GEMV over the stream-repacked mul1 tiles. Work group = one (slot, 16-column
// fragment); 16 lanes = 16 columns of that tile, each keeping its own column window
// exactly like GemvK (compile-time extraction offsets). Per k-tile row the lane computes
// 16 product words (rows 0..15 x own column) and scatters them as packed-VNNI dwords:
// slab32[(fk*8 + (rk&7))*16 + col] = product word, fk = rk>>3 selecting the two k32
// fragments this tile row feeds. joint_matrix (M8 x N16 x K32-hwk, u8/s8) does the rest:
// C[r][c] = sum_wq x8[r][wq] * bytesum(prod(wq, c)) == mul1's int8-tier identity.
struct Gemv8Base
{
    const uintptr_t* tab;
    const ChunkDev* chunks;
    const int32_t* a8;       // operand slabs from QuantIn
    int32_t* acc;            // [slot][8][N] i32 (raw accumulator, KDQ/q folded later)
    int E, nc, nm, H, I, nfl, down;
};

template <int K2V>
struct Gemv8
{
    Gemv8Base b;
    sycl::local_accessor<unsigned char, 1> slab;

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
        const int nf = (int)it.get_group(0);
        const int slot = (int)it.get_group(1);
        const int tid = (int)it.get_local_id(0);
        const bool down = b.down != 0;
        const int j = down ? slot : slot / b.nm;
        const int lmu = down ? 0 : slot % b.nm;
        const int cat = down ? CAT_DOWN : (b.nm == 2 ? lmu : CAT_UP);
        const int e = b.chunks[j].expert;
        const int K = down ? b.I : b.H;
        const int N = down ? b.H : b.I;
        const int tiles_k = K / 16;
        const int tk_hi = tiles_k;
        const uint32_t* w32 = (const uint32_t*)(uintptr_t)b.tab[(F_TRI * 3 + cat) * b.E + e];

        const int cG = nf * 16 + tid;              // global output col of this lane
        const int tile_n = nf;                     // one tile == one fragment
        const int cin = tid & 15;
        const int A2 = (K2V * (32 * (cin & 7) + 4 * ((cin >> 3) & 1))) >> 1;
        const int G = (32 - (K2V >> 1)) - A2 - AD27;
        const int wb = G >> 5;
        const int pre = G - (wb << 5);
        int widx[NW];
#pragma unroll
        for (int i = 0; i < NW; ++i) widx[i] = ((wb + i) % W + W) % W;

        // lab_jm7-validated ping-pong: ONE 512B SLM slab per packed fragment object.
        // Staging 1024B through a 512B accessor made the second fragment of every tile
        // read zeros - the KS1 'missing fragment' symptom.
        unsigned char* const slp0 = slab.get_pointer().get();
        unsigned char* const slp1 = slab.get_pointer().get() + 512;
        const size_t row_step = (size_t)(N / 16) * W;
        const uint32_t* wp = w32 + (size_t)tile_n * W + 0;
        const int32_t* pa0 = b.a8 + ((size_t)slot * (K / 8)) * 64;   // [kfrag][64]

        sycl::sub_group sg = it.get_sub_group();
        mx8::joint_matrix<sycl::sub_group, signed char, mx8::use::a, 8, 32,
                          mx8::layout::row_major> ja;
        mx8::joint_matrix<sycl::sub_group, unsigned char, mx8::use::b, 32, 16,
                          mx8::layout::ext_intel_packed> jb;
        mx8::joint_matrix<sycl::sub_group, int, mx8::use::accumulator, 8, 16> jc;
        mx8::joint_matrix_fill(sg, jc, 0);

        for (int tk = 0; tk < tk_hi; ++tk, wp += row_step) {
            uint32_t g[NW];
#pragma unroll
            for (int i = 0; i < NW; ++i) g[i] = wp[widx[i]];
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
                const int dd = 8 * ((rk >> 1) & 3) + (rk & 1) + 2 * ((rk >> 3) & 1);
                const int rel = AD27 - ((K2V * dd + KE) >> 1);
                const uint32_t lo4 = h[rel >> 5], hi4 = h[(rel >> 5) + 1];
                const uint32_t st16 = ((lo4 >> (rel & 31)) | ((hi4 << 1) << (31u - (rel & 31)))) & 0xffffu;
                const uint32_t prod0 = st16 * 0x83DCD12Du;
                const uint32_t prod = prod0;
                // packed-VNNI staging (lab_jm7 addressing): quad row -> band (rk&7) of
                // this fragment's 512B slab, dword (rk&7)*16 + col
                uint32_t* slpw = (rk < 8) ? (uint32_t*)slp0 : (uint32_t*)slp1;
                slpw[(rk & 7) * 16 + cin] = prod;
            }
            sg.barrier();
            {
                // one tile row feeds TWO k32 fragments (rows 0-7, rows 8-15): 2x512B slab
#pragma unroll
                for (int fk = 0; fk < 2; ++fk) {
                    auto pag = sycl::address_space_cast<sycl::access::address_space::global_space,
                                                        sycl::access::decorated::yes>(
                        (const signed char*)(pa0 + (size_t)(2 * tk + fk) * 64));
                    mx8::joint_matrix_load(sg, ja, pag, 32);
                    mx8::joint_matrix_load(sg, jb,
                        sycl::address_space_cast<sycl::access::address_space::local_space,
                                                 sycl::access::decorated::yes>(
                            fk ? slp1 : slp0),
                        16 * 4);   // packed stride = N*VNNI
                    mx8::joint_matrix_mad(sg, jc, ja, jb, jc);
                }
            }
            sg.barrier();   // slab reuse safety before next tile's stores
        }
        auto pcg = sycl::address_space_cast<sycl::access::address_space::global_space,
                                            sycl::access::decorated::yes>(
            b.acc + (size_t)slot * 8 * N + nf * 16);
        mx8::joint_matrix_store(sg, jc, pcg, N, mx8::layout::row_major);
    }
};

sycl::event MoeSyclLayer::forward(const ChunkDev* chunks_host, int num_chunks, const TokenMap& tmap,
                                  const uint16_t* x, float* out, int rows, const sycl::event* pre_dep)
{
    const int H = P.hidden, I = P.interm;
    const int k2 = 2 * P.bits + P.hb;
    // EXL3_MOE_B70_INT8: =1 force int8 on (lab), =0 force off, unset -> struct default
    static const int g_int8_env = []{
        const char* e = std::getenv("EXL3_MOE_B70_INT8");
        return !e ? -1 : (e[0] == '0' ? 0 : e[0] == '1' ? 1 : -1);
    }();
    use8 = (g_int8_env >= 0 ? (bool)g_int8_env : int8) && (k2 == 4 || k2 == 5 || k2 == 6 || k2 == 8);
    const int E = P.num_experts;
    const int tile_u32 = 4 * k2;                    // u32 words per tile
    const bool gated = P.gated;
    const int nm = gated ? 2 : 1;
    const int act = P.activation;
    const float lim = P.act_limit != 0.0f ? P.act_limit : INFINITY;
    sycl::queue& q = *Q;
    ensure_ws(num_chunks, rows);

    // one H2D blob: [chunks][pad64][tokb][pad64][toke]
    const int nc = num_chunks;
    const size_t off_chunk = 0;
    const size_t off_tokb = ((size_t)nc * sizeof(ChunkDev) + 63) & ~(size_t)63;
    const size_t off_toke = (off_tokb + ((size_t)rows + 1) * sizeof(int) + 63) & ~(size_t)63;
    const size_t blob_sz = off_toke + tmap.entry.size() * sizeof(int);
    if (blob_sz > cap_blob) {
        if (h_blob) sycl::free(h_blob, q);
        if (h_blob2) sycl::free(h_blob2, q);
        h_blob = (char*)sycl::malloc_host(blob_sz, q);
        h_blob2 = (char*)sycl::malloc_host(blob_sz, q);
        if (w_chunk) sycl::free(w_chunk, q);
        w_chunk = (ChunkDev*)sycl::malloc_device<char>(blob_sz, q);
        q.memset(w_chunk, 0, blob_sz);
        q.wait();
        cap_blob = blob_sz;
    }
    h_flip = !h_flip;
    char* hb = h_flip ? h_blob : h_blob2;
    std::memcpy(hb + off_chunk, chunks_host, nc * sizeof(ChunkDev));
    std::memcpy(hb + off_tokb, tmap.begin.data(), tmap.begin.size() * sizeof(int));
    std::memcpy(hb + off_toke, tmap.entry.data(), tmap.entry.size() * sizeof(int));

    // NOTE: implicit in-order ordering between chained submits/memcpys is NOT enforced on
    // this stack (oneAPI 2026.2 + L0 + Xe2); explicit depends_on chains are required.
    sycl::event dep = pre_dep ? q.memcpy(w_chunk, hb, blob_sz, {*pre_dep})
                              : q.memcpy(w_chunk, hb, blob_sz);
    if (prof) { pev.clear(); pev.push_back(dep); }
    auto launch = [&](auto&& fn) {
        dep = q.submit([&](sycl::handler& cgh) { cgh.depends_on(dep); fn(cgh); });
        if (prof) pev.push_back(dep);
    };

    int maxm_rows = 1, maxm_nm = 1;
    for (int j = 0; j < nc; ++j) maxm_rows = std::max(maxm_rows, (int)chunks_host[j].m);
    maxm_nm = maxm_rows;   // (kept separate for future per-class relaxation)
    const int NSL_GU = [&]{
        int base = nc * nm * (I / 128), w = nsl;
        // auto up to 8: real-model decode (few rows, latency-bound) wants the extra
        // parallelism; synthetic E=12 benches disagreed, the model won the argument.
        if (w == 0) { w = 1; while (w < 8 && base * w * 128 < 80000) ++w;
                      if (maxm_rows > 1 && w > 4) w = 4; }   // multi-row: slice-sum traffic dominates
        return w;
    }();
    const int NSL_D = [&]{
        int base = nc * (H / 128), w = nsl;
        if (w == 0) { w = 1; while (w < 8 && base * w * 128 < 80000) ++w; if (w > 2) w = 2; }
        return w;
    }();
    const uintptr_t* tab = d_tab;
    const ChunkDev* chunks = w_chunk;
    const int* d_tokb = (const int*)((const char*)w_chunk + off_tokb);
    const int* d_toke = (const int*)((const char*)w_chunk + off_toke);
    float* tin = w_tin;
    float* tout = w_tout;
    float* hbuf = w_h;
    float* tind = w_tind;
    float* toutd = w_toutd;

    // ---- K1: prep gate/up inputs (suh scale + 128-block hadamard), from fp16 x
    {
        const int nbk = H / 128;
        launch([&](sycl::handler& cgh) {
            sycl::local_accessor<float, 1> sh({128}, cgh);
            cgh.parallel_for(sycl::nd_range<2>({(size_t)nbk * 128, (size_t)(nc * nm)}, {128, 1}),
                [=](sycl::nd_item<2> it) {
                const int blk = (int)it.get_group(0);
                const int unit = (int)it.get_group(1);
                const int tid = (int)it.get_local_id(0);
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

    // ---- int8 / XMX joint_matrix pipeline (CPU VNNI-tier semantics). Exact-i32
    // accumulators, nsl=1; the affine {KDQ*q, -510*KDQ*q*sum_x8} folds into act/gather.
    if (use8) {
        int32_t* const accgu = w_accgu;
        int32_t* const accd8 = w_accd;
        Affine* const qsxu = (Affine*)w_qsxu;
        Affine* const qsxd = (Affine*)w_qsxd;
        {
            launch([&](sycl::handler& cgh) {
                sycl::local_accessor<float, 1> red({ 256 }, cgh);
                cgh.parallel_for(sycl::nd_range<2>({ 256, (size_t)8 * nc * nm }, { 256, 1 }),
                    QuantIn{ w_tin, w_a8u, (Affine*)w_qsxu, chunks, nc * nm, H, nm,
                             nm == 2 ? 1 : 2, red });
            });
        }
        Gemv8Base g8{ d_tab, w_chunk, nullptr, nullptr, E, nc, nm, H, I, 0, 0 };
        {
            g8.a8 = w_a8u; g8.acc = w_accgu; g8.nfl = I / 16; g8.down = 0;
            launch([&](sycl::handler& cgh) {
                sycl::local_accessor<unsigned char, 1> slm({ 1024 }, cgh);
                switch (k2) {
                    case 4: cgh.parallel_for(sycl::nd_range<2>({ (size_t)(I / 16) * 16, (size_t)nc * nm }, { 16, 1 }), Gemv8<4>{g8, slm}); break;
                    case 5: cgh.parallel_for(sycl::nd_range<2>({ (size_t)(I / 16) * 16, (size_t)nc * nm }, { 16, 1 }), Gemv8<5>{g8, slm}); break;
                    case 6: cgh.parallel_for(sycl::nd_range<2>({ (size_t)(I / 16) * 16, (size_t)nc * nm }, { 16, 1 }), Gemv8<6>{g8, slm}); break;
                    default: cgh.parallel_for(sycl::nd_range<2>({ (size_t)(I / 16) * 16, (size_t)nc * nm }, { 16, 1 }), Gemv8<8>{g8, slm}); break;
                }
            });
        }
        {
            // K34i8: act + fused down-prep from i32 accumulators (clone of the fp32 K34
            // without slice sums; the per-row affine B term enters as 128*B at position 0
            // after the Hadamard, which is Hadamard(B*ones) exactly).
            const int nbk = I / 128;
            launch([&](sycl::handler& cgh) {
                sycl::local_accessor<float, 1> sh({ 256 }, cgh);
                cgh.parallel_for(sycl::nd_range<2>({ (size_t)nbk * 128, (size_t)nc }, { 128, 1 }),
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
                    // int8 acc/operand slots: gated slot(j*2+cat); gateless single slot j
                    const int slotu = gated ? j * 2 + mu_up : j;
                    const int slotg = j * 2;
                    const int32_t* ag = accgu + ((size_t)slotg * 8) * I;
                    const int32_t* au = accgu + ((size_t)slotu * 8) * I;
                    const int32_t* ags = gated ? ag : nullptr; (void)ags;
                    const Affine* qg = qsxu + slotg * 8;
                    const Affine* qu = qsxu + slotu * 8;
                    const Affine* qgs = gated ? qg : nullptr; (void)qgs;
                    const float hg = HAD_SCALE * (gated ? f16(((const uint16_t*)tab[(F_SVH * 3 + CAT_GATE) * E + e])[cG]) : 0.f);
                    const float bi = gated && bu ? 0.f : 0.f;   // recomputed per branch below
                    (void)hg; (void)bi;
                    const uint16_t* svhg = gated ? (const uint16_t*)tab[(F_SVH * 3 + CAT_GATE) * E + e] : nullptr;
                    const uint16_t* bg = gated ? (const uint16_t*)tab[(F_BIAS * 3 + CAT_GATE) * E + e] : nullptr;
                    const float hgv = gated ? HAD_SCALE * f16(svhg[cG]) : 0.f;
                    const float biv = gated && bg ? f16(bg[cG]) : 0.f;
                    const float hu = HAD_SCALE * f16(svhu[cG]);
                    const float bj = bu ? f16(bu[cG]) : 0.f;
                    for (int r = 0; r < m; ++r) {
                        if (gated) {
                            const Affine cg0 = qg[2 * r], cg1 = qg[2 * r + 1];
                            const Affine cu0 = qu[2 * r], cu1 = qu[2 * r + 1];
                            sh[tid]       = cg0.A * (float)ags[(size_t)(2 * r) * I + cG]
                                          + cg1.A * (float)ags[(size_t)(2 * r + 1) * I + cG];
                            sh[128 + tid] = cu0.A * (float)au[(size_t)(2 * r) * I + cG]
                                          + cu1.A * (float)au[(size_t)(2 * r + 1) * I + cG];
                            hadamard128(it, tid, sh.get_pointer());
                            hadamard128(it, tid, sh.get_pointer() + 128);
                            if (tid == 0) {
                                sh[0] += 128.0f * (cg0.B + cg1.B);
                                sh[128] += 128.0f * (cu0.B + cu1.B);
                            }
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
                            sh[tid] = av * sd;
                        } else {
                            const Affine cu0 = qu[2 * r], cu1 = qu[2 * r + 1];
                            sh[tid] = cu0.A * (float)au[(size_t)(2 * r) * I + cG]
                                    + cu1.A * (float)au[(size_t)(2 * r + 1) * I + cG];
                            hadamard128(it, tid, sh.get_pointer());
                            if (tid == 0) sh[0] += 128.0f * (cu0.B + cu1.B);
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
        {
            launch([&](sycl::handler& cgh) {
                sycl::local_accessor<float, 1> red({ 256 }, cgh);
                cgh.parallel_for(sycl::nd_range<2>({ 256, (size_t)8 * nc }, { 256, 1 }),
                    QuantIn{ w_tind, w_a8d, (Affine*)w_qsxd, chunks, nc, I, 1, 1, red });
            });
        }
        {
            g8.a8 = w_a8d; g8.acc = w_accd; g8.nfl = H / 16; g8.down = 1;
            launch([&](sycl::handler& cgh) {
                sycl::local_accessor<unsigned char, 1> slm({ 1024 }, cgh);
                switch (k2) {
                    case 4: cgh.parallel_for(sycl::nd_range<2>({ (size_t)(H / 16) * 16, (size_t)nc }, { 16, 1 }), Gemv8<4>{g8, slm}); break;
                    case 5: cgh.parallel_for(sycl::nd_range<2>({ (size_t)(H / 16) * 16, (size_t)nc }, { 16, 1 }), Gemv8<5>{g8, slm}); break;
                    case 6: cgh.parallel_for(sycl::nd_range<2>({ (size_t)(H / 16) * 16, (size_t)nc }, { 16, 1 }), Gemv8<6>{g8, slm}); break;
                    default: cgh.parallel_for(sycl::nd_range<2>({ (size_t)(H / 16) * 16, (size_t)nc }, { 16, 1 }), Gemv8<8>{g8, slm}); break;
                }
            });
        }
        {
            // K6i8: down out-transform + weighted gather, i32 accumulators + affine fold.
            const int nbk = H / 128;
            const int nent = (int)tmap.entry.size();
            if (nent) {
                dep = q.memset(out, 0, (size_t)rows * H * sizeof(float), { dep });
                if (prof) pev.push_back(dep);
                launch([&](sycl::handler& cgh) {
                    sycl::local_accessor<float, 1> sh({ 128 }, cgh);
                    cgh.parallel_for(sycl::nd_range<2>({ (size_t)nbk * 128, (size_t)nent }, { 128, 1 }),
                        [=](sycl::nd_item<2> it) {
                        const int blk = (int)it.get_group(0);
                        const int p = (int)it.get_group(1);
                        const int tid = (int)it.get_local_id(0);
                        const int cG = blk * 128 + tid;
                        int lo = 0, hi = rows;
                        while (hi - lo > 1) { const int mid = (lo + hi) >> 1;
                            if (d_tokb[mid] <= p) lo = mid; else hi = mid; }
                        const int t = lo;
                        const int ent = d_toke[p];
                        const int j = ent >> 2, s = ent & 3;
                        const int e = chunks[j].expert;
                        const float wgt = chunks[j].weight[s];
                        const uint16_t* svhe = (const uint16_t*)tab[(F_SVH * 3 + CAT_DOWN) * E + e];
                        const uint16_t* be = (const uint16_t*)tab[(F_BIAS * 3 + CAT_DOWN) * E + e];
                        const Affine cd0 = qsxd[j * 8 + 2 * s], cd1 = qsxd[j * 8 + 2 * s + 1];
                        sh[tid] = cd0.A * (float)accd8[((size_t)j * 8 + 2 * s) * H + cG]
                                + cd1.A * (float)accd8[((size_t)j * 8 + 2 * s + 1) * H + cG];
                        hadamard128(it, tid, sh.get_pointer());
                        if (tid == 0) sh[0] += 128.0f * (cd0.B + cd1.B);
                        float v = sh[tid] * (HAD_SCALE * f16(svhe[cG]));
                        if (be) v += f16(be[cG]);
                        sycl::atomic_ref<float, sycl::memory_order::relaxed,
                                         sycl::memory_scope::device> ao(out[(size_t)t * H + cG]);
                        ao.fetch_add(wgt * v);
                    });
                });
            } else {
                dep = q.memset(out, 0, (size_t)rows * H * sizeof(float), { dep });
                if (prof) pev.push_back(dep);
            }
        }
        return dep;
    }

    // ---- K2/K5: GEMV over mul1 tiles for one matrix class
    GemvBase gb;
    gb.tab = d_tab; gb.chunks = w_chunk;
    gb.tin = w_tin; gb.tout = w_tout; gb.tind = w_tind; gb.toutd = w_toutd;
    gb.E = E; gb.nc = nc; gb.nm = nm; gb.H = H; gb.I = I; gb.gated = gated ? 1 : 0;
    gb.nsl = nsl;
    auto gemv = [&](bool down) {
        gb.tiles_n = (down ? H : I) / 16;
        gb.tiles_k = (down ? I : H) / 16;
        gb.nbk = (down ? H : I) / 128;
        gb.down = down ? 1 : 0;
        gb.nsl = down ? NSL_D : NSL_GU;
        // single-slot chunks (decode) take the MMA=false specialization: the m>1 FMA chains
        // were predicated off but still issued ~30% of the inner loop (VTune, Xe2)
        const bool single = down ? (maxm_rows == 1) : (maxm_nm == 1);
        const int units = (down ? nc * gb.nbk : nc * nm * gb.nbk) * gb.nsl;
        const size_t gn = (size_t)units * 128;
        launch([&](sycl::handler& cgh) {
            switch (k2) {
                case 4: if (single) cgh.parallel_for(sycl::nd_range<1>({gn}, {128}), GemvK<4, false>{gb});
                        else        cgh.parallel_for(sycl::nd_range<1>({gn}, {128}), GemvK<4, true>{gb});  break;
                case 5: if (single) cgh.parallel_for(sycl::nd_range<1>({gn}, {128}), GemvK<5, false>{gb});
                        else        cgh.parallel_for(sycl::nd_range<1>({gn}, {128}), GemvK<5, true>{gb});  break;
                case 8: if (single) cgh.parallel_for(sycl::nd_range<1>({gn}, {128}), GemvK<8, false>{gb});
                        else        cgh.parallel_for(sycl::nd_range<1>({gn}, {128}), GemvK<8, true>{gb});  break;
                default: cgh.parallel_for(sycl::nd_range<1>({gn}, {128}), GemvFallback{gb, k2}); break;
            }
        });
    };

    gemv(false);

    // ---- K3+K4 fused: out transform (hadamard + svh + bias) + activation + down-prep
    // (activation h never leaves the workgroup: down-side suh/Hadamard run on the same
    // 128-column tile while it is in SLM; saves a global roundtrip and a submit)
    {
        const int nbk = I / 128;
        launch([&](sycl::handler& cgh) {
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

    gemv(true);

    // ---- K6: down out-transform + weighted gather into out. One workgroup per
    // (128-column block, routing entry) so a rows=1 decode still lights 2560*deg threads
    // (the old per-token loop was latency-bound at 20 WGs); fp32 atomics combine experts.
    {
        const int nbk = H / 128;
        const int nent = (int)tmap.entry.size();
        if (nent) {
            dep = q.memset(out, 0, (size_t)rows * H * sizeof(float), {dep});
            if (prof) pev.push_back(dep);
            launch([&](sycl::handler& cgh) {
                sycl::local_accessor<float, 1> sh({128}, cgh);
                cgh.parallel_for(sycl::nd_range<2>({(size_t)nbk * 128, (size_t)nent}, {128, 1}),
                    [=](sycl::nd_item<2> it) {
                    const int blk = (int)it.get_group(0);
                    const int p = (int)it.get_group(1);
                    const int tid = (int)it.get_local_id(0);
                    const int cG = blk * 128 + tid;
                    // token t owns entries [d_tokb[t], d_tokb[t+1]): binary search
                    int lo = 0, hi = rows;
                    while (hi - lo > 1) { const int mid = (lo + hi) >> 1;
                        if (d_tokb[mid] <= p) lo = mid; else hi = mid; }
                    const int t = lo;
                    const int ent = d_toke[p];
                    const int j = ent >> 2, s = ent & 3;
                    const int e = chunks[j].expert;
                    const float wgt = chunks[j].weight[s];
                    const uint16_t* svhe = (const uint16_t*)tab[(F_SVH * 3 + CAT_DOWN) * E + e];
                    const uint16_t* be = (const uint16_t*)tab[(F_BIAS * 3 + CAT_DOWN) * E + e];
                    float sv = 0.f;
                    for (int qq = 0; qq < NSL_D; ++qq)
                        sv += toutd[((size_t)(j * NSL_D + qq) * MAXM + s) * H + cG];
                    sh[tid] = sv;
                    hadamard128(it, tid, sh.get_pointer());
                    float v = sh[tid] * (HAD_SCALE * f16(svhe[cG]));
                    if (be) v += f16(be[cG]);
                    sycl::atomic_ref<float, sycl::memory_order::relaxed,
                                     sycl::memory_scope::device> ao(out[(size_t)t * H + cG]);
                    ao.fetch_add(wgt * v);
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