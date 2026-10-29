// What the B70 can actually sustain on the mul1 decode access pattern.
//
// WHY TWO LOCALITY REGIMES: an earlier revision of this probe reported 567 GB/s for reads it should
// not have been able to sustain and 1580 GB/s for reads it certainly could not, for reasons listed
// below; the fixed version measures the same tile reads twice - once with a globally scrambled
// item->tile map (worst case for DRAM page locality) and once with consecutive items on consecutive
// tiles (what a GEMV fragment stream inside one expert looks like) - because if those two differ a
// lot, then *job composition*, not the tile permutation, is the lever, and the design has to say so.
//
// Warm-up and mode interleaving are mandatory here: measured back-to-back without them, the mode
// that happened to run first reported 399 GB/s against 573 GB/s for the later ones, purely from the
// front-end clock ramp.
//
// Settles, by measurement, three things the design carried as projections:
//   R2  NATIVE trellis tile order - what a decode GEMV really does: walk a 128-output-column band,
//       reading that band's tiles for consecutive k-tiles. Successive tiles of a band are
//       tiles_n*80..96 B apart, i.e. a strided read of small blocks; doc/port §2.2 assumed Xe2's
//       128 B lines and 18 MiB L2 would make that acceptable.
//   R3  BANDED (repacked) order - the same tile set, contiguous per band. R3/R2 is the entire
//       payoff of a B70-side repack, decided with bytes rather than by analogy to the CPU tiers.
//   R4/R5  the decode arithmetic on top of R2 at the *light* end: multiply + one int8 dot per u32
//       word versus multiply + a manual 3-mask/3-shift/3-add byte sum. At the rates this card hits
//       these are indistinguishable, i.e. the loop is bandwidth-bound and they measure nothing about
//       the ALU - which is itself the useful result (the cheap part of the decode math is free).
//   R6/R7  the arithmetic at the *real* decode density: a mul1 GEMV costs ~5-7 lane-ops per weight
//       (window extraction + multiply + dot), and at K=3 there are 32/K = 10.7 weights per u32 word,
//       so a faithful proxy is ~10 extract+mul+dot triples per word. R6 uses dot_acc, R7 the manual
//       byte sum; R6/R7 is what the hardware dot is actually worth, and R6's absolute rate says
//       whether decode lands bandwidth-bound or ALU-bound on this compiler. That is the number the
//       kernel design is gated on, not an instruction count in a listing.
//
// Two earlier revisions of this probe reported 1580 GB/s against a 608 GB/s peak, for reasons worth
// recording because they are the general traps in any GPU bandwidth microbenchmark:
//   * items were assigned to addresses linearly, so a wave of in-flight items sat inside the 18 MiB
//     L2 and the measurement returned cache bandwidth;
//   * the item->address map did not cover the buffer, so the *counted* bytes exceeded the *read*
//     bytes (a silent 30x);
//   * dropping one inner loop made each item read 1/8 of the tiles it was credited for.
// So: the mapping below is an exact cover of every tile, scrambled so consecutive items land far
// apart; the result is consumed unconditionally; a self-check verifies the cover and that the sink
// moved; and one shape per process, so a fault cannot poison what follows.
//
// build: icpx -fsycl -O2 -o probe_rates probe_rates.cpp
// run:   ./probe_rates <shape 0..2> [MiB]
#include <sycl/sycl.hpp>
#include <sycl/ext/oneapi/dot_product.hpp>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <vector>

using namespace std::chrono;
using u32 = uint32_t;

struct Shape { const char *name; uint32_t k; uint32_t n; float K; };
static const Shape SHAPES[] = {
    {"Qwen3.8 gate/up  k=2560 n=640  K=2.5 (80 B tiles)", 2560, 640, 2.5f},
    {"Qwen3.8 gate/up  k=2560 n=640  K=3.0 (96 B tiles)", 2560, 640, 3.0f},
    {"GLM      gate/up  k=4096 n=2048 K=3.0 (96 B tiles)", 4096, 2048, 3.0f},
};

#define SINK_WORDS 16384          // 64 KiB accumulator area; index is masked to this

// multiplicative scramble: consecutive items address distant tiles (prime stride, coprime with the
// tile counts used here)
static inline size_t scramble(size_t i, size_t span)
{
    return (i * 1048583ull) % span;
}

