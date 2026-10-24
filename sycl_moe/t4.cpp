#include <sycl/sycl.hpp>
#include <cstdio>
#include <vector>
int main() {
    sycl::queue q{sycl::gpu_selector_v, {sycl::property::queue::enable_profiling()}};
    constexpr int N = 1 << 20;
    float* buf = sycl::malloc_device<float>(N, q);
    std::vector<float> probe(N);
    for (int trial = 0; trial < 3; ++trial) {
        q.memset(buf, 0, N * 4);
        // A: write constants, with local accessor + barriers like the real kernels
        q.submit([&](sycl::handler& cgh) {
            sycl::local_accessor<float, 1> sh({128}, cgh);
            cgh.parallel_for(sycl::nd_range<2>({512, 128}, {128, 1}), [=](sycl::nd_item<2> it) {
                int g = (int)it.get_group(1), tid = (int)it.get_local_id(0);
                sh[tid] = (float)g + 1.f;
                sycl::group_barrier(it.get_group());
                buf[g * 128 + tid] = sh[tid];
            });
        });
        // B: read immediately, sum; if stale zeros -> mismatch
        q.submit([&](sycl::handler& cgh) {
            cgh.parallel_for(N, [=](sycl::id<1> i) { buf[i] = buf[i] * 2.f; });
        });
        q.wait();
        q.memcpy(probe.data(), buf, N * 4).wait();
        int zero = 0; for (int i = 0; i < 512 * 128; ++i) zero += probe[i] == 0.f;
        int firstz = -1, firsto = -1;
        for (int i = 0; i < 512 * 128; ++i) { if (probe[i] == 0.f && firstz < 0) firstz = i; if (probe[i] != 0.f && firsto < 0) firsto = i; }
        int vals[8]; for (int k = 0; k < 8; ++k) vals[k] = (int)probe[k * 8192];
        printf("trial %d: zeros = %d firstzero %d firstone %d samples %d %d %d %d %d %d %d %d\n", trial, zero, firstz, firsto, vals[0], vals[1], vals[2], vals[3], vals[4], vals[5], vals[6], vals[7]);
    }
    return 0;
}
