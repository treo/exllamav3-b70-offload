// lab_resident_bw.cpp — gate G0 of PLAN_PERSISTENT_WORKER.md (§3.0).
//
// THE QUESTION: a resident engine has to feed itself. The megakernel died of exactly this
// (466 us vs 183 us at rows=1: "the per-command overhead it removed was never the dominant cost -
// starvation is"), and its grid was capped by co-residency. So before spending a day on trigger
// mechanics, measure the resource bound of the engine shape itself:
//
//   (1) RESIDENCY: are N thin float-gemv teams alive SIMULTANEOUSLY, for N in {16..640}?
//   (2) BANDWIDTH: sustained aggregate packed-byte rate of that grid running decode-shaped work
//       back to back. Gate: >= 195 GB/s (= today's measured marginal rate, 6.3 us per 1.2288 MB
//       expert).
//   (3) NET WIN: engine wall vs the split path's wall at the SAME nc, same bytes, same process.
//       Gate: engine_wall < split_wall - 20 us.
//
// HOW RESIDENCY IS TESTED, and why the first cut was wrong. The obvious test ("every team tickets
// a counter, team 0 waits for all N tickets, then releases them") DEADLOCKS-AND-SLOWS ITSELF: it
// puts N leaders RMW-polling two shared lines, which is precisely the catastrophic serialization
// already measured on this hardware (rule 2: >20 ms per job from 8 WGs up). It also converts a
// "not resident" answer into a multi-minute spin. So instead, measure the overlap directly and
// non-blockingly: each team bumps ENTER once at start and EXIT once at end (two RMWs per team per
// LAUNCH, not per poll), and continuously OBSERVES `ENTER - EXIT`, i.e. how many teams it can see
// that have started and not finished; the max it ever sees is published to its OWN cache line. max
// over teams == N is proof that all N were alive at one instant; a grid that pipelines instead of
// co-residing can never reach N. No waiting, no barriers, no hang, no shared hot line.
//
// Shapes are the real 2.05bpw float-tier decode geometry (K2=4): HID=2560, INT=640, gate/up
// [INT,HID], down [HID,INT], 0.4096 MB packed per matrix, 1.2288 MB per expert (= the model's
// expert_bytes). One "team" = 128 threads = one 128-column block, the granularity production's
// GemvK distributes over, so team counts map onto the plan's "gu ~= 20 WGs, down ~= 40" 1:1. The
// gemv inner loop is lab_gemv_shape.cpp's Body (= GemvK<4,false> verbatim, NCWG=128, DEPTH=2),
// which reproduced 160 GB/s for the shipping kernel - so this lab is calibrated to production.
//
// Modes:
//   A  resident loop, NO doorbell: ONE launch does J decode jobs' worth of units, teams stride the
//      flattened unit list. Pure "engine doing work" - gives residency + the GB/s curve.
//   C  split path (control arm): the same jobs issued as today - blob H2D, gu launch, down launch,
//      D2H, one wait per job. Optimistic vs production (4 commands, no K1/K34), which RAISES the
//      bar the engine has to clear.
//   B  engine WITH doorbell: one permanent launch; host rings a pinned doorbell per job; team 0
//      fans the job id out to per-team slots (rule 2), teams work, fan in on arrival counters
//      (flat or two-level, both reported), last arrival stores `done` to sysmem (rule 3:
//      level-triggered). Reports per-job wall p50/p90/p99, stalls, aggregate GB/s INCLUDING the
//      poll loop, and the §2a device poll counter so a stall is attributable in the same run.
//
// Doorbell rules honoured (NOTES lever 1b): (1) the sysmem doorbell is read with an atomic RMW, not
// an acquire load; (2) fan-out uses per-team slots on separate cache lines, and nothing polls a
// shared line; (3) completion is level-triggered with a signed distance; (4) every device spin is
// bounded, bounds are ~seconds not minutes, and the host always posts QUIT before giving up.
// Cross-lane broadcast inside a team uses production's proven pattern (`coop_load`: one release
// store + global-space group barrier + device-scope relaxed atomic loads), because DPC++ here has
// no __shared__ in functor kernels.
//
//   source ../sycl_moe/env.sh ; icpx -fsycl -O2 -ffp-contract=off -w lab_resident_bw.cpp -o lab_resident_bw
//   ./lab_resident_bw [A|B|C|all] [nc] [jobs]
#include <sycl/sycl.hpp>
#include <algorithm>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <immintrin.h>
#include <vector>

// ---------------------------------------------------------------- geometry
static constexpr int HID = 2560;            // token hidden size
static constexpr int INT = 640;             // expert intermediate size (h width)
static constexpr int K2V = 4;               // 2.05bpw: 2 bits/weight
static constexpr int W = 4 * K2V;           // 16 ring words = 64 B per 16x16 tile
static constexpr int AD27 = (27 * K2V) >> 1;
static constexpr int NW = (AD27 + 16 + 31 + 31) / 32 + 1;   // 5
static constexpr float KDQ = 0.00676727294921875f;
static constexpr int TEAM = 128;            // threads per team = one 128-column block
static constexpr int U_GU = INT / TEAM;     // 5 blocks per matrix (gate, up)
static constexpr int U_DN = HID / TEAM;     // 20 blocks (down)
static constexpr int U_PER_E = 2 * U_GU + U_DN;   // 30 units per expert
static constexpr double JOB_BYTES_PER_E = 3.0 * 409600.0;   // packed bytes per expert
static constexpr int MAXTEAMS = 768;

static double now_us() {
    return std::chrono::duration<double, std::micro>(
        std::chrono::steady_clock::now().time_since_epoch()).count();
}

// ---------------------------------------------------------------- gemv unit
// One team, one 128-column block, walking tiles_k packed 16x16 tiles (n-major arena order, so the
// walk is sequential in k like production's MOE_STREAM_NMAJOR=1).
static inline void gemv_unit(const uint32_t* wp, const float* xr, float* outp,
                             size_t tiles_k, int tid) {
    const int cin = tid & 15;
    const int A2 = (K2V * (32 * (cin & 7) + 4 * ((cin >> 3) & 1))) >> 1;
    const int G = (32 - (K2V >> 1)) - A2 - AD27, wb = G >> 5, pre = G - (wb << 5);
    int widx[NW];
#pragma unroll
    for (int i = 0; i < NW; ++i) widx[i] = ((wb + i) % W + W) % W;

    float acc = 0.f, accB = 0.f;
    uint32_t g0[NW], g1[NW];
#pragma unroll
    for (int i = 0; i < NW; ++i) g0[i] = wp[widx[i]];
    for (size_t tk = 0; tk < tiles_k; ++tk, wp += W) {
        if (tk + 1 < tiles_k) {
            const uint32_t* wpf = wp + W;
#pragma unroll
            for (int i = 0; i < NW; ++i) g1[i] = wpf[widx[i]];
        } else {
#pragma unroll
            for (int i = 0; i < NW; ++i) g1[i] = 0u;
        }
        const uint32_t* g = g0;
        uint32_t h[NW];
        if (pre == 0) {
#pragma unroll
            for (int i = 0; i < NW; ++i) h[i] = g[i];
        } else {
#pragma unroll
            for (int i = 0; i + 1 < NW; ++i) h[i] = (g[i] >> pre) | (g[i + 1] << (32 - pre));
            h[NW - 1] = g[NW - 1] >> pre;
        }
#pragma unroll
        for (int rk = 0; rk < 16; ++rk) {
            const int d = 8 * ((rk >> 1) & 3) + (rk & 1) + 2 * ((rk >> 3) & 1);
            const int rel = AD27 - ((K2V * d) >> 1);
            const uint32_t lo4 = h[rel >> 5], hi4 = h[(rel >> 5) + 1];
            const uint32_t st16 = ((lo4 >> (rel & 31)) | ((hi4 << 1) << (31u - (rel & 31)))) & 0xffffu;
            const uint32_t xm = st16 * 0x83DCD12Du;
            const uint32_t t1 = (xm & 0x00ff00ffu) + ((xm >> 8) & 0x00ff00ffu);
            const uint32_t bs = (t1 & 0xffffu) + (t1 >> 16);
            const float wc = (float)(int)bs - 510.0f;
            const float xv = xr[tk * 16 + rk];
            if (rk & 1) accB = sycl::fma(wc, xv, accB);
            else        acc  = sycl::fma(wc, xv, acc);
        }
#pragma unroll
        for (int i = 0; i < NW; ++i) g0[i] = g1[i];
    }
    outp[tid] = (acc + accB) * KDQ;
}

