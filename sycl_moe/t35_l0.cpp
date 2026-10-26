// t35: per-command latency sources, and can raw ze appends beat SYCL submit on THIS stack?
//   A ) 6 submits + depends_on chain, one wait at end  (what forward_impl does)
//   B ) (n/a: SYCL forbids multiple actions per command group)
//   C ) raw ze appends on the QUEUE'S OWN immediate command list (the pattern the
//       maintained DPC++ e2e test Graph/RecordReplay/NativeRecording uses on BMG-G31):
//       get_native<queue> -> ze_command_list_handle_t, zeKernelSuggestGroupSize,
//       zeCommandListAppendLaunchKernelWithArguments. Same list as the RT => ordering
//       with SYCL ops is automatic; sync = q.wait().
// Lessons baked in from attempts 1-3: hand-rolled ze_context lists + fixed group sizes
// FAULT SILENTLY (kernel executes, writes nothing, later segfaults NEO copies).
#include <sycl/sycl.hpp>
#include <level_zero/ze_api.h>
#include <cstdint>
#include <cstdio>
#include <climits>
#include <chrono>
#include <variant>
#include <vector>

static constexpr int N = 1024;
struct k1 {}; struct k2 {}; struct k3 {}; struct k4 {}; struct k5 {}; struct k6 {};
struct stask {};   // no-builtin constant writer

template <typename K, int J>
static void one(sycl::handler& cgh, int* p)
{
    // store whose VALUE identifies the writer (final 6 iff k6 wrote last)
    cgh.parallel_for<K>(sycl::range<1>(N), [p](sycl::item<1> it) { p[it.get_linear_id()] = J + 1; });
}

using clk = std::chrono::steady_clock;
static double us(clk::time_point a, clk::time_point b) { return std::chrono::duration<double, std::micro>(b - a).count(); }

