// lab_graph3.cpp — validate (and time) the pattern a decode-graph implementation would need:
// ONE captured graph = [H2D of a fixed pinned 'job block' -> kernels reading it], replayed per
// job with the host rewriting the pinned block in between. Proves the copy node re-reads the
// host buffer on every replay and that geometry can vary through device memory instead of
// kernel args.   icpx -fsycl -O2 lab_graph3.cpp -o lab_graph3 && ./lab_graph3
#include <sycl/sycl.hpp>
#include <sycl/ext/oneapi/experimental/graph.hpp>
#include <chrono>
#include <cstdio>
#include <vector>
namespace gx = sycl::ext::oneapi::experimental;

struct Job { int rows; int nc; float scale; };            // the "job block"

static double now_us() {
    return std::chrono::duration<double, std::micro>(
        std::chrono::steady_clock::now().time_since_epoch()).count();
}

int main() {
    sycl::queue q{sycl::gpu_selector_v, sycl::property::queue::in_order{}};
    printf("device: %s\n", q.get_device().get_info<sycl::info::device::name>().c_str());

    Job* hjob = (Job*)sycl::malloc_host(sizeof(Job), q);       // pinned host job block
    Job* djob = (Job*)sycl::malloc_device(sizeof(Job), q);     // device copy the kernels read
    float* out = sycl::malloc_device<float>(4096, q);
    q.memset(out, 0, 4096 * sizeof(float)).wait();

    // 'kernel chain' shape: 3 dependent kernels, all arg-stable; geometry comes from djob.
    auto cgk = [&](int k) {
        return [=](sycl::handler& cgh) {
            cgh.parallel_for(sycl::range<1>{64}, [=](sycl::item<1> it) {
                const Job j = *djob;                       // read the indirected job block
                float v = out[it.get_id(0)] * 0.5f;
                out[it.get_id(0)] = v + j.rows * 1.f + j.nc * 2.f + j.scale + k;
            });
        };
    };
    auto build_chain = [&](sycl::queue& qq) {
        sycl::event e = qq.memcpy(djob, hjob, sizeof(Job));
        for (int k = 0; k < 3; ++k) {
            sycl::event prev = e;
            e = qq.submit([&](sycl::handler& cgh) {
                cgh.depends_on(prev);
                cgh.parallel_for(sycl::range<1>{64}, [=](sycl::item<1> it) {
                    const Job j = *djob;
                    out[it.get_id(0)] = out[it.get_id(0)] * 0.5f
                                      + j.rows + 2 * j.nc + j.scale + k;
                });
            });
        }
        return e;
    };

    gx::command_graph<gx::graph_state::modifiable> mg{q};
    gx::node n = mg.add([&](sycl::handler& cgh) { cgh.memcpy(djob, hjob, sizeof(Job)); });
    for (int k = 0; k < 3; ++k)
        n = mg.add(cgk(k), sycl::property_list{gx::property::node::depends_on{n}});
    auto eg = mg.finalize();

    // ---- correctness: each replay must see the NEW pinned contents
    int bad = 0;
    float prev = 0.f;                                  // out[] is NOT reset between replays
    float* hout = (float*)sycl::malloc_host(sizeof(float), q);
    for (int trial = 0; trial < 500; ++trial) {
        hjob->rows = trial % 7; hjob->nc = (trial * 13) % 11; hjob->scale = 0.25f * trial;
        q.ext_oneapi_graph(eg).wait();
        q.memcpy(hout, out + 3, sizeof(float)).wait();
        float got = *hout;
        float want = prev;
        for (int k = 0; k < 3; ++k)                          // replicate the recurrence
            want = want * 0.5f + hjob->rows + 2 * hjob->nc + hjob->scale + k;
        prev = want;
        if (std::abs(got - want) > 1e-4f) { if (bad++ < 3) printf("  MISMATCH %d: got %.4f want %.4f\n", trial, got, want); }
    }
    printf("replay-sees-updated-job-block: %s (%d bad / 500)\n", bad ? "NO" : "YES", bad);

    // ---- timing: submits vs replay, both with a per-iteration host-side job rewrite
    const int iters = 4000;
    for (int i = 0; i < 2000; ++i) { hjob->rows = i & 7; build_chain(q).wait(); }
    double bs = 1e30, bg = 1e30;
    for (int w = 0; w < 3; ++w) {
        double t0 = now_us();
        for (int i = 0; i < iters; ++i) { hjob->rows = i & 7; hjob->nc = i & 15; build_chain(q).wait(); }
        bs = std::min(bs, (now_us() - t0) / iters);
        t0 = now_us();
        for (int i = 0; i < iters; ++i) { hjob->rows = i & 7; hjob->nc = i & 15; q.ext_oneapi_graph(eg).wait(); }
        bg = std::min(bg, (now_us() - t0) / iters);
    }
    printf("\nus per decode-shaped forward (H2D job block + 3 kernels + wait), min of 3:\n");
    printf("  submits : %7.2f\n  graph   : %7.2f  (%.2fx)\n", bs, bg, bs / bg);
    sycl::free(hjob, q); sycl::free(djob, q); sycl::free(out, q);
    return 0;
}