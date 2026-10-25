// lab_dot: microbenchmark for the mul1 bytesum on Xe2, per the Trellis cheat sheet.
//   1) validates the cheat-sheet test vectors through Recipe-B extraction (native layout)
//   2) A/B bytesum implementations: mask-chain (production today) vs esimd dp4a variants
//   3) measures both pure-unpack throughput and a production-shaped gemv inner loop
// build: icpx -fsycl -O3 lab_dot.cpp -o lab_dot
#include <sycl/sycl.hpp>
#include <sycl/ext/intel/esimd.hpp>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <chrono>

using namespace sycl;
using namespace sycl::ext::intel::esimd;
using u32 = uint32_t;
using i32 = int32_t;

constexpr u32 MUL1 = 0x83DCD12Du;

// ---- funnel shifts (never a shift-by-32 count) --------------------------------
static inline u32 funnel_r(u32 hi, u32 lo, u32 s) { return (lo >> s) | ((hi << 1) << (31u - s)); }
static inline u32 funnel_l(u32 hi, u32 lo, u32 s) { return (hi << s) | ((lo >> 1) >> (31u - s)); }

// ---- bytesum variants ----------------------------------------------------------
static inline u32 bs_mask(u32 xm) {
    u32 t1 = (xm & 0x00ff00ffu) + ((xm >> 8) & 0x00ff00ffu);
    return (t1 & 0xffffu) + (t1 >> 16);
}
static inline i32 bs_dot_acc(u32 xm, i32 acc) {  // handwritten pattern; see if IGC fuses
    return acc + (i32)((xm & 0xffu) + ((xm >> 8) & 0xffu) + ((xm >> 16) & 0xffu) + (xm >> 24));
}

// Recipe B column extract, K=4 bits/weight (8 half-bits). native tile = 16 u32? L=256*4=1024 bits=32 words.
// The cheat sheet uses K=4 integer bits => words32 = 8*K = 32.
template <int K>
static inline void recipe_b_column(const u32* w, u32 c, u32 states[16]) {
    const u32 W = 8u * K;
    const u32 h = c >> 3, j = c & 7u;
    u32 sw = K * j + W - 1u + h * ((4u * K) >> 5);
    if (sw >= W) sw -= W;
    const u32 ph = (4u * K * h) & 31u;
    u32 raw[K + 2], a[K + 1];
    for (u32 i = 0; i < K + 2u; ++i) { u32 q = sw + i; raw[i] = w[q < W ? q : q - W]; }
    if (ph == 0) { for (u32 i = 0; i < K + 1u; ++i) a[i] = raw[i]; }
    else for (u32 i = 0; i < K + 1u; ++i) a[i] = funnel_l(raw[i], raw[i + 1], ph);
    #pragma unroll
    for (u32 r = 0; r < 16u; ++r) {
        const u32 off = 8u * ((r & 7u) >> 1) + 2u * (r >> 3) + (r & 1u);
        const u32 pe = 32u + (off + 1u) * K;
        const u32 lo = pe - 1u;
        states[r] = funnel_r(a[(pe - 16u) >> 5], a[lo >> 5], 31u - (lo & 31u)) & 0xFFFFu;
    }
}

// ---- correctness kernel: vector table from the cheat sheet ---------------------
// tile words: word i = i*0x9E3779B9 + 0x12345678; expected (t, state, bs) given below.
struct Vectors
{
    // t computed via t_of(r,c) = 32*(c&7)+8*((r&7)>>1)+4*(c>>3)+2*(r>>3)+(r&1)
    int r, c; u32 state, bs;
};
static constexpr Vectors VECS[] = {
    {0, 0, 0x3DF1, 633}, {1, 0, 0xDF12, 621}, {8, 0, 0xF123, 544}, {0, 8, 0x2345, 385},
    {2, 5, 0x8EC0, 667}, {7, 3, 0x9657, 396}, {15, 15, 0x13DF, 480},
};

