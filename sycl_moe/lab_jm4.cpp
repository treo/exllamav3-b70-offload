// lab_jm4: sustained int8 joint_matrix gemv inner loop vs production float-gemv shapes.
// Per SG: one (chunk j, n-fragment c16) pair; loop k in 32-weight steps:
//   lanes unpack their 8 product words (2 states per u32 word -> 4 word-loads),
//   store 8xu32 to SLM (col-major B), jm_load B/A, mad. One C store at the end.
// Decode shape (2.05 model): nc=120 chunks, H=2560 -> ksteps 80, GU nfrags 40 (I 640).
// Reports us/job and effective GB/s of packed-weight streaming (0.5 B/weight read).
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

struct GemvInt8
{
    const u32* __restrict__ wsf;   // [chunk][kstep][16c][4] packed states (2 u16/u32)
    const signed char* __restrict__ a8; // [chunk][kstep][8][32] replicated x8
    int* __restrict__ out;         // [chunk][nfrag][8][16]
    int nchunks, ksteps, nfl;
    sycl::local_accessor<unsigned char, 1> slab;
    int mode;
    static constexpr int MODE_FULL = 0, MODE_NOBAR = 1, MODE_NOJM = 2, MODE_NOUNPACK = 3;
    void operator()(sycl::nd_item<1> it) const
    {
        sycl::sub_group sg = it.get_sub_group();
        const int lane = (int)sg.get_local_linear_id();
        const int jobn = nchunks * nfl;
        for (int job = (int)it.get_group(0); job < jobn; job += (int)it.get_group_range(0)) {
            const int j = job / nfl, nf = job % nfl;
            const u32* wf = wsf + (size_t)j * ksteps * 64 + (size_t)nf * 0;  // nf: col block
            const signed char* af = a8 + (size_t)j * ksteps * MM * KK;
            unsigned char* sl = slab.get_pointer().get();
            mx::joint_matrix<sycl::sub_group, signed char, mx::use::a, MM, KK, mx::layout::row_major> a;
            mx::joint_matrix<sycl::sub_group, unsigned char, mx::use::b, KK, NN, mx::layout::col_major> b;
            mx::joint_matrix<sycl::sub_group, int, mx::use::accumulator, MM, NN> c;
            mx::joint_matrix_fill(sg, c, 0);
            const int wq = lane >> 1, cb = (lane & 1) * 8;
            for (int ks = 0; ks < ksteps; ++ks) {
                // lane stages cols cb..cb+7 (within this nf's 16 cols: offset cb), wq
                const u32* w0 = wf + (size_t)ks * 64;
                if (mode != MODE_NOUNPACK) {
#pragma unroll
                    for (int jj = 0; jj < 8; ++jj) {
                        int c = cb + jj;
                        u32 st = w0[c * 4 + (wq >> 1)];
                        u16 s16 = (wq & 1) ? (u16)(st >> 16) : (u16)st;
                        *(u32*)&sl[c * 32 + wq * 4] = (u32)s16 * MUL1;
                    }
                }
                if (mode != MODE_NOBAR) sg.barrier();
                if (mode == MODE_NOJM) {   // scalar stand-in accumulation
                    int acc = 0;
#pragma unroll
                    for (int i = 0; i < 32; ++i) acc += sl[i] + (int)af[(size_t)ks * MM * KK + i];
                    if (acc == 0x7f5f3f) out[0] = acc;
                    continue;
                }
                auto pa = sycl::address_space_cast<sycl::access::address_space::global_space,
                                                   sycl::access::decorated::yes>(af + (size_t)ks * MM * KK);
                auto pb = sycl::address_space_cast<sycl::access::address_space::local_space,
                                                   sycl::access::decorated::yes>(sl);
                mx::joint_matrix_load(sg, a, pa, KK);
                mx::joint_matrix_load(sg, b, pb, KK);
                mx::joint_matrix_mad(sg, c, a, b, c);
                if (mode == MODE_FULL) sg.barrier();   // protect slab from next write
            }
            auto pc = sycl::address_space_cast<sycl::access::address_space::global_space,
                                               sycl::access::decorated::yes>(
                out + (size_t)job * MM * NN);
            mx::joint_matrix_store(sg, c, pc, NN, mx::layout::row_major);
        }
    }
};

