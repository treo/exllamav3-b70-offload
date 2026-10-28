// B70 transport capability probe (dev scaffolding, not part of the library).
//
// Measures the Level Zero / SYCL facts the MoE-offload design rests on, in one process, with
// every wait bounded so a driver wedge cannot hang the box. Section numbers match the report:
//
//   1  device properties the kernel design needs
//   2  host(pinned USM) <-> device copy bandwidth and per-copy latency at the sizes the decode
//      handoff actually moves (~15 KiB down, ~10 KiB up at H=2560), with the PCIe link state
//      sampled while the copy engine is busy
//   3  what a job costs as "submit commands, wait for an event": memcpy / empty kernel /
//      one-kernel-per-job round trips
//   4  zero-copy: a kernel reading / writing host-pinned memory in place
//   5  resident (persistent) kernel driven by a host doorbell in pinned memory: the round-trip
//      floor with no submission on the critical path, scaled by work-group count
//   6  what a parked engine costs the rest of the card (copies and FMA throughput on a second
//      queue), and the board power drawn while parked
//   7  register_host_memory: the same doorbell through a *foreign* host mapping (what the
//      multiprocessing.shared_memory handoff region is)
//
// build:  source /opt/intel/oneapi/setvars.sh && icpx -fsycl -O2 -o probe_transport probe_transport.cpp
// run:    timeout 300 ./probe_transport [resident_wg]

#include <sycl/sycl.hpp>

#include <atomic>
#include <cerrno>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <thread>
#include <vector>
#include <sys/mman.h>

using namespace std::chrono;

// --------------------------------------------------------------------------- helpers

static const char *szof(size_t n)
{
    static char buf[32];
    if (n >= (1u << 20) && n % (1u << 20) == 0) snprintf(buf, sizeof buf, "%zu MiB", n >> 20);
    else if (n >= 1024) snprintf(buf, sizeof buf, "%zu KiB", n >> 10);
    else snprintf(buf, sizeof buf, "%zu B", n);
    return buf;
}

static double now_us() { return duration<double, std::micro>(steady_clock::now().time_since_epoch()).count(); }

static int dcmp(const void *a, const void *b)
{
    double x = *(const double *) a, y = *(const double *) b;
    return x < y ? -1 : (x > y ? 1 : 0);
}
struct Stats
{
    std::vector<double> v;
    void add(double x) { v.push_back(x); }
    double q(double p)
    {
        if (v.empty()) return -1;
        std::vector<double> s = v;
        qsort(s.data(), s.size(), sizeof(double), dcmp);
        return s[size_t(p * (s.size() - 1) + 0.5)];
    }
    double med() { return q(0.5); }
    double p90() { return q(0.9); }
    double mx() { return q(1.0); }
};

// one host-visible flag line. Host side is volatile: the optimiser must not hoist a poll out
// of a spin loop (that bug cost a whole first revision of this probe), and the fences below
// keep the polls ordered against the payload accesses. Device side is a system-scope
// sycl::atomic_ref over the same address.
struct Flag { alignas(64) volatile uint32_t v; };
static inline uint32_t flag_load(volatile uint32_t *p)
{
    std::atomic_thread_fence(std::memory_order_seq_cst);
    uint32_t x = *p;
    std::atomic_thread_fence(std::memory_order_seq_cst);
    return x;
}
static inline void flag_store(volatile uint32_t *p, uint32_t x)
{
    std::atomic_thread_fence(std::memory_order_seq_cst);
    *p = x;
    std::atomic_thread_fence(std::memory_order_seq_cst);
}

static void read_sysfs(const char *path, char *out, size_t n)
{
    FILE *f = fopen(path, "r");
    out[0] = 0;
    if (!f) return;
    if (fgets(out, int(n), f)) { size_t l = strlen(out); while (l && (out[l - 1] == '\n' || out[l - 1] == ' ')) out[--l] = 0; }
    fclose(f);
}

struct Power
{
    FILE *f = nullptr;
    const char *path = "/sys/class/drm/card1/device/hwmon/hwmon7/energy1_input";   // label "card", microjoules
    long long base = 0; double t0 = 0;
    bool ok = false;
    void start()
    {
        f = fopen(path, "r");
        if (!f) return;
        long long v;
        if (fscanf(f, "%lld", &v) == 1) { base = v; ok = true; }
        rewind(f); t0 = now_us();
    }
    double watts()
    {
        if (!ok) return -1;
        long long v;
        if (fscanf(f, "%lld", &v) != 1) return -1;
        rewind(f);
        double dt = (now_us() - t0) * 1e-6;
        return dt > 0 ? double(v - base) * 1e-6 / dt : -1;
    }
    ~Power() { if (f) fclose(f); }
};

