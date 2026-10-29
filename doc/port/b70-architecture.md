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
   S_g   home = 3090 VRAM      ~936 GB/s      quota: whatever the KV/weight trade leaves
   S_b   home = B70 VRAM       ~608 GB/s peak <- the new tier, filled to capacity
   S_c   home = host DRAM      ~45 GB/s CPU   the arena; also the source for a 655 us upload to S_b
   S_d   home = NVMe           ~5.0 GB/s [M]  read through a bounded pinned ring when needed
```

Disjointness is the point, not an simplification: the two devices' expert-read rates are within 1.5×
of each other, so a replica of an expert on both cards buys nothing except capacity that neither
tier has — every GiB duplicated is a GiB that cannot hold a *different* expert, and on an oversized
model that GiB is the difference between the CPU computing a pick in 199 µs and a device computing it
in 22 µs. Placement is therefore a **partition problem over three (or four) homes**, sized by each
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
the expert tensors from the checkpoint, and uploads each layer's expert block over the link
(`14.4 GB/s` **[M]** ⇒ 36 GiB in ~2.7 s, overlapped with the parent's own module load — same
trick `model.py:614` uses to hide the CPU child's interpreter start). Aux tensors (`suh`, `svh`,
bias) are uploaded alongside, per expert, in a side table the kernels can index.

`S_c` handling: **keep the existing host arena byte-for-byte as it is**, including the CPU tier's
packed layout, because it is also (a) the source for streamed prefill of spilled experts and
(b) what promote/demote and `moe_unswizzle_trellis` operate on. The B70's VRAM copy is made in the
B70's own layout (below) at upload time; when an expert is spilled out of B70 VRAM the B70 reads it
from the arena over the link (rare, and the layout question recurs there).

If the B70 holds all offloaded experts, the host arena can be dropped entirely (`EXL3_MOE_B70_ARENA=0`):
a second, independent saving of the same 36 GiB in *host RAM*. That is only sound when nothing is in
`S_c`, so it stays opt-in.

### 2.2 Weight layout on the B70

Native tile order first (the format's own order, `doc/prep/mul1-trellis.md` §2). It has three
advantages: no repack pass at load, no un-swizzle anywhere, and the bytes are interchangeable with
the GPU's kernels, so an expert can be streamed B70→3090 (or the reverse) with no translation.

A B70-specific repack (k-major banding along `n`, the GPU analogue of the CPU's band-8) is a
*measured optimisation*, not a prerequisite: Xe2's 128-byte cache lines and 18 MB L2 make a
128–256 B strided tile read much less costly than it is on x86, and `annotated_ptr`/evict-first
cache controls recover most of the difference. If it is adopted, the rule must live in exactly one
place — `exl3_b70_tile_layout(K)` — be *reported* to every consumer (upload, spill read, streamed
transfer), and never be conflated with `exl3_moe_cpu_swizzle_group(K)`: the arena and the B70 copy
of the same expert may legitimately differ. Acceptance Gate B4 applies verbatim.

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

So `σ → 1` costs roughly `2×` the payload and `2×` the handshake per row: ≈1.8 µs + ≈12 µs per
spanning row per layer, which at 1 row/token and 48 layers is ≈0.7 ms/token — comfortably hidden
behind the parent's ~10 ms/token of work, but worth *minimising*, because the same doubling applies
per row at prefill where the rows are 2048 and the link is the bottleneck. Two levers, both offline:
the frequency-sorted permutation (hot experts co-occur with hot, so the 3090's slice absorbs a
disproportionate share of whole rows) and, if E13 shows `σ` uncomfortably high, an explicit
co-location pass that trades a little rate for a lot of spanning (same section, `…_COLICATE`).

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

PLACEMENT (offline, per layer, two cut points on the frequency-sorted permutation):
  minimise  sum_D [ E[compute(D)] / rate_D + E[rows_touched(D)] * payload / link_rate ]
  subject to bytes(S_g) <= VRAM_3090 - KV - dense   and   bytes(S_b) <= VRAM_b70, bytes(S_c) <= DRAM_cap
  frequency order within a layer is optimal for the compute term (equal bytes per expert, uniform
  rate per home); sigma (the spanning penalty) is the only reason to deviate from it (..._COLICATE).

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

Constants on this box: `link_rate` 14.4 GB/s **[M]**, `notify` 3.2 µs resident / 5–8 µs per
submission **[M]**, `vram_rate` ≤608 GB/s (target ≥70 % for the GEMV, i.e. ≥420 GB/s, to be
measured), `xmx_rate` 183 TFLOP/s fp16 / 367 TOPS int8 **[M]** via `b70-bench`, `parent_gpu_work`
165 µs/layer (Qwen3.5) and ~250 µs/layer (Qwen3.8) **[M, doc/prep]**.

What the model says at a glance:

* Decode: with 8 experts × 1.465 MiB read at 420 GB/s (28 µs) plus a ~10 µs handshake, the B70 job
  is 4–7× shorter than the window the parent gives it. The knob that matters is therefore *how many
  experts land on the B70*, not how the handshake is built — until the handshake stops being hidden.
* Prefill is link-bound at ~2048 rows unless `sz_out` drops to fp16 or the row split keeps more work
  on the 3090; the model gives the crossover for both, and the harness measures which the box lands on.
* Adding a *second* B70 (32 GiB each) would make Qwen3.8 fully `S_b`-resident; the ring/protocol
  already supports several workers because each gets its own `MoeCpuHost`-shaped object.

---

## 4a. Models that exceed the tiers: hit-rate engineering

Everything above assumes the offload device holds the experts it is asked about. That stops being
true as soon as `bytes(experts) > VRAM_b70`, and it stops being a footnote for any serious model.
`notes/scan_expert_capacity.py` (output in `notes/m_expert_capacity.txt`) reads the local
checkpoints' safetensors headers and prints this table plus the economics below — text-model experts
only, since an MTP/draft head is a separate capacity consumer with its own rate (Qwen3.5's MTP
experts are 4 bpw against the text model's 3 bpw, 0.38 GiB of them, and every verify step touches
them):

| checkpoint | MoE layers × E | expert block | routed-expert trellis | fits one B70 | per-layer quota | `h_min` |
|---|---|---|---|---|---|---|
| Qwen3.5-35B @3 bpw | 40 × 256 | 1.125 MiB | 11.25 GiB | 100 % | 726 of 256 (surplus) | 39 % |
| Qwen3.6-35B @2.49 | 40 × 256 | 1.125 MiB | 9.09 GiB | 100 % | surplus | 39 % |
| Qwen3.8-FN @2.05 | 48 × 512 | 1.17 MiB | 28.12 GiB | 100 % | 581 of 512 (surplus) | 53 % |
| Qwen3.8-FN @2.68 | 48 × 512 | 1.465 / 1.758 MiB | 36.33 GiB | **87.8 %** | 387 of 512 | 68.8 % |
| Qwen3.8-FN @4.05 | 48 × 512 | 2.34 MiB | 56.25 GiB | 56.7 % | 290 of 512 | 76.6 % |
| Qwen3.8-FN @5.05 | 48 × 512 | 2.93 MiB | 70.31 GiB | 45.4 % | 232 of 512 | 81.2 % |
| Qwen3.8-FN @6.05 | 48 × 512 | 3.52 MiB | 84.38 GiB | 37.8 % | 194 of 512 | 84.4 % |
| GLM-5.3-Flash @3.05 | 43 × 288 | 9.00 MiB | **108.84 GiB** | 29.3 % | 84 of 288 | **92.4 %** |

Two readings. The **cache regime starts at ~32 GiB of expert trellis**, which the local reference
model (Qwen3.8 @2.68) already crosses — so the §4a machinery is not an exotic corner, it is what the
second reference model runs on, just gently (12.2 % spilled). And `h_min`, the hit rate the policy
must exceed for prefetch to keep up, climbs from 69 % to a hard **92.4 %** on GLM: past ~90 % the
cache cannot converge on prefetch alone and misses must be *served* (CPU worker) rather than hidden,
which is where the second B70 or a smaller quantisation is the honest answer.

`h` below means **device-resident pick share**: the fraction of a step's `topk` picks whose expert
has a device home. Because placement is frequency-ordered, `h` is much larger than the byte-residency
fraction — routing skew means the last 71 % of experts by size carry far less than 71 % of the picks —
and `h` is *predictable offline* from the saved expert-stats profile, before a single forward pass
(gate E14 checks that prediction against measurement). When `bytes(experts) > VRAM_3090 + VRAM_b70`
the residue is not an accident but a designed share of the work handed to the CPU, and the port's
central problem stops being handshake latency (which is hidden anyway) and becomes that share.
Three numbers frame it, all derived from measured rates for GLM-5.3-Flash (9.00 MiB expert, K=3,
topk 8, 43 MoE layers;
`link` and `disk` are **[M]** — 14.4 GB/s and 5.0–5.2 GB/s `dd iflag=direct` — the CPU rate is the
K=3 figure from `doc/prep/measured-costs.md` §5, and 420 GB/s is the *target* B70 read rate E4, so
`brk-even` moves with it but only weakly):

```
admit(expert -> S_b)   = expert_bytes / link_rate            = 655 us   (from S_c)
                         + expert_bytes / disk_rate (~5 GB/s) = 2.5 ms   (from S_d)
