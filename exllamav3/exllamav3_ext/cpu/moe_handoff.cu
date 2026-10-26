#include "moe_handoff.h"
#include "moe_mul1.h"
#include "../routing.cuh"

#include <c10/cuda/CUDAGuard.h>
#include <ATen/cuda/CUDAContext.h>
#include <cuda.h>
#include <atomic>
#include <chrono>
#include <cstring>
#include <thread>

#include "../ptx.cuh"

#ifdef __linux__
#include <dlfcn.h>
#else
#include <intrin.h>
#include <windows.h>
#endif

// Wait timeout: generous, the CPU may be chewing a full prefill chunk
#define MOE_WAIT_TIMEOUT_NS 30000000000ull
#define MOE_SLEEP_MIN 64
#define MOE_SLEEP_MAX 2048

// -------------------------------------------------------------------------------------------
//   GPU flag kernels
// -------------------------------------------------------------------------------------------

// Fallback for when the stream memory operations are unavailable or disabled
__global__ void moe_flag_write_kernel(moe_flag_t* flag, moe_flag_t value)
{
#if MOE_FLAG_BITS == 64
    stg_release_sys_u64(flag, value);
#else
    stg_release_sys_u32(flag, value);
#endif
}

// Fallback for when the stream memory operations are unavailable or disabled
__global__ void moe_flag_wait_kernel(moe_flag_t* flag, moe_flag_t value, uint32_t* abort_flag)
{
    uint64_t sleep = MOE_SLEEP_MIN;
    uint64_t waited = 0;
    while (true)
    {
#if MOE_FLAG_BITS == 64
        if (ldg_acquire_sys_u64(flag) >= value) return;
#else
        uint32_t v = (uint32_t) ldg_acquire_sys_u32(flag);
        if ((int32_t)(v - value) >= 0) return;
#endif
        __nanosleep(sleep);
        waited += sleep;
        if (sleep < MOE_SLEEP_MAX) sleep <<= 1;
        if (waited > MOE_WAIT_TIMEOUT_NS)
        {
            stg_release_sys_u32(abort_flag, 1);
            return;
        }
    }
}

