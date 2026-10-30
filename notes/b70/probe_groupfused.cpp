// E25c WITHOUT a device-wide barrier: possible? This prices the primitive that question turns on.
//
// out_e25c_barrier.txt rejected "gate+up+down in one launch" because down's input is produced by other
// work-items, so the naive mapping needs a GRID-WIDE spin barrier: 6.2 us at the device's 2048-slot capacity to
// save a ~2.9 us launch. But a grid-wide sync is only required if the dependency crosses work-groups. It does
// not have to:
//
//   ROUTE 1 (group-scoped). Give ONE work-group the whole chain for one expert: its lanes cooperate on gate/up,
//     publish h into SLM, `it.barrier()` (a WORK-GROUP barrier - hardware, and legal without any residency
//     argument because a work-group is the unit the scheduler guarantees is co-resident), then the same group
//     consumes h for down. Extra prize: if the group also owns the row, the silu*mul and the re-quantisation of
//     h for down's A operand (which needs amax over the whole row) become group reductions, so the combine
//     launch disappears too when KS=1 (no split-K partials to combine).
//     Cost side: SLM staging of h, group syncs, and a coarser mapping. With 10 experts and a 128-lane group per
//     expert that is 1280 lanes - comparable to the 1600 the current fused gate+up launch uses at E=10 KS=1, so
//     the concurrency worry is real but not obviously fatal. THIS FILE MEASURES THE SYNC AND SLM PRIMITIVES; the
//     mapping question needs a real kernel and stays open.
//
//   ROUTE 2 (dataflow flags). Order producers before consumers and spin per expert. Still a spin dependency, and
//     a spinning consumer holds a slot a producer may need. The existing flag round-trip numbers (resident-engine
//     doorbell 3.2 us; fence-visible stores ~us) already put it at the price of the launch it would save. Not
//     measured here.
//
// Every variant runs the SAME body with and without the sync, and only the delta is reported: the launch and the
// data movement cancel. (a) additionally warns where the comparison is not apples-to-apples.
#include <sycl/sycl.hpp>
#include <cstdio>
#include <chrono>
#include <cstdlib>

using namespace sycl;

static constexpr int R = 8;
static constexpr int SLOT_STRIDE = R + 1;

static void bump(int *sink)
{
    atomic_ref<int, memory_order::relaxed, memory_scope::device, access::address_space::global_space>(*sink).fetch_add(1);
}

// (a) grid-wide spin barrier with a global hand-off (the E25c-as-proposed coordination), sync optional.
static void dev_wide(queue &q, int *slot, int *ctr, int G, int *sink, bool sync)
{
    q.parallel_for(nd_range<1>{range<1>(G), range<1>(64)}, [=](nd_item<1> it)
    {
        const int i = (int)it.get_global_id(0);
        const int j = (i + G - 1) % G;
        for (int r = 0; r < R; ++r)
        {
            slot[(size_t)i * SLOT_STRIDE + r] = i + r;
            if (sync)
            {
                atomic_ref<int, memory_order::acq_rel, memory_scope::device, access::address_space::global_space> c(ctr[r]);
                c.fetch_add(1);
                while (c.load(memory_order::acquire) < G) { }
            }
            if (slot[(size_t)j * SLOT_STRIDE + r] != j + r) bump(sink);
        }
    });
    q.wait();
}

// (c) work-group barrier, nothing else.
static void grp_only(queue &q, int G, int wg, bool sync)
{
    q.parallel_for(nd_range<1>{range<1>(G), range<1>(wg)}, [=](nd_item<1> it)
    { for (int r = 0; r < R; ++r) if (sync) it.barrier(); });
    q.wait();
}

// (b) the route-1 pattern: hand off the actual intermediate - one expert's h, which is rows x 640 values -
// through SLM, with two group barriers per round (publish / consume). per_lane follows from the real size, so
// this measures the footprint the design would actually carry rather than an arbitrary one.
static void grp_slm(queue &q, int *slot, int G, int wg, int hvals, bool sync)
{
    const int per_lane = (hvals + wg - 1) / wg;
    q.submit([&](handler &h)
    {
        local_accessor<int, 1> sm((size_t)wg * per_lane, h);
        h.parallel_for(nd_range<1>{range<1>(G), range<1>(wg)}, [=](nd_item<1> it)
        {
            const int li = (int)it.get_local_id(0);
            const int gi = (int)it.get_global_id(0);
            const int base = li * per_lane;
            for (int r = 0; r < R; ++r)
            {
                for (int k = 0; k < per_lane; ++k) sm[base + k] = li + r;
                if (sync) it.barrier();
                int acc = 0;
                for (int k = 0; k < per_lane; ++k) acc += sm[base + k];
                slot[(size_t)gi * SLOT_STRIDE + r] = acc;          // keep the read live
                if (sync) it.barrier();
            }
        });
    });
    q.wait();
}