CPU compute / use      = expert_bytes / 47.4 GB/s            = 199 us
B70  compute / use     = expert_bytes / 420 GB/s             =  22 us
break-even uses        = 655 / (199 - 22)                    = 3.7      (scale-invariant: the ratio
                                                                  of three byte-proportional rates)
```

so *admit on the third use* is roughly optimal, independent of model size, bitrate and expert shape.
And because the miss path is only paid once per expert while the hit path is paid per use, the whole
decode cost curve is steep in the hit rate `h` (misses/token = `topk·(1−h)`, ×43 layers):

| `h` | CPU-served picks/token | CPU cost of them | link cost if they were admitted instead, per token |
|---|---|---|---|
| 0.70 | 2.40 | 20.6 ms/token | 68 ms/token |
| 0.80 | 1.60 | 13.7 ms/token | 45 ms/token |
| 0.90 | 0.80 | 6.9 ms/token | 23 ms/token |
| 0.95 | 0.40 | 3.4 ms/token | 11 ms/token |
| 0.99 | 0.08 | 0.7 ms/token | 2 ms/token |

Read the last column as the trap the user's instinct is right about: below `h ≈ 0.97`, *admitting*
every miss costs more link time than the CPU spends computing it, so the CPU is the cheaper tier and
migration must be selective (admit on the ~4th predicted use, and prefer evicting toward `S_c` over
`S_d`). Above it, admission is a small investment that removes a large recurring cost. The two
columns are not alternatives to choose per token — they are the constraint set for the offline
placement, and `EXL3_MOE_B70_MISS_POLICY=cost` makes the per-window decision with exactly this
arithmetic rather than with a fixed threshold.

Two structural consequences for the design:

**1. Prefetch sets a hard floor on the achievable hit rate.** The link is shared with activations,
and the only window available at decode is the parent's own per-layer work `T_layer`:

```
prefetch budget per layer = link_rate * T_layer            (5.8 MB at T_layer = 400 us -> 0.61 experts)
feasible steady state     : topk*(1-h)*expert_bytes <= link_rate * T_layer
                         => h_min = 1 - link_rate*T_layer / (topk*expert_bytes)   = 92.4 % here
