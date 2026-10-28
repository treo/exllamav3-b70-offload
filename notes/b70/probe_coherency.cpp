// Who can see whom, through a shared page-locked region: the CPU's caches vs a B70 kernel's
// stores. probe_stores.cpp showed plain device stores landing; the cross-vendor probe showed the
// *same* pattern invisible - the difference is that there the host had just written those lines,
// so this isolates the three orderings:
//
//   R1 host writes 0, device writes values, host reads        (host cache lines are dirty)
//   R2 host never touches it, device writes values, host reads (cold lines)
//   R3 as R1, host reads after an explicit sfence + clflush
//   R4 device writes values, host writes 0, device reads back  (reverse: does the host's write
//                                                                reach the device's read?)
//   R5 host writes 0, DEVICE reads and reports, host reads too (who is stale, if anyone)
//
// Matters because the engine thread spins on a flag the 3090 wrote, and the parent reads a slot the
// B70 wrote: if either side can be served a stale copy, the protocol needs a fence on that side too.
//
// build: icpx -fsycl -O2 -o probe_coherency probe_coherency.cpp
#include <sycl/sycl.hpp>
#include <atomic>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <immintrin.h>
#include <sys/mman.h>

static const size_t W = 4096;

static int cmp(const uint32_t *a, uint32_t seed, size_t &bad, size_t &zero)
{
    bad = zero = 0;
    for (size_t i = 0; i < W; ++i)
        if (a[i] != seed + uint32_t(i)) { ++bad; if (a[i] == 0) ++zero; }
    return bad == 0;
}

int main()
{
    setvbuf(stdout, nullptr, _IONBF, 0);
    sycl::device dev{sycl::gpu_selector_v};
    sycl::context ctx{dev};
    sycl::queue q{ctx, dev, sycl::property::queue::in_order{}};

    void *p = nullptr;
    if (posix_memalign(&p, 4096, 1u << 20) || !p) return 1;
    memset(p, 0, 1u << 20);
    if (mlock(p, 1u << 20) != 0) printf("mlock failed (continuing)\n");
    sycl::ext::oneapi::experimental::register_host_memory(p, 1u << 20, ctx);
    uint32_t *base = (uint32_t *) p;
    printf("region %p, %zu words per trial, mlocked, registered with the SYCL context\n\n", p, W);

    auto trial = [&](const char *tag, size_t off, uint32_t seed, int mode)
    {
        uint32_t *a = base + off;
        size_t bad, zero;
        for (int rep = 0; rep < 3; ++rep)
        {
            if (mode != 1) memset(a, 0, W * 4);                    // dirty the host cache lines
            _mm_sfence();
            if (mode == 0 || mode == 2 || mode == 3 || mode == 4)
                q.parallel_for(W, [=](sycl::id<1> i) { a[i[0]] = seed + uint32_t(i[0]); });
            if (mode == 5)
            {
                // device reads what the host just zeroed and reports a fingerprint
                q.parallel_for(1, [=](sycl::id<1>) { a[W] = a[0] * 3u + a[W - 1] + 7u; });
            }
            q.wait();
            _mm_lfence();
            if (mode == 2) for (size_t i = 0; i < W; ++i) _mm_clflush((const char *) a + i * 4);
            if (mode == 3) { q.single_task([=] { sycl::atomic_fence(sycl::memory_order::acq_rel, sycl::memory_scope::system); }); q.wait(); }
            if (mode == 5)
            {
                uint32_t fp = *(volatile uint32_t *)((char *) a + W * 4);
                printf("  %-46s rep%d: device fingerprint %08x (host-zeroed input would give %08x, all-ones %08x)\n",
                       tag, rep, fp, 7u, 0x00000007u);
                continue;
            }
            bool ok = cmp(a, seed, bad, zero);
            printf("  %-46s rep%d: %s (%zu/%zu wrong, %zu zero)\n", tag, rep,
                   ok ? "ok" : "STALE/ZERO", bad, W, zero);
            seed += 0x10000u;
        }
    };

    trial("R1 host dirties, device stores, host reads", 1024, 0x11110000, 0);
    trial("R2 device stores into an area the host never touched", 2048, 0x22220000, 1);
    trial("R3 as R1 + host clflush before reading", 3072, 0x33330000, 2);
    trial("R4 as R1 + an empty fenced kernel before reading", 4096, 0x44440000, 3);
    trial("R5 host zeroes, device reads back a fingerprint", 5120, 0x55550000, 5);

    printf("\nreverse direction (device polls a flag the host writes):\n");
    {
        uint32_t *f = base + 8192;
        *f = 0;
        q.single_task([=] { *(volatile uint32_t *) f = 0xA11CE; });
        q.wait();
        printf("  host sees 0x%x after a device store to a line it owns [%s]\n", *f,
               *f == 0xA11CE ? "ok" : "STALE");
    }
    sycl::ext::oneapi::experimental::unregister_host_memory(p, ctx);
    munlock(p, 1u << 20);
    free(p);
    return 0;
}
