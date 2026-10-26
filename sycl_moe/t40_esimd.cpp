// t40_esimd.cpp - ESIMD xmx::dpas int8 spike (m8n16k32 per HW thread).
//
// Context (t39 findings): the joint_matrix global A-operand load lowers to a per-lane
// byte-gather that costs 2.8x the entire kernel; per-lane CONTIGUOUS 16B loads of the
// same bytes run at the no-A-load ceiling (st18 == st6). joint_matrix cannot consume a
// packed i8 A operand (no builtin), but ESIMD xmx::dpas takes per-thread operand vectors
// directly: A row-major "one row per repeat", B VNNI panels - both loadable with fully
// contiguous per-thread loads. This lab validates numerics + speed of that path against
// a CPU reference on a single 8x16 tile over full K, then a tiled sweep for bandwidth.
//
// int8 DPAS per-thread operand sizes (exec 16, k32n16, m8 via RC... see manual 8.6):
//   a: simd<uint8_t, 8*32>  = 8 rows x 32 bytes (k32), row-major, pitch = K
//   b: simd<uint32_t, 128>  = k32 x n16 u8 = 512 B as VNNI dwords: dword[r*16+n] holds
//      bytes B8 = u8 k[4r..4r+3] of column n? - VNNI u8 layout: within each 4-k qword...
//   result: simd<int32_t, 8*16>
// The exact dword order of the u8 VNNI B operand is what Part 1 nails down against the
// host reference: we sweep the 3 plausible interleave conventions if needed.

#include <sycl/sycl.hpp>
#include <sycl/ext/intel/esimd.hpp>
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <vector>
#include <chrono>
#include <random>

using namespace sycl;
using namespace sycl::ext::intel::esimd;
namespace xmx = sycl::ext::intel::esimd::xmx;

#ifndef T40_K
#define T40_K 2560
#endif
static constexpr int K = T40_K, NT = 16, M = 8;

// b variant encodings (host packer): index = (k, n) byte position inside the 512B panel
static int bidx_variant(int v, int k, int n)
{
    // k in [0,32), n in [0,16): return BYTE offset in the panel as laid out linearly.
    // HW VNNI-u8 convention candidates; the dword containing (k,n) and byte lane within.
    const int kd = k >> 2, kb = k & 3;          // k-dword row and byte within
    switch (v)
    {
        case 0: return (kd * NT + n) * 4 + kb;              // dword = (k/4, n), bytes=k
        case 1: return (n * (K / 32 * 4) ) + 0;             // unused placeholder
        case 2: return ((k & ~3) * NT + n) * 4 + kb;        // per-byte k-major (wrong size)
        default: return 0;
    }
}

// Kernel: one work-item = one HW thread computes an 8x16 tile over K, k-chunked by 32.
template <int BV>
void run_tile(queue& q, const uint8_t* A, const uint8_t* Bp, int32_t* out, int iters, int variant, int steps)
{
    for (int i = 0; i < iters; ++i)
    {
        q.parallel_for(sycl::range<1>(1), [=](sycl::item<1> it) SYCL_ESIMD_KERNEL {
            (void)it;
            simd<int32_t, M * NT> acc(0);
            #pragma clang loop unroll_count(4)
            for (int kk = 0; kk < steps * 32; kk += 32)
            {
                // A: 8 rows x 32 bytes, row pitch K. load_2d(surface w-1, h-1, pitch, x, y)
                simd<uint8_t, M * 32> a =
                    load_2d<uint8_t, 32, M>(A, K - 1, M - 1, K - 1, kk, 0);
                // B: 512B VNNI panel for this k32 step as 512 per-thread u8 elements
                // (32 u8 per lane). The VNNI byte order within each 4-k qword is what
                // the variant sweep pins down.
                simd<uint8_t, 512> b = block_load<uint8_t, 512>(
                    Bp + (size_t)(kk / 32) * 512);
                // dpas: SD=8 (k32 for int8), RC=8 (M rows), dst int, prec A s8, B u8.
                if (variant)
                    acc = xmx::dpas<8, 8, int, int, uint8_t, uint8_t,
                                    xmx::dpas_argument_type::s8, xmx::dpas_argument_type::s8>(acc, b, a);
                else
                    acc = xmx::dpas<8, 8, int, int, uint8_t, uint8_t,
                                    xmx::dpas_argument_type::u8, xmx::dpas_argument_type::s8>(acc, b, a);
            }
            block_store(out, acc);
        }).wait();
    }
}

