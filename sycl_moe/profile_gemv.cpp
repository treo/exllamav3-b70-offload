// clean per-op profile: 12800 threads x 2560 ops, 5 modes, rock-solid DCE barriers
#include <sycl/sycl.hpp>
#include <cstdio>
#include <cstdint>
#include <vector>
#include <algorithm>
int main() {
    sycl::queue q{sycl::gpu_selector_v, {sycl::property::queue::enable_profiling()}};
    const int NG = 100, LT = 128, OPS = 2560;
    const size_t bufn = 1 << 22;
    uint32_t* buf = sycl::malloc_device<uint32_t>(bufn, q);
    float* out = sycl::malloc_device<float>(NG * LT, q);
    q.parallel_for(bufn, [=](sycl::id<1> i){ buf[i] = (uint32_t)(i[0] * 2654435761u); }).wait();
    const char* names[5] = {"fma      ", "uni-load ", "gather   ", "gather+mrg", "full     "};
    for (int mode = 0; mode < 5; ++mode) {
        double best = 1e30;
        for (int rep = 0; rep < 20; ++rep) {
            auto e = q.submit([&](sycl::handler& cgh) {
                cgh.parallel_for(sycl::nd_range<1>({(size_t)NG * LT}, {LT}), [=](sycl::nd_item<1> it) {
                    const int g = (int)it.get_group(0), tid = (int)it.get_local_id(0);
                    const uint32_t* p = buf + (size_t)(g * 132 + tid) * 32;   // ~streaming
                    float acc = 0.f;
                    // pseudo-random per-lane word indices (0..31) for gather modes
                    uint32_t ix = 0x9e3779b9u * (tid + 1) + g;
                    unsigned char ai[2];
                    ai[0] = (unsigned char)(ix & 31); ai[1] = (unsigned char)((ix >> 5) & 31);
                    int a0 = ai[0], a1 = ai[1], sh = 3 + (int)((ix >> 10) & 15);
                    for (int i = 0; i < OPS; i += 2) {
                        switch (mode) {
                        case 0: acc = sycl::fma(acc, 1.000001f, 0.5f); acc = sycl::fma(acc, 0.999999f, 0.25f); break;
                        case 1: acc += (float)p[(i * LT + tid) & 4095]; acc += (float)p[(i * LT + tid + 1) & 4095]; break;
                        case 2: acc += (float)p[a0]; acc += (float)p[a1]; break;
                        case 3: { uint64_t mg = ((uint64_t)p[a0] << 32) | p[a1]; acc += (float)((mg >> sh) & 0xffff); } break;
                        case 4: {
                            uint64_t mg = ((uint64_t)p[a0] << 32) | p[a1];
                            uint32_t st16 = (uint32_t)(mg >> sh) & 0xffffu;
                            uint32_t xm = st16 * 0x83DCD12Du;
                            uint32_t t1 = (xm & 0x00ff00ffu) + ((xm >> 8) & 0x00ff00ffu);
                            uint32_t bs = (t1 & 0xffffu) + (t1 >> 16);
                            acc = sycl::fma((float)(int)bs - 510.0f, 0.001f, acc);
                        } break;
                        }
                    }
                    out[(size_t)g * LT + tid] = acc;
                });
            });
            e.wait();
            best = std::min(best, (double)(e.get_profiling_info<sycl::info::event_profiling::command_end>() -
                         e.get_profiling_info<sycl::info::event_profiling::command_start>()) * 1e-3);
        }
        printf("%s: %7.1f us  => %5.2f Gops/lane-s %4.1f cyc/op(2.8GHz)\n", names[mode], best,
               NG * (double)LT * OPS / best / 1e3, best * 1e-6 * 2.8e9 / (NG * (double)LT * OPS / (NG * (double)LT)));
    }
    return 0;
}
