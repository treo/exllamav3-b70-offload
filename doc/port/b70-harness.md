# B70 offload: harness

Continuous verification for the port: correctness, speed, and **utilisation** (board power, per the
brief: the best available indicator that the card is actually doing the work). It exists so that
every commit can answer three separate questions without ambiguity:

1. *Did the arithmetic change?* → levels A/B′ (kernel numerics, bit-exactness), independent of any
   protocol or model.
2. *Did the data movement or the protocol change?* → level D (liveness, ordering, geometry).
3. *Did the machine's work change?* → level E (per-hop, per-layer, per-token cost) and the power
   channel (which cannot lie about idleness).

Hygiene rules inherited from the prep work and enforced mechanically, because each of them once
produced a wrong conclusion in `doc/prep/measured-costs.md`:

* **pin placement state** per run (delete `~/.cache/exllamav3/expert_stats/<hash>.json`, or set
  `EXL3_MOE_CPU_SPLIT_STATS`, or redirect `block_sparse_mlp_cpu.EXPERT_STATS_DIR`) and print which
  start was used; the measured effect of forgetting this is +12–22 % on decode.
* **rotate expert selections** in any GEMV microbenchmark (working set ≫ L2's 18 MiB / L3's 64 MiB).
* **use real text** for anything routing-sensitive; random token ids wash the profile out.
* **state the measured link rate** with every bandwidth figure (sysfs is wrong on this box: it says
  `2.5 GT/s ×1` while carrying 14.4 GB/s).
* **report profiled runs separately** — `EXL3_SPLIT_PROF`/`HANDOFF_PROF` cost ~30 % by themselves,
  and on the B70 side `.wait()`-based instrumentation costs 24 µs per call (**[M]** `LESSONS` 1).
* **warm up** before timing, and take medians/p90 over ≥200 samples, never a mean of 3.

## Levels

### A — format, bit-exact (unchanged, plus two B70 checks)

`notes/verify_trellis.py` and `tests/testlib/trellis.py` remain the spec; A1–A7 are re-run
unchanged. Added:

| check | how | gate |
|---|---|---|
| A8 upload fidelity | after `b70_upload_experts`, copy the B70 VRAM block back and `memcmp` against the source tensors, for every layer and every rate present | byte-identical; run in CI for one layer per rate and in full nightly |
| A9 layout agreement | `exl3_b70_tile_layout(K)` (or its "native" answer) must be the single source for uploader, spill reader and any B70→GPU transfer; assert the three readers agree | one function, three call sites, one test that would break if a second table appeared |

### B′ — B70 kernel numerics (the new level)

The B70 kernel is a *new* implementation of an existing contract, so it is graded three ways at
once, on real expert weights:

