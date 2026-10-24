#include <sycl/sycl.hpp>
#include <sycl/ext/oneapi/dot_product.hpp>
#include <cstdio>
#include <vector>
#include <algorithm>
int main() {
    sycl::queue q{sycl::gpu_selector_v, {sycl::property::queue::enable_profiling()}};
    constexpr int N = 1 << 23, IT = 1024;
    int* out = sycl::malloc_device<int>(N, q);
    for (int mode = 0; mode < 2; ++mode) {
        double best = 1e30;
        for (int rep = 0; rep < 3; ++rep) {
            sycl::event e;
            if (mode == 0)
                e = q.parallel_for(N, [=](sycl::id<1> i) {
                    int x = (int)i[0], a = 0x41424344, c = 0;
                    for (int it = 0; it < IT; ++it) c = sycl::ext::oneapi::dot_acc((uint32_t)(a ^= x), (uint32_t)0x01010101u, c);
                    out[i] = c;
                });
            else
                e = q.parallel_for(N, [=](sycl::id<1> i) {
                    int x = (int)i[0], a = 0x41424344, c = 0;
                    for (int it = 0; it < IT; ++it) {
                        uint32_t p = (uint32_t)(a ^= x);
                        c += (int)(p & 0xff) + (int)((p >> 8) & 0xff) + (int)((p >> 16) & 0xff) + (int)(p >> 24);
                    }
                    out[i] = c;
                });
            e.wait();
            double s = (e.get_profiling_info<sycl::info::event_profiling::command_end>() -
                        e.get_profiling_info<sycl::info::event_profiling::command_start>()) * 1e-9;
            best = std::min(best, s);
        }
        printf("%s: %.2f G-iter/s\n", mode ? "manual bytes" : "dp4a  ", N * (double)IT / best / 1e9);
    }
    return 0;
}
