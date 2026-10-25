// law: state(t) = 16 ascending bits at P(t) = P0 - (K2*t)>>1 in stream S[k]=w[(-k)%W]
#include <cstdio>
#include <cstring>
#include <cstdint>
#include <vector>
#include "exl3_ref.h"
static uint32_t rdw(const std::vector<uint16_t>& r16, int w, int W) { uint32_t v; std::memcpy(&v, &r16[((w%W+W)%W)*2], 4); return v; }
static uint16_t asc16(const std::vector<uint16_t>& w16, int W, int P, int RB) {
    P %= RB; if (P < 0) P += RB;
    int k = P / 32, s = P % 32;   // stream word k = ring word (-k)%W
    auto sw = [&](int kk) { return rdw(w16, ((-kk) % W + W) % W, W); };
    uint32_t cur = sw(k), nxt = sw(k + 1);
    return (uint16_t)(((uint64_t)cur >> s | (uint64_t)nxt << (32 - s)) & 0xffffu);
}
int main() {
    for (int K2 : {2, 3, 4, 5, 6, 7, 8, 15, 16, 17}) {
        int bits = K2 / 2, hb = K2 % 2;
        if (bits < 1 || bits > 8) continue;
        int W16 = 8 * K2, W = W16 / 2, RB = W16 * 16;
        exl3ref::Rng rng(12345 + K2);
        std::vector<uint16_t> ring(W16);
        for (auto& v : ring) v = (uint16_t)(rng.next() >> 40);
        int P0 = -1, bad = 0, which = 0;
        for (int cand = 0; cand < 4 && P0 < 0; ++cand)
            for (int c0 = 0; c0 < RB; ++c0) {
                bool ok = true;
                for (int t = 0; t < 256 && ok; ++t) {
                    int adv;
                    switch (cand) {
                        case 0: adv = (K2 * t) >> 1; break;
                        case 1: adv = ((K2 * t) + 1) >> 1; break;
                        case 2: adv = (K2 * (t + 1)) >> 1; break;
                        default: adv = ((K2 + 1) * t) >> 1; break;
                    }
                    ok = asc16(ring, W, c0 - adv, RB) == exl3ref::decode_state(ring.data(), bits, hb, t);
                }
                if (ok) { P0 = c0; which = cand; break; }
            }
        printf("K2=%2d: P0=%4d cand %d\n", K2, P0, which);
    }
    return 0;
}
