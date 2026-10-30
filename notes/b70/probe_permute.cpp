// probe_permute.cpp - E24 follow-up (D3): what does the intra-tile transpose actually cost?
//
// D3 was accepted on the argument that the permute is paid once, while weights are loaded into VRAM. That
// argument has two unmeasured premises, and this probe prices both:
//
//   1. the device-side permute kernel's own throughput, against a straight device copy of the same bytes
//      (the delta is the price of the permutation itself, not of the traffic);
//   2. the host-side cost, i.e. permuting DURING the parent->device staging copy instead of doing a plain
//      copy and following it with a device pass. If a host permute-copy runs near memcpy speed, the whole
//      question is moot and the layout can be produced as part of staging for free.
//
// Layout (rev J/K, doc/port/b70-decode-closeout.md D3): within one tile of 8*K dwords, dword q*K + i
// (row i of column group q) moves to i*8 + q. A permutation inside each tile - same bytes, same DRAM
// traffic, so capacity and streaming volume are untouched.
//
// Sizes deliberately include one full b=1 decode admission (a layer's resident slice, ~14 MiB on Qwen3.8)
// as well as the steady-state resident set, because an evicted-then-readmitted expert pays this again:
// "once per process" is true only for experts that never leave VRAM (b70-architecture.md §4a's cache tier).
//
// Build: icpx -fsycl -O2 -o probe_permute probe_permute.cpp
// Run:   ./probe_permute [K]        (default K = 3)
#include <sycl/sycl.hpp>

#include <algorithm>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>

static void permute_host(const uint32_t *src, uint32_t *dst, size_t ntiles, int K)
{
    const int NW = 8 * K;
    for (size_t t = 0; t < ntiles; ++t)
        for (int q = 0; q < 8; ++q)
            for (int i = 0; i < K; ++i) dst[t * NW + i * 8 + q] = src[t * NW + q * K + i];
}

