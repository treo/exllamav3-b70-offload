// dp4a hardware check
#include <sycl/sycl.hpp>
#include <sycl/ext/oneapi/dot_product.hpp>
#include <cstdio>
#include <cstdint>
#include <algorithm>
int main() {
    sycl::queue q{sycl::gpu_selector_v, {sycl::property::queue::enable_profiling()}};
    const int NG = 800, LT = 128, IT = 2048;
    int* out = sycl::malloc_device<int>(NG * LT, q);
    for (int mode = 0; mode < 2; ++mode) {
        double best = 1e30;
        for (int rep = 0; rep < 5; ++rep) {
            sycl::event e;
            if (mode == 0)
                e = q.submit([&](sycl::handler& cgh) {
                    cgh.parallel_for(sycl::nd_range<1>({(size_t)NG * LT}, {LT}), [=](sycl::nd_item<1> it) {
                        int t = (int)it.get_global_id(0);
                        int c0 = t, c1 = t | 1, c2 = t ^ 3, c3 = t + 5, c4 = t * 2, c5 = t - 1, c6 = t ^ 16, c7 = t | 8;
                        int x = t * 2654435761u;
                        for (int i = 0; i < IT; ++i) {
                            x ^= (x << 13);
                            c0 = sycl::ext::oneapi::dot_acc((uint32_t)x, 0x01010101u, c0);
                            c1 = sycl::ext::oneapi::dot_acc((uint32_t)x, 0x01010101u, c1);
                            c2 = sycl::ext::oneapi::dot_acc((uint32_t)x, 0x01010101u, c2);
                            c3 = sycl::ext::oneapi::dot_acc((uint32_t)x, 0x01010101u, c3);
                            c4 = sycl::ext::oneapi::dot_acc((uint32_t)x, 0x01010101u, c4);
                            c5 = sycl::ext::oneapi::dot_acc((uint32_t)x, 0x01010101u, c5);
                            c6 = sycl::ext::oneapi::dot_acc((uint32_t)x, 0x01010101u, c6);
                            c7 = sycl::ext::oneapi::dot_acc((uint32_t)x, 0x01010101u, c7);
                        }
                        out[t] = c0 + c1 + c2 + c3 + c4 + c5 + c6 + c7;
                    });
                });
            else
                e = q.submit([&](sycl::handler& cgh) {
                    cgh.parallel_for(sycl::nd_range<1>({(size_t)NG * LT}, {LT}), [=](sycl::nd_item<1> it) {
                        int t = (int)it.get_global_id(0);
                        int c0 = t, c1 = t | 1, c2 = t ^ 3, c3 = t + 5, c4 = t * 2, c5 = t - 1, c6 = t ^ 16, c7 = t | 8;
                        int x = t * 2654435761u;
                        for (int i = 0; i < IT; ++i) {
                            x ^= (x << 13);
                            uint32_t xm = (uint32_t)x;
                            uint32_t t1 = (xm & 0x00ff00ffu) + ((xm >> 8) & 0x00ff00ffu);
                            int bs = (int)((t1 & 0xffffu) + (t1 >> 16));
                            c0 += bs; c1 += bs; c2 += bs; c3 += bs; c4 += bs; c5 += bs; c6 += bs; c7 += bs;
                        }
                        out[t] = c0 + c1 + c2 + c3 + c4 + c5 + c6 + c7;
                    });
                });
            e.wait();
            best = std::min(best, (double)(e.get_profiling_info<sycl::info::event_profiling::command_end>() -
                         e.get_profiling_info<sycl::info::event_profiling::command_start>()) * 1e-3);
        }
        double gops = (double)NG * LT * IT * 8 / best / 1e3;
        printf("%s: %.1f us  %.2f G-ops/s\n", mode ? "manual bytesum " : "dp4a dot_acc  ", best, gops);
    }
    return 0;
}
