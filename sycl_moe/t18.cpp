// padded-tile + vector-load gemv inner loop profile (no correctness, pure throughput)
#include <sycl/sycl.hpp>
#include <cstdio>
#include <cstdint>
#include <algorithm>
int main() {
    sycl::queue q{sycl::gpu_selector_v, {sycl::property::queue::enable_profiling()}};
    const int NG = 100, LT = 128;
    const int K2 = 4, W = 4 * K2, WP = W + 1;         // padded words per tile
    const int TK = 160, TILES = 8;
    const size_t bufn = (size_t)NG * TILES * WP * TK;
    uint32_t* buf = sycl::malloc_device<uint32_t>(bufn, q);
    float* out = sycl::malloc_device<float>(NG * LT, q);
    q.parallel_for(bufn, [=](sycl::id<1> i){ buf[i] = (uint32_t)(i[0] * 2654435761u); }).wait();
    double best = 1e30;
    for (int rep = 0; rep < 20; ++rep) {
        auto e = q.submit([&](sycl::handler& cgh) {
            cgh.parallel_for(sycl::nd_range<1>({(size_t)NG * LT}, {LT}), [=](sycl::nd_item<1> it) {
                const int g = (int)it.get_group(0), tid = (int)it.get_local_id(0);
                const int cin = tid & 15;
                // per-column window plan: rel bit offsets vs. column's linear word base
                int lo = 1000, rel[16];
                for (int rk = 0; rk < 16; ++rk) {
                    const int bb = ((cin & 7) << 2) | ((rk >> 1) & 3);
                    const int jj = (rk & 1) | ((rk & 8) ? 2 : 0) | ((cin & 8) ? 4 : 0);
                    const int t = (bb << 3) | jj;
                    const int b1 = (((t + 1) * K2) >> 1) + 128 * K2;
                    const int b0 = b1 - 16;
                    const int w0 = (b0 >> 5);            // NO mod: linear (padded tiles)
                    lo = w0 < lo ? w0 : lo;
                    rel[rk] = b0 - lo * 32;
                }
                const uint32_t* base = buf + (size_t)g * TILES * WP + (lo >> 4) * 0;
                // tile t at (tk*TILES + sg)*WP; lane's vector base = tile base + lo
                const int sg = tid >> 4;
                float acc = 0.f;
                for (int tk = 0; tk < TK; ++tk) {
                    const uint32_t* p = base + ((size_t)tk * TILES + sg) * WP + lo;
                    sycl::vec<uint32_t, 4> v = sycl::vec<uint32_t, 4>(
                        p[0], p[1], p[2], p[3]);
#pragma unroll
                    for (int rk = 0; rk < 16; ++rk) {
                        const int s = rel[rk];
                        const uint32_t x = s < 32 ? (v[s / 32] >> s) | (s + 16 > 32 ? v[s / 32 + 1] << (32 - s) : 0)
                                                  : (v[s / 32] >> (s - 32)) | (s + 16 > 64 ? v[s / 32 + 1] << (64 - s) : 0);
                        acc += (float)(x & 0xffffu);
                    }
                }
                out[(size_t)g * LT + tid] = acc;
            });
        });
        e.wait();
        best = std::min(best, (double)(e.get_profiling_info<sycl::info::event_profiling::command_end>() -
                     e.get_profiling_info<sycl::info::event_profiling::command_start>()) * 1e-3);
    }
    const double bytes = (double)NG * TILES * WP * 4 * TK;
    printf("vec-load gemv: %.1f us => %.1f GB/s\n", best, bytes / (best * 1e-6) / 1e9);
    return 0;
}
