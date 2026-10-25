#include <sycl/sycl.hpp>
#include <cstdio>
int main() {
    sycl::queue q{sycl::gpu_selector_v};
    auto d = q.get_device();
    printf("%s\n", d.get_info<sycl::info::device::name>().c_str());
    printf("global mem total %.2f GB, size %.2f GB\n",
        d.get_info<sycl::info::device::global_mem_size>() / 1e9,
        d.get_info<sycl::info::device::global_mem_size>() / 1e9);
    size_t maxalloc = d.get_info<sycl::info::device::max_mem_alloc_size>();
    printf("max single alloc %.2f GB\n", maxalloc / 1e9);
    // try allocating 168MB
    for (int i = 0; i < 40; ++i) {
        void* p = sycl::malloc_device(168u << 20, q);
        if (!p) { printf("FAILED at alloc #%d\n", i + 1); break; }
    }
    printf("40x168MB ok? (leaked, process exits)\n");
    return 0;
}
