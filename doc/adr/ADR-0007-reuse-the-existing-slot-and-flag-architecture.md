# ADR-0007: The card reuses the existing slot, staging and flag architecture

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `integration`, `engine`, `constraint`

## Context

The engine already contains a heterogeneous worker with the shapes the card needs. In-flight work is
capped by slots, and each slot holds a row capacity. Weight movement is double-buffered through
weight-staging slots. A pinned flag region already has an address map for doorbell and completion.
Workers are registered per model component, which is how a draft head gets its own worker and budget.

The card could use these structures or define its own. Defining its own is faster to write in the first
week and costs more everywhere after that: a second protocol needs its own coherency evidence, its own
slot arithmetic and its own accounting, and the operator-facing flags `-mcs`, `-mcl` and `-mcpa` then
have to describe two systems at once.

Choosing the existing structures imports their limits as hard design constraints. Two of those limits
turn out to explain measurements that had no mechanism before them, which is the strongest evidence
that they are the right ones to reuse.

## Decision

We will build the card path as a second worker behind the existing host object. We will reuse slot
capping, the per-slot row capacity, double-buffered weight staging, the pinned flag region and the
per-component worker key. We will not create a parallel handoff. Where the card needs more in-flight
capacity than a constant allows, that is an engine change to the constant, and the flag-region size is
recomputed in the same commit.

## Consequences

Positive:

* Slot and flag accounting stays single-sourced, and the three-home meaning of `-mcs`, `-mcl` and
  `-mcpa` stays interpretable.
* A draft or MTP head gets a card worker for free, because worker registration is already keyed per
  component. See ADR-0024.
* Two measurements gain a mechanism. In-flight promotion is bounded by two 32 MiB weight slots, which
  is why `-mcpa`'s relief saturates at about eight experts per layer whatever is remote. See
  [`notes/b70/out_prefill_mcpa.txt`](../../notes/b70/out_prefill_mcpa.txt).
* Picks arrive already sorted by expert id on the parent, so the gather the card dispatcher wants is
  partly computed for free.

Negative:

* The card inherits a single reserved host core for submission and flag servicing. Nothing
  synchronous may be added to that core, which is why ADR-0004 exists as a rule and not a preference.
* Two weight-staging slots of 32 MiB cap how many experts move at once. At the measured link rate a
  32 MiB slot takes about 2.4 ms.
* `MOE_FLAGS_SIZE` is derived from slot counts, so raising a slot count without recomputing it is a
  memory-safety bug rather than a tuning mistake.

Neutral:

* The CPU worker's thread-count default of physical cores minus one is deliberate, not naive. The card
  has no thread pool to size, because the card schedules its own engines.

## Alternatives considered

* A separate card-side handoff with its own ring and flags: rejected, because it duplicates the
  protocol surface, doubles the Level-D test set, and needs coherency evidence that took a device loss
  to learn once. See ADR-0006.
* Card submission from the forward thread: rejected, because the reserved core's budget is one core and
  it already carries promotion and memory movement.
* Larger weight-staging slots to unblock promotion throughput: deferred, and treated as an engine
  change with a `MOE_FLAGS_SIZE` recomputation, not as a card-side workaround.

## Links

* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §13
* [`doc/port/b70-decisions.md`](../port/b70-decisions.md) D21
* Related: ADR-0003, ADR-0004, ADR-0014, ADR-0017, ADR-0043