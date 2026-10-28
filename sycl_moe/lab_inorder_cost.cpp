// lab_inorder_cost.cpp — is our per-action submission cost partly the DEPENDENCY BOOKKEEPING, and
// does an in-order queue let us stop paying for it?
//
// Why now. NOTES' top trap P1 said "an in-order queue does NOT serialize q.memcpy after q.submit
// kernels; only explicit dependency edges are honored", and the plugin accordingly chains EVERY op
// through returned events (moe_sycl.cpp, g_last_ev across calls). But b70_lib.cpp never built an
// in-order queue at all (label: `{gpu_selector_v, async_handler}`), and lab_p1_order.cpp measured
// that a real in-order queue DOES serialize both directions (0/1000 vs 322/1000). Two consequences:
//   (1) the chains are load-bearing only because our queue is out-of-order;
//   (2) the vendor launch-latency doc notes that on an OUT-OF-ORDER queue, event-less submission
//       "still creates events internally". If that is where part of our 5.4 us/action lives, then
//       `property::queue::in_order` + dropping the edges is a fixed-cost lever that needs no new
//       machinery at all - unlike the persistent engine, which is closed (PLAN_PERSISTENT_WORKER §11).
//
// What is measured. One decode-shaped forward chain, identical ops in every arm:
//   blob H2D (1 KB, pinned host -> device)  +  K1 (nd_range<2> + local_accessor, like prep)
//   + K2 gemv (nd_range<1>, plain args, like GemvK)  + K34 (local_accessor)  + K56 down (plain)
//   + out D2H (10 KB).
// Two timings, kept strictly separate (the doc's "measure them separately", and rule 2 of this repo):
//   HOST  = burst-submit 40 chains WITHOUT waiting, divide by actions. This is `sub` (27.2 us for 5
//           actions in the model) - the parent-thread cost that is 41% of a decode forward.
//   WALL  = one chain + wait, min-of-5. This is what the child's `wait` leg sees.
// Arms:
//   OOO+deps    production today: default queue, every op chained through events
//   OOO+nodeps  default queue, no edges (WRONG semantics; isolates the bookkeeping cost)
//   IO+deps     in_order queue, still chained
//   IO+nodeps   in_order queue, no edges  <-- the candidate change
//   IO+ndl      in_order queue + handler-free nd_launch for the kernels (event-less API)
//   OOO+ndl     default queue + nd_launch  (does event-less still allocate on an out-of-order queue?)
//   ic          in_order + discard_events property on the chained submits (deprecated API, priced for
//               completeness because the plugin needs ONE event per forward to poll completion)
//   source ../sycl_moe/env.sh
//   icpx -fsycl -O2 -w lab_inorder_cost.cpp -o lab_inorder_cost && ./lab_inorder_cost [chains]
#include <sycl/sycl.hpp>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <atomic>
#include <thread>
#include <vector>

static double us() {
    return std::chrono::duration<double, std::micro>(
        std::chrono::steady_clock::now().time_since_epoch()).count();
}

namespace gx = sycl::ext::oneapi::experimental;

static constexpr size_t NBIG = 4096;         // float elements the kernels touch
static constexpr size_t NBLOB = 1024;        // job blob bytes
static constexpr size_t NOUT = 2560;         // out floats (rows=1 x hidden)

// The two hot float gemvs declare NO local_accessor: every argument is already a plain byte blob,
// which is what makes the handler-free path applicable to them (regime N of lab_submit_busy).
SYCL_EXT_ONEAPI_FUNCTION_PROPERTY((gx::nd_range_kernel<1>))
void kGemv(float* p, const float* a, const float* b, float* c, float* e, float* f,
           const unsigned long long* tab, int E, int nc, int nm, int H, int I, int nbk, int cfg) {
    // 7 pointers + 7 ints: the nd_launch argument list below must match this exactly.
    const size_t i = sycl::ext::oneapi::this_work_item::get_nd_item<1>().get_global_linear_id();
    float v = a[i & (NBIG - 1)] + (float)E + (float)nbk + (float)(*tab);
    c[i & (NBIG - 1)] = v + b[i & (NBIG - 1)] + p[i & (NBIG - 1)] + e[i & (NBIG - 1)] +
                        f[i & (NBIG - 1)] + (float)(nc + nm + H + I + cfg);
}

