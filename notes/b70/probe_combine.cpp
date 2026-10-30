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
    for (int R : {1, 8, 16})
    {
        auto a = [&](void) { split(q, PA, PB, Q, SX8, YA, YB, R); };
        auto b = [&](void) { pair(q, PA, PB, Q, SX8, YA, YB, R); };
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
        do { a(); b(); } while (std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count() < ws);
        q.wait();
        double ta = 1e30, tb = 1e30;
        for (int r = 0; r < 4; ++r) { ta = std::min(ta, burst(a)); tb = std::min(tb, burst(b)); }
        const double bytes = 2.0 * ((double)KS * 2 * E * R * N * 4 + (double)E * R * N * 4);
        printf("combine rows=%-2d  split %6.2f us   pair %6.2f us   %+5.2f us   (pair carries 2 launch's work: %.0f MB moved)\n",
               R, ta * 1e6, tb * 1e6, (tb - ta) * 1e6, bytes / 1e6);
    }
    return 0;
}