// --------------------------------------------------------------------------- resident engine
//
// ngroups work-groups, one lane each doing the polling. Mirrors the CPU worker's spin loop, but
// parked on the card: host bumps `db`, every group notices and increments `ack`, host waits for
// all acks, then clears `ack` for the next round. Exits on `quit` or after a bounded spin.
static void submit_resident(sycl::queue &q, uint32_t ngroups, uint32_t wgs,
                            uint32_t *db, uint32_t *ack, uint32_t *quit,
                            uint32_t *payload_in, uint32_t *payload_out, size_t payload_words,
                            uint32_t *status)
{
    q.submit([=](sycl::handler &cgh)
    {
        cgh.parallel_for(sycl::nd_range<1>(sycl::range<1>(size_t(ngroups) * wgs), sycl::range<1>(wgs)),
            [=](sycl::nd_item<1> it)
            {
                using sys_atom = sycl::atomic_ref<uint32_t, sycl::memory_order::acq_rel,
                                                  sycl::memory_scope::system,
                                                  sycl::access::address_space::global_space>;
                sys_atom adb(*db), aack(*ack), aquit(*quit);
                const uint32_t wg = uint32_t(it.get_group(0));
                const uint32_t li = uint32_t(it.get_local_id(0));
                if (li == 0)
                {
                    uint32_t last = adb.load(sycl::memory_order::acquire);
                    for (uint64_t spin = 0; spin < 200'000'000ull; ++spin)
                    {
                        const uint32_t cur = adb.load(sycl::memory_order::acquire);
                        if (cur != last)
                        {
                            last = cur;
                            // one lane echoes the doorbell value so the host can tell a stale
                            // store from a real read-back of the payload
                            if (payload_in && payload_out && wg == 0)
                            {
                                uint32_t s = 0;
                                for (size_t i = 0; i < payload_words; ++i) s += payload_in[i];
                                payload_out[0] = s;
                            }
                            aack.fetch_add(1, sycl::memory_order::acq_rel);
                        }
                        if (aquit.load(sycl::memory_order::relaxed)) return;
                    }
                    sycl::atomic_ref<uint32_t, sycl::memory_order::relaxed, sycl::memory_scope::device,
                                     sycl::access::address_space::global_space>(*status).store(0xDEAD);
                    return;
                }
                // the other lanes of group 0 just park too (they exist to show a wider
                // resident footprint is possible); all groups must reach the ack count
                uint32_t last = adb.load(sycl::memory_order::acquire);
                for (uint64_t spin = 0; spin < 200'000'000ull; ++spin)
                {
                    if (adb.load(sycl::memory_order::acquire) != last) last = adb.load(sycl::memory_order::acquire);
                    if (aquit.load(sycl::memory_order::relaxed)) return;
                }
            });
    });
    q.ext_oneapi_submit_barrier();   // force submission without waiting (queue::flush is gone in SYCL 2020)
}

static bool host_round_trips(volatile uint32_t *db, volatile uint32_t *ack, uint32_t ngroups,
                             int iters, Stats &rt)
{
    for (uint32_t i = 1; i <= uint32_t(iters); ++i)
    {
        flag_store(const_cast<uint32_t *>(ack), 0);
        const double t = now_us();
        flag_store(const_cast<uint32_t *>(db), i);
        uint64_t spins = 0;
        while (flag_load(const_cast<uint32_t *>(ack)) < ngroups)
            if (++spins > 300'000'000ull) return false;
        rt.add(now_us() - t);
    }
    return true;
}

// --------------------------------------------------------------------------------------- main

