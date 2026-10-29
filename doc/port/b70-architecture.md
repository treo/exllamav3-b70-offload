# B70 offload: architecture

Anchors are to this tree (`dev`, v1.6.5 + the `doc/prep` commits). Costs marked **[M]** are measured
on this box (see [`notes/b70/README.md`](../../notes/b70/README.md) for the raw logs); **[P]** are
projected from hardware figures and must be re-measured before they are quoted anywhere else.

---

## 1. The one structural decision: the B70 is a *worker*, not a *device*

Everything the model itself runs (attention, dense MLP, router, shared expert, sampling, KV cache)
stays on the CUDA device, in torch, unchanged. The B70 takes the role that `moe_cpu_host.py`'s child
process plays today: **it consumes jobs from the shared-memory ring and fills the slot's output**.
It is reached through a Level Zero / SYCL engine, not through torch (there is no `torch.xpu` in this
venv, and even with one there is no reason to make the model's forward aware of a second vendor).

Why that framing rather than "make the B70 a second compute device the model loads experts onto":

* The parent side of the protocol is then *literally unchanged*: the fused decode handoff, the four
  flags per slot, the `COMPUTE_GATED` empty-job trick, the `consumed` gating, the ring geometry, the
  watchdog, the deferred collect, and every Level-D invariant in `doc/prep/port-acceptance.md` keep
  holding because nobody on the CUDA side knows who did the arithmetic. Measured proof that this is
  possible: `probe_cross.py` A1/A2/A3 **[M]** — one page-locked region is written by a B70 kernel and
  read by the 3090, a `cuStreamWriteValue32` from the 3090 is visible to a B70 kernel, and a flag
  written by a B70 kernel retires a `cuStreamWaitValue32`.
* The five capabilities `doc/prep/moe-cpu-offload-data-paths.md` §9 lists as "what a port needs from
  the accelerator" map onto this box as:

| requirement | CUDA today | B70 engine | status |
|---|---|---|---|
| page-locked host memory with a device mapping | `cudaHostRegister(PORTABLE\|MAPPED)` + `cudaHostGetDevicePointer` | `register_host_memory(ptr, len, ctx)` on the region the parent already registered | **[M]** works; the region must be pinned by CUDA, *not* by the xe driver (`cudaHostRegister` on `sycl::malloc_host` fails `invalid argument`) |
| kernels that store to / load from it, system-scope ordered | `int4` stores, `__threadfence_system()`, `ldg_acquire_sys` | plain volatile stores + `sycl::atomic_fence(acq_rel, system)` | **[M]** works for stores (100/100 reps, cold and host-dirtied lines, in-process and cross-process); **loads are latency-bound (~65 ns each)**, so the payload comes in by DMA; a `sycl::atomic_ref` at *any* scope on a registered foreign pointer loses the device (`UR_RESULT_ERROR_DEVICE_LOST`) — publish flags with a fenced volatile store (`LESSONS` 4) |
| stream-ordered flag wait/write without SM occupancy | `cuStreamWaitValue32` / `cuStreamWriteValue32` | not needed on the B70 side: it *produces* flags (kernel store) and *consumes* them by spinning host-side, exactly as the CPU worker does | no Level Zero equivalent exists (checked `ze_api.h` 1.18: only events/timestamps); not required |
| multiple streams + events, contiguous async copies | compute + copy streams, `wready_ev`/`wconsumed_ev` | one in-order queue for jobs + one for weight transfer; `sycl::event` for the engine thread only (**never** on the parent's path) | **[M]** `.wait()` costs 24 µs, so event waits belong to the engine thread's idle path, not the per-job path |
| the GPU-side expert kernels | `exl3_moe*`, `reconstruct*`, `hgemm*`, `moe_unswizzle_trellis` | unchanged on the 3090; a *new* implementation for the B70 (see `b70-kernels.md`) | this is the port |

*Consequence for the plan*: no change to `BlockSparseMLP.forward`'s structure, no new torch device,
no TP interaction, and the CPU worker stays available both as a fallback and as the **numerical
oracle** for the new kernels.

---

## 2. Where the bytes live

### 2.1 Four disjoint homes, three computers

**An expert has exactly one home, and its home does its arithmetic.** No replication between the
3090 and the B70:

```
   S_g   home = 3090 VRAM      936 GB/s peak   quota: COMPUTED, see 2.1a (16.6 GiB on Qwen3.8/GLM at
                                               4k ctx, not the 2 GiB an earlier draft assumed)
   S_b   home = B70 VRAM       ~608 GB/s peak <- the new tier, filled to capacity
   S_c   home = host DRAM      ~45 GB/s CPU   the arena; also the source for a 655 us upload to S_b
   S_d   home = NVMe           ~5.0 GB/s [M]  read through a bounded pinned ring when needed
```

#### 2.1a Pricing the parent's other work: two bills, not one

The 3090 is also running attention, the linear-attention states, the shared expert, the router and the
sampler, so `S_g`'s quota cannot be assumed. `plan_parent_budget.py` splits that into the two things
"the 3090 is busy" actually means, because they pull in opposite directions (**[M]**, byte bills from
the shard headers; `out_parent_budget.txt`):

**CAPACITY bill — what must be resident.** Both reference models are hybrid linear-attention with
compressed KV (Qwen3.8: 36 of 48 layers linear, 12 full at 2 KV heads → 24 KiB/token, 108 MiB state per
*sequence*; GLM: 34 of 45 linear, 11 MLA-sparse with `kv_lora_rank` 512 → 22 KiB/token, 136 MiB state),
and the tables that look terrifying are not resident at all: Qwen3.8 carries **49.91 GiB of per-layer
n-gram embeddings** plus embed/lm_head, which `modules/row_table.py` row-gathers from host/disk
(`ngram_gather_cpu`) — capacity on disk, a few rows per token in traffic. What must actually sit in the
24 GiB is 4.05 GiB (Qwen3.8) / 5.67 GiB (GLM) of streamed non-expert weights, plus KV/state, plus
reserve → **~16.6 GiB free for experts at 4k ctx, b=1**, i.e. 265 of 512 slots per layer on Qwen3.8 and
42 of 288 on GLM. The 2 GiB this plan previously assumed was a guess, and it was 8× too stingy:

| `S_g` | Qwen3.8 `h` | CPU ms/token | GLM `h` | CPU ms/token |
|---|---|---|---|---|
| 2 GiB (old assumption) | 97.6 % | 0.42 | 70.8 % | 19.6 |
| 8 GiB | 99.6 % | 0.07 | 75.5 % | 16.4 |
| **16.6 GiB (computed)** | **100.0 %** | **0.00** | **81.1 %** | **12.6** |

That single correction moves GLM's hit rate by 10 points and its CPU residue by 35 % — more than any
hot/cold ordering choice does — and it makes Qwen3.8 fully homed with ~12 GiB of *surplus* capacity,
which reopens replication as an option (below).

**TRAFFIC bill — what competes for bandwidth.** A decode token on Qwen3.8 streams 86.4 MiB/layer of
non-expert weights = **96.8 µs of the ~250 µs parent window**, i.e. the parent runs at ~39 % of its own
peak bandwidth at b=1. So the 3090 is *latency-bound, not bandwidth-bound*, at small batch: expert reads
there are cheap in bytes/second terms and the 3090 remains the faster expert home even while busy
(~576 GB/s nominally spare versus the B70's measured 292). Nobody has measured that spare, because the
estimate assumes perfect overlap — E18 does.

**So what does the parent's other work do to placement?** It changes the objective, not the ordering.
Costs on `S_g` are *serial* with the parent's own stream; `S_b` and `S_c` run concurrently. The right
objective is therefore the per-layer maximum, not the sum the earlier draft minimised:

```
wall/layer = max( T_parent + picked_bytes(S_g)/936 ,  picked_bytes(S_b)/rate_b ,  picked_bytes(S_c)/47.4 )
```

and this is where the "distribute the hot experts across both accelerators, still disjoint" idea lands.
`plan_parent_budget.py` evaluates it as an LPT greedy (walk the hot list once, give each expert to the
home whose resulting term is smallest) against the frequency-ordered cut (`P_order`, the plan's rule):

| model | rows | `S_g` slots | `P_order` µs/layer | `P_lpt` µs/layer | winner |
|---|---|---|---|---|---|
| Qwen3.8 | 1 | 30 | 253 | 253 | tie (parent-bound) |
| Qwen3.8 | 8 | 30 | 314 | **278** | fair split, +13 % |
| Qwen3.8 | 8 | 120 | 304 | **299** | fair split, +2 % |
| GLM | 1 | 30 | **571** | 623 | ordered, +9 % |
| GLM | 4 | 120 | **695** | 865 | ordered, +20 % |

Which is a genuinely mixed answer, and the reason is visible in the objective: **fair-splitting wins
when the B70 is the binding worker** (Qwen3.8 at b≥4, where the 3090's spare rate beats it) and **loses
when the CPU is binding** (every GLM row above, where `S_c` still carries 19–30 % of picks): spreading
hot experts over both VRAM homes necessarily leaves *colder* experts to the CPU, and the CPU term is
`bytes/47.4` — the most expensive byte on the box. So the rule is not "hottest on the 3090" and not
"parity"; it is *minimise the maximum term*, which under a CPU residue means pack the fast homes with
the hottest first, and once the residue is gone (Qwen3.8 with the computed slice: `h` = 100 %) means
balance the two VRAM homes by load, which is what `P_lpt` does.

The measured rate ratio also kills the original argument against replication. §2.1 said the homes'
read rates were "within 1.5×" — that was spec-to-spec (936/608); footprint-matched they are 3.2×
apart on Qwen3.8 and 7× on GLM. Disjointness still holds for GLM (no spare capacity to duplicate
with), but Qwen3.8's ~12 GiB surplus makes a *third* option real: replicate the hottest few experts on
both cards and steer each pick to the idle home, which decouples placement from load-balancing entirely
at the cost of capacity. It is not adopted here — E14 measures whether the surplus survives real
context lengths, and E20 would be the gate for the steering logic.

**Does any of this hold for the bigger recipes?** Yes, and it was checked rather than assumed
(**[M]** `plan_quant_scaling.py`, `out_quant_scaling.txt`; the K = 4/5/6 tile rates are newly measured
in `out_rates_footprint_hiq.txt`, not extrapolated). Five Qwen3.8 checkpoints, `S_g` computed per
recipe, 4k ctx, b=1:

| bpw | expert MiB | slots/layer | `h` / live | CPU ms/tok | dev MiB/layer | matched GB/s | µs/layer | b=8 winner |
|---|---|---|---|---|---|---|---|---|
| 2.05 | 1.215 | 335 | 100 % / 356 | 0.00 | 12.1 | 292 | **44** | fair split (+7 %) |
| 2.68 | 1.563 | 249 | 100 % / 512 | 0.00 | 15.6 | 292 | **56** | fair split (+4 %) |
| 4.05 | 2.411 | 162 | 94.8 % / 512 | 1.34 | 22.9 | 294 | **81** | fair split (+3 %) |
| 5.05 | 3.009 | 127 | 100 % / 258 | 0.00 | 30.1 | 290 | **109** | fair split (+9 %) |
| 6.05 | 3.608 | 104 | 90.4 % / 500 | 3.68 | 32.6 | 243 | **141** | **hottest-first (+43 %)** |

* What scales is `expert_bytes` (2.4× from 2.68 → 6.05), so a decode layer's footprint grows from 12 to
  33 MiB, the resident *count* per layer falls 512 → 104, and the µs/layer rise is mostly just more bytes
  at a rate that barely moves (243–294 GB/s across every K). Offload still hides at b=1 for all five
  recipes (44–141 µs inside a ~250 µs window).
* What does **not** scale is the parent's byte bill: 69–101 MiB/layer, 31–45 % bandwidth duty, across all
  five recipes — because the quantisation recipe holds the streamed non-expert tensors near a fixed width
  instead of scaling them with the experts. §2.1a's "the 3090 is latency-bound with spare bandwidth" is
  therefore recipe-general on this model, and my initial guess that duty would reach ~83 % at 6.05 bpw
  was wrong by ~2×.
* The policy rule predicts its own crossover across the whole range: fair-split wins wherever the residue
  is zero or dust-small, and at 6.05 bpw — the one recipe where a real 9.6 % of picks land on the CPU —
  hottest-first wins by 43 %. `EXL3_MOE_B70_BALANCE=auto` selecting on `h` is exactly this boundary, so
  the same knob covers every recipe, with one condition: `h` must be read against the **live** expert
  count (the `512L` / `258L` column), since the decayed profiles' dust tail otherwise reports 100 %
  residency for recipes that are only ~90 % homed.
* One rate caveat, kept because it is a live E4c lead: fatter tiles make banding slightly *positive* —
  1.06–1.07× at K = 5/6 and 64–128 MiB, versus 0.96–1.05× at K = 2.5/3.0. Still not consistent in sign
  across footprints, so §2.2's decision stands, but "repacking buys nothing" was measured on thin tiles
  and the trend runs the other way as bits rise.


Disjointness is the default, not an oversimplification: with a CPU residue to serve, every GiB
duplicated is a GiB that cannot hold a *different* expert, and on an oversized model that GiB is the
difference between the CPU computing a pick in 199 µs and a device computing it in 31 µs. (The earlier
justification — that the two devices read at within 1.5× — was spec-to-spec and does not survive
measurement; see 2.1a.) Placement is therefore a **partition problem over three (or four) homes**,
sized by each
home's byte budget, and — for `S_g` — by the existing autosplit weight-versus-KV trade
(`exllamav3/model/model_ls.py`, per-module `autosplit_prepare`/`autosplit_extra_measure`) now
evaluated with the B70 as the alternative home for experts rather than the disk.

Two things follow, and both are costs, not freebies:

* **A row whose picks live in more than one home is computed in pieces** — one job per home holding
  ≥1 of its picks, each writing its own partial, combined by the parent in a fixed order (3090
  in place, then the B70 slot, then the CPU slot: the `cpu_split_combine` add already does this, and
  no atomics are involved, so determinism is preserved). The penalty is a duplicated activation
  payload and an extra handshake on that row, not a correctness hazard. `σ`, the *spanning fraction*,
  becomes a first-class placement metric (§4a, gate E13) and the placement may be re-ordered to
  reduce it.
* **The CPU is a compute tier, not a spill yard.** It wins whenever the bytes would have to move
  further than the arithmetic: copying an expert into a device costs `bytes/link` (655 µs for GLM's
  9 MiB) *before* the first useful byte is read, while computing it where it already lies costs
  `bytes/45 GB/s` per use and never moves anything. The rule that falls out of that (§4a) is a
  ~3-4 use break-even, and it is roughly model-independent.

`S_d` is reached by models whose expert set exceeds host DRAM as well as both cards —
[`§4a`](#4a-models-that-exceed-the-tiers-hit-rate-engineering) is about that regime, and about the
one before it (both VRAM tiers full, `S_c` comfortable), which is where
GLM-5.3-Flash@3.05 bpw (108.84 GiB of routed-expert trellis, present on this box) actually lives.

Because the homes are contiguous ranges of one permutation, the mechanism is the existing one with a
second cut point: the profile sorts experts hot-to-cold (`cpu_post_load` permutes the router weights
to match), `[0, F_g)` is the 3090's `num_local_experts` slice, `[F_g, F_g+F_b)` is the B70's, and
`[F_g+F_b, E)` stays with the CPU — which is exactly `moe_split_map_kernel`'s translate
(`routing.cu:1114-1122`, `p >= first_cpu ? p - first_cpu : -1`) generalised from a threshold to a
range, per home. Three homes, two cut points, no new addressing machinery.

Loading: the engine child receives the same `("layer", spec)` pipe messages as the CPU child, reads
**only the experts whose home is `S_b`** (the cut points are decided before either side loads, so the
3090's slice and the CPU's slice are simply never sent to it), and uploads them over the link
(`14.4 GB/s` **[M]** ⇒ a full 31.9 GiB tier in 2.3 s, overlapped with the parent's own module load —
same trick `model.py:614` uses to hide the CPU child's interpreter start). Aux tensors (`suh`, `svh`,
bias) are uploaded alongside, per expert, in a side table the kernels can index. The parent's
`num_local_experts` shrink (`cpu_maybe_split_load`, `block_sparse_mlp_cpu.py:428`) keeps covering the
3090's slice exactly as `-mcs` does today, so nothing else about the load path forks.

`S_c` handling: **keep the existing host arena byte-for-byte as it is**, including the CPU tier's
packed layout, because the arena is the CPU's *home* copy and at the same time the source for a
migration into `S_b` (655 µs) and for the streamed-prefill path of P3. The B70's VRAM copy is made in
the B70's own layout (below) at upload time; when an expert is migrated into `S_b` later, the bytes
come from the arena in the CPU's layout and are repacked on the way in — a load-time cost paid once
per migration, on the low-priority queue, never inside a job. `EXL3_MOE_B70_ARENA_CAP_GB` bounds the
arena to the `S_c` slice; anything below it is `S_d` (§4a).

When `bytes(S_b ∪ S_g) = bytes(experts)` — nothing in `S_c` — the host arena can be dropped entirely
(`EXL3_MOE_B70_ARENA=0`), a second, independent saving of the same tens of GiB in *host RAM* (which
matters because the arena competes with the page cache the checkpoint reads go through). Opt-in only:
it also means eviction from `S_b` has nowhere to go, so the tier is then a static partition.

### 2.2 Weight layout on the B70

**Decided: the B70 stores experts in native tile order** (**[M]** `notes/b70/probe_rates.cpp`,
`out_rates.txt`, `out_rates_repeat.txt`, `out_rates_footprint.txt`). Banded repacking (the GPU
analogue of the CPU's band-8, k-major along `n`) was measured against native on two geometries across
six working-set sizes: **0.96–1.05×, with no consistent sign** — it helped twice on GLM's wide
`tiles_n` and hurt there elsewhere, and sat on 1.00 for Qwen3.8. That is not nothing, but it is not a
lever either, and it is paid for twice: a repack pass at load, and losing the byte-identity that lets
an expert move between the 3090 and the B70 without translation (§5). So there is no repack at load,
no un-swizzle interaction, and the bytes stay interchangeable with the 3090's kernels.
`exl3_b70_tile_layout(K)` still exists as the single place the layout is *reported* (Gate B4's rule
that no second table may appear), but its answer is `native` for every K, and reversing that needs a
consistent win in the real GEMV (E4), not an analogy to the CPU tiers. One qualifier added by the
higher-quant sweep: banding is not flat in K — at K = 5/6 tiles it measures 1.06–1.07× at 64–128 MiB
against 0.96–1.05× at K = 2.5/3.0 (`out_rates_footprint_hiq.txt`). The sign is still inconsistent across
footprints so the decision stands, but the null was established on thin tiles and the mechanism
(per-item contiguity) should strengthen as tiles fatten — so E4c must run at the deployment's actual K.

The size of the intervention is why the null deserves belief. Banding rewrites the tile index from
native `kt·tiles_n + nt` to `(nt/8)·tiles_k + kt`, cutting the k-step of a GEMV fragment from
`tiles_n × tile_bytes` = 3200 B (Qwen3.8) or 12288 B (GLM) to `8 × tile_bytes` = 640–768 B: an item's
64 tile reads collapse from a 25–60 KiB scatter into one contiguous ~5 KiB run — a 5–16× stride
reduction, and both mappings were checked to be exact covers of the same tiles before timing. What
does *not* come out of the data is a mechanism story: per-item locality ought to matter only when few
streams are in flight, yet GLM's banded gain appears at 2 GiB, 512 MiB and 64 MiB and not at 1 GiB,
256 MiB or 128 MiB. The honest summary is **no reliable gain, and this instrument is not sharp enough
to prove the gain is exactly zero** — the configuration variance (which moves absolute rates ~2×, see
`out_rates_footprint.txt`) exceeds the effect. §12 therefore records the layout decision as made on
engineering grounds and revisitable, not as closed by measurement.

What *does* move the number, consistently and in one direction, is **locality**: clustered
work-item→tile mapping over scattered, **1.08–1.99×** across both geometries and all six footprints,
never negative, never below 1.08. Absolute rates for orientation: 132–292 GB/s scattered and
216–558 GB/s clustered, the low ends being GLM at a 64 MiB working set and the high end Qwen3.8
clustered at 64 MiB–1 GiB. That is a kernel-scheduling and allocation property, so it is specified in
kernel-scheduling and allocation property, so it is specified in
[b70-kernels.md](b70-kernels.md) §3a (keep a layer's experts contiguous in B70 VRAM; give one
work-group one expert's fragment range; never interleave experts across the items of a wave) and it
is what gate E4 is written against.

### 2.3 Activations

Today: `x` is copied to the slot as fp16 and the CPU worker quantises it to int8 per row
(`doc/prep/moe-cpu-offload-data-paths.md` §6). For the B70, quantise on the **3090** inside the
issue kernel and ship int8:

* payload halves (`hi` bytes/row instead of `2·hi`), and only the minority of rows that need the
  wide (15-bit) second plane pay `2·hi` again;
* the B70 kernel's input contract becomes identical to the CPU kernel's (`x8`, per-row `q`,
  `Σx8`, wide flag), which is what makes the two implementations comparable at the same arithmetic
  (Gate B′2 in `b70-harness.md`);
* the quantiser must be a faithful port of `quantize_row_wide_avx2`'s rule (scale `amax/127`;
  `amax/16256` with a 128-step high plane when more than 1/16 of the row would round to zero) — the
  harness diffs the *quantised tensors*, not the outputs, so a quantiser difference cannot hide
  inside a GEMV difference.

Output stays fp32 (protocol-compatible, same accumulation as today) with `EXL3_MOE_B70_OUT_F16=1`
as a measured option that halves the return payload; it must be re-scored under Gate C1.

---

## 3. The data paths, rewritten for a fast offload device

### P1 — decode (rows < `stream_min_rows`), fused handoff

Protocol unchanged: `submit_issue_fused` (`moe_cpu_host.py:1411`) → `moe_split_issue_kernel` writes
the slot and `data_ready` → engine computes → `done` → `submit_collect_fused` folds the fp32 partial
in place from pinned memory and writes `consumed`. What changes is who does what in the middle:

```
3090 stream : issue kernel (map translate, int8 quantise, slot write, data_ready)
              │  [GPU-resident experts + shared expert run here, 165-250 us of work]
              └─ wait done → collect-add (in place) → consumed
engine      : host thread spins on data_ready (a CPU load on host memory, as today)
  child     : 1 submission: DMA the compact slot message into B70 VRAM
              kernels: bucket → GEMV(g,u) → transform+act → GEMV(d) → accumulate, write out, fence, done
```

Two deliberate changes to the payload shape:

1. **Compact slot message.** The current slot is four fixed-capacity sections (`x`, `sel`, `w`,
   `out`, `ensure_started` geometry at `moe_cpu_host.py:1203-1207`), so a 1-row decode job has its
   5 KiB of payload split across three sections sized for 64 rows — three DMAs, or a 320 KiB one.
   For the B70 worker the issue kernel instead writes a *dense* message: 64-byte header
   (`seq, rows, topk, hi, ho, flags`) + `sel` + `w` + per-row `q`/`Σx8`/wide + `x8`, then the
   engine moves it with one `memcpy` (**[M]** 16 KiB DMA + flag = 7.6 µs, 128 KiB = 15 µs).
   `out` stays at a fixed offset so the collect kernel is untouched. The CPU worker keeps the old
   layout; the two slot formats live in different regions of different workers, so no shared code
   has to agree on both.
2. **Results are pushed, not pulled.** The final kernel stores the fp32 partial straight into the
   pinned slot and publishes `done` after a system fence (**[M]**: 16 KiB of stores + flag costs
   ~2 µs over the empty-job baseline). No D2H copy engine transfer, no extra submission, and the
   3090's `done` wait is then ordered by a write the same kernel made — which is precisely the
   ordering guarantee `moe_split_collect_add_kernel` relies on today.

Expected exposed cost per decode layer: `10-15 µs` of handshake + `~25-35 µs [P]` of compute,
against `165 µs` (Qwen3.5) / `~250 µs` (Qwen3.8) of parent GPU work in the same window ⇒
**fully hidden**, i.e. the offload becomes free at decode. The floor that matters is the empty job:
with `COMPUTE_GATED` semantics preserved (no payload written, no submission, `dev_count == 0`), the
engine's cost for a cold layer is one host-side spin miss, and the collect's cost is one kernel that
exits — unchanged from today's 20 µs, and *cheaper* since the wait retires immediately.

### P1′ — whole-layer offload at decode (`-mbl`)

Same shape as today's copy path (`_issue_compute`, `moe_cpu_host.py:1469`): `sel32` cast, `y_pad`,
three contiguous `copy_` D2H, `data_ready`, engine, `done`, readback. `doc/prep/measured-costs.md`
§4 prices that at ~26 µs of parent-side device work per layer against the fused path's 20 µs, and
the gap is pure overhead — which the CPU path tolerated because the compute behind it was 200 µs+.
Recommendation: do not carry `-mbl` over as its own path. Express it as `-mb E` (all of a layer's
experts offloaded) on the fused path, which already handles an arbitrary `first_cpu`, and let the
shared expert provide the overlap exactly as `-mcs` does today.

### P2 — prefill, rows to the B70 (the new default)

`submit_prefill` (`moe_cpu_host.py:1864`) currently syncs the host on a per-expert count readback to
decide what to stream. For B70-resident experts there is nothing to decide: **ship the rows.**

* Payload per 2048-row chunk, per layer, Qwen3.8 (`hi = ho = 2560`): int8 `x` 5.2 MB + fp32 `out`
  21 MB ⇒ 26 MB, or fp16 `out` ⇒ 15.7 MB. At 14.4 GB/s **[M]** that is 1.1–1.8 ms/layer.
* B70 compute per 2048-row chunk, per layer: 2048 × 10 picks × 3 × 2560 × 640 MAC ≈ 201 GFLOP ⇒
  1.1 ms at XMX fp16 rate **[P]**, plus reading the layer's whole 0.73 GiB expert set once at
  608 GB/s ⇒ 1.3 ms **[P]**. So link and compute are the same order, and they overlap.
* Chunking: `EXL3_MOE_B70_SLOT_ROWS` (propose 256, not 64) so a 2048-row prefill is 8 jobs/layer
  instead of 32 — each job carries a ~7-9 µs **[M]** handshake, so 32 jobs would add 0.25 ms/layer
  of pure protocol. Pinned cost is `slots × rows × (sz_x·hi + sz_out·ho)` ≈ 4 × 256 × 7.7–12.8 KB
  ≈ 8–13 MB, and the engine's VRAM staging is the same again. Four slots keep DMA and compute
  pipelined.
* No host sync: the *device* decides per row which rows the B70 handles (rule in P4), so the count
  readback and the whole tail-compression machinery is skipped on the B70 path.

### P3 — streamed prefill: retired for `S_b`, kept for `S_c`

The crossover is arithmetic, not taste. Streaming expert *e* to the 3090 costs
`expert_bytes / link_rate` of link — one crossing if the bytes come from the host arena, two if they
come from B70 VRAM. Computing *e* on the B70 for `rows_e` rows costs
`rows_e × (sz_x·hi + sz_out·ho) / link_rate` plus its share of B70 compute. With one crossing:

```
stream wins  <=>  rows_e  >  expert_bytes / (sz_x*hi + sz_out*ho)
   int8 in, fp16 out:  Qwen3.8  1.465 MiB / 7680 B = 200 rows     Qwen3.5  1.125 MiB / 6144 B = 192 rows
   int8 in, fp32 out:  Qwen3.8 -> 120 rows                         Qwen3.5 -> 115 rows
   and halve again if the bytes must come off the B70 (two crossings) rather than the host arena
```

An expert only sees ~200 picks in a chunk when `rows × topk / E` is that large or routing is very
skewed: at 2048 rows × topk 10 over 512 experts the *average* is 40, and the experts that would
clear 200 are precisely the ones already in `S_g` on the 3090. So for B70-resident experts the
fused / batched-reconstruct / per-expert streamed tiers, the weight-staging rings, `WSLOT_MB`,
`BATCH_EXPERTS`, the `stage_jobs` ring, the stager thread and the `moe_unswizzle_trellis` restore
pass are all **dead code** (and the 28.6 % of device time they cost, per
`doc/prep/measured-costs.md` §7, disappears).

For `S_c` experts, all of it still applies unchanged — streaming a spilled expert to the 3090 beats
a 45 GB/s CPU GEMV by ~12×, which is why `stream_t` remains the biggest knob on the CPU path (2.1×
end to end). Keep `stream_t`'s calibration (`probe_bandwidth`, `moe_cpu_host.py:900`) for `S_c`
only, re-probed against the B70-era link if the CPU worker is disabled.

### P4 — rows, spanning, and who computes what

With disjoint homes, membership decides everything, and the routing rule is *derived*, not chosen:

```
device D gets a job for row r        <=>  picks(r) ∩ home(D) ≠ ∅        (device-side test, 1 word/row)
sel sent to D                        =   local index inside home(D), else -1   (as today)
final_out                            =   Σ over homes with a job, in a fixed order (3090, B70, CPU)
```

No host sync is needed for any of it: the issue kernel already evaluates the per-row predicate while
it stages the payload (it writes `dev_count` today), the `-1` sentinel translation and the
out-of-range masking inside `exl3_moe*` are the existing `-mcs` mechanism (`routing.cu:1114-1122`,
`1180-1199`), and the combine already adds a worker partial to the routed sum
(`cpu_split_combine`, `block_sparse_mlp_cpu.py:633`). What is new is only that a row may appear in two
or three jobs, and that each job's `sel` masks differently.

Cost model of a spanning row (`σ` = fraction of rows that span, at decode, Qwen3.8 shapes,
`x` int8 2.5 KiB + `out` fp32 10 KiB):

| | row entirely in one home | row spanning two | row spanning three |
|---|---|---|---|
| activation payload per layer | 12.5 KiB | 25 KiB | 37.5 KiB |
| handshakes | 1 (5–8 µs **[M]**) | 2 | 3 |
| partial adds on the 3090 | 1 | 2 | 3 |

So a spanning row costs one extra payload (12.5 KiB ≈ 0.9 µs of link) plus one extra handshake
(~6 µs) per layer: ≈7 µs, i.e. ≈0.33 ms/token at 48 layers with one row per token — hidden behind
the parent's ~10 ms/token (Qwen3.5) or ~30 ms/token (Qwen3.8), so at decode `σ` is a secondary cost.
It is *not* secondary at prefill, where the same doubling applies to 2048 rows and the link is the
bottleneck: there `σ` feeds straight into E5, which is why it is measured rather than assumed. Two
levers, both offline:
the frequency-sorted permutation (hot experts co-occur with hot, so the 3090's slice absorbs a
disproportionate share of whole rows) and, if E13 shows `σ` uncomfortably high, an explicit
co-location pass that trades a little rate for a lot of spanning (§8, `EXL3_MOE_B70_COLICATE`).

Load balance falls out of the same numbers instead of a runtime knob: expected work per device is
`Σ_{e ∈ home} n_e`, so the two cut points are chosen so that ratio matches the measured throughput
ratio of the two cards (E4/E5). `EXL3_MOE_B70_ROW_FRACTION` from the first revision of this document
is **dropped** — with disjoint homes, forcing a share of *rows* to a device that does not hold their
experts is meaningless; you move the *home*, offline, where the cost is one 655 µs copy instead of a
per-chunk re-shuffle.

---

## 4. Cost model

Everything the policy knobs tune, in one place. All rates are measured by the probes listed in
[`b70-harness.md`](b70-harness.md) (link, `b70_bench_kernel`, `b70_bench_engine`) and re-probed at
startup — never inherited.

```
FOR ONE LAYER, ONE STEP, homes running in parallel:
  rows_touched(D) = rows with >= 1 pick inside home(D)          sum_D rows_touched(D) = rows*(1 + sigma)
  link_bytes(D)   = rows_touched(D) * (sz_x*hi + sz_out*ho)     (3090 home: 0, it is the parent)
  compute(D)      = sum_{e in picks of the step, home(e)=D} bytes_e / rate_D
  layer_cost      = max( parent_gpu_work_layer,
                         max_D [ notify + link_bytes(D)/link_rate + compute(D) ] )

PLACEMENT (offline, per layer, cut points on the frequency-sorted permutation; objective per 2.1a):
  minimise   max( parent_gpu_work_layer + compute(S_g)/gpu_rate,          <- SERIAL with the parent
                  compute(S_b)/b70_rate,                                  <- concurrent
                  compute(S_c)/cpu_rate )                                 <- concurrent
  + sum_D rows_touched(D) * payload / link_rate                            (the spanning term, sigma)
  subject to bytes(S_g) <= VRAM_3090 - KV - state - streamed-non-expert - reserve
             bytes(S_b) <= VRAM_b70, bytes(S_c) <= DRAM_cap
  frequency order within a layer is optimal for the compute term while any CPU residue exists (equal
  bytes per expert, uniform rate per home); once the residue is gone the objective becomes a pure
  load-balance between two VRAM homes and P_lpt beats P_order (2.1a). sigma (the spanning penalty) is
  the only other reason to deviate from frequency order (..._COLICATE).

MIGRATION / MISS DECISION - an expert with no device home, c uses predicted in the window:
  leave it on the CPU      : c * bytes / cpu_rate                     (moves nothing, ever)
  admit it to S_b (once)   : bytes / link_rate + c * bytes / b70_rate
  stream it to the 3090    : bytes / link_rate + c * bytes / gpu_rate  (paid PER CHUNK: the streamed
                                                                        slot is transient, so P3's
                                                                        threshold is ~200 rows, not ~4)
  => admit to the B70 iff  c > (bytes/link) / (bytes/cpu - bytes/b70) = 3.7 uses here; the ratio is
     scale-invariant, so 3-4 is the default for any model, bitrate or expert shape.

HOME vs JOB: the copy-vs-compute comparison decides HOMES, amortised over a window. It never decides
a single job: a resident expert is always computed at home, and an extra pick on a row that is
already crossing to that home costs the marginal weight-read only. Re-deciding per job is what makes
the CPU path's promote hook cost 2-3 ms/token.
```

Constants on this box, as measured (see `notes/b70/out_rates.txt` and `notes/b70/README.md`):
`link_rate` 14.4 GB/s **[M]**; `notify` 3.2 µs resident / 5–8 µs per submission **[M]**;
`vram_rate` for the decode read pattern: **scattered 200–292 GB/s (Qwen3.8) / 132–260 GB/s (GLM),
clustered 278–558 / 216–322**, as a function of working-set size (**[M]**, `out_rates_footprint.txt`
for the sweep; `out_rates.txt` and `out_rates_repeat.txt` are the 1–1.5 GiB points) — 45–81 % of the
608 GB/s spec, and 729–919 G-weights/s scattered at the reference footprint. **The absolute rate is
not a card constant**: identical code and geometry vary ~2× with footprint, non-monotonically, so the
planning figures below carry up to ~2× uncertainty until E4 measures the real GEMV at the footprints
decode actually presents; that replaces the earlier "target ≥420 GB/s" projection. The *clustered*
end is only reachable if the kernel keeps one expert's tiles together (b70-kernels.md §3a);
`xmx_rate` 183 TFLOP/s fp16 / 367 TOPS int8 **[M]** (`b70-bench`); `parent_gpu_work` 165 µs/layer
(Qwen3.5) and ~250 µs/layer (Qwen3.8) **[M, doc/prep]**, GLM unmeasured (E10 measures it first).

The read-rate measurement also settles the arithmetic question for decode. The cost is taken as the
difference between two measured kernels, never as a modelled duty cycle: adding the real unpack
density (window extract + multiply + accumulate, ~10 weights per word, **+47 lane-instructions per
32-lane word = per 128 B of stream**) costs **4.4 % of bandwidth on Qwen3.8's geometry and 0.1 % on
GLM's** at the 1 GiB footprint, and the hardware int8 dot and a manual byte-sum differ by
**0.2–0.4 %, i.e. not measurably** (three independent runs, `out_rates_repeat.txt`). Splitting the
accumulator across 8 independent chains makes it 1.2–1.4 % *worse*, so the residual cost is not
dependency latency — it tracks instruction count and register pressure. One caveat from the footprint
sweep: at a 64 MiB working set the density penalty grows to ~14 % (Qwen3.8), because the loop is then
running close enough to the card's latency limit that extra instructions stop hiding under memory
latency. Decode on this card is bandwidth-bound at the footprints decode actually uses, so neither the
dot's availability nor Recipe A-versus-Recipe B decides decode throughput — locality and job
composition do. (The dot
still matters for the XMX prefill routes and for power, and `spillMemSize`/ISA checks stay in the
harness; what no longer gates the design is "what if `dot_acc` becomes seven ops".)

What the model says at a glance. **The footprint that sets the rate is the set of experts a layer
actually touches, not the checkpoint**: `topk` (10 on Qwen3.8, 8 on GLM, from `config.json`) unioned
across the rows of the batch, times the fraction `h` this card owns. `plan_operating_point.py`
(`out_operating_point.txt`) computes that per batch from the real selection counts and samples the
measured rate curve at the matched footprint:

| rows | Qwen3.8 MiB/layer | GB/s | µs/layer | vs parent 250 µs | GLM MiB/layer | GB/s | µs/layer |
|---|---|---|---|---|---|---|---|
| 1 | 14.3 | 292 | **51** | 4.9× margin | 50.9 | 132 | **405** |
| 4 | 55.5 | 292 | 199 | 1.3× | 192.2 | 220 | 917 |
| 8 | 104.0 | 234 | 465 | **0.5×** | 351.2 | 239 | 1539 |
| 32 | 313.3 | 234 | 1404 | 0.2× | 975.6 | 254 | 4020 |

* Decode at **b=1**, rate-matched: Qwen3.8 takes **51 µs/layer** (27 µs if the kernel clusters) inside a
  ~250 µs parent window — hidden ~5×, and the whole model's routed-expert reads are 2.46 ms/token of
  B70 time. Qwen3.5 is proportionally cheaper. **GLM is the hard case: 405 µs/layer, 17.0 ms/token**,
  because its 9 MiB experts put a single token's 50.9 MiB footprint on the *worst* point of the measured
  curve (132 GB/s) with little locality to recover (1.6× at best). Whether that hides depends entirely on
  GLM's own parent work (45 layers, H=4096, 64 heads), which E10 must measure before anyone promises
  "free at decode" for it. The claim is conditional per model, not universal.
* **Batch is the variable that the per-token view hides, and it cuts against offloading.** Distinct
  experts per layer grow almost linearly with rows (72.7 of 512 at b=8 for Qwen3.8) until routing's
  effective support saturates, so B70 work per layer grows ~9× from b=1 to b=8 while the parent's window
  grows far more slowly — at b=1 it is bound by *weight* reads, which are batch-independent. Qwen3.8's
  margin goes 4.9× → 1.3× → 0.5× over b = 1 → 4 → 8: **the offload stops hiding at single-digit batch**.
  Two consequences: the harness must report decode at several batch sizes (E9/E10, not just b=1), and
  past the crossover the extra rows belong on the XMX routes, where batch is what pays.
* **A second/third B70 buys rate, not only capacity.** Each pick is computed in exactly one home, so a
  layer's expert bytes divide linearly across cards: GLM's 405 µs/layer becomes ~202 with two cards and
  ~135 with three. The §4a card sweep (19.6 → 6.9 → 0.9 ms/token of *CPU* residue) was about hit rate
  alone; this is an independent reason to add cards for exactly the models that need them.
* Prefill is link-bound at ~2048 rows unless `sz_out` drops to fp16 or the row split keeps more work
  on the 3090; the model gives the crossover for both, and the harness measures which the box lands on.

---

## 4a. Models that exceed the tiers: hit-rate engineering

Everything above assumes the offload device holds the experts it is asked about. That stops being
true as soon as `bytes(experts) > VRAM_b70`, and it stops being a footnote for any serious model.
`notes/scan_expert_capacity.py` (output in `notes/m_expert_capacity.txt`) reads the local
checkpoints' safetensors headers and prints this table plus the economics below — text-model experts
only, since an MTP/draft head is a separate capacity consumer with its own rate (Qwen3.5's MTP
experts are 4 bpw against the text model's 3 bpw, 0.38 GiB of them, and every verify step touches
them):

| checkpoint | MoE layers × E | expert block | routed-expert trellis | fits one B70 | experts per layer resident¹ |
|---|---|---|---|---|---|
| Qwen3.5-35B @3 bpw | 40 × 256 | 1.125 MiB | 11.25 GiB | 100 % | all 256 (surplus) |
| Qwen3.6-35B-A3B @2.49 | 40 × 256 | 1.125 MiB | 9.09 GiB | 100 % | all 256 (surplus) |
| Qwen3.8-FN @2.05 | 48 × 512 | 1.17 MiB | 28.12 GiB | 100 % | all 512 (surplus) |
| Qwen3.8-FN @2.68 | 48 × 512 | 1.465 / 1.758 MiB | 36.33 GiB | **87.8 %** | 411 of 512 |
| Qwen3.8-FN @4.05 | 48 × 512 | 2.34 MiB | 56.25 GiB | 56.7 % | 308 of 512 |
| Qwen3.8-FN @5.05 | 48 × 512 | 2.93 MiB | 70.31 GiB | 45.4 % | 246 of 512 |
| Qwen3.8-FN @6.05 | 48 × 512 | 3.52 MiB | 84.38 GiB | 37.8 % | 205 of 512 |
| GLM-5.3-Flash @3.05 | 43 × 288 | 9.00 MiB | **108.84 GiB** | 29.3 % | 91 of 288 |

¹ from `plan_placement.py --b70-gib 31.9 --gpu-gib 2`. **The 2 GiB slice is now known to be too small**
— `plan_parent_budget.py` prices the parent's real capacity bill at ~16.6 GiB of free VRAM on these
hybrid-KV checkpoints, which lifts Qwen3.8@2.68 to `h` = 100 % and GLM to 81.1 % (see 2.1a). The table
keeps the 2 GiB column because that is the configuration every figure in this section was derived
with; re-derive before sizing hardware.

Byte residency alone says almost nothing useful — what matters is how much *pick mass* the resident
experts carry, and that is the `h` column of the planner block below. The pair that proves it: Qwen3.8
@6.05 (37.8 % of bytes resident, **h = 96.6 %**) and GLM-5.3-Flash @3.05 (29.3 % resident,
**h = 70.8 %**) — similar capacity, 26 points of difference, because GLM's routing is nearly flat.

Two readings. The **cache regime starts at ~32 GiB of expert trellis**, which the local reference model
(Qwen3.8 @2.68) already crosses — so this section is not an exotic corner, it is what the second
reference model runs on, just gently (12.2 % of its bytes spilled). And whether that spill matters at
all depends on the *shape* of the routing distribution, not on the spilled fraction: the same 12 % is
nearly free on a peaked model and crippling on a flat one, which is exactly the difference between
Qwen3.8 @2.68 (97.6 % of picks resident) and GLM-5.3-Flash (70.8 %) below.

`h` below means **device-resident pick share**: the fraction of a step's `topk` picks whose expert has
a device home. It is no longer a projection: `notes/b70/plan_placement.py` joins the safetensors census
to the **real per-layer selection counts** that dynamic placement already persists
(`~/.cache/exllamav3/expert_stats/…json`) and returns `h` exactly for any pair of home sizes
(`out_placement.txt`). Two properties of that data bound how far to trust it:

* the counts are **decayed cumulative** statistics from runs whose placement was already adaptive, so
  cold experts linger as near-zero dust (individual counts of 1e-27 in the local profiles). `h` from a
  profile is an **upper bound** and `|res|` a lower bound; E14 measures both from a fresh trace and
  must find `h_live ≤ h_profile`;
* pick *breadth* differs enormously between models, and that — not the spilled byte fraction — decides
  the design. Qwen3.8@2.68 concentrates 97.6 % of picks in 411 of 512 experts per layer; GLM-5.3-Flash
  is nearly flat (effective support 213–231 of 288, its top expert only 2–4 % of a layer's picks), so
  91 resident experts capture just 70.8 %.

```
GLM-5.3-Flash @3.05, per-layer byte budget from N cards (plus 2 GiB on the 3090):
  1 card   91 of 288 resident   h = 70.8 %   CPU-served residue 19.6 ms/token  sigma 99.2 %  |res| 197
  2 card  177 of 288            h = 89.7 %   CPU                 6.9 ms/token  sigma 92.4 %
  3 card  264 of 288            h = 98.6 %   CPU                 0.9 ms/token  sigma 79.4 %

Qwen3.8 @2.68, 1 card: 411 of 512 resident, h = 97.6 %, CPU residue 0.42 ms/token, |res| 33, fill 0.2 s
Qwen3.8 @6.05, 1 card: 205 of 512 resident, h = 96.6 %, CPU residue 1.29 ms/token, |res| 307, fill 3.8 s
```

The economics, for GLM's geometry (9.00 MiB expert = 9.44e6 B, K=3, topk 8; 43 MoE layers of which the
local profile covers 42, so the per-token figures below are ~2 % light) at measured rates — `link`
14.4 GB/s and `disk` 5.0–5.2 GB/s **[M]**, CPU 47.4 GB/s **[M, doc/prep §5]**, B70
250 GB/s **[M, the middle of the scattered sweep; §2.2 shows the rate is footprint-dependent, and the
break-even below moves only from 3.8 to 4.1 uses across the whole 132–545 GB/s range, so this input
barely matters]**:

```
admit one expert to S_b  = expert_bytes / link_rate              =  655 us   (from S_c)
                           + expert_bytes / disk_rate            = 2.5 ms    (from S_d, 1.8 ms of it disk)
CPU compute per use      = expert_bytes / 47.4 GB/s              =  199 us
B70  compute per use     = expert_bytes / 300 GB/s               =   31 us   (22 us at the 420 goal)
break-even uses          = 655 / (199 - 31)                      =  3.8      (4.3 at 420 GB/s: the
                                                                     answer is rate-insensitive)
```

**The distinction that decides the policy: CPU cost accrues per pick and never stops; admission cost
is paid once per newly resident expert.** An earlier draft of this section compared the two per token
by charging an upload per pick, which made migration look ~50x more expensive than it is and produced
the wrong verdict ("do not migrate, let the CPU serve the residue"). Charged correctly:

```
steady state, per token:   CPU      = topk*(1-h) * layers * 199 us
                           migrate  = |res| * layers * churn_fraction * 655 us
                           migrate wins  iff  churn_fraction < topk*(1-h)*199 / (|res|*655)
```

`churn_fraction` is **not measured and is not derivable from what exists**: the profiles are single
cumulative snapshots with no time axis. Two proxies I tried and rejected, recorded so nobody reuses
them — comparing the top-N *sets of counts* between layer groups (gives ~92 % "overlap", because
repeated count values collide, so it measures value coincidences and not expert identity), and
splitting one layer's array in half (which partitions the experts by index, so it is spatial, not
temporal, and reports ~100 % by the same artifact). Getting a real number needs either two profile
snapshots taken minutes apart in one run, or per-window counters in the engine — that is E11, and
until it reports, this whole policy branch is a hypothesis with a stated break-even.

So the verdict for an oversized model turns on one unmeasured number. `churn_fraction` is **not
derivable from what exists**: the persisted profiles are single cumulative snapshots with no time
axis. Two proxies were tried here and both are invalid, recorded so nobody reuses them — comparing
top-N **sets of counts** between groups of layers reports "92 % overlap" because decayed counts repeat
across experts, so it measures value collisions rather than identity; and splitting one layer's array
in half is a *spatial* partition of a static snapshot, with no time in it. Getting a real figure needs
two dated snapshots of the placement table within one run, or per-window counters in the engine —
E11. Until then this is a hypothesis with a clean decision rule, not a conclusion.

Two structural consequences for the design:

**1. Keeping the tier warm is a link-budget question, and the unit is churn, not picks.** The link is
shared with activations, and the only window available at decode is the parent's own per-layer work
`T_layer`:

```
link budget per layer   = link_rate * T_layer                        (5.8 MB at T_layer = 400 us)
maintenance demand      = |res| * churn_fraction * expert_bytes      (distinct new experts/token)
GLM, 1 card             = 197 * churn * 9.44e6 B, so
   saturates the budget at churn = 5.8e6 / (197*9.44e6) = 0.31 %/token
   stops beating the CPU     at churn = 2.33*199us / (197*655us)     = 0.36 %/token
```

The two thresholds **coincide**, which is the cleanest result in this section: there is no regime in
which migration is affordable-but-unattractive. Below ~0.3 %/token it is both (at 0.03 %/token it
costs 1.6 ms/token of link and 0.56 MB/layer against the CPU's 19.5 ms/token — 12× better); above it,
migration is simultaneously uneconomical *and* stealing the window activations need. So the policy
question collapses to a single measurement with a clean decision rule: **E11 measures churn; if it is
under ~0.3 %/token, migrate with a per-step budget sized to the link window; if it is over, the CPU
serves the residue and `S_b` is static apart from priming.**

The earlier per-pick version of this test — `h_min = 1 − link_rate·T_layer / (topk·expert_bytes)`,
92.4 % for GLM — was the wrong instrument for the same reason: it charged a fresh upload for every
pick, i.e. it silently assumed `churn_fraction = 1`, which is past the saturation point of any
geometry and produced a verdict (“the cache cannot converge; the CPU must serve the residue”) that the
correct accounting does not support. Retained only as that pathological bound.

What the planner states at load, entirely from measured quantities, is `|res|`, the one-time `fill`
cost, and these two thresholds. Where real churn sits relative to them is E11's measurement, and until
it reports the CPU worker stays **required** in oversized mode (§6) — a job that needs a non-resident
expert must be delegated, never waited for, because stalling the parent's stream is not an option
whatever the arithmetic says.

Two things `T_layer`-depend and must be measured rather than assumed: GLM's parent work per layer is
unknown (400 µs used here; the budget scales linearly), which E10 establishes first.

**2. Capacity must be split per layer, in bytes, by marginal gain — not globally.** A global
frequency sort leaves some layers fully resident and others not at all, and a layer with zero
residents pays `topk·CPU` on *every* token. Hit rate per layer is concave in its resident byte quota,
so the allocation is a water-filling over layers: repeatedly give the next MiB to the layer with the
largest `∂h/∂bytes`. In the common case (similar routing entropy everywhere) that degenerates to
*equal bytes per layer* — which is what `-mcs` already does per layer, except that it splits by
*expert count*, and Qwen3.8's 2.5- and 3-bpw layers have different `expert_bytes`. Budget in bytes;
let the per-layer count follow.

Per-layer budgets are also what set `σ`, and **spanning is the normal case, not an edge case**: the
planner puts `σ` at 92–99 % for every model that retains a CPU residue, because with 8–10 picks per
row across three homes a row with any chance of a residue pick almost always has one. Three
consequences, all corrections to earlier drafts of this document:

* the prefill link model must use `Σ_D rows_touched(D) = rows·(1+σ)` — **roughly double** the
  activation bytes whenever a residue exists (P2's figures are the single-home case);
* the 3-way combine is a first-class path, not a corner: up to three partials per row in a fixed
  order, two extra handshakes (~12 µs/layer/token, hidden behind the parent's window) and one extra
  `x` copy per participating home;
* `…_COLICATE` cannot remove the spanning, because with capacity-driven residues the homes are not
  separable by co-occurrence — the sweep at the head of this section shows `σ` falling only as
capacity *rises* (99 % → 79 % from one card to three), not as the ordering changes. It ships as an
  experiment behind a knob rather than a default, and E13 is what promotes or deletes it.

Supporting decisions for this regime:

* **Prime the tier at load** from the existing expert-stats profile: 31.9 GiB is 2.3 s of link time
  (or ~7 s disk-bound, overlapping the parent's own load, which for a 117 GB checkpoint is minutes).
  Without priming, the first generation of a session runs at the `h` of whatever the checkpoint order
  happened to put in `S_b` — the same cold/warm confound `doc/prep/measured-costs.md` §8.3 measured,
  but with 10× the stakes. Priming makes that profile an asset rather than a measurement hazard, so
  it must be reported with every benchmark.
* **Admission traffic goes on a low-priority queue.** SYCL in this toolchain exposes no queue
  priority (checked: no `aspect::queue_priority`), but Level Zero does
  (`ze_command_queue_desc_t.priority` = `PRIORITY_LOW`) — another reason the engine's transfer queue
  is created through the L0 path (§5, T1). Admission must also be *budgeted* per step
  (`EXL3_MOE_B70_PROMOTE_BUDGET`, experts/step) exactly as the CPU promote-on-miss hook is, because
  the measured lesson there (`doc/prep/measured-costs.md` §8.2: a 2–3 ms/token host hook cancelling a
  25 % hit-rate win) is that an ungoverned policy loses money.
* **Offline first, online second.** The two cut points, the predicted `h`, the predicted `σ` and a
  predicted ms/token are all computable from the profile plus the four measured rates, so the planner
  should print them at load — and refuse configurations whose predicted `h` is unreachable
  (`…_MISS_POLICY=cost` logs each admit/decline with the numbers it used, so a wrong prediction is
  attributable). Online admission then only has to handle what the static profile could not foresee
  (a topic switch), which is exactly the case the E11 thrash gate measures.
* **Admission is much cheaper than the CPU path's equivalent**, and that changes what policy is
  affordable: a B70 admission is a 655 µs DMA on a private queue with no checkpoint re-read and no
  `torch.cuda.synchronize()` of the parent, versus the measured ~6 ms stop-the-world sweep and the
  ~2–3 ms/token hook. So admission decisions can be made *online, per chunk*, instead of by a
  periodic sweep between generations.
* **Eviction needs no destination.** The victim's bytes are still in `S_c` (or on disk), so eviction
  is a free space reclaim — unlike the 3090↔arena demote path, which writes bytes back. Only the
  `EXL3_MOE_B70_ARENA=0` mode (every expert homed on the B70, no host copy) forbids eviction, and is
  offered only when `bytes(experts) ≤ VRAM_b70`.
* **`S_d` is not hypothetical on this box.** Host DRAM is 125.6 GiB and GLM-5.3-Flash's expert trellis
  alone is 108.84 GiB (the whole checkpoint is 117 GB on disk — experts dominate a Flash-Next model to
  that degree), so a full arena would leave ~14 GiB for torch, the pinned ring, the in-flight 3090
  weights and the page cache. `S_c` therefore needs its own cap
  (`EXL3_MOE_B70_ARENA_CAP_GB`), with anything beyond it living only on disk. The placement table then
  records the *home* per expert (`S_g` / `S_b` / `S_c` / `S_d`), which gives migration two prices —
  655 µs from `S_c`, ~2.5 ms from `S_d` — and makes "evict the victim that is still in `S_c`" a rule
  rather than an accident.
* **Scaling out is the fix for this class, and the curve is measured rather than argued** (the sweep
  at the head of this section): for GLM each card buys a nonlinear fall in the CPU-served residue,
  19.6 → 6.9 → 0.9 ms/token, and `σ` falls with it as rows stop spanning. The useful question for a
  model this large is "how many cards until the CPU share stops dominating", which
  `plan_placement.py` answers offline from real routing counts before any hardware work. The protocol
  already supports N cards — one engine child, ring and slot region per device, home index in the
  placement table (the `dev_count`-per-device mechanism the multi-GPU CUDA path already has). A
  capacity-vs-cards curve belongs in the same sweep as E9.
* **`S_d` (DRAM exhausted)** reuses the loader's deferred/paged reads into a *bounded pinned ring*
  (`EXL3_MOE_B70_DISK_RING_MB`), never an unbounded arena: read → DMA → recycle. Keep the expert's
  *presence* metadata (tier + byte offset) in the placement table so a miss knows whether to pay
  655 µs or 2.5 ms. This is the only place the design should reach for the disk during generation,
  and the budget/priority rules above apply doubly there.
* **Rejected: band-level striping of one expert across tiers.** The 128-column band is the natural
  sub-unit, so an expert *could* be split 3090/B70 to sharpen capacity granularity, but with
  `expert_bytes` (1–9 MiB) three orders of magnitude below tier capacity the granularity is already
  ~10³ experts per tier, and striping would need a second partial-combine path plus a per-band layout
  rule. Not worth the protocol cost.
* **Combine the tiers as a maximum, not a sum, and the card decision becomes obvious.** The `ms/token`
  figures quoted above and in `out_placement.txt` are per-*worker busy time*; the homes compute
  concurrently, so per-layer latency is `max(T_parent, T_b70/N_cards, T_cpu)` and throughput is
  `1 / (layers × that)`. Adding the two would double-count and hide the real ceiling. With the
  rate-matched per-layer times from `plan_operating_point.py`:

| GLM @3.05 | h | B70 µs/layer (each) | CPU µs/layer | per-layer max | binding | tok/s @ 42 layers, `T_parent` = 300 µs |
|---|---|---|---|---|---|---|
| 1 card | 0.708 | 405 | 467 | 467 µs | **CPU** | 51 |
| 2 cards | 0.897 | 202 | 164 | 300 µs | **parent** | 79 (+55 %) |
| 3 cards | 0.986 | 135 | 21 | 300 µs | **parent** | 79 (+0 %) |

  which says something the hit-rate view could not: the second card is worth 55 % because it takes the
  CPU off the critical path, and the **third buys literally nothing** unless `T_parent` is below ~135
  µs/layer — at which point the B70s bind again. So the question "how many B70s for GLM?" reduces to a
  single unmeasured number, `T_parent`, and a rule: *add cards while `max(T_b70/N, T_cpu) > T_parent`.*
  Two caveats on the B70 column, both honest: it divides bytes by N **at the same rate**, and it drives
  the per-card footprint to 32 MiB/layer, which is *below the smallest footprint this card has been
  measured at for GLM's geometry*. If GLM's rate keeps falling as the footprint shrinks (it fell from
  208 to 132 GB/s between 128 and 64 MiB), the second card buys less than the table claims — E4 must
  measure below 64 MiB before this table is used to decide a purchase.
* Prefill behaves differently and more kindly: rows are already crossing for the resident experts,
  so a miss costs only the *incremental* link time of its upload against a chunk that is link-bound
  anyway, and the `stream_t`-style rule for the 3090 (≥200 rows/expert) still applies. Measure both;
  do not run one threshold at both row counts.

## 5. Execution model tiers

Three ways to run one job on the B70, priced with the measured numbers. The phase plan adopts T1 and
holds T2 as an optimisation with a hard gate, because the difference between them (≈3 µs/layer) is
smaller than the noise `doc/prep/measured-costs.md` §8 warns about.

| | T0 phases | T1 graph/command-list per job | T2 resident engine |
|---|---|---|---|
| what is submitted per job | 5–8 kernels (bucket, gemv_gu, transform+act, gemv_d, accumulate, publish) | one pre-recorded graph / reused L0 command list, rebuilt only when the shape class changes | nothing: a doorbell store in pinned memory |
| measured per-job cost component | ~2 µs host per submission; ~2–5 µs device turnaround per phase | **[M]** 5.0–6.3 µs end-to-end for an empty job, 7.6–9 µs with a 16 KiB DMA | **[M]** 3.2 µs round trip (mean of 200, best 2.8) |
| phases separated by | separate launches | graph edges | grid-wide barriers inside the resident kernel (atomic counter, device scope) |
| occupies the card | only while running | only while running | **permanently** (must be sized to leave cores for anything else) |
| liveness | queue errors surface per submission | same | a hang is a device loss; needs the child to die so the parent's watchdog fires |
| needs | nothing exotic | `ext/oneapi/experimental/graph.hpp` (present) or raw `zeCommandList` reuse | one polling lane per sub-group **with a system fence** (`LESSONS` 2/3/6), uniform control flow, no `atomic_ref` on foreign pointers |

T0 is the first thing that runs at all (it is the honest baseline and the easiest place to bisect a
wrong number). T1 is the shipping default. T2 additionally removes the *engine thread's* wake-up and
is only interesting if the harness shows the engine thread, not the card, on the critical path.

What makes this easy is the same thing the CPU worker already exploits: the engine thread spins on
`data_ready` in host memory with an ordinary CPU load (no PCIe involved, exactly like the loop in
`cpu/moe_handoff.cu:351`), so a job can be handed to the card ~100 ns after the 3090 wrote it. Only
the *payload* needs the link, not the notification.

---

## 6. Process and ownership model

* **Engine = a child process**, like the CPU worker, for three reasons beyond symmetry: (a) it moves
  the SYCL enqueue cost (2 µs/submission, 20 µs if a `.wait()` sneaks in) off the Python forward
  thread, which `doc/prep/measured-costs.md` §6 shows is already 3.6 ms/token; (b) a device fault or
  a wedged queue kills the child, and the existing parent-side watchdog (`moe_cpu_host.py:1310`)
  already knows how to unblock pending stream waits and raise on the next `begin_pass`; (c) the
  load/upload pipeline (`("layer", spec)` messages, acks, deferred safetensors reads) is reused.
  The one capability this needs was proven in Phase 0: `probe_crossproc.py` passes 10/10 — the child
  maps the parent's `shared_memory` segment at a different VA, registers it with its SYCL context,
  a kernel there writes payload + flag that the parent and a 3090 DMA both see, and a `cuStreamWriteValue32`
  from the parent is seen by a kernel in the child. (The in-process-thread fallback is therefore not
  needed, but keep it as the documented Plan B for a machine where registration is refused.)
* **Ownership**: the parent owns and registers the control region; the engine never allocates memory
  the 3090 must see (§2.1, measured constraint). The engine owns all B70 VRAM: expert weights,
  staging, scratch. Nothing on the B70 is shared with the 3090 except the handoff region.
* **Queues**: one in-order job queue, one weight-transfer queue, both private to the engine. The
  engine publishes `done` only from the job queue, so flag order equals data order.
* **Lifetime**: engine start is scheduled exactly like the CPU worker's (spawned before any module
  loads, `ready` awaited in `ensure_started`, quit flag + `PDEATHSIG`), and `shutdown`/`unregister`
  keep working across reload and autosplit rollback. `register_host_memory` is undone on unload
  (`unregister_host_memory`) or the next load in the same process may fail.
* **Affinity**: the engine thread that spins needs a core; it joins the existing reservation
  (`EXL3_HOST_CORES`, `moe_cpu_host.py:187` `_apply_host_affinity`) rather than a GEMV pool. There is
  no pool to size: the card schedules its own 256 vector engines, so `EXL3_MOE_CPU_THREADS`,
  `_PIN`, `_SPREAD` and `_SMALL_WORKERS` have no B70 counterpart.
* **Coexistence with the CPU worker**: two hosts, two rings, two slot regions. A row whose picks
  span `S_b` and `S_c` produces one job per worker and the collect adds both partials (the combine
  already adds; the `COMPUTE_GATED` gate is per worker). Deferred to Phase 5 for the ordinary case —
  nothing in the protocol blocks it — its first real use is the oversized regime of §4a (phase 4b),
  where a non-resident expert must be *delegated* rather than waited for; for a model that fits the
  two VRAM tiers the CPU has no home and the question does not arise. Two extra obligations come with
  it: the row-split predicate has to classify picks into three destinations (the issue kernel
  already writes a per-row `dev_count`, so it becomes a small per-row mask), and the promote/admit
  policy must be one optimisation over both tiers, not two independent greedy policies fighting over
  the same misses.

---

## 7. Code impact

| file | change |
|---|---|
| `exllamav3/exllamav3_ext/b70/` *(new)* | SYCL/Level Zero engine + kernels: a **torch-free C ABI** shared library (`b70_engine.so`), driven by ctypes — the probes prove that shape works end to end and it keeps `-fsycl` out of the nvcc build (`util/cuda_flags.py:77 extension_sources` walks `.c/.cpp/.cu` and would choke on a SYCL TU) |
| `exllamav3/ext_b70.py` *(new)* | locate or JIT-build `b70_engine.so` with `icpx -fsycl`, mirroring `ext.py`'s JIT/cache/env logic; capability probe (device present, aspects, `register_host_memory`, graph support, `spillMemSize == 0` for shipped kernels) |
| `exllamav3/model/moe_b70_host.py` *(new)* | `MoeB70Host`: reuses the ring/flag/geometry constants, `_set_job_seq`, `_write_flag`, `check_shm_capacity`, `probe_bandwidth`, `_HugeArena` from `moe_cpu_host.py`; own `_spawn`/child main (upload + engine loop); own `submit_prefill` policy (no streaming for `S_b`, no count readback); own slot format (§3 P1) |
| `exllamav3/model/moe_cpu_host.py` | *factor out*, do not fork: the protocol half (constants 45-82, `ensure_started` geometry 1187-1290, `_register_handoff` 1050, watchdog 1310, fused issue/collect 1411-1467) becomes worker-agnostic; the CPU-specific half stays. Until that refactor lands, `MoeB70Host` may subclass and override — but each override must be listed here so the Level-D tests keep being run against both |
| `exllamav3/exllamav3_ext/routing.cu` | `moe_split_issue_kernel` gains a payload mode: compact message, int8 quantisation (+wide plane, `q`, `Σx8`), row-split predicate. The fp16/slot mode stays for the CPU worker |
| `exllamav3/exllamav3_ext/cpu/moe_handoff.cu` | none (its `*_fused` host calls and flag ops are worker-agnostic; `exl3_moe_cpu_worker_run` is simply not used by the B70 host) |
| `exllamav3/exllamav3_ext/moe_unswizzle.cu` | untouched while `S_b` is native-ordered; gains a `(src_layout)` selector only if the B70 repack lands |
| `exllamav3/modules/block_sparse_mlp_cpu.py` | eligibility: replace the `device.type == "cuda"` test at `cpu_maybe_offload_load`/`cpu_maybe_split_load` (402, 428) with "an offload worker is configured"; three-home placement — two cut points on the sorted permutation — in `load_cpu_split` (778); delegate `cpu_split_submit`/`cpu_split_combine` (556, 633) to the right host; swap/promote (`_split_swap_tick` 936, `_split_promote_step` 189) extended to the B70 tier or explicitly disabled there |
| `exllamav3/model/config.py` | `-mbl/-mb/-mba` and the knobs of §8, next to `moe_cpu_offload`/`moe_cpu_split` (42-54) |
| `exllamav3/model/model.py` | spawn the B70 engine beside the CPU worker before module load (614-616); same TP refusal (695-710) |
| `exllamav3/util/backend.py` | `B70` fact module: presence, toolchain, and the per-backend defaults that `MoeCpuTuning` currently hard-codes for a CPU worker |
| `tests/b70/`, `notes/b70/` | see `b70-harness.md` |
| `doc/env_vars.md` | document every new knob (the prep README lists four knobs that were live but undocumented — do not repeat that) |

## 8. Knobs

Naming follows the existing convention (`EXL3_MOE_*`, mirrored in `MoeCpuTuning`-style objects, plus
CLI aliases in `config.py`). Family A/B/C = shape / policy / implementation, per
`doc/prep/tuning-knobs.md`.

| knob | class | default | meaning |
|---|---|---|---|
| `-mb N` / `EXL3_MOE_B70_SPLIT` | A | 0 | put the coldest `N` experts of every eligible layer on the B70 (mirror of `-mcs`) |
| `-mba` / `EXL3_MOE_B70_AUTO` | B | 0 | size `S_b` to fill B70 VRAM with the experts that do not fit the 3090 |
| `-mbl N` / `EXL3_MOE_B70_LAYERS` | B | 0 | restrict the B70 split to the first N eligible layers |
| `EXL3_MOE_B70_SLOTS`, `…_SLOT_ROWS` | A | 4, 256 | ring depth and rows per job (prefill chunking; decode is unaffected because one job is one step) |
| `-mbg N` / `EXL3_MOE_GPU_SLICE` | A | `auto` | experts kept on the 3090; with disjoint homes this *is* the row-router's first cut. `auto` = 24 GiB − streamed non-expert − KV(ctx)×rows − state×rows − reserve, computed at load by the planner (2.1a) rather than assumed: 16.6 GiB on both reference models at 4k ctx |
| `EXL3_MOE_B70_BALANCE` | B | `order` | cut-point rule: `order` = frequency-sorted fills (optimal while a CPU residue exists), `lpt` = minimise the per-layer maximum (wins once the residue is gone, +13 % measured for Qwen3.8 at b=8). Chosen per model by the planner from its own `h` |
| `EXL3_MOE_B70_SLICE_BYTES` / `…_GPU_SLICE_MB` | A | fill | byte budgets per home, the quantities the cut points are actually derived from (per layer: §4a rule 2) |
| `EXL3_MOE_B70_MISS_POLICY` | B | `cost` | `cost` = admit iff predicted uses in the window beat the §4 break-even; `never` = static homes only; `always` = admit on first miss (measures the trap in §4a's table) |
| `EXL3_MOE_B70_COLICATE` | B | `freq` | placement order within a layer: pure frequency (optimal for the compute term) or a co-location pass that trades rate for a lower spanning fraction `σ` (E13 decides whether it pays) |
| `EXL3_MOE_B70_QUANT_INPUT` | C | 1 | int8 payload from the 3090 vs fp16 (0 also disables the wide-plane path: use for numerics bisection only) |
| `EXL3_MOE_B70_OUT_F16` | C | 0 | return fp16 partials (halves the uplink) |
| `EXL3_MOE_B70_ENGINE` | C | `graph` | `phase` (T0) / `graph` (T1) / `resident` (T2) |
| `EXL3_MOE_B70_RESIDENT_WGs`, `…_POLL_BACKOFF` | A | 64, ~500 | resident-engine footprint and poll rate (`LESSONS` 6 — a wrong value here costs 1000×, not 10 %) |
| `EXL3_MOE_B70_SWIZZLE` | A | 0 | B70-side banding (§2.2); must be reported by `exl3_b70_tile_layout` |
| `EXL3_MOE_B70_ARENA` | B | 1 | keep a host-arena copy of `S_b` weights (needed for spill, streamed `S_c` and eviction); off is only offered when the whole set fits B70 VRAM |
| `EXL3_MOE_B70_LAYER_BALANCE` | A | `bytes` | how the tier is divided across layers: `none` (global frequency tail, can leave layers empty), `bytes` (equal bytes per layer, §4a rule 2), `freq` (equal pick-share per layer) |
| `EXL3_MOE_B70_ADMIT_T` | B | 4 | uses (in the admission window) before an expert is worth a 655 µs upload; `0` = admit on first miss, `-1` = never (static placement) |
| `EXL3_MOE_B70_WINDOW` | B | 512 | tokens (decode) over which use counts are accumulated before deciding; prefill decides per chunk |
| `EXL3_MOE_B70_PROMOTE_BUDGET` | B | 2 | experts admitted per step, on the low-priority transfer queue; 0 disables online admission (prime-only mode) |
| `EXL3_MOE_B70_EVICT` | B | `lfu-decay` | victim rule for `S_b`; `hyst` mirrors `EXL3_MOE_CPU_SWAP_HYST` semantics |
| `EXL3_MOE_B70_PRIME` | B | 1 | at load, fill `S_b` from the saved expert-stats profile before the first forward |
| `EXL3_MOE_B70_DISK_RING_MB` | A | 64 | pinned ring size for the `S_d` (checkpoint→B70) path; also bounds transient host memory |
| `EXL3_MOE_B70_ARENA_CAP_GB` | A | auto | cap on the host arena, so an oversized model keeps a DRAM tier instead of trying to hold 109 GiB in 125 GiB; beyond it, experts are `S_d` and admission is disk-priced |
| `EXL3_MOE_B70_THREADS`, `…_PIN` | C | 2, 1 | engine thread count/pinning (transfer thread + engine loop) |
| `EXL3_MOE_B70_PROF`, `…_STREAM_DEBUG`, `…_VERIFY`, `…_MAX_ISA` | C | off | observability parity with the CPU worker; `…_VERIFY` runs the same job on the CPU worker and diffs |
| inherited | | | `EXL3_MOE_CPU_SPLIT_STATS` (placement profile — same state-pinning requirement, `doc/prep/measured-costs.md` §8.3), `EXL3_HOST_CORES`, `EXL3_MOE_STREAM_MIN_ROWS` (path selector), `EXL3_MOE_STREAM_T` (only for `S_c`) |

Knobs that **stop applying** when a layer's experts are in `S_b`: `EXL3_MOE_CPU_WSLOTS/_WSLOT_MB`,
`EXL3_MOE_STREAM_BATCH_EXPERTS`, `EXL3_MOE_STREAM_FUSED_T`, `EXL3_MOE_STREAM_BATCH_RECON`,
`EXL3_MOE_CPU_STAGE_THREADS`, `EXL3_MOE_PINNED_ARENA`'s streamed-DMA half, and
`EXL3_MOE_CPU_SWIZZLE`'s GPU-restore consequence (§3 P3). They stay live for `S_c`.

## 9. Phases and gates

Each phase ends with a commit at a known-good state and a harness report; a gate may be *explained*
by a measurement but not waived. (Gate definitions: `b70-harness.md`.)

| phase | deliverable | gate |
|---|---|---|
| 0 | probes in `notes/b70/` (done: transport, notify paths, resident engine, cross-vendor and cross-process region, store discipline) + engine skeleton that round-trips one fake job | D0 (protocol liveness), A-format bit-exactness of the uploaded bytes (`memcmp` B70 VRAM against the source tensors) |
| 0b | *offline, no B70 code needed*: `plan_placement.py` over routing traces from existing `-mcs` runs → per-home pick share, per-layer `σ`, predicted ms/token for every candidate pair of cut points | E13/E14 inputs; the placement design is falsified on today's tree before any kernel exists |
| 1 | T0 engine, naive `Recipe A` decode kernel, fp16 payload, `-mb` on a small split, CPU worker untouched | **A** bit-exact, **B′** rel RMS ≤ 2.5e-2 vs the fp64 oracle *and* vs the CPU tier, **C1-C3** model agreement, **D** all invariants, **E1/E2/E3** handshake floors |
| 2 | T1 graph engine, int8 payload + wide rows, `Recipe B` GEMV, layout decision measured | **E4** cold-expert read rate ≥ 300 GB/s, **E1** empty job ≤ 10 µs, **B3** determinism, zero spills in every shipped kernel |
| 3 | prefill: rows-to-B70, big slots, row split, streaming off for `S_b` | **E5** prefill link efficiency ≥ 80 % of measured rate; **E7′** (successor of E7) B70 prefill ≥ 4× the CPU-tail path on the same model |
| 4 | three-home partition (two cut points), migration policy, reload/autosplit, docs + env-var table | **C** at `-mb 255`/`-mba` on both reference models, decode within 5 % of the all-GPU reference on Qwen3.5 |
| 4b | oversized models (§4a): per-layer byte quotas, online admission + eviction, low-priority transfer queue, `S_d` disk path, CPU coexistence, planner prints `h_min` | **E9** capacity–throughput curve is smooth (no cliff > 15 % between adjacent capacity points), **E10** measured `h` ≥ `h_min` on the calibration corpus or the planner refuses the configuration, **E11** thrash test converges within 2 % tok/s after a topic switch, **U** admission energy ≤ 10 % of the run's J/token |
| 5 | optional: T2 resident engine, CPU+B70 coexistence, second B70, power policy | each justified by a ≥ 20 µs/token measured saving |

## 10. Risks

| risk | mitigation |
|---|---|
| `register_host_memory` on a second process's mapping works *today* (`probe_crossproc.py` 10/10) but is driver-version-specific | it is a per-commit test, not an archived result; fallback stays designed-in = engine as a parent-side thread (§6) |
| documented `sycl_ext_intel_matrix` extras are newer than the installed 2026.2 runtime (no `aspect::ext_intel_matrix`) | build-time capability probe; kernels written against plain `joint_matrix` / ESIMD `xmx::dpas` with the OpenCL `intel_sub_group_*` route as the reference; `b70-kernels.md` §4 grades the options |
| a resident engine wedges the card, or blocks a second B70 user | T2 off by default; sized by measurement; child dies on device-lost so the parent's watchdog turns it into an exception instead of a hang |
| `.wait()`/event latency creeping back into the hot path (it is 24 µs and silent) | the harness asserts a *per-job host-time* budget and the code review rule: no `wait()` outside setup/teardown (`LESSONS` 1) |
| int8-dot or funnel-shift mis-compilation quietly corrupts weights | the format test vectors from `doc/b70` (K=4 table) run as a device unit test at every commit, plus the `EXL3_MOE_B70_VERIFY` differential against the CPU tier |
| fp32-vs-int32 accumulation temptation changes the numeric class | Gate B′ pins the class; any deviation (e.g. bf16 DPAS) needs a new level-B measurement, not a relaxed threshold |
| the link is not really 14.4 GB/s on another boot (sysfs says Gen1 ×1 **[M]**, measured 14.4) | never hard-code: `probe_bandwidth` at startup drives `SLOT_ROWS`, `ADMIT_T`, the quotas and `stream_t(S_c)`, and the report states the measured rate with every number |
| power/thermal: 275 W cap, and B70 prefill is a sustained all-core load | the harness samples board power and pkg/vram temperature; a throttled run is flagged by the temperature slope, not by wall time alone |
| placement profile leaks between runs (the single biggest confounder found in the prep work) | harness deletes or pins the profile per run, exactly as `notes/run_profile_ab.sh` does, and every reported number names its placement start |
| **oversized model oscillates in `S_b`** (two hot expert sets, e.g. code vs prose) and every swap costs 655 µs of link per expert | hysteresis on eviction (`…_EVICT=lfu-decay`, mirroring `EXL3_MOE_CPU_SWAP_HYST`), a per-step admission budget, and the thrash test (E11) as a regression gate; if `h` cannot reach `h_min`, the honest answer is that the model is too big for one B70 and the planner should say so rather than run |
| admission traffic steals bandwidth from activations and the two fight each other into a worse state than either alone | low-priority transfer queue (L0 only, §4a), budget per step, and E5 measured *with* admission active, not with it disabled |
| host DRAM exhaustion on a 100 GiB-class expert set (this box has 125 GB and the arena for GLM-5.3 alone is 109 GiB) | `S_d` disk path with a bounded pinned ring (never an unbounded arena), `EXL3_HOST_MEM_RESERVE_MB` respected per 1 GiB chunk as today, and `-mba` sized so `bytes(S_c)` + KV + the B70 staging fits with the reserve |

---

## 10a. Standing rules the probes earned

Three rules that are not optional, because each was bought with a silent-failure bug:

1. **Payload movement is asymmetric.** In: `memcpy` (DMA) into B70 VRAM. Out: kernel stores to the
   pinned slot, then `sycl::atomic_fence(acq_rel, system)`, then the flag store. Never let a kernel
   chase host pointers for input (`LESSONS` 7: 16 KiB as one dependent chain = 280 µs).
2. **No `sycl::atomic_ref` on the shared region at any scope** (`LESSONS` 4 — it loses the device);
   flags are fenced volatile stores, and the only atomics allowed on shared memory are host-side
   `std::atomic`/`volatile` reads by the engine thread.
3. **Kernel index arithmetic is spelled out** (`i[0]`, explicit casts) and **every kernel test
   compares every payload word it wrote**, not a return code or a flag (`LESSONS` 4a — the sloppy
   form compiles, "succeeds", and stores nothing).

## 11. Open questions that could still change this design

Each is answerable by one probe or one benchmark, listed in the order that would hurt most if the
answer goes the wrong way:

1. ~~Does `register_host_memory` work on a segment mapped in a second process?~~ **Answered: yes**
   (`probe_crossproc.py`, 10/10, `out_crossproc.txt`). Closed 2026-10-28; §6 keeps the child-process
   design. The residual risk is that this is driver-version-specific, so the test belongs in the
   per-commit set rather than in the archive.
2. ~~Does `dot_4x8packed_us_int` / `sycl::ext::oneapi::dot_acc` compile to one Xe2 instruction?~~
   **Answered behaviourally** (`probe_rates`, R6 vs R7, reproduced over three independent runs):
   the hardware dot and a manual byte-sum differ by 0.2–0.4 % (mean 1.002×, 1.004×) at realistic
   decode density, and that density costs 4.4 % (Qwen3.8) to 0.1 % (GLM) of bandwidth against the
   same reads with no arithmetic. Decode is bandwidth-bound, so the ISA question no longer gates
   the design; it stays relevant to the XMX prefill routes and to J/token. (Direct ISA inspection is
   unavailable on this driver: `IGC_ShaderDumpEnable` emitted nothing, `SYCL_SAVE_TEMPS` left no files.)
3. ~~How much of the 608 GB/s does the decode GEMV actually reach?~~ **Measured, with a surprise**:
   scattered 132–292 GB/s (Qwen3.8) and 132–260 (GLM), clustered 216–558, native order — and the
   absolute rate depends ~2× on the *working-set size*, non-monotonically, which is why no design
   number is allowed to rest on one microbenchmark point (`out_rates_footprint.txt`). The arrangement
   is worth 1.08–1.99× while the tile permutation is worth 0.96–1.05× with no consistent sign, so the
   lever moved from layout (§2.2, decided on engineering grounds rather than closed) to kernel
   scheduling and VRAM allocation (b70-kernels.md §3a; gate E4 restated against both regimes). Once the
   rate is sampled at the footprint a decode layer really
   presents (`plan_operating_point.py`), Qwen3.8's b=1 layer is **51 µs** and stays hidden ~5×, while
   **GLM's is 405 µs** — worse than the pooled figure suggested, because its 9 MiB experts put a token's
   50.9 MiB of reads on the worst point of the curve. It compounds with GLM's flat routing distribution,
   and it is batch-sensitive: Qwen3.8's own margin is gone by b≈8.
4. **Is a resident engine survivable in production** (device-loss semantics, a second B70 client,
   `power1_cap` behaviour while spinning)? Measured: 3.2 µs round trip and a 21–371 µs drain, so it
   is worth ~2–5 µs/layer and nothing more.
5. **DPAS route R1 (fp16 B) vs R2 (u8 product bytes)** — depends on whether the card is ALU- or
   XMX-bound at the model's actual rows/expert, and on the undocumented byte order inside a DPAS
   operand (confirm with the vectors first).
6. **Where the input transform belongs** (3090 in the issue kernel vs B70): the payload argument is
   only real if E5 shows the link as the prefill bottleneck; B′5 has to pass either way.
7. **What serves `S_c` best on a machine with a B70 at all** — the CPU GEMV at 47.4 GB/s, streaming
   the expert to the 3090 at 14.4 GB/s, or migrating it into `S_b`? §4's migration table ranks them
   per (expert, window), and the answer for a *resident-elsewhere* expert at decode is settled; what
   is not settled is the per-chunk streamed case, where `stream_t`'s inherited value (8, scaled by
   measured link rate) has never been calibrated against a B70-era configuration. Recalibrate it in
   phase 3 rather than trusting it.

## 12. What is final, and how each item would be reopened

This is the plan's contract with the implementation phase: every row is either *closed on evidence*
(the build must not re-litigate it) or *open behind a named gate* (the build must not assume it).
Numbers are **[M]** measured on this box or **[P]** projection, and every `[P]` sits behind a gate.

| decision | status | evidence | reopened by |
|---|---|---|---|
| B70 is a worker, not a second torch device; parent protocol unchanged | closed | `probe_cross.py` 8/9, `probe_crossproc.py` 10/10 | a driver that refuses cross-process `register_host_memory` (§6 Plan B: parent-side thread) |
| engine in a child process | closed | `out_crossproc.txt` | same as above |
| completion by pinned flag, never `.wait()` | closed | 24 µs vs 5–8 µs **[M]** | nothing; the harness asserts it (D-level test) |
| payload: DMA in, fenced kernel stores out | closed | 258–283 µs vs ~2 µs for the same bytes **[M]** | nothing |
| no `sycl::atomic_ref` on the shared region, at any scope | closed | `UR_RESULT_ERROR_DEVICE_LOST` repro (`probe_stores.cpp` case 7) | nothing |
| explicit `i[0]` indexing + every-word assertions in kernel tests | closed | silent zero-store bug, `LESSONS` 4a | nothing |
| three disjoint homes, two cut points, no replication | **weakened**: holds where capacity is scarce, not where it is surplus | the old 1.5× rate premise was spec-to-spec; footprint-matched the homes are 3.2× (Qwen3.8) to 7× (GLM) apart. Disjointness now rests on the CPU residue costing `bytes/47.4`, which still holds for GLM. `plan_parent_budget.py` also shows Qwen3.8 running `h` = 100 % with ~12 GiB spare **[M]** | E20: replicating the hottest experts and steering per pick, if surplus survives real context lengths (E14) |
| native tile layout on the B70, no repack | **decided on engineering grounds, not closed by measurement** | banded/native 0.96–1.05× over 2 geometries × 6 footprints: no consistent sign, and the probe's configuration variance exceeds the effect **[M]** | E4c: a *consistent* win in the real GEMV at decode footprints, large enough to pay for a load-time repack and for losing byte-interchangeability with the 3090 kernels |
| locality rules (one expert per work-group, contiguous per-layer VRAM) | adopted as design, unmeasured in situ | clustered/native 1.08–1.99×, never below 1.08 **[M]** | E4 measuring the real GEMV below 200 GB/s |
| streamed/staged prefill dead for `S_b`, live for `S_c` | closed | ~200-row crossover from measured bytes/rates | a model with far more skewed routing (E7′ measures) |
| admission economics: β ≈ 655 µs, μ_cpu ≈ 199 µs, break-even ≈ 4 uses | closed as arithmetic | measured rates | only new rate measurements |
| migration policy = cost-based, break-even on **churn**, not picks | adopted as arithmetic; **churn itself unmeasured and unmeasurable offline** | `\|res\|`, `fill`, and the two thresholds, which coincide at ~0.3 %/token (link saturation 0.31 %, economic 0.36 %) from measured quantities | E11: under ~0.3 %/token migrate with a link-budgeted per-step cap; over it, `S_b` is static apart from priming and the CPU serves the residue |
| `h`/`σ` values quoted for the reference models | upper bounds, not promises | decayed cumulative profiles (dust counts of 1e-27) | E14 (fresh trace) — expect `h_live < h_profile` |
| spanning ≈ 1 whenever a residue exists; prefill bytes ≈ 2× | adopted | planner with real counts, independence approximation | E13 with a real co-occurrence trace |
| T1 (graph/command-list per job) as the shipping engine tier | adopted | 5–8 µs vs 24 µs vs 3.2 µs **[M]** | E1/E8 if the engine thread, not the card, becomes critical |
| T2 resident engine | open, gated | 3.2 µs round trip, 21–371 µs drain **[M]** | only a ≥ 20 µs/token measured win |
| DPAS route R1 (fp16 B) vs R2 (u8 product bytes) | open, gated | unmeasured; undocumented DPAS operand byte order | E4/E7 prefill sweep at 32/128/512 rows |
| quantise `x` on the 3090 (int8 payload) | adopted, cheap to flip | halves payload; B′5 makes either side verifiable | E5 showing the link is not the prefill bottleneck |
| GLM-class oversized verdict (cards needed, CPU share) | measured for the local profile | 19.6 → 6.9 → 0.9 ms/token at 1/2/3 cards | E14/E11 with live traces |
| …and the verdict **revised** by the parallel-max view | per-worker busy time is real but does not set throughput | `max(T_parent, T_b70/N, T_cpu)` → 51 → 79 → 79 tok/s, so the 3rd card buys nothing unless `T_parent` < 135 µs | E10 (GLM's `T_parent`); E4 below 64 MiB/launch, because the 2-card case presents 32 MiB and that part of the curve is unmeasured |
| decode rates must be footprint-matched before use | adopted as a rule | `plan_operating_point.py`: 14.3 MiB/layer (Qwen3.8 b=1) → 292 GB/s → 51 µs; 50.9 MiB (GLM b=1) → 132 GB/s → 405 µs **[M]** | any estimate multiplying a GB/s figure by layer bytes without naming the footprint it measured that rate at (`LESSONS` 19) |
| "the offload hides at decode" | true for Qwen3.8 at b ≤ 4, **not** general | margin 4.9× → 1.3× → 0.5× over b = 1 → 4 → 8, from real selection counts | E9's batch axis; if the measured crossover is below b=4, the decode path is a small-batch optimization and the docs must say so |
| `S_g` quota = whatever the KV trade leaves (2 GiB assumed) | **replaced by a computed budget** | byte bills from shard headers + config: 4.05/5.67 GiB streamed non-expert, 22–24 KiB KV/token, 108–136 MiB state/sequence, and the 49.91 GiB n-gram tables are host row-gathers, not VRAM → ~16.6 GiB free at 4k ctx **[M]** | E14 at the deployment's ctx/rows; E18 if the traffic half of the bill is wrong |
| placement objective = minimise summed compute | **replaced: minimise the per-layer maximum**, with `S_g` serial and `S_b`/`S_c` concurrent | 2.1a; `P_order` vs `P_lpt` differ by 0 % (Qwen3.8 b=1) to +20 % (GLM, ordered better) depending on regime **[P, from measured rates]** | E19 |
| hottest-first within a layer | retained **while a CPU residue exists**, not as a universal rule; the boundary is **recipe-dependent** | spreading hot experts over both VRAM homes leaves colder ones to `bytes/47.4`, the most expensive byte on the box (GLM: `order` wins 9–20 %). Across five Qwen3.8 recipes: `lpt` wins +3…+9 % at 2.05/2.68/4.05/5.05 bpw, `order` wins **+43 % at 6.05 bpw**, the only one with a real residue **[M]** | E19 |
| §2.1a's premises are recipe-general on Qwen3.8 | checked, not assumed | matched rate band 207–295 GB/s at K = 2.5–6.0; parent duty 31–45 % at every quant; residency falls 512 → 104 slots/layer only through `expert_bytes` **[M]** | a recipe that scaled the streamed non-expert tensors with bits — then the parent's duty would climb with quantisation and the "spare bandwidth on the 3090" premise would break |
| every knob default except the rate-derived ones | provisional | — | phases 1–4 gates |

Nothing else in this document is a decision: the remaining prose is rationale, and rationale does not
need to be final — only the rows above do.
