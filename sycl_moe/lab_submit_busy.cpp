// lab_submit_busy.cpp — does appending to a BUSY queue cost more than appending to a drained one?
//
// Why this exists: the model's decode forward spends p50 27.2 us of PARENT-THREAD time inside
// moe_sycl::forward(), which enqueues 5 commands (job-blob H2D + 4 kernels) => ~5.4 us per submit.
// The exact same code measured with EXL3_MOE_B70_HOSTPROF=1 under bench_layer came out at 0.05 us
// per submit, and that number is what killed command graphs the first time (lab_graph4's slope,
// ~1.2 us/command). The two environments differ in one respect: bench_layer drains the queue
// (barrier/wait) before every timed forward, while the plugin submits into a queue that still has
// the previous forward's D2H in flight and chains every command with depends_on.
//
// If submit cost depends on queue state, then graphs were priced in the wrong regime, and the
// right question is "how many host-side actions per forward", not "how many device commands".
//
// Regimes, all timing only the HOST CALLS (no device timestamps, no profiler):
//   A  5 chained submits on a drained queue                      (bench_layer's world)
//   B  5 chained submits appended while a ~1 ms kernel occupies the queue, first one depending
//      on the blocker's event                                   (the plugin's world)
//   C  like B but with NO depends_on anywhere (in-order queue only)
//   D  like B, but ONE submit of a 5-command graph (needs graph support; skipped if absent)
//   icpx -fsycl -O3 lab_submit_busy.cpp -o lab_submit_busy && ./lab_submit_busy
#include <sycl/sycl.hpp>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <algorithm>

static double us() {
    return std::chrono::duration<double, std::micro>(
        std::chrono::steady_clock::now().time_since_epoch()).count();
}

