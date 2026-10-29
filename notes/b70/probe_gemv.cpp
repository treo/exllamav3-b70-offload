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

int main(int argc, char **argv)
{
    if (argc < 2) { fprintf(stderr, "usage: %s CASE_DIR [order 0|1] [reps] [rows]\n", argv[0]); return 2; }
    const std::string dir = argv[1];
    const int order = argc > 2 ? atoi(argv[2]) : 0;
    const int reps = argc > 3 ? atoi(argv[3]) : 5;
    const int rows_arg = argc > 4 ? atoi(argv[4]) : 0;
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
    if (m.K != 3.0) { fprintf(stderr, "probe covers integer K = 3.0 only (case K = %g)\n", m.K); return 2; }

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
    q.memcpy(W, wbuf.data(), wbytes);
    q.memcpy(X8, xbuf.data(), xbuf.size());
    q.memcpy(Q, qbuf.data(), qbuf.size());
    q.memcpy(SX8, sbuf.data(), sbuf.size());
    q.memset(Y, 0, (size_t) m.E * m.R * m.n * 4);
    q.wait();

    // exact layout check first, before any timing
    submit<0, true, 1>(q, W, X8, Q, SX8, Y, BSD, m, m.kinv);
    q.wait();
    std::vector<int16_t> hbs(256);
    q.memcpy(hbs.data(), BSD, 256 * 2);
    q.wait();
    long long cksum = 0;
    for (int i = 0; i < 256; ++i) cksum += hbs[i];
    printf("layout check: expert0/tile0 bytesum checksum %lld (non-zero: ring extractor ran)\n", cksum);

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
        if (nb == 1) run(std::integral_constant<int, 1>{});
        else if (nb == 2) run(std::integral_constant<int, 2>{});
        else if (nb == 4) run(std::integral_constant<int, 4>{});
        else if (nb == 8) run(std::integral_constant<int, 8>{});
        else if (nb == 16) run(std::integral_constant<int, 16>{});
        else run(std::integral_constant<int, 64>{});
    };
    printf("rows per item %d (4 row-blocks cover R = %d)\n", nb, m.R);

    std::vector<float> y((size_t) m.E * m.R * m.n);
    double best = 1e30;
    for (int r = 0; r < reps + 2; ++r)
    {
        auto t0 = std::chrono::steady_clock::now();
        dispatch();
        q.wait();
        double s = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
        if (r >= 2 && s < best) best = s;          // first two are warm-up (clock ramp, LESSONS 15)
    }
    q.memcpy(y.data(), Y, y.size() * 4);
    q.wait();

    const double gw = (double) m.E * m.tk * m.tn * 256.0 / best / 1e9;
    printf("order %d (%s): %8.1f us   %6.1f GB/s   %7.1f G-weights/s\n", order,
           order == 0 ? "clustered" : "scattered ", best * 1e6, wbytes / best / 1e9, gw);

    std::vector<float> yy(y);
    char outpath[512];
    snprintf(outpath, sizeof outpath, "%s/y_dev_order%d.bin", dir.c_str(), order);
    FILE *fo = fopen(outpath, "wb");
    fwrite(yy.data(), 4, yy.size(), fo);
    fclose(fo);
    double ymax = 0;
    for (size_t i = 0; i < yy.size(); ++i) ymax = std::max(ymax, (double) std::fabs(yy[i]));
    printf("wrote %s  (max|y| %.3f, sum %.1f)\n", outpath, ymax,
           [&] { double s = 0; for (float v : yy) s += v; return s; }());
    sycl::free(W, q); sycl::free(X8, q); sycl::free(Q, q); sycl::free(SX8, q);
    sycl::free(Y, q); sycl::free(BSD, q);
    return 0;
}