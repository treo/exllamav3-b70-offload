# Porting the MoE offload to the Intel Arc Pro B70

**Status: v1.0 — final for building against.** [`b70-architecture.md`](b70-architecture.md) §12 lists
every decision as either *closed on evidence* (do not re-litigate during the build) or *open behind a
named gate* (do not assume it). Two of the three things that could have reshaped the design were
measured away in this directory; the third (locality) reshaped the kernel rules, not the architecture.

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
| [`b70-architecture.md`](b70-architecture.md) | participant model, the three disjoint expert homes and where their bytes move, the five data paths rewritten for a fast offload device, the placement/migration cost model, oversized models (§4a: `S_b` as a cache, `h_min`, the disk tier), execution-model tiers with measured costs, code-impact map, phased plan with decision gates, risks |
| [`b70-kernels.md`](b70-kernels.md) | the expert kernels themselves: mul1 trellis decode on Xe2, the decode GEMV, the XMX (DPAS) routes for prefill, the Hadamard/activation phases, determinism, layout rules, test vectors |
| [`b70-harness.md`](b70-harness.md) | the harness that proves correctness, speed and *utilisation* (board power) continuously, with the gates each phase must clear |
| [`b70-decode-closeout.md`](b70-decode-closeout.md) | **E24 close-out (start here for decode):** decision record D1–D7 including the one open item (accepting the intra-tile permuted layout), the measured anchors, what was refuted so it isn't re-attempted, the ranked unknowns handed forward, and the exact reproduce/gate commands |

Measured inputs live in [`notes/b70/`](../../notes/b70/README.md) (probes + raw logs) and the traps
found while measuring them in [`notes/b70/LESSONS.md`](../../notes/b70/LESSONS.md). Reference
material for the card is symlinked at [`doc/b70/`](../b70/) (cheat sheets, the LLVM SYCL tree with
`doc/extensions/experimental/sycl_ext_matrix/`, and `test-e2e/` as trusted example code).

## Thesis in six measured numbers

| | CPU offload today (RTX 3090 + Ryzen 9 5950X) | B70 offload (measured or projected) |
|---|---|---|
| one cold expert read at decode | 403 µs/layer (Qwen3.8, 15 threads) | **51 µs/layer** for Qwen3.8 at b=1 — sampled at the footprint a decode layer actually presents (14.3 MiB: `topk` 10 × the picks this card owns), 27 µs if the kernel obeys the locality rules — but **405 µs/layer for GLM**, whose 9 MiB experts put the same token at 50.9 MiB, the worst point of the measured curve (**[M]**, `plan_operating_point.py`) |
| handshake floor, job with nothing to do | 20 µs/layer | **5.0–6.3 µs** (submit + flag) / **3.2 µs** (resident doorbell) |
| expert bytes must cross the link for prefill | yes — 28.6 % of device time is that DMA | **no** for experts homed on the B70; yes for the residue, priced per use (§4a) |
| pinned ↔ device bandwidth | 13.3 GB/s (Gen4 ×8) | **14.4 GB/s** |
| activation payload per decode layer | 5.1 KiB down, 10 KiB up | same, and it hides entirely |
| GPU work available to hide the offload behind | 165 µs/layer (Qwen3.5), ~250 µs/layer (Qwen3.8) | unchanged — ~5× the offload cost for Qwen3.8 at b=1, **not** for GLM, and gone by b=8: distinct experts per layer grow ~linearly with rows (10 → 39 → 73), so B70 work scales ~9× while the window barely moves |
| what the trellis tile walk actually sustains | — (the CPU is DRAM-bound at 45 GB/s) | **132–292 GB/s scattered, 216–558 clustered** (the spread is working-set size, not code): tile repacking buys **0.96–1.05×** with no consistent sign, work-item ordering buys **1.08–1.99×** and never less |
| is the decode arithmetic affordable? | 7-op VNNI fallback costs ~20 % on x86 | **not yet.** `probe_gemv` runs the real trellis GEMV (bit-exact vs `tests/testlib/trellis.py`): **61.4 GB/s** at R=1, 27.9 before the byte-sum dot fix — 4–5× below the 292 GB/s the byte stream sustains, and the rows cost ~4 instructions each. Both points match an instruction-count model to 10 %, and `b70-kernels.md` §2a names the CUDA/CPU structures that close it. **Answered and closed by E24:** the selected kernel (rev J, transposed tiles) runs gate_proj at **14.0 µs = 437 GB/s effective**, ~90 % of the measured 484 GB/s stream slope, and a b=1 MoE layer costs **43.6 µs** against the parent's 250 µs window; bit-exactness is gated by `notes/b70/gate_dpas.py` (112 comparisons across dp4a/rev I/rev J/rev K, all byte-identical). Decisions and open items: [`b70-decode-closeout.md`](b70-decode-closeout.md) |
| what actually binds decode | DRAM bandwidth on the CPU tier (45 GB/s) | **instructions per weight** on the B70 — the opposite of what an earlier draft of this plan concluded from a proxy that walked the bytes without computing them |

Oversized models are covered too, and they are a different problem: at 108.8 GiB of routed-expert
trellis (GLM-5.3-Flash@3.05, present on this box) only 29 % of the experts fit the B70, so the B70
tier becomes a **cache** and the port's problem becomes hit-rate engineering — a 655 µs admission
against a 199 µs CPU compute makes "admit on the fourth use" roughly size-independent, and the
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

Phase 0 and phase 0b are done: the probes in [`notes/b70/`](../../notes/b70/README.md) answer the
transport, sharing, store-discipline, bandwidth, layout and arithmetic questions, and
`plan_placement.py` answers the placement questions from real routing counts (`out_placement.txt`).
What remains before the design is exercised end to end:

1. `notes/b70/probe_gemv.cpp` — the `Recipe A` trellis decode for one 16×16 tile diffed against
   `tests/testlib/trellis.py` on the device, plus the K=4 vector table from
   `doc/b70/EXL3 mul1 Trellis Unpacking…` (Gate B′6), and then the *fragment* kernel measured in both
   orderings from b70-kernels.md §3a. That single file settles Gates B′6, E4, E4b and E4c, and it is the
   last measurement that can invalidate the decode cost model.
2. `exllamav3/exllamav3_ext/b70/` + `ext_b70.py` — the torch-free C-ABI engine library, with a
   `b70_engine_submit(job_desc)` that does nothing but DMA the slot message in, wait, and publish
   `done` from the pinned slot. Wire it to `MoeB70Host` in the child process and run the Level-D
   liveness tests with a *null* kernel: if an all-zero output folded into the routed sum still passes
   the protocol tests, the plumbing is right and only the arithmetic is missing.
3. The real GEMV (Gates B′1/B′2), then `-mb`, then the row/home partition (which today is only
   validated against decayed profiles — E14 needs a fresh trace, ideally dumped from an existing
   `-mcs` run before any B70 code exists at all).

Rules to keep while doing it (`notes/b70/LESSONS.md` is the reason for each):
no `.wait()` on a job path; DMA in, fenced stores out; no `sycl::atomic_ref` on the shared region at
any scope; explicit `i[0]` indexing; assert on every payload word, never on a return code or a flag
alone; grid order = memory order and one contiguous VRAM block per layer; pin the placement profile
before timing anything; sample board power with the engine parked as the baseline; and for any
microbenchmark, prove the bytes were read and the result was consumed before believing the rate
(`LESSONS` 15).
