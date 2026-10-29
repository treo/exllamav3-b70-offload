// devinfo.cpp - cache hierarchy of the B70, for sizing what a "prepare once" cache could ever hold.
#include <sycl/sycl.hpp>
#include <cstdio>

int main()
{
    sycl::device d{sycl::gpu_selector_v};
    const double M = 1048576.0;
    printf("global memory        : %.1f MiB\n", d.get_info<sycl::info::device::global_mem_size>() / M);
    printf("local (SLM) / group  : %.1f KiB\n", d.get_info<sycl::info::device::local_mem_size>() / 1024.0);
    printf("global cache (L2)    : %.1f MiB\n", d.get_info<sycl::info::device::global_mem_cache_size>() / M);
    printf("max compute units    : %d\n", d.get_info<sycl::info::device::max_compute_units>());
    return 0;
}