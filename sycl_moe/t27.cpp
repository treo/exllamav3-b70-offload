// simulate the kernel fast-path extraction against decode_state on a repacked tile
#include <cstdio>
#include <cstring>
#include <cstdint>
#include <vector>
#include "exl3_ref.h"
#include "moe_sycl.hpp"
template <int K2V>
void test() {
    const int W = 4 * K2V, W16 = W * 2;
    exl3ref::Rng rng(0xdeadbeef + K2V);
    for (int i = 0; i < 40; ++i) rng.next();
    std::vector<uint16_t> native(W16), repacked(W16);
    for (auto& v : native) v = (uint16_t)(rng.next() >> 32);
    if (false) printf("native[0..5]=%04x %04x %04x %04x %04x %04x  W16=%d\n", native[0], native[1], native[2], native[3], native[4], native[5], W16);
    moe_sycl::repack_native_to_stream_words((uint32_t*)repacked.data(), (const uint32_t*)native.data(), 1, K2V);
    printf("K2=%d post-repack: R[0]=%08x R[29]=%08x native32[0]=%08x\n", K2V, ((uint32_t*)repacked.data())[0], ((uint32_t*)repacked.data())[29], ((uint32_t*)native.data())[0]);
    const uint32_t* wp = (const uint32_t*)repacked.data();
    constexpr int KE = K2V & 1;
    constexpr int AD27 = (27 * K2V + KE) >> 1;
    constexpr int NW = (AD27 + 16 + 31) / 32 + 1;
    int bad = 0;
    if (false) {
        printf("native u16[4..9]: %04x %04x %04x %04x %04x %04x\n", native[4], native[5], native[6], native[7], native[8], native[9]);
        printf("repack probe: native32[3]=%08x R[29]=%08x R[0]=%08x R[1]=%08x W=%d W16=%d\n",
               ((uint32_t*)native.data())[3], ((uint32_t*)repacked.data())[29],
               ((uint32_t*)repacked.data())[0], ((uint32_t*)repacked.data())[1], W, W16);
    }
    for (int cin = 0; cin < 16; ++cin) {
        const int A2 = (K2V * (32 * (cin & 7) + 4 * ((cin >> 3) & 1))) >> 1;
        const int G = (32 - (K2V >> 1)) - A2 - AD27;
        const int wb = G >> 5, pre = G - (wb << 5);
        int widx[NW]; for (int i = 0; i < NW; ++i) widx[i] = ((wb + i) % W + W) % W;
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
            const int t = (bb << 3) | jj;
            uint16_t want = exl3ref::decode_state(native.data(), K2V / 2, K2V % 2, t);
            if (st16 != want) {
                if (bad < 4) printf("K2=%d cin %d rk %d t %d rel %d pre %d wb %d want %04x got %04x h[%d]=%08x h[%d]=%08x g[%d..]: %08x %08x %08x\n", K2V, cin, rk, t, rel, pre, wb, want, st16, rel>>5, h[rel>>5], (rel>>5)+1, h[(rel>>5)+1], 0, g[0], g[1], g[2]);
                ++bad;
            }
        }
    }
    printf("K2=%d: %d bad\n", K2V, bad);
}
int main() { test<8>(); return 0; }
