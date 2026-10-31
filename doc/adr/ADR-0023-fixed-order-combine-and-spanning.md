# ADR-0023: Home partials combine in a fixed order, and spanning is the normal case

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `numerics`, `protocol`, `placement`

## Context

With one home per expert, a row whose picks live in more than one home is computed in pieces. The
spanning fraction, written `sigma`, is the share of rows that need more than one piece. The planner puts
`sigma` at 92 to 99 percent for every model that keeps a CPU residue, and at 99.2 percent for GLM on one
card. It is not an edge case. With eight to ten picks per row spread over three homes, a row that has any
chance of a residue pick almost always has one.

Two designs are available for putting the pieces back together. An atomic accumulation into one output is
shorter to write and destroys repeatability, because the arrival order changes between runs. A fixed-order
sum preserves it, at the cost of one partial buffer per home. The project treats bit-identical repeated
calls as an invariant, because it is what makes greedy replay debuggable.

The independence assumption behind the analytic prediction of `sigma` was measured rather than assumed. On
real cross-session draws the closed form predicts 32.2 distinct experts per layer at batch 4 against 32.1
measured, and 18.4 against 18.2 at batch 2. Pooling sessions adds about 2 percent, and pooling prose with
code adds about 10 percent.

## Decision

We will derive routing from membership: a home gets a job for a row when it holds at least one of that
row's picks, its id list is masked to local indices with the existing sentinel for everything else, and the
final output is the sum of the home partials in a fixed order, parent, then card, then CPU. We will use no
atomics in that sum. We will report `sigma` per layer as a first-class placement metric, and gate E13
requires the offline prediction and the live measurement to agree within 10 percent.

## Consequences

Positive:

* Repeatability survives the third home, so the determinism gate extends to a three-way row without new
  arithmetic.
* The existing mechanism carries it: the sentinel translate, the per-row device count, and the partial add in
  the split combine are all in production today. What is new is only that a row can appear in two or three
  jobs.
* The cost of spanning is small and known at decode: one extra payload of about 12.5 KiB, roughly 0.9 µs of
  link, plus one extra handshake of about 6 µs per layer, which is about 0.33 ms per token against a 10 to 30
  ms token.

Negative:

* At prefill, spanning is not secondary. The same doubling applies to thousands of rows on a link-bound path,
  so the activation byte model must use rows times one plus `sigma`, which is roughly double the single-home
  figure whenever a residue exists.
* The three-way combine is a permanent path rather than a corner, so it needs its own fixture and its own
  scoring.
* A co-location pass cannot remove the spanning, because capacity-driven homes are not separable by pick
  co-occurrence. `sigma` falls only as capacity rises: 99 to 79 percent from one card to three.

Neutral:

* The co-location knob ships as an experiment, and gate E13 promotes or deletes it.

## Alternatives considered

* Atomic accumulation into a single output: rejected, because arrival order changes the result and breaks the
  determinism invariant for a saving of one buffer.
* Replicate experts so no row spans: rejected as a default, because it trades capacity, which sets the
  residue, for locality, which is worth microseconds at decode. Gate E20 can revisit it. See ADR-0009.
* Assign whole rows to one home: rejected, because a row's picks are distributed across homes by
  construction unless one home holds every expert.
* Estimate `sigma` from an independence model only: rejected as the sole source, because the same class of
  shortcut, collapsing a distribution before taking an order statistic, has produced three separate errors in
  this plan. See ADR-0038.

## Links

* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §3 P4, §4a
* [`notes/b70/out_live_trace.txt`](../../notes/b70/out_live_trace.txt),
  [`notes/b70/analyze_live_trace.py`](../../notes/b70/analyze_live_trace.py)
* [`doc/port/b70-harness.md`](../port/b70-harness.md) gate E13
* Related: ADR-0009, ADR-0011, ADR-0033, ADR-0038

## Amendment

An earlier draft priced a spanning row at decode and generalised the conclusion to prefill. The two phases
differ by three orders of magnitude in row count, and the prefill case is now stated separately above.