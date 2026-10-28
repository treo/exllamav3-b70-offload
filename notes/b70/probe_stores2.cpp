// Store visibility from a B70 kernel into host memory, isolated.
//
// The cross-vendor probe found a kernel whose *only* job is `p[i] = value` leaving the shared
// region untouched while a fenced single-word flag write next to it was visible. This narrows it
// down along the axes that could explain it: whether the host dirtied those lines first, whether a
// system fence follows the stores, whether the writing kernel is the first to touch the region
// after registration, and whether the pattern is intermittent (a race) or systematic (a policy).
//
// Areas are 64 KiB apart (an earlier revision overlapped them and produced pure noise).
//
// build: icpx -fsycl -O2 -o probe_stores2 probe_stores2.cpp
#include <sycl/sycl.hpp>
#include <atomic>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <immintrin.h>
#include <sys/mman.h>

static const size_t W = 4096;                      // 16 KiB per area, like a decode x payload

int main()
{
    setvbuf(stdout, nullptr, _IONBF, 0);
    sycl::device dev{sycl::gpu_selector_v};
    sycl::context ctx{dev};
    sycl::queue q{ctx, dev, sycl::property::queue::in_order{}};

    const size_t SZ = 1u << 22;
    void *p = nullptr;
    if (posix_memalign(&p, 4096, SZ) || !p) return 1;
    memset(p, 0, SZ);
    if (mlock(p, SZ) != 0) printf("mlock failed (continuing)\n");
    sycl::ext::oneapi::experimental::register_host_memory(p, SZ, ctx);
    uint32_t *base = (uint32_t *) p;
    printf("region %p (%zu MiB), %zu words per area, areas 16384 words apart\n\n", p, SZ >> 20, W);

    struct Case { const char *tag; int dirty_first; int fence_after; int vol; };
    const Case cases[] = {
        {"plain store, host dirtied lines first",  1, 0, 0},
        {"plain store, host lines cold",           0, 0, 0},
        {"plain store + fenced kernel after, cold",0, 1, 0},
        {"volatile store, host lines cold",        0, 0, 1},
        {"plain store + fence, host dirtied",      1, 1, 0},
    };

    int area = 0;
    for (const auto &c : cases)
    {
        uint32_t *a = base + size_t(area) * 16384;
        area++;
        size_t fails = 0, reps = 20;
        uint32_t firstbad0 = 0, firstbad1 = 0;
        for (size_t r = 0; r < reps; ++r)
        {
            uint32_t seed = 0xA5A50000u + uint32_t(r * 0x1000u);
            if (c.dirty_first) { memset(a, 0, W * 4); _mm_sfence(); }
            if (c.vol)
                q.parallel_for(W, [=](sycl::id<1> i) { ((volatile uint32_t *) a)[i[0]] = seed + uint32_t(i[0]); });
            else
                q.parallel_for(W, [=](sycl::id<1> i) { a[i[0]] = seed + uint32_t(i[0]); });
            if (c.fence_after)
                q.single_task([=] { sycl::atomic_fence(sycl::memory_order::acq_rel, sycl::memory_scope::system); });
            q.wait();
            _mm_lfence();
            size_t bad = 0;
            for (size_t i = 0; i < W; ++i) if (a[i] != seed + uint32_t(i)) { ++bad; if (bad == 1) { firstbad0 = a[0]; firstbad1 = a[1]; } }
            if (bad) ++fails;
        }
        printf("  %-44s %2zu/%zu reps wrong", c.tag, fails, reps);
        if (fails) printf("   (sample observed 0x%08x 0x%08x, written 0x%08x...)", firstbad0, firstbad1, 0xA5A50000u + uint32_t((reps - 1) * 0x1000u));
        printf("\n");
    }

    // Same, but writing through the *device-side* pointer obtained from a USM host allocation,
    // which is the other arrangement the engine could use.
    printf("\nusm host allocation (runtime-pinned) for reference:\n");
    {
        uint32_t *h = (uint32_t *) sycl::malloc_host(W * 4, q);
        size_t fails = 0, reps = 20;
        for (size_t r = 0; r < reps; ++r)
        {
            uint32_t seed = 0xBEEF0000u + uint32_t(r * 0x1000u);
            memset(h, 0, W * 4);
            q.parallel_for(W, [=](sycl::id<1> i) { h[i[0]] = seed + uint32_t(i[0]); });
            q.wait();
            size_t bad = 0;
            for (size_t i = 0; i < W; ++i) if (h[i] != seed + uint32_t(i)) ++bad;
            if (bad) ++fails;
        }
        printf("  %-44s %2zu/%zu reps wrong\n", "plain store into sycl::malloc_host", fails, reps);
        sycl::free(h, q);
    }

    // and through a USM *shared* allocation
    {
        uint32_t *sh = (uint32_t *) sycl::malloc_shared(W * 4, q);
        size_t fails = 0, reps = 20;
        for (size_t r = 0; r < reps; ++r)
        {
            uint32_t seed = 0xC0DE0000u + uint32_t(r * 0x1000u);
            memset(sh, 0, W * 4);
            q.parallel_for(W, [=](sycl::id<1> i) { sh[i[0]] = seed + uint32_t(i[0]); });
            q.wait();
            size_t bad = 0;
            for (size_t i = 0; i < W; ++i) if (sh[i] != seed + uint32_t(i)) ++bad;
            if (bad) ++fails;
        }
        printf("  %-44s %2zu/%zu reps wrong\n", "plain store into sycl::malloc_shared", fails, reps);
        sycl::free(sh, q);
    }

    sycl::ext::oneapi::experimental::unregister_host_memory(p, ctx);
    munlock(p, SZ);
    free(p);
    return 0;
}
