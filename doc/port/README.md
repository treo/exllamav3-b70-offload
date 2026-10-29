# Porting the MoE offload to the Intel Arc Pro B70

Design and architecture for running the offloaded MoE expert computation on an **Arc Pro B70**
(Xe2-HPG / BMG-G31, 32 Xe cores, 31.9 GiB @ 608 GB/s) instead of, or alongside, the x86 worker.

[`doc/prep/`](../prep/README.md) is the study of the existing CUDA + CPU-offload machinery that this
port is built on; every claim there about the protocol stays true here. What changes is the
*assumption* underneath it: **the offload device is no longer slow.** The B70 is a ~10× faster
expert reader than this box's CPU worker, has its own 32 GiB of memory, and sits on a link that is
(a shade) *faster* than the one the 3090 uses. Several load-bearing parts of the CPU design
(weight streaming, the staged prefill rings, the packed-layout contract with the GPU) stop paying
for themselves, and one part becomes the whole game: the **handshake**.

| document | what it answers |
|---|---|
| [`b70-architecture.md`](b70-architecture.md) | participant model, where weights/activations live and move, the five data paths rewritten for a fast offload device, the placement cost model, execution-model tiers with measured costs, code-impact map, phased plan with decision gates, risks |
| [`b70-kernels.md`](b70-kernels.md) | the expert kernels themselves: mul1 trellis decode on Xe2, the decode GEMV, the XMX (DPAS) routes for prefill, the Hadamard/activation phases, determinism, layout rules, test vectors |
| [`b70-harness.md`](b70-harness.md) | the harness that proves correctness, speed and *utilisation* (board power) continuously, with the gates each phase must clear |

Measured inputs live in [`notes/b70/`](../../notes/b70/README.md) (probes + raw logs) and the traps
found while measuring them in [`notes/b70/LESSONS.md`](../../notes/b70/LESSONS.md). Reference
material for the card is symlinked at [`doc/b70/`](../b70/) (cheat sheets, the LLVM SYCL tree with
`doc/extensions/experimental/sycl_ext_matrix/`, and `test-e2e/` as trusted example code).

## Thesis in six measured numbers

| | CPU offload today (RTX 3090 + Ryzen 9 5950X) | B70 offload (measured or projected) |
|---|---|---|
| one cold expert read at decode | 403 µs/layer (Qwen3.8, 15 threads) | **~35 µs/layer** (projected from 608 GB/s and the ALU budget) |
| handshake floor, job with nothing to do | 20 µs/layer | **5.0–6.3 µs** (submit + flag) / **3.2 µs** (resident doorbell) |
| expert bytes must cross the link for prefill | yes — 28.6 % of device time is that DMA | **no**: they already live on the offload device |
| pinned ↔ device bandwidth | 13.3 GB/s (Gen4 ×8) | **14.4 GB/s** |
| activation payload per decode layer | 5.1 KiB down, 10 KiB up | same, and it hides entirely |
| GPU work available to hide the offload behind | 165 µs/layer (Qwen3.5), ~250 µs/layer (Qwen3.8) | unchanged — and now 4–7× the offload cost |

Oversized models are covered too, and they are a different problem: at 108.8 GiB of routed-expert
trellis (GLM-5.3-Flash@3.05, present on this box) only 29 % of the experts fit the B70, so the B70
tier becomes a **cache** and the port's problem becomes hit-rate engineering — a 655 µs admission
against a 199 µs CPU compute makes "admit on the third use" roughly size-independent, and the
prefetchable link bandwidth sets a hard floor (`h_min`, 92 % there) below which no policy converges.
See [`b70-architecture.md` §4a](b70-architecture.md).

Both cards hold experts and both do the arithmetic, with **disjoint** expert sets: the two read rates
are within 1.5× of each other, so a replica on the second card buys only capacity that neither has.
That makes row routing a consequence of membership (a row is computed in pieces, one job per home it
touches, partials added in a fixed order) and it makes the CPU an *equal* compute tier chosen by cost:
copying an expert across the link costs 655 µs before its first useful read, so below ~3-4 uses in a
window the CPU is simply cheaper, and above that the device is. §2.1, §3 P4 and §4 of the
architecture are that model.

Consequence: at decode the offload should become **free** (hidden behind the parent GPU's own work)
rather than the 20–56 % tax it is today, and at prefill the question flips from *"is it cheaper to
ship the weights or the rows?"* to *"how do we split rows between two fast devices without
saturating the link?"*.

## Non-negotiables carried over from the CPU design

These are not re-litigated here; the port keeps them and [`b70-harness.md`](b70-harness.md) re-tests
them:

1. The parent's forward thread **never blocks**. Everything is stream-ordered flag waits
   (`cuStreamWaitValue32`) and asynchronous copies; the offload device's latency is hidden by the
   parent's own queue depth, not by waiting.
2. One shared-memory control block: job rings, four monotonic flags per slot (`data_ready`, `done`,
   `consumed`, plus the weight-ring pair), sequence numbers, `COMPUTE_GATED` jobs that skip compute
   *and* readback when no offloaded expert was picked. Slot reuse gates on `consumed`, written by
   whoever reads the output back.
3. Every byte crossing the boundary is contiguous and 64-byte grained, and the weight format
   ([`doc/prep/mul1-trellis.md`](../prep/mul1-trellis.md)) is consumed, not re-derived:
   `tests/testlib/trellis.py` stays the executable spec.
4. Numerics are the CPU path's class (int8 activations, fp32 transforms), validated by the
   acceptance levels in [`doc/prep/port-acceptance.md`](../prep/port-acceptance.md), not by
   bit-exactness against the GPU path.

## Start here, next session

Phase 0 is nearly done (the probes in [`notes/b70/`](../../notes/b70/README.md) answer the
transport and sharing questions). What is left before any of the design is exercised end to end:

1. `notes/b70/probe_gemv.cpp`: the `Recipe A` trellis decode for one 16×16 tile, diffed against
   `tests/testlib/trellis.py` on the device, plus the K=4 vector table from
   `doc/b70/EXL3 mul1 Trellis Unpacking…` — this is Gate B′6 and it needs no engine, so it is the
   cheapest place to find out whether the ALU budget (`~9 ops/weight`) is real on this compiler.
2. Same file, second kernel: does `dot_acc` / `dot_4x8packed_us_int` become **one** instruction
   (`IGC_ShaderDumpEnable=1`)? Open question 2, and it gates the decode-vs-XMX tier boundary.
3. `exllamav3/exllamav3_ext/b70/` + `ext_b70.py`: the torch-free C-ABI engine library, with a
   `b70_engine_submit(job_desc)` that does nothing but DMA the slot message back and forth and
   publish `done`. Wire it to `MoeB70Host` in the child process and run the Level-D liveness tests
   with a *null* kernel: if an all-zero output folded into the routed sum still passes the protocol
   tests, the plumbing is right and only the arithmetic is missing.
4. Then the real GEMV (Gate B′1/B′2), and only then `-mb`.

Rules to keep while doing it (`notes/b70/LESSONS.md` is the reason for each):
no `.wait()` on a job path; DMA in, fenced stores out; no `sycl::atomic_ref` on the shared region;
explicit `i[0]` indexing; assert on every payload word, never on a return code or a flag alone;
pin the placement profile before timing anything; sample board power with the engine parked as the
baseline.
