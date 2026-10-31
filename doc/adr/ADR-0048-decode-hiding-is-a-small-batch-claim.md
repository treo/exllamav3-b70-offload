# ADR-0048: The offload is hidden at decode only at small batch

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `decode`, `batch`, `scope`, `expectation`

## Context

Most of this plan's headline numbers are batch-1 numbers, and the phrase that carries them is "the offload
is hidden behind the parent's own per-layer work". That phrase is true, and it is also bounded in a way a
reader can easily miss.

The parent's per-layer time at batch 1 is dominated by weight reads, which do not grow with batch. The card's
per-layer work is the union of the experts that the batch's rows touch, and that union grows almost linearly
with rows. On Qwen3.8 the ratio between the two goes from 4.9 times of headroom at batch 1, to 1.3 times at
batch 4, to 0.5 times at batch 8, where 72.7 of 512 experts are touched per layer. Recomputed against the
measured kernel cost rather than a byte rate, the card becomes the binding worker from about batch 4 onward and
never loses that place: at batch 256 the aggregate model gives 1739 tokens per second against a parent leg of
2107 µs per layer.

So the same configuration is a latency optimization at batch 1 and a throughput engine at batch 32. Those need
different acceptance tests, and only one of them is "hidden".

## Decision

We will state every decode hiding claim with its batch. The shipping claim is that the offload is hidden at
batch 1 through about batch 4, and that past that point the card is the binding worker, so aggregate throughput
is `rows / (layers x union(rows) x resident share x expert bytes / rate)` and is a property of the card's byte
rate rather than of overlap. We will report decode at batches 1, 2, 4, 8 and 16 in the harness, and gate E9
requires the measured crossover batch to agree with the predicted one within about 2 times.

## Consequences

Positive:

* The plan stops promising one property where it delivers two, and each has its own test.
* It makes the scaling behaviour predictable rather than surprising: adding cards multiplies throughput past the
  crossover, because the bytes are already deduplicated by the bucketing of ADR-0029.
* It tells the operator which knob matters in which regime: placement quality at batch 1, and card count plus
  grid order at large batch.

Negative:

* A large share of the published numbers in this plan are batch-1 numbers, and each one now needs its batch
  stated beside it.
* The crossover batch is modelled from measured rates rather than measured end to end, so gate E21 can move it.
  If it arrives earlier or flatter than predicted, the per-step byte cost is worse than the footprint-matched
  rate implies.
* The locality rescue of ADR-0028 is worth nothing at batch 1, where the parent already binds, and that is the
  regime most of the decode tuning was done in.
* More rows do not rescue a model that keeps a residue. The projection for the densest local recipe, 6.05 bpw,
  falls from 156 tokens per second at batch 4 to 146 at batch 8, because the CPU term climbs alongside the card's
  term. Gate E21 measures that curve, and the fix there is placement rather than concurrency.

Neutral:

* The one point where the offload is genuinely free is also the point where the card contributes least. That is
  not a defect of the port. It is what the arithmetic of two fast homes implies.

## Alternatives considered

* Keep the unqualified "hidden at decode" claim: rejected, because it is a small-batch statement and it was
  written before the rows axis existed.
* Quote only the batch-1 figure and state the rest as future work: rejected, because the batch axis already
  changes a build decision, which is whether the large-rows schedule of ADR-0029 exists at all.
* Treat aggregate throughput as the single target: rejected, because a deployment that serves one interactive
  user lives entirely in the regime where the parent binds and the card is free.

## Links

* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §4, §12 rows "the offload hides at decode" and
  "decode figures are b=1 figures"
* [`notes/b70/out_operating_point.txt`](../../notes/b70/out_operating_point.txt),
  [`notes/b70/out_concurrency.txt`](../../notes/b70/out_concurrency.txt),
  [`notes/b70/plan_concurrency.py`](../../notes/b70/plan_concurrency.py)
* [`doc/port/b70-harness.md`](../port/b70-harness.md) gates E9, E21
* Related: ADR-0011, ADR-0026, ADR-0028, ADR-0029, ADR-0037