// Stream memory operations: same semantics as the flag kernels (CU_STREAM_WAIT_VALUE_GEQ is
// documented as the cyclic comparison (int32_t)(*addr - value) >= 0, identical to the kernel's
// predicate), but executed by the GPU front-end: no SM occupancy (nothing to co-schedule against
// exl3_moe's all-blocks-resident launch) and no kernel-launch cost per wait. The kernel path
// remains as a fallback (EXL3_MOE_MEMOPS=0 forces it); note the memop wait has no timeout, so
// dead-worker detection moves to the host-side watchdog, which unblocks pending waits by
// writing satisfying values into the flags.
namespace {

#if defined(USE_ROCM)
// HIP has the memops as runtime entry points in the library already linked. Its wait compares with a plain
// unsigned >= rather than CUDA's cyclic one, hence the 64-bit flags (see moe_handoff.h)
typedef hipError_t (*fn_stream_wait64)(hipStream_t, void*, uint64_t, unsigned int, uint64_t);
typedef hipError_t (*fn_stream_write64)(hipStream_t, void*, uint64_t, unsigned int);

struct MemOps
{
    fn_stream_wait64 wait = &hipStreamWaitValue64;
    fn_stream_write64 write = &hipStreamWriteValue64;
    bool resolved = true;
};
#else
typedef CUresult (CUDAAPI* fn_stream_wait32)(CUstream, CUdeviceptr, cuuint32_t, unsigned int);
typedef CUresult (CUDAAPI* fn_stream_write32)(CUstream, CUdeviceptr, cuuint32_t, unsigned int);

struct MemOps
{
    fn_stream_wait32 wait = nullptr;
    fn_stream_write32 write = nullptr;
    bool resolved = false;
    MemOps()
    {
        // Symbol resolution is unconditional (independent of exl3_moe_cpu_set_memops): whether
        // the ops are used is a separate, mutable runtime switch, not a one-time decision
#ifdef __linux__
        void* h = dlopen("libcuda.so.1", RTLD_LAZY | RTLD_NOLOAD);
        if (!h) h = dlopen("libcuda.so", RTLD_LAZY | RTLD_NOLOAD);
        if (!h) return;
        wait = (fn_stream_wait32) dlsym(h, "cuStreamWaitValue32_v2");
        if (!wait) wait = (fn_stream_wait32) dlsym(h, "cuStreamWaitValue32");
        write = (fn_stream_write32) dlsym(h, "cuStreamWriteValue32_v2");
        if (!write) write = (fn_stream_write32) dlsym(h, "cuStreamWriteValue32");
#else
        HMODULE h = GetModuleHandleA("nvcuda.dll");
        if (!h) return;
        wait = (fn_stream_wait32) GetProcAddress(h, "cuStreamWaitValue32_v2");
        if (!wait) wait = (fn_stream_wait32) GetProcAddress(h, "cuStreamWaitValue32");
        write = (fn_stream_write32) GetProcAddress(h, "cuStreamWriteValue32_v2");
        if (!write) write = (fn_stream_write32) GetProcAddress(h, "cuStreamWriteValue32");
#endif
        resolved = wait && write;
    }
};
#endif

MemOps& memops() { static MemOps m; return m; }
std::atomic<bool> g_memops_ok { true };
std::atomic<bool> g_memops_enabled { true };

inline uint32_t load_acquire_u32(const uint32_t* p)
{
#if defined(_MSC_VER) && !defined(__clang__)
    long v = _InterlockedCompareExchange(
        reinterpret_cast<volatile long*>(const_cast<uint32_t*>(p)), 0L, 0L);
    return static_cast<uint32_t>(v);
#else
    return __atomic_load_n(p, __ATOMIC_ACQUIRE);
#endif
}

inline void store_release_u32(uint32_t* p, uint32_t v)
{
#if defined(_MSC_VER) && !defined(__clang__)
    (void)_InterlockedExchange(reinterpret_cast<volatile long*>(p), static_cast<long>(v));
#else
    __atomic_store_n(p, v, __ATOMIC_RELEASE);
#endif
}

} // namespace

void exl3_moe_cpu_set_memops(bool enabled)
{
    g_memops_enabled.store(enabled, std::memory_order_relaxed);
}

void exl3_moe_flag_write(uintptr_t flag, int64_t value)
{
    cudaStream_t stream = at::cuda::getCurrentCUDAStream().stream();
    MemOps& m = memops();
    if (m.resolved && g_memops_enabled.load(std::memory_order_relaxed)
        && g_memops_ok.load(std::memory_order_relaxed))
    {
#if defined(USE_ROCM)
        hipError_t r = m.write(stream, (void*) flag, (uint64_t) value, 0);
        if (r == hipSuccess) return;
#else
        CUresult r = m.write((CUstream) stream, (CUdeviceptr) flag, (cuuint32_t) value, 0);
        if (r == CUDA_SUCCESS) return;
#endif
        g_memops_ok.store(false, std::memory_order_relaxed);
    }
    moe_flag_write_kernel<<<1, 1, 0, stream>>>(reinterpret_cast<moe_flag_t*>(flag), static_cast<moe_flag_t>(value));
}

