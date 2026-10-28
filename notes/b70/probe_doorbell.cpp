// Minimal "can a parked kernel see a host write" test, to find out why the doorbell in
// probe_transport never acks. Three mechanisms, each bounded, each with a heartbeat so a kernel
// that never started is distinguishable from one that cannot see the flag.
//
//   A  poll a host-USM word with sycl::atomic_ref<..., memory_scope::system>
//   B  poll a host-USM word with a plain volatile load + sycl::ext::oneapi::experimental::atomic_fence
//   C  one-shot kernel per round (the "submit every job" model), for the cost baseline
//
// build: icpx -fsycl -O2 -o probe_doorbell probe_doorbell.cpp
#include <sycl/sycl.hpp>
#include <atomic>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <thread>

using namespace std::chrono;
static double us() { return duration<double, std::micro>(steady_clock::now().time_since_epoch()).count(); }

template <int MODE>
static void parker(uint32_t *db, uint32_t *ack, uint32_t *quit, uint32_t *beat, uint64_t budget)
{
    using sys_atom = sycl::atomic_ref<uint32_t, sycl::memory_order::acq_rel,
                                      sycl::memory_scope::system,
                                      sycl::access::address_space::global_space>;
    sys_atom adb(*db), aack(*ack), aquit(*quit), abeat(*beat);
    uint32_t last = adb.load(sycl::memory_order::acquire);
    for (uint64_t spin = 0; spin < budget; ++spin)
    {
        uint32_t cur;
        if constexpr (MODE == 0) cur = adb.load(sycl::memory_order::acquire);
        else
        {
            cur = *(volatile uint32_t *) db;     // plain volatile read of the same address
            sycl::atomic_fence(sycl::memory_order::acq_rel, sycl::memory_scope::system);
        }
        if (cur != last) { last = cur; aack.fetch_add(1, sycl::memory_order::acq_rel); }
        if (aquit.load(sycl::memory_order::relaxed)) return;
        if ((spin & 0xFFFFF) == 0) abeat.store(uint32_t(spin >> 20), sycl::memory_order::relaxed);
    }
}

int main()
{
    setvbuf(stdout, nullptr, _IONBF, 0);
    sycl::device dev{sycl::gpu_selector_v};
    sycl::context ctx{dev};
    sycl::queue q{ctx, dev};

    uint32_t *h = (uint32_t *) sycl::malloc_host(64 * 8, q);   // db, ack, quit, beat, out (64 B apart)
    uint32_t *db = h, *ack = h + 16, *quit = h + 32, *beat = h + 48;
    auto rd = [&](uint32_t *p) { std::atomic_thread_fence(std::memory_order_seq_cst); uint32_t v = *(volatile uint32_t *) p; std::atomic_thread_fence(std::memory_order_seq_cst); return v; };
    auto wr = [&](uint32_t *p, uint32_t v) { std::atomic_thread_fence(std::memory_order_seq_cst); *(volatile uint32_t *) p = v; std::atomic_thread_fence(std::memory_order_seq_cst); };

    for (int mode = 0; mode < 2; ++mode)
    {
        wr(db, 0); wr(ack, 0); wr(quit, 0); wr(beat, 0);
        q.submit([&](sycl::handler &cgh)
        {
            auto k = [=](sycl::id<1>) { if (mode == 0) parker<0>(db, ack, quit, beat, 300'000'000ull); else parker<1>(db, ack, quit, beat, 300'000'000ull); };
            cgh.parallel_for(sycl::range<1>(1), k);
        });
        q.ext_oneapi_submit_barrier();
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
        printf("mode %c: after 50 ms, heartbeat=%u (0 = kernel never ran or never reached the beat)\n",
               mode ? 'B' : 'A', rd(beat));
        wr(ack, 0);
        double t = us();
        wr(db, 1);
        uint64_t spins = 0;
        while (rd(ack) < 1 && spins < 300'000'000ull) ++spins;
        double rt = us() - t;
        printf("mode %c: doorbell round trip %.2f us [%s], beat %u\n", mode ? 'B' : 'A', rt,
               rd(ack) >= 1 ? "acked" : "NOT ACKED", rd(beat));

        // 200 more rounds
        double best = 1e30, sum = 0; int n = 0;
        for (int i = 2; i < 202; ++i)
        {
            wr(ack, 0);
            t = us(); wr(db, uint32_t(i));
            spins = 0;
            while (rd(ack) < 1 && spins < 100'000'000ull) ++spins;
            double d = us() - t;
            if (rd(ack) >= 1) { sum += d; ++n; if (d < best) best = d; }
            else break;
        }
        printf("mode %c: %d rounds, mean %.2f us, best %.2f us\n", mode ? 'B' : 'A', n, n ? sum / n : -1.0, best);
        wr(quit, 1);
        double tq = us();
        while (true) { try { q.wait(); break; } catch (...) { break; } if (us() - tq > 10e6) { printf("wedged\n"); return 3; } }
    }

    // C: one submission per job
    {
        wr(db, 0); wr(ack, 0);
        double sum = 0; int n = 0; double best = 1e30;
        for (int i = 0; i < 300; ++i)
        {
            double t = us();
            q.single_task([=] { *(volatile uint32_t *) ack = 1; });
            uint64_t spins = 0;
            while (rd(ack) < 1 && spins < 300'000'000ull) ++spins;
            double d = us() - t;
            sum += d; ++n; if (d < best) best = d;
            wr(ack, 0);
        }
        printf("mode C: submit-per-job, mean %.2f us, best %.2f us\n", sum / n, best);
    }
    printf("done\n");
    return 0;
}