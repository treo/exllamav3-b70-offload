// t30: isolate Gemv8 (DPAS staging + A load + accumulation) with controlled A operands.
// Weights come from the NATIVE layout via the production repack; host bs(k,c) comes from
// exl3ref::decode_tile (the spec decoder) - NOT from the kernel's window formula, so a
// decode flaw shows up. Modes:
//   hot   : row r has x8=1 at real k=KPROBE[r] (rest 0)   -> C[r][c] == bs(k0,c)
//   one   : every A word x8=1                              -> C[r][c] == sum_k bs(k,c)
//   rnd   : x8 = per-(r,frag,word) deterministic +-0..8    -> exact i32 check
//   sat   : every A byte x8=VAL (1/64/127) at full K       -> detects i16-pair saturation
// Scales: small (K=32) and production-like (K=2560, N=I=640 + multi-slot launch).
#include <cstdio>
#include <cstdlib>
#include <vector>
#include <random>
#include <chrono>
#include "exl3_ref.h"
#include "moe_sycl.cpp"

using namespace moe_sycl;
using u32 = uint32_t;

static std::vector<int> bs_host;   // [K*N]

// Gemv8X: timing-ablation twin of Gemv8 (LAB ONLY - lives in t30, never ships).
// FLAGS bit0: run the mad; bit1: load jb from SLM; bit2: load ja (A block2d); bit3: STS
// the prod words; bit4: load the 5 window words (else reuse). Everything else identical.
template <int K2V, int FLAGS>
struct Gemv8X
{
    Gemv8Base b;
    sycl::local_accessor<unsigned char, 1> slab;

    auto get(sycl::ext::oneapi::experimental::properties_tag) const
    {
        return sycl::ext::oneapi::experimental::properties{
            sycl::ext::oneapi::experimental::sub_group_size<16> };
    }
    static constexpr int W = 4 * K2V;
    static constexpr int KE = K2V & 1;
    static constexpr int AD27 = (27 * K2V + KE) >> 1;
    static constexpr int NW = (AD27 + 16 + 31 + 31) / 32 + 1;

