// Hypothesis for the "payload vanished, flag survived" observations: tearing the mapping down with
// unregister_host_memory right after wait() drops device writes that had not reached system memory,
// while a store that was system-fenced before it survives. Register once, write, unregister, read.
#include <sycl/sycl.hpp>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <sys/mman.h>
static const unsigned long W = 4096;
int main()
{
    setvbuf(stdout, nullptr, _IONBF, 0);
    sycl::device dev{sycl::gpu_selector_v};
    sycl::context ctx{dev};
    sycl::queue q{ctx, dev, sycl::property::queue::in_order{}};
    void *p = nullptr; posix_memalign(&p, 4096, 1u << 20); memset(p, 0, 1u << 20); mlock(p, 1u << 20);
    uint32_t *a = (uint32_t *) p;

    auto run = [&](const char *tag, int fence_flag, int unregister_before_read)
    {
        memset(p, 0, 1u << 20);
        sycl::ext::oneapi::experimental::register_host_memory(p, 1u << 20, ctx);
        q.parallel_for(W, [=](sycl::id<1> i) { a[i[0]] = 0xC0FFEE00u + uint32_t(i[0]); });
        if (fence_flag)
            q.single_task([=] { sycl::atomic_fence(sycl::memory_order::acq_rel, sycl::memory_scope::system);
                                *(volatile uint32_t *)((char *) p + W * 4) = 0x1234u; });
        q.wait();
        if (unregister_before_read) sycl::ext::oneapi::experimental::unregister_host_memory(p, ctx);
        size_t bad = 0;
        for (unsigned long i = 0; i < W; ++i) if (a[i] != 0xC0FFEE00u + uint32_t(i)) ++bad;
        uint32_t flag = *(volatile uint32_t *)((char *) p + W * 4);
        if (!unregister_before_read) sycl::ext::oneapi::experimental::unregister_host_memory(p, ctx);
        printf("  %-52s payload %4zu/%lu wrong, flag 0x%x\n", tag, bad, W, flag);
    };
    run("fenced flag, unregister AFTER read",            1, 0);
    run("fenced flag, unregister BEFORE read",           1, 1);
    run("no flag, unregister AFTER read",                0, 0);
    run("no flag, unregister BEFORE read",               0, 1);
    munlock(p, 1u << 20); free(p);
    return 0;
}
