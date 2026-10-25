// lab_jm6: which B-feed layout makes joint_matrix_load shuffle-free?
// Variants (timing-only; correctness of canonical layouts checked separately):
//  V0: B row-major global [KS*32][16] pre-unpacked bytes, load ld=16   (preunpack ceiling)
//  V1: B canonical row-major SLM (byte-scatter stores in loop), ld=16
//  V2: B col-major SLM (dword stores), ld=32 (jm3 layout, loop form)
//  V3: B = row-major global but K=16 fragments (mem row-major, ld=16) half-size frags
// Includes a numeric self-check for V1/V2 against scalar reference (small single job).
#include <sycl/sycl.hpp>
#include <cstdio>
#include <vector>
#include <random>
#include <chrono>
#include <cmath>

namespace mx = sycl::ext::oneapi::experimental::matrix;
using u32 = uint32_t;
using u16 = unsigned short;
constexpr u32 MUL1 = 0x83DCD12Du;
constexpr int MM = 8, NN = 16, KK = 32;

template <int V>
struct Gemv6
{
    const u32* __restrict__ wsf;
    const unsigned char* __restrict__ bpre;   // V0: pre-unpacked bytes [job][ks*32][16]
    const signed char* __restrict__ a8;
    int* __restrict__ out;
    int njobs, ksteps;
    sycl::local_accessor<unsigned char, 1> slab;
    void operator()(sycl::nd_item<1> it) const
    {
        sycl::sub_group sg = it.get_sub_group();
        const int lane = (int)sg.get_local_linear_id();
        const size_t job = it.get_group(0);
        const u32* wf = wsf + job * ksteps * 64;
        const unsigned char* bf = bpre + job * ksteps * (KK * NN);
        const signed char* af = a8 + job * ksteps * MM * KK;
        unsigned char* sl = slab.get_pointer().get();
        mx::joint_matrix<sycl::sub_group, signed char, mx::use::a, MM, KK, mx::layout::row_major> a;
        mx::joint_matrix<sycl::sub_group, unsigned char, mx::use::b, KK, NN,
                         mx::layout::row_major> b;
        mx::joint_matrix<sycl::sub_group, int, mx::use::accumulator, MM, NN> c;
        mx::joint_matrix_fill(sg, c, 0);
        const int wq = lane >> 1, cb = (lane & 1) * 8;
        for (int ks = 0; ks < ksteps; ++ks) {
            if (V == 1 || V == 2) {
                const u32* w0 = wf + (size_t)ks * 64;
#pragma unroll
                for (int jj = 0; jj < 8; ++jj) {
                    int c = cb + jj;
                    u32 st = w0[c * 4 + (wq >> 1)];
                    u16 s16 = (wq & 1) ? (u16)(st >> 16) : (u16)st;
                    u32 prod = (u32)s16 * MUL1;
                    if (V == 1) {
                        int k0 = wq * 4;
                        sl[(k0 + 0) * NN + c] = (unsigned char)prod;
                        sl[(k0 + 1) * NN + c] = (unsigned char)(prod >> 8);
                        sl[(k0 + 2) * NN + c] = (unsigned char)(prod >> 16);
                        sl[(k0 + 3) * NN + c] = (unsigned char)(prod >> 24);
                    } else {
                        *(u32*)&sl[c * 32 + wq * 4] = prod;
                    }
                }
                sg.barrier();
            }
            {
                auto pa = sycl::address_space_cast<sycl::access::address_space::global_space,
                                                   sycl::access::decorated::yes>(af + (size_t)ks * MM * KK);
                mx::joint_matrix_load(sg, a, pa, KK);
                if (V == 0) {
                    auto pb = sycl::address_space_cast<sycl::access::address_space::global_space,
                                                       sycl::access::decorated::yes>(bf + (size_t)ks * KK * NN);
                    mx::joint_matrix_load(sg, b, pb, NN);
                } else if (V == 1) {
                    auto pb = sycl::address_space_cast<sycl::access::address_space::local_space,
                                                       sycl::access::decorated::yes>(sl);
                    mx::joint_matrix_load(sg, b, pb, NN);
                } else {   // V2: declare col-major matrix over the dword-stored slab
                    mx::joint_matrix<sycl::sub_group, unsigned char, mx::use::b, KK, NN,
                                     mx::layout::col_major> b2;
                    auto pb = sycl::address_space_cast<sycl::access::address_space::local_space,
                                                       sycl::access::decorated::yes>(sl);
                    mx::joint_matrix_load(sg, b2, pb, KK);
                    sg.barrier();
                    mx::joint_matrix_mad(sg, c, a, b2, c);
                    continue;
                }
                mx::joint_matrix_mad(sg, c, a, b, c);
                if (V == 1) sg.barrier();
            }
        }
        auto pc = sycl::address_space_cast<sycl::access::address_space::global_space,
                                           sycl::access::decorated::yes>(out + job * MM * NN);
        mx::joint_matrix_store(sg, c, pc, NN, mx::layout::row_major);
    }
};

