// lab_gemv_shape.cpp — is the rows=1 decode gemv ISSUE-bound or PARALLELISM-bound?
//
// Evidence that started this: the packed k-walk is already sequential (MOE_STREAM_NMAJOR=1) and a
// pure read probe of this exact layout measured 781 GB/s (moe_sycl.hpp header, t47), yet the
// shipping decode gemv reads it at ~160 GB/s. lab_i8gemv then showed variant A going 145 -> 254
// GB/s purely by DOUBLING THE WORKGROUP COUNT with identical per-lane instruction counts, and
// lab_gemv_ablate showed that REMOVING 16 ACTIVATION LOADS PER TILE makes the loop *slower*.
// Both point at exposed memory latency (too few independent streams per EU), not at the trellis
// decode's instruction count.
//
// So the two knobs that cost nothing (no layout change, no numerical change, no extra VRAM):
//   NCWG  columns per workgroup. 128 today. Halving it DOUBLES the workgroup count for the same
//         total work and the same bytes touched (each 16-lane subgroup still owns one 64 B tile
//         ring), so it buys streams without buying traffic - if registers, not threads, gate EU
//         occupancy.
//   DEPTH software-pipeline depth. 2 today. Each extra level is one more outstanding ring load
//         per lane: latency hidden INSIDE a stream instead of by adding streams.
//
// Everything else is GemvK<4,false> verbatim at the 2.05bpw rate (K2=4: W=16 ring words = 64 B per
// 16x16 tile, NW=5, 0.25 B per weight), 16-lane subgroups, per-tile pre-shift, two FMA chains.
// Timed like the benches: 300 back-to-back launches, min over 3 windows.
//   icpx -fsycl -O3 -ffp-contract=off lab_gemv_shape.cpp -o lab_gemv_shape && ./lab_gemv_shape [E] [K] [N]
#include <sycl/sycl.hpp>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <algorithm>

static double now_us() {
    return std::chrono::duration<double, std::micro>(
        std::chrono::steady_clock::now().time_since_epoch()).count();
}

static constexpr float KDQ = 0.00676727294921875f;
static constexpr int K2V = 4;                                 // 2.05bpw: 2 bits/weight
static constexpr int W = 4 * K2V;                             // 16 words = 64 B ring per tile
static constexpr int AD27 = (27 * K2V) >> 1;
static constexpr int NW = (AD27 + 16 + 31 + 31) / 32 + 1;     // 5

template <int NCWG, int DEPTH>
struct Body {
    const uint32_t* wpack;
    const float* xrow;
    float* out;
    size_t tiles_k, TN;
    int K, N, E;

    void operator()(sycl::nd_item<1> it) const {
        const int ng = (int)it.get_group(0);
        const int e = ng / (int)(N / NCWG);
        const int blk = ng % (int)(N / NCWG);
        const int tid = (int)it.get_local_id(0);
        const int cG = blk * NCWG + tid;
        const int tile_n = cG >> 4, cin = cG & 15;
        const int A2 = (K2V * (32 * (cin & 7) + 4 * ((cin >> 3) & 1))) >> 1;
        const int G = (32 - (K2V >> 1)) - A2 - AD27, wb = G >> 5, pre = G - (wb << 5);
        int widx[NW];
#pragma unroll
        for (int i = 0; i < NW; ++i) widx[i] = ((wb + i) % W + W) % W;

        const float* xr0 = xrow + (size_t)e * K;
        float acc = 0.f, accB = 0.f;
        const uint32_t* wp = wpack + ((size_t)e * TN + tile_n) * tiles_k * W;

        // Software pipeline of depth DEPTH: at the top of iteration tk, gp[p] holds ring word set
        // for tile tk+p. Indexing is compile-time throughout (a runtime slot index trips DPC++'s
        // device std-sec-range check, which aborts the lab); DEPTH=2 reduces to production's
        // g/gn pair plus the same g=gn copy at the bottom.
        uint32_t gp[DEPTH][NW];
        constexpr int npre = DEPTH - 1;
#pragma unroll
        for (int p = 0; p < npre; ++p)
#pragma unroll
            for (int i = 0; i < NW; ++i)
                gp[p][i] = ((size_t)p < tiles_k) ? wp[(size_t)p * W + widx[i]] : 0u;

        for (size_t tk = 0; tk < tiles_k; ++tk, wp += W) {
            if constexpr (DEPTH > 1) {
                if (tk + npre < tiles_k) {
                    const uint32_t* wpf = wp + (size_t)npre * W;
#pragma unroll
                    for (int i = 0; i < NW; ++i) gp[npre][i] = wpf[widx[i]];
                }
            } else {
#pragma unroll
                for (int i = 0; i < NW; ++i) gp[0][i] = wp[widx[i]];
            }
            const uint32_t* g = gp[0];
            uint32_t h[NW];
            if (pre == 0) {
#pragma unroll
                for (int i = 0; i < NW; ++i) h[i] = g[i];
            } else {
#pragma unroll
                for (int i = 0; i + 1 < NW; ++i) h[i] = (g[i] >> pre) | (g[i + 1] << (32 - pre));
                h[NW - 1] = g[NW - 1] >> pre;
            }
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
                const float xv = xr0[tk * 16 + rk];
                if (rk & 1) accB = sycl::fma(wc, xv, accB);
                else        acc  = sycl::fma(wc, xv, acc);
            }
            if constexpr (DEPTH > 1) {
#pragma unroll
                for (int p = 0; p < npre; ++p)
#pragma unroll
                    for (int i = 0; i < NW; ++i) gp[p][i] = gp[p + 1][i];
            }
        }
        out[(size_t)e * N + blk * NCWG + tid] = (acc + accB) * KDQ;
    }
};

