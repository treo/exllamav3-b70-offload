# MoE CPU offload: the data paths

Scope: every path a token's activations and an expert's weights take when routed experts run on
the CPU, for both offload modes, plus the CUDA-side work each path performs. Companion documents:
`tuning-knobs.md` (what each knob changes about these shapes), `timing.md` (measured cost of each
hop), `mul1-trellis.md` (the weight format the CPU kernels read).

Everything below is anchored in the tree at HEAD (`cdc785db`, v1.6.5). File:line references are
given so each claim can be checked. Machine-readable geometry is reproduced by
`python notes/geom.py` (kept in the branch history).

---

## 0. Participants

| Piece | Where | Role |
|---|---|---|
| Forward thread (parent) | `exllamav3/modules/block_sparse_mlp.py::BlockSparseMLP.forward` | routing, tier selection, enqueues all GPU work |
| Split/offload mixin (parent) | `exllamav3/modules/block_sparse_mlp_cpu.py` | decides *which* path per layer per step, hands tensors to the host |
| Handoff host (parent) | `exllamav3/model/moe_cpu_host.py::MoeCpuHost` | owns the pinned shared-memory region, job rings, slot views, VRAM rings, copy streams |
| CUDA handoff kernels | `exllamav3/exllamav3_ext/routing.cu` (`moe_split_issue_kernel`, `moe_split_collect_add_kernel`, `moe_split_map_kernel`), `exllamav3/exllamav3_ext/cpu/moe_handoff.cu` (flag ops, fused issue/collect, worker loop) | publish/consume flags, move bytes between VRAM and pinned slots |
| Worker process (child) | `moe_cpu_host.py::_moe_cpu_child_main` + `cpu/moe_handoff.cu::exl3_moe_cpu_worker_run` | owns expert weights in a huge-page arena, computes GEMVs, stages weights for GPU streaming |
| CPU expert GEMM | `exllamav3/exllamav3_ext/cpu/moe_mul1.cpp` | mul1 trellis dequant fused into int8 dot products |
| GPU expert paths | `exllamav3/exllamav3_ext/quant/exl3_moe*.cu`, `reconstruct.cu`, `moe_unswizzle.cu`, `hgemm*.cu`, `libtorch/blocksparse_mlp.cpp` (`bc`, bsz ≤ 8 fused decode) | everything the GPU still computes |

Two independent module-level switches choose a path (they are not env knobs):

* `BlockSparseMLP.cpu_offload` — whole layer's routed experts live on the CPU (`-mcl`).
* `BlockSparseMLP.cpu_split_first` — a tail slice `[first, E)` of every eligible layer's experts
  lives on the CPU (`-mcs`); `cpu_split_first` is also the base of the worker's expert numbering.

They are mutually exclusive (`cpu_maybe_offload_load` / `cpu_maybe_split_load` assert it), so
exactly one is set per module.

Within a path the choice is by row count `bsz = y.shape[0]`:

```
                          bsz < stream_min_rows (32)          bsz >= 32
                          ─────────────────────────           ──────────────────────────
split (-mcs)              P1 fused decode handoff             P2 prefill (memcpy jobs), or
                                                            P3 streamed prefill when experts are hot
whole layer (-mcl)        P1' copy-path issue/collect         P2 / P3 (same functions)
```

`bsz < 32` also covers speculative-verify batches (`TEMP_ROWS_GRAPH = 32` is the same number by
construction). The child never knows which mode produced a job: both feed the same job ring.

---

## 1. Shared memory: what all paths have in common

One `multiprocessing.shared_memory.SharedMemory` region per worker (per model component: main /
draft / MTP), page-locked in the parent with `cudaHostRegister(..., PORTABLE | MAPPED)`
(`moe_cpu_host.py:1050` `_register_handoff`), so the GPU can read/write it directly under UVA.
`gpu_base_ptr` (`cuda_host_get_device_pointer`) is the device-visible alias; all kernel-facing
addresses are computed from it.

