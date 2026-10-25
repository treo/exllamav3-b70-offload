// lab_dpas4: per-lane-slice discovery of esimd xmx::dpas<8,8> s8/u8 (kd32) operand maps.
// Convention forced here: lane L's A operand bytes = global aA[L*16 .. +16) (4 LE u32 words
// in order), same for B (L*16). C read per lane = 4 int32. SG pinned to 16.
// Fingerprints (A row tags / B col tags etc.) decode HW's (row,k,col) wiring.
//   FA: A = row-identity   (byte value = oA/32),        B = 1   -> C[r][c] = 32*r_own
//   FB: A = k-identity     (byte value = (oA%32)+1),    B = 1   -> C = sum of own ks + 32
//   FC: A = 1, B = col-identity (byte = oB/32 % 8 + 1)  -> C = 32*(own col band tag)
//   FD: A = 1, B = k tag by OWN ordinal mod 32 + 1
//   FE: random s8/u8 vs reference rebuilt from the discovered maps (PASS/FAIL)
#include <sycl/sycl.hpp>
#include <sycl/ext/intel/esimd.hpp>
#include <cstdio>
#include <vector>
#include <cstring>

using namespace sycl;
namespace esimd = sycl::ext::intel::esimd;
namespace xmx = sycl::ext::intel::esimd::xmx;

struct KSlice
{
    const unsigned char* da; const unsigned char* db; int* dc;
    auto get(sycl::ext::oneapi::experimental::properties_tag) const {
        return sycl::ext::oneapi::experimental::properties{
            sycl::ext::oneapi::experimental::sub_group_size<16>};
    }
    void operator()(nd_item<1> it) const {
        int lane = (int)it.get_local_id(0);
        const unsigned* a32 = (const unsigned*)(da + lane * 16);
        const unsigned* b32 = (const unsigned*)(db + lane * 16);
        // A per lane = 16 bytes; B per lane = 16 bytes  (SG totals 256 each?? B kd32 x rc8 = 256;
        // for the 16-col dpas this API wanted 512 bytes: with SG16, per-lane B = 32 bytes.)
        // Support both by choosing slice size from a compile flag: default 16 for A, 32 for B.
        esimd::simd<signed char, 16> a;
        esimd::simd<unsigned char, 32> b;
#pragma unroll
        for (int i = 0; i < 16; ++i) { unsigned w = a32[i >> 2]; a[i] = (signed char)((w >> (8 * (i & 3))) & 0xff); }
#pragma unroll
        for (int i = 0; i < 32; ++i) {
            unsigned w = (i < 16) ? ((const unsigned*)db)[lane * 4 + (i >> 2)] : 0;
            // second half from db + 256 + lane*16
            const unsigned* b32b = (const unsigned*)(db + 256 + lane * 16);
            unsigned ww = (i < 16) ? w : b32b[(i >> 2) - 4];
            unsigned sel = (i < 16) ? w : ww;
            b[i] = (unsigned char)((sel >> (8 * (i & 3))) & 0xff);
        }
        esimd::simd<int32_t, 8> c(0);   // rd*rc/... per-lane count TBD; try 8, then 4
        c = xmx::dpas<8, 8, int32_t>(c, b, a);
#pragma unroll
        for (int j = 0; j < 8; ++j) dc[lane * 8 + j] = c[j];
    }
};

int main() {
    queue q{gpu_selector_v};
    printf("device: %s\n", q.get_device().get_info<sycl::info::device::name>().c_str());
    unsigned char* da = malloc_device<unsigned char>(256, q);
    unsigned char* db = malloc_device<unsigned char>(512, q);
    int* dc = malloc_shared<int>(128, q);
    std::vector<unsigned char> ha(256), hb(512);
    auto launch = [&]() { q.parallel_for(nd_range<1>{{16}, {16}}, KSlice{da, db, dc}).wait(); };
    auto dump = [&](const char* nm) {
        printf("%s: ", nm);
        for (int l = 0; l < 16; ++l) { printf("| L%02d:", l); for (int j = 0; j < 8; ++j) printf(" %5d", dc[l * 8 + j]); }
        printf("\n");
    };

    for (int o = 0; o < 256; ++o) ha[o] = (unsigned char)(o / 32);
    std::memset(hb, 1, 512);
    q.copy(ha.data(), da, 256); q.copy(hb.data(), db, 512); q.wait(); launch(); dump("FA rows");

    for (int o = 0; o < 256; ++o) ha[o] = (unsigned char)((o % 32) + 1);
    q.copy(ha.data(), da, 256); q.wait(); launch(); dump("FB Aksum");

    std::memset(ha, 1, 256);
    for (int o = 0; o < 512; ++o) hb[o] = (unsigned char)((o / 32) % 8 + 1);
    q.copy(ha.data(), da, 256); q.copy(hb.data(), db, 512); q.wait(); launch(); dump("FC Bcolband");

    for (int o = 0; o < 512; ++o) hb[o] = (unsigned char)((o % 32) + 1);
    q.copy(hb.data(), db, 512); q.wait(); launch(); dump("FD Bksum");
    return 0;
}