// Identical device work spelled two ways, to isolate the CALL PATH from the kernel: a functor
// through q.submit (what the plugin does today) vs a prebuilt sycl::kernel + raw arg bytes through
// nd_launch. lab_submit_busy's regimes K-O priced these as equal for isolated tiny submits; this
// chain-in-a-burst context is where a difference would actually matter.
SYCL_EXT_ONEAPI_FUNCTION_PROPERTY((gx::nd_range_kernel<1>))
void kSame(float* p, const float* a, const float* b, float* c, float* e, float* f,
           const unsigned long long* tab, int E, int nc, int nm, int H, int I, int nbk, int cfg) {
    const size_t i = sycl::ext::oneapi::this_work_item::get_nd_item<1>().get_global_linear_id();
    float v = a[i & (NBIG - 1)] + (float)E + (float)nbk + (float)(*tab);
    c[i & (NBIG - 1)] = v + b[i & (NBIG - 1)] + p[i & (NBIG - 1)] + e[i & (NBIG - 1)] +
                        f[i & (NBIG - 1)] + (float)(nc + nm + H + I + cfg);
}

struct SameFunctor {           // same 7 ptrs + 7 ints, same arithmetic
    float *p, *c, *e, *f; const float *a, *b; const unsigned long long* tab;
    int E, nc, nm, H, I, nbk, cfg;
    void operator()(sycl::nd_item<1> it) const {
        const size_t i = it.get_global_linear_id();
        float v = a[i & (NBIG - 1)] + (float)E + (float)nbk + (float)(*tab);
        c[i & (NBIG - 1)] = v + b[i & (NBIG - 1)] + p[i & (NBIG - 1)] + e[i & (NBIG - 1)] +
                            f[i & (NBIG - 1)] + (float)(nc + nm + H + I + cfg);
    }
};

template <auto* Func>
sycl::kernel getKernel(sycl::queue& q) {
    auto bundle = gx::get_kernel_bundle<Func, sycl::bundle_state::executable>(q.get_context());
    return bundle.template ext_oneapi_get_kernel<Func>();
}

// prep-like kernel: nd_range<2> + one local_accessor (what K1/K6 declare)
struct KPrep {
    float* d;
    sycl::local_accessor<float, 1> sh;
    void operator()(sycl::nd_item<2> it) const {
        const int l = (int)it.get_local_id(0);
        sh[l] = 1.0f;
        it.barrier(sycl::access::fence_space::local_space);
        d[it.get_global_linear_id() & (NBIG - 1)] = sh[l];
    }
};

struct Chain {
    sycl::queue* q;
    float *d, *a, *b, *c, *e, *f;
    unsigned long long* tab;
    uint8_t* blob;          // device
    float* hb;              // pinned host staging for the blob
    float* ho;              // pinned host out
    sycl::kernel* kgemv = nullptr;   // heap: Chain must stay default-constructible
    bool inorder;
    int mode;               // 0 = chained submits, 1 = unchained submits, 2 = nd_launch kernels
};

