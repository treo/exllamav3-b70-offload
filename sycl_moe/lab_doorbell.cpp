// lab_doorbell.cpp — persistent-kernel feasibility: what does ONE round trip cost on the B70?
//
// Why (see NOTES lever 1/1b): the model's decode forward is p50 66.1 us, of which 27.2 us is the
// parent thread ENQUEUEING 5 commands and 28.6 us is blocked waiting for them. Per action, that
// cost is irreducible by API choice (lab_submit_busy: 2.6-3.5 us flat across 15 regimes, including
// the handler-free nd_launch path), graphs (replay costs MORE than the chain), and fusion
// (CoopGuK: a wash). The only design left is to stop enqueuing per layer: one resident kernel that
// waits on a pinned doorbell, runs the job, posts completion, and waits again.
//
// Go/no-go is decided by the round-trip floor, NOT by elegance:
//   RTT = host store -> device observes doorbell -> (fan out to N WGs) -> work -> fan in
//         -> device store to sysmem -> host observes completion
// If that floor is ~10 us, decode's 57.6 us of fixed cost per forward mostly disappears (~2 ms of a
// 14.7 ms token). If it is ~40 us, the design is dead and this file is its tombstone.
//
// Modes (all measured as RTT percentiles over many pings, host-side clocks only):
//   0  1 WG, trivial work                       pure mailbox<->mailbox latency
//   1  NW WGs, device-flag fan-out + arrive-count fan-in, trivial work
//                                              the realistic trigger path for a full-grid job
//   2  as 1 + FMA spin of TRIP iterations       adds a known device-work delay
//   3  as 1 + read TOUCH_MB across WGs         adds weight-like DRAM traffic
//   4  as 0 but the mailbox loop backs off      what a polite spinner costs in latency
// Plus: does a resident spinner STARVE other work? Times a 16 MB bandwidth kernel on a second
// queue with no spinner, with a mode-0 spinner, and with a mode-1 (256 WG) spinner.
//
// Safety: every device spin is bounded (SPIN_MAX) and self-exits; the host pings have a deadline
// and always post quit before q.wait(), so a broken assumption prints a failure instead of hanging.
//   icpx -fsycl -O2 lab_doorbell.cpp -o lab_doorbell && ./lab_doorbell [NWG] [TRIP] [TOUCH_MB]
#include <sycl/sycl.hpp>
#include <algorithm>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <immintrin.h>
#include <vector>

struct Mailbox {                       // lives in PINNED host memory
    alignas(64) volatile unsigned seq;         // host -> device: job id (doorbell)
    alignas(64) volatile unsigned done;        // device -> host: completed job id
    alignas(64) volatile unsigned quit;        // host -> device: shut down
    alignas(64) volatile unsigned seen;        // device -> host: how many WGs woke (diagnostic)
    alignas(64) volatile int payload[8];       // stand-in for the job blob
};

// Bail bounds. The SYSMEM poller must bound tightly: each poll is a PCIe round trip (~1.5-2 us),
// so a large bound means an ABANDONED kernel (host killed, crash, Ctrl-C) keeps an EU busy for
// minutes and poisons every later run on the box. The device-flag poller is cheap, so it can be
// generous. Both report failure by never publishing `done`, which the host treats as "not resident".
static constexpr long SPIN_MAX_SYS = 1'500'000L;   // ~3 s of sysmem polls; a crash safety net only
static constexpr long SPIN_MAX_DEV = 20'000'000L;  // device-memory polls are ~100x cheaper
// POLLED doorbell style: 1 = atomic RMW (correct), 0 = acquire load (caches, goes deaf).
#ifndef POLL_SYS
#define POLL_SYS 1
#endif
static constexpr bool POLL_SYS_B = (POLL_SYS != 0);
// Ping count per mode. Percentiles over ~10 surviving samples are meaningless, so the lab prints
// the sample count next to them.
static constexpr int NPING = 400;
static constexpr unsigned QUIT = 0xFFFFFFFFu;

static double now_us() {
    return std::chrono::duration<double, std::micro>(
        std::chrono::steady_clock::now().time_since_epoch()).count();
}

