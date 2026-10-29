// -----------------------------------------------------------------------------
// probe_dpas3.cpp - E24 step 3 (rev F): rev E with the operand-path fixes, each behind a switch.
//
// Rev E priced trellis unpack + SLM assembly at ~24 slots/weight. A hand count of the unpack is ~1-2,
// so the gap is memory messages and stalls rather than arithmetic. Rev F removes the suspected causes
// one at a time. DPAS_F selects them (default "psfu" = all on; DPAS_F=none = rev E's code paths):
//
//   p  B PATH. DPAS wants B VNNI-packed (4 consecutive K bytes per dword). A row-major int8 B makes
//      joint_matrix_load transform it: a 2D block load can do that from global (pitch permitting -
//      row-major B has a 16-byte pitch), nothing can from SLM, so there it becomes per-byte gathers plus
//      packing. Here B is stored packed and loaded as ext_intel_packed. Every weight's 4 bytes multiply
//      the same activation, so the packed dword is x * 0x01010101, and byte offsets into B are unchanged
//      (byte row r -> packed row r/4 at 4*NTOK bytes = r*NTOK); only the stride and the layout tag
//      change. SLM staging becomes one 16-byte x8 load per lane per tile (lane = token) instead of 64
//      dependent byte loads. Also: B is loaded once per (tile, byte-block) and used for both
//      column-blocks - rev E reloaded the identical B fragment for each of the 2 column-blocks.
//   s  SUB-GROUP SYNC. Each sub-group's A tile and B slice are private, so every barrier becomes
//      group_barrier(sg) (on Intel a sub-group is one hardware thread, so this is a fence, not a
//      gateway barrier). The A tile is double-buffered, which removes the trailing write-after-read
//      barrier altogether.
//   f  FETCH AHEAD. The ring indices depend only on lane and K, so they are computed once per thread,
//      and each tile's 6 trellis dwords per lane are loaded PF_DIST tiles ahead, across expert
//      boundaries. The tile loop is flattened and unrolled by PF_DIST+1 so the in-flight register sets
//      are renamed statically - rotating them with moves would stall on the youngest load and quietly
//      reduce the distance to 1.
//   u  U32 UNPACK. The window is cut with one 32-bit funnel shift after selecting the word pair (rev E
//      evaluates two 64-bit variable shifts per weight and selects), the multiply is 16x32, and the
//      products for j and j^1 - adjacent dwords r, r+1 of the same column - go out as one 8-byte store.
//      Assumes K <= 4 (every window inside d0..d2 starts below bit 64); main() enforces it.
//
// Always on: SLM is sized from the operand sources. Rev E allocated the B staging buffer even under
// DPAS_B_GLOBAL, so its A/B source comparison still carried B staging's occupancy cap
// ((tps + 2) KiB per two-thread work-group).
//
// Everything is integer and the combine pass is rev E's, so y must be BIT-IDENTICAL to rev E for every
// switch combination. DPAS_CHECK=<file> compares against a rev E output; without it, CASE_DIR/y_ref.bin
// is used if it exists and has the right size.
//
// Switches (env):
//   DPAS_F=psfu|none|any subset   rev F changes above (default psfu)
//   DPAS_A_GLOBAL, DPAS_B_GLOBAL  operand sources, as in rev E (B global + 'p' = packed, 64-byte pitch)
//   DPAS_NO_MAD                   unpack + assembly only
//   DPAS_NO_UNPACK                matrix path only (stale A, no trellis loads)
//   both NO_ switches             fixed overhead: B staging, barriers, PART stores, combine
//   DPAS_CHECK=<file>             bitwise comparison of y against a reference file
//
// Ablation ladder:  for f in none p ps psf psfu; do DPAS_F=$f ./probe_dpas3 CASE 5 1 8; done
//
// Build: notes/b70/build.sh probe_dpas3    Run: ./probe_dpas3 CASE_DIR [reps] [rows] [ks]
// All 64 switch combinations are instantiated. Add -fsycl-device-code-split=per_kernel to the build if
// it isn't there already, so a run JIT-compiles only the variant it uses.
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
#include <type_traits>
#include <utility>
#include <vector>

namespace mx = sycl::ext::oneapi::experimental::matrix;