class KVec {};
void vec_check(queue& q, int* fails) {
    q.single_task<KVec>([=] {
        u32 w[32];
        for (int i = 0; i < 32; ++i) w[i] = (u32)i * 0x9E3779B9u + 0x12345678u;
        u32 states[16];
        int bad = 0;
        // columns of interest: c=0 (rows 0,1,8), c=8 (row 0), c=5 (row 2), c=3 (row 7), c=15 (row 15)
        const int cs[5] = {0, 8, 5, 3, 15};
        for (int ci = 0; ci < 5; ++ci) {
            recipe_b_column<4>(w, (u32)cs[ci], states);
            for (int rr = 0; rr < 16; ++rr) {
                u32 t = 32u * ((u32)cs[ci] & 7u) + 8u * (((u32)rr & 7u) >> 1) + 4u * ((u32)cs[ci] >> 3)
                      + 2u * ((u32)rr >> 3) + ((u32)rr & 1u);
                // find matching vector
                for (auto& v : VECS) {
                    if (v.c == cs[ci] && v.r == rr) {
                        if (states[rr] != v.state) bad |= 1;
                        u32 xm = states[rr] * 0x83DCD12Du;
                        if (bs_mask(xm) != v.bs) bad |= 2;
                        if (bs_dot_acc(xm, 0) != (i32)v.bs) bad |= 4;
                    }
                }
                (void)t;
            }
        }
        // edge states: 0x0000 -> bs 0 ; 0xFFFF -> bs 414
        if (bs_mask(0x0000u * MUL1) != 0) bad |= 8;
        if (bs_mask(0xFFFFu * MUL1) != 414) bad |= 16;
        *fails = bad;
    }).wait();
}

// ---- throughput kernels ---------------------------------------------------------
// Production replica: per k-step a lane decodes 16 states (stream layout, parity-split
// float accumulators, fma with activation). VAR selects only the bytesum/combine form.
static constexpr int K2V = 8;            // production 4-bit family (biggest stream)
static constexpr int WK = 4 * K2V;       // 32 words per tile
static constexpr int AD27 = (27 * K2V + (K2V & 1)) >> 1;
static constexpr int NW = (AD27 + 16 + 31 + 31) / 32 + 1;

