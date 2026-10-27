// lab_jm9: is a SINGLE m16n16k32 int8 joint_matrix legal and faster on Xe2 than the two
// m8n16k32 fragments production runs per (k tile, fk)? The 16 A rows of one production a8
// block ([16 rows][8 i32] = 512 B, stride 32 B) already describe exactly the rows the two
// m8 fragments consume, and the two m8 accumulators already describe one 16x16 C tile - so
// if m16 works, the fragment issue count HALVES with no layout change anywhere downstream.
//
// Stage 1 checks bit-exactness against a scalar integer reference over the same logical
// A/hw-k/B bytes. Stage 2 times m16 vs 2x m8 for identical logical work (sustained,
// burn-in + min-of-N per sycl_moe/NOTES).
#include <sycl/sycl.hpp>
#include <cstdio>
#include <cstdlib>
#include <vector>
#include <chrono>
#include <algorithm>

namespace mx = sycl::ext::oneapi::experimental::matrix;
using u32 = unsigned int;

static constexpr int TILES = 160;      // k tiles per gemv slot at the 2.05bpw gu shape
static constexpr int SLAB = 1024;      // bytes of packed B staged per tile (2 x 512)

// ---- kernel A: production shape (two m8 fragments per fk)
struct TwoM8
{
    const u32* __restrict__ ws;          // [tile][16 rows][16 cols] product dwords
    const int* __restrict__ a8;          // [tile][2 fk][16 rows][8 words]
    int* __restrict__ out;               // [16][16]
    int tiles;
    sycl::local_accessor<unsigned char, 1> slab;
    void operator()(sycl::nd_item<1> it) const
    {
        sycl::sub_group sg = it.get_sub_group();
        const int lane = (int)sg.get_local_linear_id();
        u32* sl32 = (u32*)slab.get_pointer().get();
        mx::joint_matrix<sycl::sub_group, unsigned char, mx::use::b, 32, 16,
                         mx::layout::ext_intel_packed> jb;
        mx::joint_matrix<sycl::sub_group, signed char, mx::use::a, 8, 32,
                         mx::layout::row_major> ja;
        mx::joint_matrix<sycl::sub_group, int, mx::use::accumulator, 8, 16> c0, c1;
        mx::joint_matrix_fill(sg, c0, 0);
        mx::joint_matrix_fill(sg, c1, 0);
        for (int tk = 0; tk < tiles; ++tk) {
            for (int rk = 0; rk < 16; ++rk)
                sl32[rk * 16 + lane] = ws[(size_t)tk * 256 + rk * 16 + lane];
            sg.barrier();
            for (int fk = 0; fk < 2; ++fk) {
                const int* blk = a8 + ((size_t)tk * 2 + fk) * 128;
                auto pal = sycl::address_space_cast<sycl::access::address_space::local_space,
                                                    sycl::access::decorated::yes>(
                    (const unsigned char*)sl32 + fk * 512);
                mx::joint_matrix_load(sg, jb, pal, 64);
                for (int f = 0; f < 2; ++f) {
                    auto pag = sycl::address_space_cast<sycl::access::address_space::global_space,
                                                        sycl::access::decorated::yes>(
                        (const signed char*)(blk + f * 64));
                    mx::joint_matrix_load(sg, ja, pag, 32);
                    if (f) mx::joint_matrix_mad(sg, c1, ja, jb, c1);
                    else   mx::joint_matrix_mad(sg, c0, ja, jb, c0);
                }
            }
            sg.barrier();
        }
        auto p0 = sycl::address_space_cast<sycl::access::address_space::global_space,
                                           sycl::access::decorated::yes>(out);
        auto p1 = sycl::address_space_cast<sycl::access::address_space::global_space,
                                           sycl::access::decorated::yes>(out + 8 * 16);
        mx::joint_matrix_store(sg, c0, p0, 16, mx::layout::row_major);
        mx::joint_matrix_store(sg, c1, p1, 16, mx::layout::row_major);
    }
};

