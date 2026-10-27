// Phase timing for the registration upload path at realistic geometry (E=256, 2bit).
#include <sycl/sycl.hpp>
#include <chrono>
#include <cstdio>
#include <vector>
#include "../sycl_moe/moe_sycl.hpp"
using clk = std::chrono::steady_clock;
static double ms(clk::time_point a, clk::time_point b) {
    return std::chrono::duration<double, std::milli>(b - a).count();
}
int main() {
    sycl::queue q{sycl::gpu_selector_v};
    const int H = 2560, I = 640, k2 = 4, E = 256;
    const size_t tri_u16 = (size_t)(H/16)*(I/16)*8*k2;
    const size_t block = ((tri_u16*2 + 63)/64*64)*3 + 2048*3*2;   // ~ per-expert block (approx)
    const size_t total = block * E;
    printf("geometry: block %zu KB, total %.2f GB\n", block/1024, total/1e9);
    std::vector<uint16_t> src(tri_u16 * E * 3, 0x1234);
    std::vector<uint8_t> stage(total, 0);
    auto t0 = clk::now();
    for (size_t e = 0; e < (size_t)E * 3; ++e)
        moe_sycl::repack_native_to_stream_words((uint32_t*)(stage.data() + (e*(block/3)) ), (const uint32_t*)(src.data() + e*tri_u16), tri_u16/(2*(size_t)k2*4), k2);
    auto t1 = clk::now();
    printf("host repack+fill:      %.1f ms\n", ms(t0, t1));
    char* d = sycl::malloc_device<char>(total, q);
    q.wait();
    auto t2 = clk::now();
    q.memcpy(d, stage.data(), total).wait();
    auto t3 = clk::now();
    printf("pageable H2D one-shot: %.1f ms  (%.2f GB/s)\n", ms(t2, t3), total/ms(t2,t3)/1e6);
    char* dp = (char*)sycl::malloc_host(total, q);
    memcpy(dp, stage.data(), total);
    q.wait();
    auto t4 = clk::now();
    q.memcpy(d, dp, total).wait();
    auto t5 = clk::now();
    printf("pinned   H2D one-shot: %.1f ms  (%.2f GB/s)\n", ms(t4, t5), total/ms(t4,t5)/1e6);
    // chunked pinned copy in 32MB slices (overlap potential probe)
    auto t6 = clk::now();
    for (size_t o = 0; o < total; o += (1u<<25)) q.memcpy(d+o, dp+o, std::min<size_t>(1u<<25, total-o)).wait();
    auto t7 = clk::now();
    printf("pinned   H2D 32MB:     %.1f ms  (%.2f GB/s)\n", ms(t6, t7), total/ms(t6,t7)/1e6);
    return 0;
}