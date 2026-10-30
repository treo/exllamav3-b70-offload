// E25b follow-up: the two combine schedules in isolation, so the ISA dump contains only them.
//   split : one launch per projection (the kept schedule)
//   pair  : one launch whose index space covers both projections (refuted in-probe, out_e25b_combine.txt)
// Standalone on purpose: probe_dpas9's dump buries the combine kernels under the gemm, and the merged arm no
// longer exists there. Sizes match the gate case (E=10, n=640, KS=1). Not an engine kernel - a microscope.
#include <sycl/sycl.hpp>
#include <cstdio>
#include <chrono>
#include <cstdlib>
#include <vector>

static constexpr int E = 10, N = 640, KS = 1, RPAD = 16;

static void split(sycl::queue &q, const int32_t *PA, const int32_t *PB, const float *Q, const int32_t *SX8,
                  float *YA, float *YB, int R)
{
    const size_t one = (size_t)E * R * N;
    for (int p = 0; p < 2; ++p)
    {
        const int32_t *PART = p ? PB : PA; float *Y = p ? YB : YA;
        q.parallel_for(sycl::range<1>(one), [=](sycl::id<1> id)
        {
            const size_t i = id[0];
            const int e = (int)(i / ((size_t)R * N)), row = (int)((i / N) % R), col = (int)(i % N);
            int32_t s = 0;
            for (int k = 0; k < KS * 2; ++k) s += PART[(((size_t)k * E + e) * RPAD + row) * N + col];
            Y[i] = 0.0067f * Q[row] * ((float)s - 510.0f * (float)SX8[row]);
        });
    }
}

static void pair(sycl::queue &q, const int32_t *PA, const int32_t *PB, const float *Q, const int32_t *SX8,
                 float *YA, float *YB, int R)
{
    const size_t one = (size_t)E * R * N;
    q.parallel_for(sycl::range<1>(2 * one), [=](sycl::id<1> id)
    {
        const size_t i = id[0];
        const bool a = i < one;
        const int32_t *PART = a ? PA : PB; float *Y = a ? YA : YB;
        const size_t j = a ? i : i - one;
        const int e = (int)(j / ((size_t)R * N)), row = (int)((j / N) % R), col = (int)(j % N);
        int32_t s = 0;
        for (int k = 0; k < KS * 2; ++k) s += PART[(((size_t)k * E + e) * RPAD + row) * N + col];
        Y[j] = 0.0067f * Q[row] * ((float)s - 510.0f * (float)SX8[row]);
    });
}

// Mimic the gemm epilogue: write the partials immediately before the combines, so they sit in L2 dirty exactly
// as they do in situ. E25b's whole anomaly is that merging the combines wins standalone and loses after the
// gemm, and the two kernels are ISA near-clones - so whatever inverts the sign has to be the state the gemm
// leaves behind, not the combine's own work.
// E25b, next hypothesis: in situ the partials may not be L2-resident when the combine runs - the fused gemm is
// a full-device kernel and the layer moves other traffic through L2 - whereas the hot arm above re-reads the
// same 1.6 MB forever. Scrub writes a 32 MB buffer (> the 16 MB L2) between producer and combine to evict them.
static void scrub(sycl::queue &q, char *S, size_t n)
{
    q.parallel_for(sycl::range<1>(n / 64), [=](sycl::id<1> id)
    { for (int k = 0; k < 16; ++k) ((int *)S)[id[0] * 16 + k] = 0x5a5a5a5a; });
}

static void producer(sycl::queue &q, int32_t *PA, int32_t *PB, int R)
{
    const size_t n = (size_t)KS * 2 * E * RPAD * N;   // one projection's full partial region
    q.parallel_for(sycl::range<1>(2 * n), [=](sycl::id<1> id)
    {
        const size_t i = id[0];
        const bool a = i < n;
        int32_t *P = a ? const_cast<int32_t *>(PA) : const_cast<int32_t *>(PB);
        const size_t j = a ? i : i - n;
        P[j] = (int32_t)(j * 3 + 7);
    });
}

