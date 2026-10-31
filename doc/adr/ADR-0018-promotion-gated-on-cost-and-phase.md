# ADR-0018: Promotion is gated on upload cost and on phase

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `promotion`, `policy`, `glm`

## Context

One flag, `-mcpa`, turns hot-expert promotion on. Its measured effect ranges from a half gain to a
serious loss, and the sign is not a property of the flag.

On Qwen3.8 prefill it gains 30 percent at 2.05 bpw and 50 percent at 2.68 bpw, and the gain is present on
the first pass of a cold process. On GLM decode it costs 29 percent, from 16.0 to 11.4 tokens per second,
and the copy bucket in the parent's profile goes from 0.2 to 151.2 µs per layer, which is about 2.1 MiB per
layer per token of promotion traffic. The physical reason is size: a GLM expert is 9 MiB and takes 0.66 ms
to upload, against 0.09 ms for a 1.2 MiB Qwen expert at 2.05 bpw.

The reopening condition written for the earlier version of this decision then fired. GLM prefill under
promotion measures 126 to 167 tokens per second, a gain of 33 percent, with device time and the copy
bucket unchanged, so what disappeared was host wait. The same model, the same flag, opposite signs in
opposite phases.

## Decision

We will treat promotion as a cost decision per model and per phase, gated on `expert_bytes` divided by the
measured link rate against expected reuse, and not as a boolean preference. Until a phase-aware policy
exists, the operational rule is a prohibition: do not enable promotion on a GLM-class deployment that
serves interactive decode, whatever it does for batch ingest. A card-side admission budget obeys the same
gate and is throttled harder than the parent's, because it pays the same upload cost.

## Consequences

Positive:

* A measured 29 percent regression becomes a documented configuration error rather than a surprise.
* The card's admission policy inherits a cost rule instead of the parent's cadence, which is what keeps
  ADR-0014's break-even honest on 9 MiB experts.
* The asymmetry is explained by a mechanism, expert size over link rate, so it predicts the next model
  rather than adding a special case.

Negative:

* One flag cannot express the right answer today, so the interim rule is guidance for the operator and not
  enforced by the engine.
* The phase split is measured on two models only, and GLM's decode figure came from an attended run under a
  memory guard, because an unattended arm of the same shape hard-hung the box.
* A phase-aware policy is new engine work with no existing hook: phase is known at submit time, but the
  promotion state machine is shared across phases.

Neutral:

* This record is reopened by a phase-aware promotion policy, or by a GLM decode measurement taken with the
  card present and serving the tail.

## Alternatives considered

* Leave promotion as a global flag and let the operator decide: rejected, because the sign is invisible from
  the flag and the loss is large.
* Never promote on models with experts above a byte threshold: rejected, because the same models gain 33
  percent at prefill.
* Promote only during prefill: this is the interim behaviour, but it is expressed as operator guidance until
  the engine can select by phase.

## Links

* [`doc/port/b70-decisions.md`](../port/b70-decisions.md) D20
* [`notes/b70/out_glm_prefill_mcpa.txt`](../../notes/b70/out_glm_prefill_mcpa.txt),
  [`notes/b70/out_engine_step.txt`](../../notes/b70/out_engine_step.txt)
* [`notes/b70/run_glm_mcpa_attended.sh`](../../notes/b70/run_glm_mcpa_attended.sh),
  [`notes/b70/LESSONS.md`](../../notes/b70/LESSONS.md) item 85, item 87
* Related: ADR-0014, ADR-0015, ADR-0017, ADR-0034, ADR-0045