int main(int argc, char **argv)
{
    const int K = argc > 1 ? std::atoi(argv[1]) : 3;
    if (K < 2 || K > 16) { fprintf(stderr, "K outside 2..16\n"); return 2; }
    const int NW = 8 * K;                       // dwords per tile

    sycl::device dev{sycl::gpu_selector_v};
    sycl::context ctx{dev};
    sycl::queue q{ctx, dev, sycl::property::queue::in_order{}};
    printf("device: %s   K %d  (tile = %d dwords = %d B)\n",
           dev.get_info<sycl::info::device::name>().c_str(), K, NW, NW * 4);

    // ---- correctness first: a permutation measured without being verified measures nothing ----
    {
        const size_t nt = 4096;
        std::vector<uint32_t> a(nt * NW), b(nt * NW, 0u), want(nt * NW, 0u);
        for (size_t i = 0; i < a.size(); ++i) a[i] = (uint32_t)(i * 2654435761u + K);
        permute_host(a.data(), want.data(), nt, K);
        uint32_t *da = (uint32_t *)sycl::malloc_device(a.size() * 4, q),
               *db = (uint32_t *)sycl::malloc_device(b.size() * 4, q);
        q.memcpy(da, a.data(), a.size() * 4).wait();
        q.parallel_for(sycl::range<1>(nt), [=](sycl::id<1> id) {
            const size_t t = id[0];
            for (int i = 0; i < K; ++i)
                for (int j = 0; j < 8; ++j) db[t * NW + i * 8 + j] = da[t * NW + j * K + i];
        }).wait();
        q.memcpy(b.data(), db, b.size() * 4).wait();
        sycl::free(da, q); sycl::free(db, q);
        size_t bad = 0;
        for (size_t i = 0; i < b.size(); ++i) bad += (b[i] != want[i]);
        printf("device permute vs host reference: %s (%zu of %zu dwords differ)\n",
               bad ? "MISMATCH" : "exact", bad, b.size());
        if (bad) return 3;
    }

    const size_t sizes_mib[] = {14, 64, 256, 512};
    std::vector<uint32_t> host;
    for (size_t mib : sizes_mib)
    {
        const size_t bytes = (size_t)mib << 20;
        const size_t nt = bytes / (NW * 4);
        const size_t n = nt * NW;
        uint32_t *d_src = (uint32_t *)sycl::malloc_device(n * 4, q);
        uint32_t *d_dst = (uint32_t *)sycl::malloc_device(n * 4, q);
        std::vector<uint32_t> seed(std::min<size_t>(n, 1 << 20), 0x5a5a5a5au);
        q.memset(d_src, 0x5a, n * 4); q.memset(d_dst, 0, n * 4); q.wait();
        (void)seed;

        auto time_rep = [&](int which) {
            auto t0 = std::chrono::steady_clock::now();
            if (which == 0)
                q.parallel_for(sycl::range<1>(nt), [=](sycl::id<1> id) {
                    const size_t t = id[0];
                    for (int i = 0; i < K; ++i)
                        for (int j = 0; j < 8; ++j) d_dst[t * NW + i * 8 + j] = d_src[t * NW + j * K + i];
                });
            else
                q.parallel_for(sycl::range<1>(n), [=](sycl::id<1> id) { d_dst[id[0]] = d_src[id[0]]; });
            q.wait();
            return std::chrono::duration<double, std::micro>(std::chrono::steady_clock::now() - t0).count();
        };

        // warm-up then min-of-N, interleaved between the two kernels so clock state cancels
        for (int r = 0; r < 3; ++r) { time_rep(0); time_rep(1); }
        double wp = 1e30, wc = 1e30, lastp = -1.0, drift = 0;   // lastp < 0: seeding it at 0 made "drift"
        for (int r = 0; r < 7; ++r)                             // report the magnitude itself (own bug)
        {
            double p = time_rep(0), c = time_rep(1);
            if (lastp >= 0) drift = std::max(drift, std::abs(p - lastp));
            lastp = p;
            wp = std::min(wp, p); wc = std::min(wc, c);
        }
        const double gib = bytes / (double)(1u << 30);
        printf("%4zu MiB  device permute %8.1f us (%6.1f GiB/s payload) | device copy %8.1f us "
               "(%6.1f GiB/s) | permute/copy x%.2f | rep drift %.1f us\n",
               mib, wp, gib / (wp * 1e-6), wc, gib / (wc * 1e-6), wp / wc, drift);

        sycl::free(d_src, q); sycl::free(d_dst, q);
    }

    // ---- host side: permuting while copying, vs memcpy (what staging would cost the parent) ----
    {
        const size_t bytes = (size_t)64 << 20, n = bytes / 4, nt = n / NW;
        std::vector<uint32_t> a(n, 0x12345678u), b(n);
        volatile uint64_t sink = 0;
        auto hcopy = [&] {
            auto t0 = std::chrono::steady_clock::now();
            std::memcpy(b.data(), a.data(), bytes);
            sink += (uint64_t)b[n / 2];
            return std::chrono::duration<double, std::micro>(std::chrono::steady_clock::now() - t0).count();
        };
        auto hperm = [&] {
            auto t0 = std::chrono::steady_clock::now();
            permute_host(a.data(), b.data(), nt, K);
            sink += (uint64_t)b[n / 2];
            return std::chrono::duration<double, std::micro>(std::chrono::steady_clock::now() - t0).count();
        };
        for (int r = 0; r < 3; ++r) { hcopy(); hperm(); }
        double bc = 1e30, bp = 1e30;
        for (int r = 0; r < 5; ++r) { bc = std::min(bc, hcopy()); bp = std::min(bp, hperm()); }
        const double gib = bytes / (double)(1u << 30);
        printf("host 64 MiB: memcpy %8.1f us (%6.1f GiB/s) | permute-copy %8.1f us (%6.1f GiB/s) | "
               "x%.2f  (link rate is ~9 GB/s = ~8.4 GiB/s, so the comparison that matters is whether the "
               "permute-copy stays above it)\n",
               bc, gib / (bc * 1e-6), bp, gib / (bp * 1e-6), bp / bc);
    }
    return 0;
}