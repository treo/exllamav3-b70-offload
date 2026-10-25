// lab_jm3: joint_matrix B fed from SLM the subgroup unpacked itself (production dataflow:
// per-lane unpack of packed stream words -> SLM product words -> jm_load -> mad).
//   weight (wq 0..7, col c) product word P[wq][c] u32 covers hw-k slots 4wq..4wq+3
//   B logical [hwk][c] stored COL-MAJOR: byte(c, hwk) at SLM[c*32 + hwk] => u32 stores
//   A[r][4wq+bd] = x8[r][wq] replicated x4, row-major
//   C[r][c] = sum_wq x8[r][wq] * bytesum(P[wq][c])   == mul1 int8-tier semantics
#include <sycl/sycl.hpp>
#include <cstdio>
#include <vector>
#include <random>
#include <chrono>

namespace mx = sycl::ext::oneapi::experimental::matrix;
constexpr int MM = 8, NN = 16, KK = 32;
using u32 = uint32_t;
using u16 = unsigned short;
constexpr u32 MUL1 = 0x83DCD12Du;

struct SlmFrag
{
    const signed char* A;
    const u32* states;          // [16 c][4] = 8 wq states per col, 2 packed per u32
    int* out;
    sycl::local_accessor<unsigned char, 1> slab;
    void operator()(sycl::nd_item<1> it) const
    {
        sycl::sub_group sg = it.get_sub_group();
        const int lane = (int)sg.get_local_linear_id();
        const size_t fo = (size_t)it.get_group(0);
        const signed char* Af = A + fo * MM * KK;
        const u32* Sf = states + fo * 64;
        unsigned char* sl = slab.get_pointer().get();
        const int wq = lane >> 1, cb = (lane & 1) * 8;
#pragma unroll
        for (int j = 0; j < 8; ++j) {
            int c = cb + j;
            u32 st = Sf[c * 4 + (wq >> 1)];
            u16 s16 = (wq & 1) ? (u16)(st >> 16) : (u16)st;
            u32 prod = (u32)s16 * MUL1;
            *(u32*)&sl[c * 32 + wq * 4] = prod;
        }
        sg.barrier();
        mx::joint_matrix<sycl::sub_group, signed char, mx::use::a, MM, KK, mx::layout::row_major> a;
        mx::joint_matrix<sycl::sub_group, unsigned char, mx::use::b, KK, NN, mx::layout::col_major> b;
        mx::joint_matrix<sycl::sub_group, int, mx::use::accumulator, MM, NN> c;
        auto pa = sycl::address_space_cast<sycl::access::address_space::global_space,
                                           sycl::access::decorated::yes>(Af);
        auto pb = sycl::address_space_cast<sycl::access::address_space::local_space,
                                           sycl::access::decorated::yes>(sl);
        mx::joint_matrix_load(sg, a, pa, KK);
        mx::joint_matrix_load(sg, b, pb, KK);
        mx::joint_matrix_fill(sg, c, 0);
        mx::joint_matrix_mad(sg, c, a, b, c);
        auto pc = sycl::address_space_cast<sycl::access::address_space::global_space,
                                           sycl::access::decorated::yes>(out);
        mx::joint_matrix_store(sg, c, pc, NN, mx::layout::row_major);
    }
};
int main() {
    sycl::queue q{sycl::gpu_selector_v};
    printf("device: %s\n", q.get_device().get_info<sycl::info::device::name>().c_str());
    std::mt19937 rng(11);
    const int NF = 4096;
    std::vector<signed char> hA((size_t)NF * MM * KK);
    std::vector<u32> hS((size_t)NF * 64);
    // A: random x8 per (r, wq), replicated into 4 hwk slots
    for (int f = 0; f < NF; ++f)
        for (int r = 0; r < MM; ++r)
            for (int wq = 0; wq < 8; ++wq) {
                signed char v = (signed char)(rng() % 255 - 127);
                for (int bd = 0; bd < 4; ++bd) hA[(size_t)f * MM * KK + r * KK + wq * 4 + bd] = v;
            }
    for (auto& v : hS) v = (u32)(rng() & 0xffff) | ((u32)(rng() & 0xffff) << 16);
    signed char* dA = sycl::malloc_device<signed char>(hA.size(), q);
    u32* dS = sycl::malloc_device<u32>(hS.size(), q);
    int* dC = sycl::malloc_device<int>((size_t)NF * MM * NN, q);
    q.copy(hA.data(), dA, hA.size()); q.copy(hS.data(), dS, hS.size()); q.wait();

    auto launch = [&]() {
        return q.submit([&](sycl::handler& h) {
            sycl::local_accessor<unsigned char, 1> slm(sycl::range<1>(512), h);
            h.parallel_for(sycl::nd_range<1>{NF * 16, 16},
                           [=](sycl::nd_item<1> it) [[sycl::reqd_sub_group_size(16)]]
                           { SlmFrag{dA, dS, dC + (size_t)it.get_group(0) * MM * NN, slm}(it); });
        });
    };
    launch().wait();
    std::vector<int> hC((size_t)NF * MM * NN);
    q.copy(dC, hC.data(), hC.size()); q.wait();
    int bad = 0;
    for (int f = 0; f < 4; ++f) {           // check first frags fully
        for (int c = 0; c < NN; ++c) for (int r = 0; r < MM; ++r) {
            long e = 0;
            for (int wq = 0; wq < 8; ++wq) {
                u32 st = hS[(size_t)f * 64 + c * 4 + (wq >> 1)];
                u16 s16 = (wq & 1) ? (u16)(st >> 16) : (u16)st;
                u32 prod = (u32)s16 * MUL1;
                int bs = (int)((prod & 0xff) + ((prod >> 8) & 0xff) + ((prod >> 16) & 0xff) + (prod >> 24));
                e += (long)bs * hA[(size_t)f * MM * KK + r * KK + wq * 4];
            }
            if (std::abs(hC[(size_t)f * MM * NN + r * NN + c] - (int)e) > 1) {
                if (bad < 8) printf(" f%d r%d c%d got %d want %ld\n", f, r, c,
                                    hC[(size_t)f * MM * NN + r * NN + c], e);
                bad++;
            }
        }
    }
    printf("SLM-fed joint_matrix frag: %s (%d bad in first 4 frags)\n", bad ? "CHECK" : "PASS", bad);

    launch().wait();
    auto t0 = std::chrono::steady_clock::now();
    while (std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count() < 1.2) launch();
    q.wait();
    double best = 1e30;
    for (int it = 0; it < 5; ++it) {
        auto s = std::chrono::steady_clock::now();
        launch().wait();
        auto e1 = std::chrono::steady_clock::now();
        double us = std::chrono::duration<double, std::micro>(e1 - s).count();
        if (us < best) best = us;
    }
    double macs = (double)NF * MM * NN * 8;   // LOGICAL k = 8 weight-quads
    printf("slm-frag: %.1f us -> %.2f TMAC/s logical (%.2f TMAC/s hw-k32 equiv)\n",
           best, macs / best / 1e6, (double)NF * MM * NN * KK / best / 1e6);
    return 0;
}