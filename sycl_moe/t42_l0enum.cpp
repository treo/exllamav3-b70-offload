// t42: does zeModuleCreate accept the production TU's SPV, and what are the kernel names?
#include <sycl/sycl.hpp>
#include <level_zero/ze_api.h>
#include <variant>
#include <cstdio>
#include <cstring>
#include <vector>
#include <string>

int main(int argc, char** argv)
{
    const char* path = argc > 1 ? argv[1] : "/tmp/l0build/moe_all.spv";
    sycl::queue q{sycl::gpu_selector_v};
    auto ctx = q.get_context();
    auto dev = q.get_device();
    ze_context_handle_t zctx = sycl::get_native<sycl::backend::ext_oneapi_level_zero>(ctx);
    ze_device_handle_t zd = sycl::get_native<sycl::backend::ext_oneapi_level_zero>(dev);
    FILE* f = fopen(path, "rb");
    if (!f) { printf("no spv %s\n", path); return 1; }
    fseek(f, 0, SEEK_END); long n = ftell(f); fseek(f, 0, SEEK_SET);
    std::vector<char> blob(n); fread(blob.data(), 1, n, f); fclose(f);
    ze_module_desc_t md{ZE_STRUCTURE_TYPE_MODULE_DESC};
    md.format = ZE_MODULE_FORMAT_IL_SPIRV;
    md.pInputModule = (const uint8_t*)blob.data();
    md.inputSize = n;
    ze_module_build_log_handle_t log{};
    ze_module_handle_t mod{};
    ze_result_t rc = zeModuleCreate(zctx, zd, &md, &mod, &log);
    if (rc != ZE_RESULT_SUCCESS) {
        size_t ls = 0; zeModuleBuildLogGetString(log, &ls, nullptr);
        std::string s(ls, 0); zeModuleBuildLogGetString(log, &ls, s.data());
        printf("MODULE CREATE FAILED rc=%d log:\n%s\n", (int)rc, s.c_str());
        return 2;
    }
    printf("module ok\n");
    uint32_t cnt = 0;
    zeModuleGetKernelNames(mod, &cnt, nullptr);
    std::vector<const char*> names(cnt);
    zeModuleGetKernelNames(mod, &cnt, names.data());
    printf("%u kernels:\n", cnt);
    for (uint32_t i = 0; i < cnt; ++i) printf("  %s\n", names[i]);
    return 0;
}