// (d) the same shape but handing off through global/L2 instead of SLM (what happens if h will not fit in SLM).
static void grp_global(queue &q, int *slot, int G, int wg, bool sync)
{
    q.parallel_for(nd_range<1>{range<1>(G), range<1>(wg)}, [=](nd_item<1> it)
    {
        const int i = (int)it.get_global_id(0);
        const int li = (int)it.get_local_id(0);
        const int j = i - li + ((li + wg - 1) % wg);
        for (int r = 0; r < R; ++r)
        {
            slot[(size_t)i * SLOT_STRIDE + r] = i + r;
            if (sync) it.barrier();
            (void)slot[(size_t)j * SLOT_STRIDE + r];
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
    const int G = argc > 1 ? atoi(argv[1]) : (int)hw;
    const int ROWS = argc > 2 ? atoi(argv[2]) : 1;          // decode rows: h per expert is ROWS x 640
    const int hvals = ROWS * 640;
    const size_t lmem = dev.get_info<info::device::local_mem_size>();
    const size_t max_wg = dev.get_info<info::device::max_work_group_size>();
    int *slot = (int *)sycl::malloc_device((size_t)G * SLOT_STRIDE * 4, q);
    int *ctr  = (int *)sycl::malloc_device((size_t)R * 4, q);
    int *sink = (int *)sycl::malloc_device(4, q);
    q.memset(slot, 0, (size_t)G * SLOT_STRIDE * 4); q.memset(ctr, 0, (size_t)R * 4); q.memset(sink, 0, 4); q.wait();

    auto best_of = [&](auto fn)
    {
        double b = 1e30;
        for (int t = 0; t < 5; ++t)
        {
            auto t0 = std::chrono::steady_clock::now();
            fn();
            b = std::min(b, std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count());
        }
        return b * 1e6;
    };

    printf("total work-items %d (device capacity %zu), %d rounds per launch, min of 5 per measurement\n"
           "intermediate handed off per group: %d x 640 = %d ints = %.1f KiB   |   local memory per group: %zu"
           " bytes, max work-group size: %zu\n\n", G, hw, R, ROWS, hvals, hvals * 4.0 / 1024.0, lmem, max_wg);

    double a = 1e30;
    for (int t = 0; t < 5; ++t)
    {
        q.memset(ctr, 0, (size_t)R * 4); q.wait();
        auto t0 = std::chrono::steady_clock::now();
        dev_wide(q, slot, ctr, G, sink, true);
        a = std::min(a, std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count());
    }
    a *= 1e6;
    double a0 = best_of([&]{ dev_wide(q, slot, ctr, G, sink, false); });
    printf("  (a) GRID-WIDE spin barrier, %d work-items: %7.2f us gross, %5.2f unbarriered  ->  %.3f us per barrier\n",
           G, a, a0, (a - a0) / R);

    printf("\n  work-group scoped equivalents (route 1):\n");
    for (int wg : {64, 128, 256, 512, 1024})
    {
        if (wg > G || (size_t)wg > max_wg) continue;
        const int per_lane = (hvals + wg - 1) / wg;
        const size_t sm_bytes = (size_t)wg * per_lane * 4;
        if (sm_bytes > lmem)
        {
            printf("   wg=%5d:  SKIPPED - h needs %.1f KiB of SLM, above the %zu byte per-group limit"
                   "   <- this is route 1's real ceiling\n", wg, sm_bytes / 1024.0, lmem);
            continue;
        }
        double c0 = best_of([&]{ grp_only(q, G, wg, false); });
        double c  = best_of([&]{ grp_only(q, G, wg, true); });
        double b0 = best_of([&]{ grp_slm(q, slot, G, wg, hvals, false); });
        double b  = best_of([&]{ grp_slm(q, slot, G, wg, hvals, true); });
        double d0 = best_of([&]{ grp_global(q, slot, G, wg, false); });
        double d  = best_of([&]{ grp_global(q, slot, G, wg, true); });
        printf("   wg=%5d:  (c) sync only %6.2f->%6.2f |  (b) via SLM %7.2f->%7.2f (%.1f KiB) |"
               "  (d) via global %6.2f->%6.2f     net per barrier:  c %.3f   b %.3f   d %.3f us\n",
               wg, c0, c, b0, b, sm_bytes / 1024.0, d0, d,
               (c - c0) / R, (b - b0) / (2.0 * R), (d - d0) / (2.0 * R));   // (b),(d): two barriers per round
    }

    int hsink = 0; q.memcpy(&hsink, sink, 4); q.wait();
    printf("\nmismatch counter = %d. NOTE: as in probe_barrier, the UNBARRIERED runs also feed this counter and it", hsink);
    printf(" stayed %d, so this check cannot distinguish a working barrier from no barrier - it is NOT evidence", hsink);
    printf(" that any barrier here delivers visibility.\n");
    printf("WHAT IS AND IS NOT ANSWERED: the numbers above price the SYNC and the hand-off path. They do not\n"
           " price route 1's real cost, which is the coarser mapping (one group per expert instead of one thread\n"
           " per column tile) - D4 established that thread-level parallelism is what hides latency at rows=1, so\n"
           " the honest reading is: if the group sync is cheap, E25c's viability turns entirely on the mapping,\n"
           " and that needs a kernel, not a primitive probe.\n");
    sycl::free(slot, q); sycl::free(ctr, q); sycl::free(sink, q);
    return 0;
}