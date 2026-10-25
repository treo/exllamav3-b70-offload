// lab_jm5: k-loop int8 gemv with B staged in SLM using the CANONICAL row-major [32][16]
// layout (byte stores), so joint_matrix_load needs no fixup transforms.
// Modes: 0 = row-major SLM B (byte scatter stores); 1 = same but A also pre-staged in SLM
// once per job; 2 = pure-global B (pre-unpacked elsewhere) for ceiling comparison.
#include <sycl/sycl.hpp>
#include <cstdio>
#include <vector>
#include <random>
#include <chrono>

namespace mx = sycl::ext::oneapi::experimental::matrix;
using u32 = uint32_t;
using u16 = unsigned short;
constexpr u32 MUL1 = 0x83DCD12Du;
constexpr int MM = 8, NN = 16, KK = 32;

struct Gemv5
{
    const u32* __restrict__ wsf;    // [job][ks][64] packed states (2/u32) per fragment
    const signed char* __restrict__ a8;  // [job][ks][8][32]
    int* __restrict__ out;          // [job][8][16]
    int njobs, ksteps;
    sycl::local_accessor<unsigned char, 1> slab;  // 512 B slab
    int mode;
    void operator()(sycl::nd_item<1> it) const
    {
        sycl::sub_group sg = it.get_sub_group();
        const int lane = (int)sg.get_local_linear_id();
        const size_t job = it.get_group(0);
        const u32* wf = wsf + job * ksteps * 64;
        const signed char* af = a8 + job * ksteps * MM * KK;
        unsigned char* sl = slab.get_pointer().get();
        mx::joint_matrix<sycl::sub_group, signed char, mx::use::a, MM, KK, mx::layout::row_major> a;
        mx::joint_matrix<sycl::sub_group, unsigned char, mx::use::b, KK, NN, mx::layout::row_major> b;
        mx::joint_matrix<sycl::sub_group, int, mx::use::accumulator, MM, NN> c;
        mx::joint_matrix_fill(sg, c, 0);
        const int wq = lane >> 1, cb = (lane & 1) * 8;
        for (int ks = 0; ks < ksteps; ++ks) {
            const u32* w0 = wf + (size_t)ks * 64;
#pragma unroll
            for (int jj = 0; jj < 8; ++jj) {
                int c = cb + jj;
                u32 st = w0[c * 4 + (wq >> 1)];
                u16 s16 = (wq & 1) ? (u16)(st >> 16) : (u16)st;
                u32 prod = (u32)s16 * MUL1;
                if (mode == 2) { // byte-scatter canonical row-major B[k][c] at k*16+c
                    int k0 = wq * 4;
                    sl[(k0 + 0) * NN + c] = (unsigned char)prod;
                    sl[(k0 + 1) * NN + c] = (unsigned char)(prod >> 8);
                    sl[(k0 + 2) * NN + c] = (unsigned char)(prod >> 16);
                    sl[(k0 + 3) * NN + c] = (unsigned char)(prod >> 24);
                } else {         // lane-slice layout: lane owns bytes [32L..32L+32)
                    *(u32*)&sl[lane * 32 + jj * 4] = prod;
                }
            }
            sg.barrier();
            auto pb = sycl::address_space_cast<sycl::access::address_space::local_space,
                                               sycl::access::decorated::yes>(sl);
            if (mode == 2) mx::joint_matrix_load(sg, b, pb, NN);
            else           mx::joint_matrix_load(sg, b, pb, NN);   // lie: same call, layout probe
            auto pa = sycl::address_space_cast<sycl::access::address_space::global_space,
                                               sycl::access::decorated::yes>(af + (size_t)ks * MM * KK);
            mx::joint_matrix_load(sg, a, pa, KK);
            mx::joint_matrix_mad(sg, c, a, b, c);
            sg.barrier();
        }
        auto pc = sycl::address_space_cast<sycl::access::address_space::global_space,
                                           sycl::access::decorated::yes>(out + job * MM * NN);
        mx::joint_matrix_store(sg, c, pc, NN, mx::layout::row_major);
    }
};

int main(int argc, char** argv) {
    sycl::queue q{sycl::gpu_selector_v};
    printf("device: %s\n", q.get_device().get_info<sycl::info::device::name>().c_str());
    const int NJ = 4800, KS = 320;     // decode-shape jobs: 120 chunks x 40 nfrag
    std::mt19937 rng(5);
    std::vector<u32> ws((size_t)NJ * KS * 64 / 8);   // smaller footprint, L2-hot ok
    std::vector<signed char> as((size_t)NJ * KS * MM * KK / 16);
    for (auto& v : ws) v = (u32)((rng() & 0xffff) | ((rng() & 0xffff) << 16));
    for (auto& v : as) v = (signed char)(rng() % 255 - 127);
    u32* dws = sycl::malloc_device<u32>(ws.size(), q);
    signed char* das = sycl::malloc_device<signed char>(as.size(), q);
    int* dout = sycl::malloc_device<int>((size_t)NJ * MM * NN, q);
    q.copy(ws.data(), dws, ws.size()); q.copy(as.data(), das, as.size()); q.wait();

    auto launch = [&](int mode) {
        return q.submit([&](sycl::handler& h) {
            sycl::local_accessor<unsigned char, 1> slm(sycl::range<1>(512), h);
            h.parallel_for(sycl::nd_range<1>{NJ * 16, 16},
                           [=](sycl::nd_item<1> it) [[sycl::reqd_sub_group_size(16)]]
                           { Gemv5{dws, das, dout, NJ, KS, slm, mode}(it); });
        });
    };
    launch(2).wait();
    auto t0 = std::chrono::steady_clock::now();
    while (std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count() < 1.0) launch(2);
    q.wait();
    for (int md = 2; md >= 0; --md) {
        if (md == 1) continue;
        double best = 1e30;
        for (int it = 0; it < 4; ++it) {
            auto s = std::chrono::steady_clock::now();
            launch(md).wait();
            auto e1 = std::chrono::steady_clock::now();
            double us = std::chrono::duration<double, std::micro>(e1 - s).count();
            if (us < best) best = us;
        }
        printf("mode %d: %8.1f us for %d jobs x %d ksteps\n", md, best, NJ, KS);
    }
    return 0;
}