| gate | bar | why |
|---|---|---|
| B′1 vs fp64 oracle | rel RMS ≤ **2.5e-2** per layer at rows 1/4/16 (the band the int8 scheme already occupies: the CPU path measures 1.45–2.16e-2) | the port must not change the numeric class |
| B′2 vs the CPU tier **at identical quantised inputs** | rel L2 ≤ **0.05** (the suite's `SCALAR_TOL`) | separating quantiser drift from GEMV drift; feeding both backends the same `x8/q/Σx8` is what makes this meaningful |
| B′3 vs the 3090 path | ratio to `reconstruct` ≤ ~25× | parity with Gate B2 |
| B′4 determinism | **bit-identical** over ≥30 repeated calls, and unchanged when the k-slice count changes for the same shape | catches the atomic-accumulation mistake §3 of `b70-kernels.md` |
| B′5 quantiser parity | the CUDA-side and B70-side quantisers (`QUANT_INPUT=1` vs `2`) agree **bit-for-bit** on the same fp16 rows | cheap, and it has historically been where Hadamard normalisation bugs hide |
| B′6 codebook vectors | the K=4 cheat-sheet table (state / product / byte-sum / weight for six `(r,c)` pairs incl. the wrap case `(0,0)`) and `bytesum ∈ [0,1005]` over all 65536 states, run *on the device* | the shift-by-32 and tail-biting traps are silent-corruption bugs |
| B′7 no spills / one dp4a | `zeKernelGetProperties` → `spillMemSize == 0 && privateMemSize == 0` for every shipped kernel × rate; ISA dump shows a single instruction for the dot | Recipe B's whole premise is register residency |

Scripts: `notes/b70/acceptance_kernel_b70.py` (mirrors `notes/acceptance_kernel.py`, adds the
fixed-input B′2 mode and dumps the quantised tensors it used).

### C — whole-model agreement (unchanged policy)

`notes/acceptance_model.py` + `notes/acceptance_report.py`, scored by
`tests/testlib/e2e.py::assert_logits_agree`: median KL < `max(abs_median_kl=1e-2, 4×floor)`, mean <
`max(0.05, 4×floor)`, confident top-1 ≥ 0.97, all logits finite. Measured reference headroom on the
CPU path is 14–32× on median KL, so the CPU bar is not tight and the B70 port must not need it to be.

Placements to score, each at both cold and warm placement start:

```
ref            all-GPU (Qwen3.5 only; Qwen3.8 does not fit the 3090)
b70_split      -mb 192 (Qwen3.5, all experts fit B70 VRAM)
b70_all        -mb 255
b70_auto       -mba on Qwen3.8 (≈90 % of 36.3 GiB into 31.9 GiB, the rest spilled)
b70+cpu        -mb … plus -mcs … (Phase 5)
cpu_split      -mcs 192 (the incumbent, for the diff)
```
plus the three measurement paths Gate C3 requires (teacher-forced, cached prefill+decode, batched
decode) and `OUT_F16=1` as a *separate* scoring, never folded into the default numbers.

### D — protocol and liveness (every existing invariant + B70-specific)

All of `doc/prep/port-acceptance.md` level D applies unchanged (descriptor-before-flag, cyclic
32-bit flag compares, `consumed` gating, ring-full throttle with side-effect-free refusal,
`COMPUTE_GATED` skipping compute *and* readback, watchdog unblocking, uniform `hi/ho/topk`,
contiguous-only copies, `/dev/shm` capacity, reload cleanliness, TP refusal, host affinity). Added,
each as a test rather than a note:

| invariant | test |
|---|---|
| cross-process pinned sharing: the engine child can `register_host_memory` the parent's registered segment (page-multiple sizes, `LESSONS` 5) | **proven**, `notes/b70/probe_crossproc.py` 10/10 (`out_crossproc.txt`) — promoted to `tests/b70/test_region_attach.py` so a driver update cannot silently break it |
| every kernel that writes the shared region writes *all* of it, and publishes last | `tests/b70/test_store_discipline.py`, from `probe_stores2.cpp` / `probe_unreg.cpp`: N×20 reps per pattern, **comparing every word**, plus the negative case that a `sycl::atomic_ref` on the region loses the device (`probe_stores.cpp` case 7) so no code path can regress into it |
| publishing `done` from a B70 kernel is ordered after the payload stores | `test_flag_order.py`: 10 000 rounds of `write payload → fence → flag`, host/3090 verify the payload matches the seq every time (this is the `LESSONS` 4 bug class: `atomic_ref` on a foreign pointer poisons the queue *silently*, so also assert the payload, never only the flag) |
| the engine never calls `.wait()`/blocks on the job path | an instrumented build counts blocking calls and asserts zero during a generation; a regression here costs 24 µs/layer silently |
| device loss surfaces as an exception, not a hang | kill the engine mid-generation / inject `ZE_RESULT_ERROR_DEVICE_LOST`; the parent must raise within one `begin_pass` and leave no stream parked (mirrors the existing `EXL3_MOE_MEMOPS=0` timeout tests) |
| a resident engine (T2) releases the card | unload/reload and a second process must get the whole device back; measure the drain time (`probe_resident.cpp` prints it: 21–371 µs) |
| no PCIe poll storm | assert round-trip latency of the T2 loop stays ≤ 2× the single-poller baseline while N groups are parked (`probe_resident.cpp` as a regression test) |
| **homes are disjoint** | no expert may be resident on both devices at once: `tests/b70/test_placement_disjoint.py` asserts `S_g ∩ S_b = ∅` from the placement tables *and* that each device's local id mapping is injective; a replication bug would silently double capacity use and make every capacity number in the report meaningless |
| a spanning row combines in a fixed order | the 3090 → B70 → CPU add order is deterministic and B′4-style bit-repeatability survives it; a row spanning all three homes is an explicit fixture, not an accident of routing |
| B70 VRAM accounting | upload + scratch accounted in the memory planner; `-mba` never over-commits; unload frees everything (no leak across reload) |
| queue/region lifetime | `unregister_host_memory` on unload; a second load in the same process re-registers cleanly |

Current-status rule from the prep work stands: the CPU suite must stay green
(`pytest tests/moe_cpu tests/kernels/moe_cpu_host tests/kernels/moe -m "not slow"`, 395 passed /
29 skipped / 22 deselected on the reference box) *while* `tests/b70/` is added, since the CPU worker
is the oracle.

### E — performance floors

Every gate below is a *floor or ceiling on a measured quantity*; "explained by a mechanism from
E1–E5" is an acceptable outcome, "within noise" is not (see the hygiene rules at the top).

| gate | reference / floor | note |
|---|---|---|
| E1 empty (all-`-1`) job | B70 handshake ≤ **8 µs**/layer; the CPU path is 20 µs, submit+flag is 5.0–6.3 µs **[M]**, resident doorbell 3.2 µs **[M]** | if this regresses past ~10 µs the layer count multiplies the loss |
| E2 flag round trip host↔B70 | ≤ 8 µs (measured 5.0–6.3) | twice per layer |
| E3 payload movers | 16 KiB in ≤ 9 µs, 16 KiB out ≤ 9 µs (**[M]** 7.6–9.0) | use DMA in, kernel stores out (**[M]** 258–283 µs for the same read done as a one-lane dependent chain, `LESSONS` 7) |
| E4 expert read rate | the real GEMV, cold selections, per rate (K = 2.5 / 3 / 8): **≥ 300 GB/s floor, 420 GB/s target**, judged against the measured bracket for this access pattern (287–313 scattered / 321–492 clustered **[M]**); report G-weights/s and J/GiB too | below 300 GB/s is treated as a **grid-ordering or allocation bug**, not a hardware limit (b70-kernels.md §3a) |
| E4b locality conformance | the same GEMV measured twice: correct grid order + one contiguous per-layer VRAM block, versus expert-innermost ordering + per-expert allocation; the ratio should land in the 1.0–1.7× range `probe_rates` measured, in the predicted direction | a cheap falsifiable check that §3a's rules are implemented rather than believed |
| E5 link efficiency at prefill | ≥ 80 % of the measured `probe_bandwidth` rate for the job sizes in use | the CPU path's equivalent was the 28.6 % DMA share |
| E6 end to end | Qwen3.5 `-mb 255` decode within **5 %** of the all-GPU reference; prefill ≥ 2× the `-mcs 192` incumbent; Qwen3.8 `-mba` ≥ 2× the `-mcs 410` incumbent (377 tok/s @1024) | placement-controlled, both models, cold and warm |
| E7′ | rows-to-B70 ≥ **4×** "stream everything to the 3090" at 2048 rows, on a model whose experts are `S_b`-resident | successor of the CPU path's E7 (`stream_t`) gate: it re-checks, per model, that the streaming decision is still the right one — the crossover is `expert_bytes/(hi+2·ho)` ≈ 184–200 rows/expert here |
| E8 host cost | the engine must add ≤ 20 µs/token of *parent* host time; engine-thread CPU time charged separately | the forward thread is already 3.6 ms/token |
| E9 capacity curve | `tok/s` vs `S_b` capacity (sweep `-mb`/quota from 0 to full) must be **monotone and smooth**: no adjacent pair differing by more than 15 %, and ≥ 90 % of the resident-case rate at 50 % capacity. The property that says the cache degrades gracefully instead of cliff-edging | the graceful-degradation property; a cliff means placement or admission is thrashing, not that the kernels are slow |
| E10 tier-maintenance budget | the planner's offline statement — `\|res\|` per layer, one-time `fill` seconds, break-even churn fraction — reproduced by the live run within 2× on `fill` and 1.5× on the migration traffic it actually generates | the earlier per-pick `h_min` formulation is kept only as the `churn = 1` pathological bound; it charged an upload per pick and so mis-ranked migration against the CPU |
| E11 thrash convergence | alternate two disjoint corpora (chat vs code) and record tok/s and `h` per window: must return within 2 % of the single-corpus steady state within `EXL3_MOE_B70_WINDOW` tokens, and the admission count per step must stay under the budget | the online half of the policy: the static profile cannot foresee a topic switch |
| E12 admission/eviction cost | one `S_b` admission (expert upload) measured cold: ≤ 1.15 × `expert_bytes / link_rate`; and a decode step *while* N admissions are in flight ≤ 1.1 × the no-admission step (proves the low-priority queue and the budget actually work) | measured with the queue priority from §4a; without it, activations and admission fight over one queue and both lose |
| E13 spanning fraction `σ` | fraction of rows computed in more than one piece, **per layer** as well as overall, from a real routing trace and from the live run; the two must agree within 10 %. The offline number uses an independence approximation and currently puts `σ` at **92–99 % for every model retaining a residue**, so the hypothesis under test is "spanning is the norm" | if a real trace shows much *less* spanning, co-occurrence is structured and `COLICATE` earns its keep; if it agrees, the 3-way combine and the ~2× prefill payload are permanent |
| E14 predicted vs realised homes | the planner's offline `h` and ms/token against the live run. Profile-derived `h` is an **upper bound** (decayed cumulative counts, 1e-27 dust entries, recorded by an already-adaptive run), so the gate is `h_live ≤ h_profile` with `h_live` reported as the real figure | a large gap (GLM's 70.8 % → say 45 %) hardens the oversized verdict and grows the CPU share; decision-changing, hence a gate rather than a note |

