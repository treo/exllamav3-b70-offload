// host simulation of the fast-path extraction math vs scalar spec
#include <cstdio>
#include <cstring>
#include <cstdint>
#include <vector>
#include "exl3_ref.h"
int main() {
    for (int K2V : {4, 8}) {
        const int W = 4 * K2V, WM = W - 1;
        exl3ref::Rng rng(1);
        std::vector<uint16_t> tile(W * 2);
        for (auto& v : tile) v = (uint16_t)(rng.next() >> 40);
        const uint32_t* wp = (const uint32_t*)tile.data();
        int bad = 0;
        for (int cin = 0; cin < 16; ++cin) {
            for (int rk = 0; rk < 16; ++rk) {
                // spec window
                const int bb = ((cin & 7) << 2) | ((rk >> 1) & 3);
                const int jj = (rk & 1) | ((rk & 8) ? 2 : 0) | ((cin & 8) ? 4 : 0);
                const int t = (bb << 3) | jj;
                const uint16_t want = exl3ref::decode_state(tile.data(), K2V / 2, K2V % 2, t);
                // fast path
                int bmin = ((((32 * (cin & 7)) + 1) * K2V) >> 1) + 128 * K2V - 16;
                bmin += (cin & 8) ? (2 * K2V) : 0;
                const int wb = bmin >> 5, pre = bmin & 31;
                auto g = [&](int i) { return wp[(wb + i) & WM]; };
                uint32_t h[6];
                for (int i = 0; i < 5; ++i)
                    h[i] = pre ? ((g(i) >> pre) | (g(i + 1) << (32 - pre))) : g(i);
                const int d = 8 * ((rk >> 1) & 3) + (rk & 1) + 2 * ((rk >> 3) & 1);
                const int rel = (d * K2V) >> 1;
                const int q = rel >> 5, s = rel & 31;
                const uint64_t pair = ((uint64_t)h[q + 1] << 32) | h[q];
                const uint32_t got = (uint32_t)(pair >> s) & 0xffffu;
                if (got != want) {
                    if (bad < 4) printf("K2=%d cin %d rk %d want %04x got %04x (wb %d pre %d rel %d)\n", K2V, cin, rk, want, got, wb, pre, rel);
                    ++bad;
                }
            }
        }
        printf("K2V=%d: %d bad\n", K2V, bad);
    }
    return 0;
}
