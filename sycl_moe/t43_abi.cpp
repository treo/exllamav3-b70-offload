// t43: validate the EXACT launch ABI the production chain needs:
//   kernel captured args = { by-value POD struct, local_accessor<uchar,1> }
// launched via zeCommandListAppendLaunchKernelWithArguments on the queue's own
// immediate list, from a zeModuleCreate'd own SPV. Writes verifiable output via the
// struct's pointers; the host checks (1) struct passed intact, (2) local accessor
// usable as SLM, (3) nd_item group/local ids correct for nd_range<2>.
#include <sycl/sycl.hpp>
#include <level_zero/ze_api.h>
#include <variant>
#include <cstdio>
#include <cstring>
#include <vector>

struct SB   // our Gemv8Base-shaped POD bundle
{
    int a, b, c, d;
    long xs, ys, zs, ws;   // a few pointers-as-usize to test 8B packing
    int e, f;
};

void build(sycl::queue& q, int* out, SB s)
{
    q.submit([=](sycl::handler& cgh) {
        sycl::local_accessor<unsigned char, 1> slab({4096}, cgh);
        cgh.parallel_for<class abik>(
            sycl::nd_range<2>{{64, 3}, {16, 1}},
            [=](sycl::nd_item<2> it) {
                unsigned char* sl = slab.get_pointer().get();
                const int g0 = (int)it.get_group(0), g1 = (int)it.get_group(1);
                const int lid = (int)it.get_local_id(0);
                sl[lid] = (unsigned char)(g0 * 16 + lid);
                sl[lid + 16] = (unsigned char)(g1 * 4);
                sycl::group_barrier(it.get_group());
                if (lid == 0)
                    out[g1 * 4 + g0] = (int)sl[lid] + s.a * 100000 + s.b + (int)sl[lid + 16] + (int)s.xs;
            });
    });
    q.wait();
}

int main(int argc, char** argv)
{
    sycl::queue q{sycl::gpu_selector_v};
    int* dout = sycl::malloc_device<int>(16, q);
    q.memset(dout, 0, 64).wait();
    SB s{}; s.a = 7; s.b = 31; s.xs = 1234567; s.c = 9;
    build(q, dout, s);
    std::vector<int> ref(16), got(16, -1);
    q.memcpy(ref.data(), dout, 64).wait();
    q.memset(dout, 0, 64).wait();
    printf("sycl path: %d %d ... %d\n", ref[0], ref[1], ref[15]);
    std::fill(ref.begin(), ref.end(), -1);
    build(q, dout, s);
    q.memcpy(ref.data(), dout, 64).wait();   // fresh reference (nonzero expectations)

    // ---- now the native path ----
    ze_context_handle_t zctx = sycl::get_native<sycl::backend::ext_oneapi_level_zero>(q.get_context());
    ze_device_handle_t zd = sycl::get_native<sycl::backend::ext_oneapi_level_zero>(q.get_device());
    ze_command_list_handle_t list = std::get<ze_command_list_handle_t>(
        sycl::get_native<sycl::backend::ext_oneapi_level_zero>(q));
    // blob produced by: icpx -fsycl -c -save-temps t43.cpp; sycl-post-link ...; llvm-spirv ...
    FILE* f = fopen("/tmp/l0build/t43.spv", "rb");
    if (!f) { printf("run build first\n"); return 1; }
    fseek(f, 0, SEEK_END); long n = ftell(f); fseek(f, 0, SEEK_SET);
    std::vector<char> blob(n); fread(blob.data(), 1, n, f); fclose(f);
    ze_module_desc_t md{ZE_STRUCTURE_TYPE_MODULE_DESC};
    md.format = ZE_MODULE_FORMAT_IL_SPIRV; md.pInputModule = (const uint8_t*)blob.data(); md.inputSize = n;
    ze_module_handle_t mod{}; ze_module_build_log_handle_t mlog{};
    ze_result_t rc = zeModuleCreate(zctx, zd, &md, &mod, &mlog);
    if (rc != ZE_RESULT_SUCCESS) { printf("mod rc=%d\n", (int)rc); return 2; }
    ze_kernel_desc_t kd{ZE_STRUCTURE_TYPE_KERNEL_DESC};
    uint32_t kn = 0;
    zeModuleGetKernelNames(mod, &kn, nullptr);
    std::vector<const char*> names(kn);
    zeModuleGetKernelNames(mod, &kn, names.data());
    const char* want = nullptr;
    for (auto* nm : names) if (strstr(nm, "4abik")) { want = nm; break; }
    if (!want) { printf("kernel 'abik' not in module (%u names)\n", kn); return 3; }
    printf("kernel name: %s\n", want);
    ze_kernel_handle_t k{};
    kd.pKernelName = want;
    rc = zeKernelCreate(mod, &kd, &k);
    if (rc != ZE_RESULT_SUCCESS) { printf("kernel rc=%d\n", (int)rc); return 3; }
    q.memset(dout, 0, 64).wait();
    unsigned char local_token = 0;                 // __local arg: value patched by driver
    void* dummy_local = (void*)&local_token;
    (void)dummy_local;
    SB s2 = s;
    void* args2[] = {&dout, &s2};
    void* args3[] = {&dout, &s2, &dummy_local};
    ze_group_size_t gs{16, 1, 1};
    ze_group_count_t gc{4, 3, 1};
    for (int variant = 3; variant <= 3; ++variant)   // 2-arg variant PROVES the crash: local_accessor IS arg 3
    {
        q.memset(dout, 0, 64).wait();
        rc = zeCommandListAppendLaunchKernelWithArguments(list, k, gc, gs,
                variant == 2 ? args2 : args3, nullptr, nullptr, 0, nullptr);
        q.wait();
        if (rc != ZE_RESULT_SUCCESS) { printf("v%d launch rc=%d\n", variant, (int)rc); continue; }
        q.memcpy(got.data(), dout, 64).wait();
        printf("variant %d args: %s\n", variant, got == ref ? "MATCH" : "mismatch");
    }
}