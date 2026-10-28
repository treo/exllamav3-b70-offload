# MoE CPU offload: tuning knobs, and what each one does to the data

Three families matter:

* **A. Structural knobs** change the *shape* of the shared-memory region and of every payload in
  flight (`SLOTS`, `SLOT_ROWS`, `WSLOT_MB`, `BATCH_EXPERTS`, …). A port has to reproduce these
  shapes exactly on both sides of the boundary.
* **B. Policy knobs** change *which* path a given layer/step/expert takes, without changing any
  shape (`STREAM_T`, `MIN_ROWS`, `STREAM_FUSED_T`, placement knobs).
* **C. Implementation knobs** change only *how* a hop is executed (`MEMOPS`, `PIN`, `SPREAD`,
  `MAX_ISA`, `SWIZZLE`, `STAGE_THREADS`).

Sources: `MoeCpuTuning` (`exllamav3/model/moe_cpu_host.py:84-177`, the single place env vars are
read), `BlockSparseMLP_CPU` (`exllamav3/modules/block_sparse_mlp_cpu.py`),
`exllamav3/exllamav3_ext/cpu/moe_handoff.h`, `exllamav3/util/backend.py:49-51`, and
`doc/env_vars.md` (362-822). Measured effects are from `measured-costs.md` §5, §7, §8.

Anything in `MoeCpuTuning` can also be set without env vars by mutating the module-level `TUNING`
singleton before constructing the model — that is the intended way to sweep in one process.

---

## 1. Mode selection (these decide the set of paths that exist at all)

| knob | effect |
|---|---|
| `-mcl N` / `EXL3_MOE_CPU_OFFLOAD` | first N eligible MoE layers route **all** their experts to the worker. `cpu_offload=True`: routing output is the worker's sum, no expert-range masking. Decode uses P1' (copy path, `kind=COMPUTE`, unconditional readback); prefill uses P2/P3. |
| `-mcs K` / `EXL3_MOE_CPU_SPLIT` | every eligible layer keeps experts `[0, E-K)` on the GPU and `[E-K, E)` in the worker. Shrinks the module (`num_local_experts`, `routing_first/last`), so the GPU-side fused/reconstruct tiers see a smaller expert range and out-of-range picks are masked in-kernel. Decode uses P1 (`kind=COMPUTE_GATED`). Capped at `E-1` with a notice. |
| `EXL3_MOE_CPU_SPLIT_LAYERS` | limit the split to the first N layers (default 0 = all eligible). |
| `-mcpa` / `EXL3_MOE_PINNED_ARENA` | worker arena = shared memfd/section mapped **and page-locked by the parent**, each expert laid out as one contiguous `gate, up, down` block. Two consequences: streamed prefill DMAs from the arena on the copy stream (no stage job, no stager memcpy: +32% prefill measured) and promote-on-miss becomes possible. Costs ~0.2 s/GiB of registration at load and double-counted RSS. |
| `EXL3_MOE_ARENA_HUGE` (`2m` or `1g`) | back the arena chunks with hugetlbfs pages instead of shmem (needs `vm.nr_hugepages` reservations). |
| `EXL3_MOE_ARENA_HUGEPAGE` | THP promotion: post-load `MADV_COLLAPSE` pass on Linux (background thread), `MEM_LARGE_PAGES` per chunk on Windows. Affects CPU-side GEMV page-walk cost only, not any shape. |
| `EXL3_MOE_CPU_LOAD_BATCH` (32) | experts the worker reads per deferred load pass; bounds transient host memory above the arena to a slice of a layer. **No effect on arena layout or contents.** |
| `EXL3_HOST_MEM_RESERVE_MB` | guard applied before arena chunks (and the n-gram table). |
| `EXL3_MOE_CPU_START_TIMEOUT` | how long the parent waits for the worker's `ready` flag after the last layer is handed over. |

Eligibility for both modes (checked on header metadata only, `cpu_maybe_*_load`): CUDA device,
layer-split mode (no TP), mul1 codebook, tile width ⇒ `K ∈ 1..8` or `1.5/2.5/3.5`, activation
silu/gelu/swiglu_oai (gated) or relu2 (gateless), and biases either all-or-none per projection.
`MoeCpuHost.ensure_started` additionally requires **uniform `hi`, `ho` and `topk` across all
registered layers** (assert), because the slot sections must stay contiguous 2-D blocks.

