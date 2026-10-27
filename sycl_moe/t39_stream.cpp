// t39_stream.cpp - B-operand stream-rate forensics for the int8 Gemv8 access pattern.
//
// Motivation (archive/int8-dpas-tier.md, prefill roofline): forward time ~= 8-16 us per slot = per B-matrix
// traversal; per-token DPAS work is nearly free. Implied per-slot stream rate is
// ~100-200 GB/s against a ~570 GB/s device. This lab reads the SAME bytes with the SAME
// unit->matrix mapping as Gemv8 but without DPAS/A-side machinery, in several access
// modes, to find where the multiplier is lost:
//
//   0 EXACT    - Gemv8 layout [tk][nf][W]: per (nf,tk) a 512B row at row_step stride;
//                dword loads, depth-4 groups. Ladder of strided 512B blocks.
//   1 EXACT16  - same ladder, uint4 loads (128B granularity per lane).
//   2 NFMAJOR  - relayout candidate [nf][tk][W]: each subgroup's slab is contiguous.
//   4 NFMAJ16  - same, uint4.
//   3 FLAT     - per-slot units read the matrix in contiguous shares (read ideal).
//
// Usage: t39 [mode] [nsl] [nexp] [iters]
// Mirrors gate/up at H=2560,I=640: K=2560, tiles_k=160(16-k), W=128 dw (512B), nfl=40.

#include <sycl/sycl.hpp>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <chrono>
#include <vector>

static constexpr int K = 2560, NT = 640;
static constexpr int TILES_K = K / 16;          // 160
static constexpr int NFL = NT / 16;             // 40 nf tiles
static constexpr int W = 128;                   // dwords per (tk,nf) row = 512 B
static constexpr int NSUB = 8;                  // subgroups per WG, one nf tile each
static constexpr int LANES = 16;
static constexpr size_t MAT_DW = (size_t)TILES_K * NFL * W;   // 3.28 MB

#include <sycl/ext/oneapi/experimental/annotated_ptr/annotated_ptr.hpp>
namespace expe = sycl::ext::oneapi::experimental;
namespace inte = sycl::ext::intel::experimental;
inline constexpr auto g_read_hint = inte::read_hint<inte::cache_control<
    inte::cache_mode::streaming, expe::cache_level::L1, expe::cache_level::L2>>;
using AP_W = expe::annotated_ptr<const uint32_t, decltype(expe::properties{g_read_hint})>;
namespace mx8 = sycl::ext::oneapi::experimental::matrix;

