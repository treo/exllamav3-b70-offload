# ADR-0036: Each tier is priced by a measured primitive

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `cost-model`, `method`, `units`

## Context

Four separate errors in this plan came from the same move: taking a rate measured in one shape and applying it in
another.

The card's 292 GB/s decode read rate predicts a prefill expert leg of 486 to 631 ms per chunk, against a measured 734
ms. Used the other way, the measurement implies an effective 193 to 251 GB/s, so the rate is 14 to 34 percent
optimistic in the prefill bucket regime. The CPU term was carried at 47.4 GB/s, which is the datasheet peak of this
box's memory, while the measured achievable read rate is 42.6 GiB/s and the kernel runs at about half that once rows per
expert grow. The parent's non-expert leg was twice estimated from bytes and twice wrong, by 5.9 times in one direction
and by a missing component in the other: the measured figure is 141.9 µs per layer at 2.05 bpw and 195.6 at 2.68, of
which about 83 µs is hyper-connections, which no byte model in the plan contained. The parent's own expert leg is
kernel-bound at about 190 GB/s, flat from batch 1 to 16, while it streams other weights at 860 GB/s.

## Decision

We will price every tier with a measured primitive that names its regime, and we will use a byte rate only inside the
regime where it was measured. These are the current primitives:

* 5.70 µs per expert-bucket for engine-integrated prefill on Qwen geometry.
* 32.6 to 37.3 µs per bucket on GLM geometry.
* 10.23 ms per CPU-homed expert per 4096-token chunk for the host tier at prefill rows.
* 42.6 GiB/s read, 24.1 copy and about 485 GiB/s from last-level cache as host ceilings.
* An engine-measured parent non-expert table keyed on batch and context, with a shape anchored on measured levels.
* 13.4 GiB/s for the pinned link.

The planner does a nearest-cell lookup, refuses to extrapolate past its measured range, and
carries a units self-test, because a 1000 times slip in one conversion once made every placement policy tie.

## Consequences

Positive:

* A missing primitive surfaces as a refusal, where a wrong rate surfaced as a plausible number.
* The primitives explain a result the rate model did not explain: a bucket costs 4.8 plus 1.19 µs per bit of rate, so
  about 67
  percent of a 2 bpw bucket is fixed overhead. That is the quantitative reason the mechanisms of ADR-0034 lost, and the
  reason a byte rate misprices low rates most.
* Comparisons across recipes now use weights per second rather than bytes per second, because the two differ by the rate
  factor.

Negative:

* Each new geometry owes a measurement. Three cheap ones are deliberately unfinished: the 3 bpw bucket cost in the probe,
  a GLM-geometry bucket cost so GLM rows stop borrowing Qwen rates, and per-cell coverage outside 3 bpw.
* Two families of the same quantity must not be averaged. The 5.70 µs engine figure and the 7.2 to 11.95 µs probe
  ladder measure different things, and fitting one line across both is wrong in a way that looks precise.
* Absolute levels move 2.4 percent between processes while within-process slopes fit to under 2 ms, so primitives must be
  re-fit inside one process and cross-process absolute comparisons are not admissible.

Neutral:

* The three-point rate ladder is provisional, and the 4 bpw point sits 5 percent off its own fit.
* A prefill kernel whose rows per expert crosses the eligibility bar makes a byte rate the right primitive again,
  because arithmetic rather than memory binds. That is the reopening condition for the prefill primitive.

## Alternatives considered

* One card bandwidth constant for all phases: rejected, 14 to 34 percent optimistic, and it also hides the fact that
  small-footprint rates are partly cache rather than memory.
* Byte rates scaled by arithmetic intensity: rejected for the parent, because the largest single component is not a
  weight read at all.
* The datasheet host memory rate: rejected, 11 percent optimistic as a ceiling and unusable at prefill shapes. The
  planner constant that carried it is limited to the rows-near-one regime, where it is accurate. The prefill rows of the
  tiering tables use the per-bucket primitive above rather than a rate.
* Byte rates plus per-phase correction factors: rejected, because three of the corrections were themselves the source of
  factors-of-two errors.

## Links

* [`doc/port/b70-decisions.md`](../port/b70-decisions.md) D11, D18
* [`notes/b70/out_host_mem.txt`](../../notes/b70/out_host_mem.txt),
  [`notes/b70/out_prefill_kscale.txt`](../../notes/b70/out_prefill_kscale.txt),
  [`notes/b70/out_probe_gemm_glm.txt`](../../notes/b70/out_probe_gemm_glm.txt),
  [`notes/b70/out_engine_step.txt`](../../notes/b70/out_engine_step.txt),
  [`notes/b70/out_parent_leg.txt`](../../notes/b70/out_parent_leg.txt)
* [`notes/b70/LESSONS.md`](../../notes/b70/LESSONS.md) item 51, item 54, item 81
* Related: ADR-0011, ADR-0017, ADR-0025, ADR-0031, ADR-0037, ADR-0039