int main(int argc, char **argv)
{
    sycl::queue q{sycl::gpu_selector_v};
    const int reps = argc > 1 ? atoi(argv[1]) : 200;
    const double ws = getenv("WARM_S") ? atof(getenv("WARM_S")) : 2.0;
    const size_t partb = (size_t)KS * 2 * E * RPAD * N * 4, ob = (size_t)E * 64 * N * 4;
    int32_t *PA = (int32_t *)sycl::malloc_device(partb, q), *PB = (int32_t *)sycl::malloc_device(partb, q);
    int32_t *SX8 = (int32_t *)sycl::malloc_device(64 * 4, q);
    float *Q = (float *)sycl::malloc_device(64 * 4, q);
    float *YA = (float *)sycl::malloc_device(ob, q), *YB = (float *)sycl::malloc_device(ob, q);
    q.memset(PA, 1, partb); q.memset(PB, 1, partb); q.memset(SX8, 0, 64 * 4); q.memset(Q, 0, 64 * 4);
    q.memset(YA, 0, ob); q.memset(YB, 0, ob); q.wait();
    const size_t scn = (size_t)32 << 20;
    char *SC = (char *)sycl::malloc_device(scn, q);
    q.memset(SC, 0, scn); q.wait();
    for (int R : {1, 8, 16})
    {
        auto a = [&](void) { split(q, PA, PB, Q, SX8, YA, YB, R); };
        auto b = [&](void) { pair(q, PA, PB, Q, SX8, YA, YB, R); };
        auto ca = [&](void) { producer(q, PA, PB, R); split(q, PA, PB, Q, SX8, YA, YB, R); };
        auto cb = [&](void) { producer(q, PA, PB, R); pair(q, PA, PB, Q, SX8, YA, YB, R); };
        auto ea = [&](void) { producer(q, PA, PB, R); scrub(q, SC, scn); split(q, PA, PB, Q, SX8, YA, YB, R); };
        auto eb = [&](void) { producer(q, PA, PB, R); scrub(q, SC, scn); pair(q, PA, PB, Q, SX8, YA, YB, R); };
        auto s_only = [&](void) { scrub(q, SC, scn); };
        auto burst = [&](auto &f)
        {
            double bt = 1e30;
            for (int w = 0; w < 2; ++w) { f(); f(); f(); } q.wait();
            for (int r = 0; r < 5; ++r)
            {
                auto t0 = std::chrono::steady_clock::now();
                for (int i = 0; i < reps; ++i) f();
                q.wait();
                bt = std::min(bt, std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count() / reps);
            }
            return bt;
        };
        auto t0 = std::chrono::steady_clock::now();
        do { a(); b(); ca(); cb(); ea(); eb(); } while (std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count() < ws);
        q.wait();
        double ta = 1e30, tb = 1e30, tc = 1e30, td = 1e30, te = 1e30, tf = 1e30, tp = 1e30, tq = 1e30;
        auto p_only = [&](void) { producer(q, PA, PB, R); };
        for (int r = 0; r < 4; ++r)
        {
            ta = std::min(ta, burst(a)); tb = std::min(tb, burst(b));
            tc = std::min(tc, burst(ca)); td = std::min(td, burst(cb));
            te = std::min(te, burst(ea)); tf = std::min(tf, burst(eb));
            tp = std::min(tp, burst(p_only)); tq = std::min(tq, burst(s_only));
        }
        // Producer / scrub cost subtracted so each column compares combine-only; the last figure in each pair
        // is merged-minus-split, which is the quantity at issue.
        printf("rows=%-2d  resident: split %6.2f pair %6.2f (%+5.2f)  |  producer: split %6.2f pair %6.2f (%+5.2f)"
               "  |  evicted: split %6.2f pair %6.2f (%+5.2f)   [prod %5.2f scrub %5.2f]\n",
               R, ta * 1e6, tb * 1e6, (tb - ta) * 1e6,
               (tc - tp) * 1e6, (td - tp) * 1e6, (td - tc) * 1e6,
               (te - tp - tq) * 1e6, (tf - tp - tq) * 1e6, (tf - te) * 1e6, tp * 1e6, tq * 1e6);
    }
    return 0;
}