// map every (t,j) -> physical (word,bit) by differential probing; K2=4
#include <cstdio>
#include <cstring>
#include <cstdint>
#include <vector>
#include "exl3_ref.h"
int main() {
    const int bits = 2, hb = 0, K2 = 4, W16 = 8 * K2, W = W16 / 2, RB = W16 * 16;
    std::vector<uint16_t> zero(W16, 0), pr = zero;
    std::vector<uint16_t> ref(256);
    for (int t = 0; t < 256; ++t) ref[t] = exl3ref::decode_state(zero.data(), bits, hb, t);
    for (int w = 0; w < W; ++w) for (int b = 0; b < 32; ++b) {
        pr = zero;
        ((uint32_t*)pr.data())[w] ^= (1u << b);
        for (int t = 0; t < 24; ++t) {
            uint16_t s1 = exl3ref::decode_state(pr.data(), bits, hb, t);
            uint32_t d = s1 ^ ref[t];
            if (d) {
                int j = __builtin_ctz(d);
                if (__builtin_popcount(d) == 1)
                    printf("t=%2d j=%2d <- word %2d bit %2d (lin %d)\n", t, j, w, b, w * 32 + b);
            }
        }
    }
    return 0;
}