### U — utilisation and power (the "is the card actually working" channel)

Sensors available on this box, no extra daemon needed:

| signal | source | use |
|---|---|---|
| board energy | `/sys/class/drm/card1/device/hwmon/hwmon7/energy1_input` (label `card`, **µJ**) | ΔE/Δt = W; `J per GiB of expert weights read` = device-independent efficiency |
| package / VRAM temperature | `temp2_input` (`pkg`), `temp3_input` (`vram`) | throttling detection (slope, not absolute) |
| power limit | `power1_cap` (275 W here) | headroom, and to notice a BIOS/PL change between runs |
| engine activity, clock | Level Zero sysman `zesEngineGetActivity` (`activeTime`/`stallTime`) and `zesFrequencyGetState` | true duty cycle and clock residency, to separate "busy but stalled" from "idle" |

Method — the parts that are easy to get wrong:

* **Baseline is the same process with the engine parked**, not a cold card: an idle process with a
  live SYCL context draws 45.6 W here versus 14.6 W with no context (**[M]**), so a naive "power
  during generation" figure attributes 31 W of context overhead to the kernels.
* Sample at 10–20 ms from a background thread into a timestamped log; the benchmark writes
  **phase markers** (`decode_layer`, `prefill_chunk`, `staged`, `parked`, `spin_only`) with
  timestamps, and the report integrates power per phase.
