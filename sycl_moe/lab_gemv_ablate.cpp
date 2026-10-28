// lab_gemv_ablate.cpp — ablation ladder on the REAL decode gemv inner loop (K2=4 == 2.05bpw).
//
// Why: the packed k-walk is already sequential (MOE_STREAM_NMAJOR=1) and the pure read probe of
// this exact layout measured 781 GB/s (moe_sycl.hpp header, t47), while the shipping rows=1 gemv
// runs at ~160 GB/s of packed bytes. So the wall is what the kernel DOES per weight, not DRAM.
// "Byte-align the nibbles" is NOT available: mul1 stores 16-bit trellis STATES that advance by
// K2/2 bits (2 bits at K2=4), so de-overlapping a lane's window would duplicate the arena 32/K2
// = 8x. The question this lab answers is which instruction CLASS to remove instead, and whether
// removal is paid for by memory latency (another class gets worse) rather than by issue.
//
// Base = GemvK<4,false> faithfully: 16-lane subgroups, one output column per lane, 8 column tiles
// per 128-lane WG, NW=5 u32 gathers per 16-k tile with a depth-2 pipeline, per-weight
// funnel-extract + magic multiply + bytesum + cvt + fma, activations read per lane per tile.
//
// MODE  what is taken away                                        if it gets much faster, the wall is
//   0   full (== production)                                       -  (reference)
//   1   weight loads replaced by a loop-variant seed               global load issue / latency
//   2   activation loads replaced by a constant                    redundant per-lane tin reads
//   3   bytesum chain collapsed to one mask                        the 0x83DCD12D + pair-sum idiom
//   4   state extract collapsed to one register select             the funnel-shift / pre-shift path
//   5   activations staged once per WG in SLM (whole k slice)      upper bound on fixing tin
//   6   whole ring loaded as W/4 x uint4 vectors, extracted from    5 scalar gathers -> 4 vec loads
//       registers (SAME bytes, different instruction mix)
//   7   activations read as 4 x float4 per tile into registers      16 scalar loads -> 4 vector loads
//       (numerically IDENTICAL values, identical FMA order)
//
// Timed like production benches: 300 back-to-back launches, min over 3 windows. Values are probe
// garbage; the access pattern and instruction mix are the signal. Nothing here is a win claim.
//   icpx -fsycl -O3 -ffp-contract=off lab_gemv_ablate.cpp -o lab_gemv_ablate && ./lab_gemv_ablate [E] [K] [N] [mode]
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

static constexpr float KDQ = 0.00676727294921875f;   // production k_inv (2.05bpw, hb=0)
static constexpr int K2V = 4;                        // 2 bits/weight, hb=0 -> the model under test
static constexpr int W = 4 * K2V;                    // ring words per 16x16 tile (16 -> 64 B)
static constexpr int AD27 = (27 * K2V) >> 1;
static constexpr int NW = (AD27 + 16 + 31 + 31) / 32 + 1;   // 5 words cover a lane's 16 windows

// MODE 5 geometry: stage the WG's whole activation slice in SLM.
template <int MODE>
struct Body {
    const uint32_t* __restrict__ wpack;
    const float* __restrict__ xrow;
    float* __restrict__ out;
    sycl::local_ptr<float> slm{};        // MODE 5 only (accessor pointer, set inside the kernel)
    size_t tiles_k, TN;   // TN = tiles_n of this matrix
    int K, N, E;

