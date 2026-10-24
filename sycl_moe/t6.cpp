#include <sycl/sycl.hpp>
#include <cstdio>
#include <cstdlib>
#include <vector>
int main(int argc, char** argv) {
    int variant = argc > 1 ? atoi(argv[1]) : 0;
    sycl::queue q{sycl::gpu_selector_v, {sycl::property::queue::enable_profiling()}};
    constexpr int N = 1 << 20;
    float* buf = sycl::malloc_device<float>(N, q);
    q.memset(buf, 0, N * 4);
    q.submit([&](sycl::handler& cgh) {
        sycl::local_accessor<float, 1> sh({128}, cgh);
        cgh.parallel_for(sycl::nd_range<2>({128, 512}, {128, 1}), [=](sycl::nd_item<2> it) {
            int g = (int)it.get_group(1), tid = (int)it.get_local_id(0);
            if (variant & 1) { sh[tid] = (float)g + 1.f; sycl::group_barrier(it.get_group()); buf[g * 128 + tid] = sh[tid]; }
            else buf[g * 128 + tid] = (float)g + 1.f;
        });
    });
    if (variant & 2) q.wait();
    q.submit([&](sycl::handler& cgh) {
        cgh.parallel_for(N, [=](sycl::id<1> i) { buf[i] = buf[i] * 2.f; });
    });
    q.wait();
    std::vector<float> probe(65536);
    q.memcpy(probe.data(), buf, probe.size() * 4).wait();
    int zero = 0; for (float v : probe) zero += v == 0.f;
    printf("variant %d: zeros = %d (expect 0)\n", variant, zero);
    return 0;
}
