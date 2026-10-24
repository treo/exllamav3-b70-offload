// Rigorous inner-loop A/B lab: same data shape as the real gemv (tile rings, per-column
// word plans), several lowering strategies, interleaved reps, min-of-many.
#include <sycl/sycl.hpp>
#include <sycl/ext/oneapi/dot_product.hpp>
#include <cstdio>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <algorithm>
#include <vector>

constexpr int K2 = 4;                 // K=2 rate (target model)
constexpr int W = 4 * K2;             // u32 words per tile
constexpr int NG = 100;               // workgroups
constexpr int LT = 128;               // threads/WG
constexpr int TK = 160;               // k tiles
constexpr int TILES = LT / 16;        // tiles per WG (one per 16-lane group)
constexpr size_t BUFN = (size_t)NG * TILES * W * TK;

struct ColPlan { unsigned int a[16]; };

template <int MODE>
float run_once(sycl::queue& q, uint32_t* buf, const float* tin, float* out, const ColPlan* plans)
{
    sycl::event e = q.submit([&](sycl::handler& cgh) {
        cgh.parallel_for(sycl::nd_range<1>({(size_t)NG * LT}, {LT}), [=](sycl::nd_item<1> it) {
            const int g = (int)it.get_group(0), tid = (int)it.get_local_id(0);
            const int sg = tid >> 4, lane = tid & 15;
            const ColPlan cp = plans[lane];
            const uint32_t* wp = buf + (size_t)sg * W;
            const float* tp = tin;
            float acc0 = 0, acc1 = 0, acc2 = 0, acc3 = 0;
            int ia0 = 0, ia1 = 0, ia2 = 0, ia3 = 0;
            const int x0 = (int)tp[0] & 0xff, x1 = (int)tp[8] & 0xff;   // int8 operands demo
            for (int tk = 0; tk < TK; ++tk, wp += (size_t)TILES * W, tp += 16) {
#pragma unroll
                for (int rk = 0; rk < 16; ++rk) {
                    const unsigned a = cp.a[rk];
                    const uint32_t v0 = wp[a & 0xff], v1 = wp[(a >> 8) & 0xff];
                    const uint64_t merged = ((uint64_t)v0 << 32) | v1;
                    const uint32_t st16 = (uint32_t)(merged >> (a >> 16)) & 0xffffu;
                    if (MODE == 0) {            // fp path (current)
                        const uint32_t xm = st16 * 0x83DCD12Du;
                        const uint32_t t1 = (xm & 0x00ff00ffu) + ((xm >> 8) & 0x00ff00ffu);
                        const uint32_t bs = (t1 & 0xffffu) + (t1 >> 16);
                        const float wcomb = (float)(int)bs - 510.0f;
                        acc0 = sycl::fma(wcomb, tp[rk], acc0);
                        acc1 = sycl::fma(wcomb, tp[(size_t)2560 + rk], acc1);
                    } else if (MODE == 1) {     // dp4a int path (x replicated bytes)
                        const uint32_t xm = st16 * 0x83DCD12Du;
                        const uint32_t splat = (0x01010101u * (uint32_t)(x0 & 0x7f)) | 0x80808080u * 0u;
                        ia0 = sycl::ext::oneapi::dot_acc(xm, splat, ia0);
                        ia1 = sycl::ext::oneapi::dot_acc(xm, splat ^ 0x00800000u, ia1);
                    } else if (MODE == 2) {     // manual int8: 4 explicit byte mults
                        const uint32_t xm = st16 * 0x83DCD12Du;
                        const int xb = x0 & 0x3f;
                        ia0 += (int)(xm & 0xff) * xb + (int)((xm >> 8) & 0xff) * xb
                             + (int)((xm >> 16) & 0xff) * xb + (int)(xm >> 24) * xb;
                        ia1 += (int)(xm & 0xff) * (x1 & 0x3f);
                    } else if (MODE == 3) {     // loads + shift only (floor probe)
                        acc0 += (float)st16;
                    }
                }
            }
            out[(size_t)g * LT + tid] = acc0 + acc1 + acc2 + acc3 + (float)(ia0 + ia1 + ia2 + ia3) + x0 + x1;
        });
    });
    e.wait();
    return (float)(e.get_profiling_info<sycl::info::event_profiling::command_end>() -
                   e.get_profiling_info<sycl::info::event_profiling::command_start>()) * 1e-3;
}

template <int MODE>
float bench(sycl::queue& q, uint32_t* buf, const float* tin, float* out, const ColPlan* plans)
{
    float best = 1e30;
    for (int r = 0; r < 30; ++r) best = std::min(best, run_once<MODE>(q, buf, tin, out, plans));
    return best;
}

int main()
{
    sycl::queue q{sycl::gpu_selector_v, {sycl::property::queue::enable_profiling()}};
    uint32_t* buf = sycl::malloc_device<uint32_t>(BUFN, q);
    float* tin = sycl::malloc_device<float>(256 * 2560, q);
    float* out = sycl::malloc_device<float>(NG * LT, q);
    q.parallel_for(BUFN, [=](sycl::id<1> i) { buf[i] = (uint32_t)(i[0] * 2654435761u) >> 8; }).wait();
    q.memset(tin, 0, 256 * 2560 * 4).wait();
    std::vector<ColPlan> hplans(16);
    for (int cin = 0; cin < 16; ++cin)
        for (int rk = 0; rk < 16; ++rk) {
            const int bb = ((cin & 7) << 2) | ((rk >> 1) & 3);
            const int jj = (rk & 1) | ((rk & 8) ? 2 : 0) | ((cin & 8) ? 4 : 0);
            const int t = (bb << 3) | jj;
            const int b1 = (((t + 1) * K2) >> 1) + 128 * K2;
            const int b0 = b1 - 16;
            hplans[cin].a[rk] = (unsigned)((b0 >> 5) % W | ((((b1 - 1) >> 5) % W) << 8) | (((((b1 - 1) >> 5) + 1) * 32 - b1) << 16));
        }
    ColPlan* plans = sycl::malloc_device<ColPlan>(16, q);
    q.memcpy(plans, hplans.data(), 16 * sizeof(ColPlan)).wait();
    const double mb = (double)BUFN * 4 / 1e6;
    printf("footprint %.1f MB\n", mb);
    for (int round = 0; round < 3; ++round) {
        printf("round %d: fp=%.1f dp4a=%.1f manual=%.1f floor=%.1f us\n", round,
               bench<0>(q, buf, tin, out, plans), bench<1>(q, buf, tin, out, plans),
               bench<2>(q, buf, tin, out, plans), bench<3>(q, buf, tin, out, plans));
    }
    return 0;
}