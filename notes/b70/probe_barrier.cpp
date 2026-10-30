// E25c go/no-go instrument: what does a device-wide barrier cost on this device, and can the schedule that
// would need it even be resident?
//
// Why this is the right first question. gate/up -> silu*up -> down is a true data dependency, so putting all
// three projections in ONE launch means a kernel that (a) writes the intermediate, (b) synchronises every
// work-item, and (c) reads it back for down. Three consequences have to be priced before writing any real
// kernel:
//   1. the barrier costs something, and the prize it buys is one launch (~2.9 us standalone, the per-launch
//      protocol cost measured in out_e25b_combine.txt) - if the two are the same size, E25c is dead already;
//   2. a spin barrier is only safe if every work-item is resident at once, so the grid must fit the device
//      (2048 slots here). Measure the ceiling rather than assume it;
//   3. the phases are sequential inside one kernel, so the register budget is the MAX of the phases - and at
//      rows > 1 the register file is already zero-sum against the prefetch ring (E29, out_e29_share.txt).
// This probe measures (1) with matched work and reports (2) empirically. (3) is argued from E29, not measured.
//
// Barrier used: atomic arrival counter + spin on the same counter, the standard pattern. It is NOT guaranteed
// by the API (there is no cooperative launch here), which is exactly why the run reports whether it completed
// and whether the ordering it claims is real.
#include <sycl/sycl.hpp>
#include <cstdio>
#include <chrono>
#include <cstdlib>
#include <vector>

using namespace sycl;

// One barrier per round, one counter per round, so there is no reset/phase bookkeeping here to deadlock on:
// write my cell, arrive-and-wait, then read a neighbour's cell. After a correct barrier every cell of this
// round is necessarily written, so a mismatch is direct evidence the barrier did not order what it claims to.
// `with_barrier=false` runs the identical body without the barrier, giving a matched-work baseline (and, as a
// side effect, showing whether the mismatch counter can tell the two apart at all).
static void kern(queue &q, int *slot, int *ctr, int G, int R, int *sink, bool with_barrier)
{
    const int stride = R + 1;
    q.parallel_for(nd_range<1>{range<1>(G), range<1>(64)}, [=](nd_item<1> it)
    {
        const int i = (int)it.get_global_id(0);
        const int j = (i + G - 1) % G;                        // neighbour whose value I must observe
        for (int r = 0; r < R; ++r)
        {
            slot[(size_t)i * stride + r] = i + r;
            if (with_barrier)
            {
                atomic_ref<int, memory_order::acq_rel, memory_scope::device, access::address_space::global_space> c(ctr[r]);
                c.fetch_add(1);
                while (c.load(memory_order::acquire) < G) { }
            }
            const int v = slot[(size_t)j * stride + r];
            if (v != j + r)
                atomic_ref<int, memory_order::relaxed, memory_scope::device, access::address_space::global_space>(*sink).fetch_add(1);
        }
    });
    q.wait();
}

int main(int argc, char **argv)
{
    device dev{gpu_selector_v};
    context ctx{dev};
    queue q{ctx, dev, property::queue::in_order{}};
    size_t hw = 2048;
    if (dev.has(aspect::ext_intel_gpu_eu_count) && dev.has(aspect::ext_intel_gpu_hw_threads_per_eu))
        hw = (size_t)dev.get_info<ext::intel::info::device::gpu_eu_count>() *
             dev.get_info<ext::intel::info::device::gpu_hw_threads_per_eu>();
    printf("device reports %zu hw thread slots; work-group size 64\n", hw);

    const int R = argc > 1 ? atoi(argv[1]) : 8;
    const int SG = 4096;                                       // largest grid measured here
    int *slot = (int *)malloc_device((size_t)SG * (R + 1) * 4, q);
    int *ctr  = (int *)malloc_device((size_t)R * 4, q);
    int *sink = (int *)malloc_device(sizeof(int), q);
    q.memset(slot, 0, (size_t)SG * (R + 1) * 4); q.memset(ctr, 0, (size_t)R * 4); q.memset(sink, 0, 4);
    q.wait();

    printf("\n%8s %12s %12s %15s %14s %10s\n", "G", "barrier us", "plain us", "us per barrier",
           "ns/wi/barrier", "mismatch");
    for (int G : {256, 1024, 2048, 3072, 4096})
    {
        double tb = 1e30, tn = 1e30;
        for (int t = 0; t < 5; ++t)
        {
            q.memset(ctr, 0, (size_t)R * 4); q.wait();
            auto t0 = std::chrono::steady_clock::now();
            kern(q, slot, ctr, G, R, sink, true);
            tb = std::min(tb, std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count());
        }
        for (int t = 0; t < 5; ++t)
        {
            auto t0 = std::chrono::steady_clock::now();
            kern(q, slot, ctr, G, R, sink, false);
            tn = std::min(tn, std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count());
        }
        int hsink = 0; q.memcpy(&hsink, sink, 4); q.wait();
        q.memset(ctr, 0, (size_t)R * 4);                        // clean state for the next size
        q.memset(sink, 0, 4); q.wait();                         // report mismatches per G, not cumulatively
        printf("%8d %12.2f %12.2f %15.3f %14.2f %10d%s\n", G, tb * 1e6, tn * 1e6, (tb - tn) * 1e6 / R,
               (tb - tn) * 1e9 / R / G, hsink,
               (size_t)G > hw ? "   <- OVER SUBSCRIBED: completing here is luck, not legality" : "");
    }
    printf("\nReading this: 'us per barrier' is what one device-wide sync costs inside an already-running kernel,\n"
           "at the same work per item with and without it. Compare against the ~2.9 us a whole extra launch\n"
           "costs (out_e25b_combine.txt) - that is the only thing E25c can save. 'mismatch' counts neighbour\n"
           "reads that disagreed with what the writer stored: the barrier runs should contribute 0, and the\n"
           "plain runs are expected to contribute some (there is no ordering there) - if BOTH are zero, this\n"
           "check proves nothing and should not be quoted.\n");
    printf("NOTE: a spin barrier is only safe when every work-item is resident. Above %zu slots the API promises\n"
           "nothing, so an over-subscribed run that finishes is a ceiling to design under, not a pass.\n", hw);
    sycl::free(slot, q); sycl::free(ctr, q); sycl::free(sink, q);
    return 0;
}