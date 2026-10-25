// Microbench + correctness harness for the SYCL MoE layer forward: synthesizes a layer of
// mul1 experts, runs the device forward and a host fp32 reference, compares, and times it.
#include <sycl/sycl.hpp>
#include <chrono>
#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <string>
#include <unordered_set>
#include <vector>
#include <map>
#include <fstream>
#include <algorithm>
#include <cmath>
#include "exl3_ref.h"
#include "moe_host_ref.hpp"
#include "moe_sycl.hpp"

using namespace moe_sycl;

struct Args
{
    int E = 16, rows = 1, topk = 10, bits = 2, hb = 0, act = 0, iters = 50;
    bool gated = true, check = true, verbose = false, i8trace = false;
    uint64_t seed = 7;
    const char* load = nullptr;
};

// i8_trace: external, readback-driven stage verifier for the int8/XMX pipeline.
// Each stage is emulated on the host FROM READBACKS of its input buffers and compared
// against the readback of its output buffer. Integer stages bit-exact; float 1e-5 rel.
// Uses only public peek()/i8buf()/ws(); touches no kernel state.
static void i8_trace(MoeSyclLayer& layer, const moe_ref::Layer& L,
                     const std::vector<ChunkDev>& chunks, const TokenMap& tmap,
                     const std::vector<float>& out_host)
{
    const int H = L.hidden, I = L.interm;
    const bool gated = L.gated;
    const int nm = gated ? 2 : 1;
    const int nc = (int)chunks.size();
    const int slots = nc * nm;
    constexpr float KDQ = 0.00676727294921875f;
    constexpr float HS = 0.088388347648f;   // HAD_SCALE
    printf("== i8trace: nc %d nm %d ==\n", nc, nm);

    std::vector<float> tin((size_t)slots * 4 * H);
    layer.peek(tin.data(), layer.ws(0), tin.size() * 4);
    std::vector<int32_t> a8u((size_t)slots * (H / 8) * 64);
    layer.peek(a8u.data(), layer.i8buf(0), a8u.size() * 4);
    std::vector<float> qsxu((size_t)slots * 8 * 2);
    layer.peek(qsxu.data(), layer.i8buf(2), qsxu.size() * 4);
    std::vector<int32_t> accgu((size_t)slots * 8 * I);
    layer.peek(accgu.data(), layer.i8buf(4), accgu.size() * 4);
    std::vector<float> tind((size_t)nc * 4 * I);
    layer.peek(tind.data(), layer.ws(3), tind.size() * 4);
    std::vector<int32_t> a8d((size_t)nc * (I / 8) * 64);
    layer.peek(a8d.data(), layer.i8buf(1), a8d.size() * 4);
    std::vector<float> qsxd((size_t)nc * 8 * 2);
    layer.peek(qsxd.data(), layer.i8buf(3), qsxd.size() * 4);
    std::vector<int32_t> accd((size_t)nc * 8 * H);
    layer.peek(accd.data(), layer.i8buf(5), accd.size() * 4);

    int fails = 0;
    auto closef = [](float a, float b) {
        const double d = std::fabs((double)a - b);
        return d <= 1e-5 * std::fabs((double)b) + 1e-9;
    };
    auto x8row = [&](const std::vector<int32_t>& a8, int slot, int r, int k, int K) {
        const int kf = K / 8;
        return (int)(signed char)((unsigned int)
            a8[((size_t)slot * kf + (k >> 3)) * 64 + r * 8 + (k & 7)] & 0xffu);
    };

    // ---- stage B: quantization gu (input = tin readback; output = a8u/qsxu)
    for (int slot = 0; slot < slots && !fails; ++slot) {
        const int j = gated ? slot / 2 : slot;
        const int m = chunks[j].m;
        const int ts = gated ? slot : slot * 2;             // tin slot written by K1
        for (int t = 0; t < m && !fails; ++t) {
            const float* xr = &tin[((size_t)ts * 4 + t) * H];
            float am = 0.f;
            for (int k = 0; k < H; ++k) am = std::max(am, std::fabs(xr[k]));
            const float qw = am > 0.f ? am * (1.0f / 8192.0f) : 1.0f;
            const float rq = am > 0.f ? 8192.0f / am : 1.0f;
            for (int part = 0; part < 2 && !fails; ++part) {
                const int r = 2 * t + part;
                long sacc = 0;
                for (int k = 0; k < H && !fails; ++k) {
                    const float vf = xr[k] * rq;
                    int v = (int)(vf >= 0.f ? std::floor(vf + 0.5f) : std::ceil(vf - 0.5f));
                    v = std::max(-8128, std::min(8128, v));
                    const int vh = (v + 64) >> 7;
                    const int x8 = part ? (v - (vh << 7)) : vh;
                    sacc += x8;
                    const int32_t want = x8 * 0x01010101;
                    const int kf = H / 8;
                    const int32_t gotw = a8u[((size_t)slot * kf + (k >> 3)) * 64 + r * 8 + (k & 7)];
                    if (gotw != want) {
                        printf("B slot%d tok%d part%d k%d: got %08x want %08x\n",
                               slot, t, part, k, (unsigned)gotw, (unsigned)want);
                        ++fails;
                    }
                }
                const float A = KDQ * (part ? qw : qw * 128.0f);
                const float B = -510.0f * A * (float)sacc;
                const float gA = qsxu[(size_t)slot * 16 + r * 2];
                const float gB = qsxu[(size_t)slot * 16 + r * 2 + 1];
                if (!fails && (!closef(gA, A) || !closef(gB, B))) {
                    printf("B affine slot%d r%d: got {%g,%g} want {%g,%g}\n", slot, r, gA, gB, A, B);
                    ++fails;
                }
            }
        }
    }
    if (fails) { printf("i8trace FAIL at quant-gu\n"); return; }
    printf("stage B quant-gu: OK\n");

    // ---- stage C: gu GEMV (inputs = a8u + weights; output = accgu), sampled columns
    {
        std::vector<int> cols;
        for (int n = 0; n < 48; ++n) cols.push_back(n);
        for (int n = 64; n < I; n += 101) cols.push_back(n);
        const int NC = (int)cols.size();
        std::vector<float> tile(256);
        const int pu = exl3ref::tile_u16(L.bits, L.hb);
        for (int slot = 0; slot < slots && !fails; ++slot) {
            const int j = gated ? slot / 2 : slot;
            const int lmu = gated ? slot % 2 : 0;
            const int e = chunks[j].expert;
            const moe_ref::Matrix& M = (gated && lmu == 0) ? L.gates[e] : L.ups[e];
            const int m = chunks[j].m;
            bool crossed = false;
            std::vector<int> bs((size_t)H * NC);
            {
                const int tiles_n = I / 16, tiles_k = H / 16;
                for (size_t ci = 0; ci < cols.size(); ++ci) {
                    const int n = cols[ci], tn = n >> 4, cn = n & 15;
                    for (int tk = 0; tk < tiles_k; ++tk) {
                        exl3ref::decode_tile(&M.trellis[((size_t)tk * tiles_n + tn) * pu],
                                             L.bits, L.hb, tile.data());
                        for (int rk = 0; rk < 16; ++rk)
                            bs[(size_t)(tk * 16 + rk) * NC + ci] =
                                (int)std::llround(tile[rk * 16 + cn] / KDQ) + 510;
                    }
                }
            }
            std::vector<long> wantv, gotv;
            for (int r = 0; r < 8 && !fails; ++r) {
                const int t = r >> 1;
                if (t >= m) {
                    for (size_t ci = 0; ci < cols.size() && !fails; ++ci) {
                        const int32_t g = accgu[((size_t)slot * 8 + r) * I + cols[ci]];
                        if (g != 0) { printf("C pad slot%d r%d n%d got %d\n", slot, r, cols[ci], g); ++fails; }
                    }
                    continue;
                }
                for (size_t ci = 0; ci < cols.size() && (!fails || wantv.size() < 48); ++ci) {
                    const int n = cols[ci];
                    long acc = 0;
                    for (int k = 0; k < H; ++k)
                        acc += (long)x8row(a8u, slot, r, k, H) * bs[(size_t)k * NC + ci];
                    const int32_t g = accgu[((size_t)slot * 8 + r) * I + n];
                    wantv.push_back(acc); gotv.push_back(g);
                    if (g != (int32_t)acc) ++fails;
                }
            }
            if (fails && !crossed) {
                crossed = true;
                int perm_hits = 0, novel = 0, exact = 0;
                for (size_t i = 0; i < gotv.size(); ++i) {
                    if (gotv[i] == wantv[i]) { ++exact; continue; }
                    bool found = false;
                    for (size_t k2 = 0; k2 < wantv.size(); ++k2)
                        if (gotv[i] == wantv[k2]) { ++perm_hits; found = true; break; }
                    if (!found) ++novel;
                }
                printf("C slot%d cross: exact %d/%zu perm-hits %d novel %d\n",
                       slot, exact, gotv.size(), perm_hits, novel);
                for (size_t i = 0; i < wantv.size(); ++i)
                    printf("CSVA %d %ld %ld\n", cols[i], gotv[i], wantv[i]);
            }
        }
    }
    if (fails) { printf("i8trace FAIL at gemv-gu\n"); return; }
    printf("stage C gemv-gu: OK\n");

    // ---- stage D: K34i8 (accgu+qsxu -> tind), full block 0 of every 128-block, tok r<m
    for (int j = 0; j < nc && !fails; ++j) {
        const int e = chunks[j].expert;
        const int m = chunks[j].m;
        const int slotg = gated ? j * 2 : j;
        const int slotu = gated ? j * 2 + 1 : j;
        const uint16_t* svhu = L.ups[e].svh.data();
        const uint16_t* svhg = gated ? L.gates[e].svh.data() : nullptr;
        const uint16_t* suhd = L.downs[e].suh.data();
        for (int r0 = 0; r0 < m && !fails; ++r0) {
            for (int blk = 0; blk < I / 128 && !fails; ++blk) {
                std::vector<float> gv(128), uv(128);
                float gb = 0.f, ub = 0.f;
                for (int i = 0; i < 128; ++i) {
                    const int c = blk * 128 + i;
                    if (gated) {
                        const float* q0 = &qsxu[((size_t)slotg * 8 + 2 * r0) * 2];
                        const float* q1 = &qsxu[((size_t)slotg * 8 + 2 * r0 + 1) * 2];
                        const int32_t* a0 = &accgu[((size_t)slotg * 8 + 2 * r0) * I];
                        const int32_t* a1 = &accgu[((size_t)slotg * 8 + 2 * r0 + 1) * I];
                        gv[i] = q0[0] * (float)a0[c] + q1[0] * (float)a1[c];
                        gb += q0[1] + q1[1];
                        const float* p0 = &qsxu[((size_t)slotu * 8 + 2 * r0) * 2];
                        const float* p1 = &qsxu[((size_t)slotu * 8 + 2 * r0 + 1) * 2];
                        const int32_t* b0 = &accgu[((size_t)slotu * 8 + 2 * r0) * I];
                        const int32_t* b1 = &accgu[((size_t)slotu * 8 + 2 * r0 + 1) * I];
                        uv[i] = p0[0] * (float)b0[c] + p1[0] * (float)b1[c];
                        ub += p0[1] + p1[1];
                    } else {
                        const float* q0 = &qsxu[((size_t)slotu * 8 + 2 * r0) * 2];
                        const float* q1 = &qsxu[((size_t)slotu * 8 + 2 * r0 + 1) * 2];
                        const int32_t* a0 = &accgu[((size_t)slotu * 8 + 2 * r0) * I];
                        const int32_t* a1 = &accgu[((size_t)slotu * 8 + 2 * r0 + 1) * I];
                        uv[i] = q0[0] * (float)a0[c] + q1[0] * (float)a1[c];
                        ub += q0[1] + q1[1];
                    }
                }
                // kernel order: sh = A*acc; hadamard; sh[0] += 128*B; transform; act; *sd;
                // barrier; hadamard; tind = *HAD_SCALE
                moe_ref::hadamard_128(gv.data());
                moe_ref::hadamard_128(uv.data());
                gv[0] += 128.0f * gb;
                uv[0] += 128.0f * ub;
                for (int i = 0; i < 128; ++i) {
                    const int c = blk * 128 + i;
                    if (gated) {
                        gv[i] = gv[i] * (HS * exl3ref::f16_to_f32(svhg[c]));   // + bias empty
                        uv[i] = uv[i] * (HS * exl3ref::f16_to_f32(svhu[c]));
                    } else {
                        uv[i] = uv[i] * (HS * exl3ref::f16_to_f32(svhu[c]));
                    }
                }
                std::vector<float> hv(128);
                for (int i = 0; i < 128; ++i) {
                    if (gated) {
                        float av;
                        switch (L.activation) {
                            case 0: { const float eg = std::exp(std::min(-gv[i], 80.0f));
                                      av = gv[i] / (1.0f + eg); break; }
                            case 1: { const float cdf = 0.5f * (1.0f + std::erff(gv[i] * 0.70710678f));
                                      av = gv[i] * cdf; break; }
                            case 3: av = (uv[i] + 1.0f) * gv[i] /
                                         (1.0f + std::exp(std::min(-1.702f * gv[i], 80.0f))); break;
                            default: av = gv[i]; break;
                        }
                        hv[i] = av * std::max(-1e30f, std::min(uv[i], 1e30f));
                    } else {
                        const float rv = uv[i] > 0.f ? uv[i] : 0.f;
                        hv[i] = rv * rv;
                    }
                    hv[i] *= exl3ref::f16_to_f32(suhd[blk * 128 + i]);
                }
                moe_ref::hadamard_128(hv.data());
                for (int i = 0; i < 128; ++i) {
                    const float want = hv[i] * HS;
                    const float g = tind[((size_t)j * 4 + r0) * I + blk * 128 + i];
                    if (!closef(g, want)) {
                        printf("D MISMATCH j%d r%d c%d: got %.7g want %.7g\n",
                               j, r0, blk * 128 + i, g, want);
                        ++fails;
                        break;
                    }
                }
            }
        }
    }
    if (fails) { printf("i8trace FAIL at act-tind\n"); return; }
    printf("stage D act-tind: OK\n");

    // ---- stage E: quant down (tind -> a8d/qsxd)
    for (int j = 0; j < nc && !fails; ++j) {
        const int m = chunks[j].m;
        for (int t = 0; t < m && !fails; ++t) {
            const float* xr = &tind[((size_t)j * 4 + t) * I];
            float am = 0.f;
            for (int k = 0; k < I; ++k) am = std::max(am, std::fabs(xr[k]));
            const float qw = am > 0.f ? am * (1.0f / 8192.0f) : 1.0f;
            const float rq = am > 0.f ? 8192.0f / am : 1.0f;
            for (int part = 0; part < 2 && !fails; ++part) {
                const int r = 2 * t + part;
                long sacc = 0;
                for (int k = 0; k < I && !fails; ++k) {
                    const float vf = xr[k] * rq;
                    int v = (int)(vf >= 0.f ? std::floor(vf + 0.5f) : std::ceil(vf - 0.5f));
                    v = std::max(-8128, std::min(8128, v));
                    const int vh = (v + 64) >> 7;
                    const int x8 = part ? (v - (vh << 7)) : vh;
                    sacc += x8;
                    const int32_t want = x8 * 0x01010101;
                    const int kf = I / 8;
                    const int32_t gotw = a8d[((size_t)j * kf + (k >> 3)) * 64 + r * 8 + (k & 7)];
                    if (gotw != want) {
                        printf("E slot%d tok%d part%d k%d: got %08x want %08x\n",
                               j, t, part, k, (unsigned)gotw, (unsigned)want);
                        ++fails;
                    }
                }
                const float A = KDQ * (part ? qw : qw * 128.0f);
                const float B = -510.0f * A * (float)sacc;
                const float gA = qsxd[(size_t)j * 16 + r * 2];
                const float gB = qsxd[(size_t)j * 16 + r * 2 + 1];
                if (!fails && (!closef(gA, A) || !closef(gB, B))) {
                    printf("E affine j%d r%d: got {%g,%g} want {%g,%g}\n", j, r, gA, gB, A, B);
                    ++fails;
                }
            }
        }
    }
    if (fails) { printf("i8trace FAIL at quant-d\n"); return; }
    printf("stage E quant-d: OK\n");

    // ---- stage F: down GEMV (a8d + weights -> accd), sampled columns
    {
        std::vector<int> cols;
        for (int n = 0; n < 48; ++n) cols.push_back(n);
        for (int n = 64; n < H; n += 101) cols.push_back(n);
        const int NC = (int)cols.size();
        std::vector<float> tile(256);
        const int pu = exl3ref::tile_u16(L.bits, L.hb);
        for (int j = 0; j < nc && !fails; ++j) {
            const int e = chunks[j].expert;
            const moe_ref::Matrix& M = L.downs[e];
            const int m = chunks[j].m;
            std::vector<int> bs((size_t)I * NC);
            {
                const int tiles_n = H / 16, tiles_k = I / 16;
                for (size_t ci = 0; ci < cols.size(); ++ci) {
                    const int n = cols[ci], tn = n >> 4, cn = n & 15;
                    for (int tk = 0; tk < tiles_k; ++tk) {
                        exl3ref::decode_tile(&M.trellis[((size_t)tk * tiles_n + tn) * pu],
                                             L.bits, L.hb, tile.data());
                        for (int rk = 0; rk < 16; ++rk)
                            bs[(size_t)(tk * 16 + rk) * NC + ci] =
                                (int)std::llround(tile[rk * 16 + cn] / KDQ) + 510;
                    }
                }
            }
            for (int r = 0; r < 8 && !fails; ++r) {
                const int t = r >> 1;
                if (t >= m) {
                    for (size_t ci = 0; ci < cols.size() && !fails; ++ci) {
                        const int32_t g = accd[((size_t)j * 8 + r) * H + cols[ci]];
                        if (g != 0) { printf("F pad j%d r%d n%d got %d\n", j, r, cols[ci], g); ++fails; }
                    }
                    continue;
                }
                for (size_t ci = 0; ci < cols.size() && !fails; ++ci) {
                    const int n = cols[ci];
                    long acc = 0;
                    for (int k = 0; k < I; ++k)
                        acc += (long)x8row(a8d, j, r, k, I) * bs[(size_t)k * NC + ci];
                    const int32_t g = accd[((size_t)j * 8 + r) * H + n];
                    if (g != (int32_t)acc) {
                        printf("F MISMATCH j%d r%d n%d: got %d want %ld (ratio %.4f)\n",
                               j, r, n, g, acc, (double)g / (double)acc);
                        ++fails;
                    }
                }
            }
        }
    }
    if (fails) { printf("i8trace FAIL at gemv-d\n"); return; }
    printf("stage F gemv-d: OK\n");

    // ---- stage G: gather-out (accd+qsxd+CSR -> out), all columns of block 0 per token
    {
        const int rows = (int)tmap.begin.size() - 1;
        for (int tk = 0; tk < rows && !fails; ++tk) {
            for (int blk = 0; blk < H / 128 && !fails; blk += H / 128) {  // block 0 only
                std::vector<float> sum(128, 0.f);
                for (int p = tmap.begin[tk]; p < tmap.begin[tk + 1]; ++p) {
                    const int ent = tmap.entry[p];
                    const int j = ent >> 2, s = ent & 3;
                    const int e = chunks[j].expert;
                    const float wgt = chunks[j].weight[s];
                    const uint16_t* svhd = L.downs[e].svh.data();
                    std::vector<float> v(128);
                    float bb = 0.f;
                    for (int i = 0; i < 128; ++i) {
                        const int c = blk * 128 + i;
                        const float* q0 = &qsxd[((size_t)j * 8 + 2 * s) * 2];
                        const float* q1 = &qsxd[((size_t)j * 8 + 2 * s + 1) * 2];
                        const int32_t* a0 = &accd[((size_t)j * 8 + 2 * s) * H];
                        const int32_t* a1 = &accd[((size_t)j * 8 + 2 * s + 1) * H];
                        v[i] = q0[0] * (float)a0[c] + q1[0] * (float)a1[c];
                        bb += q0[1] + q1[1];
                    }
                    moe_ref::hadamard_128(v.data());
                    v[0] += 128.0f * bb;
                    for (int i = 0; i < 128; ++i) {
                        const int c = blk * 128 + i;
                        float val = v[i] * (HS * exl3ref::f16_to_f32(svhd[c]));
                        if (!L.downs[e].bias.empty())
                            val += exl3ref::f16_to_f32(L.downs[e].bias[c]);
                        sum[i] += wgt * val;
                    }
                }
                for (int i = 0; i < 128 && !fails; ++i) {
                    const float g = out_host[(size_t)tk * H + blk * 128 + i];
                    if (!closef(g, sum[i])) {
                        printf("G MISMATCH tok%d c%d: got %.7g want %.7g\n", tk, blk * 128 + i, g, sum[i]);
                        ++fails;
                    }
                }
            }
        }
    }
    if (fails) { printf("i8trace FAIL at gather-out\n"); return; }
    printf("stage G gather-out: OK -- PIPELINE FULLY VERIFIED\n");
}