int main() {
    sycl::queue q{sycl::gpu_selector_v, sycl::property::queue::in_order{}};
    printf("device %s\n", q.get_device().get_info<sycl::info::device::name>().c_str());
    float* d = sycl::malloc_device<float>(1 << 20, q);
    int* dpin = (int*)sycl::malloc_host(64, q);      // stands in for the job blob
    int* ddev = sycl::malloc_device<int>(64, q);
    q.parallel_for(1 << 20, [=](sycl::id<1> i) { d[i] = 0.f; }).wait();
    q.memset(ddev, 0, 256).wait();

    // Calibrate a blocker of ~1 ms (long enough that 5 submits definitely land while it runs).
    auto blocker = [&](int inner) {
        return q.parallel_for(1 << 14, [=](sycl::id<1> i) {
            float a = d[i[0] & ((1 << 20) - 1)];
            for (int k = 0; k < inner; ++k) a = sycl::fma(a, 1.000001f, 1e-7f);
            d[i[0] & ((1 << 20) - 1)] = a;
        });
    };
    int inner = 2000;
    for (int trial = 0; trial < 6; ++trial) {
        double t0 = us(); blocker(inner).wait(); double dt = us() - t0;
        if (dt > 700 && dt < 1600) break;
        inner = std::max(50, (int)(inner * 1000.0 / std::max(dt, 1.0)));
    }
    printf("blocker inner=%d (~1 ms)\n\n", inner);

    auto chain = [&](bool with_deps, const sycl::event* head, int n, bool dowait = true) {
        // returns host us spent in the n submits
        double t0 = us();
        sycl::event dep = head ? *head : sycl::event{};
        for (int i = 0; i < n; ++i) {
            if (i == 0)
                dep = with_deps ? q.memcpy(ddev, dpin, 64, {dep}) : q.memcpy(ddev, dpin, 64);
            else
                q.submit([&](sycl::handler& cgh) {
                    if (with_deps) cgh.depends_on(dep);
                    cgh.single_task([=] { d[1000 + i] = (float)i; });
                });
        }
        double dt = us() - t0;
        if (dowait) q.wait();
        return dt;
    };

    for (int mode = 0; mode < 3; ++mode) {
        const char* nm = mode == 0 ? "A drained, chained depends_on"
                       : mode == 1 ? "B busy queue, chained depends_on (first dep = in-flight kernel)"
                                   : "C busy queue, NO depends_on (in-order only)";
        double best = 1e30;
        for (int w = 0; w < 5; ++w) {
            if (mode == 0) { q.wait(); best = std::min(best, chain(true, nullptr, 5)); }
            else {
                sycl::event bl = blocker(inner);
                best = std::min(best, chain(mode == 1, &bl, 5));
                bl.wait();
            }
        }
        printf("  %-56s %6.2f us for 5 submits = %5.2f us/submit\n", nm, best, best / 5);
    }

    // D: does the HARNESS's own timing pattern distort what a submit costs? bench_layer brackets
    // every measured forward with two q.ext_oneapi_submit_barrier() calls and waits on both, which
    // may force the runtime to close/reopen a command list around each submit. If submits inside
    // that pattern cost far more than in regimes A-C, then bench_layer's decode wall (and every
    // A/B ever run through it) carries a submission artifact, and only model-level numbers mean
    // anything for the per-forward fixed cost.
    {
        double best = 1e30;
        for (int w = 0; w < 5; ++w) {
            q.wait();
            double t = 0.0;
            for (int i = 0; i < 200; ++i) {
                sycl::event e0 = q.ext_oneapi_submit_barrier();
                double t0 = us();
                chain(true, nullptr, 5, false);   // no inner wait: the barrier does it, like bench_layer
                t += us() - t0;
                sycl::event e1 = q.ext_oneapi_submit_barrier();
                e0.wait(); e1.wait();
            }
            best = std::min(best, t / 200);
        }
        printf("  %-56s %6.2f us for 5 submits = %5.2f us/submit\n",
               "D drained, but inside the harness's barrier-bracket pattern", best, best / 5);
    }

    // E-I: which PROPERTY of the submitted kernel costs host time? Trivial submits are 2.6 us
    // (regimes A-D) but the plugin's real launches measure 3.4-11.3 us in the model and ~21 us
    // under bench_layer. Candidates, one per regime, all with identical tiny device work:
    //   E  one local_accessor<{128}>              (what K1/K6/K56 declare)
    //   F  two local_accessors {128} + {256}      (what the coop kernels declare)
    //   G  a RUNTIME-sized local_accessor         (what the int8 tier declares)
    //   H  nd_range<2> + local_accessor           (K1/K6's exact launch shape)
    //   I  a 40-word functor, no accessors        (GemvBase's argument bulk alone)
    struct Big { const float* p; int a[38]; };
    {
        auto reg = [&](const char* nm, auto submit1) {
            double best = 1e30;
            for (int w = 0; w < 5; ++w) {
                q.wait();
                double t0 = us();
                for (int i = 0; i < 5; ++i) submit1();
                double dt = us() - t0;
                q.wait();
                best = std::min(best, dt);
            }
            printf("  %-56s %6.2f us for 5 submits = %5.2f us/submit\n", nm, best, best / 5);
        };
        reg("E nd_range<1> + local_accessor<128>", [&] {
            return q.submit([&](sycl::handler& cgh) {
                sycl::local_accessor<float, 1> sh({128}, cgh);
                cgh.parallel_for(sycl::nd_range<1>({512}, {128}),
                    [=](sycl::nd_item<1> it) { sh[it.get_local_id(0)] = 1.f; d[it.get_global_id(0)] = sh[it.get_local_id(0)]; });
            });
        });
        reg("F nd_range<1> + local_accessors 128 + 256", [&] {
            return q.submit([&](sycl::handler& cgh) {
                sycl::local_accessor<float, 1> sh({128}, cgh);
                sycl::local_accessor<int, 1> flg({2}, cgh);
                cgh.parallel_for(sycl::nd_range<1>({512}, {128}),
                    [=](sycl::nd_item<1> it) { sh[it.get_local_id(0)] = (float)flg.get_pointer()[0];
                                              d[it.get_global_id(0)] = sh[it.get_local_id(0)]; });
            });
        });
        const int rsz = 8192;
        reg("G nd_range<1> + RUNTIME-sized local_accessor", [&] {
            return q.submit([&](sycl::handler& cgh) {
                sycl::local_accessor<uint32_t, 1> slm({(size_t)rsz}, cgh);
                cgh.parallel_for(sycl::nd_range<1>({512}, {128}),
                    [=](sycl::nd_item<1> it) { d[it.get_global_id(0)] = (float)slm.get_pointer()[0]; });
            });
        });
        reg("H nd_range<2> + local_accessor (K1/K6 launch shape)", [&] {
            return q.submit([&](sycl::handler& cgh) {
                sycl::local_accessor<float, 1> sh({128}, cgh);
                cgh.parallel_for(sycl::nd_range<2>({512, 2}, {128, 1}),
                    [=](sycl::nd_item<2> it) { sh[it.get_local_id(0)] = 1.f;
                                               d[it.get_global_id(0)] = sh[it.get_local_id(0)]; });
            });
        });
        Big big{d, {}};
        reg("I nd_range<1>, 40-word functor, no accessors", [&] {
            return q.submit([&](sycl::handler& cgh) {
                cgh.parallel_for(sycl::nd_range<1>({512}, {128}),
                    [=](sycl::nd_item<1> it) { d[it.get_global_id(0)] = big.p[it.get_global_id(0)] + big.a[3]; });
            });
        });
    }

    // How much of that is the memcpy vs a kernel submit?
    {
        double b1 = 1e30, b2 = 1e30;
        for (int w = 0; w < 5; ++w) {
            sycl::event bl = blocker(inner);
            double t0 = us();
            sycl::event e = q.memcpy(ddev, dpin, 64, {bl});
            double tm = us() - t0;
            t0 = us();
            for (int i = 0; i < 4; ++i) e = q.single_task({e}, [=] { d[2000] = (float)i; });
            double tk = us() - t0;
            q.wait();
            b1 = std::min(b1, tm); b2 = std::min(b2, tk / 4);
        }
        printf("  on a busy queue: 1 pinned-memcpy submit %5.2f us | 1 kernel submit %5.2f us\n", b1, b2);
    }
    sycl::free(d, q); sycl::free(dpin, q); sycl::free(ddev, q);
    return 0;
}