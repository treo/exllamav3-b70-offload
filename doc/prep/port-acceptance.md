# Acceptance criteria for a port of the MoE CPU offload

What "done and correct" means for moving this feature to a new accelerator (and/or a new CPU tier),
with the thresholds the project already enforces and the values measured on the reference box
(`measured-costs.md`) so each criterion has a number attached. Ordered strictest first: a port that
fails an earlier level cannot be validated by the later ones.

Harnesses added for this document (all runnable now):

| script | level | output |
|---|---|---|
| `notes/verify_trellis.py` | A (format) | [1]-[5] format checks |
| `notes/acceptance_kernel.py` | B (kernel numerics) | CPU vs fp64 oracle vs GPU reconstruct, bitwise repeatability |
| `notes/acceptance_model.py` + `notes/acceptance_report.py` | C (model agreement) | KL / top-1 / greedy table with pass-fail under the suite's own policy |
| `notes/run_profile_ab.sh` | C, E hygiene | cold vs warm placement start |
| `notes/bench_handoff.py`, `notes/bench_cpu_moe.py`, `notes/bench_link.py`, `notes/prof_e2e.py`, `notes/run_e2e.sh` | E (performance) | per-hop, per-tier and end-to-end costs |

---

## Level A — the weight format must be **bit-exact**

No tolerance is acceptable here: `reconstruct`, the GEMV/GEMM kernels, the CPU worker and the
un-swizzle kernel all read the same bytes, so a bit-order deviation is silent corruption, not noise.

Required properties, each with the check that proves it (details in [`mul1-trellis.md`](mul1-trellis.md)):

| # | property | check | expected on the reference data |
|---|---|---|---|
| A1 | window = ring bits `[S(i)-16, S(i))`, tail-biting, MSB-first, `uint16` pairs forming big-endian-bit `uint32`s | `testlib.trellis.is_tail_biting(unpack(packed, K), K)` on a real expert tensor | `True` at K=3 and K=2.5 (`verify_trellis.py [1]`) |
| A2 | tile element order = tensor-core permutation | independent NumPy dequant vs `ext.reconstruct` | max abs diff **0.0** on `(2560, 640)` expert weights, both rates (`[2]`) |
| A3 | mul1 codebook = `fp16((bytesum(s·0x83DCD12D) − 510) · fp16(0x1eee))`, one rounding | enumerate all 65536 states | **913** distinct values, range `[-3.4531, 3.3477]`, mean `-0.0019`, std `1.0003`, largest collision class 175 (`[3]`) |
| A4 | half-integer rates: `D(i) = KA + bit(i mod 16) of 0xAAAA`, tile = `16K` `uint16` | A1/A2 at K = 1.5 / 2.5 / 3.5 | covered by `tests/moe_cpu/test_half_rates_cpu.py`, `tests/kernels/moe/test_moe_half_rates.py` |
| A5 | packed CPU layouts (band-g, planar dwords) round-trip, and the *rule* is per-tier | `repack` → inverse → compare | equal for K = 1, 2, 2.5, 3, 8 with this tier's `(group, planar)` = `(2, 1)`, `(2, 1)`, `(0, 0)`, `(2, 1)`, `(2, 1)` (`[4]`) |
| A6 | int8 fusion identity (`Σ w·x = k_inv·q·(Σ bytesum·x8 − 510·Σx8)`) | dot-product check | agrees to fp16 rounding, rel err 3.3e-4 (`[5]`) |
| A7 | dims are multiples of 128 after padding; `k ≤ 8192` for int32 accumulators | loader assertions (`moe_mul1.cpp:3668-3674`) | assert, don't assume |

**A new backend must not re-derive any of this**: `tests/testlib/trellis.py` is the executable spec
(pack/unpack/decode/dequant/dense-linear in float64, no extension calls) and should be ported with
the kernels; every format test in `tests/kernels/quant/` treats it as ground truth.

## Level B — the CPU expert kernel's numerical class

