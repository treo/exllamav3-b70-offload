// Shared reference definitions for the SYCL MoE port: the mul1 dequant math and tile
// extraction rules, mirroring the scalar path of exllamav3/exllamav3_ext/cpu/moe_mul1.cpp
// (which is the authoritative spec). Header-only, no torch, usable from host code in the
// microbench harnesses.
#pragma once

#include <cstdint>
#include <cstring>
#include <array>

namespace exl3ref {

constexpr uint32_t MUL1_MULT = 0x83DCD12Du;
constexpr float HAD_SCALE = 0.088388347648f;

inline float f16_to_f32(uint16_t h)
{
    _Float16 f;
    std::memcpy(&f, &h, 2);
    return static_cast<float>(f);
}

inline uint16_t f32_to_f16(float x)
{
    _Float16 f = static_cast<_Float16>(x);
    uint16_t h;
    std::memcpy(&h, &f, 2);
    return h;
}

// fp16 0x1eee as float (mul1 k_inv)
inline float k_inv()
{
    static const float v = f16_to_f32(0x1eeeu);
    return v;
}

inline int rate_k2(int bits, int hb) { return 2 * bits + hb; }
inline int tile_u16(int bits, int hb) { return 8 * rate_k2(bits, hb); }
inline int tile_words32(int bits, int hb) { return 4 * rate_k2(bits, hb); }

// End of state t's 16-bit window in the tile's bit ring
inline int state_end(int bits, int hb, int t)
{
    return (((t + 1) * rate_k2(bits, hb)) >> 1) + 128 * rate_k2(bits, hb);
}

inline uint32_t load_u32(const uint16_t* ptr, int word)
{
    uint32_t v;
    std::memcpy(&v, ptr + word * 2, sizeof(v));
    return v;
}

inline uint16_t decode_state(const uint16_t* packed, int bits, int hb, int t)
{
    const int W = tile_words32(bits, hb);
    const int b1 = state_end(bits, hb, t);
    const int b0 = b1 - 16;
    const int shift = ((b1 - 1) / 32 + 1) * 32 - b1;
    const uint64_t merged = (static_cast<uint64_t>(load_u32(packed, (b0 / 32) % W)) << 32) |
                            load_u32(packed, ((b1 - 1) / 32) % W);
    return static_cast<uint16_t>(merged >> shift);
}

inline float decode_mul1(uint16_t state)
{
    const uint32_t x = static_cast<uint32_t>(state) * MUL1_MULT;
    const int sum = (x & 0xff) + ((x >> 8) & 0xff) + ((x >> 16) & 0xff) + (x >> 24);
    return (static_cast<float>(sum) - 510.0f) * k_inv();
}

// Tile weight-index permutation (tensor-core order baked into the storage format)
inline const std::array<uint16_t, 256>& tc_perm()
{
    static const std::array<uint16_t, 256> p = [] {
        std::array<uint16_t, 256> q{};
        for (int t = 0; t < 32; ++t) {
            const int r0 = (t % 4) * 2, r1 = r0 + 1, r2 = r0 + 8, r3 = r0 + 9;
            const int c0 = t / 4, c1 = c0 + 8;
            q[t * 8 + 0] = static_cast<uint16_t>(r0 * 16 + c0); q[t * 8 + 1] = static_cast<uint16_t>(r1 * 16 + c0);
            q[t * 8 + 2] = static_cast<uint16_t>(r2 * 16 + c0); q[t * 8 + 3] = static_cast<uint16_t>(r3 * 16 + c0);
            q[t * 8 + 4] = static_cast<uint16_t>(r0 * 16 + c1); q[t * 8 + 5] = static_cast<uint16_t>(r1 * 16 + c1);
            q[t * 8 + 6] = static_cast<uint16_t>(r2 * 16 + c1); q[t * 8 + 7] = static_cast<uint16_t>(r3 * 16 + c1);
        }
        return q;
    }();
    return p;
}

// Decode a whole 16x16 tile into weights in (r-major) order: tile[r * 16 + c]
inline void decode_tile(const uint16_t* packed, int bits, int hb, float* tile)
{
    const auto& perm = tc_perm();
    for (int t = 0; t < 256; ++t)
        tile[perm[t]] = decode_mul1(decode_state(packed, bits, hb, t));
}

// Seeded xorshift for identical synthetic data on any host
struct Rng
{
    uint64_t s;
    explicit Rng(uint64_t seed) : s(seed ? seed : 1) {}
    uint64_t next()
    {
        s ^= s << 13; s ^= s >> 7; s ^= s << 17;
        return s;
    }
    float uniform(float lo, float hi)
    {
        const uint32_t u = static_cast<uint32_t>(next() >> 32);
        return lo + (hi - lo) * (u / 4294967296.0f);
    }
};

} // namespace exl3ref