static size_t g_last_wgs = 0;
template <int NCWG, int DEPTH>
static double bench(sycl::queue& q, uint32_t* wpack, float* xrow, float* out,
                    size_t tiles_k, size_t TN, int K, int N, int E) {
    const size_t wgs = (size_t)E * (N / NCWG);
    g_last_wgs = wgs;
    Body<NCWG, DEPTH> bd{wpack, xrow, out, tiles_k, TN, K, N, E};
    auto run = [&]() {
        return q.submit([&](sycl::handler& cgh) {
            cgh.parallel_for(sycl::nd_range<1>{{wgs * NCWG}, {NCWG}},
                [=](sycl::nd_item<1> it) { bd(it); });
        });
    };
    for (int i = 0; i < 300; ++i) run().wait();
    double b = 1e30;
    for (int w = 0; w < 3; ++w) {
        double t0 = now_us();
        for (int i = 0; i < 300; ++i) run().wait();
        b = std::min(b, (now_us() - t0) / 300);
    }
    return b;
}

int main(int argc, char** argv) {
    const int E = argc > 1 ? atoi(argv[1]) : 10;
    const int K = argc > 2 ? atoi(argv[2]) : 2560;
    const int N = argc > 3 ? atoi(argv[3]) : 640;
    sycl::queue q{sycl::gpu_selector_v, sycl::property::queue::in_order{}};
    auto dev = q.get_device();
    const size_t tiles_k = K / 16, TN = N / 16;
    const size_t packed_w = (size_t)E * TN * tiles_k * W;
    const double pack_MB = 1.0 * packed_w * 4 / 1e6;
    printf("device %s\nE %d K %d N %d | arena %.2f MB @2 bits/w | one gemv of the decode pair"
           " | wg count shown per config\n",
           dev.get_info<sycl::info::device::name>().c_str(), E, K, N, pack_MB);

    uint32_t* wpack = sycl::malloc_device<uint32_t>(packed_w, q);
    float* xrow = sycl::malloc_device<float>((size_t)E * K, q);
    float* out = sycl::malloc_device<float>((size_t)E * N, q);
    q.parallel_for(packed_w, [=](sycl::id<1> i) { wpack[i] = (uint32_t)(i[0] * 2654435761u); }).wait();
    q.parallel_for((size_t)E * K, [=](sycl::id<1> i) { xrow[i[0]] = 0.001f * (float)(i[0] & 127); }).wait();
    q.memset(out, 0, (size_t)E * N * sizeof(float)).wait();

    auto pr = [&](const char* nm, double us) {
        printf("  %-22s %7.1f us | %6.1f GB/s packed | %4zu wgs\n", nm, us, pack_MB * 1e6 / (us * 1e3),
               g_last_wgs);
    };
#define RUN(nc, d) pr("NCWG " #nc " DEPTH " #d, bench<nc, d>(q, wpack, xrow, out, tiles_k, TN, K, N, E))
    RUN(128, 2);   // == production shape
    RUN(128, 1);
    RUN(128, 4);
    RUN(64, 2);
    RUN(64, 4);
    RUN(32, 2);
    RUN(32, 4);
    RUN(256, 2);
    RUN(256, 4);
    RUN(16, 2);
    RUN(16, 4);
    RUN(128, 2);   // repeat of the baseline: drift check within one process
#undef RUN
    printf("  (pure sequential read of this layout measured 781 GB/s in t47;"
           " shipping gu gemv = 160 GB/s at 100 wgs)\n");

    sycl::free(wpack, q); sycl::free(xrow, q); sycl::free(out, q);
    return 0;
}