// -----------------------------------------------------------------------------
// probe_dpas.cpp - E24 step 1: does the XMX integer matrix path actually remove the per-row
// instruction slot that makes rev C cost ~1.15 issue slots per (weight, extra token)?
//
// The trick under test (b70-kernels.md §2c item 13b): mul1's value is bytesum(window * 0x83DCD12D),
// a 10-bit number that will not fit int8. But the four BYTES of the product do. Feed the matrix unit
// A = those four bytes as four K-steps, and B = the activation replicated 4x along K, and one integer
// DPAS computes sum_bytes p_j * x = sum_k bytesum(prod_k) * x_k -- exactly, in int32, no float, no
// bias-term rearrangement, and the epilogue stays bit-identical to rev B/rev C.
//
// THIS STEP MAKES OPERAND ASSEMBLY FREE on purpose: A comes from abytes.bin, produced by the same
// authoritative unpacker that produces y_ref (dump_gemv_case.py --with-abytes), not by a second C++
// unpacker. That isolates the question worth answering first -- does the matrix math scale flat with
// rows? -- from the expensive engineering question (can a real kernel assemble A in registers without
// paying more than it saves, which is exactly what llm-scaler's "strided register moves cost more than
// the DPAS itself saved" warning is about). If THIS variant does not scale flat, the ESIMD rewrite is
// pointless and we stop here.
//
// The price of the free lunch is DRAM: A is 4 bytes per weight against the trellis's K/8, i.e. 10.7x
// more bytes at K=3. So GB/s here is NOT comparable to rev C's; read G-weights/s and its SHAPE across
// rows, and read the absolute number as "the ceiling a materialized-byte design would hit", which is
// itself a result (it says a shipping DPAS kernel must assemble A on the fly, never store it).
//
// Shape proven on this card by doc/b70/b70-bench: int8 A/B -> int32 C, M=8, K=32, N=16, sub-groups of
// 16 ("XMX needs sub-groups of 16 work-items"), at 366.92 TOPS = 100% of Intel's 367.
//
// Build: notes/b70/build.sh probe_dpas    Run: ./probe_dpas CASE_DIR [reps] [rows] [ks]
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

static constexpr int MM = 8;      // DPAS rows: output columns per matrix op
static constexpr int MK = 32;     // DPAS K for int8 (bytes)
static constexpr int NTOK = 16;   // DPAS columns: token slots in one tile
static constexpr int SGSZ = 16;   // XMX needs 16-lane sub-groups

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
// one sub-group = (e, column-block, k-slice, half of that slice)
// PART layout: [ks][sg][e][col][t]  int32; every slot written exactly once, and the sums are integer,
// so the combine pass is order-independent and the result must match rev B bit for bit.
// ---------------------------------------------------------------------------
static void submit(sycl::queue &q, const uint8_t *A, const int8_t *B, int32_t *PART,
                   const Meta &m, int KS)
{
    const int n = m.n, E = m.E;
    const int kbytes = 4 * m.k;                  // A's K extent: four bytes per weight
    const int nc = n / MM;                       // column blocks
    const int slice = kbytes / KS;               // bytes per k-slice
    const int per_sg = slice / 2;                // two sub-groups per work-group
    const size_t groups = (size_t)E * nc * KS;

    q.submit([&](sycl::handler &cgh)
    {
        cgh.parallel_for(sycl::nd_range<1>(sycl::range<1>(groups * SGSZ * 2), sycl::range<1>(SGSZ * 2)),
                         [=](sycl::nd_item<1> it) [[sycl::reqd_sub_group_size(SGSZ)]]
        {
            const sycl::sub_group sg = it.get_sub_group();
            const int gid = (int)(it.get_group(0));
            const int sub = (int)sg.get_group_id()[0];          // 0 or 1
            // column blocks innermost: adjacent sub-groups touch adjacent columns of the same expert
            int g = gid;
            const int cb = g % nc; g /= nc;
            const int e = g % E;  g /= E;
            const int ks = g;

            const uint8_t *Ap = A + ((size_t)e * n + (size_t)cb * MM) * kbytes + (size_t)ks * slice
                              + (size_t)sub * per_sg;
            const int8_t *Bp = B + (size_t)(ks * slice + sub * per_sg) * NTOK;

            auto pA = sycl::address_space_cast<sycl::access::address_space::global_space,
                                               sycl::access::decorated::no>(Ap);
            auto pB = sycl::address_space_cast<sycl::access::address_space::global_space,
                                               sycl::access::decorated::no>(Bp);

            mx::joint_matrix<sycl::sub_group, uint8_t, mx::use::a, MM, MK,
                             mx::layout::row_major> a;
            // B MUST be signed. Declaring it uint8_t compiles, runs fast, and turns every negative
            // activation into 128..255, so the accumulator picks up a large same-sign bias instead of
            // cancelling - the sum jumps to ~1.6e8 (the all-positive bound) instead of ~5e5. dpas.hpp
            // allows the mix explicitly: C in ud/d with A, B independently from ub, b, u4, s4, u2, s2.
            mx::joint_matrix<sycl::sub_group, int8_t, mx::use::b, MK, NTOK,
                             mx::layout::row_major> b;
            mx::joint_matrix<sycl::sub_group, int32_t, mx::use::accumulator, MM, NTOK> c;
            mx::joint_matrix_fill(sg, c, int32_t(0));

            for (int kb = 0; kb < per_sg; kb += MK)
            {
                mx::joint_matrix_load(sg, a, pA + kb, kbytes);     // A[col][kbytes] row-major
                mx::joint_matrix_load(sg, b, pB + (size_t)kb * NTOK, NTOK);
                mx::joint_matrix_mad(sg, c, a, b, c);
            }

            int32_t *P = PART + (((size_t)ks * 2 + sub) * E + e) * (size_t)n * NTOK
                         + (size_t)cb * MM * NTOK;
            auto pC = sycl::address_space_cast<sycl::access::address_space::global_space,
                                              sycl::access::decorated::no>(P);
            mx::joint_matrix_store(sg, c, pC, NTOK, mx::layout::row_major);
        });
    });
}

