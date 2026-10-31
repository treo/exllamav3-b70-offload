# ADR-0042: The master flag's off state is bit-identical

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `rollout`, `correctness`, `flags`

## Context

The card path touches the load path, the module eligibility test, the issue kernel and the combine. Every one of those is
on the route a normal CUDA-only run takes. The port must answer a question that no numeric tolerance can
answer: when the feature is off, is the old behaviour still exactly the old behaviour?

The project's existing policy for offload paths is statistical agreement, and greedy token equality is a stated non-goal
between paths, because a near-tie at 0.234 logits is legal. That policy is about comparing two different implementations.
It is the wrong policy for comparing one configuration against itself, which is what an off switch is.

## Decision

We will ship the card path behind one master flag, `EXL3_MOE_B70`, and that flag is off by default. With the flag off, the build must be
bit-identical to the pre-change CUDA path: greedy token equality over the verification fixture and a 32-token decode, plus
whole-model logits agreement against the measured noise floor on the 4096-token varied corpus. We allow zero tolerance on
tokens and no epsilon. A difference in the off configuration is a defect in the flag, not a numerical discussion, and the
cross-path non-goal of ADR-0040 does not apply to it.

## Consequences

Positive:

* An operator can revert by configuration, which is what makes a load-path change safe to ship at all.
* Any numeric difference can only come from the on configuration, which halves the search space of every regression.
* The gate is cheap: two decodes and one logits comparison, with no card required, so it can run per commit.

Negative:

* Bit-identical is strict. A refactor that reorders a reduction in shared code fails this gate even when it is numerically
  harmless, so the shared-protocol refactor of ADR-0043 must be gated by the CPU suite as well and not by this test alone.
* Two configurations must be built and exercised continuously rather than one.
* Fixtures become load-bearing. The corpus is pinned, and a change to it invalidates the comparison, which is why the
  corpus is a committed file rather than generated text.

Neutral:

* Sub-flags for layout, output precision and engine tier are explicitly outside this gate, because those are on-configuration
  variants and are scored separately.

## Alternatives considered

* Statistical equivalence when off: rejected, because off means the same code path and a tolerance licenses silent
  coupling between the flag and the old route.
* Gradual rollout with a KL budget: rejected for the off state, and appropriate for on-state placements at Level C.
* Remove the flag and retire the CPU worker: rejected, because the CPU worker is both the numeric oracle and the
  fallback,
  and because oversized models require it. See ADR-0014.

## Links

* [`doc/port/b70-harness.md`](../port/b70-harness.md) per-flag acceptance table, first row
* [`notes/b70/fixtures/prefill_pool.txt`](../../notes/b70/fixtures/prefill_pool.txt)
* [`notes/b70/LESSONS.md`](../../notes/b70/LESSONS.md) item 76
* Related: ADR-0040, ADR-0043, ADR-0045, ADR-0047

## Amendment

This gate was written after a repeated-text corpus was found to inflate prefill throughput by 4.2 percent while reducing
distinct experts touched. The corpus is a committed set of twelve distinct documents, each appearing once, and not
generated text.