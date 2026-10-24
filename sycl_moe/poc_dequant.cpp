// PoC 1: extract mul1 trellis states and dequantize weights on the Arc B70, compare against
// the host reference (exl3ref, a transcription of the moe_mul1.cpp scalar path). Correctness
// only; no perf claim here.
#include <sycl/sycl.hpp>
#include <cmath>
#include <cstdio>
#include <vector>
#include "exl3_ref.h"

// Device-side weight-slot math: state t's tile weight index perm[t], computed inline
// (mirror of exl3ref::tc_perm: b = t>>3 selects the 8-bit group, j = t&7 the slot)
static void dequant_tiles(sycl::queue& q, const uint16_t* tiles, float* out, int tiles_n,
                          int bits, int hb, int n_tiles)
{
    // one work-item per tile
    q.parallel_for(n_tiles, [=](sycl::id<1> wid) {
        const int t0 = static_cast<int>(wid[0]);
        const uint16_t* packed = tiles + (size_t)t0 * 8 * (2 * bits + hb);
        float* dst = out + (size_t)t0 * 256;
        const int k2 = 2 * bits + hb;
        const int W = 4 * k2;                       // u32 words in the ring
        const uint32_t* w32 = reinterpret_cast<const uint32_t*>(packed);
        for (int t = 0; t < 256; ++t)
        {
            const int b1 = (((t + 1) * k2) >> 1) + 128 * k2;
            const int b0 = b1 - 16;
            const int shift = ((b1 - 1) / 32 + 1) * 32 - b1;
            const uint64_t merged = ((uint64_t)w32[(b0 / 32) % W] << 32) | w32[((b1 - 1) / 32) % W];
            const uint16_t state = (uint16_t)(merged >> shift);
            const uint32_t x = (uint32_t)state * 0x83DCD12Du;
            const int sum = (int)((x & 0xff) + ((x >> 8) & 0xff) + ((x >> 16) & 0xff) + (x >> 24));
            // weight slot
            const int b = t >> 3, j = t & 7;
            const int row = ((b & 3) * 2) + (j & 1) + ((j & 2) ? 8 : 0);
            const int col = (b >> 2) + ((j & 4) ? 8 : 0);
            dst[row * 16 + col] = ((float)sum - 510.0f) * 0.00676727294921875f; // k_inv = fp16(0x1eee)
        }
    }).wait();
    (void)tiles_n;
}

int main()
{
    sycl::queue q{sycl::gpu_selector_v};
    printf("Device: %s\n", q.get_device().get_info<sycl::info::device::name>().c_str());

    struct Case { int bits, hb; };
    const Case cases[] = {{1,0},{2,0},{2,1},{3,0},{3,1},{4,0},{6,0},{8,0},{1,1}};
    bool all_ok = true;

    for (const auto& cs : cases)
    {
        const int tiles_k = 8, tiles_n = 8;
        const int n_tiles = tiles_k * tiles_n;
        const int pu = exl3ref::tile_u16(cs.bits, cs.hb);
        std::vector<uint16_t> h_trellis(n_tiles * pu);
        exl3ref::Rng rng(12345 + cs.bits * 10 + cs.hb);
        for (auto& v : h_trellis) v = (uint16_t)(rng.next() >> 40);   // random bit soup

        std::vector<float> ref((size_t)n_tiles * 256);
        for (int t = 0; t < n_tiles; ++t)
            exl3ref::decode_tile(&h_trellis[(size_t)t * pu], cs.bits, cs.hb, &ref[(size_t)t * 256]);

        uint16_t* d_trellis = sycl::malloc_device<uint16_t>(h_trellis.size(), q);
        float* d_out = sycl::malloc_device<float>(ref.size(), q);
        q.memcpy(d_trellis, h_trellis.data(), h_trellis.size() * 2).wait();
        dequant_tiles(q, d_trellis, d_out, tiles_n, cs.bits, cs.hb, n_tiles);
        std::vector<float> got(ref.size());
        q.memcpy(got.data(), d_out, got.size() * 4).wait();
        sycl::free(d_trellis, q); sycl::free(d_out, q);

        double max_err = 0; size_t bad = 0;
        for (size_t i = 0; i < ref.size(); ++i) {
            const double e = std::fabs(ref[i] - got[i]);
            if (e > 1e-6) { if (bad < 3) printf("  [%zu] ref %f got %f\n", i, ref[i], got[i]); ++bad; }
            if (e > max_err) max_err = e;
        }
        const bool ok = bad == 0;
        all_ok &= ok;
        printf("K=%d%s : %s (max err %.3g, %zu/%zu bad)\n", cs.bits, cs.hb ? ".5" : "",
               ok ? "ok" : "FAIL", max_err, bad, ref.size());
    }
    printf("%s\n", all_ok ? "ALL OK" : "FAILURES");
    return all_ok ? 0 : 1;
}