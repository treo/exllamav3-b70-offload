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

## 4. A `sycl::atomic_ref` on *foreign* (registered) host memory takes the device down

Any scope. `probe_stores.cpp` used `atomic_ref<uint32_t, relaxed, memory_scope::device>` on a
`register_host_memory` pointer and the next call returned
`level_zero backend failed with error: 20 (UR_RESULT_ERROR_DEVICE_LOST)` — the *device* was lost, not
just the queue. With `memory_scope::system` the same mistake was quieter: `wait()` returned success,
nothing had been written, and the poisoned queue made the *next*, unrelated kernel also silently
write nothing (that is how test A4b failed until the cause, three tests earlier, was fixed).

Publish flags with `sycl::atomic_fence(acq_rel, system)` + a plain volatile store instead: that is
measured to work, in-process and cross-process, and the 3090's `cuStreamWaitValue32` retires on it
(`probe_cross.py` A3a/A3b, `probe_crossproc.py` X1/X3). Plain kernel stores into the same region are
also fine and reliably visible — 100 repetitions across five patterns, cold and host-dirtied lines,
with and without a following fence, registering 5 pages or 4 MiB, and before or after
`unregister_host_memory` (`probe_stores2.cpp`, `probe_unreg.cpp`).

Corollary for every B70 test: **assert that the payload landed, never only the flag.** A test that
checks a flag and a return code passes happily while 16 KiB of results are missing.

## 4a. Kernel index arithmetic (the expensive one): spell `i[0]` out, or the kernel silently writes nothing

The single most expensive bug in this directory. This compiles, runs, returns success, and does not
write anything:

```c++
uint32_t *p = (uint32_t *) ptr;
g_q->parallel_for(n_words, [=](sycl::id<1> i) { p[i] = 0xC0FFEE00u + i; });   // payload stays ZERO
g_q->single_task([=] { ...fence...; *(volatile uint32_t *) (p + n_words) = seq; });  // this lands
```

`sycl::id<1>` has an implicit conversion to `size_t`, so the expression type-checks; the kernel is
accepted by the compiler, submitted, completes without error, the *neighbouring* word written by the
next command is visible to the host, and the payload itself is never stored. Writing it the
explicit way

```c++
g_q->parallel_for(n_words, [=](sycl::id<1> i) { p[i[0]] = 0xC0FFEE00u + uint32_t(i[0]); });
```

stores every word, first time, in every memory type tried. The `+=` (read-modify-write) form of the
sloppy expression happened to work, which is what made it take so long to find: the first probe that
looked correct (A1) masked the pattern that did not (A3a), and the failure then looked like a PCIe
coherency problem, sending two full probe rewrites down that path (`probe_coherency.cpp` is kept as
the artefact that *disproved* the coherency theory).

Rules adopted: index with `i[0]` / `it.get_global_id(0)` and cast to the value type explicitly; never
mix `sycl::id` into arithmetic; and give every kernel test a "wrote it, read it back, compared every
word" assertion.

Related: `sycl::malloc_host` memory (allocated by the xe driver) and memory brought in with
`register_host_memory` are *not* equivalent: the former accepts atomics, the latter does not, and
only the former is refused by `cudaHostRegister` (item 8). Nothing in the design should depend on
either being interchangeable.

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

Submitting a kernel that uses it fails at launch with
`Required aspect ext_oneapi_clock_device is not supported on the device`. Bounded loops in tests must
use spin budgets, not a GPU clock. Same
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

## 14. Repo hygiene, learned the hard way twice in one day

* **Never delete with a glob.** `rm -f probe_*[!.c]*` — intended to remove probe *binaries* — matched
  and destroyed all ten `.cpp`/`.py` sources. They came back only because every step had been
  committed minutes earlier. List the files, or `git clean -nd` first and read the output, or delete
  by exact name.
* **Verify an edit by reading the file, not the tool's echo.** Several multi-line replacements here
  looked right in review and were wrong on disk: a table row that gained a column and lost its
  neighbours, a sentence spliced mid-clause, a claim of "11/11" for a probe that prints "10/10".
  For prose and tables especially, re-read the region after editing it.
* **Commit before and after a bulk edit**, so a mistake is one `git checkout --` away rather than a
  rewrite from memory.
* **Never report a number a tool did not print.** I described the output of `plan_placement.py` —
  including "h = 99.7 %" and a capacity sweep — in prose before the script had ever run; it had a
  syntax error and a dict-unpacking bug, and every one of those figures was invented. The real run
  produced different, less convenient numbers (GLM `h` = 70.8 %, not 99.7 %). Nothing in these notes
  or in `doc/port/` may cite a measurement that is not in an `out_*.txt` next to the script that made
  it, and claims quoted in conversation must come from a finished command's output, not from an
  expectation about what it would say. This is the same failure as believing a 1580 GB/s read rate
  because it was the number the design wanted.

## 15. Bandwidth microbenchmarks lie in four specific ways

`probe_rates.cpp` reported 1580 GB/s, then 1227, then 567, then 286 GB/s for essentially the same
reads against a 608 GB/s card. Each regression was a real defect, and each one flattered or punished
the design in a different direction:

1. **Item→address mapping local to a wave.** Assigning items to tiles linearly put a wave's working
   set inside the 18 MiB L2 and returned cache bandwidth. Fix: scramble the mapping, and check that
   the *touched footprint* is orders of magnitude above cache size, not just the allocation.
2. **Counted bytes ≠ read bytes.** An item that was credited 16 tiles but read 1/8 of them inflated
   the rate ~30×. Fix: assert exact cover (every tile touched once, none out of range) *before*
   timing, and print it. `probe_rates` now does this and prints `[exact cover]`.
3. **Unconsumed loads.** Guarding the sink with `if (acc == MAGIC)` lets the compiler keep the
   arithmetic and drop the loads, or drop everything. Fix: an unconditional store into a small sink,
   plus a host-side check that the sink is non-zero ("MEASUREMENT VOID" otherwise).
4. **Shared kernel bodies across measured variants.** One kernel with `if (mode == …)` made every
   variant carry every other variant's code: the pure-read mode measured 286 GB/s specialised-
   away-into-itself and 567 GB/s when the branch was `if constexpr`. A microbenchmark whose
   instrumentation changes the result is worse than no measurement, because it looks like data.
   Fix: template on the variant, one instantiation per measured configuration.

Then, and only then, the numbers stabilised across modes and repetitions - and the surviving result
(locality worth 1.03–1.71×, layout worth nothing, arithmetic worth 1–4 %) reversed two conclusions
the earlier, smoother-looking numbers had supported.

## 16. A proxy metric must be the same *kind* of quantity as the thing it proxies

Needing a churn number for the migration policy and having only cumulative expert-count profiles, I
tried two proxies and both produced confident, useless figures:

* comparing the top-N **sets of counts** between groups of layers reported "92 % overlap". The sets
  were of *values*, and decayed counts repeat (many experts share 16.046875), so the intersection
  measured value collisions, not whether the same experts were hot.
* splitting one layer's array in half reported "100 % overlap". That partitions experts by index: a
  spatial split of a static snapshot, with no time in it at all, and the same value-collision artifact
  on top.

Both were rejected before reaching the plan, and the honest state is now written where the number is
used (`doc/port/b70-architecture.md` §4a: churn unmeasured, break-even ~0.7 %/token, E11 must produce
it from two snapshots or per-window counters). The lesson generalises to every statistic scraped from
someone else's artifact: ask what the *identity* of the compared objects is, and whether the artifact
has the axis (here, time) the question needs. A decayed cumulative count cannot answer "how fast does
the set change", no matter how neatly the numbers line up.