// Unit u within one expert (0..29) -> matrix, k-tiles, source arena, scratch output.
// SK (LAB_SK) splits each unit's k-range into SK independent units, which is what production does
// (its decode gu grid is nc*nm*(I/ncwg) with nm=2, i.e. split-K 2, so 40 teams for nc=2 and 80 for
// down - twice this lab's default). Without SK the lab under-states production's own parallelism.
static unsigned g_sk = 1, g_skd = 1;         // LAB_SK (gate/up), LAB_SK_DN (down); shipped = 8 and 1
static inline void do_unit(int u, int ks, unsigned sku, unsigned skd,
                          const uint32_t* gate, const uint32_t* up, const uint32_t* down,
                          const float* xgu, const float* xdn, float* out, int e, int tid) {
    const unsigned sk = (u < 2 * U_GU) ? sku : skd;
    const uint32_t* src; const float* xr; size_t tiles_k; int TNcols, blk;
    if (u < U_GU)          { src = gate; xr = xgu + (size_t)e * HID; tiles_k = HID / 16; TNcols = INT; blk = u; }
    else if (u < 2 * U_GU) { src = up;   xr = xgu + (size_t)e * HID; tiles_k = HID / 16; TNcols = INT; blk = u - U_GU; }
    else                   { src = down; xr = xdn + (size_t)e * INT; tiles_k = INT / 16; TNcols = HID; blk = u - 2 * U_GU; }
    const size_t TN = (size_t)TNcols / 16;
    const int tile_n0 = blk * (TEAM / 16);            // 8 tile columns per team
    size_t k0 = 0, klen = tiles_k;
    if (sk > 1) {
        klen = tiles_k / sk;
        k0 = (size_t)ks * klen;
        if (ks == (int)sk - 1) klen = tiles_k - k0;   // last slice absorbs the remainder
    }
    const uint32_t* wp = src + ((size_t)e * TN + tile_n0 + (tid >> 4)) * tiles_k * W + k0 * W;
    float* dst = out + (size_t)e * 4096 + (size_t)u * TEAM + (size_t)ks * 128;   // scratch
    gemv_unit(wp, xr, dst, klen, tid);
}

// Flat unit index q -> (unit within expert, k slice). `span` is U_PER_E (all units) or 2*U_GU (gu
// launch) or U_DN (down launch).
static inline void do_unit(int u, int ks, unsigned sk,
                          const uint32_t* gate, const uint32_t* up, const uint32_t* down,
                          const float* xgu, const float* xdn, float* out, int e, int tid) {
    do_unit(u, ks, sk, sk, gate, up, down, xgu, xdn, out, e, tid);
}
static inline void unit_map(unsigned span, size_t q, unsigned sk, int& u, int& ks) {
    ks = (int)(q % sk);
    const size_t v = q / sk;
    u = (int)(v % span);
}
static inline unsigned upe(unsigned sku, unsigned skd) { return 2 * U_GU * sku + U_DN * skd; }
// q indexes [0, nc*upe); returns (unit-within-expert u, k slice ks) and the expert slot.
static inline void unit_map(size_t q, unsigned sku, unsigned skd, int& u, int& ks, int& slot) {
    const unsigned gub = 2 * U_GU * sku;
    const unsigned w = (unsigned)(q % upe(sku, skd));
    slot = (int)(q / upe(sku, skd));
    if (w < gub) {
        const unsigned half = w / (U_GU * sku), rem = w % (U_GU * sku);
        u = (int)(half * U_GU + rem / sku);
        ks = (int)(rem % sku);
    } else {
        const unsigned w2 = w - gub;
        u = (int)(2 * U_GU + w2 / skd);
        ks = (int)(w2 % skd);
    }
}
// phase-restricted map: span==0 -> gu units only, span==1 -> down units only
static inline void unit_map_ph(size_t q, unsigned sku, unsigned skd, int phase, int& u, int& ks,
                               int& slot) {
    if (phase == 0) {
        const unsigned per = 2 * U_GU * sku;
        const unsigned w = (unsigned)(q % per);
        slot = (int)(q / per);
        const unsigned half = w / (U_GU * sku), rem = w % (U_GU * sku);
        u = (int)(half * U_GU + rem / sku); ks = (int)(rem % sku);
    } else {
        const unsigned per = U_DN * skd;
        const unsigned w = (unsigned)(q % per);
        slot = (int)(q / per);
        u = (int)(2 * U_GU + w / skd); ks = (int)(w % skd);
    }
}

// ---------------------------------------------------------------- counters layout (device)
// Per-team entities live on their own 16-unsigned (64 B) lines: rule 2 says never let many WGs
// touch one line. The only shared words are ENTER/EXIT (one RMW per team per LAUNCH) and the
// arrival counters, which are arrived-on once per team per job - never polled.
enum : unsigned {
    C_ENTER = 0, C_EXIT = 1, C_ARRIVE = 2, C_GO = 3, C_DIAG = 4,
    C_GARR = 64,                                             // two-level fan-in, one line / group
    C_BC = 62,                                               // fout==2 single broadcast line
    C_DP_GUARD = 63,                                         // dead-protocol guard (never 7777)
    C_RING = 2048,                                           // 4096-entry observe-poll ring
    C_OBS = 8192,                                            // per-team max-alive observation
    C_PUB = C_OBS + MAXTEAMS * 16, C_SLOT = C_PUB + MAXTEAMS * 16,
    C_WORDS = C_SLOT + MAXTEAMS * 16
};
static inline unsigned* obsep(unsigned* c, unsigned t) { return c + C_OBS + t * 16; }
static inline unsigned* slotp(unsigned* c, unsigned t) { return c + C_SLOT + t * 16; }
static inline unsigned* pubp(unsigned* c, unsigned t) { return c + C_PUB + t * 16; }

// ---------------------------------------------------------------- atomics (rules 1-3)
template <sycl::memory_scope S>
static inline unsigned rmw0(unsigned* p) {
    return sycl::atomic_ref<unsigned, sycl::memory_order::acq_rel, S,
                            sycl::access::address_space::global_space>(*p).fetch_add(0u);
}
template <sycl::memory_scope S>
static inline unsigned add_a(unsigned* p, unsigned v) {
    return sycl::atomic_ref<unsigned, sycl::memory_order::acq_rel, S,
                            sycl::access::address_space::global_space>(*p).fetch_add(v);
}
template <sycl::memory_scope S>
static inline void st_rel(unsigned* p, unsigned v) {
    sycl::atomic_ref<unsigned, sycl::memory_order::relaxed, S,
                     sycl::access::address_space::global_space>(*p)
        .store(v, sycl::memory_order::release);
}
template <sycl::memory_scope S>
static inline unsigned ld_rlx(unsigned* p) {
    return sycl::atomic_ref<unsigned, sycl::memory_order::relaxed, S,
                            sycl::access::address_space::global_space>(*p).load();
}

