// probe_slm.cpp - is "read the weights ONCE and feed many row-slabs" cheap on Arc Pro B70?
//
// WHY. doc/port/b70-prefill.md reduces the B70-prefill case to one property: an expert's weight bytes must be
// read from DRAM once per chunk however many token rows hit that expert. The decode kernel cannot do it - the
// weight fragments live in a register ring consumed as it streams, rows beyond 16/thread spill (E29), and the
// engine's answer is row BUCKETS, measured additive in weight traffic (x2.00/x2.98/x3.96 at 32/48/64 rows).
// At the measured prefill rows-per-expert (Qwen3.8@2.68, 2048-token chunk: ~105) that is ~7x amplification,
// which lands the kernel below its own compute ceiling - the worst of both.
//
// The proposed mechanism: stage a group's tile set into SLM once, then let each work-item own a 16-row slab and
// read B from SLM. Before building a full DPAS GEMM on that idea, price the mechanism. Three modes, identical
// ALU per dword consumed, differing ONLY in where the repeated reads land:
//
//   OWNED   each item reads its OWN slice of the region -> DRAM traffic == region            (roofline)
//   DRAM    every item reads the WHOLE region from global -> DRAM traffic == ITEMS x region  (bucketing)
//   SLM     the group stages the region into local memory once (cooperative copy + one group
//           barrier), then every item walks it from SLM   -> DRAM traffic == region          (the proposal)
//
// SLM/OWNED is the mechanism's price; DRAM/SLM is the amplification it removes. Sizes come from the real
// workload: one Qwen3.8@2.68 expert's gate weights for one k-slice is tk=160 tiles x 512 B = 80 KiB whole,
// 40 KiB at KS=2 - chosen against the 128 KiB/group SLM budget so feasibility is arithmetic, not hope - and
// the unique-byte footprint is set far above L2 (24 MiB) so nothing here measures cache.
//
// Build: icpx -fsycl -O2 -o probe_slm probe_slm.cpp
// Run:   WARM_S=1 ./probe_slm [tile_KiB] [items] [unique_MiB] [reps]
//          ./probe_slm 40 32 2048 5      # KS=2 slice, 32 row-slabs per weight read, 2 GiB unique bytes
// Protocol (doc/port/b70-harness.md): >=1 s of continuous EXECUTED work before timing (WARM_S, q.wait() every
// 8 dispatches - LESSONS 53), min-of-reps, and read the device frequency before blaming the environment.
//
// Reading the ISA (the standing rule for this chapter): IGC_ShaderDumpEnable=1 with a dump dir shows whether
// the SLM path lowers to shared-local-memory ops with no scratch, whether the cooperative stage vectorises,
// and whether the item loop kept its accumulator in registers. A timing result whose kernel spills is not a
// result about SLM.

#include <CL/sycl.hpp>
#include <sycl/sycl.hpp>

#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <vector>

enum Mode { OWNED = 0, DRAM = 1, SLM = 2 };