template <int MODE, bool HINT, int STAGE>
struct Mega5
{
    const uint32_t* b; const uint32_t* a8; uint32_t* accg;
    int slots, nsl, nexp, per_slot;
    sycl::local_accessor<uint32_t, 1> slm;
    auto get(sycl::ext::oneapi::experimental::properties_tag) const
    { return sycl::ext::oneapi::experimental::properties{ sycl::ext::oneapi::experimental::sub_group_size<16> }; }
    void operator()(sycl::nd_item<1> it) const
    {
        constexpr int K2V = 8, KE = 0, AD27 = (27 * K2V + KE) >> 1;
        constexpr int WQ = 4 * K2V;                    // 32 dwords = 128 B per tile row
        constexpr int NWQ = (AD27 + 16 + 31 + 31) / 32 + 1;   // 6
        constexpr size_t RSTEP = (size_t)NFL * WQ;     // 1280 dwords between tk ladders
        constexpr size_t MAT5_DW = (size_t)TILES_K * NFL * WQ;   // 819 KB per matrix
        const int u = (int)it.get_group(0);
        const int lid = (int)it.get_local_id(0);
        const int slot = u / per_slot;
        const int uu = u % per_slot;
        const int e = slot % nexp;
        const int sgid = lid >> 4, cin = lid & 15;
        const int nfg = uu / nsl, sl = uu % nsl;
        const int nf = (nfg * NSUB + sgid) % NFL;
        const int tk_lo = (TILES_K * sl) / nsl, tk_hi = (TILES_K * (sl + 1)) / nsl;
        const int cnt = tk_hi - tk_lo;
        const uint32_t* base = b + (size_t)e * MAT5_DW;
        const int A2 = (K2V * (32 * (cin & 7) + 4 * ((cin >> 3) & 1))) >> 1;
        const int G = (32 - (K2V >> 1)) - A2 - AD27;
        const int wb = G >> 5;
        const int pre = G - (wb << 5);
        int widx[NWQ];
#pragma unroll
        for (int i = 0; i < NWQ; ++i) widx[i] = ((wb + i) % WQ + WQ) % WQ;
        const uint32_t* wp = base + (size_t)nf * WQ + (size_t)tk_lo * RSTEP;
        sycl::sub_group sg = it.get_sub_group();
        uint32_t* slb = slm.get_pointer().get() + (size_t)sgid * 512;
        mx8::joint_matrix<sycl::sub_group, signed char, mx8::use::a, 8, 32,
                          mx8::layout::row_major> ja;
        mx8::joint_matrix<sycl::sub_group, unsigned char, mx8::use::b, 32, 16,
                          mx8::layout::ext_intel_packed> jb;
        mx8::joint_matrix<sycl::sub_group, int, mx8::use::accumulator, 8, 16> jc, jc1;
        mx8::joint_matrix_fill(sg, jc, 0); mx8::joint_matrix_fill(sg, jc1, 0);
        const uint32_t* pa0 = a8 + (size_t)(slot & 31) * (K / 8) * 128;
        // STAGE 9: cooperative A-ring in SLM - one 1KB contiguous copy per (WG, q),
        // all subgroups read the same A bytes (A is nf-independent).
        char* const slm2 = (char*)slm.get_pointer().get() + 8 * 512 * 4;
        auto COPYTK = [&](int tqidx, int slot) {
            const sycl::uint4* s = (const sycl::uint4*)(pa0 + (size_t)(2 * (tk_lo + tqidx)) * 128);
            sycl::uint4* d = (sycl::uint4*)(slm2 + (slot & 3) * 1024);
            if (lid < 64) d[lid] = s[lid];
        };
        if constexpr (STAGE == 9) { COPYTK(0, 0); sycl::group_barrier(it.get_group()); }
        // STAGE 14: 4-region group-granular A ring: one cooperative 4KB copy (one contiguous
        // run!) + ONE group barrier per 4-tile group; reads lag writes by >= 2 groups.
        auto COPYGRP = [&](int g) {
            const sycl::uint4* s = (const sycl::uint4*)(pa0 + (size_t)(2 * (tk_lo + g * 4)) * 128);
            sycl::uint4* d = (sycl::uint4*)(slm2 + (g & 3) * 4096);
            d[lid] = s[lid]; d[lid + 128] = s[lid + 128];
        };
        // STAGE 16: split copy - loads issued pre-barrier (latency hidden by the wait),
        // stores post-barrier. Write of g+2 (region (g+2)&3) vs read of g (region g&3):
        // no same-iteration collision; visibility via barrier(g+1); clobber safety via
        // barrier(g-1) ordering the previous reader group.
        sycl::uint4 cpcA, cpcB;
        auto CPLOAD = [&](int g) {
            const sycl::uint4* s = (const sycl::uint4*)(pa0 + (size_t)(2 * (tk_lo + g * 4)) * 128);
            cpcA = s[lid]; cpcB = s[lid + 128];
        };
        auto CPSTORE = [&](int g) {
            sycl::uint4* d = (sycl::uint4*)(slm2 + (g & 3) * 4096);
            d[lid] = cpcA; d[lid + 128] = cpcB;
        };
        auto COPYGRP15 = [&](int g) {
            const sycl::uint4* s = (const sycl::uint4*)(pa0 + (size_t)(2 * (tk_lo + g * 4)) * 128);
            sycl::uint4* d = (sycl::uint4*)(slm2 + (g & 7) * 4096);
            d[lid] = s[lid]; d[lid + 128] = s[lid + 128];
        };
        // STAGE 17: period-2 barrier, 6 regions (24 KB ring): groups g+4,g+5 written on
        // even iterations; read of g trails its write by 4 groups, region reuse by 6.
        auto COPYGRP17 = [&](int g) {
            const sycl::uint4* s = (const sycl::uint4*)(pa0 + (size_t)(2 * (tk_lo + g * 4)) * 128);
            sycl::uint4* d = (sycl::uint4*)(slm2 + (g % 6) * 4096);
            d[lid] = s[lid]; d[lid + 128] = s[lid + 128];
        };
        uint32_t jc_dummy = 0;
        // STAGE 7: ja fragments prefetched one q-iteration ahead, rotating sets per (fk,f).
        typedef mx8::joint_matrix<sycl::sub_group, signed char, mx8::use::a, 8, 32,
                                  mx8::layout::row_major> ja_t;
        ja_t jaS[4][2][2];   // [parity2][fk][f]  (STAGE 7 = depth 1, STAGE 8 = depth 4)
        auto JLOAD = [&](ja_t& jm, int ttk, int fk, int f) {
            auto pag = sycl::address_space_cast<sycl::access::address_space::global_space,
                                                sycl::access::decorated::yes>(
                (const signed char*)(pa0 + (size_t)(2 * ttk + fk) * 128 + f * 64));
            mx8::joint_matrix_load(sg, jm, pag, 32);
        };
        auto JP = [](int tq) { return (tq >> 2) & 1; };
        auto JP4 = [](int tq) { return tq & 3; };
        if constexpr (STAGE == 7)
            for (int fk = 0; fk < 2; ++fk) for (int f = 0; f < 2; ++f) JLOAD(jaS[0][fk][f], tk_lo, fk, f);
        if constexpr (STAGE == 8)
            for (int pq = 0; pq < 4; ++pq) { const int tt = tk_lo + pq; if (tt < tk_hi)
                for (int fk = 0; fk < 2; ++fk) for (int f = 0; f < 2; ++f) JLOAD(jaS[pq & 3][fk][f], tt, fk, f); }
        for (int t = 0; t < cnt; t += 4)
        {
            if constexpr (STAGE == 17)
            {
                const int g = t >> 2;
                if (g == 0) { for (int gg = 0; gg < 6; ++gg) if (gg * 4 < cnt) COPYGRP17(gg); }
                else if ((g & 1) == 0) { if ((g + 4) * 4 < cnt) COPYGRP17(g + 4); if ((g + 5) * 4 < cnt) COPYGRP17(g + 5); }
                if ((g & 1) == 0) sycl::group_barrier(it.get_group());
            }
            if constexpr (STAGE == 16)
            {
                const int g = t >> 2;
                if (g == 0) { COPYGRP(0); COPYGRP(1); }
                else { if ((g + 2) * 4 < cnt) CPLOAD(g + 2); }
                sycl::group_barrier(it.get_group());
                if (g != 0 && (g + 2) * 4 < cnt) CPSTORE(g + 2);
            }
            if constexpr (STAGE == 14)
            {
                const int g = t >> 2;
                if (g == 0) { COPYGRP(0); if (4 < cnt) COPYGRP(1); }
                else if ((g + 2) * 4 < cnt) COPYGRP(g + 2);
                sycl::group_barrier(it.get_group());
            }
            // STAGE 15: 8 regions; every 2nd group copies TWO groups ahead, barrier amortized
            if constexpr (STAGE == 15)
            {
                const int g = t >> 2;
                if (g == 0) { for (int q4 = 0; q4 < 4; ++q4) if (q4 * 4 < cnt) COPYGRP15(q4); }
                else if ((g & 1) == 0) { if ((g + 4) * 4 < cnt) COPYGRP15(g + 4); if ((g + 5) * 4 < cnt) COPYGRP15(g + 5); }
                if ((g & 1) == 0) sycl::group_barrier(it.get_group());
            }
            uint32_t gA[NWQ], gB[NWQ], gC[NWQ], gD[NWQ];
            const uint32_t* p4 = wp + (size_t)t * RSTEP;
            if constexpr (HINT)
            {
                AP_W q0{ p4, expe::properties{g_read_hint} };
                AP_W q1{ p4 + RSTEP, expe::properties{g_read_hint} };
                AP_W q2{ p4 + 2 * RSTEP, expe::properties{g_read_hint} };
                AP_W q3{ p4 + 3 * RSTEP, expe::properties{g_read_hint} };
#pragma unroll
                for (int i = 0; i < NWQ; ++i) {
                    gA[i] = (t + 0 < cnt) ? q0[widx[i]] : 0u;
                    gB[i] = (t + 1 < cnt) ? q1[widx[i]] : 0u;
                    gC[i] = (t + 2 < cnt) ? q2[widx[i]] : 0u;
                    gD[i] = (t + 3 < cnt) ? q3[widx[i]] : 0u;
                }
            }
            else
            {
#pragma unroll
                for (int i = 0; i < NWQ; ++i) {
                    gA[i] = (t + 0 < cnt) ? p4[widx[i]] : 0u;
                    gB[i] = (t + 1 < cnt) ? p4[RSTEP + widx[i]] : 0u;
                    gC[i] = (t + 2 < cnt) ? p4[2 * RSTEP + widx[i]] : 0u;
                    gD[i] = (t + 3 < cnt) ? p4[3 * RSTEP + widx[i]] : 0u;
                }
            }
#pragma unroll
            for (int q = 0; q < 4; ++q)
            {
                if (t + q >= cnt) break;
                const int tk = tk_lo + t + q;
                if constexpr (STAGE == 9)
                {
                    if (t + q + 1 < cnt) COPYTK(t + q + 1, (t + q + 1) & 3);
                    sycl::group_barrier(it.get_group());
                }
                const uint32_t* gsrc = (q == 0) ? gA : (q == 1) ? gB : (q == 2) ? gC : gD;
                uint32_t h[NWQ];
                if (pre == 0) { for (int i = 0; i < NWQ; ++i) h[i] = gsrc[i]; }
                else {
                    for (int i = 0; i + 1 < NWQ; ++i) h[i] = (gsrc[i] >> pre) | (gsrc[i + 1] << (32 - pre));
                    h[NWQ - 1] = gsrc[NWQ - 1] >> pre;
                }
                uint32_t* const band = slb + (q & 1) * 256;
                if constexpr (STAGE == 7)
                {
                    const int tn = tk_lo + t + q + 1;
                    if (tn < tk_hi)
                        for (int fk2 = 0; fk2 < 2; ++fk2) for (int f2 = 0; f2 < 2; ++f2)
                            JLOAD(jaS[JP(t + q + 1)][fk2][f2], tn, fk2, f2);
                }
                if constexpr (STAGE == 8)
                {
                    const int tn = tk_lo + t + q + 4;
                    if (tn < tk_hi)
                        for (int fk2 = 0; fk2 < 2; ++fk2) for (int f2 = 0; f2 < 2; ++f2)
                            JLOAD(jaS[JP4(t + q + 4)][fk2][f2], tn, fk2, f2);
                }
                if constexpr (STAGE >= 2)
#pragma unroll
                for (int rk = 0; rk < 16; ++rk) {
                    const int d = 8 * ((rk >> 1) & 3) + (rk & 1) + 2 * ((rk >> 3) & 1);
                    const int rel = AD27 - ((K2V * d + KE) >> 1);
                    const uint32_t lo4 = h[rel >> 5], hi4 = h[(rel >> 5) + 1];
                    const uint32_t st16 = ((lo4 >> (rel & 31)) | ((hi4 << 1) << (31u - (rel & 31)))) & 0xffffu;
                    band[(rk >> 3) * 128 + (rk & 7) * 16 + cin] = st16 * 0x83DCD12Du;
                }
                sg.barrier();
                if constexpr (STAGE >= 3)
                {
                uint32_t* const bnd = slb + (q & 1) * 256;
#pragma unroll
                for (int fk = 0; fk < 2; ++fk) {
                    if constexpr (STAGE != 5)
                    mx8::joint_matrix_load(sg, jb,
                        sycl::address_space_cast<sycl::access::address_space::local_space,
                                                 sycl::access::decorated::yes>((unsigned char*)bnd + fk * 512),
                        16 * 4);
                        if constexpr (STAGE >= 4)
                        for (int f = 0; f < 2; ++f) {
                        if constexpr (STAGE == 18) {
                            // swizzled-A probe: per-lane 16B contiguous load (fragment stays
                            // stale; we measure MEMORY, not math)
                            const sycl::uint4* swz = (const sycl::uint4*)(pa0 + (size_t)(2 * tk + fk) * 128);
                            sycl::uint4 v = swz[cin];
                            jc_dummy ^= v.x() ^ v.y() ^ v.z() ^ v.w();
                            if (f) mx8::joint_matrix_mad(sg, jc1, ja, jb, jc1);
                            else   mx8::joint_matrix_mad(sg, jc, ja, jb, jc);
                            continue;
                        }
                        if constexpr (STAGE == 7) {
                            ja_t& jr = jaS[JP(t + q)][fk][f];
                            if (f) mx8::joint_matrix_mad(sg, jc1, jr, jb, jc1);
                            else   mx8::joint_matrix_mad(sg, jc, jr, jb, jc);
                            continue;
                        }
                        if constexpr (STAGE == 8) {
                            ja_t& jr = jaS[JP4(t + q)][fk][f];
                            if (f) mx8::joint_matrix_mad(sg, jc1, jr, jb, jc1);
                            else   mx8::joint_matrix_mad(sg, jc, jr, jb, jc);
                            continue;
                        }
                        if constexpr (STAGE == 9) {
                            const signed char* asrc = (const signed char*)(slm2 + ((t + q) & 3) * 1024 + (fk * 2 + f) * 256);
                            auto pal = sycl::address_space_cast<sycl::access::address_space::local_space,
                                                                sycl::access::decorated::yes>(asrc);
                            mx8::joint_matrix_load(sg, ja, pal, 32);
                            if (f) mx8::joint_matrix_mad(sg, jc1, ja, jb, jc1);
                            else   mx8::joint_matrix_mad(sg, jc, ja, jb, jc);
                            continue;
                        }
                        if constexpr (STAGE == 15) {
                            const signed char* asrc = (const signed char*)(slm2 + ((t >> 2) & 7) * 4096 + (q & 3) * 1024 + (fk * 2 + f) * 256);
                            auto pal = sycl::address_space_cast<sycl::access::address_space::local_space,
                                                                sycl::access::decorated::yes>(asrc);
                            mx8::joint_matrix_load(sg, ja, pal, 32);
                            if (f) mx8::joint_matrix_mad(sg, jc1, ja, jb, jc1);
                            else   mx8::joint_matrix_mad(sg, jc, ja, jb, jc);
                            continue;
                        }
                        if constexpr (STAGE == 17) {
                            const signed char* asrc = (const signed char*)(slm2 + ((t >> 2) % 6) * 4096 + (q & 3) * 1024 + (fk * 2 + f) * 256);
                            auto pal = sycl::address_space_cast<sycl::access::address_space::local_space,
                                                                sycl::access::decorated::yes>(asrc);
                            mx8::joint_matrix_load(sg, ja, pal, 32);
                            if (f) mx8::joint_matrix_mad(sg, jc1, ja, jb, jc1);
                            else   mx8::joint_matrix_mad(sg, jc, ja, jb, jc);
                            continue;
                        }
                        if constexpr (STAGE == 16 || STAGE == 14) {
                            const signed char* asrc = (const signed char*)(slm2 + ((t >> 2) & 3) * 4096 + (q & 3) * 1024 + (fk * 2 + f) * 256);
                            auto pal = sycl::address_space_cast<sycl::access::address_space::local_space,
                                                                sycl::access::decorated::yes>(asrc);
                            mx8::joint_matrix_load(sg, ja, pal, 32);
                            if (f) mx8::joint_matrix_mad(sg, jc1, ja, jb, jc1);
                            else   mx8::joint_matrix_mad(sg, jc, ja, jb, jc);
                            continue;
                        }
                        if constexpr (STAGE == 12) {
                            // local ja gather cost only: fixed slot, no copies/barriers
                            const signed char* asrc = (const signed char*)(slm2 + (fk * 2 + f) * 256);
                            auto pal = sycl::address_space_cast<sycl::access::address_space::local_space,
                                                                sycl::access::decorated::yes>(asrc);
                            mx8::joint_matrix_load(sg, ja, pal, 32);
                            if (f) mx8::joint_matrix_mad(sg, jc1, ja, jb, jc1);
                            else   mx8::joint_matrix_mad(sg, jc, ja, jb, jc);
                            continue;
                        }
                        if constexpr (STAGE == 13 && NWQ == -42) {
                            // packed A layout from GLOBAL: per-lane 16B contiguous fragment
                            // DISABLED: IGL has no packed-A i8 load builtin (shows intended
                            // v8i8 lowering name though - revisit via esimd::dpas).
                            mx8::joint_matrix<sycl::sub_group, signed char, mx8::use::a, 8, 32,
                                              mx8::layout::ext_intel_packed> jap;
                            auto pag = sycl::address_space_cast<sycl::access::address_space::global_space,
                                                                sycl::access::decorated::yes>(
                                (const signed char*)(pa0 + (size_t)(2 * tk + fk) * 128 + f * 64));
                            mx8::joint_matrix_load(sg, jap, pag, 256);
                            if (f) mx8::joint_matrix_mad(sg, jc1, jap, jb, jc1);
                            else   mx8::joint_matrix_mad(sg, jc, jap, jb, jc);
                            continue;
                        }
                        if constexpr (STAGE != 6) {
                        auto pag = sycl::address_space_cast<sycl::access::address_space::global_space,
                                                            sycl::access::decorated::yes>(
                            (const signed char*)(pa0 + (size_t)(2 * tk + fk) * 128 + f * 64));
                        mx8::joint_matrix_load(sg, ja, pag, 32);
                        }
                        if (f) mx8::joint_matrix_mad(sg, jc1, ja, jb, jc1);
                        else   mx8::joint_matrix_mad(sg, jc, ja, jb, jc);
                    }
                }
                }
                if constexpr (STAGE < 2) { for (int i = 0; i < NWQ; ++i) jc_dummy ^= h[i]; }
            }
        }
        auto psg = sycl::address_space_cast<sycl::access::address_space::global_space,
                                            sycl::access::decorated::yes>((int*)(accg + (size_t)u * 288));
        mx8::joint_matrix_store(sg, jc, psg, 16, mx8::layout::row_major);
        mx8::joint_matrix_store(sg, jc1, psg + 128, 16, mx8::layout::row_major);
        uint32_t fold_sg = sycl::reduce_over_group(it.get_sub_group(), jc_dummy, sycl::bit_xor<>());
        if (it.get_local_id(0) == 0) accg[(size_t)u * 288 + 256] = fold_sg;
    }
};

