#include <cstdio>
#include <cstdint>
#include <vector>
#include "moe_sycl.hpp"
int main() {
    const int K2 = 8, W = 4 * K2;
    std::vector<uint32_t> a(W), b(W, 0);
    for (int i = 0; i < W; ++i) a[i] = 0xA000000u + i;
    moe_sycl::repack_native_to_stream_words(b.data(), a.data(), 1, K2);
    printf("b[0]=%08x b[1]=%08x b[31]=%08x (want a0=%08x a1=%08x a31=%08x)\n", b[0], b[1], b[31], a[0], a[31], a[1]);
    return 0;
}
