# ADR-0001: The card runs as a job worker, not as a second device

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `boundary`, `protocol`

## Context

The port adds a second vendor accelerator, an Intel Arc Pro B70, to a CUDA engine that already
offloads routed MoE experts to an x86 worker. Two framings exist. The first makes the card a second
compute device that the model loads experts onto. The second makes the card a worker: it takes the
role that the CPU child process takes today.

The card is about ten times the expert-read rate of that worker, has its own 31.9 GiB of memory, and
sits on a link slightly faster than the parent's. A second-device framing looks attractive for that
reason. But the existing design is already a heterogeneous worker with a pinned handoff protocol: a
job ring, four monotonic flags per slot, a watchdog, and a deferred collect. The study of that design
is in [`doc/prep/moe-cpu-offload-data-paths.md`](../prep/moe-cpu-offload-data-paths.md), and its list
of "what a port needs from the accelerator" has five items. This card has four of them. It has no
stream-ordered flag wait, and it does not need one.

The hard constraint on both framings is the same: the parent's forward thread must never block.

## Decision

We will treat the card as a worker behind the existing protocol. The model's forward stays on CUDA
and does not change. A SYCL and Level Zero engine takes jobs from the shared-memory ring and writes
the slot's output. We add no torch device, no vendor test inside the model, and no new topology.

## Consequences

Positive:

* The parent side of the protocol is unchanged, so every Level-D invariant keeps holding by
  construction. See ADR-0003.
* The CPU worker stays available as a fallback and as the numeric oracle for the new kernels.
  See ADR-0040.
* Measured support exists. One page-locked region is written by a card kernel and read by the
  parent, a parent stream memop is visible to a card kernel, and a flag written by a card kernel
  retires a parent stream wait. `notes/b70/probe_cross.py` scores 8 of 9, and the one refusal is
  deliberate. See `notes/b70/out_cross.txt`.

Negative:

* The engine owns its own memory, queues and layout. None of it comes from a framework.
* The card cannot take work the protocol cannot express, so attention, dense layers, the router and
  sampling stay on the parent. Hyper-connections, at about 83 µs/layer, are out of reach.
* Two vendor toolchains live in one feature. A build failure can now come from either side.

Neutral:

* Tensor-parallel loads still raise when an offload is requested. That refusal is inherited.

## Alternatives considered

* Make the card a torch device: rejected, because it needs `torch.xpu` in this environment, makes the
  model vendor-aware, and buys nothing that the worker path does not already provide.
* Make the card the parent: rejected, because the model, its kernels and its measured baselines are
  CUDA, and the card has no advantage outside the expert term.
* Move routing or the shared expert to the card: rejected, because both are small, and the shared
  expert is a dense `GatedMLP` that the parent's dense kernels already tile well.

## Links

* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §1
* [`doc/prep/moe-cpu-offload-data-paths.md`](../prep/moe-cpu-offload-data-paths.md) §9
* Related: ADR-0002, ADR-0003, ADR-0007, ADR-0043