// sycl::atomic_ref rejects acquire/release as its DEFAULT order (relaxed/acq_rel/seq_cst only), so
// the reference is declared relaxed and the order is passed per operation. This implementation also
// spells the space `sycl::access::address_space`, not `sycl::address_space`.
template <sycl::memory_scope S>
static inline unsigned ld_acq(const volatile unsigned* p) {
    return sycl::atomic_ref<unsigned, sycl::memory_order::relaxed, S,
                            sycl::access::address_space::global_space>(
        *const_cast<unsigned*>(p)).load(sycl::memory_order::acquire);
}
template <sycl::memory_scope S>
static inline unsigned ld_rlx(const volatile unsigned* p) {
    return sycl::atomic_ref<unsigned, sycl::memory_order::relaxed, S,
                            sycl::access::address_space::global_space>(
        *const_cast<unsigned*>(p)).load();
}
template <sycl::memory_scope S>
static inline void st_rel(volatile unsigned* p, unsigned v) {
    sycl::atomic_ref<unsigned, sycl::memory_order::relaxed, S,
                     sycl::access::address_space::global_space>(*const_cast<unsigned*>(p))
        .store(v, sycl::memory_order::release);
}
// A doorbell read MUST be a real atomic RMW, not an acquire load. `atomic_ref::load(acquire)` is
// legally lowered to a plain load + fence, and a plain load of sysmem can be served from the GPU's
// cache - which is exactly what the first version of this lab did: the first ~9 pings worked at
// ~3 us, then the resident kernel went deaf forever (pings all timed out). `add 0` forces an
// uncached atomic to the coherence point.
template <sycl::memory_scope S>
static inline unsigned rmw0(volatile unsigned* p) {
    return sycl::atomic_ref<unsigned, sycl::memory_order::acq_rel, S,
                            sycl::access::address_space::global_space>(*const_cast<unsigned*>(p))
        .fetch_add(0u);
}

struct Persist {
    Mailbox* mb;
    unsigned* trig;        // device memory: fan-out flag
    unsigned* arrive;      // device memory: fan-in counter
    float* buf;
    size_t bufsz;
    unsigned nwgs;
    int mode;
    long trip;
    size_t touch;          // floats to read in mode 3

