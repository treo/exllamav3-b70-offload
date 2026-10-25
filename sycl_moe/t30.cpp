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
#include "exl3_ref.h"
#include "moe_sycl.cpp"

using namespace moe_sycl;
using u32 = uint32_t;

static std::vector<int> bs_host;   // [K*N]

int main(int argc, char** argv)
{
    const std::string mode = argc > 1 ? argv[1] : "hot";
    const int K = argc > 2 ? atoi(argv[2]) : 32;      // gemv K (a8 side)
    const int N = argc > 3 ? atoi(argv[3]) : 32;      // gemv N
    const int SLOTS = argc > 4 ? atoi(argv[4]) : 1;   // workgroups along dim1
    const int VAL = argc > 5 ? atoi(argv[5]) : 127;   // sat mode value
    constexpr int K2 = 4;

    sycl::queue q{sycl::gpu_selector_v};
    printf("device: %s | mode %s K %d N %d slots %d val %d\n",
           q.get_device().get_info<sycl::info::device::name>().c_str(),
           mode.c_str(), K, N, SLOTS, VAL);

    std::mt19937 rng(42);
    const int W = 4 * K2, TK = K / 16, TN = N / 16;
    const size_t nw = (size_t)TK * TN * W;
    std::vector<u32> native(nw);
    for (auto& v : native) v = rng();
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
    uintptr_t* dtab = sycl::malloc_device<uintptr_t>(12 * SLOTS, q);
    std::vector<uintptr_t> tab(12, 0);
    tab[(F_TRI * 3 + CAT_DOWN)] = (uintptr_t)dtri;       // E = 1, expert 0, down cat
    q.memcpy(dtab, tab.data(), tab.size() * 8).wait();
    ChunkDev* dch = sycl::malloc_device<ChunkDev>(SLOTS, q);
    {
        std::vector<ChunkDev> ch(SLOTS);
        for (auto& c : ch) { c = ChunkDev{}; c.expert = 0; c.m = 4; }
        q.memcpy(dch, ch.data(), ch.size() * sizeof(ChunkDev)).wait();
    }
    const int kf = K / 8;
    int32_t* da8 = sycl::malloc_device<int32_t>((size_t)SLOTS * kf * 64, q);
    int32_t* dacc = sycl::malloc_device<int32_t>((size_t)SLOTS * 8 * N, q);

    // ---- build A operands per mode
    std::vector<int32_t> ha8((size_t)SLOTS * kf * 64, 0);
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
    } else if (mode == "rnd") {
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

    Gemv8Base g8{ dtab, dch, da8, dacc, 1, SLOTS, 1, N, K, N / 16, 1 };
    q.submit([&](sycl::handler& cgh) {
        sycl::local_accessor<unsigned char, 1> slm({1024}, cgh);
        cgh.parallel_for(sycl::nd_range<2>({(size_t)(N / 16) * 16, (size_t)SLOTS}, {16, 1}),
                         Gemv8<4>{g8, slm});
    }).wait();

    std::vector<int32_t> acc((size_t)SLOTS * 8 * N);
    q.copy(dacc, acc.data(), acc.size()); q.wait();

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
                const int got = acc[((size_t)slot * 8 + r) * N + c];
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