static constexpr int MM = 8;      // matrix rows = output columns per mad
static constexpr int MK = 32;     // matrix K for int8 = 8 weights x 4 bytes
#ifndef NTOK_OVERRIDE
#define NTOK_OVERRIDE 16
#endif
// Matrix columns = token slots. Every consumer of this is consistent (B tensor pitch, staging stride,
// PART stride and size, combine indexing), so -DNTOK_OVERRIDE=8|4 is a real compile-time narrowing of
// the operand, not a mask: it asks whether the compiler exploits a known-small row count, since the HW
// minimum N for int8 DPAS is 8 and below that the operation has to be emulated.
static constexpr int NTOK = NTOK_OVERRIDE;
static constexpr int SGSZ = 16;   // XMX needs 16-lane sub-groups
static constexpr int TILE_BYTES = 64;          // one trellis tile row: 16 weights x 4 bytes
static constexpr int A_TILE = 16 * TILE_BYTES; // one assembled A tile: 16 columns x 64 bytes = 1 KiB
static constexpr int PF_DIST = 2;              // 'f': tiles fetched ahead (6 GRF-dwords per tile in flight)

enum : unsigned
{
    F_AGLOB = 1u, F_BGLOB = 2u, F_PACKB = 4u, F_SGBAR = 8u, F_PREF = 16u, F_U32 = 32u,
    F_DUPP = 64u,          // 'd': write PART twice (shadow) - prices partial-sum traffic, same numerics
    F_STRUCT = 128u,       // 'x': experts in the grid, KS=1, so PART holds 2 partials per output not 2*KS
    F_COUNT = 256u
};

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

// The address space is a template argument of the load, so choosing SLM vs global needs a compile-time
// seam. The pointer's element type must MATCH the matrix data type (see LESSONS 31).
template <sycl::access::address_space SP, typename T, typename MAT>
static void ld_matrix(sycl::sub_group sg, MAT &mat, T *p, int ldm)
{
    auto pp = sycl::address_space_cast<SP, sycl::access::decorated::no>(p);
    mx::joint_matrix_load(sg, mat, pp, ldm);
}

// ---------------------------------------------------------------------------
// Unpack one ring position t of one trellis tile: 8 windows -> 8 weights -> the A tile.
// Mapping is rev C/E's: col = (t>>2) + 8*(j>>2), r = 2*(t&3) + (j&1) + 8*((j>>1)&1).
// ---------------------------------------------------------------------------
template <bool U32>
static inline void unpack_t(uint8_t *A, int t, uint32_t d0, uint32_t d1, uint32_t d2, uint32_t of, int K)
{
    const int q0 = t >> 2, a4 = t & 3;
    if constexpr (!U32)
    {
        const uint64_t V01 = ((uint64_t)d0 << 32) | d1;
        const uint64_t V12 = ((uint64_t)d1 << 32) | d2;
#pragma unroll
        for (int j = 0; j < 8; ++j)
        {
            const int s = (int)of + K * j;
            const uint32_t win = (uint32_t)((s >= 32 ? (V12 >> (48u - (uint32_t)(s - 32)))
                                                     : (V01 >> (48u - (uint32_t)s))) & 0xFFFFu);
            const uint32_t prod = win * 0x83DCD12Du;   // its 4 bytes ARE the weight
            const int col = q0 + 8 * (j >> 2);
            const int r = 2 * a4 + (j & 1) + ((j & 2) ? 8 : 0);
            *(uint32_t *)(A + col * TILE_BYTES + r * 4) = prod;
        }
    }
    else
    {
        uint8_t *base = A + q0 * TILE_BYTES + a4 * 8;   // (col q0, r 2*a4)
#pragma unroll
        for (int jp = 0; jp < 4; ++jp)
        {
            uint32_t p[2];
#pragma unroll
            for (int h = 0; h < 2; ++h)
            {
                // bits s..s+15 of the big-endian stream d0:d1:d2. Pick the word pair, then one funnel
                // shift; (lo >> 1) >> (31 - sh) is lo >> (32 - sh) without the undefined sh = 0 case.
                const uint32_t s = of + (uint32_t)(K * (2 * jp + h));
                const bool up = s >= 32u;
                const uint32_t hi = up ? d1 : d0, lo = up ? d2 : d1, sh = s & 31u;
                const uint32_t win = ((hi << sh) | ((lo >> 1) >> (31u - sh))) >> 16;
                p[h] = (uint32_t)(uint16_t)win * 0x83DCD12Du;
            }
            // j = 2jp, 2jp+1 -> col q0 + 8*(jp>>1), r = 2*a4 + 8*(jp&1) + {0, 1}: adjacent dwords
            *(sycl::vec<uint32_t, 2> *)(base + (jp >> 1) * 8 * TILE_BYTES + (jp & 1) * 32) =
                sycl::vec<uint32_t, 2>(p[0], p[1]);
        }
    }
}

