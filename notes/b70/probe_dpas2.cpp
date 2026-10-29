// -----------------------------------------------------------------------------
// probe_dpas2.cpp - E24 step 2 (rev E): the DPAS path fed by A ASSEMBLED FROM TRELLIS BYTES.
//
// Step 1 (probe_dpas.cpp) made operand assembly free by reading a byte-expanded A from DRAM, and
// proved two things: the integer matrix path is bit-exact with rev B, and its rows curve is flat
// (~2.2 us/MiB marginal, 484 GB/s, plus a ~12 us floor). Its loser status at decode footprints came
// entirely from A's 4 bytes/weight vs the trellis's K/8 = 0.375. So the only question left is the one
// llm-scaler warns about: "assembling it with strided register moves cost more than the DPAS itself
// saved."
//
// REV E ANSWERS THAT BY CONSTRUCTION. Each sub-group:
//   * stages B (the activation replicated 4x along K) into SLM once per k-slice, then reuses it across
//     every expert - the activation-reload trap, avoided;
//   * per trellis tile, the 16 lanes unpack the ring (the SAME window math rev C validated bit-exactly)
//     and write each window's 4 product bytes as ONE u32 store straight into the SLM A tile;
//   * four joint_matrix_load/mad pairs consume that tile (2 column-blocks x 2 byte-blocks).
// DRAM traffic is therefore the trellis bytes only. The cost that replaces them is unpack + assembly,
// which is exactly what this probe prices.
//
// Reported metric, in priority order:
//   1. G-weights/s and the implied issue slots per weight (1.43e12 slots/s budget), vs rev C's fitted
//      5.8 + 1.15*rows and vs rev D's ~5-slot floor with free assembly;
//   2. bit-exactness against rev B / y_ref (integers, so order-independence is expected but must not be
//      assumed);
//   3. rows and expert sweeps, since flatness in rows is the whole point.
//
// Build: notes/b70/build.sh probe_dpas2    Run: ./probe_dpas2 CASE_DIR [reps] [rows] [ks]
// Needs the trellis weights (weights.bin), not abytes.bin - it unpacks on the fly.
// -----------------------------------------------------------------------------
#include <sycl/sycl.hpp>
#include <sycl/ext/oneapi/matrix/matrix.hpp>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <string>
#include <vector>

namespace mx = sycl::ext::oneapi::experimental::matrix;

static constexpr int MM = 8;      // matrix rows = output columns per mad
static constexpr int MK = 32;     // matrix K for int8 = 8 weights x 4 bytes
static constexpr int NTOK = 16;   // matrix columns = token slots
static constexpr int SGSZ = 16;   // XMX needs 16-lane sub-groups
static constexpr int TILE_BYTES = 64;   // one trellis tile: 16 weights x 4 bytes

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

// ---------------------------------------------------------------------------
// sub-group = (nt, k-slice half); loops experts inside so B is staged once.
// PART layout [ks][sub][e][col][t] int32, identical to rev D so the combine pass is shared.
// ---------------------------------------------------------------------------
// The address space is a template argument of the load, so choosing SLM vs global at run time needs a
// compile-time seam - these thin wrappers are it. The pointer's element type must also MATCH the matrix
// data type (b is int8_t because activations are signed; see LESSONS 31).
template <sycl::access::address_space SP, typename T, typename MAT>
static void ld_matrix(sycl::sub_group sg, MAT &mat, T *p, int ldm)
{
    auto pp = sycl::address_space_cast<SP, sycl::access::decorated::no>(p);
    mx::joint_matrix_load(sg, mat, pp, ldm);
}