* Report **J/token** and **J/GiB-moved** next to tok/s. Two configurations with the same tok/s and
  different J/token are not equivalent (one is burning power polling, waiting or re-reading weights),
  and a resident engine that spins without work is exactly the case that shows up only here.
* Sanity-check magnitudes rather than trusting a single reading. A Qwen3.8 decode token with all
  experts on the B70 moves ~0.55 GiB of expert weights (48 layers × ~8 experts × 1.465 MiB). At
  120 tok/s and an average of 150 W that is ~1.25 J/token, i.e. **~2.3 J per GiB moved**. Two
  configurations with the same tok/s but a 3× J/GiB gap are not equivalent — the expensive one is
  spinning, stalling or re-reading (typically a cache-policy mistake, an over-frequent doorbell
  poll, or weights being re-uploaded per layer instead of once), and tok/s alone will not show it.
  Conversely a prefill run that never rises above ~120 W is not using the card, whatever it reports
  for throughput.

Scripts (all in `notes/b70/`, extending the existing harnesses rather than replacing them):

| script | feeds |
|---|---|
| `build.sh` | builds the probes/shim (`icpx -fsycl`); run before any B70 test |
| `probe_transport.cpp`, `probe_notify.cpp` | E1–E3, and the link/bandwidth constants the policy derives from |
| `probe_resident.cpp`, `probe_doorbell.cpp` | T2 sizing, `D` poll-storm and drain tests |
| `b70_shim.cpp` + `probe_cross.py` | D cross-vendor region tests (8/9; the exception is the one-way `cudaHostRegister` refusal) — run before anything else touches the protocol |
| `probe_crossproc.py` | D cross-process region tests (10/10): engine child attaches, kernel writes reach parent *and* a 3090 DMA, a 3090 memop reaches a kernel in the child, wait retires on the child's flag |
| `probe_stores.cpp`, `probe_stores2.cpp`, `probe_unreg.cpp`, `probe_coherency.cpp` | the store-visibility family behind the two rules in architecture §10a |
| `probe_rates.cpp` | the read-bandwidth and arithmetic-density measurements behind E4/E4b, §2.2's layout verdict and §4a's device rate: exact-cover self-check, warm-up, round-robin modes, one specialised kernel per mode (compile-time) |
| `b70_bench_kernel.py` | B′ + E4: GEMV/GEMM rate vs rows × experts × rate × layout, cold selections, both the scattered and the clustered orderings |
| `b70_bench_engine.py` | E1–E3, E8: real jobs through the ring with the engine child live (the `notes/bench_handoff.py` analogue) |
| `b70_prof.py` | per-layer decode/prefill attribution + power phases (the `notes/prof_e2e.py` analogue; CUDA events on the parent, engine-side `EXL3_MOE_B70_PROF` gap/queue/compute per 64 jobs, hwmon sampler) |
| `plan_placement.py` | E13/E14 and the input to `-mba`: reads the checkpoint headers plus a routing trace (`sel` per layer, dumped by `notes/acceptance_model.py`) and enumerates candidate cut points, reporting per-home byte share, pick share, `σ`, and predicted ms/token for each — the placement decision is then made offline, before any kernel exists |
| `b70_bench_capacity.py` | E9–E12: capacity sweep, hit-rate/`h_min` accounting, corpus-switch thrash test, admission cost with and without concurrent jobs (drives `-mba` and the admission knobs) |
| `b70_power.py` | the U channel alone: sampler + phase integration + `J/token`, `J/GiB`, clock/temperature, used by every other script |
| `b70_run_e2e.sh` | E6/E7′: `eval/perf.py` over named configs (`b70_split`, `b70_all`, `b70_auto`, `b70_plus_cpu`, `cpu_split`, `ref`) with the profile pinned per row |
| `b70_compare.py` | diffs a run against `notes/b70/baseline.json` with per-gate tolerances (±30 % protocol-bound, ±10 % bandwidth-bound, absolute for the numerics levels) and refuses to compare runs whose placement state or link rate differ |