// ---- kernel B: one m16 fragment per fk, same bytes, half the fragment issues
struct OneM16
{
    const u32* __restrict__ ws;
    const int* __restrict__ a8;
    int* __restrict__ out;
    int tiles;
    sycl::local_accessor<unsigned char, 1> slab;
    void operator()(sycl::nd_item<1> it) const
    {
        sycl::sub_group sg = it.get_sub_group();
        const int lane = (int)sg.get_local_linear_id();
        u32* sl32 = (u32*)slab.get_pointer().get();
        mx::joint_matrix<sycl::sub_group, unsigned char, mx::use::b, 32, 16,
                         mx::layout::ext_intel_packed> jb;
        mx::joint_matrix<sycl::sub_group, signed char, mx::use::a, 16, 32,
                         mx::layout::row_major> ja;
        mx::joint_matrix<sycl::sub_group, int, mx::use::accumulator, 16, 16> c;
        mx::joint_matrix_fill(sg, c, 0);
        for (int tk = 0; tk < tiles; ++tk) {
            for (int rk = 0; rk < 16; ++rk)
                sl32[rk * 16 + lane] = ws[(size_t)tk * 256 + rk * 16 + lane];
            sg.barrier();
            for (int fk = 0; fk < 2; ++fk) {
                const int* blk = a8 + ((size_t)tk * 2 + fk) * 128;
                auto pal = sycl::address_space_cast<sycl::access::address_space::local_space,
                                                    sycl::access::decorated::yes>(
                    (const unsigned char*)sl32 + fk * 512);
                auto pag = sycl::address_space_cast<sycl::access::address_space::global_space,
                                                    sycl::access::decorated::yes>(
                    (const signed char*)blk);
                mx::joint_matrix_load(sg, jb, pal, 64);
                mx::joint_matrix_load(sg, ja, pag, 32);
                mx::joint_matrix_mad(sg, c, ja, jb, c);
            }
            sg.barrier();
        }
        auto pc = sycl::address_space_cast<sycl::access::address_space::global_space,
                                           sycl::access::decorated::yes>(out);
        mx::joint_matrix_store(sg, c, pc, 16, mx::layout::row_major);
    }
};

