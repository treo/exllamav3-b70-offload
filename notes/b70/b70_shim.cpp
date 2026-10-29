// Thin C shim over SYCL for the cross-vendor sharing test (loaded with ctypes from Python).
//
// Question this answers: can the *same* page-locked host region be written by the RTX 3090 and
// read by the B70 (and the other way round) without either side copying it? The whole handoff
// protocol rests on that. Two directions are tested:
//
//   b70_touch_foreign()  a host pointer this process obtained elsewhere (torch pin_memory =>
//                        cudaHostAlloc'd, or multiprocessing.shared_memory + cudaHostRegister),
//                        registered with sycl::ext::oneapi::experimental::register_host_memory,
//                        then read and written by a B70 kernel.
//   b70_alloc_pinned()   memory allocated by the B70 runtime (sycl::malloc_host, page-locked by
//                        the xe driver), which the caller then tries to cudaHostRegister.
//
// build:
//   source /opt/intel/oneapi/setvars.sh
//   icpx -fsycl -O2 -shared -fPIC -o libb70shim.so b70_shim.cpp
extern "C" {

int b70_shim_init(void);
// add seed to every word, and write 0xB5 into word 0 on the way out; returns 0 on success
int b70_touch_foreign(void *ptr, unsigned long n_words, unsigned seed);
// same but with a fence-ordered flag write: sets ((unsigned*)ptr)[n_words] = seq after the payload
int b70_write_flag(void *ptr, unsigned long n_words, unsigned seq);
// allocate page-locked, device-accessible host memory (bytes); returns null on failure
void *b70_alloc_pinned(unsigned long bytes);
void b70_free_pinned(void *ptr);
// fill with idx+seed from the device, to prove a kernel can store into runtime-pinned memory
int b70_fill_pinned(void *ptr, unsigned long n_words, unsigned seed);
int b70_echo_flag(void *ptr, unsigned long flag_idx, unsigned long dst_idx, unsigned seed);
const char *b70_last_error(void);
unsigned long b70_pinned_bytes(void);
}

#include <sycl/sycl.hpp>
#include <cstring>
#include <string>

// register_host_memory insists on a whole number of host pages, so round up. The caller must
// therefore hand over a region that has room to the next page boundary (torch's pinned blocks
// and every SharedMemory segment do).
static unsigned long page_up(unsigned long n) { return (n + 4095ul) & ~4095ul; }

static sycl::device *g_dev = nullptr;
static sycl::context *g_ctx = nullptr;
static sycl::queue *g_q = nullptr;
static std::string g_err = "ok";
static unsigned long g_pinned_bytes = 0;

#define TRY_TRY try {
#define CATCH_FAIL                                                              \
    }                                                                           \
    catch (const std::exception &e) { g_err = e.what(); return 1; }             \
    g_err = "ok"; return 0;

extern "C" int b70_shim_init(void)
{
    TRY_TRY
    g_dev = new sycl::device(sycl::gpu_selector_v);
    g_ctx = new sycl::context(*g_dev);
    g_q = new sycl::queue(*g_ctx, *g_dev, sycl::property::queue::in_order());
    CATCH_FAIL
}

extern "C" const char *b70_last_error(void) { return g_err.c_str(); }
extern "C" unsigned long b70_pinned_bytes(void) { return g_pinned_bytes; }

extern "C" int b70_touch_foreign(void *ptr, unsigned long n_words, unsigned seed)
{
    TRY_TRY
        sycl::ext::oneapi::experimental::register_host_memory(ptr, page_up(n_words * 4), *g_ctx);
        uint32_t *p = (uint32_t *) ptr;
        g_q->parallel_for(n_words, [=](sycl::id<1> i) { p[i[0]] += seed + uint32_t(i[0]); });
        g_q->wait();
        sycl::ext::oneapi::experimental::unregister_host_memory(ptr, *g_ctx);
    CATCH_FAIL
}

extern "C" int b70_write_flag(void *ptr, unsigned long n_words, unsigned seq)
{
    // payload first, then a release fence, then the flag: the ordering the done/consumed
    // protocol needs from whichever side publishes it
    TRY_TRY
        sycl::ext::oneapi::experimental::register_host_memory(ptr, page_up((n_words + 16) * 4), *g_ctx);
        uint32_t *p = (uint32_t *) ptr;
        // NOTE the explicit i[0] and the uint32_t cast: with the original
        //   `p[i] = 0xC0FFEE00u + i`  (id<1> implicitly converted) the kernel "succeeded", the
        //   flag written after it landed, and the whole 16 KiB payload stayed zero - in every
        //   memory type tested. Index arithmetic inside kernel lambdas is spelled out hereafter.
        g_q->parallel_for(n_words, [=](sycl::id<1> i) { p[i[0]] = 0xC0FFEE00u + uint32_t(i[0]); });
        g_q->single_task([=]
        {
            // plain volatile store after a system fence. A sycl::atomic_ref on a *foreign*
            // (register_host_memory) pointer must not be used at all: at system scope it failed
            // silently and poisoned the queue, and at device scope it took the whole card down
            // (UR_RESULT_ERROR_DEVICE_LOST) - probe_stores.cpp case 7 is the repro.
            sycl::atomic_fence(sycl::memory_order::acq_rel, sycl::memory_scope::system);
            *(volatile uint32_t *)((char *) ptr + n_words * 4) = seq;
            sycl::atomic_fence(sycl::memory_order::acq_rel, sycl::memory_scope::system);
        });
        g_q->wait();
        sycl::ext::oneapi::experimental::unregister_host_memory(ptr, *g_ctx);
    CATCH_FAIL
}

extern "C" int b70_echo_flag(void *ptr, unsigned long flag_idx, unsigned long dst_idx, unsigned seed)
{
    // one work-item: read the flag word the *other* device published, echo it to dst. Proves a
    // B70 kernel observes a CUDA stream-memop write without any host round trip in between.
    TRY_TRY
    sycl::ext::oneapi::experimental::register_host_memory(ptr, page_up((flag_idx + 64) * 4), *g_ctx);
    uint32_t *p = (uint32_t *) ptr;
    g_q->single_task([=]
    {
        sycl::atomic_fence(sycl::memory_order::acq_rel, sycl::memory_scope::system);
        uint32_t v = ((volatile uint32_t *) ptr)[flag_idx];
        ((volatile uint32_t *) ptr)[dst_idx] = v;
    });
    g_q->wait();
    sycl::ext::oneapi::experimental::unregister_host_memory(ptr, *g_ctx);
    CATCH_FAIL
}

extern "C" void *b70_alloc_pinned(unsigned long bytes)
{
    if (!g_q && b70_shim_init()) return nullptr;
    void *p = sycl::malloc_host(bytes, *g_q);
    g_pinned_bytes = p ? bytes : 0;
    return p;
}

extern "C" void b70_free_pinned(void *ptr) { if (ptr) sycl::free(ptr, *g_q); }

extern "C" int b70_fill_pinned(void *ptr, unsigned long n_words, unsigned seed)
{
    TRY_TRY
        uint32_t *p = (uint32_t *) ptr;
        g_q->parallel_for(n_words, [=](sycl::id<1> i) { p[i[0]] = seed + uint32_t(i[0]); });
        g_q->wait();
    CATCH_FAIL
}