// One pass = every tile read exactly once. Item i covers one (expert, band, k-tile group): 8 tiles of
// one band across kt_per_item consecutive k-tiles, which is one GEMV fragment.
//
// MODE is a template parameter. With one runtime-branched kernel, every mode carried every other
// mode's code (predicated branches, registers reserved for the worst case) and even the pure-read
// modes fell to 286 GB/s from the 568 GB/s they reach when specialised - a microbenchmark whose
// instrumentation changes the result is the fourth trap in this file's history.
template <int MODE>
static double pass(sycl::queue &q, u32 *src, u32 *sink, size_t tiles_per_expert, size_t experts,
                   uint32_t tiles_n, uint32_t tiles_k, uint32_t bands, uint32_t tile_words,
                   uint32_t kt_per_item, size_t *bytes_moved)
{
    const size_t per_expert = size_t(bands) * (tiles_k / kt_per_item);   // items per expert
    const size_t items = experts * per_expert;
    *bytes_moved = items * size_t(8) * kt_per_item * tile_words * 4;
    double best = 1e30;
    for (int rep = 0; rep < 4; ++rep)
    {
        q.wait();
        const auto t = steady_clock::now();
        q.parallel_for(items, [=](sycl::id<1> id)
        {
            const size_t p = scramble(id[0], items);
            const size_t expert = p / per_expert;
            const size_t r = p % per_expert;
            const uint32_t band = uint32_t(r % bands);
            const uint32_t kt0 = uint32_t((r / bands) % (tiles_k / kt_per_item)) * kt_per_item;
            const size_t base = expert * tiles_per_expert;
            u32 acc = 0;
            for (uint32_t i = 0; i < kt_per_item; ++i)
            {
                const size_t row = size_t(kt0 + i) * tiles_n;
                for (uint32_t sub = 0; sub < 8; ++sub)
                {
                    // native: (kt, nt) with nt = band*8+sub;  banded: (band, kt, sub) contiguous
                    const size_t tix = (MODE == 1)
                        ? base + (size_t(band) * tiles_k + kt0 + i) * 8 + sub
                        : base + row + size_t(band) * 8 + sub;
                    const u32 *w = src + tix * tile_words;
                    for (uint32_t x = 0; x < tile_words; ++x)
                    {
                        const u32 v = w[x];
                        if constexpr (MODE <= 1) acc += v;
                        else if constexpr (MODE == 2)
                            acc += u32(sycl::ext::oneapi::dot_acc(v * 0x83DCD12Du, 0x41414141u, int32_t(acc)));
                        else if constexpr (MODE == 3) { const u32 pr = v * 0x83DCD12Du;
                               acc += (pr & 0xffu) + ((pr >> 8) & 0xffu) + ((pr >> 16) & 0xffu) + (pr >> 24); }
                        else
                        {
                            // The second word of the pair, only for the dense modes: reading it (or
                            // worse, doing `% tile_words` per iteration) for every mode slowed even
                            // the pure-read modes by 2x and made the whole table meaningless.
                            const u32 v2 = w[x + 1 < tile_words ? x + 1 : 0];
                            // ~10 weights per word at K=3: extract a 16-bit window from the word pair
                            // (the funnel_r shape, which never shifts by 32), then mul + accumulate.
                            // MODE 4 keeps the hardware dot, MODE 5 replaces it with the byte sum.
                            for (uint32_t j = 0; j < 10; ++j)
                            {
                                const uint32_t s = j & 15u;
                                const u32 st = ((v >> s) | ((v2 << 1) << (31u - s))) & 0xFFFFu;
                                const u32 pr = st * 0x83DCD12Du;
                                if constexpr (MODE == 4)
                                    acc += u32(sycl::ext::oneapi::dot_acc(pr, 0x41414141u, int32_t(acc)));
                                else
                                    acc += (pr & 0xffu) + ((pr >> 8) & 0xffu) + ((pr >> 16) & 0xffu) + (pr >> 24);
                            }
                        }
                    }
                }
            }
            sink[(id[0] * 8) & (SINK_WORDS - 1)] += acc;     // unconditional: nothing may be deleted
        }).wait();
        const double s = duration<double>(steady_clock::now() - t).count();
        if (s < best) best = s;
    }
    return double(*bytes_moved) / best / 1e9;
}