// one decode-shaped forward: H2D blob, K1, K2, K34, K56, D2H out. Returns the last event (what the
// plugin polls for completion) - mode 2 has none, which is the point.
static sycl::event forward_chain(Chain& X) {
    const int c11[7] = {10, 1, 2, 2560, 640, 5, 4};
    sycl::nd_range<1> gemv_rng{sycl::range<1>{512}, sycl::range<1>{128}};
    sycl::nd_range<2> prep_rng{sycl::range<2>{512, 2}, sycl::range<2>{128, 1}};

    if (X.mode == 2) {
        // Realistically only the two HOT gemvs go handler-free: K1/K34 declare a local_accessor,
        // which is exactly the case the enqueue-functions path does not cover.
        X.q->memcpy(X.blob, X.hb, NBLOB);
        X.q->submit([&](sycl::handler& cgh) {
            sycl::local_accessor<float, 1> sh({128}, cgh);
            cgh.parallel_for(prep_rng, KPrep{X.c, sh});
        });
        for (int twice = 0; twice < 2; ++twice)     // K2 and K56, the plugin's hot launches
            gx::nd_launch(*X.q, gemv_rng, *X.kgemv, X.d, X.a, X.b, X.c, X.e, X.f, X.tab,
                          gx::raw_kernel_arg{&c11[0], sizeof(int)}, gx::raw_kernel_arg{&c11[1], sizeof(int)},
                          gx::raw_kernel_arg{&c11[2], sizeof(int)}, gx::raw_kernel_arg{&c11[3], sizeof(int)},
                          gx::raw_kernel_arg{&c11[4], sizeof(int)}, gx::raw_kernel_arg{&c11[5], sizeof(int)},
                          gx::raw_kernel_arg{&c11[6], sizeof(int)});
        X.q->memcpy(X.ho, X.c, NOUT * sizeof(float));
        return {};
    }
    if (X.mode == 1) {
        X.q->memcpy(X.blob, X.hb, NBLOB);
        X.q->submit([&](sycl::handler& cgh) {
            sycl::local_accessor<float, 1> sh({128}, cgh);
            cgh.parallel_for(prep_rng, KPrep{X.c, sh});
        });
        X.q->submit([&](sycl::handler& cgh) { cgh.parallel_for(gemv_rng, [=](sycl::nd_item<1> it) {
            const size_t i = it.get_global_linear_id();
            X.c[i & (NBIG - 1)] = X.a[i & (NBIG - 1)] + X.d[i & (NBIG - 1)] + (float)c11[3];
        }); });
        X.q->submit([&](sycl::handler& cgh) {
            sycl::local_accessor<float, 1> sh({128}, cgh);
            cgh.parallel_for(prep_rng, KPrep{X.e, sh});
        });
        X.q->submit([&](sycl::handler& cgh) { cgh.parallel_for(gemv_rng, [=](sycl::nd_item<1> it) {
            const size_t i = it.get_global_linear_id();
            X.f[i & (NBIG - 1)] = X.e[i & (NBIG - 1)] + X.b[i & (NBIG - 1)] + (float)c11[4];
        }); });
        return X.q->memcpy(X.ho, X.c, NOUT * sizeof(float));
    }
    // mode 0: production's pattern - keep every event and chain the next op on it
    sycl::event e0 = X.q->memcpy(X.blob, X.hb, NBLOB);
    sycl::event e1 = X.q->submit([&](sycl::handler& cgh) {
        cgh.depends_on(e0);
        sycl::local_accessor<float, 1> sh({128}, cgh);
        cgh.parallel_for(prep_rng, KPrep{X.c, sh});
    });
    sycl::event e2 = X.q->submit([&](sycl::handler& cgh) {
        cgh.depends_on(e1);
        const float* a = X.a; float* c = X.c; float* d = X.d;
        cgh.parallel_for(gemv_rng, [=](sycl::nd_item<1> it) {
            const size_t i = it.get_global_linear_id();
            c[i & (NBIG - 1)] = a[i & (NBIG - 1)] + d[i & (NBIG - 1)] + (float)c11[3];
        });
    });
    sycl::event e3 = X.q->submit([&](sycl::handler& cgh) {
        cgh.depends_on(e2);
        sycl::local_accessor<float, 1> sh({128}, cgh);
        cgh.parallel_for(prep_rng, KPrep{X.e, sh});
    });
    sycl::event e4 = X.q->submit([&](sycl::handler& cgh) {
        cgh.depends_on(e3);
        const float* e = X.e; const float* b = X.b; float* f = X.f;
        cgh.parallel_for(gemv_rng, [=](sycl::nd_item<1> it) {
            const size_t i = it.get_global_linear_id();
            f[i & (NBIG - 1)] = e[i & (NBIG - 1)] + b[i & (NBIG - 1)] + (float)c11[4];
        });
    });
    return X.q->memcpy(X.ho, X.c, NOUT * sizeof(float), {e4});
}

