// Which store pattern actually reaches host memory?  [SUPERSEDED for rows 1-6; KEEP for case 7]
//
// Case 7 is the deliberate device-loss repro: a `sycl::atomic_ref` at *device* scope on a
// `register_host_memory` pointer brings the whole device down
// (`level_zero backend failed with error: 20 (UR_RESULT_ERROR_DEVICE_LOST)`), which is why the run
// aborts after it. Rows 1-6 of this file are unreliable - the trial areas were laid out 1024 words
// apart while each is 4096 words long, so they overlapped; probe_stores2.cpp is the corrected
// version (areas 64 KiB apart, 20 reps each, all plain-store patterns visible).
//
// Found while wiring the cross-vendor probes: a kernel that *read-modify-writes* a registered
// foreign host region shows its result to the host, and a `single_task` that publishes a flag
// between two system fences shows its result, but a `parallel_for` whose only job is
// `p[i] = value` left the whole 16 KiB region at zero - in the same process and across processes.
// That is the silent-corruption class of bug (the parent would just add zeroes), so the store
// flavours are isolated here, with no CUDA in the picture, on a mlock'ed anon mapping registered
// with the SYCL context.
//
// build: icpx -fsycl -O2 -o probe_stores probe_stores.cpp
#include <sycl/sycl.hpp>
#include <atomic>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <sys/mman.h>

static uint32_t *g_reg = nullptr;      // registered base
static size_t g_sz = 1u << 20;

static void verify(const char *tag, uint32_t *area, uint32_t seed, size_t words, size_t skip)
{
    size_t bad = 0, zero = 0;
    for (size_t i = 0; i < words; ++i)
    {
        uint32_t want = seed + uint32_t(i);
        if (area[i] != want) { ++bad; if (area[i] == 0) ++zero; }
    }
    printf("  %-52s %s  (%zu/%zu wrong, %zu of them still zero)%s\n", tag, bad ? "FAIL" : "ok",
           bad, words, zero, skip ? " [first word excluded from the pattern]" : "");
}

int main()
{
    setvbuf(stdout, nullptr, _IONBF, 0);
    sycl::device dev{sycl::gpu_selector_v};
    sycl::context ctx{dev};
    sycl::queue q{ctx, dev, sycl::property::queue::in_order{}};

    void *p = nullptr;
    if (posix_memalign(&p, 4096, g_sz) || !p) return 1;
    memset(p, 0, g_sz);
    if (mlock(p, g_sz) != 0) printf("mlock failed (continuing)\n");
    sycl::ext::oneapi::experimental::register_host_memory(p, g_sz, ctx);
    uint32_t *base = (uint32_t *) p;
    const size_t W = 4096;
    printf("registered %p, %zu pages, payload %zu words\n\n", p, g_sz >> 12, W);

    auto round = [&](const char *tag, size_t off_words, auto launch)
    {
        uint32_t *area = base + off_words;
        memset(area, 0, W * 4);
        std::atomic_thread_fence(std::memory_order_seq_cst);
        launch(area);
        q.wait();
        std::atomic_thread_fence(std::memory_order_seq_cst);
        verify(tag, area, 0xABCD0000u + uint32_t(off_words), W, 0);
    };

    round("1 plain store, no fence", 1024, [&](uint32_t *a)
    {
        q.parallel_for(W, [=](sycl::id<1> i) { a[i[0]] = 0xABCD0000u + 1024u + uint32_t(i[0]); });
    });
    round("2 plain store, then in-kernel system fence", 2048, [&](uint32_t *a)
    {
        q.parallel_for(W, [=](sycl::id<1> i) { a[i[0]] = 0xABCD0000u + 2048u + uint32_t(i[0]); });
        q.single_task([=] { sycl::atomic_fence(sycl::memory_order::acq_rel, sycl::memory_scope::system); });
    });
    round("3 volatile store", 3072, [&](uint32_t *a)
    {
        q.parallel_for(W, [=](sycl::id<1> i) { ((volatile uint32_t *) a)[i[0]] = 0xABCD0000u + 3072u + uint32_t(i[0]); });
    });
    round("4 read-modify-write (the pattern that appeared to work)", 4096, [&](uint32_t *a)
    {
        q.parallel_for(W, [=](sycl::id<1> i) { a[i[0]] += 0xABCD0000u + 4096u + uint32_t(i[0]); });
    });
    round("5 plain store from a single_task loop", 5120, [&](uint32_t *a)
    {
        q.single_task([=] { for (size_t i = 0; i < W; ++i) a[i] = 0xABCD0000u + 5120u + uint32_t(i); });
    });
    round("6 fence before and after, same kernel (group-wide)", 6144, [&](uint32_t *a)
    {
        q.parallel_for(sycl::range<1>(W), [=](sycl::id<1> ix)
        {
            sycl::atomic_fence(sycl::memory_order::acq_rel, sycl::memory_scope::system);
            a[ix[0]] = 0xABCD0000u + 6144u + uint32_t(ix[0]);
            sycl::atomic_fence(sycl::memory_order::acq_rel, sycl::memory_scope::system);
        });
    });
    round("7 sycl::atomic_ref device-scope store", 7168, [&](uint32_t *a)
    {
        q.parallel_for(W, [=](sycl::id<1> ix)
        {
            sycl::atomic_ref<uint32_t, sycl::memory_order::relaxed, sycl::memory_scope::device,
                             sycl::access::address_space::global_space> r(a[ix[0]]);
            r.store(0xABCD0000u + 7168u + uint32_t(ix[0]), sycl::memory_order::relaxed);
        });
    });
    round("8 plain store + explicit sycl::_fence (async) via barrier", 8192, [&](uint32_t *a)
    {
        q.parallel_for(W, [=](sycl::id<1> ix) { a[ix[0]] = 0xABCD0000u + 8192u + uint32_t(ix[0]); });
        q.single_task([=] { *(volatile uint32_t *) base = 0x1234u; });   // a later write to the same page
    });

    // ordering question: is it the *first* kernel after registration, or the pattern?
    printf("\nrepeat of pattern 1 (plain store, no fence):\n");
    for (int r = 0; r < 3; ++r)
        round(r == 0 ? "  1st repeat" : r == 1 ? "  2nd repeat" : "  3rd repeat", 9216, [&](uint32_t *a)
        {
            uint32_t seed = 0xABCD0000u + 9216u;
            q.parallel_for(W, [=](sycl::id<1> i) { a[i[0]] = seed + uint32_t(i[0]); });
        });

    sycl::ext::oneapi::experimental::unregister_host_memory(p, ctx);
    munlock(p, g_sz);
    free(p);
    return 0;
}