## 2. The compute handoff region (shape family A)

| knob | default | what it changes |
|---|---|---|
| `EXL3_MOE_CPU_SLOTS` | 4 (max 8 = `MOE_MAX_SLOTS`) | number of compute slots ⇒ job-ring depth in flight ⇒ how many `cap_rows` chunks the parent can have issued+un-collected at once. The multi-chunk issue loop inline-collects the oldest job once `len(jobs) == num_slots`, so slots directly set the D2H/H2D pipelining depth; at 1 the prefill path degenerates to lockstep. Pinned cost `slots × slot_size`. |
| `EXL3_MOE_CPU_SLOT_ROWS` (`cap_rows`) | 64 | rows per job ⇒ `x` = `cap_rows × hi × 2 B`, `out` = `cap_rows × ho × 4 B`, `sel`/`w` = `cap_rows × topk × (4,2) B`; a prefill of `rows` becomes `ceil(rows/cap_rows)` jobs. **Also a functional gate:** the fused decode path (P1) refuses jobs with `rows > cap_rows` and silently falls back to the copy path, so `cap_rows < 32` forfeits the fused path for speculative-verify batches (`TEMP_ROWS_GRAPH = 32`). Measured: 32 gives 105 tok/s vs 93 at 64 (smaller chunks pipeline better against the GPU); 128 + 8 slots gives 97. |
| `EXL3_MOE_CPU_THREADS`, `-mct` | phys cores − `HOST_CORES` | pool size for the GEMV phases. Bandwidth-bound past ~8 here (45 GB/s wall at 8-16 threads); `-mct 8` measured 98 tok/s vs 93 at 15, i.e. free. |
| `EXL3_MOE_HOST_CORES` | 1 | cores withheld from the pool; the parent is then *confined* to them. The one host core matters because the parent's forward thread and CUDA driver threads otherwise preempt a pinned worker at its per-dispatch barriers (docs: 11-32 vs 30-36 tok/s on a 12-core box). |
| `EXL3_MOE_CPU_PIN` / `EXL3_MOE_CPU_SPREAD` | 1 / 0 | pin one worker thread per physical core (SMT siblings last) / order cores round-robin across L3 domains first. Pure scheduling. |
| `EXL3_MOE_MEMOPS` | 1 | stream memory operations vs the spin-wait kernels for every flag write/wait. Measured: 1.8 µs vs 2.9 µs host enqueue, 6.4 vs 10.7 µs round trip, and decode 91.7 vs 93.2 tok/s (noise). The kernel path is the only one with a 30 s timeout; with memops, worker death is caught by the host watchdog, which unblocks pending waits by writing satisfying values into the flags. |
| `EXL3_MOE_SPLIT_FUSED` | 1 | **path switch**: `0` makes `cpu_split_submit` skip the fused decode handoff entirely and take the P1' copy path (three `cudaMemcpyAsync`, an `int32` cast and a pad per layer per step). Exists for A/B testing; costs ~6 µs/layer at decode (§4). |
| `EXL3_MOE_POOL_PRIME` | on | worker primes (wakes) the pool at `pass_wake` and before its GPU payload arrives, so the pool is spinning when the job lands. Off ⇒ first dispatch pays futex wake-up. |
| `EXL3_MOE_CPU_SMALL_WORKERS` | 0 (off) | caps participants for jobs with ≤ 2 chunks (`Pool::run(n_run)`), trading per-barrier stragglers against bandwidth. |
| `EXL3_MOE_CPU_MAX_ISA` | auto | caps the CPU kernel tier (`scalar/avx2/bw/vnni/vbmi`). Changes **the packed layout rule** too (capping below `bw` disables band-8 and, on `avx2`, switches to band-2+planar for integer rates), so parent, child and GPU restore must agree — they all query `exl3_moe_cpu_swizzle_group`. Read once per process, parent and child independently: it must be set before either starts. |
| `EXL3_MOE_CPU_WIDE` | 1 | a row whose small elements would all round to zero is carried as two int8 rows ⇒ that chunk uses 2 GEMV rows per token, doubling GEMV work and requiring `MAX_SLOTS = 8`-row scratch. Measured decode 96.1 vs 93.2 tok/s off/on (noise either way on this model, i.e. wide rows are rare here); the microbenchmark difference is proportional to how often rows go wide. |
| `EXL3_MOE_CPU_SWIZZLE` | 1 | pack (band/planar) the arena copies. Changes (a) CPU GEMV throughput, (b) whether the streamed path must run `moe_unswizzle_trellis` and allocate the second VRAM ring (`native_slots`). On this AVX2 host: K=3 decode 89.3 vs 93.2 tok/s unpacked/packed; half-integer rates unaffected (they are native on this tier anyway). |

