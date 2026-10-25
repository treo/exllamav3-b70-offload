// t31: Gemv8P crash bisect (device loss at N=640). Standalone replica of the two-tile
// DPAS loop on synthetic buffers. Variants (-DVARIANT=n):
//   0 full two-tile    1 no bottom sg.barrier    2 no second-tile mad block
//   3 stage only (no jm/mads)                    4 gb aliases ga (one word stream)
//   5 two INDEPENDENT single-tile passes (pair loop, 2 barriers/pair, no dual stage)
#include <sycl/sycl.hpp>
#include <cstdio>
#include <vector>
#include <chrono>
#include <random>
#include "moe_sycl.hpp"
#ifndef VARIANT
#define VARIANT 0
#endif

namespace mx8 = sycl::ext::oneapi::experimental::matrix;
using u32 = uint32_t;

struct P
{
    const u32* w32;           // [TK][TN][W] stream words (row_step = TN*W)
    const int32_t* a8;        // [SLOTS][KF][64]
    int32_t* acc;             // [SLOTS][NSL][8][N]
    int TN, TK, W, KF, N, NSL;
    sycl::local_accessor<unsigned char, 1> slab;
#if VARIANT == 7
    uint32_t* gscratch;       // per-WG 2048B ping-pong bands in GLOBAL (bank-conflict probe)
    int nfl_tot, nsl_tot;
#endif
#if VARIANT == 6 || VARIANT == 8 || VARIANT == 9 || VARIANT == 12 || VARIANT == 15
    const uintptr_t* tab;
    const int* experts;       // chunks stand-in: expert per slot
#endif
#if VARIANT == 6 || VARIANT == 8 || VARIANT == 12 || VARIANT == 15
    auto get(sycl::ext::oneapi::experimental::properties_tag) const
    {
        return sycl::ext::oneapi::experimental::properties{
            sycl::ext::oneapi::experimental::sub_group_size<16> };
    }
#endif

    static constexpr int K2V = 4;
    static constexpr int AD27 = (27 * K2V) >> 1;
#if VARIANT == 15
    int W;                      // RUNTIME W (as in production Gemv8 this is constexpr 16)
#define CONSTW_ 0
#else
    static constexpr int W = 16;
#define CONSTW_ 1
#endif
    static constexpr int NW = (AD27 + 16 + 31 + 31) / 32 + 1;

