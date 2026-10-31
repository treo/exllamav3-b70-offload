# ADR-0003: The four-flag handoff protocol carries over unchanged

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `protocol`, `liveness`, `inherited`

## Context

The CPU offload orders all work between parent and worker with monotonic flags in pinned memory, not
with locks and not with framework synchronisation. A slot carries `data_ready`, `done` and `consumed`,
and the weight-staging path adds `stage_done` and `pinned_free`. Twenty-two protocol and liveness
invariants sit on top of that, each with a test in the tree. The list is Level D of the acceptance
criteria in [`doc/prep/port-acceptance.md`](../prep/port-acceptance.md).

The port is a new consumer of this protocol, and the temptation with a new consumer is to design a
cleaner one. The cost of that is concrete: the current protocol has a test suite, a watchdog, and a
history of fixed deadlocks behind it, including the historical "second-prompt freeze". The card adds
capabilities, such as kernels that write host memory directly, that make some of those invariants look
redundant. They are not redundant; two of them exist specifically because a second device can queue a
write that has not happened yet.

## Decision

We will inherit the protocol unchanged: one shared control block, one job ring, four monotonic flags
per slot, sequence numbers in the descriptor, `COMPUTE_GATED` jobs that skip compute and readback,
slot reuse gated on `consumed`, and the parent-side watchdog. Every Level-D invariant gets a card-side
test, and the CPU suite stays green while the card suite is added.

## Consequences

Positive:

* A card job and a CPU job are the same object, so coexistence of both workers needs no new protocol.
* Each invariant already has a test to copy, which makes the Level-D surface cheap to reach.
* Empty jobs stay cheap: with no offloaded expert selected, the layer costs one host spin miss and one
  kernel that exits.

Negative:

* The card inherits constraints it does not need in isolation. The 32-bit flag compare is cyclic, and
  all boundary copies must stay contiguous, because a strided host copy is satisfied at enqueue time
  outside stream order.
* `hi`, `ho` and `topk` must be uniform across registered layers. That is an assertion to add, not an
  assumption to keep. See ADR-0045.
* Adding a card-specific field to a job means adding it to a shared descriptor, so the reserved area
  is the place for it and its size is a real limit.

Neutral:

* The flag width rule is inherited too: 32-bit where the wait compares cyclically, 64-bit where it
  does not.

## Alternatives considered

* Design a card-specific protocol with doorbells and events: rejected, because it would need its own
  coherency evidence, its own deadlock history and its own watchdog, and it would break the
  three-home semantics of `-mcs`, `-mcl` and `-mcpa`. See ADR-0007.
* Keep the ring but replace flags with SYCL events: rejected, because an event wait costs 24.8 µs,
  which is larger than the compute job it would gate. See ADR-0004.
* Gate slot reuse on `done` instead of `consumed`: rejected. With offloaded layers spread over more
  than one device, `done` lets a worker overwrite an output that another device has queued but not
  written.

## Links

* [`doc/prep/port-acceptance.md`](../prep/port-acceptance.md) Level D
* [`doc/prep/moe-cpu-offload-data-paths.md`](../prep/moe-cpu-offload-data-paths.md) §1
* [`doc/port/b70-harness.md`](../port/b70-harness.md) Level D
* Related: ADR-0004, ADR-0005, ADR-0007, ADR-0040