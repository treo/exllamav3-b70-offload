// lab_sub_position.cpp — WHERE inside the 28 us of `sub` does each action cost what?
//
// The model's own per-stage instrument (EXL3_MOE_B70_HOSTPROF, now split per job class) says for a
// rows=1 float decode forward:
//     prologue 0.6 | blob-h2d 3.3 | K1-prep 11.9 | gemv 4.6 | K34-act 4.5 | K56-coopdn 5.2  => 30 us
// so ONE submit - K1, the first KERNEL after the two host->device copies - is 2.6x any other and 40%
// of the whole phase. This lab localizes why, by timing every action individually under the two
// queue states that matter, with the real action sequence and sizes:
//
//   x H2D 5 KB (dep on the PREVIOUS forward's event)   <- b70_forward's first queue op
//   blob H2D ~1.5 KB                                    <- moe_sycl::forward's first op
//   K1  nd_range<2> + local_accessor{128}               <- the 12 us one
//   K2  nd_range<1>, plain args (GemvK shape)
//   K34 nd_range<2> + local_accessor{256}
//   K56 nd_range<2> + local_accessor{128} + {2}
//   out D2H 10 KB
//
// Regimes (the plugin's queue DRAINS between forwards - the parent does its own GPU work for
// ~100-300 us - which is also exactly what NOTES blames for bench_layer's ~21 us/submit):
//   busy    : chains submitted back-to-back, queue never drained (the lab_submit_busy world)
//   drained : one chain, then wait, then an idle gap, then the next chain (the model's world)
// Arms peel factors off the production order:
//   prod        x2H2D + 4 kernel submits + D2H, every op chained with depends_on (production)
//   nokernel    only the 3 memory ops
//   nomemcpy    only the 4 kernel submits
//   kernelsfirst copies AFTER the kernels (semantics wrong; isolates "first KERNEL after a copy")
//   noaccessor  4 kernel submits, none declaring a local_accessor (isolates the SLM reservation)
//   nodeps      production order, no dependency edges (out-of-order queue: unsafe, prices the DAG)
//   inorder     production order on a queue built with property::queue::in_order
//
//   source ../sycl_moe/env.sh
//   icpx -fsycl -O3 -w lab_sub_position.cpp -o lab_sub_position && ./lab_sub_position [chains]
#include <sycl/sycl.hpp>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>

static double us() { return std::chrono::duration<double, std::micro>(
    std::chrono::steady_clock::now().time_since_epoch()).count(); }

static constexpr size_t NH = 4096;         // floats the kernels touch
static constexpr size_t BX = 5120;         // x bytes (rows=1 x hidden x 2)
static constexpr size_t BB = 1536;         // job blob bytes

struct KAcc {                  // prep-like: nd_range<2> + one local_accessor
    float* d; sycl::local_accessor<float, 1> sh;
    void operator()(sycl::nd_item<2> it) const {
        const int l = (int)it.get_local_id(0); sh[l] = 1.f;
        it.barrier(sycl::access::fence_space::local_space);
        d[(it.get_global_linear_id() & (NH - 1))] = sh[l];
    }
};
struct KPlain {                // gemv-like: nd_range<1>, no accessor
    float* d; const float* a; int n;
    void operator()(sycl::nd_item<1> it) const {
        const size_t i = it.get_global_linear_id();
        d[i & (NH - 1)] = a[i & (NH - 1)] + (float)n;
    }
};

struct Ctx {
    float *d, *a; uint8_t *dx, *bdev; void* hx; void* hb; void* hout;
};

// one production-shaped forward: x H2D, blob H2D, K1(acc), gemv, K34(acc), K56(2 accs), out D2H.
// Per-action HOST time goes into t[] (7 slots) when t != nullptr. `deps` selects the production
// depends_on chain; `nacc` swaps the accessor kernels for plain ones (isolates the SLM request).
static sycl::event chain(sycl::queue& q, Ctx& C, double* t, bool deps, bool nacc = false) {
    sycl::nd_range<2> r2{sycl::range<2>{512, 2}, sycl::range<2>{128, 1}};
    sycl::nd_range<1> r1{sycl::range<1>{512}, sycl::range<1>{128}};
    double p = us();
    auto tick = [&](int k) { const double z = us(); if (t) t[k] += z - p; p = z; };
    sycl::event ex = q.memcpy(C.dx, C.hx, BX);                              tick(0);
    sycl::event eb = deps ? q.memcpy(C.bdev, C.hb, BB, {ex})
                          : q.memcpy(C.bdev, C.hb, BB);                     tick(1);
    sycl::event e1 = q.submit([&](sycl::handler& cgh) {
        if (deps) cgh.depends_on(eb);
        if (nacc) cgh.parallel_for(r1, KPlain{C.d, C.a, 0});
        else { sycl::local_accessor<float, 1> sh({128}, cgh); cgh.parallel_for(r2, KAcc{C.d, sh}); }
    });                                                                     tick(2);
    sycl::event e2 = q.submit([&](sycl::handler& cgh) {
        if (deps) cgh.depends_on(e1);
        cgh.parallel_for(r1, KPlain{C.d, C.a, 1});
    });                                                                     tick(3);
    sycl::event e3 = q.submit([&](sycl::handler& cgh) {
        if (deps) cgh.depends_on(e2);
        if (nacc) cgh.parallel_for(r1, KPlain{C.d, C.a, 2});
        else { sycl::local_accessor<float, 1> sh({256}, cgh); cgh.parallel_for(r2, KAcc{C.d, sh}); }
    });                                                                     tick(4);
    sycl::event e4 = q.submit([&](sycl::handler& cgh) {
        if (deps) cgh.depends_on(e3);
        if (nacc) cgh.parallel_for(r1, KPlain{C.d, C.a, 3});
        else { sycl::local_accessor<float, 1> sh({128}, cgh);
               sycl::local_accessor<int, 1> flg({2}, cgh);
               cgh.parallel_for(r2, KAcc{C.d, sh}); }
    });                                                                     tick(5);
    sycl::event e5 = deps ? q.memcpy(C.hout, C.d, 10240, {e4})
                          : q.memcpy(C.hout, C.d, 10240);                   tick(6);
    return e5;
}

