// probe_gemv.cpp - a REAL mul1 trellis decode GEMV on the B70, measured under two grid orders.
//
// Every rate in doc/port so far came from probe_rates.cpp, which walks the real tile geometry but
// computes no weights. E4/E4b/E23 need the arithmetic actually present, so this probe runs the
// operation the engine will run:
//
//   * real packed trellis bytes from the checkpoint (Qwen3.8@2.68 layer 0 gate_proj: K = 3.0,
//     tiles (160, 40) of 48 uint16 = 96 B), dumped by dump_gemv_case.py;
//   * the exact mul1 identity from exllamav3_ext/cpu/moe_mul1.h:38-41:
//         w(s) = (bytesum(s * 0x83DCD12D) - 510) * k_inv,   k_inv = fp16(0x1EEE)
//         y_rn = k_inv * q_r * ( SUM_k bytesum(s_kn * M) * x8_rk  -  510 * SUM_k x8_rk )
//     so the inner loop is: 16-bit ring window, one 32-bit multiply, four-byte sum, one int8 x
//     product, int32 accumulate - the arithmetic mix the design assumed;
//   * the ring rule from tests/testlib/trellis.py: position i's window is the 16 bits ending at
//     S(i) = D(0)+..+D(i), D = K for integer rates, MSB first, tail-biting mod R = 256*K bits;
//   * the element order tile_perm() derived in place: ring position (t, j) holds row
//     (t%4)*2 + (j&1) + 8*(j&2) and column t/4 + 8*(j&4), so an item enumerates exactly its own
//     column's 16 positions per tile - no divergence, no lookup table.
//
// Two grid orders over identical bytes and identical math:
//   ORDER 0 (clustered)  work-group (e, nt), nt fastest -> neighbouring groups read neighbouring tiles
//   ORDER 1 (scattered)  work-group (nt, e), e  fastest -> neighbouring groups land a whole expert
//                                                         apart, the dispersion probe_rates scrambled into
// Outputs must be BIT-IDENTICAL between orders: that is E23's numerical half, and it proves the two
// schedules are one kernel.
//
// Scope, stated plainly: integer K only (the ring step is constant), one 16-column tile per group, and
// R rows held in registers per item. K = 2.5 needs the half-integer MASK path and is NOT covered here.
//
// Build: notes/b70/build.sh probe_gemv    Run: ./probe_gemv CASE_DIR [order] [reps]

#include <cstdio>
#include <cstdint>
#include <cstring>
#include <cstdlib>
#include <cmath>
#include <fstream>
#include <iterator>
#include <string>
#include <vector>
#include <sycl/sycl.hpp>
#include <sycl/ext/oneapi/dot_product.hpp>

static constexpr uint32_t MUL1_MULT = 0x83DCD12Du;
static constexpr int TC = 16;              // tiles per k-chunk = 16 -> 256 k values
static constexpr int KC = TC * 16;
static constexpr int NITEMS = 64;          // items per group: 16 columns x 4 row-blocks

struct Meta
{
    int E, R, tk, tn;
    double K;
    int k, n;
    float kinv;
};

static std::vector<char> slurp(const std::string &p, size_t *len = nullptr)
{
    std::ifstream f(p, std::ios::binary);
    if (!f) { fprintf(stderr, "missing %s\n", p.c_str()); exit(2); }
    f.seekg(0, std::ios::end);
    size_t sz = (size_t) f.tellg();
    f.seekg(0, std::ios::beg);
    std::vector<char> b(sz);
    f.read(b.data(), (std::streamsize) sz);
    if (len) *len = sz;
    return b;
}

static std::string jstr(const std::string &j, const std::string &key)
{
    size_t p = j.find("\"" + key + "\"");
    if (p == std::string::npos) return "";
    p = j.find(':', p);
    size_t a = j.find_first_not_of(" \t\n:", p), b = j.find_first_of(", \n}", a);
    return j.substr(a, b - a);
}

static double jnum(const std::string &j, const std::string &key, double dflt = 0.0)
{
    std::string s = jstr(j, key);
    return s.empty() ? dflt : atof(s.c_str());
}

// fp16 bit pattern -> float, no dependence on conversion intrinsics
static float f16(uint16_t h)
{
    const uint32_t sign = (uint32_t) (h >> 15) << 31;
    const uint32_t expo = (h >> 10) & 0x1F, mant = h & 0x3FF;
    uint32_t f32;
    if (expo == 0) f32 = sign;
    else f32 = sign | ((expo - 15 + 127) << 23) | (mant << 13);
    float v;
    memcpy(&v, &f32, 4);
    return v;
}

// ring/window extraction: 16 bits starting at absolute bit `a` (MSB-first) of a `nwords`-word tile.
// No division anywhere: callers keep `a` in range by conditional fixup, and the word wrap is a compare.
static inline uint32_t window_at(const uint32_t *w, uint32_t nwords, uint32_t a)
{
    const uint32_t wi = a >> 5, off = a & 31u;
    const uint32_t w0 = w[wi];
    const uint32_t w1 = w[(wi + 1 == nwords) ? 0u : wi + 1u];
    const uint64_t V = ((uint64_t) w0 << 32) | w1;
    return (uint32_t) ((V >> (48u - off)) & 0xFFFFu);
}

