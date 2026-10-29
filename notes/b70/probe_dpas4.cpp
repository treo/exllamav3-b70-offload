// -----------------------------------------------------------------------------
// probe_dpas4.cpp - E24 step 4 (rev G): TOKENS ON M. The matrix path that scales down to rows = 1.
//
// Revs D-F put tokens on N, which XMX fixes at 16 for int8, so every DPAS did 16 tokens' work and
// rows = 1 cost the same as rows = 16 (that is what "flat in rows" meant). Rev G swaps the operands:
//
//   A  = activation, int8, row-major, M = token rows (1, 2, 4 or 8; two M = 8 fragments for 9-16 rows),
//        each x replicated 4x along K: A[m][4w + b] = x[m][w]. Row-major is A's native DPAS layout.
//   B  = weights, uint8, ext_intel_packed, K = 32 bytes (8 weights) x N = 16 output columns. A packed
//        dword is 4 consecutive K-bytes of one column - exactly one weight's 4 product bytes - so
//        assembly is still ONE u32 per weight; the B tile is [weight r][column] at r*64 + col*4.
//   C  = [token][column], M x 16 int32.
//
// int8 x uint8 -> int32 with M <= 8, N = 16, K = 32 is in the extension's XMX table for BMG (Intel's
// joint_matrix_su_int8 test). M is the DPAS repeat count, so matrix work should fall roughly with rows:
// per trellis tile it is 2 DPAS of M = rows (rows <= 8) instead of rev F's 4 of M = 8.
//
// Unpack is reorganised so LANE = OUTPUT COLUMN. Column c of a tile comes from ring positions
// t = 4*(c&7) + a4 (a4 = 0..3) with j = 4*(c>>3) + jl (jl = 0..3) - same window math and (t, j) -> (col, r)
// mapping as revs B-F, regrouped. Each lane therefore reads 4 neighbouring ring positions (8 dword
// loads per tile, ring indices computed once per thread), and every B-tile store is one contiguous
// 64-byte row (16 lanes = 16 columns of one weight row).
//
// Kept from rev F, now always on: sub-group barriers, a double-buffered B tile, trellis fetch-ahead
// (PF_DIST tiles, statically renamed register sets), 32-bit window cut. A comes straight from a small
// global tensor (L1-resident), so SLM holds only the B tiles: 4 KiB per work-group.
//
// Partials are [ks][sub][e][token][col] with only the padded token rows, so the partial-sum stream
// shrinks with rows (at rows = 1 it is 1/16 of rev F's) and the combine pass reads contiguous columns.
// If you have your own item-5 reduction, it should port onto this layout directly.
//
// EXPERIMENTAL, off by default - DPAS_REG=1: no SLM at all. In packed B's register layout each lane
// holds its own column, and with lane = column a lane's 16 products ARE its two B fragments. They are
// written in with sycl::ext::intel::experimental::matrix::joint_matrix_apply (element coordinates).
// Correct under the extension's documented coordinates, but whether IGC lowers it to plain register
// moves is exactly what to check (ISA dump, or just the timing): if not, ESIMD's xmx::dpas is the route.
//
// Everything is integer and the combine is unchanged in substance, so y must be BIT-IDENTICAL to revs
// E/F. DPAS_CHECK=<file> compares bitwise (default: CASE_DIR/y_ref.bin if present and the right size).
//
// Switches (env):
//   DPAS_M=1|2|4|8      force the rows per A fragment (default: smallest that covers rows; rows > 8
//                       always use two M = 8 fragments). DPAS_M=8 at rows = 1 measures what M buys.
//   DPAS_X=1              experts in the grid too (grid = tn*KS*E); PART drops its E multiplier
//   DPAS_REG=1          experimental in-register B (above)
//   DPAS_NO_MAD         unpack + assembly only;  DPAS_NO_UNPACK  matrix path only (stale B)
//   DPAS_CHECK=<file>   bitwise comparison of y against a reference file
//
// Build: notes/b70/build.sh probe_dpas4    Run: ./probe_dpas4 CASE_DIR [reps] [rows] [ks]
// Requires K <= 5 (every window of a ring-position group lies within two dwords).
// -----------------------------------------------------------------------------
#include <sycl/sycl.hpp>
#include <sycl/ext/oneapi/matrix/matrix.hpp>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <string>
#include <vector>

