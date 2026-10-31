# ADR-0037: Every performance claim reports wall time and device time

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `cost-model`, `method`, `stall`

## Context

The plan's balance is a maximum over home terms, and every term in it is device work. That is sound only when each home
is busy for the whole time its device work takes. On one of the two reference models it is not.

At batch 1 on GLM, the measured step costs 1392.2 µs per layer of wall time and 406.7 µs of device time, so 71 percent
of the step is exposed waiting, and the wait is on the CPU worker. Qwen3.8 stalls far less, which is why a device-only
model passed every test thrown at it on that model. The same gap explains a dispute that could not be settled inside the
device view: a bottom-up floor and a window-calibrated estimate differed by 2.1 times and both were defensible, because
one measured a floor and the other absorbed waits and per-token overheads.

## Decision

We will report wall time and device time for every parent number, and we will publish their difference as a named
quantity, stall. A device-only cost model is a lower bound on the card's benefit and is labelled as one, never a
forecast. The vertical slice's acceptance test is against measured wall time, within 15 percent, and if the model is
optimistic by more than that it gains an explicit stall term fitted from that run and revalidated against the independent
wall-and-device pair already recorded for GLM.

## Consequences

Positive:

* The direction of the model's error is known, so the card's value on a stalling model is understated rather than
  overstated. GLM is the strongest case in the plan partly because of this term.
* One run, the vertical slice, either closes the term or tells us the balance is structurally wrong.
* Reporting the pair retires the argument between the two earlier parent estimates, since they measured different
  quantities and the labels now say which.

Negative:

* Wall time is influenced by everything the device model ignores: the sampler, the language-modelling head, graph
  capture, host scheduling. A fitted stall term risks becoming a bag that holds every unexplained difference.
* If the gap turns out to depend on batch, then a maximum over device terms is structurally wrong and the plan needs a
  queueing model. That is a larger revision than any kernel change here, and this record does not rule it out.
* The zero-interference measurement does not cover this. It showed no slowdown for card work in card-resident memory, and
  says nothing about waiting.

Neutral:

* The interim method is level measured, shape anchored, and every extrapolated cell is marked as such.

## Alternatives considered

* Quote device time only, and treat waiting as an operator concern: rejected, because wall time is what a user waits for
  and what the split rule of ADR-0011 is computed against.
* Model the stall as a queue from first principles: deferred, not rejected. It becomes mandatory if the measured gap is
  batch-dependent, and it cannot be fitted from fewer than one joint run.
* Fold stall into the parent's device term by inflating it: rejected, because it would hide a structural finding inside a
  constant and would mis-price every configuration that removes the wait.

## Links

* [`doc/port/b70-decisions.md`](../port/b70-decisions.md) D19
* [`notes/b70/out_engine_step.txt`](../../notes/b70/out_engine_step.txt) §11
* [`doc/port/b70-slice.md`](../port/b70-slice.md) acceptance row
* [`notes/b70/LESSONS.md`](../../notes/b70/LESSONS.md) item 61
* Related: ADR-0011, ADR-0025, ADR-0036, ADR-0039, ADR-0047