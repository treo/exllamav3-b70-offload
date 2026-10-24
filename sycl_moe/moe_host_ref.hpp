// Host fp32 reference for the SYCL MoE layer forward, transcribing the scalar-tier semantics
// of exllamav3/exllamav3_ext/cpu/moe_mul1.cpp. Used to validate the device kernels.
#pragma once

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <limits>
#include <vector>
#include "exl3_ref.h"

namespace moe_ref {

struct Matrix
{
    std::vector<uint16_t> trellis;   // [k/16, n/16, tile_u16] native order
    std::vector<uint16_t> suh, svh, bias;   // bias may be empty
    int k = 0, n = 0;
};

struct Layer
{
    std::vector<Matrix> gates, ups, downs;   // per expert
    int hidden = 0, interm = 0;
    int bits = 2, hb = 0;
    int activation = 0;
    float act_limit = 0.f;
    bool gated = true;
};

struct RefChunk
{
    int expert;
    int m;
    int token[4];
    float weight[4];
};

inline void hadamard_128(float* v)
{
    for (int width = 1; width < 128; width *= 2)
        for (int base = 0; base < 128; base += 2 * width)
            for (int i = 0; i < width; ++i) {
                const float a = v[base + i];
                const float b = v[base + width + i];
                v[base + i] = a + b;
                v[base + width + i] = a - b;
            }
}

inline void prep_row(const float* src, const uint16_t* suh, int k, float* dst)
{
    for (int block = 0; block < k; block += 128) {
        float vals[128];
        for (int i = 0; i < 128; ++i)
            vals[i] = src[block + i] * exl3ref::f16_to_f32(suh[block + i]);
        hadamard_128(vals);
        for (int i = 0; i < 128; ++i) dst[block + i] = vals[i] * exl3ref::HAD_SCALE;
    }
}

// tout[r][n] = raw gemv (no transform)
inline void gemv_raw(const Layer& L, const Matrix& m, const float* tin, int rows, float* tout)
{
    const int k = m.k, n = m.n;
    const int tiles_k = k / 16, tiles_n = n / 16;
    const int pu = exl3ref::tile_u16(L.bits, L.hb);
    for (int tn = 0; tn < tiles_n; ++tn) {
        float acc[4][16] = {};
        for (int tk = 0; tk < tiles_k; ++tk) {
            float tile[256];
            exl3ref::decode_tile(&m.trellis[((size_t)tk * tiles_n + tn) * pu], L.bits, L.hb, tile);
            for (int r = 0; r < rows; ++r) {
                const float* x = tin + (size_t)r * k + tk * 16;
                for (int rk = 0; rk < 16; ++rk)
                    for (int c = 0; c < 16; ++c)
                        acc[r][c] += x[rk] * tile[rk * 16 + c];
            }
        }
        for (int r = 0; r < rows; ++r)
            std::memcpy(tout + (size_t)r * n + tn * 16, acc[r], 16 * sizeof(float));
    }
}

// tout[r][n] = transform(gemv(matrix, tin))
inline void gemv_transform(const Layer& L, const Matrix& m, const float* tin, int rows, float* tout)
{
    gemv_raw(L, m, tin, rows, tout);
    const int n = m.n;
    for (int r = 0; r < rows; ++r) {
        float* row = tout + (size_t)r * n;
        for (int block = 0; block < n; block += 128) {
            hadamard_128(row + block);
            for (int i = 0; i < 128; ++i) {
                float v = row[block + i] * exl3ref::HAD_SCALE
                          * exl3ref::f16_to_f32(m.svh[block + i]);
                if (!m.bias.empty()) v += exl3ref::f16_to_f32(m.bias[block + i]);
                row[block + i] = v;
            }
        }
    }
}

inline void apply_activation(const Layer& L, float* g, float* u, size_t count)
{
    const float lim = L.act_limit != 0.0f ? L.act_limit : std::numeric_limits<float>::infinity();
    const float exp_max = 80.0f;
    switch (L.activation) {
        case 0:
            for (size_t i = 0; i < count; ++i) {
                const float gv = g[i];
                const float av = std::min(gv / (1.0f + std::exp(std::min(-gv, exp_max))), lim);
                g[i] = av * std::clamp(u[i], -lim, lim);
            }
            break;
        case 1:
            for (size_t i = 0; i < count; ++i) {
                const float gv = g[i];
                const float cdf = 0.5f * (1.0f + std::erf(gv * 0.70710678f));
                const float av = std::min(gv * cdf, lim);
                g[i] = av * std::clamp(u[i], -lim, lim);
            }
            break;
        case 3:
            for (size_t i = 0; i < count; ++i) {
                const float gv = std::min(g[i], lim);
                const float uv = std::clamp(u[i], -lim, lim);
                g[i] = (uv + 1.0f) * gv / (1.0f + std::exp(std::min(-1.702f * gv, exp_max)));
            }
            break;
        default:
            for (size_t i = 0; i < count; ++i) {
                const float uv = u[i] > 0.0f ? u[i] : 0.0f;
                u[i] = uv * uv;
            }
            break;
    }
}

// x: rows x hidden fp16 bits; out: rows x hidden fp32 (zeroed inside)
inline void forward(const Layer& L, const std::vector<RefChunk>& chunks,
                    const uint16_t* x, int rows, float* out)
{
    const int H = L.hidden, I = L.interm;
    std::memset(out, 0, (size_t)rows * H * sizeof(float));
    std::vector<float> tin(std::max(H, I) * 4), tg(I * 4), tu(I * 4), td(H * 4), hd(I * 4);
    std::vector<float> xr(H);
    for (const auto& ch : chunks) {
        const Matrix& up = L.ups[ch.expert];
        const Matrix& gate = L.gated ? L.gates[ch.expert] : up;
        const Matrix& down = L.downs[ch.expert];
        // prepped inputs (gate and up differ only by suh, so prep per matrix)
        if (L.gated) {
            for (int r = 0; r < ch.m; ++r) {
                for (int i = 0; i < H; ++i) xr[i] = exl3ref::f16_to_f32(x[(size_t)ch.token[r] * H + i]);
                prep_row(xr.data(), gate.suh.data(), H, tin.data() + (size_t)r * H);
            }
            gemv_transform(L, gate, tin.data(), ch.m, tg.data());
            for (int r = 0; r < ch.m; ++r) {
                for (int i = 0; i < H; ++i) xr[i] = exl3ref::f16_to_f32(x[(size_t)ch.token[r] * H + i]);
                prep_row(xr.data(), up.suh.data(), H, tin.data() + (size_t)r * H);
            }
            gemv_transform(L, up, tin.data(), ch.m, tu.data());
            apply_activation(L, tg.data(), tu.data(), (size_t)ch.m * I);
            // activation result lives in g == tg
            for (int r = 0; r < ch.m; ++r)
                prep_row(tg.data() + (size_t)r * I, down.suh.data(), I, hd.data() + (size_t)r * I);
        } else {
            for (int r = 0; r < ch.m; ++r) {
                for (int i = 0; i < H; ++i) xr[i] = exl3ref::f16_to_f32(x[(size_t)ch.token[r] * H + i]);
                prep_row(xr.data(), up.suh.data(), H, tin.data() + (size_t)r * H);
            }
            gemv_transform(L, up, tin.data(), ch.m, tu.data());
            for (int i = 0; i < ch.m * I; ++i) {
                const float uv = tu[i] > 0.0f ? tu[i] : 0.0f;
                tu[i] = uv * uv;
            }
            for (int r = 0; r < ch.m; ++r)
                prep_row(tu.data() + (size_t)r * I, down.suh.data(), I, hd.data() + (size_t)r * I);
        }
        gemv_transform(L, down, hd.data(), ch.m, td.data());
        for (int r = 0; r < ch.m; ++r) {
            float* dst = out + (size_t)ch.token[r] * H;
            const float w = ch.weight[r];
            const float* src = td.data() + (size_t)r * H;
            for (int i = 0; i < H; ++i) dst[i] += w * src[i];
        }
    }
}

} // namespace moe_ref