static void mega5_dummy();


struct Args
{
    const uint32_t* b;
    uint32_t* sink;
    const uint32_t* a8;
    uint32_t* accg;
    int slots, nsl, nexp, stage;
};


template <int MODE, int STAGE>
static void mega5_launch(sycl::queue& q, const Args& a, int units, int per_slot)
{
    q.submit([&](sycl::handler& h) {
        sycl::local_accessor<uint32_t, 1> slm({ 8 * 512 + (STAGE == 15 ? 8192 : (STAGE == 17 ? 6144 : ((STAGE == 14 || STAGE == 16) ? 4096 : 1024))) }, h);
        if constexpr (MODE == 6)
            h.parallel_for(sycl::nd_range<1>({ (size_t)units * 128 }, { 128 }),
                           Mega5<MODE, true, STAGE>{ a.b, a.a8, a.accg, a.slots, a.nsl, a.nexp, per_slot, slm });
        else
            h.parallel_for(sycl::nd_range<1>({ (size_t)units * 128 }, { 128 }),
                           Mega5<MODE, false, STAGE>{ a.b, a.a8, a.accg, a.slots, a.nsl, a.nexp, per_slot, slm });
    }).wait();
}

template <int MODE>
void run_mode(sycl::queue& q, const Args& a, int units, int per_slot)
{
    if constexpr (MODE == 5 || MODE == 6) {
        switch (a.stage) {
            case 0: mega5_launch<MODE, 0>(q, a, units, per_slot); break;
            case 1: mega5_launch<MODE, 1>(q, a, units, per_slot); break;
            case 2: mega5_launch<MODE, 2>(q, a, units, per_slot); break;
            case 3: mega5_launch<MODE, 3>(q, a, units, per_slot); break;
            case 4: mega5_launch<MODE, 4>(q, a, units, per_slot); break;
            case 5: mega5_launch<MODE, 5>(q, a, units, per_slot); break;
            case 6: mega5_launch<MODE, 6>(q, a, units, per_slot); break;
            case 7: mega5_launch<MODE, 7>(q, a, units, per_slot); break;
            case 8: mega5_launch<MODE, 8>(q, a, units, per_slot); break;
            case 9: mega5_launch<MODE, 9>(q, a, units, per_slot); break;
            case 14: mega5_launch<MODE, 14>(q, a, units, per_slot); break;
            case 15: mega5_launch<MODE, 15>(q, a, units, per_slot); break;
            case 16: mega5_launch<MODE, 16>(q, a, units, per_slot); break;
            case 17: mega5_launch<MODE, 17>(q, a, units, per_slot); break;
            case 18: mega5_launch<MODE, 18>(q, a, units, per_slot); break;
            case 12: mega5_launch<MODE, 12>(q, a, units, per_slot); break;
            case 13: mega5_launch<MODE, 9>(q, a, units, per_slot); break;  // packed-A unsupported; proxy=9
            default: mega5_launch<MODE, 4>(q, a, units, per_slot); break;
        }
        return; }
    q.submit([&](sycl::handler& h) {
        h.parallel_for(sycl::nd_range<1>({ (size_t)units * 128 }, { 128 }), [=](sycl::nd_item<1> it) {
            const int u = (int)it.get_group(0);
            const int lid = (int)it.get_local_id(0);
            const int slot = u / per_slot;
            const int uu = u % per_slot;
            const int e = slot % a.nexp;
            const uint32_t* base = a.b + (size_t)e * MAT_DW;
            const int sgid = lid >> 4, cin = lid & 15;
            uint32_t acc = 0;

            if constexpr (MODE == 3)
            {
                // FLAT: this unit reads its contiguous share of the matrix
                const size_t share = MAT_DW / per_slot;
                const sycl::uint4* v = (const sycl::uint4*)(base + (size_t)uu * share);
                for (int i = lid; i < (int)(share / 4); i += 128)
                {
                    sycl::uint4 x = v[i];
                    acc ^= x.x() ^ x.y() ^ x.z() ^ x.w();
                }
            }
            else
            {
                const int nfg = (a.nsl > 0) ? (uu / a.nsl) : uu;      // nf-group
                const int sl = uu % (a.nsl > 0 ? a.nsl : 1);          // k slice
                const int nf = (nfg * NSUB + sgid) % NFL;
                const int tk_lo = (TILES_K * sl) / (a.nsl ? a.nsl : 1);
                const int tk_hi = (TILES_K * (sl + 1)) / (a.nsl ? a.nsl : 1);
                const int cnt = tk_hi - tk_lo;
                const int woff = cin * (W / LANES);
                const uint32_t* wp;
                size_t step;
                if constexpr (MODE == 0 || MODE == 1) { wp = base + (size_t)nf * W + (size_t)tk_lo * ((size_t)NFL * W); step = (size_t)NFL * W; }
                else { wp = base + ((size_t)nf * TILES_K + tk_lo) * W; step = (size_t)W; }   // NFMAJOR
                const uint32_t* p = wp + woff;

                auto ROW = [&](const uint32_t* r, uint32_t& s, int qsel) {
                    if constexpr (MODE == 1 || MODE == 4)
                    {
                        const sycl::uint4* v = (const sycl::uint4*)(r);
                        #pragma unroll
                        for (int i = 0; i < W / LANES / 4; ++i)
                        {
                            sycl::uint4 x = v[i];
                            s ^= x.x() ^ x.y() ^ x.z() ^ x.w();
                        }
                    }
                    else
                        #pragma unroll
                        for (int i = 0; i < W / LANES; ++i) s ^= r[i];
                    (void)qsel;
                };
                for (int t = 0; t < cnt; t += 4)
                {
                    uint32_t s0 = 0, s1 = 0, s2 = 0, s3 = 0;
                    if (t + 0 < cnt) ROW(p + (size_t)(t + 0) * step, s0, 0);
                    if (t + 1 < cnt) ROW(p + (size_t)(t + 1) * step, s1, 1);
                    if (t + 2 < cnt) ROW(p + (size_t)(t + 2) * step, s2, 2);
                    if (t + 3 < cnt) ROW(p + (size_t)(t + 3) * step, s3, 3);
                    acc ^= s0 ^ s1 ^ s2 ^ s3;
                }
            }
            acc = sycl::reduce_over_group(it.get_sub_group(), acc, sycl::plus<>());
            if (cin == 0) a.sink[(size_t)u * NSUB + sgid] = acc;
        });
    }).wait();
}

