#include <sycl/sycl.hpp>
#include <level_zero/ze_api.h>
#include <cstdio>
#include <fstream>
#include <variant>
#include <vector>
void build(sycl::queue&, int*);
int main(int argc, char** argv)
{
    const char* spv = argc > 1 ? argv[1] : "t37k.spv";
    std::ifstream f(spv, std::ios::binary);
    if (!f) { printf("no %s\n", spv); return 1; }
    std::vector<char> blob((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
    printf("blob %zu\n", blob.size());
    sycl::device dev([](const sycl::device& d) { return d.get_info<sycl::info::device::name>().find("Arc") != std::string::npos; });
    sycl::context ctx(dev);
    sycl::queue q(ctx, dev, sycl::property::queue::in_order{});
    int* p = sycl::malloc_device<int>(1024, q);
    q.memset(p, 0, 1024 * sizeof(int)).wait();
    ze_context_handle_t zctx = sycl::get_native<sycl::backend::ext_oneapi_level_zero>(ctx);
    ze_device_handle_t zd = sycl::get_native<sycl::backend::ext_oneapi_level_zero>(dev);
    auto qnat = sycl::get_native<sycl::backend::ext_oneapi_level_zero>(q);
    ze_command_list_handle_t list = std::get<ze_command_list_handle_t>(qnat);
    ze_module_desc_t md{ZE_STRUCTURE_TYPE_MODULE_DESC};
    md.format = ZE_MODULE_FORMAT_IL_SPIRV; md.pInputModule = (const uint8_t*)blob.data(); md.inputSize = blob.size(); md.pBuildFlags = "";
    ze_module_handle_t mod = nullptr; ze_module_build_log_handle_t mlog = nullptr;
    ze_result_t r = zeModuleCreate(zctx, zd, &md, &mod, &mlog);
    { size_t sz = 0; zeModuleBuildLogGetString(mlog, &sz, nullptr); std::vector<char> lb(sz);
      if (sz) { zeModuleBuildLogGetString(mlog, &sz, lb.data()); printf("log: %.*s\n", (int)sz, lb.data()); } }
    printf("module rc=%d\n", (int)r);
    if (!mod) return 3;
    // enumerate kernel names in the module
    uint32_t kn = 0; zeModuleGetKernelNames(mod, &kn, nullptr);
    std::vector<const char*> names(kn);
    zeModuleGetKernelNames(mod, &kn, names.data());
    for (auto nm : names) printf("module kernel: %s\n", nm);
    if (kn == 0) return 4;
    // launch the FIRST kernel found as nk (pointer arg): find name containing "nk"
    const char* nn = nullptr;
    for (auto nm : names) if (strstr(nm, "2nk")) nn = nm;
    if (!nn) nn = names[0];
    printf("launching as nk: %s\n", nn);
    ze_kernel_desc_t kd{ZE_STRUCTURE_TYPE_KERNEL_DESC}; kd.pKernelName = nn;
    ze_kernel_handle_t k1 = nullptr;
    r = zeKernelCreate(mod, &kd, &k1);
    printf("kcreate rc=%d\n", (int)r);
    if (!k1) return 5;
    uint32_t gx = 0, gy = 0, gz = 0;
    zeKernelSuggestGroupSize(k1, 1024, 1, 1, &gx, &gy, &gz);
    printf("suggested %u x %u x %u\n", gx, gy, gz);
    void* args[] = {&p};
    ze_group_size_t gs{32, 1, 1};          // FORCE the SYCL nd_range's local size
    ze_group_count_t gc{1024 / 32, 1, 1};
    r = zeCommandListAppendLaunchKernelWithArguments(list, k1, gc, gs, args, nullptr, nullptr, 0, nullptr);
    q.wait();
    std::vector<int> h(1024); q.memcpy(h.data(), p, 1024 * 4); q.wait();
    printf("raw sycl-lambda kernel rc=%d p[0]=%d p[33]=%d p[1023]=%d (expect 0, 1033, 31031) = group*1000+local\n",
           (int)r, h[0], h[33], h[1023]);
    // and the subgroup-collective kernel
    kd.pKernelName = "_ZTS2mk";
    ze_kernel_handle_t k2 = nullptr;
    if (zeKernelCreate(mod, &kd, &k2) == ZE_RESULT_SUCCESS && k2)
    {
        void* a2[] = {&p};
        ze_group_size_t g2{64, 1, 1};
        ze_group_count_t gc2{1024 / 64, 1, 1};
        q.memset(p, 0, 1024 * 4); q.wait();
        r = zeCommandListAppendLaunchKernelWithArguments(list, k2, gc2, g2, a2, nullptr, nullptr, 0, nullptr);
        q.wait();
        q.memcpy(h.data(), p, 1024 * 4); q.wait();
        printf("mk (subgroup reduce, wg64) rc=%d p[0]=%d p[70]=%d (predict grp*100+lane (elect term never fires: sg<64): 0, 106)\n", (int)r, h[0], h[70]);
    }
    return 0;
}
