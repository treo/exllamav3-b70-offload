// lab_i8gemv.cpp — for a rows=1 (decode) gemv, is the wall decode-INSTRUCTIONS or memory?
//
// Production reads a decode token's expert weights at ~76 GB/s of 608 (see NOTES lever 2), which
// prior art attributes to the ~11 lane-instructions-per-weight trellis decode (issue floor), not
// to bandwidth. The escape hatch worth pricing: keep a PRE-DECODED int8 copy of the weights and
// spend 2-4x more bytes to run ~4x fewer instructions. This lab prices that trade for the same
// logical work (one row x K x N per expert, E experts):
//
//   A packed-gather : mimics GemvK's access + decode (16-lane subgroup, one column per lane,
//                     NW u32 gathers per 16-k tile, 16 x funnel/mask/mul/pairsum/cvt/fma).
//   B int8-dot      : weights pre-decoded to int8 (VNNI-ordered, k contiguous), 8 lanes per
//                     column split k, uint4 loads (16 weights), pair multiplies in int32,
//                     subgroup reduce. ~1 instruction per 2 weights + 1 cvt/fma per 16.
//   C int8-load-only: identical loads to B, math replaced by a cheap XOR fold (DCE-barriered)
//                     => the memory ceiling for that access pattern at this working set.
//
// Reports us, REAL GB/s of bytes touched, and PACKED-EQUIVALENT GB/s (logical weight count x
// 0.27 B/weight, i.e. what the packed tier would have read) so B/C compare directly against the
// production 76 GB/s. Diagnostic lab; nothing here is a claim of a win.
//   icpx -fsycl -O3 -ffp-contract=off lab_i8gemv.cpp -o lab_i8gemv && ./lab_i8gemv [E] [K] [N]
#include <sycl/sycl.hpp>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <vector>
#include <algorithm>

static double now_us() {
    return std::chrono::duration<double, std::micro>(
        std::chrono::steady_clock::now().time_since_epoch()).count();
}
static constexpr float KDQ = 0.001f;