int main(int argc, char** argv)
{
    int variant = argc > 1 ? atoi(argv[1]) : 0;
    int iters = argc > 2 ? atoi(argv[2]) : 3;
    const char* probe = argc > 3 ? argv[3] : nullptr;   // "a" | "b" layout probes
    if (probe && (*probe == '-' || *probe == 'x')) probe = nullptr;
    queue q{gpu_selector_v};
    printf("dev: %s\n", q.get_device().get_info<sycl::info::device::name>().c_str());

    std::mt19937 rng(1234);
    std::vector<int8_t> hA(M * K), hB(K * NT);
    if (!probe)
    {
        for (auto& v : hA) v = (int8_t)((rng() % 201) - 100);
        for (auto& v : hB) v = (int8_t)(rng() % 251);
        if (std::getenv("T40_WIN"))
        {
            const int w0 = atoi(std::getenv("T40_WIN"));
            for (int m = 0; m < M; ++m) for (int k = 0; k < K; ++k)
                if (k < w0 || k >= w0 + 32) hA[(size_t)m * K + k] = 0;
            for (int k = 0; k < K; ++k) for (int n = 0; n < NT; ++n)
                if (k < w0 || k >= w0 + 32) hB[(size_t)k * NT + n] = 0;
        }
    }
    else if (probe[0] == 'a')
    {
        // B[k][n] = (k==n); A[m][k] = unique tag byte (m*32+k)
        for (auto& v : hB) v = 0;
        for (int k = 0; k < 16; ++k) hB[(size_t)k * NT + k] = 1;   // no k>=16 aliasing
        for (int m = 0; m < M; ++m) for (int k = 0; k < K; ++k) hA[(size_t)m * K + k] = (int8_t)(m * 32 + k);
    }
    else if (probe[0] == 'e')
    {
        // single-impulse map probes: 'e' -> A=e(0,1), B=ones; main flips sel via env
        const int sel = std::getenv("T40_SEL") ? atoi(std::getenv("T40_SEL")) : 1;
        for (auto& v : hA) v = 0;
        for (auto& v : hB) v = 1;
        hA[sel] = 1;                       // A[0][sel]
    }
    else
    {
        // A[m][k] = (k==m) so out[m][n] = B[m][n]: reveals the B panel byte map
        for (auto& v : hA) v = 0;
        for (int m = 0; m < M; ++m) hA[(size_t)m * K + m] = 1;
        for (int k = 0; k < K; ++k) for (int n = 0; n < NT; ++n) hB[(size_t)k * NT + n] = (int8_t)(k * 16 + n);
    }
    std::vector<int32_t> ref(M * NT, 0), dev(M * NT, 0xFF);

    // reference: out[m][n] = sum_k A[m][k] * (int8)B[k][n]
    // reference domains must mirror the packer + dpas precisions: variant 0 = u8 B,
    // variant 1 = signed B stored as (byte - 128)
    for (int m = 0; m < M; ++m)
        for (int n = 0; n < NT; ++n)
        {
            long s = 0;
            for (int k = 0; k < K; ++k)
            {
                const int bv = variant ? (int)(int8_t)(hB[(size_t)k * NT + n] - 128)
                                       : (int)(uint8_t)hB[(size_t)k * NT + n];
                s += (long)hA[(size_t)m * K + k] * bv;
            }
            ref[(size_t)m * NT + n] = (int32_t)s;
        }

    // pack B panel per variant, linearly per k32 step; variant 1 = signed weights (-128 bias)
    std::vector<uint8_t> pB((size_t)(K / 32) * 512, 0);
    for (int ks = 0; ks < K / 32; ++ks)
        for (int k = 0; k < 32; ++k)
            for (int n = 0; n < NT; ++n)
            {
                const int gk = ks * 32 + k;
                const int off = variant == 0 ? (((k >> 2) * NT + n) * 4 + (k & 3))
                                 : (((k >> 2) * NT + n) * 4 + (k & 3));
                pB[(size_t)ks * 512 + off] = variant ? (uint8_t)((int)hB[(size_t)gk * NT + n] - 128)
                                                      : hB[(size_t)gk * NT + n];
            }

    if (variant == 9)
    {
        // PERF: NBLK independent units; each = one HW thread: per k32 step loads 256B A
        // (load_2d, 8 rows x 32B, shared hot in L1/L2 per slot) + 512B B panel (streamed
        // from a pool >> L2). Comparable unit count/bytes to t39 st18 (1280 units).
        const int NBLK = 1280, SLOTA = 32, NPOOL = 16384;   // 671 MB B pool: DRAM regime
        uint8_t* pA2 = malloc_device<uint8_t>((size_t)SLOTA * M * K, q);
        uint8_t* pB2 = malloc_device<uint8_t>((size_t)NPOOL * (K / 32) * 512, q);
        int32_t* pO = malloc_device<int32_t>((size_t)NBLK * 128, q);
        q.memset(pA2, 0x03, (size_t)SLOTA * M * K).wait();
        q.memset(pB2, 0x02, (size_t)NPOOL * (K / 32) * 512).wait();
        double mb = (double)NBLK * (K / 32) * 512 / 1e6;   // B-stream bytes (A ~ L1/L2)
        auto LAUNCHWI = [&](int rot) {
            q.parallel_for(sycl::range<1>(NBLK), [=](sycl::item<1> it) SYCL_ESIMD_KERNEL {
                const int wi = (int)it.get_id(0);
                const uint8_t* Ab = pA2 + (size_t)(wi % SLOTA) * (M * K);
                const uint8_t* Bb = pB2 + (size_t)((wi + rot) % NPOOL) * (K / 32) * 512;
                simd<int32_t, 128> acc(0);
                for (int kk = 0; kk < K; kk += 32)
                {
                    simd<uint8_t, M * 32> a = load_2d<uint8_t, 32, M>(Ab, K - 1, M - 1, K - 1, kk, 0);
                    simd<uint8_t, 512> b = block_load<uint8_t, 512>(Bb + (size_t)(kk / 32) * 512);
                    acc = xmx::dpas<8, 8, int, int, uint8_t, uint8_t,
                                    xmx::dpas_argument_type::s8, xmx::dpas_argument_type::s8>(acc, b, a);
                }
                block_store(pO + (size_t)wi * 128, acc);
            }).wait();
        };
        for (int i = 0; i < 2; ++i) LAUNCHWI(i * 7919);
        double best = 1e30;
        for (int i = 0; i < iters; ++i)
        {
            auto t0 = std::chrono::steady_clock::now();
            LAUNCHWI((i + 1) * 1280 + 337);
            auto t1 = std::chrono::steady_clock::now();
            double us = std::chrono::duration<double, std::micro>(t1 - t0).count();
            if (us < best) best = us;
        }
        printf("perf: best %.1f us  B-rate %.0f GB/s  (%.0f ns/unit)\n", best, mb / best * 1000.0, best * 1000.0 / NBLK);
        return 0;
    }

    uint8_t* dA = malloc_device<uint8_t>(M * K, q);
    uint8_t* dB = malloc_device<uint8_t>(pB.size(), q);
    int32_t* dO = malloc_device<int32_t>(M * NT, q);
    q.memcpy(dA, hA.data(), M * K).wait();
    q.memcpy(dB, pB.data(), pB.size()).wait();

    const int steps = argc > 4 ? atoi(argv[4]) : K / 32;
    run_tile<0>(q, dA, dB, dO, iters, variant, steps);
    q.memcpy(dev.data(), dO, M * NT * 4).wait();
    if (probe)
    {
        for (int m = 0; m < M; ++m)
        {
            printf("P%s m%d:", probe, m);
            for (int n = 0; n < NT; ++n) printf(" %3d", (int)(int8_t)dev[(size_t)m * NT + n]);
            printf("\n");
        }
        return 0;
    }
    int bad = 0;
    for (int i = 0; i < M * NT; ++i) if (dev[i] != ref[i]) { if (bad < 6) printf("tile[%d] dev %d ref %d\n", i, dev[i], ref[i]); ++bad; }
    printf("variant %d: %s (%d/%d bad)\n", variant, bad ? "MISMATCH" : "MATCH", bad, M * NT);
    return 0;
}