    void operator()(sycl::nd_item<2> it) const
    {
        const int gid = (int)it.get_group(0);
        const int slot = (int)it.get_group(1);
        const int tid = (int)it.get_local_id(0);
        const int nf = gid % b.nfl;
        const int sl = gid / b.nfl;
        const int e = b.chunks[slot].expert;
        const int K = b.I, N = b.H;
        const int tiles_k = K / 16;
        const uint32_t* w32 = (const uint32_t*)(uintptr_t)b.tab[(F_TRI * 3 + CAT_DOWN) * b.E + e];
        const int cin = tid & 15;
        const int A2 = (K2V * (32 * (cin & 7) + 4 * ((cin >> 3) & 1))) >> 1;
        const int G = (32 - (K2V >> 1)) - A2 - AD27;
        const int wb = G >> 5;
        const int pre = G - (wb << 5);
        int widx[NW];
#pragma unroll
        for (int i = 0; i < NW; ++i) widx[i] = ((wb + i) % W + W) % W;
        unsigned char* const slb = slab.get_pointer().get();
        uint32_t* const sl32 = (uint32_t*)slb;
        const int32_t* const pa0 = b.a8 + (size_t)slot * (K / 8) * 64;
        const size_t row_step = (size_t)b.nfl * W;
        const int tk_lo = (tiles_k * sl) / b.nsl;
        const int tk_hi = (tiles_k * (sl + 1)) / b.nsl;
        const uint32_t* wp = w32 + (size_t)nf * W + (size_t)tk_lo * row_step;
        sycl::sub_group sg = it.get_sub_group();
        mx8::joint_matrix<sycl::sub_group, signed char, mx8::use::a, 8, 32,
                          mx8::layout::row_major> ja;
        mx8::joint_matrix<sycl::sub_group, unsigned char, mx8::use::b, 32, 16,
                          mx8::layout::ext_intel_packed> jb;
        mx8::joint_matrix<sycl::sub_group, int, mx8::use::accumulator, 8, 16> jc;
        mx8::joint_matrix_fill(sg, jc, 0);
        uint32_t g[NW], gn[NW];
#pragma unroll
        for (int i = 0; i < NW; ++i) g[i] = wp[widx[i]];
        for (int tk = tk_lo; tk < tk_hi; ++tk, wp += row_step) {
            if ((tk + 1 < tk_hi) && (FLAGS & 16)) {
                const uint32_t* wpn = wp + row_step;
#pragma unroll
                for (int i = 0; i < NW; ++i) gn[i] = wpn[widx[i]];
            }
            uint32_t h[NW];
            if (pre == 0) {
#pragma unroll
                for (int i = 0; i < NW; ++i) h[i] = g[i];
            } else {
#pragma unroll
                for (int i = 0; i + 1 < NW; ++i)
                    h[i] = (g[i] >> pre) | (g[i + 1] << (32 - pre));
                h[NW - 1] = g[NW - 1] >> pre;
            }
            uint32_t* const band = sl32 + (tk & 1) * 256;
            uint32_t accx = 0;
            if (!(FLAGS & 128)) {
#pragma unroll
                for (int rk = 0; rk < 16; ++rk) {
                    const int d = 8 * ((rk >> 1) & 3) + (rk & 1) + 2 * ((rk >> 3) & 1);
                    const int rel = AD27 - ((K2V * d + KE) >> 1);
                    const uint32_t lo4 = h[rel >> 5], hi4 = h[(rel >> 5) + 1];
                    const uint32_t st16 = ((lo4 >> (rel & 31)) | ((hi4 << 1) << (31u - (rel & 31)))) & 0xffffu;
                    const uint32_t prod = st16 * 0x83DCD12Du;
                    if (FLAGS & 8) band[(rk >> 3) * 128 + (rk & 7) * 16 + cin] = prod;
                    else accx += prod;
                }
            } else {
                accx = h[0] ^ h[NW - 1];
                if (FLAGS & 8) band[cin] = accx;
            }
            if (!(FLAGS & 8) && accx == 0xdeadbeefu) sl32[0] = accx;   // keep decode alive
            if (FLAGS & 32) sg.barrier();
            if (!(FLAGS & 64)) {
#pragma unroll
                for (int fk = 0; fk < 2; ++fk) {
                    auto pag = sycl::address_space_cast<sycl::access::address_space::global_space,
                                                        sycl::access::decorated::yes>(
                        (const signed char*)(pa0 + (size_t)(2 * tk + fk) * 64));
                    if (FLAGS & 4) mx8::joint_matrix_load(sg, ja, pag, 32);
                    if (FLAGS & 2)
                        mx8::joint_matrix_load(sg, jb,
                            sycl::address_space_cast<sycl::access::address_space::local_space,
                                                     sycl::access::decorated::yes>(
                                slb + (tk & 1) * 1024 + fk * 512),
                            16 * 4);
                    if (FLAGS & 1) mx8::joint_matrix_mad(sg, jc, ja, jb, jc);
                }
            }
            if (FLAGS & 16) {
#pragma unroll
                for (int i = 0; i < NW; ++i) g[i] = gn[i];
            }
        }
        auto pcg = sycl::address_space_cast<sycl::access::address_space::global_space,
                                            sycl::access::decorated::yes>(
            b.acc + ((size_t)slot * b.nsl + sl) * 8 * N + nf * 16);
        mx8::joint_matrix_store(sg, jc, pcg, N, mx8::layout::row_major);
    }
};

