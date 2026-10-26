// t38: grid-wide barrier feasibility + cost + residency ceiling on B70.
// Persistent kernel: NWG work-groups x THR threads, PH phases. Each phase:
//   work slice (bounded FMA loop) -> arrival counter (acq_rel atomic_add) + spin
//   until counter == nwg*(phase+1). If any WG is NOT co-resident the kernel
//   DEADLOCKS -> host detects via timed event poll and reports the ceiling.
#include <sycl/sycl.hpp>
#include <cstdio>
#include <cstdlib>
#include <chrono>
#include <thread>
#include <vector>

using u32 = uint32_t;

static void grid_barrier(u32* cnt, u32 target, sycl::nd_item<1>& it)
{
    it.barrier(sycl::access::fence_space::global_space);
    if (it.get_local_id(0) == 0)
    {
        sycl::atomic_ref<u32, sycl::memory_order::acq_rel, sycl::memory_scope::device,
                         sycl::access::address_space::global_space> r(*cnt);
        r.fetch_add(1u);
        while (r.load(sycl::memory_order::acquire) < target) {}
    }
    it.barrier(sycl::access::fence_space::global_space);
}

int main(int argc, char** argv)
{
    const int SLM_KB = argc > 1 ? atoi(argv[1]) : 0;      // per-WG static SLM
    const int GRID = argc > 2 ? atoi(argv[2]) : 0;         // 0 = sweep
    const int THR = argc > 3 ? atoi(argv[3]) : 64;
    printf("== SLM %d KB/WG, threads %d ==\n", SLM_KB, THR);
    sycl::device dev([](const sycl::device& d) { return d.get_info<sycl::info::device::name>().find("Arc") != std::string::npos; });
    sycl::context ctx(dev);
    sycl::queue q(ctx, dev, sycl::property::queue::in_order{});
    printf("device: %s  EU=%u\n", dev.get_info<sycl::info::device::name>().c_str(),
           dev.get_info<sycl::info::device::max_compute_units>());
    u32* cnt = sycl::malloc_device<u32>(4, q);
    float* out = sycl::malloc_device<float>(1 << 20, q);
    q.wait();

    const int PH = 8;
    bool poisoned = false;
    std::vector<int> grids = GRID ? std::vector<int>{GRID}
        : std::vector<int>{16, 32, 48, 64, 96, 128, 160, 192, 256, 384, 512};
    for (int nwg : grids)
    {
        if (poisoned) break;
        int thr = THR;
        {
            q.memset(cnt, 0, 4).wait();
            auto t0 = std::chrono::steady_clock::now();
            bool ok = true;
            sycl::event ev;
            ev = [&] {
                size_t ldn = (size_t)(SLM_KB ? SLM_KB * 256 : 1);
                return q.submit([=](sycl::handler& cgh) {
                    sycl::local_accessor<float, 1> slm(ldn, cgh);
                    cgh.parallel_for(sycl::nd_range<1>{{(size_t)nwg * thr}, {(size_t)thr}},
                                [=](sycl::nd_item<1> it) {
                                    float acc = (float)it.get_global_id(0);
                                    for (int p = 0; p < PH; ++p)
                                    {
                                        for (int i = 0; i < 64; ++i) acc = sycl::fma(acc, 1.0001f, 0.5f);
                                        grid_barrier(cnt, (u32)(p + 1) * nwg, it);
                                    }
                                    slm[it.get_local_id(0)] = acc;
                                    it.barrier(sycl::access::fence_space::local_space);
                                    out[it.get_global_id(0)] = slm[it.get_local_id(0)] + slm[thr - 1 - it.get_local_id(0)];
                                });
                });
            }();
            int64_t us = 0;
            while (ev.get_info<sycl::info::event::command_execution_status>()
                   != sycl::info::event_command_status::complete)
            {
                std::this_thread::yield();
                us = std::chrono::duration_cast<std::chrono::microseconds>(
                        std::chrono::steady_clock::now() - t0).count();
                if (us > 2000000) { ok = false; break; }
            }
            double total_ms = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count();
            printf("thr %3d nwg %3d: %s in %8.3f ms%s\n", thr, nwg, ok ? "OK     " : "TIMEOUT", total_ms,
                   ok ? "" : "  <- co-residency ceiling crossed");
            if (!ok) { printf("(kernel still spinning on device; giving up the sweep)\n"); poisoned = true; break; }
            // barrier cost: same grid, no-barrier baseline for subtraction
            auto t1 = std::chrono::steady_clock::now();
            for (int rep = 0; rep < 100; ++rep)
                q.submit([=](sycl::handler& cgh) {
                    sycl::local_accessor<float, 1> slm((size_t)(SLM_KB ? SLM_KB * 256 : 1), cgh);
                    cgh.parallel_for(sycl::nd_range<1>{{(size_t)nwg * thr}, {(size_t)thr}},
                               [=](sycl::nd_item<1> it) {
                                   float acc = (float)it.get_global_id(0);
                                   for (int i = 0; i < 64; ++i) acc = sycl::fma(acc, 1.0001f, 0.5f);
                                   slm[it.get_local_id(0)] = acc;
                                   it.barrier(sycl::access::fence_space::local_space);
                                   out[it.get_global_id(0)] = slm[it.get_local_id(0)];
                               });
                });
            q.wait();
            double one_ms = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t1).count() / 100;
            printf("   barrier ~%.2f us each (chain %.3f ms vs no-barrier %.3f ms)\n",
                   (total_ms - one_ms) * 1000.0 / (PH - 1), total_ms, one_ms);
        }
    }
    return 0;
}