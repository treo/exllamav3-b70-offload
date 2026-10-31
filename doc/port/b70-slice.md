# B70 vertical slice: the one experiment that closes the composition blockers

Status: **design only** — this is the last artifact of the planning phase, not implementation. It exists because
three blockers (stall/wall-clock fidelity, engine integration shape, and whether the plan's arithmetic composes at
all) cannot be closed by another kernel probe. Every rate in this plan came from a kernel that never met another
workload.

## What is already decided before this slice starts

Nothing here is re-opened by the slice; the slice tests *composition*, not the pieces:

- D14's crossing point (now wired into `policy()`), D17's 16-row + co-resident-slab dispatch, D18's per-bucket
  primitives, D21's reuse of the engine's slot / weight-staging / flag architecture, and the no-`.wait()` +
  completion-by-pinned-flag rules from the decode close-out.
- Correctness oracle already exists: `notes/b70/gate_dpas.py` (206 checks, 0 fails) and `check_gemv_oracle.py`
  against engine-produced references.

## The single question

> When a real router in a real engine run hands assignments to the card, does the layer finish in the time
> `layer_us_joint()` says it should?

If yes, the plan's throughput numbers inherit a validated composition model and the build can proceed kernel-first.
If no, the gap is the **stall term** the model omits — and D19 already tells me its sign: the model will be
*optimistic*, because GLM's measured step is 71 % waiting.

## Scope: one layer, three configurations, no new kernels

Take **one MoE layer** (`model.language_model.layers.12.mlp`, which has a stored live profile and dumped cases) and
route a subset of its experts to the card. The remaining 41 layers are untouched, so every regression is
attributable and the parent's own non-expert leg stays a constant.

| config | experts on card | what it isolates |
|---|---|---|
| **S0** control | 0 | the baseline wall/device pair for the same process, same seed, same corpus — the number the card must beat |
| **S1** card as CPU-substitute | the coldest ~64 experts (the ones the CPU home serves today) | the substitution D15 measured on prefill, now under a live router: does moving the *same picks* to a faster home pay as predicted |
| **S2** card as capacity | the hot ~84 experts (a GLM-shaped tier, static) | D16's central claim: capacity that makes promotion unnecessary — with `-mcpa` held **off** so the mechanisms do not confound |

S1 and S2 use the *same* card-side kernel and the same dispatch code, differing only in the placement vector. That
is deliberate: a placement-only difference cannot hide a mechanism change.

## Wiring (all inside existing seams — this is the point)

1. `exllamav3/model/moe_cpu_host.py` already owns slots (`EXL3_MOE_CPU_SLOTS`, `SLOT_ROWS`), weight staging
   (`WSLOTS` × `WSLOT_MB`), the pinned flag region (`MOE_FLAGS_SIZE`), affinity (`EXL3_MOE_HOST_CORES`) and
   per-component registration (`moe_cpu_component`). The slice adds a **second worker behind that same host
   object**, selected by expert id rather than by a new queue.
2. `exllamav3/modules/block_sparse_mlp_cpu.py` chooses home per expert today; it becomes the one place the card is
   consulted. Picks are already sorted by expert id upstream (`block_sparse_mlp.py:106`), so the gather the card
   wants is partly free.
3. Card side: `notes/b70/b70_shim.cpp` (doorbell + resident loop, already exercised by `probe_resident`) submits
   the rev-L GEMV kernel with a `best_launch()`-chosen (fused, KS) schedule, signals completion by writing a
   pinned flag. **No `sycl::atomic_ref` on the shared region at any scope** (close-out: `UR_RESULT_ERROR_DEVICE_LOST`
   repro) and **no `.wait()` on the parent's critical path** — the host spins on the flag with a bounded budget and
   falls back to the CPU worker if the card is late, which also gives the slice its graceful-degradation test.
4. Weights: staged into card VRAM once per expert on admit, permuted on admit per D3-alt/E29 normalize-at-admit
   (0.66 ms per GLM expert, 0.09 ms per Qwen@2.05 expert at the measured 13.4 GiB/s link).