int main(int argc, char** argv)
{
    const std::string mode = argc > 1 ? argv[1] : "hot";
    const int K = argc > 2 ? atoi(argv[2]) : 32;      // gemv K (a8 side)
    const int N = argc > 3 ? atoi(argv[3]) : 32;      // gemv N
    const int SLOTS = argc > 4 ? atoi(argv[4]) : 1;   // workgroups along dim1
    const int VAL = argc > 5 ? atoi(argv[5]) : 127;   // sat mode value
    const int NSL8 = argc > 6 ? atoi(argv[6]) : 1;    // Gemv8 split-K degree
    constexpr int K2 = 4;

    sycl::queue q{sycl::gpu_selector_v};
    printf("device: %s | mode %s K %d N %d slots %d val %d\n",
           q.get_device().get_info<sycl::info::device::name>().c_str(),
           mode.c_str(), K, N, SLOTS, VAL);

    std::mt19937 rng(42);
    const bool konst = getenv("CONSTW") != nullptr;
    const int W = 4 * K2, TK = K / 16, TN = N / 16;
    const size_t nw = (size_t)TK * TN * W;
    std::vector<u32> native(nw);
    for (auto& v : native) v = konst ? 0x5bb187bdu : rng();
    std::vector<u32> stream(nw);
    repack_native_to_stream_words(stream.data(), native.data(), (size_t)TK * TN, K2);
    {   // host truth bs(k,c) from the NATIVE spec decode
        bs_host.assign((size_t)K * N, 0);
        std::vector<float> tile(256);
        const uint16_t* nat16 = (const uint16_t*)native.data();
        const int pu = 2 * W;
        int lo = 1 << 30, hi = -1;
        for (int tn = 0; tn < TN; ++tn)
            for (int tk = 0; tk < TK; ++tk) {
                exl3ref::decode_tile(&nat16[((size_t)tk * TN + tn) * pu], K2 / 2, K2 & 1, tile.data());
                for (int rk = 0; rk < 16; ++rk)
                    for (int c = 0; c < 16; ++c) {
                        const int v = (int)std::llround(tile[rk * 16 + c] / KDQ) + 510;
                        bs_host[(size_t)(tk * 16 + rk) * N + tn * 16 + c] = v;
                        if (v < lo) lo = v; if (v > hi) hi = v;
                    }
            }
        printf("bs range [%d..%d] over %d weights\n", lo, hi, K * N);
    }

    u32* dtri = sycl::malloc_device<u32>(nw, q);
    q.memcpy(dtri, stream.data(), nw * 4).wait();
    // 'tm' (timing-multi): one DISTINCT weight matrix per slot, like production decode
    // (each chunk reads its own expert's stream). Verification is skipped in this mode.
    const int E_X = (mode == "tm") ? SLOTS : 1;
    std::vector<u32*> dtri_e(E_X, nullptr);
    if (mode == "tm") {
        std::vector<u32> native2(nw), stream2(nw);
        for (int ex = 0; ex < E_X; ++ex) {
            for (auto& v : native2) v = rng();
            repack_native_to_stream_words(stream2.data(), native2.data(), (size_t)TK * TN, K2);
            dtri_e[ex] = sycl::malloc_device<u32>(nw, q);
            q.memcpy(dtri_e[ex], stream2.data(), nw * 4).wait();
        }
    }
    uintptr_t* dtab = sycl::malloc_device<uintptr_t>(12 * SLOTS, q);
    std::vector<uintptr_t> tab(12 * SLOTS, 0);
    for (int ex = 0; ex < E_X; ++ex)
        tab[(F_TRI * 3 + CAT_DOWN) * E_X + ex] = (uintptr_t)(E_X == 1 ? dtri : dtri_e[ex]);
    q.memcpy(dtab, tab.data(), tab.size() * 8).wait();
    ChunkDev* dch = sycl::malloc_device<ChunkDev>(SLOTS, q);
    {
        std::vector<ChunkDev> ch(SLOTS);
        for (auto& c : ch) { c = ChunkDev{}; c.expert = E_X > 1 ? -1 : 0; c.m = 4; }
        if (E_X > 1) for (int s2 = 0; s2 < SLOTS; ++s2) ch[s2].expert = s2;   // one expert per slot
        q.memcpy(dch, ch.data(), ch.size() * sizeof(ChunkDev)).wait();
    }
    const int kf = K / 8;
    int32_t* da8 = sycl::malloc_device<int32_t>((size_t)SLOTS * kf * 64, q);
    int32_t* dacc = sycl::malloc_device<int32_t>((size_t)SLOTS * NSL8 * 8 * N, q);

    // ---- build A operands per mode
    std::vector<int32_t> ha8((size_t)SLOTS * kf * 64, konst ? 0x02020202 : 0);
    const int KPROBE[8] = {0, 1, 7, 8, 9, 15, 16, 31};
    auto word_at = [&](int slot, int k, int r) -> int32_t& {
        return ha8[((size_t)slot * kf + (k >> 3)) * 64 + r * 8 + (k & 7)];
    };
    auto splat = [](int x) { return (int32_t)((x & 0xff) * 0x01010101); };  // uchar splat: NOT x*0x01010101
    if (mode == "hot") {
        for (int r = 0; r < 8; ++r) {
            const int k0 = KPROBE[r] % K;
            word_at(0, k0, r) = 0x01010101;
        }
    } else if (mode == "one") {
        for (size_t i = 0; i < ha8.size(); ++i) ha8[i] = 0x01010101;
    } else if (mode == "tm" || mode == "rnd") {
        std::mt19937 ar(7);
        for (int slot = 0; slot < SLOTS; ++slot)
            for (int k = 0; k < K; ++k)
                for (int r = 0; r < 8; ++r) {
                    const int x = (int)(ar() % 17) - 8;
                    word_at(slot, k, r) = splat(x);
                }
    } else if (mode == "rnrow") {
        // rneg restricted to row VAL only (amplitude -(VAL+1) at KPROBE[VAL])
        const int r = VAL;
        word_at(0, KPROBE[r] % K, r) = splat(-(r + 1));
    } else if (mode == "rnrows") {
        // rneg restricted to rows 0..VAL inclusive
        for (int r = 0; r <= VAL && r < 8; ++r)
            word_at(0, KPROBE[r] % K, r) = splat(-(r + 1));
    } else if (mode == "allneg") {
        for (size_t i = 0; i < ha8.size(); ++i) ha8[i] = (int32_t)0xFFFFFFFF;   // x8=-1 everywhere
    } else if (mode == "oneneg") {
        word_at(0, 3, 0) = (int32_t)0xFFFFFFFF;                                  // single -1
    } else if (mode == "twoneg") {
        word_at(0, 3, 0) = (int32_t)0xFEFEFEFE;                                   // single -2
        word_at(0, 10, 2) = (int32_t)0xFBFBFBFB;                                  // single -5 (frag 1)
    } else if (mode == "rn0") {
        word_at(0, 0, 0) = (int32_t)0xFFFFFFFF;                        // -1 at k=0 row 0
    } else if (mode == "rn1") {
        word_at(0, 1, 1) = (int32_t)0xFEFEFEFE;                        // -2 at k=1 row 1
    } else if (mode == "rr0") {
        word_at(0, 0, 0) = 0x01010101;                                 // +1 at k=0 row 0
    } else if (mode == "rpairs") {
        // positives like q25 but at the rneg positions, mixed amplitudes 1..8
        for (int r = 0; r < 8; ++r) word_at(0, KPROBE[r] % K, r) = splat(r + 1);
    } else if (mode == "q25") {
        // hot words ONLY at quad (k&7) positions 2..5 (the range 'hot' never probes)
        for (int r = 0; r < 8; ++r) {
            const int k0 = (r % 4) + 2;               // k<8: quad pos 2..5, fragment 0
            word_at(0, k0, r) = splat(r + 1);
        }
        for (int slot = 0; slot < SLOTS; ++slot) {}
    } else if (mode == "rneg") {
        // hot with NEGATIVE amplitudes at quad 0/1/7 only (known-good positions, sign test)
        for (int r = 0; r < 8; ++r) {
            const int k0 = KPROBE[r] % K;
            word_at(0, k0, r) = splat(-(r + 1));
        }
    } else if (mode == "rpos") {
        // positive-only diverse values (sign vs diversity discriminator)
        std::mt19937 ar(7);
        for (int slot = 0; slot < SLOTS; ++slot)
            for (int k = 0; k < K; ++k)
                for (int r = 0; r < 8; ++r) {
                    const int x = (int)(ar() % 8) + 1;
                    word_at(slot, k, r) = splat(x);
                }
    } else if (mode == "sat") {
        const int32_t b = (u32)(unsigned char)(signed char)VAL;
        const int32_t w = b * 0x01010101;
        for (size_t i = 0; i < ha8.size(); ++i) ha8[i] = w;
    }
    q.memcpy(da8, ha8.data(), ha8.size() * 4).wait();

    Gemv8Base g8{ dtab, dch, da8, dacc, E_X, SLOTS, 1, N, K, N / 16, 1, NSL8 };
    auto launch = [&]() {
        if (mode == "tq") {
            return q.submit([&](sycl::handler& cgh) {
                sycl::local_accessor<unsigned char, 1> slm({2048}, cgh);
                cgh.parallel_for(sycl::nd_range<2>({(size_t)(N / 16) * 16 * NSL8, (size_t)SLOTS}, {16, 1}),
                                 Gemv8<4>{g8, slm});
            });
        }
        if (mode == "tm") {
            const int XF = getenv("XFLAGS") ? atoi(getenv("XFLAGS")) : 31;
#define LX(lf) return (sycl::event)q.submit([&](sycl::handler& cgh) { sycl::local_accessor<unsigned char,1> slm({2048}, cgh); cgh.parallel_for(sycl::nd_range<2>({(size_t)(N/16)*16*NSL8,(size_t)SLOTS},{16,1}), Gemv8X<4,lf>{g8,slm}); });
            switch (XF) {
                case 31: LX(31)
                case 23: LX(23)
                case 15: LX(15)
                case 143: LX(143)
                case 159: LX(159)
                case 14: LX(14)
                case 6: LX(6)
                case 30: LX(30)
                case 29: LX(29)
                case 27: LX(27)
                case 16: LX(16)
                case 26: LX(26)
                case 24: LX(24)
                case 63: LX(63)
                case 51: LX(51)
                case 49: LX(49)
                case 35: LX(35)
                case 33: LX(33)
                case 1:  LX(1)
                default: LX(31)
            }
#undef LX
        }
        return q.submit([&](sycl::handler& cgh) {
            sycl::local_accessor<unsigned char, 1> slm({2048}, cgh);
            cgh.parallel_for(sycl::nd_range<2>({(size_t)(N / 16) * 16 * NSL8, (size_t)SLOTS}, {16, 1}),
                             Gemv8<4>{g8, slm});
        });
    };
    launch().wait();
    printf("first launch OK\n"); fflush(stdout);
    if (getenv("ONESHOT")) { if (mode == "tm" || mode == "tp" || mode == "tq") return 0; }

    // ---- burn-in + timing (clock ramp lesson: >=1.5s continuous before timing)
    {
        auto t0 = std::chrono::steady_clock::now();
        while (std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count() < 1.5)
            launch();
        q.wait();
        double best = 1e30;
        for (int it = 0; it < 8; ++it) {
            auto s = std::chrono::steady_clock::now();
            launch().wait();
            auto e1 = std::chrono::steady_clock::now();
            double us = std::chrono::duration<double, std::micro>(e1 - s).count();
            if (us < best) best = us;
        }
        const double frags = (double)SLOTS * NSL8 * (N / 16) * ((K / 16) / NSL8);
        printf("timing: best %.1f us (%.2f ns/frag)\n", best, best * 1e3 / frags);
    }

    std::vector<int32_t> acc((size_t)SLOTS * NSL8 * 8 * N);
    q.copy(dacc, acc.data(), acc.size()); q.wait();
    if (mode == "tm") { printf("t30 tm: timing-only, %d experts\n", E_X); return 0; }

    // ---- verify exactly (integers)
    long bad = 0, checked = 0;
    int shown = 0;
    for (int slot = 0; slot < SLOTS; ++slot)
        for (int r = 0; r < 8; ++r)
            for (int c = 0; c < N; ++c) {
                long want = 0;
                for (int k = 0; k < K; ++k) {
                    const int x8 = (int)(signed char)((unsigned)word_at(slot, k, r) & 0xffu);
                    want += (long)x8 * bs_host[(size_t)k * N + c];
                }
                int got = 0;
                for (int qq = 0; qq < NSL8; ++qq)
                    got += acc[((size_t)slot * NSL8 + qq) * 8 * N + (size_t)r * N + c];
                ++checked;
                if (got != (int)want) {
                    ++bad;
                    if (shown < 12) {
                        printf("  MISMATCH s%d r%d c%d: got %d (0x%08x) want %ld (0x%08lx) delta %ld",
                               slot, r, c, got, (unsigned)got, want, (unsigned long)want,
                               (long)got - want);
                        // does the delta match +/-bs(k,c) for some k? (x8-unit search)
                        for (int kk = 0; kk < K; ++kk)
                            if (bs_host[(size_t)kk * N + c] == (got - (int)want) ||
                                -bs_host[(size_t)kk * N + c] == (got - (int)want)) {
                                printf("  = %cbs(k%d,c)", (got - (int)want > 0) ? '+' : '-', kk);
                                break;
                            }
                        printf("\n");
                        ++shown;
                    }
                }
            }
    printf("t30 %s: %ld/%ld exact%s\n", mode.c_str(), checked - bad, checked,
           bad ? "  <-- FAIL" : "");
    return bad ? 1 : 0;
}