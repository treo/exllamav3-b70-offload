// -----------------------------------------------------------------------------
// probe_shapes.cpp - which joint_matrix shapes does the B70 backend actually accept?
//
// *** KNOWN-INVALID INSTRUMENT - DO NOT TRUST ITS NEGATIVES. ***
// It reports "M=8, N=16, K=8 is not supported on this device", and that is the shape probe_dpas3 runs
// successfully every time it is executed. Whatever it rejects may be a property of this file's construction
// rather than of the device. The only result here that survives cross-checking is M=8, N=16, K=32, which
// matches the vendor bench's int8 shape (bench.cpp run_matrix<int8_t,int32_t,8,16,32>, 366.92 of 367 TOPS).
// Shape questions must be answered by editing probe_dpas3 (a kernel with a passing bit-exactness gate) and
// observing whether it launches. See LESSONS 40: calibrate an oracle on a case you already know passes.
//
// Motivation: narrowing the DPAS token dimension (rev F's NTOK=16 -> 8) compiles but throws at launch,
//   "joint_matrix with parameters matrix_type::sint32, use::accumulator, Rows=8, Cols=8 is not supported
//    on this device"
// - a RUNTIME rejection, with no static_assert and no table in the headers to read, so the legal set is
// only knowable by trial. Whether narrow N is unusable in general, or just narrow N with narrow M, decides
// two open questions at once: (1) can a compile-time single-row DPAS variant exist at all, and (2) is the
// M=16 consolidation (two 8x16 accumulators -> one 16x16, halving the mad stream) expressible?
// It also prices the K dimension: mads per tile = (output columns / M) * (K bytes / K per mad), so a K
// wider than 8 would cut instructions the same way M does, and at rows=1 that is the whole ball game.
//
// Each shape is checked numerically, not just for a successful launch, using the vendor bench's
// reference-free invariant: A = u8 ones, B = s8 ones => every C element must equal K. A shape that
// "supports" itself but computes something else is worse than one that refuses.
//
// Build: icpx -fsycl -O2 -o probe_shapes probe_shapes.cpp
// Run:   ./probe_shapes
// -----------------------------------------------------------------------------
#include <cstdint>
#include <cstdio>
#include <string>
#include <vector>
#include <sycl/sycl.hpp>
#include <sycl/ext/oneapi/matrix/matrix.hpp>

namespace mx = sycl::ext::oneapi::experimental::matrix;

template <int M, int N, int K>
static bool attempt()
{
    sycl::queue q{sycl::gpu_selector_v};
    // Operands come from memory, not joint_matrix_fill: fill itself has shape restrictions, and a probe
    // that uses it reports "unsupported" even for the shape rev F runs every day. Loads are how real
    // kernels materialize operands, so that is what capability has to be tested through.
    std::vector<uint8_t> hA((size_t)M * K, 1);
    std::vector<int8_t> hB((size_t)K * N, 1);
    uint8_t *A = (uint8_t *)sycl::malloc_device(hA.size(), q);
    int8_t *B = (int8_t *)sycl::malloc_device(hB.size(), q);
    int32_t *out = (int32_t *)sycl::malloc_device((size_t)M * N * 4, q);
    q.memcpy(A, hA.data(), hA.size());
    q.memcpy(B, hB.data(), hB.size());
    q.wait();
    bool rejected = false;
    std::string err;
    try
    {
        q.submit([&](sycl::handler &cgh)
        {
            cgh.parallel_for(sycl::nd_range<1>(sycl::range<1>(16), sycl::range<1>(16)),
                             [=](sycl::nd_item<1> it) [[sycl::reqd_sub_group_size(16)]]
                             {
                                 const sycl::sub_group sg = it.get_sub_group();
                                 mx::joint_matrix<sycl::sub_group, uint8_t, mx::use::a, M, K,
                                                  mx::layout::row_major> a;
                                 mx::joint_matrix<sycl::sub_group, int8_t, mx::use::b, K, N,
                                                  mx::layout::row_major> b;
                                 mx::joint_matrix<sycl::sub_group, int32_t, mx::use::accumulator, M, N> c;
                                 mx::joint_matrix_load(
                                     sg, a,
                                     sycl::address_space_cast<sycl::access::address_space::global_space,
                                                              sycl::access::decorated::no>(A),
                                     K);
                                 mx::joint_matrix_load(
                                     sg, b,
                                     sycl::address_space_cast<sycl::access::address_space::global_space,
                                                              sycl::access::decorated::no>(B),
                                     N);
                                 mx::joint_matrix_fill(sg, c, int32_t(0));
                                 mx::joint_matrix_mad(sg, c, a, b, c);
                                 mx::joint_matrix_store(
                                     sg, c,
                                     sycl::address_space_cast<sycl::access::address_space::global_space,
                                                              sycl::access::decorated::no>(out),
                                     N, mx::layout::row_major);
                             });
        });
        q.wait();
    }
    catch (const sycl::exception &e)
    {
        rejected = true;
        err = e.what();
    }
    if (rejected)
    {
        printf("  M=%-3d N=%-3d K=%-3d  REJECTED  %s\n", M, N, K, err.substr(0, 74).c_str());
        sycl::free(A, q); sycl::free(B, q); sycl::free(out, q);
        return false;
    }
    std::vector<int32_t> h((size_t)M * N, -1);
    q.memcpy(h.data(), out, (size_t)M * N * 4).wait();
    int bad = 0, first = 0;
    for (int i = 0; i < M * N; ++i)
        if (h[i] != K)
        {
            if (!bad) first = h[i];
            ++bad;
        }
    if (!bad)
        printf("  M=%-3d N=%-3d K=%-3d  ok  (every C element == K = %d)\n", M, N, K, K);
    else
        printf("  M=%-3d N=%-3d K=%-3d  LAUNCHED BUT WRONG: %d of %d differ (e.g. %d != %d)\n",
               M, N, K, bad, M * N, first, K);
    sycl::free(A, q); sycl::free(B, q); sycl::free(out, q);
    return !bad;
}

int main()
{
    sycl::queue q{sycl::gpu_selector_v};
    printf("device: %s\n\nA = u8 row_major MxK, B = s8 row_major KxN, C = s32 accumulator MxN\n",
           q.get_device().get_info<sycl::info::device::name>().c_str());
    printf("rev F runs M=8, N=16, K=8 today; the NTOK=8 rejection was M=8, N=8\n\n");
    printf("operands loaded from global (fill has its own shape limits), A=u8 ones, B=s8 ones, so C must be K\n\n");
    attempt<8, 16, 8>();
    attempt<8, 8, 8>();
    attempt<8, 4, 8>();
    attempt<8, 1, 8>();    // the compile-time single-row operand the question is about
    attempt<16, 16, 8>();  // the M consolidation
    attempt<16, 8, 8>();   // narrow N with full M: does accumulator area decide legality?
    attempt<16, 4, 8>();
    attempt<16, 1, 8>();
    attempt<4, 16, 8>();
    attempt<32, 16, 8>();
    printf("\nK sweep - a wider K per mad is the other way to cut instructions:\n");
    attempt<8, 16, 16>();
    attempt<8, 16, 32>();
    attempt<16, 16, 16>();
    attempt<16, 16, 32>();
    attempt<16, 8, 32>();
    return 0;
}