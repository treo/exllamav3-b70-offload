// lab_dpas5 v2: production-dataflow DPAS probe (u8 route, correct VNNI semantics).
// Maps decoded (lab_dpas3, SG16, dpas<8,8,i32> on s8/u8):
//   B byte ordinal o=32b+ib -> col=(ib>>2)+8(b&1), hwk=4(b>>1)+(ib&3)
//     -> B u32 word #w of lane L = ONE product word: col = w + 8(L&1), k-quad = L>>1
//     -> A byte ordinal oA: row = oA/32, hwk = oA%32; A word = x8[row][hwk] s8 replicated x4
//   C ordinal i: row = i/16, col = i%16; lane L holds C ints [8L..8L+8) = row L>>1, col 8(L&1)+0..7
// One fragment = k32 x n16 = 128 weights = 8 product words/lane.
// Lane unpacks its 8 states from PREPACKED window words (stand-in for registration repack),
// computes products, assembles operands, dpas, stores. Reference on host.
#include <sycl/sycl.hpp>
#include <sycl/ext/intel/esimd.hpp>
#include <cstdio>
#include <cstdlib>
#include <vector>
#include <cmath>
#include <chrono>

using namespace sycl;
namespace esimd = sycl::ext::intel::esimd;
namespace xmx = sycl::ext::intel::esimd::xmx;
using u32 = uint32_t;
using u16 = unsigned short;

template <int WMODE, int AMODE, int SRCMODE = 0>
struct DpasGemm
{
    const u16* __restrict__ states;  // [frag][16 lanes][8] u16 states (lane = colset,kquad)
    const unsigned char* __restrict__ splat8; // [8 rows][32 hwk] replicated s8
    float* __restrict__ out;         // [frag][8][16]
    int nfrags;
    auto get(sycl::ext::oneapi::experimental::properties_tag) const {
        return sycl::ext::oneapi::experimental::properties{
            sycl::ext::oneapi::experimental::sub_group_size<16>};
    }
    void operator()(nd_item<1> it) const {
        const int lane = (int)it.get_local_id(0) & 15;
        const int f = (int)it.get_group(0);
        if (SRCMODE == 9) {   // exact BK clone: uniform byte globals
            const unsigned char* da = (const unsigned char*)states;   // reuse buffers
            const unsigned char* db = splat8;
            esimd::simd<signed char, 256> a;
            esimd::simd<unsigned char, 512> b;
#pragma unroll
            for (int i = 0; i < 256; ++i) a[i] = (signed char)da[i];
#pragma unroll
            for (int i = 0; i < 512; ++i) b[i] = db[i];
            esimd::simd<int32_t, 128> c(0);
            c = xmx::dpas<8, 8, int32_t>(c, b, a);
            if (lane == 0) for (int i = 0; i < 128; ++i) out[f * 128 + i] = (float)c[i] * 0.001f;
            return;
        }
        const u16* sp = states + (size_t)f * 128 + (SRCMODE == 1 ? 0 : lane * 8);
        u32 prod[8];
#pragma unroll
        for (int w = 0; w < 8; ++w) prod[w] = (u32)sp[w] * 0x83DCD12Du;

        esimd::simd<unsigned char, 512> B;
        // FULL fill (all 512 elements) - partial writes into an uninitialized simd are UB
        // and can DCE the whole dpas. Slice placement per lane, filler zeros elsewhere.
#pragma unroll
        for (int i = 0; i < 512; ++i) {
            int li = i - lane * 32;
            unsigned char v = 0;
            if (li >= 0 && li < 32) v = (unsigned char)(prod[(li >> 2) & 7] >> (8 * (li & 3)));
            B[WMODE ? (i & 31) : i] = v;
        }

        esimd::simd<signed char, 256> A;
        {
            const int row = lane >> 1, k0 = (lane & 1) * 16;
            const unsigned char* ap = splat8 + (AMODE == 2 ? 0 : row * 32 + k0);
#pragma unroll
            for (int i = 0; i < 256; ++i) {
                int li = i - lane * 16;
                signed char v = 0;
                if (AMODE == 3) v = (signed char)splat8[i];
                else if (li >= 0 && li < 16) v = (signed char)ap[li];
                A[AMODE && AMODE != 3 ? (i & 15) : i] = v;
            }
        }
        esimd::simd<int32_t, 128> C(0);
        C = xmx::dpas<8, 8, int32_t>(C, B, A);
        if (lane == 0)
            for (int i = 0; i < 128; ++i) out[f * 128 + i] = (float)C[i] * 0.001f;
    }
};

