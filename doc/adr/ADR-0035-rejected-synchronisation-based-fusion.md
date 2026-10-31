# ADR-0035: Rejected: synchronisation-based fusion

- Status: Rejected
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `kernel`, `fusion`, `synchronisation`, `refuted`

## Context

Removing a launch is the obvious way to attack the 7.8 and 8.4 µs of fixed cost per projection. Three designs remove a
launch by adding synchronisation instead, and on this device synchronisation repeatedly costs more than the traffic it
avoids.

The first design folds the combine kernel into the producer with per-expert atomic adds, a fence and an arrival
counter. The second runs all three projections in one launch, which needs a device-wide barrier because down reads what
gate and up wrote. The third has a compute kernel watch the host for work instead of being handed work by a host thread.

## Decision

We will not fuse across a data dependency, and we will not use atomics to publish a partial result. The combine stays a
separate launch, and the gate-to-down dependency stays a launch boundary. Work is merged only where it is embarrassingly
parallel, as in ADR-0030. A dependency may be closed inside one work-group, where the barrier is free, only when the
resulting groups still fill the device.

## Consequences

The measured prices, and the mechanism each one exposes:

* Fused combine with atomics: plus 6.4 to 8.4 µs on gate and plus 13.6 to 15.8 µs on down, where the round trip it
  removes was worth 1.9 µs. The atomic protocol alone costs about 8.7 µs.
* One launch for all three projections: a device-wide spin barrier costs 1.6 µs at 256 work-items, 2.5 µs at 1024 and
  6.2 µs at the 2048 capacity, and beyond capacity it is illegal by API because co-residence is not promised. Against
  that, a launch costs about 2.9 µs. A barrier confined to one work-group measures free, between minus 0.03 and plus 0.22
  µs, and the intermediate activation fits local memory comfortably. That is why the barrier was not the real reason.
  The real reason is fill: the backend caps this kernel family at 64 work-items per group, and one expert's dependency
  closure is 40 gate and up tiles plus 160 down tiles, so a group per expert puts 640 items in flight instead of 1600 at
  ten experts. The same gate and up work costs 20.8 µs at 1600 items and 33.7 µs at 800, so the design would have traded
  about 60 percent of the machine for 6 µs of launches.
* A kernel polling the host for work: posting a doorbell where a pinned flag works costs 4 to 17 µs per launch, and a
  compute kernel that spins on the host inside a layer adds 24 to 54 ms per layer on top of the traffic.

The reusable rule from this set is a ranking, not a ban: a launch is cheap, group-scoped coordination is free,
device-wide coordination is expensive, and the loss of fill that a coarse dependency forces is the most expensive of
all.

## Alternatives considered

These are the rejected designs, each with the argument that motivated it:

* Fuse the combine into the producer to delete a launch and a round trip: rejected, the protocol costs more than the
  round trip, and it would also break the determinism rule of ADR-0033.
* Fuse all three projections in one launch to delete two launches: rejected, and closed rather than deferred. At 16 rows
  the fill penalty falls from 62 to 36 percent and still dwarfs the launches saved, and fill stops binding only past the
  16-row bucket the engine splits on anyway.
* Fuse the two independent gate and up chains inside one item body: rejected, 42 to 125 percent slower at low rates,
  because the two chains compete for the same scoreboard slots and the fused form needs twice the accumulators. The
  grid-level fusion that won, in ADR-0030, keeps one projection per item for exactly this reason.
* A resident kernel that removes the submission entirely: not rejected on principle, but gated on a measured 20 µs per
  token saving. See ADR-0008.

## Links

* [`doc/port/b70-decode-closeout.md`](../port/b70-decode-closeout.md) D2, D10
* [`notes/b70/out_e25c_barrier.txt`](../../notes/b70/out_e25c_barrier.txt),
  [`notes/b70/out_e25c_groupscoped.txt`](../../notes/b70/out_e25c_groupscoped.txt),
  [`notes/b70/probe_barrier.cpp`](../../notes/b70/probe_barrier.cpp),
  [`notes/b70/probe_groupfused.cpp`](../../notes/b70/probe_groupfused.cpp)
* [`notes/b70/LESSONS.md`](../../notes/b70/LESSONS.md) item 43, item 60
* Related: ADR-0004, ADR-0006, ADR-0008, ADR-0023, ADR-0030, ADR-0033

## Amendment

D10 was first rejected on the barrier cost. The barrier argument was wrong on its own terms, because a group-scoped
barrier is free, so the record now leads with the fill cost that measurement actually supports. The rejection stands;
the reason does not resemble the original.