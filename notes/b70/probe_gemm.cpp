
// Clean-line decode kernel (rev L). Everything here is a MEASURED WIN with no alternative path in the file;
// the experimental history, ablation switches, and the refuted variants live on in probe_dpas7.cpp (rev J),
// probe_dpas8.cpp (rev K) and doc/port/b70-decode-closeout.md.
//
// The main path, and the evidence behind each piece:
//   * Tokens on M, weights as B, int8 x uint8 -> int32 (rev G). XMX fixes N=16, so putting the (few) tokens on
//     the shrinkable M dimension is what makes low batch efficient.
//   * ESIMD xmx::dpas with the unpacked weight tile in REGISTERS (rev H): no SLM, no barriers, no B loads.
//   * Transposed tiles (rev J): inside a tile, column group q owns dwords [qK, qK+K) and every funnel's bit
//     offset is independent of q, so storing the tile's 8xK dwords transposed to Kx8 turns operand routing into
//     plain register rows with compile-time shifts. Rev H's iselect cascade and rev I's per-lane gathers both
//     disappeared; this kernel runs at ~90 % of the measured stream slope.
//   * Inputs are taken in the layout the PARENT ALREADY STAGES (D3-alt): moe_cpu_host._copy_repacked's planar
//     dword order is byte-identical to rev J's intra-tile transpose, and its tile banding is what `layout`
//     selects. With a staged input the B70 copy is verbatim - no device permute pass at all.
//   * One expert per thread (D4), reached independently by the expert-grid port and by rev J's DPAS_EPT sweep.
//   * Partials + a SEPARATE combine kernel (D2). Fusing the combine with per-expert atomics was measured
//     4.5x more expensive than the round trip it removes (E29's row bucketing is also absent: register budget).
//   * Optional gate+up fusion in ONE launch (E25a/D8): pass a second case dir. A thread still serves exactly
//     one projection, so no extra accumulator registers - unlike row bucketing, which paid that bill and lost.
//
// Rows per launch is capped at 16 on purpose: that is the largest shape that is spill-free (E29's ring sweep),
// and above it the engine buckets launches with an additive cost law (out_rows_gt16.txt).
//
// Usage:  ./probe_dpas9 CASE_DIR [reps] [rows] [ks] [layout] [dir2]
//           CASE_DIR  dumped by dump_gemv_case.py --with-reference --with-sx8 (weights.bin, x8.bin, q.bin,
//                     sx8.bin, meta.json). With layout=native the intra-tile transpose is applied here; a
//                     staged dir must already be in the parent's order.
//           reps      single-launch timing iterations (default 5)
//           rows      token rows, 1..16 (default 1)
//           ks        k-slices; 1 is the optimum for a fused launch (fusion and split-K both buy parallelism)
//           layout    native | staged | staged2 | staged8   (default native)
//                     staged = planar dwords, unbanded tiles (a control, not something a parent emits);
//                     staged2 / staged8 = exactly what the AVX2 / AVX-512 BW tiers stage, consumed verbatim.
//           dir2      optional second projection (gate+up fused in one launch); must have identical tiling
//
// Output: CASE_DIR/y_dev_ks<K>_r<R>[_f2].bin for the harness to check bit-exactly (gate_dpas.py). No built-in
//         reference comparison on purpose: rev J's skipped silently when sizes mismatched and reported a pass
//         that had not happened.
//
// Timing: 3 s of CONTINUOUS in-process work before measuring (the device downclocks when idle; a chain of short
//         separate runs measures an unramped card, and looks like a 2x regression across untouched binaries).
//         Override with WARM_S=<seconds>. Burst-throughput and single-launch round-trip are both reported.
//
// Build:  see notes/b70/build.sh; keep -fsycl-device-code-split=per_kernel (K_MIN..K_MAX x M variants).
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
static constexpr int XROWS = 16;                // token rows per launch: the spill-free ceiling (E29)
static constexpr int RING_DW = 384;             // trellis prefetch ring budget, dwords (24 GRF)
static constexpr uint32_t HASH = 0x83DCD12Du;   // window -> 4 weight bytes
static constexpr int K_MIN = 2, K_MAX = 16;     // trellis bits per weight compiled in (windows are 16 bits)

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
    // E25a: gate+up in ONE launch. A thread still touches exactly one projection, so nothing about the
    // register bill changes (the lesson from E29, where paying it twice killed the idea). Null/0 = no fusion.
    const uint32_t *W2 = nullptr;
    int32_t *PART2 = nullptr;
    int tn2 = 0;
    int band = 0;                 // dispatch KEY for the templated tile order: 0 = checkpoint (kt,nt),
                                  // 2 = AVX2 staged, 8 = AVX-512 tiers staged. The kernel never sees it as
                                  // a runtime value - dispatch_band picks a specialized instance instead.
    Meta m;
    int KS = 1;                     // k-slices
    // probe_gemm (prefill/verify reuse test). A 16-row slab is the unit rev L already handles; NSLAB slabs of
    // one expert's tile are either (B) separate items of ONE launch, adjacent in the grid so they are
    // co-resident, or (A) the same work issued as sequential launches - which is what the engine does today
    // above 16 rows and what E29 measured as additive. Same arithmetic, same bytes, only the temporal
    // relationship of the re-reads differs, so any A/B difference IS the re-use hypothesis.
    int NSLAB = 1;                // variant B: slabs carried as a grid axis
    int RPADT = 0;                // PART's rows dimension when NSLAB > 1 (0 => RPAD)
    size_t xa_off = 0;            // variant A: dwords into XA for this launch's slab window
    int prow = 0;                 // variant A: PART row offset for this launch
    int wgsize = 2;                 // work-group size (see submit()); 2 = the shipped mapping
    int zero = 0;                   // always 0; a kernel argument, so the device compiler cannot fold it
};

