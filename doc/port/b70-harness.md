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
| E4 **status: failing, and now measurable** | `probe_gemv` is the first real GEMV: bit-exact against the NumPy trellis reference, 61.4 GB/s at R = 1 (300 MiB of checkpoint bytes), falling to 13.8 / 4.6 / 0.2 GB/s at R = 8 / 32 / 128. The gate below is unchanged as a target; what changed is that `b70-kernels.md` §2a now names the specific structures to transplant (register-resident `prod`, one `dot_acc` per weight-row against pre-splatted activations, grouped dword-pair extraction) and the instruction-count model predicts the measurement to 10 %, so the next revision is engineered, not hunted | measured by `probe_gemv`, not projected — and it shows the ordering question (E4b) is downstream of this one, since clustered and scattered differ by <1.5 % while the kernel is instruction-bound |
| E4 expert read rate | the real GEMV, cold selections, per rate (K = 2.5 / 3 / 8), **measured at the footprint decode actually presents** (a layer's resident slice, not a synthetic 1.5 GiB sweep) and reported alongside the footprint: pass = **above the scattered mid-band for that geometry** (≥ 250 GB/s Qwen3.8-class, ≥ 230 GB/s GLM-class at ≥ 512 MiB); report G-weights/s and J/GiB too. Also run one case **below 64 MiB per launch** (a b=1 decode layer is 14 MiB on Qwen3.8, 51 MiB on GLM, and 32 MiB per card at 2 cards) — the rate curve has no measured points there and GLM's rate fell 208→132 GB/s between 128 and 64 MiB, so the extrapolation the "N cards divide the bytes" argument relies on is currently unmeasured | landing in the bottom of the footprint-matched bracket (`out_rates_footprint.txt`) means the ordering rules of b70-kernels.md §3a are **not implemented**, not that the card is slow. Note that the absolute rate varies ~2× with footprint, so a comparison across footprints is worthless — this is why the gate names the condition, not just a number |
| E4b locality conformance | the same GEMV measured twice at the same footprint: correct grid order + one contiguous per-layer VRAM block, versus expert-innermost ordering + per-expert allocation; the ratio must land in **1.08–1.99×** in the predicted direction, at every footprint tested | a cheap falsifiable check that §3a's rules are implemented rather than believed; the ratio is the robust quantity (it reproduces to ≤3 % across runs where absolutes move 2×) |
| E4c banding revisited | inside the real GEMV, native vs `(nt/8)·tiles_k+kt` tile addressing at decode footprints, ≥ 3 repeats | the microbenchmark says 0.96–1.05× with no consistent sign and its variance exceeds the effect; this is the only measurement good enough to justify a load-time repack, since the alternative cost is losing byte-identity with the 3090 kernels (expert migration) |
| E5 link efficiency at prefill | ≥ 80 % of the measured `probe_bandwidth` rate for the job sizes in use | the CPU path's equivalent was the 28.6 % DMA share |
| E6 end to end | Qwen3.5 `-mb 255` decode within **5 %** of the all-GPU reference; prefill ≥ 2× the `-mcs 192` incumbent; Qwen3.8 `-mba` ≥ 2× the `-mcs 410` incumbent (377 tok/s @1024) | placement-controlled, both models, cold and warm |
| E7′ | rows-to-B70 ≥ **4×** "stream everything to the 3090" at 2048 rows, on a model whose experts are `S_b`-resident | successor of the CPU path's E7 (`stream_t`) gate: it re-checks, per model, that the streaming decision is still the right one — the crossover is `expert_bytes/(hi+2·ho)` ≈ 184–200 rows/expert here |
| E8 host cost | the engine must add ≤ 20 µs/token of *parent* host time; engine-thread CPU time charged separately | the forward thread is already 3.6 ms/token |
| E9 capacity curve | `tok/s` vs `S_b` capacity (sweep `-mb`/quota from 0 to full) must be **monotone and smooth**: no adjacent pair differing by more than 15 %, and ≥ 90 % of the resident-case rate at 50 % capacity. The property that says the cache degrades gracefully instead of cliff-edging. **Sweep batch on the same axis** (b = 1, 2, 4, 8, 16): `plan_operating_point.py` predicts Qwen3.8's hiding margin falls 4.9× → 1.3× → 0.5× across b = 1 → 4 → 8 because distinct experts per layer grow almost linearly with rows while the parent's window is weight-bound; the measured curve must show a crossover batch, and it should agree within ~2× | the graceful-degradation property; a cliff means placement or admission is thrashing, not that the kernels are slow. The batch axis is the check on the "offload is hidden at decode" claim, which is a small-batch statement and must not be shipped as a general one |
| E10 parent window vs batch | `T_parent` per layer, measured with the CPU child disabled, at b = 1, 2, 4, 8, 16, for Qwen3.8 **and GLM** (GLM's is unknown and is the denominator of every hiding argument in §4a/§7, including the "how many cards" rule `max(T_b70/N, T_cpu) > T_parent`) | without it the oversized-model card recommendation is unfalsifiable: the table predicts GLM is parent-bound from 2 cards onward, which changes the recommendation from "buy another B70" to "nothing helps until the parent is faster" |
| E10 tier-maintenance budget | the planner's offline statement — `\|res\|` per layer, one-time `fill` seconds, break-even churn fraction — reproduced by the live run within 2× on `fill` and 1.5× on the migration traffic it actually generates | the earlier per-pick `h_min` formulation is kept only as the `churn = 1` pathological bound; it charged an upload per pick and so mis-ranked migration against the CPU |
| E11 churn, the number the migration policy actually rests on | measure `churn_fraction` = fraction of `S_b`'s resident set replaced per 1000 decode tokens, from **two dated snapshots** of the placement table (or per-window counters in the engine), on one corpus and then across a corpus switch; report it against the two §4a thresholds, which nearly coincide (~0.31 %/token where maintenance saturates the link window, ~0.36 %/token where it stops beating the CPU). Alternating two disjoint corpora must return within 2 % of the single-corpus steady state within `EXL3_MOE_B70_WINDOW` tokens, and admissions per step must stay under the budget | the profiles on disk **cannot** answer this: they are cumulative snapshots with no time axis, and two proxies tried here were invalid (value-set overlap between layers, spatial half-split of one array — `LESSONS` 16). Below the break-even, migration serves the residue; above it, the CPU does, and the placement verdict flips |
| E12 admission/eviction cost | one `S_b` admission (expert upload) measured cold: ≤ 1.15 × `expert_bytes / link_rate`; and a decode step *while* N admissions are in flight ≤ 1.1 × the no-admission step (proves the low-priority queue and the budget actually work) | measured with the queue priority from §4a; without it, activations and admission fight over one queue and both lose |
| E13 spanning fraction `σ` | fraction of rows computed in more than one piece, **per layer** as well as overall, from a real routing trace and from the live run; the two must agree within 10 %. The offline number uses an independence approximation and currently puts `σ` at **92–99 % for every model retaining a residue**, so the hypothesis under test is "spanning is the norm" | if a real trace shows much *less* spanning, co-occurrence is structured and `COLICATE` earns its keep; if it agrees, the 3-way combine and the ~2× prefill payload are permanent |
| E21 throughput vs concurrency | measured aggregate tok/s at rows = 1, 2, 4, 8, 16, 32, 64 with the binding worker identified (parent / B70 / CPU) from timestamps, against `plan_concurrency.py`'s prediction: parent binds to b≈4, B70 binds from b≈4–8 onward, and tok/s should reach ~307 (2.68 bpw) and ~146 (6.05 bpw) at b=8 | this is the gate that says whether the offload *scales*: if measured tok/s flattens earlier or lower than predicted, the B70's per-step byte cost is worse than the footprint-matched rate implies (launch/queue overhead, insufficient reuse across rows of the same expert, or slot depth starving the pipeline) |
| E22 XMX eligibility in the real prefill kernel | for the chunk size in use, log rows-per-expert per layer and count experts above the 272-row crossover; the DPAS path must be taken for ~exactly the predicted set (0–13 of 512 at R=2048) and must not be taken below it | the prediction is the cheap half; if the measured compute-bound threshold sits far below 272 the DPAS operand layout or the int8 path is leaving throughput on the table, and §4's route choice changes |
| E23 batched-decode schedule (b70-kernels.md §3b) | same kernel, two grids — per-row GEMV ordering vs expert-bucketed ordering — at rows = 8, 32, 128, 256; must reproduce a **1.4–1.7×** ratio at 2.68 bpw and **1.1–1.4×** at 6.05, with bit-identical outputs between the two schedules, and must show throughput flattening where `T_parent` overtakes | the whole case for a large-`rows` schedule is measured locality; if the ratio is absent the grid is not actually bucketed (E4b's failure mode at scale), and if the outputs differ the two schedules are two kernels in disguise |
| E24 integer-DPAS rows crossover (b70-kernels.md §2c items 1, 13, 13b) | build the A=u8-bytes / B=s8-repeated / C=int32 DPAS variant for one geometry (Qwen3.8 gate_proj, `tn`=40, `[[sycl::reqd_sub_group_size(16)]]`) and measure G-weights/s at rows = 1, 2, 4, 8, 16 against rev C's 205 (R=1) and 137 (R=4). The refit model (`slots/weight ≈ 5.8 + 1.15·M`) predicts **×1.8 at R=4, ×2.6 at R=8, ×4.2 at R=16**, which is the falsifiable claim; it must also pass Gate A bit-exactly, since this route has no float in it, and use the bench's reference-free invariant (A=B=1 ⇒ C = ITERS·K) to prove the VNNI operand layout before trusting any rate | if the gains do not appear, the cost is in assembling the A operand — llm-scaler's own warning that "assembling it with strided register moves cost more than the DPAS itself saved" — and then §3b's rows schedule needs a different fix and `plan_kernel_split.py`'s rescue factors stay as they are; if it appears, the rows-collapse term disappears from the operating-point and placement models, and §4a's eligibility bar (26 rows, not 272) has to be re-run through `plan_concurrency.py`. **Step 1 done** (`probe_dpas.cpp`, `out_dpas.txt`): the byte-replicated integer form is bit-exact against `y_ref` and its rows curve is flat to within 3 % (18.3 → 18.8 µs over rows 4 → 16 at E=1), versus rev C's saturated ~520–580 G-weight-tokens/s ceiling — so the row term is confirmed removable. **Step 2 is measured too** (`probe_dpas2.cpp`): assembly costs ~2.7 slots/weight, rev E runs at 8.3–11.1 slots/weight **flat across rows 1→16**, bit-exact, netting ×1.13 / ×2.31 / ×3.98 at rows 4 / 8 / 16 while **losing ×0.79 at rows 1**; operand sourcing (L2-resident global scratch, *not* SLM) mattered more than any kernel detail (§2c item 13e). What remains for this gate: re-measure on the other eight checkpoints (GLM n=4096/tn=256 and the tn=32 geometries especially, since grid width is the known lever), measure `down_proj` so per-layer figures can be restated, optimize rev E (matrix objects are constructed inside the inner loop, two barriers per tile, scratch geometry untuned), and validate the two-schedule policy — dp4a for rows ≤ 2, DPAS for rows ≥ 4 — with both paths held to Gate A in CI. **Step 3 measured** (`probe_dpas3.cpp`, rev F, warm + interleaved, all nine switch combinations bit-exact vs rev E): the activation operand's **layout** was the cost — VNNI-packed B (`x * 0x01010101`, `ext_intel_packed`, same tensor size) is the only switch that pays on both projections (×1.06–1.19 gate, ×1.04–1.08 down), and `psu` reaches 87.7 µs at rows=1 against rev E's 106.2; prefetching trellis loads is **×0.58** (refuted — decode is issue-bound, not latency-bound); and SLM-vs-global sourcing is now flat to 1.5 %, so item 13e is superseded by 13k. `down_proj` is measured: crossover moves to **rows ≈ 3–4**, two-schedule policy intact. **Protocol requirement from this step: ~20 s sustained warm-up plus round-robin interleaving, and record per-round values** — cold, the identical command varies 2.3× and any sequentially-ordered A/B manufactures effects (LESSONS 37). Still open for this gate: partial-sum traffic (128·KS/k bytes per weight — 0.5 B/w at k=2560/KS=8, 1.0 B/w on down_proj at KS=4 — the largest unpriced lever, which rev F does not touch), the other eight checkpoints (GLM `n`=4096/`tn`=256 and the `tn`=32 geometries), `u` is valid only for K ≤ 4, and the ISA dump (now working) should be used for B′7's spill check rather than inferred. **Item 5 priced** via a new duplicate-store ablation (`DPAS_F=d`, numerics untouched): marginal PART cost is 0.2–0.8 µs/MiB while weights+partials fit L2 and 1.3–2.2 µs/MiB (≈450–770 GB/s) once they don't, so deleting PART+combine is worth ~5–11 % (gate, KS=8) to ~15–25 % (down_proj, KS=4) — and partials, not grid-fill, are what cap useful KS (cap by `128·KS/k ≲ 0.4 B/w`). Next candidate was specializing the DPAS N dimension (16 token columns are computed at every batch size and b=1 discards fifteen of them) — **withdrawn after counting instructions (§2c 13n): mads per tile are column blocks × k byte-blocks, independent of N**, so it would buy ~0.4 µs of PART for a 12-site layout change. Replaced by M consolidation: one 16×16 accumulator instead of two 8×16 halves the mad stream, halves the PART stores and drops an A load per byte-block, at every row count including rows=1; untested, gated on whether `joint_matrix<int32, accumulator, 16, 16>` is accepted with these int8 operand shapes and whether the `r → (row, column-block)` store map survives. **Item 5 then solved structurally** (`DPAS_F=x`: experts in the grid, `KS=1`, PART = `2·E·n·16` so `128/k` B/weight independent of KS and E): ×1.19–×1.32 gate and ×1.04–×1.30 down, near-flat rows curve, bit-exact at rows 1/4/16 on both projections, and the edit checked neutral (×1.00) against the HEAD build in the same window. Crossover is now **between rows 1 and 4** — so rows = 2–3 needs its own measured point before the engine's dispatch threshold is set, and `tn·E` must stay ≳ 256 groups (low-E models need grid = `tn·E·KS`, untested). **Cost factorization added** (`DPAS_LOADS_ONLY`, `DPAS_NO_STORE`): trellis unpack + A-operand assembly is 66 % of the kernel, `joint_matrix_load` 21 %, the mads 2 %, PART stores free — identical at rows 1 and 8 — so both shape ideas in item 13n (M=16 consolidation, wider K) are dead and the ESIMD register-operand route is the only remaining lever. `DPAS_NO_MAD` must never be quoted as the cost of mads, since it also removes the operand loads; that conflation is what put a fake 62.7 µs mad term in `out_dpas.txt` |
| E25 fusion: gate+up in one launch, down+finalize in one (§2c items 3–5) | fuse with the weight tensors kept separate (no concat copy) and measure the Qwen3.8 b=1 per-layer composition against the measured 80.7 + 80.7 + 77.8 = 239.2 µs; report grid work-items before and after, because fusing divides the grid by top_k | their fused decode is a measured win in a comparable kernel, but our win can only come from activation reuse plus one fewer launch — and their own warning (M=5 with ROWS=4 leaves 2560 work-items where the unfused pair had 20480) means a fusion that starves the grid is a loss at b=1 |
| E26 launch tax through the real submission path | enqueue cost of a B70 GEMV issued the way the engine will issue it (pinned-flag handoff), set against the vendor's measured ~48 µs of host per enqueue in a torch-mediated stack | the whole decode budget assumes ~3–6 µs of handshake per layer; if any part of the path drifts toward torch-dispatch cost, the fusion items invert in priority and b=1 hiding dies no matter what the kernel rate is |
| E27 launch-policy fit: work-item target and split-K table (§2c items 7–8) | sweep work-items per launch over (E × tn × ks × ROWS) on the geometries we own — including the worst case measured so far, `tn` = 32 at 76.5 G-w/s — and fit (a) a work-item target analogous to their 8192 and (b) a `select_ks`-style table keyed on **work-items, not groups**; the fit must predict the measured optimum ks within one doubling for every shape | the current policy is a three-point hand fit, and the vendor thresholds are expressed in work-items, which is exactly why they read as aggressive against our "400 groups of 32 lanes needed no split-K" result. Without this fit the planner cannot pick a grid for any unmeasured model × batch combination, which is most of them |
| E28 same-size tile repack to cut the fixed unpack cost (b70-kernels.md §2c item 16) | repack the trellis ring within a tile so a lane's 8 windows fall inside one wide load (still K bits/weight — zero extra bytes, zero extra DRAM), then measure slots/weight for rev C and rev E against the current baselines (rev C 5.8 fixed + 1.15/row; rev E 8.3–11.1 flat); must confirm the repacked stream still satisfies Gate A and that the one-time pass at model load is acceptable | this is the only surviving form of "prepare the operands once": full expansion is measured-dead — rev D *is* the free-assembly design and loses to rev E at every row count (135.8 vs 95.5 µs at rows=1), and 4 B/weight collapses h from 0.98 to ~0.08. If the fixed cost drops to ~3 slots, one decode kernel serves every batch size and the rows-keyed two-path policy disappears; if it does not, the engine carries two schedules. **Premise corrected before building (E28 is now an implementation task, not a format change):** solving `K·i ≡ 16 (mod 32)` shows dword-aligned window groups already exist in the ring for every shipped K (periods 8/16/32, all dividing 256), so aligned extraction needs no repack, no extra bytes and does not cost byte-interchangeability with the 3090/CPU kernels — E4c never comes due here. Measured ceiling of the change, from `probe_gemv -DGEMV_CONSTSHIFT` (numerics deliberately wrong, timing only): **×1.52 / ×2.07 at rows=1**, ×1.17–1.26 at rows 4/8 (`out_gemv.txt`). Remaining work: build rev F (aligned-group lane assignment) for rev C and rev E, hold Gate A, and report slots/weight against the 75.1 µs / 5.8-slots baseline. **CLOSED without any reassignment:** rev C's lanes already own contiguous 32-window groups, and their intra-dword offset is lane-invariant (a function of `a4` and `K` only — verified K=2..6), so simply compiling K in (`probe_gemv -DGEMV_KCONST`) delivers the ceiling bit-exactly: gate ×1.90 and down_proj ×1.89 at rows=1, per-layer 226.0 → 126.1 µs, output bit-identical to the default build. Remaining engine work: instantiate the decode kernel per trellis K (2..6) and re-measure the other recipes; the DPAS crossover moved to rows ≈ 5 |
| E18 the parent's real spare bandwidth | measure the 3090's expert-read rate **while its own per-layer work runs concurrently** (2.1a's byte bill predicts 86.4 MiB/layer of non-expert streaming ≈ 97 µs of a ~250 µs window, i.e. ~39 % bandwidth duty and ~570 GB/s nominally spare) and the achieved rate for a GEMV issued into that stream | the placement objective in 2.1a treats `S_g` work as serial at 936 GB/s. If contention drags the effective rate toward the B70's 292 GB/s, the "hottest on the 3090" argument loses its rate half and only the parallelism asymmetry survives — which moves E19's balance point sharply |
| E19 placement rule, `order` vs `lpt` | same model, same homes, both `EXL3_MOE_B70_BALANCE` settings, tok/s at b = 1, 4, 8 with the profile pinned, **at two recipes at least (one with a residue, one without)** — `plan_quant_scaling.py` predicts the rule flips between them: `lpt` +3…+9 % at 2.05–5.05 bpw, `order` +43 % at 6.05 bpw. Prediction from `plan_parent_budget.py`: tie at b=1 (parent-bound), `lpt` +13 % at b=8 on Qwen3.8, `order` +9…+20 % on GLM while a CPU residue survives | the user-visible form of the "share the hot experts fairly" question: the measurement decides whether the planner should pick the rule from `h` as designed, or one rule simply dominates |
| E20 replication with steering (only if E14 shows surplus) | with `h` = 100 % and ~12 GiB spare on Qwen3.8, home the hottest N experts on **both** cards and steer each pick to the less-loaded home; must beat `lpt` by > 5 % at b ≥ 4 to justify abandoning disjointness | disjointness is argued from capacity scarcity, which does not hold where capacity is surplus; replication is the only mechanism that decouples placement from load-balancing, and also the only one that spends that surplus |
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
| `probe_rates.cpp` | the read-bandwidth and arithmetic-density measurements behind E4/E4b/E4c, §2.2's layout verdict and §4a's device rate: exact-cover self-check, warm-up, round-robin modes, one specialised kernel per mode (compile-time), an 8-accumulator mode (R9) to separate dependency latency from instruction count, and argv validation. Artifacts: `out_rates.txt` (1.5 GiB sweep), `out_rates_repeat.txt` (3 independent runs/geometry → the ≤3 % ratio repeatability the gates are set against), `out_rates_footprint.txt` (64 MiB–2 GiB, where the ~2× absolute-rate swing shows up) |
| `b70_bench_kernel.py` | B′ + E4: GEMV/GEMM rate vs rows × experts × rate × layout, cold selections, both the scattered and the clustered orderings |
| `b70_bench_engine.py` | E1–E3, E8: real jobs through the ring with the engine child live (the `notes/bench_handoff.py` analogue) |
| `b70_prof.py` | per-layer decode/prefill attribution + power phases (the `notes/prof_e2e.py` analogue; CUDA events on the parent, engine-side `EXL3_MOE_B70_PROF` gap/queue/compute per 64 jobs, hwmon sampler) |
| `plan_concurrency.py` | the rows axis for all three workers: `T_parent(rows)` (fixed overhead calibrated to the measured T_layer(1), batch-independent weights, plus state and KV per sequence-layer) vs `T_b70(rows)` (expert union × h, i.e. reuse already credited) vs `T_cpu(rows)`; aggregate tok/s and which term binds; plus the per-expert row distribution that decides XMX eligibility (`out_concurrency.txt`) |
| `plan_kernel_split.py` | prices a separate large-`rows` decode schedule against the only addressable factor (rate, via grid order), reports the rescue and where `T_parent` caps it, and the activation path's share of B70 time (`out_kernel_split.txt`) — the numbers behind b70-kernels.md §3b and gate E23 |
| `plan_quant_scaling.py` | the recipe axis of every claim above: five Qwen3.8 checkpoints, capacity/residency/decode time per quant, driven by newly measured K = 4/5/6 tile rates; drops the one K=6/64 MiB row that exceeded the copy peak (`out_quant_scaling.txt`, `out_rates_footprint_hiq.txt`) |
| `plan_parent_budget.py` | the parent's two bills: capacity (what must be resident: streamed non-expert, KV/token and recurrent-state from `config.json`, and proof the n-gram/embedding tables are host row-gathers not VRAM) versus traffic (MiB/layer the parent streams, hence its bandwidth duty); then `P_order` vs `P_lpt` against the min-max objective — the analysis behind §2.1a and gates E18/E19/E20. Ships a scale selftest (MiB @ GB/s → µs) because a 1000× slip in that one conversion silently made every policy tie |
| `probe_gemv.cpp` + `dump_gemv_case.py` | the real mul1 trellis GEMV: checkpoint trellis bytes dumped by the python helper, `y` validated BIT-EXACT against `tests/testlib/trellis.py`, both grid orders bit-identical, rates for E × rows grids, and two timing modes (burst-throughput and single-launch round trip) (`out_gemv.txt`) — the instrument behind E4/E4b/E23 |
| `gate_gemv.py` | the wide correctness gate: rev C vs rev B bit-for-bit across E × rows × split-K × grid order (88 configs), exploiting that every partial is an int32 integer sum so regrouping cannot change the value |
| `check_gemv_oracle.py` | independent einsum oracle for the raw accumulator, shape-asserted, with `--xmode zero/ones` synthetic-activation controls; reproduced rev B exactly (sd 0) and is what localised the splat bug |
| `probe_dpas.cpp` / `probe_dpas2.cpp` + `dump_gemv_case.py --with-abytes` | E24's instruments. rev D: the integer XMX path fed by a byte-expanded A (assembly made free) — bit-exact, flat rows curve, and proof that materializing A is a dead end at decode footprints. rev E: the real thing — trellis bytes unpacked in-kernel and assembled into the A operand (u32 store per window), with `DPAS_A_GLOBAL`/`DPAS_B_GLOBAL` to source operands from SLM or an L2-resident global scratch and `DPAS_NO_MAD`/`DPAS_NO_UNPACK` to price each half separately (`out_dpas.txt`). rev F: `probe_dpas3.cpp`, one switch per suspected cause (`DPAS_F` ∈ p/s/f/u, default all-on), SLM sized from the operand sources, `DPAS_CHECK=<file>` for bit-identity against a saved rev E output, and a two-flag ablation (`NO_MAD`+`NO_UNPACK` together) that prices fixed overhead — measured 19.4 µs of 126.8 at KS=8/rows=1. Two further switches: `d` duplicates PART writes to price partial traffic (a floor, not the subsystem cost — LESSONS 39), and `x` moves experts into the grid with `KS=1`, which is the structural fix `d` was invented to justify. `DPAS_LOADS_ONLY` / `DPAS_NO_STORE` complete the factorial (assembly vs operand loads vs mads vs stores) — necessary because `DPAS_NO_MAD` conflates the first three |
| `sweep_models.py` + `out_gemv_models.txt` | discovers every MoE checkpoint on disk (geometry read from the tensors, expert-bearing layer from the index), validates numerics **per trellis recipe**, and measures rev B/rev C per projection × experts × rows with interleaved min-of-N, deriving per-layer decode time (`2 × gate + down`) — the instrument behind §2b items 9/12/13 and §2c's prioritisation |
| `plan_operating_point.py` | the operating point: distinct experts touched per layer vs batch (Monte-Carlo over real selection counts, `topk` read from each `config.json`), × `h`, sampled against the measured rate-vs-footprint curve → µs/layer, ms/token and the crossover batch behind §7's decode table and E9's batch axis |
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
