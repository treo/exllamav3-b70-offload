# ADR-0025: Transfer is a first-class cost term, not overhead

- Status: Proposed
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `cost-model`, `prefill`, `link`, `open-question`

## Context

Every prefill projection in this plan until recently charged expert work and treated everything else as one
non-expert floor of about 1992 ms per 4096-token chunk. Decomposing that floor by kernel bucket changed what it
means. At a split of 256 experts on the parent, 756 ms of the 1922.9 ms floor, 39 percent, is the offload path's
own copy traffic. Homing 192 more experts adds 2999 ms of copy and 8 ms of real work. At 4.05 bpw, copy is 8886
ms, or 77 percent of device time. See [`notes/b70/out_prefill_decomp.txt`](../../notes/b70/out_prefill_decomp.txt).

Independent support comes from the shipped CUDA kernel: its unswizzle calls go 572, 2518 then 5409 as local
experts carry about 160 to about 640 rows each against a 128-row fused capacity. The production path pays the
same per-bucket arithmetic that the card's cost model carries, and it pays it as traffic.

The card replaces the CPU's compute. It does not automatically replace that traffic. If activations still leave
the parent, land in pinned host memory and go on to the card, the tax is inherited, and much of the revised
prefill upside goes with it. This is the one remaining measurement that can move the headline number, and it
bounds it in both directions.

## Decision

We will carry an explicit copy term, per homed expert and per phase, in every prefill and offload projection.
We will price the card's activation path before we quote its expert rate. Three routes are candidates, and all
three are open:

* A host-staged two-hop transfer, at 13.4 GiB/s in and 42.6 GiB/s of host read.
* A single copy, if any cross-vendor peer path exists on this root complex.
* The existing round trip, batched per layer instead of per assignment.

This record stays proposed until one of the three is measured on the card.

## Consequences

Positive:

* The headline prefill figure becomes honest in both directions. Real model work is about 1.15 s per
  4096-token chunk, so the ceiling is higher than the earlier floor implied, and the sign of the gain now
  depends on a named quantity rather than on an assumption.
* The plan's priority order changes in a useful way: the highest-value measurement is above any remaining kernel
  work, and it is an instrument question rather than a tuning question.
* The card's own activation path, fp16 output and card-side partial summation move from options to requirements
  at large batch, where the computed activation share is 31 percent of the card's time.

Negative:

* The flagship prefill multiplier stays a projection, not a promise, and is written as one in every summary that
  uses it. See ADR-0017.
* Closing it needs code, not a probe: a card-side staged buffer and link instrumentation. That is the reason it
  is the first implementation-phase measurement rather than a planning-phase one.
* The measured zero-interference result covers card work in card-resident memory only. Card transfer concurrent
  with CPU-home streaming of host DRAM has never been measured, and that pairing is exactly what the two-hop
  route depends on, so the parallel-maximum balance rests on an unproven assumption in this regime.

Neutral:

* If a home can keep activations entirely on device, the tax disappears and ADR-0017's combined floor improves
  rather than degrades.

## Alternatives considered

* Fold copy into the non-expert floor as before: rejected, because it is 39 to 77 percent of that floor and it
  scales with placement rather than with the model.
* Assume the two-hop cost and move on: rejected, because it bounds the headline number in both directions and the
  assumption is the cheapest thing in the plan to test once the engine exists.
* Plan on cross-vendor peer-to-peer: rejected as a plan, because it is unproven on this root complex. It stays a
  candidate route, and a refusal costs nothing but the attempt.

## Links

* [`doc/port/b70-decisions.md`](../port/b70-decisions.md) D24
* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §11, first item
* [`notes/b70/out_interference.txt`](../../notes/b70/out_interference.txt),
  [`notes/b70/bench_parent_prefill.py`](../../notes/b70/bench_parent_prefill.py)
* Related: ADR-0017, ADR-0020, ADR-0021, ADR-0036, ADR-0037, ADR-0047