    void operator()(sycl::nd_item<1> it) {
        const int ncol_wg = 128;
        const int ng = (int)it.get_group(0);
        const int e = ng / (int)(N / ncol_wg);
        const int blk = ng % (int)(N / ncol_wg);
        const int tid = (int)it.get_local_id(0);
        const int cG = blk * ncol_wg + tid;
        const int tile_n = cG >> 4, cin = cG & 15;
        const int A2 = (K2V * (32 * (cin & 7) + 4 * ((cin >> 3) & 1))) >> 1;
        const int G = (32 - (K2V >> 1)) - A2 - AD27, wb = G >> 5, pre = G - (wb << 5);
        int widx[NW];
#pragma unroll
        for (int i = 0; i < NW; ++i) widx[i] = ((wb + i) % W + W) % W;

        const float* xr0 = xrow + (size_t)e * K;
        float acc = 0.f, accB = 0.f;
        const uint32_t* wp = wpack + ((size_t)e * TN + tile_n) * tiles_k * W;

        int nslm = 0;
        if constexpr (MODE == 5) {
            nslm = (int)(tiles_k * 16);
            for (int i = tid; i < nslm; i += ncol_wg) slm[i] = xr0[i];
            sycl::group_barrier(it.get_group());
        }

        uint32_t g[NW], gn[NW];
#pragma unroll
        for (int i = 0; i < NW; ++i) g[i] = (MODE == 1) ? (uint32_t)(tid + i) : wp[widx[i]];
        for (size_t tk = 0; tk < tiles_k; ++tk, wp += W) {
            const uint32_t seed = (uint32_t)(tk * 2654435761u + tid);
            if (tk + 1 < tiles_k) {
                if constexpr (MODE == 6) {
                    const sycl::uint4* rv = (const sycl::uint4*)(wp + W);
#pragma unroll
                    for (int i = 0; i < W / 4; ++i) { sycl::uint4 u = rv[i]; gn[4*i] = u.x(); gn[4*i+1] = u.y(); gn[4*i+2] = u.z(); gn[4*i+3] = u.w(); }
                } else if constexpr (MODE != 1) {
                    const uint32_t* wpn = wp + W;
#pragma unroll
                    for (int i = 0; i < NW; ++i) gn[i] = wpn[widx[i]];
                } else {
#pragma unroll
                    for (int i = 0; i < NW; ++i) gn[i] = seed + i;
                }
            }
            // pre-shift the ring window once per tile (production trick)
            uint32_t h[NW];
            if (pre == 0) {
#pragma unroll
                for (int i = 0; i < NW; ++i) h[i] = g[i];
            } else {
#pragma unroll
                for (int i = 0; i + 1 < NW; ++i) h[i] = (g[i] >> pre) | (g[i + 1] << (32 - pre));
                h[NW - 1] = g[NW - 1] >> pre;
            }
            // Activations: ONE read per rk, inline in the consumer, exactly as GemvK does
            // (`const float* xr = tp + rk; ... fma(wcomb, xr[0], acc)`). Hoisting all 16 into a
            // register array first was a lab artifact: it spilled and made mode 0 2.5x slower
            // than the kernel it claims to model.
            sycl::float4 v4[4];
            if constexpr (MODE == 7) {
                const sycl::float4* x4 = (const sycl::float4*)(xr0 + tk * 16);
#pragma unroll
                for (int i = 0; i < 4; ++i) v4[i] = x4[i];
            }
#pragma unroll
            for (int rk = 0; rk < 16; ++rk) {
                float xv;
                if constexpr (MODE == 2)      xv = 1e-3f * (float)(seed & 7);
                else if constexpr (MODE == 5) xv = slm[tk * 16 + rk];
                else if constexpr (MODE == 7) xv = ((const float*)&v4[0])[rk];
                else                          xv = xr0[tk * 16 + rk];
            for (int rk = 0; rk < 16; ++rk) {
                const int d = 8 * ((rk >> 1) & 3) + (rk & 1) + 2 * ((rk >> 3) & 1);
                const int rel = AD27 - ((K2V * d) >> 1);
                uint32_t st16;
                if constexpr (MODE == 4) {
                    st16 = h[rel & (NW - 1)] & 0xffffu;
                } else {
                    const uint32_t lo4 = h[rel >> 5], hi4 = h[(rel >> 5) + 1 > NW - 1 ? NW - 1 : (rel >> 5) + 1];
                    st16 = ((lo4 >> (rel & 31)) | ((hi4 << 1) << (31u - (rel & 31)))) & 0xffffu;
                }
                float wc;
                if constexpr (MODE == 3) {
                    wc = (float)(st16 & 7) - 3.5f;
                } else {
                    const uint32_t xm = st16 * 0x83DCD12Du;
                    const uint32_t t1 = (xm & 0x00ff00ffu) + ((xm >> 8) & 0x00ff00ffu);
                    const uint32_t bs = (t1 & 0xffffu) + (t1 >> 16);
                    wc = (float)(int)bs - 510.0f;
                }
                if (rk & 1) accB = sycl::fma(wc, xv, accB);
                else        acc  = sycl::fma(wc, xv, acc);
            }
#pragma unroll
            for (int i = 0; i < NW; ++i) g[i] = gn[i];
            if constexpr (MODE == 6) {
                // MODE 6 keeps the ring in a register array; fold so the vector loads stay live
                uint32_t f = 0;
#pragma unroll
                for (int i = 0; i < W; ++i) f |= gn[i] >> i;
                if (f == 0xdeadbeefu) acc += 1.f;
            }
        }
        out[(size_t)e * N + blk * ncol_wg + tid] = (acc + accB) * KDQ;
    }
};

template <int MODE>
static double bench(sycl::queue& q, uint32_t* wpack, float* xrow, float* out,
                    size_t tiles_k, size_t TN, int K, int N, int E, size_t slm_bytes) {
    const size_t slm_elems = (MODE == 5) ? slm_bytes / 4 : 4;   // never tax the other modes
    const int ncol_wg = 128;
    const size_t wgs = (size_t)E * (N / ncol_wg);
    Body<MODE> bd{wpack, xrow, out, {}, tiles_k, TN, K, N, E};
    auto run = [&]() {
        return q.submit([&](sycl::handler& cgh) {
            sycl::local_accessor<float, 1> slma({slm_elems}, cgh);
            Body<MODE> kern = bd;
            cgh.parallel_for(sycl::nd_range<1>{{wgs * ncol_wg}, {ncol_wg}},
                [=](sycl::nd_item<1> it) {
                    Body<MODE> k2 = kern;
                    if constexpr (MODE == 5) k2.slm = slma.get_pointer();
                    k2(it);
                });
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

int main(int E_argc, char** E_argv) {
    const int E = E_argc > 1 ? atoi(E_argv[1]) : 10;
    const int K = E_argc > 2 ? atoi(E_argv[2]) : 2560;
    const int N = E_argc > 3 ? atoi(E_argv[3]) : 640;
    const int only = E_argc > 4 ? atoi(E_argv[4]) : -1;
    sycl::queue q{sycl::gpu_selector_v, sycl::property::queue::in_order{}};
    auto dev = q.get_device();
    const size_t slm_max = dev.get_info<sycl::info::device::local_mem_size>();
    const size_t tiles_k = K / 16, TN = N / 16;
    const size_t packed_w = (size_t)E * TN * tiles_k * W;
    const double pack_MB = 1.0 * packed_w * 4 / 1e6;
    printf("device %s\nE %d K %d N %d | packed arena %.2f MB (%d bits/w) | W=%d NW=%d | SLM %zu B\n",
           dev.get_info<sycl::info::device::name>().c_str(), E, K, N, pack_MB, 256 * K2V / 256, W, NW, slm_max);

    uint32_t* wpack = sycl::malloc_device<uint32_t>(packed_w, q);
    float* xrow = sycl::malloc_device<float>((size_t)E * K, q);
    float* out = sycl::malloc_device<float>((size_t)E * N, q);
    q.parallel_for(packed_w, [=](sycl::id<1> i) { wpack[i] = (uint32_t)(i[0] * 2654435761u); }).wait();
    q.parallel_for((size_t)E * K, [=](sycl::id<1> i) { xrow[i[0]] = 0.001f * (float)(i[0] & 127); }).wait();
    q.memset(out, 0, (size_t)E * N * sizeof(float)).wait();

    const size_t slm_bytes = std::min(slm_max, (size_t)tiles_k * 16 * 4);   // MODE 5 slice
    struct Row { const char* nm; double us; };
    double full_us = 1.0;
    auto pr = [&](const char* nm, double us) {
        printf("  %-34s %7.1f us | packed %6.1f GB/s | %5.2fx of full\n", nm, us,
               pack_MB * 1e6 / (us * 1e3), full_us / us);
    };
    full_us = bench<0>(q, wpack, xrow, out, tiles_k, TN, K, N, E, slm_bytes);
    pr("0 full (== production)", full_us);
    const double full = full_us;
    if (only < 0 || only == 1) pr("1 no weight loads", bench<1>(q, wpack, xrow, out, tiles_k, TN, K, N, E, slm_bytes));
    if (only < 0 || only == 2) pr("2 no activation loads", bench<2>(q, wpack, xrow, out, tiles_k, TN, K, N, E, slm_bytes));
    if (only < 0 || only == 3) pr("3 no bytesum", bench<3>(q, wpack, xrow, out, tiles_k, TN, K, N, E, slm_bytes));
    if (only < 0 || only == 4) pr("4 no state extract", bench<4>(q, wpack, xrow, out, tiles_k, TN, K, N, E, slm_bytes));
    if (only < 0 || only == 5) {
        if ((size_t)tiles_k * 16 * 4 <= slm_max) pr("5 activations in SLM (whole slice)", bench<5>(q, wpack, xrow, out, tiles_k, TN, K, N, E, slm_bytes));
        else printf("  %-34s skipped (slice %.1f KB > SLM %zu KB)\n", "5 activations in SLM",
                    tiles_k * 16 * 4 / 1e3, slm_max / 1e3);
    }
    if (only < 0 || only == 6) pr("6 whole-ring vector loads", bench<6>(q, wpack, xrow, out, tiles_k, TN, K, N, E, slm_bytes));
    if (only < 0 || only == 7) pr("7 activations as 4 x float4", bench<7>(q, wpack, xrow, out, tiles_k, TN, K, N, E, slm_bytes));
    printf("  (reference: pure sequential read of this layout measured 781 GB/s in t47)\n");

    sycl::free(wpack, q); sycl::free(xrow, q); sycl::free(out, q);
    return 0;
}