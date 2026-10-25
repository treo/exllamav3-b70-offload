// lab_dpas3: exact dpas<8,8,i32,u8/s8> (kd32) B-operand map on B70 via delta sweeps.
// Established (RX/RY lab): A ordinal o -> (row o/32, k o%32); C ordinal i = row*16 + colgrp.
// B sweep: A[o] = (o%32)+1, B = delta(target ordinal t) -> C[r*16+c] = (k*+1) iff (k*,c)~t.
// Also sweeps with SG pinned to 16 for comparison against default (exec-size 32?).
#include <sycl/sycl.hpp>
#include <sycl/ext/intel/esimd.hpp>
#include <cstdio>
#include <vector>
#include <cstring>

using namespace sycl;
namespace esimd = sycl::ext::intel::esimd;
namespace xmx = sycl::ext::intel::esimd::xmx;

template <bool SG16>
struct BK   // B-delta kernel
{
    const unsigned char* da; const unsigned char* db; int* dc;
    auto get(sycl::ext::oneapi::experimental::properties_tag) const {
        if constexpr (SG16)
            return sycl::ext::oneapi::experimental::properties{
                sycl::ext::oneapi::experimental::sub_group_size<16>};
        else
            return sycl::ext::oneapi::experimental::properties{};
    }
    void operator()(item<1> itm) const {
        esimd::simd<signed char, 256> a;
        esimd::simd<unsigned char, 512> b;
#pragma unroll
        for (int i = 0; i < 256; ++i) a[i] = (signed char)da[i];
#pragma unroll
        for (int i = 0; i < 512; ++i) b[i] = db[i];
        esimd::simd<int32_t, 128> c(0);
        c = xmx::dpas<8, 8, int32_t>(c, b, a);
        if (itm.get_id() == 0)
            for (int i = 0; i < 128; ++i) dc[i] = c[i];
    }
};

template <bool SG16>
struct AK   // A-delta kernel
{
    const unsigned char* da; const unsigned char* db; int* dc;
    auto get(sycl::ext::oneapi::experimental::properties_tag) const {
        if constexpr (SG16)
            return sycl::ext::oneapi::experimental::properties{
                sycl::ext::oneapi::experimental::sub_group_size<16>};
        else
            return sycl::ext::oneapi::experimental::properties{};
    }
    void operator()(item<1> itm) const {
        esimd::simd<signed char, 256> a;
        esimd::simd<unsigned char, 512> b;
#pragma unroll
        for (int i = 0; i < 256; ++i) a[i] = (signed char)da[i];
#pragma unroll
        for (int i = 0; i < 512; ++i) b[i] = db[i];
        esimd::simd<int32_t, 128> c(0);
        c = xmx::dpas<8, 8, int32_t>(c, b, a);
        if (itm.get_id() == 0)
            for (int i = 0; i < 128; ++i) dc[i] = c[i];
    }
};

int main() {
    queue q{gpu_selector_v};
    printf("device: %s\n", q.get_device().get_info<sycl::info::device::name>().c_str());
    unsigned char* da = malloc_device<unsigned char>(256, q);
    unsigned char* db = malloc_device<unsigned char>(512, q);
    int* dc = malloc_shared<int>(128, q);
    std::vector<unsigned char> ha(256), hb(512);

    // ---------- B map sweep ----------
    for (int o = 0; o < 256; ++o) ha[o] = (unsigned char)((o % 32) + 1);   // A: k+1 tags
    q.copy(ha.data(), da, 256);
    auto sweepB = [&](bool sg16) {
        printf("=== B map %s\n", sg16 ? "(SG16)" : "(default)");
        for (int t = 0; t < 512; ++t) {
            std::memset(hb.data(), 0, 512);
            hb[t] = 1;
            q.copy(hb.data(), db, 512); q.wait();
            if (sg16) q.parallel_for(range<1>{16}, BK<true>{da, db, dc}).wait();
            else      q.parallel_for(range<1>{16}, BK<false>{da, db, dc}).wait();
            printf("B_ord %3d (band %2d, in-band %2d):", t, t / 32, t % 32);
            int nz = 0;
            for (int i = 0; i < 128; ++i)
                if (dc[i]) { printf(" [row %d, col %d]=%d", i / 16, i % 16, dc[i]); nz++; if (nz >= 10) break; }
            if (!nz) printf(" (all zero)");
            printf("\n");
        }
    };
    sweepB(false);
    sweepB(true);

    // ---------- A map spot check (delta on A rows) ----------
    printf("=== A map check (SG16): A delta ordinal -> row reached, value=B(k,c)\n");
    for (int o = 0; o < 512; ++o) hb[o] = (unsigned char)((o % 32) + 1);  // B: k+1 by own ordinals
    q.copy(hb.data(), db, 512);
    for (int t = 0; t < 256; t += 17) {
        std::memset(ha.data(), 0, 256);
        ha[t] = 1;
        q.copy(ha.data(), da, 256); q.wait();
        q.parallel_for(range<1>{16}, AK<true>{da, db, dc}).wait();
        printf("A_ord %3d (band %2d, in-band %2d):", t, t / 32, t % 32);
        int nz = 0;
        for (int i = 0; i < 128; ++i)
            if (dc[i]) { printf(" [row %d, col %d]=%d", i / 16, i % 16, dc[i]); nz++; if (nz >= 18) break; }
        if (!nz) printf(" (all zero)");
        printf("\n");
    }
    return 0;
}