void exl3_moe_flag_wait(uintptr_t flag, int64_t value, uintptr_t abort_flag)
{
    cudaStream_t stream = at::cuda::getCurrentCUDAStream().stream();
    MemOps& m = memops();
    if (m.resolved && g_memops_enabled.load(std::memory_order_relaxed)
        && g_memops_ok.load(std::memory_order_relaxed))
    {
#if defined(USE_ROCM)
        hipError_t r = m.wait(stream, (void*) flag, (uint64_t) value, hipStreamWaitValueGte, ~0ull);
        if (r == hipSuccess) return;
#else
        CUresult r = m.wait(
            (CUstream) stream,
            (CUdeviceptr) flag,
            (cuuint32_t) value,
            CU_STREAM_WAIT_VALUE_GEQ
        );
        if (r == CUDA_SUCCESS) return;
#endif
        g_memops_ok.store(false, std::memory_order_relaxed);
    }
    moe_flag_wait_kernel<<<1, 1, 0, stream>>>
    (
        reinterpret_cast<moe_flag_t*>(flag),
        static_cast<moe_flag_t>(value),
        reinterpret_cast<uint32_t*>(abort_flag)
    );
}

// ---- fused split issue / collect -----------------------------------------------------------
//
// One call per layer per step for each half of the decode handoff, replacing the host-side job
// descriptor write, ring check and the separate flag-wait / kernel / flag-write calls. The job
// descriptor goes into the shared ring here (same layout as the Python writer); the flag memops
// and the kernel are enqueued on the stream of the tensors' device. Returns false without
// touching anything when the job ring is within its safety margin of overflowing, so the caller
// can throttle and retry (a long prefill is the only way to get there).

namespace {

inline void flag_write_on(cudaStream_t stream, uintptr_t flag, int64_t value)
{
    MemOps& m = memops();
    if (m.resolved && g_memops_enabled.load(std::memory_order_relaxed)
        && g_memops_ok.load(std::memory_order_relaxed))
    {
#if defined(USE_ROCM)
        if (m.write(stream, (void*) flag, (uint64_t) value, 0) == cudaSuccess) return;
#else
        if (m.write((CUstream) stream, (CUdeviceptr) flag, (cuuint32_t) value, 0) == CUDA_SUCCESS) return;
#endif
        g_memops_ok.store(false, std::memory_order_relaxed);
    }
    moe_flag_write_kernel<<<1, 1, 0, stream>>>(reinterpret_cast<moe_flag_t*>(flag), static_cast<moe_flag_t>(value));
}

inline void flag_wait_on(cudaStream_t stream, uintptr_t flag, int64_t value, uintptr_t abort_flag)
{
    MemOps& m = memops();
    if (m.resolved && g_memops_enabled.load(std::memory_order_relaxed)
        && g_memops_ok.load(std::memory_order_relaxed))
    {
#if defined(USE_ROCM)
        if (m.wait(stream, (void*) flag, (uint64_t) value, hipStreamWaitValueGte, ~0ull) == cudaSuccess) return;
#else
        if (m.wait((CUstream) stream, (CUdeviceptr) flag, (cuuint32_t) value, CU_STREAM_WAIT_VALUE_GEQ) == CUDA_SUCCESS) return;
#endif
        g_memops_ok.store(false, std::memory_order_relaxed);
    }
    moe_flag_wait_kernel<<<1, 1, 0, stream>>>(
        reinterpret_cast<moe_flag_t*>(flag), static_cast<moe_flag_t>(value), reinterpret_cast<uint32_t*>(abort_flag));
}

} // namespace

