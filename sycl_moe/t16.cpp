// staging variants: subgroup-local shared staging with cheap barriers
#include <sycl/sycl.hpp>
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <vector>
#include <algorithm>
int main() {
    sycl::queue q{sycl::gpu_selector_v, {sycl::property::queue::enable_profiling()}};
    const int NG = getenv("TNG") ? atoi(getenv("TNG")) : 100;                 // work groups
    const int TK = 160;                 // k steps
    const int TILES_PER_WG = 8;         // 16-lane subgroups, one tile each
    const int WORDS = 16;               // u32 words per tile (K2=4)
    const size_t total_w = (size_t)NG * TILES_PER_WG * WORDS * TK;
    uint32_t* buf = sycl::malloc_device<uint32_t>(total_w, q);
    float* out = sycl::malloc_device<float>(NG * TILES_PER_WG * 16, q);
    q.memset(buf, 0x5a, total_w * 4).wait();
    for (int variant = 0; variant < 5; ++variant) {
        double best = 1e30;
        for (int rep = 0; rep < 10; ++rep) {
            sycl::event e = q.submit([&](sycl::handler& cgh) {
                sycl::local_accessor<uint32_t, 1> st({(size_t)TILES_PER_WG * WORDS}, cgh);
                cgh.parallel_for(sycl::nd_range<1>({(size_t)NG * 128}, {128}), [=](sycl::nd_item<1> it) {
                    const int g = (int)it.get_group(0), tid = (int)it.get_local_id(0);
                    const int sg_lane = (int)it.get_sub_group().get_local_linear_id();
                    const int sg_id = (int)tid >> 4;                       // 0..7
                    // extraction plan (fake but realistic): each lane reads 2 words per tile
                    const int k2 = 4;
                    int w0[16], w1[16], sh[16];
#pragma unroll
                    for (int rk = 0; rk < 16; ++rk) {
                        const int col = sg_lane;   // lane = column within tile
                        const int bb = ((col & 7) << 2) | ((rk >> 1) & 3);
                        const int jj = (rk & 1) | ((rk & 8) ? 2 : 0) | ((col & 8) ? 4 : 0);
                        const int t = (bb << 3) | jj;
                        const int b1 = (((t + 1) * k2) >> 1) + 128 * k2;
                        const int b0 = b1 - 16;
                        w0[rk] = (b0 >> 5) % 16; w1[rk] = ((b1 - 1) >> 5) % 16;
                        sh[rk] = ((((b1 - 1) >> 5) + 1) * 32) - b1;
                    }
                    const uint32_t* p = buf + (size_t)g * TILES_PER_WG * WORDS * TK;
                    float acc = 0;
                    if (variant == 0) {           // direct global (divergent gather)
                        for (int tk = 0; tk < TK; ++tk) {
                            const uint32_t* wp = p + (size_t)tk * TILES_PER_WG * WORDS + sg_id * WORDS;
#pragma unroll
                            for (int rk = 0; rk < 16; ++rk) {
                                uint64_t merged = ((uint64_t)wp[w0[rk]] << 32) | wp[w1[rk]];
                                acc += (float)((merged >> sh[rk]) & 0xffff);
                            }
                        }
                    } else if (variant == 1) {    // WG barrier staging
                        for (int tk = 0; tk < TK; ++tk) {
                            const uint32_t* wp = p + (size_t)tk * TILES_PER_WG * WORDS;
                            st[tid] = wp[tid];
                            sycl::group_barrier(it.get_group());
                            const uint32_t* sp = st.get_pointer() + sg_id * WORDS;
#pragma unroll
                            for (int rk = 0; rk < 16; ++rk) {
                                uint64_t merged = ((uint64_t)sp[w0[rk]] << 32) | sp[w1[rk]];
                                acc += (float)((merged >> sh[rk]) & 0xffff);
                            }
                            sycl::group_barrier(it.get_group());
                        }
                    } else {                      // subgroup barrier staging
                        for (int tk = 0; tk < TK; ++tk) {
                            const uint32_t* wp = p + (size_t)tk * TILES_PER_WG * WORDS + sg_id * WORDS;
                            st[sg_id * WORDS + sg_lane] = wp[sg_lane];
                            it.get_sub_group().barrier();
                            const uint32_t* sp = st.get_pointer() + sg_id * WORDS;
#pragma unroll
                            for (int rk = 0; rk < 16; ++rk) {
                                uint64_t merged = ((uint64_t)sp[w0[rk]] << 32) | sp[w1[rk]];
                                acc += (float)((merged >> sh[rk]) & 0xffff);
                            }
                            it.get_sub_group().barrier();
                        }
                    }
                    if (variant == 3) {   // pure pointer walk + 1 uniform load per tk
                        for (int tk = 0; tk < TK; ++tk) acc += (float)p[((size_t)tk * TILES_PER_WG * WORDS + sg_id * WORDS + sg_lane) & 0x7fffffff];
                    } else if (variant == 4) {  // pure ALU
                        float x = acc + (float)tid;
                        for (int tk = 0; tk < TK * 16; ++tk) x = sycl::fma(x, 1.0000001f, 0.5f);
                        acc = x;
                    }
                    out[(size_t)g * 128 + tid] = acc;
                });
            });
            e.wait();
            best = std::min(best, (double)(e.get_profiling_info<sycl::info::event_profiling::command_end>() -
                         e.get_profiling_info<sycl::info::event_profiling::command_start>()) * 1e-3);
        }
        printf("variant %d: %.1f us (%.1f GB/s)\n", variant, best, total_w * 4.0 / (best * 1e-6) / 1e9);
    }
    return 0;
}
