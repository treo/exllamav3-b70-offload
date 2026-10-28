// l0_exts.cpp — enumerate the Level Zero driver + device extension surface this box actually
// has, because which latency tricks are even POSSIBLE depends on it (see
// archive/decode-command-latency.md "Research 2026-10-28"). Built with:
//   icpx -O1 l0_exts.cpp -o l0_exts -lze_loader
#include <level_zero/ze_api.h>
#include <cstdio>
#include <cstring>

int main() {
  zeInit(0);
  uint32_t n = 1;
  ze_driver_handle_t d; zeDriverGet(&n, &d);
  ze_driver_properties_t dp{ZE_STRUCTURE_TYPE_DRIVER_PROPERTIES};
  zeDriverGetProperties(d, &dp);
  printf("driver api %u.%u\n", ZE_MAJOR_VERSION(dp.driverVersion), ZE_MINOR_VERSION(dp.driverVersion));
  uint32_t e = 0;
  zeDriverGetExtensionProperties(d, &e, nullptr);
  printf("extensions=%u\n", e);
  for (uint32_t i = 0; i < e; ++i) { }
  ze_driver_extension_properties_t xp[256];
  e = 256;
  zeDriverGetExtensionProperties(d, &e, xp);
  for (uint32_t i = 0; i < e; ++i)
    printf("  %-58s %u.%u\n", xp[i].name, xp[i].version >> 16, xp[i].version & 0xffff);
  return 0;
}
