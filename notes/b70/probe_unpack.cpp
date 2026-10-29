// -----------------------------------------------------------------------------
// probe_unpack.cpp - does ALIGNED GROUP ASSIGNMENT make trellis extraction cheaper?
//
// Why this exists. E28's ceiling probe (probe_gemv -DGEMV_CONSTSHIFT) showed x1.5-2.1 at rows=1, but it
// lied about the data on purpose. Building the real thing ran into a structural tension: aligned
// extraction wants each lane to own a k-contiguous run of windows (that is what makes the shift amounts
// compile-time constants), while the dp4a accumulator wants each lane to own a COLUMN pair (that is what
// keeps the running sums in registers with no cross-lane reduce). Buying alignment therefore costs a
// cross-lane reduction through SLM - which this session has already measured as not free at low group
// counts. Before restructuring the accumulators, price the extraction half on its own.
//
// Both kernels below visit the same 256 ring positions per tile, so their checksums MUST agree - that
// equality is the test of the aligned group/position mapping, independent of any reference.
//
// STATUS: kernel A's total (8,360,138,626 on /tmp/gemv_dpE10) reproduces the authoritative sum from
// tests/testlib/trellis.py exactly. Kernel B is short by 0.02%, so its mapping has a bug and its x1.30
// timing is NOT believed. The reassignment turned out to be unnecessary anyway: rev C's existing lane
// groups are already contiguous 32-window runs whose intra-dword offset is lane-invariant, so compiling
// K in (-DGEMV_KCONST in probe_gemv) buys constant shifts with no reassignment, no cross-lane reduce and
// no layout change - measured x1.90 at rows=1, bit-exact. Kept as the record of a wrong turn.
//
//   A: rev C's assignment. lane = (q0 = l&7, sub = l>>3); per tile a lane walks t = 4*q0 + a4 (a4=0..3)
//      and j = 0..7, i.e. its column pair's windows. Shift amount depends on the lane's dword bit offset
//      at run time, so every window costs a variable 64-bit shift plus a V01/V12 select.
//   B: aligned groups (K = 3). Window i occupies ring bits [3i-16, 3i); 3i = 16 (mod 32) solves at
//      i = 16 with period 32, so group g covers positions 16+32g .. 47+32g and its base bit 32+96g is
//      dword-aligned. 8 groups, 8 lanes -> one group per lane, 32 windows each. Within a group the bit
//      offset of window w is 3w: a COMPILE-TIME constant once unrolled, so extraction is two dword
//      shifts and an or - no variable shift, no select, and the four dwords are read once per group.
//
// K=3 only, on purpose: it is the recipe of record and the only case where the shift constants fold.
// If B does not win here, no accumulator restructuring is worth building and E28 closes negative.
//
// Build: notes/b70/build.sh probe_unpack    Run: ./probe_unpack CASE_DIR [reps] [kernel 0|1]
// -----------------------------------------------------------------------------
#include <sycl/sycl.hpp>

#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <string>
#include <vector>

static constexpr int K3 = 3;          // trellis bits per window in this probe
static constexpr int NGRP = 8;        // aligned groups per tile (256 positions / 32)
static constexpr int PER_GRP = 32;    // windows per group
static constexpr uint32_t MUL1 = 0x83DCD12Du;

struct Meta
{
    int E = 0, tk = 0, tn = 0;
    double K = 0;
    int tiles() const { return E * tk * tn; }
};

static std::vector<char> slurp(const std::string &p)
{
    std::ifstream f(p, std::ios::binary | std::ios::ate);
    if (!f) { fprintf(stderr, "missing %s\n", p.c_str()); exit(2); }
    std::streamsize sz = f.tellg(); f.seekg(0);
    std::vector<char> b((size_t)sz);
    f.read(b.data(), sz);
    return b;
}