```
offset 0        ctrl block:  quit | pass_wake | abort | ready | jobs_tail | jobs_head   (64 B apart)
offset 384      MoeJob jobs[256]            (1056 B each: 7 u32 header + experts[256] + seq_hi)
offset 270720   flags: data_ready[8] | done[8] | consumed[8] | stage_done[8] | pinned_free[8]   (64 B stride)
offset 273280   stage ring tail/head
offset 273408   MoeJob stage_jobs[64]
offset 340992   compute slot data, num_slots x slot_size            <- MOE_CTRL_SIZE
        +n*slot  weight-staging slots, num_wslots x wslot_size       <- wstage_off (sent in "start")
```

Flag width: 32-bit on CUDA (compared cyclically by `cuStreamWaitValue32`), 64-bit on HIP (its wait
is a plain unsigned `>=`, so 32-bit flags would satisfy early after wrap). Both cases own a 64-byte
cache line; the descriptor carries the sequence as two 32-bit halves.
Constants: `MOE_JOB_RING 256`, `MOE_MAX_SLOTS 8`, `MOE_MAX_WSLOTS 8`, `MOE_STAGE_RING 64`,
`MOE_JOB_MAX_EXPERTS 256` (`cpu/moe_handoff.h:54-60`).

Slot geometry comes from the registered layers, not from the model (`ensure_started`,
`moe_cpu_host.py:1187`):

```
max_hi   = max(spec.hi)      # k of gate/up  = the hidden width the experts were quantized at
max_ho   = max(spec.ho)      # n of down     = the width of the routed sum
max_topk = max(spec.topk)
off_x   = 0
off_sel = align64(cap_rows * max_hi * 2)          # fp16 x    [cap_rows, max_hi]
off_w   = align64(off_sel + cap_rows * max_topk * 4)   # i32 sel [cap_rows, max_topk]
off_out = align64(off_w + cap_rows * max_topk * 2)     # fp16 w  [cap_rows, max_topk]
slot_size = align64(off_out + cap_rows * max_ho * 4)   # fp32 out[cap_rows, max_ho]
```

All `hi`, `ho`, `topk` must be equal across registered layers (assert at `moe_cpu_host.py:1200`),
otherwise the D2H/H2D copies would be strided — torch implements those with a host-side staging
pass performed *at enqueue time*, outside stream order, which would ship the slot's previous
contents.

Concrete numbers (Qwen3.8-Flash-Next, `H = 2560`, `topk = 10`, defaults `num_slots = 4`,
`cap_rows = 64`): `x` 320 KiB, `sel` 2.5 KiB, `w` 1.25 KiB, `out` 640 KiB, `slot_size` 963.8 KiB,
4 slots = 3.76 MiB; plus 2 × 32 MiB weight-staging slots. Control region 333 KiB.

Job kinds (`MOE_JOB_KIND_{COMPUTE,STAGE,COMPUTE_GATED}`, `cpu/moe_handoff.h:56-70`): a
`COMPUTE_GATED` job's payload may be entirely `-1` (no CPU-resident expert selected), and then both
the worker's compute and the collect's readback are skipped — the common case once the split tail
is genuinely cold.

---

## 2. P1 — fused decode handoff (split mode, `bsz < 32`)

Entered at `block_sparse_mlp.py:1138` (`cpu_split_submit`) with
`y (bsz, H) fp16`, `selected_experts (bsz, topk) int64` **holding raw router ids**, `routing_weights
(bsz, topk) fp16`. Requirements: `bsz <= cap_rows` and both `y` and `routing_weights` contiguous,
else the function returns `None` and the caller falls back to P1' (copy path).

One Python call per half, each doing host + GPU work in one extension entry point:

**Issue** — `MoeCpuHost.submit_issue_fused` (`moe_cpu_host.py:1411`) →
`ext.exl3_moe_split_issue_fused` (`cpu/moe_handoff.cu:245`):

1. Host: refuse if the job ring is within 4 of full (caller throttles on `jobs_head` and retries);
   write the descriptor into `jobs[tail % 256]` (`kind = COMPUTE_GATED`, `slot`, `rows`, `topk`,
   `seq` halves), then release-store `jobs_tail`.
