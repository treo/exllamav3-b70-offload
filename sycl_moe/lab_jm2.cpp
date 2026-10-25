// lab_jm2: recover the slot<->(lane,raw-byte) mapping of joint_matrix B fragments so the
// mul1 int8 tier can fill B from registers (unpack in-lane, no global int8 roundtrip).
// Method: A = 1 (via jm_load from global s8 ones). B filled ONLY through get_x raw bytes
// with stamps, twice: (i) byte value = lane+1  (ii) byte value = t+1 (index within raw).
// C[r][c] = sum over the 32 logical B bytes (k,c) of the stamp -> per-launch fingerprints
// reveal which (lane,t) bytes land in which (k,c) slots. Then random-data numeric check.
#include <sycl/sycl.hpp>
#include <cstdio>
#include <vector>
#include <random>

namespace mx = sycl::ext::oneapi::experimental::matrix;
constexpr int MM = 8, NN = 16, KK = 32;

template <int STAMP>
struct StampB
{
    const signed char* one;    // global 8x32 of value 1 for A
    int* out;                  // C 8x16
    void operator()(sycl::nd_item<1> it) const
    {
        sycl::sub_group sg = it.get_sub_group();
        const int lane = (int)sg.get_local_linear_id();
        mx::joint_matrix<sycl::sub_group, signed char, mx::use::a, MM, KK, mx::layout::row_major> a;
        mx::joint_matrix<sycl::sub_group, unsigned char, mx::use::b, KK, NN, mx::layout::row_major> b;
        mx::joint_matrix<sycl::sub_group, int, mx::use::accumulator, MM, NN> c;
        auto pa = sycl::address_space_cast<sycl::access::address_space::global_space,
                                           sycl::access::decorated::yes>(one);
        mx::joint_matrix_load(sg, a, pa, KK);
        auto br = b.get_x();
        using BT = decltype(br);
        auto bb = br.template bit_cast_view<unsigned char>();
#pragma unroll
        for (int t = 0; t < (int)bb.size(); ++t)
            bb[t] = (STAMP == 0) ? (unsigned char)(lane + 1) : (unsigned char)(t + 1);
        b.store(bb);   // if no store() exists, need different route -- compile will tell us
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
    signed char* dA = sycl::malloc_device<signed char>(MM * KK, q);
    int* dC = sycl::malloc_device<int>(MM * NN, q);
    std::vector<signed char> ones(MM * KK, 1);
    q.copy(ones.data(), dA, ones.size()); q.wait();

    q.parallel_for(sycl::nd_range<1>{16, 16}, StampB<0>{dA, dC}); q.wait();
    std::vector<int> h0(MM * NN);
    q.copy(dC, h0.data(), h0.size()); q.wait();
    q.parallel_for(sycl::nd_range<1>{16, 16}, StampB<1>{dA, dC}); q.wait();
    std::vector<int> h1(MM * NN);
    q.copy(dC, h1.data(), h0.size()); q.wait();

    printf("row0 stamps (lane-id sum, tsum) per col:\n  col:");
    for (int c = 0; c < NN; ++c) printf(" %4d", c);
    printf("\n  Ln:");
    for (int c = 0; c < NN; ++c) printf(" %4d", h0[c]);
    printf("\n  T :");
    for (int c = 0; c < NN; ++c) printf(" %4d", h1[c]);
    printf("\n(rows should repeat: A=1 => all rows identical)\n");
    int rowsame = 1;
    for (int r = 1; r < MM; ++r) for (int c = 0; c < NN; ++c)
        if (h0[r * NN + c] != h0[c] || h1[r * NN + c] != h1[c]) rowsame = 0;
    printf("rows identical: %s\n", rowsame ? "yes" : "no");
    return 0;
}