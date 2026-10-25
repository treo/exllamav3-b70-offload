// lab_dpas2: discover esimd xmx::dpas rd8/rc8/8bit (kd=32) operand semantics on B70.
// ESIMD "full matrix per call" model: A = simd<signed char, rc*32=256>,
// B = simd<unsigned char, 32*exec=512>, C = simd<int32_t, rc*exec?> -- shapes verified
// by the header's static_asserts at compile time; this lab discovers the runtime layout
// by tagging ordinals:
//   RX:  A[o] = o/32,   B = 1     -> C element = 32 * (A row band feeding it)
//   RY:  A = 1,         B[o]=o/32 -> C element = 32 * (B band feeding it)
//   RZ:  A[o] = o%32+1, B[o]=o%32+1 -> 11440 iff same k order both sides
//   RW:  A[o] = o%32,   B[o] = (o%32)*? per-column k tags
#include <sycl/sycl.hpp>
#include <sycl/ext/intel/esimd.hpp>
#include <cstdio>
#include <vector>
#include <cstring>

using namespace sycl;
namespace esimd = sycl::ext::intel::esimd;
namespace xmx = sycl::ext::intel::esimd::xmx;

int main() {
    queue q{gpu_selector_v};
    printf("device: %s\n", q.get_device().get_info<sycl::info::device::name>().c_str());
    unsigned char* da = malloc_device<unsigned char>(256, q);
    unsigned char* db = malloc_device<unsigned char>(512, q);
    int* dc = malloc_shared<int>(128 * 16, q);   // room if replicated per lane
    std::vector<unsigned char> ha(256), hb(512);

    auto launch = [&]() {
        q.parallel_for(range<1>{16}, [=](item<1> itm) {
            esimd::simd<signed char, 256> a;
            esimd::simd<unsigned char, 512> b;
#pragma unroll
            for (int i = 0; i < 256; ++i) a[i] = (signed char)da[i];
#pragma unroll
            for (int i = 0; i < 512; ++i) b[i] = db[i];
            esimd::simd<int32_t, 128> c(0);
            c = xmx::dpas<8, 8, int32_t>(c, b, a);
            // store the FULL returned simd from lane view: store all 128 (uniform assumption)
            for (int i = 0; i < 128; ++i) dc[i] = c[i];
        }).wait();
    };

    auto run = [&](const char* name) {
        q.copy(ha.data(), da, 256); q.copy(hb.data(), db, 512); q.wait();
        launch();
        printf("%s:\n", name);
        for (int r = 0; r < 8; ++r) {
            printf("  ");
            for (int i = 0; i < 16; ++i) printf("%5d", dc[r * 16 + i]);
            printf("   (rows of 16 by rc idx)\n");
        }
    };

    for (int o = 0; o < 256; ++o) ha[o] = (unsigned char)(o / 32);
    std::memset(hb.data(), 1, 512);
    run("RX A=o/32 B=1 -> 32*Arow");

    for (int o = 0; o < 256; ++o) ha[o] = 1;
    for (int o = 0; o < 512; ++o) hb[o] = (unsigned char)(o / 32);
    run("RY A=1 B=o/32 -> 32*Bband");

    for (int o = 0; o < 256; ++o) ha[o] = (unsigned char)((o % 32) + 1);
    for (int o = 0; o < 512; ++o) hb[o] = (unsigned char)((o % 32) + 1);
    run("RZ tags k+1 both -> 11440 if aligned");

    for (int o = 0; o < 256; ++o) ha[o] = (unsigned char)(o % 32);
    for (int o = 0; o < 512; ++o) hb[o] = (unsigned char)((o / 32) * 32 + (o % 32));
    run("RW A=o%32 B=mixed");
    return 0;
}