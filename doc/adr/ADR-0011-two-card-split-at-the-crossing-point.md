# ADR-0011: Set the two-card split at the crossing point, not by equal shares

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `placement`, `load-balance`, `prefill`, `decode`

## Context

Two accelerators hold experts and both do the arithmetic. The intuitive split is half the experts, or
half the bytes, or half the picks. None of those is the objective. The parent's expert work is added on
top of its non-expert work, because both run in the parent's stream. The card's expert work runs in
parallel with the parent, because the card has its own memory and engines. The cost per layer is the
larger of the two terms, so the right split is where the two terms cross.

The planner had this wrong in a way that is worth recording, because the wrong form looked reasonable:
its greedy balance compared the card's bytes against the parent's bytes, which returns an equal-byte
share independent of the parent's non-expert cost. For Qwen decode that is 0.61 against a measured
optimum of 0.79, so it under-filled the card by 18 points of expert share at exactly the operating point
the rule exists for.

## Decision

We will put expert work on the card up to the point where the card's term equals the parent's term
including its own expert share. If the card's whole expert leg already hides under the parent's
non-expert time, we give it everything and leave the parent no expert bytes, because any byte handed
back only lengthens the critical path. We never use an equal-share rule.

## Consequences

Positive:

* The rule reproduces the measured optima and never loses where it degenerates: card share 1.00 at rows
  4 or fewer, 0.86 to 0.88 at rows 8, 0.77 to 0.78 at rows 16 on Qwen3.8. An equal split costs 21 to 72
  percent at rows 4 or fewer, 13 to 15 percent at rows 8, and 26 to 28 percent at rows 16. See
  [`doc/port/b70-tiering.md`](../port/b70-tiering.md) §5.
* It explains why GLM's answer differs instead of contradicting itself. GLM's geometry gives the card
  84 to 97 GB/s on prefill shapes against the parent's 190, so the crossing point sits near a half
  share, and splitting is mandatory: 296 µs per layer against 574 µs all-card.
* Prefill never splits. The card's measured 734 ms expert leg hides under a parent non-expert term of
  1166 ms of real work even after the transfer correction, and every byte moved back to the parent adds
  to the critical path monotonically.
* A hidden cost became visible: a token whose picks straddle both homes duplicates one activation copy.
  At 4096 tokens that is 140 ms per chunk, or 19 percent of the card's own leg, and at topk 10 nearly
  every token straddles any real split.

Negative:

* The rule needs the parent's term per model and per shape, so a model with no measured parent leg has
  no split until one is measured. GLM's first rows were wrong by 5.9 times on an assumed parent cost.
* Two numbers disagree by construction: the planner uses the CPU as a third parallel leg and lands 9 to
  13 percent below the two-home analytic wall. Quote the two-home table for go and no-go, and the
  planner for exploration.
* The optimum moves with batch, so a single tuned share is wrong across a batch sweep.

Neutral:

* This record is reopened by a measured parent term that is large relative to the card's leg at the
  operating rows, which pushes the crossing point to 1.00 and makes "give it everything" the whole rule.
  It is also reopened by a straddle cost that dominates the gain at the computed share.

## Alternatives considered

* Equal shares: rejected, 21 to 72 percent worse at low batch and 54 percent worse at batch 16 on 2.68.
* Hottest experts on the parent first: correct only while a CPU residue exists, and 43 percent better at
  6.05 bpw. It is the wrong rule wherever the residue is gone. See ADR-0012.
* Force a fixed fraction of rows to the card: dropped from the plan, because with disjoint homes a row
  cannot be sent to a device that does not hold its experts. The home moves offline instead, at a cost of
  one admission transfer.

## Links

* [`doc/port/b70-tiering.md`](../port/b70-tiering.md) §5, [`doc/port/b70-decisions.md`](../port/b70-decisions.md) D14
* [`notes/b70/plan_parent_budget.py`](../../notes/b70/plan_parent_budget.py)
* Related: ADR-0009, ADR-0012, ADR-0023, ADR-0036, ADR-0037