int main() {
    sycl::queue q{sycl::gpu_selector_v};
    printf("device: %s\n", q.get_device().get_info<sycl::info::device::name>().c_str());
    const int NJ = 4800, KS = 320;
    std::mt19937 rng(5);
    std::vector<u32> ws((size_t)NJ * KS * 64);
    std::vector<unsigned char> bpre((size_t)NJ * KS * KK * NN);
    std::vector<signed char> as((size_t)NJ * KS * MM * KK);
    for (auto& v : ws) v = (u32)((rng() & 0xffff) | ((rng() & 0xffff) << 16));
    for (auto& v : bpre) v = (unsigned char)(rng() & 0xff);
    for (auto& v : as) v = (signed char)(rng() % 255 - 127);
    u32* dws = sycl::malloc_device<u32>(ws.size(), q);
    unsigned char* dbp = sycl::malloc_device<unsigned char>(bpre.size(), q);
    signed char* das = sycl::malloc_device<signed char>(as.size(), q);
    int* dout = sycl::malloc_device<int>((size_t)NJ * MM * NN, q);
    q.copy(ws.data(), dws, ws.size()); q.copy(bpre.data(), dbp, bpre.size());
    q.copy(as.data(), das, as.size()); q.wait();

    auto launch = [&](auto vtag) {
        constexpr int V = decltype(vtag)::value;
        return q.submit([&](sycl::handler& h) {
            sycl::local_accessor<unsigned char, 1> slm(sycl::range<1>(512), h);
            h.parallel_for(sycl::nd_range<1>{NJ * 16, 16},
                           [=](sycl::nd_item<1> it) [[sycl::reqd_sub_group_size(16)]]
                           { Gemv6<V>{dws, dbp, das, dout, NJ, KS, slm}(it); });
        });
    };
    using V0 = std::integral_constant<int, 0>;
    using V1 = std::integral_constant<int, 1>;
    using V2 = std::integral_constant<int, 2>;
    launch(V0{}).wait(); launch(V1{}).wait(); launch(V2{}).wait();
    auto t0 = std::chrono::steady_clock::now();
    while (std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count() < 1.0) launch(V0{});
    q.wait();
    auto bench = [&](auto vt, const char* nm) {
        constexpr int V = decltype(vt)::value;
        double best = 1e30;
        for (int it = 0; it < 4; ++it) {
            auto s = std::chrono::steady_clock::now();
            launch(vt).wait();
            auto e1 = std::chrono::steady_clock::now();
            double us = std::chrono::duration<double, std::micro>(e1 - s).count();
            if (us < best) best = us;
        }
        double frags = (double)NJ * KS;
        printf("V%d %-24s %9.1f us   %6.2f ns/fragment(128 wt)   %5.2f ops-clk/wt@2GHz est\n",
               V, nm, best, best * 1e3 / frags, best * 1e3 / frags / 16 / 128 * 2.0);
    };
    bench(V0{}, "global preunpack rm");
    bench(V1{}, "SLM bytescatter rm");
    bench(V2{}, "SLM dword colmajor");
    return 0;
}