namespace mx = sycl::ext::oneapi::experimental::matrix;

static constexpr int MK = 32;                   // matrix K for int8 = 8 weights x 4 bytes
static constexpr int NCOL = 16;                 // matrix N = output columns of one trellis tile
static constexpr int SGSZ = 16;                 // XMX needs 16-lane sub-groups
static constexpr int ROW_BYTES = NCOL * 4;      // one packed B row: 16 columns x 4 bytes
static constexpr int B_TILE = 16 * ROW_BYTES;   // one assembled tile: 16 weight rows x 16 columns = 1 KiB
static constexpr int XROWS = 16;                // rows held in the activation tensor (max tokens)
static constexpr int PF_DIST = 2;               // trellis tiles fetched ahead (8 GRF-dwords per tile in flight)

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

// The address space is a template argument of the load; the pointer's element type must MATCH the
// matrix data type (see LESSONS 31): A is int8_t (signed activations), B is uint8_t (product bytes).
template <sycl::access::address_space SP, typename T, typename MAT>
static void ld_matrix(sycl::sub_group sg, MAT &mat, T *p, int ldm)
{
    auto pp = sycl::address_space_cast<SP, sycl::access::decorated::no>(p);
    mx::joint_matrix_load(sg, mat, pp, ldm);
}

// ---------------------------------------------------------------------------
// Lane = output column c. Its 16 weights come from ring positions t = 4*(c&7) + a4 and
// j = 4*(c>>3) + jl, i.e. window starts K*(8t + j + 1) - 16 = start0 + K*(8*a4 + jl) (mod ring), with
// start0 = K*(32*(c&7) + 4*(c>>3) + 1) - 16. Weight row r = 2*a4 + (jl&1) + 8*(jl>>1) (rev B-F mapping).
// Per a4 the four windows start within K*3 bits of each other, so two dwords hold them all (K <= 5).
// ---------------------------------------------------------------------------
struct ColRing
{
    uint32_t ix[8];   // dword indices into the tile: (a4, 0/1)
    uint32_t s0[4];   // bit offset of the a4 group's first window in its first dword
};
static inline ColRing col_ring(int c, int K, uint32_t nw, int RB)
{
    ColRing cr;
    int start0 = K * (32 * (c & 7) + 4 * (c >> 3) + 1) - 16;
    start0 = start0 < 0 ? start0 + RB : (start0 >= RB ? start0 - RB : start0);
    for (int a4 = 0; a4 < 4; ++a4)
    {
        const uint32_t P = (uint32_t)start0 + (uint32_t)(8 * K * a4);   // < RB + 24K, so one wrap at most
        uint32_t w = P >> 5;
        w = w >= nw ? w - nw : w;
        cr.ix[2 * a4] = w;
        cr.ix[2 * a4 + 1] = (w + 1 == nw) ? 0u : w + 1u;
        cr.s0[a4] = P & 31u;
    }
    return cr;
}

// 16 products of one column, indexed by weight row r. Window bits s..s+15 of d0:d1, s <= 31 + 3K <= 46:
// for s >= 32 the window lies inside d1 and the low word's bits fall below bit 16, so lo = d1 always.
static inline void unpack_col(uint32_t (&prod)[16], const uint32_t *d, const uint32_t (&s0)[4], int K)
{
#pragma unroll
    for (int a4 = 0; a4 < 4; ++a4)
    {
        const uint32_t d0 = d[2 * a4], d1 = d[2 * a4 + 1];
#pragma unroll
        for (int jl = 0; jl < 4; ++jl)
        {
            const uint32_t s = s0[a4] + (uint32_t)(K * jl);
            const uint32_t hi = s >= 32u ? d1 : d0, sh = s & 31u;
            const uint32_t win = ((hi << sh) | ((d1 >> 1) >> (31u - sh))) >> 16;
            prod[2 * a4 + (jl & 1) + 8 * (jl >> 1)] = (uint32_t)(uint16_t)win * 0x83DCD12Du;
        }
    }
}

