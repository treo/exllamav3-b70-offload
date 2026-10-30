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







