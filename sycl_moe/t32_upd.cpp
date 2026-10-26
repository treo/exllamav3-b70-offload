// b70_update_expert functional test: forward with expert A in slot e, then update slot e to
// expert B weights, forward again; must equal a fresh layer that was registered with B.
#include <dlfcn.h>
#include <cstdint>
#include <cstdio>
#include <cmath>
#include <cstring>
#include <vector>
#include <random>
using RegFn = int64_t (*)(int, int, int, int, int, int, float, int,
    const uint64_t*, const uint64_t*, const uint64_t*, const uint64_t*,
    const uint64_t*, const uint64_t*, const uint64_t*, const uint64_t*,
    const uint64_t*, const uint64_t*, const uint64_t*, const uint64_t*);
using FwdFn = int (*)(int64_t, const void*, const int32_t*, const void*, float*, int, int);
using UpdFn = int (*)(int64_t, int,
    const uint64_t*, const uint64_t*, const uint64_t*, const uint64_t*,
    const uint64_t*, const uint64_t*, const uint64_t*, const uint64_t*,
    const uint64_t*, const uint64_t*, const uint64_t*, const uint64_t*);
using InitFn = int (*)();
using FreeFn = void (*)(int64_t);

int main()
{
    void* h = dlopen("./libb70moe.so", RTLD_NOW);
    if (!h) { printf("dlopen: %s\n", dlerror()); return 1; }
    auto init  = (InitFn)dlsym(h, "b70_init");
    auto reg   = (RegFn)dlsym(h, "b70_register_layer");
    auto fwd   = (FwdFn)dlsym(h, "b70_forward");
    auto upd   = (UpdFn)dlsym(h, "b70_update_expert");
    auto freelay = (FreeFn)dlsym(h, "b70_free_layer");
    if (!upd) { printf("NO b70_update_expert SYMBOL\n"); return 1; }
    if (init()) return 1;
    const int E = 4, H = 2560, I = 640, bits = 2, hb = 1, k2 = 2 * bits + hb;
    const size_t pu_gu = (size_t)(H / 16) * (I / 16) * 8 * k2;   // u16 elems
    const size_t pu_d  = (size_t)(I / 16) * (H / 16) * 8 * k2;
    std::mt19937 rng(1234);
    auto mk = [&](size_t n, int seedoff) {
        std::vector<uint16_t> v(n);
        std::mt19937 r(rng() + seedoff);
        for (auto& x : v) x = (uint16_t)r();
        return v;
    };
    // finite fp16 for scales/activations (random exponent bits would emit inf/NaN and make
    // every numeric assertion vacuous)
    auto mk16 = [&](size_t n, int seedoff) {
        std::vector<uint16_t> v(n);
        std::mt19937 r(rng() + seedoff);
        for (auto& x : v) x = (uint16_t)(0x2c00 + (r() & 0x1fff));   // ~0.008..0.31
        return v;
    };
    // two expert weight sets A and B (fresh random), built for every layer-cat
    struct W { std::vector<uint16_t> tr, suh, svh; };
    auto setw = [&](std::vector<W>& g, std::vector<W>& u, std::vector<W>& d, int seed) {
        g.clear(); u.clear(); d.clear();
        for (int e = 0; e < E; ++e) {
            g.push_back({ mk(pu_gu, seed + e * 7 + 1), mk16(H, seed + e * 7 + 2), mk16(I, seed + e * 7 + 3) });
            u.push_back({ mk(pu_gu, seed + e * 7 + 4), mk16(H, seed + e * 7 + 5), mk16(I, seed + e * 7 + 6) });
            d.push_back({ mk(pu_d,  seed + e * 7 + 7), mk16(I, seed + e * 7 + 8), mk16(H, seed + e * 7 + 9) });
        }
    };
    std::vector<W> gA, uA, dA, gB, uB, dB;
    setw(gA, uA, dA, 1000); setw(gB, uB, dB, 90000);
    auto pack = [&](std::vector<W>& g, std::vector<W>& u, std::vector<W>& d,
                    std::vector<uint64_t>& ptrs) {
        ptrs.clear();
        for (auto* ws : { &g, &u, &d }) for (auto& w : *ws) { ptrs.push_back((uint64_t)(uintptr_t)w.tr.data()); }
        size_t k = ptrs.size();
        for (auto* ws : { &g, &u, &d }) for (auto& w : *ws) { ptrs.push_back((uint64_t)(uintptr_t)w.suh.data()); }
        size_t k2i = ptrs.size();
        for (auto* ws : { &g, &u, &d }) for (auto& w : *ws) { ptrs.push_back((uint64_t)(uintptr_t)w.svh.data()); }
        (void)k; (void)k2i;
    };
    // register layout expected by the ABI: per-cat arrays of E trellis ptrs, E suh, E svh, E bias(=0)
    auto arrays = [&](std::vector<W>& w, std::vector<uint64_t>& tr, std::vector<uint64_t>& suh,
                      std::vector<uint64_t>& svh) {
        tr.clear(); suh.clear(); svh.clear();
        for (auto& x : w) { tr.push_back((uint64_t)(uintptr_t)x.tr.data());
                            suh.push_back((uint64_t)(uintptr_t)x.suh.data());
                            svh.push_back((uint64_t)(uintptr_t)x.svh.data()); }
    };
    std::vector<uint64_t> gtr, gsuh, gsvh, utr, usuh, usvh, dtr, dsuh, dsvh, zb;
    arrays(gA, gtr, gsuh, gsvh); arrays(uA, utr, usuh, usvh); arrays(dA, dtr, dsuh, dsvh);
    zb.assign(E, 0);
    int64_t L1 = reg(E, H, I, bits, hb, 0, 0.f, 1, gtr.data(), gsuh.data(), gsvh.data(), zb.data(),
                     utr.data(), usuh.data(), usvh.data(), zb.data(),
                     dtr.data(), dsuh.data(), dsvh.data(), zb.data());
    if (L1 < 0) { printf("reg failed\n"); return 1; }
    const int rows = 3, topk = 4;
    std::vector<uint16_t> x(rows * H), wts(rows * topk);
    for (auto& v : x) v = (uint16_t)(0x2c00 + (rng() & 0x1fff));
    _Float16 wf = (float)0.25; for (auto& v : wts) memcpy(&v, &wf, 2);
    std::vector<int32_t> sel(rows * topk);
    for (int i = 0; i < rows * topk; ++i) sel[i] = i % E;
    std::vector<float> o1(rows * H), o2(rows * H), o3(rows * H);
    if (fwd(L1, x.data(), sel.data(), wts.data(), o1.data(), rows, topk)) { printf("fwd1 failed\n"); return 1; }
    // now REPLACE slot 1 and 3 (updates for expert 1 -> B1, 3 -> B3)
    struct Single { std::vector<uint64_t> gtr,gsuh,gsvh,gb, utr,usuh,usvh,ub, dtr,dsuh,dsvh,db; } s1, s3;
    auto one = [&](W& gw, W& uw, W& dww, Single& s) {
        s.gtr = { (uint64_t)(uintptr_t)gw.tr.data() }; s.gsuh = { (uint64_t)(uintptr_t)gw.suh.data() };
        s.gsvh = { (uint64_t)(uintptr_t)gw.svh.data() }; s.gb = { 0 };
        s.utr = { (uint64_t)(uintptr_t)uw.tr.data() }; s.usuh = { (uint64_t)(uintptr_t)uw.suh.data() };
        s.usvh = { (uint64_t)(uintptr_t)uw.svh.data() }; s.ub = { 0 };
        s.dtr = { (uint64_t)(uintptr_t)dww.tr.data() }; s.dsuh = { (uint64_t)(uintptr_t)dww.suh.data() };
        s.dsvh = { (uint64_t)(uintptr_t)dww.svh.data() }; s.db = { 0 };
    };
    one(gB[1], uB[1], dB[1], s1); one(gB[3], uB[3], dB[3], s3);
    int r1 = upd(L1, 1, s1.gtr.data(), s1.gsuh.data(), s1.gsvh.data(), s1.gb.data(),
                 s1.utr.data(), s1.usuh.data(), s1.usvh.data(), s1.ub.data(),
                 s1.dtr.data(), s1.dsuh.data(), s1.dsvh.data(), s1.db.data());
    int r2 = upd(L1, 3, s3.gtr.data(), s3.gsuh.data(), s3.gsvh.data(), s3.gb.data(),
                 s3.utr.data(), s3.usuh.data(), s3.usvh.data(), s3.ub.data(),
                 s3.dtr.data(), s3.dsuh.data(), s3.dsvh.data(), s3.db.data());
    if (r1 || r2) { printf("update failed r1=%d r2=%d\n", r1, r2); return 1; }
    if (fwd(L1, x.data(), sel.data(), wts.data(), o2.data(), rows, topk)) { printf("fwd2 failed\n"); return 1; }
    // reference: fresh layer registered directly with the MIXED set (slots 1,3 = B)
    auto A2 = gA; auto U2 = uA; auto D2 = dA;
    A2[1] = gB[1]; U2[1] = uB[1]; D2[1] = dB[1];
    A2[3] = gB[3]; U2[3] = uB[3]; D2[3] = dB[3];
    arrays(A2, gtr, gsuh, gsvh); arrays(U2, utr, usuh, usvh); arrays(D2, dtr, dsuh, dsvh);
    int64_t L2 = reg(E, H, I, bits, hb, 0, 0.f, 1, gtr.data(), gsuh.data(), gsvh.data(), zb.data(),
                     utr.data(), usuh.data(), usvh.data(), zb.data(),
                     dtr.data(), dsuh.data(), dsvh.data(), zb.data());
    if (L2 < 0) { printf("reg2 failed\n"); return 1; }
    if (fwd(L2, x.data(), sel.data(), wts.data(), o3.data(), rows, topk)) { printf("fwd3 failed\n"); return 1; }
    double md = 0; size_t diff = 0;
    for (size_t i = 0; i < o2.size(); ++i) {
        double d = std::fabs((double)o2[i] - (double)o3[i]);
        if (d > 0) diff++;
        if (d > md) md = d;
    }
    double mmixed_vs_old = 0;
    for (size_t i = 0; i < o2.size(); ++i) mmixed_vs_old = std::max(mmixed_vs_old, std::fabs((double)o2[i] - (double)o1[i]));
    printf("updated-vs-fresh max|diff| = %g (nonzero elems %zu / %zu)\n", md, diff, o2.size());
    printf("updated-vs-before-update max|diff| = %g  (must be >0: weights really changed)\n", mmixed_vs_old);
    printf("%s\n", (md == 0.0 && mmixed_vs_old > 0.0) ? "UPDATE TEST PASS" : "UPDATE TEST FAIL");
    freelay(L1); freelay(L2);
    return !(md == 0.0 && mmixed_vs_old > 0.0);
}