// rev E's ring-window position for ring position t: word index, its two successors (with wrap), offset
struct RingIx
{
    uint32_t w0, w1, w2, of;
};
static inline RingIx ring_ix(int t, int K, uint32_t nw, int RB)
{
    const int o0 = K * (t * 8 + 1) - 16;
    const int o = o0 < 0 ? o0 + RB : (o0 >= RB ? o0 - RB : o0);
    const uint32_t wi = (uint32_t)o >> 5;
    return RingIx{wi, (wi + 1 == nw) ? 0u : wi + 1u, (wi + 2 >= nw) ? (wi + 2 - nw) : wi + 2u,
                  (uint32_t)o & 31u};
}

struct Launch
{
    sycl::queue *q = nullptr;
    const uint32_t *W = nullptr;   // trellis, [e][kt][nt][nw] dwords
    const int8_t *B = nullptr;     // replicated activation for the global path: row-major, or packed with 'p'
    const int8_t *X16 = nullptr;   // x8 padded to NTOK rows (rows >= R repeat R-1): source of packed staging
    int32_t *PART = nullptr;
    int32_t *PART2 = nullptr;    // 'd': equal-sized shadow region, written but never read
    uint8_t *ASC = nullptr;        // A-tile scratch for DPAS_A_GLOBAL: 2 tiles per sub-group
    Meta m;
    int KS = 8;
    bool skip_mad = false, skip_unpack = false;
};

// Per-sub-group SLM: the staged B slice (unless B is global) and the A tile(s) (unless A is global).
static void slm_layout(unsigned F, const Meta &m, int KS, size_t &slmB, size_t &slmA)
{
    const int per_sg = (m.tk / KS) / 2;
    slmB = (F & F_BGLOB) ? 0 : (size_t)per_sg * TILE_BYTES * NTOK;
    slmA = (F & F_AGLOB) ? 0 : (size_t)((F & F_SGBAR) ? 2 : 1) * A_TILE;
}

