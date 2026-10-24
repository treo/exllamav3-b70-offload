// gemv inner-loop cost ladder
#include <sycl/sycl.hpp>
#include <cstdio>
#include <cstdint>
#include <algorithm>
#include <vector>
template <int MODE>
void run(sycl::queue& q, uint32_t* w, float* tin, float* out, int NC, int NM, int TK, int TNB, int K) {
    // same geometry as K2: units = NC*NM*(I/128); here TNB = blocks of 128 cols
    const int units = NC * NM * TNB;
    double best = 1e30;
    for (int rep = 0; rep < 20; ++rep) {
        auto e = q.submit([&](sycl::handler& cgh) {
            cgh.parallel_for(sycl::nd_range<1>({(size_t)units * 128}, {128}), [=](sycl::nd_item<1> it) {
                const int unit = (int)it.get_group(0);
                const int tid = (int)it.get_local_id(0);
                const int blk = unit % TNB;
                const int jm = unit / TNB;
                const int cG = blk * 128 + tid;
                const int tile_n = cG >> 4, cin = cG & 15;
                const int k2 = 4, tile_u32 = 16;
                unsigned long long apack[8] = {0,0,0,0,0,0,0,0};
    #pragma unroll
                for (int rk = 0; rk < 16; ++rk) {
                    const int row = rk, col = cin;
                    const int b = ((col & 7) << 2) | ((row >> 1) & 3);
                    const int jj = (row & 1) | ((row & 8) ? 2 : 0) | ((col & 8) ? 4 : 0);
                    const int t = (b << 3) | jj;
                    const int b1 = (((t + 1) * k2) >> 1) + 128 * k2;
                    const int b0 = b1 - 16;
                    const int w0 = (b0 >> 5) % tile_u32;
                    const int w1 = ((b1 - 1) >> 5) % tile_u32;
                    const int sh = (((b1 - 1) >> 5) + 1) * 32 - b1;
                    apack[rk >> 1] |= (unsigned long long)(w0 | (w1 << 8) | (sh << 16)) << ((rk & 1) * 24);
                }
    #define GETADDR(rk_const) ((apack[(rk_const) >> 1] >> (((rk_const) & 1) * 24)) & 0xffffffu)
                float acc = 0;
                float acc4[4] = {0, 0, 0, 0};
                const int tiles_n = TNB * 8;
                const uint32_t* wp = w + ((size_t)jm * tiles_n + tile_n) * tile_u32;
                const float* tp = tin + (size_t)jm * K;
                for (int tk = 0; tk < TK; ++tk, wp += (size_t)tiles_n * tile_u32, tp += 16) {
    #pragma unroll
                    for (int rk = 0; rk < 16; ++rk) {
                        unsigned a;
                        if (MODE == 7) {
                            const int row = rk;
                            const int b = ((cin & 7) << 2) | ((row >> 1) & 3);
                            const int jj = (row & 1) | ((row & 8) ? 2 : 0) | ((cin & 8) ? 4 : 0);
                            const int t = (b << 3) | jj;
                            const int bb1 = (((t + 1) * k2) >> 1) + 128 * k2;
                            const int bb0 = bb1 - 16;
                            a = (unsigned)(((bb0 >> 5) % tile_u32) | ((((bb1 - 1) >> 5) % tile_u32) << 8) | (((((bb1 - 1) >> 5) + 1) * 32 - bb1) << 16));
                        } else if (MODE == 5) {
                            a = (unsigned)(rk / 2 | ((rk / 2) << 8) | (16 << 16));
                        } else {
                            a = (unsigned)GETADDR(rk);
                        }
                        const uint32_t v0 = wp[a & 0xff], v1 = wp[(a >> 8) & 0xff];
                        if (MODE == 0) { acc += (float)(v0 + v1); continue; }
                        const uint64_t merged = ((uint64_t)v0 << 32) | v1;
                        const uint32_t st16 = ((uint32_t)(merged >> (a >> 16))) & 0xffffu;
                        if (MODE == 1) { acc += (float)st16; continue; }
                        const uint32_t xm = st16 * 0x83DCD12Du;
                        if (MODE == 2) { acc += (float)xm; continue; }
                        if (MODE == 5) { acc += (float)st16; continue; }
                        if (MODE == 7 && rk == 0) acc += 0.f;  // keep st path
                        const float wcomb = (float)((xm & 0xff) + ((xm >> 8) & 0xff) +
                                                    ((xm >> 16) & 0xff) + (xm >> 24)) - 510.0f;
                        if (MODE == 3) { acc += wcomb; continue; }
                        if (MODE == 6) { acc4[rk & 3] = sycl::fma(wcomb, tp[rk], acc4[rk & 3]); continue; }
                        acc = sycl::fma(wcomb, tp[rk], acc);
                    }
                }
                out[(size_t)jm * TNB * 128 + cG] = MODE == 6 ? (acc4[0] + acc4[1]) + (acc4[2] + acc4[3]) : acc;
            });
        });
        e.wait();
        best = std::min(best, (double)(e.template get_profiling_info<sycl::info::event_profiling::command_end>() -
                     e.template get_profiling_info<sycl::info::event_profiling::command_start>()) * 1e-3);
    }
    printf("mode %d: %.1f us\n", MODE, best);
}
int main() {
    sycl::queue q{sycl::gpu_selector_v, {sycl::property::queue::enable_profiling()}};
    // K2 geometry: 10 experts x 2 mats, tiles_k=160, 5 blocks, K=2560, weights 10*2*640*2560*0.25
    const int NC = 10, NM = 2, TK = 160, TNB = 5, K = 2560;
    const size_t wcount = (size_t)NC * NM * (TNB * 8) * TK * 16;
    uint32_t* w = sycl::malloc_device<uint32_t>(wcount, q);
    float* tin = sycl::malloc_device<float>((size_t)NC * NM * K, q);
    float* out = sycl::malloc_device<float>((size_t)NC * NM * TNB * 128, q);
    q.memset(w, 0x5a, wcount * 4).wait();
    q.memset(tin, 0, (size_t)NC * NM * K * 4).wait();
    run<0>(q, w, tin, out, NC, NM, TK, TNB, K);
    run<1>(q, w, tin, out, NC, NM, TK, TNB, K);
    run<2>(q, w, tin, out, NC, NM, TK, TNB, K);
    run<3>(q, w, tin, out, NC, NM, TK, TNB, K);
    run<4>(q, w, tin, out, NC, NM, TK, TNB, K);
    run<5>(q, w, tin, out, NC, NM, TK, TNB, K);
    run<6>(q, w, tin, out, NC, NM, TK, TNB, K);
    run<7>(q, w, tin, out, NC, NM, TK, TNB, K);
    return 0;
}