class KThru {};
template <int VAR>
struct Thru
{
    static constexpr int NT = 128;   // tiles per lane per pass
    u32* src; float* xin; float* sink; int reps;
    auto get(sycl::ext::oneapi::experimental::properties_tag) const {
        return sycl::ext::oneapi::experimental::properties{
            sycl::ext::oneapi::experimental::sub_group_size<16>};
    }
    void operator()(nd_item<1> it) const {
        const int tid = (int)it.get_local_id(0);
        const int grp = (int)it.get_group(0);
        const int cin = tid & 15;
        const int A2 = (K2V * (32 * (cin & 7) + 4 * ((cin >> 3) & 1))) >> 1;
        const int G = (32 - (K2V >> 1)) - A2 - AD27;
        const int wb = G >> 5;
        const int pre = G - (wb << 5);
        int widx[NW];
#pragma unroll
        for (int i = 0; i < NW; ++i) widx[i] = ((wb + i) % WK + WK) % WK;

        float acc0 = 0.f, accB0 = 0.f, nx0 = 0.f, nxB = 0.f;
        u32 iacc = 0, iaccB = 0;
        const u32* base = src + (size_t)grp * NT * WK;
        const float* xb = xin + (size_t)grp * NT * 16;
        for (int rep = 0; rep < reps; ++rep) {
            for (int tk = 0; tk < NT; ++tk) {
                const u32* wp = base + (size_t)tk * WK;
                const float* tp = xb + (size_t)tk * 16;
                u32 g[NW];
#pragma unroll
                for (int i = 0; i < NW; ++i) g[i] = wp[widx[i]];
                u32 h[NW];
                if (pre == 0) { for (int i = 0; i < NW; ++i) h[i] = g[i]; }
                else {
                    for (int i = 0; i + 1 < NW; ++i) h[i] = (g[i] >> pre) | (g[i + 1] << (32 - pre));
                    h[NW - 1] = g[NW - 1] >> pre;
                }
#pragma unroll
                for (int rk = 0; rk < 16; ++rk) {
                    const int d = 8 * ((rk >> 1) & 3) + (rk & 1) + 2 * ((rk >> 3) & 1);
                    const int rel = AD27 - ((K2V * d + (K2V & 1)) >> 1);
                    const uint64_t pair = ((uint64_t)h[(rel >> 5) + 1] << 32) | h[rel >> 5];
                    const u32 st16 = (u32)(pair >> (rel & 31)) & 0xffffu;
                    const u32 xm = st16 * MUL1;
                    const float xr = tp[rk];
                    if constexpr (VAR == 0) {        // production today: pair chain, float acc
                        u32 t1 = (xm & 0x00ff00ffu) + ((xm >> 8) & 0x00ff00ffu);
                        u32 bs = (t1 & 0xffffu) + (t1 >> 16);
                        float wc = (float)bs - 510.f;
                        if (rk & 1) accB0 = sycl::fma(wc, xr, accB0); else acc0 = sycl::fma(wc, xr, acc0);
                    } else if constexpr (VAR == 1) { // flat tree bytesum
                        u32 bs = ((xm & 0xffu) + ((xm >> 8) & 0xffu)) + (((xm >> 16) & 0xffu) + (xm >> 24));
                        float wc = (float)bs - 510.f;
                        if (rk & 1) accB0 = sycl::fma(wc, xr, accB0); else acc0 = sycl::fma(wc, xr, acc0);
                    } else if constexpr (VAR == 3) { // flat tree, -510 folded: acc += bs*x; nx -= 510*x
                        u32 bs = ((xm & 0xffu) + ((xm >> 8) & 0xffu)) + (((xm >> 16) & 0xffu) + (xm >> 24));
                        if (rk & 1) { accB0 = sycl::fma((float)bs, xr, accB0); nx0 -= 510.f * xr; }
                        else { acc0 = sycl::fma((float)bs, xr, acc0); nx0 -= 510.f * xr; }
                    } else if constexpr (VAR == 6) { // pair chain + -510 folded (isolates fold vs tree)
                        u32 t1 = (xm & 0x00ff00ffu) + ((xm >> 8) & 0x00ff00ffu);
                        u32 bs = (t1 & 0xffffu) + (t1 >> 16);
                        if (rk & 1) { accB0 = sycl::fma((float)bs, xr, accB0); nx0 -= 510.f * xr; }
                        else { acc0 = sycl::fma((float)bs, xr, acc0); nx0 -= 510.f * xr; }
                    } else if constexpr (VAR == 7) { // flat + fold, parity-split nx accumulators
                        u32 bs = ((xm & 0xffu) + ((xm >> 8) & 0xffu)) + (((xm >> 16) & 0xffu) + (xm >> 24));
                        if (rk & 1) { accB0 = sycl::fma((float)bs, xr, accB0); nxB -= 510.f * xr; }
                        else { acc0 = sycl::fma((float)bs, xr, acc0); nx0 -= 510.f * xr; }
                    } else if constexpr (VAR == 4) { // integer dual accs, float scale at end (NOT same rounding; perf probe)
                        u32 bs = ((xm & 0xffu) + ((xm >> 8) & 0xffu)) + (((xm >> 16) & 0xffu) + (xm >> 24));
                        if (rk & 1) iaccB += bs * (u32)(xr * 4096.f); else iacc += bs * (u32)(xr * 4096.f);
                    } else if constexpr (VAR == 5) { // pair chain, int dual accs (probe)
                        u32 t1 = (xm & 0x00ff00ffu) + ((xm >> 8) & 0x00ff00ffu);
                        u32 bs = (t1 & 0xffffu) + (t1 >> 16);
                        if (rk & 1) iaccB += bs * (u32)(xr * 4096.f); else iacc += bs * (u32)(xr * 4096.f);
                    }
                }
            }
        }
        float r = (VAR == 4 || VAR == 5) ? (float)(iacc + iaccB) : (acc0 + accB0 + nx0 + nxB);
        if (r == 12345.678f) sink[tid] = 1.0f;
    }
};

// equivalence check for VAR2: sum dp4a vs mask on the same data
class KEq {};
struct Eq
{
    u32* src; i32* out;
    void operator()(nd_item<1> it) const {
        const int c = (int)it.get_local_id(0);
        u32* base = src + (size_t)it.get_group(0) * 4 * WK;
        i32 s0 = 0, s2 = 0;
        simd<u32, 1> accu(0u);
        const simd<u32, 1> ones((u32)0x01010101u);
        for (int tk = 0; tk < 4; ++tk) {
            u32 w[WK];
            for (int i = 0; i < WK; ++i) w[i] = base[tk * WK + i];
            u32 st[16];
            recipe_b_column<4>(w, (u32)(c & 15), st);   // K=4bit native; WK here = 32 = 8*4 ✓
            for (int r = 0; r < 16; ++r) {
                u32 xm = st[r] * MUL1;
                s0 += (i32)bs_mask(xm);
                accu = dp4a<u32>(simd<u32, 1>(xm), ones, accu);
            }
        }
        s2 = (i32)accu[0];
        if (c == 0) { out[it.get_group(0) * 2] = s0; out[it.get_group(0) * 2 + 1] = s2; }
    }
};