Deliberately **not** built for the slice: prefill paths, verify/MTP batching, co-resident slab dispatch, the
3090↔B70 split rule, promotion policy, telemetry dashboards. Each is a later phase with its own gate; adding any
of them here would destroy attribution, which is the only thing this slice produces.

## What gets printed (the artifact, not a log)

Per config S0/S1/S2, at b = 1 and b = 8, 200+ steps, warm, min-of-N, plus:

| quantity | source | why the slice exists |
|---|---|---|
| wall µs/layer, device µs/layer, **stall = wall − device** | `torch.profiler` + CUDA events, same classifier as `bench_engine_step.classify` | the model has no stall term; this measures one |
| card µs/launch and its idle fraction | shim timestamps | separates "card slow" from "card starved" |
| parent µs/layer with card present vs absent, same process | S0 vs S1/S2 | the interference term the `max(·)` balance silently assumes is zero — E36 (`run_plan_close.sh` S2) prices it at process level; this prices it at handoff level |
| picks served by card / by CPU / by parent | counters, not ratios (LESSONS 83) | placement did what it was told? A placement that silently serves nothing makes every other number meaningless |
| predicted µs/layer from `layer_us_joint(geom=)` | planner, same inputs | the comparison the whole plan rests on |
| output equality vs CPU reference on the same assignments | `gate_dpas.py` oracle | speed without this is not a result |

Acceptance: predicted within **15 %** of measured wall, or the model gains an explicit stall term fitted from this
one run and revalidated against `out_engine_step.txt` §11's GLM numbers (which are the only independent
wall-vs-device pair the plan currently owns).

## The failure modes I expect, and how the slice detects each

1. **The card never receives work** (router hands it nothing, or placement is overridden later in load). Caught by
   the counters row; this is the same class of bug as the silent `ValueError` fallback that quietly disabled the
   joint dispatch for a whole ladder (LESSONS 67), and it is why counters come before ratios.
2. **Starvation, not slowness** — one reserved host core (`EXL3_MOE_HOST_CORES = 1`) cannot issue fast enough at
   b = 1, where a launch is 16–19 µs and the submit path is microseconds of work per assignment. Idle-fraction
   column distinguishes it from a slow kernel.
3. **Flag coherency at the second order** — the decode probes proved the direction that matters, but a live engine
   adds a second writer (the CPU worker) touching the same region. Bounded spin + fallback makes this a
   performance failure rather than a hang.
4. **Allocation churn** — card buffers allocated per step (0.216 ms each) instead of resident. Timestamps show it
   as a constant additive term per launch.

## Effort and sequencing

- Shim already does doorbell + resident submit (`b70_shim.cpp`, `probe_resident`, `probe_notify`,
  `probe_coherency`); the oracle and cost model are written; the seam in `moe_cpu_host.py` is identified.
- The genuinely new code is the placement hook in `block_sparse_mlp_cpu.py` and the flag-completion path — small,
  but it touches the load path, so it must sit behind `EXL3_MOE_B70=0` by default and satisfy the bit-identical
  gate in `b70-harness.md` before any measurement is trusted.
- If the slice cannot be built in a few days, the blocker is not the slice: it means the handoff seam is deeper
  than §13 of `b70-architecture.md` claims, and that answer is worth the attempt too.

## What each outcome changes

| outcome | consequence |
|---|---|
| within 15 % | the plan's arithmetic composes; proceed kernel-first, and the prefill multiplier becomes a defensible projection instead of **[P]** |
| model optimistic by a roughly constant per-layer term | add that term as a measured stall constant; re-run the split rule (D14) and the verify-batch crossover, since both are functions of the parent's *wall* leg |
| model optimistic in a batch-dependent way | the `max(·)` balance is structurally wrong; the plan needs a queueing model, which is a bigger revision than any kernel here |
| card starved (idle ≫ busy at S2) | the single reserved host core is the constraint, not the card: revisit `EXL3_MOE_HOST_CORES`, batch the submits, or move issuing onto the card side entirely |
| picks do not reach the card | integration, not performance — fix before believing anything else |