struct BKClone
{
    const unsigned char* da; const unsigned char* db; float* out;
    void operator()(item<1> itm) const {
        esimd::simd<signed char, 256> a;
        esimd::simd<unsigned char, 512> b;
#pragma unroll
        for (int i = 0; i < 256; ++i) a[i] = (signed char)da[i];
#pragma unroll
        for (int i = 0; i < 512; ++i) b[i] = db[i];
        esimd::simd<int32_t, 128> c(0);
        c = xmx::dpas<8, 8, int32_t>(c, b, a);
        if (itm.get_id() == 0) {
            for (int i = 0; i < 127; ++i) out[i] = (float)c[i] * 0.001f;
            out[127] = 777.0f;   // canary: did the kernel body run at all
            out[126] = (float)a[5] + 500.f;   // canary: operand materialized?
        }
    }
};

// proper ESIMD framing: launched via single_task -> the kernel body is a uniform SIMD
// program; simd values are distributed across the sub-group lanes.
struct Esmk
{
    const unsigned char* da; const unsigned char* db; float* out;
    auto get(sycl::ext::oneapi::experimental::properties_tag) const {
        return sycl::ext::oneapi::experimental::properties{
            sycl::ext::oneapi::experimental::sub_group_size<16>};
    }
    void operator()() const {
        esimd::simd<signed char, 256> a;
        esimd::simd<unsigned char, 512> b;
#pragma unroll
        for (int i = 0; i < 256; ++i) a[i] = (signed char)da[i];
#pragma unroll
        for (int i = 0; i < 512; ++i) b[i] = db[i];
        esimd::simd<int32_t, 128> c(0);
        c = xmx::dpas<8, 8, int32_t>(c, b, a);
#pragma unroll
        for (int i = 0; i < 128; ++i) out[i] = (float)c[i] * 0.001f;
    }
};

// Ownership probe (kept): every lane stamps its own lane id into its ordinal slice of B
// k=4(b>>1)+(ib&3). If the HW reads each ordinal from the WRITING lane's copy (contiguous
// slice ownership), C[r][col] = sum of 32 stamps = for col in 0..7: lanes with b&1==0 and
// b>>1 fixed... expected values computed on the host for BOTH hypotheses.
struct OwnProbe
{
    float* out;
    auto get(sycl::ext::oneapi::experimental::properties_tag) const {
        return sycl::ext::oneapi::experimental::properties{
            sycl::ext::oneapi::experimental::sub_group_size<16>};
    }
    void operator()(item<1> itm) const {
        const int lane = (int)itm.get_id() & 15;
        esimd::simd<unsigned char, 512> b;
#pragma unroll
        for (int i = 0; i < 512; ++i) {
            int li = i - lane * 32;
            b[i] = (unsigned char)((li >= 0 && li < 32) ? (lane + 1) : 0);
        }
        esimd::simd<signed char, 256> a;
#pragma unroll
        for (int i = 0; i < 256; ++i) a[i] = 1;   // uniform: only B stamps ownership
        esimd::simd<int32_t, 128> c(0);
        c = xmx::dpas<8, 8, int32_t>(c, b, a);
        if (itm.get_id() == 0)
            for (int i = 0; i < 128; ++i) out[i] = (float)c[i];
    }
};


