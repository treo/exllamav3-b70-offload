// device-only AOT source for t36: plain extern-C kernels, no SYCL types at all
extern "C" __attribute__((sycl_kernel)) void stask2(int* p)
{
    p[0] = 5;
}
extern "C" __attribute__((sycl_kernel)) void addk(int* p, int n)
{
    // ndrange-style: consume global id to prove ids arrive correctly
    extern int __spirv_GlobalInvocationId_x();
    int i = __spirv_GlobalInvocationId_x();
    if (i < n) p[i] += 1;
}