bool exl3_moe_split_issue_fused
(
    uintptr_t shm_base,
    int64_t seq,
    int64_t layer,
    int64_t rows,
    int64_t topk,
    int64_t slot,
    int64_t prev_seq,
    at::Tensor sel,
    const c10::optional<at::Tensor>& map,
    const c10::optional<at::Tensor>& hist,
    const at::Tensor& y,
    const at::Tensor& w,
    int64_t h_sel_ptr,
    int64_t h_x_ptr,
    int64_t h_w_ptr,
    at::Tensor dev_count,
    int64_t hi,
    int64_t first_cpu,
    uintptr_t data_ready_flag,
    uintptr_t consumed_flag,
    uintptr_t abort_flag
)
{
    uint8_t* base = reinterpret_cast<uint8_t*>(shm_base);
    uint32_t* jobs_tail = reinterpret_cast<uint32_t*>(base + 256);
    uint32_t* jobs_head = reinterpret_cast<uint32_t*>(base + 320);
    MoeJob* jobs = reinterpret_cast<MoeJob*>(base + MOE_CTRL_JOBS_OFFSET);
    const uint32_t tail = *jobs_tail;
    if (tail - load_acquire_u32(jobs_head) >= MOE_JOB_RING - 4) return false;
    // Descriptor first: host-visible before the GPU can publish the data flag
    MoeJob& job = jobs[tail % MOE_JOB_RING];
    job.seq = (uint32_t) (seq & 0xFFFFFFFFull);
    job.seq_hi = (uint32_t) ((uint64_t) seq >> 32);
    job.layer = (uint32_t) layer;
    job.rows = (uint32_t) rows;
    job.topk = (uint32_t) topk;
    job.slot = (uint32_t) slot;
    job.kind = MOE_JOB_KIND_COMPUTE_GATED;
    store_release_u32(jobs_tail, tail + 1);

    const at::cuda::OptionalCUDAGuard device_guard(y.device());
    cudaStream_t stream = at::cuda::getCurrentCUDAStream(y.get_device()).stream();
    if (prev_seq) flag_wait_on(stream, consumed_flag, prev_seq, abort_flag);
    moe_split_issue(sel, map, hist, y, w, h_sel_ptr, h_x_ptr, h_w_ptr, dev_count, slot, hi, first_cpu);
    flag_write_on(stream, data_ready_flag, seq);
    return true;
}

void exl3_moe_split_collect_fused
(
    at::Tensor final_out,
    int64_t h_out_ptr,
    const at::Tensor& dev_count,
    int64_t slot,
    int64_t ho,
    uintptr_t done_flag,
    int64_t seq,
    uintptr_t consumed_flag,
    uintptr_t abort_flag
)
{
    const at::cuda::OptionalCUDAGuard device_guard(final_out.device());
    cudaStream_t stream = at::cuda::getCurrentCUDAStream(final_out.get_device()).stream();
    flag_wait_on(stream, done_flag, seq, abort_flag);
    moe_split_collect_add(final_out, h_out_ptr, dev_count, slot, ho);
    // Consumption is published AFTER the readback on this same stream: the slot's next tenant
    // (possibly issuing from another device) gates on it
    flag_write_on(stream, consumed_flag, seq);
}

// ---- child worker loop --------------------------------------------------------------------

namespace {

inline void cpu_pause_()
{
#if defined(__aarch64__) || defined(__arm__)  // EXL3_AARCH64_PAUSE
    asm volatile("yield" ::: "memory");
#elif defined(__linux__)
    __builtin_ia32_pause();
#else
    _mm_pause();
#endif
}

// Publish a job's full sequence number into a flag (only the 64-bit flags take the high half)
inline void store_release_flag(uint32_t* p, const MoeJob& job)
{
#if MOE_FLAG_BITS == 64
    uint64_t v = (uint64_t(job.seq_hi) << 32) | job.seq;
#if defined(_MSC_VER) && !defined(__clang__)
    (void)_InterlockedExchange64(reinterpret_cast<volatile long long*>(p), static_cast<long long>(v));
#else
    __atomic_store_n(reinterpret_cast<uint64_t*>(p), v, __ATOMIC_RELEASE);
#endif
#else
    store_release_u32(p, job.seq);
#endif
}

inline size_t align64(size_t x) { return (x + 63) & ~size_t(63); }

} // namespace