## Cadence

| when | what | budget |
|---|---|---|
| every commit | A (incl. A8/A9), B′1–B′7 for the rates the change touches, D protocol tests, E1–E4 on one model | < 5 min (no model load beyond one layer; `probe_*` re-run only if the toolchain or topology changed) |
| every push | full A/B′/C/D, E1–E8 single config, U phases for decode and one prefill chunk | < 25 min |
| nightly / pre-merge | `b70_run_e2e.sh` across configs × both models × cold and warm placement, `-mba` spill stress, reload/autosplit, T2 residency, `b70_compare.py` against the rolling baseline | hours |
| on any "it got slower" | re-run the U sampler and `b70_prof.py` *before* changing code: on the CPU path every unexplained slowdown was handshake- or policy-related, never kernel-related | minutes, and always before a code change |

## What the harness deliberately does not test

* Bit-exactness between the B70, the CPU and the 3090 paths (different rounding by construction;
  B′2 pins the *inputs*, not the outputs, where that is achievable).
* Greedy-token equality (Gate C4 stays a non-goal), and equality across `OUT_F16`, `SWIZZLE` or
  engine-tier settings.
* Determinism across slot/ring geometry changes — `SLOT_ROWS` changes chunking and therefore
  accumulation grouping; B′4 holds only for a fixed shape.
