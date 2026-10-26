// Load-path repro: 48 sequential E=256 registrations (the model's shape), i.e. what the
// worker child does while the parent loads. Optional second phase: a background thread
// firing forwards while further registrations proceed (the autosplit-measure shape that
// the exec_mu fix is meant to serialize). Usage: t34_load [concurrent]
#include <dlfcn.h>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <ctime>
#include <vector>
#include <random>
#include <thread>
#include <atomic>
#include <unistd.h>
using RegFn = int64_t (*)(int, int, int, int, int, int, float, int,
    const uint64_t*, const uint64_t*, const uint64_t*, const uint64_t*,
    const uint64_t*, const uint64_t*, const uint64_t*, const uint64_t*,
    const uint64_t*, const uint64_t*, const uint64_t*, const uint64_t*);
using FwdFn = int (*)(int64_t, const void*, const int32_t*, const void*, float*, int, int);
using InitFn = int (*)();

int main(int argc, char** argv)
{
    const bool concurrent = argc > 1;
    void* h = dlopen("./libb70moe.so", RTLD_NOW);
    if (!h) { printf("dlopen: %s\n", dlerror()); return 1; }
    auto init = (InitFn)dlsym(h, "b70_init");
    auto reg = (RegFn)dlsym(h, "b70_register_layer");
    auto fwd = (FwdFn)dlsym(h, "b70_forward");
    if (init()) return 1;
    const int E = 256, H = 2560, I = 640, bits = 2, hb = 0, k2 = 2 * bits + hb;
    const size_t pu = (size_t)(H / 16) * (I / 16) * 8 * k2;
    std::mt19937 rng(5);
    // one shared weight set (page-cache-cheap), registered as 48 "layers"
    std::vector<uint16_t> tri(pu), sc(H), ic(I);
    for (auto& x : tri) x = (uint16_t)rng();
    for (auto& x : sc) x = (uint16_t)(0x2c00 + (rng() & 0x1fff));
    for (auto& x : ic) x = (uint16_t)(0x2c00 + (rng() & 0x1fff));
    std::vector<uint64_t> tr(E), su(E), sv(E), zb(E, 0);
    for (int e = 0; e < E; ++e) { tr[e] = (uint64_t)(uintptr_t)tri.data(); su[e] = (uint64_t)(uintptr_t)sc.data(); sv[e] = (uint64_t)(uintptr_t)ic.data(); }
    std::vector<uint16_t> x((size_t)128 * H), w(128 * 10);
    for (auto& v : x) v = (uint16_t)(0x2c00 + (rng() & 0x1fff));
    _Float16 wf = 0.25f; for (auto& v : w) memcpy(&v, &wf, 2);
    std::vector<int32_t> sel(128 * 10);
    for (size_t i = 0; i < sel.size(); ++i) sel[i] = (int)(rng() % (unsigned)E);
    std::vector<float> out((size_t)128 * H);
    std::vector<int64_t> handles;
    std::atomic<bool> busy { false };
    auto t0 = std::clock();
    for (int li = 0; li < 48; ++li)
    {
        const int64_t hh = reg(E, H, I, bits, hb, 0, 0.f, 1, tr.data(), su.data(), sv.data(), zb.data(),
                               tr.data(), su.data(), sv.data(), zb.data(),
                               tr.data(), su.data(), sv.data(), zb.data());
        if (hh < 0) { printf("reg failed at %d\n", li); return 1; }
        handles.push_back(hh);
        if (concurrent && li == 4 && handles.size() == 5)
        {
            // worker-thread analogue: keep firing real jobs while the remaining 43 layers
            // register+warm on the "main" thread (the autosplit-measure overlap)
            busy = true;
            std::thread th([&]() {
                long n = 0;
                while (busy) {
                    alarm(45);
                    const int rows = 1 + (int)(n % 128);   // mix under and over the 64 prime
                    int rc = fwd(handles[n % 5], x.data(), sel.data(), w.data(), out.data(), rows, 10);
                    alarm(0);
                    if (rc) { printf("job rc=%d\n", rc); _exit(2); }
                    if (++n % 256 == 0) printf("  jobs=%ld ok\n", n), fflush(stdout);
                }
            });
            th.detach();
        }
        if (li % 8 == 7) printf("layer %d at %.1fs\n", li + 1, (double)(std::clock() - t0) / CLOCKS_PER_SEC), fflush(stdout);
    }
    printf("48 layers registered; entering quiet phase\n"); fflush(stdout);
    sleep(concurrent ? 3 : 0);
    busy = false;
    // final proof the layers still work
    int rc = fwd(handles[23], x.data(), sel.data(), w.data(), out.data(), 128, 10);
    alarm(45);
    rc |= fwd(handles[47], x.data(), sel.data(), w.data(), out.data(), 128, 10);
    alarm(0);
    printf("final fwd rc=%d -> %s\n", rc, rc ? "FAIL" : "LOAD REPRO PASS");
    return rc;
}