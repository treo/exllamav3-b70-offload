// an SYCL-idiomatic kernel: nd_range + nd_item builtins + captured pointer, like ours
#include <sycl/sycl.hpp>
struct nk {}; struct mk {};
void build(sycl::queue& q, int* p)
{
    q.submit([=](sycl::handler& cgh) {
        cgh.parallel_for<nk>(sycl::nd_range<1>{{1024}, {32}}, [=](sycl::nd_item<1> it) {
            p[it.get_global_id(0)] = it.get_group(0) * 1000 + (int)it.get_local_id(0);
        });
    });
    q.submit([=](sycl::handler& cgh) {   // dpas-flavored: sub_group ops + reduce geometry
        cgh.parallel_for<mk>(sycl::nd_range<1>{{1024}, {64}}, [=](sycl::nd_item<1> it) {
            auto sg = it.get_sub_group();
            int lane = (int)sg.get_local_id();
            int v = it.get_group(0) * 100 + lane;
            v += sycl::reduce_over_group(sg, 1, sycl::plus<int>()) == 64 ? 7 : 0;
            p[it.get_global_id(0)] = v;
        });
    });
    q.wait();
}