// clustered variant of MODE 0: same reads, same count, identity item->tile mapping
static double pass_clustered(sycl::queue &q, u32 *src, u32 *sink, size_t tiles_per_expert,
                             size_t experts, uint32_t tiles_n, uint32_t tiles_k, uint32_t bands,
                             uint32_t tile_words, uint32_t kt_per_item, size_t *bytes_moved)
{
    const size_t per_expert = size_t(bands) * (tiles_k / kt_per_item);
    const size_t items = experts * per_expert;
    *bytes_moved = items * size_t(8) * kt_per_item * tile_words * 4;
    double best = 1e30;
    for (int rep = 0; rep < 4; ++rep)
    {
        q.wait();
        const auto t = steady_clock::now();
        q.parallel_for(items, [=](sycl::id<1> id)
        {
            const size_t p = id[0];                       // no scramble: locality, not layout
            const size_t expert = p / per_expert;
            const size_t r = p % per_expert;
            const uint32_t band = uint32_t(r % bands);
            const uint32_t kt0 = uint32_t((r / bands) % (tiles_k / kt_per_item)) * kt_per_item;
            const size_t base = expert * tiles_per_expert;
            u32 acc = 0;
            for (uint32_t i = 0; i < kt_per_item; ++i)
            {
                const size_t row = size_t(kt0 + i) * tiles_n;
                for (uint32_t sub = 0; sub < 8; ++sub)
                {
                    const u32 *w = src + (base + row + size_t(band) * 8 + sub) * tile_words;
                    for (uint32_t x = 0; x < tile_words; ++x) acc += w[x];
                }
            }
            sink[(id[0] * 8) & (SINK_WORDS - 1)] += acc;
        }).wait();
        const double s = duration<double>(steady_clock::now() - t).count();
        if (s < best) best = s;
    }
    return double(*bytes_moved) / best / 1e9;
}