struct Mailbox {                       // PINNED host memory, one cache line per field
    alignas(64) unsigned seq;          // host -> device doorbell (job id)
    alignas(64) unsigned done;         // device -> host, level-triggered
    alignas(64) unsigned quit;         // host -> device advisory
    alignas(64) unsigned polls_at_observe;   // §2a: team 0's spin count when it saw this seq
    alignas(64) unsigned polls_total;        // §2a: team 0's cumulative polls (rate calibration)
    alignas(64) unsigned tg_seq;             // TRIG_TASK: host stages the id here, a kernel copies it
};
// Trigger mechanisms. The plan's rule 1 ("the doorbell must be an atomic RMW") fixed the DEVICE
// side of the poll, but every stall seen so far is consistent with the other half: a HOST store to
// pinned USM lands in the CPU's own cache, and a discrete GPU polling that line over PCIe has no
// obligation to see it until the line is evicted - which would explain "first ping fine, later
// pings > 20 ms, ~2 us when it works" better than any clock-state story does.
//   0  host plain atomic store -> pinned line; device RMW-polls it
//   1  host NON-TEMPORAL store (_mm_stream_si32 + sfence) -> straight to the memory interface
//   2  host clflush the line after storing
//   3  host enqueues a 4-byte H2D copy onto a SECOND queue -> DMA into DEVICE memory; the engine
//      polls device memory. Contractual (no cross-agent atomic claims), but prices in one enqueue.
enum { TRIG_STORE = 0, TRIG_NTSTORE = 1, TRIG_CLFLUSH = 2, TRIG_DMA = 3, TRIG_TASK = 4 };
static constexpr unsigned QUIT = 0xFFFFFFFFu;

// Bail bounds. lab_doorbell assumed a sysmem poll costs ~1.5-2 us (a PCIe round trip). MEASURED
// here: ~60 ns (~1.7e7 polls/s) - the RMW is being absorbed close to the GPU, which is itself the
// coherence worry of plan §10. So a poll-COUNT bound is not a time bound: 1e6 polls is 60 ms, and
// an engine that idles between tokens would kill itself. These bounds are set to ~1-3 s AT THE
// MEASURED RATE (plan §4 lifecycle rule iii).
static constexpr long SPIN_MAX_SYS = 20'000'000L;    // ~1.2 s of sysmem polls
static constexpr long SPIN_MAX_DEV = 100'000'000L;   // device-slot polls are cheaper still
static constexpr long SPIN_MAX_REL = 300'000L;       // gate wait: ~10-30 ms of cheap device polls

// Non-blocking co-residency sampler (see header). Leader-only; publishes to the team's own line.
struct AliveWatch {
    unsigned best;
    unsigned* ctr;
    inline void sample() {
        const unsigned e = ld_rlx<sycl::memory_scope::device>(ctr + C_ENTER);
        const unsigned x = ld_rlx<sycl::memory_scope::device>(ctr + C_EXIT);
        const unsigned alive = e > x ? e - x : 0u;
        if (alive > best) best = alive;
    }
};

// ---------------------------------------------------------------- mode A: resident loop
struct ResidentLoop {
    const uint32_t *gate, *up, *down;
    const float *xgu, *xdn;
    float* out;
    unsigned* ctr;
    int E, nc, jobs;
    size_t units_job;
    unsigned nteams, sk, skd;
    unsigned deadproto;          // 1 = compile the engine's protocol in but never run it
    Mailbox* mb;                 // only used by the dead-protocol path

    void operator()(sycl::nd_item<1> it) const {
        const int tid = (int)it.get_local_id(0);
        const unsigned nt = (unsigned)it.get_group(0);
        const unsigned nteams = this->nteams;
        AliveWatch aw{0u, ctr};

        // ---- residency, DECIDED by release-then-all-arrive. The first cut waited for all N tickets
        // BEFORE releasing anyone, which turns the test into a mutual deadlock whenever the grid is
        // bigger than co-residency (and a 448-team sweep then takes minutes). Here team 0 just waits
        // for N entries (bounded, ~us if they are really launched at once) and then opens the gate;
        // every team must reach the gate, and the host's own end-of-kernel ENTRY-vs-EXIT check
        // (below) is what proves nobody retired before the last one started.
        if (tid == 0) {
            add_a<sycl::memory_scope::device>(ctr + C_ENTER, 1u);
            if (nt == 0) {
                long spins = 0; unsigned seen = 0;
                do { seen = ld_rlx<sycl::memory_scope::device>(ctr + C_ENTER); }
                while (seen < nteams && ++spins < SPIN_MAX_REL);
                st_rel<sycl::memory_scope::device>(ctr + C_DIAG, seen);
                st_rel<sycl::memory_scope::device>(ctr + C_GO, 1u);          // release everyone
            } else {
                long spins = 0;
                while (ld_rlx<sycl::memory_scope::device>(ctr + C_GO) == 0u && ++spins < SPIN_MAX_REL) {}
            }
        }
        it.barrier(sycl::access::fence_space::global_space);

        const size_t total = units_job * (size_t)jobs;
        for (size_t u = nt; u < total; u += nteams) {
            if (tid == 0) aw.sample();          // 2 relaxed loads per unit: free next to ~2 us work
            // ATTRIBUTION HACK: the engine's whole protocol, compiled in and live, but guarded by a
            // value only the device can know, so the compiler cannot DCE it. If this makes mode A as
            // slow as the engine, the engine's deficit is the protocol's LIVE STATE (register
            // allocation), not anything it dynamically costs at run time.
            if (deadproto && ld_rlx<sycl::memory_scope::device>(ctr + C_DP_GUARD) == 7777u) {
                const unsigned sx = rmw0<sycl::memory_scope::system>(&mb->seq);
                st_rel<sycl::memory_scope::device>(slotp(ctr, nt), sx);
                add_a<sycl::memory_scope::device>(ctr + C_ARRIVE, 1u);
            }
            const size_t jobid = u / units_job;
            const size_t ui = u % units_job;
            int uu, ks, sl;
            unit_map(ui, sk, skd, uu, ks, sl);
            const int e = (int)((jobid * (unsigned)nc + (unsigned)sl) % (unsigned)E);
            do_unit(uu, ks, sk, skd, gate, up, down, xgu, xdn, out, e, tid);
        }
        if (tid == 0) {
            // Everyone is still inside the kernel here (nobody exits before the gate), so at this
            // instant alive = ENTER - EXIT counts the teams that are simultaneously resident. If the
            // grid were pipelined, the last team could not enter until an early one retired, and
            // this number would be < N.
            aw.sample();
            st_rel<sycl::memory_scope::device>(obsep(ctr, nt), aw.best);
            add_a<sycl::memory_scope::device>(ctr + C_EXIT, 1u);
        }
    }
};

