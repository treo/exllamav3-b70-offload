# ADR-0013: The card tier is divided per layer in bytes

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `placement`, `capacity`

## Context

A tier holds a byte budget, and that budget has to be shared out across 40 to 48 MoE layers. The obvious
rule, fill a global hot list until the budget runs out, produces a distribution where some layers are
fully resident and others hold nothing. A layer with no resident expert pays the full routed cost on the
CPU for every token, so an empty layer is not a proportionally worse layer. It is the worst layer.

Hit rate per layer is concave in that layer's resident byte quota, which makes the allocation a
water-filling problem: give the next MiB to the layer with the largest gain in resident pick share. In
the common case, where routing entropy is similar across layers, that degenerates to equal bytes per
layer. Equal bytes is not the same as equal expert counts, and the difference is real in the local
checkpoints: Qwen3.8 at 2.68 bpw carries 2.5 bpw experts in layers 4 to 43 and 3 bpw experts in layers 0
to 3 and 44 to 47, so an equal-count split gives those layers different byte budgets.

## Decision

We will divide the card tier as a per-layer byte quota, with the expert count per layer following the
quota. We will not divide it by expert count and we will not divide it with one global hot list. Where
measured per-layer pick mass makes the marginal gains differ, the quota moves to the layer with the
larger gain.

## Consequences

Positive:

* No layer is left empty, which removes the worst-case term from the residue.
* Mixed-rate layers are handled by the natural unit, because a byte quota prices a 2.5 bpw expert and a
  3 bpw expert differently.
* The per-layer budget is also the quantity that sets the spanning fraction, so one number serves
  placement and the activation model.

Negative:

* The quota needs per-layer pick mass, which is a trace rather than a checkpoint property. See
  ADR-0038.
* Byte accounting must be done in the loader's units, and a 1000-times slip in a MiB-to-µs conversion once
  made every placement policy tie silently. The planner now carries a scale self-test for that reason.
* Rate uniformity inside a layer must be asserted rather than assumed, because per-expert byte layout is
  derived from expert 0's dimensions today. See ADR-0045.

Neutral:

* Equal bytes per layer is the degenerate case of the water-filling rule, so a later entropy-driven
  allocation refines this record instead of contradicting it.

## Alternatives considered

* One global frequency-sorted tail: rejected, because it can leave a layer with zero residents.
* Equal expert counts per layer, as the CPU split does today: rejected, because byte sizes differ per
  layer within one checkpoint at mixed rates.
* Water-fill on measured marginal gain from the first build: deferred, because it needs per-layer pick
  mass for every model, and the equal-bytes case is within its error for the models measured here.

## Links

* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §4a, structural consequence 2
* [`notes/b70/plan_placement.py`](../../notes/b70/plan_placement.py),
  [`notes/b70/out_placement.txt`](../../notes/b70/out_placement.txt)
* [`notes/b70/plan_parent_budget.py`](../../notes/b70/plan_parent_budget.py) scale self-test
* Related: ADR-0010, ADR-0012, ADR-0014, ADR-0045