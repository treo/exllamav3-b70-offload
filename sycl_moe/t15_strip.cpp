// Prototype of the "column-strip" GPU weight layout + lean GEMV inner loop.
// New layout: within each 16x16 tile, the state slot order is permuted so that weight
// (rk, cin) lives at slot j = rk + 16*cin, i.e. slot j's 16-bit window starts at bit
// (j*k2)>>1 (+ tile base). A lane owning column cin then reads ONE 64-bit word pair per
// k-step and extracts all 16 weights with pure register shifts.
#include <sycl/sycl.hpp>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <vector>
#include "exl3_ref.h"

static void repack_tile(const uint16_t* src, uint16_t* dst, int k2)
{
    // src: native ring; dst: same size, slot j(rk,cin)=rk+16cin <- native slot inv[rk*16+cin]
    // bit-serial copy: read 16-bit window at native end position, write at strip position.
    const int ring_u16 = 8 * k2;
    std::memset(dst, 0, ring_u16 * 2);
    auto rd = [&](int bit, int nbits) -> uint32_t {          // read nbits<=16 at bit pos
        const int wi = bit / 16, sh = bit % 16;
        uint32_t v = src[wi % ring_u16] >> sh;
        if (sh) v |= (uint32_t)src[(wi + 1) % ring_u16] << (16 - sh);
        return v & ((1u << nbits) - 1);
    };
    auto wr = [&](int bit, uint32_t val, int nbits) {        // write nbits at bit pos
        int wi = bit / 16, sh = bit % 16;
        uint32_t m = ((1u << nbits) - 1) << sh;
        dst[wi % ring_u16] = (uint16_t)((dst[wi % ring_u16] & ~m) | ((val << sh) & m));
        if (sh + nbits > 16) {
            const int nb2 = sh + nbits - 16;
            const uint32_t m2 = (1u << nb2) - 1;
            dst[(wi + 1) % ring_u16] = (uint16_t)((dst[(wi + 1) % ring_u16] & ~m2) | ((val >> (nbits - nb2)) & m2));
        }
    };
    // native slot t's window END bit (from scalar spec), start = end - 16
    for (int rk = 0; rk < 16; ++rk)
        for (int cin = 0; cin < 16; ++cin) {
            const int idx = rk * 16 + cin;
            // inverse tc_perm
            const int b = ((cin & 7) << 2) | ((rk >> 1) & 3);
            const int jj = (rk & 1) | ((rk & 8) ? 2 : 0) | ((cin & 8) ? 4 : 0);
            const int t = (b << 3) | jj;
            (void)idx;
            const int e1 = (((t + 1) * k2) >> 1) + 128 * k2;   // end bit (biased)
            const int s1 = e1 - 16;                            // start bit, mod ring
            const int j = rk + 16 * cin;
            const int s2 = (j * k2) >> 1;                      // new start bit
            const int nbits = (k2 + 1) / 2 + 16 - (k2 / 2) - (k2 & 1 ? 0 : 0);
            // move exactly 16 bits; only the LOWEST k2/2-rounded-new bits of a window are
            // semantically independent, but moving the full 16-bit window at the same
            // alignment delta preserves every window we address
            (void)nbits;
            wr(s2 % (ring_u16 * 16), rd(s1 % (ring_u16 * 16), 16), 16);
        }
}

int main()
{
    sycl::queue q{sycl::gpu_selector_v, {sycl::property::queue::enable_profiling()}};
    for (int k2 : {4, 5, 8})
    {
        // correctness vs scalar decode
        const int tiles_k = 10, tiles_n = 20;
        const int H = tiles_k * 16, I = tiles_n * 16;
        exl3ref::Rng rng(42 + k2);
        const int ring = 8 * k2;
        std::vector<uint16_t> nat((size_t)tiles_k * tiles_n * ring), strip(nat.size());
        for (auto& v : nat) v = (uint16_t)(rng.next() >> 40);
        for (size_t t = 0; t < (size_t)tiles_k * tiles_n; ++t)
            repack_tile(&nat[t * ring], &strip[t * ring], k2);

        // device: gemv over strip layout
        uint16_t* dtri = sycl::malloc_device<uint16_t>(strip.size(), q);
        float *dtin = sycl::malloc_device<float>(H), *dout = sycl::malloc_device<float>(I);
        std::vector<float> htin(H);
        for (auto& v : htin) v = rng.uniform(-1.f, 1.f);
        q.memcpy(dtri, strip.data(), strip.size() * 2).wait();
        q.memcpy(dtin, htin.data(), H * 4).wait();
        const int bits = k2 / 2, hb = k2 % 2;
        q.parallel_for(sycl::nd_range<1>({(size_t)(I / 128) * 128}, {128}), [=](sycl::nd_item<1> it) {
            const int tid = (int)it.get_local_id(0);
            const int cG = (int)it.get_group(0) * 128 + tid;
            const int tile_n = cG >> 4, cin = cG & 15;
            const int wtot = 4 * k2;                       // u32 words per tile
            const int cbits = ((16 * cin * k2) >> 1);      // column strip start bit
            const int w0 = (cbits >> 5) % wtot, fb = cbits & 31;
            const uint32_t* wp = (const uint32_t*)dtri + (size_t)tile_n * wtot;
            float acc = 0;
            for (int tk = 0; tk < tiles_k; ++tk) {
                const uint32_t* pw = wp + (size_t)tk * tiles_n * wtot + w0;
                const uint32_t a = pw[0 % wtot], b = pw[1 % wtot];   // wrap not needed for k2<=8 sizes vs tile? use mod for safety
                const uint64_t lo = (((uint64_t)b << 32) | a) >> fb;
                const uint32_t c = pw[2 % wtot];
#pragma unroll
                for (int rk = 0; rk < 16; ++rk) {
                    const int s = (rk * k2) >> 1;
                    uint32_t st16;
                    if (s + 16 <= 64) st16 = (uint32_t)(lo >> s) & 0xffffu;
                    else st16 = (uint32_t)((lo >> s) | ((uint64_t)c << (32 - fb + (64 - s) - 32 + (s + 16 - 64) - (16 - (s + 16 - 64))))) & 0xffffu;
                    const uint32_t xm = st16 * 0x83DCD12Du;
                    const float wcomb = (float)((xm & 0xff) + ((xm >> 8) & 0xff) +
                                                ((xm >> 16) & 0xff) + (xm >> 24)) - 510.0f;
                    acc = sycl::fma(wcomb, dtin[tk * 16 + rk], acc);
                }
            }
            dout[cG] = acc * 0.00676727294921875f;
        }).wait();
        std::vector<float> dev(I);
        q.memcpy(dev.data(), dout, I * 4).wait();

        // host reference on native layout
        double worst = 0;
        for (int c = 0; c < I; ++c) {
            const int tn = c >> 4, cic = c & 15;
            double a = 0;
            for (int tk = 0; tk < tiles_k; ++tk) {
                float tile[256];
                exl3ref::decode_tile(&nat[((size_t)tk * tiles_n + tn) * ring], bits, hb, tile);
                for (int rk = 0; rk < 16; ++rk)
                    a += (double)htin[tk * 16 + rk] * tile[rk * 16 + cic];
            }
            worst = std::max(worst, std::fabs(a - dev[c]) / (std::fabs(a) + 1e-3));
        }
        printf("k2=%d: worst_rel %.3e\n", k2, worst);
        sycl::free(dtri, q); sycl::free(dtin, q); sycl::free(dout, q);
    }
    return 0;
}