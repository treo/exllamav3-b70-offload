// l0_coop_probe.cpp — gate G0a of PLAN_PERSISTENT_WORKER.md §3.0, cheap half.
//
// Does this stack advertise COOPERATIVE KERNEL LAUNCH at all? Level Zero puts the entry points in
// core API (zeCommandListAppendLaunchCooperativeKernel, zeKernelSuggestMaxCooperativeGroupCount —
// both exported by the installed loader), so the API's existence proves nothing. The spec's actual
// requirement is a per-command-queue-group capability flag:
//   ZE_COMMAND_QUEUE_GROUP_PROPERTY_FLAG_COOPERATIVE_KERNELS (ze_api.h:2371), and
//   "Kernel is launched ... on a command queue with cooperative flag set".
// Without a queue group advertising it there is no contractual cooperative launch, hence no
// driver-guaranteed grid-wide barrier, hence the engine interior MUST be barrier-free
// (per-expert arrival counters as designed in §3.0) — which is the answer this probe exists for.
//
// Deliberately kernel-free: no module, no SPIR-V, no arg-ABI risk. Just enumeration.
//   icpx -O1 l0_coop_probe.cpp -o l0_coop_probe -lze_loader
#include <level_zero/ze_api.h>
#include <cstdio>
#include <cstring>
#include <dlfcn.h>

static const char *fmt_flags(ze_command_queue_group_property_flags_t f, char *buf, size_t n) {
    *buf = 0;
    if (f & ZE_COMMAND_QUEUE_GROUP_PROPERTY_FLAG_COMPUTE) strncat(buf, "COMPUTE ", n - strlen(buf) - 1);
    if (f & ZE_COMMAND_QUEUE_GROUP_PROPERTY_FLAG_COPY) strncat(buf, "COPY ", n - strlen(buf) - 1);
    if (f & ZE_COMMAND_QUEUE_GROUP_PROPERTY_FLAG_COOPERATIVE_KERNELS)
        strncat(buf, "COOPERATIVE_KERNELS ", n - strlen(buf) - 1);
    if (f & ZE_COMMAND_QUEUE_GROUP_PROPERTY_FLAG_METRICS) strncat(buf, "METRICS ", n - strlen(buf) - 1);
    if (!*buf) strcpy(buf, "(none)");
    return buf;
}

int main() {
    setvbuf(stdout, nullptr, _IONBF, 0);
    zeInit(ZE_INIT_FLAG_GPU_ONLY);

    // Loader symbols exist; do they dispatch to a driver that implements them?
    void *p1 = dlsym(RTLD_DEFAULT, "zeCommandListAppendLaunchCooperativeKernel");
    void *p2 = dlsym(RTLD_DEFAULT, "zeKernelSuggestMaxCooperativeGroupCount");
    printf("loader symbols: AppendLaunchCooperativeKernel=%p SuggestMaxCooperativeGroupCount=%p\n",
           p1, p2);

    uint32_t n = 0;
    zeDriverGet(&n, nullptr);
    ze_driver_handle_t d;
    n = 1;
    zeDriverGet(&n, &d);
    ze_device_handle_t dev = nullptr;
    uint32_t nd = 1;
    zeDeviceGet(d, &nd, &dev);

    ze_device_properties_t dp{ZE_STRUCTURE_TYPE_DEVICE_PROPERTIES};
    zeDeviceGetProperties(dev, &dp);
    printf("device %s (flags 0x%x)\n\n", dp.name, (unsigned)dp.flags);

    uint32_t g = 0;
    zeDeviceGetCommandQueueGroupProperties(dev, &g, nullptr);
    printf("command queue groups: %u\n", g);
    ze_command_queue_group_properties_t qg[8];
    memset(qg, 0, sizeof(qg));
    for (uint32_t i = 0; i < g && i < 8; ++i) qg[i].stype = ZE_STRUCTURE_TYPE_COMMAND_QUEUE_GROUP_PROPERTIES;
    uint32_t gg = g < 8 ? g : 8;
    zeDeviceGetCommandQueueGroupProperties(dev, &gg, qg);
    bool any_coop = false;
    for (uint32_t i = 0; i < gg; ++i) {
        char fb[128];
        printf("  group %u: %-24s fillPattern=%zu numQueues=%u\n", i,
               fmt_flags(qg[i].flags, fb, sizeof(fb)), qg[i].maxMemoryFillPatternSize,
               (unsigned)qg[i].numQueues);
        if (qg[i].flags & ZE_COMMAND_QUEUE_GROUP_PROPERTY_FLAG_COOPERATIVE_KERNELS) any_coop = true;
    }
    printf("\nVERDICT G0a: queue group advertises COOPERATIVE_KERNELS = %s\n",
           any_coop ? "YES (cooperative launch is addressable; grid barrier available)"
                    : "NO  (no driver-guaranteed grid-wide barrier: the engine interior must be "
                      "barrier-free, per-expert arrival counters only)");
    return 0;
}