// Bounce-cap growth test (regression for the silent-FATAL bug): a job larger than the
// registration's 64-row prime must run, not refuse. Exactness anchor: per-token results are
// chunk-width invariant (i8trace), so one 128-row forward must equal the two 64-row halves.
#include <dlfcn.h>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <cmath>
#include <vector>
#include <random>
using RegFn = int64_t (*)(int, int, int, int, int, int, float, int,
    const uint64_t*, const uint64_t*, const uint64_t*, const uint64_t*,
    const uint64_t*, const uint64_t*, const uint64_t*, const uint64_t*,
    const uint64_t*, const uint64_t*, const uint64_t*, const uint64_t*);
using FwdFn = int (*)(int64_t, const void*, const int32_t*, const void*, float*, int, int);
using InitFn = int (*)();

int main()
{
    void* h = dlopen("./libb70moe.so", RTLD_NOW);
    if (!h) { printf("dlopen: %s\n", dlerror()); return 1; }
    auto init = (InitFn)dlsym(h, "b70_init");
    auto reg = (RegFn)dlsym(h, "b70_register_layer");
    auto fwd = (FwdFn)dlsym(h, "b70_forward");
    if (init()) return 1;
    const int E = 4, H = 2560, I = 640, bits = 2, hb = 1, k2 = 2 * bits + hb;
    const size_t pu_gu = (size_t)(H / 16) * (I / 16) * 8 * k2;
    const size_t pu_d  = (size_t)(I / 16) * (H / 16) * 8 * k2;
    std::mt19937 rng(77);
    struct W { std::vector<uint16_t> tr, suh, svh; };
    std::vector<W> g, u, d;
    auto mk = [&](size_t n) { std::vector<uint16_t> v(n); std::mt19937 r(rng()); for (auto& x : v) x = (uint16_t)r(); return v; };
    auto mk16 = [&](size_t n) { std::vector<uint16_t> v(n); std::mt19937 r(rng()); for (auto& x : v) x = (uint16_t)(0x2c00 + (r() & 0x1fff)); return v; };
    for (int e = 0; e < E; ++e) {
        g.push_back({ mk(pu_gu), mk16(H), mk16(I) });
        u.push_back({ mk(pu_gu), mk16(H), mk16(I) });
        d.push_back({ mk(pu_d),  mk16(I), mk16(H) });
    }
    std::vector<uint64_t> gtr, gsuh, gsvh, utr, usuh, usvh, dtr, dsuh, dsvh, zb;
    auto arr = [&](std::vector<W>& w, std::vector<uint64_t>& tr, std::vector<uint64_t>& suh, std::vector<uint64_t>& svh) {
        for (auto& x : w) { tr.push_back((uint64_t)(uintptr_t)x.tr.data()); suh.push_back((uint64_t)(uintptr_t)x.suh.data()); svh.push_back((uint64_t)(uintptr_t)x.svh.data()); }
    };
    arr(g, gtr, gsuh, gsvh); arr(u, utr, usuh, usvh); arr(d, dtr, dsuh, dsvh);
    printf("dbg: gsz=%zu g0.tr=%zu gtr0=%llx u0.tr=%zu utr0=%llx\n", g.size(),
           g[0].tr.size(), (unsigned long long)gtr[0], u[0].tr.size(), (unsigned long long)utr[0]);
    zb.assign(E, 0);
    int64_t L = reg(E, H, I, bits, hb, 0, 0.f, 1, gtr.data(), gsuh.data(), gsvh.data(), zb.data(),
                    utr.data(), usuh.data(), usvh.data(), zb.data(), dtr.data(), dsuh.data(), dsvh.data(), zb.data());
    if (L < 0) { printf("reg failed\n"); return 1; }
    const int rows = 128, topk = 4;
    std::vector<uint16_t> x((size_t)rows * H), wts(rows * topk);
    for (auto& v : x) v = (uint16_t)(0x2c00 + (rng() & 0x1fff));
    _Float16 wf = (float)0.25; for (auto& v : wts) memcpy(&v, &wf, 2);
    std::vector<int32_t> sel((size_t)rows * topk);
    for (int i = 0; i < rows * topk; ++i) sel[i] = (i * 7) / topk % E;   // ~even expert spread
    std::vector<float> full((size_t)rows * H), a((size_t)64 * H), b((size_t)64 * H);
    int r1 = fwd(L, x.data(), sel.data(), wts.data(), full.data(), rows, topk);
    int r2 = fwd(L, x.data(), sel.data(), wts.data(), a.data(), 64, topk);
    int r3 = fwd(L, x.data() + (size_t)64 * H, sel.data() + 64 * topk,
                 wts.data() + 64 * topk, b.data(), 64, topk);
    if (r1 || r2 || r3) { printf("fwd rc %d %d %d (growth must not fail)\n", r1, r2, r3); return 1; }
    double md = 0; bool nz = false;
    for (size_t i = 0; i < (size_t)64 * H; ++i) {
        md = std::max(md, std::fabs((double)full[i] - (double)a[i]));
        md = std::max(md, std::fabs((double)full[64 * (size_t)H + i] - (double)b[i]));
        if (full[i] != 0.f) nz = true;
    }
    printf("128-row growth forward vs two 64-row halves: max|diff|=%g, nonzero=%d -> %s\n",
           md, (int)nz, (md == 0.0 && nz) ? "GROWTH TEST PASS" : "GROWTH TEST FAIL");
    return !(md == 0.0 && nz);
}