int main(int argc, char** argv) {
    setvbuf(stdout, nullptr, _IONBF, 0);
    const int CHAINS = argc > 1 ? atoi(argv[1]) : 40;
    const int ACT = 6;                                  // actions per chain
    sycl::device dev{sycl::gpu_selector_v};
    sycl::context ctx{dev};
    printf("device %s | chain = H2D blob 1KB + 4 kernels + D2H 10KB = %d actions | %d chains per"
           " window\n\n", dev.get_info<sycl::info::device::name>().c_str(), ACT, CHAINS);

    sycl::queue qooo{dev};
    sycl::queue qio{dev, sycl::property::queue::in_order{}};
    printf("is_in_order: default=%d  in_order=%d   (production builds the default one)\n\n",
           (int)qooo.is_in_order(), (int)qio.is_in_order());

    Chain X;
    X.d = sycl::malloc_device<float>(NBIG, qooo);
    X.a = sycl::malloc_device<float>(NBIG, qooo);
    X.b = sycl::malloc_device<float>(NBIG, qooo);
    X.c = sycl::malloc_device<float>(NBIG, qooo);
    X.e = sycl::malloc_device<float>(NBIG, qooo);
    X.f = sycl::malloc_device<float>(NBIG, qooo);
    X.tab = sycl::malloc_device<unsigned long long>(8, qooo);
    X.blob = sycl::malloc_device<uint8_t>(NBLOB, qooo);
    X.hb = (float*)sycl::malloc_host(NBLOB, ctx);
    X.ho = (float*)sycl::malloc_host(NOUT * sizeof(float), ctx);
    memset((void*)X.hb, 0, NBLOB);
    qooo.memset(X.d, 0, NBIG * 4).wait();
    qooo.memset(X.a, 0, NBIG * 4).wait();
    qooo.memset(X.b, 0, NBIG * 4).wait();
    qooo.memset(X.c, 0, NBIG * 4).wait();
    qooo.memset(X.e, 0, NBIG * 4).wait();
    qooo.memset(X.f, 0, NBIG * 4).wait();
    qooo.memset(X.tab, 0, 64).wait();
    qooo.memset(X.blob, 0, NBLOB).wait();
    X.kgemv = new sycl::kernel(getKernel<kGemv>(qio));

    auto run = [&](const char* nm, sycl::queue& q, bool inorder, int mode) {
        X.q = &q; X.inorder = inorder; X.mode = mode;
        // burn-in (rule 1)
        for (int i = 0; i < 200; ++i) { forward_chain(X); q.wait(); }
        // HOST cost: burst-submit without waiting, device stays busy behind the burst
        double best_h = 1e30;
        for (int w = 0; w < 5; ++w) {
            q.wait();
            const double t0 = us();
            for (int i = 0; i < CHAINS; ++i) forward_chain(X);
            const double dt = us() - t0;
            q.wait();
            best_h = std::min(best_h, dt);
        }
        // WALL: one chain, then a QUEUE wait. Not event.wait(): the handler-free arm returns no
        // event at all, and .wait() on a null event is a no-op - which would have made that arm look
        // 8 us faster for free. Same yardstick for every arm.
        double best_w = 1e30;
        for (int w = 0; w < 5; ++w) {
            q.wait();
            const double t0 = us();
            forward_chain(X);
            q.wait();
            best_w = std::min(best_w, us() - t0);
        }
        // and the plugin's actual completion pattern: wait on the LAST event only
        double best_we = 1e30;
        for (int w = 0; w < 5; ++w) {
            q.wait();
            const double t0 = us();
            sycl::event ent = forward_chain(X);
            (void)ent;
            q.wait();
            best_we = std::min(best_we, us() - t0);
        }
        printf("  %-34s host %6.2f us/action (%6.2f us/chain)   wall %7.2f us\n", nm,
               best_h / (CHAINS * ACT), best_h / CHAINS, best_w);
        (void)best_we;
    };

    printf("HOST column = parent-thread submission cost, device busy behind the burst (the model's\n"
           "`sub` = 5.4 us/action, 27.2 us for 5 actions). WALL column = chain + wait (the model's\n"
           "`wait` = 28.6 us). min-of-5 windows after 200 chains of burn-in.\n\n");
    run("OOO + explicit deps (production)", qooo, false, 0);
    run("OOO + NO deps (unsafe; cost probe)", qooo, false, 1);
    run("in_order + explicit deps", qio, true, 0);
    run("in_order + NO deps (the candidate)", qio, true, 1);
    run("in_order + nd_launch (handler-free)", qio, true, 2);
    run("OOO + nd_launch (handler-free)", qooo, false, 2);

    // ---- contention: does the SUBMITTING THREAD's CPU environment explain the model's 5.4 us/action?
    {
        const char* env = getenv("LAB_SPINNERS");
        const int nspin = env ? atoi(env) : -1;
        std::vector<std::thread> sp;
        std::atomic<bool> go{true};
        if (nspin > 0) for (int i = 0; i < nspin; ++i)
            sp.emplace_back([&] { volatile double z = 1.0; while (go) z = z * 1.0000001 + 1e-9; });
        X.q = &qio; X.mode = 1;
        for (int i = 0; i < 200; ++i) { forward_chain(X); qio.wait(); }
        double best_h = 1e30;
        for (int w = 0; w < 5; ++w) {
            qio.wait();
            const double t0 = us();
            for (int i = 0; i < CHAINS; ++i) forward_chain(X);
            const double dt = us() - t0;
            qio.wait();
            best_h = std::min(best_h, dt);
        }
        go = false;
        for (auto& t : sp) t.join();
        printf("  %-34s host %6.2f us/action  (%d busy spinner threads in this process)\n",
               "in_order + NO deps, contended", best_h / (CHAINS * ACT), nspin);
    }

    // ---- clean call-path comparison: 6 identical launches, handler vs handler-free
    {
        const int c11[7] = {10, 1, 2, 2560, 640, 5, 4};
        sycl::nd_range<1> r{sycl::range<1>{512}, sycl::range<1>{128}};
        sycl::kernel ks = getKernel<kSame>(qio);
        auto burst = [&](const char* nm, sycl::queue& q, int path) {
            for (int i = 0; i < 300; ++i) {
                if (path == 0) q.submit([&](sycl::handler& cgh) {
                    cgh.parallel_for(r, SameFunctor{X.d, X.c, X.e, X.f, X.a, X.b, X.tab,
                                                    10, 1, 2, 2560, 640, 5, 4}); });
                else gx::nd_launch(q, r, ks, X.d, X.a, X.b, X.c, X.e, X.f, X.tab,
                                   gx::raw_kernel_arg{&c11[0], sizeof(int)},
                                   gx::raw_kernel_arg{&c11[1], sizeof(int)},
                                   gx::raw_kernel_arg{&c11[2], sizeof(int)},
                                   gx::raw_kernel_arg{&c11[3], sizeof(int)},
                                   gx::raw_kernel_arg{&c11[4], sizeof(int)},
                                   gx::raw_kernel_arg{&c11[5], sizeof(int)},
                                   gx::raw_kernel_arg{&c11[6], sizeof(int)});
                if (path == 2) q.wait();
            }
            double best = 1e30;
            for (int w = 0; w < 5; ++w) {
                q.wait();
                const double t0 = us();
                for (int i = 0; i < CHAINS; ++i)
                    for (int k = 0; k < ACT; ++k) {
                        if (path == 0 || path == 2) q.submit([&](sycl::handler& cgh) {
                            cgh.parallel_for(r, SameFunctor{X.d, X.c, X.e, X.f, X.a, X.b, X.tab,
                                                            10, 1, 2, 2560, 640, 5, 4}); });
                        else gx::nd_launch(q, r, ks, X.d, X.a, X.b, X.c, X.e, X.f, X.tab,
                                           gx::raw_kernel_arg{&c11[0], sizeof(int)},
                                           gx::raw_kernel_arg{&c11[1], sizeof(int)},
                                           gx::raw_kernel_arg{&c11[2], sizeof(int)},
                                           gx::raw_kernel_arg{&c11[3], sizeof(int)},
                                           gx::raw_kernel_arg{&c11[4], sizeof(int)},
                                           gx::raw_kernel_arg{&c11[5], sizeof(int)},
                                           gx::raw_kernel_arg{&c11[6], sizeof(int)});
                    }
                const double dt = us() - t0;
                q.wait();
                best = std::min(best, dt);
            }
            printf("  %-44s host %6.3f us/launch (%6.2f us for %d launches)\n", nm,
                   best / (CHAINS * ACT), best, CHAINS * ACT);
        };
        printf("\nCall path alone (6 identical launches, same kernel, same 14 args, same device work):\n");
        burst("q.submit functor, in_order queue", qio, 0);
        burst("nd_launch prebuilt kernel, in_order queue", qio, 1);
        burst("q.submit functor, default (OOO) queue", qooo, 0);
        burst("nd_launch prebuilt kernel, default (OOO) queue", qooo, 1);
    }

    printf("\nreading: if `in_order + NO deps` beats `OOO + deps` on the host column, the plugin can"
           " drop the\nevent bookkeeping by building its queue in_order (lab_p1_order proved the"
           " ordering is real);\nif it does not, P1's chains cost nothing and the fixed 57.6 us is"
           " elsewhere.\n");
    printf("NOTE mode 2 (nd_launch) needs the kernel-argument ABI to match exactly; a mismatch shows"
           " as a fault, not a slow number.\n");
    return 0;
}