int main(int argc, char **argv)
{
    setvbuf(stdout, nullptr, _IONBF, 0);
    const uint32_t ngroups = argc > 1 ? uint32_t(atoi(argv[1])) : 32;
    const uint32_t wgs = 32;
    const char *pci = "/sys/bus/pci/devices/0000:0f:00.0";
    char l0[64], l1[64];

    sycl::device dev{sycl::gpu_selector_v};
    sycl::context ctx{dev};
    sycl::queue qMain{ctx, dev, {sycl::property::queue::enable_profiling{}}};
    sycl::queue qXfer{ctx, dev, {sycl::property::queue::enable_profiling{}}};

    // ---- 1 -------------------------------------------------------------------------------
    printf("== 1. device\n");
    printf("  %-44s %s\n", "name", dev.get_info<sycl::info::device::name>().c_str());
    printf("  %-44s %u\n", "compute units reported", dev.get_info<sycl::info::device::max_compute_units>());
    printf("  %-44s %zu\n", "max work-group size", dev.get_info<sycl::info::device::max_work_group_size>());
    printf("  %-44s ", "sub-group sizes");
    for (auto s : dev.get_info<sycl::info::device::sub_group_sizes>()) printf("%u ", unsigned(s));
    printf("\n");
    printf("  %-44s %.1f GiB\n", "global memory", dev.get_info<sycl::info::device::global_mem_size>() / 1073741824.0);
    printf("  %-44s %zu KiB\n", "local memory (SLM)", dev.get_info<sycl::info::device::local_mem_size>() >> 10);
    printf("  %-44s %s\n", "usm host / shared / boxed",
           (dev.has(sycl::aspect::usm_host_allocations) ? "y" : "n"));
    printf("  %-44s %s\n", "  ... shared", dev.has(sycl::aspect::usm_shared_allocations) ? "y" : "n");
    printf("  %-44s %s\n", "  ... indirect call/stack (spi), images",
           dev.has(sycl::aspect::usm_atomic_shared_allocations) ? "atomic-shared y" : "atomic-shared n");
    printf("  %-44s %s\n", "buffer/image import (interop)", dev.has(sycl::aspect::usm_system_allocations) ? "system-alloc y" : "system-alloc n");
    read_sysfs((std::string(pci) + "/current_link_speed").c_str(), l0, sizeof l0);
    read_sysfs((std::string(pci) + "/current_link_width").c_str(), l1, sizeof l1);
    printf("  %-44s %s x%s (idle sample)\n", "PCIe link", l0, l1);

    // ---- 2 -------------------------------------------------------------------------------
    printf("== 2. pinned(host USM) <-> device\n");
    const size_t big = 256ull << 20;
    uint32_t *hp = (uint32_t *) sycl::malloc_host(big, qMain);
    uint32_t *dp = (uint32_t *) sycl::malloc_device(big, qMain);
    std::memset((void *) hp, 0x5a, big);
    qMain.memset(dp, 0, big).wait();   // device USM is not host-dereferenceable here
    const size_t sizes[] = {big, 32u << 20, 1u << 20, 128u << 10, 16384, 4096};
    printf("  %-11s %11s %11s %11s %11s  %s\n", "size", "H2D GB/s", "D2H GB/s", "H2D us", "D2H us", "round trip submit+wait us");
    for (size_t n : sizes)
    {
        const int reps = n > (16u << 20) ? 8 : 64;
        for (int w = 0; w < 2; ++w) qMain.memcpy(dp, hp, n).wait();
        auto e0 = steady_clock::now();
        for (int r = 0; r < reps; ++r) qMain.memcpy(dp, hp, n);
        qMain.wait();
        double s_h2d = duration<double>(steady_clock::now() - e0).count();
        read_sysfs((std::string(pci) + "/current_link_speed").c_str(), l0, sizeof l0);
        read_sysfs((std::string(pci) + "/current_link_width").c_str(), l1, sizeof l1);
        for (int w = 0; w < 2; ++w) qMain.memcpy(hp, dp, n).wait();
        auto e1 = steady_clock::now();
        for (int r = 0; r < reps; ++r) qMain.memcpy(hp, dp, n);
        qMain.wait();
        double s_d2h = duration<double>(steady_clock::now() - e1).count();
        Stats a, b;
        for (int r = 0; r < 100; ++r)
        {
            double t = now_us(); qMain.memcpy(dp, hp, n).wait(); a.add(now_us() - t);
            t = now_us(); qMain.memcpy(hp, dp, n).wait(); b.add(now_us() - t);
        }
        printf("  %-11s %11.2f %11.2f %11.2f %11.2f  under load link %s x%s\n", szof(n),
               double(n) * reps / s_h2d / 1e9, double(n) * reps / s_d2h / 1e9, a.med(), b.med(), l0, l1);
    }

    // ---- 3 -------------------------------------------------------------------------------
    printf("== 3. one-job-one-submission cost model\n");
    {
        Flag *f = (Flag *) sycl::malloc_host(64, qMain);
        new (f) Flag();
        Stats t_sub, t_rt, t_kern, t_pipe;
        for (int r = 0; r < 300; ++r)
        {
            double t = now_us();
            qMain.single_task([=] { f->v = 1u; });
            t_sub.add(now_us() - t);
            qMain.wait();
            t_rt.add(now_us() - t);
        }
        printf("  %-44s med %.2f us (p90 %.2f)\n", "single_task: host submit only", t_sub.med(), t_sub.p90());
        printf("  %-44s med %.2f us (p90 %.2f)\n", "single_task: submit + wait", t_rt.med(), t_rt.p90());
        // a "job" shaped like the real thing: memcpy in, kernel, memcpy out, event
        for (int r = 0; r < 100; ++r)
        {
            double t = now_us();
            qMain.memcpy(dp, hp, 16384);
            qMain.parallel_for(4096, [=](sycl::id<1> i) { dp[i] = hp[i] + 1; });
            qMain.memcpy(hp, dp, 16384).wait();
            t_kern.add(now_us() - t);
        }
        printf("  %-44s med %.2f us (p90 %.2f)\n", "copy+kernel+copy, 16 KiB, wait once", t_kern.med(), t_kern.p90());
        // same, but 8 jobs in flight before one wait
        for (int w = 0; w < 3; ++w)
        {
            for (int r = 0; r < 8; ++r) { qMain.memcpy(dp, hp, 16384); qMain.parallel_for(4096, [=](sycl::id<1> i) { dp[i] = hp[i] + 1; }); qMain.memcpy(hp, dp, 16384); }
            qMain.wait();
        }
        double t = now_us();
        for (int r = 0; r < 8; ++r) { qMain.memcpy(dp, hp, 16384); qMain.parallel_for(4096, [=](sycl::id<1> i) { dp[i] = hp[i] + 1; }); qMain.memcpy(hp, dp, 16384); }
        qMain.wait();
        printf("  %-44s %.2f us per job (8 in flight)\n", "same, pipelined", (now_us() - t) / 8);
    }

    // ---- 4 -------------------------------------------------------------------------------
    printf("== 4. kernel touching host-pinned memory in place (zero copy)\n");
    {
        const uint32_t words = 4096;                       // 16 KiB, the decode x payload at H=2560
        uint32_t *src = (uint32_t *) sycl::malloc_host(words * 4, qMain);
        uint32_t *dst = (uint32_t *) sycl::malloc_host(words * 4, qMain);
        for (uint32_t i = 0; i < words; ++i) src[i] = i;
        Stats cp, wr, rd;
        for (int r = 0; r < 100; ++r)
        {
            double t = now_us();
            qMain.parallel_for(words, [=](sycl::id<1> i) { dst[i] = src[i]; }).wait();
            cp.add(now_us() - t);
            t = now_us();
            qMain.parallel_for(words, [=](sycl::id<1> i) { dst[i] = 7u; }).wait();
            wr.add(now_us() - t);
        }
        for (int r = 0; r < 20; ++r)
        {
            double t = now_us();
            qMain.parallel_for(1, [=](sycl::id<1>) { uint32_t s = 0; for (uint32_t i = 0; i < words; ++i) s += src[i]; dst[0] = s; }).wait();
            rd.add(now_us() - t);
        }
        printf("  %-44s med %.2f us (%.2f GB/s incl. launch)\n", "4096 lanes: pinned read + write", cp.med(), double(words * 8) / cp.med() / 1000.0);
        printf("  %-44s med %.2f us\n", "4096 lanes: pinned write only", wr.med());
        printf("  %-44s med %.2f us (dependent!)\n", "1 lane, 4096 sequential pinned reads", rd.med());
        printf("  %-44s %s\n", "=> stores cheap, reads latency-bound", "kernel must not chase host pointers");
    }

    // sections 5-7 (resident engine, cost of a parked engine, doorbell through a foreign
    // mapping) were moved to probe_resident.cpp, probe_notify.cpp and probe_cross.py: a parked
    // kernel has to poll with ONE lane per sub-group, with a system-scope fence around the read,
    // and must publish flags with a plain volatile store (a system-scope sycl::atomic_ref on a
    // register_host_memory pointer takes a device fault). See LESSONS.md items 2-5.
    Power pw; pw.start();
    std::this_thread::sleep_for(std::chrono::milliseconds(400));
    printf("== 8. board power, idle with live context: %.1f W\n", pw.watts());
    printf("done\n");
    return 0;
}