// ---------------------------------------------------------------------------
// sub-group = (nt, k-slice half); loops experts inside so B is staged once.
// PART layout [ks][sub][e][col][t] int32, identical to rev D/E so the combine pass is shared.
// ---------------------------------------------------------------------------
template <unsigned F>
static void submit(const Launch &L)
{
    constexpr bool AGLOB = F & F_AGLOB, BGLOB = F & F_BGLOB, PACKB = F & F_PACKB;
    constexpr bool SGBAR = F & F_SGBAR, PREF = F & F_PREF, U32 = F & F_U32, DUPP = F & F_DUPP,
                   STRUCT = F & F_STRUCT;
    constexpr int NBUF_A = SGBAR ? 2 : 1;
    constexpr int BLD = PACKB ? 4 * NTOK : NTOK;   // B stride in int8 elements

    using AMat = mx::joint_matrix<sycl::sub_group, uint8_t, mx::use::a, MM, MK, mx::layout::row_major>;
    using BMat = std::conditional_t<
        PACKB, mx::joint_matrix<sycl::sub_group, int8_t, mx::use::b, MK, NTOK, mx::layout::ext_intel_packed>,
        mx::joint_matrix<sycl::sub_group, int8_t, mx::use::b, MK, NTOK, mx::layout::row_major>>;
    using CMat = mx::joint_matrix<sycl::sub_group, int32_t, mx::use::accumulator, MM, NTOK>;

    const Meta m = L.m;
    const int KS = L.KS;
    const int E = m.E, tk = m.tk, tn = m.tn, n = m.n, k = m.k;
    const int K = (int)m.K;
    const int tps = tk / KS;                  // trellis tiles per k-slice
    const int per_sg = tps / 2;               // tiles per sub-group (main() enforces even halves)
    const size_t groups = (size_t)tn * (STRUCT ? m.E : KS);
    const uint32_t nw = (uint32_t)(8 * K);    // dwords per trellis tile
    const int RB = 256 * K;                   // ring bits per tile
    size_t slmB, slmA;
    slm_layout(F, m, KS, slmB, slmA);
    const size_t slmTotal = std::max<size_t>(2 * (slmB + slmA), 64);
    const bool skip_mad = L.skip_mad, skip_unpack = L.skip_unpack;
    const uint32_t *W = L.W;
    const int8_t *B = L.B;
    const int8_t *X16 = L.X16;
    int32_t *PART = L.PART;
    int32_t *PART2 = L.PART2;
    uint8_t *ASC = L.ASC;

    L.q->submit([&](sycl::handler &cgh)
    {
        sycl::local_accessor<uint8_t, 1> SLM(sycl::range<1>(slmTotal), cgh);
        cgh.parallel_for(sycl::nd_range<1>(sycl::range<1>(groups * SGSZ * 2), sycl::range<1>(SGSZ * 2)),
                         [=](sycl::nd_item<1> it) [[sycl::reqd_sub_group_size(SGSZ)]]
        {
            const sycl::sub_group sg = it.get_sub_group();
            const int l = (int)it.get_local_id(0);
            const int sub = l / SGSZ;                       // 0 or 1 within the work-group
            const int lane = l % SGSZ;                      // 0..15 inside the sub-group
            const int grp = (int)it.get_group(0);
            const int nt = grp % tn;
            // 'x' reuses the second grid dimension for the expert instead of the k-slice; KS is forced
            // to 1 host-side, so ks stays 0 and the two sub-groups still split the k-range in half, which
            // is exactly the two partials combine already sums.
            const int ks = STRUCT ? 0 : grp / tn;
            const int eg = STRUCT ? grp / tn : 0;
            const int kt0 = ks * tps + sub * per_sg;
            const int ntile = per_sg;

            // Everything this sub-group touches in SLM is its own, so with 's' a sub-group barrier
            // (an SLM fence) is enough; without it, rev E's work-group barrier.
            auto sync = [&]
            {
                if constexpr (SGBAR) sycl::group_barrier(sg);
                else                 sycl::group_barrier(it.get_group());
            };

            uint8_t *slm_sub =
                SLM.template get_multi_ptr<sycl::access::decorated::no>().get() + (size_t)sub * (slmB + slmA);
            uint8_t *sB = slm_sub;                          // staged B slice (unused with BGLOB)
            uint8_t *Abase;                                 // A tile(s): SLM, or a small L2-hot scratch
            if constexpr (AGLOB)
                Abase = ASC + ((size_t)grp * 2 + (size_t)sub) * (size_t)(2 * A_TILE);
            else
                Abase = slm_sub + slmB;

            // --- stage B once for the whole slice ---
            if constexpr (!BGLOB)
            {
                if constexpr (PACKB)
                {
                    // packed: dword (w, t) = x[t][w] in all 4 bytes; lane = token, 16 weights per load,
                    // and each weight's 16 lanes write one contiguous 64-byte row.
                    uint32_t *sB32 = reinterpret_cast<uint32_t *>(sB);
                    const int8_t *xr = X16 + (size_t)lane * k + (size_t)kt0 * 16;
                    for (int ti = 0; ti < ntile; ++ti)
                    {
                        const sycl::vec<uint32_t, 4> v =
                            *reinterpret_cast<const sycl::vec<uint32_t, 4> *>(xr + ti * 16);
#pragma unroll
                        for (int qd = 0; qd < 4; ++qd)
                        {
                            const uint32_t d = v[qd];
#pragma unroll
                            for (int b = 0; b < 4; ++b)
                                sB32[(ti * 16 + qd * 4 + b) * NTOK + lane] = ((d >> (8 * b)) & 0xFFu) * 0x01010101u;
                        }
                    }
                }
                else
                {
                    // rev E: B_local[byte_row][t] = x8[t][k], k = byte_row/4, byte by byte. Global B is
                    // byte-row indexed, so the source row is kt0*64 + brow (see rev E for the bug this
                    // avoids). Host B already repeats row R-1 in columns >= R, so no clamp is needed.
                    for (int idx = lane; idx < ntile * TILE_BYTES * NTOK; idx += SGSZ)
                        sB[idx] = (uint8_t)B[(size_t)(kt0 * TILE_BYTES) * NTOK + idx];
                }
            }
            sync();

            // --- the matrix unit for one assembled tile: 2 byte-blocks x 2 column-blocks ---
            auto load_b = [&](BMat &b, int ti, int kb)
            {
                if constexpr (BGLOB)
                    ld_matrix<sycl::access::address_space::global_space>(
                        sg, b, B + ((size_t)(kt0 + ti) * TILE_BYTES + kb * MK) * NTOK, BLD);
                else
                    ld_matrix<sycl::access::address_space::local_space>(
                        sg, b, reinterpret_cast<int8_t *>(sB) + ((size_t)ti * TILE_BYTES + kb * MK) * NTOK, BLD);
            };
            auto load_a = [&](AMat &a, uint8_t *A, int cb, int kb)
            {
                uint8_t *pa = A + cb * 8 * TILE_BYTES + kb * MK;
                if constexpr (AGLOB)
                    ld_matrix<sycl::access::address_space::global_space>(sg, a, pa, TILE_BYTES);
                else
                    ld_matrix<sycl::access::address_space::local_space>(sg, a, pa, TILE_BYTES);
            };
            auto mad_tile = [&](uint8_t *A, int ti, CMat &c0, CMat &c1)
            {
                if constexpr (PACKB)
                {
                    // one B fragment per byte-block, shared by both column-blocks
#pragma unroll
                    for (int kb = 0; kb < 2; ++kb)
                    {
                        BMat b;
                        load_b(b, ti, kb);
                        AMat a0, a1;
                        load_a(a0, A, 0, kb);
                        load_a(a1, A, 1, kb);
                        mx::joint_matrix_mad(sg, c0, a0, b, c0);
                        mx::joint_matrix_mad(sg, c1, a1, b, c1);
                    }
                }
                else
                {
                    // rev E: column-block outer, so the identical B fragment is loaded twice
#pragma unroll
                    for (int cb = 0; cb < 2; ++cb)
#pragma unroll
                        for (int kb = 0; kb < 2; ++kb)
                        {
                            AMat a;
                            BMat b;
                            load_a(a, A, cb, kb);
                            load_b(b, ti, kb);
                            if (cb == 0) mx::joint_matrix_mad(sg, c0, a, b, c0);
                            else         mx::joint_matrix_mad(sg, c1, a, b, c1);
                        }
                }
            };

            // int32 partials, one column-block per store
            auto store_part = [&](int e, CMat &c0, CMat &c1)
            {
                int32_t *P = PART + (((size_t)ks * 2 + sub) * E + e) * (size_t)n * NTOK + (size_t)nt * 16 * NTOK;
                auto pC0 = sycl::address_space_cast<sycl::access::address_space::global_space,
                                                    sycl::access::decorated::no>(P);
                auto pC1 = sycl::address_space_cast<sycl::access::address_space::global_space,
                                                    sycl::access::decorated::no>(P + 8 * NTOK);
                mx::joint_matrix_store(sg, c0, pC0, NTOK, mx::layout::row_major);
                mx::joint_matrix_store(sg, c1, pC1, NTOK, mx::layout::row_major);
                // 'd': identical partials written a second time to a shadow region. Nothing else changes -
                // same instructions in the tile loop, same combine, same y - so the gap over the plain
                // build is the marginal price of PART bytes plus their store instructions, which is what
                // decides whether item 5 deserves a restructuring rather than a tweak.
                if constexpr (DUPP)
                {
                    int32_t *P2 = PART2 + (((size_t)ks * 2 + sub) * E + e) * (size_t)n * NTOK
                                  + (size_t)nt * 16 * NTOK;
                    mx::joint_matrix_store(
                        sg, c0,
                        sycl::address_space_cast<sycl::access::address_space::global_space,
                                                 sycl::access::decorated::no>(P2),
                        NTOK, mx::layout::row_major);
                    mx::joint_matrix_store(
                        sg, c1,
                        sycl::address_space_cast<sycl::access::address_space::global_space,
                                                 sycl::access::decorated::no>(P2 + 8 * NTOK),
                        NTOK, mx::layout::row_major);
                }
            };

            auto tile_ptr = [&](int e, int ti) -> const uint32_t *
            {
                return W + ((size_t)e * tk + kt0 + ti) * tn * nw + (size_t)nt * nw;
            };

            if constexpr (!PREF)
            {
                // rev E structure: per-tile index math, loads consumed immediately
                int tc = 0;                                     // running tile count -> A buffer
                for (int e = eg; e < (STRUCT ? eg + 1 : E); ++e)
                {
                    CMat c0, c1;
                    mx::joint_matrix_fill(sg, c0, int32_t(0));
                    mx::joint_matrix_fill(sg, c1, int32_t(0));
                    for (int ti = 0; ti < ntile; ++ti, ++tc)
                    {
                        uint8_t *A = Abase + (NBUF_A == 2 ? (tc & 1) * A_TILE : 0);
                        if (!skip_unpack)
                        {
                            const uint32_t *dw = tile_ptr(e, ti);
#pragma unroll
                            for (int tt = 0; tt < 2; ++tt)
                            {
                                const int t = lane + tt * SGSZ;
                                const RingIx ri = ring_ix(t, K, nw, RB);
                                unpack_t<U32>(A, t, dw[ri.w0], dw[ri.w1], dw[ri.w2], ri.of, K);
                            }
                        }
                        sync();
                        if (skip_mad) continue;       // cost of unpack + assembly only
                        mad_tile(A, ti, c0, c1);
                        if constexpr (!SGBAR) sync(); // single A buffer: wait before overwriting it
                    }
                    store_part(e, c0, c1);
                }
            }
            else
            {
                // Lane-invariant ring indices, once per thread.
                uint32_t ix[6], ofs[2];
#pragma unroll
                for (int tt = 0; tt < 2; ++tt)
                {
                    const RingIx ri = ring_ix(lane + tt * SGSZ, K, nw, RB);
                    ix[3 * tt + 0] = ri.w0; ix[3 * tt + 1] = ri.w1; ix[3 * tt + 2] = ri.w2;
                    ofs[tt] = ri.of;
                }

                // Register ring of NSET tiles: tile g lives in set g % NSET. The loop below is unrolled
                // by NSET so every set index is a compile-time constant (no moves between sets).
                constexpr int NSET = PF_DIST + 1;
                uint32_t pf[NSET][6];
                int fe = 0, fti = 0;                            // next tile to fetch
                auto fetch = [&](uint32_t *d)
                {
                    if (fe >= E) return;
                    const uint32_t *p = tile_ptr(fe, fti);
#pragma unroll
                    for (int i = 0; i < 6; ++i) d[i] = p[ix[i]];
                    if (++fti == ntile) { fti = 0; ++fe; }
                };
                if (!skip_unpack)
                {
#pragma unroll
                    for (int d = 0; d < PF_DIST; ++d) fetch(pf[d]);
                }

                const int total = E * ntile;
                int ce = 0, cti = 0;                            // current tile
                CMat c0, c1;
                for (int g0 = 0; g0 < total; g0 += NSET)
                {
#pragma unroll
                    for (int u = 0; u < NSET; ++u)
                    {
                        const int g = g0 + u;
                        if (g >= total) break;
                        if (cti == 0)
                        {
                            mx::joint_matrix_fill(sg, c0, int32_t(0));
                            mx::joint_matrix_fill(sg, c1, int32_t(0));
                        }
                        uint8_t *A = Abase + (NBUF_A == 2 ? (g & 1) * A_TILE : 0);
                        if (!skip_unpack)
                        {
                            fetch(pf[(u + PF_DIST) % NSET]);   // the set the previous tile just used
                            unpack_t<U32>(A, lane, pf[u][0], pf[u][1], pf[u][2], ofs[0], K);
                            unpack_t<U32>(A, lane + SGSZ, pf[u][3], pf[u][4], pf[u][5], ofs[1], K);
                        }
                        sync();
                        if (!skip_mad)
                        {
                            mad_tile(A, cti, c0, c1);
                            if constexpr (!SGBAR) sync();
                        }
                        if (++cti == ntile)
                        {
                            store_part(ce, c0, c1);
                            cti = 0;
                            ++ce;
                        }
                    }
                }
            }
        });
    });
}

