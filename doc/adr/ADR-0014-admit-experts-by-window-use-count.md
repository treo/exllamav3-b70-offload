# ADR-0014: Admit experts by window use count, never per job

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `placement`, `migration`, `policy`

## Context

An expert with no device home can be computed where it lies, on the CPU, or admitted to the card, or
streamed to the parent. Admission costs one transfer before the first useful read: 655 µs for a 9 MiB
GLM expert at the measured 13.4 GiB/s link, and 2.5 ms when the bytes must come off disk. A CPU
assignment on the same expert costs about 199 µs per use, and the card about 31 µs. The break-even is
about four uses, and that ratio is scale-invariant: it moves only from 3.8 to 4.1 uses across
the whole measured rate range of 132 to 545 GB/s.

An earlier draft charged the upload per pick, which made migration look fifty times more expensive than
it is and produced the wrong verdict: "do not migrate, let the CPU serve the residue". The distinction
that decides the policy is that CPU cost accrues per pick and never stops, while admission is paid once
per newly resident expert.

The CPU path supplies the negative precedent for deciding too often. Its promote-on-miss hook costs 2 to
3 ms per token of host time, and its periodic hot-versus-cold sweep costs about 6 ms including a device
quiesce and a checkpoint re-read. An ungoverned policy loses money at those rates.

## Decision

We will decide homes over a window, never per job. An expert with no device home is admitted when its
predicted uses inside the window exceed the break-even, which defaults to 4. Admissions are budgeted per
step and issued on a low-priority transfer queue. The tier is primed at load from the saved
expert-stats profile, and the planner prints the predicted resident pick share, the predicted spanning
fraction, the migration set size and the one-time fill cost at load, and refuses a configuration whose
predicted share is unreachable.

## Consequences

Positive:

* A card admission needs no parent quiesce and no checkpoint re-read, unlike the CPU path's 6 ms sweep,
  so decisions can be made online per chunk instead of periodically between generations.
* The break-even barely depends on rate, so a wrong bandwidth assumption does not flip the policy.
* Priming turns the expert-stats profile from a benchmark confounder into an asset, and makes the cold
  and warm starts explicit in every report.
* Eviction is a free space reclaim, because the victim's bytes still exist in host memory or on disk.

Negative:

* The policy rests on churn, which is measurable online but has not been measured yet. Two offline
  proxies were tried and both are invalid, so gate E11 owns the number.
* Admission traffic shares the link with activations. Gate E5 is measured with admission active, not with
  it disabled, and the low-priority queue is a Level Zero feature with no SYCL equivalent.
* A profile-derived resident share is an upper bound, because the stored counts are decayed cumulative
  statistics written by an already-adaptive run. The gate is then that the live figure is not above
  the profile figure.

Neutral:

* Where real churn sits above the break-even, the CPU serves the residue and the card tier stays static
  apart from priming. Below it, migration serves the residue with a per-step budget sized to the link
  window. The two thresholds nearly coincide, at about 0.31 and 0.36 percent per token, so there is no
  regime where migration is affordable but unattractive.

## Alternatives considered

* Admit on first miss: rejected as a default, because a transient expert then pays 655 µs for one use.
  Kept as a knob setting that measures the thrash case.
* Never admit, static homes only: kept as a supported mode, and it is the configuration that isolates
  placement effects in the harness.
* Stream the expert to the parent instead: correct at prefill row counts and wrong at decode, because a
  streamed slot is transient and its threshold is about 200 rows per expert rather than four uses. See
  ADR-0021.
* Reuse the CPU path's periodic sweep: rejected, because it stops the world and the card has no need to.

## Links

* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §4, §4a
* [`notes/m_expert_capacity.txt`](../../notes/m_expert_capacity.txt),
  [`notes/b70/out_placement.txt`](../../notes/b70/out_placement.txt)
* [`doc/prep/measured-costs.md`](../prep/measured-costs.md) §8.2
* [`doc/port/b70-harness.md`](../port/b70-harness.md) gates E11, E12, E14
* Related: ADR-0013, ADR-0015, ADR-0016, ADR-0017, ADR-0019