    void operator()(sycl::nd_item<1> it) const {
        const unsigned wg = (unsigned)it.get_group(0);
        if (it.get_local_id(0) != 0) return;      // one lane per WG drives the protocol

        unsigned last = 0;
        for (;;) {
            unsigned s = 0;
            long spins = 0;
            if (wg == 0) {
                // Mailbox WG: watch sysmem. Back off in mode 4.
                do {
                    s = POLL_SYS_B ? rmw0<sycl::memory_scope::system>(const_cast<unsigned*>(&mb->seq))
                                 : ld_acq<sycl::memory_scope::system>(&mb->seq);
                    if (s == QUIT) {
                        st_rel<sycl::memory_scope::device>(trig, QUIT);
                        st_rel<sycl::memory_scope::system>(&mb->done, QUIT);
                        return;
                    }
                    if (++spins > SPIN_MAX_SYS) return;
                    if (mode == 4) { volatile int z = 0; for (long b = 0; b < 3000; ++b) z += (int)b; }
                } while (s == last);
                st_rel<sycl::memory_scope::device>(trig, s);
            } else {
                do {
                    // Same rule as the sysmem doorbell: a cross-agent flag must be read with an
                    // atomic RMW. As an acquire LOAD this stalled the two-level mode permanently -
                    // one WG never saw the new trig value, so its group counter never completed and
                    // `done` was never published.
                    s = rmw0<sycl::memory_scope::device>(trig);
                    if (s == QUIT) return;
                    if (++spins > SPIN_MAX_DEV) return;
                    if (s != last) break;
                } while (s == last);
            }
            last = s;

            // ---- the job
            if (mode == 2 || (mode == 3 && false)) {
                float a = (float)(wg + 1);
                for (long k = 0; k < trip; ++k) a = sycl::fma(a, 1.0000001f, 1e-8f);
                buf[(wg * 37u + 11u) & 4095u] = a;
            }
            if (mode == 3) {
                const size_t per = touch / (nwgs ? nwgs : 1);
                const size_t base = (size_t)wg * per;
                float acc = 0.f;
                for (size_t i = 0; i < per; ++i) acc += buf[base + i];
                buf[base] = acc;
            }

            // ---- completion
            if (mode == 5) {
                // Two-level fan-in: GROUP WGs share one counter, each group leader arrives on the
                // master. Turns O(nwgs) serialized RMWs into O(nwgs/GROUP + GROUP). Requires
                // nwgs % GROUP == 0 (the sweep only uses multiples).
                constexpr unsigned GROUP = 8;
                const unsigned g = wg / GROUP, lane_in_g = wg % GROUP;
                const unsigned gsz = nwgs / GROUP;
                unsigned* gcnt = arrive + 1 + g;          // arrive[0] is the master
                const unsigned prev =
                    sycl::atomic_ref<unsigned, sycl::memory_order::acq_rel, sycl::memory_scope::device,
                                     sycl::access::address_space::global_space>(*gcnt).fetch_add(1u);
                if (prev == GROUP - 1) {
                    sycl::atomic_ref<unsigned, sycl::memory_order::relaxed, sycl::memory_scope::device,
                                     sycl::access::address_space::global_space>(*gcnt).store(0u);
                    const unsigned p2 =
                        sycl::atomic_ref<unsigned, sycl::memory_order::acq_rel, sycl::memory_scope::device,
                                         sycl::access::address_space::global_space>(*arrive).fetch_add(1u);
                    if (p2 == gsz - 1) {
                        sycl::atomic_ref<unsigned, sycl::memory_order::relaxed, sycl::memory_scope::device,
                                         sycl::access::address_space::global_space>(*arrive).store(0u);
                        st_rel<sycl::memory_scope::system>(&mb->done, s);
                    }
                }
                (void)lane_in_g;
            } else if (nwgs <= 1) {
                st_rel<sycl::memory_scope::system>(&mb->done, s);
            } else {
                const unsigned prev =
                    sycl::atomic_ref<unsigned, sycl::memory_order::acq_rel, sycl::memory_scope::device,
                                     sycl::access::address_space::global_space>(*arrive).fetch_add(1u);
                if (prev == nwgs - 1) {
                    sycl::atomic_ref<unsigned, sycl::memory_order::relaxed, sycl::memory_scope::device,
                                     sycl::access::address_space::global_space>(*arrive).store(0u);
                    st_rel<sycl::memory_scope::system>(&mb->done, s);
                }
            }
        }
    }
};

// Bounded event wait: a resident kernel that fails to observe quit must not strand the lab.
static bool wait_bounded(sycl::event& e, double ms) {
    const double t0 = now_us();
    while (e.get_info<sycl::info::event::command_execution_status>() !=
           sycl::info::event_command_status::complete) {
        if (now_us() - t0 > ms * 1e3) return false;
        _mm_pause();
    }
    return true;
}

