// -----------------------------------------------------------------------------
// probe_dpas5.cpp - E24 step 5 (rev H): rev G's tokens-on-M matrix path, written in ESIMD so the
// unpacked weights feed DPAS straight from registers.
//
// Rev G's DPAS_REG experiment tried to hand the 16 products per lane to the matrix unit through
// joint_matrix_apply; IGC spilled them to scratch and reloaded them byte-wise in front of every DPAS.
// In ESIMD a thread owns all 16 columns as explicit vectors, and the register image xmx::dpas wants for
// B is exactly what the unpack produces: B element (k, n) is byte k%4 of dword (k/4)*16 + n, i.e. 8 rows
// of 16 column-dwords, and a column-dword is one weight's 4 product bytes. So per trellis tile:
//
//   * one block load of the tile's 8K dwords (16+8 for K=3) into a register ring, PF_DIST tiles ahead;
//   * 8 iselects pick each column's ring words (indices fixed per thread: same geometry as rev G);
//   * one funnel shift per ring-position group gives a 32-bit word that holds all four of its windows,
//     so each window is an immediate shift + mask, and its product goes straight into a B operand row;
//   * one block load of the activation tile (both byte-blocks, all padded token rows);
//   * 2 x xmx::dpas<8, M> (u8 weights x s8 activations -> s32), M = rows (1, 2, 4, 8; or 2 x 8).
//
// No SLM, no barriers, no matrix loads for B. K is a template parameter (2..5), so window offsets and
// the tile size are compile-time constants.
//
// What the BMG ISA looks like (AOT for bmg, IGC 2.42, checked before release): 128 GRF and no spills in
// all 20 variants; per 256-weight tile 81-96 instructions (K=3, M=1: 83 = 0.32/weight) - 3 block loads,
// 8 indirect moves, ~45 16-wide ALU ops, dpas.8xM reading B straight from the registers the products
// were written to. To compare with your driver: IGC_ShaderDumpEnable=1 IGC_DumpToCustomDir=<dir>, then
// look at the VC_*submitILi3ELi1ELi1E*.asm file. Three things in the source exist because of that ISA:
// the opaque `zero`, the compile-time ring slots in step(), and the incremental fetch pointer.
//
// Same window math and (t, j) -> (col, r) mapping as revs B-G; partials [ks][sub][e][token][col] and
// the combine pass are rev G's. Everything is integer, so y must be BIT-IDENTICAL to revs E-G.
//
// Switches (env):
//   DPAS_M=1|2|4|8      force rows per DPAS (default: smallest that covers rows; > 8 rows -> 2 x M=8)
//   DPAS_NO_MAD         unpack only;  DPAS_NO_UNPACK  matrix path only (stale B, no trellis loads)
//   DPAS_CHECK=<file>   bitwise comparison of y (default: CASE_DIR/y_ref.bin if present, right size)
//
// Build: notes/b70/build.sh probe_dpas5    Run: ./probe_dpas5 CASE_DIR [reps] [rows] [ks]
// Instantiates 4 K values x 5 M configurations; -fsycl-device-code-split=per_kernel keeps JIT short.
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
#include <vector>

namespace esimd = sycl::ext::intel::esimd;
namespace xmx = sycl::ext::intel::esimd::xmx;
using esimd::simd;

static constexpr int NCOL = 16;                 // output columns per trellis tile = DPAS execution size
static constexpr int XROWS = 16;                // max token rows
#ifndef PF_DIST_OVERRIDE
#define PF_DIST_OVERRIDE 2
#endif
// Trellis tiles fetched ahead. Build-tunable (-DPF_DIST_OVERRIDE=n) because the measured kernel sits ~4x
// above the DRAM floor and ~6x above its own issue floor, i.e. latency-bound: in-flight load count is the
// knob that should matter most, and the ISA shows the activation load issued in the same tile it feeds.
static constexpr int PF_DIST = PF_DIST_OVERRIDE;
static constexpr uint32_t HASH = 0x83DCD12Du;   // window -> 4 weight bytes

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

