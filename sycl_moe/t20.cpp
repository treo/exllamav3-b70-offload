#include <sycl/sycl.hpp>
#include <sycl/ext/intel/esimd.hpp>
#include <cstdio>
#define __ESIMD_ENQ_DECLARE__
#include <cstdint>
#include <algorithm>
using namespace sycl::ext::intel::esimd;
int main() {
    sycl::queue q{sycl::gpu_selector_v, {sycl::property::queue::enable_profiling()}};
    const int NG = 2000, LT = 128, IT = 2048;
    int* out = sycl::malloc_device<int>(NG * LT, q);
    for (int mode = 0; mode < 3; ++mode) {
        double best = 1e30;
        for (int rep = 0; rep < 3; ++rep) {
            sycl::event e = q.parallel_for(sycl::range<1>((size_t)NG * LT), [=](sycl::id<1> idx) {
                __ESIMD_ENQ_DECLARE__
                int t = (int)idx[0];
                int a0 = t, a1 = t ^ 1, a2 = t ^ 2, a3 = t ^ 3, a4 = t ^ 4, a5 = t ^ 5, a6 = t ^ 6, a7 = t ^ 7;
                simd<uint32_t, 1> x; 
                for (int i = 0; i < IT; ++i) {
                    x.update((uint32_t)(t + i));
                    if (mode == 0) {
                        a0 = dp4a<int>(x, 0x01010101u, a0);
                        a1 = dp4a<int>(x, 0x01010101u, a1);
                        a2 = dp4a<int>(x, 0x01010101u, a2);
                        a3 = dp4a<int>(x, 0x01010101u, a3);
                    } else if (mode == 1) {
                        uint32_t xm = (uint32_t)(t + i);
                        a0 += (int)(xm & 0xff) + (int)((xm >> 8) & 0xff) + (int)((xm >> 16) & 0xff) + (int)(xm >> 24);
                        a1 += (int)(xm & 0xff) * 2;
                        a2 += (int)((xm >> 8) & 0xff) * 2;
                        a3 += (int)((xm >> 16) & 0xff) * 2;
                    } else {
                        uint32_t xm = (uint32_t)(t + i);
                        a0 += (int)xm; a1 ^= (int)xm; a2 -= (int)xm; a3 |= (int)xm;
                        a4 += (int)(xm >> 3); a5 ^= (int)(xm << 2); a6 -= (int)(xm >> 7); a7 |= xm;
                    }
                }
                out[t] = a0 + a1 + a2 + a3 + a4 + a5 + a6 + a7;
            });
            e.wait();
            best = std::min(best, (double)(e.get_profiling_info<sycl::info::event_profiling::command_end>() -
                         e.get_profiling_info<sycl::info::event_profiling::command_start>()) * 1e-3);
        }
        printf("mode %d: %.1f us  %.2f G-chainops/s\n", mode, best, (double)NG * LT * IT * 4 / best / 1e3);
    }
    return 0;
}