template <size_t... I>
static void submit_variant(unsigned f, const Launch &L, std::index_sequence<I...>)
{
    const bool hit = ((f == I ? (submit<(unsigned)I>(L), true) : false) || ...);
    if (!hit) { fprintf(stderr, "no variant for flags %u\n", f); exit(2); }
}

static void combine(sycl::queue &q, const int32_t *PART, const float *Q, const int32_t *SX8,
                    float *Y, const Meta &m, int KS)
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
            s += PART[((size_t)p * m.E + e) * m.n * NTOK + (size_t)col * NTOK + row];
        Y[i] = m.kinv * Q[row] * ((float)s - 510.0f * (float)SX8[row]);
    });
}

static unsigned parse_flags()
{
    const char *s = getenv("DPAS_F");
    if (!s) s = "psfu";
    if (!strcmp(s, "none") || !strcmp(s, "-")) s = "";
    unsigned f = 0;
    for (; *s; ++s)
        switch (*s)
        {
        case 'p': f |= F_PACKB; break;
        case 's': f |= F_SGBAR; break;
        case 'f': f |= F_PREF; break;
        case 'u': f |= F_U32; break;
        case 'd': f |= F_DUPP; break;
        case 'x': f |= F_STRUCT; break;
        case ',': case ' ': case '+': break;
        default: fprintf(stderr, "DPAS_F: unknown switch '%c' (use any of p s f u, or none)\n", *s); exit(2);
        }
    if (getenv("DPAS_A_GLOBAL")) f |= F_AGLOB;
    if (getenv("DPAS_B_GLOBAL")) f |= F_BGLOB;
    return f;
}