```

Below `h_min` the cache cannot converge no matter how good the policy is, and the misses must be
*served* rather than hidden — which means the CPU worker stops being an optional Phase-5 extra and
becomes **required** in oversized mode (§6), because a job that needs a non-resident expert must
either be delegated or stall, and stalling is never acceptable on the parent's stream. `h_min` is
printed by the planner at load (with the measured `T_layer` and `link_rate` it used) so a user is told
up front whether the model is oversized on this box instead of discovering it at 8 tok/s.

**2. Capacity must be split per layer, in bytes, by marginal gain — not globally.** A global
frequency sort leaves some layers fully resident and others not at all, and a layer with zero
residents pays `topk·CPU` on *every* token. Hit rate per layer is concave in its resident byte quota,
so the allocation is a water-filling over layers: repeatedly give the next MiB to the layer with the
largest `∂h/∂bytes`. In the common case (similar routing entropy everywhere) that degenerates to
*equal bytes per layer* — which is what `-mcs` already does per layer, except that it splits by
*expert count*, and Qwen3.8's 2.5- and 3-bpw layers have different `expert_bytes`. Budget in bytes;
let the per-layer count follow. Uniform-per-layer placement also keeps the P4 row-split rule sensible
(every layer has some resident experts, so rows carry only B70 work).

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
  `EXL3_MOE_B70_ARENA=0` mode (all experts on the B70, no host copy) forbids eviction, and it is only
  offered when `bytes(S_b) ≤ VRAM_b70`.
* **`S_d` is not hypothetical on this box.** Host DRAM is 125.6 GiB and GLM-5.3-Flash's expert trellis
  alone is 108.84 GiB (the whole checkpoint is 117 GB on disk — experts dominate a Flash-Next model to
  that degree), so a full arena would leave ~14 GiB for torch, the pinned ring, the in-flight 3090
  weights and the page cache. `S_c` therefore needs its own cap
  (`EXL3_MOE_B70_ARENA_CAP_GB`), with anything beyond it living only on disk; the placement table
  records the tier per expert (`S_b` / `S_c` / `S_d`) so a miss knows whether to pay 655 µs or 2.5 ms,
  and the cache policy then has two admission prices rather than one (cheap from `S_c`, expensive from
  `S_d` — evicting to `S_d` should be avoided in favour of evicting an expert that is still in `S_c`).
* **Scaling out is the real fix for this class.** `h_min` disappears once `bytes(experts) ≤ VRAM_b70`:
  two B70s make GLM 59 % resident (quota 168 of 288 per layer), four make it fully resident. The
  protocol already supports it — one engine child, ring and slot region per device, and the row-split
  predicate extended from "on the B70 or not" to "which of the N" (the `dev_count`-per-device
  mechanism the multi-GPU CUDA path already has). A capacity–device curve belongs in the same sweep
  as E9.
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
  The one capability this needs was proven in Phase 0: `probe_crossproc.py` passes 11/11 — the child
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
  nothing in the protocol blocks it — but **mandatory in the oversized regime of §4a**, where a
  non-resident expert must be *delegated* rather than waited for. Two extra obligations come with
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
| `exllamav3/modules/block_sparse_mlp_cpu.py` | eligibility: replace the `device.type == "cuda"` test at `cpu_maybe_offload_load`/`cpu_maybe_split_load` (402, 428) with "an offload worker is configured"; three-tier placement in `load_cpu_split` (778); delegate `cpu_split_submit`/`cpu_split_combine` (556, 633) to the right host; swap/promote (`_split_swap_tick` 936, `_split_promote_step` 189) extended to the B70 tier or explicitly disabled there |
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
| `-mbg N` / `EXL3_MOE_GPU_SLICE` | A | as today | experts kept on the 3090; with disjoint homes this *is* the row-routing knob (§3 P4), since a row's destination set follows from membership |
| `EXL3_MOE_B70_SLICE_BYTES` / `…_GPU_SLICE_MB` | A | fill | byte budgets per home, the quantities the cut points are actually derived from (per layer: §4a rule 2) |
| `EXL3_MOE_B70_MISS_POLICY` | B | `cost` | `cost` = admit iff predicted uses in the window beat the §4 break-even; `never` = static homes only; `always` = admit on first miss (measures the trap in §4a's table) |
| `EXL3_MOE_B70_COLICATE` | B | `freq` | placement order within a layer: pure frequency (optimal for the compute term) or a co-location pass that trades rate for a lower spanning fraction `σ` (E13 decides whether it pays) |
| `EXL3_MOE_B70_QUANT_INPUT` | C | 1 | int8 payload from the 3090 vs fp16 (0 also disables the wide-plane path: use for numerics bisection only) |
| `EXL3_MOE_B70_OUT_F16` | C | 0 | return fp16 partials (halves the uplink) |
| `EXL3_MOE_B70_ENGINE` | C | `graph` | `phase` (T0) / `graph` (T1) / `resident` (T2) |
| `EXL3_MOE_B70_RESIDENT_WGs`, `…_POLL_BACKOFF` | A | 64, ~500 | resident-engine footprint and poll rate (`LESSONS` 6 — a wrong value here costs 1000×, not 10 %) |
| `EXL3_MOE_B70_SWIZZLE` | A | 0 | B70-side banding (§2.2); must be reported by `exl3_b70_tile_layout` |
| `EXL3_MOE_B70_ARENA` | B | 1 | keep a host-arena copy of `S_b` weights (needed for spill, streamed `S_c` and eviction); off is only offered when the whole set fits B70 VRAM |
| `-mba` capacity split | A | bytes | per-layer **byte** quotas by water-filling (§4a) rather than one global tail; `EXL3_MOE_B70_LAYER_BALANCE=none\|bytes\|freq` |
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
| 0 | probes in `notes/b70/` (done) + cross-process `register_host_memory` test + engine skeleton that round-trips one fake job | D0 (protocol liveness), A-format bit-exactness of the uploaded bytes (`memcmp` B70 VRAM against the source tensors) |
| 1 | T0 engine, naive `Recipe A` decode kernel, fp16 payload, `-mb` on a small split, CPU worker untouched | **A** bit-exact, **B′** rel RMS ≤ 2.5e-2 vs the fp64 oracle *and* vs the CPU tier, **C1-C3** model agreement, **D** all invariants, **E1/E2/E3** handshake floors |
| 2 | T1 graph engine, int8 payload + wide rows, `Recipe B` GEMV, layout decision measured | **E4** cold-expert read rate ≥ 300 GB/s, **E1** empty job ≤ 10 µs, **B3** determinism, zero spills in every shipped kernel |
| 3 | prefill: rows-to-B70, big slots, row split, streaming off for `S_b` | **E5** prefill link efficiency ≥ 80 % of measured rate; **E7′** (successor of E7) B70 prefill ≥ 4× the CPU-tail path on the same model |
| 0b | *offline, no B70 code needed*: `plan_placement.py` over routing traces from existing `-mcs` runs → per-home pick share, `σ`, predicted ms/token for every candidate cut point (E13/E14 inputs). Do this before writing kernels: it is the only part of the placement design that can be falsified on today's tree |
| 4 | three-home partition (two cut points), migration policy, reload/autosplit, docs + env-var table | **C** at `-mb 255`/`-mba` on both reference models, decode within 5 % of the all-GPU reference on Qwen3.5 |
| 4b | oversized models (§4a): per-layer byte quotas, online admission + eviction, low-priority transfer queue, `S_d` disk path, CPU coexistence, planner prints `h_min` | **E9** capacity–throughput curve is smooth (no cliff > 15 % between adjacent capacity points), **E10** measured `h` ≥ `h_min` on the calibration corpus or the planner refuses the configuration, **E11** thrash test converges within 2 % tok/s after a topic switch, **U** admission energy ≤ 10 % of the run's J/token |
| 5 | optional: T2 resident engine, CPU+B70 coexistence, second B70, power policy | each justified by a ≥ 20 µs/token measured saving |

## 10. Risks

| risk | mitigation |
|---|---|
| `register_host_memory` does not work on a second process's mapping | Phase-0 test; fallback = engine as a parent-side thread (§6) |
| documented `sycl_ext_intel_matrix` extras are newer than the installed 2026.2 runtime (no `aspect::ext_intel_matrix`) | build-time capability probe; kernels written against plain `joint_matrix` / ESIMD `xmx::dpas` with the OpenCL `intel_sub_group_*` route as the reference; `b70-kernels.md` §4 grades the options |
| a resident engine wedges the card, or blocks a second B70 user | T2 off by default; sized by measurement; child dies on device-lost so the parent's watchdog turns it into an exception instead of a hang |
| `.wait()`/event latency creeping back into the hot path (it is 24 µs and silent) | the harness asserts a *per-job host-time* budget and the code review rule: no `wait()` outside setup/teardown (`LESSONS` 1) |
| int8-dot or funnel-shift mis-compilation quietly corrupts weights | the format test vectors from `doc/b70` (K=4 table) run as a device unit test at every commit, plus the `EXL3_MOE_B70_VERIFY` differential against the CPU tier |
| fp32-vs-int32 accumulation temptation changes the numeric class | Gate B′ pins the class; any deviation (e.g. bf16 DPAS) needs a new level-B measurement, not a relaxed threshold |
| the link is not really 14.4 GB/s on another boot (sysfs says Gen1 ×1 **[M]**, measured 14.4) | never hard-code: `probe_bandwidth` at startup drives `SLOT_ROWS`, `ROW_FRACTION` and `stream_t(S_c)`, and the report states the measured rate with every number |
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
   (`probe_crossproc.py`, 11/11, `out_crossproc.txt`). Closed 2026-10-28; §6 keeps the child-process
   design. The residual risk is that this is driver-version-specific, so the test belongs in the
   per-commit set rather than in the archive.
2. **Does `dot_4x8packed_us_int` / `sycl::ext::oneapi::dot_acc` compile to one Xe2 instruction?**
   Seven ops per weight instead of one pushes decode past the ALU budget (§1 of
   `b70-kernels.md`) and the answer becomes "decode on the B70 is XMX-only", which changes the tier
   boundary at 4–16 rows.
3. **How much of the 608 GB/s does the decode GEMV actually reach** with native tile order, with
   banding, and with evict-first cache controls? Below ~250 GB/s the decode job stops being hidden
   behind the parent's window and the *placement* (how many experts go to the B70 at all) becomes a
   throughput decision instead of a capacity one.
4. **Is a resident engine survivable in production** (device-loss semantics, a second B70 client,
   `power1_cap` behaviour while spinning)? Measured: 3.2 µs round trip and a 21–371 µs drain, so it
   is worth ~2–5 µs/layer and nothing more.
5. **DPAS route R1 (fp16 B) vs R2 (u8 product bytes)** — depends on whether the card is ALU- or
   XMX-bound at the model's actual rows/expert, and on the undocumented byte order inside a DPAS
   operand (confirm with the vectors first).
6. **Where the input transform belongs** (3090 in the issue kernel vs B70): the payload argument is
   only real if E5 shows the link as the prefill bottleneck; B′5 has to pass either way.
7. **What serves `S_c` best on a machine with a B70 at all** — the CPU GEMV at ~45 GB/s, streaming
   the expert to the 3090 at 14.4 GB/s, or streaming it to the B70 (two crossings, then 608 GB/s)?
   Recalibrate `stream_t` for all three rather than inheriting the CPU value.
