# ADR-0006: SYCL atomics never touch the shared region

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `protocol`, `memory`, `correctness`

## Context

The shared control region is host memory that the parent pins, the engine registers with its context,
and three parties read and write: the parent's CUDA kernels, the card's kernels, and host threads. The
natural SYCL tool for a flag is `sycl::atomic_ref` with an acquire-release ordering at system scope.

That tool destroys the device on this driver. An `atomic_ref` over a pointer obtained from
`register_host_memory` produces `UR_RESULT_ERROR_DEVICE_LOST` at every scope tested, and the loss is
not clean: the queue is poisoned and the failure can surface far from the call that caused it. Plain
volatile stores, and volatile stores followed by `sycl::atomic_fence(acq_rel, system)`, work. This was
found by elimination across cache-state hypotheses that measurement then disproved, and the disproved
theory is kept in the tree because the reasoning that led to it is the useful part.

The same class of silent failure appears twice more in the probe work, which is why the rule is about
assertions and not only about atomics. A kernel written as `p[i] = seed + i` over a `sycl::id<1>`
compiles, reports success, and stores nothing. Index arithmetic must be spelled out.

## Decision

We will not use `sycl::atomic_ref`, or any library atomic that lowers to the same path, on the shared
region at any scope. The ban covers host pointers obtained from `register_host_memory`. It does not
cover card memory, where card-side atomics are unaffected, and it does not cover the fence, which is a
SYCL construct and is required. Flags are fenced volatile stores. The only ordered atomic access on the
shared region is a host-side read by the engine thread. Every card kernel test compares every payload
word it wrote, and never a return code or a flag alone.

## Consequences

Positive:

* One publication mechanism exists, so the ordering argument is made once instead of per kernel.
* The negative case is a test, not a comment. A regression into a library atomic fails a gate rather
  than losing a device during a customer run.
* Every-word assertions catch the silent class of bug: the kernel that "succeeded" and wrote nothing,
  and the kernel that wrote the wrong value and returned no error.

Negative:

* Code that wants a lock-free counter on shared memory has to go elsewhere. Card-side atomics are fine
  in card memory, and the payload-publish protocol is a store, not an increment.
* A fenced volatile store is easy to write in the wrong order: fence after stores, then flag. The
  10 000-round ordering test is what holds that.

Neutral:

* The rule is driver-version-specific in its cause, so the negative test stays in the per-commit set.

## Alternatives considered

* `sycl::atomic_ref` at device or semaphore scope: rejected, both forms lost the device.
* `sycl::streaming_store` or write-combining intrinsics for the payload: rejected as unnecessary,
  because plain volatile stores already reach host memory at the measured rate.
* Assert only the flag and sample the payload in review: rejected, because the two known silent
  failures both passed a flag-only assertion.
* Keep a host-side spin lock over the region: rejected, because the parent must never block, and the
  protocol needs no mutual exclusion between a writer and a reader that own different fields.

## Links

* [`notes/b70/probe_stores.cpp`](../../notes/b70/probe_stores.cpp) case 7,
  [`notes/b70/out_stores.txt`](../../notes/b70/out_stores.txt)
* [`notes/b70/probe_coherency.cpp`](../../notes/b70/probe_coherency.cpp),
  [`notes/b70/out_coherency.txt`](../../notes/b70/out_coherency.txt)
* [`notes/b70/LESSONS.md`](../../notes/b70/LESSONS.md) item 4, item 4a
* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §10a
* Related: ADR-0005, ADR-0040