int main(int argc, char** argv)
{
    int mode = argc > 1 ? atoi(argv[1]) : 0;
    int nsl = argc > 2 ? atoi(argv[2]) : 1;
    int nexp = argc > 3 ? atoi(argv[3]) : 128;
    int iters = argc > 4 ? atoi(argv[4]) : 20;
    int stage = argc > 5 ? atoi(argv[5]) : 9;
    int slots = 256;
    if (mode == 3) nsl = 1;   // FLAT ignores slicing (shares per unit)

    sycl::queue q{sycl::gpu_selector_v};
    printf("dev: %s\n", q.get_device().get_info<sycl::info::device::name>().c_str());

    uint32_t* b = sycl::malloc_device<uint32_t>((size_t)nexp * MAT_DW, q);
    int per_slot = (mode == 3) ? 5 : (NFL / NSUB) * nsl;
    uint32_t* sink = sycl::malloc_device<uint32_t>((size_t)slots * per_slot * NSUB + 1024, q);
    uint32_t* a8 = sycl::malloc_device<uint32_t>((size_t)32 * (K / 8) * 128 + 4096, q);
    uint32_t* accg = sycl::malloc_device<uint32_t>((size_t)slots * per_slot * 288 + 4096, q);
    q.memset(a8, 0x11, (size_t)32 * (K / 8) * 128).wait();
    std::vector<uint32_t> pat(MAT_DW);
    for (size_t i = 0; i < MAT_DW; ++i) pat[i] = (uint32_t)(i * 2654435761u);
    q.memcpy(b, pat.data(), MAT_DW * 4).wait();
    for (int e = 1; e < nexp; ++e) q.memcpy(b + (size_t)e * MAT_DW, b, MAT_DW * 4).wait();  // cheap D2D fill
    if (std::getenv("T39_DUMP"))
    {
        size_t offs[] = {0, 128, 4096, 300000, MAT_DW - 1, MAT_DW, MAT_DW + 128, (size_t)(nexp - 1) * MAT_DW + 300000};
        for (size_t o : offs) { uint32_t v = 0; q.memcpy(&v, b + o, 4).wait();
            printf("dump off %zu: dev %08x expect %08x %s\n", o, v, (uint32_t)(o % MAT_DW * 2654435761u),
                   v == (uint32_t)(o % MAT_DW * 2654435761u) ? "" : "<-- BAD"); }
    }

    int units = slots * per_slot;
    double mb = (double)slots * ((mode >= 5) ? ((size_t)TILES_K * NFL * 32) : MAT_DW) * 4 / 1e6;
    printf("mode %d nsl %d nexp %d: units %d, %.0f MB/iter\n", mode, nsl, nexp, units, mb);

    Args a{ b, sink, a8, accg, slots, nsl, nexp, stage };
    auto dispatch = [&]() {
        switch (mode) { case 0: run_mode<0>(q,a,units,per_slot); break;
                        case 1: run_mode<1>(q,a,units,per_slot); break;
                        case 2: run_mode<2>(q,a,units,per_slot); break;
                        case 4: run_mode<4>(q,a,units,per_slot); break;
                        case 5: run_mode<5>(q,a,units,per_slot); break;
                        case 6: run_mode<6>(q,a,units,per_slot); break;
                        default: run_mode<3>(q,a,units,per_slot); }
    };
    for (int i = 0; i < 2; ++i) dispatch();
    double best = 1e30;
    for (int i = 0; i < iters; ++i)
    {
        auto t0 = std::chrono::steady_clock::now();
        dispatch();
        auto t1 = std::chrono::steady_clock::now();
        double us = std::chrono::duration<double, std::micro>(t1 - t0).count();
        if (us < best) best = us;
    }
    printf("best %.1f us -> %.0f GB/s\n", best, mb / best * 1000.0);
    // VERIFY: host-recompute the stage-1 xor fold (pattern is per-matrix identity)
    if ((mode == 5 || mode == 6) && stage <= 1)
    {
        std::vector<uint32_t> hb((size_t)units * 288 + 288);
        q.memcpy(hb.data(), accg, hb.size() * 4).wait();
        constexpr int K2Vq = 8, KEq = 0, AD27q = (27 * K2Vq + KEq) >> 1;
        constexpr int WQq = 4 * K2Vq, NWQq = (AD27q + 16 + 31 + 31) / 32 + 1;
        const size_t RSTEPq = (size_t)NFL * WQq;
        const size_t MAT5q = (size_t)TILES_K * NFL * WQq;
        int bad = 0;
        for (int us_ : {0, 1, units / 2, units - 1})
        {
            const int uu = us_ % per_slot, slot0 = us_ / per_slot;
            const int ee = slot0 % nexp;
            const int nfg = uu / nsl, sl = uu % nsl;
            uint32_t fold = 0;
            for (int sgid = 0; sgid < 8; ++sgid)
            {
                const int nf = (nfg * NSUB + sgid) % NFL;
                const int tk_lo = (TILES_K * sl) / nsl, tk_hi = (TILES_K * (sl + 1)) / nsl;
                for (int cinl = 0; cinl < 16; ++cinl)
                {
                    const int A2 = (K2Vq * (32 * (cinl & 7) + 4 * ((cinl >> 3) & 1))) >> 1;
                    const int G = (32 - (K2Vq >> 1)) - A2 - AD27q;
                    const int wb = G >> 5, pre = G - (wb << 5);
                    int widx[NWQq];
                    for (int i = 0; i < NWQq; ++i) widx[i] = ((wb + i) % WQq + WQq) % WQq;
                    for (int t = 0; t < tk_hi - tk_lo; t += 4)
                        for (int q = 0; q < 4; ++q)
                        {
                            if (t + q >= tk_hi - tk_lo) break;
                            uint32_t g[NWQq];
                            for (int i = 0; i < NWQq; ++i)
                            {
                                size_t dw = (size_t)ee * MAT5q + (size_t)nf * WQq + (size_t)(tk_lo + t + q) * RSTEPq + widx[i];
                                g[i] = (uint32_t)((dw % MAT_DW) * 2654435761u);
                            }
                            uint32_t hh[NWQq];
                            if (pre == 0) for (int i = 0; i < NWQq; ++i) hh[i] = g[i];
                            else {
                                for (int i = 0; i + 1 < NWQq; ++i) hh[i] = (g[i] >> pre) | (g[i + 1] << (32 - pre));
                                hh[NWQq - 1] = g[NWQq - 1] >> pre;
                            }
                            for (int i = 0; i < NWQq; ++i) fold ^= hh[i];
                        }
                }
            }
            if (hb[(size_t)us_ * 288 + 256] != fold) { ++bad; printf("VERIFY u%d dev %08x host %08x\n", us_, hb[(size_t)us_ * 288 + 256], fold); }
        }
        printf("VERIFY %s\n", bad ? "MISMATCH (loads/coverage differ!)" : "OK (all bytes really read)");
    }
    sycl::free(b, q); sycl::free(sink, q);
    return 0;
}