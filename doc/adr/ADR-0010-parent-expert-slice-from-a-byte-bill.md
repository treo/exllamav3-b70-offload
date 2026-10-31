# ADR-0010: Size the parent's expert slice from a computed byte bill

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `capacity`, `placement`, `parent`

## Context

Experts homed on the parent compete for the same memory as the KV cache, the recurrent state, and the
streamed non-expert weights. The size of that slice is not a free parameter. An early draft
of this plan assumed 2 GiB. That assumption was a guess, and it was eight times too small.

"The parent is busy" is two different claims, and they pull in opposite directions. The capacity bill
asks what must be resident. The traffic bill asks what competes for bandwidth. Conflating them is what
produced the 2 GiB figure. Measured separately, the capacity bill is small: 4.05 GiB of streamed
non-expert weights on Qwen3.8, 5.67 GiB on GLM, 22 to 24 KiB of KV per token, and 108 to 136 MiB of
recurrent state per sequence. The 49.91 GiB of n-gram tables that look alarming are host row-gathers,
not resident memory. That leaves 18.25 GiB free for experts on Qwen3.8 and 16.61 GiB on GLM, at a 4k context and
batch 1. The traffic bill says the parent streams 86.4 MiB per layer of non-expert weights on Qwen3.8. At the
measured 860 GB/s that is 105.3 µs of memory time, and on GLM the same bill is 129.0 MiB or 157.3 µs. That is 31 to
45 percent of the parent's own layer window at every recipe measured, and its expert leg is kernel-bound at about
190 GB/s. The parent is thus latency-bound rather than bandwidth-bound at small batch.

## Decision

We will compute the parent's expert slice at load from the shard-header byte bill and the model config:
total memory, minus streamed non-expert weights, minus KV per token times context times rows, minus
state per sequence times rows, minus a reserve. No fixed slice constant ships as a default. The same
bill is reported with every capacity number, and is re-derived at the deployment's context length and
batch.

## Consequences

Positive:

* Qwen3.8 at 2.68 bpw moves from 97.6 percent to 100 percent of picks homed, and its CPU residue goes
  to zero. GLM moves from 70.8 to 81.1 percent, and its residue from 19.6 to 12.6 ms per token. That
  correction is worth more than any hot-versus-cold ordering choice measured. The 2 GiB side is the planner's
  own row at that slice, and the corrected side is the table in
  [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §2.1a.
* The byte bill, the resulting free slice of 16.61 GiB, and both rules under it are printed by
  [`notes/b70/out_parent_budget.txt`](../../notes/b70/out_parent_budget.txt), and the 2 GiB residency rows are
  printed by [`notes/b70/out_placement.txt`](../../notes/b70/out_placement.txt).
* The traffic half of the bill is recipe-general: 69 to 101 MiB per layer and 31 to 45 percent duty at
  every one of five Qwen3.8 recipes, which is a checked fact rather than an assumption.
* Surplus capacity becomes visible, so replication can be evaluated instead of assumed away. See
  ADR-0009.

Negative:

* The bill depends on context and batch, so the slice changes between deployments. A benchmark that
  quotes a slice must quote the context and batch with it.
* About 12 GiB of surplus on one recipe is a spending decision that this record does not make, and
  unused capacity is the honest outcome until gate E14 measures whether the surplus survives.
* The traffic figure is inferred from a byte bill, not measured as spare bandwidth. Gate E18 measures
  the parent's achieved expert-read rate while its own per-layer work runs concurrently.

Neutral:

* The existing autosplit machinery already weighs memory against KV, and now evaluates experts against
  the card as an alternative home instead of against disk only.

## Alternatives considered

* Keep a fixed 2 GiB slice: rejected, eight times too stingy, and it made the residue look like a
  placement problem rather than an accounting error.
* Assume all memory left after the model load: rejected, because autosplit reserves against KV growth
  and the state term is large per sequence on these hybrid-attention models.
* Balance the two accelerators by equal byte shares: rejected on measurement. See ADR-0011.

## Links

* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §2.1a
* [`notes/b70/plan_parent_budget.py`](../../notes/b70/plan_parent_budget.py),
  [`notes/b70/out_parent_budget.txt`](../../notes/b70/out_parent_budget.txt)
* [`notes/b70/LESSONS.md`](../../notes/b70/LESSONS.md) item 22
* Related: ADR-0009, ADR-0011, ADR-0013, ADR-0036

## Amendment

An earlier version of this record carried the design document's traffic figures: 96.8 µs per layer, about 39 percent
bandwidth duty, and one free-slice number of 16.6 GiB for both models. The planner's current run prints 105.3 µs for
Qwen3.8 and 157.3 µs for GLM, computed at the measured 860 GB/s rather than at the 936 GB/s spec, and it prints 18.25
GiB free on Qwen3.8 against 16.61 GiB on GLM. The conclusion is unchanged, because it turns on the ratio rather than on
either value.