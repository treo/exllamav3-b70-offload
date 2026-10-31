# ADR-0012: Placement minimises the per-layer maximum

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `placement`, `objective`, `decode`

## Context

Placement decides which experts live on which home. The first objective written for it minimised summed
compute across homes. That objective is wrong whenever homes run concurrently, because a step finishes
when its slowest home finishes, not when all three have finished their share of a total.

With the correct objective the ordering rule is not one rule. Cost on the parent is serial with the
parent's own work, while cost on the card and on the CPU is concurrent. When some picks still land on
the CPU, the CPU term, priced at bytes over 42.6 GiB/s, is the most expensive byte on the box, and
spreading hot experts over both accelerators leaves colder ones there. When no pick lands on the CPU,
the problem becomes a pure balance between two accelerators and the fair-share rule wins. Which side of
that boundary a model sits on is measurable, and it changes with the quantisation recipe.

## Decision

We will minimise the per-layer maximum of the three home terms, with the parent's term serial and the
card's and the CPU's terms concurrent. We will choose the cut-point rule per model from the live
residue: frequency order, hottest first, while a CPU residue exists, and a load-balanced greedy pass
once the residue is gone. The evaluation is per layer, from per-layer routing statistics, never from one
collapsed distribution.

## Consequences

Positive:

* The objective separates the two rules in the direction the balance implies, on modelled costs from measured rates.
  On Qwen3.8 at batch 8 the balanced rule gains 13 percent,
  but on GLM at batch 1 and 4 the frequency rule gains 9 and 20 percent, and in both cases the loser is the
  rule that ignores the CPU residue.
* The rule predicts its own crossover across five recipes: balanced wins by 3 to 9 percent at 2.05, 2.68,
  4.05 and 5.05 bpw, and frequency order wins by 43 percent at 6.05 bpw, the one recipe with a real 9.6
  percent residue.
* Aggregating per layer instead of collapsing the layers removes two large errors. Collapsing inflates
  the distinct-expert union from 10.6 to 22.8 times, and mis-states residence hit rate from 99.3 to 74.5
  percent, which is worth a factor of 6.6 in predicted throughput.

Negative:

* The selection input, the live residue, only exists after a trace. A profile-derived residue is an upper
  bound, so the rule can pick the wrong side for a model nobody has traced. See ADR-0038.
* Two ordering rules and one selector is more surface than one rule, and the selector must read the residue
  against the live expert count rather than the decayed profile tail.
* Gate E19 must confirm both sides at two recipes at least, one with a residue and one without.

Neutral:

* A co-location pass that trades read rate for a lower spanning fraction ships as an experiment behind a
  knob, not as a default. Spanning falls only as capacity rises, not as ordering changes. See ADR-0023.

## Alternatives considered

* Minimise summed compute: rejected, it double-counts concurrent homes and hides the ceiling.
* One ordering rule for every recipe: rejected, because the sign of the comparison flips at 6.05 bpw.
* Solve the partition exactly: rejected as unnecessary, because a single greedy pass over the frequency
  order reproduces the measured optimum at every point sampled, and an exact solve needs statistics
  the planner does not have.

## Links

* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §2.1a, §4
* [`notes/b70/out_parent_budget.txt`](../../notes/b70/out_parent_budget.txt),
  [`notes/b70/out_quant_scaling.txt`](../../notes/b70/out_quant_scaling.txt)
* [`doc/port/b70-harness.md`](../port/b70-harness.md) gates E19, E20
* Related: ADR-0010, ADR-0011, ADR-0013, ADR-0038

## Amendment

This record first said "minimises the per-layer maximum, and orders by frequency while a residue
exists", which read as one rule with an exception. Measurement made it two rules with a selector, and the
selector is the decision. The change is recorded here rather than edited silently, because the earlier
form ships the wrong rule for the dense recipes.