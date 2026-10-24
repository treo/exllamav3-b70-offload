#include <sycl/sycl.hpp>
#include <cstdio>
#include <vector>
int main() {
    sycl::queue q{sycl::gpu_selector_v};
    constexpr int N = 1 << 20;
    float* buf = sycl::malloc_device<float>(N, q);
    for (int gdims : {64, 128, 129, 200, 256, 512, 1024}) {
        q.memset(buf, 0, N * 4).wait();
        q.submit([&](sycl::handler& cgh) {
            cgh.parallel_for(sycl::nd_range<2>({128, (size_t)gdims}, {128, 1}), [=](sycl::nd_item<2> it) {
                int g = (int)it.get_group(1), tid = (int)it.get_local_id(0);
                buf[g * 128 + tid] = (float)g + 1.f;
            });
        });
        q.wait();
        std::vector<float> probe((size_t)gdims * 128);
        q.memcpy(probe.data(), buf, probe.size() * 4).wait();
        int written = 0, maxg = -1;
        for (int g = 0; g < gdims; ++g) if (probe[g * 128] != 0.f) { ++written; maxg = g; }
        printf("dims %4d: groups_written %4d/%d maxg %d\n", gdims, written, gdims, maxg);
    }
    return 0;
}