template <int MODE>
class GemvK;   // fwd for naming
int main() {
    sycl::queue q{sycl::gpu_selector_v};
    printf("device: %s\n", q.get_device().get_info<sycl::info::device::name>().c_str());
    const int NC = 120, KS = 320, NFL = 40;   // KS = H/8: each k-step consumes 8 real
                                              // weight rows (kd32 = 4 bytes/weight trick)
    std::mt19937 rng(5);
    std::vector<u32> ws((size_t)NC * KS * 64);
    std::vector<signed char> as((size_t)NC * KS * MM * KK);
    for (auto& v : ws) v = (u32)((rng() & 0xffff) | ((rng() & 0xffff) << 16));
    for (auto& v : as) v = (signed char)(rng() % 255 - 127);
    u32* dws = sycl::malloc_device<u32>(ws.size(), q);
    signed char* das = sycl::malloc_device<signed char>(as.size(), q);
    int* dout = sycl::malloc_device<int>((size_t)NC * NFL * MM * NN, q);
    q.copy(ws.data(), dws, ws.size()); q.copy(as.data(), das, as.size()); q.wait();
    printf("weights packed %.1f MB\n", ws.size() * 4.0 / 1e6);

    const int G = 2048 / 16;   // 2048 SGs
    auto launch = [&](int mode) {
        return q.submit([&](sycl::handler& h) {
            sycl::local_accessor<unsigned char, 1> slm(sycl::range<1>(512), h);
            h.parallel_for(sycl::nd_range<1>{G * 16, 16},
                           [=](sycl::nd_item<1> it) [[sycl::reqd_sub_group_size(16)]] {
                if (mode == 0) GemvInt8{dws, das, dout, NC, KS, NFL, slm, 0}(it);
                if (mode == 1) GemvInt8{dws, das, dout, NC, KS, NFL, slm, 1}(it);
                if (mode == 2) GemvInt8{dws, das, dout, NC, KS, NFL, slm, 2}(it);
                if (mode == 3) GemvInt8{dws, das, dout, NC, KS, NFL, slm, 3}(it);
                           });
        });
    };
    launch(0).wait();
    // spot-check one job against scalar
    {
        std::vector<int> hc(MM * NN);
        q.copy(dout + (size_t)(NC * NFL - 1) * MM * NN, hc.data(), hc.size()); q.wait();
        int job = NC * NFL - 1, j = job / NFL, nf = job % NFL;
        long e = 0; int r = 3, cc = 5;
        for (int ks = 0; ks < KS; ++ks) {
            int c16 = nf * 16 + 5;
            const u32* w0 = &ws[((size_t)j * KS + ks) * 64];
            for (int wq = 0; wq < 8; ++wq) {
                u32 st = w0[(5) * 4 + (wq >> 1)];   // local col 5 within the fragment
                u16 s16 = (wq & 1) ? (u16)(st >> 16) : (u16)st;
                u32 prod = (u32)s16 * MUL1;
                int bs = (int)((prod & 0xff) + ((prod >> 8) & 0xff) + ((prod >> 16) & 0xff) + (prod >> 24));
                e += (long)bs * as[((size_t)j * KS + ks) * MM * KK + r * KK + wq * 4];
            }
        }
        printf("spotcheck job(r3,c5): got %d want %ld  %s\n", hc[3 * NN + 5], e,
               hc[3 * NN + 5] == (int)e ? "OK" : "MISMATCH");
    }
    int* dout_mode = dout;
    (void)dout_mode;
    auto t0 = std::chrono::steady_clock::now();
    while (std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count() < 1.2) launch(0);
    q.wait();
    const char* nm[4] = {"full", "no-post-bar", "no-jm(scalar)", "no-unpack"};
    for (int md = 0; md < 4; ++md) {
        double best = 1e30;
        for (int it = 0; it < 6; ++it) {
            auto s = std::chrono::steady_clock::now();
            launch(md).wait();
            auto e1 = std::chrono::steady_clock::now();
            double us = std::chrono::duration<double, std::micro>(e1 - s).count();
            if (us < best) best = us;
        }
        double wbytes = (double)ws.size() * 4.0;
        double ab = (double)as.size();
        printf("mode %-14s %8.1f us  (%3.0f GB/s eff)\n", nm[md], best, (wbytes + ab) / best / 1e3);
    }
    return 0;
}