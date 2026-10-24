// in-process calibration: fp32 vector throughput + mem copy, b70-bench style
#include <sycl/sycl.hpp>
#include <cstdio>
#include <algorithm>
int main() {
    sycl::queue q{sycl::gpu_selector_v, {sycl::property::queue::enable_profiling()}};
    printf("dev %s\n", q.get_device().get_info<sycl::info::device::name>().c_str());
    { // vector fma
        constexpr size_t ITEMS = 1<<23; constexpr int ITERS = 4096, CH = 8;
        float* out = sycl::malloc_device<float>(ITEMS, q);
        double best = 1e30;
        for (int rep=0; rep<3; ++rep) {
            auto e = q.parallel_for(ITEMS, [=](sycl::id<1> i){
                float x[CH]; for (int c=0;c<CH;++c) x[c]=(float)(i[0]%7+c);
                for (int it=0; it<ITERS; ++it)
                    _Pragma("unroll")
                    for (int c=0;c<CH;++c) x[c]=sycl::fma(x[c],0.5f,1.0f);
                float s=0; for (int c=0;c<CH;++c) s+=x[c];
                out[i]=s; });
            e.wait();
            best = std::min(best, (double)(e.get_profiling_info<sycl::info::event_profiling::command_end>() - e.get_profiling_info<sycl::info::event_profiling::command_start>())*1e-9);
        }
        printf("FP32 FMA: %.2f TFLOPS\n", 2.0*ITEMS*ITERS*CH/best/1e12);
        sycl::free(out, q);
    }
    { // 64MB copy
        size_t n = 16<<20;
        float *a = sycl::malloc_device<float>(n,q), *b = sycl::malloc_device<float>(n,q);
        double best=1e30;
        for (int rep=0; rep<5; ++rep) {
            auto e = q.memcpy(b,a,n*4); e.wait();
            best = std::min(best,(double)(e.get_profiling_info<sycl::info::event_profiling::command_end>() - e.get_profiling_info<sycl::info::event_profiling::command_start>())*1e-9);
        }
        printf("memcpy: %.1f GB/s (r+w)\n", 2.0*n*4/best/1e9);
    }
    return 0;
}