// Contiguous dword load in power-of-two LSC block sizes. Every caller's address is 16-byte aligned:
// trellis tiles start at multiples of 32K bytes, activation tiles at multiples of 64 bytes.
template <int NDW>
ESIMD_INLINE simd<uint32_t, NDW> load_dw(const uint32_t *p)
{
    constexpr esimd::properties props{esimd::alignment<16>};
    if constexpr (NDW == 8 || NDW == 16 || NDW == 32 || NDW == 64 || NDW == 128)
        return esimd::block_load<uint32_t, NDW>(p, props);
    else
    {
        constexpr int H = NDW >= 256 ? 128 : NDW >= 64 ? 32 : 16;   // 256 = 128+128, 40 = 32+8, 24 = 16+8
        static_assert(NDW > H, "unsupported block size");
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

struct Launch
{
    sycl::queue *q = nullptr;
    const uint32_t *W = nullptr;    // trellis, [e][kt][nt][8K] dwords
    const uint32_t *XA = nullptr;   // activation tiles [kt][kb][rpad][32 bytes], x replicated 4x along K
    int32_t *PART = nullptr;        // [ks][sub][e][rpad][n]
    Meta m;
    int KS = 8;
    int zero = 0;                   // always 0; opaque to the device compiler (see the kernel)
    bool skip_mad = false, skip_unpack = false;
    // 'X' (DPAS_X=1): experts in the grid as well as the k-slice (grid = tn*KS*E), so PART carries 2*KS
    // partials per output instead of 2*KS*E. rev H's timing showed it starved for parallelism without this.
    bool structx = false;
    // DPAS_DUP_LOAD=1: issue a second, non-CSE-able load of the same tile per iteration and sink the result
    // into a 4-byte scratch. Same unpack arithmetic, same DPAS, same y - so the delta over the plain build
    // is the marginal price of the load message stream itself (the LSU-volume hypothesis), which the K sweep
    // alone cannot settle because duplicated bytes scale with K while the time does not.
    bool dup_load = false;
    // DPAS_DUP_UNPACK=1: run the unpack a second time into a shadow operand image each tile, xor the result
    // into an accumulator and store it once after the loop (so nothing can be dead-code eliminated). Doubles
    // the unpack arithmetic at unchanged loads, DPAS and y: if the cost is ~0 the kernel is latency-bound and
    // ILP is the lever; if it roughly doubles the unpack term the kernel is issue-bound and the instruction
    // count has to come down.
    bool dup_unpack = false;
    uint32_t *bsink = nullptr;
    uint32_t *sink = nullptr;
};

// K = trellis bits per weight, MR = token rows per DPAS (repeat count), NF = DPAS per byte-block (1, or 2
// for 9-16 rows). One ESIMD thread = one (column tile, k-slice half), looping experts inside.
template <int K, int MR, int NF>
static void submit(const Launch &L)
{
    constexpr int NW = 8 * K;                 // dwords per trellis tile
    constexpr int RB = 256 * K;               // ring bits per tile
    constexpr int RPAD = MR * NF;             // padded token rows
    constexpr int ADW = RPAD * 16;            // activation dwords per tile: 2 byte-blocks x RPAD rows x 8
    constexpr int NSET = PF_DIST + 1;

    const Meta m = L.m;
    const int KS = L.KS;
    const int E = m.E, tk = m.tk, tn = m.tn, n = m.n;
    const int tps = tk / KS;                  // trellis tiles per k-slice
    const int per_sg = tps / 2;               // tiles per thread (main() enforces even halves)
    const size_t threads = (size_t)tn * KS * (L.structx ? E : 1) * 2;
    const bool skip_mad = L.skip_mad, skip_unpack = L.skip_unpack, structx = L.structx;
    const uint32_t *W = L.W;
    const uint32_t *XA = L.XA;
    int32_t *PART = L.PART;
    uint32_t *SINK = L.sink;
    const bool dup_load = L.dup_load;
    const bool dup_unpack = L.dup_unpack;
    const int zero = L.zero;

    L.q->submit([&](sycl::handler &cgh)
    {
        cgh.parallel_for(sycl::nd_range<1>(sycl::range<1>(threads), sycl::range<1>(2)),
                         [=](sycl::nd_item<1> it) SYCL_ESIMD_KERNEL
        {
            const int gid = (int)it.get_global_id(0);
            const int sub = gid & 1;
            const int grp = gid >> 1;
            const int nt = grp % tn;
            const int ks = structx ? (grp / tn) % KS : grp / tn;
            const int eg = structx ? grp / (tn * KS) : 0;      // expert owned by this thread group under 'X'
            const int kt0 = ks * tps + sub * per_sg;
            const int ntile = per_sg;
            const int total = (structx ? 1 : E) * ntile;

            // --- ring geometry, once per thread, as vectors over the 16 columns (rev G's col_ring) ---
            // Column c reads ring positions t = 4*(c&7) + a4, j = 4*(c>>3) + jl: window starts
            // start0 + K*(8*a4 + jl) (mod ring), start0 = K*(32*(c&7) + 4*(c>>3) + 1) - 16.
            // `zero` is a kernel argument that is always 0. It keeps these indices out of constant folding:
            // with K known, IGC otherwise folds each iselect into its consumers as a stride-K operand region,
            // which the ISA can only encode for K = 2 and 4 - for K = 3 the BMG code split every shift that
            // touches a ring word into 16 scalar instructions. Opaque, each iselect stays one 16-wide
            // indirect move.
            const simd<int32_t, NCOL> col = simd<int32_t, NCOL>(0, 1) + zero;
            simd<int32_t, NCOL> st = K * (32 * (col & 7) + 4 * (col >> 3) + 1) - 16;
            st.merge(st + RB, st < 0);
            simd<uint16_t, NCOL> ix[8];               // tile dword index of (a4, word 0/1)
            simd<uint32_t, NCOL> s0[4], rs0[4];       // bit offset of the a4 group's first window; 31 - s0
#pragma unroll
            for (int a4 = 0; a4 < 4; ++a4)
            {
                const simd<uint32_t, NCOL> P = simd<uint32_t, NCOL>(st) + (uint32_t)(8 * K * a4);
                simd<uint32_t, NCOL> w = P >> 5;
                w.merge(w - (uint32_t)NW, w >= (uint32_t)NW);
                simd<uint32_t, NCOL> w1 = w + 1u;
                w1.merge(simd<uint32_t, NCOL>(0u), w1 == (uint32_t)NW);
                ix[2 * a4] = simd<uint16_t, NCOL>(w);
                ix[2 * a4 + 1] = simd<uint16_t, NCOL>(w1);
                s0[a4] = P & 31u;
                rs0[a4] = 31u - s0[a4];
            }

            // --- trellis register ring: tile g lives in set g % NSET (compile-time slots, see step) ---
            // The fetch pointer advances by one tile row (tn tiles) per k step and jumps once per expert,
            // instead of re-deriving ((e*tk + kt)*tn + nt)*8K per tile (32 scalar instructions in the ISA).
            simd<uint32_t, NW> pf[NSET];
            const size_t kstride = (size_t)tn * NW;                                   // next kt, same expert
            const size_t estride = (size_t)tk * kstride - (size_t)(ntile - 1) * kstride; // last kt -> next expert
            const uint32_t *fp = W + (size_t)(structx ? eg : 0) * tk * kstride + (size_t)kt0 * kstride +
                                 (size_t)nt * NW;         // next tile to fetch
            // Under 'X' the ring must both start and stop at this group's expert. Getting only the store
            // counter right (as happened on rev G) loads expert 0 while PART is indexed correctly, which
            // yields confidently wrong output for every configuration.
            int fe = structx ? eg : 0, fti = 0;
            const int elast = structx ? eg + 1 : E;
            auto fetch = [&](simd<uint32_t, NW> &d) SYCL_ESIMD_FUNCTION
            {
                if (fe >= elast) return;
                d = load_dw<NW>(fp);
                if (++fti == ntile) { fti = 0; ++fe; fp += estride; }
                else fp += kstride;
            };
            if (!skip_unpack)
            {
#pragma unroll
                for (int d = 0; d < PF_DIST; ++d) fetch(pf[d]);
            }

            // --- B operands: weight row r of byte-block r/8 is dwords (r%8)*16 .. +15, one per column ---
            simd<uint32_t, 128> Bop[2] = {simd<uint32_t, 128>(0u), simd<uint32_t, 128>(0u)};
            // shadow image for DPAS_DUP_UNPACK (16 registers: 128 elements over 16 lanes)
            simd<uint32_t, 128> Bop2[2] = {simd<uint32_t, 128>(0u), simd<uint32_t, 128>(0u)};
            simd<uint32_t, 128> keep(0u);
            uint32_t *BSK = L.bsink + (size_t)gid * 256;
            auto unpack_into = [&](simd<uint32_t, NW> &t, simd<uint32_t, 128> (&B)[2]) SYCL_ESIMD_FUNCTION
            {
#pragma unroll
                for (int a4 = 0; a4 < 4; ++a4)
                {
                    // One funnel shift per ring-position group: w32 = bits s0..s0+31 of d0:d1 (s0 < 32;
                    // (d1 >> 1) >> (31 - s0) is d1 >> (32 - s0) without the s0 = 0 case).
                    const simd<uint32_t, NCOL> d0 = t.iselect(ix[2 * a4]);
                    const simd<uint32_t, NCOL> d1 = t.iselect(ix[2 * a4 + 1]);
                    const simd<uint32_t, NCOL> w32 = (d0 << s0[a4]) | ((d1 >> 1) >> rs0[a4]);
#pragma unroll
                    for (int jl = 0; jl < 4; ++jl)
                    {
                        // window jl = bits K*jl .. K*jl+15 of w32 (needs 3K + 16 <= 32, i.e. K <= 5): the
                        // shift is the same for every column, so it is an immediate, not a per-lane funnel
                        const simd<uint32_t, NCOL> win = (w32 >> (16 - K * jl)) & 0xFFFFu;
                        const int r = 2 * a4 + (jl & 1) + 8 * (jl >> 1);
                        B[r >> 3].template select<NCOL, 1>((r & 7) * NCOL) = win * HASH;
                    }
                }
            };
            auto unpack = [&](simd<uint32_t, NW> &t) SYCL_ESIMD_FUNCTION { unpack_into(t, Bop); };

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

            // One tile. U is the ring slot as a compile-time constant: the VC backend does not honour
            // #pragma unroll on a loop with an early exit, and a runtime slot index made it copy the tile
            // out of the ring one dword at a time (24 indirect moves per tile, seen in the BMG ISA).
            int ce = structx ? eg : 0, cti = 0;          // current tile
            const uint32_t *ap = XA + (size_t)kt0 * ADW;   // this thread's activation tiles
            auto step = [&](auto U) SYCL_ESIMD_FUNCTION
            {
                constexpr int u = decltype(U)::value;
                if (cti == 0)
                {
#pragma unroll
                    for (int f = 0; f < NF; ++f) acc[f] = 0;
                }
                if (!skip_unpack)
                {
                    fetch(pf[(u + PF_DIST) % NSET]);  // the set the previous tile just used
                    unpack(pf[u]);
                    if (dup_unpack)
                    {
                        // a DIFFERENT ring slot, so the compiler cannot fold this into the real unpack
                        unpack_into(pf[(u + 1) % NSET], Bop2);
                        keep = keep ^ (Bop2[0] ^ Bop2[1]);
                    }
                    if (dup_load)
                    {
                        // `zero` is a kernel argument that is always 0 and opaque to the optimizer (see the
                        // ring-index comment above): without it the duplicate folds into the real load.
                        const simd<uint32_t, NW> j = load_dw<NW>(fp + zero);
                        if (j[0] == 0xDEADBEEFu) *SINK = j[1];   // data-dependent, never true, cannot be removed
                    }
                }
                if (!skip_mad)
                {
                    simd<uint32_t, ADW> At = load_dw<ADW>(ap + (size_t)cti * ADW);   // select() is non-const
#pragma unroll
                    for (int kb = 0; kb < 2; ++kb)
#pragma unroll
                        for (int f = 0; f < NF; ++f)
                        {
                            const simd<uint32_t, MR * 8> a =
                                At.template select<MR * 8, 1>(kb * RPAD * 8 + f * MR * 8);
                            acc[f] = xmx::dpas<8, MR, int32_t, int32_t, uint32_t, uint32_t,
                                               xmx::dpas_argument_type::u8, xmx::dpas_argument_type::s8>(
                                acc[f], Bop[kb], a);
                        }
                }
                if (++cti == ntile)
                {
                    store_part(ce);
                    cti = 0;
                    ++ce;
                }
            };
            for (int g0 = 0; g0 < total; g0 += NSET) unrolled<0, NSET>(step, g0, total);
            if (dup_unpack)
            {
#pragma unroll
                for (int i = 0; i < 128; ++i) BSK[i] = keep[i];
            }
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
    if (K < 2 || K > 5) { fprintf(stderr, "rev H is instantiated for K = 2..5 (K is %d)\n", K); return 2; }

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

    auto wbuf = slurp(dir + "/weights.bin");
    auto xbuf = slurp(dir + "/x8.bin");
    auto qbuf = slurp(dir + "/q.bin");
    auto sbuf = slurp(dir + "/sx8.bin");
    const size_t wexp = (size_t)m.E * m.tk * m.tn * 8 * K * 4;
    if (wbuf.size() != wexp) { fprintf(stderr, "weights.bin has %zu bytes, meta implies %zu\n", wbuf.size(), wexp); return 2; }
    if (xbuf.size() < (size_t)m.R * m.k || qbuf.size() < (size_t)m.R * 4 || sbuf.size() < (size_t)m.R * 4)
    {
        fprintf(stderr, "x8/q/sx8 hold fewer than %d rows\n", m.R);
        return 2;
    }

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

    const double trellis_mib = wbuf.size() / 1048576.0;
    printf("case %s: E %d R %d k %d n %d K %d  trellis %.2f MiB  KS %d  threads %d\n",
           dir.c_str(), m.E, m.R, m.k, m.n, K, trellis_mib, KS,
           m.tn * KS * (getenv("DPAS_X") ? m.E : 1) * 2);
    printf("rev H (ESIMD): dpas repeat count %d x %d per byte-block (rows padded to %d), no SLM\n", MR, NF, RPAD);

    sycl::device dev{sycl::gpu_selector_v};
    sycl::context ctx{dev};
    sycl::queue q{ctx, dev, sycl::property::queue::in_order{}};

    uint32_t *W = (uint32_t *)sycl::malloc_device(wbuf.size(), q);
    uint32_t *SINK = (uint32_t *)sycl::malloc_device(4, q);
    // sized by the ACTUAL thread count: under DPAS_X the grid is tn*KS*E, so the old tn*KS*2 sizing would
    // have been an out-of-bounds write exactly when the ablation was switched on.
    uint32_t *BSINK = (uint32_t *)sycl::malloc_device(
                          (size_t)m.tn * KS * (getenv("DPAS_X") ? m.E : 1) * 2 * 256 * 4, q);
    q.memset(SINK, 0, 4);
    uint32_t *XA = (uint32_t *)sycl::malloc_device(hXA.size(), q);
    float *Q = (float *)sycl::malloc_device(qbuf.size(), q);
    int32_t *SX8 = (int32_t *)sycl::malloc_device(sbuf.size(), q);
    float *Y = (float *)sycl::malloc_device((size_t)m.E * m.R * m.n * 4, q);
    int32_t *PART = (int32_t *)sycl::malloc_device((size_t)KS * 2 * m.E * RPAD * m.n * 4, q);
    q.memcpy(W, wbuf.data(), wbuf.size());
    q.memcpy(XA, hXA.data(), hXA.size());
    q.memcpy(Q, qbuf.data(), qbuf.size());
    q.memcpy(SX8, sbuf.data(), sbuf.size());
    q.wait();

    Launch L;
    L.q = &q; L.W = W; L.XA = XA; L.PART = PART; L.m = m; L.KS = KS;
    L.sink = SINK;
    L.bsink = BSINK;
    L.skip_mad = getenv("DPAS_NO_MAD") != nullptr;
    L.structx = getenv("DPAS_X") != nullptr;
    L.dup_load = getenv("DPAS_DUP_LOAD") != nullptr;
    L.dup_unpack = getenv("DPAS_DUP_UNPACK") != nullptr;
    L.skip_unpack = getenv("DPAS_NO_UNPACK") != nullptr;
    L.zero = 0;                     // a kernel argument, so the device compiler cannot fold it

    auto dispatch = [&]
    {
        switch (K)
        {
        case 2: submit_k<2>(MR, NF, L); break;
        case 3: submit_k<3>(MR, NF, L); break;
        case 4: submit_k<4>(MR, NF, L); break;
        default: submit_k<5>(MR, NF, L); break;
        }
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
    printf("revH ks %d rows %d: %8.1f us  %7.1f G-w/s  %6.2f slots/weight  %6.1f GB/s(trellis)"
           "   [burst; single-launch %7.1f us = %7.1f G-w/s, %.2f slots/w]  [M %dx%d esimd]\n",
           KS, m.R, tpbest * 1e6, weights / tpbest / 1e9, slots_per_weight, wbuf.size() / tpbest / 1e9,
           best * 1e6, weights / best / 1e9, 1.43e12 * best / weights, MR, NF);

    char outpath[512];
    snprintf(outpath, sizeof outpath, "%s/y_dev_revh_ks%d_r%d_m%dx%d.bin", dir.c_str(), KS, m.R, MR, NF);
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

    sycl::free(W, q); sycl::free(XA, q); sycl::free(Q, q); sycl::free(SX8, q);
    sycl::free(Y, q); sycl::free(PART, q);
    return 0;
}
