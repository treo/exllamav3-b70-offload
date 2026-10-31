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
(locality worth up to ~1.7–2.0×, layout worth nothing reliable, arithmetic worth a few percent)
reversed two conclusions the earlier, smoother-looking numbers had supported.

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
used (`doc/port/b70-architecture.md` §4a: churn unmeasured, the two thresholds coinciding at
~0.3 %/token, E11 to produce it from two snapshots or per-window counters). The lesson generalises to
every statistic scraped from someone else's artifact: ask what the *identity* of the compared objects
is, and whether the artifact has the axis (here, time) the question needs. A decayed cumulative count
cannot answer "how fast does the set change", no matter how neatly the numbers line up.

## 17. An absolute microbenchmark rate is not a constant; sweep the working set before quoting one
`probe_rates` measured the *same* kernel on the *same* geometry at six working-set sizes and returned
132–292 GB/s (Qwen3.8) and 132–260 GB/s (GLM) — a ~2× swing, non-monotonic, with no clean relation to
grid size (128 MiB: 104,800 items at 200 GB/s; 64 MiB: half the items at 292). The first version of
the design docs quoted "287–313 GB/s" as if it were a property of the card, when it was a property of
the card *plus* a 1536 MiB footprint I had not thought about.

Three rules came out of it:

* **Quote rates as a bracket with the footprint attached**, and take design numbers from the regime
  the real workload sits in, not from wherever the probe happened to land.
* **Ratios between modes survive; absolutes do not.** Across three independent runs, absolute rates
  repeat to 0.1–2.4 % but every mode-ratio repeats to ≤3 %, and the ratios are what the design
  conclusions rest on.
* **Check that the effect you are measuring is bigger than the instrument's variance.** Banded-vs-
  native came out at 0.96–1.05× while footprint noise alone is ~2×, so the correct claim is "no
  reliable gain", not "worth nothing". Overstating a null is the mirror image of overstating a win.

## 18. An unrecognised flag is parsed as data

`./probe_rates --quick` did not select a quick mode (there is none): `atoi("--quick")` is 0, which is
a valid shape index, so the probe silently measured *one* geometry while I believed I had a sweep. It
surfaced only because the output had one block where three were expected. The probe now rejects
arguments that are not a shape index and prints the shape table. Generalise: any tool whose arguments
are integers must validate them, because the failure mode is a plausible result, not an error.

## 19. Match the measurement's condition to the workload's operating point (`topk`, batch, `h` — not the checkpoint)

Every decode estimate in the plan was built by asking "what GB/s does the card sustain?" and multiplying.
The question that decides the answer was never asked: **what is the working set of the thing being timed?**
Per token only `topk` of E experts fire, so one MoE layer reads `topk × expert_bytes`, times the fraction
`h` this card owns — **14.3 MiB** for Qwen3.8 at b=1, **50.9 MiB** for GLM. That is 2 orders of magnitude
below the 1–2 GiB sweeps the rates came from, and since the measured curve moves ~2× over exactly that
range, the old numbers were not conservative or optimistic in a predictable direction: they were sampled
at the wrong x. Recomputed at matched footprints, Qwen3.8 gets *better* (51 µs/layer, not 55–95) and GLM
gets much *worse* (405 µs/layer, not 278–548), which flips the practical recommendation for the model
that matters most.

Three siblings of the same mistake, all found only after writing the first version down:

* **`topk` was guessed.** Qwen3.8 is 10, GLM is 8; the script had 8 for both because the number came from
  my memory of `doc/prep` instead of from `config.json`. Now read from the checkpoint.
* **Batch was treated as a constant.** Distinct experts per layer grow almost linearly with rows (10 → 39
  → 73 for Qwen3.8 at b = 1 → 4 → 8), so offloaded work scales ~9× while the parent's window — bound by
  weight reads at b=1 — barely moves. "The offload hides at decode" is a b≤4 statement dressed as a
  general one.
* **Parallel workers were summed.** The homes compute concurrently, so per-layer latency is
  `max(T_parent, T_b70/N, T_cpu)`; adding worker ms/token (17.0 + 19.6 ms for GLM) implies 27 tok/s when
  the max-based figure is 51 with one card and 79 with two — and shows that a third card buys exactly
  nothing. Every capacity recommendation must be built on the max, or it argues for hardware that cannot
  help.

The general rule these probes should have enforced on themselves: before multiplying a measured rate by a
quantity, verify that the measurement was taken *at that quantity*.

## 20. A proxy that omits the operation under study cannot bound its cost

For most of this design's life, "decode is bandwidth-bound, arithmetic costs 1–4 % of bandwidth, the
int8 dot's instruction count does not matter" was a *measured* conclusion. It rested on `probe_rates`,
which walked the real trellis bytes at ~1 lane-op per weight and varied an artificial arithmetic density
on top. Then `probe_gemv` ran the actual operation — checkpoint trellis bytes, the `moe_mul1.h` identity,
output bit-exact against `tests/testlib/trellis.py` — and returned **27.9 GB/s**, then 61.4 GB/s after
adopting the byte-sum dot, against 292 GB/s for the bare stream. An instruction-count model (256 EU ×
2.8 GHz × 2 slots) predicts 31.6 and 67.2 GB/s from the two kernels' op counts, so the card was never the
question; the proxy was.

What went wrong is general and worth naming precisely: the proxy varied *a* cost, not *the* cost. Ten
extract-mul-dot triples per word is a plausible density, but the real inner loop's expense lives in
where the window comes from (ring address math, 64-bit shifts, wraparound) and how the accumulate happens
(byte-sum then multiply then add, per row). By generating windows from a synthetic pattern and summing
bytes by hand, the proxy measured an implementation nobody would ship, in a direction that flattered the
conclusion. The behavioural closure of the `dot_acc` question was the same error wearing a gate's clothes.

Three rules:

* **If the claim is about cost X, the measurement must contain X.** "Arithmetic costs 1–4 %" requires a
  kernel that does the arithmetic the real kernel does — same data, same inner loop, verified output.
* **Read the shipped implementations first.** CUDA (`exl3_gemv_int8_kernel.cuh`: two loads per 4–8
  windows, `fshift` per window, `dp4a_us(prod, splat(a), acc)` per weight-row) and the CPU VNNI path both
  contained the answer before I wrote 300 lines of plausible kernel. The e2e/SYCL test suites are the same
  kind of free evidence for the target ISA.
* **Check that the measurement and a first-principles budget agree.** Mine agreed only *after* the real
  kernel existed — and the model's agreement at both 17 and 8 ops/weight is what tells me 61 GB/s is an
  instruction problem rather than a fluke or a bandwidth wall. A microbenchmark with no such cross-check
  is a story, not a measurement.

## 21. A rate above the card's copy peak is a bug report, and a 100 % hit rate can be dust

Two catches from scaling the analysis to the higher-quant Qwen3.8 recipes, both of which would have
passed silently into the design:

* The K = 6 shape at a 64 MiB working set reported **754 GB/s** — above the 674 GB/s measured device-copy
  peak and above the 608 GB/s spec. Nothing else was wrong: the cover check passed, the sink moved. It is
  simply an impossible number, so the row is dropped from `BANDS["K6.0"]` with the reason written down
  rather than averaged in. Every bandwidth table should carry its physical ceiling next to it, because the
  failure mode of a cache/TLB artifact is a *better* result, which nobody questions.
* `h` came out exactly **100.0 %** for the 5.05 bpw recipe, which cannot be true when the two device
  slices hold 353 of 512 experts. The profiles are decayed cumulatives, and the ~250 experts that never
  fire carry counts around 1e-27, so pick mass rounds to 1.0 — the same dust already documented as "`h`
  is an upper bound", but here it silently flipped a *policy* conclusion (no residue ⇒ balance; real
  residue ⇒ hottest-first). The tool now prints the count of live experts next to every `h`
  (`100 %/258L`), which makes the two cases distinguishable at a glance.

The general shape of both: a metric that saturates at a bound (peak bandwidth, probability 1) is not
informative near that bound, and the fix is to print the underlying count alongside it, not to trust the
normalised value.

Same class, found the same week in `plan_concurrency.py`: the state helper returns KV **per token summed
over all attention layers**, and using it as a per-layer figure inflated the parent's KV term 48-fold,
which made the parent look like it needed 29 ms/layer at 256 rows and dominated every conclusion. The
assertion that caught nothing was `fixed > 0` after calibrating to the measured T_layer — the model can
be internally consistent and still be reading a summed quantity as a per-layer one. When a term dwarfs
the others by roughly a factor equal to a layer or head count, check which axis it was summed over.

## 22. "The device is busy" is two different claims; conflating them gave the 3090 an 8× too small expert slice

Asked how the 3090's non-expert work affects placement, the intuitive answer is "little VRAM and little
bandwidth left, so few experts, and they had better be cheap to reach". Neither half survived the byte
bills:

* **Capacity** — the scary number was Qwen3.8's **49.91 GiB of per-layer n-gram embeddings**, which
  would leave no room at all. They are never resident: `modules/row_table.py` row-gathers them from
  host/disk (`ngram_gather_cpu`). Table bytes are capacity on disk, not on the card, and a handful of
  rows is the only traffic. What must actually be resident is 4.05 GiB of streamed weights plus 24
  KiB/token of KV (12 of 48 layers are full attention, at 2 KV heads) plus a 108 MiB-per-sequence linear
  state. Free for experts: **~16.6 GiB**, not the 2 GiB the plan had been using — worth `h` 97.6 → 100 %
  on Qwen3.8 and 70.8 → 81.1 % on GLM, a bigger effect than every ordering rule combined.
* **Traffic** — the same bill says the parent streams 86.4 MiB/layer = 97 µs of a 250 µs window, so at
  b=1 the 3090 is ~39 % bandwidth-duty: latency-bound, with bandwidth to spare. "Busy" and "full" are
  unrelated here.

The trap generalises: when reasoning about a memory hierarchy, ask **separately** whether a byte range
must be resident and whether it is read per token. Big lookup tables (n-gram, embeddings, codebooks,
MoE router caches) break the intuition that resident bytes ≈ streamed bytes, and either equality assumed
as the other produces confident, wrong capacity plans.

## 23. If an analysis tool reports "no difference" everywhere, debug the tool before believing the finding

The first version of `plan_parent_budget.py` printed `tie` for all 54 placement comparisons. The
plausible reading was "placement order does not matter", which is the kind of conclusion that gets
written into a design and never revisited. The actual cause was a `*1000` slip in the MiB@GB/s→µs
helper, which shrank every worker term ~1000× so that `max(parent, b70, cpu)` was always the parent.
The tell was structural, not numerical: **the choice of `S_g` slots changed nothing**, and a model whose
input cannot affect its output is a broken model, not a null result.

Two habits came out of it: the tool now runs a `selftest()` asserting five known conversions
(106 MiB @ 292 GB/s = 380 µs, etc.) before printing anything — ten lines that would have caught this on
the first run — and any sweep where a varied parameter has zero effect is treated as a bug report on the
script, not as a finding about the system. After the fix the same code shows 13 % gaps in one direction
and 20 % in the other, which is a far more interesting and far more believable answer.

## 24. The vendor's own kernels are documentation — and two more Xe2 hazards they recorded