int main(int argc, char** argv)
{
    const int reps = argc > 1 ? atoi(argv[1]) : 400;
    sycl::queue q([](sycl::exception_list el) {
        for (auto& e : el) {
            try { std::rethrow_exception(e); }
            catch (const sycl::exception& x) { printf("ASYNC: %s\n", x.what()); }
        }
    });
    printf("%s\n", q.get_device().get_info<sycl::info::device::name>().c_str());

    // logical bytes: hw-k' q (0..63 per tile: 2 fk x k32) and col c carry value (q*16+c)%97+1;
    // A row r, hw-k' value = ((r*7 + q*4) % 101) - 50 (signed, small, i16-safe in pairs)
    std::vector<u32> ws((size_t)TILES * 256);
    std::vector<int> a8((size_t)TILES * 2 * 128);
    std::vector<signed char> av((size_t)TILES * 2 * 16 * 32);
    for (int tk = 0; tk < TILES; ++tk)
        for (int rk = 0; rk < 16; ++rk)
            for (int c = 0; c < 16; ++c) {
                int hk = (rk >> 3) * 32 + (rk & 7) * 4;      // hw-k base of this quad row
                u32 v = (u32)((hk + c) % 97 + 1);
                ws[(size_t)tk * 256 + rk * 16 + c] = (v << 24) | (v << 16) | (v << 8) | v;
            }
    for (int tk = 0; tk < TILES; ++tk)
        for (int fk = 0; fk < 2; ++fk)
            for (int r = 0; r < 16; ++r)
                for (int w = 0; w < 8; ++w) {
                    int hk = fk * 32 + w * 4;                // hw-k within this fk block
                    signed char xv = (signed char)(((r * 7 + hk) % 101) - 50);
                    a8[((size_t)tk * 2 + fk) * 128 + r * 8 + w] = (int)(u32)((unsigned char)xv * 0x01010101u);
                    for (int b = 0; b < 4; ++b)
                        av[((size_t)tk * 2 + fk) * 512 + r * 32 + w * 4 + b] = xv;
                }
    // scalar reference: C[r][c] = sum_tk sum_fk sum_hwk A * B, B byte value = (hwk + c) % 97 + 1
    std::vector<long> ref(16 * 16, 0);
    for (int tk = 0; tk < TILES; ++tk)
        for (int fk = 0; fk < 2; ++fk)
            for (int r = 0; r < 16; ++r)
                for (int c = 0; c < 16; ++c) {
                    long acc = 0;
                    for (int w = 0; w < 8; ++w) {
                        int hk = fk * 32 + w * 4;
                        long a = av[((size_t)tk * 2 + fk) * 512 + r * 32 + w * 4];
                        long b = (hk + c) % 97 + 1;
                        acc += 4 * a * b;                    // the value spans 4 hw-k bytes
                    }
                    ref[r * 16 + c] += acc;
                }

    u32* dws = (u32*)sycl::malloc_device(ws.size() * 4, q);
    int* da8 = (int*)sycl::malloc_device(a8.size() * 4, q);
    int* dout = (int*)sycl::malloc_device(16 * 16 * 4, q);
    q.memcpy(dws, ws.data(), ws.size() * 4).wait();
    q.memcpy(da8, a8.data(), a8.size() * 4).wait();

    auto run_check = [&](const char* name, auto maker) {
        q.memset(dout, 0, 16 * 16 * 4).wait();
        q.submit([&](sycl::handler& h) {
            sycl::local_accessor<unsigned char, 1> slab({ SLAB }, h);
            h.parallel_for(sycl::nd_range<1>{ 16, 16 }, maker(dws, da8, dout, slab));
        }).wait();
        std::vector<int> got(16 * 16);
        q.copy(got.data(), dout, got.size()).wait();
        int bad = 0;
        long worst = 0;
        for (int i = 0; i < 16 * 16; ++i) {
            long d = std::labs((long)got[i] - ref[i]);
            if (d) { ++bad; worst = std::max(worst, d); }
        }
        printf("%-10s correctness: %s (%d/%d bad, worst diff %ld)\n", name,
               bad ? "FAIL" : "BIT-EXACT", bad, 16 * 16, worst);
        if (bad) for (int i = 0; i < 8; ++i) printf("   r%d c0: got %d want %ld\n", i, got[i*16], ref[i*16]);
        return bad == 0;
    };

    bool ok8 = run_check("2x m8", [&](auto w, auto a, auto o, auto& s) { return TwoM8{ w, a, o, TILES, s }; });
    bool ok16 = run_check("1x m16", [&](auto w, auto a, auto o, auto& s) { return OneM16{ w, a, o, TILES, s }; });

    auto timeit = [&](const char* name, auto maker) {
        double best = 1e30;
        auto t_start = std::chrono::steady_clock::now();
        for (;;) {
            for (int i = 0; i < 20; ++i)
                q.submit([&](sycl::handler& h) {
                    sycl::local_accessor<unsigned char, 1> slab({ SLAB }, h);
                    h.parallel_for(sycl::nd_range<1>{ 16, 16 }, maker(dws, da8, dout, slab));
                }).wait();
            auto t0 = std::chrono::steady_clock::now();
            for (int i = 0; i < reps; ++i)
                q.submit([&](sycl::handler& h) {
                    sycl::local_accessor<unsigned char, 1> slab({ SLAB }, h);
                    h.parallel_for(sycl::nd_range<1>{ 16, 16 }, maker(dws, da8, dout, slab));
                }).wait();
            best = std::min(best, std::chrono::duration<double, std::micro>(
                std::chrono::steady_clock::now() - t0).count() / reps);
            if (std::chrono::duration<double>(std::chrono::steady_clock::now() - t_start).count() > 2.5) break;
        }
        printf("%-10s %8.2f us for %d slots x %d k tiles\n", name, best, 1, TILES);
        return best;
    };

    // INTERLEAVED rounds (clock ramp inverts Xe2 rankings when variants run in blocks):
    // A B A B A B, min of each variant's samples.
    double t8 = 1e30, t16 = 1e30;
    for (int round = 0; round < 3; ++round) {
        t8 = std::min(t8, timeit("2x m8", [&](auto w, auto a, auto o, auto& s) { return TwoM8{ w, a, o, TILES, s }; }));
        t16 = std::min(t16, timeit("1x m16", [&](auto w, auto a, auto o, auto& s) { return OneM16{ w, a, o, TILES, s }; }));
    }
    printf("m16 / m8 = %.3f   (%s)\n", t16 / t8,
           t16 < t8 * 0.97 ? "m16 WINS" : (t16 > t8 * 1.03 ? "m16 loses" : "tie"));
    if (!ok8 || !ok16) printf("NOTE: timing on unverified results is informational only\n");

    sycl::free(dws, q); sycl::free(da8, q); sycl::free(dout, q);
    return 0;
}