
// probe_dpas7.cpp - E24 step 6 (rev J): rev H with the trellis unpack taken apart.
//
// Rev H's unpack was ~83 instructions per 256-weight tile (K=3), but 8 of them were 16-channel
// indirect moves (r[a0.0] with one address per channel) - the gathers that give each column its ring
// words - plus ~15 scalar bookkeeping instructions, and the trellis data arrived only 2 tiles ahead.
// "Unpack time" can therefore be either ALU or waiting for DRAM; rev J attacks both and adds switches
// that tell them apart.
//
// 1. TRANSPOSED TILES - no indirect moves. Within a tile, column group q (columns q and q+8) owns
//    exactly dwords [q*K, q*K + K): 4 ring positions x 8 windows x K bits = 32K bits. Every funnel's bit
//    offset relative to its group depends only on (K, a4, jl, which half), never on q. So if each tile
//    is stored as its 8 x K dwords transposed to K x 8 (row i = dword i of every group), a funnel's
//    words for the 16 columns are two 8-dword rows of the tile: a plain register region
//    (replicate_vs_w_hs, vertical stride 0/8/16), and its shift amounts are compile-time constants.
//    The one wrinkle is the window that starts up to 15 bits before its group: that needs "row -1",
//    the previous group's last dword, which is the last row rotated by one column (2 moves per tile).
//    The transpose is a host-side permutation inside each tile (main() does it on load): same bytes,
//    same DRAM traffic. Rev H remains the kernel for tiles in the original order.
// 2. FIRST WINDOW OF A RUN FROM THE HIGH HALF. Window 0 of a funnel word is its top 16 bits, read as a
//    16-bit register region by the multiply: no shift, and a 16x32 mul instead of mul+macl.
// 3. DEEPER PREFETCH. Rev H fetched 2 tiles ahead (192 bytes per thread at K=3). A tile now costs
//    8K+16 dwords of registers, and the ring depth is sized to a budget of RING_DW dwords: 8 tiles ahead
//    for K <= 4, falling to 2 at K = 15-16 - roughly 1 KB in flight per thread at every K (half that
//    budget with 9-16 rows, where accumulators and activations take the registers).
// 4. EXPERTS ACROSS THREADS. Nothing is shared between experts any more except the small activation
//    tile, so a thread now covers EPT experts instead of all E, and the grid grows by E/EPT. The default
//    fills ~2x the GPU's hardware threads (queried); DPAS_EPT overrides.
//
// Same window math and mapping as revs B-H; partials and combine as rev G/H; y must be BIT-IDENTICAL.
//
// Switches (env):
//   DPAS_M=1|2|4|8        force rows per DPAS (default: smallest that covers rows; > 8 -> 2 x M=8)
//   DPAS_EPT=<n>          experts per thread (default: auto, printed)
//   diagnostics - what one run executes per tile:
//     (default)           fetch + unpack + dpas
//     DPAS_NO_MAD         fetch + unpack
//     DPAS_FETCH_ONLY     fetch                      } NO_MAD ~ FETCH_ONLY  -> DRAM/latency bound
//     DPAS_ALU_ONLY       unpack (no loads)          } NO_MAD ~ ALU_ONLY    -> ALU bound
//     DPAS_NO_UNPACK      dpas only
//   DPAS_CHECK=<file>     bitwise comparison of y (default: CASE_DIR/y_ref.bin if present, right size)
//
// Build: notes/b70/build.sh probe_dpas7    Run: ./probe_dpas7 CASE_DIR [reps] [rows] [ks]
// K_MIN..K_MAX x 5 M configurations are instantiated; keep -fsycl-device-code-split=per_kernel.
// -----------------------------------------------------------------------------
#include <sycl/sycl.hpp>
#include <sycl/ext/intel/esimd.hpp>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <string>
#include <type_traits>
#include <utility>
#include <vector>

namespace esimd = sycl::ext::intel::esimd;
namespace xmx = sycl::ext::intel::esimd::xmx;
using esimd::simd;

static constexpr int NCOL = 16;                 // output columns per trellis tile = DPAS execution size
static constexpr int XROWS = 16;                // max token rows
static constexpr int RING_DW = 384;             // register budget of the trellis prefetch ring (24 GRF)
static constexpr uint32_t HASH = 0x83DCD12Du;   // window -> 4 weight bytes
static constexpr int K_MIN = 2, K_MAX = 16;     // trellis bits per weight compiled in (windows are 16 bits)
#ifndef DPAS_BAND
#define DPAS_BAND 0                            // 0 = checkpoint tile order; g = staged band (nt/g, kt, nt%g)
#endif