struct Launch
{
    sycl::queue *q = nullptr;
    const uint32_t *W = nullptr;   // trellis, [e][kt][nt][nw] dwords
    const int8_t *X4 = nullptr;    // [XROWS][4k]: x replicated 4x along K; rows >= R repeat R-1
    int32_t *PART = nullptr;       // [ks][sub][e][rpad][n]
    Meta m;
    int KS = 8;
    // DPAS_DUP_UNPACK=1: run unpack_col a second time per tile on a different ring slot and fold all 16
    // products into one data-dependent predicate, so none of them can be eliminated. Same loads, same
    // stores, same DPAS, same y. Priced alongside rev H's identical knob to answer "whose unpack is
    // cheaper per tile", since rev G is faster overall while also doing 16 SLM stores per tile.
    bool dup_unpack = false;
    uint32_t *gsink = nullptr;
    // 'X' (DPAS_X=1): put the experts in the grid as well as the k-slice. A group then covers one expert and
    // one k-slice, so PART holds 2*KS partials per output instead of 2*KS*E - the item-5 reduction, on top
    // of rev G's rows-scaled partial layout. KS stays usable (grid = tn*KS*E), which is what makes the trade
    // smooth: high KS no longer has to be paid for in partial traffic.
    bool structx = false;
    bool skip_mad = false, skip_unpack = false;
};

