// isolate K2: one chunk, gate matrix only; compare kernel vs host sim
#include <sycl/sycl.hpp>
#include <cmath>
#include <cstdio>
#include <vector>
#include <cstring>
#include "exl3_ref.h"

struct InvPerm { unsigned char inv[256]; };
InvPerm make_invperm() {
    InvPerm p{};
    for (int t = 0; t < 256; ++t) {
        const int b = t >> 3, j = t & 7;
        const int row = ((b & 3) * 2) + (j & 1) + ((j & 2) ? 8 : 0);
        const int col = (b >> 2) + ((j & 4) ? 8 : 0);
        p.inv[row * 16 + col] = (unsigned char)t;
    }
    return p;
}

int main() {
    sycl::queue q{sycl::gpu_selector_v};
    const int H = 128, I = 128;               // minimal 128x128: 8x8 tiles
    const int bits = 2, hb = 0, k2 = 2 * bits + hb, tile_u32 = 4 * k2;
    const int tiles_n = I / 16, tiles_k = H / 16, nbk = I / 128;
    exl3ref::Rng rng(99);
    std::vector<uint16_t> tri((size_t)tiles_k * tiles_n * 8 * k2);
    for (auto& v : tri) v = (uint16_t)(rng.next() >> 40);
    std::vector<float> tin(H, 0);
    for (auto& v : tin) v = rng.uniform(-1.f, 1.f);
    const int units = nbk;
    InvPerm invp = make_invperm();
    uint16_t* dtri = sycl::malloc_device<uint16_t>(tri.size(), q);
    float* dtin = sycl::malloc_device<float>(H, q);
    float* dout = sycl::malloc_device<float>(I, q);
    q.memcpy(dtri, tri.data(), tri.size()*2).wait();
    q.memcpy(dtin, tin.data(), H*4).wait();
    const uint32_t* w32 = (const uint32_t*)dtri;
    const float KDQ = 0.00676727294921875f;
    q.submit([&](sycl::handler& cgh) {
        cgh.parallel_for(sycl::nd_range<1>({units * 128}, {128}), [=](sycl::nd_item<1> it) {
            const int unit = (int)it.get_group(0);
            const int tid = (int)it.get_local_id(0);
            const int blk = unit % nbk;
            const int cG = blk * 128 + tid;
            const int tile_n = cG >> 4, cin = cG & 15;
            unsigned int addr[16];
            for (int rk = 0; rk < 16; ++rk) {
                const int t = invp.inv[rk * 16 + cin];
                const int b1 = (((t + 1) * k2) >> 1) + 128 * k2;
                const int b0 = b1 - 16;
                const int w0 = (b0 >> 5) % tile_u32;
                const int w1 = ((b1 - 1) >> 5) % tile_u32;
                const int sh = (((b1 - 1) >> 5) + 1) * 32 - b1;
                addr[rk] = (unsigned)(w0 | (w1 << 8) | (sh << 16));
            }
            float acc = 0;
            for (int tk = 0; tk < tiles_k; ++tk) {
                const uint32_t* wp = w32 + ((size_t)tk * tiles_n + tile_n) * tile_u32;
                const float* tp = dtin + (size_t)tk * 16;
                for (int rk = 0; rk < 16; ++rk) {
                    const unsigned a = addr[rk];
                    const uint64_t merged = ((uint64_t)wp[a & 0xff] << 32) | wp[(a >> 8) & 0xff];
                    const uint32_t st = (uint32_t)(merged >> (a >> 16));
                    const uint32_t xm = st * 0x83DCD12Du;
                    const float wcomb = (float)((xm & 0xff) + ((xm >> 8) & 0xff) +
                                                ((xm >> 16) & 0xff) + (xm >> 24)) - 510.0f;
                    acc = sycl::fma(wcomb, tp[rk], acc);
                }
            }
            dout[cG] = acc * KDQ;
        });
    });
    q.wait();
    std::vector<float> dev(I), dref(I, 0);
    q.memcpy(dev.data(), dout, I*4).wait();
    // host sim
    const uint32_t* hw32 = (const uint32_t*)tri.data();
    for (int cG = 0; cG < I; ++cG) {
        const int tile_nn = cG >> 4, cin = cG & 15;
        float acc = 0;
        for (int tk = 0; tk < tiles_k; ++tk) {
            const uint32_t* wp = hw32 + ((size_t)tk * tiles_n + tile_nn) * tile_u32;
            for (int rk = 0; rk < 16; ++rk) {
                const int t = invp.inv[rk * 16 + cin];
                const int b1 = (((t + 1) * k2) >> 1) + 128 * k2;
                const int b0 = b1 - 16;
                const int w0 = (b0 >> 5) % tile_u32;
                const int w1 = ((b1 - 1) >> 5) % tile_u32;
                const int sh = (((b1 - 1) >> 5) + 1) * 32 - b1;
                const uint64_t merged = ((uint64_t)wp[w0] << 32) | wp[w1];
                const uint32_t st = (uint32_t)(merged >> sh);
                const uint32_t xm = st * 0x83DCD12Du;
                const float wcomb = (float)((xm & 0xff) + ((xm >> 8) & 0xff) + ((xm >> 16) & 0xff) + (xm >> 24)) - 510.0f;
                acc += wcomb * tin[tk * 16 + rk];
            }
        }
        dref[cG] = acc * KDQ;
    }
    int bad = 0;
    for (int i = 0; i < I; ++i)
        if (std::fabs(dev[i] - dref[i]) > 1e-4 * (std::fabs(dref[i]) + 1)) {
            if (bad < 4) printf("col %d: dev %.6f ref %.6f\n", i, dev[i], dref[i]);
            ++bad;
        }
    printf("t7: %d/%d bad\n", bad, I);
    return 0;
}