    void operator()(sycl::nd_item<2> it) const
    {
        const int gid = (int)it.get_group(0);
        const int slot = (int)it.get_group(1);
        const int tid = (int)it.get_local_id(0);
        const int nf = gid % TN;
        const int sl = gid / TN;
        const int cin = tid & 15;
        const int A2 = (K2V * (32 * (cin & 7) + 4 * ((cin >> 3) & 1))) >> 1;
        const int G = (32 - (K2V >> 1)) - A2 - AD27;
        const int wb = G >> 5;
        const int pre = G - (wb << 5);
        int widx[NW];
#pragma unroll
        for (int i = 0; i < NW; ++i) widx[i] = ((wb + i) % W + W) % W;
        unsigned char* const slb = slab.get_pointer().get();
#if VARIANT == 7
        // scratch indexed by flat WG id: slot-major (gid, slot)
        uint32_t* const gsl32 = gscratch + ((size_t)slot * nsl_tot + sl) * (nfl_tot * 512);
        u32* const sl32 = gsl32;   // STS become global stores
#define SLB_OFF(x) ((unsigned char*)(gsl32) + (x))
#else
        u32* const sl32 = (u32*)slb;
#define SLB_OFF(x) (slb + (x))
#endif
        const size_t row_step = (size_t)TN * W;
#if VARIANT == 6 || VARIANT == 9 || VARIANT == 12 || VARIANT == 15
        const u32* w32x = (const u32*)(uintptr_t)tab[2 + experts[slot]];   // F_TRI*3+CAT_DOWN=2, E=1
        const u32* wp0 = w32x;
#else
        const u32* wp0 = w32;
#endif
        const int tk_lo = (TK * sl) / NSL;
        const int tk_hi = (TK * (sl + 1)) / NSL;
        const u32* wp = wp0 + (size_t)nf * W + (size_t)tk_lo * row_step;
        const int32_t* const pa0 = a8 + (size_t)slot * KF * 64;

        sycl::sub_group sg = it.get_sub_group();
        mx8::joint_matrix<sycl::sub_group, signed char, mx8::use::a, 8, 32,
                          mx8::layout::row_major> ja;
        mx8::joint_matrix<sycl::sub_group, unsigned char, mx8::use::b, 32, 16,
                          mx8::layout::ext_intel_packed> jb;
        mx8::joint_matrix<sycl::sub_group, int, mx8::use::accumulator, 8, 16> jc;
        mx8::joint_matrix_fill(sg, jc, 0);

        u32 ga[NW], gb[NW], gan[NW], gbn[NW];
#pragma unroll
        for (int i = 0; i < NW; ++i) ga[i] = wp[widx[i]];
        const bool has2i = (tk_lo + 1) < tk_hi;
        const u32* wp2 = wp + (has2i ? row_step : 0);
#if VARIANT == 4
#pragma unroll
        for (int i = 0; i < NW; ++i) gb[i] = ga[i];
#else
#pragma unroll
        for (int i = 0; i < NW; ++i) gb[i] = has2i ? wp2[widx[i]] : ga[i];
#endif
        for (int tc = tk_lo; tc < tk_hi; tc += 2, wp += 2 * row_step) {
            const bool has2 = (tc + 1) < tk_hi;
            if (tc + 2 < tk_hi) {
                const u32* wa = wp + 2 * row_step;
#pragma unroll
                for (int i = 0; i < NW; ++i) gan[i] = wa[widx[i]];
                if (tc + 3 < tk_hi) {
                    const u32* wbx = wp + 3 * row_step;
#pragma unroll
                    for (int i = 0; i < NW; ++i) gbn[i] = wbx[widx[i]];
                } else {
#pragma unroll
                    for (int i = 0; i < NW; ++i) gbn[i] = gan[i];
                }
            }
            u32 ha[NW], hb[NW];
            if (pre == 0) {
#pragma unroll
                for (int i = 0; i < NW; ++i) { ha[i] = ga[i]; hb[i] = gb[i]; }
            } else {
#pragma unroll
                for (int i = 0; i + 1 < NW; ++i) {
                    ha[i] = (ga[i] >> pre) | (ga[i + 1] << (32 - pre));
                    hb[i] = (gb[i] >> pre) | (gb[i + 1] << (32 - pre));
                }
                ha[NW - 1] = ga[NW - 1] >> pre;
                hb[NW - 1] = gb[NW - 1] >> pre;
            }
            u32* const banda = sl32;
            u32* const bandb = sl32 + 256;
#if VARIANT == 12
            static constexpr int PKA[8] = {0, 1, 4, 5, 8, 9, 12, 13};
#pragma unroll
            for (int p = 0; p < 8; ++p) {
                const int rk = PKA[p], rkB = rk + 2;
                const int dA = 8 * ((rk >> 1) & 3) + (rk & 1) + 2 * ((rk >> 3) & 1);
                const int relA = AD27 - ((K2V * dA) >> 1);
                const int relB = relA - 16;
                const int a = relB >> 5, s = relB & 31;
                const u32 wav = s ? ((ha[a] >> s) | (ha[a + 1] << (32 - s))) : ha[a];
                banda[(rk >> 3) * 128 + (rk & 7) * 16 + cin] = (wav >> 16) * 0x83DCD12Du;
                banda[(rkB >> 3) * 128 + (rkB & 7) * 16 + cin] = (wav & 0xffffu) * 0x83DCD12Du;
                if (has2) {
                    const u32 wbv = s ? ((hb[a] >> s) | (hb[a + 1] << (32 - s))) : hb[a];
                    bandb[(rk >> 3) * 128 + (rk & 7) * 16 + cin] = (wbv >> 16) * 0x83DCD12Du;
                    bandb[(rkB >> 3) * 128 + (rkB & 7) * 16 + cin] = (wbv & 0xffffu) * 0x83DCD12Du;
                }
            }
#else
#pragma unroll
            for (int rk = 0; rk < 16; ++rk) {
                const int d = 8 * ((rk >> 1) & 3) + (rk & 1) + 2 * ((rk >> 3) & 1);
                const int rel = AD27 - ((K2V * d) >> 1);
                const u32 lo4 = ha[rel >> 5], hi4 = ha[(rel >> 5) + 1];
                const u32 s16a = ((lo4 >> (rel & 31)) | ((hi4 << 1) << (31u - (rel & 31)))) & 0xffffu;
                banda[(rk >> 3) * 128 + (rk & 7) * 16 + cin] = s16a * 0x83DCD12Du;
#if VARIANT == 0 || VARIANT == 1 || VARIANT == 4 || VARIANT == 15
                if (has2) {
                    const u32 lo4b = hb[rel >> 5], hi4b = hb[(rel >> 5) + 1];
                    const u32 s16b = ((lo4b >> (rel & 31)) | ((hi4b << 1) << (31u - (rel & 31)))) & 0xffffu;
                    bandb[(rk >> 3) * 128 + (rk & 7) * 16 + cin] = s16b * 0x83DCD12Du;
                }
#endif
            }
#endif
            sg.barrier();
#pragma unroll
            for (int fk = 0; fk < 2; ++fk) {
                auto pag = sycl::address_space_cast<sycl::access::address_space::global_space,
                                                    sycl::access::decorated::yes>(
                    (const signed char*)(pa0 + (size_t)(2 * tc + fk) * 64));
                mx8::joint_matrix_load(sg, ja, pag, 32);
                mx8::joint_matrix_load(sg, jb,
                    sycl::address_space_cast<
#if VARIANT == 7
                        sycl::access::address_space::global_space,
#else
                        sycl::access::address_space::local_space,
#endif
                        sycl::access::decorated::yes>(SLB_OFF(fk * 512)),
                    16 * 4);
#if VARIANT != 3
                mx8::joint_matrix_mad(sg, jc, ja, jb, jc);
#endif
            }
#if VARIANT == 0 || VARIANT == 1 || VARIANT == 4
            if (has2) {
                const int tc1 = tc + 1;
#pragma unroll
                for (int fk = 0; fk < 2; ++fk) {
                    auto pag = sycl::address_space_cast<sycl::access::address_space::global_space,
                                                        sycl::access::decorated::yes>(
                        (const signed char*)(pa0 + (size_t)(2 * tc1 + fk) * 64));
                    mx8::joint_matrix_load(sg, ja, pag, 32);
                    mx8::joint_matrix_load(sg, jb,
                        sycl::address_space_cast<
#if VARIANT == 7
                            sycl::access::address_space::global_space,
#else
                            sycl::access::address_space::local_space,
#endif
                            sycl::access::decorated::yes>(SLB_OFF(1024 + fk * 512)),
                        16 * 4);
                    mx8::joint_matrix_mad(sg, jc, ja, jb, jc);
                }
            }
#endif
#if VARIANT != 1
            sg.barrier();
#endif
#pragma unroll
            for (int i = 0; i < NW; ++i) { ga[i] = gan[i]; gb[i] = gbn[i]; }
        }
        auto pcg = sycl::address_space_cast<sycl::access::address_space::global_space,
                                            sycl::access::decorated::yes>(
            acc + ((size_t)slot * NSL + sl) * 8 * N + nf * 16);
        mx8::joint_matrix_store(sg, jc, pcg, N, mx8::layout::row_major);
    }
};

