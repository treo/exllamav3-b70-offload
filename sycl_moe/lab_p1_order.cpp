// lab_p1_order.cpp — is NOTES' top platform trap (P1) actually a runtime bug?
//
// P1 as written: "on this stack an in-order queue does NOT serialize q.memcpy after q.submit
// kernels; only explicit depends_on/{deps} edges are honored". Asked outside, that description drew
// the answer: no spec allows it, so it is a bug in our code or in the runtime, and the named
// suspects are (1) reading the destination before the copy completes, (2) two separately built
// queues, (3) the property not actually applying, (4) graph-recording mode - plus two A/B env knobs
// (UR_L0_USE_COPY_ENGINE=0, UR_L0_USE_DRIVER_COUNTER_BASED_EVENTS=0) that separate copy-engine
// cross-engine ordering from same-engine ordering.
//
// Inspecting the code first: the queue that production actually uses has NO in_order property at all
// (b70_lib.cpp: `static sycl::queue queue{gpu_selector_v, async_handler{...}}`), and neither does
// bench_layer.cpp's (`{gpu_selector_v, {enable_profiling}}`). Files that DO pass in_order are the
// labs. On a default OUT-OF-ORDER queue, an unchained memcpy racing a kernel is required behaviour,
// not a bug - which would mean P1 documents correct mitigation for a mis-diagnosed cause.
//
// This lab settles it by measuring both queues under the same adversarial pattern, with the property
// ASSERTED at runtime rather than assumed:
//
//   T1  D2H after a kernel that writes the source, NO dependency edge.
//       The device buffer carries a monotonically increasing sentinel per iteration, so a copy that
//       starts early reads the PREVIOUS iteration's value: a mismatch IS the violation, and it is
//       undetectable-as-stale only if it equals the current sentinel. Host reads the destination
//       strictly AFTER q.wait(), so suspect (1) is structurally excluded.
//   T2  kernel after a H2D copy that wrote its source, no edge (the other direction).
//   T3  same as T1 but with the explicit event chain production uses -> must be 0 violations.
//   T4  same as T1 with an injected host-side delay between kernel submit and copy, widening the
//       window (a race that needs luck to hit will hit here).
//   T5  two separately built in-order queues, copies issued on the other one - suspect (2), the
//       shape a "second queue for telemetry" would produce.
//
// Every arm prints is_in_order() and its denominator, per rule 11.
//   source ../sycl_moe/env.sh
//   icpx -fsycl -O2 -w lab_p1_order.cpp -o lab_p1_order
//   ./lab_p1_order [iters] [kernel_spin_us_equiv]
//   for AB in "" UR_L0_USE_COPY_ENGINE=0 UR_L0_USE_DRIVER_COUNTER_BASED_EVENTS=0; do env $AB ./lab_p1_order; done
#include <sycl/sycl.hpp>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

static double now_us() {
    return std::chrono::duration<double, std::micro>(
        std::chrono::steady_clock::now().time_since_epoch()).count();
}

static constexpr size_t NBUF = 4u << 20;          // 4 MB of uint32 (1 M elements)
static constexpr size_t NELEM = NBUF / sizeof(uint32_t);

// Fill the whole device buffer with `val`. LONG enough (4 MB of stores) that an unchained 4 MB copy
// launched right after it will visibly overlap if ordering is not enforced.
struct Fill {
    uint32_t* p;
    uint32_t v;
    void operator()(sycl::item<1> i) const { p[i.get_id(0)] = v; }
};