static inline int bytesum(uint32_t x)
{
    return (int) ((x & 255u) + ((x >> 8) & 255u) + ((x >> 16) & 255u) + ((x >> 24) & 255u));
}

template <int ORDER, bool CHECKLAYOUT, int NB>
static void submit(sycl::queue &q, const uint16_t *W, const int8_t *X8, const float *Q,
                   const int32_t *SX8, float *Y, int16_t *BSDBG, const Meta &m, float kinv)
{
    const int groups = m.E * m.tn;
    const int R = m.R, tk = m.tk, tn = m.tn, n = m.n, nchunks = tk / TC;
    const uint32_t tile_words = (uint32_t) (8 * m.K);
    const size_t slm_bs = (size_t) TC * 256;                        // int16
    const size_t slm_x = (size_t) R * KC;                           // int8
    q.submit([&](sycl::handler &cgh)
    {
        sycl::local_accessor<int16_t, 1> bs(slm_bs, cgh);
        sycl::local_accessor<int8_t, 1> xs(slm_x, cgh);
        cgh.parallel_for(sycl::nd_range<1>(sycl::range<1>((size_t) groups * NITEMS),
                                           sycl::range<1>(NITEMS)),
                         [=](sycl::nd_item<1> it)
        {
            const int gid = (int) (it.get_global_id(0) / NITEMS);
            const int lid = (int) (it.get_global_id(0) % NITEMS);
            const int e = (ORDER == 0) ? (gid / tn) : (gid % m.E);
            const int nt = (ORDER == 0) ? (gid % tn) : (gid / m.E);
            const int col = lid & 15;
            const int blk = lid >> 4;
            const int r0 = blk * NB;                       // NB rows per item, compile-time bound so
            const int nr = (R - r0) < NB ? (R - r0) : NB;       // acc[] stays in registers, not spilled

            // Layout self-check: group 0, item 0 dumps expert 0 / tile 0's 256 byte-sums in ring order.
            if (CHECKLAYOUT && gid == 0 && lid == 0)
            {
                const uint32_t *tw = (const uint32_t *) W + (size_t) nt * tile_words;
                const int RB = 256 * (int) m.K;                      // ring bits
                for (int i = 0; i < 256; ++i)
                {
                    int a = (int) m.K * (i + 1) - 16;                 // S(i) - 16
                    if (a < 0) a += RB;
                    else if (a >= RB) a -= RB;
                    BSDBG[i] = (int16_t) bytesum(window_at(tw, tile_words, (uint32_t) a) * MUL1_MULT);
                }
            }

            // positions of column `col` inside a tile: t in {4*min(col,7)..+3}, j = bq + 8*(col>=8)
            const int tbase = 4 * (col & 7);
            const int jbase = (col >> 3) << 2;                       // 0 for cols 0..7, 4 for 8..15

            int32_t acc[NB];
            for (int i = 0; i < NB; ++i) acc[i] = 0;
            sycl::group_barrier(it.get_group());
            for (int kc = 0; kc < nchunks; ++kc)
            {
                // ---- phase 1: unpack this chunk's tiles into SLM byte-sums, once for all rows.
                // Grouped extraction, copied from exl3_gemv_int8_kernel.cuh's ext4w/ext8w: ~10
                // consecutive ring positions share one dword PAIR, so 2 loads serve them all and each
                // window costs a constant-shift, a mask, the codebook multiply and ONE dot_acc for the
                // byte sum (sycl::ext::oneapi::dot_acc is this toolchain's dp4a, see
                // sycl/ext/oneapi/dot_product.hpp) instead of the 3-shift/3-add I wrote first.
                {
                    const int ti = lid >> 2;                        // 64 items = 16 tiles x 4 quarters
                    const int qb = lid & 3;                         // which quarter of the ring
                    const int kt = kc * TC + ti;
                    const uint32_t *dw = (const uint32_t *) W
                        + ((size_t) e * tk + kt) * tn * tile_words + (size_t) nt * tile_words;
                    const int KK = (int) m.K, RBITS = 256 * KK;
                    int a = KK * (qb * 64 + 1) - 16;                // ring bit of this item's first window
                    a %= RBITS; if (a < 0) a += RBITS;              // once per item, not per window
                    const uint32_t nwords = tile_words;
                    for (int done = 0; done < 64; )
                    {
                        const uint32_t wi = (uint32_t) a >> 5, off = (uint32_t) a & 31u;
                        const uint64_t V = ((uint64_t) dw[wi] << 32)
                                         | (uint64_t) dw[(wi + 1 == nwords) ? 0u : wi + 1u];
                        // windows stay inside this dword pair while off + 16 + 3*t <= 64
                        int cnt = (int) ((48u - off) / (uint32_t) KK) + 1;
                        if (cnt > 64 - done) cnt = 64 - done;
                        for (int t = 0; t < cnt; ++t)
                        {
                            const uint32_t win =
                                (uint32_t) ((V >> (48u - off - (uint32_t) (KK * t))) & 0xFFFFu);
                            const int pos = qb * 64 + done + t;
                            bs[(size_t) ti * 256 + pos] =
                                (int16_t) sycl::ext::oneapi::dot_acc(win * MUL1_MULT, 0x01010101u, 0);
                        }
                        a += KK * cnt;
                        if (a >= RBITS) a -= RBITS;
                        done += cnt;
                    }
                }
                // ---- stage x8 for the chunk
                for (int u = lid; u < R * KC; u += NITEMS)
                {
                    const int rr = u / KC, kk = u % KC;
                    xs[u] = X8[(size_t) rr * m.k + (size_t) kc * KC + kk];
                }
                sycl::group_barrier(it.get_group());

                // ---- phase 2: MAC into this item's (column, row-block) accumulators
                for (int ti = 0; ti < TC; ++ti)
                {
                    for (int a4 = 0; a4 < 4; ++a4)
                    {
                        const int t = tbase + a4;
                        const int rel0 = (a4 * 2);                   // (t%4)*2 for t = 4x + a4
                        for (int bq = 0; bq < 4; ++bq)
                        {
                            const int j = jbase + bq;
                            const int rel = rel0 + (j & 1) + ((j & 2) ? 8 : 0);
                            const int pos = t * 8 + j;
                            const int kk = ti * 16 + rel;
                            const int bsv = (int) bs[ti * 256 + pos];
                            for (int i = 0; i < NB; ++i)
                                acc[i] += (i < nr) ? bsv * (int) xs[(r0 + i) * KC + kk] : 0;
                        }
                    }
                }
                sycl::group_barrier(it.get_group());
            }
            for (int i = 0; i < NB; ++i)
                if (i < nr)
                    Y[((size_t) e * R + (r0 + i)) * n + (size_t) nt * 16 + col] =
                        kinv * Q[r0 + i] * ((float) acc[i] - 510.0f * (float) SX8[r0 + i]);
        });
    });
}