The CPU path is allowed to differ from the GPU path (int8 activations, fp32 transforms, different
accumulation order), so the criterion is *error against exact arithmetic on the same quantized
weights*, plus internal consistency.

Existing bars in the tree (do not weaken them):

| test | bar |
|---|---|
| `tests/moe_cpu/test_tiers.py` | every int8 tier within **rel L2 0.05** of the fp32 `scalar` tier (`SCALAR_TOL`), and tiers mutually consistent |
| `tests/moe_cpu/test_half_rates_cpu.py` | per-row error **< 0.04** at each rate, swizzled and native |
| `tests/moe_cpu/test_wide_rows.py` | **< 0.04-0.05** on inputs with a dominant shared component; deep-saturation activations must stay **finite** |
| `tests/moe_cpu/test_cpu_decode.py` | single-token fused finish == batched path (exact same arithmetic, so compare tightly) |

Measured class of the current implementation (`notes/acceptance_kernel.py`, real expert weights,
activations either real captured hidden states or `randn` with a massive shared component; error is
relative L2 of the routed sum against a float64 reference built only from `testlib.trellis`):

| model / rate | rows | input | CPU rel RMS | GPU reconstruct rel RMS | CPU/GPU | CPU bitwise repeatable |
|---|---|---|---|---|---|---|
| Qwen3.5 @K=3 (band-2+planar) | 1 | synthetic+massive | 1.82e-2 | 8.36e-4 | 21.8 | yes (30 reps) |
| | 4, 16 | **real** | 1.45e-2, 1.50e-2 | 8.0e-4, 7.95e-4 | 18.1, 18.8 | yes |
| Qwen3.8 @K=2.5 (native) | 1, 4, 16 | synthetic | 2.00e-2, 2.16e-2, 2.10e-2 | 8.3-8.7e-4 | 24.2-24.8 | yes |

**Gate B1:** rel RMS against the fp64 oracle ≤ **2.5e-2** per layer for the above shapes, i.e. within
the ~1.5-2.2e-2 band the int8 scheme already occupies, and comfortably inside the suite's 0.04 bar.
**Gate B2:** the ratio to the device reconstruct path ≤ **~25×**; a port that beats 1e-2 has changed
the algorithm (finer activation quantization) and must say so.
**Gate B3:** repeated calls with identical inputs are **bit-identical**. The CPU scheduler steals
work units, so this is a real invariant (per-unit arithmetic must not depend on the worker), and it
is what makes greedy replay debuggable.
**Gate B4:** tier agreement — if the port adds a new ISA tier, it must land inside 0.05 of the
existing tiers, and the *layout rule* (`swizzle_group`, `planar_layout`) must be reported per rate
(the AVX2 tier leaves half rates native; the AVX-512 tiers band them; a new target must state its
own table and have the GPU restore side read it, never duplicate it).

## Level C — whole-model agreement (the project's own tolerance policy)

Policy, from `tests/testlib/e2e.py::assert_logits_agree`: per-position KL(P‖Q) with
`median < max(abs_median_kl, 4 × noise_floor_median)`, `mean < max(0.05, 4 × floor_mean)`,
**confident top-1 ≥ 0.97** over positions where the reference leads by > 1.0 logit, and all logits
finite. `tests/e2e/test_moe_offload.py` sets `abs_median_kl = 1e-2` for the CPU path (its docstring:
"The CPU path's int8 activations add error on top of the routing noise floor").

Measured against an all-GPU load of the same weights (Qwen3.5-35B, 193-token teacher-forced prompt,
24 cached decode steps, **cold placement start**, `notes/m_accept_report2.txt`):