int main(int argc, char** argv)
{
    Args a;
    for (int i = 1; i < argc; ++i) {
        std::string s(argv[i]);
        auto val = [&](void) -> int { return i + 1 < argc ? atoi(argv[++i]) : 0; };
        if (s == "--e") a.E = val();
        else if (s == "--rows") a.rows = val();
        else if (s == "--topk") a.topk = val();
        else if (s == "--bits") a.bits = val();
        else if (s == "--hb") a.hb = val();
        else if (s == "--act") a.act = val();
        else if (s == "--iters") a.iters = val();
        else if (s == "--nocheck") a.check = false;
        else if (s == "--gateless") a.gated = false;
        else if (s == "--v") a.verbose = true;
        else if (s == "--i8trace") a.i8trace = true;
        else if (s == "--load") a.load = argv[++i];
        else { printf("unknown arg %s\n", s.c_str()); return 1; }
    }
    if (!a.gated && a.act != 2) { printf("gateless => act=2 (relu2)\n"); a.act = 2; }

    const int H = 2560, I = 640;
    const int rows = a.rows, topk = std::min(a.topk, a.E);
    sycl::queue q{sycl::gpu_selector_v, {sycl::property::queue::enable_profiling()}};
    printf("Device: %s\n", q.get_device().get_info<sycl::info::device::name>().c_str());

    exl3ref::Rng rng(a.seed);
    const int pu = exl3ref::tile_u16(a.bits, a.hb);

    if (a.load) {
        // ---- load a layer + inputs + CPU reference output produced by xval_cpu.py ----
        const std::string dir(a.load);
        auto kv = [&](void) {};
        std::map<std::string, std::string> meta;
        { std::ifstream mf(dir + "/meta.txt"); std::string k, v; while (mf >> k >> v) meta[k] = v; }
        a.E = std::stoi(meta["E"]); a.rows = std::stoi(meta["rows"]); a.topk = std::stoi(meta["topk"]);
        a.bits = std::stoi(meta["bits"]); a.hb = std::stoi(meta["hb"]); a.act = std::stoi(meta["act"]);
        a.gated = std::stoi(meta["gateless"]) == 0;
        const int E = a.E, rows = a.rows, topk = a.topk, act = a.act;
        const int pu2 = exl3ref::tile_u16(a.bits, a.hb);
        auto load_vec = [&](const std::string& name, size_t count) {
            std::vector<uint16_t> v(count);
            std::ifstream f(dir + "/" + name + ".bin", std::ios::binary);
            if (!f) { printf("missing %s\n", name.c_str()); exit(1); }
            f.read((char*)v.data(), count * 2);
            return v;
        };
        moe_ref::Layer L2;
        L2.hidden = H; L2.interm = I; L2.bits = a.bits; L2.hb = a.hb;
        L2.activation = act; L2.act_limit = 0.f; L2.gated = a.gated;
        std::vector<MatrixSrc> gs(E), us(E), ds(E);
        std::vector<std::vector<uint16_t*> > keepers;
        const int K2load = 2 * a.bits + a.hb;
        auto up16 = [&](const std::vector<uint16_t>& v, bool trellis = false) {
            std::vector<uint32_t> rp;
            const void* datap = v.data();
            if (trellis) {
                rp.resize(v.size() / 2);
                moe_sycl::repack_native_to_stream_words(rp.data(), (const uint32_t*)v.data(),
                                                        v.size() / (2 * 4 * (size_t)K2load), K2load);
                datap = rp.data();
            }
            uint16_t* p = sycl::malloc_device<uint16_t>(v.size(), q);
            keepers.push_back({p});
            q.memcpy(p, datap, v.size() * 2).wait();
            return (const uint16_t*)p;
        };
        for (int e = 0; e < E; ++e) {
            moe_ref::Matrix m;
            auto fill = [&](MatrixSrc& d, const char* pre, int k, int n) {
                auto tr = load_vec(std::string(pre) + "_tr_" + std::to_string(e), (size_t)(k/16)*(n/16)*pu2);
                auto suh = load_vec(std::string(pre) + "_suh_" + std::to_string(e), k);
                auto svh = load_vec(std::string(pre) + "_svh_" + std::to_string(e), n);
                d.trellis = up16(tr, true); d.suh = up16(suh); d.svh = up16(svh); d.bias = nullptr;
                m.trellis = std::move(tr); m.suh = std::move(suh); m.svh = std::move(svh);
            };
            if (a.gated) { fill(gs[e], "gate", H, I); L2.gates.push_back(m); }
            m = moe_ref::Matrix{}; fill(us[e], "up", H, I);
            m.k = H; m.n = I; L2.ups.push_back(m);
            m = moe_ref::Matrix{}; fill(ds[e], "down", I, H);
            m.k = I; m.n = H; L2.downs.push_back(m);
        }
        auto hx2 = load_vec("x", (size_t)rows * H);
        std::vector<int> sel2((size_t)rows * topk);
        { std::ifstream f(dir + "/sel.bin", std::ios::binary); f.read((char*)sel2.data(), sel2.size() * 4); }
        auto wts2 = load_vec("wts", (size_t)rows * topk);
        std::vector<float> ref_out((size_t)rows * H);
        { std::ifstream f(dir + "/out_cpu.bin", std::ios::binary); f.read((char*)ref_out.data(), ref_out.size() * 4); }

        // chunks (expert-asc, MAX_M=4) + CSR, same grouping as the CPU forward
        std::vector<std::vector<std::pair<int, float>>> per_expert(E);
        for (int t = 0; t < rows; ++t)
            for (int j = 0; j < topk; ++j)
                per_expert[sel2[(size_t)t * topk + j]].emplace_back(
                    t, exl3ref::f16_to_f32(wts2[(size_t)t * topk + j]));
        std::vector<ChunkDev> chunks;
        for (int e = 0; e < E; ++e) {
            auto& lst = per_expert[e];
            for (size_t i = 0; i < lst.size(); i += 4) {
                ChunkDev ch{};
                ch.expert = e;
                ch.m = (int)std::min<size_t>(4, lst.size() - i);
                for (int r = 0; r < ch.m; ++r) { ch.token[r] = lst[i + r].first; ch.weight[r] = lst[i + r].second; }
                chunks.push_back(ch);
            }
        }
        TokenMap tmap;
        {
            std::vector<std::vector<int>> tok(rows);
            for (size_t j = 0; j < chunks.size(); ++j)
                for (int r = 0; r < chunks[j].m; ++r)
                    tok[chunks[j].token[r]].push_back((int)j * 4 + r);
            tmap.begin.assign(rows + 1, 0);
            for (int t = 0; t < rows; ++t) {
                tmap.begin[t] = (int)tmap.entry.size();
                for (int x : tok[t]) tmap.entry.push_back(x);
            }
            tmap.begin[rows] = (int)tmap.entry.size();
        }
        LayerParams p2;
        p2.num_experts = E; p2.hidden = H; p2.interm = I; p2.bits = a.bits; p2.hb = a.hb;
        p2.activation = act; p2.act_limit = 0.f; p2.gated = a.gated;
        MoeSyclLayer layer2;
        layer2.init(&q, p2, gs, us, ds);
        uint16_t* dx2 = sycl::malloc_device<uint16_t>(hx2.size(), q);
        float* dout2 = sycl::malloc_device<float>(ref_out.size(), q);
        q.memcpy(dx2, hx2.data(), hx2.size() * 2).wait();
        sycl::event e2 = layer2.forward(chunks.data(), (int)chunks.size(), tmap, dx2, dout2, rows);
        std::vector<float> got(ref_out.size());
        q.memcpy(got.data(), dout2, got.size() * 4, {e2}).wait();
        double se = 0, ss = 0, maxrel = 0; size_t worst = 0;
        for (size_t i = 0; i < got.size(); ++i) {
            const double d = std::fabs((double)ref_out[i] - got[i]);
            se += d * d; ss += (double)ref_out[i] * ref_out[i];
            const double r = d / (std::fabs((double)ref_out[i]) + 1e-12);
            if (r > maxrel && d > 1e-4 * std::sqrt(ss / got.size())) { maxrel = r; worst = i; }
        }
        printf("xval vs CPU: rms_rel %.3e  worst(abs>1e-4*rms) %.3e @%zu (cpu %g gpu %g)  ref_rms %.3e\n",
               std::sqrt(se / std::max(ss, 1e-300)), maxrel, worst, ref_out[worst], got[worst],
               std::sqrt(ss / got.size()));
        // bench GPU forward with this shape
        for (int i = 0; i < 5; ++i) layer2.forward(chunks.data(), (int)chunks.size(), tmap, dx2, dout2, rows);
        q.wait();
        std::vector<float> times;
        for (int i = 0; i < a.iters; ++i) {
            auto t0 = std::chrono::steady_clock::now();
            layer2.forward(chunks.data(), (int)chunks.size(), tmap, dx2, dout2, rows);
            q.wait();
            times.push_back(std::chrono::duration<float, std::micro>(std::chrono::steady_clock::now() - t0).count());
        }
        std::sort(times.begin(), times.end());
        printf("xval bench: median %.1f us (wall incl sync)\n", times[times.size() / 2]);
        return 0;
    }

    // ---------------------------------------------------- synthetic layer weights
    moe_ref::Layer L;
    L.hidden = H; L.interm = I; L.bits = a.bits; L.hb = a.hb;
    L.activation = a.act; L.act_limit = 0.f; L.gated = a.gated;
    auto mk_matrix = [&](int k, int n) {
        moe_ref::Matrix m;
        m.k = k; m.n = n;
        m.trellis.resize((size_t)(k / 16) * (n / 16) * pu);
        for (auto& v : m.trellis) v = (uint16_t)(rng.next() >> 40);
        m.suh.resize(k); m.svh.resize(n);
        for (auto& v : m.suh) v = exl3ref::f32_to_f16(rng.uniform(0.02f, 0.06f));
        for (auto& v : m.svh) v = exl3ref::f32_to_f16(rng.uniform(0.02f, 0.06f));
        return m;
    };
    for (int e = 0; e < a.E; ++e) {
        if (a.gated) L.gates.push_back(mk_matrix(H, I));
        L.ups.push_back(mk_matrix(H, I));
        L.downs.push_back(mk_matrix(I, H));
    }

    // ---------------------------------------------------- inputs
    std::vector<uint16_t> hx((size_t)rows * H);
    for (auto& v : hx) v = exl3ref::f32_to_f16(rng.uniform(-2.f, 2.f));
    std::vector<int> sel((size_t)rows * topk);
    std::vector<uint16_t> wts((size_t)rows * topk);
    for (int t = 0; t < rows; ++t) {
        // distinct experts per token
        std::vector<int> pool(a.E);
        for (int i = 0; i < a.E; ++i) pool[i] = i;
        for (int j = 0; j < topk; ++j) {
            std::swap(pool[j], pool[j + rng.next() % (a.E - j)]);
            sel[(size_t)t * topk + j] = pool[j];
            wts[(size_t)t * topk + j] = exl3ref::f32_to_f16(rng.uniform(0.05f, 1.f));
        }
    }

    // ---------------------------------------------------- chunking (mirrors CPU forward_raw)
    const int MAX_M = 4;
    std::vector<std::vector<std::pair<int, float>>> per_expert(a.E);
    for (int t = 0; t < rows; ++t)
        for (int j = 0; j < topk; ++j)
            per_expert[sel[(size_t)t * topk + j]].emplace_back(
                t, exl3ref::f16_to_f32(wts[(size_t)t * topk + j]));
    std::vector<ChunkDev> chunks;
    std::vector<moe_ref::RefChunk> rchunks;
    for (int e = 0; e < a.E; ++e) {
        auto& lst = per_expert[e];
        for (size_t i = 0; i < lst.size(); i += MAX_M) {
            ChunkDev ch{};
            ch.expert = e;
            ch.m = (int)std::min<size_t>(MAX_M, lst.size() - i);
            for (int r = 0; r < ch.m; ++r) {
                ch.token[r] = lst[i + r].first;
                ch.weight[r] = lst[i + r].second;
            }
            chunks.push_back(ch);
            rchunks.push_back(moe_ref::RefChunk{});
            static_assert(sizeof(ChunkDev) == sizeof(moe_ref::RefChunk), "layout");
            std::memcpy(static_cast<void*>(&rchunks.back()), &ch, sizeof(ch));
        }
    }
    // token CSR
    TokenMap tmap;
    {
        std::vector<std::vector<int>> tok(rows);
        for (size_t j = 0; j < chunks.size(); ++j)
            for (int r = 0; r < chunks[j].m; ++r)
                tok[chunks[j].token[r]].push_back((int)j * 4 + r);
        tmap.begin.assign(rows + 1, 0);
        for (int t = 0; t < rows; ++t) {
            tmap.begin[t] = (int)tmap.entry.size();
            for (int e : tok[t]) tmap.entry.push_back(e);
        }
        tmap.begin[rows] = (int)tmap.entry.size();
    }

    // ---------------------------------------------------- upload weights, run device
    std::vector<std::vector<uint16_t*>> keep(3);
    const int K2cur = 2 * a.bits + a.hb;
    auto upload = [&](std::vector<uint16_t*>& dst, const std::vector<uint16_t>& src, bool trellis = false) {
        std::vector<uint32_t> rp;
        const void* datap = src.data();
        size_t bytes = src.size() * 2;
        if (trellis) {
            rp.resize(src.size() / 2);
            moe_sycl::repack_native_to_stream_words(rp.data(), (const uint32_t*)src.data(),
                                                    src.size() / (2 * 4 * (size_t)K2cur), K2cur);
            datap = rp.data();
        }
        dst.push_back(sycl::malloc_device<uint16_t>(bytes / 2, q));
        q.memcpy(dst.back(), datap, bytes).wait();
        return dst.back();
    };
    std::vector<MatrixSrc> gs(a.E), us(a.E), ds(a.E);
    for (int e = 0; e < a.E; ++e) {
        auto fill = [&](MatrixSrc& d, const moe_ref::Matrix& m) {
            d.trellis = upload(keep[0], m.trellis, true);
            d.suh = upload(keep[1], m.suh);
            d.svh = upload(keep[1], m.svh);
            d.bias = nullptr;
        };
        if (a.gated) fill(gs[e], L.gates[e]);
        fill(us[e], L.ups[e]);
        fill(ds[e], L.downs[e]);
    }

    LayerParams p;
    p.num_experts = a.E; p.hidden = H; p.interm = I; p.bits = a.bits; p.hb = a.hb;
    p.activation = a.act; p.act_limit = 0.f; p.gated = a.gated;
    MoeSyclLayer layer;
    layer.init(&q, p, gs, us, ds);

    uint16_t* dx = sycl::malloc_device<uint16_t>(hx.size(), q);
    float* dout = sycl::malloc_device<float>((size_t)rows * H, q);
    q.memcpy(dx, hx.data(), hx.size() * 2).wait();
    sycl::event e_fw = layer.forward(chunks.data(), (int)chunks.size(), tmap, dx, dout, rows);
    std::vector<float> got((size_t)rows * H);
    q.memcpy(got.data(), dout, got.size() * 4, {e_fw}).wait();
    if (a.i8trace) i8_trace(layer, L, chunks, tmap, got);

    if (a.verbose) {
        for (int wsb = 0; wsb < 5; ++wsb) {
            const size_t cnt = (size_t)chunks.size() * 4 *
                (wsb == 0 ? 2 * H : wsb == 1 ? 2 * I : wsb == 4 ? H : I);
            std::vector<float> probe(cnt);
            q.memcpy(probe.data(), layer.ws(wsb), cnt * 4).wait();
            double s = 0; int nz = 0;
            for (auto v : probe) { s += std::fabs(v); nz += v != 0.f; }
            printf("ws%d: nonzero %d absmean %.4g\n", wsb, nz, s / probe.size());
        }
    }

    // per-stage check: recompute stage 0..4 for chunk 0 row 0 from the reference,
    // and locate the first stage whose device output disagrees.
    if (a.check && a.gated && a.act == 0) {
        const auto& ch = rchunks[0];
        const int j = 0, r = 0;
        const int e = ch.expert;
        std::vector<float> xr(H), tin_r(std::max(H, I)), tg_r(I), tu_r(I), h_r(I), td_r(H);
        const auto rel = [](float a, float b) { return std::fabs(a - b) / (std::fabs(a) + 1e-3); };
        auto cmp = [&](const char* name, std::vector<float>& refv, const float* devbase, size_t off) {
            std::vector<float> dev(refv.size());
            q.memcpy(dev.data(), devbase + off, dev.size() * 4).wait();
            double worst = 0; size_t wi = 0;
            for (size_t i = 0; i < refv.size(); ++i)
                if (rel(refv[i], dev[i]) > worst) { worst = rel(refv[i], dev[i]); wi = i; }
            printf("stage %-8s worst_rel %.2e (ref %.6g dev %.6g @%zu)\n", name, worst,
                   refv[wi], dev[wi], wi);
        };
        for (int i = 0; i < H; ++i) xr[i] = exl3ref::f16_to_f32(hx[(size_t)ch.token[r] * H + i]);
        moe_ref::prep_row(xr.data(), L.gates[e].suh.data(), H, tin_r.data());
        cmp("tin_g", tin_r, layer.ws(0), 0);
        moe_ref::gemv_raw(L, L.gates[e], tin_r.data(), 1, tg_r.data());
        cmp("tout_g", tg_r, layer.ws(1), 0);
        {
            // simulate K2's per-column algorithm for the worst col vs the correct gemv
            const int e0 = rchunks[0].expert;
            const auto& m = L.gates[e0];
            const int tiles_n = I / 16, tiles_k = H / 16;
            const int pu2 = exl3ref::tile_u16(a.bits, a.hb);
            InvPermDump:;
            const int k2 = 2 * a.bits + a.hb, W = 4 * k2;
            unsigned char inv[256];
            for (int t = 0; t < 256; ++t) {
                int b = t >> 3, j = t & 7;
                int row = ((b & 3) * 2) + (j & 1) + ((j & 2) ? 8 : 0);
                int col = (b >> 2) + ((j & 4) ? 8 : 0);
                inv[row * 16 + col] = (unsigned char)t;
            }
            if (getenv("MOE_DUMP382")) {
                const int cG2 = 382;
                const int tnc = cG2 >> 4, cic = cG2 & 15;
                std::vector<float> devst(2560);
                q.memcpy(devst.data(), layer.ws(2), (size_t)2560 * 4).wait();
                int shown = 0;
                for (int tk = 0; tk < tiles_k; ++tk) {
                    const uint16_t* pk = &m.trellis[((size_t)tk * tiles_n + tnc) * pu2];
                    for (int rk = 0; rk < 16; ++rk) {
                        const int t = inv[rk * 16 + cic];
                        const int b1 = (((t + 1) * k2) >> 1) + 128 * k2;
                        const int b0 = b1 - 16;
                        const int w0 = (b0 >> 5) % W, w1 = ((b1 - 1) >> 5) % W;
                        const int sh = (((b1 - 1) >> 5) + 1) * 32 - b1;
                        uint32_t l0, l1; std::memcpy(&l0, pk + w0 * 2, 4); std::memcpy(&l1, pk + w1 * 2, 4);
                        const uint16_t st2 = (uint16_t)((((uint64_t)l0 << 32) | l1) >> sh);
                        if ((int)st2 != (int)devst[tk * 16 + rk] && shown < 8)
                            printf("state diff tk %d rk %d sim %04x dev %04x\n", tk, rk, st2, (int)devst[tk*16+rk]);
                        if ((int)st2 != (int)devst[tk * 16 + rk]) ++shown;
                    }
                }
                printf("dump382: %d state diffs\n", shown);
            }
            if (getenv("MOE_COLPAT")) {
                std::vector<float> devall(I);
                q.memcpy(devall.data(), layer.ws(1), (size_t)I * 4).wait();
                // per column: run same sim, report bad cols grouped by cin
                int badcnt[16] = {};
                for (int cG2 = 0; cG2 < I; ++cG2) {
                    const int tnc = cG2 >> 4, cic = cG2 & 15;
                    double a2 = 0;
                    for (int tk = 0; tk < tiles_k; ++tk) {
                        const uint16_t* pk = &m.trellis[((size_t)tk * tiles_n + tnc) * pu2];
                        for (int rk = 0; rk < 16; ++rk) {
                            const int t = inv[rk * 16 + cic];
                            const int b1 = (((t + 1) * k2) >> 1) + 128 * k2;
                            const int b0 = b1 - 16;
                            const int w0 = (b0 >> 5) % W, w1 = ((b1 - 1) >> 5) % W;
                            const int sh = (((b1 - 1) >> 5) + 1) * 32 - b1;
                            uint32_t l0, l1; std::memcpy(&l0, pk + w0 * 2, 4); std::memcpy(&l1, pk + w1 * 2, 4);
                            const uint16_t st2 = (uint16_t)((((uint64_t)l0 << 32) | l1) >> sh);
                            a2 += (double)tin_r[tk * 16 + rk] * exl3ref::decode_mul1(st2);
                        }
                    }
                    if (std::fabs(a2 - devall[cG2]) > 1e-3 * (std::fabs(a2) + 1)) badcnt[cic]++;
                }
                printf("bad cols per cin:");
                for (int c = 0; c < 16; ++c) printf(" %d", badcnt[c]);
                printf("\n");
            }
            for (int cG : {488, 0, 1}) {
                const int tile_nc = cG >> 4, cin = cG & 15;
                double acc = 0;
                for (int tk = 0; tk < tiles_k; ++tk) {
                    const uint16_t* packed = &m.trellis[((size_t)tk * tiles_n + tile_nc) * pu2];
                    for (int rk = 0; rk < 16; ++rk) {
                        const int t = inv[rk * 16 + cin];
                        const int b1 = (((t + 1) * k2) >> 1) + 128 * k2;
                        const int b0 = b1 - 16;
                        const int w0 = (b0 >> 5) % W, w1 = ((b1 - 1) >> 5) % W;
                        const int sh = (((b1 - 1) >> 5) + 1) * 32 - b1;
                        uint32_t lw0, lw1;
                        std::memcpy(&lw0, packed + w0 * 2, 4);
                        std::memcpy(&lw1, packed + w1 * 2, 4);
                        const uint16_t st = (uint16_t)((((uint64_t)lw0 << 32) | lw1) >> sh);
                        acc += (double)tin_r[tk * 16 + rk] * exl3ref::decode_mul1(st);
                    }
                }
                std::vector<float> dev(I);
                q.memcpy(dev.data(), layer.ws(1) + 0, (size_t)I * 4).wait();
                printf("K2 sim col %d: sim %.6f dev %.6f ref %.6f\n", cG, acc, dev[cG], tg_r[cG]);
                if (cG == 488 && getenv("MOE_K2DBG")) {
                    for (int tk = 0; tk < 1; ++tk) {
                        const uint16_t* packed = &m.trellis[((size_t)tk * tiles_n + tile_nc) * pu2];
                        for (int rk = 0; rk < 4; ++rk) {
                            const int t = inv[rk * 16 + 8]; // cin for col 488 = 8
                            const int b1 = (((t + 1) * k2) >> 1) + 128 * k2;
                            const int b0 = b1 - 16;
                            const int w0 = (b0 >> 5) % W, w1 = ((b1 - 1) >> 5) % W;
                            const int sh = (((b1 - 1) >> 5) + 1) * 32 - b1;
                            uint32_t lw0, lw1; std::memcpy(&lw0, packed + w0 * 2, 4); std::memcpy(&lw1, packed + w1 * 2, 4);
                            printf("SIM tk%d rk%d addr=%06x w0=%08x w1=%08x st=%04x tp=%.8g\n", tk, rk,
                                   (unsigned)(w0 | (w1 << 8) | (sh << 16)), lw0, lw1,
                                   (unsigned)(((((uint64_t)lw0 << 32) | lw1) >> sh)) & 0xffffu, tin_r[tk * 16 + rk]);
                        }
                    }
                }
            }
        }
        for (int i = 0; i < H; ++i) xr[i] = exl3ref::f16_to_f32(hx[(size_t)ch.token[r] * H + i]);
        moe_ref::prep_row(xr.data(), L.ups[e].suh.data(), H, tin_r.data());
        moe_ref::gemv_raw(L, L.ups[e], tin_r.data(), 1, tu_r.data());
        {
            auto trans = [&](std::vector<float>& row, const moe_ref::Matrix& m) {
                for (int block = 0; block < I; block += 128) {
                    moe_ref::hadamard_128(row.data() + block);
                    for (int i = 0; i < 128; ++i)
                        row[block + i] *= exl3ref::HAD_SCALE * exl3ref::f16_to_f32(m.svh[block + i]);
                }
            };
            trans(tg_r, L.gates[e]);
            trans(tu_r, L.ups[e]);
            const float lim = std::numeric_limits<float>::infinity();
            for (int i = 0; i < I; ++i) {
                const float gv = tg_r[i];
                const float av = std::min(gv / (1.0f + std::exp(std::min(-gv, 80.0f))), lim);
                h_r[i] = av * std::clamp(tu_r[i], -lim, lim);
            }
        }
        cmp("h", h_r, layer.ws(2), 0);
        moe_ref::prep_row(h_r.data(), L.downs[e].suh.data(), I, tin_r.data());
        cmp("tind", tin_r, layer.ws(3), 0);
        moe_ref::gemv_raw(L, L.downs[e], tin_r.data(), 1, td_r.data());
        cmp("toutd", td_r, layer.ws(4), 0);
        // final out for token 0 includes all its chunks; full check done separately
    }

    // ---------------------------------------------------- reference + compare
    if (a.check) {
        auto t0 = std::chrono::steady_clock::now();
        std::vector<float> ref(got.size());
        moe_ref::forward(L, rchunks, hx.data(), rows, ref.data());
        auto t1 = std::chrono::steady_clock::now();
        double max_rel = 0, se = 0, ss = 0;
        size_t worst = 0;
        for (size_t i = 0; i < ref.size(); ++i) {
            const double d = std::fabs((double)ref[i] - got[i]);
            const double r = std::fabs((double)ref[i]) + 1e-3;
            if (d / r > max_rel) { max_rel = d / r; worst = i; }
            se += d * d; ss += (double)ref[i] * ref[i];
        }
        printf("check: max_rel %.3e  rms_rel %.3e  (worst idx %zu: ref %f got %f)  ref_ms %.1f\n",
               max_rel, std::sqrt(se / std::max(ss, 1e-30)), worst, ref[worst], got[worst],
               std::chrono::duration<double, std::milli>(t1 - t0).count());
        if (max_rel > 2e-3) { printf("MISMATCH\n"); return 1; }
    }

    // ---------------------------------------------------- bench
    // warmup
    layer.prof = a.verbose;
    for (int i = 0; i < 5; ++i) layer.forward(chunks.data(), (int)chunks.size(), tmap, dx, dout, rows);
    q.wait();
    std::vector<float> times;
    for (int i = 0; i < a.iters; ++i) {
        auto e0 = q.ext_oneapi_submit_barrier();
        layer.forward(chunks.data(), (int)chunks.size(), tmap, dx, dout, rows);
        auto e1 = q.ext_oneapi_submit_barrier();
        e0.wait(); e1.wait();
        times.push_back((float)(e1.get_profiling_info<sycl::info::event_profiling::command_end>() -
                                e0.get_profiling_info<sycl::info::event_profiling::command_end>()) * 1e-3f);
    }
    if (a.verbose) {
        const char* names[6] = {"K1 prep_gu", "K2 gemv_gu", "K34 act+prep_d", "K5 gemv_d", "K6 gather", "-"};
        printf("per-kernel us (last iter; span = kernel start->end, gap = prev end->start):\n");
        auto& evs = layer.events();
        uint64_t prev_end = 0;
        for (size_t kk = 1; kk < evs.size() && kk <= 6; ++kk) {
            uint64_t st = evs[kk].get_profiling_info<sycl::info::event_profiling::command_start>();
            uint64_t en = evs[kk].get_profiling_info<sycl::info::event_profiling::command_end>();
            printf("  %-12s span %8.1f  gap %8.1f\n", names[kk - 1],
                (double)(en - st) * 1e-3, prev_end ? (double)(st - prev_end) * 1e-3 : 0.0);
            prev_end = en;
        }
    }
    std::sort(times.begin(), times.end());
    const float med = times[times.size() / 2];
    // unique experts touched and weight bytes
    std::unordered_set<int> used;
    for (auto& c : chunks) used.insert(c.expert);
    const double per_expert_bytes = ((a.gated ? 2.0 : 1.0) + 1.0) *
        (double)((size_t)(H / 16) * (I / 16) * pu * 2);
    const double bytes = used.size() * per_expert_bytes;
    printf("bench: rows %d topk %d E %d used %zu  median %.1f us  weights %.1f MB => %.1f GB/s\n",
           rows, topk, a.E, used.size(), med, bytes / 1e6, bytes / (med * 1e-6) / 1e9);
    return 0;
}