enum : int { MODE_FETCH = 1, MODE_UNPACK = 2, MODE_MAD = 4, MODE_ALL = 7 };

struct Meta
{
    int E = 0, R = 0, tk = 0, tn = 0, k = 0, n = 0;
    double K = 0;
    float kinv = 0.f;
};

static std::vector<char> slurp(const std::string &p)
{
    std::ifstream f(p, std::ios::binary | std::ios::ate);
    if (!f) { fprintf(stderr, "missing %s\n", p.c_str()); exit(2); }
    std::streamsize sz = f.tellg(); f.seekg(0);
    std::vector<char> b((size_t)sz);
    f.read(b.data(), sz);
    return b;
}

static Meta load_meta(const std::string &dir)
{
    std::ifstream f(dir + "/meta.json");
    if (!f) { fprintf(stderr, "missing meta.json\n"); exit(2); }
    std::string s((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
    auto get = [&](const char *k) -> double {
        size_t i = s.find(std::string("\"") + k + "\"");
        if (i == std::string::npos) return 0;
        i = s.find(':', i); return atof(s.c_str() + i + 1);
    };
    Meta m;
    m.E = (int)get("E"); m.R = (int)get("R"); m.tk = (int)get("tk"); m.tn = (int)get("tn");
    m.K = get("K"); m.k = m.tk * 16; m.n = m.tn * 16; m.kinv = (float)get("kinv");
    return m;
}

// Contiguous dword load, largest power-of-two LSC block first (K=7: 32+16+8). Addresses are 16-byte
// aligned: trellis tiles start at multiples of 32K bytes, activation tiles at multiples of 64 bytes.
template <int NDW>
ESIMD_INLINE simd<uint32_t, NDW> load_dw(const uint32_t *p)
{
    constexpr esimd::properties props{esimd::alignment<16>};
    static_assert(NDW % 8 == 0, "block sizes are multiples of 8 dwords");
    constexpr int H = NDW >= 128 ? 128 : NDW >= 64 ? 64 : NDW >= 32 ? 32 : NDW >= 16 ? 16 : 8;
    if constexpr (H == NDW)
        return esimd::block_load<uint32_t, NDW>(p, props);   // 128 dwords needs 8-byte alignment: we have 16
    else
    {
        simd<uint32_t, NDW> v;
        v.template select<H, 1>(0) = esimd::block_load<uint32_t, H>(p, props);
        v.template select<NDW - H, 1>(H) = load_dw<NDW - H>(p + H);
        return v;
    }
}

// f(integral_constant<I>) for I = I0 .. N-1 while g0 + I < total: compile-time ring slots, guaranteed.
template <int I, int N, typename F>
ESIMD_INLINE void unrolled(F &f, int g0, int total)
{
    if constexpr (I < N)
    {
        if (g0 + I < total)
        {
            f(std::integral_constant<int, I>{});
            unrolled<I + 1, N>(f, g0, total);
        }
    }
}

// f(integral_constant<I>) for I = I0 .. N-1 (compile-time loop: template arguments need the index)
template <int I, int N, typename F>
ESIMD_INLINE void static_for(F &&f)
{
    if constexpr (I < N)
    {
        f(std::integral_constant<int, I>{});
        static_for<I + 1, N>(f);
    }
}

// --- compile-time funnel geometry --------------------------------------------------------------------
// A 32-bit funnel word holds windows at bit offsets 0, K, 2K, ... while offset + 16 <= 32: WPF windows of
// a ring-position group's 4 (4 for K <= 5, 3 for K 6-8, 2 for K 9-16), NFUN funnels per group.
template <int K> constexpr int wpf() { return 16 / K + 1 < 4 ? 16 / K + 1 : 4; }
template <int K> constexpr int nfun() { return (4 + wpf<K>() - 1) / wpf<K>(); }

// Funnel fu = (a4, run) for the 8 columns of half h (columns q + 8h): its first window starts at bit
// r = K*(8*a4 + 4*h + jl0 + 1) - 16 of the column's group (bit 0 = MSB of the group's dword 0), i.e. in
// group row floor(r/32) (row -1 = the previous group's last dword) at offset r mod 32.
struct FunGeo
{
    int a4, jl0;        // ring-position group and first window of the run
    int i0, i1;         // row of the first word, half 0 / half 1
    int s0, s1;         // bit offset in that word, half 0 / half 1
    int j0, j1;         // row of the second word (clamped to K-1: past the group, no window needs it)
    bool two_step;      // some half has offset 0, so the low word needs (d1 >> 1) >> (31 - s)
};
constexpr int floordiv32(int r) { return r >= 0 ? r / 32 : -((31 - r) / 32); }
template <int K> constexpr FunGeo fun_geo(int fu)
{
    FunGeo g{};
    g.a4 = fu / nfun<K>();
    g.jl0 = (fu % nfun<K>()) * wpf<K>();
    const int r0 = K * (8 * g.a4 + g.jl0 + 1) - 16, r1 = r0 + 4 * K;
    g.i0 = floordiv32(r0); g.s0 = r0 - 32 * g.i0;
    g.i1 = floordiv32(r1); g.s1 = r1 - 32 * g.i1;
    g.j0 = g.i0 + 1 < K - 1 ? g.i0 + 1 : K - 1;
    g.j1 = g.i1 + 1 < K - 1 ? g.i1 + 1 : K - 1;
    g.two_step = g.s0 == 0 || g.s1 == 0;
    return g;
}
template <int K> constexpr bool needs_prev_row()
{
    for (int fu = 0; fu < 4 * nfun<K>(); ++fu)
        if (fun_geo<K>(fu).i0 < 0 || fun_geo<K>(fu).i1 < 0) return true;
    return false;
}

struct Launch
{
    sycl::queue *q = nullptr;
    const uint32_t *W = nullptr;    // trellis, [e][kt][nt] tiles of 8K dwords, each TRANSPOSED to [K][8]
    const uint32_t *XA = nullptr;   // activation tiles [kt][kb][rpad][32 bytes], x replicated 4x along K
    int32_t *PART = nullptr;        // [ks][sub][e][rpad][n]
    Meta m;
    int KS = 8, EPT = 1;            // k-slices; experts per thread
    int mode = MODE_ALL;
    int zero = 0;                   // always 0; a kernel argument, so the device compiler cannot fold it
};

// K = trellis bits per weight, MR = token rows per DPAS (repeat count), NF = DPAS per byte-block (1, or 2
// for 9-16 rows). One ESIMD thread = one (column tile, k-slice half, group of EPT experts).
template <int K, int MR, int NF>
static void submit(const Launch &L)
{
    constexpr int NW = 8 * K;                 // dwords per trellis tile
    constexpr int XW = NW + 16;               // ring slot: [8 unused][row -1][rows 0..K-1], tile GRF-aligned
    constexpr int RPAD = MR * NF;             // padded token rows
    constexpr int ADW = RPAD * 16;            // activation dwords per tile: 2 byte-blocks x RPAD rows x 8
    // with 9-16 rows the accumulators and activation tile double: the ring gets half the budget
    // (at the full budget the M=8x2 kernels for odd K >= 7 spilled ~1.5 KB on BMG)
    constexpr int PF_RAW = (RPAD > 8 ? RING_DW / 2 : RING_DW) / XW;
    constexpr int PF_MIN = (RPAD > 8 && XW > 128) ? 1 : 2;   // K >= 15 with 9-16 rows: one 0.5 KB tile ahead
    constexpr int PF_DIST = PF_RAW < PF_MIN ? PF_MIN : PF_RAW > 8 ? 8 : PF_RAW;
    constexpr int NSET = PF_DIST + 1;
    constexpr int WPF = wpf<K>();
    constexpr int NFUNC = 4 * nfun<K>();      // funnels per tile
    constexpr bool PREV = needs_prev_row<K>();

    const Meta m = L.m;
    const int KS = L.KS, EPT = L.EPT;
    const int E = m.E, tk = m.tk, tn = m.tn, n = m.n;
    const int tps = tk / KS;                  // trellis tiles per k-slice
    const int per_sg = tps / 2;               // tiles per thread and expert (main() enforces even halves)
    const int NEG = (E + EPT - 1) / EPT;      // expert groups
    const size_t threads = (size_t)tn * KS * 2 * NEG;
    const int mode = L.mode;
    const uint32_t *W = L.W;
    const uint32_t *XA = L.XA;
    int32_t *PART = L.PART;
    const int zero = L.zero;

    L.q->submit([&](sycl::handler &cgh)
    {
        cgh.parallel_for(sycl::nd_range<1>(sycl::range<1>(threads), sycl::range<1>(2)),
                         [=](sycl::nd_item<1> it) SYCL_ESIMD_KERNEL
        {
            const int gid = (int)it.get_global_id(0);
            const int sub = gid & 1;
            int rest = gid >> 1;
            const int nt = rest % tn; rest /= tn;
            const int ks = rest % KS;
            const int eg = rest / KS;
            const int e0 = eg * EPT;
            const int ne = E - e0 < EPT ? E - e0 : EPT;
            const int kt0 = ks * tps + sub * per_sg;
            const int ntile = per_sg;
            const int total = ne * ntile;

            // Funnel shift amounts per column: two values (half 0, half 1), compile-time - but held in
            // registers (+ zero): as immediates IGC would split each 16-wide shift into two 8-wide ones.
            simd<uint32_t, NCOL> SH[NFUNC], SR[NFUNC];
            static_for<0, NFUNC>([&](auto F) SYCL_ESIMD_FUNCTION
            {
                constexpr int fu = decltype(F)::value;
                constexpr FunGeo g = fun_geo<K>(fu);
                simd<uint32_t, NCOL> sh((uint32_t)g.s0), sr((uint32_t)(g.two_step ? 31 - g.s0 : 32 - g.s0));
                sh.template select<8, 1>(8) = (uint32_t)g.s1;
                sr.template select<8, 1>(8) = (uint32_t)(g.two_step ? 31 - g.s1 : 32 - g.s1);
                SH[fu] = sh + (uint32_t)zero;
                SR[fu] = sr + (uint32_t)zero;
            });

            // --- trellis register ring: tile g lives in slot g % NSET (compile-time slots, see step) ---
            simd<uint32_t, XW> pf[NSET];
            // Tile order. Default is the checkpoint's (kt, nt). -DDPAS_BAND=g switches to the ORDER THE
            // PARENT ACTUALLY STAGES IN: moe_cpu_host._copy_repacked puts tile (kt, nt) at
            // (nt/g, kt, nt%g) within each expert (g = exl3_moe_cpu_swizzle_group: 2 on AVX2, 8 on the
            // AVX-512 BW tiers, 0 when there is no repack). Consecutive kt for a fixed nt are then g tiles
            // apart rather than tn apart - that is the whole change, and it is what makes the B70 copy
            // verbatim instead of permuted on arrival.
            const size_t band = DPAS_BAND;
            const size_t kstride = (band ? band : (size_t)tn) * NW;                     // next kt, same expert
            const size_t estride = (size_t)tk * tn * NW - (size_t)(ntile - 1) * kstride; // last kt -> next expert
            const size_t tbase = band ? (nt / band) * (tk * band) + (size_t)kt0 * band + (nt % band)
                                      : (size_t)kt0 * tn + nt;
            const uint32_t *fp = W + ((size_t)e0 * tk * tn + tbase) * NW;
            int fe = 0, fti = 0;                      // next tile to fetch
            auto fetch = [&](simd<uint32_t, XW> &d) SYCL_ESIMD_FUNCTION
            {
                if (fe >= ne) return;
                d.template select<NW, 1>(16) = load_dw<NW>(fp);
                if (++fti == ntile) { fti = 0; ++fe; fp += estride; }
                else fp += kstride;
            };
            if (mode & MODE_FETCH)
            {
#pragma unroll
                for (int d = 0; d < PF_DIST; ++d) fetch(pf[d]);
            }

            // --- B operands: weight row r of byte-block r/8 is dwords (r%8)*16 .. +15, one per column ---
            simd<uint32_t, 128> Bop[2] = {simd<uint32_t, 128>(0u), simd<uint32_t, 128>(0u)};
            auto unpack = [&](simd<uint32_t, XW> &t) SYCL_ESIMD_FUNCTION
            {
                if constexpr (PREV)
                {
                    // row -1 for group q is group q-1's last dword (q = 0: group 7's, the ring wraps):
                    // the last row shifted right by one column
                    t.template select<7, 1>(9) = t.template select<7, 1>(16 + 8 * (K - 1));
                    t.template select<1, 1>(8) = t.template select<1, 1>(16 + 8 * (K - 1) + 7);
                }
                static_for<0, NFUNC>([&](auto F) SYCL_ESIMD_FUNCTION
                {
                    constexpr int fu = decltype(F)::value;
                    constexpr FunGeo g = fun_geo<K>(fu);
                    // the funnel's two words for all 16 columns: rows (i0, i1) and (j0, j1) of the tile
                    const simd<uint32_t, NCOL> d0 =
                        t.template replicate_vs_w_hs<2, 8 * (g.i1 - g.i0), 8, 1>(16 + 8 * g.i0);
                    const simd<uint32_t, NCOL> d1 =
                        t.template replicate_vs_w_hs<2, 8 * (g.j1 - g.j0), 8, 1>(16 + 8 * g.j0);
                    simd<uint32_t, NCOL> lo;
                    if constexpr (g.two_step) lo = (d1 >> 1) >> SR[fu];
                    else lo = d1 >> SR[fu];
                    simd<uint32_t, NCOL> w32 = (d0 << SH[fu]) | lo;   // bits s..s+31 of d0:d1
                    static_for<0, WPF>([&](auto Qc) SYCL_ESIMD_FUNCTION
                    {
                        constexpr int qq = decltype(Qc)::value;
                        constexpr int jl = g.jl0 + qq;
                        if constexpr (jl < 4)
                        {
                            // window qq = bits K*qq .. K*qq+15 of w32, taken as a 16-bit register region
                            constexpr int r = 2 * g.a4 + (jl & 1) + 8 * (jl >> 1);
                            simd<uint32_t, NCOL> prod;
                            if constexpr (qq == 0)
                                prod = simd<uint32_t, NCOL>(simd<uint16_t, NCOL>(
                                           w32.template bit_cast_view<uint16_t>().template select<NCOL, 2>(1))) *
                                       HASH;
                            else
                            {
                                simd<uint32_t, NCOL> sh = w32 >> (16 - K * qq);
                                prod = simd<uint32_t, NCOL>(simd<uint16_t, NCOL>(
                                           sh.template bit_cast_view<uint16_t>().template select<NCOL, 2>(0))) *
                                       HASH;
                            }
                            Bop[r >> 3].template select<NCOL, 1>((r & 7) * NCOL) = prod;
                        }
                    });
                });
            };

            simd<int32_t, MR * NCOL> acc[NF];
            auto store_part = [&](int e) SYCL_ESIMD_FUNCTION
            {
                constexpr esimd::properties props{esimd::alignment<16>};
                int32_t *P = PART + ((((size_t)ks * 2 + sub) * E + e) * RPAD) * (size_t)n + (size_t)nt * NCOL;
#pragma unroll
                for (int f = 0; f < NF; ++f)
#pragma unroll
                    for (int mr = 0; mr < MR; ++mr)
                    {
                        const simd<int32_t, NCOL> row = acc[f].template select<NCOL, 1>(mr * NCOL);
                        esimd::block_store<int32_t, NCOL>(P + (size_t)(8 * f + mr) * n, row, props);
                    }
            };

            auto mad = [&](const uint32_t *a_tile) SYCL_ESIMD_FUNCTION
            {
                simd<uint32_t, ADW> At = load_dw<ADW>(a_tile);   // select() is non-const
#pragma unroll
                for (int kb = 0; kb < 2; ++kb)
#pragma unroll
                    for (int f = 0; f < NF; ++f)
                    {
                        const simd<uint32_t, MR * 8> a = At.template select<MR * 8, 1>(kb * RPAD * 8 + f * MR * 8);
                        acc[f] = xmx::dpas<8, MR, int32_t, int32_t, uint32_t, uint32_t,
                                           xmx::dpas_argument_type::u8, xmx::dpas_argument_type::s8>(
                            acc[f], Bop[kb], a);
                    }
            };

            // One tile; U is its ring slot as a compile-time constant. The normal path (mode == ALL) is
            // straight-line; the diagnostic modes take the other branch.
            int ce = 0, cti = 0;                      // current tile (expert within this thread, k tile)
            const uint32_t *ap0 = XA + (size_t)kt0 * ADW;
            const uint32_t *ap = ap0;                 // activation tile of the current k tile
            auto step = [&](auto U) SYCL_ESIMD_FUNCTION
            {
                constexpr int u = decltype(U)::value;
                if (cti == 0)
                {
#pragma unroll
                    for (int f = 0; f < NF; ++f) acc[f] = 0;
                }
                if (mode == MODE_ALL)
                {
                    fetch(pf[(u + PF_DIST) % NSET]);  // the slot the previous tile just used
                    unpack(pf[u]);
                    mad(ap);
                }
                else
                {
                    if (mode & MODE_FETCH) fetch(pf[(u + PF_DIST) % NSET]);
                    if (mode & MODE_UNPACK) unpack(pf[u]);
                    if (mode & MODE_MAD) mad(ap);
                }
                ap += ADW;
                if (++cti == ntile)
                {
                    store_part(e0 + ce);
                    cti = 0;
                    ++ce;
                    ap = ap0;
                }
            };
            for (int g0 = 0; g0 < total; g0 += NSET) unrolled<0, NSET>(step, g0, total);
        });
    });
}

template <int K>
static void submit_k(int mr, int nf, const Launch &L)
{
    if (nf == 2) { submit<K, 8, 2>(L); return; }
    switch (mr)
    {
    case 1: submit<K, 1, 1>(L); break;
    case 2: submit<K, 2, 1>(L); break;
    case 4: submit<K, 4, 1>(L); break;
    default: submit<K, 8, 1>(L); break;
    }
}

template <int... I>
static void dispatch_k(int K, int mr, int nf, const Launch &L, std::integer_sequence<int, I...>)
{
    const bool hit = ((K == K_MIN + I ? (submit_k<K_MIN + I>(mr, nf, L), true) : false) || ...);
    if (!hit) { fprintf(stderr, "no kernel for K %d\n", K); exit(2); }
}

static void combine(sycl::queue &q, const int32_t *PART, const float *Q, const int32_t *SX8,
                    float *Y, const Meta &m, int KS, int rpad)
{
    const size_t total = (size_t)m.E * m.R * m.n;
    q.parallel_for(sycl::range<1>(total), [=](sycl::id<1> id)
    {
        const size_t i = id[0];
        const int e = (int)(i / ((size_t)m.R * m.n));
        const int row = (int)((i / m.n) % m.R);
        const int col = (int)(i % m.n);
        int32_t s = 0;
        for (int p = 0; p < KS * 2; ++p)
            s += PART[(((size_t)p * m.E + e) * rpad + row) * m.n + col];   // contiguous in col
        Y[i] = m.kinv * Q[row] * ((float)s - 510.0f * (float)SX8[row]);
    });
}

static void check_against(const std::string &path, const std::vector<float> &y, bool quiet_if_missing)
{
    std::ifstream f(path, std::ios::binary | std::ios::ate);
    if (!f)
    {
        if (!quiet_if_missing) printf("check: %s not found\n", path.c_str());
        return;
    }
    const size_t sz = (size_t)f.tellg();
    if (sz != y.size() * 4)
    {
        printf("check: %s has %zu bytes, this run produced %zu - skipped (rows/E mismatch?)\n",
               path.c_str(), sz, y.size() * 4);
        return;
    }
    std::vector<float> r(y.size());
    f.seekg(0);
    f.read((char *)r.data(), (std::streamsize)sz);
    size_t bad = 0;
    double maxd = 0;
    for (size_t i = 0; i < y.size(); ++i)
        if (memcmp(&r[i], &y[i], 4))
        {
            ++bad;
            maxd = std::max(maxd, std::fabs((double)r[i] - (double)y[i]));
        }
    printf("check vs %s: %s (%zu of %zu differ, max |d| %.3g)\n", path.c_str(),
           bad ? "MISMATCH" : "bit-exact", bad, y.size(), maxd);
}

int main(int argc, char **argv)
{
    if (argc < 2) { fprintf(stderr, "usage: %s CASE_DIR [reps] [rows] [ks]\n", argv[0]); return 2; }
    const std::string dir = argv[1];
    const int reps = argc > 2 ? atoi(argv[2]) : 5;
    const int rows_arg = argc > 3 ? atoi(argv[3]) : 0;
    const int KS = argc > 4 ? atoi(argv[4]) : 8;
    Meta m = load_meta(dir);
    if (rows_arg > 0) m.R = rows_arg;
    if (m.R < 1 || m.R > XROWS) { fprintf(stderr, "rows %d outside 1..%d\n", m.R, XROWS); return 2; }
    if (KS < 1 || m.tk % KS || (m.tk / KS) % 2) { fprintf(stderr, "tk must split into even halves (KS %d, tk %d)\n", KS, m.tk); return 2; }
    const int K = (int)m.K;
    if (K < K_MIN || K > K_MAX) { fprintf(stderr, "rev J is compiled for K = %d..%d (K is %d)\n", K_MIN, K_MAX, K); return 2; }

    int MR = m.R <= 1 ? 1 : m.R <= 2 ? 2 : m.R <= 4 ? 4 : 8;
    const int NF = m.R > 8 ? 2 : 1;
    if (const char *fm = getenv("DPAS_M"))
    {
        const int want = atoi(fm);
        if (want != 1 && want != 2 && want != 4 && want != 8) { fprintf(stderr, "DPAS_M must be 1, 2, 4 or 8\n"); return 2; }
        if (want * NF < m.R) { fprintf(stderr, "DPAS_M=%d does not cover %d rows\n", want, m.R); return 2; }
        MR = want;
    }
    if (NF == 2) MR = 8;
    const int RPAD = MR * NF;

    int mode = MODE_ALL;
    const char *mode_name = "fetch+unpack+dpas";
    if (getenv("DPAS_NO_MAD"))     { mode = MODE_FETCH | MODE_UNPACK; mode_name = "fetch+unpack (DPAS_NO_MAD)"; }
    if (getenv("DPAS_FETCH_ONLY")) { mode = MODE_FETCH;               mode_name = "fetch only (DPAS_FETCH_ONLY)"; }
    if (getenv("DPAS_ALU_ONLY"))   { mode = MODE_UNPACK;              mode_name = "unpack ALU only (DPAS_ALU_ONLY)"; }
    if (getenv("DPAS_NO_UNPACK"))  { mode = MODE_MAD;                 mode_name = "dpas only (DPAS_NO_UNPACK)"; }

    auto wbuf = slurp(dir + "/weights.bin");
    auto xbuf = slurp(dir + "/x8.bin");
    auto qbuf = slurp(dir + "/q.bin");
    auto sbuf = slurp(dir + "/sx8.bin");
    const int NW = 8 * K;
    const size_t ntiles = (size_t)m.E * m.tk * m.tn;
    if (wbuf.size() != ntiles * NW * 4) { fprintf(stderr, "weights.bin has %zu bytes, meta implies %zu\n", wbuf.size(), ntiles * NW * 4); return 2; }
    if (xbuf.size() < (size_t)m.R * m.k || qbuf.size() < (size_t)m.R * 4 || sbuf.size() < (size_t)m.R * 4)
    {
        fprintf(stderr, "x8/q/sx8 hold fewer than %d rows\n", m.R);
        return 2;
    }

    // Transposed tiles: within each tile, dword q*K + i (row i of column group q) moves to i*8 + q.
    // A permutation inside each 32K-byte tile - in a real pipeline, done once when the weights load.
    //
    // -DDPAS_STAGED_LAYOUT says the input is ALREADY in that order, which is the production AVX2 staged
    // form: moe_cpu_host._copy_repacked swaps each tile's trailing (8, bits) dword dims, i.e. dword w ->
    // 8*(w%bits) + w/bits - byte-identical to the map below (verified on /tmp/gemv_dpE10: 1.536M dwords).
    // So the B70 can consume the CPU's staged bytes verbatim; this build is how that claim is tested.
    std::vector<uint32_t> hW(ntiles * NW);
#ifdef DPAS_STAGED_LAYOUT
    memcpy(hW.data(), wbuf.data(), ntiles * NW * 4);
#else
    {
        const uint32_t *src = (const uint32_t *)wbuf.data();
        for (size_t t = 0; t < ntiles; ++t)
            for (int q = 0; q < 8; ++q)
                for (int i = 0; i < K; ++i) hW[t * NW + i * 8 + q] = src[t * NW + q * K + i];
    }
#endif

    // Activation tiles: XA[kt][kb][row][4*w + b] = x8[row][kt*16 + kb*8 + w], row < RPAD (rows >= R repeat
    // R-1), w = 0..7, b = 0..3 - so each (tile, byte-block, DPAS) A operand is one contiguous run.
    const int8_t *x8 = (const int8_t *)xbuf.data();
    std::vector<int8_t> hXA((size_t)m.tk * 2 * RPAD * 32);
    for (int kt = 0; kt < m.tk; ++kt)
        for (int kb = 0; kb < 2; ++kb)
            for (int row = 0; row < RPAD; ++row)
            {
                const int8_t *src = x8 + (size_t)(row < m.R ? row : m.R - 1) * m.k + kt * 16 + kb * 8;
                int8_t *dst = &hXA[(((size_t)kt * 2 + kb) * RPAD + row) * 32];
                for (int w = 0; w < 8; ++w)
                    for (int b = 0; b < 4; ++b) dst[w * 4 + b] = src[w];
            }

    sycl::device dev{sycl::gpu_selector_v};
    sycl::context ctx{dev};
    sycl::queue q{ctx, dev, sycl::property::queue::in_order{}};

    // Experts per thread: fill about twice the GPU's hardware threads (or DPAS_EPT).
    size_t hw_threads = 2048;   // B70: 32 Xe2 cores x 8 vector engines x 8 threads, if the query is absent
    if (dev.has(sycl::aspect::ext_intel_gpu_eu_count) && dev.has(sycl::aspect::ext_intel_gpu_hw_threads_per_eu))
        hw_threads = (size_t)dev.get_info<sycl::ext::intel::info::device::gpu_eu_count>() *
                     dev.get_info<sycl::ext::intel::info::device::gpu_hw_threads_per_eu>();
    const size_t base_threads = (size_t)m.tn * KS * 2;
    int NEG = (int)std::min<size_t>(m.E, std::max<size_t>(1, (2 * hw_threads + base_threads - 1) / base_threads));
    int EPT = (m.E + NEG - 1) / NEG;
    if (const char *fe = getenv("DPAS_EPT")) EPT = std::max(1, std::min(m.E, atoi(fe)));
    NEG = (m.E + EPT - 1) / EPT;

    const double trellis_mib = wbuf.size() / 1048576.0;
    printf("case %s: E %d R %d k %d n %d K %d  trellis %.2f MiB  KS %d\n",
           dir.c_str(), m.E, m.R, m.k, m.n, K, trellis_mib, KS);
    printf("rev J (ESIMD, transposed tiles): dpas %d x %d per byte-block (rows padded to %d), %d expert%s per "
           "thread, %zu threads (%zu HW), mode: %s\n",
           MR, NF, RPAD, EPT, EPT > 1 ? "s" : "", base_threads * NEG, hw_threads, mode_name);

    uint32_t *W = (uint32_t *)sycl::malloc_device(hW.size() * 4, q);
    uint32_t *XA = (uint32_t *)sycl::malloc_device(hXA.size(), q);
    float *Q = (float *)sycl::malloc_device(qbuf.size(), q);
    int32_t *SX8 = (int32_t *)sycl::malloc_device(sbuf.size(), q);
    float *Y = (float *)sycl::malloc_device((size_t)m.E * m.R * m.n * 4, q);
    int32_t *PART = (int32_t *)sycl::malloc_device((size_t)KS * 2 * m.E * RPAD * m.n * 4, q);
    q.memcpy(W, hW.data(), hW.size() * 4);
    q.memcpy(XA, hXA.data(), hXA.size());
    q.memcpy(Q, qbuf.data(), qbuf.size());
    q.memcpy(SX8, sbuf.data(), sbuf.size());
    q.wait();

    Launch L;
    L.q = &q; L.W = W; L.XA = XA; L.PART = PART; L.m = m; L.KS = KS; L.EPT = EPT; L.mode = mode;
    L.zero = 0;

    auto dispatch = [&]
    {
        dispatch_k(K, MR, NF, L, std::make_integer_sequence<int, K_MAX - K_MIN + 1>{});
        combine(q, PART, Q, SX8, Y, m, KS, RPAD);
    };

    double best = 1e30;
    for (int r = 0; r < reps + 2; ++r)
    {
        auto t0 = std::chrono::steady_clock::now();
        dispatch();
        q.wait();
        double s = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
        if (r >= 2 && s < best) best = s;
    }
    const int BURST = 8;
    double tpbest = 1e30;
    for (int w = 0; w < 2; ++w) { for (int i = 0; i < 3; ++i) dispatch(); q.wait(); }
    for (int r = 0; r < 4; ++r)
    {
        auto t0 = std::chrono::steady_clock::now();
        for (int i = 0; i < BURST; ++i) dispatch();
        q.wait();
        double s = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count() / BURST;
        if (s < tpbest) tpbest = s;
    }

    std::vector<float> y((size_t)m.E * m.R * m.n);
    q.memcpy(y.data(), Y, y.size() * 4);
    q.wait();

    const double weights = (double)m.E * m.k * m.n;
    const double slots_per_weight = 1.43e12 * tpbest / weights;
    printf("revI ks %d rows %d: %8.1f us  %7.1f G-w/s  %6.2f slots/weight  %6.1f GB/s(trellis)"
           "   [burst; single-launch %7.1f us = %7.1f G-w/s, %.2f slots/w]  [M %dx%d ept %d]\n",
           KS, m.R, tpbest * 1e6, weights / tpbest / 1e9, slots_per_weight, wbuf.size() / tpbest / 1e9,
           best * 1e6, weights / best / 1e9, 1.43e12 * best / weights, MR, NF, EPT);

    if (mode == MODE_ALL)
    {
        char outpath[512];
        snprintf(outpath, sizeof outpath, "%s/y_dev_revi_ks%d_r%d_m%dx%d.bin", dir.c_str(), KS, m.R, MR, NF);
        FILE *fo = fopen(outpath, "wb");
        if (fo)
        {
            fwrite(y.data(), 4, y.size(), fo);
            fclose(fo);
            printf("wrote %s\n", outpath);
        }
        else
            fprintf(stderr, "could not write %s\n", outpath);

        if (const char *ref = getenv("DPAS_CHECK"))
            check_against(ref, y, false);
        else
            check_against(dir + "/y_ref.bin", y, true);
    }
    else
        printf("(diagnostic mode: y is not meaningful and is not written)\n");

    sycl::free(W, q); sycl::free(XA, q); sycl::free(Q, q); sycl::free(SX8, q);
    sycl::free(Y, q); sycl::free(PART, q);
    return 0;
}