| placement | teacher-forced KL med / mean / max | cached prefill+decode KL med / mean / max | confident top-1 | greedy (24 tok) |
|---|---|---|---|---|
| `-mcs 192` | 7.09e-4 / 1.15e-3 / 1.52e-2 | 4.85e-4 / 1.45e-3 / 1.87e-2 | 1.000 (114 pos) | identical |
| `-mcs 192 -mcpa` | 4.93e-4 / 1.10e-3 / 3.03e-2 | 3.17e-4 / 1.46e-3 / 1.62e-2 | 1.000 | identical |
| `-mcs 192` `WIDE=0` | 5.03e-4 / 1.04e-3 / 3.09e-2 | 4.57e-4 / 1.16e-3 / 7.64e-3 | 1.000 | differs at token 4, reference lead **+0.234** → allowed near-tie |
| `-mcl 20` | 5.09e-4 / 1.13e-3 / 2.75e-2 | 3.52e-4 / 8.79e-4 / 8.88e-3 | 1.000 | identical |

The model's own noise floor in the same run: median `2.43e-4`, mean `3.07e-4`.

**Gate C1:** median KL ≤ 1e-2 (the suite's CPU bar). Measured headroom **14-32×** against 1e-2, and
**2.8-6×** against the *generic* 2e-3 bar — so a port that merely matches the current path passes
both, and anything landing above ~2e-3 median needs justifying.
**Gate C2:** confident top-1 = 1.000 measured; the bar is 0.97. A real expert-mapping or staleness
bug produces KL of **order 1** (per `test_moe_offload`'s docstring), i.e. this gate is not marginal.
**Gate C3:** the same three measurement paths must pass: cache-less teacher-forced forward, cached
prefill + single-token decode (this is the one that exercises the decode handoff), and batched
decode (in the suite; `prefill_decode_logits` accepts a list of sequences).
**Gate C4 (not required):** greedy trajectory equality. It happens to hold here for `-mcs` and
`-mcl`, but the contract is statistical agreement: `WIDE=0` diverges at a 0.234-logit near-tie and
that is legal. Do not add a greedy-equality gate without also pinning the placement profile.
**Prerequisite:** placement state must be controlled or these numbers are meaningless —
`measured-costs.md` §8.3 shows the hot-expert profile is keyed on model dir + expert count only, is
rewritten at unload, and changes decode throughput 12-22% and the CPU hit count 25%. Redirect
`block_sparse_mlp_cpu.EXPERT_STATS_DIR` (what `tests/` does) or pass
`EXL3_MOE_CPU_SPLIT_STATS`, and say in the report which state was used.

## Level D — protocol and liveness invariants

Each of these has a test in the tree; a port must keep the behaviour, ideally the test.

| invariant | why it bites | existing test |
|---|---|---|
| Descriptor is host-visible **before** the GPU publishes `data_ready`; sequence increases monotonically | child reads a torn/old descriptor | `tests/kernels/moe_cpu_host/test_moe_worker.py`, `test_moe_flags.py` |
| 32-bit flags compared **cyclically**; 64-bit where the backend's wait is a plain `>=` | wrapped flag satisfies a wait early | `test_moe_flags.py` (+ `MOE_FLAG_BITS` note in `moe_handoff.h:44-52`) |
| Slot reuse gates on `consumed` (written by the *reading* stream), not `done` | multi-device: worker overwrites an output another device has queued | `test_moe_worker.py`; reasoning in `moe_handoff.h:26-33` |
| Issue window ≤ `num_slots` with inline collect | in-stream deadlock (the historical "second-prompt freeze") | `tests/e2e/test_moe_offload.py` (two prompts in one session) |
| Ring-full throttle: `exl3_moe_split_issue_fused` returns false without side effects, caller polls `jobs_head` | long prefill overflowing 256 jobs | `test_moe_worker.py` |
| `COMPUTE_GATED` jobs may skip compute **and** the readback; plain `COMPUTE` must always write/zero the output | collect reads garbage for an all-`-1` job | `tests/kernels/moe/test_moe_split.py` |
| Dead-worker detection: memop waits have no timeout, so the host watchdog unblocks them | hung stream instead of an error | `moe_cpu_host.py:1310` `_start_watchdog`; exercised by kill tests |
| Uniform `hi`/`ho`/`topk` across registered layers; all boundary copies contiguous | strided host copies are executed eagerly at enqueue time | `ensure_started` assert (`moe_cpu_host.py:1200`) |
| Pinned/registered memory: handoff segment registered **after** arena chunks, with chunk release-and-retry if the pinned budget is exhausted | OOM-in-registration on WDDM/WSL2 | `tests/moe_cpu/test_pinned_arena{,_windows}.py`, `_register_handoff` |
| `/dev/shm` capacity checked before creating the segment | silent failure to map | `tests/moe_cpu/test_shm_capacity.py` |
| Reload (load → generate → unload → load) leaves no stale worker/layer indices | autosplit rollback and `--reload` paths | `tests/moe_cpu/test_reload.py` |
| Swap sweeps run under inference mode and quiesce **all** devices holding split layers | issue #329; torn arena writes | `tests/moe_cpu/test_swap_sweep_inference_mode.py` |
| Permuted placement forces eager router load | deferred tensors would be filled after the permutation | `tests/moe_cpu/test_split_defer_guard.py` |
| TP load with an offload requested raises, never silently loads experts to device | `model.py:695-710` | `tests/e2e/test_tensor_parallel.py` adjacency |
| Host affinity/pinning: pool pins one thread per physical core, host confined to the reserved cores, and pinning failures degrade to a notice | a straggler at every dispatch barrier | `tests/moe_cpu/test_host_affinity.py`, `test_core_order.py`, `test_pool_stress.py` |

**Current state of that suite on the reference box** (`pytest tests/moe_cpu
 tests/kernels/moe_cpu_host tests/kernels/moe -m "not slow"`): **395 passed, 29 skipped, 22
deselected, exit 0** in 88 s. The skips are environmental, not failures: Windows-only arena tests,
and tests that need a specific registry checkpoint (e.g. `test_tiers.py:185` wants an
`lfm2.5-8b-a1b` mul1 bitrate ladder under the model root). A port should reach the same pass count
and account for each skip.

One fix was needed to get there and is included on this branch: `tests/moe_cpu/test_swap_sweep_
inference_mode.py`'s stub `Generator` lacked `sparse_head`, which `Generator.on_queue_drained`
began reading when the sparse draft head landed, so the test failed for a reason unrelated to the
offload path while guarding an offload invariant (issue #329: the sweep must enter inference mode).

Backend-specific pieces that need explicit tests on the new target (the CUDA versions are
`tests/kernels/moe/test_moe_split.py`, `test_moe_unswizzle.py`,
`tests/e2e/test_moe_stream_unswizzle.py`, `tests/moe_cpu/test_stream_layout.py`,
`test_stream_probe.py`): zero-copy stores into mapped host memory with a system-scope fence; the
stream value wait/write semantics (and their absence fallback kernel); the bandwidth probe behaving
correctly when the link is idle/downclocked; and the packed→native restore for **every** rate the
new CPU tier bands.

## Level E — performance gates

Floors, from `measured-costs.md`, with the tolerance a port should hold itself to (±30% is the
suggestion where the mechanism is protocol-bound, since those costs are launch/latency dominated):

| gate | reference value | why |
|---|---|---|
| E1 empty (all-`-1`) decode job | **20 µs/layer** (48-job pipeline: 13-19 µs) | the floor for cold tails; if the port's handshake is slower than this, layer count multiplies the loss |
| E2 flag round trip host↔device | 6.4 µs (memops) / 10.7 µs (kernel), enqueue 1.8 µs | per-layer, twice |
| E3 issue + collect kernels at decode | 3.9 + 4.0 µs each, 1 row; ~21.6 + 41.3 µs as `copy_` at 64 rows | the payload movers |
| E4 CPU layer cost | `experts × expert_bytes ÷ DRAM read rate` with the measured rate for the actual tier (47.4 GB/s @K=3 packed, 31.1 @K=2.5 native, 15 threads) | bandwidth-bound: measure cold selections, never a repeated one |
| E5 pinned→device sustained | 13.3 GB/s here (Gen4 **×8**); unswizzle ~440 GB/s effective; stage `memcpy` 16.3 GB/s + ~175 µs per job | prefill is link-bound: 28% of device time is this DMA |
| E6 end-to-end, placement-controlled | `-mcs 192` warm ≈ 100 tok/s decode / 1790 prefill; `-mcs 192 -mcpa` ≈ 78 / 2523; `-mcl 40` 54.5 / 1401; all-GPU 124 / 5043 (Qwen3.5, this box) | regressions must be explained by E1-E5, not by noise |
| E7 streaming must dominate the tail | turning streaming off costs **2.1×** at 2048 rows | if a port makes streaming cheaper than 2.1× better than CPU tail, `stream_t` is wrong |

Measurement hygiene that these gates depend on: rotate expert selections (L3 is 64 MiB and will
otherwise absorb the whole working set); use real text routing for anything placement- or
threshold-sensitive (random ids wash the profile effect out); warm up before timing; report profiler
numbers separately (`EXL3_SPLIT_PROF`/`HANDOFF_PROF` cost ~30% on their own); state link geometry
(gen **and** width, measured under load) with every bandwidth figure.

## Procedure

```bash
source notes/env.sh                                   # venv + CUDAHOSTCXX for the JIT build
# A - format
python notes/verify_trellis.py                        # compare against the table above
# B - kernel numerics (no model load)
python notes/acceptance_kernel.py $MODEL --experts 24 --rows 1,4,16 --acts /tmp/acts.pt
EXL3_MOE_CPU_WIDE=0 python notes/acceptance_kernel.py $MODEL --experts 24 --rows 1,4,16 --no-offset
EXL3_MOE_CPU_MAX_ISA=scalar python notes/acceptance_kernel.py $MODEL --experts 8 --rows 1 --no-offset
# C - model agreement (cold and warm placement, both reported)
python notes/acceptance_model.py $MODEL --placements ref,split,split_pa,layer20 \
        --profile cold --prompt 256 --decode 24 --dump-acts /tmp/acts.pt --out /tmp/m1.pt
python notes/acceptance_report.py /tmp/m1.pt
# D - the suite
pytest tests/moe_cpu tests/kernels/moe_cpu_host tests/kernels/moe -m "not slow"
pytest tests/e2e/test_moe_offload.py tests/e2e/test_moe_stream_unswizzle.py -m slow
# E - performance
bash notes/run_e2e.sh split192 split192pa layer40 streamT0 && bash notes/run_profile_ab.sh
python notes/bench_link.py; python notes/bench_handoff.py $MODEL --experts 256
```

A port is accepted when A is bit-exact, B1-B4 hold, C1-C3 pass with the placement state declared,
every Level-D invariant has a passing analogue on the new backend, and E1-E7 deltas are either
within tolerance or explained by a measured mechanism.

## Explicit non-goals

- **Bit-exact CPU/GPU parity** — impossible by construction (int8 activations, fp32 transforms,
  different accumulation order); Levels B/C measure the *distribution* of the difference instead.
- **Greedy-token equality** across paths (Gate C4), and bit-identity across `EXL3_MOE_RECON_FOLDED`
  modes (the docs note those are "equally far from the baseline", not closer).
- **Determinism across slot/ring geometry changes**: `SLOT_ROWS`/`SLOTS` change chunking, hence the
  number of jobs, hence nothing about arithmetic — but placement and atomics do change results.
- **Porting the tuning defaults**: `stream_t`, `STREAM_FUSED_T`, `SLOT_ROWS`, `WSLOT_MB` and the
  swizzle tier table are all calibrated to *this* silicon; the port inherits the *procedure*
  (`measured-costs.md` §9), not the numbers.