// sum the KS*2 integer partials and apply the unchanged mul1 epilogue
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
        // PART is [p][e][col][t] with the token fastest (that is how joint_matrix_store lays C out),
        // which is NOT the [e][row][col] order of Y's index - keep the two straight.
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
    const int KS = argc > 4 ? atoi(argv[4]) : 4;
    Meta m = load_meta(dir);
    if (rows_arg > 0) m.R = rows_arg;
    if (m.R > NTOK) { fprintf(stderr, "rows %d > NTOK %d\n", m.R, NTOK); return 2; }
    if (m.n % MM || (4 * m.k) % (KS * 2 * MK))
    { fprintf(stderr, "shape not divisible: n %% %d = %d, 4k %% %d = %d\n",
              MM, m.n % MM, KS * 2 * MK, (4 * m.k) % (KS * 2 * MK)); return 2; }

    auto wbytes = slurp(dir + "/abytes.bin");
    auto xbuf = slurp(dir + "/x8.bin");
    auto qbuf = slurp(dir + "/q.bin");
    auto sbuf = slurp(dir + "/sx8.bin");
    const int kbytes = 4 * m.k;

    // B[kb][t] = x8[t][kb/4]: each activation repeated four times along K, one step per weight byte.
    // Tokens past R are clamped onto the last valid row (b70-bench's idiom: in-bounds, branch-free,
    // and the garbage columns are simply never stored), which keeps OOB reads away from the device.
    std::vector<int8_t> hB((size_t)kbytes * NTOK);
    const int8_t *x8 = (const int8_t *)xbuf.data();
    for (int kb = 0; kb < kbytes; ++kb)
        for (int t = 0; t < NTOK; ++t)
        {
            const int row = t < m.R ? t : m.R - 1;
            hB[(size_t)kb * NTOK + t] = x8[(size_t)row * m.k + kb / 4];
        }

    printf("case %s: E %d R %d k %d n %d K %g  A bytes %.1f MiB (%.1fx trellis)  KS %d  sub-groups %zu\n",
           dir.c_str(), m.E, m.R, m.k, m.n, m.K, (double)wbytes.size() / 1048576.0,
           (double)wbytes.size() / (double)(m.E * m.tk * m.tn * (int)(8 * m.K) * 4), KS,
           (unsigned long long)((size_t)m.E * (m.n / MM) * KS * 2));

    sycl::device dev{sycl::gpu_selector_v};
    sycl::context ctx{dev};
    sycl::queue q{ctx, dev, sycl::property::queue::in_order{}};

    uint8_t *A = (uint8_t *)sycl::malloc_device(wbytes.size(), q);
    int8_t *B = (int8_t *)sycl::malloc_device(hB.size(), q);
    float *Q = (float *)sycl::malloc_device(qbuf.size(), q);
    int32_t *SX8 = (int32_t *)sycl::malloc_device(sbuf.size(), q);
    float *Y = (float *)sycl::malloc_device((size_t)m.E * m.R * m.n * 4, q);
    int32_t *PART = (int32_t *)sycl::malloc_device((size_t)KS * 2 * m.E * m.n * NTOK * 4, q);
    q.memcpy(A, wbytes.data(), wbytes.size());
    q.memcpy(B, hB.data(), hB.size());
    q.memcpy(Q, qbuf.data(), qbuf.size());
    q.memcpy(SX8, sbuf.data(), sbuf.size());
    q.wait();

    auto dispatch = [&]
    {
        submit(q, A, B, PART, m, KS);
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
    std::vector<float> yy(y);
    char outpath[512];
    snprintf(outpath, sizeof outpath, "%s/y_dev_dpas_ks%d.bin", dir.c_str(), KS);
    FILE *fo = fopen(outpath, "wb");
    fwrite(yy.data(), 4, yy.size(), fo);
    fclose(fo);

    const double weights = (double)m.E * m.k * m.n;          // weight-count, the comparable metric
    const double macs = weights * (double)m.R * 4.0;         // four byte-MACs per weight-token
    printf("dpas ks %d rows %d: %8.1f us  %7.1f G-weights/s  %7.1f GB/s(A reads)  %6.2f T byte-MAC/s"
           "   [burst; single-launch %7.1f us = %7.1f G-w/s]\n",
           KS, m.R, tpbest * 1e6, weights / tpbest / 1e9, wbytes.size() / tpbest / 1e9,
           macs / tpbest / 1e12, best * 1e6, weights / best / 1e9);
    printf("wrote %s (max|y| %.3f, sum %.1f)\n", outpath,
           *std::max_element(yy.begin(), yy.end(), [](float a, float b){ return fabs(a) < fabs(b); }),
           [&]{ double s = 0; for (float v : yy) s += v; return s; }());

    sycl::free(A, q); sycl::free(B, q); sycl::free(Q, q); sycl::free(SX8, q);
    sycl::free(Y, q); sycl::free(PART, q);
    return 0;
}