template <int TILE_DW, int ITEMS, int MODE>
static void enqueue(sycl::queue &q, const uint32_t *SRC, uint32_t *OUT, long groups)
{
    q.submit([&](sycl::handler &cgh)
    {
        constexpr int LSIZE = (MODE == SLM) ? TILE_DW : 1;
        sycl::local_accessor<uint32_t, 1> LOC(sycl::range<1>(LSIZE), cgh);
        cgh.parallel_for(sycl::nd_range<1>(sycl::range<1>((size_t)groups * ITEMS), sycl::range<1>(ITEMS)),
                         [=](sycl::nd_item<1> it)
        {
            const int g = (int)it.get_group(0);
            const int li = (int)it.get_local_id(0);
            const uint32_t *reg = SRC + (size_t)g * TILE_DW;
            uint32_t acc = li * 2654435761u;

            if (MODE == SLM)
            {
                // cooperative stage: contiguous, ITEMS-wide slices; the compiler should vectorise this into
                // wide loads, and the barrier after it is a work-group barrier (measured free at decode).
                // Indexed through the accessor rather than a pointer: a local_accessor's element address is a
                // local-space multi_ptr, which will not unify with a global uint32_t* in a ternary.
                constexpr int PER = TILE_DW / ITEMS;
                #pragma unroll
                for (int j = 0; j < PER; j++) LOC[li * PER + j] = reg[li * PER + j];
                sycl::group_barrier(it.get_group());
            }

            if (MODE == OWNED)
            {
                // each item consumes exactly its own share: one read of the region overall
                constexpr int PER = TILE_DW / ITEMS;
                const uint32_t *p = reg + li * PER;
                #pragma unroll
                for (int j = 0; j < PER; j += 4)
                {
                    uint32_t a = p[j], b = p[j + 1], cc = p[j + 2], dd = p[j + 3];
                    a ^= (a >> 7); b += (b << 3); cc ^= (cc >> 11); dd += (dd << 5);
                    acc ^= (a + b) ^ (cc + dd);
                }
            }
            else if (MODE == SLM)
            {
                // every item walks the WHOLE region from SLM - the reuse pattern a row-slab owner needs.
                // Lane-contiguous 4-dword chunks (lane li takes [j*ITEMS+li]*4 .. +3) so the compiler can
                // emit d32x4 here too: the first version indexed p[j+li], which lowered to scalar d32 loads
                // and quietly made the comparison about vectorisation instead of traffic.
                constexpr int STEPD = ITEMS * 4;
                for (int j = 0; j < TILE_DW; j += STEPD)
                {
                    const int b = (j + li * 4);
                    uint32_t a = LOC[b], bb = LOC[b + 1], cc = LOC[b + 2], dd = LOC[b + 3];
                    a ^= (a >> 7); bb += (bb << 3); cc ^= (cc >> 11); dd += (dd << 5);
                    acc ^= (a + bb) ^ (cc + dd);
                }
            }
            else
            {
                // same walk against global memory: the traffic pattern row-bucketing imposes today, done by
                // concurrently-executing items instead of in time-separated launches (which is the actual
                // distinction this probe exists to expose)
                constexpr int STEPD = ITEMS * 4;
                for (int j = 0; j < TILE_DW; j += STEPD)
                {
                    const int b = (j + li * 4);
                    uint32_t a = reg[b], bb = reg[b + 1], cc = reg[b + 2], dd = reg[b + 3];
                    a ^= (a >> 7); bb += (bb << 3); cc ^= (cc >> 11); dd += (dd << 5);
                    acc ^= (a + bb) ^ (cc + dd);
                }
            }
            OUT[(size_t)g * ITEMS + li] = acc;      // per-item store: keeps the loop live, no atomic, no bias
        });
    });
}

struct Cfg { int kib; int items; };

