# Prep notes: porting the MoE CPU offload

Research artifacts for moving the MoE CPU-offload machinery (currently CUDA + x86 workers) to a
different kind of accelerator. Written against `dev` @ `cdc785db` (v1.6.5) on the tree in this
repository; every code claim carries a `file:line`.

| document | what it answers |
|---|---|
| [`moe-cpu-offload-data-paths.md`](moe-cpu-offload-data-paths.md) | What runs, in what order, on which side of the device boundary, for each of the four paths (fused decode handoff, copy-path handoff, plain prefill, streamed prefill), including the CUDA kernels, the shared-memory layout, and the worker's internal schedule. |
| [`mul1-trellis.md`](mul1-trellis.md) | The weight format: bit-ring container, tile element order, the `mul1` codebook and why it makes the CPU GEMV an integer dot product, the CPU "packed" layouts and who restores them, and the invariants a new consumer must keep. |
| [`tuning-knobs.md`](tuning-knobs.md) | Every env var and hard-coded constant that shapes or routes the data, grouped by whether it changes a *shape*, a *decision*, or only an *implementation*, with a cheat sheet of knob → shape changed. |
| [`measured-costs.md`](measured-costs.md) | Timings for each hop on the reference box, the CPU-GEMM cost curve, the kernel-level decode/prefill breakdown, the end-to-end knob sweep, and a list of what to measure first on new hardware. |

Reproduce with the scripts kept in `notes/` on this branch (`git log --oneline -- notes`):

```
source notes/env.sh            # venv + CUDAHOSTCXX=g++-15 for the JIT extension
python notes/geom.py           # handoff-region and ring geometry for the models below
python notes/scan_widths.py    # bitrate/tile-width census of the local checkpoints
python notes/verify_trellis.py # every format claim in mul1-trellis.md
python notes/bench_cpu_moe.py  MODEL_DIR ...       # cold-expert CPU GEMV sweeps
python notes/bench_handoff.py  MODEL_DIR ...       # flags, copies, decode loop, staging, unswizzle
python notes/bench_link.py                          # pinned bandwidth + negotiated PCIe width
python notes/prof_e2e.py -m MODEL_DIR -mcs 192      # per-kernel decode/prefill breakdown
bash   notes/run_e2e.sh <cfg>...                    # eval/perf.py sweep over the knob configs
```

Reference environment for all numbers: RTX 3090 (sm_86) on a PCIe Gen4 **×8** link, Ryzen 9 5950X
(16c/32t, **AVX2 tier only**), models `Qwen3.5-35B-A3B-3bpw-hq2` (256 experts, top-8, K=3, fits the
GPU so it gives an all-GPU reference) and `Qwen3.8-Flash-Next-exl3-2.68bpw_h6_ng8` (512 experts,
top-10, K=2.5/3).

## Headline findings

1. **Two handshakes, one ring.** Decode uses a kernel that writes the payload *directly into pinned
   host memory* and folds the fp32 result back in place from that memory (no `cudaMemcpy`, and no
   payload at all when no CPU expert was selected: 20 µs/layer). Prefill uses contiguous
   `cudaMemcpyAsync` chunks of `cap_rows` rows. Both are ordered purely by four monotonic flags per
   slot (`data_ready`, `done`, `consumed`, plus `stage_done`/`pinned_free` for weights), which is
   what makes the parent's forward never block.
2. **Decode is DRAM-bound, prefill is link-bound.** A decode layer costs
   `experts_touched × expert_bytes / ~45 GB/s` plus a ~20-35 µs handshake tax; ~28% of a streamed
   prefill's device time is pinned→VRAM expert DMA running at exactly the measured link rate
   (12.9 GB/s over 3.9 GiB in the profiled 2048-token chunk), against 8% for the fused MoE kernel.
3. **`stream_t` is the knob.** Turning GPU streaming off costs 2.1× at 2048 prefill tokens; letting
    the parent DMA expert bytes straight out of the worker's page-locked arena (`-mcpa`) is worth
    another 1.3×; nothing else measured moved prefill by more than 6%.
4. **The worker's throughput does not scale with queue depth** at decode shapes (pipelined 48 jobs
   = same per-layer cost as serial), because a single job already saturates the pool; extra slots
   buy overlap with the *GPU*, not with the worker.
5. The packed-layout rule is ISA-tier dependent, and on this AVX2 host half-integer bitrates stay
   **native** and lose ~35% of the CPU read rate that integer bitrates get from band-2+planar. A new
   CPU target should decide its own tier table rather than inherit AVX-512/AVX2 semantics.

## Things a port should watch out for (found while reading, not guessed)

* `MoeCpuHost.ensure_started` **asserts** uniform `hi`/`ho`/`topk` across all offloaded layers; the
  per-expert byte layout (`proj_bytes`, `stage_phase`, `promote/demote`) is derived from **expert 0's
  dimensions**, while `MoeCpuMatrix` carries `bits`/`hb` per matrix. Locally, every expert inside a
  layer does share one rate (`notes/scan_mixed_rates.py`), so the assumption currently holds — but
  nothing enforces it at load, and rates do vary per layer (Qwen3.8 @2.68: 2.5 bpw in layers 4-43,
  3 bpw in 0-3 and 44-47). A port should assert uniformity rather than rely on it.
* `exl3_moe_cpu_stage_experts` spawns and joins fresh `std::thread`s per stage job; measured fixed
  cost ~175 µs per job on this host, insensitive to `EXL3_MOE_CPU_STAGE_THREADS`.
* The staged path deliberately ships bytes **verbatim** and un-swizzles on the GPU
  (`moe_unswizzle_trellis`) because un-swizzling on the stager thread measured as a 17% prefill loss
  on a fully-offloaded 119B model. Keep that division of labour.
* Slot reuse is gated on `consumed` (written by the *reading* device's stream), not `done`
  (written by the worker): with offloaded layers spread over several accelerators, `done` alone lets
  the worker overwrite an output another device has queued but not performed.
* `EXL3_MOE_CPU_SLOT_ROWS` is not only a chunk size: the fused decode path refuses `rows >
  cap_rows`, so lowering it below the speculative-verify width (32) silently switches that traffic
  to the slower copy path.
* `doc/env_vars.md:411` documents the streaming threshold base as 16; the code uses 8
  (`moe_cpu_host.py:139`), and `moe_cpu_host.py`'s module docstring says the worker is spawned at the
  first layer registration while `model.py:614-616` spawns it before any module loads (deliberately,
  to overlap interpreter startup). Neither changes behaviour, but both are load-bearing-looking text
  a porter would otherwise trust.
* Live but undocumented in `doc/env_vars.md`: `EXL3_MOE_CPU_SPLIT`,
  `EXL3_MOE_CPU_SPLIT_LAYERS`, `EXL3_MOE_CPU_SWAP{,_INTERVAL,_HYST,_FLOOR,_MAX,_DEBUG,_VERIFY}`,
  `EXL3_MOE_SPLIT_FUSED`, `EXL3_MOE_SUBMIT_PROF`, `EXL3_SPLIT_PROF`, `EXL3_MOE_POOL_PRIME`,
  `EXL3_MOE_CPU_SMALL_WORKERS`.