// ---------------------------------------------------------------- mode C: split path
struct SplitUnits {
    const uint32_t *gate, *up, *down;
    const float *xgu, *xdn;
    float* out;
    unsigned* ctr;
    int E, nc, phase, job;
    unsigned sk, skd;
    void operator()(sycl::nd_item<1> it) const {
        const int tid = (int)it.get_local_id(0);
        const unsigned nt = (unsigned)it.get_group(0);
        if (tid == 0) add_a<sycl::memory_scope::device>(ctr + C_ENTER, 1u);   // concurrency stats
        const unsigned span = phase == 1 ? (unsigned)U_DN : (phase == 2 ? (unsigned)U_PER_E
                                                                        : 2u * (unsigned)U_GU);
        const unsigned per = (unsigned)nc * span * sk;
        if (nt < per) {
            int u, ks;
            unit_map(span, nt, sk, u, ks);
            const unsigned sl = nt / sk / span;
            const int e = (int)(((unsigned)job * (unsigned)nc + sl) % (unsigned)E);
            do_unit((int)((phase == 1 ? 2 * U_GU : 0) + u), ks, sk, gate, up, down, xgu, xdn, out, e,
                    tid);
        }
        if (tid == 0) {
            const unsigned alive = ld_rlx<sycl::memory_scope::device>(ctr + C_ENTER) -
                                   ld_rlx<sycl::memory_scope::device>(ctr + C_EXIT);
            unsigned* o = obsep(ctr, nt);
            if (alive > ld_rlx<sycl::memory_scope::device>(o)) st_rel<sycl::memory_scope::device>(o, alive);
            add_a<sycl::memory_scope::device>(ctr + C_EXIT, 1u);
        }
    }
};

// ---------------------------------------------------------------- mode B: engine + doorbell
struct Engine {
    Mailbox* mb;
    unsigned* ctr;
    const uint32_t *gate, *up, *down;
    const float *xgu, *xdn;
    float* out;
    int E, nc;
    size_t units_job;
    unsigned nteams, sk, skd;
    unsigned group;            // fan-in group size (1 = flat single counter, 8 = two-level)
    unsigned fout;             // fan-OUT: 0 = team 0 writes every slot, 1 = two-level tree
    unsigned trigger;          // TRIG_* above
    unsigned* dflag;           // device-memory doorbell for TRIG_DMA
    unsigned backoff;          // idle-loop iterations between polls (0 = hammer)
    unsigned per_ping;         // decode JOBS done per doorbell (attribution knob)
    int nowork;                // LAB_NOWORK=1: skip the gemv, measure the protocol alone

    void operator()(sycl::nd_item<1> it) const {
        const int tid = (int)it.get_local_id(0);
        const unsigned nt = (unsigned)it.get_group(0);
        unsigned* slot = slotp(ctr, nt);
        unsigned* pub = pubp(ctr, nt);
        AliveWatch aw{0u, ctr};

        unsigned last = 0;
        // Poll accounting stays in a REGISTER: reading sysmem inside the poll loop adds a
        // system-scope (fenced, uncached) load per iteration on every team, which is exactly the
        // kind of PCIe pressure that produced the 20 ms stalls in lab_doorbell.
        unsigned polls_total = 0;
        if (tid == 0) add_a<sycl::memory_scope::device>(ctr + C_ENTER, 1u);
        for (;;) {
            // ---- trigger. Team 0's leader watches sysmem (RMW, rule 1) and fans the job id out to
            // per-team slots (rule 2). Other teams watch only their OWN slot. Only the leader
            // touches the polled line; the value reaches the rest of the team through `pub` after a
            // global-space group barrier, so every lane runs the same number of barriers.
            if (tid == 0) {
                unsigned s = 0;
                long sp = 0;
                aw.sample();
                if (nt == 0) {
                    for (;;) {
                        s = (trigger == TRIG_DMA || trigger == TRIG_TASK)
                                ? rmw0<sycl::memory_scope::device>(dflag)
                                : rmw0<sycl::memory_scope::system>(&mb->seq);
                        if (++sp > SPIN_MAX_SYS) { s = QUIT; break; }
                        if ((int)(s - last) > 0 || s == QUIT) break;
                        for (unsigned b = 0; b < backoff; ++b) sp += (b >> 31);   // idle backoff
                    }
                    polls_total += (unsigned)sp;
                    if (s != QUIT) {
                        // §2a attribution: stamp THIS job's time-to-observe (in sysmem polls) into a
                        // DEVICE ring - a sysmem write here would sit on the critical path, and the
                        // host reads the ring after teardown, where it can zip it against its own
                        // per-job wall list to split a stall into ->observe vs ->host.
                        st_rel<sycl::memory_scope::device>(ctr + C_RING + (s & 4095u), (unsigned)sp);
                        if (fout == 0) {
                            for (unsigned t = 0; t < nteams; ++t)
                                st_rel<sycl::memory_scope::device>(slotp(ctr, t), s);
                        } else if (fout == 2) {
                            // Rule 2 bans many WGs RMW-polling ONE line (measured >20 ms/job from 8
                            // WGs up). It says nothing about many WG LOAD-polling one line, which is
                            // production's proven coop_load pattern and L2-broadcastable: one release
                            // store here replaces N of them.
                            st_rel<sycl::memory_scope::device>(ctr + C_BC, s);
                        } else {
                            // two-level: team 0 posts only the group leaders, leaders post members.
                            // Costs 1 + N/GROUP stores instead of N, at the price of one extra hop.
                            for (unsigned t = 0; t < nteams; t += group ? group : 1u)
                                st_rel<sycl::memory_scope::device>(slotp(ctr, t), s);
                        }
                    } else {
                        for (unsigned t = 0; t < nteams; ++t)
                            st_rel<sycl::memory_scope::device>(slotp(ctr, t), QUIT);
                        st_rel<sycl::memory_scope::system>(&mb->done, QUIT);
                    }
                } else {
                    if (fout == 2) {
                        for (;;) {
                            s = ld_rlx<sycl::memory_scope::device>(ctr + C_BC);
                            if (++sp > SPIN_MAX_DEV) { s = QUIT; break; }
                            if ((int)(s - last) > 0 || s == QUIT) break;
                            for (unsigned b = 0; b < backoff; ++b) sp += (b >> 31);
                        }
                    } else {
                        for (;;) {
                            s = rmw0<sycl::memory_scope::device>(slot);
                            if (++sp > SPIN_MAX_DEV) { s = QUIT; break; }
                            if ((int)(s - last) > 0 || s == QUIT) break;
                            for (unsigned b = 0; b < backoff; ++b) sp += (b >> 31);   // idle backoff
                        }
                    }
                    if (fout == 1 && s != QUIT && (nt % (group ? group : 1u)) == 0) {
                        const unsigned gsz = group ? group : 1u;
                        for (unsigned k = 1; k < gsz && nt + k < nteams; ++k)
                            st_rel<sycl::memory_scope::device>(slotp(ctr, nt + k), s);
                    }
                }
                st_rel<sycl::memory_scope::device>(pub, s);
                last = s;
                // Diagnostics: each team leader records the last REAL job id it entered, on its OWN
                // line. After teardown the host compares them with `done` to see who stopped.
                if (s != QUIT) st_rel<sycl::memory_scope::device>(slot + 8, s);
            }
            it.barrier(sycl::access::fence_space::global_space);
            const unsigned s = ld_rlx<sycl::memory_scope::device>(pub);
            if (s == QUIT) {
                if (tid == 0 && nt == 0) st_rel<sycl::memory_scope::system>(&mb->polls_total, polls_total);
                if (tid == 0) st_rel<sycl::memory_scope::device>(obsep(ctr, nt), aw.best);
                return;
            }

            // ---- the job: this team's units of job s.
            // per_ping > 1 is the ATTRIBUTION knob: the engine does `per_ping` decode jobs' worth of
            // units per doorbell, amortising the whole trigger/fan-in/completion round trip over
            // them. per_ping=1 is the real protocol; a large per_ping approaches mode A (same code,
            // same grid, same bytes). If us/job falls to mode A's number the deficit is the per-job
            // protocol tail; if it stays high, the engine's compiled BODY is slower per expert than
            // a normal launch - which is gate G0's stated failure mode.
            if (!nowork)
            for (size_t uu = nt; uu < units_job * per_ping; uu += nteams) {
                const size_t sub = uu / units_job;             // which decode job of this ping
                const size_t qi = uu % units_job;
                int u, ks, sl;
                unit_map(qi, sk, skd, u, ks, sl);
                const int e = (int)((((s * (unsigned)per_ping) + sub) * (unsigned)nc + (unsigned)sl) %
                                    (unsigned)E);
                do_unit(u, ks, sk, skd, gate, up, down, xgu, xdn, out, e, tid);
            }

            // ---- fan-in + completion. Level-triggered (rule 3). Flat = one counter RMW'd by all
            // teams (arrival, not polling, but still O(N) on one line); two-level = group counter
            // then master, which is what lab_doorbell measured at ~3 us for 8-16 WGs.
            it.barrier(sycl::access::fence_space::global_space);
            if (tid == 0) {
                bool publish = false;
                if (group <= 1) {
                    publish = add_a<sycl::memory_scope::device>(ctr + C_ARRIVE, 1u) == nteams - 1;
                    if (publish) st_rel<sycl::memory_scope::device>(ctr + C_ARRIVE, 0u);
                } else {
                    const unsigned g = nt / group, gs = (nteams + group - 1) / group;
                    const unsigned cnt = (nteams - g * group < group) ? nteams - g * group : group;
                    unsigned* gc = ctr + C_GARR + g * 16;
                    if (add_a<sycl::memory_scope::device>(gc, 1u) == cnt - 1) {
                        st_rel<sycl::memory_scope::device>(gc, 0u);
                        publish = add_a<sycl::memory_scope::device>(ctr + C_ARRIVE, 1u) == gs - 1;
                        if (publish) st_rel<sycl::memory_scope::device>(ctr + C_ARRIVE, 0u);
                    }
                }
                if (publish) st_rel<sycl::memory_scope::system>(&mb->done, s);
            }
        }
    }
};

