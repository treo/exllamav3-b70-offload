// fit S(t) = (C - ((t+1)*K2>>1)) style laws for each K2; validate on random rings
#include <cstdio>
#include <cstring>
#include <cstdint>
#include <vector>
#include <cstdlib>
#include "exl3_ref.h"
static uint16_t rd_lin(const std::vector<uint16_t>& ring, int W16, int S, int ringbits) {
    // 16 bits ascending from linear bit S in plain LSB-first u32 stream of W16/2 words
    int W = W16 / 2;
    S %= ringbits; if (S < 0) S += ringbits;
    uint32_t a = ((const uint32_t*)ring.data())[S / 32];
    uint32_t b = ((const uint32_t*)ring.data())[(S / 32 + 1) % W];
    int sh = S % 32;
    uint64_t m = ((uint64_t)b << 32) | a;
    if (sh <= 16) return (uint16_t)(m >> sh);
    uint64_t m2 = ((uint64_t)(((const uint32_t*)ring.data())[(S / 32 + 2) % W]) << 32) | b;
    return (uint16_t)(((m >> sh) | (m2 << (64 - sh))) & 0xffffu);
}
int main() {
    for (int cfg = 0; cfg < 3; ++cfg) {
        int bits = cfg == 0 ? 2 : cfg == 1 ? 4 : 2, hb = cfg == 2 ? 1 : 0;
        int K2 = 2 * bits + hb, W16 = 8 * K2, ringbits = W16 * 16;
        exl3ref::Rng rng(7);
        std::vector<uint16_t> ring(W16);
        for (auto& v : ring) v = (uint16_t)(rng.next() >> 40);
        // measure S(0): search
        int S0 = -1;
        for (int S = 0; S < ringbits; ++S) {
            int b1 = ((1) * K2 >> 1) + 128 * K2;   // t=0: ((0+1)*K2>>1)+128K2
            uint16_t want = exl3ref::decode_state(ring.data(), bits, hb, 0);
            if (rd_lin(ring, W16, S, ringbits) == want) { S0 = S; break; }
        }
        // law candidates: S(t) = S0 - ((t*K2)>>1) or S0 - ((t*K2+t... try slope
        int bad = 0, firstbad = -1;
        for (int t = 0; t < 256; ++t) {
            uint16_t want = exl3ref::decode_state(ring.data(), bits, hb, t);
            int S = S0 - (int)(((long)t * K2 + 1) >> 1);
            if (rd_lin(ring, W16, S, ringbits) != want) { ++bad; if (firstbad < 0) firstbad = t; }
        }
        printf("K2=%d: S0=%d slope-fit bad %d/256 (first %d) [S(t)=S0-((t*K2+1)>>1)]\n", K2, S0, bad, firstbad);
    }
    return 0;
}