## 3. The streamed prefill path (policy family B, shape family A)

Entered only when `rows ≥ EXL3_MOE_STREAM_MIN_ROWS` and the layer registered `aux` tensors and
`expert_bytes ≤ wslot_size`.

| knob | default | effect |
|---|---|---|
| `EXL3_MOE_STREAM_MIN_ROWS` | 32 | the **path selector** (`bsz < min_rows` ⇒ P1/P1'). Raising it above your chunk size disables streaming entirely: measured prefill 818 vs 1661 tok/s at 2048 rows. |
| `EXL3_MOE_STREAM_T` | 8, scaled per device to `max(8, 8·√(25/bw_GB/s))` | per-expert assignment count above which the expert's weights are streamed instead of computed on the CPU. This is the single biggest prefill lever (measured 2.1× between on and off). *Doc/code mismatch:* `doc/env_vars.md:411` documents the base as `16`; the code constant is `8` (`moe_cpu_host.py:139`, `TUNING.stream_t`) and the calibration comment says 8 was best on Gen5 links — the log line `pinned->device 13.4 GB/s, stream_t 11` is `8·√(25/13.4)`, confirming 8. |
| `EXL3_MOE_CPU_WSLOTS` | 2 (max 8) | depth of the weight-staging ring (pinned and VRAM) ⇒ how many expert batches can be in flight on the copy stream while the compute stream works the previous ones. 1 makes streaming lockstep with the DMA. |
| `EXL3_MOE_CPU_WSLOT_MB` | 32 | per-slot bytes. Two hard consequences: an expert must fit alone (`expert_bytes ≤ wslot_size`, else the layer never streams), and `per_slot = min(wslot_size // expert_bytes, STREAM_BATCH_EXPERTS, 256)` caps the batch size. Sized for the *largest* layer, so small experts waste slot space (Qwen3.5's 1.125 MiB experts: 28 fit a 32 MiB slot, but the default batch is 24, so ~14% of the ring is unused). |
| `EXL3_MOE_STREAM_BATCH_EXPERTS` | 24, hard max 256 | experts per stage job / DMA / fused launch. Ceiling is `MOE_JOB_MAX_EXPERTS` (the descriptor's `experts[]` array). Bigger batches amortize the ~175 µs fixed cost per stage job and the per-launch overhead, at the price of latency (a batch is the scheduling unit) and of the VRAM ring. Measured neutral (+/- noise) at 24→48 with `WSLOT_MB=96`. |
| `EXL3_MOE_CPU_STAGE_THREADS` | 4 | scratch threads the stager uses for the arena→pinned `memcpy`. Measured **no effect** 1..8 on this host (16.3 GB/s either way) because a single thread already saturates; the code also spawns fresh `std::thread`s per job, so the fixed cost is not thread-count dependent. Docs say it matters for many small experts on a fast link. |
| `EXL3_MOE_STREAM_FUSED_T` | 256 | per-expert row ceiling for the fused `exl3_moe` tier; above it the batched-reconstruct tier, above `recon.max_rows` the per-expert loop. Sets the streamed tier's temp buffers: `concurrency × T × (2·hidden + 2·interm) × 2 B` per device (halved when 512→256). Between 256 and 64 the tier choice moved prefill by ≤5% (§8), so treat it as a VRAM/planning knob rather than a throughput one — unless routing is very skewed. |
| `EXL3_MOE_STREAM_BATCH_RECON` | 1 | batched-reconstruct tier on/off for streamed experts (off ⇒ per-expert reconstruct loop). Measured neutral: with `STREAM_FUSED_T=64` forcing most experts off the fused tier, batched vs per-expert was 1752 vs 1740 tok/s prefill (§8). |
| `EXL3_MOE_MTILE` | 1 | fused-kernel row-tile tiers 16/32/64 (three launches, largest first) — same rule on both the GPU-resident and streamed tiers (`mtile` in `MoeCpuTuning`, used in `_submit_prefill_streamed`). |
| `EXL3_MOE_FUSED_ROWS` (128) / `EXL3_MOE_FUSED_ROWS_WIDE` (256) / `EXL3_MOE_TILE_N` | | the GPU-resident tier's row capacity and tile shape; `fused_rows` also gates whether `expert_count.tolist()` (a per-layer host sync) is needed at all — see §5. |
| `EXL3_MOE_BATCH_RECON` + `EXL3_MOE_RECON_TILES` / `EXL3_MOE_RECON_BATCH` / `EXL3_MOE_RECON_PAD` / `EXL3_MOE_RECON_ROWS` / `EXL3_MOE_RECON_MB` / `EXL3_MOE_RECON_MAX_ROWS` / `EXL3_MOE_RECON_FOLDED` | see `doc/env_vars.md:722-755` | the batched reconstruct tier for GPU-resident experts (`BATCH`: on/off; `TILES`: legacy tile-budget cap; `BATCH`: experts per group; `PAD`: padded-to-real row ratio per group; `ROWS`/`MB`: padded-row and dequant-scratch budgets; `MAX_ROWS`: explicit row cap; `FOLDED`: fold both Hadamards into the dequantized weights). The **same** `BatchReconLayer` object is reused by the streamed tier (`_stream_recon_layer`), so `RECON_MAX_ROWS`/`RECON_ROWS` also decide where a *streamed* expert leaves the batched tier for the per-expert loop, and `RECON_FOLDED` changes its numeric behaviour on both paths. |
| `EXL3_MOE_FUSED_DET` (and `EXL3_MOE_RECON_DET`, which follows it) | 1 | deterministic slot+gather accumulation: allocates `assignments × hidden` fp32 scratch per call (~320 MB per layer call at 4k tokens on Qwen3.8) and one `exl3_moe_gather` (measured 135 µs/layer at 2048 rows). Cost is VRAM, not time — but it *is* a large prefill-time allocation the autosplit planner must budget. `RECON_DET` only matters where the batched tier cannot write into the slot scratch (the streamed tier, or `FUSED_DET=0`). |

## 4. Placement (which experts are CPU-resident)

| knob | default | effect |
|---|---|---|
| `EXL3_MOE_CPU_SWAP=0` | dynamic on | static tail (no placement changes after load) vs periodic sweep every `EXL3_MOE_CPU_SWAP_INTERVAL` (128) decode steps, run from the generator's queue-drained hook; `SWAP_HYST` (2.0) and `SWAP_FLOOR` (8.0 × mean count) gate swaps; `SWAP_MAX` (64) caps swaps per sweep round. A swap re-reads the promoted expert **from the checkpoint** into the demoted expert's GPU slot in place (pointers stay valid) and quiesces the device (`torch.cuda.synchronize`) — i.e. it is a stop-the-world event, deferred to between generations. |
| `EXL3_MOE_CPU_PROMOTE` (4) + `-mcpa` | promote-on-miss | replaces the sweep: each decode step, experts the worker computed are DMA'd into spare GPU slots on a side stream (`_PROMOTE_BUDGET = 6` layers/step, `_PROMOTE_RATIO = 1.5`, `_PROMOTE_DECAY = 0.98`/step), and the least-used resident goes back into the freed worker slot. No checkpoint read, no quiesce. Measured cost at decode: 78 vs 93 tok/s (the transfers and per-step numpy bookkeeping land on the critical path). |
| `EXL3_MOE_CPU_SPLIT_STATS`, `~/.cache/exllamav3/expert_stats/<hash>.json` | | permutes experts hot-to-cold at load from a saved profile (`_STATS_SAVE_INTERVAL = 4096` steps, `_STATS_MIN_STEPS = 64`), so the GPU slice starts with the frequent experts. The permutation is applied to the router weights too (`cpu_post_load`). |
| `EXL3_MOE_CPU_SWAP_DEBUG`, `…_VERIFY`, `EXL3_MOE_CPU_PROMOTE_VERIFY` | off | counters / readback comparison against the checkpoint (very slow). |

## 5. Overlap, observability and kill switches

These do not change any shape, but they change **how much GPU work exists to hide the worker**
behind, which is what sets decode latency (`measured-costs.md` §4, §6):

| knob | default | effect |
|---|---|---|
| `EXL3_MOE_SHARED_COOP` | 1 | folds the shared expert into the routed decode kernel (`sh_coop`). When it is on, the shared expert no longer runs *between* the CPU issue and collect (`block_sparse_mlp.py:1436` requires `not bc_sh_exp`), so whole-layer offload loses its only overlap at decode. |
| `EXL3_MOE_COOP_WIDE`, `EXL3_MOE_COOP_KSPLIT` | auto / none | tile geometry and split-k of the bsz≤8 fused decode kernels (`exl3_moe_coop_*`), i.e. the duration of the window the CPU job hides in. Testing knobs per `doc/env_vars.md:570-582`. |
| `EXL3_MOE_FUSED_ROWS`, `EXL3_MOE_FUSED_ROWS_WIDE`, `EXL3_MOE_TILE_N`, `EXL3_MOE_MTILE` | 128 / 256 / auto / 1 | GPU-resident tier capacity and launch shape; also decide whether `expert_count.tolist()` (a per-layer host sync) is needed at all (`block_sparse_mlp.py:1197-1205`). |
| `EXL3_MOE_HANDOFF_PROF` | off | worker-side `gap / spin / compute` per 64 jobs, printed by the **child** (`moe_handoff.cu:437,544`). The only direct measurement of worker compute and of how far ahead of the GPU it is. |
| `EXL3_MOE_CPU_PROF` | off | per-phase µs and GB/s from the CPU kernel, **cumulative** since start (`moe_mul1.cpp:3900,3985`), reported every 512 jobs. |
| `EXL3_SPLIT_PROF` | off | CUDA-event brackets around issue and around the collect: med/p90 per 2048 brackets — the *exposed* stall. |
| `EXL3_MOE_SUBMIT_PROF` | off | same idea for the copy path's `submit()` (env read per call). |
| `EXL3_MOE_STREAM_DEBUG` | off | per-layer bandwidth probe result, `stream_t`, streamed/total experts and assignments, per-batch tier split. Needed to reproduce any byte accounting of the streamed path. |
| `EXL3_MOE_ARENA_DEBUG` | off | arena chunk allocations and the hugepage collapse pass timing. |
| `EXL3_MOE_POOL_PRIME` | on | wake the pool at `pass_wake` / before the payload arrives; off exposes futex wake latency per job. |
| `EXL3_MOE_CPU_SMALL_WORKERS` | 0 | cap pool participants for jobs of ≤ 2 chunks. |
| `EXL3_MOE_CPU_SWAP_DEBUG` / `_VERIFY`, `EXL3_MOE_CPU_PROMOTE_VERIFY` | off | placement counters / readback comparison against the checkpoint. |

All the profilers above add measurable cost on the per-layer path: `-mcs 192` with the three decode
profilers enabled measured 67 tok/s against 93-104 without (`notes/m_e2e_prof_split.txt` vs
`notes/m_e2e_split192.txt`).

## 6. Constants in code that shape the data

Not env-tunable, but every one of them constrains a port:

| constant | value | why it matters |
|---|---|---|
| `MOE_JOB_RING` | 256 | compute jobs in flight before the parent throttles (margin 4). 1056 B each ⇒ 270 KiB. |
| `MOE_STAGE_RING` | 64 | stage jobs in flight (margin 2). |
| `MOE_MAX_SLOTS` / `MOE_MAX_WSLOTS` | 8 / 8 | hard ceiling behind the `SLOTS`/`WSLOTS` asserts. |
| `MOE_JOB_MAX_EXPERTS` | 256 | `MoeJob.experts[]`: the hard ceiling on `STREAM_BATCH_EXPERTS`, and why `MOE_JOB_BYTES` is 1056 B. |
| flag line stride / `MOE_FLAG_BITS` | 64 B; 32-bit CUDA, 64-bit HIP | the width *is* the ordering protocol (cyclic vs plain `>=` compare); the job carries the sequence as two u32 halves. |
| ctrl layout offsets | 384 / 270720 / 273408 / 340992 | duplicated in `moe_handoff.h` and `moe_cpu_host.py` (and `tests/testlib/moe_handoff.py`) with a comment to keep them in sync. |
| section alignment | `align64` between `x/sel/w/out`, 64 B arena blocks (`reserve`), `nbytes(trellis) % 64 == 0` assert | everything that crosses the boundary is 64-byte grained; the DMA and unswizzle kernels assume it. |
| `MAX_M` / `MAX_SLOTS` (CPU) | 4 / 8 | a job is chunked into ≤4-token GEMV groups; a wide row doubles that to 8 ⇒ every scratch buffer is sized `8 × k`. |
| `WIDE_LEVELS`, `WIDE_ZERO_DIV` | 16256, 16 | the wide-row test (1/16 of activations would round to zero). |
| `k ≤ 8192`, `k % 128 == 0`, `n % 128 == 0` | | int32 accumulator safety and the Hadamard block size; enforced in `make_matrix`. |
| band width | 8 (VNNI), widened on VBMI, 2 (AVX2 packed) | the traversal granularity of the GEMV and the `g` in the packed layout; also why `assign_gemvs` splits work in 8-tile groups (`FLAT_MAX_GEMVS_PER_WORKER = 4` chooses flat-vs-strided). |
| split-K parts `P` | 1, 2 or 4, VBMI tier only, `m == 1` only | changes the partial-sum buffers, not the wire. |
| `MAX_BSZN` (8), `TEMP_ROWS_GRAPH` (32) | | the decode tiers on the GPU side, hence how much work exists to hide the worker behind. |
| `MOE_JOB_KIND_*` gating | `COMPUTE_GATED` skips compute+readback | an *all-`-1` job must remain nearly free*: the worker scans `sel`, the issue kernel writes no payload, the collect kernel exits on `dev_count == 0`. |
| spin/backoff | 65536 `pause`, then 50 µs sleeps; `MOE_WAIT_TIMEOUT_NS = 30 s`, `MOE_SLEEP_MIN/MAX = 64/2048 ns` | the ~175 µs fixed cost per stage job and the tail of the decode latency distribution. |
| `_HugeArena.CHUNK_BYTES` | 1 GiB | arena chunk granularity, hence `EXL3_HOST_MEM_RESERVE_MB` check granularity and (with `-mcpa`) the registration unit. |

## 7. Cheat sheet: knob → shape actually changed

| shape | changed by |
|---|---|
| `slot_size`, `x`/`out` payload bytes | `CPU_SLOT_ROWS`; `hi/ho/topk` (model-driven, not tunable) |
| pinned region size | `CPU_SLOTS × slot_size + CPU_WSLOTS × CPU_WSLOT_MB + 333 KiB` |
| jobs per prefill | `ceil(rows / CPU_SLOT_ROWS)` (P2/P3 tail) |
| experts per stage job / DMA / fused launch | `min(CPU_WSLOT_MB / expert_bytes, STREAM_BATCH_EXPERTS, 256)` |
| streamed VRAM rings | `CPU_WSLOTS × CPU_WSLOT_MB` (×2 when the layer's bytes arrive packed) |
| fused temp buffers | `concurrency × (fused_rows or STREAM_FUSED_T) × (2H + 2I) × 2 B` |
| GEMV rows per token | `EXL3_MOE_CPU_WIDE` (1 or 2), `MAX_M = 4` chunking |
| bytes of an expert on the wire | bitrate K and dims only (checkpoint), plus the layout permutation (`CPU_SWIZZLE`, `MAX_ISA`) |
| which experts are on which device | `-mcs K`, `CPU_SWAP*`, `CPU_PROMOTE`, stats/profile |