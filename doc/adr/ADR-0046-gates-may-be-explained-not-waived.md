# ADR-0046: A gate may be explained by measurement, never waived

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `process`, `gates`, `planning`

## Context

The work is divided into phases, and each phase ends at a commit that is known good, with a harness report and a set of
gates. Phase 0 and phase 0b are complete: the probes answered the transport, sharing, store-discipline, bandwidth, layout and
arithmetic questions, and the placement planners answered the placement questions from real routing counts. What remains,
phases 1 through 5, is the engine, the decode kernel in the engine, prefill, the three-home partition, oversized models, and
then the optional items.

The alternative control, ship when the end-to-end result looks right, is the one this plan has already paid for. Its
history is numbers that looked right: a decode rate that turned out to be cache, a prefill eligibility count that was wrong
by a factor of six because a distribution was collapsed, a two-card share that was wrong by 18 points because a balance
omitted an overhead, and a flag that looked 30 percent harmful in a single-shot test and neutral when interleaved.

## Decision

We will hold each phase to its gates. A gate is passed by a measurement that a finished command printed, or by a named
measurement that explains a deviation from the bar. Waiver is not an available action. Every gate has its failure action
written before the run, every threshold is either measured or left explicitly blank, and any check that runs in a commit
path exits nonzero. Retracted numbers keep their records, marked as retracted, next to the numbers that replaced them.

## Consequences

Positive:

* The build cannot drift into approximate success, which is the failure mode the history above describes.
* Explanations are cheap when they are allowed. The main rate gate is a footprint-matched bracket rather than a single
  number, precisely so that a measured explanation is possible.
* Blank thresholds are informative. A gate that has no bar yet names the instrument that owes one, which converts "not
  measured" into a work item.

Negative:

* An explanation can itself be wrong, and a gate passed on a bad explanation is worse than a gate failed honestly. The
  mitigation is that explanations cite an artifact, and retraction conventions apply to them as well.
* Some gates depend on instruments that do not exist yet, so a phase can be blocked by a missing measurement rather than by
  unfinished code. That is the intended cost.
* Nonzero-exit discipline means a malformed table or a stale output file stops a commit, which is friction that occasionally
  lands on the wrong change.

Neutral:

* Phases are ordered by which unknown would hurt most if it went the wrong way, not by ease. The activation path of
  ADR-0025 sits ahead of remaining kernel work for that reason.

## Alternatives considered

* Ship on end-to-end quality: rejected for the reasons in the Context section.
* Allow a documented waiver: rejected, because a waiver recorded in prose is how a superseded number survives into a
  summary.
* Set every threshold now, before measuring: rejected, because a threshold invented before the measurement is a wish, and the
  first run that fails it gets renegotiated until it passes.
* Merge phases to reduce ceremony: rejected, because a phase boundary is where a known-good commit is recorded, and the
  rollback cost of losing that is the whole point.

## Links

* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §9, §12
* [`doc/port/b70-harness.md`](../port/b70-harness.md) per-flag acceptance table
* [`notes/b70/LESSONS.md`](../../notes/b70/LESSONS.md) item 45
* Related: ADR-0039, ADR-0040, ADR-0044, ADR-0047

## Amendment

Gate E4 was previously recorded as failing against a single projected number, 420 GB/s or better. It is restated as a
footprint-matched bracket with named pass conditions, because the projection was not measurable at the shape it named and
the gate, not the kernel, was the thing that was wrong.