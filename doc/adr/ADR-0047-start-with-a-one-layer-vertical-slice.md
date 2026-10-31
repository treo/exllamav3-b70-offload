# ADR-0047: Implementation starts with a one-layer vertical slice

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `process`, `integration`, `risk`

## Context

Every rate in this plan came from a kernel that never met another workload. Three open questions cannot be closed by another
probe, because they are about composition rather than about components. Whether the parent's waiting behaves as assumed is
the stall question of ADR-0037. Whether the handoff seam described from source is really shallow enough is the integration
question. And whether the plan's arithmetic composes at all, when a live router assigns work rather than a planner
enumerating it, is the question every preceding number has dodged.

One experiment answers all three: route a subset of one layer's experts to the card, behind the existing handoff, with the
kernel that already passes its exactness gate, and print what the model predicted beside what the clock measured. The
design exists and is deliberate about not building anything new: no new kernels, no prefill path, no promotion policy, no
dashboard.

## Decision

We will make the one-layer vertical slice the first implementation deliverable. It runs three configurations on one MoE
layer: a control with nothing on the card, a substitution with the coldest about 64 experts on the card, and a capacity case
with a static hot tier of about 84 and promotion held off. It prints six quantities per configuration at batch 1 and batch
8: wall microseconds per layer, device microseconds, their difference, card time per launch with its idle fraction, the
parent's cost with and without the card present, per-home pick counters, and the predicted value from the joint cost model.
Acceptance is a prediction within 15 percent of measured wall time.

## Consequences

Positive:

* Attribution survives, because the other 47 layers are untouched and the parent's non-expert leg stays a constant.
* Counters come before ratios, which is the specific discipline that catches a placement that silently serves nothing while
  every timing looks healthy.
* The fallback path doubles as the graceful-degradation test: the host spins on the flag with a bounded budget and hands the
  job to the CPU worker if the card is late, so a coherency or starvation problem becomes a performance failure rather than a
  hang.
* A negative result is still a decision. If the slice cannot be built in a few days, the handoff seam is deeper than the
  integration map claims, and that answer changes the plan more cheaply than any measurement would.

Negative:

* It answers nothing about prefill, so the activation path of ADR-0025 stays open after it lands, and the headline prefill
  multiplier stays a projection.
* A batch-dependent error in the prediction means the maximum-over-device-terms balance is structurally wrong and the plan
  needs a queueing model. The slice can produce that outcome, and narrowing the slice does not avoid it.
* One layer cannot expose cross-layer effects such as cache interference between consecutive layers, which ADR-0028 flags as
  plausible and unmeasured.

Neutral:

* The outcome table is written before the run: within 15 percent proceeds kernel-first, a constant offset gains a measured
  stall constant, a batch-dependent offset triggers the queueing revision, a starved card points at the single reserved host
  core, and no picks reaching the card is an integration bug to fix before anything else is believed.

## Alternatives considered

* Build the full decode path first: rejected, because the composition question would then be answered by a system too large
  to attribute.
* Build prefill first: rejected, because it needs the same handoff plus the unpriced activation path, which is the larger
  unknown.
* Simulate the composition from measured components: rejected, because the point of the slice is that a device-only model is
  a lower bound. See ADR-0037.
* Two layers instead of one: rejected, because the second layer buys no new effect and costs the attribution.

## Links

* [`doc/port/b70-slice.md`](../port/b70-slice.md)
* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §13
* [`notes/b70/plan_decode_cost.py`](../../notes/b70/plan_decode_cost.py) `layer_us_joint()`
* Related: ADR-0007, ADR-0026, ADR-0037, ADR-0042, ADR-0046

## Amendment

The slice spec was written after two other first-deliverable candidates, a null-kernel protocol test and a full decode path.
The null-kernel test survives inside it, as the control configuration, because a protocol test with no arithmetic answers the
integration question and none of the composition ones.