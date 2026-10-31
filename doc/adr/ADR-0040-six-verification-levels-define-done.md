# ADR-0040: Six verification levels define done

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `harness`, `acceptance`, `testing`

## Context

A port can fail in three unrelated ways: the arithmetic can be wrong, the data movement or protocol can be wrong, and
the machine can be doing the right work badly. A single end-to-end test cannot tell those apart, and this project's
history is a list of plausible results produced by the wrong one of the three.

The CPU offload already has an acceptance document with five levels, thresholds, measured reference values and the tests
that hold them. The port needs those five, plus one channel that can detect a card that is nominally busy and actually
idle. It also needs its non-goals stated, because two obvious criteria, bit-exactness against the CUDA path and greedy
token equality across paths, cannot be met by design, and requiring them stalls the port.

## Decision

We will accept the port against six levels, and a change is done when each of the first five holds and the sixth is
reported. Level A is bit-exact format fidelity, extended with an upload comparison against the source bytes and one
layout function as the single source of truth. Level B′ is the kernel's numeric class, graded against an exact-arithmetic
oracle, against the CPU worker at identical quantised inputs, for repeatability, for quantiser agreement bit for bit, for
the codebook vectors on the device, and for zero register spills per shipped kernel and rate. Level C is whole-model
agreement under the project's own tolerance policy, at every placement, from both cold and warm starts, through three
measurement paths. Level D is every protocol and liveness invariant, with a card-side test. Level E is the performance
floors. Level U is utilisation and power. The CPU worker's suite stays green throughout, because that worker is the
oracle.

## Consequences

Positive:

* A failure names its own level, so a wrong number does not become a week of kernel reading.
* Bars are set below measured values on purpose, so a regression is a test failure rather than a documentation edit.
* Exactness gates already have teeth: the decode exactness gate runs 206 comparisons with zero failures and zero skips,
  and it deletes stale outputs before each run so a leftover file cannot make a working run look broken.
* The non-goals are explicit: no bit-exactness between paths, no greedy-trajectory gate, no equality across output
  precision or layout settings, and no determinism claim across slot-geometry changes.

Negative:

* The surface is wide. Level B′ is per rate and per geometry, Level C is per placement and per start state, and Level D
  must run against both workers while the shared-protocol refactor proceeds.
* An E gate can be satisfied by an explanation instead of a number, which is permitted and is also the easiest place for
  drift. An explanation must cite the measurement that supports it.
* Thresholds that cannot be invented yet stay blank on purpose, which means the first run of some gates has no bar and must
  produce one rather than a pass.

Neutral:

* A skipped test is accounted for, not deleted. The reference box reports 395 passed, 29 skipped and 22 deselected, and the
  skips are environmental.

## Alternatives considered

* Require bit-exactness against the CUDA path: impossible by construction, because int8 activations and fp32 transforms
  accumulate in a different order. See ADR-0033.
* Require only whole-model agreement: rejected, because a KL budget of 1e-2 with 14 to 32 times headroom will pass a
  component that is quietly wrong in a way the next model exposes.
* Require greedy token equality across paths: rejected as a non-goal, and required in exactly one place, where the master
  flag is off. See ADR-0042.
* Grade performance against a rolling baseline alone: rejected, because the baseline itself was once wrong by 12 to 22
  percent through an uncontrolled placement start.

## Links

* [`doc/prep/port-acceptance.md`](../prep/port-acceptance.md) Levels A to E and non-goals
* [`doc/port/b70-harness.md`](../port/b70-harness.md) Levels A to U, per-flag acceptance table
* [`notes/b70/gate_dpas.py`](../../notes/b70/gate_dpas.py),
  [`notes/b70/check_gemv_oracle.py`](../../notes/b70/check_gemv_oracle.py)
* Related: ADR-0003, ADR-0020, ADR-0026, ADR-0033, ADR-0039, ADR-0041, ADR-0042

## Amendment

Level A was described as unchanged from the CPU port until the layout decision of ADR-0027 made card bytes differ from
checkpoint bytes. The upload-fidelity and layout-agreement checks were added to close the gap that a bit-exact format
gate cannot see: an expert that routing never selects.