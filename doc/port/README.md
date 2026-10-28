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