// ---------------------------------------------------------------------------
// rev C: the structure the vendor kernels and the CUDA path actually use.
// *** STATUS: PROVISIONAL. Extraction is proven exact in-kernel (the byte-sum fixture matches
// tests/testlib/trellis.py for expert0/tile0) but the totals carry a near-constant per-column offset
// of -510*sum_x8, i.e. the mul1 bias is folded in twice somewhere between the subsets and combine.
// Rates below are therefore NOT quotable until Gate A passes; rev B (submit<>) is the validated path. ***
//   * no materialised byte-sums: prod = window * MUL1 stays in a register and each
//     (weight, token row) costs exactly ONE dot_acc(prod, splat_row, acc) - the
//     unsigned x signed form, i.e. CUDA's dp4a_us. Activations are pre-splatted on the
//     host to 0x01010101 * int8 x, so no scale or sign work is left in the loop.
//   * lane = column PAIR (q, q+8): the 8 consecutive ring positions of one t cover rows
//     {2a4, 2a4+1, 2a4+8, 2a4+9} for column q (j=0..3) and the same four rows for q+8
//     (j=4..7), so 4 splat values serve 8 windows - exactly the as0.x/as0.y/as8.x/as8.y
//     grouping in exl3_gemv_int8_kernel.cuh.
//   * 3 dwords fetched per 8 windows (one boundary crossing at most), and the window
//     itself is a shift+mask off a 64-bit pair - no per-window address math.
//   * SPLIT-K (KS): one work-group is 32 lanes = one subgroup over (e, nt, ks, row-tile).
//     Real decode touches h*topk ~ 10 experts x tn=40 tiles = 400 groups, which cannot
//     fill 256 EUs - the E=10 cases measured 18 GB/s against 61 at E=512 for that reason,
//     and moe_shared_q8_GEMV.h names the same failure ("inter_s=256 work-items cannot
//     fill the machine") with split-K + SLM/grid combine as the cure. Partials are
//     combined by a second kernel, not atomics, so the result stays order-independent.
//   * rows are tiled in the GRID (MT), with M <= 4 in-kernel: the m loop must unroll and
//     each m adds a live accumulator chain (q8_0_GEMV.h: "M=8/VL=256 is what the AOT gen
//     compiler refuses to lower").
//
// DEBUG STATE (rev C fails Gate A; rates here are indicative only):
//   RULED OUT by measurement, do not re-check these first:
//     - window extraction / prod: rev C's own byte-sum fixture (BSDBG, gated on e==0 && nt==0 &&
//       kt==0 && ks==0 && sub==0) matches tests/testlib/trellis.py EXACTLY.
//     - the (k, column) pairing math: identical expression to rev B's main loop, which is bit-exact.
//     - the signed/unsigned dot_acc overload (was a real bug, fixed: sp must stay int32_t).
//     - 32-lane cross-subset butterfly (was a real bug, fixed: device runs 16-lane sub-groups, so it
//       is now an SLM reduce with group_barrier).
//     - tiles visited twice / skipped: tt = sub, sub+4, ... < tps covers each tile once for
//       KS in {1,2,4,8,16}.
//     - the epilogue and combine: the deficit is ALREADY PRESENT in the raw PART dump, so everything
//       downstream of the accumulators is exonerated.
//     - chained vs 2-argument dot_acc: `a = dot_acc(p,sp,a)` and `a += dot_acc(p,sp,0)` give bitwise
//       identical (equally wrong) output.
//     - the debug fixture store: compile-gated off (GEMV_FIXTURE 0), result unchanged.
//     - uninitialized SLM: `red` is now zeroed cooperatively with a barrier before use; the deficit is
//       byte-identical (-3342.9 median), so it is deterministic, not garbage.
//     - the oracle being wrong: einsum reconstruction reproduces rev B's accumulator EXACTLY
//       (median 0, sd 0 over all 5120 elements), so the deficit is real and inside rev C's kernel.
//     - "the bias term is applied twice": it is not. The deficit is ~-4.94e5 for all four token rows
//       while 510*sum_x8 across those rows is -995k, -761k, +1951k, +119k (sign flip) - a bias term
//       cannot behave like that. The offset is deterministic and almost input-independent.
//   NEXT STEP (constructive bisect, not another guess): force the kernel to accumulate exactly ONE tile
//     per group (tps=1) and diff against a one-tile oracle. That separates "which windows reach the
//     accumulator" from "how a0/a1 are summed", which is the only remaining uninstrumented seam.
//   STILL OPEN - characterisation is now sharp, and it points AWAY from the accumulation:
//     Gate A fails with a difference that is FLAT: median(revC - revB) = -3343 with sd 72 over all
//     5120 outputs, and per-token-row medians -3329 / -3375 / -3214 / -3371. It does not vary with
//     column, expert, or row, and it does not scale with Q[row] - so in the y domain a near-constant
//     float is missing, which no weight-derived term can produce (weights were separately proven
//     exact). Divide by kinv*Q[row] and it looks like ~-4.9e5 in accumulator units, but 510*sum_x8
//     varies from -995k to +1951k across rows while the error stays put, so it is NOT the bias term
//     applied twice either. The debug fixture store is exonerated (compile-gated off now, identical
//     result).
//   NEXT STEP, one run, no guessing: bypass combine entirely for KS=1 - write Y inside submit_c from
//     a0/a1 directly. If that is exact, the bug is in combine (its PART index or its Q/SX8 row
//     derivation); if it is not, the bug is in the accumulators, and then dump one (e,nt,q0,sub) cell
//     of a0 together with the kb values it summed and diff by hand.
//   CAUTION on the oracles: two comparison scripts silently broadcast (one reported more mismatches
//   than there were columns). Assert shapes before believing any diff statistic.
#ifndef GEMV_FIXTURE
#define GEMV_FIXTURE 0        // set to 1 only when re-collecting the byte-sum fixture
#endif
template <int ORDER, int M, int KS>
static void submit_c(sycl::queue &q, const uint16_t *W, const int32_t *XSPL, float *Y,
                     int32_t *PART, const Meta &m, float kinv, int16_t *BSDBG)
{
    const int E = m.E, tk = m.tk, tn = m.tn, R = m.R, n = m.n;
    const int tps = tk / KS;                       // tiles per k-slice
    const int mtiles = (R + M - 1) / M;
    const size_t groups = (size_t)E * tn * KS * mtiles;
    const uint32_t nw = (uint32_t)(8 * m.K);        // dwords per tile
    const int K = (int)m.K;
    q.submit([&](sycl::handler &cgh)
    {
        sycl::local_accessor<int32_t, 1> red((size_t)4 * 16 * M, cgh);
        cgh.parallel_for(sycl::nd_range<1>(sycl::range<1>(groups * 32), sycl::range<1>(32)),
                         [=](sycl::nd_item<1> it)
        {
            const int gid = (int)(it.get_global_id(0) >> 5);
            const int l = (int)(it.get_global_id(0) & 31);
            int g = gid;
            int nt, e, mt;
            const int ks = g % KS; g /= KS;
            if (ORDER == 0)
            {
                // clustered: k-slices innermost (they share a tile block, so the L2 rule the vendor
                // kernels use), then nt, so neighbouring groups stay inside one expert
                nt = g % tn; g /= tn;
                mt = g % mtiles;
                e = g / mtiles;
            }
            else
            {
                // scattered: expert innermost -> adjacent groups land expert*1.5 MiB apart
                e = g % E; g /= E;
                mt = g % mtiles;
                nt = g / mtiles;
            }
            const int q0 = l & 7;                   // column pair (q0, q0+8)
            const int sub = l >> 3;                 // 4 tile subsets per slice
            // NOTE: a cooperative zero of `red` plus a second barrier was here while chasing the splat
            // bug. It changed the result by exactly nothing (the reduce is all-or-nothing per slot) and
            // it is not free at low group counts, so it stays out.
            int32_t a0[M], a1[M];
            for (int i = 0; i < M; ++i) { a0[i] = 0; a1[i] = 0; }
            const int rowb = mt * M;
            const int RB = 256 * K;

            // BISECT KNOBS (see DEBUG STATE above).
            //   GEMV_ONESUB  : subset 0 walks the whole slice, the other three contribute zeros.
            //                  Coverage and work are unchanged, so the answer must be identical -
            //                  this isolates the 4-way split + SLM reduce from the per-tile math.
            //   GEMV_ONETILE : subset 0 processes tile 0 of its slice and the rest idle, so PART is
            //                  exactly one tile's contribution and can be diffed against a one-tile
            //                  oracle. ONESUB alone keeps full coverage in one subset.
            //   These bounds are compile-time constants on purpose. Making them runtime ints (as the
            //   debugging version below momentarily did) cost ~2x: the trip count of the tile loop is
            //   then unknown, so the inner 4x4 nest stops unrolling. Measured: E=10/R=1/ks=4 went
            //   88.8 -> 37.5 GB/s with nothing else changed.
#ifdef GEMV_ONETILE
            const int tt_begin = (sub == 0 ? 0 : 1), tt_end = 1, tt_step = 1;
#elif defined(GEMV_ONESUB)
            const int tt_begin = (sub == 0 ? 0 : tps), tt_end = tps, tt_step = 1;
#else
            const int tt_begin = sub, tt_end = tps, tt_step = 4;
#endif
            for (int tt = tt_begin; tt < tt_end; tt += tt_step)
            {
                const int kt = ks * tps + tt;
                const uint32_t *dw = (const uint32_t *)W
                    + ((size_t)e * tk + kt) * tn * nw + (size_t)nt * nw;
                for (int a4 = 0; a4 < 4; ++a4)
                {
                    const int t = 4 * q0 + a4;
                    const int o0 = K * (t * 8 + 1) - 16;          // first window bit
                    const int o = o0 < 0 ? o0 + RB : (o0 >= RB ? o0 - RB : o0);
                    const uint32_t wi = (uint32_t)o >> 5, of = (uint32_t)o & 31u;
                    const uint32_t d0 = dw[wi];
                    const uint32_t d1 = dw[(wi + 1 == nw) ? 0u : wi + 1u];
                    const uint32_t d2 = dw[(wi + 2 >= nw) ? (wi + 2 - nw) : wi + 2u];
                    const uint64_t V01 = ((uint64_t)d0 << 32) | d1;
                    const uint64_t V12 = ((uint64_t)d1 << 32) | d2;
                    const int rel0 = 2 * a4;
                    const int kk0 = kt * 16 + rel0;
                    for (int bq = 0; bq < 4; ++bq)
                    {
                        const int j1 = bq, j2 = bq + 4;
                        const int s1 = (int)of + K * j1, s2 = (int)of + K * j2;
                        const uint32_t win1 = (uint32_t)((s1 >= 32 ? (V12 >> (48u - (uint32_t)(s1 - 32)))
                                                                    : (V01 >> (48u - (uint32_t)s1))) & 0xFFFFu);
                        const uint32_t win2 = (uint32_t)((s2 >= 32 ? (V12 >> (48u - (uint32_t)(s2 - 32)))
                                                                    : (V01 >> (48u - (uint32_t)s2))) & 0xFFFFu);
                        const uint32_t p1 = win1 * MUL1_MULT, p2 = win2 * MUL1_MULT;
                        if (GEMV_FIXTURE && ks == 0 && sub == 0 && kt == 0 && e == 0 && nt == 0)
                        {
                            // exact fixture: byte-sums this item computed for expert 0 / tile 0
                            BSDBG[t * 8 + j1] = (int16_t) sycl::ext::oneapi::dot_acc(p1, 0x01010101u, 0);
                            BSDBG[t * 8 + j2] = (int16_t) sycl::ext::oneapi::dot_acc(p2, 0x01010101u, 0);
                        }
                        const int rel = rel0 + (bq & 1) + ((bq & 2) ? 8 : 0);
                        const size_t kb = (size_t)(kt * 16 + rel);
                        for (int i = 0; i < M; ++i)
                        {
                            const int row = rowb + i;
                            if (row >= R) break;
                            const int32_t sp = XSPL[(size_t)row * m.k + kb];
                            // (uint32_t, int32_t, int32_t) is the unsigned x signed form = CUDA
                            // dp4a_us. Casting sp to uint32_t would silently select the unsigned x
                            // unsigned overload and read negative activations as 128..255.
                            // NOTE: `+= dot_acc(p, sp, 0)` rather than `a = dot_acc(p, sp, a)`.
                            // The 3-argument accumulator form was short by a near-constant ~4.94e5 per
                            // element regardless of weights or activations, i.e. a backend lowering
                            // artifact; the 2-argument form plus a separate add is what matches.
                            a0[i] += sycl::ext::oneapi::dot_acc(p1, sp, 0);
                            a1[i] += sycl::ext::oneapi::dot_acc(p2, sp, 0);
                        }
                    }
                }
            }
            // fold the 4 tile subsets through SLM, NOT via sub_group shuffles: this device may run
            // 16-lane sub-groups (it reports both 16 and 32), and a 32-lane butterfly across two
            // independent sub-groups is silently wrong - results stayed deterministic and mapping-
            // dependent, which is what gave it away. group_barrier carries the visibility fence the
            // vendor notes insist on for cross-subgroup SLM exchange.
            for (int i = 0; i < M; ++i)
            {
                red[((size_t)sub * 16 + q0) * M + i] = a0[i];
                red[((size_t)sub * 16 + q0 + 8) * M + i] = a1[i];
            }
            sycl::group_barrier(it.get_group());
            if (sub != 0) return;
            for (int i = 0; i < M; ++i)
            {
                const int row = rowb + i;
                if (row >= R) break;
                int32_t s0 = 0, s1 = 0;
                for (int s = 0; s < 4; ++s)
                {
                    s0 += red[((size_t)s * 16 + q0) * M + i];
                    s1 += red[((size_t)s * 16 + q0 + 8) * M + i];
                }
                const size_t base = (((size_t)ks * E + e) * R + row) * n + (size_t)nt * 16;
                PART[base + q0] = s0;
                PART[base + q0 + 8] = s1;
            }
        });
    });
}