void exl3_moe_cpu_worker_run
(
    uintptr_t shm_base,
    int64_t num_slots,
    int64_t slot_size,
    int64_t cap_rows,
    int64_t max_hi,
    int64_t max_ho,
    int64_t max_topk,
    int64_t wstage_offset,
    int64_t num_wslots,
    int64_t wslot_size,
    int64_t threads,
    int64_t stage_threads
)
{
    // GIL is released by the binding's call_guard; do not release it again here
    uint8_t* base = reinterpret_cast<uint8_t*>(shm_base);
    uint32_t* quit = reinterpret_cast<uint32_t*>(base + 0);
    uint32_t* pass_wake = reinterpret_cast<uint32_t*>(base + 64);
    uint32_t* ready = reinterpret_cast<uint32_t*>(base + 192);
    uint32_t* jobs_tail = reinterpret_cast<uint32_t*>(base + 256);
    uint32_t* jobs_head = reinterpret_cast<uint32_t*>(base + 320);
    MoeJob* jobs = reinterpret_cast<MoeJob*>(base + MOE_CTRL_JOBS_OFFSET);
    uint32_t* data_ready = reinterpret_cast<uint32_t*>(base + MOE_SLOT_FLAGS_OFFSET);
    uint32_t* done = reinterpret_cast<uint32_t*>(base + MOE_SLOT_FLAGS_OFFSET + 64 * MOE_MAX_SLOTS);
    uint32_t* stage_done = reinterpret_cast<uint32_t*>(base + MOE_SLOT_FLAGS_OFFSET + 3 * 64 * MOE_MAX_SLOTS);
    uint32_t* pinned_free = reinterpret_cast<uint32_t*>(base + MOE_SLOT_FLAGS_OFFSET + 3 * 64 * MOE_MAX_SLOTS + 64 * MOE_MAX_WSLOTS);
    uint32_t* stage_tail = reinterpret_cast<uint32_t*>(base + MOE_STAGE_TAIL_OFFSET);
    uint32_t* stage_head = reinterpret_cast<uint32_t*>(base + MOE_STAGE_HEAD_OFFSET);
    MoeJob* stage_jobs = reinterpret_cast<MoeJob*>(base + MOE_STAGE_JOBS_OFFSET);
    uint8_t* data = base + MOE_CTRL_SIZE;
    uint8_t* wstage = base + wstage_offset;

    // Dedicated stager: consumes the stage ring so weight memcpys run concurrently with the
    // compute pool's work on the token tail. Uses its own scratch threads, never the pool.
    // stage_threads comes from the parent (MoeCpuTuning), passed through the "start" layout.
    //
    // Handoff profiling (EXL3_MOE_HANDOFF_PROF, or the EXL3_MOE_PROF umbrella): per-job wall
    // times for the three segments the worker can observe -- idle gap since the previous job,
    // spin-on-data_ready, and compute -- accumulated per layer AND per backend class (plain
    // CPU compute vs a layer routed through the B70 plugin), plus the stager's own wait/copy
    // time. Rolling window every 64 jobs on stdout, plus a full run summary when the parent
    // shuts the worker down.
    const bool hprof = getenv("EXL3_MOE_HANDOFF_PROF") != nullptr;
    constexpr int HP_LAYERS = 256;
    struct HpAgg
    {
        double spin = 0.0, comp = 0.0, comp_mx = 0.0;   // ms
        long jobs = 0, rows = 0, empty = 0;
    };
    struct HpTot
    {
        double spin = 0.0, comp = 0.0, comp_mx = 0.0, gap = 0.0;
        long jobs = 0, n1 = 0, nsmall = 0, nbig = 0;
    };
    HpAgg* hp_layer = hprof ? new HpAgg[HP_LAYERS] {} : nullptr;
    HpTot hp_tot[2];                      // [0] = CPU-compute layers, [1] = B70 layers
    double hp_gap = 0.0, hp_spin = 0.0, hp_comp = 0.0;
    double hp_gap_mx = 0.0, hp_spin_mx = 0.0, hp_comp_mx = 0.0;
    long hp_jobs = 0, hp_empty = 0, hp_assign = 0, hp_rows = 0;
    long hp_stg = 0; double hp_stg_wait = 0.0, hp_stg_copy = 0.0, hp_stg_copy_mx = 0.0;
    auto hp_prev_end = std::chrono::steady_clock::now();
    auto hp_ms = [](std::chrono::steady_clock::time_point a, std::chrono::steady_clock::time_point b)
        { return std::chrono::duration<double, std::milli>(b - a).count(); };
    int stage_threads_ = stage_threads > 0 ? (int) stage_threads : 1;
    std::thread stager([&]()
    {
        uint32_t shead = load_acquire_u32(stage_head);
        uint32_t s_last_wake = 0;
        int s_idle = 0;
        while (true)
        {
            if (load_acquire_u32(quit)) return;
            const uint32_t wake = load_acquire_u32(pass_wake);
            if (wake != s_last_wake) { s_last_wake = wake; s_idle = 0; }
            if (load_acquire_u32(stage_tail) == shead)
            {
                if (++s_idle < 65536) { cpu_pause_(); continue; }
                std::this_thread::sleep_for(std::chrono::microseconds(50));
                continue;
            }
            s_idle = 0;

            const MoeJob job = stage_jobs[shead % MOE_STAGE_RING];
            shead++;
            store_release_u32(stage_head, shead);

            // Wait until the slot's previous tenant has been DMA'd out (low half of the flag, cyclically)
            uint32_t* pf = pinned_free + size_t(job.slot) * 16;
            const auto sg0 = hprof ? std::chrono::steady_clock::now() : std::chrono::steady_clock::time_point{};
            while ((int32_t)(load_acquire_u32(pf) - job.prev_seq) < 0)
            {
                if (load_acquire_u32(quit)) return;
                cpu_pause_();
            }
            const auto sg1 = hprof ? std::chrono::steady_clock::now() : sg0;
            exl3_moe_cpu_stage_experts(
                static_cast<int64_t>(job.layer),
                job.experts,
                static_cast<int>(job.rows),
                wstage + size_t(job.slot) * wslot_size,
                stage_threads_
            );
            if (hprof)
            {
                const auto sg2 = std::chrono::steady_clock::now();
                const double cc = hp_ms(sg1, sg2);
                hp_stg_wait += hp_ms(sg0, sg1); hp_stg_copy += cc; ++hp_stg;
                if (cc > hp_stg_copy_mx) hp_stg_copy_mx = cc;
            }
            store_release_flag(stage_done + size_t(job.slot) * 16, job);
        }
    });

    // Fixed slot section offsets from the registered maxima
    const size_t off_x = 0;
    const size_t off_sel = align64(off_x + size_t(cap_rows) * max_hi * 2);
    const size_t off_w = align64(off_sel + size_t(cap_rows) * max_topk * 4);
    const size_t off_out = align64(off_w + size_t(cap_rows) * max_topk * 2);

    const char* prime_env = getenv("EXL3_MOE_POOL_PRIME");
    const bool prime_pool = !prime_env || prime_env[0] != '0';
    if (prime_pool) exl3_moe_cpu_pool_prime((int) threads);
    store_release_u32(ready, 1);

    uint32_t head = load_acquire_u32(jobs_head);
    uint32_t last_wake = 0;
    int idle = 0;
    while (true)
    {
        if (load_acquire_u32(quit)) break;

        const uint32_t wake = load_acquire_u32(pass_wake);
        if (wake != last_wake)
        {
            last_wake = wake;
            idle = 0;
            if (prime_pool) exl3_moe_cpu_pool_prime((int) threads);
        }

        if (load_acquire_u32(jobs_tail) == head)
        {
            // Spin hard in-pass (jobs arrive within microseconds of the GPU reaching the layer),
            // back off to naps when the queue has been dry for a while
            if (++idle < 65536) { cpu_pause_(); continue; }
            std::this_thread::sleep_for(std::chrono::microseconds(50));
            continue;
        }
        idle = 0;

        const MoeJob job = jobs[head % MOE_JOB_RING];
        head++;
        store_release_u32(jobs_head, head);

        const auto hp_t0 = std::chrono::steady_clock::now();

        // Wait for the GPU to publish the staged inputs for this seq (low half of the flag, cyclically)
        uint32_t* drdy = data_ready + size_t(job.slot) * 16;
        while ((int32_t)(load_acquire_u32(drdy) - job.seq) < 0)
        {
            if (load_acquire_u32(quit)) goto out;
            cpu_pause_();
        }

        const auto hp_t1 = std::chrono::steady_clock::now();

        {
            uint8_t* slot = data + size_t(job.slot) * slot_size;
            bool run = true;
            if (job.kind == MOE_JOB_KIND_COMPUTE_GATED)
            {
                // Fused-issue job: the collecting kernel reads the output only when some
                // selected expert is CPU-resident, so an all-inactive job is a pure no-op
                const int32_t* selp = reinterpret_cast<const int32_t*>(slot + off_sel);
                const int total = (int) job.rows * (int) job.topk;
                if (hprof)
                {
                    // Full-count variant: CPU-assignment stats for the profiler report
                    int n = 0;
                    for (int i = 0; i < total; ++i)
                        if (selp[i] >= 0) n++;
                    run = n > 0;
                    hp_assign += n;
                    hp_rows += (int) job.rows;
                    if (!run) hp_empty++;
                }
                else
                {
                    run = false;
                    for (int i = 0; i < total; ++i)
                        if (selp[i] >= 0) { run = true; break; }
                }
            }
            if (run)
                exl3_moe_cpu_forward_raw(
                    static_cast<int64_t>(job.layer),
                    reinterpret_cast<const at::Half*>(slot + off_x),
                    reinterpret_cast<const int32_t*>(slot + off_sel),
                    reinterpret_cast<const at::Half*>(slot + off_w),
                    reinterpret_cast<float*>(slot + off_out),
                    static_cast<int>(job.rows),
                    static_cast<int>(job.topk),
                    static_cast<int>(threads)
                );
        }

        store_release_flag(done + size_t(job.slot) * 16, job);

        if (hprof)
        {
            const auto hp_t2 = std::chrono::steady_clock::now();
            const double g = hp_ms(hp_prev_end, hp_t0), s = hp_ms(hp_t0, hp_t1), c = hp_ms(hp_t1, hp_t2);
            hp_gap += g; hp_spin += s; hp_comp += c;
            if (g > hp_gap_mx) hp_gap_mx = g;
            if (s > hp_spin_mx) hp_spin_mx = s;
            if (c > hp_comp_mx) hp_comp_mx = c;
            hp_prev_end = hp_t2;

            // Class + layer attribution (class = where the compute actually ran: the B70
            // plugin swallows the whole job for registered layers, see forward_raw)
            const int cls = exl3_moe_cpu_is_b70(static_cast<int64_t>(job.layer)) ? 1 : 0;
            HpTot& t = hp_tot[cls];
            t.jobs++; t.spin += s; t.comp += c;
            if (c > t.comp_mx) t.comp_mx = c;
            if (job.rows <= 1) t.n1++; else if (job.rows <= 8) t.nsmall++; else t.nbig++;
            HpAgg& a = hp_layer[job.layer < HP_LAYERS ? job.layer : HP_LAYERS - 1];
            a.jobs++; a.spin += s; a.comp += c; a.rows += job.rows;
            if (c > a.comp_mx) a.comp_mx = c;

            if (++hp_jobs % 64 == 0)
            {
                printf(" -- handoff prof (%ld jobs, ms/job avg|max): gap %.3f|%.3f "
                       "spin %.3f|%.3f compute %.3f|%.3f | empty %ld/64, "
                       "cpu-assign/row %.2f\n",
                       hp_jobs, hp_gap / 64, hp_gap_mx, hp_spin / 64, hp_spin_mx,
                       hp_comp / 64, hp_comp_mx, hp_empty,
                       hp_rows ? (double) hp_assign / (double) hp_rows : 0.0);
                fflush(stdout);
                hp_gap = hp_spin = hp_comp = 0.0;
                hp_gap_mx = hp_spin_mx = hp_comp_mx = 0.0;
                hp_empty = 0; hp_assign = 0; hp_rows = 0;
            }
            if (hp_jobs % 1024 == 0)
                printf(" -- handoff prof [%ld jobs, cumulative ms]: cpu jobs %ld comp %.1f "
                       "(%.3f/job, max %.2f) spin %.1f | b70 jobs %ld comp %.1f (%.3f/job, "
                       "max %.2f) spin %.1f | rows1 %ld/%ld small %ld/%ld big %ld/%ld "
                       "| stager %ld copies %.1f ms (wait %.1f, max %.2f)\n",
                       hp_jobs, hp_tot[0].jobs, hp_tot[0].comp, hp_tot[0].jobs ? hp_tot[0].comp / hp_tot[0].jobs : 0.0,
                       hp_tot[0].comp_mx, hp_tot[0].spin, hp_tot[1].jobs, hp_tot[1].comp,
                       hp_tot[1].jobs ? hp_tot[1].comp / hp_tot[1].jobs : 0.0, hp_tot[1].comp_mx,
                       hp_tot[1].spin, hp_tot[0].n1 + hp_tot[1].n1, hp_jobs,
                       hp_tot[0].nsmall + hp_tot[1].nsmall, hp_jobs,
                       hp_tot[0].nbig + hp_tot[1].nbig, hp_jobs,
                       hp_stg, hp_stg_copy, hp_stg_wait, hp_stg_copy_mx);
        }
    }
    out:;
    stager.join();

    // Run summary: where the worker's wall time actually went, per backend class and per layer
    if (hprof)
    {
        printf(" -- handoff SUMMARY (%ld jobs): cpu jobs %ld, b70 jobs %ld\n", hp_jobs,
               hp_tot[0].jobs, hp_tot[1].jobs);
        for (int cls = 0; cls < 2; ++cls)
        {
            const HpTot& t = hp_tot[cls];
            if (!t.jobs) continue;
            printf(" --   [%s] spin %.2f ms total (%.4f/job) | compute %.2f ms total "
                   "(%.4f/job avg, %.3f max) | rows: 1 %ld, 2-8 %ld, >8 %ld\n",
                   cls ? "b70" : "cpu", t.spin, t.spin / t.jobs, t.comp, t.comp / t.jobs,
                   t.comp_mx, t.n1, t.nsmall, t.nbig);
        }
        printf(" --   [stager] %ld weight stagings, copy %.2f ms total (%.4f/job, %.3f max), "
               "pinned-free wait %.2f ms\n", hp_stg, hp_stg_copy,
               hp_stg ? hp_stg_copy / hp_stg : 0.0, hp_stg_copy_mx, hp_stg_wait);
        // Top layers by total compute: the per-layer spread is what placement decisions need
        int shown = 0;
        for (int pass = 0; pass < HP_LAYERS && shown < 8; ++pass)
        {
            int best = -1;
            for (int l = 0; l < HP_LAYERS; ++l)
                if (hp_layer[l].jobs && (best < 0 || hp_layer[l].comp > hp_layer[best].comp)) best = l;
            if (best < 0) break;
            const HpAgg& a = hp_layer[best];
            printf(" --   layer %-3d jobs %6ld rows/job %.1f spin %.3f ms comp %.3f ms "
                   "avg %.4f max %.3f\n", best, a.jobs, (double) a.rows / a.jobs,
                   a.spin, a.comp, a.comp / a.jobs, a.comp_mx);
            hp_layer[best].jobs = 0;   // consume for the ranking walk
            ++shown;
        }
        fflush(stdout);
        delete[] hp_layer;
    }
}
