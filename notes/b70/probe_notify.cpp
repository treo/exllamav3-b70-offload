// Notification-path probe: every measurement completes by *polling a flag the device wrote*,
// because sycl::event::wait()/queue::wait() cost ~24 us on this stack while the same job
// notified through a pinned flag completes in ~3-5 us. That distinction decides the whole
// architecture of the B70 worker, so it is measured, not assumed.
//
// Job shapes measured (each is one host submission, or one doorbell to a parked kernel):
//   N1  empty kernel writes ack                     = submission + launch + notify floor
//   N2  kernel reads 4/16/256 KiB of pinned "x", writes checksum ack = zero-copy pull
//   N3  kernel writes 16 KiB to pinned "out"        = zero-copy push
//   N4  memcpy(D2H 16 KiB..32 MiB) then kernel ack  = DMA push + in-order notify
//   N5  memcpy(H2D ...) then kernel ack             = DMA pull
//   N6  parked kernel does N2+N3 in place           = the decode-handoff floor
//
// build: icpx -fsycl -O2 -o probe_notify probe_notify.cpp
#include <sycl/sycl.hpp>
#include <atomic>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <thread>
#include <vector>

using namespace std::chrono;
static double us() { return duration<double, std::micro>(steady_clock::now().time_since_epoch()).count(); }

static int dcmp(const void *a, const void *b) { double x = *(const double *) a, y = *(const double *) b; return x < y ? -1 : (x > y); }
struct S
{
    std::vector<double> v;
    void add(double x) { v.push_back(x); }
    double pct(double p)
    {
        if (v.empty()) return -1;
        std::vector<double> s = v;
        qsort(s.data(), s.size(), sizeof(double), dcmp);
        return s[size_t(p * (s.size() - 1) + 0.5)];
    }
    double med() { return pct(0.5); }
    double p90() { return pct(0.9); }
};

// 64-byte-grained control block in host-pinned memory
struct Ctl
{
    uint32_t *db, *ack, *quit, *beat, *out;
    void *base;
    void alloc(sycl::queue &q, size_t payload_words)
    {
        size_t bytes = 64 * 8 + payload_words * 4 + 64;
        base = sycl::malloc_host(bytes, q);
        db = (uint32_t *) base; ack = db + 16; quit = db + 32; beat = db + 48; out = db + 64;
    }
};

static inline uint32_t rd(volatile uint32_t *p)
{
    std::atomic_thread_fence(std::memory_order_seq_cst);
    uint32_t v = *p;
    std::atomic_thread_fence(std::memory_order_seq_cst);
    return v;
}
static inline void wr(volatile uint32_t *p, uint32_t v)
{
    std::atomic_thread_fence(std::memory_order_seq_cst);
    *p = v;
    std::atomic_thread_fence(std::memory_order_seq_cst);
}
// spin until *p >= want, bounded; returns false on timeout
static bool spin_ge(volatile uint32_t *p, uint32_t want, double budget_us = 2e6)
{
    double t = us();
    uint64_t spins = 0;
    while (rd(p) < want)
        if (++spins > 500'000'000ull || us() - t > budget_us) return false;
    return true;
}

int main()
{
    setvbuf(stdout, nullptr, _IONBF, 0);
    sycl::device dev{sycl::gpu_selector_v};
    sycl::context ctx{dev};
    sycl::queue q{ctx, dev, sycl::property::queue::in_order{}};   // in-order: the ack task really is last
    sycl::queue qr{ctx, dev};                                       // separate queue for the parked engine

    Ctl c; c.alloc(q, 1u << 20);              // 4 MiB of payload area after the control words
    uint32_t *pay = (uint32_t *) c.out + 16;   // leave a gap
    for (size_t i = 0; i < (1u << 18); ++i) pay[i] = uint32_t(i & 7);
    uint32_t *dv = (uint32_t *) sycl::malloc_device(64u << 20, q);
    q.memset(dv, 0, 64u << 20).wait();

    printf("== N1..N5: one submission per job, completion via pinned flag\n");
    printf("  %-46s %10s %10s %10s\n", "job", "med us", "p90 us", "GB/s");

    auto run = [&](const char *tag, size_t bytes, int iters, auto submit)
    {
        S s;
        for (int i = 1; i <= iters; ++i)
        {
            wr(c.ack, 0);
            double t = us();
            submit(uint32_t(i));
            if (!spin_ge(c.ack, 1)) { printf("  %-46s TIMEOUT at iter %d\n", tag, i); return; }
            s.add(us() - t);
        }
        printf("  %-46s %10.2f %10.2f %10.2f\n", tag, s.med(), s.p90(), bytes / s.med() / 1000.0);
    };

    run("N1 empty kernel -> ack", 0, 500, [&](uint32_t i)
    {
        q.single_task([=] { *(volatile uint32_t *) c.ack = 1u; });
        q.ext_oneapi_submit_barrier();
    });
    for (size_t kb : {4u << 10, 16u << 10, 256u << 10})
    {
        size_t words = kb / 4;
        char tag[64]; snprintf(tag, sizeof tag, "N2 kernel reads %zu KiB pinned, acks sum", kb >> 10);
        run(tag, kb, 300, [&](uint32_t i)
        {
            q.parallel_for(words, [=](sycl::id<1> ix)
            {
                volatile uint32_t *src = (volatile uint32_t *) pay;
                uint32_t v = src[ix[0]];
                if (v == 0xDEADBEEFu) *(volatile uint32_t *) c.ack = 1u;   // never true, keeps the load
                if (ix[0] == 0) *(volatile uint32_t *) c.out = v;
            });
            q.single_task([=] { *(volatile uint32_t *) c.ack = 1u; });
            q.ext_oneapi_submit_barrier();
        });
    }
    run("N3 kernel writes 16 KiB to pinned, acks", 16384, 300, [&](uint32_t i)
    {
        q.parallel_for(4096, [=](sycl::id<1> ix) { ((volatile uint32_t *) pay)[ix[0]] = 0x1234u + ix[0]; });
        q.single_task([=] { *(volatile uint32_t *) c.ack = 1u; });
        q.ext_oneapi_submit_barrier();
    });
    for (size_t mb : {16u << 10, 128u << 10, 1u << 20, 4u << 20})
    {
        char tag[64]; snprintf(tag, sizeof tag, "N4 D2H %zu B via DMA, then ack", mb);
        run(tag, mb, 200, [&](uint32_t i)
        {
            q.memcpy(pay, dv, mb);
            q.single_task([=] { *(volatile uint32_t *) c.ack = 1u; });
            q.ext_oneapi_submit_barrier();
        });
        snprintf(tag, sizeof tag, "N5 H2D %zu B via DMA, then ack", mb);
        run(tag, mb, 200, [&](uint32_t i)
        {
            q.memcpy(dv, pay, mb);
            q.single_task([=] { *(volatile uint32_t *) c.ack = 1u; });
            q.ext_oneapi_submit_barrier();
        });
    }

    // N6 (parked kernel handling a decode-shaped payload) moved to probe_resident.cpp, where the
    // polling is SIMD-uniform (one lane per sub-group + system fence) and it actually completes.
    // The version here branched on local id and never acked - see LESSONS.md.

    printf("done\n");
    return 0;
}