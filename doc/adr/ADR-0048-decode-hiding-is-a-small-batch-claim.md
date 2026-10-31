# ADR-0048: The offload is hidden at decode only over part of the batch range

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `decode`, `batch`, `scope`, `expectation`

## Context

Most of this plan's headline numbers are batch-1 numbers, and the phrase that carries them is "the offload
is hidden behind the parent's own per-layer work". That phrase holds at small batch, and it stops holding as rows grow.

The parent's per-layer time at batch 1 is dominated by weight reads, which do not grow much with batch, plus a
per-sequence term that does. The card's per-layer work is the union of the experts the batch's rows touch, which
grows almost linearly with rows at first and then flattens as routing's support saturates. Put the two measured
curves side by side on Qwen3.8 at 2.68 bpw, with the parent leg engine-measured at 195.6 µs and the card priced
from its measured kernel costs, and the binding worker changes twice. The parent binds at batch 1 through 8, with
5.2 times of headroom at batch 1. The card binds from batch 16 through 64. The parent binds again at batch 128 and
above, because its own state and key-value traffic per sequence grows with rows too.

The recipe moves the boundaries. At 2.05 bpw, where each expert read is cheaper, the card takes over at batch 8 and
keeps the lead through 256. At 6.05 bpw the card binds at batch 16 through 64, and the residue term is non-zero,
which is the case ADR-0012 protects.

## Decision

We will state every decode hiding claim with its batch and its recipe. The shipping claim for Qwen3.8 at 2.68 bpw
is this:

* Hidden with about 5 times of headroom at batch 1.
* Still hidden at batch 8, where the parent leg is 237 µs against the card's 202 µs.
* The card is the binding home between batch 16 and 64.
* The parent is the binding home again from batch 128, at 1721 µs against the card's 1262 µs.

We will report decode at batches 1, 2, 4, 8, 16, 32, 64, 128 and 256
in the harness, and gate E21 requires the measured binding worker to match the predicted one at each of those
points rather than only the throughput.

## Consequences

Positive:

* The plan stops promising one property where it delivers three, and each has a test point.
* Naming the binding worker at each batch is the decision that tells an operator what a second card buys. It buys
  throughput in the middle band, where the card binds, and little at batch 1, where the parent binds.
* Checking the prediction by which worker binds is stronger than checking throughput within a factor, because a
  wrong curve can still land inside a loose throughput band.
* It states the honest shape of the win: a latency optimization at batch 1, a throughput engine in the middle, and
  a parent-limited case again at very large batch.

Negative:

* The concurrency figures published in the plan, and the ones in the harness gate for E21, come from a run of the
  same planner that predates the fused kernel schedule and the engine-measured parent leg. That run had the card binding
  from about batch 4 with no return of the parent, and lower aggregate throughput at every point. Those places now carry
  a note that the current run supersedes them.
* The middle band where the card binds is exactly the band where a locality or fusion gain pays, so the batch at
  which the card tuning matters is a narrow one at this recipe.
* Aggregate throughput past the crossover is a property of the card's byte rate, so it is bought with cards rather
  than with kernels, and a kernel improvement in the middle band is worth less than the same improvement at
  batch 16.

Neutral:

* The point where the offload is free is the point where the card contributes least. That is not a defect of the
  port. It is what two fast homes imply, and ADR-0011 is the response to it.
* The parent's return as the binding worker at batch 128 rests on an anchored extrapolation of its per-sequence
  terms, which is the least certain number in the comparison. Gate E10 measures the parent leg, and its batch list
  stops at 16 today, so it must extend to 128 and 256 before any decision leans on that boundary.

## Alternatives considered

* Keep the unqualified "hidden at decode" claim: rejected, because it is a single-point statement presented as a
  range, and the range is where the purchase decisions live.
* Predict throughput only, and identify the binding worker as reporting detail: rejected, because the worker
  identity is what determines whether the next improvement is a kernel, a card, or a parent fix.
* Quote the batch range for one reference recipe only: rejected, because the boundaries move by a factor of two
  between 2.05 and 6.05 bpw, which is the recipe range the deployment actually spans.

## Links

* [`notes/b70/out_concurrency.txt`](../../notes/b70/out_concurrency.txt) is the current run, and
  [`notes/b70/plan_concurrency.py`](../../notes/b70/plan_concurrency.py) produces it
* [`notes/b70/out_kernel_split.txt`](../../notes/b70/out_kernel_split.txt) for the large-rows schedule inside the
  middle band
* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §4 and §12, whose concurrency table and rows carry
  the superseded run
* [`doc/port/b70-harness.md`](../port/b70-harness.md) gates E9, E10, E21
* Related: ADR-0011, ADR-0012, ADR-0026, ADR-0028, ADR-0029, ADR-0037