int main(int argc, char** argv) {
    setvbuf(stdout, nullptr, _IONBF, 0);
    const int N = argc > 1 ? atoi(argv[1]) : 3000;
    sycl::device dev{sycl::gpu_selector_v};
    sycl::context ctx{dev};
    sycl::queue qooo{dev};                                     // what production builds
    sycl::queue qio{dev, sycl::property::queue::in_order{}};
    printf("device %s | is_in_order: default=%d in_order=%d | %d chains per window\n",
           dev.get_info<sycl::info::device::name>().c_str(), (int)qooo.is_in_order(),
           (int)qio.is_in_order(), N);

    Ctx C;
    C.d = sycl::malloc_device<float>(NH, qooo);
    C.a = sycl::malloc_device<float>(NH, qooo);
    C.dx = sycl::malloc_device<uint8_t>(BX, qooo);
    C.bdev = sycl::malloc_device<uint8_t>(BB, qooo);
    C.hx = sycl::malloc_host(BX, ctx); C.hb = sycl::malloc_host(BB, ctx);
    C.hout = sycl::malloc_host(10240, ctx);
    memset(C.hx, 1, BX); memset(C.hb, 2, BB);
    qooo.memset(C.d, 0, NH * 4).wait(); qooo.memset(C.a, 0, NH * 4).wait();

    const char* nm[] = {"x H2D", "blob H2D", "K1 acc", "gemv", "K34 acc", "K56 acc2", "out D2H"};
    auto show = [&](const char* arm, sycl::queue& q, int regime, bool deps, bool nacc = false) {
        double acc[7] = {}; double best_wall = 1e30; double best_sum = 1e30;
        for (int w = 0; w < 3; ++w) {
            double t[7] = {}; double wallsum = 0.0;
            if (regime == 0) {                       // busy: chains back-to-back
                for (int i = 0; i < 200; ++i) { chain(q, C, nullptr, deps, nacc); }
                q.wait();
                const double t0 = us();
                for (int i = 0; i < N; ++i) { double tt[7] = {}; chain(q, C, tt, deps, nacc);
                                              for (int k = 0; k < 7; ++k) t[k] += tt[k]; }
                q.wait(); wallsum = (us() - t0) / N;
            } else {                                 // drained + idle, like the model's cadence
                for (int i = 0; i < 50; ++i) { chain(q, C, nullptr, deps, nacc); q.wait(); }
                for (int i = 0; i < N; ++i) {
                    const double tg = us(); while (us() - tg < 200.0) {}     // parent's own work
                    const double t0 = us();
                    double tt[7] = {}; chain(q, C, tt, deps, nacc);
                    q.wait();
                    wallsum += us() - t0;
                    for (int k = 0; k < 7; ++k) t[k] += tt[k];
                }
                wallsum /= N;
            }
            for (int k = 0; k < 7; ++k) acc[k] += t[k];
            best_wall = std::min(best_wall, wallsum);
            double sum = 0; for (int k = 0; k < 7; ++k) sum += t[k];
            best_sum = std::min(best_sum, sum / N);
        }
        printf("  %-34s wall %6.1f | sum %5.1f |", arm, best_wall, best_sum);
        for (int k = 0; k < 7; ++k) printf(" %.2f", acc[k] / (3.0 * N));
        printf("\n");
    };
    printf("\nPer-action HOST us. Regime BUSY = chains back-to-back; DRAINED = queue emptied and\n"
           "left idle 150 us between chains (the model's cadence: ~48 layer-jobs per 14.7 ms token).\n\n");
    printf("action order in the columns:");
    for (int k = 0; k < 7; ++k) printf(" %s", nm[k]);
    printf("\n\nBUSY (queue never drained):\n");
    show("OOO + deps  (production shape)", qooo, 0, true);
    show("in_order + deps", qio, 0, true);
    show("in_order, no deps", qio, 0, false);
    show("OOO + deps, NO local_accessors", qooo, 0, true, true);
    printf("\nDRAINED + 200 us idle per chain (the model's cadence):\n");
    show("OOO + deps  (production shape)", qooo, 1, true);
    show("in_order + deps", qio, 1, true);
    show("in_order, no deps", qio, 1, false);
    show("OOO + deps, NO local_accessors", qooo, 1, true, true);
    printf("\ncompare: the MODEL measures blob-h2d 3.3 | K1 11.9 | gemv 4.6 | K34 4.5 | down 5.2 us\n");
    return 0;
}