// K = trellis bits per weight, MR = token rows per DPAS (repeat count), NF = DPAS per byte-block (1, or 2
// for 9-16 rows). One ESIMD thread = one (column tile, k-slice, expert) - one expert per thread (D4).
template <int K, int MR, int NF, int Band>
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
    const int KS = L.KS;
    const int E = m.E, tk = m.tk, tn = m.tn, n = m.n;
    const int tps = tk / KS;                  // trellis tiles per k-slice
    const int per_sg = tps / 2;               // tiles per thread and expert (main() enforces even halves)
    const int NEG = E;                        // one expert per thread (D4): the grid is (tile, k-slice, expert)
    const int TN = tn + L.tn2;                // fused grid spans both projections' column tiles
    const size_t threads = (size_t)TN * KS * 2 * NEG * (size_t)L.NSLAB;
    const uint32_t *W = L.W;
    const uint32_t *W2 = L.W2;          // E25a second projection (null when not fused)
    const uint32_t *XA = L.XA;
    int32_t *PART = L.PART;
    int32_t *PART2 = L.PART2;
    const int zero = L.zero;

    L.q->submit([&](sycl::handler &cgh)
    {
        // DPAS_WG (E25c route 1 probe): work-group size. Default 2 = the shipped mapping (a group is two Xe
        // threads). Larger groups put a whole expert's tiles, or several experts, inside one group - which is
        // what would let the gate/up -> down hand-off use a WORK-GROUP barrier (measured free, probe_groupfused)
        // instead of a grid-wide one (7.6 us). Caveat the probe exists to expose: the device hosts 8 hardware
        // threads per EU, so any group above 8 spans EUs and loses the locality that made the group barrier cheap.
        const size_t wgsize = L.wgsize && L.wgsize <= threads ? (size_t)L.wgsize : (size_t)2;
        cgh.parallel_for(sycl::nd_range<1>(sycl::range<1>(threads), sycl::range<1>(wgsize)),
                         [=](sycl::nd_item<1> it) SYCL_ESIMD_KERNEL
        {
            const int gid = (int)it.get_global_id(0);
            // Slab index FASTEST-varying: items that differ only in row-slab are adjacent, hence co-resident.
            // That adjacency is the entire mechanism under test, so it must be visible in the id math (and in
            // the grid order the hardware walks), not assumed from a comment.
            const int slab = L.NSLAB > 1 ? gid % L.NSLAB : 0;
            const int g0 = L.NSLAB > 1 ? gid / L.NSLAB : gid;
            const int sub = g0 & 1;
            int rest = g0 >> 1;
            const int ntx = rest % TN; rest /= TN;
            const uint32_t *Ws = ntx < tn ? W : W2;      // which projection this thread serves
            int32_t *Ps = ntx < tn ? PART : PART2;
            const int nt = ntx < tn ? ntx : ntx - tn;
            const int ks = rest % KS;
            const int eg = rest / KS;
            const int e0 = eg;                    // one expert per thread
            const int ne = 1;
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

            simd<uint32_t, XW> pf[NSET];
            // Tile order. Band == 0 is the checkpoint's (kt, nt). Band == g is the order the PARENT stages
            // in: moe_cpu_host._copy_repacked puts tile (kt, nt) at (nt/g, kt, nt%g) within each expert
            // (g = exl3_moe_cpu_swizzle_group: 2 on AVX2, 8 on the AVX-512 BW tiers, 0 for no repack), so the
            // B70 takes the staged bytes verbatim (D3-alt). Consecutive kt for a fixed nt are g apart.
            //
            // Band is a TEMPLATE parameter, not a runtime field, and that is worth ~19% by itself: with the
            // stride coming from the Launch struct the same kernel measured 23.1 us against 19.6-19.7 us for
            // the constant-folded version, on bit-identical inputs (out_revl.txt). Anything the admit path
            // already knows belongs here rather than in a parameter block.
            constexpr size_t band = Band;
            const size_t kstride = (band ? band : (size_t)tn) * NW;                     // next kt, same expert
            const size_t estride = (size_t)tk * tn * NW - (size_t)(ntile - 1) * kstride; // last kt -> next expert
            const size_t tbase = band ? (nt / band) * (tk * band) + (size_t)kt0 * band + (nt % band)
                                      : (size_t)kt0 * tn + nt;
            const uint32_t *fp = Ws + ((size_t)e0 * tk * tn + tbase) * NW;
            int fe = 0, fti = 0;                      // next tile to fetch
            auto fetch = [&](simd<uint32_t, XW> &d) SYCL_ESIMD_FUNCTION
            {
                if (fe >= ne) return;
                d.template select<NW, 1>(16) = load_dw<NW>(fp);
                if (++fti == ntile) { fti = 0; ++fe; fp += estride; }
                else fp += kstride;
            };
#pragma unroll
            for (int d = 0; d < PF_DIST; ++d) fetch(pf[d]);

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
                int32_t *P = Ps + ((((size_t)ks * 2 + sub) * E + e) * (size_t)(L.RPADT ? L.RPADT : RPAD)
                                   + (size_t)(L.prow + slab * RPAD)) * (size_t)n + (size_t)nt * NCOL;
#pragma unroll
                for (int f = 0; f < NF; ++f)
#pragma unroll
                    for (int mr = 0; mr < MR; ++mr)
                    {
                        const simd<int32_t, NCOL> row = acc[f].template select<NCOL, 1>(mr * NCOL);
                        esimd::block_store<int32_t, NCOL>(P + (size_t)(8 * f + mr) * n, row, props);
                    }
            };

            // The unpacked weight tile already lives in Bop: no SLM round trip, no barrier, because this
            // sub-group produced everything it consumes.
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

            // One tile; U is its ring slot as a compile-time constant.
            int ce = 0, cti = 0;                      // current tile (expert within this thread, k tile)
            // One slab window per launch (variant A shifts xa_off; variant B indexes it by slab).
            const uint32_t *ap0 = XA + L.xa_off + (size_t)slab * ((size_t)m.tk * ADW) + (size_t)kt0 * ADW;
            const uint32_t *ap = ap0;                 // activation tile of the current k tile
            auto step = [&](auto U) SYCL_ESIMD_FUNCTION
            {
                constexpr int u = decltype(U)::value;
                if (cti == 0)
                {
#pragma unroll
                    for (int f = 0; f < NF; ++f) acc[f] = 0;
                }
                fetch(pf[(u + PF_DIST) % NSET]);  // the slot the previous tile just used
                unpack(pf[u]);
                mad(ap);                          // one weight tile in registers, applied to this launch's rows
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

template <int K, int Band>
static void submit_kb(int mr, int nf, const Launch &L)
{
    if (nf == 2) { submit<K, 8, 2, Band>(L); return; }   // 9-16 rows: two M=8 fragments
    switch (mr)
    {
    case 1: submit<K, 1, 1, Band>(L); break;
    case 2: submit<K, 2, 1, Band>(L); break;
    case 4: submit<K, 4, 1, Band>(L); break;
    default: submit<K, 8, 1, Band>(L); break;
    }
}

// The staged forms this device will actually be handed: none, AVX2's group 2, the AVX-512 tiers' group 8.
template <int K, int... B>
static void dispatch_band(int band, int mr, int nf, const Launch &L, std::integer_sequence<int, B...>)
{
    const bool hit = ((band == B ? (submit_kb<K, B>(mr, nf, L), true) : false) || ...);
    if (!hit)
    {
        fprintf(stderr, "no kernel for band %d (specialized: %s)\n", band, "0, 2, 8");
        exit(2);
    }
}

template <int... I>
static void dispatch_k(int K, int mr, int nf, const Launch &L, std::integer_sequence<int, I...>)
{
    const bool hit = ((K == K_MIN + I
        ? (dispatch_band<K_MIN + I>(L.band, mr, nf, L, std::integer_sequence<int, 0, 2, 8>{}), true)
        : false) || ...);
    if (!hit) { fprintf(stderr, "no kernel for K %d\n", K); exit(2); }
}

// E25a: rev J needs intra-tile transposed tiles, and the transform must live in ONE place - the fused path
// initially uploaded the second projection's weights raw and produced garbage for it (while gate stayed
// bit-exact), which is how a missing permutation masqueraded as a broken fused kernel.
static void permute_tiles(const std::vector<char> &raw, uint32_t *dst, size_t ntiles, int K)
{
    const int NW = 8 * K;
    const uint32_t *src = (const uint32_t *)raw.data();
    for (size_t t = 0; t < ntiles; ++t)
        for (int q = 0; q < 8; ++q)
            for (int i = 0; i < K; ++i) dst[t * NW + i * 8 + q] = src[t * NW + q * K + i];
}

// KS is a template parameter here (E25b): with a runtime KS the in-situ combine lost the folded immediate
// offset for the second k-slice that the standalone probe had, and the merged body paid +27 % instructions for
// it (asm_insite/, out_e25b_combine.txt). Dispatching on the value instead of passing it costs 4 host-side
// kernels per body, which is nothing next to the gemm's instantiation count.
template <int KSn>
static void combine(sycl::queue &q, const int32_t *PART, const float *Q, const int32_t *SX8,
                    float *Y, const Meta &m, int rpad)
{
    const size_t total = (size_t)m.E * m.R * m.n;
    q.parallel_for(sycl::range<1>(total), [=](sycl::id<1> id)
    {
        const size_t i = id[0];
        const int e = (int)(i / ((size_t)m.R * m.n));
        const int row = (int)((i / m.n) % m.R);
        const int col = (int)(i % m.n);
        int32_t s = 0;
        for (int p = 0; p < KSn * 2; ++p)
            s += PART[(((size_t)p * m.E + e) * rpad + row) * m.n + col];   // contiguous in col
        Y[i] = m.kinv * Q[row] * ((float)s - 510.0f * (float)SX8[row]);
    });
}

// E25b, RESOLVED - three shapes of "fewer combine launches", measured in situ (anchor 19.4 us, all arms
// bit-exact; combine-section time at rows 1 / 8 / 16):
//   split  two launches, grid N each              9.54 / 11.29 / 13.20 us   (pre-E25b main path)
//   merged one launch,  grid 2N, one item/output  9.57 / 13.19 / 16.96 us   <- loses by 1.9-3.8 us
//   both   one launch,  grid N, item does BOTH    9.57 / 10.18 / 12.97 us   <- ADOPTED (combine_both below)
// Standalone, with no gemm ahead of it in the stream, the merged form is ~2x faster than two launches (rows=1
// 2.90 vs 5.86 us; rows=8 2.99 vs 5.99; rows=16 3.80 vs 5.95 - probe_combine.cpp), which is what the ~2.9 us
// per-launch protocol cost predicts. The reversal in situ was not L2 dirtiness, not the timing protocol (it held
// for burst-of-8 and for sync-per-iteration), not KS address folding (templatizing KS moved +3.5 to +3.4), and
// not the two partial regions being far apart (allocating them contiguously moved +3.5 to +3.6). What remained
// was GRID SIZE: doubling a grid dispatched immediately after a full-device ESIMD gemm costs more than the
// launch it saves. One item producing both projections keeps the single launch AND the original grid - and it is
// where the engine folds SiLU-mul, since both values land in registers, writing one product tensor instead of two
// outputs plus an elementwise pass. Noise floor: the gemm column of the same per-stage run varies +-1 us across
// arms with byte-identical code, so only the 3-4 us separations are meaningful. Full history, including how the
// ISA was read (both bodies: 3 lsc_load.ugm + 1 lsc_store; merged +27 % instructions), in out_e25b_combine.txt.


// E25b main path: ONE combine launch whose grid is the OUTPUT count (not 2x), each work-item producing BOTH
// projections' values. Keeping the grid at N is what made the single launch pay off in situ - the 2N-grid
// version, one item per output element per projection, lost to two separate launches (table above). It is also
// the natural home for SiLU-mul, since both values are already in registers: see combine_silu.
template <int KSn>
static void combine_both(sycl::queue &q, const int32_t *PA, const int32_t *PB, const float *Q,
                         const int32_t *SX8, float *YA, float *YB, const Meta &m, int rpad)
{
    const size_t one = (size_t)m.E * m.R * m.n;
    q.parallel_for(sycl::range<1>(one), [=](sycl::id<1> id)
    {
        const size_t j = id[0];
        const int e = (int)(j / ((size_t)m.R * m.n)), row = (int)((j / m.n) % m.R), col = (int)(j % m.n);
        const size_t base = (((size_t)e)* rpad + row) * m.n + col;
        const size_t sl = (size_t)m.E * rpad * m.n;
        int32_t sa = 0, sb = 0;
        for (int p = 0; p < KSn * 2; ++p) { sa += PA[p * sl + base]; sb += PB[p * sl + base]; }
        const float sc = m.kinv * Q[row], bias = 510.0f * (float)SX8[row];
        YA[j] = sc * ((float)sa - bias);
        YB[j] = sc * ((float)sb - bias);
    });
}

// E25b's payoff for the engine: same single launch, one item per output element, but writing only the product
// silu(gate) * up - the only consumer of both projections - so the layer drops an elementwise pass and half the
// combine's writes. Selected by DPAS_SILU=1 so both forms can be timed from one binary; exactness is checked
// against silu(y_ref_gate) * y_ref_up, computed on the host from the two cases' own references.
template <int KSn>
static void combine_silu(sycl::queue &q, const int32_t *PA, const int32_t *PB, const float *Q,
                        const int32_t *SX8, float *YOUT, const Meta &m, int rpad)
{
    const size_t one = (size_t)m.E * m.R * m.n;
    q.parallel_for(sycl::range<1>(one), [=](sycl::id<1> id)
    {
        const size_t j = id[0];
        const int e = (int)(j / ((size_t)m.R * m.n)), row = (int)((j / m.n) % m.R), col = (int)(j % m.n);
        const size_t base = (((size_t)e) * rpad + row) * m.n + col, sl = (size_t)m.E * rpad * m.n;
        int32_t sa = 0, sb = 0;
        for (int p = 0; p < KSn * 2; ++p) { sa += PA[p * sl + base]; sb += PB[p * sl + base]; }
        const float sc = m.kinv * Q[row], bias = 510.0f * (float)SX8[row];
        const float g = sc * ((float)sa - bias), u = sc * ((float)sb - bias);
        YOUT[j] = (g / (1.0f + expf(-g))) * u;
    });
}

#define DISPATCH_COMBINE(F, KSV, ...) do { switch (KSV) { \
    case 1: F<1>(__VA_ARGS__); break; case 2: F<2>(__VA_ARGS__); break; \
    case 4: F<4>(__VA_ARGS__); break; case 8: F<8>(__VA_ARGS__); break; \
    default: fprintf(stderr, "no combine instantiated for KS %d\n", (int)(KSV)); exit(2); } } while (0)

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
    if (argc < 2) { fprintf(stderr, "usage: %s CASE_DIR [reps] [rows] [ks] [layout] [dir2]\n", argv[0]); return 2; }
    const std::string dir = argv[1];
    const int reps = argc > 2 ? atoi(argv[2]) : 5;
    // (E25b settled: combine_both is the fused main path; the 2N-grid and two-launch forms were deleted.)
    static const bool SILU = getenv("DPAS_SILU") != nullptr;   // write silu(gate)*up instead of both outputs
    const int rows_arg = argc > 3 ? atoi(argv[3]) : 0;
    const int KS = argc > 4 ? atoi(argv[4]) : 1;
    const std::string layout = argc > 5 ? argv[5] : "native";      // native | staged | staged2 | staged8
    const std::string dir2 = argc > 6 ? argv[6] : "";              // optional: fuse this projection too
    int band = 0;                                                // staged tile banding g (0 = checkpoint)
    const bool staged = layout != "native";
    if (layout == "native") band = 0;
    else if (layout == "staged") band = 0;    // planar dwords, checkpoint tile order: isolates the two
    else if (layout == "staged2") band = 2;   // what AVX2 parents stage (moe_cpu_host._copy_repacked)
    else if (layout == "staged8") band = 8;   // what the AVX-512 BW tiers would stage, byte-for-byte
    else { fprintf(stderr, "layout must be native | staged | staged2 | staged8\n"); return 2; }
    Meta m = load_meta(dir);
    if (rows_arg > 0) m.R = rows_arg;
    if (m.R < 1 || m.R > 64) { fprintf(stderr, "rows %d outside 1..64\n", m.R); return 2; }
    if (KS < 1 || m.tk % KS || (m.tk / KS) % 2) { fprintf(stderr, "tk must split into even halves (KS %d, tk %d)\n", KS, m.tk); return 2; }
    const int K = (int)m.K;
    if (K < K_MIN || K > K_MAX) { fprintf(stderr, "rev L is compiled for K = %d..%d (K is %d)\n", K_MIN, K_MAX, K); return 2; }

    // Rows per launch = MR x NF fragments of M=8, capped at 16: the spill-free ceiling measured in E29. Above
    // 16 rows the engine buckets launches (additive law, out_rows_gt16.txt) rather than carrying more row state
    // through the weight stream.
    // probe_gemm: rows PER LAUNCH stay at rev L's spill-free ceiling (16). Anything beyond that is slabs, so
    // MR/NF are chosen from the launch rows, and NSLAB covers the rest. Rows total = NSLAB * RPAD.
    const int RLAUNCH = m.R > XROWS ? XROWS : m.R;
    const int MR = RLAUNCH <= 1 ? 1 : RLAUNCH <= 2 ? 2 : RLAUNCH <= 4 ? 4 : 8;
    const int NF = RLAUNCH <= 8 ? 1 : 2;
    const int RPAD = MR * NF;
    const int NSLAB = (m.R + RPAD - 1) / RPAD;      // 16-row slabs needed to cover the chunk's rows
    const int RPADT = NSLAB * RPAD;                 // PART's rows dimension
    const char *mode_env = getenv("GEMM_MODE");
    const int VARIANT_B = !(mode_env && strcmp(mode_env, "A") == 0);   // default B (concurrent slabs)

    // (E29's shared-stream buckets and the ablation switches lived here in rev J; both are kept in
    // probe_dpas7.cpp. They are absent here deliberately: the buckets lost, and a clean main path is worth
    // more than a switchboard.)

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
    // layout=staged* means the bytes are ALREADY in that order, which is the production AVX2 staged
    // form: moe_cpu_host._copy_repacked swaps each tile's trailing (8, bits) dword dims, i.e. dword w ->
    // 8*(w%bits) + w/bits - byte-identical to the map below (verified on /tmp/gemv_dpE10: 1.536M dwords).
    // So the B70 can consume the CPU's staged bytes verbatim; the staged* layouts are how that is tested.
    std::vector<uint32_t> hW(ntiles * NW);
    // Intra-tile transpose (rev J). Skipped when the input is already the parent's staged form, because the
    // planar dword order IS this transpose (verified byte-identical over 1.536 M dwords, out_cpu_layout.txt).
    // One definition of the map, shared with the fused projection below.
    if (!staged) permute_tiles(wbuf, hW.data(), ntiles, K);
    else memcpy(hW.data(), wbuf.data(), ntiles * NW * 4);

    // Activation tiles: XA[kt][kb][row][4*w + b] = x8[row][kt*16 + kb*8 + w], row < RPAD (rows >= R repeat
    // R-1), w = 0..7, b = 0..3 - so each (tile, byte-block, DPAS) A operand is one contiguous run.
    const int8_t *x8 = (const int8_t *)xbuf.data();
    const size_t xab = (size_t)m.tk * 2 * RPAD * 32;      // one slab's XA window, bytes (= tk * ADW dwords)
    std::vector<int8_t> hXA(xab * NSLAB);
    for (int sb = 0; sb < NSLAB; ++sb)
    for (int kt = 0; kt < m.tk; ++kt)
        for (int kb = 0; kb < 2; ++kb)
            for (int row = 0; row < RPAD; ++row)
            {
                const int rr = sb * RPAD + row;           // this slab's global row in the chunk
                const int8_t *src = x8 + (size_t)(rr < m.R ? rr : m.R - 1) * m.k + kt * 16 + kb * 8;
                int8_t *dst = &hXA[sb * xab + (((size_t)kt * 2 + kb) * RPAD + row) * 32];
                for (int w = 0; w < 8; ++w)
                    for (int b = 0; b < 4; ++b) dst[w * 4 + b] = src[w];
            }

    sycl::device dev{sycl::gpu_selector_v};
    sycl::context ctx{dev};
    sycl::queue q{ctx, dev, sycl::property::queue::in_order{}};

    // One expert per thread (D4). Both the expert-grid port on revs G/H/I and rev J's own DPAS_EPT sweep
    // independently landed here: it is a latency-hiding requirement, not only a partial-traffic fix.
    size_t hw_threads = 2048;   // B70: 32 Xe2 cores x 8 vector engines x 8 threads, if the query is absent
    if (dev.has(sycl::aspect::ext_intel_gpu_eu_count) && dev.has(sycl::aspect::ext_intel_gpu_hw_threads_per_eu))
        hw_threads = (size_t)dev.get_info<sycl::ext::intel::info::device::gpu_eu_count>() *
                     dev.get_info<sycl::ext::intel::info::device::gpu_hw_threads_per_eu>();

    printf("gemm %s: rows %d = NSLAB %d x %d rows/launch, RPAD %d, PART rows %d, threads %zu x %zu x NSLAB\n",
           VARIANT_B ? "B (concurrent slabs, one launch)" : "A (sequential bucket launches)",
           m.R, NSLAB, RPAD, RPAD, RPADT,
           (size_t)m.tn * KS * 2, (size_t)m.E);
    const double trellis_mib = wbuf.size() / 1048576.0;
    printf("case %s: E %d R %d k %d n %d K %d  trellis %.2f MiB  KS %d  layout %s\n",
           dir.c_str(), m.E, m.R, m.k, m.n, K, trellis_mib, KS, layout.c_str());
    printf("rev L: dpas %d x %d per byte-block (rows padded to %d), 1 expert/thread, %zu x %zu threads (%zu HW)\n",
           MR, NF, RPAD, (size_t)(m.tn + (dir2.empty() ? 0 : m.tn)) * KS * 2, (size_t)m.E, hw_threads);

    uint32_t *W = (uint32_t *)sycl::malloc_device(hW.size() * 4, q);
    uint32_t *XA = (uint32_t *)sycl::malloc_device(hXA.size(), q);
    float *Q = (float *)sycl::malloc_device(qbuf.size(), q);
    int32_t *SX8 = (int32_t *)sycl::malloc_device(sbuf.size(), q);
    float *Y = (float *)sycl::malloc_device((size_t)m.E * m.R * m.n * 4, q);
    const size_t pb = (size_t)KS * 2 * m.E * RPADT * m.n * 4;
    int32_t *PART = (int32_t *)sycl::malloc_device(pb, q);
    q.memcpy(W, hW.data(), hW.size() * 4);
    q.memset(XA, 0, hXA.size());
    q.memset(PART, 0, (size_t)KS * 2 * m.E * RPAD * m.n * 4);
    q.memcpy(XA, hXA.data(), hXA.size());
    q.memcpy(Q, qbuf.data(), qbuf.size());
    q.memcpy(SX8, sbuf.data(), sbuf.size());
    q.wait();

    // E25a/D8: an optional SECOND projection joins the same launch (gate+up fused). Each thread still serves
    // exactly one projection, so a fused launch carries one accumulator set, not two - the register lesson that
    // killed row bucketing (E29). What fusion saves is a launch and the machine's idle slots: gate and up read
    // different weights, so nothing of the weight stream is shared; the activation tiles are the same bytes and
    // are verified identical between the two case dirs.
    Meta m2 = m;
    uint32_t *W2 = nullptr;
    int32_t *PART2 = nullptr;
    float *Y2 = nullptr;
    if (!dir2.empty())
    {
        m2 = load_meta(dir2);
        // The case file's meta carries the row count it was dumped with; the run's row count comes from the CLI.
        // Skipping this override made combine() size by m2.R and write past the second output buffer, which
        // corrupted the FIRST projection's results too - a real bug that looked like a broken fused kernel.
        if (rows_arg > 0) m2.R = rows_arg;
        if (m2.E != m.E || m2.tk != m.tk || m2.tn != m.tn || (int)m2.K != K || m2.n != m.n || m2.R != m.R)
        { fprintf(stderr, "dir2 tiling differs from CASE_DIR; fusion needs identical shapes\n"); return 2; }
        std::vector<char> w2 = slurp(dir2 + "/weights.bin");
        const size_t wb = (size_t)m.E * m.tk * m.tn * NW * 4;
        if (w2.size() != wb) { fprintf(stderr, "dir2 weights: %zu bytes, expected %zu\n", w2.size(), wb); return 2; }
        std::vector<uint32_t> hW2(wb / 4);
        if (staged) memcpy(hW2.data(), w2.data(), wb);          // already in the B70 order
        else permute_tiles(w2, hW2.data(), ntiles, K);          // same single definition of the map
        const size_t ob = (size_t)m.E * m.R * m.n * 4;
        W2 = (uint32_t *)sycl::malloc_device(wb, q);
        PART2 = (int32_t *)sycl::malloc_device(pb, q);
        Y2 = (float *)sycl::malloc_device(ob, q);
        q.memcpy(W2, hW2.data(), wb);
        q.memset(PART2, 0, pb);
        q.memset(Y2, 0, (size_t)m.E * m.R * m.n * 4);
        q.wait();
    }

    Launch L;
    L.q = &q; L.W = W; L.XA = XA; L.PART = PART; L.m = m; L.KS = KS; L.band = band;
    // DPAS_WG: 0/absent = 2 (shipped); N = that work-group size; -1 = one group per expert (TN*KS*2 items).
    if (const char *w = getenv("DPAS_WG"))
    {
        int v = atoi(w);
        L.wgsize = v == -1 ? (int)((m.tn + (dir2.empty() ? 0 : m.tn)) * KS * 2) : v;
        printf("work-group size forced to %d (device hosts ~8 hw threads per EU; above that a group spans EUs)\n",
               L.wgsize);
    }
    L.W2 = W2; L.PART2 = PART2; L.tn2 = dir2.empty() ? 0 : m.tn;
    // Variant B carries the slabs inside ONE launch (grid axis, adjacent ids); variant A replays them as
    // sequential launches with a shifted XA window and PART row offset - today's engine behaviour.
    L.NSLAB = VARIANT_B ? NSLAB : 1;
    L.RPADT = RPADT;
    L.zero = 0;

    // gemm + a SEPARATE combine kernel. Fusing the combine with per-expert atomics was measured 4.5x more
    // expensive than the partial round trip it removes (D2), so the two-launch structure is the main path.
    auto gemm = [&]
    {
        if (VARIANT_B)
        {
            L.xa_off = 0; L.prow = 0;
            dispatch_k(K, MR, NF, L, std::make_integer_sequence<int, K_MAX - K_MIN + 1>{});
        }
        else
            for (int sb = 0; sb < NSLAB; ++sb)      // buckets at DIFFERENT times: E29's additive-law shape
            {
                L.xa_off = (size_t)sb * (xab / 4);   // dwords
                L.prow = sb * RPAD;
                dispatch_k(K, MR, NF, L, std::make_integer_sequence<int, K_MAX - K_MIN + 1>{});
            }
    };
    auto combines = [&]
    {
        DISPATCH_COMBINE(combine, KS, q, PART, Q, SX8, Y, m, RPADT);
        // E25b: fused gate+up get ONE combine whose grid is N (not 2N) - each item produces both projections.
        // Measured in situ against rows 1/8/16, anchor 19.4: this beats the 2N-grid merge by 3.0-4.0 us and
        // beats or ties the two-launch form, and it is where the engine folds SiLU-mul (both values are in
        // registers, so it can write one product tensor and halve the output traffic).
        if (!dir2.empty())
        {
            if (SILU) DISPATCH_COMBINE(combine_silu, KS, q, PART, PART2, Q, SX8, Y, m, RPAD);
            else DISPATCH_COMBINE(combine_both, KS, q, PART, PART2, Q, SX8, Y, Y2, m, RPAD);
        }
    };
    auto dispatch = [&] { gemm(); combines(); };

    // Sustained CONTINUOUS work in this process before timing. The device downclocks when idle, so warming up
    // with a chain of short separate runs (each with its own idle gap) measures whatever clock it happens to sit
    // at - which has shown up as a uniform ~2x shift across binaries that were never touched. 3 s is enough
    // (measured: 0/1/3/5/20 s -> 31.1/13.9/13.7/13.7/13.7 us); WARM_S overrides.
    //
    // The wait INSIDE the loop matters: enqueueing is much cheaper than executing once the per-launch work grows
    // (host submit ~40 us vs 400 us of GPU time at E=96), so a loop that only measures wall time while submitting
    // builds a backlog - a nominal 1 s warm-up at E=96 queued ~30 s of work and dumped it all on the first
    // q.wait(). Draining in batches makes WARM_S mean "seconds of work actually executed", which is what the
    // clock cares about, and keeps large-E runs from taking half a minute each.
    const double WARM_S = getenv("WARM_S") ? atof(getenv("WARM_S")) : 3.0;
    if (WARM_S > 0.0)
    {
        auto tw0 = std::chrono::steady_clock::now();
        do {
            for (int k = 0; k < 8; ++k) dispatch();
            q.wait();
        } while (std::chrono::duration<double>(std::chrono::steady_clock::now() - tw0).count() < WARM_S);
    }

    // DPAS_PROF=1: attribute time per stage, in situ - placed after the warm-up deliberately, since a cold
    // device shifts every stage. The combine SECTION is timed as ONE block whether it holds one launch or two,
    // so both arms pay exactly two waits and the timing protocol itself cannot account for the difference,
    // which is the whole point: the E25b anomaly only appears here, not standalone.
    if (getenv("DPAS_PROF"))
    {
        double tg = 1e30, tc = 1e30;
        for (int r = 0; r < 40; ++r)
        {
            auto t0 = std::chrono::steady_clock::now();
            gemm(); q.wait();
            auto t1 = std::chrono::steady_clock::now();
            combines(); q.wait();
            auto t2 = std::chrono::steady_clock::now();
            tg = std::min(tg, std::chrono::duration<double>(t1 - t0).count());
            tc = std::min(tc, std::chrono::duration<double>(t2 - t1).count());
        }
        printf("PROF %-5s rows %2d ks %d: gemm %7.2f us   combine section %7.2f us   total %7.2f us\n",
               dir2.empty() ? "1proj" : "fused", m.R, KS, tg * 1e6, tc * 1e6, (tg + tc) * 1e6);
    }

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

    // Rows > 16 is the engine's problem, not the kernel's: bucket 16-row launches, whose cost is additive to
    // within 1-2 % (out_rows_gt16.txt). The measurement harness for that law lives in probe_dpas7.cpp.
    const int rows_avail = (int)(xbuf.size() / (size_t)m.k);

    // E29's shared-stream buckets are NOT here: they lost to plain bucketing in every shape measured, because
    // carrying more than 16 rows of accumulators borrows register space from the prefetch ring (the ring sweep
    // in out_e29_share.txt). The implementation and its device-fault story remain in probe_dpas7.cpp.

    const double nproj = dir2.empty() ? 1.0 : 2.0;
    const double weights = (double)m.E * m.k * m.n * nproj;
    printf("revL ks %d rows %d %s layout %s: %8.1f us  %7.1f G-w/s  %6.1f GB/s(trellis)"
           "   [single-launch %7.1f us]  [M %dx%d, %zu tiles x %d experts]\n",
           KS, m.R, dir2.empty() ? "1-proj    " : "gate+up fused", layout.c_str(),
           tpbest * 1e6, weights / tpbest / 1e9, (wbuf.size() * nproj) / tpbest / 1e9,
           best * 1e6, MR, NF, (size_t)(m.tn + L.tn2), (size_t)m.E);

    // Outputs for the harness (gate_dpas.py) to compare bit-exactly. Deliberately no self-check here: rev J's
    // built-in comparison SKIPPED silently whenever the reference size mismatched the run, so its printed
    // "pass" below rows=16 had never actually compared anything.
    {
        char path[512];
        std::vector<float> y((size_t)m.E * m.R * m.n);
        q.memcpy(y.data(), Y, y.size() * 4); q.wait();
        snprintf(path, sizeof path, "%s/y_dev_ks%d_r%d.bin", dir.c_str(), KS, m.R);
        FILE *fo = fopen(path, "wb");
        if (fo) { fwrite(y.data(), 4, y.size(), fo); fclose(fo); }
        else fprintf(stderr, "could not write %s\n", path);
        if (!dir2.empty())
        {
            std::vector<float> y2(y.size());
            q.memcpy(y2.data(), Y2, y2.size() * 4); q.wait();
            snprintf(path, sizeof path, "%s/y_dev_ks%d_r%d_p2.bin", dir.c_str(), KS, m.R);
            FILE *f2 = fopen(path, "wb");
            if (f2) { fwrite(y2.data(), 4, y2.size(), f2); fclose(f2); }
            else fprintf(stderr, "could not write %s\n", path);
        }
    }


    sycl::free(W, q); sycl::free(XA, q); sycl::free(Q, q); sycl::free(SX8, q);
    sycl::free(Y, q); sycl::free(PART, q);
    if (!dir2.empty()) { sycl::free(W2, q); sycl::free(PART2, q); sycl::free(Y2, q); }
    return 0;
}
