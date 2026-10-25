// clean fast-path extraction verification (all rates)
#include <cstdio>
#include <cstring>
#include <cstdint>
#include <vector>
#include "exl3_ref.h"
#include "moe_sycl.hpp"
template <int K2V>
int test() {
    constexpr int W = 4 * K2V, W16 = W * 2;
    constexpr int KE = K2V & 1;
    constexpr int AD27 = (27 * K2V + KE) >> 1;
    constexpr int NW = (AD27 + 16 + 31 + 31) / 32 + 1;
    exl3ref::Rng rng(0xC0FFEEu * K2V + 13);
    for (int i = 0; i < 50; ++i) rng.next();
    std::vector<uint16_t> native(W16), repacked(W16);
    for (auto& v : native) v = (uint16_t)(rng.next() >> 32);
    moe_sycl::repack_native_to_stream_words((uint32_t*)repacked.data(), (const uint32_t*)native.data(), 1, K2V);
    const uint32_t* wp = (const uint32_t*)repacked.data();
    if (K2V == 8) {
        printf("K2=8 dump: native:"); for (int i = 0; i < 6; ++i) printf(" %08x", ((const uint32_t*)native.data())[i]);
        printf(" | repacked:"); for (int i = 0; i < 6; ++i) printf(" %08x", wp[i]);
        printf(" | sizeof u16vec=%zu elems=%zu\n", sizeof(uint16_t)*repacked.size(), repacked.size());
    }
    int bad = 0;
    for (int cin = 0; cin < 16; ++cin) {
        const int A2 = (K2V * (32 * (cin & 7) + 4 * ((cin >> 3) & 1))) >> 1;
        const int G = (32 - (K2V >> 1)) - A2 - AD27;
        const int wb = G >> 5;
        const int pre = G - (wb << 5);
        int widx[NW];
        for (int i = 0; i < NW; ++i) widx[i] = ((wb + i) % W + W) % W;
        uint32_t g[NW], h[NW];
        for (int i = 0; i < NW; ++i) g[i] = wp[widx[i]];
        if (pre == 0) { for (int i = 0; i < NW; ++i) h[i] = g[i]; }
        else { for (int i = 0; i + 1 < NW; ++i) h[i] = (g[i] >> pre) | (g[i + 1] << (32 - pre)); h[NW - 1] = g[NW - 1] >> pre; }
        for (int rk = 0; rk < 16; ++rk) {
            const int d = 8 * ((rk >> 1) & 3) + (rk & 1) + 2 * ((rk >> 3) & 1);
            const int rel = AD27 - ((K2V * d + KE) >> 1);
            const uint64_t pair = ((uint64_t)h[(rel >> 5) + 1] << 32) | h[rel >> 5];
            const uint32_t st16 = (uint32_t)(pair >> (rel & 31)) & 0xffffu;
            const int bb = ((cin & 7) << 2) | ((rk >> 1) & 3);
            const int jj = (rk & 1) | ((rk & 8) ? 2 : 0) | ((cin & 8) ? 4 : 0);
            const uint16_t want = exl3ref::decode_state(native.data(), K2V / 2, K2V % 2, (bb << 3) | jj);
            if (st16 != want && bad < 3)
                printf("  K2=%d cin %d rk %d rel %d pre %d wb %d want %04x got %04x | R0=%08x R1=%08x h0=%08x h1=%08x h2=%08x h3=%08x h4=%08x h5=%08x\n",
                       K2V, cin, rk, rel, pre, wb, want, st16, wp[0], wp[1], h[0], h[1], h[2], h[3], h[4], NW > 5 ? h[5] : 0);
            if (st16 != want) ++bad;
        }
    }
    printf("K2=%2d: %d bad\n", K2V, bad);
    return bad;
}
int main() {
    int bad = 0;
    bad += test<2>(); bad += test<3>(); bad += test<4>(); bad += test<5>(); bad += test<6>();
    bad += test<7>(); bad += test<8>(); bad += test<9>(); bad += test<10>(); bad += test<11>();
    bad += test<12>(); bad += test<13>(); bad += test<14>(); bad += test<15>(); bad += test<16>();
    bad += test<17>();
    printf(bad ? "FAILURES\n" : "ALL OK\n");
    return bad != 0;
}
