// Resident-engine sizing probe.
//
// The first attempt at a parked kernel (32 work-groups x 32 lanes, every lane polling a
// host-pinned doorbell with a fence per iteration) never completed a round trip in 2 s: ~1k lanes
// hammering PCIe read transactions starve the link that carries the actual payload. Only one lane
// per group may poll, and it must back off. This measures the resulting cost, as a function of
// group count and poll backoff, with a decode-shaped payload (16 KiB in, 10 KiB out).
//
// build: icpx -fsycl -O2 -o probe_resident probe_resident.cpp
// run:   ./probe_resident [groups] [lanes_per_group] [backoff_iters] [payload_words]
#include <sycl/sycl.hpp>
#include <atomic>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <thread>
#include <vector>

using namespace std::chrono;
static double us() { return duration<double, std::micro>(steady_clock::now().time_since_epoch()).count(); }
static int dcmp(const void *a, const void *b) { double x = *(const double *) a, y = *(const double *) b; return x < y ? -1 : (x > y); }
struct S { std::vector<double> v; void add(double x){v.push_back(x);} double pct(double p){ if(v.empty()) return -1; std::vector<double> s=v; qsort(s.data(), s.size(), sizeof(double), dcmp); return s[size_t(p*(s.size()-1)+0.5)]; } double med(){return pct(0.5);} double p90(){return pct(0.9);} };

static inline uint32_t rd(volatile uint32_t *p) { std::atomic_thread_fence(std::memory_order_seq_cst); uint32_t v = *p; std::atomic_thread_fence(std::memory_order_seq_cst); return v; }
static inline void wr(volatile uint32_t *p, uint32_t v) { std::atomic_thread_fence(std::memory_order_seq_cst); *p = v; std::atomic_thread_fence(std::memory_order_seq_cst); }