static Meta load_meta(const std::string &dir)
{
    std::ifstream f(dir + "/meta.json");
    std::string s((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
    auto get = [&](const char *k) -> double {
        size_t i = s.find(std::string("\"") + k + "\"");
        if (i == std::string::npos) return 0;
        i = s.find(':', i); return atof(s.c_str() + i + 1);
    };
    Meta m; m.E = (int)get("E"); m.tk = (int)get("tk"); m.tn = (int)get("tn"); m.K = get("K");
    return m;
}

static inline uint32_t bytesum(uint32_t prod)
{
    return (prod & 255u) + ((prod >> 8) & 255u) + ((prod >> 16) & 255u) + (prod >> 24);
}

// ---- A: rev C's column-pair assignment (variable shifts) -------------------
static void unpack_a(sycl::queue &q, const uint32_t *W, uint32_t *OUT, const Meta &m)
{
    const int tn = m.tn, nw = 8 * K3, RB = 256 * K3;
    const int groups = m.tiles() / 4;              // 4 tiles per work-group (4 subsets x 8 lanes)
    q.submit([&](sycl::handler &cgh)
    {
        cgh.parallel_for(sycl::range<1>(groups * 32), [=](sycl::id<1> id)
        {
            const int l = (int)id[0] & 31;
            const int gid = (int)(id[0] >> 5);
            const int q0 = l & 7, sub = l >> 3;
            const int tile = gid * 4 + sub;
            const uint32_t *dw = W + (size_t)tile * nw;
            uint32_t sum = 0;
            for (int a4 = 0; a4 < 4; ++a4)
            {
                const int t = 4 * q0 + a4;
                const int o0 = K3 * (t * 8 + 1) - 16;
                const int o = o0 < 0 ? o0 + RB : (o0 >= RB ? o0 - RB : o0);
                const uint32_t wi = (uint32_t)o >> 5, of = (uint32_t)o & 31u;
                const uint32_t d0 = dw[wi];
                const uint32_t d1 = dw[(wi + 1 == nw) ? 0u : wi + 1u];
                const uint32_t d2 = dw[(wi + 2 >= nw) ? (wi + 2 - nw) : wi + 2u];
                const uint64_t V01 = ((uint64_t)d0 << 32) | d1;
                const uint64_t V12 = ((uint64_t)d1 << 32) | d2;
                for (int j = 0; j < 8; ++j)
                {
                    const int s = (int)of + K3 * j;
                    const uint32_t win = (uint32_t)((s >= 32 ? (V12 >> (48u - (uint32_t)(s - 32)))
                                                             : (V01 >> (48u - (uint32_t)s))) & 0xFFFFu);
                    sum += bytesum(win * MUL1);
                }
            }
            // every lane publishes its own partial; the host sums them, so no cross-lane shuffle is
            // needed here (this probe measures extraction, not reduction)
            OUT[(size_t)id[0]] = sum;
        });
    });
}

// ---- B: aligned groups (compile-time shift amounts, no select) --------------
static void unpack_b(sycl::queue &q, const uint32_t *W, uint32_t *OUT, const Meta &m)
{
    const int tn = m.tn, nw = 8 * K3;
    const int groups = m.tiles() / 4;              // same work per item as A: 32 windows
    q.submit([&](sycl::handler &cgh)
    {
        cgh.parallel_for(sycl::range<1>(groups * 32), [=](sycl::id<1> id)
        {
            const int l = (int)id[0] & 31;
            const int gid = (int)(id[0] >> 5);
            const int sub = l >> 3, g = l & 7;     // one aligned group per lane
            const int tile = gid * 4 + sub;
            const uint32_t *dw = W + (size_t)tile * nw;
            const uint32_t db = 1 + 3 * (uint32_t)g;          // dword-aligned group base
            const uint32_t d0 = dw[db % nw];
            const uint32_t d1 = dw[(db + 1) % nw];
            const uint32_t d2 = dw[(db + 2) % nw];
            const uint32_t d3 = dw[(db + 3) % nw];
            uint32_t sum = 0;
            // Window w of the group starts at bit 3w of the 128-bit group, so (di, bi) are constants
            // once unrolled: no variable shift, no straddle select, no per-window address math.
            #pragma unroll
            for (int w = 0; w < PER_GRP; ++w)
            {
                const uint32_t sh = (uint32_t)(K3 * w);
                const uint32_t di = sh >> 5, bi = sh & 31u;
                uint32_t lo, hi;
                switch (di)
                {
                    case 0: lo = d0; hi = d1; break;
                    case 1: lo = d1; hi = d2; break;
                    case 2: lo = d2; hi = d3; break;
                    default: lo = d3; hi = d0; break;
                }
                const uint32_t win = bi == 0 ? (lo & 0xFFFFu)
                                             : ((lo >> bi) | (hi << (32u - bi))) & 0xFFFFu;
                sum += bytesum(win * MUL1);
            }
            OUT[(size_t)id[0]] = sum;
        });
    });
}

int main(int argc, char **argv)
{
    if (argc < 2) { fprintf(stderr, "usage: %s CASE_DIR [reps] [kernel 0|1|2=both]\n", argv[0]); return 2; }
    const std::string dir = argv[1];
    const int reps = argc > 2 ? atoi(argv[2]) : 21;
    const int which = argc > 3 ? atoi(argv[3]) : 2;
    Meta m = load_meta(dir);
    if (m.K != 3.0) { fprintf(stderr, "this probe is K=3 only (case K=%g)\n", m.K); return 2; }

    auto wbuf = slurp(dir + "/weights.bin");
    const int groups = m.tiles() / 4;
    printf("case %s: tiles %d  work-groups %d  windows %d  bytes %.2f MiB (%.3f B/window)\n",
           dir.c_str(), m.tiles(), groups, m.tiles() * 256, wbuf.size() / 1048576.0,
           wbuf.size() / (double)(m.tiles() * 256));

    sycl::device dev{sycl::gpu_selector_v};
    sycl::context ctx{dev};
    sycl::queue q{ctx, dev, sycl::property::queue::in_order{}};
    uint32_t *W = (uint32_t *)sycl::malloc_device(wbuf.size(), q);
    uint32_t *O0 = (uint32_t *)sycl::malloc_device((size_t)groups * 32 * 4, q);
    uint32_t *O1 = (uint32_t *)sycl::malloc_device((size_t)groups * 32 * 4, q);
    q.memcpy(W, wbuf.data(), wbuf.size());
    q.wait();

    const double win_count = (double)m.tiles() * 256.0;
    struct Res { double us; uint64_t ck; bool ok; };
    auto bench = [&](int kern, uint32_t *O) -> Res
    {
        auto run = [&] { kern ? unpack_b(q, W, O, m) : unpack_a(q, W, O, m); };
        double best = 1e30;
        for (int r = 0; r < reps + 2; ++r)
        {
            auto t0 = std::chrono::steady_clock::now();
            run(); q.wait();
            double s = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
            if (r >= 2 && s < best) best = s;
        }
        const int BURST = 8;
        double tp = 1e30;
        for (int w = 0; w < 2; ++w) { for (int i = 0; i < 3; ++i) run(); q.wait(); }
        for (int r = 0; r < 4; ++r)
        {
            auto t0 = std::chrono::steady_clock::now();
            for (int i = 0; i < BURST; ++i) run();
            q.wait();
            double s = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count() / BURST;
            if (s < tp) tp = s;
        }
        std::vector<uint32_t> h((size_t)groups * 32);
        q.memcpy(h.data(), O, h.size() * 4); q.wait();
        uint64_t ck = 0; for (uint32_t v : h) ck += v;
        return {tp * 1e6, ck, true};
    };

    Res ra{0, 0, false}, rb{0, 0, false};
    if (which != 1) ra = bench(0, O0);
    if (which != 0) rb = bench(1, O1);
    const double slots_per_win = 1.43e12 / 32.0;   // issue budget per lane-slot, for reference only
    if (which != 1)
        printf("A column-pair assignment (variable shifts) : %8.1f us  %7.1f G-windows/s  %5.2f ns/win  ck %llu\n",
               ra.us, win_count / ra.us / 1e3, ra.us * 1e3 / win_count, (unsigned long long)ra.ck);
    if (which != 0)
        printf("B aligned groups (constant shifts)         : %8.1f us  %7.1f G-windows/s  %5.2f ns/win  ck %llu\n",
               rb.us, win_count / rb.us / 1e3, rb.us * 1e3 / win_count, (unsigned long long)rb.ck);
    if (which == 2)
    {
        printf("\naligned extraction gain: x%.2f   checksums match: %s  (must be yes - same 256 windows)\n",
               ra.us / rb.us, ra.ck == rb.ck ? "YES" : "NO");
        printf("slots/weight at the issue budget: A %.2f  B %.2f\n",
               1.43e12 * ra.us * 1e-6 / win_count, 1.43e12 * rb.us * 1e-6 / win_count);
        (void)slots_per_win;
    }
    sycl::free(W, q); sycl::free(O0, q); sycl::free(O1, q);
    return 0;
}