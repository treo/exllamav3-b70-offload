// t46_pub.cpp - does it.barrier(fence_space::global_space) PUBLISH (flush) a WG's global
// stores to the point where another WG's DEVICE-atomic load sees them? Writers store the
// launch index into their cells, bump a release counter; one reader WG acquire-spins on
// the counter, then verifies EVERY cell with device-atomic loads (L2, not L1). Data value
// increases every launch, so both same-launch publication failures AND cross-launch
// staleness show up as "seen < cur".
//
// LESSON (first version of this lab produced total garbage - 58% "failures" INCLUDING
// values from FUTURE launches, which is physically impossible under serialized
// execution): the launches were submitted WITHOUT depends_on chaining - on this stack
// (NOTES bug #8) implicit in-order ordering is fiction, the launches overlapped, and the
// lab measured concurrency, not coherence. EVERY submit below is chained. Read this
// before concluding anything from a "failed" microbench on this box.
#include <sycl/sycl.hpp>
#include <cstdio>
#include <cstdlib>

template <int WMODE>   // 0 plain store, 1 atomic relaxed store, 2 atomic release store
struct Pub {
    int* data;    // NW*32 cells
    int* ctr;     // arrival counter (monotonic across launches)
    int* bad;     // accumulated mismatch count
    int tag;      // this launch's value
    int base;     // counter value before this launch's writers (expected start)
    static constexpr int NW = 32;

    auto get(sycl::ext::oneapi::experimental::properties_tag) const
    {
        return sycl::ext::oneapi::experimental::properties{
            sycl::ext::oneapi::experimental::sub_group_size<16>};
    }

    void operator()(sycl::nd_item<1> it) const
    {
        const int wg = (int)it.get_group(0);
        const int tid = (int)it.get_local_id(0);
        if (wg < NW) {
            int* p = data + wg * 32;
#pragma unroll
            for (int i = 0; i < 32; ++i) {
                if constexpr (WMODE == 0) p[i] = tag;           // plain stores (like tsw)
                else if constexpr (WMODE == 1) {
                    sycl::atomic_ref<int, sycl::memory_order::relaxed, sycl::memory_scope::device,
                        sycl::access::address_space::global_space> ws(p[i]);
                    ws.store(tag, sycl::memory_order::relaxed);
                } else {
                    sycl::atomic_ref<int, sycl::memory_order::relaxed, sycl::memory_scope::device,
                        sycl::access::address_space::global_space> ws(p[i]);
                    ws.store(tag, sycl::memory_order::release);
                }
            }
            it.barrier(sycl::access::fence_space::global_space);  // publish?
            if (tid == 0) {
                sycl::atomic_ref<int, sycl::memory_order::acq_rel, sycl::memory_scope::device,
                                 sycl::access::address_space::global_space> ar(*ctr);
                ar.fetch_add(1, sycl::memory_order::acq_rel);
            }
            return;
        }
        // reader WG: acquire-spin until all NW writers bumped this launch, then verify
        if (tid == 0) {
            sycl::atomic_ref<int, sycl::memory_order::relaxed, sycl::memory_scope::device,
                             sycl::access::address_space::global_space> ar(*ctr);
            while (ar.load(sycl::memory_order::acquire) - base < NW) {}
        }
        sycl::group_barrier(it.get_group());
        for (int i = tid; i < NW * 32; i += 128) {
            sycl::atomic_ref<int, sycl::memory_order::relaxed, sycl::memory_scope::device,
                             sycl::access::address_space::global_space> dc(data[i]);
            const int v = dc.load(sycl::memory_order::relaxed);
            if (v == tag) continue;
            int slot = (v == tag - 1) ? 0 : (v < tag ? 1 : 2);   // lag1 / older / future
            sycl::atomic_ref<int, sycl::memory_order::relaxed, sycl::memory_scope::device,
                             sycl::access::address_space::global_space> b(bad[slot]);
            b.fetch_add(1, sycl::memory_order::relaxed);
        }
    }
};

int main(int argc, char** argv)
{
    const int iters = argc > 1 ? atoi(argv[1]) : 2000;
    const int wmode = argc > 2 ? atoi(argv[2]) : 0;
    sycl::queue q;
    std::printf("device: %s, iters %d\n", q.get_device().get_info<sycl::info::device::name>().c_str(), iters);
    int* data = sycl::malloc_device<int>(Pub<0>::NW * 32, q);
    int* ctr = sycl::malloc_device<int>(4, q);
    int* bad = sycl::malloc_device<int>(4, q);
    q.memset(data, 0, Pub<0>::NW * 32 * 4); q.memset(ctr, 0, 16); q.memset(bad, 0, 16); q.wait();
    sycl::event prev;
    for (int i = 1; i <= iters; ++i) {
        prev = q.submit([&](sycl::handler& cgh) {
            if (i > 1) cgh.depends_on(prev);          // EXPLICIT chain (bug #8 doctrine)
            if (wmode == 0) cgh.parallel_for(sycl::nd_range<1>({(Pub<0>::NW + 1) * 128}, {128}), Pub<0>{data, ctr, bad, i, 32 * (i - 1)});
            else if (wmode == 1) cgh.parallel_for(sycl::nd_range<1>({(Pub<1>::NW + 1) * 128}, {128}), Pub<1>{data, ctr, bad, i, 32 * (i - 1)});
            else cgh.parallel_for(sycl::nd_range<1>({(Pub<2>::NW + 1) * 128}, {128}), Pub<2>{data, ctr, bad, i, 32 * (i - 1)});
        });
    }
    int hb[3] = {0, 0, 0};
    q.memcpy(hb, bad, 12).wait();
    std::printf("wmode %d: lag1 %d  older %d  future %d  / %d checks\n",
                wmode, hb[0], hb[1], hb[2], iters * Pub<0>::NW * 32);
    std::printf("mismatches: %d\n", hb[0] + hb[1] + hb[2]);
    return hb[0] + hb[1] + hb[2] != 0;
}