// ---------------------------------------------------------------- host side
static bool wait_bounded(sycl::event& e, double ms) {
    const double t0 = now_us();
    while (e.get_info<sycl::info::event::command_execution_status>() !=
           sycl::info::event_command_status::complete) {
        if (now_us() - t0 > ms * 1e3) return false;
        _mm_pause();
    }
    return true;
}

struct Pct { double p50 = 0, p90 = 0, p99 = 0, mx = 0, mean = 0; int n = 0, over20 = 0, over20ms = 0; };
static std::vector<unsigned> parse_list(const char* s) {
    std::vector<unsigned> v;
    while (s && *s) {
        v.push_back((unsigned)strtoul(s, (char**)&s, 10));
        while (*s && *s != ',') ++s;
        if (*s == ',') ++s;
    }
    return v;
}
static Pct pct(std::vector<double> v) {
    std::sort(v.begin(), v.end());
    Pct r;
    r.n = (int)v.size();
    if (!r.n) return r;
    r.p50 = v[r.n / 2]; r.p90 = v[(size_t)(r.n * 0.9)]; r.p99 = v[(size_t)(r.n * 0.99)];
    r.mx = v.back();
    double s = 0; for (double x : v) { s += x; if (x > 20.0) ++r.over20; if (x > 20000.0) ++r.over20ms; }
    r.mean = s / r.n;
    return r;
}

// max over teams of "how many teams did you see alive at once" (q.copy is Src,Dest!)
static unsigned max_alive(sycl::queue& q, unsigned* ctr, unsigned n, std::vector<unsigned>& scratch) {
    scratch.resize((size_t)n * 16);
    q.copy(ctr + C_OBS, scratch.data(), n * 16).wait();
    unsigned m = 0;
    for (unsigned i = 0; i < n; ++i) m = std::max(m, scratch[i * 16]);
    return m;
}

