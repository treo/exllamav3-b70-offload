// Three-tier subset registration (b70_register_layer_n): members [0,n_sub) must behave
// bit-identically to a full registration; updates to members publish, updates to
// non-members no-op without disturbing members; a stray non-member id in a job must
// produce FINITE output (aliased slot-0 weights), never a fault or NaN.
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
using RegNFn = int64_t (*)(int, int, int, int, int, int, float, int,
    const uint64_t*, const uint64_t*, const uint64_t*, const uint64_t*,
    const uint64_t*, const uint64_t*, const uint64_t*, const uint64_t*,
    const uint64_t*, const uint64_t*, const uint64_t*, const uint64_t*, int);
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
    auto regn  = (RegNFn)dlsym(h, "b70_register_layer_n");
    auto fwd   = (FwdFn)dlsym(h, "b70_forward");
    auto upd   = (UpdFn)dlsym(h, "b70_update_expert");
    auto ebytes = (int64_t (*)(int, int, int, int, int))dlsym(h, "b70_expert_bytes");
    auto freelay = (FreeFn)dlsym(h, "b70_free_layer");
    if (!regn || !upd || !ebytes) { printf("MISSING SYMBOLS\n"); return 1; }
    if (init()) return 1;
    const int E = 4, NSUB = 2, H = 2560, I = 640, bits = 2, hb = 1, k2 = 2 * bits + hb;
    const size_t pu_gu = (size_t)(H / 16) * (I / 16) * 8 * k2;
    const size_t pu_d  = (size_t)(I / 16) * (H / 16) * 8 * k2;
    std::mt19937 rng(777);
    auto mk = [&](size_t n, int seedoff) {
        std::vector<uint16_t> v(n);
        std::mt19937 r(rng() + seedoff);
        for (auto& x : v) x = (uint16_t)r();
        return v;
    };
    auto mk16 = [&](size_t n, int seedoff) {
        std::vector<uint16_t> v(n);
        std::mt19937 r(rng() + seedoff);
        for (auto& x : v) x = (uint16_t)(0x2c00 + (r() & 0x1fff));
        return v;
    };
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
    printf("expert bytes = %ld\n", (long)ebytes(H, I, bits, hb, 1));

    const int rows = 3, topk = 4;
    std::vector<uint16_t> x(rows * H), wts(rows * topk);
    for (auto& v : x) v = (uint16_t)(0x2c00 + (rng() & 0x1fff));
    _Float16 wf = (float)0.25; for (auto& v : wts) memcpy(&v, &wf, 2);
    std::vector<int32_t> selM(rows * topk), selAll(rows * topk), selStray(rows * topk);
    for (int i = 0; i < rows * topk; ++i) { selM[i] = i % NSUB; selAll[i] = i % E; selStray[i] = NSUB + (i % (E - NSUB)); }
    std::vector<float> o_full(rows * H), o_sub(rows * H), o_sub2(rows * H), o_fresh(rows * H);

    // 1) full reference on members-only sel
    int64_t Lf = reg(E, H, I, bits, hb, 0, 0.f, 1, gtr.data(), gsuh.data(), gsvh.data(), zb.data(),
                     utr.data(), usuh.data(), usvh.data(), zb.data(),
                     dtr.data(), dsuh.data(), dsvh.data(), zb.data());
    if (Lf < 0 || fwd(Lf, x.data(), selM.data(), wts.data(), o_full.data(), rows, topk)) { printf("full reg/fwd FAILED\n"); return 1; }

    // 2) subset registration: members-only forward must be BIT-IDENTICAL
    int64_t Ls = regn(E, H, I, bits, hb, 0, 0.f, 1, gtr.data(), gsuh.data(), gsvh.data(), zb.data(),
                      utr.data(), usuh.data(), usvh.data(), zb.data(),
                      dtr.data(), dsuh.data(), dsvh.data(), zb.data(), NSUB);
    if (Ls < 0) { printf("regn FAILED\n"); return 1; }
    if (fwd(Ls, x.data(), selM.data(), wts.data(), o_sub.data(), rows, topk)) { printf("sub fwd FAILED\n"); return 1; }
    bool eq1 = o_sub == o_full;
    printf("test1 members subset == full: %s\n", eq1 ? "PASS" : "FAIL");

    // 3) member update publishes (slot 1 -> B1), equals fresh subset registration with B1
    struct Single { std::vector<uint64_t> gtr,gsuh,gsvh,gb, utr,usuh,usvh,ub, dtr,dsuh,dsvh,db; } s1;
    s1.gtr = { (uint64_t)(uintptr_t)gB[1].tr.data() }; s1.gsuh = { (uint64_t)(uintptr_t)gB[1].suh.data() };
    s1.gsvh = { (uint64_t)(uintptr_t)gB[1].svh.data() }; s1.gb = { 0 };
    s1.utr = { (uint64_t)(uintptr_t)uA[1].tr.data() }; s1.usuh = { (uint64_t)(uintptr_t)uA[1].suh.data() };
    s1.usvh = { (uint64_t)(uintptr_t)uA[1].svh.data() }; s1.ub = { 0 };
    s1.dtr = { (uint64_t)(uintptr_t)dA[1].tr.data() }; s1.dsuh = { (uint64_t)(uintptr_t)dA[1].suh.data() };
    s1.dsvh = { (uint64_t)(uintptr_t)dA[1].svh.data() }; s1.db = { 0 };
    if (upd(Ls, 1, s1.gtr.data(), s1.gsuh.data(), s1.gsvh.data(), s1.gb.data(),
            s1.utr.data(), s1.usuh.data(), s1.usvh.data(), s1.ub.data(),
            s1.dtr.data(), s1.dsuh.data(), s1.dsvh.data(), s1.db.data())) { printf("upd member FAILED\n"); return 1; }
    if (fwd(Ls, x.data(), selM.data(), wts.data(), o_sub2.data(), rows, topk)) { printf("sub2 fwd FAILED\n"); return 1; }
    std::vector<W> gC = gA; gC[1] = gB[1];
    std::vector<uint64_t> ctr, csuh, csvh;
    arrays(gC, ctr, csuh, csvh);
    int64_t Lfr = regn(E, H, I, bits, hb, 0, 0.f, 1, ctr.data(), csuh.data(), csvh.data(), zb.data(),
                       utr.data(), usuh.data(), usvh.data(), zb.data(),
                       dtr.data(), dsuh.data(), dsvh.data(), zb.data(), NSUB);
    if (Lfr < 0 || fwd(Lfr, x.data(), selM.data(), wts.data(), o_fresh.data(), rows, topk)) { printf("fresh regn FAILED\n"); return 1; }
    bool eq2 = o_sub2 == o_fresh;
    bool chg = o_sub2 != o_sub;
    printf("test2 member update publishes: %s (changed=%d)\n", (eq2 && chg) ? "PASS" : "FAIL", (int)chg);

    // 4) non-member update is a no-op that leaves members untouched
    if (upd(Ls, 3, s1.gtr.data(), s1.gsuh.data(), s1.gsvh.data(), s1.gb.data(),
            s1.utr.data(), s1.usuh.data(), s1.usvh.data(), s1.ub.data(),
            s1.dtr.data(), s1.dsuh.data(), s1.dsvh.data(), s1.db.data()) != 0) { printf("nonmember upd != 0: FAIL\n"); return 1; }
    std::vector<float> o_sub3(rows * H);
    if (fwd(Ls, x.data(), selM.data(), wts.data(), o_sub3.data(), rows, topk)) { printf("sub3 fwd FAILED\n"); return 1; }
    printf("test3 nonmember update no-op: %s\n", o_sub3 == o_sub2 ? "PASS" : "FAIL");

    // 5) stray non-member ids: finite output, no fault (aliased weights; child must filter,
    //    but defense in depth means a bug upstream is a wrong number, not a dead device)
    if (fwd(Ls, x.data(), selStray.data(), wts.data(), o_sub.data(), rows, topk)) { printf("stray fwd FAILED\n"); return 1; }
    bool finite = true;
    for (float v : o_sub) if (!std::isfinite(v)) { finite = false; break; }
    printf("test4 stray nonmember finite: %s\n", finite ? "PASS" : "FAIL");

    freelay(Lf); freelay(Ls); freelay(Lfr);
    bool all = eq1 && eq2 && chg && finite;
    printf("%s\n", all ? "SUBSET TEST PASS" : "SUBSET TEST FAIL");
    return all ? 0 : 2;
}