int main(int argc, char **argv)
{
    setvbuf(stdout, nullptr, _IONBF, 0);
    const int shape_ix = argc > 1 ? atoi(argv[1]) : 0;
    const size_t mib = argc > 2 ? size_t(atoi(argv[2])) : 1536;
    const Shape sh = SHAPES[shape_ix];

    sycl::device dev{sycl::gpu_selector_v};
    sycl::context ctx{dev};
    sycl::queue q{ctx, dev, sycl::property::queue::in_order{}};

    const uint32_t tile_words = uint32_t(8 * sh.K);
    const size_t tile_bytes = tile_words * 4;
    const uint32_t tiles_n = sh.n / 16, tiles_k = sh.k / 16, bands = tiles_n / 8;
    const size_t tiles_per_expert = size_t(tiles_k) * tiles_n;
    size_t experts = (mib << 20) / (tiles_per_expert * tile_bytes);
    if (experts < 1) experts = 1;
    const size_t tiles = experts * tiles_per_expert;
    const size_t bytes = tiles * tile_bytes;

    printf("%s\n", sh.name);
    printf("  %zu experts, %zu tiles of %zu B = %zu MiB, tiles_n %u tiles_k %u bands %u\n",
           experts, tiles, tile_bytes, bytes >> 20, tiles_n, tiles_k, bands);
    printf("  L2 is 18 MiB: the pass reads %zu MiB, so it cannot be served from cache\n\n", bytes >> 20);

    u32 *src = nullptr, *sink = nullptr;
    try
    {
        src = (u32 *) sycl::malloc_device(bytes, q);
        sink = (u32 *) sycl::malloc_device(SINK_WORDS * 4, q);
    }
    catch (const std::exception &e) { printf("  alloc failed: %s\n", e.what()); return 1; }
    if (!src || !sink) { printf("  alloc returned null\n"); return 1; }
    q.memset(src, 0x5A, bytes);
    q.memset(sink, 0, SINK_WORDS * 4);
    q.wait();

    // exact-cover self-check on the host, before timing anything
    {
        const uint32_t kt_pi = 2;
        const size_t per_expert = size_t(bands) * (tiles_k / kt_pi), items = experts * per_expert;
        std::vector<char> seen;
        seen.assign(tiles, 0);
        size_t hits = 0, oob = 0;
        for (size_t item = 0; item < items; ++item)
        {
            const size_t p = scramble(item, items);
            const size_t expert = p / per_expert, r = p % per_expert;
            const uint32_t band = uint32_t(r % bands);
            const uint32_t kt0 = uint32_t((r / bands) % (tiles_k / kt_pi)) * kt_pi;
            const size_t base = expert * tiles_per_expert;
            for (uint32_t i = 0; i < kt_pi; ++i)
                for (uint32_t sub = 0; sub < 8; ++sub)
                {
                    const size_t tix = base + size_t(kt0 + i) * tiles_n + size_t(band) * 8 + sub;
                    if (tix >= tiles) { ++oob; continue; }
                    if (!seen[tix]) { seen[tix] = 1; ++hits; }
                }
        }
        printf("  cover check: %zu/%zu tiles touched, %zu out of range  [%s]\n",
               hits, tiles, oob, (hits == tiles && !oob) ? "exact cover" : "BAD - NUMBERS INVALID");
    }

    static const char *NAMES[] = { "R2 native tile order (scatter)", "R3 banded order    (scatter)",
                                   "R4 native + mul + int8 dot    ", "R5 native + mul + byte sum    ",
                                   "R6 native + density, dot      ", "R7 native + density, sum      ",
                                   "R8 native tile order (cluster)" };
    double rate[7] = {0, 0, 0, 0, 0, 0, 0};
    size_t moved = 0;
    // Warm up, then round-robin the modes: measured first-in-process kernels run during the front-end
    // clock ramp (this box idles far below its 2.8 GHz boost), which made the mode that happened to
    // run first look 1.4x slower than the ones after it. Each mode now sees the same clock state, and
    // the best of the rounds is reported.
    pass<0>(q, src, sink, tiles_per_expert, experts, tiles_n, tiles_k, bands, tile_words, 2, &moved);
    for (int round = 0; round < 3; ++round)
    {
#define MEASURE(M) { const double r = pass<M>(q, src, sink, tiles_per_expert, experts, tiles_n, \
                       tiles_k, bands, tile_words, 2, &moved); if (r > rate[M]) rate[M] = r; }
        MEASURE(0) MEASURE(1) MEASURE(2) MEASURE(3) MEASURE(4) MEASURE(5)
        {
            // MODE 6 proxy for the clustered regime: identical arithmetic to MODE 0 but with the
            // identity item->tile map, i.e. consecutive items read consecutive tiles, which is what
            // a single-expert GEMV fragment stream looks like.
            const double r = pass_clustered(q, src, sink, tiles_per_expert, experts, tiles_n, tiles_k,
                                            bands, tile_words, 2, &moved);
            if (r > rate[6]) rate[6] = r;
        }
#undef MEASURE
    }
    for (int mode = 0; mode < 7; ++mode)
        printf("  %-30s %8.1f GB/s   %9.1f G-weights/s   %6.1f %% of 608 GB/s\n",
               NAMES[mode], rate[mode], rate[mode] * 8.0 / sh.K, 100.0 * rate[mode] / 608.0);
    printf("  layout payoff (banded/native)      %.2f x\n", rate[0] > 0 ? rate[1] / rate[0] : 0.0);
    printf("  LOCALITY payoff (clustered / scrambled native)  %.2f x\n",
           rate[0] > 0 ? rate[6] / rate[0] : 0.0);
    printf("  light arithmetic (byte-sum / dot)  %.2f x\n", rate[2] > 0 ? rate[3] / rate[2] : 0.0);
    printf("  real density  (byte-sum / dot)     %.2f x  ( >1 means the hardware dot wins )\n",
           rate[4] > 0 ? rate[5] / rate[4] : 0.0);
    printf("  ALU pressure  (dot at density / light) %.2f x  (<1 = arithmetic costs bandwidth)\n",
           rate[2] > 0 ? rate[4] / rate[2] : 0.0);

    u32 host[SINK_WORDS / 64];
    q.memcpy(host, sink, sizeof(host)).wait();
    unsigned long long sum = 0;
    for (u32 v : host) sum += v;
    printf("  sink checksum %llu  %s\n", sum, sum ? "(non-zero: loads executed)" : "(ZERO - MEASUREMENT VOID)");
    sycl::free(src, q); sycl::free(sink, q);
    return 0;
}