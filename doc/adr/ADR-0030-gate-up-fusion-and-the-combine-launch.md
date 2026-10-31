# ADR-0030: Gate and up fuse on a fill test, and the combine stays a separate launch

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `kernel`, `fusion`, `launch-cost`

## Context

Fixed cost is the largest remaining decode term. About 7.8 µs per gate launch and 8.4 µs per down launch is
overhead rather than streaming, which is roughly 24 µs of a 43.6 µs layer at batch 1. Fusing the two independent
gate and up projections into one launch removes one of those overheads, and one combine launch for the pair removes
another.

Fusion is not free, and its two conditions point in opposite directions. A launch fills the device: the card has
about 2048 thread slots, and a gate launch at split-K 1 with ten experts occupies 800 of them, so the two separate
launches run half idle. Fusing them reaches 1600 and is worth 49 percent in occupancy terms. Once each launch
already fills the machine, fusion buys nothing and leaves only its cost, which is two independent weight streams
interleaved at about plus 7 percent. The streams also compete for cache: a fused launch's live footprint is the sum
of both projections, so it stops paying when twice the experts per launch times the byte size overflows a 24 MiB
cache while a single stream still fits.

## Decision

We will fuse gate and up only when the measured joint dispatch table says so, and the table is consulted once per
model and rate, at one row, and applied at every row count. When the fused form is selected, split-K drops to the
value that keeps the launch filled, because fusion and split-K buy the same resource. We will use one combine launch
for the fused pair, with one work-item producing both projections and a grid sized by output count. We will not
merge the two combines into one launch with a doubled grid, which measured slower by 1.9 to 3.8 µs.

## Consequences

Positive:

* Where the table selects fusion the gain is real and grows with rows: 1.04, 1.13 and 1.17 times at rows 1, 8 and 16,
  bit-exact against each projection's own reference. The layer goes from 42.6 to 40.9 µs at one row, and from 72.6 to
  64.8 µs at 16, in two gemm launches per layer instead of three.
* The grid-shape lesson is reusable: the naive merge lost, four explanations were tested and refuted, and the cause
  was isolated by per-stage attribution rather than by theory.
* Fusing the activation function into the combine costs under 0.2 µs of its own time and removes an elementwise
  pass.

Negative:

* The byte test cannot predict the sign at the edges of the penalty band. At 2 bpw with 32 experts fusion won by 1.32
  times inside the predicted band, and at 3 bpw with 16 experts the sign flipped between split-K 1 and split-K 2 at
  identical bytes. The table is thus the authority and the byte test is a warning.
* A single global fusion flag is a bug. The GLM geometry, with 128 column tiles, must not fuse, and the worst penalty
  measured inside the band is 1.27 times at 3 bpw and 1.88 times at 6 bpw.
* The joint table is dense at 3 bpw and sparse at 2, 4 and 6, so cells outside it fall back to the older
  per-projection path and must print that they did.

Neutral:

* The penalty band's depth increases with rows, from 0.76 times at one row to 0.90 times at 16, while its edges do not
  move. That is why one decision per model and rate is conservative rather than lazy.
* The table chooses both knobs together because a rule that fixes one and tunes the other was sampled at one expert
  count. At E of 2 the best fused schedule sits at split-K 4, so a rule that fixes split-K misses the winner at small
  expert counts.

## Alternatives considered

* Always fuse: rejected, it loses up to 1.27 times where both launches already fill and the pair overflows cache.
* Never fuse: rejected, it gives up 1.17 times at 16 rows and one launch per layer, which is most of the remaining
  fixed-cost budget.
* Decide fusion per batch shape: rejected on measurement, because the band edges do not move with rows, so a per-shape
  rule adds a decision without adding accuracy.
* Fuse the combine into the producer with atomics, and fuse across the gate-to-down dependency: both rejected. See
  ADR-0035.

## Links

* [`doc/port/b70-decode-closeout.md`](../port/b70-decode-closeout.md) D8, D9
* [`notes/b70/out_e25_fuse.txt`](../../notes/b70/out_e25_fuse.txt),
  [`notes/b70/out_e25b_combine.txt`](../../notes/b70/out_e25b_combine.txt),
  [`notes/b70/out_fusion_rows.txt`](../../notes/b70/out_fusion_rows.txt),
  [`notes/b70/out_fusion_penalty_k.txt`](../../notes/b70/out_fusion_penalty_k.txt),
  [`notes/b70/out_egrid.txt`](../../notes/b70/out_egrid.txt)
* [`notes/b70/plan_decode_cost.py`](../../notes/b70/plan_decode_cost.py) `best_launch()`
* Related: ADR-0026, ADR-0031, ADR-0032, ADR-0035