int main(int argc, char** argv) {
    queue q{gpu_selector_v};
    printf("device: %s\n", q.get_device().get_info<sycl::info::device::name>().c_str());

    int* fails = malloc_shared<int>(1, q);
    *fails = -1;
    vec_check(q, fails);
    printf("vector check: %s (bits: 1,2,4=recipe/state/dotacc 8,16=edge bs)\n",
           *fails == 0 ? "PASS" : (*fails == -1 ? "NOT RUN" : "FAIL"));
    int fb = *fails;

    // throughput sweep
    const int nGroups = 448;           // 2 waves worth on 32 XEs x 8 thr... tune by eye
    const int TS = Thru<0>::NT;
    size_t srcTiles = (size_t)nGroups * TS;
    u32* src = malloc_device<u32>(srcTiles * WK, q);
    float* sink = malloc_device<float>(512, q);
    {   // fill with a spread of random-ish states so nothing optimizes away
        std::vector<u32> h(srcTiles * WK);
        uint64_t s = 88172645463325252ull;
        for (auto& v : h) { s ^= s << 13; s ^= s >> 7; s ^= s << 17; v = (u32)(s >> 16); }
        q.copy(h.data(), src, h.size()).wait();
    }
    float* xin = malloc_device<float>((size_t)nGroups * Thru<0>::NT * 16, q);
    { std::vector<float> hx((size_t)nGroups * Thru<0>::NT * 16);
      for (size_t i = 0; i < hx.size(); ++i) hx[i] = (float)((i * 1103515245u + 12345u) % 2000) * 0.001f - 1.f;
      q.copy(hx.data(), xin, hx.size()).wait(); }
    i32* eq = malloc_shared<i32>(nGroups * 2, q);
    int eqbad = 0;
    q.parallel_for(nd_range<1>{nGroups * 16, 16}, Eq{src, eq}).wait();
    for (int i = 0; i < nGroups; ++i) if (eq[i * 2] != eq[i * 2 + 1]) eqbad++;
    printf("dp4a vs mask equality over %d groups: %s\n", nGroups, eqbad ? "FAIL" : "PASS");

    const int reps = 40;
    // burn-in: get clocks to steady boost before measuring (Xe2 ramps slowly under light load)
    {   auto burn = Thru<0>{src, xin, sink, reps};
        auto t0 = std::chrono::steady_clock::now();
        while (std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count() < 1.5)
            { q.parallel_for(nd_range<1>{nGroups * 16, 16}, burn); q.wait(); }
    }
    auto run = [&](auto k, const char* name) {
        nd_range<1> r{nGroups * 16, 16};
        q.parallel_for(r, k).wait();          // warm
        double best = 1e30;
        for (int it = 0; it < 5; ++it) {
            auto t0 = std::chrono::steady_clock::now();
            q.parallel_for(r, k);
            q.wait();
            auto t1 = std::chrono::steady_clock::now();
            double us = std::chrono::duration<double, std::micro>(t1 - t0).count();
            if (us < best) best = us;
        }
        double ops = (double)nGroups * TS * reps * 16;         // states
        double gb = (double)nGroups * TS * reps * WK * 4.0 * NW / 64.0;  // approx (lines dedup)
        printf("%-12s %8.1f us   %6.1f Mstates/s   ~%.0f GB/s(win)\n",
               name, best, ops / best / 1e3, gb / best / 1e3);
    };
    for (int round = 0; round < 2; ++round) {
        run(Thru<0>{src, xin, sink, reps}, "prod pair-chain");
        run(Thru<1>{src, xin, sink, reps}, "prod flat-tree");
        run(Thru<3>{src, xin, sink, reps}, "flat + fold510");
        run(Thru<6>{src, xin, sink, reps}, "pair + fold510");
        run(Thru<7>{src, xin, sink, reps}, "flat fold split");
        printf("--\n");
    }
    printf("%s\n", (fb == 0 && !eqbad) ? "ALL GOOD" : "PROBLEMS");
    return 0;
}