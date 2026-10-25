// lab_jm8: production Gemv8 geometry in isolation — ONE tile of 16 mul1 words staging
// TWO consecutive k32 fragments into a single 1KB SLM slab, loaded as slp and slp+512
// with stride 64, exactly like moe_sycl.cpp Gemv8. Reference is scalar over the same
// logical W[k][n] bytes. If this passes, production staging math is sound and the bug
// is elsewhere; if it fails, the printed C vs ref grid localizes the mispairing.
#include <sycl/sycl.hpp>

#include <cstdio>
#include <vector>

namespace mx = sycl::ext::oneapi::experimental::matrix;

using u32 = unsigned int;
using u16 = unsigned short;

#ifndef FRAGS
#define FRAGS 4          // 4 fragments = 2 tiles of 16 quad rows
#endif

static int errors = 0;

struct TwinFrag
{
    const u32* __restrict__ ws;        // [frags*8 + q][16] prod dwords, quad-row major
    const signed char* __restrict__ a8;
    int* __restrict__ out;             // [1][8][16]
    int tiles;
    sycl::local_accessor<unsigned char, 1> slab;
    void operator()(sycl::nd_item<1> it) const
    {
        sycl::sub_group sg = it.get_sub_group();
        const int lane = (int)sg.get_local_linear_id();
        u32* sl32 = (u32*)slab.get_pointer().get();
        mx::joint_matrix<sycl::sub_group, signed char, mx::use::a, 8, 32,
                         mx::layout::row_major> ja;
        mx::joint_matrix<sycl::sub_group, unsigned char, mx::use::b, 32, 16,
                         mx::layout::ext_intel_packed> jb;
        mx::joint_matrix<sycl::sub_group, int, mx::use::accumulator, 8, 16> jc;
        mx::joint_matrix_fill(sg, jc, 0);
        for (int tk = 0; tk < tiles; ++tk) {
            // stage 16 quad rows x 16 cols, exactly like production: dword (rk*16 + lane)
            for (int rk = 0; rk < 16; ++rk)
                sl32[rk * 16 + lane] = ws[(size_t)tk * 256 + rk * 16 + lane];
            sg.barrier();
            for (int fk = 0; fk < 2; ++fk) {
                auto pag = sycl::address_space_cast<sycl::access::address_space::global_space,
                                                    sycl::access::decorated::yes>(
                    (const signed char*)(a8 + (size_t)(2 * tk + fk) * 64 + lane * 8));
                // NOTE: production loads with pag = pa0 + frag*64 and stride 32 (bytes);
                // the A slab here is laid out [frag][8 rows][8 words] with row stride 8 i32.
                mx::joint_matrix_load(sg, ja, pag, 32);
                mx::joint_matrix_load(sg, jb,
                    sycl::address_space_cast<sycl::access::address_space::local_space,
                                             sycl::access::decorated::yes>(
                        (const unsigned char*)sl32 + fk * 512),
                    64);
                mx::joint_matrix_mad(sg, jc, ja, jb, jc);
            }
            sg.barrier();
        }
        auto pc = sycl::address_space_cast<sycl::access::address_space::global_space,
                                           sycl::access::decorated::yes>(out);
        mx::joint_matrix_store(sg, jc, pc, 16, mx::layout::row_major);
    }
};

int main()
{
    sycl::queue q([](sycl::exception_list) {});
    printf("Running on %s\n",
           q.get_device().get_info<sycl::info::device::name>().c_str());

    const int Q = FRAGS * 8;                     // quad rows
    std::vector<u32> ws((size_t)Q * 16);
    std::vector<signed char> x(Q * 4 * 16);      // logical activations per hw-k'
    // distinct per (quad q, col c) prod bytes: value = (q*16 + c) mod 97 + 1 (<=97 so
    // any A pair stays i16-safe); activation bytes: x8(hw-k) = (hw-k) mod 101 - 50
    for (int q = 0; q < Q; ++q)
        for (int c = 0; c < 16; ++c) {
            u32 v = (u32)((q * 16 + c) % 97 + 1);
            ws[(size_t)q * 16 + c] = (v << 24) | (v << 16) | (v << 8) | v;   // replicated
        }
    // a8: [frag][8 rows][8 words] i32, each word = one hw-k byte replicated x4
    std::vector<int> a8((size_t)FRAGS * 64);
    for (int f = 0; f < FRAGS; ++f)
        for (int r = 0; r < 8; ++r)
            for (int w = 0; w < 8; ++w) {
                int hk = f * 8 + w;                       // this word's activation index
                signed char xv = (signed char)((hk * 4) % 101 - 50);   // any per-k value
                for (int b = 0; b < 4; ++b)
                    x[(size_t)hk * 4 * 16 + r * 16 + b * 16] = xv;     // unused grid; see ref
                a8[(size_t)f * 64 + r * 8 + w] = (int)xv * 0x01010101;
            }
    std::vector<int> out(8 * 16, -12345);

    u32* dws = sycl::malloc_device<u32>(ws.size(), q);
    signed char* da = sycl::malloc_device<signed char>(a8.size() * 4, q);
    int* dout = sycl::malloc_device<int>(out.size(), q);
    q.copy(dws, ws.data(), ws.size());
    q.memcpy(da, (const char*)a8.data(), a8.size() * 4).wait();
    {
        sycl::buffer<int, 1> ob{ out };
        q.submit([&](sycl::handler& h) {
            sycl::local_accessor<unsigned char, 1> slab({ 1024 }, h);
            h.parallel_for(sycl::nd_range<1>{ 16, 16 },
                           TwinFrag{ dws, (const signed char*)da, dout, FRAGS / 2, slab });
        });
    }
    q.wait();
    std::vector<int> got(8 * 16);
    q.copy(got.data(), dout, got.size()); q.wait();

    // scalar reference: C[r][c] = sum over hw-k' A[r][k']*B[k'][c]; B quad row q covers
    // hw-k' 4q..4q+3 with bytes = ws[q][c]; A word w of fragment f covers hw-k' 4w..4w+3
    // (same value across the 4 bytes = xv).
    int bad = 0;
    for (int r = 0; r < 8; ++r)
        for (int c = 0; c < 16; ++c) {
            long ref = 0;
            for (int q = 0; q < Q; ++q) {
                const u32 wdv = ws[(size_t)q * 16 + c];
                int xb = (int)(signed char)((unsigned int)a8[(size_t)(q >> 3) * 64 + r * 8 +
                                                             (q & 7)] & 0xffu);
                for (int b = 0; b < 4; ++b)
                    ref += (long)(int)((wdv >> (8 * b)) & 0xffu) * xb;
            }
            if (got[r * 16 + c] != (int)ref) {
                if (bad < 12) printf("  MISMATCH r%d c%d: got %d ref %ld\n", r, c,
                                     got[r * 16 + c], ref);
                ++bad;
            }
        }
    errors = bad;
    printf(bad ? "FAIL: %d mismatches\n" : "PASS: twin-fragment tile staging exact (%d frags)\n",
           bad ? bad : FRAGS);
    sycl::free(dws, q); sycl::free(da, q); sycl::free(dout, q);
    return bad ? 1 : 0;
}