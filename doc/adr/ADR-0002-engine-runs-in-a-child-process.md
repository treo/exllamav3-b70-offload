# ADR-0002: The card engine runs in a child process

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `boundary`, `process`, `liveness`

## Context

The engine is the code that talks to the card: it watches for jobs, moves payload, starts kernels and
publishes completion. It can live in the parent process, on a thread beside the forward thread, or in
a child process. The CPU worker already uses a child process, and that choice carries three problems
with it: enqueue cost moves off the forward thread, a device fault kills only the child, and the
load pipeline can be reused.

One capability decides whether the child-process option is open at all. The child must map the
parent's shared-memory segment and register it with its own context, so a card kernel can read the job
and write the result into memory that the parent and the parent's GPU also see. A thread in the parent
process avoids that requirement, but keeps the other three problems.

A second constraint is directional and measured: `cudaHostRegister` refuses memory that the xe driver
pinned. Registration therefore has one legal owner, and it is the parent.

## Decision

We will run the engine in a child process, on a `multiprocessing.shared_memory` segment that the
parent pins and registers. The parent owns and registers the control region. The engine never
allocates memory that the parent must see. The engine owns all card memory: expert weights, staging
and scratch.

## Consequences

Positive:

* SYCL enqueue cost, about 2 µs per submission and about 20 µs when a blocking wait sneaks in, leaves
  the forward thread. That thread already costs 3.6 ms per token.
* A wedged queue or a lost device kills the child. The existing parent-side watchdog then unblocks
  pending stream waits and raises on the next `begin_pass`, instead of the process hanging.
* The child reuses the `("layer", spec)` pipe messages, the acknowledgements and the deferred
  safetensors reads that feed the CPU worker today.
* Measured: `notes/b70/probe_crossproc.py` passes 10 of 10. A card kernel in the child writes payload
  and a flag that both the parent and a parent DMA observe, and a parent stream memop is visible to a
  kernel in the child. Raw data: `notes/b70/out_crossproc.txt`.

Negative:

* The result depends on driver behaviour that can change. The attach test therefore runs per commit,
  not once.
* Two processes now hold placement state and both must agree. The parent is the single writer.
* Debugging spans a process boundary, so the engine needs its own log file rather than the parent's
  standard output.

Neutral:

* The in-process thread remains the documented fallback for a machine that refuses the registration.

## Alternatives considered

* Engine as a thread in the parent: rejected as the default, because enqueue cost lands on the
  forward thread and a device fault takes the model down with it. Kept as the documented fallback.
* Engine as a long-lived daemon shared by several models: rejected, because placement state, the
  pinned budget and device ownership then need an arbitration layer that nothing here requires.
* Parent pins, child also pins: impossible, because `cudaHostRegister` refuses xe-pinned memory and
  the reverse mapping is the one the protocol needs. See `notes/b70/out_cross.txt`.

## Links

* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §6
* [`notes/b70/README.md`](../../notes/b70/README.md) (cross-process row)
* Related: ADR-0001, ADR-0004, ADR-0046