`doc/b70/llm-scaler/` (Intel's XPU serving stacks with hand-written ESIMD MoE kernels) was in the repo
the whole time. Reading it after writing `probe_gemv` would have been the cheap order. It supplied, with
numbers: the ~180 GB/s realistic ceiling for a mature MoE GEMV, the "this kernel is ALU bound, not
bandwidth bound" diagnosis that independently confirms our measurement, the LSC-granularity/flat-
accumulator rules, GRF-bounded row tiling ("M=8/VL=256 is what the AOT gen compiler refuses to lower"),
and the fact that their decode GEMVs are per-route rather than dedupped by expert — which our byte model
silently assumed we would do.

Two hazards they documented that we would have hit anyway:

* **Cross-subgroup SLM needs a real barrier, not a named one.** "A named barrier only orders execution,
  it does not make the SLM stores visible to the other subgroups, so the split arrive/wait form leaves the
  exchange racy; `barrier()` carries the required memory fence." Our work-groups are 64 items = two
  subgroups sharing a staged buffer, so this is exactly the shape that breaks. Same family as `LESSONS` 2
  and 4: on this stack, ordering and visibility are separate API promises and it is easy to get one
  without the other.
* **An out-of-bounds device *read* presents as `UR_RESULT_ERROR_DEVICE_LOST`.** They traced a device loss
  to unclamped tail-index addressing in a paged read, after the arithmetic had already masked the values
  as numerically inert. So "the results are wrong" is not the symptom to watch for — the device vanishes.
  Any kernel with a partial tail iteration must clamp addressing even where the data is discarded, and
  that belongs in the kernel test suite next to `LESSONS` 4a's payload assertions.

The general lesson: before treating a platform question as open, check whether a mature kernel for the
same hardware generation is sitting in the tree. A comment that says "the original reached ~180 GB/s and
here is why" is worth more than a fresh microbenchmark of my own guess.

The second pass over the same tree was more productive than the first, for a methodological reason: the
first harvest was organised **by file** (what do their MoE kernels do), and produced a list of techniques
I then had to find problems for. The second was organised **by our own measured weakness** — the rows
collapse, the `tn`=32 worst case, the three-launch layer, the hand-fit launch policy — and grepping for
whoever else had hit *that* turned up M-tiled DPAS with the weight dequant amortised across 16 tokens, an
explicit 8192-work-item fill target with a granularity-halving picker, and a measured ~48 µs host cost per
enqueue. Two extras worth keeping from that pass: record the things you look at and **reject** (their
table-driven 3-bit decode, three streams plus a lookup table, loses to our single-ring arithmetic
byte-sum), because an unrecorded rejection gets re-evaluated next month; and check whether their numbers
are expressed in the same *unit* as yours — their split-K thresholds key on work-items, ours on
work-groups of 32 lanes, which is why their "N ≤ 512 → ks=4" looked to contradict our measurement of ks=1
winning at 400 groups when in fact we have 12,800 lanes.

## 25. Silent, deterministic wrongness on Xe2: sub-group width and `dot_acc` signedness

Getting rev C of `probe_gemv` to bit-exactness took three rounds, and each wrong answer looked like a
result:

* **16-lane sub-groups.** The device reports both 16 and 32 and the compiler picks. A 32-lane butterfly
  (`shift_group_right` by 8 then 16) across a 32-item work-group is therefore two independent 16-lane
  exchanges, and each lane happily returns a sum of the wrong set. Deterministic, reproducible,
  mapping-dependent — it looked like an indexing bug in the tile loop, and nearly got "fixed" there.
  Rule: if a reduction crosses lanes, either force the sub-group size or do the exchange through SLM
  with a full `group_barrier`. The SLM form costs nothing here (4 × 16 × M int32) and is width-agnostic.
* **`dot_acc` overload signedness.** `dot_acc(uint32, uint32, int32)` is unsigned×unsigned; `dp4a_us`'s
  equivalent is `dot_acc(uint32, int32, int32)`. Writing `(uint32_t)sp` on a signed activation splat
  compiles, runs, and turns −1 into 255. Only a bit-exact reference catches this, which is the argument
  for Gate A being bit-exact rather than tolerance-based.
* **A fixture proves only what it covers.** The byte-sum fixture was wired to expert 0 / tile 0, so it
  validated window extraction and position mapping but *nothing about tile striding* — and it passed
  while the kernel was still wrong. After it matched exactly I kept hunting in the mapping, which was
  already proven, instead of in the parts the fixture had not touched. A fixture must be chosen for the
  claim it is supporting; "the extractor is right" and "the accumulator sees the right bytes" are
  different claims needing different probes.

The diagnosis that finally worked was arithmetic on the *shape* of the error: mismatches were non-zero
in all 640 columns but their difference was near-constant (−491,786 vs the predicted −510·Σx8 =
−491,130), which says a term independent of the output column is doubled — i.e. the mul1 bias, not the
unpacking. Constant offsets across a reduction axis are a fingerprint worth checking for before reading
code.

And the finding that outranks all three: **measure at the operating shape.** Every rev B/C rate quoted
above E=512 hid the fact that b=1 decode touches ~10 experts and runs 3.5× slower there (17 vs 61 GB/s)
for reasons unrelated to arithmetic. See `b70-kernels.md` §2b item 9.

## 26. Validate the oracle against the *known-good* implementation first

Chasing rev C's numerics cost seven experiments; two of them would have been unnecessary if I had ordered
the work differently.

The oracle — an einsum reconstruction of the accumulator from `tests/testlib/trellis.py` — was only
compared against rev B at the very end. That one check (median 0, sd 0 against rev B) instantly proved
the oracle sound and the deficit real, and moved the search inside rev C's kernel. Had it been experiment
number one instead of number six, four of the intervening probes (fixture store, dot_acc chaining form,
SLM zero-init, signed/unsigned reinterpretation) would have been skipped or reframed.

The second ordering mistake was naming the bug too early. The per-column difference looked near-constant
(−491,786 vs a predicted −510·Σx8 = −491,130, 1.4 % apart), so I wrote "the bias term is folded in twice"
in three places. Then the per-row numbers came in: the deficit was ≈ −4.94e5 for all four rows while
510·Σx8 across those rows was −995k, −761k, **+1,951k**, +119k — including a sign flip. A doubled bias
cannot do that. The label was wrong for most of the hunt, and it shaped the probes I chose.

What actually held up:

* The shape-asserted three-way diff (PART vs oracle vs rev B) is the instrument that produced real
  information: rev C's raw accumulators are short by a deterministic, essentially input-independent
  ≈ 494k per element, so the epilogue and `combine` are exonerated and the byte-sum fixture is not lying.
* Exonerations are worth recording even when they don't advance the diagnosis — they stop the next person
  re-running them.
* Two of the oracle scripts silently broadcast (one reported more mismatches than there were columns).
  `assert a.shape == b.shape` before any diff statistic; a numpy broadcast produces a number, not an error.

State left behind: rev C is marked PROVISIONAL in source, artifact and docs; its rates are not quoted as
results; rev B remains bit-exact and is what every number in the design rests on. Next step is a
constructive bisect — make the kernel process exactly one tile per group and diff against a one-tile
oracle, which partitions "which windows reach the accumulator" from "how they are summed".

## 27. When a model and a measurement disagree by 30×, check the model's units first

Trying to sanity-check "dense unpack arithmetic costs 1–4 % of bandwidth", I computed an ALU duty
cycle of 0.4 % from the measured rate and concluded the measurement must be wrong — the numbers seemed
to imply the loop could not be anything but bandwidth-bound, with absurd headroom. The error: I divided
lane-operations by lanes as if a SIMD instruction moved 4 B, when one 32-lane `u32` instruction covers
128 B of stream, so the real figure was ~13 % of two issue slots, and the 1–4 % cost was perfectly
consistent. The corrected model is still not the evidence — the *measured difference* between two
kernels is — but the episode is why every arithmetic claim in `doc/port` is now expressed as
"R6 minus R2 measured −4.4 % / −0.1 %" rather than as an instruction-count argument.

Related, and the reason R9 exists: it would have been easy to explain the residual density cost as
accumulator dependency latency. Adding 8 independent accumulator chains made it 1.2–1.4 % *worse*, so
that explanation is wrong and the cost tracks instruction count and register pressure instead. A
plausible mechanism invented for a number is worth nothing until something can vary it.

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

## 28. Low variance does not mean input-independent, and synthetic inputs are the cheapest bisect

The rev C numerics bug was one line: `(int8_t)x * 0x01010101` to splat an activation byte, which for
negative `x` yields bytes `(x, x−1, x−1, x−1)` because the two's-complement negate borrows from the upper
three bytes. It survived eight rounds of analysis. Two things about how it resisted are worth writing
 down.

**I made a correct variance argument and drew the wrong conclusion from it.** The deficit had sd 10.5k on
a mean of 494k (2 %), and I argued — correctly — that a single misplaced weight contributes ~37k of
scatter, so no weight×activation routing error could produce it, therefore "a constant is being
injected". But the deficit was Σ_{k : x_k<0} 0.75·bytesum_k: a sum over ~1280 terms of a quantity that
does not depend on the *activations* at all, only on how many of them are negative. Sums over many terms
self-average, so a purely data-driven bug can look like a constant. "The scatter is too small for a data
bug" is only valid for bugs that touch few terms — I should have asked what the *number of terms* was
before concluding anything.

**Synthetic inputs were available the whole time and I tried them eighth.** Overwriting the activations
with all-zeros, then all-ones, costs two runs and cleanly separates weight-side from activation-side
faults: both were bit-exact, which localised the bug to negative `x` immediately — whereas the eight
analysis rounds I actually ran (fixture store, dot_acc chaining form, SLM zero-init, subset split,
signed reinterpretation, coverage audit) each consumed a build and produced an exoneration. Any time a
kernel consumes two input tensors, hold one at a constant and at a trivial value before reading code.

**Related, from the same session: your own scaffolding can be the regression.** Two diagnostics were
kept alive after they had answered their question — a cooperative zero of the reduce scratch, and bisect
knobs that turned compile-time loop bounds into runtime variables. Both were numerically inert, and
between them they moved small-shape timings by enough that I "explained" a 2× slowdown with a story that
was wrong (the bounds cost 1.00× at E ≥ 96; the jitter at E=10 did the rest). Delete diagnostic code once
it has reported, and re-measure the headline after deleting it.

**And measure small shapes properly.** At E=10/R=1 the same configuration measured 38.7, 45.7 and 52.5
GB/s in three back-to-back repeats, and rev B's spread at E=10/R=4 was 94 %. A single median there is not
evidence of anything — the "split-K recovers 5×" claim in the previous commit was pure noise and had
already propagated into a design rule. Interleave the configurations within each repetition and compare
minima, the way `probe_rates` already did; spread then drops to ~1 % and the conclusion inverted.

## 29. Two units-and-instrument traps from the cross-model sweep

**Replacing a binary under a running measurement silently corrupts it.** I rebuilt `probe_gemv` (adding a
second timing mode) while `sweep_models.py` was still looping. Every line printed before the rebuild was
latency-mode, every line after it throughput-mode, same column, same units, no error anywhere — a table
of 108 numbers that looked perfectly self-consistent. The only reason I noticed is that the change was
mine and I remembered the run was in flight. From now on: build to a new path and point the driver at it
(`PROBE=/tmp/pg4 …`), or stop the driver first. Related: `pkill -f "sweep_models.py --sweep"` matched the
shell issuing it and killed my own command instead (exit 143) — match a narrower pattern or kill by PID.

**Rates across quantizations must be compared in weights/s, not bytes/s.** With K bits per weight,
GB/s = G-weights/s × K/8, so a 6.05 bpw kernel is *expected* to show ~3× the GB/s of a 2.05 bpw one at
identical efficiency. Pooling all measurements by K, the per-layer times came out flat (229–240 µs over
a 3.0× byte range) while GB/s climbed 53.6 → 154.6 — read in GB/s that looks like higher quantizations
running faster, read in weights/s it says the honest thing: the GEMV is instruction-bound, so the
recipe choice costs VRAM and link bytes and essentially **no decode compute time**, which is a result the
byte-based planner in `plan_quant_scaling.py` would have got backwards. Whenever a metric's denominator
is itself a function of the variable you are sweeping, the metric is not comparable; normalize to the
count of things worked on.

## 30. Scope your absence claims, and check your own artifacts before calling something unprecedented

I wrote "**no int8 DPAS anywhere in the tree**" after grepping `dpas<` under
`doc/b70/llm-scaler` and finding only fp16/bf16/fp8 call sites. That was true of the subtree I searched
and false of the repository. `doc/b70/b70-bench/bench.cpp` — which I had *already cited* in the same
document for its 367 TOPS XMX int8 figure, and whose measured 366.92 TOPS sits in my own §1 table — runs
`run_matrix<int8_t, int32_t, 8, 16, 32>` through `joint_matrix`. Two independent signals that integer
DPAS works on this card, one of them my own measurement, and I connected neither.

The cost was not cosmetic. That claim was load-bearing for a decision: it made "integer DPAS keeps
bit-exactness" sound like an unproven route with no prior art, pushing E24 toward the fp16 path that
forfeits bit-for-bit agreement with the CPU/3090 paths. Once corrected against the actual header
(`xmx/dpas.hpp:243-256`'s static-assert table allows `A,B ∈ ub,b,u4,s4,u2,s2 → C ∈ ud,d`), a better third
route appeared that neither harvest had suggested: feed DPAS the four bytes of `window * MUL1` as four
K-steps against the activation replicated 4× along K, so the weight never needs more than 8 bits, the
accumulator is int32, and Gate A survives untouched.

Three rules out of it:

* **State the scope of an absence claim as the search that produced it** — "no int8 DPAS in
  llm-scaler's ESIMD kernels (`grep -rn 'dpas<' … | grep int8`, one subtree)", not "anywhere in the
  tree". An unscoped negative invites someone to design against it, which is exactly what happened.
* **For capability questions, the authoritative source is the toolchain header, not a sample corpus.**
  The legal (A, B, C) combinations were sitting in a `static_assert` message in an installed header;
  I mined a third-party kernel library for them instead. A corpus tells you what people *do*; a header
  tells you what is *possible* — and novelty usually lives in the gap between them.
* **Re-read your own artifacts before concluding something is unprecedented here.** I had cited a
  measurement of the very capability I declared unavailable, sitting in this project's own reference
  directory. Same failure class as the 150–180 GB/s inheritance: an earlier number, kept in a table,
  unconnected to the inference being drawn next to it.

## 31. Make the expensive part free before you build it; and a signedness trap that is now three-for-three

E24 asks whether XMX DPAS removes the per-row instruction slot from the decode GEMV. The kernel that
would answer it properly needs on-the-fly trellis unpacking *into a matrix operand layout* — the hard
part, and the part llm-scaler explicitly warns about. Instead `probe_dpas.cpp` sidestepped it: A came
from a byte-expanded file written by the reference unpacker, so operand assembly was free by
construction. One file and two dumps later I had the answer (rows curve flat to within 3 % versus rev
C's 6.5× growth), *plus* a result I had not gone looking for — the materialized-byte form spends ~145 µs
streaming A at E=10, which forbids that design in a shipping kernel and tells step 2 exactly which
number to report first. Deliberately idealizing the hard part answers the question *and* bounds what the
hard part is worth; doing it first is cheaper than doing it properly and finding out later.

The signedness bug I hit on the way is now the third instance of the same shape in this project:

1. `dot_acc(prod, (uint32_t)splat, acc)` selected the unsigned×unsigned overload — negative activations
   read as 255 (LESSONS 25).
2. `(int8_t)x * 0x01010101` to splat a byte silently produced `(x, x−1, x−1, x−1)` for x < 0 — the
   two's-complement borrow (LESSONS 28).
3. Here: `joint_matrix<…, uint8_t, use::b, …>` for the *activation* operand. Compiles, runs at full
   speed, and every negative activation becomes 128…255.

The invariant across all three: the API takes the semantics from a **type name I typed**, not from a
value, so there is nothing for the compiler or the runtime to object to. The tell is also the same —
**loss of cancellation**. A dot product of byte-sums (always ≥ 0, mean ~510) against signed activations
is a sum of terms with random signs, so a correct kernel lands around ±5·10^5 while a sign-blind one
runs to the all-same-sign bound (~1.6·10^8 here, a 300× inflation). If a magnitude-identical-looking
result is two orders of magnitude too big, suspect signedness before suspecting indexing.

Which exposes a hole in my own controls: the `GEMV_ZERO_X` / `GEMV_ONE_X` synthetic-activation probes
that nailed bug (2) are **both non-negative**, so they would have passed bug (3) happily. Sign-sensitive
bugs need a sign-carrying control: add `x ≡ −1` (expected accumulator `−Σbytesum + 510·k`, computable in
two lines) alongside the zero and one cases. Cheap controls are only good if they cover the axis the bug
lives on.

## 32. The "obviously right" optimization was 3.4× wrong, and a 2×2 found it in one pass

rev E — the DPAS kernel that assembles its A operand from trellis bytes — was 3.4× slower than it should
have been, and the cause was not in the algorithm. I had staged the assembled tile in **SLM**, because
SLM is fast, sits next to the math unit, and is where every handbook says to stage operands before
feeding a systolic array. On this toolchain `joint_matrix_load` from `local_space` costs roughly ten
times the same load from `global_space`, so the good-habit version was the bad one. Moving the tile to a
1 KB **global** scratch per sub-group — rewritten every tile, so it never leaves L2 and adds no DRAM
traffic — recovered the whole gap and more: 372 → 109 µs.

What made it cheap to find was the design of the probe, not cleverness. Rather than change one thing per
run on a hypothesis (the pattern that burned eight rounds on the rev C numerics), I ran the **2×2** of
{A source} × {B source} in one pass:

    A=SLM     B=SLM      372 us
    A=SLM     B=global   192 us    <- B's source halves it
    A=global  B=SLM      457 us    <- worse than both-SLM: an interaction
    A=global  B=global   109 us    <- and so does A's

Four points separate "which factor matters", "is there an interaction", and "is it the thing I was
already suspicious of" — one-factor-at-a-time cannot do that without assuming the answer, and here it
would have had to explain away global-A making things *worse*.

Two rules. (1) When a design choice feels right because it is a habit, treat it as an unmeasured
variable and price it: this defect lives in the *lowering*, so no amount of reading the algorithm would
have revealed it. (2) Prefer factorial probes when toggling the factors is cheap — both switches existed
already for a different measurement, so the design cost nothing but the runs.

## 33. Check the premise before building the thing, and price a refactor with a deliberately wrong build

E28 was opened as "repack the trellis so a lane's windows are aligned, and see whether it pays for the
loss of byte-interchangeability with the 3090/CPU kernels." A repacker is a day of work plus a format
policy argument. Instead I spent five minutes on arithmetic — and the gate mostly evaporated.

Extraction is cheap when a window group begins on a dword boundary, which asks for `K·i ≡ 16 (mod 32)`
to have a solution. It does, for every K we ship, and the solution's period (8, 16 or 32) divides the
256 windows in a tile, so **aligned groups already exist in the ring as stored**. The improvement is
about which windows a lane is assigned, not how the bytes are laid out — no repack, no extra bytes, and
the E4c interchangeability cost that justified the whole gate was never due.

The other half of the turn was equally cheap: rather than build the aligned kernel to find out if
alignment matters, I built an *idealization* of it — constant shift amounts, no straddle select, numerics
deliberately wrong, timing only (`-DGEMV_CONSTSHIFT`). That gave a ceiling (×1.5–2.1 at rows=1) for a
two-line diff, which is what decided the direction is worth real work at all. The discipline that makes
this safe is labelling: the probe states in its comment and in the artifact that its output is not a rate
and is not bit-exact (and I re-verified non-exactness rather than trusting that it would be wrong),
because a deliberately-wrong fast build is precisely the kind of number that leaks into a plan.

Generalized: a refactor's premise usually contains one factual claim ("the layout is misaligned") and one
value claim ("the gain would be worth the cost"). The factual claim is often checkable in minutes and,
when wrong, saves the whole task; the value claim is checkable with an idealized build before the real
one. Doing either before writing the code is not avoidance — it is the cheapest experiment available.

## 34. Ask what the compiler is being *forced* to treat as runtime

The largest single-frame win of this whole kernel effort cost one `#ifdef` and a four-entry table: making
trellis `K` a compile-time constant took the b=1 decode GEMV from 75.4 µs to 39.7 µs (**×1.90**, 6.58 →
3.47 issue slots per weight), with output **bit-identical** to the previous build and bit-exact against
the reference. Nothing about the algorithm changed.

The reason it was sitting there: the extractor computed its bit offsets as `(K*(8t+1) − 16)`, so every
window needed a variable 64-bit shift plus a select between two overlapping dword pairs. But the offset
is `(K·32·q0 + K·(8a4+1) − 16) & 31`, and `K·32·q0` is a multiple of 32 for *any* integer K — so it
depends only on the unrolled index `a4`. It was lane-invariant all along, and I had spent the previous
hour designing a lane *reassignment* (aligned groups, with a cross-lane accumulator reduce to pay for it)
to obtain a property the existing assignment already had. Two minutes of modular arithmetic, applied to
the *existing* code rather than to a hypothetical one, ended the design debate.

The general shape: performance work clusters at boundaries you did not know were artificial. A value that
is a *format constant* arriving as a *runtime parameter* is one such boundary — the compiler must emit
generic code for it, and every derived offset, stride and trip count inherits that generality. So before
optimizing an inner loop, ask: which of these quantities is actually invariant, at what scope (per
launch? per tile? per lane?), and does the compiler know? Then check whether the invariant is expressible
as a template parameter or a constexpr lookup. The same question applies to `m.K`-style reads in the
engine's kernel selection: dispatch on the format, don't pass it in.

Corollary worth keeping: the idealization probe (`-DGEMV_CONSTSHIFT`, deliberately wrong data, timing
only) said ×1.5–2.1 and the honest build delivered ×1.90. When an idealization and a real attempt agree,
the idealization was measuring something true — and it cost a two-line diff to know that before writing
the kernel I had planned instead.

## 35. A win transfers only if the bottleneck transfers

rev C gained **x1.90** from making trellis K a compile-time constant. The obvious move was to do the same
for rev E, the DPAS kernel that shares that extractor. I built it, isolated the two changes, and measured:
compile-time K alone gave **x0.99–1.01** — nothing — and the lane remap that makes the shifts constant
(rev C's own mapping) made rev E **2.3x slower**. Every variant was bit-exact, so this was a pure
performance refutation of my own prediction, which I had written down as x1.1–1.2 an hour earlier.

The reason is that the two kernels are bound by different things even though they run the same extraction
code. rev C is bound by extraction ALU, so removing shifts and a select removes most of its fixed cost.
rev E is bound by writing the assembled operand: its existing lane map has four lanes writing adjacent
4-byte slots of one column (a tidy 16-byte contiguous run), while rev C's map gives each of eight lanes a
different column 64 bytes apart, turning two store transactions into eight. Optimization gains are not
portable across kernels; only the bottleneck is portable, and I had not measured rev E's.

Two smaller findings from the same run. **Unroll pragmas did nothing** — none / a4 / j / both all landed
within 0.5%, because fixed-trip-count loops are already unrolled. An earlier 2x regression I had blamed
on "missing unroll" was really about *runtime loop bounds*, and I nearly optimized the wrong thing again.
And **reverting is a first-class outcome**: the tree went back to `HEAD`, the restored binary was
re-verified bit-exact, and the negative result is recorded in `out_dpas.txt` with the numbers that killed
it — including the earlier prediction, left in place so the disagreement is visible rather than edited
away.

The productive residue: rev E's lever is now identified by elimination rather than guesswork. The 32
lanes' stores into the operand scratch can be arranged however I like — SLM decouples producer lanes from
fragment mapping — so making them contiguous is a free experiment worth the 25–35% that assembly and
stores account for. Had I not tried the analogy and watched it fail, I would still be optimizing shifts.

## 36. Count work per element of what you are optimizing, not per loop iteration

The dense-store variant was bit-exact, 1.6× slower, and my first note said "store-bound hypothesis
refuted." That would have been a false record. The diff showed the same three `dw[]` loads in both
versions, which is why it looked like a clean single-variable test — but the loads sit *inside* the loop,
and the loop's unit changed. The committed mapping amortizes 3 dword loads over 8 windows; the dense one
loads 3 dwords per window, because the loop now iterates over columns instead of over the j-index that
shares a dword pair:

    committed (t = lane + 16*tt)    6 loads / 16 windows = 0.375 per window
    pair-map (a4 outer)            12 loads / 32 windows = 0.375 per window
    dense (c outer, 1 window)      48 loads / 16 windows = 3.000 per window

An 8× change in load count, invisible in the diff, fully explains the slowdown. Store density was never
measured; the hypothesis is alive, merely untested — and re-examining the geometry suggests it is nearly
closed for other reasons.

Two habits out of this. First, when a refactor changes a loop's *unit*, normalize every resource to the
unit that matters for the claim — here, loads and stores **per window**, not per iteration. The invariant
to check before believing any A/B: for each resource (loads, stores, multiplies, barriers, bytes), does
the total over the whole kernel stay the same in both versions? If not, you measured their difference and
not the thing you changed. Second, when an experiment turns out confounded, the honest label is
"untested," not "refuted" — a wrong negative is worse than a gap, because it closes the line of inquiry.
I caught this only by writing the per-window tallies down after the fact, which is now the first thing I
do for any mapping change.

## 37. Warm the device up, and say which state a number was taken in

Identical command, identical case, five consecutive processes:

    rev E rows=1 KS=8:   242.4  242.5  225.5  106.2  106.2 us

A 2.3× swing that has nothing to do with the code. The device ramps its clocks over the first tens of
seconds of load, so the first processes after idle run slow — and my protocol (min of N *internal*
repetitions, several processes per measurement) averages over states rather than controlling for them.
After a 20 s sustained-load warm-up plus four interleaved rounds, rev E returns to 106.2–106.3 and rev C
to 39.6, matching numbers taken in an entirely different session to ~1%. So warm + interleaved reproduces
across sessions; cold reproduces nothing.

This cost me two readings inside one hour, both published to me and not to the repo: "rev F psu is ×0.64 on
down_proj" (truly ×0.90) and "p and u don't combine" (they do). Both were *sequentially ordered* comparisons,
which is exactly the shape that turns thermal drift into a fake result: whatever runs late in the sequence
looks good. Three rules now: (1) warm up with ~15–20 s of real load before the first timed process; (2)
round-robin every configuration within a measurement, never finish one configuration before starting the
next; (3) print the per-round values alongside the min, so drift is visible in the artifact instead of
hidden by it. `[1 138 138 132]` next to a min of 106 says "this min came from a luckier round", which is
information I need when deciding whether a ×1.05 effect is real.

Absolute magnitudes are only comparable inside one warm window. That is a stricter statement than the
footprint-matching rule (item 19): matching footprint but not thermal state still yields garbage.

## 38. The ISA dump was available all along; I had the wrong variable, and gave up

For most of this project I recorded that "direct ISA inspection remains unavailable", because
`IGC_ShaderDiscoveryEnable=1` and `SYCL_SAVE_TEMPS=1` produced no files. The working combination is

    IGC_ShaderDumpEnable=1 IGC_DumpToCustomDir=$PWD/isa ./probe_dpas3 CASE 1 1 8

which emits 19–34 files including native `*_simd16_entry_*.isaasm`, plus `.spv`, `.dat`, `.progbin`,
`.zeinfo` and the LLVM IR stages. Two lessons, not one. The narrow one: an env-var name I got subtly wrong
(I thought I had tried both spellings) closed off an entire class of evidence for weeks, and I substituted
inference from probe variants — some of which I then got wrong, e.g. the operand-layout mechanism in item
13e/13k, where the ISA would have shown the transform directly. The general one: when a tool "does not
work", the failure to produce output is not evidence about the tool. Before writing "unavailable", look up
the exact spelling and semantics in the vendor docs, and check whether output went somewhere other than
where I was looking — `DumpToCustomDir` defaults are precisely the kind of thing that made my earlier
attempt look empty. Note also what the dump still did *not* settle here: the captured unit was 724
instruction lines with one `send`, so it is not the tile loop, and I declined to read a message census off
it rather than invent one.

## 39. A doubling ablation prices a resource only if the system is linear in that resource

I priced partial-sum traffic by making the kernel write its partials twice into a shadow buffer: same
instructions, same combine, same `y`, so the delta should be "the cost of one copy of the partials." It was
0.7–27.7 µs depending on KS, I halved it for a single copy, added a symmetric read-back, and wrote down
"item 5 is worth 5–11 % on gate_proj, 15–25 % on down_proj." The structural fix then delivered ×1.19–×1.32
and ×1.04–×1.30 — up to three times my estimate.

The ablation was clean as a controlled experiment and still misled, because it isolated the *write* while
the write was not the whole cost of the thing. Removing partials also removes: the combine kernel's read of
them, a second enqueue, the per-slice accumulator bookkeeping that scales with the same KS multiplier, and
the L2 footprint those bytes occupy — which is what made the measured gain grow with batch size, since
smaller partials leave L2 for everything else. Marginal cost of X is not the same quantity as cost of the
subsystem that produces X, and a doubling test can only ever see the first.

So the rule: before turning an ablation delta into a projected win, list every consumer of the resource and
say which ones the ablation touched. Where a coupled consumer exists — here, combine — either ablate the
subsystem (delete both sides) or state the projection as a floor, which is what I should have written
instead of a range that read like a forecast. Practical consequence for how I sequence work: cheap ablations
are for ranking candidates and ruling things out (they killed `f` convincingly), not for deciding whether a
fix is worth building. Item 5 was near the bottom of my list on the ablation's numbers and turned out to be
the largest single win of the rev F line.

## 40. Calibrate an oracle against a known-good case before trusting any negative from it

Asked whether a compile-time single-row DPAS variant was expressible, I wrote a shape probe: build
`joint_matrix` operands for a list of (M, N, K), launch, report supported/unsupported. It came back saying
M=8, N=16, K=8 is not supported on this device - the exact shape `probe_dpas3` runs successfully thousands
of times an hour. Every negative in that table became suspect instantly, and three of them would have
redirected real work: it "proved" M=16 accumulators unusable (the consolidation plan) and N=8 unusable at
any M.

Two flaws, both invisible in the code: it materialized operands with `joint_matrix_fill`, which carries its
own shape restrictions (fixing that changed nothing), and its kernel differed from the real one in some way
I never isolated before the budget ran out. Read as device truth, that table would have killed the M and K
levers on the strength of a harness that could not reproduce a known positive.

The rule costs one line and would have caught it immediately: **put a case you already know passes into
every oracle, and abort if it fails.** For a capability probe, the known-good case is whatever the shipping
configuration does - same shape, same construction, and if the probe rejects it, the probe is the thing
being measured. This is the fourth face of a failure I keep meeting in this project: the broadcasting
oracle, the misordered argv that made correct kernels look wrong, the doubled log line that mislabeled an
ablation, and now the probe that rejected its own ground truth. The fix is always the same - make the
instrument produce the answer you already know before believing one you do not.

Separating what survived: the *in-situ* negative is real. Building rev F itself with `NTOK=8` throws
"joint_matrix with parameters matrix_type::sint32, use::accumulator, Rows=8, Cols=8 is not supported on
this device" from inside the working kernel, identically for every flag combination. The working kernel is
its own oracle; only my standalone generalization died.

The probe file itself was deleted the same day rather than left in the tree with a KNOWN-INVALID banner at
the top, which is a judgement worth naming: a committed instrument that contradicts a working kernel invites
someone later to re-derive a wrong conclusion from it, and a warning comment is weak protection against a
plausible-looking results table further down the same file. What should survive a dead instrument is the
lesson plus whatever facts were independently corroborated - here the K=32 int8 shape comes from
`doc/b70/b70-bench/bench.cpp`, not from my probe, so deleting it cost no evidence.

## 41. Two separate caches can swallow a shader dump, and only one of them is the compiler's

`IGC_ShaderDumpEnable=1 IGC_DumpToCustomDir=<dir>` worked for weeks and then stopped: the same command that
had produced 34 files including native `.asm`/`.isaasm` began returning 4 files with no assembly at all, for
two different binaries, with no change to either. Three wrong theories cost time — the runtime cache
(`~/.cache/igdrc`), the SYCL program cache (`SYCL_DISABLE_PROGRAM_CACHE`, `SYCL_CACHE_DIR`), and "the device
code is AOT-compiled so IGC never runs at launch" (this one I wrote into three documents as a finding).
All wrong. The answer, from outside: **`NEO_CACHE_PERSISTENT=0`** — the Level Zero user-mode driver keeps its
own persistent shader cache, so IGC is never invoked and emits nothing, and no compiler-side variable can
reveal a backend call that never happened.

Three things worth extracting. The mechanism: when a dump disappears after working, enumerate every cache
between the tool and the hardware — here there are three layers (SYCL program cache, NEO driver cache, IGC
disk cache) and I only tried two, then inferred a property of the compiler from the absence of its own
output. The evidence discipline: I should have tested the AOT hypothesis by asking whether the *first* run of
a freshly built binary dumped, which it did, meaning the answer was "something caches after the first run",
not "compilation happens at build time". A hypothesis that explains the observations only if you never run
the cheapest experiment is not a finding; it is a story, and I published it as if it were the reason.

And the companion mistake, which turned a recoverable annoyance into lost data: I deleted the one rev H
`.asm` I had captured, during cleanup, before anything had cited its contents into an artifact. Dumps are
~1 MB and reproduce only under conditions I did not understand at the time. The rule now: copy the numbers
into the artifact *first*, and if the instrument is finicky, archive the dump itself alongside it; delete
nothing that is the sole instance of a measurement.

43. **On this device, synchronization primitives repeatedly cost more than the memory traffic they avoid, so
    "fuse it into one kernel with atomics" is not a free optimization here.** Three independent measured
    instances: a compute child spin-polling the host doorbell adds +24 to +54 ms/layer on top of the traffic
    (E16); posting a Doorbell where a pinned flag works costs 4–17 µs/launch (E19); and fusing the DPAS
    combine into the producer with per-expert atomic adds, a fence and an arrival counter costs +6.4…+8.4 µs
    on gate and +13.6…+15.8 µs on down, where the round trip it removes was worth 1.9 µs (13w). Method
    corollary: when a proposal removes a launch, price the synchronization before believing the saved bytes,
    and use a *floor* mode (same grid, no per-tile work) to separate fixed cost from work — that is how the
    8.7 µs protocol cost fell out, and it also showed that ~24 µs of a 43.6 µs b=1 layer is fixed overhead
    rather than streaming.

44. **FP contraction is on by default in icpx and nothing in this repo sets it**, so an epilogue of the form
    `a*b - c` may fuse into an FMA and change results depending on which kernel built it — a bit-exactness
    claim is only as stable as the expression that produced it. Either write epilogues so no multiply feeds
    an add (rev K's `CQ * ((float)s - DR)`, with the scalar differences rounded on the host) or compile device
    code with `-ffp-contract=off`. And when adopting such a rule, re-check that already-certified kernels are
    unaffected instead of assuming they were lucky: rebuilding revs I/J with the flag off gave byte-identical
    output, which is what makes the earlier verification durable rather than accidental.
45. **A check that prints a failure but exits 0 is decoration, not a gate.** The markdown table validator I
    run before every commit prints `BAD <file> <line>` when a row's column count disagrees with its table, but
    it always exited 0 — so `python3 check && git add -A && git commit` sailed straight through and committed a
    row that had lost a cell separator (the same edit that swallowed the neighbouring row's opening cell). The
    rule: any check wired into a commit path must exit nonzero on failure, and a check that cannot fail the
    chain should not be described to myself as protection. Cost here was one amend; the class of bug is the one
    that silently reaches the repo.

46. **When a whole batch of numbers moves together, suspect the instrument before the code — and prove it with
    an anchor, never with a story.** rev J's rows>16 sweep came back with every binary ~1.6–2.3× slower than
    published, including binaries untouched for hours (rev I 19.4 → 44.0 µs, rev G 36.5 → 58.9). I wrote it off
    as thermal. It wasn't: these runs last seconds. The actual cause was that the device downclocks when idle
    and my "warm-up" was a sequence of *separate short processes*, each with its own idle gap, so nothing ever
    sustained long enough to ramp — and because I had no anchor in the batch, the only signal was that a number
    I liked had gotten worse, which is precisely when a fabricated explanation is most tempting. Two fixes,
    both cheap. (a) **Put the warm-up inside the timing process**: 1 s of continuous work converges (31.1 → 13.9
    → 13.7 µs at 0/1/3 s) and 20 s buys nothing, so the old 15–20 s protocol note was wrong in *duration* while
    being right about continuity, and post-compile sleeps were pure waste. (b) **Run a fixed anchor kernel in
    every batch** — an unchanged binary on an unchanged case — so a window shift is visible as a number rather
    than as a narrative; the moment I added one it read 19.2 µs and the mystery collapsed. Corollary for the
    artifacts: ±15–20 % between windows was a wild underestimate (2.3× observed), so cross-window absolute
    comparisons are banned outright, and any claim that survives a window change must be stated as a ratio
    measured within a window.

47. **A modeling error that points the way you want will survive review; look hardest where the numbers flatter
    the thesis.** Two planning scripts charged every touched expert the *global* batch as its per-expert row
    count, so at topk=8 a b=8 step priced 65 experts at 8 rows each when each saw ~1 — inflating device time
    25-35 % and making the B70 the bottleneck at mid batch, which is the conclusion the chapter was oriented
    toward. It survived several rounds of exactly this kind of scrutiny, and the damning detail: the correct
    statistic (`rows/exp`) was printed in the same table, one column away from the number that ignored it. Two
    habits follow. (a) When a model's output agrees with what you expected, audit that model's *assumptions*
    before moving on — agreement is not evidence. (b) Check whether any column already in your own artifact
    contradicts another; the cheapest bug-finder is arithmetic consistency inside a table you already trust.

48. **When a mechanism story fits a single datapoint, vary a second knob and turn it into an experiment.** E29's
    shared-stream kernel lost to plain bucketing and I had two causal stories, both wrong. "Spilling exhausts
    local memory, hence the MMU faults" — scratch is allocated by the runtime from the kernel's own spill
    metadata, so spilling costs bandwidth, not faults; and my dump "evidence" was backwards because a faulting
    process dies before IGC compiles the remaining kernels, so **absence of spill records was a coverage
    artifact I read as a measurement**. "The non-monotonic failure set (BKT 2, 3 fault; 4 works; 8 faults) proves
    a codegen edge case" — no: whether an overrun faults depends on what the allocator happened to place after
    the buffer, which has nothing to do with BKT. What the fault record actually said — read, page-aligned,
    address moving between runs — pointed straight at walking off a live allocation, and it was my own host code
    sizing one bucket for a kernel that reads BKT. The ring sweep (96→576 dwords across four shapes) then turned
    a vague "time tracks spill" into a controlled result: the baseline is spill-free and entirely
    ring-insensitive, and every multi-bucket shape pays for extra accumulators in prefetch depth — the mechanism
    works, the **budget accounting** is what refutes it, and that is the honest form of a negative result.
    Two subsidiary habits: never send a build's stderr to /dev/null (12 silent failures read as a tooling
    mystery), and re-read preprocessor structure after editing comments — a comment glued to `#ifndef X`
    silently disables the directive.

49. **A value the caller already knows must be a template parameter, not a struct field — and when a new kernel
    disagrees with an old one about a *layout*, suspect parameterization before hardware.** rev L measured the
    parent's banded tile order as +19 % (23.10 µs vs 19.60 µs), contradicting rev J's recorded "banding is free"
    and implying that a CPU win (3.4× cold traversal) was a B70 tax. Both measurements were correct on
    bit-identical data: rev J took the band from `#define`, so `kstride`/`estride`/`tbase` folded to immediates;
    rev L read it from `Launch`, leaving runtime address arithmetic. Same source, same bytes, band forced
    compile-time: 19.70 µs at group 2 *and* group 8. `Band` is now a template parameter (`dispatch_band` over
    {0, 2, 8}) and one binary serves every staged form at 19.2–19.6 µs.
    Three transferable habits. (1) Audit the parameter block of any kernel that reaches steady-state perf: every
    field that is fixed per admit (band, KS, shape constants) is a specialization candidate. The cost of getting
    this wrong was larger than several algorithmic wins in the chapter, and no swept knob could have shown it.
    (2) When a rewrite of verified code measures worse, run the OLD binary in the same window against the same
    bytes before believing the result — that comparison, not analysis, is what localized this. (3) Specializing
    has a price worth stating in the artifact: 75 → 225 device instantiations took the probe build from 1.7 s to
    2 m 11 s. The engine avoids it by compiling per shape; the probe pays it per rebuild, so record it rather
    than letting the next reader think the build is broken.
    Subsidiary, and the third recurrence of LESSONS 42's vacuous verdict: my earlier "the staged arms are
    bit-exact" had been read from `<case>/y_dev_*.bin` while those runs wrote to `<case>_planar`/`_full`. Always
    derive the output path from the argv you passed, never from the case you meant.

50. **When a fusion loses only in situ, attribute the loss to a stage before theorising — and remember that
    "one launch" and "one grid" are two independent changes.** E25b's merged combine won standalone by ~3 µs and
    lost in situ by up to 3.5 µs. Four explanations were tested and refuted in sequence: dirty L2 (producer pass —
    merged still wins), measurement protocol (penalty present in burst-of-8 *and* sync-per-iteration),
    runtime-`KS` address folding (templatizing KS: +3.5 → +3.4), non-contiguous partial allocations (one chunk:
    +3.5 → +3.6). What the change had actually bundled was launch count *and* grid size — the merged body used a
    2× grid. Separating them answered it at once: one launch with the original grid, each work-item producing
    both projections, beats the two-launch form (rows 1/8/16 combine section 9.57/10.18/12.97 vs
    9.54/11.29/13.20 µs) and is where SiLU-mul belongs. Two habits. (1) Time *stages* in situ, not only totals:
    the per-stage mode showed the gemm unchanged and the entire delta inside the combine section, collapsing a
    vague "fusion is slower" into "this grid is too large when it follows a full-device kernel" in one run. That
    instrument paid for itself immediately; build it before the third failed hypothesis. (2) When a change
    fuses, enumerate everything else its shape altered — grid size, work per item, item-to-data mapping — and
    vary each alone before crediting the fusion. Subsidiary: a fused epilogue that recomputes in floating point
    is not bit-exact against a host reference by construction (silu form: 7.5e-11 relative on values spanning
    ±1e8), so the gate must keep bit-exactness where the arithmetic is identical and take an explicit relative
    tolerance where it is not — an intentional loosening, never a silent one.

51. **Name the leg you measured, and check whether a wrong number was ever binding before promoting the fix to
    a conclusion.** I benchmarked the CPU home (`S_c`) at b=1..16 and wrote the artifact under the heading "parent
    calibration". In this design the parent is the 3090 — `wall = max(T_parent + S_g/936, S_b/rate_b, S_c/47.4)` —
    and the CPU cores are just another home. The slip is easy to make because the host machine *is* the parent
    machine, but the model has three named legs; re-read the formula before naming a file after it. Second half,
    and the more useful habit: that leg was wrong by up to 1.9× (assumed 47.4 GiB/s against a best observed 37.9,
    and the regime is compute-bound rather than byte-bound, so the units themselves were wrong) — and after
    swapping in the measured model the placement walls moved by 0-1 us and no verdict changed, because `S_c` was
    never binding in the tested configs. Report both facts together: "the input was wrong AND it did not matter
    here", plus where it would start to matter (large CPU residue — which is the uncalibrated GLM profile). A
    correction that changes nothing is still worth committing, because it retires a number someone will lean on
    in a configuration where it does bite; announcing "1.9× error!" without the binding check oversells it.

52. **A run that printed nothing is a crashed run until proven otherwise — check exit codes, and read the
    output directory before re-running the world.** rev L's fused runs at some shapes returned no timing line
    while neighbours were fine, which read as "device/config problem" and nearly sent me into another 54-run
    sweep. Two facts settled it in two commands: the surviving output files were bit-exact (so the kernel was
    fine), and one direct run with stderr captured gave SIGABRT/`UR_RESULT_ERROR_INVALID_MEM_OBJECT` with the
    backtrace `main -> sycl::free -> usm::free -> throw`. Cause: a genuine double free I had introduced (my
    replacement text repeated `free(Y); free(PART)` while the original line was still below it). The systemic
    part is what it did to the data: an abort discards block-buffered stdout, so those rounds yielded `None`
    and `min()`-of-N continued without them — 27 core dumps from that binary against the handful of holes I
    noticed. Rules adopted: every measurement loop checks `returncode` and reports nonzero exits explicitly;
    when a probe's usefulness depends on its print, run it line-buffered (`stdbuf -oL`) or flush before exit;
    and diagnose from artifacts already on disk (outputs, cores via `coredumpctl dump` + `gdb -batch -ex bt`)
    before spending device time — the E≠10 correctness answer came entirely from files, zero runs.

53. **Define a warm-up in units of executed device work, not elapsed submit time.** `do { dispatch(); } while
    (wall < WARM_S)` is only correct while host submit and device execution cost about the same. At E=10 they did
    (~40 us each), so the chapter never noticed; at E=96 a dispatch runs ~400 us of GPU work for ~40 us of submit,
    so a "1 s" warm-up queued ~30 s of work and dumped the backlog on the first `q.wait()` — 44.2 s wall for
    1.0 s of intended warm-up, reproducibly (44.0), and a 54-cell sweep that crawled through one loop in 50
    minutes. Fix: wait every 8 dispatches so the loop measures executed work. Wall time 44.2 s → 1.6 s with the
    measured kernel time unchanged (402.9 → 410.0 us), which also shows the old behaviour was not biasing results,
    only wasting clock. Verified afterwards rather than assumed: sweeping WARM_S = 0..20 s on the corrected loop
    gives a flat 404-413 us at E=96 and 37.5 us unwarmed -> 33.5 us flat from 1 s at E=10, so the accidental 30 s
    backlog had not been providing extra ramp that the honest 1 s would lose. The reason warm-up length barely
    moves these numbers is that timing takes min-of-several-rounds, and the first rounds ramp the clock — so
    warm-up mainly prevents a throwaway first round; several timed rounds are what make the estimate stable, and
    both are needed.

54. **Quote achieved bandwidth together with the working-set size, or you will mistake L2 for DRAM — and the
    cache-residency self-check is free.** The chapter's headline rate ("437 GB/s ≈ 90 % of the 484 GB/s stream
    slope, so the streaming path is at the wall") came from an E=10 case whose weights are 5.9 MiB against a
    24 MiB L2, measured by re-reading those same tensors thousands of times. Running the quantization ladder made
    it unavoidable: 3x the bytes changed the time by 3% and the arithmetic reached 693 GB/s, above the 674 GB/s
    *copy* peak — a DRAM-bound kernel cannot beat copy, so the number was describing cache, not memory. Two
    habits. (1) Put the resident-set size next to every rate in a report, and compare it to L2 explicitly
    (`devinfo` prints it in one line). (2) Treat "exceeds the copy peak" as a proof of residency, not as a result
    to celebrate. The correct DRAM-regime numbers were already in hand at E=96 (492 GB/s at rows=1, 287–292 at
    rows=16) — the error was in which label I put on them, and the fix was arithmetic, not new measurement.
    Related instrument note: `xpu-smi stats -d 0 -j` gives power, per-domain temps, frequencies and memory
    read/write rates as JSON, and is the cheapest way to discover that the part is power-capped (~285 W mean vs a
    275 W cap under decode) — which in turn bounds what optimisation can buy: at the cap, latency hidden and
    energy spent are the same currency, so removing work beats scheduling it better. General form: any loop that enqueues asynchronously and bounds itself by wall time is
    measuring the host, not the device — check it whenever per-launch work grows (bigger E, bigger rows, fused
    multi-projection grids).

55. **This box's benchmark GPU is shared with the desktop, and the anchor is the detector.** A batch whose anchor
    (rev I gate rows=1, healthy 19.4 us) could not get below 20.6 us across six interleaved samples, with one
    43.7 us outlier, was not a thermal mystery: `fuser -v /dev/dri/renderD128` shows firefox holding the same
    render node as the probes (plus the niri compositor on the card). Every absolute figure in this chapter was
    measured over a browser. Three consequences. (1) Report ratios, not absolute us, from any batch where the
    anchor is not healthy — within-cell back-to-back comparisons survive a noisy neighbour, cross-window absolute
    values do not. (2) The old observation that absolute us swung by up to 2.3x between windows, which I had
    attributed to clock state, now has a concrete mechanism and should be re-attributed to contention (or both).
    (3) The real fix is structural and still outstanding: timing batches should run where no compositor or browser
    owns that card (headless runner, VT with the desktop stopped, second GPU), and `fuser` output should be
    captured alongside the numbers so a future reader can tell a contaminated batch from a clean one. Until then,
    the close-out's absolute decode figures carry a shared-device asterisk even though the protocol (warm
    continuous work, round-robin arms, anchor) limits the damage.

    CORRECTION, same day, and it supersedes the attribution above: those depressed anchor readings were not the
    browser - they were an UNDER-WARMED ANCHOR. The anchor binary does about 19 us of work per rep, so 120-200
    reps is 2-4 ms, which never raises the clock. Measured directly, each trial starting from ~25 s of idle:

        reps      work    anchor us   MHz before -> after   W
         200     3.8 ms      44.0        1200 -> 1200       56
        2000    38.0 ms      19.2        1200 -> 2000       62
       20000   380.0 ms      19.1        1200 -> 2650       81
      100000  1900.0 ms      19.2        1200 -> 2750       86
         200     3.8 ms      43.9        1200 -> 1200       56     (repeat of trial 1: reproducible)

    The arithmetic closes: 44.0 / 19.2 = 2.29 against a clock ratio of 2650/1200 = 2.21, so the "drift" was
    frequency, not contention. Re-running the anchor with 6000 and 60000 reps in the very window I had called
    contaminated gives 19.1 and 19.6 us at 2150 and 2750 MHz: the window was healthy all along. Consequences.
    (1) An instrument must satisfy its own warm-up rule; I applied "warm continuous work before timing" to the
    probes and then polled health with a 2 ms burst. Health checks are measurements too - state their rep count.
    (2) A depressed anchor is evidence about the anchor until proven otherwise: check xpu-smi's frequency (and the
    probe's rep count) before blaming the environment. (3) The old 2.3x cross-window swing that I had attributed
    to clock state and then to co-tenancy is explained by idle-clock operation (2.29x measured), which fits far
    better than any contention story. (4) The co-tenant is real - fuser shows firefox on the render node - but it
    is NOT the demonstrated cause of anything in this chapter; the batches I flagged as 6-19% pessimistic are
    retracted as flagged, and their absolutes stand (they were measured with WARM_S>=1 s of executed work).
    Protocol now: anchor at >= 2000 reps, preferably 6000 (~115 ms of work), and read the frequency alongside it.
    One nuance this explains: earlier in the same session the anchor sometimes read 19.4 us with only 120-150 reps
    and sometimes 44 us with the same command - when a warm probe had just run, the *neighbour's* work kept the
    clock up, and the short anchor rode along. So an anchor reading is only interpretable if the anchor carries
    enough work of its own; otherwise it reports the history of the box, not its state.

56. **State an operational rule together with the parameter range it was measured over, or it will be applied
    outside that range — usually by you.** "Fusion and split-K are substitutes, so fuse at KS=1" was a fair
    reading of the E=10 data (there, fused KS=2 cost +7%) and it sat in the decision table as if it were general.
    The low-E sweep says otherwise: at E=2 the best schedule is fused *and* KS=4 (9.7 us, against 17.6 fused KS=1
    and 14.1 separate KS=4). The two levers are not substitutes in general; they are two sources of one scarce
    resource, and at low E neither alone is enough. What was wrong was not the measurement but the FORM of the
    claim: it named the knobs instead of what the knobs buy. Three habits. (1) While a rule rests on one operating
    point, write the point into the rule ("at E=10 …") until a sweep earns the right to drop it — a scoped claim
    is falsifiable, an unscoped one is merely confident. (2) Prefer rules phrased over the underlying quantity:
    here, gemm grid occupancy (~0.6–0.8 × HW_THREADS) predicts the optimum at E=2, 4, 10 and the indifference at
    E=96, including the two cells that break the knob-level rule. (3) When a rule is superseded, keep the old
    wording and what it got wrong in the same cell (done in close-out D8), because the next reader — often me —
    remembers the stale version and needs to know which memory to discard.

57. **When holding one lever fixed to isolate another, enumerate every axis that moves — "looks equal" is not
    evidence of equality.** To compare fusion against split-K I paired `separate KS=2` with `fused KS=1` because
    their per-launch thread counts matched, and concluded fusion wins by a constant 1.13x. But separate is TWO
    launches: at equal per-launch grid the fused variant was doing twice the k-work per thread in half the
    launches, so both levers had moved and the constancy was measuring my pairing, not the device. Matching KS
    instead (equal total thread-slots by construction) gives 1.6–1.9x where the device is under-filled and
    0.96–1.12x where it is not — the original D8 conclusion, with the opposite emphasis. Habit: before calling two
    configurations "matched", write out the invariants you actually need (here: total thread-slots, work per
    thread, launch count, and which projections they carry) and check each; a coincidence in one of them is not a
    control. Corollary for reporting: when the top candidates differ by less than the noise floor, say "indifferent"
    rather than naming a winner — `best_launch()` now flags INDIFFERENT when the runner-up is within 3%, because a
    decision table that ranks noise teaches the reader to trust it.

58. **Fusion merges working sets, so its cache envelope is the union — and a "non-monotonic" anomaly is usually a
    missing dimension, not noise.** Separate KS=2 beat fused KS=2 by 1.27x at E=32, reproducing to 1% across two
    re-runs, while E=16 and E=64 showed no such effect. Reproducible + non-monotonic in the obvious axis is the
    signal that a variable is missing, not that the instrument is flaky — so rather than theorise about waves I
    computed the one thing the two schedules differ in besides thread count: bytes live at once. A fused launch
    holds *both* projections' weight streams (2·E·b); two separate launches each hold one (E·b). With L2 = 24 MiB
    and b = 0.585 MiB, fusion's advantage should end near E ≈ 20 and the penalty band should close near E ≈ 41 —
    and the measured curve (fused wins at 10 and 16; separate wins at 20, 24, 32; indifferent at 64, 96) falls out
    of those two numbers with no free parameters fitted to it. Habits. (1) On a non-monotonic result, hunt for the
    second axis the candidates differ on instead of reaching for noise or wave-parity stories. (2) Keep occupancy
    and locality as separate conditions in any rule: D8's fill test alone would have chosen fusion at E=32, where
    it costs 27%. (3) Same root as LESSONS 55 — never reason about a kernel without its working-set size beside
    it; the first time it corrected a *rate*, this time it corrected a *decision*.

59. **Price the mechanism before building the feature — a go/no-go instrument is often a tenth of the work and
    sometimes the whole answer.** E25c (gate+up+down in one launch) would have meant a three-phase ESIMD kernel
    with per-slice geometry, an intermediate hand-off and the register consequences of sequential phases. Instead
    I wrote probe_barrier.cpp — the same body with and without an atomic spin barrier, 8 rounds, min of 5 — and
    the answer arrived in one build: a device-wide barrier costs 1.6 µs at 256 work-items, 2.5 at 1024 and 6.2 at
    2048, against the ~2.9 µs the saved launch is worth, on the most favourable geometry available. Net negative
    before any of the hard parts exist. Habit: for every "fuse X into Y" proposal, first name the mechanism the
    fusion requires (here: grid-wide sync) and measure *that* in isolation; the feature is only worth building if
    the mechanism is cheaper than what it saves. This is the fourth such refutation on this device and all four
    were cheap: the recurring truth is that launches cost ~3 µs while in-kernel coordination and atomics cost
    multiples of it.
    Subsidiary, and the fifth appearance of the LESSONS 42/45 trap: the probe's built-in correctness check
    reported zero mismatches for BOTH the barrier runs and the unbarriered runs, so it could not distinguish a
    working barrier from no barrier at all — a check that cannot fail proves nothing, and I nearly quoted its
    zeros as evidence the barrier delivered visibility. The cost conclusion survived because it is a within-run
    delta between identical bodies, but the artifact now says plainly that the ordering question is unresolved and
    that any future attempt needs a wider write→read window first. When a check comes back uniformly clean, ask
    what it would have looked like had the thing been broken; if the answer is "the same", it is decoration.

60. **A rejection is a claim about the mechanism you chose, not about the goal — re-read it that way before it
    hardens.** D10 was written as "E25c needs a device-wide barrier, which costs 7.6 us, so no". Asked whether it
    could be delivered without one, the answer turned out to be yes: confine the dependency to a work-group and the
    sync measures free (-0.03..+0.22 us), the intermediate fits SLM (40 KiB of 128 KiB), and large groups cost only
    +4-10%. My barrier was not the obstacle - I had picked the one mapping that required it. The design still
    fails, but for a reason I had not considered at all: the backend caps groups at 64 work-items, the dependency
    closure needs ~40-64, so one group per expert drops in-flight items from 1600 to 640 at E=10, and the fill cost
    of a far gentler loss is measured at +62%. Three habits. (1) When rejecting on cost, say which part of the cost
    is inherent to the goal and which belongs to your sketch: "requires a grid-wide barrier" and "the mapping I
    first imagined requires a grid-wide barrier" are different claims and only the second was earned. (2) Look for
    the *second* limiter before publishing the first - the honest answer was never the barrier, it was concurrency,
    which this chapter had already found binding twice (D4, E29) and still did not get consulted first. (3) A
    corrected rejection is worth more than an untested one - but check the new optimism against data already in
    hand before publishing it: I wrote "revisit at large rows, where fill matters less", and two lines of
    out_ks_grid.txt showed that at rows=16 fill still costs +36% (~18 us) against ~6 us saved, i.e. the idea is
    closed, not deferred. A corrected reason is only better than a wrong one if it gets the same scrutiny.

61. **Two right answers can differ 2x, because one measures a floor and the other absorbed a window.** The
    parent's non-expert cost per layer now has two numbers in this tree: **122 us**, composed bottom-up on the
    3090 from measured legs (decode attention + streamed non-expert weights + recurrent-state traffic,
    out_parent_leg.txt), and **257 us** from plan_concurrency.py, whose `fixed` overhead was calibrated so the
    parent bill reproduces the inherited ~250 us/layer window. Neither is wrong: the planner's figure carries the
    sampler, lm_head, graph launch and the rest of the network - everything the window contains and no bench of
    mine measures - while the composed figure is explicitly a floor. The reason to write this down is that a
    decision sits in the gap: at b=8 the parent term is 313 us calibrated vs 176 us floored, and the B70's leg is
    299 us, so with one number the parent binds and with the other the B70 does. Rule adopted: when a constant
    was inherited as an *observed window*, never calibrate a sub-model to reproduce that window and then quote the
    sub-model as independent corroboration of the window - the calibration smuggles the window's unmeasured
    contents into the "prediction". Report both estimates and name the decisions that flip between them.
    The same file contains a second lesson about inherited rates. The parent's expert leg, measured with the real
    fused kernel at the real shapes, runs at ~190 GB/s at b=1 and stays flat (170-215) through b=16 - the
    signature of a kernel-bound leg, not a bandwidth-bound one, and batching buys it nothing. Anything that
    charged that leg at the card's byte rate had it 4-5x wrong, and the byte rate itself was the datasheet's 936
    rather than the 860 the card actually delivers (samples ranged 639-864, so only best-of-N is quotable). A
    spec bandwidth is an upper bound on a *traffic* term; it is not a rate you may charge a kernel with.

62. **A guard that encodes "not measured yet" becomes a live bug the day you measure it - and its replacement
    must be written from the printed contract, not the intention.** `plan_decode_cost.py`'s selftest asserted that
    `best_launch(64, 8)` raises, because rows=8 had never been measured at E=64 and borrowing a neighbouring row
    count was the exact failure mode the guard existed to prevent. After the rows sweep filled that cell
    (`out_fusion_rows.txt`) `plan_decode_cost.py` exited 1 while every planner importing it stayed green, so the
    symptom read as "the new data broke the model". The data was fine; the *control* was stale. Two rules came out
    of it. (1) When a cell gets measured, grep for the refusal that named it and convert that negative control into
    a positive one (assert the value now on file) while *keeping* a negative control on a cell that really is still
    unmeasured - rows=2/4 here, which is exactly what makes the planners fall back rather than guess. A suite of
    only-positive tests would have gone stale silently in the other direction. (2) My replacement assertion then
    failed too: I demanded the tie marker for E=64 rows=8 because its gain was "1.04x", but the module reports
    `INDIFFERENT` only inside 3% and that margin was 4.0%. The note in the failing message (`grid 10240 threads
    (500% of HW)`) was the correct contract; my memory of the band was not. Assertions belong downstream of the
    printed interface - and when an assertion fails on brand-new data, check the assertion before suspecting the
    data, because the data is the one thing in the commit that was just measured twice.

67. **A rule that silently falls back is a rule that is not applied - and "the numbers did not change" is the
    symptom, not the reassurance.** I wired the joint (fusion, split-K) dispatch into two planners, regenerated
    the artifacts, and reported that **no planner number moved** - which I wrote up as evidence that the old
    per-projection tables were already KS-optimal. Partly true, mostly false: `plan_operating_point.py` asks for
    rows-per-expert, which at decode is 1.x and rounds to **rows=2**, a row count the joint tables had never
    measured. So `best_launch()` raised, the caller's `except ValueError` set `j_us = None`, and every cell
    quietly used the legacy path. The rule was inert in the grid while its footer cheerfully reported "joint
    table consulted where a gate geometry is measured". What gave it away was an inconsistency I nearly
    skimmed past: after adding GLM geometry, the b=1 *summary line* moved (124→83 µs/layer) but the b=1 *row* in
    the table above it did not (129 both times) - two code paths, same inputs, disagreeing. Fixing the fallback
    to print its reason, then measuring rows 2/4 (`out_rows_2_4.txt`), moved GLM b=1 129→85 and Qwen3.8 41→34
    us/layer: the numbers HAD changed, they just hadn't been allowed to. Rules: (1) a caught exception that
    selects a lesser model must say so on the record, every time it fires - silence is how a wiring bug survives
    a commit and a review; (2) when a change produces no delta, first ask whether the changed path executed at
    all (print the branch, or make the change produce a deliberate sentinel value) before writing up "no
    decision flipped" as a finding; (3) two paths computing the same quantity must agree to the digit or be
    reconciled in the artifact - a mismatch is a cheap, high-signal bug detector that only works if you look.

69. **Never edit a file with a script. `edit`/`write` only — because a scripted edit has no failure mode.**
    Stated as policy since the first corrupted-source incident (a lost newline → `IndentationError`, an
    unterminated argparse string, an unbalanced `pprint`). Tonight it produced three defects that a tool call
    would have refused outright:
      * **Silent work loss.** `doc/port/b70-kernels.md` gained a 13b–13r item list, grep confirmed it at line
        351, and the committed file afterwards did not contain it — while §4 of the same file cited `item 13b`,
        so the tree shipped dangling internal references. git history (`bfa5579b` showing 3 changed lines where
        ~50 had been written) proves a scripted write clobbered it. There was no error, no partial state, no
        signal. `edit` cannot do this: a non-matching or ambiguous anchor raises before anything is written.
      * **Character corruption.** One of my heredoc-inserted lines contained a stray CJK glyph (`dpas殖`),
        invisible in terminal output, only caught by re-reading the text I had supposedly written.
      * **Twice more, knowingly.** I reached for `sed -i` on `b70-prefill.md` and appended a section with
        `open(p,'w').write()` — after writing the commit message describing this exact failure class. Both
        happened to work, which is the trap: `python3 - <<'PY'` prints nothing on success, so "it worked"
        carries no information about whether it worked *correctly*, and the two cases where it did not are
        indistinguishable from the cases where it did.
    The general form: a heredoc edit is unobservable in the success case, so its safety depends entirely on my
    noticing the rare visible failure — the same betting structure as skipping a negative control. Tool edits
    are atomic and loud; that is the whole argument, and it is not about convenience. Corollary now enforced
    by a gate rather than memory: `check_tables.py` checks table shape, and this file is where the reasoning
    lives — if a claim's provenance cannot be re-derived from the tree, the claim should be treated as lost
    work in progress, not as done.

70. **When a probe's conclusion is a mechanism claim, prove which resource bounds it.** `probe_slm` bundled two
    findings and only one survived: the SLM staging penalty (1.5–6.0x, mechanism verified in the archived dump:
    +80 `load.slm` +89 `store.slm` over 80 identical global vector loads, spills equal across modes) and the
    claim that concurrent global re-reads beat unique reads (1690 vs 1349 GB/s). The second died on a second ISA
    read — both bodies are dominated by scalar address arithmetic (149 `add`, 100 `shl` vs 32 vector loads) and
    the reuse mode did 32x the loads per iteration for a near-identical time. Matching ALU per element (LESSONS
    68) is necessary but not sufficient: you also have to show both arms are bound by the thing you are
    attributing the difference to. Corollary for this repo: bundle claims at your peril, since a retraction that
    lands correctly has to find *every* file that repeated the strong form — five did here.

75. **A throughput number without its input size is not a number.** The prefill baseline published at 2048
    tokens (655 / 479 tok/s) understates realistic prefill by 25 % because the parent spends ~410 ms per forward
    plus ~90 ms per chunk boundary regardless of length: at fixed chunk size the same model measures 459 tok/s at
    1024 tokens, 825 at 4096, 913 at 8192. Two rules: (1) when a quantity is affine in the variable you are
    sweeping, report slope and intercept rather than one ratio - and note that chunk size (the thing I was
    tuning) is the weak term at +5.8 % then saturating, while prompt length (the thing the operator pointed at)
    is the strong one; (2) re-derive every published comparison that consumed the old constant: the roofline gap
    here moved 75x -> 42x, and the bar a B70 prefill must clear became the `-mcpa` number, not the plain one.

76. **When a broken measurement has a cheap fix that changes what is measured, the cheap fix is the trap.** The
    prefill arms truncated to 1158 tokens because the corpus was `REFERENCE_TEXT x --reps`; repeating it more
    fixes the length and silently invalidates the result, because periodic text routes every window to the same
    experts, so a chunk touches fewer distinct experts, reads fewer bytes and prefills faster. Measured control
    (same prompt length, same chunk, corpus the only difference): varied 12-document pool 873 tok/s touching 417.7
    experts/layer vs repeated text 910 tok/s touching 399.4 - **+4.2 % speed for -4.4 % coverage**, the exact
    direction predicted. General form: before accepting an instrument fix, name a *derived* quantity that would
    move if the fix changed the phenomenon, and measure it. Here that quantity (chunk expert coverage) already
    existed in the harness, so the bias cost one arm to catch instead of a chapter of optimistic baselines. The
    permanent fix: default the corpus to distinct documents, and make a truncated arm a hard error with an
    explicit opt-in flag.

77. **Build the arm that can kill your explanation, especially when the number came from someone else.** The
    operator's estimate was "`-mcpa` can easily be worth 2x"; measured, it is +30 % (2.05) and +50 % (2.68) on
    prefill - right direction, right order, not 2x, and the artifact says the measured thing rather than the
    suggested thing. Separately, my own mechanism story (hot experts promoted during sub-chunk 1 serve sub-chunk
    2) predicted the gain should vanish when the prompt fits in one chunk; one arm falsified it - at chunk =
    prompt = 4096, plain 876 vs `-mcpa` 1064 tok/s (**+21.5 %** with provably zero intra-forward re-touch). The
    measured answer (`out_host_mem.txt`) is arithmetic migration: the CPU expert path is compute-bound at
    prefill's ~98 rows/expert on a host with AVX2 but **no VNNI**, and there is no bandwidth shortage to relieve
    (~10 % of the chunk's time would stream all unique remote expert bytes). Corollary that also fell out: the
    same flag is worth ~nothing at decode's rows/expert ~1-4, because there the path runs at 89 % of the host's
    read ceiling and moving it changes neither bytes nor arithmetic per byte. A mechanism that explains both
    regimes is worth more than a mechanism that explains the one you were looking at.

78. **A bandwidth probe must carry an invariant with a known value, or it will print confident nonsense.** My
    first `probe_mem` stepped the read index by 16 uint64 while loading at `j` and `j+4`, touching half the bytes
    it charged for: every read figure was 2x high (89 -> 45.8 GB/s at DRAM), no assertion fired, and the numbers
    looked respectable. What gave it away was internal consistency rather than authority - the same run reported
    copy at 1622 % of the datasheet DRAM ceiling, and I had pasted that line into a table without reacting. A
    symmetric read+write stream cannot exceed the memory ceiling, and `copy <= read <= peak` costs one comparison
    to enforce. Rules: (1) state the ceiling in the probe's own header and assert against it; (2) treat a
    super-theoretical number as a bug report against the probe, not as a discovery about the hardware; (3) prefer
    invariants derivable from the measurement itself (copy vs read ratio) over ones needing external truth, since
    the external truth (`dmidecode`) may not even be readable on the box.

79. **Falsify a lever with a curve before you buy it with a rebuild.** `constexpr int MAX_M = 4` in the CPU worker
    implied ~25 weight passes for a 98-row prefill expert, which sounded like a large, fixable inefficiency and
    pointed at a CUDA extension rebuild to test `MAX_M = 8/16`. Instead I swept rows 1..128 on the existing CPU
    instrument: us/token 128.8 / 112.3 / 109.5 / 109.5 / 109.9 at rows 4 / 8 / 16 / 24 / 32 — **no stair at
    multiples of 4**, so the amplification is not happening in the way the estimate assumed. Fifteen minutes of
    measurement retired both the rebuild and the mechanism. The general shape of the shortcut: if a compile-time
    constant gates a loop, its cost is a function *with a kink at that constant*, and kinks are far cheaper to
    look for than builds. Caution on the follow-up, though: the same sweep appeared to expose something more
    interesting than the lever it was testing ("one assignment per pick at prefill shape"), and that too was wrong
    - it came from a misnamed column, see LESSONS 80. Killing your own hypothesis is often where the next one comes
    from, but the next one earns the same scrutiny, not less.

80. **Know what a benchmark's independent variable holds fixed — and do not trust a column's name, check its
    expression.** `bench_cpu_moe.py`'s `rows` is *tokens over the loaded expert pool*, so rows/expert =
    rows × topk / experts. Reading three arms at face value (8 experts/128 rows at 114 µs/token, 192/96 at 119,
    418/4096 at 117) looked like "flat, compute-bound, ~1 GiB/s, so the card must be ~28× faster", and that claim
    was minutes from a document. Holding the real invariant fixed shows only the 418×4096 arm is prefill's regime.
    Then I made a second, worse error in the same table: the column headed **`asgn/exp`** is computed as
    `rows * topk / distinct_experts` — *picks* per expert, a derived routing statistic that is trivially 98 at
    that shape — and I read it as "worker assignments per expert", announced "one assignment per pick" as the
    chapter's biggest CPU-side lead, and propagated it into four documents before checking the expression. It was
    wrong, and the failed cross-check that motivated it (478 ms/layer from the bench against 98 ms/layer for the
    parent's whole forward) resolved benignly: sweeping `-mcs` shows prefill costs **10.7 ms per CPU-homed expert
    per chunk**, marginal experts are *cold* (≤ 19 picks each against the bench's uniform 98), and both
    instruments were right about their own regime.
    Rules, in order of cost: (1) a derived column must be named for its expression — the header now reads
    `picks/exp` / `ns/pick`, because "asgn" was not a description, it was an invitation; (2) before promoting a
    suspicious number into a *mechanism*, re-read the line that computes it, which takes seconds and is cheaper
    than retracting from four files; (3) keep the good part of the instinct — a cross-check against an independent
    measurement that fails is a contradiction to chase, not noise — but chase it with an experiment that varies
    the confounder (`-mcs`), not with a story about the column you are already staring at.

81. **Recompute a load-bearing quantity from primitives; never patch its factors.** The unique-remote-bytes
    estimate in one paragraph went 20 GiB/10 % → 30 GiB/15 % → 11.5 GiB/5.7 %. The first used a hand-waved
    2.0 MiB/expert; the "correction" multiplied the loader's per-expert figure by three projections, not knowing
    it already covered gate+up+down. Both revisions moved the conclusion in whatever direction the argument needed,
    which is the tell: each was a factor tweak rather than a recomputation from shapes and bytes-per-weight.
    The checked form is `(2560×640×2 + 640×2560) × 0.24 B ≈ 1.18 MiB/expert` — derived, and it agrees with the
    loader's 1.172 MiB. Same discipline as `check_tables.py`: a claim that can be derived should be *computed*,
    and a correction that changes the direction of an argument deserves the extra minute.

82. **Two optimizations that remove the same term are substitutes: sum the term, never the speedups.** Parent
    prefill on 2.05 measures 4609 ms, of which the `-mcs` slope puts **2619 ms (57 %) in the CPU expert leg**;
    `-mcpa` removes 948 ms of that leg, and moving the whole leg to the card costs 734 ms. Both mechanisms
    therefore bottom out at the same place — 4609 − 2619 + 734 = **2724 ms = 1.69×** — and arithmetic that
    multiplied `-mcpa`'s 1.26× by the card's 1.69× would promise 2.13× from a system that cannot exceed 1.69×.
    Same failure as LESSONS 66's unmatched-batch gain, one level up: after fixing the baseline, fix **which term
    each mechanism acts on**, then combine over a shared term by removing the term once. Three rules: (1) report
    each mechanism's share of the named term (948/2619 = 36 %), not just its ratio; (2) the competitive baseline
    must include free knobs — `-mcpa` is a flag anyone can set, worth +30-50 % on prefill and ~nothing at decode
    steady state, so every plain-mode “today” figure in this chapter understates the bar the B70 must clear;
    (3) a substitution claim is cheap to falsify: prefill time vs `-mcs` should flatten from 10.23 ms/expert to
    ~6.5 ms/expert with `-mcpa` on. Write that prediction down before testing it, because the case where it fails
    means the 948 ms came from somewhere else entirely and the model above is wrong. **Result: tested, and it held
    (10.24 → 5.59 ms/expert, −45 % against −36 % predicted), and the residuals taught two more things — see 83.**

83. **A mechanism whose action count does not scale with the problem is a capacity mechanism, not a scaling one:
    read the counter, not the ratio.** `-mcpa` measured +30 % on 2.05 and +50 % on 2.68, which invites the story
    "more remote experts ⇒ promotion helps more, so scale it up." The counter says otherwise: promotions were
    390 / 383 / 384 at `-mcs` 256 / 384 / 448 — a **fixed ~8 experts per layer regardless of how many experts were
    remote** — and the relief per marginal expert decayed (4.96 ms saved per expert over 256→384, 3.88 over
    384→448), with the `-mcpa` fit visibly dirtier than the plain one (±30 ms vs ±2 ms). The mechanism is a
    bounded window, so its benefit is capped while the problem it fights grows. Two rules: (1) when a ratio and a
    counter disagree, the counter is the mechanism and the ratio is its shadow — a speedup number cannot tell you
    this, a promotion count can, which is exactly why LESSONS 66 insisted on adaptation counters alongside latency;
    (2) before proposing a second, bigger instance of a placement mechanism (here: the B70 as another promotion
    destination), check whether the first instance is capacity-bound or policy-bound. If the promoted set is a
    fixed window because the destination is cramped, the right answer is *capacity* (the card holds 84 of 288 GLM
    experts per layer, or any model's whole half-mass tail) and the policy can stay coarse. If it were
    policy-bound, more VRAM would not have helped.

68. **Identical ALU is not an identical control - dump the ISA and compare the memory instructions.**
    (Numbering note: this entry sat above 69–70 until a repair edit moved 69/70 in front of it; content is
    unchanged and is what LESSONS 68 refers to.)
    `probe_slm` exists to answer one question: is the reuse prefill needs cheaper via SLM staging or via letting
    a work-group's items read the same global bytes concurrently. I made the three modes do the same ALU chain
    per dword and considered that fair. The ISA said it was not: the baseline's loop lowered to 80
    `load.ugm.d32x4.a64` (four dwords per lane per instruction) while the two shared-read loops - written with
    lane-strided indexing `p[j + li], p[j + ITEMS + li], ...` - lowered to 320 scalar `load.ugm.d32.a64`. I was
    partly measuring vectorisation, and reaching for a memory-hierarchy explanation of a codegen difference.
    Rewriting the loops lane-contiguously gave all three modes exactly 80 d32x4 loads and the comparison became
    honest - the SLM conclusion survived (staging is 1.5-6x worse, and the reason is +458 instructions of extra
    on-chip traffic: 89 `store.slm` + 80 `load.slm` on top of the 80 global loads, plus occupancy), visible only
    in the dump. The *other* half did not: I had written that concurrent global reuse is therefore "free" at
    1690 vs 1348 GB/s, and a second ISA read showed both bodies are dominated by scalar address arithmetic
    (149 `add`, 100 `shl` against 32 vector loads) with the reuse mode doing 32x the loads per iteration for a
    near-identical time - i.e. a math-bound probe, which cannot license a memory-hierarchy rate. Retracted to a
    hypothesis for `probe_gemm` to test (see the CONFIDENCE block in `out_prefill_gemm.txt`); the lesson
    generalizes past vectorization: matching ALU is not enough, you also have to prove the two modes are
    bounded by the resource you are attributing the difference to. Rules: (1) when two kernels are compared on a memory question,
    prove from the ISA that they are equal on load width, load count, and scratch traffic - not from the source
    you meant; (2) `%scratchloc` is declared in every kernel on this target, so "there is a scratch reference"
    is not evidence of a spill - check for scratch ld/st, or you will explain your result with a thing that is
    always true; (3) a surprising result is an invitation to look at the generated code before the narrative,
    not after.

71. **Before rewriting something "from first principles", measure the old version's arbitrary-looking constant —
    it is more often a boundary with a lost reason than cargo cult.** The prefill/rows work was stalled on
    rev L's `rows <= 16` cap, which read like a heritage artifact: the accumulator register law says rows=32
    wants ~16 GRF and rows=64 ~32, against `numGRF=128`, so deeper rows looked obviously free. `probe_xmx`
    was written clean-room to test exactly that (no slab axis, no sub axis, no fusion, no staged layouts, no
    cap) and it produced: spill 0 B at NF=1/2, **1792 B at NF=4, 7808 B at NF=8** — the cliff sits at 16 rows,
    precisely where rev L's cap sat, because the *A operand tile* also scales with rows and the two together
    exceed the file. The cap was right; only its justification was missing. So the cheap experiment before a
    rewrite is to reproduce the old constant's boundary in the new code and ask what breaks there — and when
    the rewrite lands within 7 % of the tuned original at the original's operating point after deleting three
    subsystems, that is evidence the deleted machinery was load-bearing (rev L's `sub` axis was buying device
    fill), not that it was noise.

72. **"Eliminate the spill" is not an objective function; time is.** The same probe, one variable (where the
    A operand lives), measured both directions:
        NF=4   hoisted: 70.2 us, 2914 inst, 1792 B spill  |  streamed: 90.5 us, 2702 inst, 0 B spill
        NF=8   hoisted: 316.8 us, 6298 inst, 7808 B spill |  streamed: 179.3 us, 5429 inst, 3392 B spill
    Making NF=4 spill-free cost 29 %: DPAS needs its A operand in a register, so trading one wide
    `load_dw<ADW>` for 2*NF narrow ones serialises load->dpas per fragment, and a *mild* spill is cheaper than
    that serialisation. Past ~4 KB of spill the ordering flips back. Two rules follow: (1) report spills and
    time as separate measurements and let time arbitrate, never optimize the proxy; (2) when a tradeoff is
    monotone in one parameter, encode the choice on that parameter with `if constexpr` — here NF was already a
    template parameter, so the crossover costs nothing, whereas a runtime flag would sit inside the tile loop
    and repeat the band-as-runtime mistake (item 13m).

73. **A knob that silently ignores its input is worse than no knob: it manufactures confident numbers.** During
    this sweep six cells were measured intending to vary split-K via `DPAS_KS=`, which rev L honours but
    `probe_xmx` takes as a *positional* argument — so all six ran KS=1 and looked internally consistent (the
    timings differed only with rows, which is exactly what a real KS=1 series does). Caught because the
    `items/launch` field, printed on purpose for the fill analysis, never changed when KS did. Two fixes now
    standard in these probes: print the derived quantity the knob is supposed to move (items, fill, rows/item),
    and make a mismatched/absent oracle print `check: FAILED ...` rather than nothing — rev L prints no check
    line at rows>16, which is the same silence that nearly validated a stale binary last session.

74. **The sign of a scheduling comparison is a function of E. Measuring it at the convenient size can report the
    exact opposite of the truth.** Slab co-scheduling lost at E=16 — B/A = 0.97x / 1.15x / 1.02x at 1/2/4 slabs,
    bit-exact, protocol-clean — and I wrote "co-scheduling does not buy re-use" as a general statement. At E=512
    (251 MiB of weights per projection, 10.5x L2) the same two arms measure **1.05x / 0.91x / 0.85x**: it wins
    9-16 %, and the win grows with slab count. Nothing about the mechanism changed; what changed is which
    constraint binds. At E=16 both arms sit near the 2048-slot capacity, so B's extra wave costs more than the
    re-use saves; at E=512 both arms are deep in many-wave territory, capacity is irrelevant, and the only
    surviving difference is fetching 251 MiB four times sequentially versus concurrently.
    Two rules extracted. (1) A "does X help" probe must run at the operating point's *resource occupancy*, not
    merely its shape: E, and hence items-per-launch, moves this family between two regimes, and any conclusion
    drawn in one is void in the other — the same reason D8 takes the fusion decision on grid fill rather than on
    model identity. (2) When a negative result is cheap to scale, scaling it is a better use of an hour than
    adding a variant: the E=16 conclusion had already propagated into three documents before the E=512 run
    reversed it, and the correction cost less than the original sweep. Corollary for reporting: qualify
    scale-dependent negatives in the headline, not just in the caveats — "at E=16" belongs where a reader will
    hit it, because "co-scheduling does not buy re-use" was defensible and wrong in the same breath.

63. **Recompute the statistic per unit; never collapse the distribution first.** The planners took `counts_for()`
    = *layer 0's* expert-selection array and treated it as "the routing distribution" for every batch-scaling
    number. A live trace showed how bad that proxy was (layer 0 of Qwen3.8@2.68 touched 289 of 512 experts in
    1,920 picks, top-10 mass 0.177, while other layers are far more peaked) - and then my first repair introduced
    a second, subtler error: averaging the 48 normalized per-layer vectors into one distribution. That is valid
    for *linear* functionals of p (expected picks per expert index) and wrong for two things I immediately used it
    for: (a) distinct-expert counts, which are concave in p, so the collapsed vector over-predicted union(32) by
    2.2x (22.8x vs the per-layer mean 10.9x, measured against the trace itself: 10.3x), and (b) residence hit
    rate, an ORDER statistic - the engine keeps the hottest N experts *per layer*, and a globally chosen top-N is
    strictly worse than 48 per-layer top-Ns, so the mixture read h = 74.5% where the per-layer value is 99.3% for
    6.05 bpw. Downstream, that single mis-aggregation moved 6.05's b=16 throughput by 6.6x (874 vs 132 t/s) and
    re-labelled which home binds. Rule: when replacing a scalar input with a distribution over units, ask "is the
    derived functional linear in it?" - if it is a union, a maximum, a top-N or any order statistic, evaluate per
    unit and average the RESULTS. Corollary worth keeping: the failure surfaced as a *crash first* (`rows=22.1 is
    above 16, where dp4a was never measured`), because the corrected union pushed rows-per-expert past the
    measured range for the first time; a guard that has never fired is not evidence the path is unreachable, and
    `layer_us()` was letting one infeasible candidate family abort the whole search instead of being skipped.

64. **A measurement is only valid for the population it was taken from, and "the routing distribution" is not one
    population.** The plan's `union(rows)` multipliers reproduced the engine's stored profile to within 1-8% - the
    transcription was faithful and the independence math checks out to ~1.5% against Monte Carlo on real data. The
    live trace nevertheless lands at 10.3x vs 21.9x for b=32: half the work the plan expected the card and CPU to
    do at batch. Cause: the stored profile accumulates across sessions, so it is roughly the distribution an
    *operator's mixed traffic* sees, while a 192-token single-user stream is far more concentrated (half its
    picks fall in 23 of 512 experts). Neither is "the" truth: for a batch of concurrent unrelated users the plan
    is about right, for a batch drawn from similar sessions the plan is 2x pessimistic, and the difference is a
    deployment fact, not a modelling error. Two rules: state which population a measured input represents before
    plugging it in, and where the answer is regime-dependent, make the regime a scheduling lever rather than an
    assumption - here, session affinity (keep one session's tokens on the worker that already holds its narrow
    expert set) converts the pessimistic case into the optimistic one, and is a better outcome than picking
    either number. Also note the direction of the original doubt: architecture.md section 12 guessed "expect
    h_live < h_profile"; measured, h_live is *higher* (99.8% at 50% residence) and the profile's flaw was in its
    tail shape, not its concentration. Being wrong about the direction of a predicted bias is survivable; never
    having measured it is not.

65. **A wrapper that forwards CLI flags must declare them all, and a filtered background arm must prove it ran.**
    `bench_live_trace.py` owns `-m/--model_dir` and forwards `--moe_cpu_split`-style flags to the engine. When a
    matrix arm passed `-mcpa`, argparse read it as `-m cpa` and overwrote the model path: the load died with
    `FileNotFoundError: 'cpa/config.json'`. Two things made that expensive instead of trivial. (1) The arm runner
    piped each run through `grep` to keep the log small, so the traceback never reached the file and the arms
    simply printed nothing - a rerun of the LESSONS 52 failure with a new mask. (2) The whole first matrix had
    silently skipped its `-mcpa` arms, and I had already concluded from the surviving arms that the pinned arena
    was irrelevant. Rules now enforced in-tree: any script that forwards engine flags uses
    `parse_known_args()` and treats leftovers as fatal (with the `-mcpa -> -m cpa` trap spelled out in the error);
    every background arm asserts its OUTPUT FILE exists (`[ -s file ] || echo "arm failed"`), because a 4-second
    arm in a 6-minute matrix is the tell; and a run that prints nothing is a crashed run.

66. **Judge an adaptive design by its mechanism and on its own horizon, not by the nearest scalar.** My first
    read of `--moe_cpu_pinned_arena` was "costs decode 12-35%": at 192 tokens, 2.05 went 71.8 -> 63.0 tok/s, 2.68
    58.3 -> 48.8, Qwen3.5 126.9 -> 82.1 (the last reproducing a recorded acceptance figure, which made it feel
    settled). Reading the ENGINE'S OWN counters at 384 tokens inverted it: plain mode performs **0 promotions and
    0 demotions** across 48 layers - hot experts cannot migrate to the GPU at all without the pinned arena - while
    `-mcpa` performs 3,689, and by pass 2 the throughputs are equal (64.5 vs 64.6 tok/s). The mechanism needs a
    horizon longer than the comparison I ran, so the metric I chose could only ever report the cost. Two rules:
    when a design's benefit comes from adaptation, measure an adaptation counter (promotions, swaps, cache fill)
    alongside the latency metric; and run the arm at least as long as the mechanism's settling time - here, the
    placement learning curve is itself worth 1.6-1.8x (pass 1 -> pass 2), so any short A/B compares warm-up
    schedules, not designs. Related trap in the same report: a "7-93x gain" that came from comparing a measured
    b=1 baseline to modelled b>1 throughput. A gain is only meaningful at matched batch; where the matched
    baseline is unmeasured, print absolute numbers and say so.