int main(int argc, char **argv)
{
    setvbuf(stdout, nullptr, _IONBF, 0);
    const uint32_t groups = argc > 1 ? uint32_t(atoi(argv[1])) : 32;
    const uint32_t lanes = argc > 2 ? uint32_t(atoi(argv[2])) : 16;
    const uint64_t backoff = argc > 3 ? uint64_t(atoll(argv[3])) : 2000;
    const uint32_t in_words = argc > 4 ? uint32_t(atoi(argv[4])) : 4096;
    const uint32_t out_words = 2560;

    sycl::device dev{sycl::gpu_selector_v};
    sycl::context ctx{dev};
    sycl::queue q{ctx, dev};

    const size_t pb = 1u << 22;
    uint32_t *host = (uint32_t *) sycl::malloc_host(pb + 1024, q);
    uint32_t *db = host, *ack = host + 16, *quit = host + 32, *stat = host + 48, *pay = host + 64;
    for (size_t i = 0; i < pb / 4; ++i) pay[i] = uint32_t(i & 15);
    uint32_t *devstat = (uint32_t *) sycl::malloc_host(64, q);
    uint32_t *go_dev = (uint32_t *) sycl::malloc_device(64 * 4, q);   // device-local wake word per group
    q.memset(go_dev, 0, 64 * 4).wait();
    wr(db, 0); wr(ack, 0); wr(quit, 0); wr(stat, 0); *devstat = 0;
    q.memset((void *) pay, 0, 0);   // touch nothing else

    printf("groups %u lanes %u backoff %llu in %u words (poller only) out %u\n",
           groups, lanes, (unsigned long long) backoff, in_words, out_words);
    printf("  %-52s %8s %8s %8s\n", "resident config", "med us", "p90 us", "jobs/s");

    q.submit([&](sycl::handler &cgh)
    {
        cgh.parallel_for(sycl::nd_range<1>(sycl::range<1>(size_t(groups) * lanes), sycl::range<1>(lanes)),
            [=](sycl::nd_item<1> it) [[sycl::reqd_sub_group_size(16)]]
            {
                // UNIFORM control flow: on Xe every lane of a sub-group runs the same loop; only
                // lane 0 touches the link, and its read is broadcast with a shuffle. The first
                // version branched on local id (leader polls, followers spin elsewhere) and never
                // completed a single round trip - divergent lanes in one hardware thread.
                auto sg = it.get_sub_group();
                const uint32_t wg = uint32_t(it.get_group(0));
                uint32_t *ackp = ack;
                sycl::atomic_ref<uint32_t, sycl::memory_order::acq_rel, sycl::memory_scope::system,
                                 sycl::access::address_space::global_space> aack(*ackp);
                volatile uint32_t *pin = (volatile uint32_t *) pay;
                const uint32_t sl = sg.get_local_id()[0];
                if (sl == 0 && wg == 0) *(volatile uint32_t *) stat = 0xBEEF;   // entry marker
                uint32_t last = sl == 0 ? *(volatile uint32_t *) db : 0;
                last = sycl::select_from_group(sg, last, uint32_t(0));
                for (uint64_t outer = 0; outer < 3'000'000ull; ++outer)
                {
                    uint32_t cur = sl == 0 ? *(volatile uint32_t *) db : 0;
                    // the fence, not "volatile", is what makes a parked kernel see a host write:
                    // without it the read is served from a stale GPU cache line forever
                    sycl::atomic_fence(sycl::memory_order::acq_rel, sycl::memory_scope::system);
                    cur = sycl::select_from_group(sg, cur, uint32_t(0));
                    if (cur != last)
                    {
                        last = cur;
                        if (cur == 0xFFFFFFFFu) return;
                        // payload spread across the sub-group: each lane strides, so the 16 KiB
                        // arrives as in-flight parallel reads, not a dependent chain
                        uint32_t acc = 0;
                        const uint32_t nth = uint32_t(sg.get_local_range().size());
                        for (uint32_t i = sl; i < in_words; i += nth) acc += pin[i];
                        volatile uint32_t *pout = pin + (1u << 19);
                        for (uint32_t i = sl; i < out_words; i += nth) pout[i] = acc;
                        for (uint32_t o = 1; o < nth; o <<= 1) acc += sycl::select_from_group(sg, acc, (sl + o) % nth);
                        sycl::atomic_fence(sycl::memory_order::acq_rel, sycl::memory_scope::system);
                        // uniform call site: a divergent system-scope atomic on host memory was
                        // the thing that made the first versions never ack
                        aack.fetch_add(sl == 0 ? 1u : 0u, sycl::memory_order::acq_rel);
                    }
                    uint32_t qf = sl == 0 ? *(volatile uint32_t *) quit : 0;
                    qf = sycl::select_from_group(sg, qf, uint32_t(0));
                    if (qf) return;
                    if (sl == 0 && wg == 0 && (outer & 0xFFFF) == 0) *(volatile uint32_t *) stat = 0xBEE0u + uint32_t(outer >> 16);
                    uint32_t x = uint32_t(outer) | 1u;
                    for (uint64_t b = 0; b < backoff; ++b) x = x * 1664525u + 1013904223u;
                    if (x == 0xDEADBEEFu) *(volatile uint32_t *) stat = 1;
                }
                if (sl == 0) *(volatile uint32_t *) stat = 0xDEAD;
            });
    });
    q.ext_oneapi_submit_barrier();
    std::this_thread::sleep_for(std::chrono::milliseconds(30));
    printf("  entry/heartbeat marker: 0x%x (0xBEEF = started, parked; 0 = never ran)\n", rd(stat));

    S s; bool ok = true;
    uint32_t i = 1;
    for (; i <= 300; ++i)
    {
        wr(ack, 0);
        double t = us();
        wr(db, i);
        uint64_t spins = 0;
        while (rd(ack) < groups) if (++spins > 1'000'000'000ull) { ok = false; break; }
        double d = us() - t;
        s.add(d);
        if (!ok || d > 5e5) { ok = false; break; }
    }
    printf("  %-52s %8.2f %8.2f %8.0f  [%s] rounds %u\n", "doorbell + payload, all groups ack",
           s.med(), s.p90(), s.med() > 0 ? 1e6 / s.med() : -1, ok ? "ok" : "TIMEOUT/SLOW", i);
    wr(quit, 1);
    wr(db, 0xFFFFFFFFu);
    double tq = us();
    while (true) { try { q.wait(); break; } catch (...) { break; } if (us() - tq > 10e6) { printf("WEDGED\n"); return 3; } }
    printf("  %-52s %.0f us to drain\n", "resident kernel exit", us() - tq);
    return 0;
}