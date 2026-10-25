// lab_dpas: discover/verify the ESIMD XMX dpas operand layouts for the mul1 int8 tier.
// Strategy: feed A and B operand bytes with ordinal-tagged values, run one dpas per SG,
// dump C; host decodes which (row,k) of A and (k,col) of B reach each output lane/j.
//   run X: A byte = (k+1) + 1000*r  (r,k from assumed row-major ordinal), B bytes = 1
//   run Y: A bytes = 1, B byte = (k+1) + 1000*c (assumed layout per spec guess: k-inner)
// If the assumed ordinals are wrong, the recovered (r,c,ksets) still identify the mapping
// because outputs are addressed by (lane, j) directly.
// build: icpx -fsycl -O3 lab_dpas.cpp -o lab_dpas
#include <sycl/sycl.hpp>
#include <sycl/ext/intel/esimd.hpp>
#include <cstdio>
#include <vector>

using namespace sycl;
using namespace sycl::ext::intel::esimd;
using namespace sycl::ext::intel::esimd::xmx;

// rd=8 rows, rc=8 cols, kd=32 k (u8/s8). SG16: per lane A=4 u32 (16 bytes), B=4 u32, C=4 i32.
// (whole-SG totals: A 8x32=256 s8, B 32x8=256 u8, C 8x8=64 i32 -> 4/lane)
class KDpasX {};
void run_x(queue& q, int* c_out, const unsigned char* a_bytes /*256*/, const unsigned char* b_bytes /*256*/) {
    q.parallel_for(nd_range<1>{{16}, {16}}, [=] __ESIMD_EN {
        int lane = esimd::lane_id();
        // per-lane operand slices from global (row-major ordinal order defined by caller)
        simd<uint32_t, 4> a;
        simd<uint32_t, 4> b;
        const uint32_t* a32 = (const uint32_t*)a_bytes + lane * 4;   // 16 bytes / lane
        const uint32_t* b32 = (const uint32_t*)b_bytes + lane * 4;
        for (int i = 0; i < 4; ++i) { a[i] = a32[i]; b[i] = b32[i]; }
        simd<int32_t, 4> c(0);
        c = dpas<8, 8, int32_t>(c, b, a);
        int* dst = c_out + lane * 4;
        for (int i = 0; i < 4; ++i) dst[i] = c[i];
    }).wait();
}

int main() {
    queue q{gpu_selector_v};
    printf("device: %s\n", q.get_device().get_info<sycl::info::device::name>().c_str());
    int* cbuf = malloc_shared<int>(64, q);

    // ---- run X: A tagged by (assumed r,k), B = 1 ----
    {
        std::vector<unsigned char> A(256), B(256, 1);
        for (int o = 0; o < 256; ++o) { int r = o / 32, k = o % 32; A[o] = (k + 1) + 1000 * r; }
        q.copy(A.data(), cbuf + 64, 256); // dummy? no: need device bufs
    }
    // proper: device buffers for operands
    unsigned char* da = malloc_device<unsigned char>(256, q);
    unsigned char* db = malloc_device<unsigned char>(256, q);
    {
        std::vector<unsigned char> A(256), B(256, 1);
        for (int o = 0; o < 256; ++o) { int r = o / 32, k = o % 32; A[o] = (unsigned char)((k + 1) + 1000 * r); }
        // NOTE byte values >255 truncated! Use a scheme that fits s8: k+1 (1..32 -> ok), r*1000 no.
        // Revised: value = (k+1) + 32*r  (r<8 => max 32+255 fits u8)
        for (int o = 0; o < 256; ++o) { int r = o / 32, k = o % 32; A[o] = (unsigned char)((k + 1) + 32 * r); }
        q.memset(da, 0, 256);
        q.copy(A.data(), da, 256);
        q.copy(B.data(), db, 256).wait();
        q.parallel_for(nd_range<1>{{16}, {16}}, [=] __ESIMD_EN {
            int lane = esimd::lane_id();
            simd<uint32_t, 4> a, b;
            const uint32_t* a32 = (const uint32_t*)(da + lane * 16);
            const uint32_t* b32 = (const uint32_t*)(db + lane * 16);
            for (int i = 0; i < 4; ++i) { a[i] = a32[i]; b[i] = b32[i]; }
            simd<int32_t, 4> c(0);
            c = dpas<8, 8, int32_t>(c, b, a);
            for (int i = 0; i < 4; ++i) cbuf[lane * 4 + i] = c[i];
        }).wait();
        printf("run X (A=(k+1)+32r, B=1): C[i] mod 32 -> k-slot sum/32 -> row\n");
        for (int l = 0; l < 16; ++l) {
            printf(" lane %2d:", l);
            for (int j = 0; j < 4; ++j) {
                int v = cbuf[l * 4 + j];
                printf(" [%d]=%d(r%d,ksum%d)", j, v, v / 32, v % 32);
            }
            printf("\n");
        }
    }
    // ---- run Y: A = 1, B tagged by assumed (k,c): B ordinal = c*32 + k (k inner per column) ----
    {
        std::vector<unsigned char> A(256, 1), B(256);
        for (int o = 0; o < 256; ++o) { int c = o / 32, k = o % 32; B[o] = (unsigned char)((k + 1) + 32 * c); }
        q.memset(da, 1, 256);
        q.copy(B.data(), db, 256).wait();
        q.parallel_for(nd_range<1>{{16}, {16}}, [=] __ESIMD_EN {
            int lane = esimd::lane_id();
            simd<uint32_t, 4> a, b;
            const uint32_t* a32 = (const uint32_t*)(da + lane * 16);
            const uint32_t* b32 = (const uint32_t*)(db + lane * 16);
            for (int i = 0; i < 4; ++i) { a[i] = a32[i]; b[i] = b32[i]; }
            simd<int32_t, 4> c(0);
            c = dpas<8, 8, int32_t>(c, b, a);
            for (int i = 0; i < 4; ++i) cbuf[lane * 4 + i] = c[i];
        }).wait();
        printf("run Y (A=1, B=(k+1)+32c ordinal=c*32+k): B column checksums\n");
        for (int l = 0; l < 16; ++l) {
            printf(" lane %2d:", l);
            for (int j = 0; j < 4; ++j) {
                int v = cbuf[l * 4 + j];
                printf(" [%d]=%d(c%d,ksum%d)", j, v, v / 32, v % 32);
            }
            printf("\n");
        }
    }
    return 0;
}