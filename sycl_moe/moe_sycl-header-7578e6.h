// This is auto-generated SYCL integration header.

#include <sycl/detail/defines_elementary.hpp>
#include <sycl/detail/kernel_desc.hpp>
#include <sycl/ext/oneapi/experimental/free_function_traits.hpp>
#include <sycl/access/access.hpp>

#ifndef SYCL_LANGUAGE_VERSION
#define SYCL_LANGUAGE_VERSION 202012L
#endif //SYCL_LANGUAGE_VERSION

// Forward declarations of templated kernel function types:

namespace sycl {
inline namespace _V1 {
namespace detail {
// names of all kernels defined in the corresponding source
static constexpr
const char* const kernel_names[] = {
  "_ZTSZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE_clESD_EUlNSB_7nd_itemILi2EEEE_",
  "_ZTSZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlbE_clEbENKUlRN4sycl3_V17handlerEE_clESE_EUlNSC_7nd_itemILi1EEEE_",
  "_ZTSZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE0_clESD_EUlNSB_7nd_itemILi2EEEE_",
  "_ZTSZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE1_clESD_EUlNSB_7nd_itemILi2EEEE_",
  "_ZTSZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE2_clESD_EUlNSB_7nd_itemILi2EEEE_",
  "",
};

static constexpr unsigned kernel_args_sizes[] = {9, 21, 10, 7, 9, 4294967295, 
};

// array representing signatures of all kernels defined in the
// corresponding source
static constexpr
const kernel_param_desc_t kernel_signatures[] = {
  //--- _ZTSZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE_clESD_EUlNSB_7nd_itemILi2EEEE_
  { kernel_param_kind_t::kind_std_layout, 4, 0 },
  { kernel_param_kind_t::kind_std_layout, 1, 4 },
  { kernel_param_kind_t::kind_pointer, 8, 8 },
  { kernel_param_kind_t::kind_pointer, 8, 16 },
  { kernel_param_kind_t::kind_std_layout, 4, 24 },
  { kernel_param_kind_t::kind_pointer, 8, 32 },
  { kernel_param_kind_t::kind_std_layout, 4, 40 },
  { kernel_param_kind_t::kind_accessor, 4064, 48 },
  { kernel_param_kind_t::kind_pointer, 8, 80 },

  //--- _ZTSZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlbE_clEbENKUlRN4sycl3_V17handlerEE_clESE_EUlNSC_7nd_itemILi1EEEE_
  { kernel_param_kind_t::kind_std_layout, 4, 0 },
  { kernel_param_kind_t::kind_std_layout, 1, 4 },
  { kernel_param_kind_t::kind_std_layout, 4, 8 },
  { kernel_param_kind_t::kind_std_layout, 1, 12 },
  { kernel_param_kind_t::kind_pointer, 8, 16 },
  { kernel_param_kind_t::kind_pointer, 8, 24 },
  { kernel_param_kind_t::kind_std_layout, 4, 32 },
  { kernel_param_kind_t::kind_pointer, 8, 40 },
  { kernel_param_kind_t::kind_std_layout, 4, 48 },
  { kernel_param_kind_t::kind_pointer, 8, 56 },
  { kernel_param_kind_t::kind_std_layout, 4, 64 },
  { kernel_param_kind_t::kind_std_layout, 256, 68 },
  { kernel_param_kind_t::kind_std_layout, 4, 324 },
  { kernel_param_kind_t::kind_std_layout, 4, 328 },
  { kernel_param_kind_t::kind_std_layout, 4, 332 },
  { kernel_param_kind_t::kind_accessor, 4064, 336 },
  { kernel_param_kind_t::kind_std_layout, 4, 368 },
  { kernel_param_kind_t::kind_accessor, 4064, 376 },
  { kernel_param_kind_t::kind_std_layout, 4, 408 },
  { kernel_param_kind_t::kind_pointer, 8, 416 },
  { kernel_param_kind_t::kind_pointer, 8, 424 },

  //--- _ZTSZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE0_clESD_EUlNSB_7nd_itemILi2EEEE_
  { kernel_param_kind_t::kind_pointer, 8, 0 },
  { kernel_param_kind_t::kind_pointer, 8, 8 },
  { kernel_param_kind_t::kind_std_layout, 4, 16 },
  { kernel_param_kind_t::kind_std_layout, 1, 20 },
  { kernel_param_kind_t::kind_pointer, 8, 24 },
  { kernel_param_kind_t::kind_std_layout, 4, 32 },
  { kernel_param_kind_t::kind_accessor, 4064, 40 },
  { kernel_param_kind_t::kind_std_layout, 4, 72 },
  { kernel_param_kind_t::kind_std_layout, 4, 76 },
  { kernel_param_kind_t::kind_pointer, 8, 80 },

  //--- _ZTSZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE1_clESD_EUlNSB_7nd_itemILi2EEEE_
  { kernel_param_kind_t::kind_pointer, 8, 0 },
  { kernel_param_kind_t::kind_pointer, 8, 8 },
  { kernel_param_kind_t::kind_std_layout, 4, 16 },
  { kernel_param_kind_t::kind_accessor, 4064, 24 },
  { kernel_param_kind_t::kind_pointer, 8, 56 },
  { kernel_param_kind_t::kind_std_layout, 4, 64 },
  { kernel_param_kind_t::kind_pointer, 8, 72 },

  //--- _ZTSZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE2_clESD_EUlNSB_7nd_itemILi2EEEE_
  { kernel_param_kind_t::kind_pointer, 8, 0 },
  { kernel_param_kind_t::kind_pointer, 8, 8 },
  { kernel_param_kind_t::kind_pointer, 8, 16 },
  { kernel_param_kind_t::kind_pointer, 8, 24 },
  { kernel_param_kind_t::kind_std_layout, 4, 32 },
  { kernel_param_kind_t::kind_accessor, 4064, 40 },
  { kernel_param_kind_t::kind_pointer, 8, 72 },
  { kernel_param_kind_t::kind_std_layout, 4, 80 },
  { kernel_param_kind_t::kind_pointer, 8, 88 },

  { kernel_param_kind_t::kind_invalid, -987654321, -987654321 }, 
};

} // namespace detail
} // namespace _V1
} // namespace sycl
// Specializations of KernelInfo for kernel function types:
namespace sycl {
inline namespace _V1 {
namespace detail {
template <> struct KernelInfoData<'_', 'Z', 'T', 'S', 'Z', 'Z', 'N', '8', 'm', 'o', 'e', '_', 's', 'y', 'c', 'l', '1', '2', 'M', 'o', 'e', 'S', 'y', 'c', 'l', 'L', 'a', 'y', 'e', 'r', '7', 'f', 'o', 'r', 'w', 'a', 'r', 'd', 'E', 'P', 'K', 'N', 'S', '_', '8', 'C', 'h', 'u', 'n', 'k', 'D', 'e', 'v', 'E', 'i', 'R', 'K', 'N', 'S', '_', '8', 'T', 'o', 'k', 'e', 'n', 'M', 'a', 'p', 'E', 'P', 'K', 't', 'P', 'f', 'i', 'E', 'N', 'K', 'U', 'l', 'R', 'N', '4', 's', 'y', 'c', 'l', '3', '_', 'V', '1', '7', 'h', 'a', 'n', 'd', 'l', 'e', 'r', 'E', 'E', '_', 'c', 'l', 'E', 'S', 'D', '_', 'E', 'U', 'l', 'N', 'S', 'B', '_', '7', 'n', 'd', '_', 'i', 't', 'e', 'm', 'I', 'L', 'i', '2', 'E', 'E', 'E', 'E', '_'> {
  __SYCL_DLL_LOCAL
  static constexpr const char* getName() { return "_ZTSZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE_clESD_EUlNSB_7nd_itemILi2EEEE_"; }
  __SYCL_DLL_LOCAL
  static constexpr unsigned getNumParams() { return 9; }
  __SYCL_DLL_LOCAL
  static constexpr const kernel_param_desc_t& getParamDesc(unsigned i) {
    return kernel_signatures[i+0];
  }
  __SYCL_DLL_LOCAL
  static constexpr bool isESIMD() { return 0; }
  __SYCL_DLL_LOCAL
  static constexpr const char* getFileName() {
#ifndef NDEBUG
    return "moe_sycl.cpp";
#else
    return "";
#endif
  }
  __SYCL_DLL_LOCAL
  static constexpr const char* getFunctionName() {
#ifndef NDEBUG
    return "moe_sycl::class (lambda)";
#else
    return "";
#endif
  }
  __SYCL_DLL_LOCAL
  static constexpr unsigned getLineNumber() {
#ifndef NDEBUG
    return 183;
#else
    return 0;
#endif
  }
  __SYCL_DLL_LOCAL
  static constexpr unsigned getColumnNumber() {
#ifndef NDEBUG
    return 17;
#else
    return 0;
#endif
  }
  // Returns the size of the kernel object in bytes.
  __SYCL_DLL_LOCAL
  static constexpr long getKernelSize() { return 88; }
};
template <> struct KernelInfoData<'_', 'Z', 'T', 'S', 'Z', 'Z', 'Z', 'N', '8', 'm', 'o', 'e', '_', 's', 'y', 'c', 'l', '1', '2', 'M', 'o', 'e', 'S', 'y', 'c', 'l', 'L', 'a', 'y', 'e', 'r', '7', 'f', 'o', 'r', 'w', 'a', 'r', 'd', 'E', 'P', 'K', 'N', 'S', '_', '8', 'C', 'h', 'u', 'n', 'k', 'D', 'e', 'v', 'E', 'i', 'R', 'K', 'N', 'S', '_', '8', 'T', 'o', 'k', 'e', 'n', 'M', 'a', 'p', 'E', 'P', 'K', 't', 'P', 'f', 'i', 'E', 'N', 'K', 'U', 'l', 'b', 'E', '_', 'c', 'l', 'E', 'b', 'E', 'N', 'K', 'U', 'l', 'R', 'N', '4', 's', 'y', 'c', 'l', '3', '_', 'V', '1', '7', 'h', 'a', 'n', 'd', 'l', 'e', 'r', 'E', 'E', '_', 'c', 'l', 'E', 'S', 'E', '_', 'E', 'U', 'l', 'N', 'S', 'C', '_', '7', 'n', 'd', '_', 'i', 't', 'e', 'm', 'I', 'L', 'i', '1', 'E', 'E', 'E', 'E', '_'> {
  __SYCL_DLL_LOCAL
  static constexpr const char* getName() { return "_ZTSZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlbE_clEbENKUlRN4sycl3_V17handlerEE_clESE_EUlNSC_7nd_itemILi1EEEE_"; }
  __SYCL_DLL_LOCAL
  static constexpr unsigned getNumParams() { return 21; }
  __SYCL_DLL_LOCAL
  static constexpr const kernel_param_desc_t& getParamDesc(unsigned i) {
    return kernel_signatures[i+9];
  }
  __SYCL_DLL_LOCAL
  static constexpr bool isESIMD() { return 0; }
  __SYCL_DLL_LOCAL
  static constexpr const char* getFileName() {
#ifndef NDEBUG
    return "moe_sycl.cpp";
#else
    return "";
#endif
  }
  __SYCL_DLL_LOCAL
  static constexpr const char* getFunctionName() {
#ifndef NDEBUG
    return "moe_sycl::class (lambda)";
#else
    return "";
#endif
  }
  __SYCL_DLL_LOCAL
  static constexpr unsigned getLineNumber() {
#ifndef NDEBUG
    return 218;
#else
    return 0;
#endif
  }
  __SYCL_DLL_LOCAL
  static constexpr unsigned getColumnNumber() {
#ifndef NDEBUG
    return 62;
#else
    return 0;
#endif
  }
  // Returns the size of the kernel object in bytes.
  __SYCL_DLL_LOCAL
  static constexpr long getKernelSize() { return 432; }
};
template <> struct KernelInfoData<'_', 'Z', 'T', 'S', 'Z', 'Z', 'N', '8', 'm', 'o', 'e', '_', 's', 'y', 'c', 'l', '1', '2', 'M', 'o', 'e', 'S', 'y', 'c', 'l', 'L', 'a', 'y', 'e', 'r', '7', 'f', 'o', 'r', 'w', 'a', 'r', 'd', 'E', 'P', 'K', 'N', 'S', '_', '8', 'C', 'h', 'u', 'n', 'k', 'D', 'e', 'v', 'E', 'i', 'R', 'K', 'N', 'S', '_', '8', 'T', 'o', 'k', 'e', 'n', 'M', 'a', 'p', 'E', 'P', 'K', 't', 'P', 'f', 'i', 'E', 'N', 'K', 'U', 'l', 'R', 'N', '4', 's', 'y', 'c', 'l', '3', '_', 'V', '1', '7', 'h', 'a', 'n', 'd', 'l', 'e', 'r', 'E', 'E', '0', '_', 'c', 'l', 'E', 'S', 'D', '_', 'E', 'U', 'l', 'N', 'S', 'B', '_', '7', 'n', 'd', '_', 'i', 't', 'e', 'm', 'I', 'L', 'i', '2', 'E', 'E', 'E', 'E', '_'> {
  __SYCL_DLL_LOCAL
  static constexpr const char* getName() { return "_ZTSZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE0_clESD_EUlNSB_7nd_itemILi2EEEE_"; }
  __SYCL_DLL_LOCAL
  static constexpr unsigned getNumParams() { return 10; }
  __SYCL_DLL_LOCAL
  static constexpr const kernel_param_desc_t& getParamDesc(unsigned i) {
    return kernel_signatures[i+30];
  }
  __SYCL_DLL_LOCAL
  static constexpr bool isESIMD() { return 0; }
  __SYCL_DLL_LOCAL
  static constexpr const char* getFileName() {
#ifndef NDEBUG
    return "moe_sycl.cpp";
#else
    return "";
#endif
  }
  __SYCL_DLL_LOCAL
  static constexpr const char* getFunctionName() {
#ifndef NDEBUG
    return "moe_sycl::class (lambda)";
#else
    return "";
#endif
  }
  __SYCL_DLL_LOCAL
  static constexpr unsigned getLineNumber() {
#ifndef NDEBUG
    return 306;
#else
    return 0;
#endif
  }
  __SYCL_DLL_LOCAL
  static constexpr unsigned getColumnNumber() {
#ifndef NDEBUG
    return 17;
#else
    return 0;
#endif
  }
  // Returns the size of the kernel object in bytes.
  __SYCL_DLL_LOCAL
  static constexpr long getKernelSize() { return 88; }
};
template <> struct KernelInfoData<'_', 'Z', 'T', 'S', 'Z', 'Z', 'N', '8', 'm', 'o', 'e', '_', 's', 'y', 'c', 'l', '1', '2', 'M', 'o', 'e', 'S', 'y', 'c', 'l', 'L', 'a', 'y', 'e', 'r', '7', 'f', 'o', 'r', 'w', 'a', 'r', 'd', 'E', 'P', 'K', 'N', 'S', '_', '8', 'C', 'h', 'u', 'n', 'k', 'D', 'e', 'v', 'E', 'i', 'R', 'K', 'N', 'S', '_', '8', 'T', 'o', 'k', 'e', 'n', 'M', 'a', 'p', 'E', 'P', 'K', 't', 'P', 'f', 'i', 'E', 'N', 'K', 'U', 'l', 'R', 'N', '4', 's', 'y', 'c', 'l', '3', '_', 'V', '1', '7', 'h', 'a', 'n', 'd', 'l', 'e', 'r', 'E', 'E', '1', '_', 'c', 'l', 'E', 'S', 'D', '_', 'E', 'U', 'l', 'N', 'S', 'B', '_', '7', 'n', 'd', '_', 'i', 't', 'e', 'm', 'I', 'L', 'i', '2', 'E', 'E', 'E', 'E', '_'> {
  __SYCL_DLL_LOCAL
  static constexpr const char* getName() { return "_ZTSZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE1_clESD_EUlNSB_7nd_itemILi2EEEE_"; }
  __SYCL_DLL_LOCAL
  static constexpr unsigned getNumParams() { return 7; }
  __SYCL_DLL_LOCAL
  static constexpr const kernel_param_desc_t& getParamDesc(unsigned i) {
    return kernel_signatures[i+40];
  }
  __SYCL_DLL_LOCAL
  static constexpr bool isESIMD() { return 0; }
  __SYCL_DLL_LOCAL
  static constexpr const char* getFileName() {
#ifndef NDEBUG
    return "moe_sycl.cpp";
#else
    return "";
#endif
  }
  __SYCL_DLL_LOCAL
  static constexpr const char* getFunctionName() {
#ifndef NDEBUG
    return "moe_sycl::class (lambda)";
#else
    return "";
#endif
  }
  __SYCL_DLL_LOCAL
  static constexpr unsigned getLineNumber() {
#ifndef NDEBUG
    return 372;
#else
    return 0;
#endif
  }
  __SYCL_DLL_LOCAL
  static constexpr unsigned getColumnNumber() {
#ifndef NDEBUG
    return 17;
#else
    return 0;
#endif
  }
  // Returns the size of the kernel object in bytes.
  __SYCL_DLL_LOCAL
  static constexpr long getKernelSize() { return 80; }
};
template <> struct KernelInfoData<'_', 'Z', 'T', 'S', 'Z', 'Z', 'N', '8', 'm', 'o', 'e', '_', 's', 'y', 'c', 'l', '1', '2', 'M', 'o', 'e', 'S', 'y', 'c', 'l', 'L', 'a', 'y', 'e', 'r', '7', 'f', 'o', 'r', 'w', 'a', 'r', 'd', 'E', 'P', 'K', 'N', 'S', '_', '8', 'C', 'h', 'u', 'n', 'k', 'D', 'e', 'v', 'E', 'i', 'R', 'K', 'N', 'S', '_', '8', 'T', 'o', 'k', 'e', 'n', 'M', 'a', 'p', 'E', 'P', 'K', 't', 'P', 'f', 'i', 'E', 'N', 'K', 'U', 'l', 'R', 'N', '4', 's', 'y', 'c', 'l', '3', '_', 'V', '1', '7', 'h', 'a', 'n', 'd', 'l', 'e', 'r', 'E', 'E', '2', '_', 'c', 'l', 'E', 'S', 'D', '_', 'E', 'U', 'l', 'N', 'S', 'B', '_', '7', 'n', 'd', '_', 'i', 't', 'e', 'm', 'I', 'L', 'i', '2', 'E', 'E', 'E', 'E', '_'> {
  __SYCL_DLL_LOCAL
  static constexpr const char* getName() { return "_ZTSZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE2_clESD_EUlNSB_7nd_itemILi2EEEE_"; }
  __SYCL_DLL_LOCAL
  static constexpr unsigned getNumParams() { return 9; }
  __SYCL_DLL_LOCAL
  static constexpr const kernel_param_desc_t& getParamDesc(unsigned i) {
    return kernel_signatures[i+47];
  }
  __SYCL_DLL_LOCAL
  static constexpr bool isESIMD() { return 0; }
  __SYCL_DLL_LOCAL
  static constexpr const char* getFileName() {
#ifndef NDEBUG
    return "moe_sycl.cpp";
#else
    return "";
#endif
  }
  __SYCL_DLL_LOCAL
  static constexpr const char* getFunctionName() {
#ifndef NDEBUG
    return "moe_sycl::class (lambda)";
#else
    return "";
#endif
  }
  __SYCL_DLL_LOCAL
  static constexpr unsigned getLineNumber() {
#ifndef NDEBUG
    return 398;
#else
    return 0;
#endif
  }
  __SYCL_DLL_LOCAL
  static constexpr unsigned getColumnNumber() {
#ifndef NDEBUG
    return 17;
#else
    return 0;
#endif
  }
  // Returns the size of the kernel object in bytes.
  __SYCL_DLL_LOCAL
  static constexpr long getKernelSize() { return 96; }
};

} // namespace detail
} // namespace _V1
} // namespace sycl