int main(int argc, char** argv) {
    setvbuf(stdout, nullptr, _IONBF, 0);
    const char* mode = argc > 1 ? argv[1] : "all";
    const int nc = argc > 2 ? atoi(argv[2]) : 2;
    const int jobs = argc > 3 ? atoi(argv[3]) : 200;
    const int E = 260;                      // experts registered per layer in the shipped config
    if (getenv("LAB_SK")) g_sk = (unsigned)atoi(getenv("LAB_SK"));
    if (getenv("LAB_SK_DN")) g_skd = (unsigned)atoi(getenv("LAB_SK_DN"));
    if (g_sk < 1) g_sk = 1;
    if (g_skd < 1) g_skd = 1;
    const bool wantA = !strcmp(mode, "all") || strchr(mode, 'A') != nullptr;
    const bool wantB = !strcmp(mode, "all") || strchr(mode, 'B') != nullptr;
    const bool wantC = !strcmp(mode, "all") || strchr(mode, 'C') != nullptr;

    sycl::device dev{sycl::gpu_selector_v};
    sycl::context ctx{dev};
    sycl::queue q{ctx, dev, sycl::property::queue::in_order{}};
    printf("device %s | %u CUs | max WG %u | nc %d | jobs %d\n",
           dev.get_info<sycl::info::device::name>().c_str(),
           dev.get_info<sycl::info::device::max_compute_units>(),
           dev.get_info<sycl::info::device::max_work_group_size>(), nc, jobs);

    // arenas: E experts x (gate, up, down) in n-major tile order, plus static x rows
    const size_t tiles_k_gu = HID / 16, TN_gu = INT / 16;
    const size_t tiles_k_dn = INT / 16, TN_dn = HID / 16;
    const size_t wgu = (size_t)E * TN_gu * tiles_k_gu * W;      // words
    const size_t wdn = (size_t)E * TN_dn * tiles_k_dn * W;
    uint32_t* gate = sycl::malloc_device<uint32_t>(wgu, q);
    uint32_t* up = sycl::malloc_device<uint32_t>(wgu, q);
    uint32_t* down = sycl::malloc_device<uint32_t>(wdn, q);
    float* xgu = sycl::malloc_device<float>((size_t)E * HID, q);
    float* xdn = sycl::malloc_device<float>((size_t)E * INT, q);
    float* out = sycl::malloc_device<float>((size_t)(E + 1) * 4096, q);
    unsigned* ctr = sycl::malloc_device<unsigned>(C_WORDS, q);
    Mailbox* mb = (Mailbox*)sycl::malloc_host(sizeof(Mailbox), ctx);
    float* hout = (float*)sycl::malloc_host(HID * sizeof(float), ctx);
    memset((void*)mb, 0, sizeof(Mailbox));
    q.parallel_for(wgu, [=](sycl::id<1> i) { gate[i] = (uint32_t)(i[0] * 2654435761u); }).wait();
    q.parallel_for(wgu, [=](sycl::id<1> i) { up[i] = (uint32_t)(i[0] * 40503u + 7u); }).wait();
    q.parallel_for(wdn, [=](sycl::id<1> i) { down[i] = (uint32_t)(i[0] * 2246822519u); }).wait();
    q.parallel_for((size_t)E * HID, [=](sycl::id<1> i) { xgu[i] = 0.001f * (float)(i[0] & 127); }).wait();
    q.parallel_for((size_t)E * INT, [=](sycl::id<1> i) { xdn[i] = 0.002f * (float)(i[0] & 63); }).wait();
    q.memset(out, 0, (size_t)(E + 1) * 4096 * sizeof(float)).wait();
    q.memset(ctr, 0, C_WORDS * sizeof(unsigned)).wait();

    const size_t units_job = (size_t)upe(g_sk, g_skd) * (size_t)nc;
    const double job_mb = JOB_BYTES_PER_E * nc / 1e6;
    printf("per job: nc %d experts, %zu units (unit = one %d-thread team), %.3f MB packed\n",
           nc, units_job, TEAM, job_mb);
    printf("G0 bars: >= 195 GB/s from a grid that is VERIFIABLY simultaneous (the model pays 6.3 us"
           "/expert\nfor exactly these bytes), and engine wall < split wall - 20 us.\n\n");

    std::vector<unsigned> scratch;
    double split_p50 = 0, eng_p50 = 1e30, eng_gbs = 0, best_gbs = 0;
    int best_gbs_n = -1, resid_max_n = -1, resid_eng_n = -1;

    // ---------------------------------------------------------- mode A
    if (wantA) {
        printf("== A: resident loop (no doorbell) - simultaneity + sustained bandwidth vs team count\n");
        printf("  %-7s %-9s %-9s %-9s %-8s %-9s %s\n", "teams", "us/job", "GB/s", "vs 195",
               "alive", "ticketed", "note");
        for (unsigned n : {16u, 32u, 64u, 96u, 128u, 160u, 192u, 256u, 320u, 448u, 576u, 704u}) {
            const unsigned dp = getenv("LAB_A_DEADPROTO") ? 1u : 0u;
            ResidentLoop rl{gate, up, down, xgu, xdn, out, ctr, E, nc, jobs, units_job, n, g_sk,
                            g_skd, dp, mb};
            q.memset(ctr, 0, C_WORDS * sizeof(unsigned)).wait();
            for (int w = 0; w < 2; ++w)      // clock burn-in with the same grid
                q.submit([&](sycl::handler& cgh) {
                    cgh.parallel_for(sycl::nd_range<1>{{(size_t)n * TEAM}, {TEAM}}, rl);
                }).wait();
            double best = 1e30; unsigned alive = 0, ticketed = 0;
            for (int w = 0; w < 3; ++w) {
                q.memset(ctr, 0, C_WORDS * sizeof(unsigned)).wait();
                const double t0 = now_us();
                q.submit([&](sycl::handler& cgh) {
                    cgh.parallel_for(sycl::nd_range<1>{{(size_t)n * TEAM}, {TEAM}}, rl);
                }).wait();
                const double us = (now_us() - t0) / jobs;
                if (us < best) best = us;
            }
            alive = max_alive(q, ctr, n, scratch);
            q.copy(ctr + C_DIAG, &ticketed, 1).wait();
            const double gbs = job_mb * 1e3 / best;
            const bool resid = (alive >= n) && (ticketed >= n);
            printf("  %-7u %-9.2f %-9.1f %-9s %-8u %-9u %s\n", n, best, gbs,
                   gbs >= 195.0 ? "PASS" : "under", alive, ticketed,
                   resid ? "simultaneous" : "PIPELINED (not co-resident)");
            if (gbs > best_gbs) { best_gbs = gbs; best_gbs_n = (int)n; }
            if (resid && (int)n >= (int)units_job) resid_max_n = std::max(resid_max_n, (int)n);
        }
        printf("  -> best sustained %.1f GB/s at N=%d teams\n\n", best_gbs, best_gbs_n);
    }

    // ---------------------------------------------------------- mode C
    if (wantC) {
        printf("== C: split path (control arm) - blob H2D + gu launch + down launch + D2H, one wait\n");
        const size_t gu_teams = (size_t)nc * 2 * U_GU * g_sk, dn_teams = (size_t)nc * U_DN * g_skd;
        SplitUnits su{gate, up, down, xgu, xdn, out, ctr, E, nc, 0, 0, g_sk, g_skd};
        auto one_job = [&](int j) {
            su.job = j;
            su.phase = 0;
            q.memcpy(ctr + C_WORDS - 16, hout, 4);            // stand-in job blob H2D
            su.ctr = ctr;
            q.submit([&](sycl::handler& cgh) {
                cgh.parallel_for(sycl::nd_range<1>{{gu_teams * TEAM}, {TEAM}}, su);
            });
            su.phase = 1;
            q.submit([&](sycl::handler& cgh) {
                cgh.parallel_for(sycl::nd_range<1>{{dn_teams * TEAM}, {TEAM}}, su);
            });
            q.memcpy(hout, out, HID * sizeof(float));
            q.wait();
        };
        q.memset(ctr, 0, C_WORDS * sizeof(unsigned)).wait();
        for (int j = 0; j < 300; ++j) one_job(j);
        // ---- idle-gap study (the doc's "measure the first launch after idle separately").
        // Direct submission (ULLS) keeps a batch running in user space and DROPS IT after idle, so a
        // workload whose submissions are sporadic can pay the kernel-driver path on the first launch
        // home. Decode is exactly sporadic for this device: one job per layer, ~48 per 14.7 ms token,
        // and the whole card idle between tokens. If a gap costs tens of us, the model's 57.6 us of
        // FIXED cost per layer-step is partly ULLS restart - and a keepalive (or any trick that keeps
        // the batch alive) is a far cheaper lever than a resident engine.
        if (getenv("LAB_GAPSCAN")) {
            const double ka = getenv("LAB_KEEPALIVE_US") ? atof(getenv("LAB_KEEPALIVE_US")) : 0.0;
            sycl::queue qk{ctx, dev, sycl::property::queue::in_order{}};
            float* kbuf = sycl::malloc_device<float>(64, qk);
            printf("  gap scan (host busy-wait before each job; min-of-3 windows p50;"
                   " keepalive %s us):\n", ka > 0 ? getenv("LAB_KEEPALIVE_US") : "off");
            for (double gap : {0.0, 200.0, 1000.0, 2000.0, 3000.0, 5000.0, 10000.0, 20000.0,
                               50000.0, 100000.0}) {
                const int nj = (int)std::min<double>(jobs, std::max(6.0, 3.0e6 / (gap + 50.0)));
                std::vector<double> g;
                long ka_count = 0;
                for (int w = 0; w < 3; ++w) {
                    std::vector<double> walls2;
                    double last_ka = now_us();
                    for (int j = 0; j < nj; ++j) {
                        const double tg = now_us();
                        while (now_us() - tg < gap) {
                            // Keep the submission path warm WITHOUT touching the measured queue:
                            // a trivial kernel on another queue of the same context.
                            if (ka > 0 && now_us() - last_ka >= ka) {
                                last_ka = now_us();
                                qk.single_task([=] { kbuf[0] = 1.0f; });
                                ++ka_count;
                            }
                        }
                        const double tj = now_us();
                        one_job(j);
                        walls2.push_back(now_us() - tj);
                    }
                    g.push_back(pct(walls2).p50);
                }
                if (ka > 0) qk.wait();
                std::sort(g.begin(), g.end());
                printf("    gap %9.0f us | jobs %4d | wall p50 %8.1f us | keepalives %ld (%.2f/job)\n",
                       gap, nj, g[0], ka_count, (double)ka_count / (3.0 * nj));
            }
            printf("  (compare: the model's decode forward is p50 66.1 us with sub 27.2 + wait 28.6;\n"
                   "   decode's own inter-job gap is ~300 us = 48 layer-jobs per 14.7 ms token)\n\n");
            sycl::free(kbuf, qk);
        }
        std::vector<double> walls;
        for (int w = 0; w < 3; ++w) {
            walls.clear();
            for (int j = 0; j < jobs; ++j) {
                const double tj = now_us();
                one_job(j);
                walls.push_back(now_us() - tj);
            }
            split_p50 = split_p50 == 0 ? pct(walls).p50 : std::min(split_p50, pct(walls).p50);
        }
        Pct p = pct(walls);
        printf("  teams gu %zu dn %zu | wall p50 %.1f us (min-of-3 %.1f) | %.1f GB/s | p90 %.1f "
               "p99 %.1f | n=%d\n",
               gu_teams, dn_teams, p.p50, split_p50, job_mb * 1e3 / p.p50, p.p90, p.p99, p.n);
        // ---- A2 control: the SAME work as ONE plain launch (units_job teams, one unit each), no
        // doorbell, no protocol. This is what a resident grid of that size costs when the work itself
        // is cold-started per job - the honest lower bound for an engine per_ping cannot beat.
        {
            su.phase = 2;
            const size_t all_teams = units_job;   // upe(sku,skd)*nc units, one per team
            auto one_all = [&](int j) {
                su.job = j;
                q.submit([&](sycl::handler& cgh) {
                    cgh.parallel_for(sycl::nd_range<1>{{all_teams * TEAM}, {TEAM}}, su);
                });
                q.wait();
            };
            for (int j = 0; j < 300; ++j) one_all(j);
            double best = 1e30;
            for (int w = 0; w < 3; ++w) {
                std::vector<double> wl;
                for (int j = 0; j < jobs; ++j) {
                    const double tj = now_us();
                    one_all(j);
                    wl.push_back(now_us() - tj);
                }
                best = std::min(best, pct(wl).p50);
            }
            printf("  A2 work-only, ONE launch of %zu teams + wait: %.1f us/job | %.1f GB/s\n",
                   all_teams, best, job_mb * 1e3 / best);
            printf("  NOTE: 4 commands/job vs production's 5-6 and no K1/K34 => a HARDER bar than the\n"
                   "  model, not an easier one.\n\n");
        }
    }

    // ---------------------------------------------------------- mode B
    if (wantB) {
        printf("== B: engine + doorbell - per-job wall as seen by the host\n");
        sycl::queue q2{ctx, dev, sycl::property::queue::in_order{}};   // trigger injections
        unsigned* dflag = sycl::malloc_device<unsigned>(16, q2);
        unsigned* hseq = (unsigned*)sycl::malloc_host(64, ctx);
        *hseq = 0;
        q2.memset(dflag, 0, 16).wait();
        const char* tname[] = {"store", "ntstore", "clflush", "dma", "task"};
        const double idle_us = getenv("LAB_IDLE_US") ? atof(getenv("LAB_IDLE_US")) : 0.0;
        const double ka_us = getenv("LAB_KEEPALIVE_US") ? atof(getenv("LAB_KEEPALIVE_US")) : 0.0;
        double ka_count = 0;
        sycl::queue qk{ctx, dev, sycl::property::queue::in_order{}};
        float* kbuf = sycl::malloc_device<float>(64, qk);
        auto ping = [&](unsigned want, unsigned trig) -> double {
            // Plan §2 arms S1/S2 applied to the ENGINE: optionally idle first (the wake-up cost the
            // gap scan found: the same 4-command chain costs 56 us warm, 247 us after 20 ms, 410 us
            // after 100 ms), optionally drip trivial kernels on a THIRD queue during that idle. The
            // doorbell itself stays a pure host store - no command per job - so if a background drip
            // keeps it responsive, the engine's cost model survives.
            if (idle_us > 0.0) {
                const double tg = now_us();
                double lastk = tg;
                for (;;) {
                    const double nn = now_us();
                    if (nn - tg >= idle_us) break;
                    if (ka_us > 0.0 && nn - lastk >= ka_us) {
                        lastk = nn;
                        qk.single_task([=] { kbuf[0] = 1.0f; });
                        ++ka_count;
                    }
                }
            }
            if (trig == TRIG_DMA) {
                *hseq = want;
                q2.memcpy(dflag, hseq, 4);           // DMA into device memory: costs an enqueue
            } else if (trig == TRIG_TASK) {
                Mailbox* m = mb;
                unsigned* df = dflag;
                q2.single_task([=] { df[0] = m->tg_seq; });   // compute-engine write, 1 command
            } else if (trig == TRIG_NTSTORE) {
                _mm_stream_si32((int*)&mb->seq, (int)want);
                _mm_sfence();
            } else {
                __atomic_store_n(&mb->seq, want, __ATOMIC_RELEASE);
                __atomic_store_n(&mb->tg_seq, want, __ATOMIC_RELEASE);
                if (trig == TRIG_CLFLUSH) _mm_clflush(&mb->seq);
            }
            const double t0 = now_us();
            for (;;) {
                const unsigned d = __atomic_load_n(&mb->done, __ATOMIC_ACQUIRE);
                if (d == QUIT) return -2.0;
                if ((int)(d - want) >= 0) return now_us() - t0;
                if (now_us() - t0 > 5000.0) return -1.0;   // 5 ms ceiling => counted as a stall
                _mm_pause();
            }
        };
        const int nowork = getenv("LAB_NOWORK") ? atoi(getenv("LAB_NOWORK")) : 0;
        const unsigned backoff = getenv("LAB_BACKOFF") ? (unsigned)atoi(getenv("LAB_BACKOFF")) : 0;
        const unsigned per_ping = getenv("LAB_PER_PING") ? (unsigned)atoi(getenv("LAB_PER_PING")) : 1;
        const int nwin = getenv("LAB_WIN") ? atoi(getenv("LAB_WIN")) : 3;
        const char* tl = getenv("LAB_ENG_TEAMS");
        std::vector<unsigned> ts = tl ? parse_list(tl) : std::vector<unsigned>{16u, 64u, 128u};
        const char* gl = getenv("LAB_ENG_FAN");
        std::vector<unsigned> gs = gl ? parse_list(gl) : std::vector<unsigned>{8u};
        const char* fl = getenv("LAB_ENG_FOUT");
        std::vector<unsigned> fs = fl ? parse_list(fl) : std::vector<unsigned>{0u, 1u};
        const char* xl = getenv("LAB_ENG_TRIG");
        std::vector<unsigned> xs = xl ? parse_list(xl) : std::vector<unsigned>{0u, 1u, 2u, 3u, 4u};
        printf("  %-7s %-8s %-5s %-4s %-8s %-8s %-8s %-10s %-9s %s\n", "teams", "trig", "fout",
               "fan", "p50", "p90", "p99", "max", ">20ms", "stuck/alive");
        for (unsigned n : ts) {
          for (unsigned fo : fs) {
            for (unsigned grp : gs) {
              for (unsigned trig : xs) {
                q.wait(); q2.wait();
                memset((void*)mb, 0, sizeof(Mailbox));
                q.memset(ctr, 0, C_WORDS * sizeof(unsigned)).wait();
                q2.memset(dflag, 0, 16).wait();
                *hseq = 0;
                Engine eng{mb, ctr, gate, up, down, xgu, xdn, out, E, nc, units_job, n, g_sk, g_skd,
                           grp, fo, trig, dflag, backoff, per_ping, nowork};
                sycl::event resident = q.submit([&](sycl::handler& cgh) {
                    cgh.parallel_for(sycl::nd_range<1>{{(size_t)n * TEAM}, {TEAM}}, eng);
                });
                double first = -3;
                const double tres = now_us();
                // Wait (bounded) for the engine to become resident before scoring anything: at
                // 256-448 teams the launch itself plus the first round trip can exceed one ping
                // ceiling, and treating that as "the doorbell failed" would be a lab artifact.
                do { first = ping(1, trig); } while (first == -1 && now_us() - tres < 3000000.0);
                (void)tres;
                if (first <= 0) {
                    printf("  %-7u %-8s %-5u %-4u DID NOT RESPOND (%.1f: -1 timeout, -2 quit)\n", n,
                           tname[trig], fo, grp, first);
                    __atomic_store_n(&mb->quit, 1u, __ATOMIC_RELEASE);
                    __atomic_store_n(&mb->seq, QUIT, __ATOMIC_RELEASE);
                    if (trig == TRIG_DMA) { *hseq = QUIT; q2.memcpy(dflag, hseq, 4); q2.wait(); }
                    if (trig == TRIG_TASK) {
                        Mailbox* m = mb; unsigned* df = dflag;
                        q2.single_task([=] { df[0] = QUIT; }); q2.wait();
                    }
                    if (!wait_bounded(resident, 4000.0)) printf("    KERNEL WILL NOT EXIT\n");
                    continue;
                }
                std::vector<std::pair<unsigned, double>> v;
                unsigned want = 1; int dead = 0, stalled = 0;
                // burn-in: the first window of any Xe2 measurement lies (rule 1). `first` already
                // proved the engine answers; warm the clocks before scoring anything.
                for (int i = 0; i < std::max(30, jobs / 2); ++i) {
                    const double t = ping(++want, trig);
                    if (t <= 0) ++dead;
                }
                const double t_start = now_us();
                double best_p50 = 1e30;
                std::vector<double> win_p50;
                for (int w = 0; w < nwin; ++w) {
                    std::vector<std::pair<unsigned, double>> vv;
                    int dd = 0, tt = 0;
                    for (int i = 0; i < jobs; ++i) {
                        const double t = ping(++want, trig);
                        if (t > 0) { vv.emplace_back(want, t / per_ping); tt = 0; }
                        else { ++dd; ++stalled; if (++tt >= 20) break; }
                    }
                    std::vector<double> wl; for (auto& pr : vv) wl.push_back(pr.second);
                    const double pp = pct(wl).p50;
                    win_p50.push_back(pp);
                    if (pp < best_p50 || best_p50 == 1e30) { best_p50 = pp; v = vv; dead = dd; }
                }
                const double el = now_us() - t_start;
                std::vector<double> walls; walls.reserve(v.size());
                for (auto& pr : v) walls.push_back(pr.second);
                Pct p = pct(walls);
                const double gbs = job_mb * 1e6 * per_ping / (el / (double)std::max(1, p.n));
                if (p.p50 < eng_p50) { eng_p50 = p.p50; eng_gbs = gbs; }
                __atomic_store_n(&mb->quit, 1u, __ATOMIC_RELEASE);
                __atomic_store_n(&mb->seq, QUIT, __ATOMIC_RELEASE);
                if (trig == TRIG_DMA) { *hseq = QUIT; q2.memcpy(dflag, hseq, 4); q2.wait(); }
                if (trig == TRIG_TASK) {
                    Mailbox* m = mb; unsigned* df = dflag;
                    q2.single_task([=] { df[0] = QUIT; }); q2.wait();
                }
                if (!wait_bounded(resident, 4000.0))
                    printf("    KERNEL WILL NOT EXIT - abandoning wait\n");
                // Readbacks MUST come after teardown: they would otherwise queue behind the resident
                // kernel on this in-order queue and hang the lab.
                const unsigned alive_raw = max_alive(q, ctr, n, scratch);
                // Advisory only: a previous arm whose engine had to be ABANDONED keeps ticketing
                // ENTER, so the sampler saturates. Rigorous residency evidence is mode A's gate test
                // plus this arm responding to every doorbell (dead == 0).
                const unsigned alive = std::min(alive_raw, n);
                // Who stopped arriving? Compare every team's last-entered id with the last id team 0
                // fanned out (slot+0 of team 0) and with the device arrival counter.
                std::vector<unsigned> sl((size_t)n * 16 + 32, 0);
                q.copy(ctr + C_SLOT, sl.data(), (size_t)n * 16).wait();
                unsigned arrive_now = 0, fan_max = 0, ent_min = ~0u;
                q.copy(ctr + C_ARRIVE, &arrive_now, 1).wait();
                for (unsigned t = 0; t < n; ++t) {
                    fan_max = std::max(fan_max, sl[t * 16]);
                    ent_min = std::min(ent_min, sl[t * 16 + 8]);
                }
                int laggards = 0;
                for (unsigned t = 0; t < n; ++t) if (sl[t * 16 + 8] != fan_max) ++laggards;
                if (alive >= n && dead == 0 && (int)n >= (int)units_job)
                    resid_eng_n = std::max(resid_eng_n, (int)n);
                const double polls = (double)mb->polls_total;

                // ---- §2a attribution: zip the host's per-job wall against team 0's own poll count
                // at the moment it observed that job's doorbell. Big wall + big polls = the DEVICE
                // saw the store late; big wall + small polls = the device was watching and the
                // COMPLETION failed to reach the host. No tau needed for that discrimination.
                std::vector<unsigned> ring(4096, 0);
                q.copy(ctr + C_RING, ring.data(), 4096).wait();
                std::vector<std::pair<double, unsigned>> slow;
                for (auto& pr : v) slow.push_back({pr.second, ring[pr.first & 4095u]});
                std::sort(slow.begin(), slow.end());
                printf("  %-7u %-8s %-5u %-4u %-8.1f %-8.1f %-8.1f %-10.1f %-9.2f %d/%u%s n=%d\n",
                       n, tname[trig], fo, grp, p.p50, p.p90, p.p99, p.mx,
                       100.0 * stalled / (double)std::max(1, stalled + p.n), dead, alive,
                       alive >= n ? "" : " NOT-SIMULTANEOUS", p.n);
                if (ka_us > 0.0)
                    printf("     keepalive %.0f us: %.2f submits per job\n", ka_us,
                           ka_count / (double)std::max(1, p.n));
                if (getenv("LAB_TRACE") && !slow.empty()) {
                    printf("     windows p50: ");
                    for (double x : win_p50) printf("%.1f ", x);
                    printf(" | polls %.3g (%.3g/s) | fan-out max id %u | slowest team id %u | "
                           "%d/%u behind | arrive %u\n",
                           polls, polls / (el * 1e-6), fan_max, ent_min, laggards, n, arrive_now);
                }
              }
            }
          }
        }
        printf("\n");
        sycl::free(dflag, q2); sycl::free(hseq, ctx);
    }

    // ---------------------------------------------------------- verdict
    printf("== G0 verdict (nc=%d, %zu units/job, %.3f MB/job)\n", nc, units_job, job_mb);
    if (wantA)
        printf("  simultaneity: largest grid whose teams were all alive at once AND >= the job's unit "
               "count: N=%d\n", resid_max_n);
    if (wantB)
        printf("  engine residency: largest doorbelled grid verified simultaneous: N=%d\n", resid_eng_n);
    if (wantA)
        printf("  bandwidth: best sustained %.1f GB/s at N=%d teams vs the 195 GB/s gate -> %s\n",
               best_gbs, best_gbs_n, best_gbs >= 195.0 ? "PASS" : "FAIL");
    else
        printf("  bandwidth: arm A not run\n");
    if (wantC && wantB && eng_p50 < 1e29)
        printf("  net win: engine p50 %.1f us vs split p50 %.1f us -> delta %.1f us, gate > 20 us:"
               " %s\n", eng_p50, split_p50, split_p50 - eng_p50,
               (split_p50 - eng_p50) > 20.0 ? "PASS" : "FAIL");
    else
        printf("  net win: needs both B and C arms in one run (./lab_resident_bw BC)\n");
    printf("\ncaveats: no act()/quant dataflow between gu and down (this is a resource bound, not\n"
           "semantics); x rows are static; out writes go to scratch; the real engine also carries\n"
           "K1/K34 traffic and the h-dependency.\n");
    sycl::free(gate, q); sycl::free(up, q); sycl::free(down, q);
    sycl::free(xgu, q); sycl::free(xdn, q); sycl::free(out, q);
    sycl::free(ctr, q); sycl::free(mb, ctx); sycl::free(hout, ctx);
    return 0;
}