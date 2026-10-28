# B70 lessons — mistakes made once, so they are not made twice

Everything here was hit in this repository while probing, and every claim is backed by an
experiment in this directory. Ordered by how much time each one cost.

## 1. `.wait()` is not a completion mechanism, it is a 24 µs tax

`sycl::event::wait()` / `sycl::queue::wait()` on this stack cost **~24 µs** even for an empty
kernel. Measured on the same work: submitting a kernel whose only job is to write a flag in
page-locked host memory, and spinning on that flag host-side, completes in **5.0–6.3 µs**. The
first version of `probe_transport.cpp` timed *everything* with `.wait()`, so every copy and every
launch looked like a 24 µs operation and the whole "resident kernel" idea looked like it was worth
8×. It is worth ~2×, and only for the handshake.

Rule: the hot path never calls `.wait()`. Completion is a flag in pinned memory that the parent's
CUDA stream waits on with `cuStreamWaitValue32` (the existing protocol), or that the B70 engine
thread spins on. `.wait()` is for setup and teardown only.

## 2. A parked kernel does not see host writes unless you fence it

`volatile` on the host pointer is *not* enough. A loop reading a host-pinned word from a resident
kernel returns the value it cached on entry, forever — no error, no progress, the host just waits.
It cost a full debugging cycle to find, because the symptom (kernel runs, host writes, nothing
happens) looks like a submission problem.

```c++
uint32_t cur = *(volatile uint32_t *) db;                                  // may be stale
sycl::atomic_fence(sycl::memory_order::acq_rel, sycl::memory_scope::system);   // this is what works
```

`probe_resident.cpp` prints an entry/heartbeat marker precisely so "never started" and "started but
cannot see the doorbell" are distinguishable. Keep that pattern in any B70 test.

## 3. Divergent polling lanes in one work-group do not work; keep control flow uniform

On Xe a work-group is executed as SIMD lanes of one hardware thread. The first resident kernel
branched (`if (local_id == 0) poll_and_ack(); else spin_elsewhere();`) and never completed a round
trip, in every configuration, including 1 group of 32 lanes. The corrected shape:

* every lane runs the same loop;
* lane 0 performs the host read (`sl == 0 ? *db : 0`), the value is broadcast with
  `sycl::select_from_group(sg, cur, 0)`;
* work is spread across the sub-group by striding on the local id, never chained in one lane.

Related: `fetch_add` on a host flag must be issued at a **uniform call site**
(`aack.fetch_add(sl == 0 ? 1u : 0u)`) — the same divergence rule applies to cross-device atomics.

## 4. A system-scope `sycl::atomic_ref` on *foreign* (registered) host memory faults the queue

`sycl::malloc_host` memory and memory brought in with
`sycl::ext::oneapi::experimental::register_host_memory` are **not** equivalent. Publishing the
`done` flag with `atomic_ref<uint32_t, ..., memory_scope::system>::store()` on a registered
CUDA-pinned pointer took a device fault: `wait()` returned success, nothing had been written, and
the queue was poisoned so the *next* unrelated kernel also silently wrote nothing (which is how
test A4b failed until the cause was fixed in A3a).

Publishing a flag with `sycl::atomic_fence(acq_rel, system)` + a plain volatile store works, and
the 3090's `cuStreamWaitValue32` retires on it (`probe_cross.py` A3a/A3b). Use that. Re-test the
atomic version before relying on it, and always assert that the *payload* landed, not just the
flag, so a poisoned queue cannot masquerade as a passing test.

## 5. `register_host_memory` requires a whole number of host pages

`register_host_memory: size must be a multiple of the host page size` — and the pointer must have
that much memory mapped behind it, so round the length up **and** give the region slack. The
parent's handoff segment is page-backed, so this only affects ad-hoc tests.

## 6. Only one lane per group may poll across PCIe

With 32 work-groups × 32 lanes all polling the doorbell, a round trip took over 2 s (the probe's
timeout) — ~1k concurrent PCIe read transactions starve the link that carries the payload. One
polling lane per sub-group plus a small backoff (a few hundred dependent FMAs, ~0.5 µs) is both
correct and fast (3.2 µs round trip).

## 7. Kernel *loads* from host memory are latency-bound; kernel *stores* are not

Dependent chain: 4096 sequential 32-bit reads from host memory by one lane = **258–283 µs**
(~65 ns each, ~0.06 GB/s). Spread over 4096 lanes, a 16 KiB read+write pass costs ~2–5 µs of
actual traffic. Stores to host memory are posted and effectively free at these sizes.

Consequence: **push the payload in with the copy engine (DMA), let the kernel write results back
zero-copy.** Do not design a kernel that "reads x straight out of the pinned slot" the way the CUDA
issue kernel does — the 3090 can do that at 3.9 µs, the B70 cannot.

## 8. `cudaHostRegister` refuses memory the xe driver pinned

`sycl::malloc_host` → `cudaHostRegister` fails with `invalid argument`. The other direction works
(torch `pin_memory` → `register_host_memory` → B70 kernel reads/writes it, 3090 still DMAs it).
So the **parent keeps owning and registering the handoff region**; the B70 side attaches. Do not
plan a design where the B70 allocates the shared control block.

## 9. `sysfs` PCIe link state is useless on this box

`/sys/bus/pci/devices/0000:0f:00.0/{current,max}_link_{speed,width}` reads `2.5 GT/s` × `1`
both idle and while pulling 14.4 GB/s. The switch upstream port claims Gen5 ×16, the downstream
port claims Gen1 ×1. Measure bandwidth; never infer topology from sysfs here. (`notes/bench_link.py`
style probing is the only trustworthy source, for either card.)

## 10. `sycl::ext::oneapi::experimental::clock<clock_scope::device>` is not available

Submitting a kernel that uses it fails at launch with `Required aspect ext_oneapi_clock_device is
not supported on the device`. Bounded loops in tests must use spin budgets, not a GPU clock. Same
for `aspect::ext_intel_matrix` (the Intel-specific `joint_matrix` extras in
`doc/b70/sycl/doc/extensions/experimental/sycl_ext_matrix/`): the *documented* extension is newer
than the installed 2026.2 runtime headers, so check `__has_include` and fall back to plain
`joint_matrix` / ESIMD `xmx::dpas`.

## 11. Power baselines need the context to exist

`energy1_input` (µJ, label `card`) says 14.6 W with nothing loaded, 45.6 W with an idle-but-live
SYCL context. Utilisation figures for the port must therefore be differenced against *the same
process with the engine parked*, not against a cold card, or the resident kernel appears to cost
30 W of "utilisation" it does not have.

## 12. Never `memset`/dereference a `sycl::malloc_device` pointer from the host

Plain segfault (this config does not give the host a mapping for device allocations), which killed
two early probe runs at the first large copy. Use `queue::memset`/`memcpy`.

## 13. Toolchain notes

* `icpx -fsycl` compiles a probe in ~3 s and needs `source /opt/intel/oneapi/setvars.sh` also at
  *run* time (`libsycl.so.9` is not in the default loader path) — so a Python-driven test must be
  launched from a shell where both `setvars.sh` and `notes/env.sh` were sourced.
* `queue::flush()` does not exist in this SYCL 2020 implementation; `queue::ext_oneapi_submit_barrier()`
  is the "submit without waiting" call.
* `sycl::queue q(ctx, dev, sycl::property::queue::in_order{})` for anything that must be ordered
  (payload → flag). An out-of-order queue relies on USM-dependency inference, which does not see
  anything through a raw host pointer.
* `nd_range<1>` takes `(range<1>, range<1>)`, not two braced lists of different rank.
