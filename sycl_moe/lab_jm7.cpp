// lab_jm7: mul1 int8 gemv via joint_matrix with B in ext_intel_packed (VNNI) layout.
// Packed 8-bit rule (sycl_ext_intel_matrix doc + test-e2e/Matrix/joint_matrix_su_int8):
//   packed addr(logical k, c) = (k>>2)*(N*4) + c*4 + (k&3)  bytes; stride = N*4.
//   In u32 units: word(k, c) = slab32[(k>>2)*N + c]  -- ONE dword store per product word!
// Fragment: A s8 row-major [8][32] (activations replicated x4 over hw-k), B u8 packed
// [hw-k 32][16 cols], C i32 [8][16]. hw-k 4*wq+db = real weight wq, byte db of product.
//   lane wq = lane>>1, cols = 8*(lane&1) + 0..7  (own slice for staging; staging pattern
//   is free: any lane may write any word; only final memory layout matters).
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

struct PackGemm
{
    const u32* __restrict__ wsf;     // [job][ks][64] packed states (2 u16 per u32), c-major [c*4+wq/2]
    const signed char* __restrict__ a8;  // [job][ks][8][32] row-major replicated
    int* __restrict__ out;           // [job][8][16]
    int njobs, ksteps;
    sycl::local_accessor<unsigned char, 1> slab;
    void operator()(sycl::nd_item<1> it) const
    {
        sycl::sub_group sg = it.get_sub_group();
        const int lane = (int)sg.get_local_linear_id();
        const size_t job = it.get_group(0);
        const u32* wf = wsf + job * ksteps * 64;
        const signed char* af = a8 + job * ksteps * MM * KK;
        u32* sl32 = (u32*)slab.get_pointer().get();
        mx::joint_matrix<sycl::sub_group, signed char, mx::use::a, MM, KK, mx::layout::row_major> a;
        mx::joint_matrix<sycl::sub_group, unsigned char, mx::use::b, KK, NN,
                         mx::layout::ext_intel_packed> b;
        mx::joint_matrix<sycl::sub_group, int, mx::use::accumulator, MM, NN> c;
        mx::joint_matrix_fill(sg, c, 0);
        const int wq = lane >> 1, cb = (lane & 1) * 8;
        for (int ks = 0; ks < ksteps; ++ks) {
            const u32* w0 = wf + (size_t)ks * 64;
#pragma unroll
            for (int jj = 0; jj < 8; ++jj) {
                int cix = cb + jj;
                u32 st = w0[cix * 4 + (wq >> 1)];
                u16 s16 = (wq & 1) ? (u16)(st >> 16) : (u16)st;
                sl32[wq * NN + cix] = (u32)s16 * MUL1;     // packed dword store
            }
            sg.barrier();
            auto pa = sycl::address_space_cast<sycl::access::address_space::global_space,
                                               sycl::access::decorated::yes>(af + (size_t)ks * MM * KK);
            auto pb = sycl::address_space_cast<sycl::access::address_space::local_space,
                                               sycl::access::decorated::yes>((unsigned char*)sl32);
            mx::joint_matrix_load(sg, a, pa, KK);
            mx::joint_matrix_load(sg, b, pb, NN * 4);      // stride = N*VNNI bytes/elems for u8
            mx::joint_matrix_mad(sg, c, a, b, c);
            sg.barrier();
        }
        auto pc = sycl::address_space_cast<sycl::access::address_space::global_space,
                                           sycl::access::decorated::yes>(out + job * MM * NN);
        mx::joint_matrix_store(sg, c, pc, NN, mx::layout::row_major);
    }
};

