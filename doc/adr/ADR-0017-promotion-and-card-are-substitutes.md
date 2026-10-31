# ADR-0017: Promotion and the card are substitutes over one cost term

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `cost-model`, `promotion`, `prefill`

## Context

The engine already has one mechanism that moves expert work off the CPU: hot-expert promotion, the
`-mcpa` flag. The card is a second mechanism that moves the same work to a different device. When a
proposal promises 1.26 times from one and 1.69 times from the other, the tempting summary is 2.1 times.
That arithmetic is only right if the two mechanisms remove different terms.

They remove the same term. On Qwen3.8 at 2.05 bpw, a 4096-token prefill chunk costs 4609 ms. A sweep of
the split size at fixed prompt and chunk fits that as 1992 ms plus 10.24 ms per remote expert, with
residuals under 2 ms, which puts 2619 ms, or 57 percent of the chunk, in the CPU expert leg. Promotion
removes 948 ms of that leg. The card's whole expert leg on the same chunk costs 734 ms. The second
mechanism cannot remove bytes the first already moved.

## Decision

We will combine the two mechanisms by removing the CPU expert term once. We will not multiply their
speedups. Where a deployment uses promotion, we will quote the card's gain against the promoted baseline
rather than against a plain baseline.

## Consequences

Positive:

* The honest figure is smaller and defensible: a combined floor of 2722 ms, which is 1.69 times the plain
  parent, and an incremental 1.34 times over a promoted baseline.
* The model was written down as a falsifiable prediction before it was tested. The slope under promotion was
  predicted to flatten by 36 percent and flattened by 45 percent, from 10.24 to 5.59 ms per expert. See
  [`notes/b70/out_prefill_mcpa.txt`](../../notes/b70/out_prefill_mcpa.txt).
* Two effects the model did not predict are now in the cost model: promotion costs 221 ms of extra
  intercept, 4.8 percent of the chunk, and its relief saturates at about eight experts per layer.

Negative:

* Every plain-mode baseline in this plan understates the bar the card must clear, because promotion is a
  flag anyone can set and it is free at steady state on small-expert models. Baselines have to be re-taken
  with promotion on before any speedup is published. See ADR-0039.
* The substituted term is smaller than it looked. The 1992 ms intercept is not irreducible model work: 756
  ms of it, 39 percent, is the offload path's own copy traffic. The multiplier is therefore a projection
  until the activation path is priced. See ADR-0025.

Neutral:

* This record is reopened by a workload where promotion and the card act on different expert subsets, for
  example a hot set that fits the parent's slack while the tail fits the card. There they are complements
  and the terms add.

## Alternatives considered

* Multiply the two speedups: rejected by measurement, and rejected on principle, because the same bytes
  cannot be removed twice.
* Treat the two as complements on capacity grounds: partly true and used elsewhere, since the card's
  capacity argument in ADR-0015 rests on promotion saturating. It does not change the arithmetic of one
  shared term.
* Disable promotion in all card benchmarks: rejected, because it hides the competitor an operator can
  switch on with one flag.

## Links

* [`doc/port/b70-decisions.md`](../port/b70-decisions.md) D15
* [`doc/port/b70-tiering.md`](../port/b70-tiering.md) §1, §6.1
* [`notes/b70/run_mcs_slope.sh`](../../notes/b70/run_mcs_slope.sh)
* [`notes/b70/LESSONS.md`](../../notes/b70/LESSONS.md) item 82
* Related: ADR-0015, ADR-0018, ADR-0025, ADR-0036, ADR-0039