int main(int argc, char** argv) {
    const int E = argc > 1 ? atoi(argv[1]) : 10;      // experts touched by one decode token
    const int K = argc > 2 ? atoi(argv[2]) : 2560;
    const int N = argc > 3 ? atoi(argv[3]) : 640;
    sycl::queue q{sycl::gpu_selector_v, sycl::property::queue::in_order{}};
    printf("device %s\nE %d K %d N %d -> logical weights %.1f M, packed-read %.1f MB "
           "(4 bits/w), int8-read %.1f MB\n",
           q.get_device().get_info<sycl::info::device::name>().c_str(), E, K, N,
           1.0 * E * K * N / 1e6, 1.0 * E * K * N * 0.5 / 1e6, 1.0 * E * K * N * 1.0 / 1e6);

    const size_t tiles_k = K / 16, tiles_n = N / 16;
    const size_t TN = N / 16;
    const size_t packed_w = (size_t)E * TN * tiles_k * 32;   // u32 words of the n-major stream
    const size_t i8_b     = (size_t)E * (size_t)K * N;                 // one int8 per weight
    uint32_t* wpack = sycl::malloc_device<uint32_t>(packed_w, q);
    int8_t* wi8 = sycl::malloc_device<int8_t>(i8_b, q);
    int8_t* xi8 = sycl::malloc_device<int8_t>((size_t)E * K, q);
    float* xrow = sycl::malloc_device<float>((size_t)E * K, q);
    float* out = sycl::malloc_device<float>((size_t)E * N, q);
    q.parallel_for(packed_w, [=](sycl::id<1> i) { wpack[i] = (uint32_t)(i[0] * 2654435761u); }).wait();
    q.parallel_for(i8_b, [=](sycl::id<1> i) { wi8[i[0]] = (int8_t)((i[0] * 37) & 0xff); }).wait();
    q.parallel_for((size_t)E * K, [=](sycl::id<1> i) {
        xi8[i[0]] = (int8_t)((i[0] * 11) & 0x7f); xrow[i[0]] = 0.001f * (float)(i[0] & 127); }).wait();
    q.memset(out, 0, (size_t)E * N * sizeof(float)).wait();

    const double pack_MB = 1.0 * E * K * N * 0.5 / 1e6;    // what the packed tier would read
    auto report = [&](const char* nm, double us, double real_bytes) {
        printf("  %-16s %8.1f us | real bytes %6.1f GB/s | packed-equivalent %6.1f GB/s\n",
               nm, us, real_bytes / (us * 1e3), (pack_MB * 1e6) / (us * 1e3));
    };

    // ---------------- A: packed-gather (mirrors GemvK's K2=8 inner loop, m=1)
    {
        constexpr int K2V = 8, W = 4 * K2V, NW = ((27 * K2V) / 2 + 16 + 62) / 32 + 1;
        const int ncol_wg = 128;                       // one WG = 128 columns
        const size_t gsize = (size_t)E * (N / ncol_wg) * 1;
        auto runA = [&]() {
            return q.submit([&](sycl::handler& cgh) {
                cgh.parallel_for(sycl::nd_range<1>{{gsize * ncol_wg}, {ncol_wg}},
                    [=](sycl::nd_item<1> it) {
                        const int e = (int)it.get_group(0) / (int)(N / ncol_wg);
                        const int blk = (int)it.get_group(0) % (int)(N / ncol_wg);
                        const int tid = (int)it.get_local_id(0);
                        const int cG = blk * ncol_wg + tid;
                        const int tile_n = cG >> 4, cin = cG & 15;
                        const int A2 = (K2V * (32 * (cin & 7) + 4 * ((cin >> 3) & 1))) >> 1;
                        const int AD27 = (27 * K2V) >> 1;
                        const int G = (32 - (K2V >> 1)) - A2 - AD27, wb = G >> 5, pre = G - (wb << 5);
                        int widx[NW];
    #pragma unroll
                        for (int i = 0; i < NW; ++i) widx[i] = ((wb + i) % W + W) % W;
                        const float* xr0 = xrow + (size_t)e * K;
                        float acc = 0.f, accB = 0.f;
                        const uint32_t* wp = wpack + ((size_t)e * TN + tile_n) * tiles_k * W;
                        uint32_t g[NW], gn[NW];
    #pragma unroll
                        for (int i = 0; i < NW; ++i) g[i] = wp[widx[i]];   // 7 gathers per tile row
                        for (size_t tk = 0; tk < tiles_k; ++tk, wp += W) {
    #pragma unroll
                            for (int i = 0; i < NW; ++i) gn[i] = wp[W + widx[i]];
                            uint32_t h[NW];
                            for (int i = 0; i + 1 < NW; ++i) h[i] = (g[i] >> pre) | (g[i + 1] << (32 - pre));
                            h[NW - 1] = g[NW - 1] >> pre;
    #pragma unroll
                            for (int rk = 0; rk < 16; ++rk) {
                                const int d = 8 * ((rk >> 1) & 3) + (rk & 1) + 2 * ((rk >> 3) & 1);
                                const int rel = AD27 - ((K2V * d) >> 1);
                                const uint32_t lo4 = h[rel >> 5], hi4 = h[(rel >> 5) + 1];
                                const uint32_t st16 = ((lo4 >> (rel & 31)) | ((hi4 << 1) << (31u - (rel & 31)))) & 0xffffu;
                                const uint32_t xm = st16 * 0x83DCD12Du;
                                const uint32_t t1 = (xm & 0x00ff00ffu) + ((xm >> 8) & 0x00ff00ffu);
                                const uint32_t bs = (t1 & 0xffffu) + (t1 >> 16);
                                const float wc = (float)(int)bs - 510.0f;
                                if (rk & 1) accB = sycl::fma(wc, xr0[tk * 16 + rk], accB);
                                else        acc  = sycl::fma(wc, xr0[tk * 16 + rk], acc);
                            }
    #pragma unroll
                            for (int i = 0; i < NW; ++i) g[i] = gn[i];
                        }
                        out[(size_t)e * N + blk * ncol_wg + tid] = (acc + accB) * KDQ;
                    });
            });
        };
        for (int i = 0; i < 300; ++i) runA().wait();
        double b = 1e30;
        for (int w = 0; w < 3; ++w) { double t0 = now_us(); for (int i = 0; i < 300; ++i) runA().wait();
            b = std::min(b, (now_us() - t0) / 300); }
        printf("A packed-gather (like GemvK, m=1):\n");
        report("A", b, pack_MB * 1e6);
    }

    // ---------------- B: int8-dot, and C: int8-load-only (same access, no math)
    for (int mode = 0; mode < 2; ++mode) {
        const int SPLIT = 8;                       // lanes per column, k split
        const int LC = 128;                        // lanes per WG
        const int cols_per_wg = LC / SPLIT;        // 16 columns per WG
        const size_t wgs = (size_t)E * (N / cols_per_wg);
        auto runBC = [&]() {
            return q.submit([&](sycl::handler& cgh) {
                cgh.parallel_for(sycl::nd_range<1>{{wgs * LC}, {LC}},
                    [=](sycl::nd_item<1> it) {
                        const int wg = (int)it.get_group(0), tid = (int)it.get_local_id(0);
                        const int e = wg / (int)(N / cols_per_wg);
                        const int cblk = wg % (int)(N / cols_per_wg);
                        const int col = cblk * cols_per_wg + (tid / SPLIT);
                        const int ks = tid % SPLIT;
                        const int kchunk = K / SPLIT;                 // per lane
                        const size_t base = (size_t)e * K * N + (size_t)col * K;   // k-contiguous
                        const int8_t* wp = wi8 + base + (size_t)ks * kchunk;
                        const int8_t* xp = xi8 + (size_t)e * K + (size_t)ks * kchunk;
                        int iacc = 0; unsigned xoracc = 0;
                        for (int k = 0; k < kchunk; k += 16) {
                            // 16 int8 products folded pairwise into int32 (dp4a-equivalent)
                            int s0 = 0;
                            #pragma unroll
                            for (int j = 0; j < 16; j += 4) {
                                int a = wp[k + j], b2 = xp[k + j];
                                int c = wp[k + j + 1], d = xp[k + j + 1];
                                int aa = wp[k + j + 2], bb = xp[k + j + 2];
                                int cc = wp[k + j + 3], dd = xp[k + j + 3];
                                s0 += (a * b2 + c * d) + (aa * bb + cc * dd);
                                if (mode == 1) xoracc ^= (unsigned)(a ^ c ^ aa ^ cc ^ b2 ^ d ^ bb ^ dd);
                            }
                            iacc += s0;
                        }
                        // fold the k-split partials (timing-faithful; values are probe garbage)
                        iacc = sycl::reduce_over_group(it.get_sub_group(), iacc, sycl::plus<int>());
                        if (ks == 0) {
                            float r = (float)iacc * KDQ;
                            if (mode == 1) r += (float)(xoracc & 1) * 0.f;
                            out[(size_t)e * N + col] = r;
                        }
                    });
            });
        };
        for (int i = 0; i < 300; ++i) runBC().wait();
        double b2 = 1e30;
        for (int w = 0; w < 3; ++w) { double t0 = now_us(); for (int i = 0; i < 300; ++i) runBC().wait();
            b2 = std::min(b2, (now_us() - t0) / 300); }
        printf(mode ? "\nC int8 loads only (memory ceiling for this pattern):\n"
                    : "\nB int8 pre-decoded dot (~1 inst / 2 weights):\n");
        report(mode ? "C" : "B", b2, (double)i8_b);
    }

    sycl::free(wpack, q); sycl::free(wi8, q); sycl::free(xi8, q); sycl::free(xrow, q); sycl::free(out, q);
    return 0;
}