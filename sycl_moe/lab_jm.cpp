// lab_jm: joint_matrix int8 fragment correctness in plain SYCL (bench.cpp style).
// Geometry = our mul1 DPAS fragment: A s8 M8xK32 row-major global, B u8 K32xN16 row-major
// global, acc i32 M8xN16. Random data, host reference C[r][c] = sum_k A[r][k]*B[k][c].
// Then a throughput pass to locate XMX headroom for the MoE gemm shapes.
#include <sycl/sycl.hpp>
#include <cstdio>
#include <vector>
#include <cmath>
#include <random>
#include <chrono>

namespace mx = sycl::ext::oneapi::experimental::matrix;
constexpr int MM = 8, NN = 16, KK = 32;

class Frag {};
void one_fragment(sycl::queue& q, const signed char* dA, const unsigned char* dB, int* dC) {
    q.parallel_for(sycl::nd_range<1>{16, 16},
                   [=](sycl::nd_item<1> it) [[sycl::reqd_sub_group_size(16)]] {
        sycl::sub_group sg = it.get_sub_group();
        mx::joint_matrix<sycl::sub_group, signed char, mx::use::a, MM, KK, mx::layout::row_major> a;
        mx::joint_matrix<sycl::sub_group, unsigned char, mx::use::b, KK, NN, mx::layout::row_major> b;
        mx::joint_matrix<sycl::sub_group, int, mx::use::accumulator, MM, NN> c;
        auto pa = sycl::address_space_cast<sycl::access::address_space::global_space,
                                           sycl::access::decorated::yes>(dA);
        auto pb = sycl::address_space_cast<sycl::access::address_space::global_space,
                                           sycl::access::decorated::yes>(dB);
        mx::joint_matrix_load(sg, a, pa, KK);
        mx::joint_matrix_load(sg, b, pb, NN);
        mx::joint_matrix_fill(sg, c, 0);
        mx::joint_matrix_mad(sg, c, a, b, c);
        auto pc = sycl::address_space_cast<sycl::access::address_space::global_space,
                                           sycl::access::decorated::yes>(dC);
        mx::joint_matrix_store(sg, c, pc, NN, mx::layout::row_major);
    }).wait();
}

// many independent fragments (one SG each) - the production pattern
class ManyFrag {};
void many_fragments(sycl::queue& q, signed char* dA, unsigned char* dB, int* dC, int nf) {
    q.parallel_for(sycl::nd_range<1>{nf * 16, 16},
                   [=](sycl::nd_item<1> it) [[sycl::reqd_sub_group_size(16)]] {
        int f = (int)it.get_group(0);
        sycl::sub_group sg = it.get_sub_group();
        mx::joint_matrix<sycl::sub_group, signed char, mx::use::a, MM, KK, mx::layout::row_major> a;
        mx::joint_matrix<sycl::sub_group, unsigned char, mx::use::b, KK, NN, mx::layout::row_major> b;
        mx::joint_matrix<sycl::sub_group, int, mx::use::accumulator, MM, NN> c;
        auto pa = sycl::address_space_cast<sycl::access::address_space::global_space,
                                           sycl::access::decorated::yes>(dA + (size_t)f * MM * KK);
        auto pb = sycl::address_space_cast<sycl::access::address_space::global_space,
                                           sycl::access::decorated::yes>(dB + (size_t)f * KK * NN);
        mx::joint_matrix_load(sg, a, pa, KK);
        mx::joint_matrix_load(sg, b, pb, NN);
        mx::joint_matrix_fill(sg, c, 0);
        mx::joint_matrix_mad(sg, c, a, b, c);
        auto pc = sycl::address_space_cast<sycl::access::address_space::global_space,
                                           sycl::access::decorated::yes>(dC + (size_t)f * MM * NN);
        mx::joint_matrix_store(sg, c, pc, NN, mx::layout::row_major);
    }).wait();
}

int main() {
    sycl::queue q{sycl::gpu_selector_v};
    printf("device: %s\n", q.get_device().get_info<sycl::info::device::name>().c_str());
    std::mt19937 rng(42);
    std::vector<signed char> hA(MM * KK);
    std::vector<unsigned char> hB(KK * NN);
    for (auto& v : hA) v = (signed char)(rng() % 201 - 100);
    for (auto& v : hB) v = (unsigned char)(rng() % 251);
    signed char* dA = sycl::malloc_device<signed char>(MM * KK, q);
    unsigned char* dB = sycl::malloc_device<unsigned char>(KK * NN, q);
    int* dC = sycl::malloc_device<int>(MM * NN, q);
    q.copy(hA.data(), dA, hA.size());
    q.copy(hB.data(), dB, hB.size());
    q.wait();

    one_fragment(q, dA, dB, dC);
    std::vector<int> hC(MM * NN);
    q.copy(dC, hC.data(), hC.size()); q.wait();
    int bad = 0;
    for (int r = 0; r < MM; ++r) for (int c = 0; c < NN; ++c) {
        long e = 0;
        for (int k = 0; k < KK; ++k) e += (long)hA[r * KK + k] * (long)hB[k * NN + c];
        if (hC[r * NN + c] != (int)e) {
            if (bad < 6) printf("  (%d,%d) got %d want %ld\n", r, c, hC[r * NN + c], e);
            bad++;
        }
    }
    printf("joint_matrix int8 fragment: %s (%d/%d bad)\n", bad ? "MAP DIFFERS" : "PASS", bad, MM * NN);

    // throughput: production-sized batch of fragments (2.05 model gate/up per layer:
    // 64 chunks x (640/16 nfrag) x (2560/32 kfrag) ~= 40960 frags for GU alone)
    const int NF = 65536;
    std::vector<signed char> bA((size_t)NF * MM * KK);
    std::vector<unsigned char> bB((size_t)NF * KK * NN);
    for (auto& v : bA) v = (signed char)(rng() % 201 - 100);
    for (auto& v : bB) v = (unsigned char)(rng() % 251);
    signed char* fA = sycl::malloc_device<signed char>(bA.size(), q);
    unsigned char* fB = sycl::malloc_device<unsigned char>(bB.size(), q);
    int* fC = sycl::malloc_device<int>((size_t)NF * MM * NN, q);
    q.copy(bA.data(), fA, bA.size()); q.copy(bB.data(), fB, bB.size()); q.wait();
    many_fragments(q, fA, fB, fC, NF);
    // burn-in for clocks
    auto t0 = std::chrono::steady_clock::now();
    while (std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count() < 1.0)
        many_fragments(q, fA, fB, fC, NF);
    double best = 1e30;
    for (int it = 0; it < 5; ++it) {
        auto s = std::chrono::steady_clock::now();
        q.parallel_for(sycl::nd_range<1>{NF * 16, 16},
                       [=](sycl::nd_item<1> i) [[sycl::reqd_sub_group_size(16)]] {}).wait();
        (void)s;
        s = std::chrono::steady_clock::now();
        many_fragments(q, fA, fB, fC, NF);
        auto e1 = std::chrono::steady_clock::now();
        double us = std::chrono::duration<double, std::micro>(e1 - s).count();
        if (us < best) best = us;
    }
    double macs = (double)NF * MM * NN * KK;
    double bytes = ((double)NF * (MM * KK + KK * NN) + NF * MM * NN * 4.0);
    printf("many-frag: %.1f us -> %.1f TMAC/s int8 (%.2f%% of 367 TOPS peak), %.0f GB/s operand traffic\n",
           best, macs / best / 1e6, 100.0 * 2 * macs / best / 367e9, bytes / best / 1e3);
    return 0;
}