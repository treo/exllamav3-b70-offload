// lab_graph.cpp — does a SYCL command graph beat a chain of dependent submits for the
// decode-shaped command chain on the B70?
//
//   icpx -fsycl -O2 lab_graph.cpp -o lab_graph && ./lab_graph [chainLen] [iters]
//
// Mirrors production: ONE in-order queue; per forward = small H2D, N dependent kernel
// launches (like moe_sycl::forward's chain), small D2H, host waits for the result - the
// round trip a decode token pays. Variants:
//   A: build the chain with submits every iteration          (status quo)
//   B: same chain as a captured/executable command_graph     (replay + wait each iteration)
//   C: B but 8 replays in flight before waiting              (host-side pipelining)
// Methodology per sycl_moe/NOTES.md: no profiler, long burn-in, min-of-3 windows.
#include <sycl/sycl.hpp>
#include <sycl/ext/oneapi/experimental/graph.hpp>
#include <algorithm>
#include <chrono>
#include <cstdio>
#include <vector>

namespace gx = sycl::ext::oneapi::experimental;
using gnode = gx::node;

static double now_us() {
    return std::chrono::duration<double, std::micro>(
        std::chrono::steady_clock::now().time_since_epoch()).count();
}

struct WorkK {                       // 64 kB touched: a real command, not a no-op
    float* p; int tag;
    void operator()(sycl::nd_item<1> it) const {
        const size_t i = it.get_global_id(0);
        p[i] = p[i] * 0.999f + (float)tag;
    }
};
static constexpr size_t N = 16384;

int main(int argc, char** argv) {
    const int chain = argc > 1 ? atoi(argv[1]) : 6;
    const int iters = argc > 2 ? atoi(argv[2]) : 3000;
    sycl::queue q{sycl::gpu_selector_v, sycl::property::queue::in_order{}};
    printf("device: %s\n", q.get_device().get_info<sycl::info::device::name>().c_str());
    try {
        printf("max_compute_queue_indices = %d\n",
               (int)q.get_device().get_info<sycl::ext::intel::info::device::max_compute_queue_indices>());
    } catch (...) { printf("max_compute_queue_indices: n/a\n"); }
    printf("graph aspect = %d\n", (int)q.get_device().has(sycl::aspect::ext_oneapi_graph));

    float* d = sycl::malloc_device<float>(N, q);
    float* h = sycl::malloc_host<float>(N, q);
    q.memset(d, 0, N * sizeof(float)).wait();

    auto cgk = [d](int k) {
        return [=](sycl::handler& cgh) {
            cgh.parallel_for<WorkK>(sycl::nd_range<1>{sycl::range<1>{N}, sycl::range<1>{256}},
                                    WorkK{d, k});
        };
    };

    // ---------- A: explicit submit chain, rebuilt every iteration
    auto chain_submit = [&]() {
        sycl::event dep = q.memcpy(d, h, 4096);
        for (int k = 0; k < chain; ++k)
            dep = q.submit([&](sycl::handler& cgh) {
                cgh.depends_on(dep);
                cgh.parallel_for<WorkK>(sycl::nd_range<1>{sycl::range<1>{N}, sycl::range<1>{256}},
                                        WorkK{d, k});
            });
        return q.memcpy(h, d, 4096);
    };
    for (int i = 0; i < 3000; ++i) chain_submit().wait();          // burn-in
    double bestA = 1e30;
    for (int w = 0; w < 3; ++w) {
        double t0 = now_us();
        for (int i = 0; i < iters; ++i) chain_submit().wait();
        bestA = std::min(bestA, (now_us() - t0) / iters);
    }

    // ---------- B/C: command graph
    double bestB = 1e30, bestC = 1e30;
    bool ok = false;
    try {
        gx::command_graph<gx::graph_state::modifiable> mg{q};
        gnode in = mg.add([&](sycl::handler& cgh) { cgh.memcpy(d, h, 4096); });
        gnode prev = in;
        for (int k = 0; k < chain; ++k)
            prev = mg.add(cgk(k), sycl::property_list{gx::property::node::depends_on{prev}});
        mg.add([&](sycl::handler& cgh) { cgh.memcpy(h, d, 4096); },
               sycl::property_list{gx::property::node::depends_on{prev}});
        auto eg = mg.finalize();

        q.ext_oneapi_graph(eg).wait();                             // instantiate
        for (int i = 0; i < 1000; ++i) q.ext_oneapi_graph(eg).wait();
        ok = true;
        for (int w = 0; w < 3; ++w) {
            double t0 = now_us();
            for (int i = 0; i < iters; ++i) q.ext_oneapi_graph(eg).wait();
            bestB = std::min(bestB, (now_us() - t0) / iters);
        }
        for (int w = 0; w < 3; ++w) {
            double t0 = now_us();
            for (int i = 0; i < iters; i += 8) {
                for (int j = 0; j < 8; ++j) q.ext_oneapi_graph(eg);
                q.wait();
            }
            bestC = std::min(bestC, (now_us() - t0) / iters);
        }
        // ---------- D: single submit of ALL kernels in one kernel (floor probe): 1 command
        double bestD = 1e30;
        for (int w = 0; w < 3; ++w) {
            double t0 = now_us();
            for (int i = 0; i < iters; ++i)
                q.single_task([=] { d[0] = d[0] * 0.999f + 1.f; }).wait();
            bestD = std::min(bestD, (now_us() - t0) / iters);
        }
        printf("\nchain=%d kernels + 2 copies, iters=%d, us per round trip (min of 3)\n",
               chain, iters);
        printf("  A submit chain every iter : %7.2f\n", bestA);
        printf("  B graph replay + wait     : %7.2f  (%.2fx vs A)\n", bestB, bestA / bestB);
        printf("  C graph replay, 8 in flight    : %7.2f  (%.2fx vs A)\n", bestC, bestA / bestC);
        printf("  D one single_task + wait  : %7.2f  (1-command floor)\n", bestD);
    } catch (const sycl::exception& e) {
        printf("\ngraph path FAILED: %s\n", e.what());
        printf("  A submit chain every iter : %7.2f\n", bestA);
    }
    if (!ok) printf("  A submit chain every iter : %7.2f\n", bestA);
    sycl::free(d, q); sycl::free(h, q);
    return 0;
}