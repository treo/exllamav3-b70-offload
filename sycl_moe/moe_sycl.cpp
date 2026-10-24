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
#include <cmath>
#include <cstdlib>
#include <cstring>

namespace moe_sycl {

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

// weight index (r*16+c) -> state slot t in the tile ring (inverse of tc_perm)
struct InvPerm { unsigned char inv[256]; };

InvPerm make_invperm()
{
    InvPerm p{};
    for (int t = 0; t < 256; ++t) {
        const int b = t >> 3, j = t & 7;
        const int row = ((b & 3) * 2) + (j & 1) + ((j & 2) ? 8 : 0);
        const int col = (b >> 2) + ((j & 4) ? 8 : 0);
        p.inv[row * 16 + col] = (unsigned char)t;
    }
    return p;
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
    nsl = getenv("MOE_NSL") ? atoi(getenv("MOE_NSL")) : 2;
    d_tab = sycl::malloc_device<uintptr_t>(tab.size(), *q);
    q->memcpy(d_tab, tab.data(), tab.size() * sizeof(uintptr_t)).wait();
}

MoeSyclLayer::~MoeSyclLayer()
{
    auto freep = [&](auto*& p) { if (p) { sycl::free(p, *Q); p = nullptr; } };
    freep(d_tab);
    freep(w_chunk); freep(w_tin); freep(w_tout); freep(w_h); freep(w_tind); freep(w_toutd);
}

void MoeSyclLayer::ensure_ws(int nc, int rows)
{
    auto realloc_p = [&](auto*& p, size_t count) {
        if (p) sycl::free(p, *Q);
        using T = std::remove_pointer_t<std::remove_reference_t<decltype(p)>>;
        p = sycl::malloc_device<T>(count, *Q);
        // prefault so device page tables are populated before the kernel pipeline runs
        Q->memset(p, 0, count * sizeof(T));
        Q->wait();
    };
    if (nc > cap_nc) {
        realloc_p(w_tin,   (size_t)nc * 2 * MAXM * P.hidden);
        realloc_p(w_tout,  (size_t)nc * 2 * nsl * MAXM * P.interm);
        realloc_p(w_h,     (size_t)nc * MAXM * P.interm);
        realloc_p(w_tind,  (size_t)nc * MAXM * P.interm);
        realloc_p(w_toutd, (size_t)nc * nsl * MAXM * P.hidden);
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

template <int K2V>
struct GemvK
{
    GemvBase b;
    int rt_k2 = 0;    // used only when K2V == 0

    void operator()(sycl::nd_item<1> it) const
    {
        const int k2 = K2V > 0 ? K2V : rt_k2;
        constexpr int tile_u32_v = K2V > 0 ? 4 * K2V : 0;
        const int tile_u32 = K2V > 0 ? tile_u32_v : 4 * k2;
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
        const float* src_tin = down ? b.tind + (size_t)j * GemvBase::MAXM_ * b.I
                                    : b.tin + ((size_t)(j * 2 + mu) * GemvBase::MAXM_) * b.H;
        const int K = down ? b.I : b.H;

        const int cG = blk * 128 + tid;
        const int tile_n = cG >> 4, cin = cG & 15;
        unsigned long long apack[8] = {0,0,0,0,0,0,0,0};
#pragma unroll
        for (int rk = 0; rk < 16; ++rk) {
            const int row = rk, col = cin;
            const int bb = ((col & 7) << 2) | ((row >> 1) & 3);
            const int jj = (row & 1) | ((row & 8) ? 2 : 0) | ((col & 8) ? 4 : 0);
            const int t = (bb << 3) | jj;
            const int b1 = K2V > 0 ? (((t + 1) * K2V) >> 1) + 128 * K2V
                                   : (((t + 1) * k2) >> 1) + 128 * k2;
            const int b0 = b1 - 16;
            const int w0 = K2V > 0 ? (b0 >> 5) % tile_u32_v : (b0 >> 5) % tile_u32;
            const int w1 = K2V > 0 ? ((b1 - 1) >> 5) % tile_u32_v : ((b1 - 1) >> 5) % tile_u32;
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
                const uint32_t v0 = wp[a & 0xff], v1 = wp[(a >> 8) & 0xff];
                const uint64_t merged = ((uint64_t)v0 << 32) | v1;
                const uint32_t st16 = ((uint32_t)(merged >> (a >> 16))) & 0xffffu;
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
        float* dst = down ? b.toutd + ((size_t)j * b.nsl + sl) * GemvBase::MAXM_ * N
                          : b.tout + ((size_t)(j * 2 + mu) * b.nsl + sl) * GemvBase::MAXM_ * N;
        dst[cG] = acc0 * KDQ;
        if (m > 1) dst[N + cG] = acc1 * KDQ;
        if (m > 2) dst[2 * N + cG] = acc2 * KDQ;
        if (m > 3) dst[3 * N + cG] = acc3 * KDQ;
    }
};

// ------------------------------------------------------------------ forward

sycl::event MoeSyclLayer::forward(const ChunkDev* chunks_host, int num_chunks, const TokenMap& tmap,
                           const uint16_t* x, float* out, int rows, const sycl::event* pre_dep)
{
    const int H = P.hidden, I = P.interm;
    const int k2 = 2 * P.bits + P.hb;
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

    const int NSL = nsl;
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

    // ---- K2/K5: GEMV over mul1 tiles for one matrix class
    const InvPerm invp = make_invperm();
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
        const int units = (down ? nc * gb.nbk : nc * nm * gb.nbk) * NSL;
        const size_t gn = (size_t)units * 128;
        launch([&](sycl::handler& cgh) {
            switch (k2) {
                case 4: cgh.parallel_for(sycl::nd_range<1>({gn}, {128}), GemvK<4>{gb}); break;
                case 5: cgh.parallel_for(sycl::nd_range<1>({gn}, {128}), GemvK<5>{gb}); break;
                case 8: cgh.parallel_for(sycl::nd_range<1>({gn}, {128}), GemvK<8>{gb}); break;
                default: cgh.parallel_for(sycl::nd_range<1>({gn}, {128}), GemvK<0>{gb, k2}); break;
            }
        });
    };

    gemv(false);

    // ---- K3: out transform (hadamard + svh + bias) + activation -> h
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
                const uint16_t* svhu = (const uint16_t*)tab[(F_SVH * 3 + CAT_UP) * E + e];
                const uint16_t* bu   = (const uint16_t*)tab[(F_BIAS * 3 + CAT_UP) * E + e];
                const int mu_up = gated ? 1 : 0;   // gateless gemv stored up at slot j*2+0
                const float* tg = tout + (size_t)(j * 2) * NSL * MAXM * I;
                const float* tu = tout + (size_t)(j * 2 + mu_up) * NSL * MAXM * I;
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
                            for (int qq = 0; qq < NSL; ++qq) {
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
                        hbuf[(size_t)j * MAXM * I + (size_t)r * I + cG] = av;
                    } else {
                        {
                            float su = 0.f;
                            for (int qq = 0; qq < NSL; ++qq)
                                su += tu[(size_t)qq * MAXM * I + (size_t)r * I + cG];
                            sh[tid] = su;
                        }
                        hadamard128(it, tid, sh.get_pointer());
                        const float uv = sh[tid] * hu + bj;
                        const float rv = uv > 0.0f ? uv : 0.0f;
                        hbuf[(size_t)j * MAXM * I + (size_t)r * I + cG] = rv * rv;
                    }
                    sycl::group_barrier(it.get_group());
                }
            });
        });
    }

    // ---- K4: prep down inputs (from fp32 h)
    {
        const int nbk = I / 128;
        launch([&](sycl::handler& cgh) {
            sycl::local_accessor<float, 1> sh({128}, cgh);
            cgh.parallel_for(sycl::nd_range<2>({(size_t)nbk * 128, (size_t)nc}, {128, 1}),
                [=](sycl::nd_item<2> it) {
                const int blk = (int)it.get_group(0);
                const int j = (int)it.get_group(1);
                const int tid = (int)it.get_local_id(0);
                const int e = chunks[j].expert;
                const int m = chunks[j].m;
                const uint16_t* suh = (const uint16_t*)tab[(F_SUH * 3 + CAT_DOWN) * E + e];
                for (int r = 0; r < m; ++r) {
                    sh[tid] = hbuf[(size_t)j * MAXM * I + (size_t)r * I + blk * 128 + tid] * f16(suh[blk * 128 + tid]);
                    hadamard128(it, tid, sh.get_pointer());
                    tind[(size_t)j * MAXM * I + (size_t)r * I + blk * 128 + tid] = sh[tid] * HAD_SCALE;
                    sycl::group_barrier(it.get_group());
                }
            });
        });
    }

    gemv(true);

    // ---- K6: down out-transform + weighted gather into out (writes every element, no
    // separate zero-init needed)
    {
        const int nbk = H / 128;
        launch([&](sycl::handler& cgh) {
            sycl::local_accessor<float, 1> sh({128}, cgh);
            cgh.parallel_for(sycl::nd_range<2>({(size_t)nbk * 128, (size_t)rows}, {128, 1}),
                [=](sycl::nd_item<2> it) {
                const int blk = (int)it.get_group(0);
                const int t = (int)it.get_group(1);
                const int tid = (int)it.get_local_id(0);
                const int cG = blk * 128 + tid;
                float acc = 0.0f;
                const int b0 = d_tokb[t], b1 = d_tokb[t + 1];
                for (int p = b0; p < b1; ++p) {
                    const int ent = d_toke[p];
                    const int j = ent >> 2, s = ent & 3;
                    const int e = chunks[j].expert;
                    const float wgt = chunks[j].weight[s];
                    const uint16_t* svhe = (const uint16_t*)tab[(F_SVH * 3 + CAT_DOWN) * E + e];
                    const uint16_t* be = (const uint16_t*)tab[(F_BIAS * 3 + CAT_DOWN) * E + e];
                    {
                        float sv = 0.f;
                        for (int qq = 0; qq < NSL; ++qq)
                            sv += toutd[((size_t)(j * NSL + qq) * MAXM + s) * H + cG];
                        sh[tid] = sv;
                    }
                    hadamard128(it, tid, sh.get_pointer());
                    float v = sh[tid] * (HAD_SCALE * f16(svhe[cG]));
                    if (be) v += f16(be[cG]);
                    acc += wgt * v;
                    sycl::group_barrier(it.get_group());
                }
                out[(size_t)t * H + cG] = acc;
            });
        });
    }
    return dep;
}

} // namespace moe_sycl