int main() {
    sycl::queue q{sycl::gpu_selector_v};
    printf("device: %s\n", q.get_device().get_info<sycl::info::device::name>().c_str());
    const int NJ = 2560, KS = 40;
    std::mt19937 rng(5);
    std::vector<u32> ws((size_t)NJ * KS * 64);
    std::vector<signed char> as((size_t)NJ * KS * MM * KK);
    for (auto& v : ws) v = (u32)((rng() & 0xffff) | ((rng() & 0xffff) << 16));
    for (int j = 0; j < NJ; ++j) for (int ks = 0; ks < KS; ++ks)
        for (int r = 0; r < MM; ++r) for (int wq = 0; wq < 8; ++wq) {
            signed char xv = (signed char)(rng() % 255 - 127);
            for (int dd = 0; dd < 4; ++dd)
                as[((size_t)j * KS + ks) * MM * KK + r * KK + wq * 4 + dd] = xv;
        }
    u32* dws = sycl::malloc_device<u32>(ws.size(), q);
    signed char* das = sycl::malloc_device<signed char>(as.size(), q);
    int* dout = sycl::malloc_device<int>((size_t)NJ * MM * NN, q);
    q.copy(ws.data(), dws, ws.size()); q.copy(as.data(), das, as.size()); q.wait();

    auto launch = [&]() {
        return q.submit([&](sycl::handler& h) {
            sycl::local_accessor<unsigned char, 1> slm(sycl::range<1>(512), h);
            h.parallel_for(sycl::nd_range<1>{NJ * 16, 16},
                           [=](sycl::nd_item<1> it) [[sycl::reqd_sub_group_size(16)]]
                           { PackGemm{dws, das, dout, NJ, KS, slm}(it); });
        });
    };
    launch().wait();
    // scalar reference spot checks on 3 jobs
    std::vector<int> hc((size_t)NJ * MM * NN);
    q.copy(dout, hc.data(), hc.size()); q.wait();
    int bad = 0;
    std::uniform_int_distribution<int> jd(0, NJ - 1);
    for (int t = 0; t < 3; ++t) {
        int j = t == 0 ? 0 : jd(rng);
        for (int r = 0; r < MM; ++r) for (int cc = 0; cc < NN; ++cc) {
            long e = 0;
            for (int ks = 0; ks < KS; ++ks) {
                const u32* w0 = &ws[((size_t)j * KS + ks) * 64];
                const signed char* a0 = &as[((size_t)j * KS + ks) * MM * KK];
                for (int wq = 0; wq < 8; ++wq) {
                    u32 st = w0[cc * 4 + (wq >> 1)];
                    u16 s16 = (wq & 1) ? (u16)(st >> 16) : (u16)st;
                    u32 prod = (u32)s16 * MUL1;
                    int bs = (int)((prod & 0xff) + ((prod >> 8) & 0xff) +
                                   ((prod >> 16) & 0xff) + (prod >> 24));
                    e += (long)bs * a0[r * KK + wq * 4];
                }
            }
            if (hc[(size_t)j * MM * NN + r * NN + cc] != (int)e) {
                if (bad < 6) printf(" j%d r%d c%d got %d want %ld\n", j, r, cc,
                                    hc[(size_t)j * MM * NN + r * NN + cc], e);
                bad++;
            }
        }
    }
    printf("packed-B joint_matrix gemv: %s (%d bad)\n", bad ? "MISMATCH" : "PASS", bad);

    auto t0 = std::chrono::steady_clock::now();
    while (std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count() < 1.0) launch();
    q.wait();
    double best = 1e30;
    for (int it = 0; it < 5; ++it) {
        auto s = std::chrono::steady_clock::now();
        launch().wait();
        auto e1 = std::chrono::steady_clock::now();
        double us = std::chrono::duration<double, std::micro>(e1 - s).count();
        if (us < best) best = us;
    }
    double frags = (double)NJ * KS;
    double wbytes = (double)ws.size() * 4 + (double)as.size();
    printf("packed gemv: %.1f us | %.2f ns/fragment(128 weights) | %.0f GB/s stream\n",
           best, best * 1e3 / frags, wbytes / best / 1e3);
    return 0;
}