int main(int argc, char** argv) {
    int which = argc > 1 ? atoi(argv[1]) : 0;
    queue q{gpu_selector_v};
    printf("device: %s\n", q.get_device().get_info<sycl::info::device::name>().c_str());
    const int NF = 128;
    std::vector<u16> hst((size_t)NF * 128);
    std::vector<unsigned char> hsp(512);
    srand(7);
    for (auto& v : hst) v = (u16)(rand() & 0xffff);
    for (auto& v : hsp) v = (unsigned char)(rand() % 201 - 100);
    u16* dstates = malloc_device<u16>(hst.size(), q);
    unsigned char* ds = malloc_device<unsigned char>(512, q);   // room for BKClone db
    float* dout = malloc_device<float>((size_t)NF * 128, q);
    q.copy(hst.data(), dstates, hst.size());
    q.copy(hsp.data(), ds, hsp.size());
    q.wait();

    // host reference with the SAME maps
    std::vector<float> href((size_t)NF * 128);
    for (int f = 0; f < NF; ++f) {
        long acc[8][16] = {};
        for (int L = 0; L < 16; ++L) {
            for (int w = 0; w < 8; ++w) {
                u32 st = hst[(size_t)f * 128 + L * 8 + w];
                u32 pr = st * 0x83DCD12Du;
                int col = w + 8 * (L & 1);
                int k0 = 4 * (L >> 1);
                for (int bb = 0; bb < 4; ++bb) {          // hwk slots k0+bb all same weight byte
                    int hwk = k0 + bb;
                    for (int r = 0; r < 8; ++r)
                        acc[r][col] += (long)((pr >> (8 * bb)) & 0xff) * (int)(signed char)hsp[r * 32 + hwk];
                }
            }
        }
        for (int r = 0; r < 8; ++r) for (int c = 0; c < 16; ++c)
            href[(size_t)f * 128 + r * 16 + c] = (float)acc[r][c] * 0.001f;
    }

    if (which == 0) q.parallel_for(nd_range<1>{{NF * 16}, {16}}, DpasGemm<0,0>{dstates, ds, dout, NF}).wait();
    if (which == 1) q.parallel_for(nd_range<1>{{NF * 16}, {16}}, DpasGemm<1,1>{dstates, ds, dout, NF}).wait();
    if (which == 2) q.parallel_for(nd_range<1>{{NF * 16}, {16}}, DpasGemm<1,0>{dstates, ds, dout, NF}).wait();
    if (which == 3) q.parallel_for(nd_range<1>{{NF * 16}, {16}}, DpasGemm<0,1>{dstates, ds, dout, NF}).wait();
    if (which == 4) q.parallel_for(nd_range<1>{{NF * 16}, {16}}, DpasGemm<1,1,1>{dstates, ds, dout, NF}).wait();
    if (which == 5) q.parallel_for(nd_range<1>{{NF * 16}, {16}}, DpasGemm<1,2,1>{dstates, ds, dout, NF}).wait();
    if (which == 11) {
        std::vector<unsigned char> a2(256), b2(512);
        srand(99);
        for (int i = 0; i < 256; ++i) a2[i] = (unsigned char)(rand() % 251 - 125);
        for (int i = 0; i < 512; ++i) b2[i] = (unsigned char)(rand() & 0xff);
        q.memcpy((unsigned char*)dstates, a2.data(), 256); q.memcpy(ds, b2.data(), 512); q.wait();
        q.memset(dout, 0, 128 * 4);
        q.parallel_for(range<1>{16}, BKClone{(const unsigned char*)dstates, ds, dout}).wait();
        std::vector<float> h11(128); q.copy(dout, h11.data(), 128); q.wait();
        long exp0 = 0, bad = 0;
        for (int cc = 0; cc < 16; ++cc) {
            long e = 0;
            for (int o = 0; o < 512; ++o) {
                int bnd = o / 32, ib = o % 32;
                int col = (ib >> 2) + 8 * (bnd & 1), hwk = 4 * (bnd >> 1) + (ib & 3);
                if (col == cc) e += (long)(signed char)a2[hwk] * (long)b2[o];
            }
            if (std::fabs(h11[cc] - e * 0.001f) > 1e-2) bad++;
            exp0 = e;
        }
        printf("which=11 range-launched uniform fill: cols-correct %d/16 (sample want %f got %f)\n",
               16 - (int)bad, exp0 * 0.001f, h11[15]);
        return 0;
    }
    if (which == 10) {
        std::vector<unsigned char> a2(256), b2(512);
        srand(99);
        for (int i = 0; i < 256; ++i) a2[i] = (unsigned char)(rand() % 251 - 125);
        for (int i = 0; i < 512; ++i) b2[i] = (unsigned char)(rand() & 0xff);
        q.memcpy((unsigned char*)dstates, a2.data(), 256); q.memcpy(ds, b2.data(), 512); q.wait();
        q.memset(dout, 0, 128 * 4);
        q.submit([&](handler& h){ h.set_arg(0, (unsigned char*)dstates); h.set_arg(1, ds); h.set_arg(2, dout);
            h.single_task(Esmk{(const unsigned char*)dstates, ds, dout}); }).wait();
        std::vector<float> h10(128); q.copy(dout, h10.data(), 128); q.wait();
        int nz = 0; for (int i = 0; i < 128; ++i) if (h10[i] != 0.f) nz++;
        long exp0 = 0;
        for (int o = 0; o < 512; ++o) {
            int bnd = o / 32, ib = o % 32;
            int col = (ib >> 2) + 8 * (bnd & 1), hwk = 4 * (bnd >> 1) + (ib & 3);
            if (col == 0) exp0 += (long)(signed char)a2[hwk] * (long)b2[o];
        }
        printf("which=10 single_task ESIMD: nonzero %d/128  C[0]=%f want %f\n", nz, h10[0], exp0 * 0.001f);
        return 0;
    }
    if (which == 7) {
        q.memset(dout, 0, 128 * 4);
        q.parallel_for(range<1>{16}, OwnProbe{dout}).wait();
        std::vector<float> h7(128); q.copy(dout, h7.data(), 128); q.wait();
        printf("ownership probe (B stamped lane+1 at OWN ordinal slice):\n");
        for (int r = 0; r < 4; ++r) {
            printf("  r%d:", r);
            for (int c = 0; c < 16; ++c) printf(" %5.0f", h7[r * 16 + c]);
            printf("\n");
        }
        // hypothesis tester
        auto test = [&](const char* nm, auto own) {
            bool ok = true;
            for (int r = 0; r < 8 && ok; ++r) for (int c = 0; c < 16 && ok; ++c) {
                long e = 0;
                for (int o = 0; o < 512; ++o) {
                    int bnd = o / 32, ib = o % 32;
                    int col = (ib >> 2) + 8 * (bnd & 1);
                    if (col == c) e += own(o) + 1;
                }
                if (std::fabs(h7[r * 16 + c] - (float)e) > 0.5f) ok = false;
            }
            printf("  hypothesis %s: %s\n", nm, ok ? "MATCH" : "no");
        };
        test("byte RR: ordinal o read from lane o%16", [](int o) { return o % 16; });
        test("slice:   ordinal o read from lane o/32", [](int o) { return o / 32; });
        return 0;
    }
    if (which == 8) {
        std::vector<unsigned char> a2(256), b2(512);
        srand(99);
        for (int i = 0; i < 256; ++i) a2[i] = (unsigned char)(rand() % 251 - 125);
        for (int i = 0; i < 512; ++i) b2[i] = (unsigned char)(rand() & 0xff);
        q.memcpy((unsigned char*)dstates, a2.data(), 256); q.memcpy(ds, b2.data(), 512); q.wait();
        q.memset(dout, 0, 128 * 4);
        q.parallel_for(range<1>{16}, [=](id<1> ix){ if (ix == 0) dout[2] = 424.0f; }).wait();
        q.parallel_for(range<1>{16}, BKClone{(const unsigned char*)dstates, ds, dout}).wait();
        std::vector<unsigned char> chk(4); q.copy((unsigned char*)dstates, chk.data(), 4); q.wait();
        std::vector<float> h8(128); q.copy(dout, h8.data(), 128); q.wait();
        printf("  sanity: plain kernel dout[2]=%f (want 424), a2[0..3][0]=%d (want %d)\n",
               h8[2], chk[0], a2[0]);
        int nz = 0; for (int i = 0; i < 128; ++i) if (h8[i] != 0.f) nz++;
        printf("which=8 item-style BK clone: nonzero %d/128  first %f %f\n", nz, h8[0], h8[1]);
        return 0;
    }
    if (which == 9) {
        std::vector<unsigned char> a2(256), b2(512);
        for (int i = 0; i < 256; ++i) a2[i] = (unsigned char)(rand() % 251 - 125);
        for (int i = 0; i < 512; ++i) b2[i] = (unsigned char)(rand() & 0xff);
        q.memcpy(dstates, a2.data(), 256); q.memcpy(ds, b2.data(), 512); q.wait();
        q.parallel_for(nd_range<1>{{16}, {16}}, DpasGemm<0,0,9>{dstates, ds, dout, 1}).wait();
        std::vector<float> h9(128); q.copy(dout, h9.data(), 128); q.wait();
        int nz = 0; for (int i = 0; i < 128; ++i) if (h9[i] != 0.f) nz++;
        long acc0 = 0;   // C ordinal 0 = row 0, col 0
        for (int o = 0; o < 512; ++o) {
            int bb2 = o / 32, ib = o % 32;
            int col = (ib >> 2) + 8 * (bb2 & 1), hwk = 4 * (bb2 >> 1) + (ib & 3);
            if (col == 0) acc0 += (long)(signed char)a2[hwk] * (long)b2[o];
        }
        printf("which=9 BK clone: nonzero %d/128 first=%f %f %f\n", nz, h9[0], h9[1], h9[2]);
        return 0;
    }
    if (which == 6) q.parallel_for(nd_range<1>{{NF * 16}, {16}}, DpasGemm<0,3,1>{dstates, ds, dout, NF}).wait();
    if (which >= 1) { printf("(uniform-mode variant %d: reference INVALID, just check nonzero)\n", which); }
    std::vector<float> hd((size_t)NF * 128);
    q.copy(dout, hd.data(), hd.size()).wait();
    int bad = 0; double mx = 0;
    for (size_t i = 0; which == 0 && i < hd.size(); ++i) {
        double d = std::fabs(hd[i] - href[i]);
        if (d > 1e-3 * (std::fabs(href[i]) + 1.0)) { if (bad < 5) printf(" i%zu got %f want %f\n", i, hd[i], href[i]); bad++; }
        if (d > mx) mx = d;
    }
    {   int nz = 0; for (size_t i = 0; i < hd.size(); ++i) if (hd[i] != 0.f) nz++;
        printf("dpas kernel which=%d: %s (bad %d, maxdiff %g, nonzero %d/%d)\n", which,
               (which == 0 && !bad) ? "PASS" : (which ? (nz ? "NONZERO(uniform probe)" : "ALL ZERO") : "MISMATCH"),
               bad, mx, nz, (int)hd.size()); }

    for (int i = 0; i < 200; ++i) q.parallel_for(nd_range<1>{{NF * 16}, {16}}, DpasGemm<0,0>{dstates, ds, dout, NF});
    q.wait();
    auto t0 = std::chrono::steady_clock::now();
    for (int i = 0; i < 50; ++i) q.parallel_for(nd_range<1>{{NF * 16}, {16}}, DpasGemm<0,0>{dstates, ds, dout, NF});
    q.wait();
    auto t1 = std::chrono::steady_clock::now();
    double us = std::chrono::duration<double, std::micro>(t1 - t0).count() / 50;
    double wt = (double)NF * 128 * 8;  // MACs
    printf("50 launches: %.1f us  (%.2f G weighted-MAC/s, weights %d KB)\n",
           us, wt / us / 1e3, (int)(hst.size() * 2 / 1024));
    return 0;
}