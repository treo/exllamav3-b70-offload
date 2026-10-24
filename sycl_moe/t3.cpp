#include <sycl/sycl.hpp>
#include <cstdio>
int main() {
    sycl::queue q{sycl::gpu_selector_v};
    int* buf = sycl::malloc_device<int>(640, q);
    q.memset(buf, 0, 640*4).wait();
    const int nc = 8;
    q.submit([&](sycl::handler& cgh) {
        sycl::local_accessor<float, 1> sh({256}, cgh);
        cgh.parallel_for(sycl::nd_range<2>({(size_t)5 * 128, (size_t)nc}, {128, 1}),
            [=](sycl::nd_item<2> it) {
            const int blk = (int)it.get_group(0);
            const int j = (int)it.get_group(1);
            const int tid = (int)it.get_local_id(0);
            sh[tid] = 7.0f;
            sycl::group_barrier(it.get_group());
            const float v = sh[tid];
            buf[blk * 128 + tid] = (int)v + j;
            if (blk == 0 && tid == 0)
                sycl::ext::oneapi::experimental::printf("K3-like ran: j=%d v=%f\n", j, v);
        });
    });
    q.wait();
    std::vector<int> h(640);
    q.memcpy(h.data(), buf, 640*4).wait();
    int nz = 0; for (int v : h) nz += v != 0;
    printf("nonzero %d/640\n", nz);
    return 0;
}
