// t47: is the int8 gemv's weight stream limited by the DRAM *access pattern* rather than by
// peak bandwidth? The arena lays tiles out k-major ([tk][nf]), so a gemv sub-group that owns
// one column tile (nf) walks k with a stride of nfl*W bytes (5 KB at the 2.05bpw shape) while
// consuming only W*4 = 128 B per step. This probe reads identical byte counts through three
// access patterns with production-like launch geometry (16-lane sub-groups):
//   P1  [tk][nf]  (production: 128 B per 5 KB stride)
//   P2  [nf][tk]  (hypothetical transposed arena: sequential per sub-group)
//   P3  whole-slab sequential sycl::uint4 (bandwidth upper bound)
// Burn-in >= 1.5 s then min-of-N (sycl_moe/NOTES measurement rules).
#include <sycl/sycl.hpp>
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <vector>
#include <chrono>

static constexpr int W = 32;                    // u32 words per (column tile, k tile) = 128 B
static constexpr int NFL = 40;                  // column tiles per k tile (N=640 -> 40)
static constexpr int TILESK = 160;              // k tiles (K=2560 -> 160)
static constexpr int LPR = 8;      // lanes per column-tile reader group (probe geometry)
static constexpr int CATW = NFL * TILESK * W;   // words per expert-cat = 204800 = 819 KB

template <int TRANSPOSED>
struct Reader
{
    const uint32_t* w;
    uint32_t* out;
    void operator()(sycl::nd_item<2> it) const
    {
        const int nf = (int)it.get_group(0);
        const int e  = (int)it.get_group(1);
        const int lid = (int)it.get_local_id(0);
        const size_t base = (size_t)e * CATW;
        uint64_t sum = 0;
        const size_t step = TRANSPOSED ? (size_t)W : (size_t)NFL * W;
        const uint32_t* p = w + base + (TRANSPOSED ? (size_t)nf * TILESK * W : (size_t)nf * W) + lid;
        for (int tk = 0; tk < TILESK; ++tk)
            for (int q = 0; q < W / LPR; ++q)
                sum += p[tk * step + q * LPR];
        out[(size_t)e * NFL + nf] = (uint32_t)(sum ^ (sum >> 32));  // observable: defeats DCE
    }
};

struct Seq
{
    const uint32_t* w;
    uint32_t* out;
    void operator()(sycl::nd_item<1> it) const
    {
        const size_t gid = it.get_group(0);
        const sycl::uint4* p = (const sycl::uint4*)(w + gid * CATW);
        uint64_t sum = 0;
        for (int i = (int)it.get_local_id(0); i < CATW / 4; i += (int)it.get_local_range(0))
        {
            sycl::uint4 v = p[i];
            sum += (uint64_t)v.x() + v.y() + v.z() + v.w();
        }
        out[gid] = (uint32_t)(sum ^ (sum >> 32));
    }
};

int main(int argc, char** argv)
{
    const int nexp = argc > 1 ? atoi(argv[1]) : 260;
    sycl::queue q{sycl::gpu_selector_v};
    printf("%s\n", q.get_device().get_info<sycl::info::device::name>().c_str());

    const size_t bytes = (size_t)nexp * CATW * 4;
    uint32_t* w = (uint32_t*)sycl::malloc_device(bytes, q);
    uint32_t* out = (uint32_t*)sycl::malloc_device((size_t)nexp * NFL * 4 + 4096, q);
    std::vector<uint32_t> host(bytes / 4);
    for (size_t i = 0; i < host.size(); ++i) host[i] = (uint32_t)(i * 2654435761u);
    q.memcpy(w, host.data(), bytes).wait();
    printf("slab %.1f MB (%d experts x %.0f KB per cat)\n", bytes / 1e6, nexp, CATW * 4 / 1e3);

    auto bench = [&](const char* name, auto fn)
    {
        for (int i = 0; i < 50; ++i) fn().wait();                     // burn-in
        double best = 1e30;
        auto t_start = std::chrono::steady_clock::now();
        while (std::chrono::duration<double>(std::chrono::steady_clock::now() - t_start).count() < 3.0)
        {
            auto t0 = std::chrono::steady_clock::now();
            for (int i = 0; i < 20; ++i) fn().wait();
            double us = std::chrono::duration<double, std::micro>(
                std::chrono::steady_clock::now() - t0).count() / 20.0;
            best = std::min(best, us);
        }
        printf("%-26s %9.1f us/iter  %7.1f GB/s\n", name, best, bytes / best / 1e3);
    };

    auto p1 = [&]{ return q.parallel_for(sycl::nd_range<2>(sycl::range<2>(NFL*LPR, nexp), sycl::range<2>(LPR, 1)), Reader<0>{w, out}); };
    auto p2 = [&]{ return q.parallel_for(sycl::nd_range<2>(sycl::range<2>(NFL*LPR, nexp), sycl::range<2>(LPR, 1)), Reader<1>{w, out}); };
    auto p3 = [&]{ return q.parallel_for(sycl::nd_range<1>(sycl::range<1>(nexp*256), sycl::range<1>(256)), Seq{w, out}); };

    bench("P1 [tk][nf] production", p1);
    bench("P2 [nf][tk] transposed", p2);
    bench("P3 sequential sycl::uint4", p3);
    bench("P1 again (warm)", p1);
    bench("P2 again (warm)", p2);
    q.wait();
    sycl::free(w, q); sycl::free(out, q);
    return 0;
}