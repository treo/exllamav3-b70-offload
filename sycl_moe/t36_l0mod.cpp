// t36: ISOLATION - can an EXTERNALLY CREATED ze module's kernel run on the SYCL
// queue's own immediate command list (same ze context)? t35 showed RT-JIT kernel
// handles accept raw launches (rc=0) but never execute, while a raw memory fill on
// the same list DOES land. If t36's own-module kernels land too, the native path
// means "ship our own SPV"; if they don't, RT lists reject foreign kernels too and
// the plugin would need a fully private context+queue (still possible; USM shared).
#include <sycl/sycl.hpp>
#include <level_zero/ze_api.h>
#include <cstdio>
#include <fstream>
#include <variant>
#include <vector>

int main(int argc, char** argv)
{
    const char* spv = argc > 1 ? argv[1] : "/tmp/ocloc_out/t36k_bmg.spv";
    std::ifstream f(spv, std::ios::binary);
    if (!f) { printf("no %s\n", spv); return 1; }
    std::vector<char> blob((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
    printf("module blob %zu bytes\n", blob.size());

    sycl::device dev([](const sycl::device& d) { return d.get_info<sycl::info::device::name>().find("Arc") != std::string::npos; });
    sycl::context ctx(dev);
    sycl::queue q(ctx, dev, sycl::property::queue::in_order{});
    int* p = sycl::malloc_device<int>(1024, q);
    q.memset(p, 0, 1024 * sizeof(int)).wait();

    ze_context_handle_t zctx = sycl::get_native<sycl::backend::ext_oneapi_level_zero>(ctx);
    ze_device_handle_t zd = sycl::get_native<sycl::backend::ext_oneapi_level_zero>(dev);
    auto qnat = sycl::get_native<sycl::backend::ext_oneapi_level_zero>(q);
    if (!std::holds_alternative<ze_command_list_handle_t>(qnat)) { printf("queue native not a list\n"); return 2; }
    ze_command_list_handle_t list = std::get<ze_command_list_handle_t>(qnat);

    ze_module_desc_t md{ZE_STRUCTURE_TYPE_MODULE_DESC};
    md.format = ZE_MODULE_FORMAT_IL_SPIRV;
    md.pInputModule = (const uint8_t*)blob.data();
    md.inputSize = blob.size();
    md.pBuildFlags = "";
    ze_module_handle_t mod = nullptr;
    ze_module_build_log_handle_t log = nullptr;
    ze_result_t r = zeModuleCreate(zctx, zd, &md, &mod, &log);
    {   size_t sz = 0; zeModuleBuildLogGetString(log, &sz, nullptr);
        std::vector<char> lb(sz); if (sz) zeModuleBuildLogGetString(log, &sz, lb.data());
        if (sz) printf("build log: %.*s\n", (int)sz, lb.data());
        if (log) zeModuleBuildLogDestroy(log);
    }
    printf("moduleCreate rc=%d\n", (int)r);
    if (!mod) return 3;

    ze_kernel_desc_t kd{ZE_STRUCTURE_TYPE_KERNEL_DESC};
    kd.pKernelName = "stask2";
    ze_kernel_handle_t k1 = nullptr;
    r = zeKernelCreate(mod, &kd, &k1);
    printf("kernel stask2 rc=%d\n", (int)r);
    if (!k1) return 4;
    kd.pKernelName = "addk";
    ze_kernel_handle_t k2 = nullptr;
    zeKernelCreate(mod, &kd, &k2);

    // stask2: one pointer arg, 1 group
    {
        void* args[] = {&p};
        ze_group_size_t gs{8, 1, 1};   // SIMD8 floor for 1-thread work; value irrelevant to outcome
        ze_group_count_t gc{1, 1, 1};
        r = zeCommandListAppendLaunchKernelWithArguments(list, k1, gc, gs, args, nullptr, nullptr, 0, nullptr);
        q.wait();
        int h = 0; q.memcpy(&h, p, 4); q.wait();
        printf("own-module stask2 rc=%d p[0]=%d (5 => EXTERNAL modules DO run on the RT list)\n", (int)r, h);
    }
    // addk: pointer + int, 1024 threads
    if (k2)
    {
        int n = 1024;
        void* args[] = {&p, &n};
        uint32_t gx = 0, gy = 0, gz = 0;
        zeKernelSuggestGroupSize(k2, 1024, 1, 1, &gx, &gy, &gz);
        ze_group_size_t gs{gx, gy ? gy : 1, gz ? gz : 1};
        ze_group_count_t gc{(uint32_t)(1024 / gx), 1, 1};
        r = zeCommandListAppendLaunchKernelWithArguments(list, k2, gc, gs, args, nullptr, nullptr, 0, nullptr);
        q.wait();
        std::vector<int> h(1024); q.memcpy(h.data(), p, 1024 * 4); q.wait();
        printf("own-module addk rc=%d p[0]=%d p[1023]=%d (expected +1 each over stask2's value)\n", (int)r, h[0], h[1023]);
    }
    return 0;
}