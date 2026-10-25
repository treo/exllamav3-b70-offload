// reverse-engineer decode_state's bit mapping: for each t and each result bit j, find which
// physical bit (word, position) of the packed ring it comes from, by differential probing.
#include <cstdio>
#include <cstring>
#include <cstdint>
#include <vector>
#include "exl3_ref.h"
int main() {
    const int bits = 2, hb = 0, k2 = 4, W = 4 * k2;   // 16 words
    std::vector<uint16_t> ring(W * 2, 0), probe(W * 2);
    // for word index w0, bit b0: which (t,j) does it appear in? set bit and diff states
    for (int w = 0; w < W; ++w)
        for (int b = 0; b < 32; ++b) {
            probe = ring;
            ((uint32_t*)probe.data())[w] ^= (1u << b);
            for (int t = 0; t < 32; ++t) {
                uint16_t s0 = exl3ref::decode_state(ring.data(), bits, hb, t);
                uint16_t s1 = exl3ref::decode_state(probe.data(), bits, hb, t);
                uint32_t d = s0 ^ s1;
                if (d) {
                    int j = __builtin_ctz(d);
                    if (w == 0 && (b == 0 || b == 1))
                        printf("ring word %d bit %d -> state(%d).bit%d\n", w, b, t, j);
                    if (w == 1)
                        printf("ring word %d bit %d -> state(%d).bit%d\n", w, b, t, j);
                }
            }
        }
    return 0;
}