int main(int argc, char **argv)
{
    const int kib = argc > 1 ? atoi(argv[1]) : 40;
    const int items = argc > 2 ? atoi(argv[2]) : 32;
    const long unique_mib = argc > 3 ? atol(argv[3]) : 2048;
    const int reps = argc > 4 ? atoi(argv[4]) : 5;
    const double warm_s = getenv("WARM_S") ? atof(getenv("WARM_S")) : 1.0;

    const long tile_dw = (long)kib * 256;
    if (tile_dw % items) { printf("tile dwords (%ld) must divide items (%d)\n", tile_dw, items); return 2; }
    const long regions = unique_mib * 1024 * 1024 / tile_dw;
    const size_t n_dw = (size_t)regions * tile_dw;

    sycl::device d; sycl::context c(d);
    sycl::queue q(d, sycl::property::queue::in_order{});
    uint32_t *SRC = (uint32_t *)sycl::malloc_device(n_dw * 4, d, c);
    uint32_t *OUT = (uint32_t *)sycl::malloc_device((size_t)regions * items * 4, d, c);
    if (!SRC || !OUT) { printf("alloc failed (%.1f GiB) - lower unique_MiB\n", n_dw * 4.0 / (1 << 30)); return 3; }
    q.memset(SRC, 0x5a, n_dw * 4).wait();

    printf("probe_slm: region %d KiB, items/group %d, regions %ld, unique %.0f MiB (%.0fx L2)\n",
           kib, items, regions, regions * (double)tile_dw * 4.0 / 1048576.0,
           regions * (double)tile_dw * 4.0 / 1048576.0 / 24.0);

    auto run_mode = [&](int mode) -> double
    {
        // The 128 KiB/group SLM budget is a device fact, so decide it ONCE here. (An earlier version put this
        // guard inside the dispatch lambda, where it printed once per enqueue and the -1/1e30 sentinel leaked
        // into the summary line - a guard in a hot loop is a bug even when the value it guards is right.)
        if (mode == SLM && kib * 1024 > 128 * 1024)
        {
            printf("  SLM    n/a: %d KiB/group exceeds the 128 KiB SLM budget\n", kib);
            return -1.0;
        }
        auto one = [&]()
        {
            const long per = regions / 8;
            for (int i = 0; i < 8; i++)
            {
                const uint32_t *s = SRC + (size_t)i * per * tile_dw;
                uint32_t *o = OUT + (size_t)i * per * items;
                switch (mode)
                {
                    case OWNED:
                        if (kib == 40 && items == 32) enqueue<10240, 32, OWNED>(q, s, o, per);
                        else if (kib == 80 && items == 32) enqueue<20480, 32, OWNED>(q, s, o, per);
                        else if (kib == 20 && items == 32) enqueue<5120, 32, OWNED>(q, s, o, per);
                        else if (kib == 320 && items == 32) enqueue<81920, 32, OWNED>(q, s, o, per);
                        else if (kib == 1024 && items == 32) enqueue<262144, 32, OWNED>(q, s, o, per);
                        else if (kib == 40 && items == 64) enqueue<10240, 64, OWNED>(q, s, o, per);
                        else if (kib == 40 && items == 16) enqueue<10240, 16, OWNED>(q, s, o, per);
                        else { printf("unsupported (kib,items)=(%d,%d): rebuild with that pair\n", kib, items); exit(4); }
                        break;
                    case DRAM:
                        if (kib == 40 && items == 32) enqueue<10240, 32, DRAM>(q, s, o, per);
                        else if (kib == 80 && items == 32) enqueue<20480, 32, DRAM>(q, s, o, per);
                        else if (kib == 20 && items == 32) enqueue<5120, 32, DRAM>(q, s, o, per);
                        else if (kib == 320 && items == 32) enqueue<81920, 32, DRAM>(q, s, o, per);
                        else if (kib == 1024 && items == 32) enqueue<262144, 32, DRAM>(q, s, o, per);
                        else if (kib == 40 && items == 64) enqueue<10240, 64, DRAM>(q, s, o, per);
                        else if (kib == 40 && items == 16) enqueue<10240, 16, DRAM>(q, s, o, per);
                        else { printf("unsupported pair\n"); exit(4); }
                        break;
                    default:
                        if (kib == 40 && items == 32) enqueue<10240, 32, SLM>(q, s, o, per);
                        else if (kib == 80 && items == 32) enqueue<20480, 32, SLM>(q, s, o, per);
                        else if (kib == 20 && items == 32) enqueue<5120, 32, SLM>(q, s, o, per);
                        else if (kib == 40 && items == 64) enqueue<10240, 64, SLM>(q, s, o, per);
                        else if (kib == 40 && items == 16) enqueue<10240, 16, SLM>(q, s, o, per);
                        else { printf("unsupported pair\n"); exit(4); }
                        break;
                }
            }
        };
        auto t0 = std::chrono::steady_clock::now();
        int n = 0;
        while (std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count() < warm_s)
        { one(); n++; if ((n & 7) == 0) q.wait(); }
        q.wait();
        double best = 1e30;
        for (int r = 0; r < reps; r++)
        {
            auto t1 = std::chrono::steady_clock::now();
            one(); q.wait();
            double ms = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t1).count();
            if (ms < best) best = ms;
        }
        return best;
    };

    double t_own = run_mode(OWNED);
    double t_dram = run_mode(DRAM);
    double t_slm = run_mode(SLM);

    const double gib = regions * (double)tile_dw * 4.0 / (1024.0 * 1024.0 * 1024.0);
    auto line = [&](const char *nm, double ms, double traffic_x)
    {
        printf("  %-6s %9.3f ms   unique %7.1f GB/s   app-visible %8.1f GB/s   (x%.0f weight traffic)\n",
               nm, ms, gib / (ms / 1000.0), gib * traffic_x / (ms / 1000.0), traffic_x);
    };
    line("OWNED", t_own, 1.0);
    line("DRAM", t_dram, (double)items);
    line("SLM", t_slm, 1.0);
    printf("  ---- SLM/OWNED = %.3f   DRAM/SLM = %.2fx traffic ratio   (copy peak 674 GB/s)\n",
           t_slm > 0 ? t_slm / t_own : -1.0, t_slm > 0 ? t_dram / t_slm : -1.0);

    std::vector<uint32_t> h((size_t)regions * items);
    q.memcpy(h.data(), OUT, h.size() * 4).wait();
    uint64_t sum = 0; for (size_t i = 0; i < h.size(); i += 997) sum += h[i];
    printf("  checksum %llu (non-zero proves the loops were not optimised away)\n", (unsigned long long)sum);
    sycl::free(SRC, q); sycl::free(OUT, q);
    return 0;
}