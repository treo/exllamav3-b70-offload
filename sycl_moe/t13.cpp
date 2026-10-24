// streaming pattern probe: same WG shape as K2 (100 WG x 128T), stream 80KB per WG through
// shared, no dequant math. Measures achievable BW for this access shape.
#include <sycl/sycl.hpp>
#include <cstdio>
#include <vector>
#include <algorithm>
int main() {
    sycl::queue q{sycl::gpu_selector_v, {sycl::property::queue::enable_profiling()}};
    const int NG = 100;              // work groups
    const int TK = 160, TW = 16;     // tile steps, words per tile band step (K=2: 8 tiles*16)
    const size_t per_stream = (size_t)TK * TW * 4 * 8;   // 8 tiles x 16 words x 4B per step * 160
    const size_t total = (size_t)NG * per_stream;
    uint32_t* buf = sycl::malloc_device<uint32_t>(total / 4, q);
    q.memset(buf, 1, total).wait();
    printf("streaming %.1f MB across %d streams\n", total / 1e6, NG);
    for (int variant = 0; variant < 3; ++variant) {
        double best = 1e30;
        for (int rep = 0; rep < 5; ++rep) {
            sycl::event e;
            if (variant == 0) {     // pure global, no shared staging
                e = q.parallel_for(sycl::nd_range<1>({(size_t)NG * 128}, {128}), [=](sycl::nd_item<1> it) {
                    const int g = it.get_group(0), tid = it.get_local_id(0);
                    const uint32_t* p = buf + (size_t)g * (TW * 8);
                    uint32_t s = 0;
                    for (int tk = 0; tk < TK; ++tk)
                        for (int w = tid; w < TW * 8; w += 128) s += p[(size_t)tk * TW * 8 + w];
                    if (s == 0xffffffffu) ((uint32_t*)buf)[0] = s;
                });
            } else if (variant == 1) {  // shared staging, double buffered
                e = q.submit([&](sycl::handler& cgh) {
                    sycl::local_accessor<uint32_t, 1> st({(size_t)TW * 8 * 2}, cgh);
                    cgh.parallel_for(sycl::nd_range<1>({(size_t)NG * 128}, {128}), [=](sycl::nd_item<1> it) {
                        const int g = (int)it.get_group(0), tid = (int)it.get_local_id(0);
                        const uint32_t* p = buf + (size_t)g * (TW * 8);
                        uint32_t s = 0;
                        for (int tk = 0; tk < TK; ++tk) {
                            const int cur = tk & 1;
                            for (int w = tid; w < TW * 8; w += 128)
                                st[cur * TW * 8 + w] = p[(size_t)tk * TW * 8 + w];
                            sycl::group_barrier(it.get_group());
                            for (int w = tid; w < TW * 8; w += 128) s += st[cur * TW * 8 + w];
                            sycl::group_barrier(it.get_group());
                        }
                        if (s == 0xffffffffu) ((uint32_t*)buf)[0] = s;
                    });
                });
            } else {                  // variant 0 with unrolled contiguous per-lane stride
                e = q.parallel_for(sycl::nd_range<1>({(size_t)NG * 128}, {128}), [=](sycl::nd_item<1> it) {
                    const int g = it.get_group(0), tid = it.get_local_id(0);
                    const uint32_t* p = buf + (size_t)g * (TW * 8);
                    uint32_t s = 0;
                    for (int tk = 0; tk < TK; ++tk) s += p[(size_t)tk * TW * 8 + tid];
                    if (s == 0xffffffffu) ((uint32_t*)buf)[0] = s;
                });
            }
            e.wait();
            double us = (e.get_profiling_info<sycl::info::event_profiling::command_end>() -
                         e.get_profiling_info<sycl::info::event_profiling::command_start>()) * 1e-3;
            best = std::min(best, us);
        }
        printf("variant %d: %.1f us => %.1f GB/s\n", variant, best, total / (best * 1e-6) / 1e9);
    }
    return 0;
}