// MR = rows per A fragment (1, 2, 4, 8), NF = A fragments (1, or 2 for 9-16 rows), REG = in-register B.
template <int MR, int NF, bool REG>
static void submit(const Launch &L)
{
    constexpr int RPAD = MR * NF;
    constexpr int NSET = PF_DIST + 1;
    using AMat = mx::joint_matrix<sycl::sub_group, int8_t, mx::use::a, MR, MK, mx::layout::row_major>;
    using BMat = mx::joint_matrix<sycl::sub_group, uint8_t, mx::use::b, MK, NCOL, mx::layout::ext_intel_packed>;
    using CMat = mx::joint_matrix<sycl::sub_group, int32_t, mx::use::accumulator, MR, NCOL>;

    const Meta m = L.m;
    const int KS = L.KS;
    const int E = m.E, tk = m.tk, tn = m.tn, n = m.n, k = m.k;
    const int K = (int)m.K;
    const int tps = tk / KS;                  // trellis tiles per k-slice
    const int per_sg = tps / 2;               // tiles per sub-group (main() enforces even halves)
    const size_t groups = (size_t)tn * KS * (L.structx ? (size_t)E : 1u);
    const uint32_t nw = (uint32_t)(8 * K);    // dwords per trellis tile
    const int RB = 256 * K;                   // ring bits per tile
    const size_t slmSub = REG ? 0 : 2 * (size_t)B_TILE;   // double-buffered B tile per sub-group
    const size_t slmTotal = std::max<size_t>(2 * slmSub, 64);
    const bool skip_mad = L.skip_mad, skip_unpack = L.skip_unpack;
    const bool L_dup_unpack = L.dup_unpack;
    uint32_t *L_gsink = L.gsink;
    const uint32_t *W = L.W;
    const int8_t *X4 = L.X4;
    int32_t *PART = L.PART;
    const bool structx = L.structx;

    L.q->submit([&](sycl::handler &cgh)
    {
        sycl::local_accessor<uint8_t, 1> SLM(sycl::range<1>(slmTotal), cgh);
        cgh.parallel_for(sycl::nd_range<1>(sycl::range<1>(groups * SGSZ * 2), sycl::range<1>(SGSZ * 2)),
                         [=](sycl::nd_item<1> it) [[sycl::reqd_sub_group_size(SGSZ)]]
        {
            const sycl::sub_group sg = it.get_sub_group();
            const int l = (int)it.get_local_id(0);
            const int sub = l / SGSZ;                       // 0 or 1 within the work-group
            const int lane = l % SGSZ;                      // = output column within the tile
            const int grp = (int)it.get_group(0);
            const int nt = grp % tn;
            const int ks = structx ? (grp / tn) % KS : grp / tn;
            const int eg = structx ? grp / (tn * KS) : 0;      // expert owned by this group under 'X'
            const int kt0 = ks * tps + sub * per_sg;
            const int ntile = per_sg;
            const int total = (structx ? 1 : E) * ntile;

            uint8_t *Bbase =
                SLM.template get_multi_ptr<sycl::access::decorated::no>().get() + (size_t)sub * slmSub;

            const ColRing cr = col_ring(lane, K, nw, RB);    // once per thread

            auto tile_ptr = [&](int e, int ti) -> const uint32_t *
            {
                return W + ((size_t)e * tk + kt0 + ti) * tn * nw + (size_t)nt * nw;
            };

            // Register ring of NSET tiles (tile g in set g % NSET); the loop is unrolled by NSET so set
            // indices are compile-time constants and no move ever waits on an in-flight load.
            uint32_t pf[NSET][8];
            // The fetch ring walks (expert, tile) pairs independently of ce, so under 'X' it has to start at
            // this group's expert and stop after it - omitting that loads expert 0 everywhere and yields
            // confidently wrong output for every KS and row count (it did, on the first try here).
            int fe = structx ? eg : 0, fti = 0;               // next tile to fetch
            const int elast = structx ? eg + 1 : E;
            auto fetch = [&](uint32_t *d)
            {
                if (fe >= elast) return;
                const uint32_t *p = tile_ptr(fe, fti);
#pragma unroll
                for (int i = 0; i < 8; ++i) d[i] = p[cr.ix[i]];
                if (++fti == ntile) { fti = 0; ++fe; }
            };
            if (!skip_unpack)
            {
#pragma unroll
                for (int d = 0; d < PF_DIST; ++d) fetch(pf[d]);
            }

            auto load_a = [&](AMat &a, int ti, int kb, int f)
            {
                ld_matrix<sycl::access::address_space::global_space>(
                    sg, a, X4 + (size_t)(8 * f) * (4 * k) + (size_t)(kt0 + ti) * 64 + kb * MK, 4 * k);
            };

            uint32_t prod[16] = {};
            int ce = eg, cti = 0;                            // current tile
            CMat c[NF];
            for (int g0 = 0; g0 < total; g0 += NSET)
            {
#pragma unroll
                for (int u = 0; u < NSET; ++u)
                {
                    const int g = g0 + u;
                    if (g >= total) break;
                    if (cti == 0)
                    {
#pragma unroll
                        for (int f = 0; f < NF; ++f) mx::joint_matrix_fill(sg, c[f], int32_t(0));
                    }
                    if (!skip_unpack)
                    {
                        fetch(pf[(u + PF_DIST) % NSET]);    // the set the previous tile just used
                        unpack_col(prod, pf[u], cr.s0, K);
                        if (L_dup_unpack)
                        {
                            uint32_t px[16];
                            unpack_col(px, pf[(u + 1) % NSET], cr.s0, K);
                            uint32_t z = 0u;
#pragma unroll
                            for (int i = 0; i < 16; ++i) z ^= px[i];
                            if (z == 0xDEADBEEFu) *L_gsink = z;   // never taken; keeps all 16 products live
                        }
                    }

                    if constexpr (!REG)
                    {
                        // one contiguous 64-byte row per store: all 16 lanes write weight row r
                        uint8_t *Bt = Bbase + (g & 1) * B_TILE;
                        if (!skip_unpack)
                        {
#pragma unroll
                            for (int r = 0; r < 16; ++r)
                                *(uint32_t *)(Bt + r * ROW_BYTES + lane * 4) = prod[r];
                        }
                        sycl::group_barrier(sg);
                        if (!skip_mad)
                        {
#pragma unroll
                            for (int kb = 0; kb < 2; ++kb)
                            {
                                BMat b;
                                ld_matrix<sycl::access::address_space::local_space>(
                                    sg, b, Bt + kb * 8 * ROW_BYTES, ROW_BYTES);
#pragma unroll
                                for (int f = 0; f < NF; ++f)
                                {
                                    AMat a;
                                    load_a(a, cti, kb, f);
                                    mx::joint_matrix_mad(sg, c[f], a, b, c[f]);
                                }
                            }
                        }
                    }
                    else
                    {
                        if (!skip_mad)
                        {
#pragma unroll
                            for (int kb = 0; kb < 2; ++kb)
                            {
                                // packed B: element (row, col) is byte row%4 of weight row 8*kb + row/4 of
                                // column col, and in XMX's B layout col is this lane - so it is ours.
                                // The fill is load-bearing: apply only edits a matrix that is already
                                // defined. On a bare `BMat b;` DPC++ 2026.2 deletes the apply, the mads and
                                // the whole unpack (an undefined operand makes the path unreachable).
                                BMat b;
                                mx::joint_matrix_fill(sg, b, (uint8_t)0);
                                sycl::ext::intel::experimental::matrix::joint_matrix_apply(
                                    sg, b, [&](uint8_t &x, size_t row, size_t col)
                                    {
                                        (void)col;
                                        x = (uint8_t)(prod[8 * kb + (row >> 2)] >> (8 * (row & 3)));
                                    });
#pragma unroll
                                for (int f = 0; f < NF; ++f)
                                {
                                    AMat a;
                                    load_a(a, cti, kb, f);
                                    mx::joint_matrix_mad(sg, c[f], a, b, c[f]);
                                }
                            }
                        }
                    }

                    if (++cti == ntile)
                    {
                        int32_t *P = PART + ((((size_t)ks * 2 + sub) * E + ce) * RPAD) * (size_t)n + (size_t)nt * NCOL;
#pragma unroll
                        for (int f = 0; f < NF; ++f)
                        {
                            auto pC = sycl::address_space_cast<sycl::access::address_space::global_space,
                                                               sycl::access::decorated::no>(P + (size_t)(8 * f) * n);
                            mx::joint_matrix_store(sg, c[f], pC, n, mx::layout::row_major);
                        }
                        cti = 0;
                        ++ce;
                    }
                }
            }
        });
    });
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
    if (K < 1 || K > 5) { fprintf(stderr, "rev G's unpack assumes K <= 5 (K is %d)\n", K); return 2; }

    // rows per A fragment: smallest that covers R, or DPAS_M; more than 8 rows -> two M = 8 fragments
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
    const bool REG = getenv("DPAS_REG") != nullptr;

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

    // A source: X4[t][4w + b] = x8[t][w], rows >= R repeat row R-1 (in bounds; never read back).
    const int8_t *x8 = (const int8_t *)xbuf.data();
    std::vector<int8_t> hX4((size_t)XROWS * 4 * m.k);
    for (int t = 0; t < XROWS; ++t)
    {
        const int8_t *src = x8 + (size_t)(t < m.R ? t : m.R - 1) * m.k;
        for (int w = 0; w < m.k; ++w)
            for (int b = 0; b < 4; ++b) hX4[((size_t)t * m.k + w) * 4 + b] = src[w];
    }

    const double trellis_mib = wbuf.size() / 1048576.0;
    printf("case %s: E %d R %d k %d n %d K %d  trellis %.2f MiB  KS %d  work-groups %d  sub-groups %d\n",
           dir.c_str(), m.E, m.R, m.k, m.n, K, trellis_mib, KS,
           m.tn * KS * (getenv("DPAS_X") ? m.E : 1), m.tn * KS * (getenv("DPAS_X") ? m.E : 1) * 2);
    printf("rev G: M %d x %d fragment%s (rows padded to %d), B %s, SLM per work-group %d KiB\n",
           MR, NF, NF > 1 ? "s" : "", RPAD, REG ? "in registers (experimental)" : "via SLM",
           REG ? 0 : 4);

    sycl::device dev{sycl::gpu_selector_v};
    sycl::context ctx{dev};
    sycl::queue q{ctx, dev, sycl::property::queue::in_order{}};

    uint32_t *W = (uint32_t *)sycl::malloc_device(wbuf.size(), q);
    int8_t *X4 = (int8_t *)sycl::malloc_device(hX4.size(), q);
    float *Q = (float *)sycl::malloc_device(qbuf.size(), q);
    int32_t *SX8 = (int32_t *)sycl::malloc_device(sbuf.size(), q);
    float *Y = (float *)sycl::malloc_device((size_t)m.E * m.R * m.n * 4, q);
    int32_t *PART = (int32_t *)sycl::malloc_device((size_t)KS * 2 * m.E * RPAD * m.n * 4, q);
    q.memcpy(W, wbuf.data(), wbuf.size());
    q.memcpy(X4, hX4.data(), hX4.size());
    q.memcpy(Q, qbuf.data(), qbuf.size());
    q.memcpy(SX8, sbuf.data(), sbuf.size());
    q.wait();

    Launch L;
    L.q = &q; L.W = W; L.X4 = X4; L.PART = PART; L.m = m; L.KS = KS;
    L.skip_mad = getenv("DPAS_NO_MAD") != nullptr;
    L.dup_unpack = getenv("DPAS_DUP_UNPACK") != nullptr;
    L.gsink = (uint32_t *)sycl::malloc_device(4, q);
    L.skip_unpack = getenv("DPAS_NO_UNPACK") != nullptr;
    L.structx = getenv("DPAS_X") != nullptr;

    auto dispatch = [&]
    {
        switch (RPAD * 2 + (REG ? 1 : 0))
        {
        case 2:  submit<1, 1, false>(L); break;
        case 3:  submit<1, 1, true>(L);  break;
        case 4:  submit<2, 1, false>(L); break;
        case 5:  submit<2, 1, true>(L);  break;
        case 8:  submit<4, 1, false>(L); break;
        case 9:  submit<4, 1, true>(L);  break;
        case 16: submit<8, 1, false>(L); break;
        case 17: submit<8, 1, true>(L);  break;
        case 32: submit<8, 2, false>(L); break;
        case 33: submit<8, 2, true>(L);  break;
        default: fprintf(stderr, "no variant for %d rows\n", RPAD); exit(2);
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
    printf("revG ks %d rows %d: %8.1f us  %7.1f G-w/s  %6.2f slots/weight  %6.1f GB/s(trellis)"
           "   [burst; single-launch %7.1f us = %7.1f G-w/s, %.2f slots/w]  [M %dx%d %s]\n",
           KS, m.R, tpbest * 1e6, weights / tpbest / 1e9, slots_per_weight, wbuf.size() / tpbest / 1e9,
           best * 1e6, weights / best / 1e9, 1.43e12 * best / weights, MR, NF, REG ? "reg" : "slm");

    char outpath[512];
    snprintf(outpath, sizeof outpath, "%s/y_dev_revg_ks%d_r%d_m%dx%d_%s.bin", dir.c_str(), KS, m.R, MR, NF,
             REG ? "reg" : "slm");
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

    sycl::free(W, q); sycl::free(X4, q); sycl::free(Q, q); sycl::free(SX8, q);
    sycl::free(Y, q); sycl::free(PART, q);
    return 0;
}