int main(int argc, char** argv) {
    setvbuf(stdout, nullptr, _IONBF, 0);
    const int ITER = argc > 1 ? atoi(argv[1]) : 500;
    const long DELAY_US = argc > 2 ? atol(argv[2]) : 0;

    sycl::device dev{sycl::gpu_selector_v};
    sycl::context ctx{dev};
    printf("device %s | iters %d | delay_between_submit_and_copy %ld us | buffer %zu MB\n",
           dev.get_info<sycl::info::device::name>().c_str(), ITER, DELAY_US, NBUF >> 20);

    // --- the three queue flavours
    sycl::queue qdef{dev, sycl::async_handler{[](sycl::exception_list el) {
                         for (auto& e : el) { try { std::rethrow_exception(e); } catch (...) {} }
                     }}};                                   // exactly what production builds
    sycl::queue qio{dev, sycl::property::queue::in_order{}};  // what P1 claims fails
    sycl::queue qio2{dev, sycl::property::queue::in_order{}}; // a SECOND in-order queue (suspect 2)
    printf("is_in_order: production-shaped=%d   in_order=%d   second_in_order=%d\n\n",
           (int)qdef.is_in_order(), (int)qio.is_in_order(), (int)qio2.is_in_order());

    uint32_t* d = sycl::malloc_device<uint32_t>(NELEM, qdef);
    uint32_t* d2 = sycl::malloc_device<uint32_t>(NELEM, qdef);
    uint32_t* hs = (uint32_t*)sycl::malloc_host(NBUF, ctx);   // pinned source
    uint32_t* hd = (uint32_t*)sycl::malloc_host(NBUF, ctx);   // pinned destination
    qdef.memset(d, 0, NBUF).wait();
    qdef.memset(d2, 0, NBUF).wait();
    memset(hd, 0, NBUF);

    auto viol = [&](const char* nm, sycl::queue& q, int mode) -> void {
        long bad = 0, first_bad = -1;
        const double t0 = now_us();
        for (int it = 1; it <= ITER; ++it) {
            const uint32_t sentinel = (uint32_t)it * 2654435761u;
            if (mode == 0 || mode == 2 || mode == 4) {           // D2H after writer kernel
                if (mode == 4) {
                    // T5: kernel on one in-order queue, copy on ANOTHER in-order queue, no edge
                    // between them - the shape a second telemetry/copy queue silently creates.
                    q.parallel_for(sycl::range<1>{NELEM}, Fill{d, sentinel});
                    qio2.memcpy(hd, d, NBUF);
                    q.wait(); qio2.wait();                        // both done before the host looks
                } else if (mode == 2) {                           // T3: explicit chain (control)
                    sycl::event e = q.parallel_for(sycl::range<1>{NELEM}, Fill{d, sentinel});
                    q.memcpy(hd, d, NBUF, {e});
                    q.wait();
                } else {                                          // T1/T4: no dependency edge
                    q.parallel_for(sycl::range<1>{NELEM}, Fill{d, sentinel});
                    if (DELAY_US > 0) { const double t = now_us();
                        while (now_us() - t < DELAY_US) {} }
                    q.memcpy(hd, d, NBUF);
                    q.wait();                                     // host reads ONLY after this
                }
            } else if (mode == 7) {                                // T8: EVENT-WAIT visibility
                // The strongest claim in P1: "an event .wait() can complete before the data is
                // host-readable". If true on a properly CHAINED copy, that is a runtime bug, not a
                // usage trap - so chain everything and wait only on the copy's own event.
                sycl::event ke = q.parallel_for(sycl::range<1>{NELEM}, Fill{d, sentinel});
                sycl::event ce = q.memcpy(hd, d, NBUF, {ke});
                ce.wait();                                        // NO q.wait() afterwards
            } else if (mode == 5 || mode == 6) {                  // T6/T7: does a BARRIER substitute?
                for (size_t i = 0; i < NELEM; ++i) hs[i] = sentinel + (uint32_t)i;
                sycl::event ce = q.memcpy(d, hs, NBUF);
                if (mode == 6) q.ext_oneapi_submit_barrier({ce});  // barrier WITH the copy event
                else q.ext_oneapi_submit_barrier();                // bare barrier: no dependency edges
                q.parallel_for(sycl::range<1>{NELEM}, [=](sycl::item<1> i) {
                    hd[i.get_id(0)] = d[i.get_id(0)];
                });
                q.wait();
            } else {                                              // T2: kernel after H2D copy
                for (size_t i = 0; i < NELEM; ++i) hs[i] = sentinel + (uint32_t)i;
                q.memcpy(d, hs, NBUF);
                if (DELAY_US > 0) { const double t = now_us();
                    while (now_us() - t < DELAY_US) {} }
                q.parallel_for(sycl::range<1>{NELEM},
                               Fill{hd, 0u});                     // touch the pipe
                q.parallel_for(sycl::range<1>{NELEM}, [=](sycl::item<1> i) {
                    hd[i.get_id(0)] = d[i.get_id(0)];             // copy-through-device
                });
                q.wait();
            }
            // ONE element is enough: every element of the buffer holds the same sentinel in the D2H
            // arms. Spot-check a few positions to catch partial-overlap cases too.
            uint32_t want = sentinel;
            if (mode == 7 && (hd[0] != sentinel || hd[NELEM/2] != sentinel ||
                              hd[NELEM - 1] != sentinel)) {
                ++bad; if (first_bad < 0) first_bad = it;
            } else if ((mode == 0 || mode == 2 || mode == 4) &&
                (hd[0] != want || hd[NELEM / 2] != want || hd[NELEM - 1] != want)) {
                ++bad;
                if (first_bad < 0) first_bad = it;
            } else if (mode == 1 || mode == 5 || mode == 6) {
                bool ok = true;
                for (size_t i = 0; i < NELEM; i += 65536)
                    if (hd[i] != sentinel + (uint32_t)i) { ok = false; break; }
                if (!ok) { ++bad; if (first_bad < 0) first_bad = it; }
            }
        }
        printf("  %-52s violations %5ld / %d => %s%s\n", nm, bad, ITER,
               bad ? "NOT ordered" : "ordered", "");
        if (bad) printf("      (first violation at iteration %ld)\n", first_bad);
    };

    printf("T1  D2H after writer kernel, NO edge:\n");
    viol("  production-shaped queue (no in_order)", qdef, 0);
    viol("  in_order queue", qio, 0);
    printf("T4  same, with %ld us host delay between submit and copy (widened window):\n", DELAY_US);
    viol("  production-shaped queue (no in_order)", qdef, 0);
    viol("  in_order queue", qio, 0);
    printf("T3  control: explicit event chain, production style:\n");
    viol("  production-shaped queue + {deps}", qdef, 2);
    printf("T2  writer kernel after H2D copy, NO edge:\n");
    viol("  production-shaped queue (no in_order)", qdef, 1);
    viol("  in_order queue", qio, 1);
    printf("T5  two separate in_order queues (copy on the other one):\n");
    viol("  kernel on q, memcpy on queue #2", qio, 4);
    printf("T8  chained copy, host reads after copy-event .wait() only (no queue wait):\n");
    viol("  production-shaped queue, fully chained + ev.wait()", qdef, 7);
    viol("  in_order queue, fully chained + ev.wait()", qio, 7);
    printf("T6/T7  can a barrier substitute for a dependency edge? (kernel after H2D, no edge)\n");
    viol("  production-shaped queue + bare submit_barrier()", qdef, 5);
    viol("  production-shaped queue + submit_barrier({copy ev})", qdef, 6);
    viol("  in_order queue + bare submit_barrier()", qio, 5);

    printf("\nreading: T1/in_order violations==0 means an in-order queue DOES serialize and P1 is a\n"
           "mis-diagnosis (production builds a non-in_order queue, so it must chain explicitly);\n"
           "violations>0 with is_in_order=1 is a real runtime bug worth filing.\n");
    sycl::free(d, qdef); sycl::free(d2, qdef); sycl::free(hs, ctx); sycl::free(hd, ctx);
    return 0;
}