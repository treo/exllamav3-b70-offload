// cold-call investigation: run forward() twice, dump ws state right after each call
#include <sycl/sycl.hpp>
#include <cstdio>
#include <cmath>
#include <cstdlib>
#include <vector>
#include "exl3_ref.h"
#include "moe_sycl.hpp"
using namespace moe_sycl;
int main(int argc, char** argv) {
    const int H = 2560, I = 640, E = 8, bits = 2, hb = 0;
    sycl::queue q{sycl::gpu_selector_v};
    exl3ref::Rng rng(7);
    const int pu = exl3ref::tile_u16(bits, hb);
    auto mk = [&](int k, int n, MatrixSrc& d) {
        std::vector<uint16_t> tri((size_t)(k/16)*(n/16)*pu), suh(k), svh(n);
        for (auto& v : tri) v = (uint16_t)(rng.next() >> 40);
        for (auto& v : suh) v = exl3ref::f32_to_f16(rng.uniform(0.02f, 0.06f));
        for (auto& v : svh) v = exl3ref::f32_to_f16(rng.uniform(0.02f, 0.06f));
        d.trellis = sycl::malloc_device<uint16_t>(tri.size(), q); q.memcpy((void*)d.trellis, tri.data(), tri.size()*2).wait();
        d.suh = sycl::malloc_device<uint16_t>(k, q); q.memcpy((void*)d.suh, suh.data(), k*2).wait();
        d.svh = sycl::malloc_device<uint16_t>(n, q); q.memcpy((void*)d.svh, svh.data(), n*2).wait();
    };
    std::vector<MatrixSrc> gs(E), us(E), ds(E);
    for (int e = 0; e < E; ++e) { mk(H, I, gs[e]); mk(H, I, us[e]); mk(I, H, ds[e]); }
    LayerParams p{E, H, I, bits, hb, 0, 0.f, true};
    MoeSyclLayer layer; layer.init(&q, p, gs, us, ds);
    // 8 chunks m=1
    std::vector<ChunkDev> chunks(8);
    TokenMap tmap; tmap.begin = {0, 8};
    for (int j = 0; j < 8; ++j) {
        chunks[j] = ChunkDev{j, 1, {0,0,0,0}, {0.5f,0,0,0}};
        tmap.entry.push_back(j*4);
    }
    std::vector<uint16_t> hx(H);
    for (auto& v : hx) v = exl3ref::f32_to_f16(rng.uniform(-2.f, 2.f));
    uint16_t* dx = sycl::malloc_device<uint16_t>(H, q); q.memcpy(dx, hx.data(), H*2).wait();
    float* dout = sycl::malloc_device<float>(H, q);
    for (int call = 1; call <= 2; ++call) {
        layer.forward(chunks.data(), 8, tmap, dx, dout, 1);
        q.wait();
        std::vector<float> probe((size_t)8*4*I);
        q.memcpy(probe.data(), layer.ws(2), probe.size()*4).wait();  // hbuf
        int nz = 0; double s = 0; for (auto v : probe) { nz += v != 0; s += std::fabs(v); }
        std::vector<float> o(H); q.memcpy(o.data(), dout, H*4).wait();
        int onz = 0; for (auto v : o) onz += v != 0;
        printf("call %d: hbuf nz %d/%d absmean %.4g | out nz %d/%d\n", call, nz, (int)probe.size(), s/probe.size(), onz, H);
        layer.debug_read();
    }
    return 0;
}