int main(int argc, char** argv)
{
    const int NSL = argc > 1 ? atoi(argv[1]) : 4;
    const int SLOTS = 20, K = 2560, N = 640;   // the crashing production shape
    constexpr int K2 = 4, W = 16;
    const int TK = K / 16, TN = N / 16, KF = K / 8;
    sycl::queue q{sycl::gpu_selector_v};
    printf("t31 VARIANT=%d nsl=%d on %dx%d (TN=%d)\n", VARIANT, NSL, K, N, TN);

    std::mt19937 rr31(42);
    std::vector<u32> hw((size_t)TK * TN * W);
    {
        // build the SAME way as t30/production: random NATIVE tiles -> stream repack
        std::vector<u32> nat((size_t)TK * TN * W);
        for (auto& v : nat) v = rr31();
        hw.resize((size_t)TK * TN * W);
        moe_sycl::repack_native_to_stream_words(hw.data(), nat.data(), (size_t)TK * TN, K2);
    }
    std::vector<int32_t> ha8((size_t)SLOTS * KF * 64, 0x02020202);
    if (getenv("RANDW")) {
        std::mt19937 r2(1);
        for (auto& v : hw) v = r2();
        for (auto& v : ha8) { const int x = (int)(r2() % 17) - 8; v = (x & 0xff) * 0x01010101; }
    }
    u32* dw;
    int32_t* da8;
    int32_t* dacc;
    if (getenv("ALLOC30")) {
        // t30/production topology: separate mallocs, trellis allocated FIRST
        dw = sycl::malloc_device<u32>((size_t)TK * TN * W, q);
        da8 = sycl::malloc_device<int32_t>(ha8.size(), q);
        dacc = sycl::malloc_device<int32_t>((size_t)SLOTS * NSL * 8 * N, q);
    } else {
        dacc = sycl::malloc_device<int32_t>((size_t)SLOTS * NSL * 8 * N, q);
        da8 = sycl::malloc_device<int32_t>(ha8.size(), q);
        dw = sycl::malloc_device<u32>((size_t)TK * TN * W, q);
    }
    q.memcpy(dw, hw.data(), hw.size() * 4).wait();
    q.memcpy(da8, ha8.data(), ha8.size() * 4).wait();

    sycl::event first;
    uint32_t* gscr = nullptr;
    if (VARIANT == 7)
        gscr = sycl::malloc_device<uint32_t>((size_t)SLOTS * NSL * TN * 128, q);
#if VARIANT == 6 || VARIANT == 9 || VARIANT == 12 || VARIANT == 15
    uintptr_t* dtab = nullptr;
    int* dexps = nullptr;
    if (VARIANT == 6 || VARIANT == 9 || VARIANT == 12 || VARIANT == 15) {
        std::vector<uintptr_t> ht(16, 0);
        for (int i = 0; i < 16; ++i) ht[i] = (uintptr_t)dw;   // any expert -> same trellis
        dtab = sycl::malloc_device<uintptr_t>(16, q);
        dexps = sycl::malloc_device<int>(SLOTS, q);
        std::vector<int> hexps(SLOTS, 0);
        q.memcpy(dtab, ht.data(), 16 * 8).wait();
        q.memcpy(dexps, hexps.data(), SLOTS * 4).wait();
    }
#endif
    auto mkp = [&](sycl::handler& cgh, sycl::local_accessor<unsigned char, 1>& slm) {
#if VARIANT == 6 || VARIANT == 9 || VARIANT == 12 || VARIANT == 15
#if VARIANT == 15
        return P{dw, da8, dacc, TN, TK, 16, KF, N, NSL, slm, dtab, dexps};
#else
        return P{dw, da8, dacc, TN, TK, W, KF, N, NSL, slm, dtab, dexps};
#endif
#elif VARIANT == 7
        return P{dw, da8, dacc, TN, TK, W, KF, N, NSL, slm, gscr, TN, NSL};
#else
        return P{dw, da8, dacc, TN, TK, W, KF, N, NSL, slm};
#endif
    };
    {
        first = q.submit([&](sycl::handler& cgh) {
            sycl::local_accessor<unsigned char, 1> slm({2048}, cgh);
            cgh.parallel_for(sycl::nd_range<2>({(size_t)TN * 16 * NSL, (size_t)SLOTS}, {16, 1}),
                             mkp(cgh, slm));
        });
        first.wait();
        printf("first launch OK\n");
        if (getenv("ONESHOT")) return 0;
        auto t0 = std::chrono::steady_clock::now();
        while (std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count() < 1.5)
            first = q.submit([&](sycl::handler& cgh) {
                sycl::local_accessor<unsigned char, 1> slm({2048}, cgh);
                cgh.parallel_for(sycl::nd_range<2>({(size_t)TN * 16 * NSL, (size_t)SLOTS}, {16, 1}),
                                 mkp(cgh, slm));
            });
        q.wait();
        double best = 1e30;
        for (int it = 0; it < 8; ++it) {
            auto s = std::chrono::steady_clock::now();
            q.submit([&](sycl::handler& cgh) {
                sycl::local_accessor<unsigned char, 1> slm({2048}, cgh);
                cgh.parallel_for(sycl::nd_range<2>({(size_t)TN * 16 * NSL, (size_t)SLOTS}, {16, 1}),
                                 mkp(cgh, slm));
            }).wait();
            auto e1 = std::chrono::steady_clock::now();
            double us = std::chrono::duration<double, std::micro>(e1 - s).count();
            if (us < best) best = us;
        }
        printf("VARIANT %d: best %.1f us\n", VARIANT, best);
    }
    return 0;
}