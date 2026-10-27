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
    double skew = 0.0;   // >0: zipf(rank^-skew) expert selection (worker-skew repro)
    bool gated = true, check = true, verbose = false, i8trace = false, bare = false;
    int alt = 0;   // --alt N: alternate two x datasets for N forwards, check each (coop visibility stress)
    uint64_t seed = 7;
    const char* load = nullptr;
};

// i8_trace: external, readback-driven stage verifier for the int8/XMX pipeline.
// Each stage is emulated on the host FROM READBACKS of its input buffers and compared
// against the readback of its output buffer. Integer stages bit-exact; float 1e-5 rel.
// Uses only public peek()/i8buf()/ws(); touches no kernel state.
static void i8_trace(MoeSyclLayer& layer, const moe_ref::Layer& L,
                     const std::vector<ChunkDev>& chunks, const TokenMap& tmap,
                     const std::vector<float>& out_host,
                     const std::vector<uint16_t>& hx)
{
    const int H = L.hidden, I = L.interm;
    if (!layer.i8buf(0)) { printf("i8trace: int8 pipeline not present in this build (reset baseline)\n"); return; }
    const bool gated = L.gated;
    const int nm = gated ? 2 : 1;
    const int nc = (int)chunks.size();
    const int slots = nc * nm;
    constexpr float KDQ = 0.00676727294921875f;
    constexpr float HS = 0.088388347648f;   // HAD_SCALE
    printf("== i8trace: nc %d nm %d ==\n", nc, nm);

    // tin is laid out by K1 at ts = (j*2+mu) slots EVEN for gateless (mu=0, ts=2j): the
    // readback must cover all 2*nc ts-slots, not just the 'slots' the quant tier uses.
    std::vector<float> tin((size_t)nc * 2 * MOE_MAXM * H);
    layer.peek(tin.data(), layer.ws(0), tin.size() * 4);
    std::vector<int32_t> a8u((size_t)slots * (H / I8_A8W) * I8_A8BLK);
    layer.peek(a8u.data(), layer.i8buf(0), a8u.size() * 4);
    std::vector<float> qsxu((size_t)slots * I8R * 2);
    layer.peek(qsxu.data(), layer.i8buf(2), qsxu.size() * 4);
    std::vector<int32_t> accgu((size_t)slots * layer.i8nsl(0) * I8R * I);
    layer.peek(accgu.data(), layer.i8buf(4), accgu.size() * 4);
    std::vector<float> tind((size_t)nc * MOE_MAXM * I);
    layer.peek(tind.data(), layer.ws(3), tind.size() * 4);
    std::vector<int32_t> a8d((size_t)nc * (I / I8_A8W) * I8_A8BLK);
    layer.peek(a8d.data(), layer.i8buf(1), a8d.size() * 4);
    std::vector<float> qsxd((size_t)nc * I8R * 2);
    layer.peek(qsxd.data(), layer.i8buf(3), qsxd.size() * 4);
    std::vector<int32_t> accd((size_t)nc * layer.i8nsl(1) * I8R * H);
    layer.peek(accd.data(), layer.i8buf(5), accd.size() * 4);

    // accgu/accd arrive as [slot][nsl][I8R][N] split-K slices; collapse to [slot][I8R][N] with
    // the SAME i32 add semantics the consumers use (values are far from int overflow).
    auto collapse = [](std::vector<int32_t>& a, int nslots, int nsl, int N) {
        if (nsl == 1) return;
        std::vector<int32_t> out((size_t)nslots * I8R * N, 0);
        for (int slot = 0; slot < nslots; ++slot)
            for (int q = 0; q < nsl; ++q)
                for (int r = 0; r < I8R; ++r)
                    for (int n = 0; n < N; ++n)
                        out[((size_t)slot * I8R + r) * N + n] +=
                            a[((size_t)slot * nsl + q) * I8R * N + (size_t)r * N + n];
        a = std::move(out);
    };
    collapse(accgu, slots, layer.i8nsl(0), I);
    collapse(accd, nc, layer.i8nsl(1), H);

    int fails = 0;
    auto closef = [](float a, float b) {
        const double d = std::fabs((double)a - b);
        // abs floor 1e-8: the int8 path legitimately reorders/recontracts fp ops vs this
        // emulation (FMA contraction in the kernel); genuine staging bugs are O(1e-3) here.
        return d <= 1e-5 * std::fabs((double)b) + 1e-8;
    };
    auto x8row = [&](const std::vector<int32_t>& a8, int slot, int r, int k, int K) {
        const int kf = K / 8;
        return (int)(signed char)((unsigned int)
            a8[((size_t)slot * kf + (k >> I8_A8W_SHIFT)) * I8_A8BLK + r * I8_A8W + (k & (I8_A8W - 1))] & 0xffu);
    };

    // ---- stage B: quantization gu (input = tin readback, or host-prepped from x when
    // the fused K1+Q1 kernel ran and tin was never written; output = a8u/qsxu)
    std::vector<float> tin_f((size_t)H), xf((size_t)H);
    for (int slot = 0; slot < slots && !fails; ++slot) {
        const int j = gated ? slot / 2 : slot;
        const int m = chunks[j].m;
        const int ts = gated ? slot : slot * 2;             // tin slot written by K1
        const int e = chunks[j].expert;
        for (int t = 0; t < m && !fails; ++t) {
            const float* xr;
            if (layer.i8fuse()) {
                const int mu = gated ? slot % 2 : 0;
                const moe_ref::Matrix& Mx = gated ? (mu ? L.ups[e] : L.gates[e]) : L.ups[e];
                const int tok = chunks[j].token[t];
                for (int k = 0; k < H; ++k) xf[k] = exl3ref::f16_to_f32(hx[(size_t)tok * H + k]);
                moe_ref::prep_row(xf.data(), Mx.suh.data(), H, tin_f.data());
                xr = tin_f.data();
            } else {
                xr = &tin[((size_t)ts * MOE_MAXM + t) * H];
            }
            float am = 0.f;
            for (int k = 0; k < H; ++k) am = std::max(am, std::fabs(xr[k]));
            const float qw = am > 0.f ? am * (1.0f / 8192.0f) : 1.0f;
            const float rq = am > 0.f ? 8192.0f / am : 1.0f;
            for (int part = 0; part < 2 && !fails; ++part) {
                const int r = i8_row_of(t) + part;                 // token+part -> I8R-row slot row
                long sacc = 0;
                for (int k = 0; k < H && !fails; ++k) {
                    const float vf = xr[k] * rq;
                    int v = (int)(vf >= 0.f ? std::floor(vf + 0.5f) : std::ceil(vf - 0.5f));
                    v = std::max(-8128, std::min(8128, v));
                    const int vh = (v + 64) >> 7;
                    const int x8 = part ? (v - (vh << 7)) : vh;
                    sacc += x8;
                    // uchar splat, mirroring the CPU's store_x8: plain x8*0x01010101 does NOT
                    // replicate NEGATIVE values (-1 -> 0xFEFEFEFF); masking first is required.
                    const int32_t want = (int32_t)((x8 & 0xff) * 0x01010101);
                    const int kf = H / 8;
                    const int32_t gotw = a8u[((size_t)slot * kf + (k >> I8_A8W_SHIFT)) * I8_A8BLK + r * I8_A8W + (k & (I8_A8W - 1))];
                    if (gotw != want) {
                        printf("B slot%d tok%d part%d k%d: got %08x want %08x\n",
                               slot, t, part, k, (unsigned)gotw, (unsigned)want);
                        // forensic: per-row fingerprints of a8 + the tin row it came from
                        for (int rr = 0; rr < I8R; ++rr) {
                            long rs = 0;
                            for (int kk = 0; kk < H; kk += 8)
                                rs += (int)(signed char)((unsigned)a8u[((size_t)slot * (H / I8_A8W) + kk / I8_A8W) * I8_A8BLK + rr * I8_A8W + (kk & (I8_A8W - 1))] & 0xffu);
                            float tsum = 0.f, tam = 0.f;
                            for (int kk = 0; kk < H; ++kk) {
                                tsum += xr[kk];
                                tam = std::max(tam, std::fabs(xr[kk]));
                            }
                            printf("   r%d a8sum=%ld  tinrow(ts%d,t%d) sum=%.6g amax=%.6g\n",
                                   rr, rs, ts, rr >> 1, tsum, tam);
                        }
                        ++fails;
                    }
                }
                const float A = KDQ * (part ? qw : qw * 128.0f);
                const float B = -510.0f * A * (float)sacc;
                const float gA = qsxu[((size_t)slot * I8R + r) * 2];
                const float gB = qsxu[((size_t)slot * I8R + r) * 2 + 1];
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
            for (int r = 0; r < I8R && !fails; ++r) {
                const int t = (r / I8_ROWS_PER_FRAG) * I8_TOK_PER_FRAG + ((r >> 1) % I8_TOK_PER_FRAG);
                if (t >= m) {
                    // slim pass: frag1 (rows 8..15) is neither written nor read - stale
                    if (!layer.i8slim() && r >= I8_ROWS_PER_FRAG) continue;
                    for (size_t ci = 0; ci < cols.size() && !fails; ++ci) {
                        const int32_t g = accgu[((size_t)slot * I8R + r) * I + cols[ci]];
                        if (g != 0) { printf("C pad slot%d r%d n%d got %d\n", slot, r, cols[ci], g); ++fails; }
                    }
                    continue;
                }
                for (size_t ci = 0; ci < cols.size() && (!fails || wantv.size() < 48); ++ci) {
                    const int n = cols[ci];
                    long acc = 0;
                    for (int k = 0; k < H; ++k)
                        acc += (long)x8row(a8u, slot, r, k, H) * bs[(size_t)k * NC + ci];
                    const int32_t g = accgu[((size_t)slot * I8R + r) * I + n];
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
            const int rr = i8_row_of(r0);                   // token -> I8R-row slot rows
            for (int blk = 0; blk < I / 128 && !fails; ++blk) {
                std::vector<float> gv(128), uv(128);
                float gb = 0.f, ub = 0.f;
                for (int i = 0; i < 128; ++i) {
                    const int c = blk * 128 + i;
                    if (gated) {
                        const float* q0 = &qsxu[((size_t)slotg * I8R + rr) * 2];
                        const float* q1 = &qsxu[((size_t)slotg * I8R + rr + 1) * 2];
                        const int32_t* a0 = &accgu[((size_t)slotg * I8R + rr) * I];
                        const int32_t* a1 = &accgu[((size_t)slotg * I8R + rr + 1) * I];
                        gv[i] = q0[0] * (float)a0[c] + q1[0] * (float)a1[c];
                        const float* p0 = &qsxu[((size_t)slotu * I8R + rr) * 2];
                        const float* p1 = &qsxu[((size_t)slotu * I8R + rr + 1) * 2];
                        const int32_t* b0 = &accgu[((size_t)slotu * I8R + rr) * I];
                        const int32_t* b1 = &accgu[((size_t)slotu * I8R + rr + 1) * I];
                        uv[i] = p0[0] * (float)b0[c] + p1[0] * (float)b1[c];
                    } else {
                        const float* q0 = &qsxu[((size_t)slotu * I8R + rr) * 2];
                        const float* q1 = &qsxu[((size_t)slotu * I8R + rr + 1) * 2];
                        const int32_t* a0 = &accgu[((size_t)slotu * I8R + rr) * I];
                        const int32_t* a1 = &accgu[((size_t)slotu * I8R + rr + 1) * I];
                        uv[i] = q0[0] * (float)a0[c] + q1[0] * (float)a1[c];
                    }
                }
                // The kernel folds B as 128.0f*(B0+B1) in ONE multiply; accumulating
                // (B0+B1) 128 times here drifts by ~1e-4 RELATIVE at gb (float add rounding
                // per iteration), which cancellation-amplified columns (|gv| ~ 1e-4) expose
                // as a 4th-digit stage-D mismatch. Fold it the kernel's way.
                if (gated) {
                    const float* q0 = &qsxu[((size_t)slotg * I8R + rr) * 2];
                    const float* q1 = &qsxu[((size_t)slotg * I8R + rr + 1) * 2];
                    const float* p0 = &qsxu[((size_t)slotu * I8R + rr) * 2];
                    const float* p1 = &qsxu[((size_t)slotu * I8R + rr + 1) * 2];
                    gb = 128.0f * (q0[1] + q1[1]);
                    ub = 128.0f * (p0[1] + p1[1]);
                } else {
                    const float* q0 = &qsxu[((size_t)slotu * I8R + rr) * 2];
                    const float* q1 = &qsxu[((size_t)slotu * I8R + rr + 1) * 2];
                    ub = 128.0f * (q0[1] + q1[1]);
                }
                // kernel order: sh = A*acc; hadamard; sh[0] += 128*B; transform; act; *sd;
                // barrier; hadamard; tind = *HAD_SCALE
                moe_ref::hadamard_128(gv.data());
                moe_ref::hadamard_128(uv.data());
                // NOTE: gb/ub ARE 128.0f*(B0+B1) (computed once, the kernel's spelling) =
                // the exact H*(B*ones) fold at element 0; no extra *128 here (the earlier
                // 128x-accumulated version both drifted ~1e-4 rel AND misdocumented the fold).
                gv[0] += gb;
                uv[0] += ub;
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
                        // exact mirror of the kernel's activation block (lim=inf synthetic):
                        // NOTE act3 already contains the uv factor (earlier harness bug
                        // multiplied by uv a second time for swiglu_oai).
                        float av;
                        switch (L.activation) {
                            case 0: { const float eg = std::exp(std::min(-gv[i], 80.0f));
                                      av = gv[i] / (1.0f + eg) * uv[i]; break; }
                            case 1: { const float cdf = 0.5f * (1.0f + std::erff(gv[i] * 0.70710678f));
                                      av = gv[i] * cdf * uv[i]; break; }
                            case 3: av = (uv[i] + 1.0f) * gv[i] /
                                         (1.0f + std::exp(std::min(-1.702f * gv[i], 80.0f))); break;
                            default: av = gv[i]; break;
                        }
                        hv[i] = av;
                    } else {
                        const float rv = uv[i] > 0.f ? uv[i] : 0.f;
                        hv[i] = rv * rv;
                    }
                    hv[i] *= exl3ref::f16_to_f32(suhd[blk * 128 + i]);
                }
                moe_ref::hadamard_128(hv.data());
                for (int i = 0; i < 128; ++i) {
                    const float want = hv[i] * HS;
                    const float g = tind[((size_t)j * MOE_MAXM + r0) * I + blk * 128 + i];
                    if (!closef(g, want)) {
                        printf("D MISMATCH j%d m%d r%d rr%d c%d: got %.7g want %.7g\n",
                               j, m, r0, rr, blk * 128 + i, g, want);
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
            const float* xr = &tind[((size_t)j * MOE_MAXM + t) * I];
            float am = 0.f;
            for (int k = 0; k < I; ++k) am = std::max(am, std::fabs(xr[k]));
            const float qw = am > 0.f ? am * (1.0f / 8192.0f) : 1.0f;
            const float rq = am > 0.f ? 8192.0f / am : 1.0f;
            for (int part = 0; part < 2 && !fails; ++part) {
                const int r = i8_row_of(t) + part;                 // token+part -> I8R-row slot row
                long sacc = 0;
                for (int k = 0; k < I && !fails; ++k) {
                    const float vf = xr[k] * rq;
                    int v = (int)(vf >= 0.f ? std::floor(vf + 0.5f) : std::ceil(vf - 0.5f));
                    v = std::max(-8128, std::min(8128, v));
                    const int vh = (v + 64) >> 7;
                    const int x8 = part ? (v - (vh << 7)) : vh;
                    sacc += x8;
                    const int32_t want = (int32_t)((x8 & 0xff) * 0x01010101);   // uchar splat (stage B note)
                    const int kf = I / 8;
                    const int32_t gotw = a8d[((size_t)j * kf + (k >> I8_A8W_SHIFT)) * I8_A8BLK + r * I8_A8W + (k & (I8_A8W - 1))];
                    if (gotw != want) {
                        printf("E slot%d tok%d part%d k%d: got %08x want %08x\n",
                               j, t, part, k, (unsigned)gotw, (unsigned)want);
                        ++fails;
                    }
                }
                const float A = KDQ * (part ? qw : qw * 128.0f);
                const float B = -510.0f * A * (float)sacc;
                const float gA = qsxd[((size_t)j * I8R + r) * 2];
                const float gB = qsxd[((size_t)j * I8R + r) * 2 + 1];
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
            for (int r = 0; r < I8R && !fails; ++r) {
                const int t = (r / I8_ROWS_PER_FRAG) * I8_TOK_PER_FRAG + ((r >> 1) % I8_TOK_PER_FRAG);
                if (t >= m) {
                    if (!layer.i8slim() && r >= I8_ROWS_PER_FRAG) continue;   // slim: frag1 stale
                    for (size_t ci = 0; ci < cols.size() && !fails; ++ci) {
                        const int32_t g = accd[((size_t)j * I8R + r) * H + cols[ci]];
                        if (g != 0) { printf("F pad j%d r%d n%d got %d\n", j, r, cols[ci], g); ++fails; }
                    }
                    continue;
                }
                for (size_t ci = 0; ci < cols.size() && !fails; ++ci) {
                    const int n = cols[ci];
                    long acc = 0;
                    for (int k = 0; k < I; ++k)
                        acc += (long)x8row(a8d, j, r, k, I) * bs[(size_t)k * NC + ci];
                    const int32_t g = accd[((size_t)j * I8R + r) * H + n];
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
        // G is the float ENDPOINT: per-entry atomic ordering vs this sequential sum differs
        // by a few ulp of the LARGEST intermediate (1e-7-ish absolutes on cancelled sums),
        // so the gate is rel 1e-3 / abs 1e-6. Wiring faults (wrong fold, wrong row/entry)
        // move values by O(1e-3+) at these scales and still cannot hide.
        auto closeg = [](float a, float b) {
            const double d = std::fabs((double)a - b);
            return d <= 1e-3 * std::fabs((double)b) + 1e-6;
        };
        const int rows = (int)tmap.begin.size() - 1;
        for (int tk = 0; tk < rows && !fails; ++tk) {
            for (int blk = 0; blk < H / 128 && !fails; blk += H / 128) {  // block 0 only
                std::vector<float> sum(128, 0.f);
                for (int p = tmap.begin[tk]; p < tmap.begin[tk + 1]; ++p) {
                    const int ent = tmap.entry[p];
                    const int j = ent >> MOE_MAXM_SHIFT, s = ent & (MOE_MAXM - 1);
                    const int e = chunks[j].expert;
                    const float wgt = chunks[j].weight[s];
                    const uint16_t* svhd = L.downs[e].svh.data();
                    std::vector<float> v(128);
                    float bb = 0.f;
                    const int rs = i8_row_of(s);   // token -> I8R-row slot rows
                    for (int i = 0; i < 128; ++i) {
                        const int c = blk * 128 + i;
                        const float* q0 = &qsxd[((size_t)j * I8R + rs) * 2];
                        const float* q1 = &qsxd[((size_t)j * I8R + rs + 1) * 2];
                        const int32_t* a0 = &accd[((size_t)j * I8R + rs) * H];
                        const int32_t* a1 = &accd[((size_t)j * I8R + rs + 1) * H];
                        v[i] = q0[0] * (float)a0[c] + q1[0] * (float)a1[c];
                    }
                    {
                        const float* q0 = &qsxd[((size_t)j * I8R + rs) * 2];
                        const float* q1 = &qsxd[((size_t)j * I8R + rs + 1) * 2];
                        bb = 128.0f * (q0[1] + q1[1]);   // the kernel's one-multiply fold
                    }
                    moe_ref::hadamard_128(v.data());
                    v[0] += bb;   // exact 128*(B0+B1) fold, computed the kernel's way
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
                    if (!closeg(g, sum[i])) {
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
        else if (s == "--skew") a.skew = i + 1 < argc ? atof(argv[++i]) : 0.0;
        else if (s == "--act") a.act = val();
        else if (s == "--iters") a.iters = val();
        else if (s == "--nocheck") a.check = false;
        else if (s == "--bare") a.bare = true;
        else if (s == "--alt") a.alt = val();
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
        auto up16 = [&](const std::vector<uint16_t>& v, bool trellis = false, size_t tiles_k = 0) {
            std::vector<uint32_t> rp;
            const void* datap = v.data();
            if (trellis) {
                rp.resize(v.size() / 2);
                moe_sycl::repack_native_to_stream_words(rp.data(), (const uint32_t*)v.data(),
                                                        v.size() / (2 * 4 * (size_t)K2load), K2load,
                                                        tiles_k);
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
                d.trellis = up16(tr, true, (size_t)k / 16); d.suh = up16(suh); d.svh = up16(svh); d.bias = nullptr;
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

        // chunks + CSR; width cap follows the tier (see int8_pick): int8 8, fp32 4
        const int k2x = 2 * a.bits + a.hb;
        const int mcapx = moe_sycl::int8_mcap_pick(
            moe_sycl::int8_pick(moe_sycl::moe_k2_dpas(k2x), rows),
            rows, rows * topk, E);
        std::vector<std::vector<std::pair<int, float>>> per_expert(E);
        for (int t = 0; t < rows; ++t)
            for (int j = 0; j < topk; ++j)
                if (sel2[(size_t)t * topk + j] >= 0)   // --skew -1: inactive (parent-owned) pick
                    per_expert[sel2[(size_t)t * topk + j]].emplace_back(
                        t, exl3ref::f16_to_f32(wts2[(size_t)t * topk + j]));
        std::vector<ChunkDev> chunks;
        for (int e = 0; e < E; ++e) {
            auto& lst = per_expert[e];
            for (size_t i = 0; i < lst.size(); i += mcapx) {
                ChunkDev ch{};
                ch.expert = e;
                ch.m = (int)std::min<size_t>(mcapx, lst.size() - i);
                for (int r = 0; r < ch.m; ++r) { ch.token[r] = lst[i + r].first; ch.weight[r] = lst[i + r].second; }
                chunks.push_back(ch);
            }
        }
        moe_sycl::moe_bucket_chunks(chunks);   // MUST mirror the plugin chunker (order is in
        TokenMap tmap;                         // the token-map entry encoding)
        {
            std::vector<std::vector<int>> tok(rows);
            for (size_t j = 0; j < chunks.size(); ++j)
                for (int r = 0; r < chunks[j].m; ++r)
                    tok[chunks[j].token[r]].push_back((int)j * moe_sycl::MOE_MAXM + r);
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
    if (a.skew < 0.0)
    {
        // degenerate repro (skew<0, use with --nocheck): all-parent-owned job, exactly
        // what a fully-streamed prefill slice produces for the worker -> empty chunk set
        // in b70_lib forward_impl. Checks whether the chunks.empty() path corrupts
        // (stale dout) or faults.
        for (size_t i = 0; i < sel.size(); ++i) { sel[i] = -1; wts[i] = exl3ref::f32_to_f16(0.5f); }
    }
    else if (a.skew > 0.0)
    {
        // zipf over expert ranks: reproduces the skewed per-expert m distribution an
        // unseeded placement produces (hot experts worker-side). Distinct per token
        // via bounded redraw; a token that stays stuck falls back to uniform draws.
        std::vector<double> cdf(a.E);
        double acc = 0.0;
        for (int i = 0; i < a.E; ++i) acc += 1.0 / std::pow((double)i + 1.0, a.skew);
        double run = 0.0;
        for (int i = 0; i < a.E; ++i) { run += (1.0 / std::pow((double)i + 1.0, a.skew)) / acc; cdf[i] = run; }
        for (int t = 0; t < rows; ++t)
        {
            int j = 0, guard = 0;
            while (j < topk && guard < topk * 64)
            {
                ++guard;
                const double u = (double)rng.next() / 18446744073709551616.0;
                int e = (int)(std::lower_bound(cdf.begin(), cdf.end(), u) - cdf.begin());
                if (e >= a.E) e = a.E - 1;
                bool dup = false;
                for (int k = 0; k < j; ++k) if (sel[(size_t)t * topk + k] == e) { dup = true; break; }
                if (dup) continue;
                sel[(size_t)t * topk + j] = e;
                wts[(size_t)t * topk + j] = exl3ref::f32_to_f16(rng.uniform(0.05f, 1.f));
                ++j;
            }
            if (j < topk)   // pathological: fill rest from a shuffled tail (uniform)
            {
                std::vector<int> pool(a.E);
                for (int i = 0; i < a.E; ++i) pool[i] = i;
                for (int i = j; i < topk; ++i)
                {
                    std::swap(pool[i], pool[i + rng.next() % (a.E - i)]);
                    sel[(size_t)t * topk + i] = pool[i];
                    wts[(size_t)t * topk + i] = exl3ref::f32_to_f16(rng.uniform(0.05f, 1.f));
                }
            }
        }
    }
    else
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
    // width cap must equal what layer.forward() will pick (fp32 tier = 4 accumulator chains)
    const int k2m = 2 * a.bits + a.hb;
    const int MAX_M = moe_sycl::int8_mcap_pick(
        moe_sycl::int8_pick(moe_sycl::moe_k2_dpas(k2m), rows),
        rows, rows * std::min(a.topk, a.E), a.E);
    std::vector<std::vector<std::pair<int, float>>> per_expert(a.E);
    for (int t = 0; t < rows; ++t)
        for (int j = 0; j < topk; ++j)
            if (sel[(size_t)t * topk + j] >= 0)   // --skew -1: inactive (parent-owned) pick
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
        }
    }
    // MUST mirror the plugin chunker: narrow chunks first (moe_bucket_chunks), because the
    // device splits its gemv launches at that boundary AND the token-map entries carry the
    // chunk index. rchunks (host reference) is rebuilt from the bucketed list.
    moe_sycl::moe_bucket_chunks(chunks);
    static_assert(sizeof(ChunkDev) == sizeof(moe_ref::RefChunk), "layout");
    rchunks.clear();
    for (const ChunkDev& ch : chunks) {
        rchunks.push_back(moe_ref::RefChunk{});
        std::memcpy(static_cast<void*>(&rchunks.back()), &ch, sizeof(ch));
    }
    // token CSR
    TokenMap tmap;
    {
        std::vector<std::vector<int>> tok(rows);
        for (size_t j = 0; j < chunks.size(); ++j)
            for (int r = 0; r < chunks[j].m; ++r)
                tok[chunks[j].token[r]].push_back((int)j * moe_sycl::MOE_MAXM + r);
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
    auto upload = [&](std::vector<uint16_t*>& dst, const std::vector<uint16_t>& src, bool trellis = false,
                      size_t tiles_k = 0) {
        std::vector<uint32_t> rp;
        const void* datap = src.data();
        size_t bytes = src.size() * 2;
        if (trellis) {
            rp.resize(src.size() / 2);
            moe_sycl::repack_native_to_stream_words(rp.data(), (const uint32_t*)src.data(),
                                                    src.size() / (2 * 4 * (size_t)K2cur), K2cur,
                                                    tiles_k);
            datap = rp.data();
        }
        dst.push_back(sycl::malloc_device<uint16_t>(bytes / 2, q));
        q.memcpy(dst.back(), datap, bytes).wait();
        return dst.back();
    };
    std::vector<MatrixSrc> gs(a.E), us(a.E), ds(a.E);
    for (int e = 0; e < a.E; ++e) {
        auto fill = [&](MatrixSrc& d, const moe_ref::Matrix& m) {
            d.trellis = upload(keep[0], m.trellis, true,
                               m.k > 0 ? (size_t)m.k / 16
                                       : m.trellis.size() / (8 * (size_t)K2cur) / ((size_t)m.n / 16));
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
    if (a.i8trace) i8_trace(layer, L, chunks, tmap, got, hx);

    if (a.verbose) {
        for (int wsb = 0; wsb < 5; ++wsb) {
            const size_t cnt = (size_t)chunks.size() * 8 *
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
    // (float-tier buffers only: the int8 tier never writes tout/toutd, skip there)
    if (a.check && a.gated && a.act == 0 && !layer.int8_active && !rchunks.empty()) {
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
        if (layer.int8_active) {
            // int8-tier deviation vs the fp32 scalar reference is a ~0.9% class metric;
            // gate on rms (NOT max_rel, which blows up on cancelling outputs).
            const double rms = std::sqrt(se / std::max(ss, 1e-30));
            if (rms > 3e-2) { printf("MISMATCH (int8 rms gate)\n"); return 1; }
        } else if (max_rel > 2e-3) { printf("MISMATCH\n"); return 1; }
    }

    // ---------------------------------------------------- alternating-dataset visibility stress
    // Counter-fed fused kernels read cross-WG data written EARLIER IN THE SAME LAUNCH; a
    // static bench dataset cannot expose a missing stale-L1 bypass (the previous
    // iteration's bytes are the correct bytes). Alternate two different x datasets and
    // verify EVERY output against its own host reference.
    if (a.alt > 0 && a.check) {
        std::vector<uint16_t> hxB(hx.size());
        for (auto& v : hxB) v = exl3ref::f32_to_f16(rng.uniform(-2.f, 2.f));
        uint16_t* dxB = sycl::malloc_device<uint16_t>(hxB.size(), q);
        q.memcpy(dxB, hxB.data(), hxB.size() * 2).wait();
        std::vector<float> refA(got.size()), refB(got.size());
        moe_ref::forward(L, rchunks, hx.data(), rows, refA.data());
        moe_ref::forward(L, rchunks, hxB.data(), rows, refB.data());
        double worst = 0; int bad = 0;
        static const int altdup = []{ const char* e = getenv("MOE_ALTDUP"); return e ? atoi(e) : 1; }();
        // CRITICAL (the queue-ordering bug, archive/platform-pitfalls.md P1, reproduced here):
        // consecutive forwards MUST be chained through forward()'s pre_dep like b70_forward
        // does with g_last_ev. On this stack the
        // implicit in-order ordering between q.memcpy and q.submit is NOT enforced, so an
        // unchained alt loop lets forward N+1's blob H2D (which zero-inits the arrival
        // counters!) race with forward N's still-running kernels. With the GU fusion the
        // counters are consumed at kernel 2 of 4 (vs the last kernel in the split path),
        // turning a narrow historical window into a deterministic failure. Symptom that
        // nails it: `out` byte-identical to the PREVIOUS dataset (epilogue never fired),
        // and every host-syncing probe (extra memset/memcpy in the chain) making it pass.
        sycl::event chain = e_fw;   // continue from the check forward's last event
        for (int i = 0; i < a.alt; ++i) {
            const bool b1 = (i / altdup) & 1;
            sycl::event ef = layer.forward(chunks.data(), (int)chunks.size(), tmap, b1 ? dxB : dx, dout, rows, &chain);
            std::vector<float> g(got.size());
            chain = q.memcpy(g.data(), dout, g.size() * 4, {ef});
            chain.wait();
            if (i <= 3 && a.gated && a.act == 0 && !rchunks.empty() && getenv("EXL3_MOE_STAGEPROBE")) {
                // external stage readback: recompute reference tout (raw gemv) and tind
                // (act+prep_d) for chunk 0 / row 0 and compare against the device ws
                const auto& ch0 = rchunks[0];
                const uint16_t* xcur = b1 ? hxB.data() : hx.data();
                std::vector<float> xr(H), tin_r((size_t)std::max(H, I)), tg_r(I), tu_r(I);
                for (int k = 0; k < H; ++k) xr[k] = exl3ref::f16_to_f32(xcur[(size_t)ch0.token[0] * H + k]);
                moe_ref::prep_row(xr.data(), L.gates[ch0.expert].suh.data(), H, tin_r.data());
                moe_ref::gemv_raw(L, L.gates[ch0.expert], tin_r.data(), 1, tg_r.data());
                moe_ref::prep_row(xr.data(), L.ups[ch0.expert].suh.data(), H, tin_r.data());
                moe_ref::gemv_raw(L, L.ups[ch0.expert], tin_r.data(), 1, tu_r.data());
                // transform + act + prep_d for row 0 (mirrors K34)
                std::vector<float> gtu(I);
                for (int blk = 0; blk < I; blk += 128) {
                    std::vector<float> gh(tg_r.begin() + blk, tg_r.begin() + blk + 128);
                    std::vector<float> uh(tu_r.begin() + blk, tu_r.begin() + blk + 128);
                    moe_ref::hadamard_128(gh.data()); moe_ref::hadamard_128(uh.data());
                    for (int k = 0; k < 128; ++k) {
                        const float gv = gh[k] * exl3ref::HAD_SCALE * exl3ref::f16_to_f32(L.gates[ch0.expert].svh[blk + k]);
                        const float uv = uh[k] * exl3ref::HAD_SCALE * exl3ref::f16_to_f32(L.ups[ch0.expert].svh[blk + k]);
                        uh[k] = (gv / (1.f + std::exp(std::min(-gv, 80.f)))) * uv;
                    }
                    for (int k = 0; k < 128; ++k) gh[k] = uh[k] * exl3ref::f16_to_f32(L.downs[ch0.expert].suh[blk + k]);
                    moe_ref::hadamard_128(gh.data());
                    for (int k = 0; k < 128; ++k) gtu[blk + k] = gh[k] * exl3ref::HAD_SCALE;
                }
                // device sums, mirroring the kernel's slice reduction (ascending qq)
                const int nq = layer.nslgu_dbg;
                std::vector<float> tgsum(I, 0.f), tusum(I, 0.f), devTind(I), tmp(I);
                for (int qq = 0; qq < nq; ++qq) {   // gate slot j=0, mu=0
                    q.memcpy(tmp.data(), layer.ws(1) + (size_t)qq * MOE_MAXM * I, I * 4).wait();
                    for (int k = 0; k < I; ++k) tgsum[k] += tmp[k];
                }
                for (int qq = 0; qq < nq; ++qq) {   // up slot = gemv slot index 1 (j*2+mu, j=0 mu=1)
                    q.memcpy(tmp.data(), layer.ws(1) + (size_t)(nq + qq) * MOE_MAXM * I, I * 4).wait();
                    for (int k = 0; k < I; ++k) tusum[k] += tmp[k];
                }
                q.memcpy(devTind.data(), layer.ws(3), I * 4).wait();
                // ALL-chunks tind sweep: compare device tind[j][0] against a full host
                // recompute per chunk (row 0 only; decode shapes have m=1 per chunk here)
                int tbad = 0; size_t tj = 0; int tk0 = 0; double tworstj = 0;
                for (size_t j = 0; j < rchunks.size(); ++j) {
                    const auto& ch = rchunks[j];
                    if (ch.m < 1) continue;
                    for (int k = 0; k < H; ++k) xr[k] = exl3ref::f16_to_f32(xcur[(size_t)ch.token[0] * H + k]);
                    std::vector<float> tgv(I), tuv(I), hgv(I);
                    if (a.gated) {
                        moe_ref::prep_row(xr.data(), L.gates[ch.expert].suh.data(), H, tin_r.data());
                        moe_ref::gemv_raw(L, L.gates[ch.expert], tin_r.data(), 1, tgv.data());
                    }
                    moe_ref::prep_row(xr.data(), L.ups[ch.expert].suh.data(), H, tin_r.data());
                    moe_ref::gemv_raw(L, L.ups[ch.expert], tin_r.data(), 1, tuv.data());
                    if (!a.gated) tgv = tuv;
                    for (int blk = 0; blk < I; blk += 128) {
                        std::vector<float> gh(tgv.begin() + blk, tgv.begin() + blk + 128);
                        std::vector<float> uh(tuv.begin() + blk, tuv.begin() + blk + 128);
                        moe_ref::hadamard_128(gh.data()); moe_ref::hadamard_128(uh.data());
                        for (int k = 0; k < 128; ++k) {
                            const float gv = gh[k] * exl3ref::HAD_SCALE * exl3ref::f16_to_f32(L.gates[ch.expert].svh[blk + k]);
                            const float uv = uh[k] * exl3ref::HAD_SCALE * exl3ref::f16_to_f32(L.ups[ch.expert].svh[blk + k]);
                            uh[k] = (gv / (1.f + std::exp(std::min(-gv, 80.f)))) * uv;
                        }
                        for (int k = 0; k < 128; ++k) gh[k] = uh[k] * exl3ref::f16_to_f32(L.downs[ch.expert].suh[blk + k]);
                        moe_ref::hadamard_128(gh.data());
                        for (int k = 0; k < 128; ++k) hgv[blk + k] = gh[k] * exl3ref::HAD_SCALE;
                    }
                    std::vector<float> devj(I);
                    q.memcpy(devj.data(), layer.ws(3) + j * 8 * (size_t)I, I * 4).wait();
                    for (int k = 0; k < I; ++k) {
                        const double dd = std::fabs(hgv[k] - devj[k]) / (std::fabs(hgv[k]) + 1e-3);
                        if (dd > 2e-3) { if (!tbad) { tj = j; tk0 = k; tworstj = dd; } ++tbad; }
                        else if (tbad == 1 && dd > tworstj) { tj = j; tk0 = k; tworstj = dd; }
                    }
                }
                std::printf("tind-allchunks: bad_values %d (first j %zu col %d rel %.3e)\n", tbad, tj, tk0, tworstj);
                double wg2 = 0, wu = 0, wd = 0, gi2 = 0, ui2 = 0, wdd = 0;
                for (int k = 0; k < I; ++k) {
                    const double dg = std::fabs(tg_r[k] - tgsum[k]) / (std::fabs(tg_r[k]) + 1e-3);
                    const double du = std::fabs(tu_r[k] - tusum[k]) / (std::fabs(tu_r[k]) + 1e-3);
                    const double dd = std::fabs(gtu[k] - devTind[k]) / (std::fabs(gtu[k]) + 1e-3);
                    if (dg > wg2) { wg2 = dg; gi2 = k; }
                    if (du > wu) { wu = du; ui2 = k; }
                    if (dd > wd) { wd = dd; wdd = k; }
                }
                std::printf("stageprobe i%d: tout_g rel %.3e @%d (ref %.5f dev %.5f) | tout_u rel %.3e @%d | tind rel %.3e @%d (ref %.5f dev %.5f)\n",
                            i, wg2, (int)gi2, tg_r[(int)gi2], tgsum[(int)gi2], wu, (int)ui2, wd, (int)wdd, gtu[(int)wdd], devTind[(int)wdd]);
            }
            if (i == 1 && getenv("EXL3_MOE_B70_CTRDBG")) {
                int dbgv[2];
                layer.read_dbg(dbgv);
                std::printf("epilogue fires: gu %d (want %d)  d-l2 %d (want %d)\n",
                            dbgv[0], (int)chunks.size() * (I / 128), dbgv[1], rows * (H / 128));
            }
            if (i == 1 && getenv("EXL3_MOE_B70_CTRDBG")) {
                const size_t nb = layer.ctr_bytes_dbg;
                if (nb) {
                    std::vector<int> c(nb / 4);
                    layer.peek(c.data(), (const char*)layer.blob() + layer.ctr_offset(), nb);
                    int hist[24] = {};
                    for (int v : c) hist[v < 24 ? v : 23]++;
                    printf("ctr hist: ");
                    for (int k = 0; k < 24; ++k) if (hist[k]) printf("%d:%d ", k, hist[k]);
                    printf("(cells %zu)\n", c.size());
                }
            }
            const std::vector<float>& ref = b1 ? refB : refA;
            if (i == 1 && getenv("EXL3_MOE_STAGEPROBE")) {
                for (int k = 0; k < 6; ++k)
                    std::printf("out[%d] ref %.6f got %.6f\n", k, ref[k], g[k]);
                // is got perhaps the OTHER dataset's out? (stale-from-prev-forward test)
                const std::vector<float>& other = b1 ? refA : refB;
                int match_other = 0;
                for (size_t k = 0; k < g.size(); ++k)
                    if (std::fabs(other[k] - g[k]) < 1e-3 * (std::fabs(other[k]) + 1e-3)) ++match_other;
                std::printf("got matches OTHER dataset in %d / %zu columns\n", match_other, g.size());
            }
            for (size_t k = 0; k < g.size(); ++k) {
                const double d = std::fabs((double)ref[k] - g[k]);
                const double r = d / (std::fabs((double)ref[k]) + 1e-3);
                // staleness detector, not a precision gate: float tier uses 2e-3 rel; the
                // int8 tier legitimately deviates ~1.3e-3 rms / ~1e-2 rel on cancelling
                // columns (documented band) - stale outputs are O(1) wrong and still trip
                // this. The precision gate proper is the check/MISMATCH block above.
                if (r > (layer.int8_active ? 5e-2 : 2e-3)) ++bad;
                if (r > worst) worst = r;
            }
        }
        printf("alt-stress: iters %d worst_rel %.3e bad %d\n", a.alt, worst, bad);
        sycl::free(dxB, q);
        if (bad) { printf("ALT MISMATCH\n"); return 1; }
    }

    // ---------------------------------------------------- bench
    // warmup
    layer.prof = a.verbose;
    for (int i = 0; i < 5; ++i) layer.forward(chunks.data(), (int)chunks.size(), tmap, dx, dout, rows);
    q.wait();
    std::vector<float> times;
    for (int i = 0; i < a.iters; ++i) {
        auto e0 = q.ext_oneapi_submit_barrier();
        if (!a.bare) layer.forward(chunks.data(), (int)chunks.size(), tmap, dx, dout, rows);
        auto e1 = q.ext_oneapi_submit_barrier();
        e0.wait(); e1.wait();
        times.push_back((float)(e1.get_profiling_info<sycl::info::event_profiling::command_end>() -
                                e0.get_profiling_info<sycl::info::event_profiling::command_end>()) * 1e-3f);
    }
    if (a.verbose) {
        const char* names[6] = {"K1 prep_gu", "K2 gemv_gu", "K34 act+prep_d", "K5 gemv_d", "K6 gather", "-"};
        const char* namc[6] = {"K1 prep_gu", "K2 gemv_gu", "K34 act+prep_d", "K56 coop-dn", "-", "-"};
        const char* n8u[8] = {"K1 prep_gu", "Q1 quant_u", "G2 gemv8_gu", "K34i8 act", "Q2 quant_d",
                              "G5 gemv8_d", "memset out", "K6i8 gather"};
        const char* n8f[7] = {"Q1f p+quant", "G2 gemv8_gu", "K34i8 act", "Q2 quant_d",
                              "G5 gemv8_d", "K6i8 gather", "-"};   // K1 fused into Q1
        printf("per-kernel us (last iter; span = kernel start->end, gap = prev end->start):\n");
        auto& evs = layer.events();
        uint64_t prev_end = 0;
        const bool f8 = layer.int8_active, fused = layer.i8fuse() != 0;
        const bool fc = !f8 && layer.coop_active() != 0;
        const size_t kev = f8 ? (fused ? 7u : 8u) : (fc ? 4u : 6u);
        for (size_t kk = 1; kk < evs.size() && kk <= kev; ++kk) {
            uint64_t st = evs[kk].get_profiling_info<sycl::info::event_profiling::command_start>();
            uint64_t en = evs[kk].get_profiling_info<sycl::info::event_profiling::command_end>();
            printf("  %-12s span %8.1f  gap %8.1f\n", f8 ? (fused ? n8f[kk - 1] : n8u[kk - 1]) : (fc ? namc[kk - 1] : names[kk - 1]),
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