// AGLOB: A tile in global (L2-resident) scratch instead of SLM. BGLOB: read B straight from the
// global replicated tensor instead of staging it. rev D fed the matrix unit from global space and cost
// ~1 slot/weight; rev E from SLM cost ~24 - these two switches say which of those is load lowering.
template <bool AGLOB, bool BGLOB>
static void submit(sycl::queue &q, const uint16_t *W, const int8_t *B, int32_t *PART,
                   uint8_t *ASC, const Meta &m, int KS)
{
    const int E = m.E, tk = m.tk, tn = m.tn, n = m.n;
    const int K = (int)m.K;
    const int tps = tk / KS;                  // trellis tiles per k-slice
    const int per_sg = (tps + 1) / 2;         // tiles per sub-group (sub 0 may take one more)
    const size_t groups = (size_t)tn * KS;
    const uint32_t nw = (uint32_t)(8 * K);    // dwords per trellis tile
    const int RB = 256 * K;                   // ring bits per tile
    const size_t slmB = (size_t)per_sg * TILE_BYTES * NTOK;      // staged B rows for this slice
    const size_t slmTotal = slmB * 2 + 2 * (size_t)16 * TILE_BYTES;
    const bool SKIP_MAD = getenv("DPAS_NO_MAD") != nullptr;      // unpack+assemble only
    const bool SKIP_UNPACK = getenv("DPAS_NO_UNPACK") != nullptr; // matrix path only (stale A)

    q.submit([&](sycl::handler &cgh)
    {
        sycl::local_accessor<uint8_t, 1> SLM(slmTotal, cgh);
        cgh.parallel_for(sycl::nd_range<1>(sycl::range<1>(groups * SGSZ * 2), sycl::range<1>(SGSZ * 2)),
                         [=](sycl::nd_item<1> it) [[sycl::reqd_sub_group_size(SGSZ)]]
        {
            const sycl::sub_group sg = it.get_sub_group();
            const int l = (int)it.get_local_id(0);
            const int sub = l / SGSZ;                       // 0 or 1 within the work-group
            const int lane = l % SGSZ;                      // 0..15 inside the sub-group
            int g = (int)it.get_group(0);
            const int nt = g % tn; g /= tn;
            const int ks = g;
            const int kt0 = ks * tps + (sub ? tps / 2 : 0);
            const int ntile = sub ? tps - tps / 2 : tps / 2;

            uint8_t *slmB_ = SLM.get_pointer().get() + (size_t)sub * slmB;
            // A tile lives either in SLM or in a small global scratch (one region per sub-group,
            // rewritten every tile so it stays L2-hot and costs no DRAM traffic).
            uint8_t *slmA = AGLOB
                ? ASC + (((size_t)it.get_group(0) * 2) + (size_t)sub) * (16 * TILE_BYTES)
                : SLM.get_pointer().get() + 2 * slmB + (size_t)sub * (16 * TILE_BYTES);

            // --- stage B once for the whole slice: B_local[byte_row][t] = x8[t][k], k = byte_row/4 ---
            // Tokens past R are clamped onto the last valid row (in bounds, branch-free, and the
            // garbage columns are simply never read back).
            const int bstage_end = BGLOB ? 0 : ntile * TILE_BYTES * NTOK;
            for (int idx = lane; idx < bstage_end; idx += SGSZ)
            {
                const int brow = idx / NTOK;            // byte row within the slice
                const int t = idx % NTOK;
                // brow is slice-LOCAL. Global B is BYTE-indexed (four consecutive rows carry one
                // weight, all holding x[t][k]), so the row to read is the byte row kt0*64 + brow -
                // indexing it by weight instead silently pairs each weight with x[k/4], which is a
                // wrong-answer bug that no timing run would reveal.
                const int tclamp = t < (int)m.R ? t : (int)m.R - 1;
                slmB_[idx] = B[(size_t)(kt0 * TILE_BYTES + brow) * NTOK + tclamp];
            }
            sycl::group_barrier(it.get_group());

            const uint32_t *W32 = (const uint32_t *)W;

            for (int e = 0; e < E; ++e)
            {
                mx::joint_matrix<sycl::sub_group, int32_t, mx::use::accumulator, MM, NTOK>
                    c0, c1;                                    // one per column-block
                mx::joint_matrix_fill(sg, c0, int32_t(0));
                mx::joint_matrix_fill(sg, c1, int32_t(0));

                for (int ti = 0; ti < ntile; ++ti)
                {
                    const int kt = kt0 + ti;
                    const uint32_t *dw = W32 + ((size_t)e * tk + kt) * tn * nw + (size_t)nt * nw;

                    // --- unpack: lane owns ring positions t = lane and t = lane+16, each covering the
                    // 8 positions j = 0..7 of one t, i.e. 16 of the tile's 256 (col, weight) pairs.
                    // Same window math as rev C/rev B (validated bit-exact against the reference).
                    for (int tt = 0; SKIP_UNPACK ? false : (tt < 2); ++tt)
                    {
                        const int t = lane + tt * SGSZ;
                        const int q0 = t >> 2, a4 = t & 3;
                        const int o0 = K * (t * 8 + 1) - 16;
                        const int o = o0 < 0 ? o0 + RB : (o0 >= RB ? o0 - RB : o0);
                        const uint32_t wi = (uint32_t)o >> 5, of = (uint32_t)o & 31u;
                        const uint32_t d0 = dw[wi];
                        const uint32_t d1 = dw[(wi + 1 == nw) ? 0u : wi + 1u];
                        const uint32_t d2 = dw[(wi + 2 >= nw) ? (wi + 2 - nw) : wi + 2u];
                        const uint64_t V01 = ((uint64_t)d0 << 32) | d1;
                        const uint64_t V12 = ((uint64_t)d1 << 32) | d2;
                        for (int j = 0; j < 8; ++j)
                        {
                            const int s = (int)of + K * j;
                            const uint32_t win = (uint32_t)((s >= 32 ? (V12 >> (48u - (uint32_t)(s - 32)))
                                                                     : (V01 >> (48u - (uint32_t)s))) & 0xFFFFu);
                            const uint32_t prod = win * 0x83DCD12Du;   // its 4 bytes ARE the weight
                            const int col = q0 + 8 * (j >> 2);
                            const int r = 2 * a4 + (j & 1) + ((j & 2) ? 8 : 0);
                            *(uint32_t *)(slmA + col * TILE_BYTES + r * 4) = prod;
                        }
                    }
                    sycl::group_barrier(it.get_group());
                    if (SKIP_MAD) continue;      // cost of unpack + SLM assembly only

                    // --- feed the matrix unit: 2 column-blocks x 2 byte-blocks per tile ---
                    for (int cb = 0; cb < 2; ++cb)
                    {
                        uint8_t *pa = slmA + cb * 8 * TILE_BYTES;
                        for (int kb = 0; kb < 2; ++kb)
                        {
                            mx::joint_matrix<sycl::sub_group, uint8_t, mx::use::a, MM, MK,
                                             mx::layout::row_major> a;
                            mx::joint_matrix<sycl::sub_group, int8_t, mx::use::b, MK, NTOK,
                                             mx::layout::row_major> b;
                            if constexpr (AGLOB)
                                ld_matrix<sycl::access::address_space::global_space>(
                                    sg, a, pa + kb * MK, TILE_BYTES);
                            else
                                ld_matrix<sycl::access::address_space::local_space>(
                                    sg, a, pa + kb * MK, TILE_BYTES);
                            if constexpr (BGLOB)
                                ld_matrix<sycl::access::address_space::global_space>(
                                    sg, b, B + ((size_t)(kt0 + ti) * TILE_BYTES + kb * MK) * NTOK,
                                    NTOK);
                            else
                                ld_matrix<sycl::access::address_space::local_space>(
                                    sg, b,
                                    reinterpret_cast<int8_t *>(slmB_) +
                                        ((size_t)ti * TILE_BYTES + kb * MK) * NTOK,
                                    NTOK);
                            if (cb == 0) mx::joint_matrix_mad(sg, c0, a, b, c0);
                            else         mx::joint_matrix_mad(sg, c1, a, b, c1);
                        }
                    }
                    sycl::group_barrier(it.get_group());
                }

                // int32 partials, one column-block per store
                int32_t *P = PART + (((size_t)ks * 2 + sub) * E + e) * (size_t)n * NTOK
                             + (size_t)nt * 16 * NTOK;
                auto pC0 = sycl::address_space_cast<sycl::access::address_space::global_space,
                                                    sycl::access::decorated::no>(P);
                auto pC1 = sycl::address_space_cast<sycl::access::address_space::global_space,
                                                    sycl::access::decorated::no>(P + 8 * NTOK);
                mx::joint_matrix_store(sg, c0, pC0, NTOK, mx::layout::row_major);
                mx::joint_matrix_store(sg, c1, pC1, NTOK, mx::layout::row_major);
            }
        });
    });
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

int main(int argc, char **argv)
{
    if (argc < 2) { fprintf(stderr, "usage: %s CASE_DIR [reps] [rows] [ks]\n", argv[0]); return 2; }
    const std::string dir = argv[1];
    const int reps = argc > 2 ? atoi(argv[2]) : 5;
    const int rows_arg = argc > 3 ? atoi(argv[3]) : 0;
    const int KS = argc > 4 ? atoi(argv[4]) : 8;
    Meta m = load_meta(dir);
    if (rows_arg > 0) m.R = rows_arg;
    if (m.R > NTOK) { fprintf(stderr, "rows %d > NTOK %d\n", m.R, NTOK); return 2; }
    if (m.tk % KS || (m.tk / KS) % 2) { fprintf(stderr, "tk must split into even halves (KS %d, tk %d)\n", KS, m.tk); return 2; }

    auto wbuf = slurp(dir + "/weights.bin");
    auto xbuf = slurp(dir + "/x8.bin");
    auto qbuf = slurp(dir + "/q.bin");
    auto sbuf = slurp(dir + "/sx8.bin");
    const int kbytes = 4 * m.k;

    // B_global[k*4 + b][t] = x8[t][k]; built once per launch, tiny (4k x 16 bytes), L2-resident.
    std::vector<int8_t> hB((size_t)kbytes * NTOK);
    const int8_t *x8 = (const int8_t *)xbuf.data();
    for (int kb = 0; kb < kbytes; ++kb)
        for (int t = 0; t < NTOK; ++t)
        {
            const int row = t < m.R ? t : m.R - 1;
            hB[(size_t)kb * NTOK + t] = x8[(size_t)row * m.k + kb / 4];
        }

    const double trellis_mib = wbuf.size() / 1048576.0;
    printf("case %s: E %d R %d k %d n %d K %g  trellis %.2f MiB  KS %d  work-groups %d  sub-groups %d\n",
           dir.c_str(), m.E, m.R, m.k, m.n, m.K, trellis_mib, KS, m.tn * KS, m.tn * KS * 2);

    sycl::device dev{sycl::gpu_selector_v};
    sycl::context ctx{dev};
    sycl::queue q{ctx, dev, sycl::property::queue::in_order{}};

    uint16_t *W = (uint16_t *)sycl::malloc_device(wbuf.size(), q);
    int8_t *B = (int8_t *)sycl::malloc_device(hB.size(), q);
    float *Q = (float *)sycl::malloc_device(qbuf.size(), q);
    int32_t *SX8 = (int32_t *)sycl::malloc_device(sbuf.size(), q);
    float *Y = (float *)sycl::malloc_device((size_t)m.E * m.R * m.n * 4, q);
    int32_t *PART = (int32_t *)sycl::malloc_device((size_t)KS * 2 * m.E * m.n * NTOK * 4, q);
    q.memcpy(W, wbuf.data(), wbuf.size());
    q.memcpy(B, hB.data(), hB.size());
    q.memcpy(Q, qbuf.data(), qbuf.size());
    q.memcpy(SX8, sbuf.data(), sbuf.size());
    q.wait();

    // Small global scratch for the A tile: one 1 KB region per sub-group, rewritten every tile, so it
    // stays L2-resident and should cost no DRAM traffic at all.
    const bool aglob = getenv("DPAS_A_GLOBAL") != nullptr;
    const bool bglob = getenv("DPAS_B_GLOBAL") != nullptr;
    const size_t asc_bytes = (size_t)m.tn * KS * 2 * (16 * TILE_BYTES);
    uint8_t *ASC = aglob ? (uint8_t *)sycl::malloc_device(asc_bytes, q) : nullptr;
    printf("operand sourcing: A from %s, B from %s\n", aglob ? "global scratch" : "SLM",
           bglob ? "global tensor" : "SLM");

    auto dispatch = [&]
    {
        if (aglob && bglob)   submit<true, true>(q, W, B, PART, ASC, m, KS);
        else if (aglob)       submit<true, false>(q, W, B, PART, ASC, m, KS);
        else if (bglob)       submit<false, true>(q, W, B, PART, ASC, m, KS);
        else                  submit<false, false>(q, W, B, PART, ASC, m, KS);
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
    printf("revE ks %d rows %d: %8.1f us  %7.1f G-w/s  %6.2f slots/weight  %6.1f GB/s(trellis)"
           "   [burst; single-launch %7.1f us = %7.1f G-w/s, %.2f slots/w]\n",
           KS, m.R, tpbest * 1e6, weights / tpbest / 1e9, slots_per_weight, wbuf.size() / tpbest / 1e9,
           best * 1e6, weights / best / 1e9, 1.43e12 * best / weights);

    char outpath[512];
    snprintf(outpath, sizeof outpath, "%s/y_dev_reve_ks%d_r%d_%s%s.bin", dir.c_str(), KS, m.R,
             aglob ? "g" : "s", bglob ? "g" : "s");
    FILE *fo = fopen(outpath, "wb");
    fwrite(y.data(), 4, y.size(), fo);
    fclose(fo);
    printf("wrote %s\n", outpath);

    sycl::free(W, q); sycl::free(B, q); sycl::free(Q, q); sycl::free(SX8, q);
    sycl::free(Y, q); sycl::free(PART, q);
    if (ASC) sycl::free(ASC, q);
    return 0;
}