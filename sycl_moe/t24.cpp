// validate law: state(t) = D2 window at pos(t) = C - (K2*t)/2 (floor), D2 = same-word-high + prev-word-low
#include <cstdio>
#include <cstring>
#include <cstdint>
#include <vector>
#include "exl3_ref.h"

static uint32_t rdW(const std::vector<uint16_t>& r16, int w, int W) { uint32_t v; std::memcpy(&v, &r16[(w%W)*2], 4); return v; }
static uint16_t d2(const std::vector<uint16_t>& r16, int W, int pos, int ringbits) {
    pos %= ringbits; if (pos < 0) pos += ringbits;
    int q = pos / 32, s = pos % 32;
    uint32_t cur = rdW(r16, q, W), prv = rdW(r16, q - 1, W);
    if (s <= 16) return (uint16_t)((cur >> s) | (prv << (32 - s)));
    return (uint16_t)((prv >> s) | (cur << (32 - s)));
}
int main() {
    for (int K2 : {2, 3, 4, 5, 6, 7, 8, 16, 17}) {
        int bits = K2 / 2, hb = K2 % 2;
        if (bits < 1 || bits > 8) continue;
        int W16 = 8 * K2, W = W16 / 2, ringbits = W16 * 16;
        exl3ref::Rng rng(99);
        std::vector<uint16_t> ring(W16);
        for (auto& v : ring) v = (uint16_t)(rng.next() >> 40);
        int C = -1, bad = 0;
        for (int c0 = 0; c0 < ringbits; ++c0) {
            int t = 0;
            if (d2(ring, W, c0 - (K2 * t) / 2, ringbits) != exl3ref::decode_state(ring.data(), bits, hb, t)) continue;
            if (d2(ring, W, c0 - (K2 * 1) / 2, ringbits) != exl3ref::decode_state(ring.data(), bits, hb, 1)) continue;
            if (d2(ring, W, c0 - (K2 * 3) / 2, ringbits) != exl3ref::decode_state(ring.data(), bits, hb, 3)) continue;
            C = c0; break;
        }
        if (C >= 0)
            for (int t = 0; t < 256; ++t)
                if (d2(ring, W, C - (K2 * t) / 2, ringbits) != exl3ref::decode_state(ring.data(), bits, hb, t)) ++bad;
        printf("K2=%2d: C=%4d  bad %d/256\n", K2, C, bad);
    }
    return 0;
}