int main()
{
    sycl::device dev([](const sycl::device& d) { return d.get_info<sycl::info::device::name>().find("Arc") != std::string::npos; });
    sycl::context ctx(dev);
    sycl::queue q(ctx, dev, sycl::property::queue::in_order{});
    int* p = sycl::malloc_device<int>(N, q);
    q.memset(p, 0, N * sizeof(int)).wait();

    const int R = 2000;
    {   // A: 6 chained submits, wait once  (plugin's shape)
        auto t0 = clk::now();
        for (int i = 0; i < R; ++i)
        {
            sycl::event dep;
            for (int j = 0; j < 6; ++j)
                dep = q.submit([&](sycl::handler& cgh) { if (j) cgh.depends_on(dep); cgh.single_task([=] { p[j] = 42; }); });
            dep.wait();
        }
        printf("A  6xsubmit chain+wait: %.2f us/chain\n", us(t0, clk::now()) / R);
    }

    // ---------- C: raw ze on the queue's own immediate list ----------
    auto bundle = sycl::get_kernel_bundle<sycl::bundle_state::executable>(ctx, {dev});
    // force-build ALL kernels via the RT first (ze handles exist only after JIT/build)
    q.submit([=](sycl::handler& cgh) { one<k1, 0>(cgh, p); }).wait();
    q.submit([=](sycl::handler& cgh) { one<k2, 1>(cgh, p); }).wait();
    q.submit([=](sycl::handler& cgh) { one<k3, 2>(cgh, p); }).wait();
    q.submit([=](sycl::handler& cgh) { one<k4, 3>(cgh, p); }).wait();
    q.submit([=](sycl::handler& cgh) { one<k5, 4>(cgh, p); }).wait();
    q.submit([=](sycl::handler& cgh) { one<k6, 5>(cgh, p); }).wait();
    std::vector<ze_kernel_handle_t> zk;
    auto grab = [&](const char* nm, auto kid) {
        if (!bundle.has_kernel(kid)) { printf("no kernel %s\n", nm); return; }
        sycl::kernel k = bundle.get_kernel(kid);
        zk.push_back(sycl::get_native<sycl::backend::ext_oneapi_level_zero>(k));
        ze_kernel_properties_t kp{}; kp.stype = ZE_STRUCTURE_TYPE_KERNEL_PROPERTIES;
        zeKernelGetProperties(zk.back(), &kp);
        printf("kernel %-6s args=%u reqSg=%u\n", nm, kp.numKernelArgs, kp.requiredSubgroupSize);
    };
    grab("k1", sycl::get_kernel_id<k1>()); grab("k2", sycl::get_kernel_id<k2>());
    grab("k3", sycl::get_kernel_id<k3>()); grab("k4", sycl::get_kernel_id<k4>());
    grab("k5", sycl::get_kernel_id<k5>()); grab("k6", sycl::get_kernel_id<k6>());
    if (zk.size() != 6) { printf("missing kernels (%zu)\n", zk.size()); return 1; }

    auto qnat = sycl::get_native<sycl::backend::ext_oneapi_level_zero>(q);
    if (!std::holds_alternative<ze_command_list_handle_t>(qnat))
        { printf("queue native is NOT an immediate command list (variant holds queue handle)\n"); return 2; }
    ze_command_list_handle_t list = std::get<ze_command_list_handle_t>(qnat);
    printf("queue's own imm list: %p\n", (void*)list);

    // --- LIST LITMUS: does a raw append on the RT's list execute AT ALL? Pure DMA,
    //     no kernel, no module, no args - fill 4 bytes at p with pattern 9.
    {
        uint32_t pat = 9;
        q.memset(p, 0, N * sizeof(int)); q.wait();
        ze_result_t fr = zeCommandListAppendMemoryFill(list, p, &pat, sizeof(pat), (size_t)4, nullptr, 0, nullptr);
        q.wait();
        std::vector<uint32_t> hf(1); q.memcpy(hf.data(), p, 4); q.wait();
        printf("LIST LITMUS fill rc=%d p[0]=%u (9 => list executes raw appends; 0 => list is inert/buffered)\n", (int)fr, hf[0]);
    }

    // --- DISCRIMINATOR: no-builtin single_task (writes p[0]=5) launched raw ---
    q.submit([=](sycl::handler& cgh) { cgh.single_task<stask>([=] { p[0] = 5; }); }).wait();
    ze_kernel_handle_t zstask = nullptr;
    if (bundle.has_kernel(sycl::get_kernel_id<stask>()))
        zstask = sycl::get_native<sycl::backend::ext_oneapi_level_zero>(bundle.get_kernel(sycl::get_kernel_id<stask>()));
    if (zstask)
    {
        uint32_t gx = 0, gy = 0, gz = 0;
        zeKernelSuggestGroupSize(zstask, 1, 1, 1, &gx, &gy, &gz);
        printf("stask suggested group %u x %u x %u\n", gx, gy, gz);
        ze_group_size_t gs1{gx ? gx : 1, 1, 1};
        ze_group_count_t gc1{1, 1, 1};
        void* args[] = {&p};
        q.memset(p, 0, N * sizeof(int)); q.wait();
        ze_result_t r1 = zeCommandListAppendLaunchKernelWithArguments(list, zstask, gc1, gs1, args, nullptr, nullptr, 0, nullptr);
        q.wait();
        std::vector<int> h1(1); q.copy(h1.data(), p, 4); q.wait();
        printf("raw stask WithArguments rc=%d p[0]=%d (5 => plumbing fine; item-kernel issue = builtins)\n", (int)r1, h1[0]);
        // old-style: mutate kernel state, plain append
        q.memset(p, 0, N * sizeof(int)); q.wait();
        zeKernelSetArgumentValue(zstask, 0, sizeof(p), &p);
        zeKernelSetGroupSize(zstask, gs1.groupSizeX, 1, 1);
        ze_result_t r2 = zeCommandListAppendLaunchKernel(list, zstask, &gc1, nullptr, 0, nullptr);
        q.wait();
        q.copy(h1.data(), p, 4); q.wait();
        printf("raw stask SetArg+append  rc=%d p[0]=%d\n", (int)r2, h1[0]);
    }

    // suggested group sizes (SIMD-correct)
    ze_group_size_t gs6[6];
    for (int i = 0; i < 6; ++i)
    {
        ze_result_t sr = zeKernelSuggestGroupSize(zk[i], N, 1, 1, &gs6[i].groupSizeX, &gs6[i].groupSizeY, &gs6[i].groupSizeZ);
        if (sr) { printf("suggest rc=%d\n", (int)sr); return 3; }
    }
    printf("suggested group size X: %u\n", gs6[0].groupSizeX);

    auto launch_one = [&](int i) {
        void* args[] = {&p};
        ze_group_count_t gc{(uint32_t)(N / gs6[i].groupSizeX), 1, 1};
        return zeCommandListAppendLaunchKernelWithArguments(list, zk[i], gc, gs6[i], args, nullptr, nullptr, 0, nullptr);
    };
    // correctness first
    q.memset(p, 0, N * sizeof(int)); q.wait();
    ze_result_t lr0 = launch_one(0);
    q.wait();
    {   std::vector<int> h(N); q.copy(h.data(), p, N * sizeof(int)); q.wait();
        printf("raw k1 rc=%d p[5]=%d (1 => raw launch of RT kernel WORKS)\n", (int)lr0, h[5]); }
    q.memset(p, 0, N * sizeof(int)); q.wait();
    for (int i = 0; i < 6; ++i) launch_one(i);
    q.wait();
    {   std::vector<int> h(N); q.copy(h.data(), p, N * sizeof(int)); q.wait();
        int nz = 0; for (int v : h) if (v) ++nz;
        printf("raw 6-chain (in-order queue) p[5]=%d nonzero=%d (6/1024 => serialized+correct)\n", h[5], nz); }

    // timing: host append cost and full roundtrip
    {   auto t0 = clk::now();
        for (int i = 0; i < R; ++i) for (int j = 0; j < 6; ++j) launch_one(j);
        q.wait();
        printf("C  6xraw-append host:  %.2f us/chain\n", us(t0, clk::now()) / R);  }
    {   auto t0 = clk::now();
        for (int i = 0; i < R; ++i) { for (int j = 0; j < 6; ++j) launch_one(j); q.wait(); }
        printf("C' 6xraw-append+wait:  %.2f us/chain\n", us(t0, clk::now()) / R); }
    printf("A-C = %.1f us/chain saved by raw appends\n", 0.0);
    return 0;
}