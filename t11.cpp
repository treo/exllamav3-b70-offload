#include <sycl/sycl.hpp>
#include <cstdio>
int main() {
    sycl::queue q{sycl::gpu_selector_v};
    int* r = sycl::malloc_device<int>(1, q);
    q.single_task([=] {
        sycl::ext::oneapi::uchar8_t a{1, 2, 3, 4};
        sycl::ext::oneapi::schar8_t b{10, 20, 30, 40};
        *r = sycl::ext::oneapi::dot_product(a, b, 0);   // expect 1*10+2*20+3*30+4*40=300
    }).wait();
    int h; q.memcpy(&h, r, 4).wait();
    printf("dp4a result %d (expect 300)\n", h);
    return 0;
}