static std::string flag_str(unsigned f)
{
    std::string s;
    if (f & F_PACKB) s += 'p';
    if (f & F_SGBAR) s += 's';
    if (f & F_PREF) s += 'f';
    if (f & F_U32) s += 'u';
    if (f & F_DUPP) s += 'd';   // without this the label and the output filename silently lie about 'd'
    if (f & F_STRUCT) s += 'x';
    return s.empty() ? "none" : s;
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
    const int KS_req = argc > 4 ? atoi(argv[4]) : 8;
    Meta m = load_meta(dir);
    if (rows_arg > 0) m.R = rows_arg;
    if (m.R < 1 || m.R > NTOK) { fprintf(stderr, "rows %d outside 1..%d\n", m.R, NTOK); return 2; }
    const unsigned flags = parse_flags();
    if (flags & F_STRUCT)
    {
        // 'x' makes the expert dimension the extra grid dimension, so the k-split collapses to 1. Two
        // requirements fall out: B must come from global (staging per_sg = tk/2 tiles of B would ask
        // ~80 KiB per sub-group, over this device's 128 KiB SLM budget), and 'f' is out because its
        // flattened loop owns the expert counter.
        if (!(flags & F_BGLOB))
        { fprintf(stderr, "'x' needs DPAS_B_GLOBAL=1 (per-expert B staging exceeds SLM)\n"); return 2; }
        if (flags & F_PREF) { fprintf(stderr, "'x' and 'f' are mutually exclusive\n"); return 2; }
    }
    const int KS = (flags & F_STRUCT) ? 1 : KS_req;
    if (KS < 1 || m.tk % KS || (m.tk / KS) % 2) { fprintf(stderr, "tk must split into even halves (KS %d, tk %d)\n", KS, m.tk); return 2; }
    const int K = (int)m.K;
    if ((flags & F_U32) && (K < 1 || K > 4))
    {
        fprintf(stderr, "'u' assumes K <= 4 (K is %d); run without it (e.g. DPAS_F=psf)\n", K);
        return 2;
    }

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

    // Activation tensors. Rows >= R repeat row R-1 (in bounds, and those columns are never read back).
    //   X16[t][k]                       x8 padded to NTOK rows - source of the packed SLM staging
    //   row-major B[k*4 + b][t]         = x8[t][k]               (rev E)
    //   packed    B[k][t][b]            = x8[t][k], b = 0..3     ('p': 64-byte rows)
    const int8_t *x8 = (const int8_t *)xbuf.data();
    std::vector<int8_t> hX((size_t)NTOK * m.k);
    for (int t = 0; t < NTOK; ++t)
        memcpy(&hX[(size_t)t * m.k], x8 + (size_t)(t < m.R ? t : m.R - 1) * m.k, (size_t)m.k);
    std::vector<int8_t> hB((size_t)4 * m.k * NTOK);
    for (int kw = 0; kw < m.k; ++kw)
        for (int t = 0; t < NTOK; ++t)
            for (int b = 0; b < 4; ++b)
            {
                const size_t at = (flags & F_PACKB) ? ((size_t)kw * NTOK + t) * 4 + b
                                                    : ((size_t)kw * 4 + b) * NTOK + t;
                hB[at] = hX[(size_t)t * m.k + kw];
            }

    size_t slmB, slmA;
    slm_layout(flags, m, KS, slmB, slmA);
    const double trellis_mib = wbuf.size() / 1048576.0;
    printf("case %s: E %d R %d k %d n %d K %d  trellis %.2f MiB  KS %d  work-groups %d  sub-groups %d\n",
           dir.c_str(), m.E, m.R, m.k, m.n, K, trellis_mib, KS,
           m.tn * ((flags & F_STRUCT) ? m.E : KS), m.tn * ((flags & F_STRUCT) ? m.E : KS) * 2);
    printf("rev F switches: %s   A from %s, B from %s   SLM per work-group %.1f KiB\n",
           flag_str(flags).c_str(), (flags & F_AGLOB) ? "global scratch" : "SLM",
           (flags & F_BGLOB) ? "global tensor" : "SLM", 2.0 * (slmB + slmA) / 1024.0);

    sycl::device dev{sycl::gpu_selector_v};
    sycl::context ctx{dev};
    sycl::queue q{ctx, dev, sycl::property::queue::in_order{}};

    uint32_t *W = (uint32_t *)sycl::malloc_device(wbuf.size(), q);
    int8_t *B = (int8_t *)sycl::malloc_device(hB.size(), q);
    int8_t *X16 = (int8_t *)sycl::malloc_device(hX.size(), q);
    float *Q = (float *)sycl::malloc_device(qbuf.size(), q);
    int32_t *SX8 = (int32_t *)sycl::malloc_device(sbuf.size(), q);
    float *Y = (float *)sycl::malloc_device((size_t)m.E * m.R * m.n * 4, q);
    const size_t part_n = (size_t)KS * 2 * m.E * m.n * NTOK;
    int32_t *PART = (int32_t *)sycl::malloc_device((flags & F_DUPP ? 2 : 1) * part_n * 4, q);
    q.memcpy(W, wbuf.data(), wbuf.size());
    q.memcpy(B, hB.data(), hB.size());
    q.memcpy(X16, hX.data(), hX.size());
    q.memcpy(Q, qbuf.data(), qbuf.size());
    q.memcpy(SX8, sbuf.data(), sbuf.size());
    q.wait();

    // A-tile scratch for DPAS_A_GLOBAL: two 1 KiB tiles per sub-group, rewritten every tile (L2-hot).
    uint8_t *ASC = nullptr;
    if (flags & F_AGLOB)
        ASC = (uint8_t *)sycl::malloc_device(
                  (size_t)m.tn * ((flags & F_STRUCT) ? m.E : KS) * 2 * 2 * A_TILE, q);

    Launch L;
    L.q = &q; L.W = W; L.B = B; L.X16 = X16; L.PART = PART; L.ASC = ASC; L.m = m; L.KS = KS;
    L.PART2 = PART + ((flags & F_DUPP) ? part_n : 0);
    L.skip_mad = getenv("DPAS_NO_MAD") != nullptr;
    L.skip_unpack = getenv("DPAS_NO_UNPACK") != nullptr;

    auto dispatch = [&]
    {
        submit_variant(flags, L, std::make_index_sequence<F_COUNT>{});
        combine(q, PART, Q, SX8, Y, m, KS);
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
    printf("revF ks %d rows %d: %8.1f us  %7.1f G-w/s  %6.2f slots/weight  %6.1f GB/s(trellis)"
           "   [burst; single-launch %7.1f us = %7.1f G-w/s, %.2f slots/w]  [%s %s%s]\n",
           KS, m.R, tpbest * 1e6, weights / tpbest / 1e9, slots_per_weight, wbuf.size() / tpbest / 1e9,
           best * 1e6, weights / best / 1e9, 1.43e12 * best / weights, flag_str(flags).c_str(),
           (flags & F_AGLOB) ? "g" : "s", (flags & F_BGLOB) ? "g" : "s");

    char outpath[512];
    snprintf(outpath, sizeof outpath, "%s/y_dev_revf_ks%d_r%d_%s%s_%s.bin", dir.c_str(), KS, m.R,
             (flags & F_AGLOB) ? "g" : "s", (flags & F_BGLOB) ? "g" : "s", flag_str(flags).c_str());
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

    sycl::free(W, q); sycl::free(B, q); sycl::free(X16, q); sycl::free(Q, q); sycl::free(SX8, q);
    sycl::free(Y, q); sycl::free(PART, q);
    if (ASC) sycl::free(ASC, q);
    return 0;
}
