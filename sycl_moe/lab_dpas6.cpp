// lab_dpas6: raw __esimd_dpas2 with PER-LANE operand slices (Triton-style distributed dpas).
// template <BPrecision, APrecision, SystolicDepth, RepeatCount, RawT, CRawT, MsgT1, MsgT2,
//           N (C ints/lane), BNCasted (B ints/lane), ANCasted (A ints/lane)>
// dpas2(C.data(), B.data(), A.data())
// Probe: SG16, rd8 rc8, u8/s8 (kd32): C = 64/16 = 4 i32/lane; B = 512B/16 = 8 i32/lane;
// A = 256B/16 = 4 i32/lane. Discover ownership: each lane stamps (lane+1) into ALL its A/B
// slots -> C tells which matrix positions its registers feed.
#include <sycl/sycl.hpp>
#include <sycl/ext/intel/esimd.hpp>
#include <sycl/ext/intel/experimental/esimd/math.hpp>
#include <cstdio>
#include <vector>
#include <cmath>
#include <cstring>

using namespace sycl;
namespace esimd = sycl::ext::intel::esimd;
namespace edns = sycl::ext::intel::experimental::esimd;
using u32 = uint32_t;

static constexpr int RD = 8, RC = 8;   // kd32 auto for 8-bit

struct RawDpas
{
    unsigned char* dbg;   // [512] stamp decode output aid (unused initially)
    float* out;           // C 128
    auto get(sycl::ext::oneapi::experimental::properties_tag) const {
        return sycl::ext::oneapi::experimental::properties{
            sycl::ext::oneapi::experimental::sub_group_size<16>};
    }
    void operator()(item<1> itm) const {
        const int lane = (int)itm.get_id() & 15;
        // stamp: A slot ints: byte value = lane+1; B bytes: (lane+1)*8 packed  (avoid collide)
        esimd::simd<int, 4> A;
        esimd::simd<int, 8> B;
        esimd::simd<int, 4> C(0);
        unsigned ab = (unsigned)((lane + 1) & 0xff);
        unsigned bb = (unsigned)((((lane + 1) * 7) & 0x3f) + 1);   // <64 keeps sums small
#pragma unroll
        for (int j = 0; j < 4; ++j) A[j] = (int)(ab * 0x01010101u);
#pragma unroll
        for (int j = 0; j < 8; ++j) B[j] = (int)(bb * 0x01010101u);
        C = edns::detail::__esimd_dpas2<edns::detail::dpas_argument_type::u8,
                                        edns::detail::dpas_argument_type::s8,
                                        RD, RC, int, int, int, int, 4, 8, 4>(
                C.data(), B.data(), A.data());
        // dump: lane L writes its C to out[L*4 .. L*4+4) DIRECT (no cross-lane reads!)
#pragma unroll
        for (int j = 0; j < 4; ++j) out[lane * 4 + j] = (float)C[j];
    }
};

int main() {
    queue q{gpu_selector_v};
    printf("device: %s\n", q.get_device().get_info<sycl::info::device::name>().c_str());
    float* dout = malloc_device<float>(64, q);
    unsigned char* dbg = malloc_device<unsigned char>(512, q);
    q.memset(dout, 0, 64 * 4);
    try {
        q.parallel_for(range<1>{16}, RawDpas{dbg, dout}).wait();
        std::vector<float> h(64);
        q.copy(dout, h.data(), 64); q.wait();
        printf("lane C (stamp a=lane+1, b=7(lane+1)+?): \n");
        for (int L = 0; L < 16; ++L)
            printf(" L%2d: %8.0f %8.0f %8.0f %8.0f\n", L, h[L * 4], h[L * 4 + 1], h[L * 4 + 2], h[L * 4 + 3]);
        // If per-lane slices work: each lane's C = sum over its own (row,col,k-range):
        // lane L covers (rows subset) x (cols subset) x (k 8?) → value pattern reveals it:
        // pure-A-stamp test: expect C = (#k owned by lane) * a_stamp * b_stamp summed over
        // owned slots only. Non-uniform per-lane values = DISTRIBUTION HAPPENED.
        // All-equal big values = replicated consumption (each lane saw full matrix).
        long full = 0;   // full-matrix replication predicts: C = 32k * (sum lanes a)(sum...)
        for (int o = 0; o < 256; ++o) full += (o % 32 < 32) ? 0 : 0;
        (void)full;
    } catch (std::exception& e) { printf("EXCEPTION %s\n", e.what()); }
    return 0;
}