2. Stream: if the slot has a previous tenant, `cuStreamWaitValue32(consumed[slot] >= prev_seq)`.
3. Stream: `moe_split_issue_kernel<<<1, 1024>>>` (`routing.cu:1165`) — a **single block** — which
   * translates router id → physical slot in place (`map` mode; also bumps the hit histogram with
     `atomicAdd`), and writes the worker-space id (`p - first_cpu`, or `-1`) straight into the
     pinned slot's `sel` with zero-copy stores;
   * writes `dev_count[slot] = 0/1` (whether any pick was CPU-resident);
   * if none: `__threadfence_system()` and return — **no activation traffic at all**;
   * else copies `w` (`rows*topk` halves) and `x` (`rows × hi` halves, zero-padded from `h_` if the
     module's hidden width differs from the quantized width) as `int4` stores.
4. Stream: `cuStreamWriteValue32(data_ready[slot] = seq)`.

Data volume for a decode step, per offloaded layer: `sel` `topk×4 B`, `w` `topk×2 B`, and either 0
or `x = hi×2 B` per row. On Qwen3.8 at bsz 1: 40 B + 20 B + 5 120 B (or nothing).

**Between issue and collect** the caller enqueues its own GPU expert work (so it overlaps the CPU):
`bc.run_bszN` for the GPU-resident experts (bsz ≤ `MAX_BSZN = 8` fused decode kernel), and the
shared expert(s) (`block_sparse_mlp.py:1436`, only for `bsz <= MAX_BSZN`).

**Collect** — `MoeCpuHost.submit_collect_fused` → `ext.exl3_moe_split_collect_fused`
(`cpu/moe_handoff.cu:295`):

1. Stream: `cuStreamWaitValue32(done[slot] >= seq)`.
2. Stream: `moe_split_collect_add_kernel` (`routing.cu:1298`), grid = `ceil(rows*h_/1024)` blocks:
   reads `dev_count[slot]`; if 0 it exits (no PCIe reads); else
   `final_out[row, c] += *(volatile float *)(h_out + row*ho + c)` — the fp32 partial is folded
   **directly out of pinned memory**, no H2D copy, and the add is in place into the routed sum.
3. Stream: `cuStreamWriteValue32(consumed[slot] = seq)` — published *after* the readback on the
   same stream, because the slot's next tenant may issue from a different device.

**Worker side** (`cpu/moe_handoff.cu:351` loop): spins on `jobs_tail` (hard spin 65536 `pause`
iterations, then 50 µs naps; `pass_wake` — bumped by `MoeCpuHost.begin_pass` at the top of every
forward — resets the backoff and primes the thread pool), pops the job, spins on `data_ready[slot]`,
scans `sel` for any ≥ 0 (full count only when handoff profiling is on), runs
`exl3_moe_cpu_forward_raw` (§5), release-stores the job's seq into `done[slot]`.

---

## 3. P1' — copy-path issue/collect (whole-layer offload at decode, and the fused path's fallback)

`_issue_compute` (`moe_cpu_host.py:1469`) is the general, un-fused form. Per `cap_rows`-row chunk
of the batch:

1. `sel32 = selected_experts.to(torch.int32)` (GPU cast, whole tensor once).
2. `y_pad = F.pad(y, (0, hi - h_))` if the widths differ (GPU), plus an `rtmp` readback buffer when
   `ho != h_`.
3. Host writes the descriptor (`kind = COMPUTE`, i.e. **not** gated: the collect always reads the
   slot back) and bumps `jobs_tail`; throttles against ring overflow with a 200 µs host poll loop.
4. Stream: `wait consumed[slot] >= last_seq`, then three contiguous `copy_(!non_blocking)` D2H:
   `slot.x[:n] ← y_pad[a:b]` (`n×hi×2 B`), `slot.sel[:n] ← sel32[a:b]` (`n×topk×4 B`),
   `slot.w[:n] ← routing_weights[a:b]` (`n×topk×2 B`); then `data_ready = seq`.
5. Deferred (`submit_collect` → `_collect_one`): `wait done >= seq`; H2D
   `slot.out[:n] → out[a:b]` (`n×ho×4 B`, or via `rtmp` then a GPU slice-copy when `ho != h_`);
   `consumed = seq`.

Whole-layer offload uses this for both halves: `cpu_offload_issue`
(`block_sparse_mlp_cpu.py:610`) issues before the shared expert runs and `cpu_split_combine`
collects afterwards, so the shared expert's kernels cover part of the CPU's latency. Since
`kind = COMPUTE` the slot is always read back and, with `cpu_partial` as the *only* contribution,
`cpu_split_combine` replaces `final_hidden_states` rather than adding to it.

Multi-chunk behaviour: the issue loop keeps at most `num_slots` jobs in flight and inline-collects
the oldest one before reusing its slot. Without that window the deferred collect's `consumed` write
would sit behind the same stream's `consumed` wait (deadlock; the "second-prompt freeze").

---

## 4. P2/P3 — prefill

`submit_prefill` (`moe_cpu_host.py:1864`) is entered when `bsz >= stream_min_rows` (32). It first
counts assignments per expert **on the GPU, then reads them to the host once**:

```
shifted = flat + 1                          # -1 sentinels (GPU-resident picks) land in bin 0
counts1 = zeros(E+1); counts1.scatter_add_(0, shifted, ones)
counts_h = counts1.tolist()[1:]             # <- the only host sync before the tail compression
streamed = [e for e in range(E) if counts_h[e] >= stream_t]
```

* Nothing streamed, or the layer cannot stream (`rows < 32`, no `expert_bytes`, expert block larger
  than a weight-staging slot, or no aux tensors) → **P2**: plain `_issue_compute` + `_collect_compute`
  over the whole batch (`submit`), i.e. `ceil(rows/cap_rows)` jobs of §3, up to `num_slots` deep.
  Data volume scales linearly: `rows × hi × 2 B` down, `rows × ho × 4 B` back up.
* Something streamed → **P3** (`_submit_prefill_streamed`, `moe_cpu_host.py:1976`).

P3 shapes the work as follows (still one call, no further syncs — everything after `tolist()` is
host-known):

1. `order = argsort(flat)`, `token_sorted = order // topk`, `weight_sorted`; prefix offsets `offs[]`
   built from the host counts, so every expert's token segment is a slice.
2. **CPU tail**: mask streamed assignments to `-1`, compress to the rows that still carry work
   (`tidx`), then `_issue_compute` on the compressed rows — *issue only*. So the tail's D2H volume is
   `n_tail × hi × 2 B` with `n_tail ≤ rows`, typically much less.
3. Per staged batch of `per_slot = min(wslot_size // expert_bytes, batch_experts, 256)` experts, on
   a **separate copy stream** with a `num_wslots`-deep ring:
   * *pinned arena* (`EXL3_MOE_PINNED_ARENA=1`): the parent DMAs each expert's contiguous
     `[gate|up|down]` block straight out of the worker's arena mapping
     (`arena_views[chunk][off:]` → `vram_slots[ws]`), `exp_b` bytes each. No worker involvement.
   * *staged*: a `STAGE` job in the second ring; the worker's dedicated stager thread waits
     `pinned_free[ws] >= prev_seq`, `memcpy`s the same expert-major packed layout
     (`stage_phase`, `moe_mul1.cpp:3570`) into the pinned weight slot, and sets `stage_done[ws]`.
     The copy stream waits that flag, then `vram_slots[ws] ← wviews[ws][:used]` (`used = len(batch)
     × exp_b`), and publishes `pinned_free[ws]`.
4. If the CPU tier stores the weights packed (see `mul1-trellis.md` §4), `restore = True` and the
   copy stream runs `moe_unswizzle_trellis` per projection over the whole batch
   (`moe_unswizzle.cu`, grid `(tiles_k × tiles_n/8, num_experts)`, 128 threads), producing native
   order in a **second** VRAM ring (`native_slots`, allocated only for layers whose experts arrive
   packed). The GPU kernels never see packed bytes.
5. `wready_ev[ws]` recorded; compute stream waits it; the batch is computed by one of three tiers
   (§4.1). `wconsumed_ev[ws]` recorded on the compute stream, gating the next writer of that slot.
6. Tail jobs are collected last (`_collect_compute`), then `out.index_add_(0, tidx, out_t)`.

### 4.1 The three streamed compute tiers

Per expert, by assigned count `c` (all thresholds in tokens/rows, not bytes):

| tier | condition | what runs | data |
|---|---|---|---|
| fused | `c <= stream_fused_t` (256) and layer eligible (`hi == ho == h`, no biases, silu/gelu/relu2) | `ext.exl3_moe` over the batch's cool experts, one launch per row-tile tier (16/32/64 rows, `mtile`) | pointer tables (9 lists × batch) built **on the host** from `vslot.data_ptr() + bi*exp_b`, uploaded once; temp buffers `(C, stream_fused_t, H/I)` fp16 |
| batched reconstruct | `stream_fused_t < c <= recon.max_rows` | `moe_batch_recon.run_group`: one pointer-table reconstruct + one strided-batched `hgemm` + one Hadamard per projection per group of ≤ `EXL3_MOE_RECON_BATCH` experts, rows padded to the group's largest expert | dequant scratch `w_scratch` (`k*n` fp16), padded slab |
| per-expert reconstruct | everything above, or when the batched tier is unavailable (biases, `EXL3_MOE_STREAM_BATCH_RECON=0`) | `_dq_linear` × 3: `had_r_128` → `reconstruct` → `hgemm` → `had_r_128` (+bias), `_act`, then `out.index_add_` | gathered `xg = y.index_select(0, idx)`, `w_scratch` fp16 (k,n) |

Tier 1 keeps the weights packed-in-VRAM→restored, and reads them as native trellis tiles; tiers 2/3
dequantize to fp16 weights (`k × n`) first, so their traffic scales with `k·n`, not with rows.

Eligibility of the whole streamed path additionally requires `spec["expert_bytes"] <= wslot_size`
(one expert must fit a slot) and that the layer's `suh`/`svh` (and optional biases) were fetched to
the GPU at load (`aux`, `block_sparse_mlp_cpu.py:746`).

---

## 5. Inside the worker: one compute job

`exl3_moe_cpu_forward_raw` (`moe_mul1.cpp:3801`), given `sel[rows×topk]` (worker-local, `-1` = skip)
and the row-major fp16 `x`:

1. Zero `out` (`rows × H` fp32).
2. Bucket `(token, weight)` by expert; split each bucket into chunks of `MAX_M = 4` rows.
   `nc = Σ_e ceil(|e| / 4)` chunks; a decode job with `topk = 10` distinct experts is `nc = 10`.
3. Workspace per chunk: `tin` (fp32 `MAX_SLOTS × k`), `splat32`/`splat_dup` (int32 `MAX_SLOTS × k`),
   `splat_pair` (int32 `MAX_SLOTS × k/2`), `tout_g/u` (`MAX_SLOTS × I`), `tout_d` (`MAX_SLOTS × H`)
   with `MAX_SLOTS = 2 × MAX_M = 8` — a "wide" row costs two GEMV rows (§6).
4. SIMD tiers run **two dispatches** over a work-stealing cursor array (`decode_phase`); the scalar
   tier runs the five/six-phase schedule (`forward_phase`). Dispatch 0 = gate+up, dispatch 1 = down;
   the transforms, activation, and the weighted accumulate run inline on whichever worker finishes
   a 128-column block last, which is why there are no phase barriers in the SIMD path.
5. Unit of work = one 8-tile (128-column) band per chunk (× 2 for gate+up), optionally split P ∈
   {1,2,4} ways along k (split-K; only on the VBMI tier, `split_k_ok`).
6. GEMV kernel: streams the expert's packed trellis k-major over a band of output tiles held in
   registers; dequant folds into integer dot products because the mul1 codebook is affine in a
   byte-sum (`mul1-trellis.md` §3).
7. Output transforms: per 128-column block, inverse Hadamard + `svh` (+ bias), then
   `out[token][c] += weight * value`.

The down projection's int8 quantization is per whole row, so `prepare_rows` for `down` must wait
for the full activated row — that coupling fixes the phase order, not performance.

---

## 6. Activation quantization on the CPU side (shape effect: 1 row ↔ 2 GEMV rows)

`EXL3_MOE_CPU_WIDE=1` (default). A row whose largest element is `amax` is scaled to ±127; if more
than 1/`WIDE_ZERO_DIV` (16) of its activations would round to zero, the row is carried as two int8
rows representing a 15-bit value (`quantize_row_wide_avx2`, step `amax/16256`, high part in steps of
128 plus remainder), and its two GEMV results are added by `fold_rows`. Consequences for the port:
a chunk of 4 tokens occupies up to 8 GEMV rows (`MAX_SLOTS`), i.e. doubling the GEMV count and the
trellis traffic for those experts; the `splat*` buffers are sized for 8 rows. With `EXL3_MOE_CPU_WIDE=0`
a chunk is always ≤ 4 rows.

---

## 7. Weight movement summary

| # | hop | mechanism | bytes |
|---|---|---|---|
| W1 | checkpoint → worker arena | safetensors deferred load → `_HugeArena.rehome` (with the packed-layout repack) | all offloaded experts, once, at load |
| W2 | arena → pinned weight slot | stager thread `memcpy` (`stage_phase`) | `exp_b` per streamed expert |
| W3 | pinned weight slot → VRAM ring | contiguous H2D on the copy stream | `len(batch) × exp_b` |
| W2' | arena → VRAM ring (pinned arena) | direct DMA from the parent's registered mapping, per expert | same |
| W4 | VRAM packed ring → VRAM native ring | `moe_unswizzle_trellis` (read+write) | `len(batch) × exp_b` |
| W5 | GPU slot tensors ← arena (promote-on-miss) | `promote_expert`/`demote_expert` on a side stream, repacked with the same strided copies as W1 | `exp_b` per moved expert |
| A1 | `y` VRAM → pinned `x` | kernel store (P1) or `copy_` (P2/P3) | `rows × hi × 2` |
| A2 | worker `out` pinned → VRAM | add-in-place kernel (P1) or `copy_` (P2/P3) | `rows × ho × 4` |
| A3 | `sel`/`w` | same mechanisms | `rows × topk × (4+2)` |

Note that P1 never materialises a GPU copy of the output tensor beyond the in-place add, and never
moves `x` when the job is empty; P2/P3 always move the full payload.

---

## 8. Path selection, in code

```
BlockSparseMLP.forward
├─ routing (router GEMV / routing_std...: routing.cu kernels)         -> sel (bsz,topk) int64, w fp16
├─ if cpu_split_first and not autosplit_measure:
│    └─ cpu_split_submit
│         ├─ _split_swap_tick / promote step (dynamic placement)
│         ├─ bsz <  stream_min_rows -> submit_issue_fused  [P1]  (fallback submit_issue [P1'])
│         └─ bsz >= stream_min_rows -> _split_translate + submit_prefill [P2/P3]
├─ GPU routed experts for the non-CPU slice:
│    ├─ bsz <= MAX_BSZN  -> bc.run_bszN (fused decode, out_bszn)
│    └─ else             -> fused exl3_moe / batched reconstruct / per-expert tiers
├─ shared experts (may be scheduled between issue and collect)
└─ cpu_split_combine -> collect_fused [P1] / submit_collect [P1'] / add cpu_partial [P2,P3]
```

`autosplit_measure` forwards skip the CPU work entirely (they only observe VRAM allocations), but
still request the streamed path's persistent buffers via `prefill_worst_case_parts` so the autosplit
planner budgets them.