int main(int argc, char** argv) {
    setvbuf(stdout, nullptr, _IONBF, 0);   // a hung lab must still tell us where it hung
    const unsigned NWG = argc > 1 ? (unsigned)atoi(argv[1]) : 256;
    const long TRIP = argc > 2 ? atol(argv[2]) : 20000;
    const size_t TOUCH = (argc > 3 ? (size_t)atoi(argv[3]) : 3) << 20;   // floats
    sycl::device dev{sycl::gpu_selector_v};
    printf("device %s | %u compute units | NWG %u TRIP %ld TOUCH %.1f MB\n\n",
           dev.get_info<sycl::info::device::name>().c_str(),
           dev.get_info<sycl::info::device::max_compute_units>(), NWG, TRIP, TOUCH * 4 / 1e6);

    sycl::context ctx{dev};
    sycl::queue q{ctx, dev, sycl::property::queue::in_order{}};         // hosts the resident kernel
    sycl::queue q2{ctx, dev, sycl::property::queue::in_order{}};        // "someone else's" work

    Mailbox* mb = (Mailbox*)sycl::malloc_host(sizeof(Mailbox), ctx);
    memset((void*)mb, 0, sizeof(Mailbox));
    unsigned* trig = sycl::malloc_device<unsigned>(4, q);
    unsigned* arrive = sycl::malloc_device<unsigned>(64, q);
    const size_t bufsz = 16u << 20;                                     // 64 MB
    float* buf = sycl::malloc_device<float>(bufsz, q);
    q.fill(buf, 0.001f, bufsz).wait();
    q.memset(trig, 0, 4).wait(); q.memset(arrive, 0, 4).wait();
    q2.wait();

    auto ping = [&](unsigned want) -> double {
        mb->payload[0] = (int)want;
        __atomic_store_n((unsigned*)&mb->seq, want, __ATOMIC_RELEASE);
        const double t0 = now_us();
        for (;;) {
            const unsigned d = __atomic_load_n((unsigned*)&mb->done, __ATOMIC_ACQUIRE);
            // LEVEL-triggered, not equality: if the device ever coalesces two doorbells (it polls
            // at ~2 us and the host can post faster), it publishes only the later id, and an
            // equality test would stall 20 ms waiting for an id that will never appear. Signed
            // distance so wrap-around is safe. This is a real protocol requirement for the design.
            if (d == QUIT) return -2.0;
            if ((int)(d - want) >= 0) return now_us() - t0;
            if (now_us() - t0 > 100000.0) return -1.0;      // 100 ms ceiling: slow cases get timed,
                                                             // not just counted as misses
            _mm_pause();
        }
    };

    // Mode 6's trigger: one 4-byte H2D copy per job (that command's host cost IS part of the
    // round trip - that is the whole point of the measurement).
    unsigned* hseq = (unsigned*)sycl::malloc_host(4, ctx);
    auto ping_dev = [&](unsigned want) -> double {
        *hseq = want;
        const double t0 = now_us();
        q2.memcpy(trig, hseq, 4);
        for (;;) {
            const unsigned d = __atomic_load_n((unsigned*)&mb->done, __ATOMIC_ACQUIRE);
            if (d == QUIT) return -2.0;
            if ((int)(d - want) >= 0) return now_us() - t0;
            if (now_us() - t0 > 100000.0) return -1.0;
            _mm_pause();
        }
    };

    // Interference probe: a 16 MB fill on the SECOND queue, measured WHILE the spinner is resident,
    // to answer the other half of the feasibility question - a permanently spinning kernel must not
    // starve the prefill path that keeps using ordinary submits.
    auto interfere = [&](const char* tag) {
        double best = 1e30;
        for (int w = 0; w < 3; ++w) {
            const double t0 = now_us();
            for (int i = 0; i < 50; ++i) q2.fill(buf, 0.002f, 4u << 20).wait();
            best = std::min(best, (now_us() - t0) / 50);
        }
        printf("  %-46s %7.1f us per 16 MB fill on a second queue\n", tag, best);
    };

    auto run_mode = [&](int mode, unsigned nwgs, const char* nm, const char* probe_tag) {
        sycl::event resident;
        if (nwgs == 0) { printf("  %-46s (no spinner resident)\n", nm); interfere(probe_tag); return; }
        else {
            const size_t touch = mode == 3 ? TOUCH : 0;
            Persist p{mb, trig, arrive, buf, bufsz, nwgs, mode, TRIP, touch};
            // Reset BOTH mailboxes: a stale trig would make the fresh kernel run a phantom job and
            // publish a done id the host never asked for.
            __atomic_store_n((unsigned*)&mb->seq, 0u, __ATOMIC_RELAXED);
            __atomic_store_n((unsigned*)&mb->done, 0u, __ATOMIC_RELAXED);
            __atomic_store_n((unsigned*)&mb->quit, 0u, __ATOMIC_RELAXED);
            printf("   [step: clearing device flags]\n"); fflush(stdout);
            q.memset(trig, 0, 4).wait();
            q.memset(arrive, 0, 64 * sizeof(unsigned)).wait();
            printf("   [step: memsets done, submitting resident kernel %u WG]\n", nwgs);
            resident = q.submit([&](sycl::handler& cgh) {
                cgh.parallel_for(sycl::nd_range<1>{{(size_t)nwgs * 32}, {32}}, p);
            });
            // Wait for it to become resident (bounded).
            double first = -3.0;
            const double tw = now_us();
            while (now_us() - tw < 1500.0) { first = (mode == 6) ? ping_dev(1) : ping(1); if (first > 0) break; }
            printf("   [step: residency ping -> %.1f us]\n", first);
            if (first <= 0) {
                printf("  %-46s DID NOT BECOME RESIDENT / no completion (ping %.1f)\n", nm, first);
                __atomic_store_n((unsigned*)&mb->quit, 1u, __ATOMIC_RELEASE);
                __atomic_store_n((unsigned*)&mb->seq, QUIT, __ATOMIC_RELEASE);
                if (!wait_bounded(resident, 3000.0)) printf("    KERNEL WILL NOT EXIT - abandoning wait\n");
                return;
            }
            std::vector<double> v;
            unsigned want = 1;
            int dead = 0;
            v.push_back(first);
            for (int i = 0; i < NPING; ++i) {
                const double t = (mode == 6) ? ping_dev(++want) : ping(++want);
                if (i < 4) printf("   [ping %u -> %.1f us]\n", want, t);
                if (t > 0) v.push_back(t); else ++dead;
            }
            std::sort(v.begin(), v.end());
            int s20 = 0, s100 = 0;
            for (double x : v) { if (x > 20.0) ++s20; if (x > 100.0) ++s100; }
            const double p50 = v[v.size() / 2], p90 = v[(size_t)(v.size() * 0.9)],
                         p99 = v[(size_t)(v.size() * 0.99)], mx = v.back();
            printf("  %-40s p50 %7.1f p90 %7.1f p99 %7.1f max %8.1f us | >20us %5.1f%% >100us "
                   "%5.1f%% | stuck %d/%d\n",
                   nm, p50, p90, p99, mx, 100.0 * s20 / v.size(), 100.0 * s100 / v.size(), dead, NPING);
            if (probe_tag) interfere(probe_tag);          // while still resident
            __atomic_store_n((unsigned*)&mb->quit, 1u, __ATOMIC_RELEASE);
            __atomic_store_n((unsigned*)&mb->seq, QUIT, __ATOMIC_RELEASE);
            if (!wait_bounded(resident, 3000.0)) printf("    KERNEL WILL NOT EXIT - abandoning wait\n");
        }
        // Interference probe: a 16 MB bandwidth kernel on the OTHER queue.
        if (false) {
            double best = 1e30;
            for (int w = 0; w < 3; ++w) {
                double t0 = now_us();
                for (int i = 0; i < 50; ++i) q2.fill(buf, 0.002f, 4u << 20).wait();
                best = std::min(best, (now_us() - t0) / 50);
            }
            printf("  %-46s %7.1f us per 16 MB fill on a second queue\n", "  interference probe", best);
        }
    };

    printf("Round-trip floor (host store -> device observe -> work -> device store -> host observe):\n");
    run_mode(0, 0, "no spinner", "  baseline, no spinner");
    run_mode(0, 1, "mode 0: 1 WG, trivial work", "  spinner = 1 WG (sysmem RMW poll)");
    run_mode(1, 1, "mode 1: 1 WG, fan-out/in path", nullptr);
    for (unsigned n : {16u, 64u, 256u}) {
        char nm[64]; snprintf(nm, sizeof(nm), "mode 1: %u WGs, fan-out + arrive-count", n);
        run_mode(1, n, nm, n == 256u ? "  spinner = full grid, idle" : nullptr);
    }
    for (unsigned n : {16u, 64u}) {
        char nm[64]; snprintf(nm, sizeof(nm), "mode 5: %u WGs, TWO-LEVEL arrive (G=8)", n);
        run_mode(5, n, nm, nullptr);
    }
    run_mode(2, 64, "mode 2: 64 WGs + FMA delay", nullptr);
    run_mode(3, 64, "mode 3: 64 WGs + MB-scale read", nullptr);
    run_mode(6, 1, "mode 6: 1 WG, H2D-copy trigger", nullptr);
    run_mode(6, 16, "mode 6: 16 WGs, H2D-copy trigger", nullptr);
    run_mode(6, 64, "mode 6: 64 WGs, H2D-copy trigger", nullptr);

    printf("\ncompare: model decode forward total p50 66.1 us (sub 27.2 + wait 28.6),"
           " marginal expert 6.3 us\n");
    sycl::free(mb, ctx); sycl::free(trig, q); sycl::free(arrive, q); sycl::free(buf, q);
    return 0;
}