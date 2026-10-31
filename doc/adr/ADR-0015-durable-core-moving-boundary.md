# ADR-0015: The card holds a durable core, and only the boundary moves

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `placement`, `promotion`, `capacity`

## Context

A second accelerator can serve two purposes. It can be a faster place to compute an expert that
promotion already selects, or it can hold so many experts that promotion stops mattering. The measured
behaviour of promotion on the parent decides between them.

Under `-mcpa`, promotion counters show 403 promotions and 403 demotions in one 4096-token prefill at a
2048-token chunk, which is a set that oscillates rather than accumulates. In the separate slope fit, across three
different split sizes, the promoted count stays at 383 to 390, about eight experts per layer, whatever number of
experts is remote. The relief per marginal remote expert in that fit decays from 4.96 ms to 3.88 ms. The two
counters come from different arms of the same instrument, so a quote carries its arm with it. A mechanism whose
action count does not scale
with the problem is a capacity mechanism, not a scaling one.

Independently, dwell was measured on validity-gated traces. A top-84 tier fitted on the first 128 tokens
of a Qwen run had one layer of 48 halve within 512 tokens. Survival by rank band was 94.1 percent at the
core, 77.0 percent in the middle and 55.3 percent at the boundary. Refreshing the tier every interval
recovers only 4.9 points of picks, and the residual 20 percent of picks still miss because 84 of 512
experts cannot serve the tail. That residue is a capacity shortfall, not a policy failure.

## Decision

We will size the card tier as capacity for a large, static core and let only its boundary move. The core
is frozen, the boundary moves with hysteresis, and the admission budget is rank-dependent: tight at the
core and loose at the edge. We will not use the card as a faster ranking target for an existing promotion
policy.

## Consequences

Positive:

* The design stops paying transfer for a 5-point gain, which is what a dynamic tier measures at.
* A card holds 84 of 288 GLM experts per layer, or any model's half-mass tail for 1.4 to 5.3 GiB, so the
  capacity argument is available rather than aspirational.
* Coarse moves with hysteresis suit the measured cost asymmetry: an admission is 0.09 ms on Qwen and
  0.68 ms on GLM, which is cheap once per expert and expensive at a few ms per token of reconsideration.

Negative:

* A frozen core is wrong for a workload whose hot set changes outright, such as a switch from prose to
  code. Gate E11's corpus-switch arm is the test for that, and the mitigation is hysteresis plus a
  budget, not a faster policy.
* The dwell evidence is thin on the axis that matters most. Two valid traces exist, at 512 and 384 tokens,
  and no trace reaches a session boundary, so the horizon a static tier must survive is unmeasured.
* A rank-dependent budget is one more policy parameter, and its shape is set from two survival numbers.

Neutral:

* A third of the apparent churn measured earlier was estimator sample size rather than routing: adjacency
  between consecutive windows rises from 0.402 at 16 tokens to 0.688 at 128 tokens.
* This record is reopened by a multi-session dwell measurement that shows the core does not persist, or by
  a deployment whose traffic is dominated by abrupt topic switches.

## Alternatives considered

* Use the card as a faster promotion target: rejected, because ranking relief is bounded by the window the
  parent can spare, while capacity relief scales.
* Dynamic placement on a short interval, the parent's swap-policy shape: rejected, 4.9 points of
  gain for the transfer cost, and the parent's own promote hook already costs 2 to 3 ms per token.
* Freeze the tier with no boundary motion at all: kept as a test configuration, not as the default,
  because boundary survival is 55 percent rather than 94 percent.

## Links

* [`doc/port/b70-decisions.md`](../port/b70-decisions.md) D16
* [`doc/port/b70-tiering.md`](../port/b70-tiering.md) §3 for the 403 pair and §7 for the slope-fit counters
* [`notes/b70/out_dwell.txt`](../../notes/b70/out_dwell.txt),
  [`notes/b70/out_prefill_mcpa.txt`](../../notes/b70/out_prefill_mcpa.txt),
  [`notes/b70/analyze_dwell.py`](../../notes/b70/analyze_dwell.py)
* [`notes/b70/LESSONS.md`](../../notes/b70/LESSONS.md) item 83, item 89
* Related: ADR-0014, ADR-0017, ADR-0018, ADR-0039