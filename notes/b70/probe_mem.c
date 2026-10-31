// probe_mem: what the CPU home can actually move, at the working-set sizes the expert path uses.
//
// WHY THIS EXISTS. The plan quotes 13-14 GB/s for pinned<->device and 190-674 GB/s for the GPU, but the HOST's
// own ceiling was never measured - it was assumed from the link. That assumption is load-bearing twice over:
// (1) any claim that the CPU expert path is "link-bound" is wrong if DRAM is the narrower term, and (2) the
// -mcpa prefill result (+30 % on 2.05, +50 % on 2.68, out_prefill_mcpa.txt) needs a bandwidth budget to say
// whether promotion moves work off DRAM or off cache. This machine is a Ryzen 9 5950X: 2x DDR4-3200 = 51.2 GB/s
// theoretical, L3 = 64 MB across TWO CCXs (32 MB each), so a 15-thread run straddles the Infinity Fabric - which
// is exactly the regime -mct 15 runs in, and exactly why a datasheet number is not the measurement.
//
// What is swept, and why each size matters to the expert path:
//   2 MiB   = one expert's three projection weight tensors at ~0.26 B/weight (the set the CPU worker re-reads
//             ceil(rows/MAX_M) times per job group, MAX_M = 4 in moe_mul1.cpp:71) -> L2/L3 service rate
//   16 MiB  = several hot experts resident together -> still L3, but on one CCX only if threads cooperate
//   64 MiB  = L3 capacity boundary
//   512 MiB = DRAM, which is what unique expert bytes come from when the split is large
// Read-only is the mode that matters for weights (activations are tiny), so read is the headline column; copy
// and triad are included because a copy is what promotion (CPU->GPU staging) looks like on the host side.
//
// Build:  gcc -O3 -mavx2 -march=native -fopenmp -o probe_mem probe_mem.c
// Usage:  ./probe_mem [threads] [reps]
#include <immintrin.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <omp.h>

static double now_s(void)
{
    struct timespec ts; clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + 1e-9 * (double)ts.tv_nsec;
}

// Sinks keep the loads live without adding arithmetic the compiler can fold away.
static volatile double SINK;

#define REP_LOOPS 7        // inner repetitions: min-of-N, because DVFS makes the first pass slow

// read: sum of dwords, the minimum work per byte so the loop is supply-bound not ALU-bound.
static double bench_read(const uint64_t *a, size_t n, int threads)
{
    double best = 1e30;
    for (int rep = 0; rep < REP_LOOPS; ++rep)
    {
        double t0 = now_s();
        uint64_t acc = 0;
        #pragma omp parallel num_threads(threads) reduction(+:acc)
        {
            const size_t chunk = (n + (size_t)omp_get_num_threads() * 4 - 1) /
                                 ((size_t)omp_get_num_threads() * 4) * 4;
            size_t i0 = (size_t)omp_get_thread_num() * chunk;
            const uint64_t *p = a + i0;
            size_t lim = n - i0 < chunk ? n - i0 : chunk;
            __m256i v0 = _mm256_setzero_si256(), v1 = _mm256_setzero_si256();
            size_t j = 0;
            // 64 B per iteration in two 32 B loads, advancing exactly what is loaded. The first version stepped
            // by 16 uint64 while loading at j and j+4, so it touched half the buffer and charged for all of it -
            // every read number came out 2x high, which no amount of staring at the print would have revealed.
            for (; j + 8 <= lim; j += 8)                      // 2 streams, fully covering
            {
                v0 = _mm256_add_epi64(v0, _mm256_load_si256((const __m256i *)(p + j)));
                v1 = _mm256_add_epi64(v1, _mm256_load_si256((const __m256i *)(p + j + 4)));
            }
            for (; j < lim; ++j) acc += p[j];
            acc += (uint64_t)_mm256_extract_epi64(_mm256_add_epi64(v0, v1), 0);
        }
        double dt = now_s() - t0;
        SINK = (double)acc;
        if (dt < best) best = dt;
    }
    return best;
}

static double bench_copy(uint64_t *d, const uint64_t *s, size_t n, int threads)
{
    double best = 1e30;
    for (int rep = 0; rep < REP_LOOPS; ++rep)
    {
        double t0 = now_s();
        #pragma omp parallel num_threads(threads)
        {
            const size_t chunk = (n + (size_t)omp_get_num_threads() - 1) / (size_t)omp_get_num_threads();
            size_t i0 = (size_t)omp_get_thread_num() * chunk;
            size_t lim = n - i0 < chunk ? n - i0 : chunk;
            #pragma omp simd
            for (size_t j = 0; j < lim; ++j) d[i0 + j] = s[i0 + j];
        }
        double dt = now_s() - t0;
        if (dt < best) best = dt;
    }
    return best;
}

int main(int argc, char **argv)
{
    const int threads = argc > 1 ? atoi(argv[1]) : 15;
    const int reps = argc > 2 ? atoi(argv[2]) : 3;
    const size_t MiB = 1024ul * 1024ul;
    static const size_t SZ[] = { 2 * MiB, 16 * MiB, 64 * MiB, 512 * MiB };
    const size_t big = SZ[sizeof(SZ) / sizeof(SZ[0]) - 1];

    uint64_t *a = aligned_alloc(64, big * sizeof(uint64_t) * 2);
    uint64_t *b = aligned_alloc(64, big * sizeof(uint64_t) * 2);
    if (!a || !b) { fprintf(stderr, "alloc failed\n"); return 2; }
    for (size_t i = 0; i < big * 2; ++i) { a[i] = i * 2654435761u; b[i] = 0; }

    printf("probe_mem: %d threads (OMP_NUM_THREADS ignored), min of %d, AVX2; ceiling for 2x DDR4-3200 = 51.2 GB/s\n",
           threads, reps);
    printf("%10s %10s %12s %12s   %s\n", "buffer", "vs L3 64M", "read GB/s", "copy GB/s", "read GB/s per thread");
    for (size_t k = 0; k < sizeof(SZ) / sizeof(SZ[0]); ++k)
    {
        size_t bytes = SZ[k];
        size_t n = bytes / sizeof(uint64_t);
        double r = 1e30, c = 1e30;
        for (int q = 0; q < reps; ++q)
        {
            double t = bench_read(a, n, threads); if (t < r) r = t;
            t = bench_copy(b, a, n, threads);     if (t < c) c = t;
        }
        double rg = (double)bytes / r / 1e9, cg = 2.0 * (double)bytes / c / 1e9;   // copy moves read+write
        printf("%9zuM %10.2fx %12.1f %12.1f   %8.2f  (copy = %.1f%% of the 51.2 DRAM ceiling; cache rows can exceed it)\n",
               bytes / MiB, (double)bytes / (64.0 * MiB), rg, cg, rg / threads, 100.0 * cg / 51.2);
    }
    free(a); free(b);
    return 0;
}