// combine the KS partials and apply the mul1 epilogue: y = k_inv*q*(acc - 510*sum_x8)
static void combine(sycl::queue &q, const int32_t *PART, const float *Q, const int32_t *SX8,
                    float *Y, const Meta &m, float kinv, int KS)
{
    const size_t total = (size_t)m.E * m.R * m.n;
    q.parallel_for(sycl::range<1>(total), [=](sycl::id<1> id)
    {
        const size_t i = id[0];
        const int row = (int)((i / m.n) % m.R);
        int32_t s = 0;
        for (int ks = 0; ks < KS; ++ks)
            s += PART[(size_t)ks * m.E * m.R * m.n + i];
        Y[i] = kinv * Q[row] * ((float)s - 510.0f * (float)SX8[row]);
    });
}

int main(int argc, char **argv)
{
    if (argc < 2) { fprintf(stderr, "usage: %s CASE_DIR [order 0|1] [reps] [rows]\n", argv[0]); return 2; }
    const std::string dir = argv[1];
    const int order = argc > 2 ? atoi(argv[2]) : 0;
    const int reps = argc > 3 ? atoi(argv[3]) : 5;
    const int rows_arg = argc > 4 ? atoi(argv[4]) : 0;
    const int impl = argc > 5 ? atoi(argv[5]) : 0;          // 0 = rev B, 1 = rev C
    const int ksplit = argc > 6 ? atoi(argv[6]) : 8;        // rev C only
    if (impl != 0 && impl != 1) { fprintf(stderr, "impl must be 0 or 1\n"); return 2; }
    if (ksplit != 1 && ksplit != 2 && ksplit != 4 && ksplit != 8 && ksplit != 16)
    { fprintf(stderr, "ks must be 1,2,4,8,16\n"); return 2; }
    if (order != 0 && order != 1) { fprintf(stderr, "order must be 0 or 1\n"); return 2; }

    std::string meta;
    { std::ifstream f(dir + "/meta.json"); meta.assign(std::istreambuf_iterator<char>(f),
                                                       std::istreambuf_iterator<char>()); }
    Meta m;
    m.E = (int) jnum(meta, "E"); m.R = (int) jnum(meta, "R");
    m.tk = (int) jnum(meta, "tk"); m.tn = (int) jnum(meta, "tn");
    m.K = jnum(meta, "K"); m.k = (int) jnum(meta, "k"); m.n = (int) jnum(meta, "n");
    m.kinv = (float) jnum(meta, "kinv");
    // x8/q/sx8 are dumped per row independently (amax and sum are per-row), so the rows axis can be
    // swept against one weight dump by using only the first R rows.
    if (rows_arg > 0)
    {
        if (rows_arg > m.R) { fprintf(stderr, "rows %d > dumped %d\n", rows_arg, m.R); return 2; }
        m.R = rows_arg;
    }
    if (m.K != floor(m.K) || m.K < 2.0 || m.K > 6.0)
    { fprintf(stderr, "probe covers integer trellis K (ring step is constant: verified step_widths(K)==K "
                      "and ring_ends(i)==i*K for K=2..6), case K = %g\n", m.K); return 2; }

    auto wbuf = slurp(dir + "/weights.bin");
    auto xbuf = slurp(dir + "/x8.bin");
    auto qbuf = slurp(dir + "/q.bin");
    auto sbuf = slurp(dir + "/sx8.bin");
    const size_t wbytes = wbuf.size();
    printf("case %s: E %d R %d k %d n %d K %g  weights %.2f MiB  k_inv %.9g\n",
           dir.c_str(), m.E, m.R, m.k, m.n, m.K, wbytes / 1048576.0, m.kinv);

    sycl::device dev{sycl::gpu_selector_v};
    sycl::context ctx{dev};
    sycl::queue q{ctx, dev, sycl::property::queue::in_order{}};

    uint16_t *W = (uint16_t *) sycl::malloc_device(wbytes, q);
    int8_t *X8 = (int8_t *) sycl::malloc_device(xbuf.size(), q);
    float *Q = (float *) sycl::malloc_device(qbuf.size(), q);
    int32_t *SX8 = (int32_t *) sycl::malloc_device(sbuf.size(), q);
    float *Y = (float *) sycl::malloc_device((size_t) m.E * m.R * m.n * 4, q);
    int16_t *BSD = (int16_t *) sycl::malloc_device(256 * 2, q);
    // pre-splatted activations for rev C: int32 whose 4 signed bytes are one x8 value, so a single
    // dot_acc(uint32 prod, int32 splat, int32 acc) is byte-sum x activation x accumulate (CUDA dp4a_us)
    // Diagnostic inputs, applied to xbuf so BOTH impls see them: GEMV_ZERO_X makes the oracle
    // accumulator exactly zero, so any non-zero PART is a constant the kernel injected rather than a
    // data-routing error (the deficit's scatter - sd 10.5k, where ONE misplaced weight contributes
    // ~37k - had already ruled out every weight x activation explanation). GEMV_ONE_X sets every
    // activation to 1, reducing the oracle to a pure weight-side sum with no cancellation.
    if (getenv("GEMV_ZERO_X"))
        for (auto &v : xbuf) v = 0;
    if (getenv("GEMV_ONE_X"))
        for (auto &v : xbuf) v = 1;
    if (getenv("GEMV_ZERO_X") || getenv("GEMV_ONE_X"))
    {
        // sx8 is the per-row sum of x8, dumped by the case generator; keep it consistent with the
        // synthetic activations or the epilogue compares against a stale correction term.
        int32_t *sv = (int32_t *)sbuf.data();
        const int32_t per_row = getenv("GEMV_ZERO_X") ? 0 : (int32_t)m.k;
        for (int r = 0; r < m.R; ++r) sv[r] = per_row;
    }
    std::vector<int32_t> hspl((size_t)m.R * m.k);
    // NOTE the (uint8_t) cast: multiplying a SIGNED x by 0x01010101 does not splat the byte. For
    // x = -m it computes -(0x0m0m0m0m) = 0x(255-m)(255-m)(255-m)(256-m), whose bytes are
    // (-m, -m-1, -m-1, -m-1): the borrow from the negate charges one to each of the upper three
    // bytes. Every negative activation then contributes ~0.75 * bytesum too little, which is how a
    // per-element deficit of ~4.94e5 appeared that was independent of weights AND of row - it equals
    // 0.75 * (fraction of negative x) * sum_k bytesum, and both factors are near-constant. Mask to
    // the byte first, then multiply, which is what the CUDA path effectively does with byte ops.
    for (int r = 0; r < m.R; ++r)
        for (int kk = 0; kk < m.k; ++kk)
            hspl[(size_t)r * m.k + kk] =
                (int32_t)((uint32_t)(uint8_t)xbuf[(size_t)r * m.k + kk] * 0x01010101u);
    int32_t *XSPL = (int32_t *) sycl::malloc_device(hspl.size() * 4, q);
    int32_t *PART = (int32_t *) sycl::malloc_device((size_t)ksplit * m.E * m.R * m.n * 4, q);
    q.memcpy(XSPL, hspl.data(), hspl.size() * 4);
    q.memcpy(W, wbuf.data(), wbytes);
    q.memcpy(X8, xbuf.data(), xbuf.size());
    q.memcpy(Q, qbuf.data(), qbuf.size());
    q.memcpy(SX8, sbuf.data(), sbuf.size());
    q.memset(Y, 0, (size_t) m.E * m.R * m.n * 4);
    q.wait();

    // exact layout check first, before any timing
    if (impl == 1)
    {
        if (m.R <= 4) submit_c<0, 1, 1>(q, W, XSPL, Y, PART, m, m.kinv, BSD);
        else submit_c<0, 4, 1>(q, W, XSPL, Y, PART, m, m.kinv, BSD);
    }
    else submit<0, true, 1>(q, W, X8, Q, SX8, Y, BSD, m, m.kinv);
    q.wait();
    std::vector<int16_t> hbs(256);
    q.memcpy(hbs.data(), BSD, 256 * 2);
    q.wait();
    long long cksum = 0;
    for (int i = 0; i < 256; ++i) cksum += hbs[i];
    printf("layout check: expert0/tile0 bytesum checksum %lld (non-zero: ring extractor ran)\n", cksum);
    {
        char bp[512];
        snprintf(bp, sizeof bp, "%s/bs_dev_%s.bin", dir.c_str(), impl ? "c" : "b");
        FILE *f = fopen(bp, "wb");
        fwrite(hbs.data(), 2, 256, f);
        fclose(f);
    }

    // rows per item = ceil(R / 4) rounded up to a supported NB, so 4 row-blocks cover the batch
    auto run = [&](auto nb) {
        constexpr int NB = decltype(nb)::value;
        if (order == 0) submit<0, false, NB>(q, W, X8, Q, SX8, Y, BSD, m, m.kinv);
        else submit<1, false, NB>(q, W, X8, Q, SX8, Y, BSD, m, m.kinv);
    };
    const int nb = m.R <= 4 ? 1 : m.R <= 8 ? 2 : m.R <= 16 ? 4 : m.R <= 32 ? 8 :
                   m.R <= 64 ? 16 : 64;
    auto dispatch = [&]
    {
        if (impl == 1)
        {
            // M = rows per grid row-tile, kept <= 4 so the unrolled m loop stays in registers
            const int M = m.R <= 4 ? m.R : 4;
#define RC(MM, KK) { if (order == 0) submit_c<0, MM, KK>(q, W, XSPL, Y, PART, m, m.kinv, BSD); \
                     else submit_c<1, MM, KK>(q, W, XSPL, Y, PART, m, m.kinv, BSD); \
                     combine(q, PART, Q, SX8, Y, m, m.kinv, KK); }
            if (M == 1) { if (ksplit == 1) RC(1,1) else if (ksplit == 2) RC(1,2)
                          else if (ksplit == 4) RC(1,4) else if (ksplit == 8) RC(1,8) else RC(1,16) }
            else if (M == 2) { if (ksplit == 1) RC(2,1) else if (ksplit == 2) RC(2,2)
                               else if (ksplit == 4) RC(2,4) else if (ksplit == 8) RC(2,8) else RC(2,16) }
            else if (M == 3) { if (ksplit == 1) RC(3,1) else if (ksplit == 2) RC(3,2)
                               else if (ksplit == 4) RC(3,4) else if (ksplit == 8) RC(3,8) else RC(3,16) }
            else { if (ksplit == 1) RC(4,1) else if (ksplit == 2) RC(4,2)
                   else if (ksplit == 4) RC(4,4) else if (ksplit == 8) RC(4,8) else RC(4,16) }
#undef RC
            return;
        }
        if (nb == 1) run(std::integral_constant<int, 1>{});
        else if (nb == 2) run(std::integral_constant<int, 2>{});
        else if (nb == 4) run(std::integral_constant<int, 4>{});
        else if (nb == 8) run(std::integral_constant<int, 8>{});
        else if (nb == 16) run(std::integral_constant<int, 16>{});
        else run(std::integral_constant<int, 64>{});
    };
    printf("rows per item %d (4 row-blocks cover R = %d)\n", nb, m.R);
    if (impl == 1) printf("rev C: k-split %d, rows/tile %d, groups %d\n", ksplit,
                          m.R <= 4 ? m.R : 4, m.E * m.tn * ksplit * ((m.R + 3) / 4));

    std::vector<float> y((size_t) m.E * m.R * m.n);
    // Two different quantities, and at decode footprints they are NOT the same number:
    //   lat = one dispatch + q.wait(): what a caller that needs the result before proceeding pays,
    //         including driver round trip (~25 us measured for .wait(), LESSONS on notify costs)
    //   tp  = BURST back-to-back dispatches inside a single wait, per dispatch: what the machine
    //         sustains, with the launch cost amortised and the queue never drained
    // Reporting only the first badly overstates small shapes: E=10 measured ~80 us for BOTH 3.9 MiB
    // and 5.86 MiB, i.e. the interval was the round trip, not the kernel.
    double best = 1e30;
    for (int r = 0; r < reps + 2; ++r)
    {
        auto t0 = std::chrono::steady_clock::now();
        dispatch();
        q.wait();
        double s = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
        if (r >= 2 && s < best) best = s;          // first two are warm-up (clock ramp, LESSONS 15)
    }
    const int BURST = 16;
    double tpbest = 1e30;
    for (int w = 0; w < 2; ++w) { for (int i = 0; i < 4; ++i) dispatch(); q.wait(); }
    for (int r = 0; r < 4; ++r)
    {
        auto t0 = std::chrono::steady_clock::now();
        for (int i = 0; i < BURST; ++i) dispatch();
        q.wait();
        double s = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count() / BURST;
        if (s < tpbest) tpbest = s;
    }
    q.memcpy(y.data(), Y, y.size() * 4);
    q.wait();
    if (getenv("GEMV_DUMP_PART"))
    {
        std::vector<int32_t> hp((size_t)ksplit * m.E * m.R * m.n);
        q.memcpy(hp.data(), PART, hp.size() * 4); q.wait();
        char pp[512]; snprintf(pp, sizeof pp, "%s/part_dev.bin", dir.c_str());
        FILE *fp = fopen(pp, "wb"); fwrite(hp.data(), 4, hp.size(), fp); fclose(fp);
        printf("dumped partials %s (%d slices)\n", pp, ksplit);
    }

    const double wcount = (double) m.E * m.tk * m.tn * 256.0;
    printf("impl %d order %d (%s): %8.1f us   %6.1f GB/s   %7.1f G-weights/s   [burst-of-16 throughput;"
           " single-launch round trip %7.1f us = %6.1f GB/s, %7.1f G-w/s]\n",
           impl, order, order == 0 ? "clustered" : "scattered ",
           tpbest * 1e6, wbytes / tpbest / 1e9, wcount / tpbest / 1e9,
           best * 1e6, wbytes / best / 1e9, wcount / best / 1e9);

    std::vector<float> yy(y);
    char outpath[512];
    snprintf(outpath, sizeof outpath, "%s/y_dev_order%d_impl%d.bin", dir.c_str(), order, impl);
    FILE *fo = fopen(outpath, "wb");
    fwrite(yy.data(), 4, yy.size(), fo);
    fclose(fo);
    double ymax = 0;
    for (size_t i = 0; i < yy.size(); ++i) ymax = std::max(ymax, (double) std::fabs(yy[i]));
    printf("wrote %s  (max|y| %.3f, sum %.1f)\n", outpath, ymax,
           [&] { double s = 0; for (float v : yy) s += v; return s; }());
    sycl::free(W, q); sycl::free(X8, q); sycl::free(Q, q); sycl::free(SX8, q);
    sycl::free(Y, q); sycl::free(BSD, q); sycl::free(XSPL, q); sycl::free(PART, q);
    return 0;
}