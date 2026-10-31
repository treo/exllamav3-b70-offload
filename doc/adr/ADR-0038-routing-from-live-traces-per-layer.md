# ADR-0038: Routing input comes from live traces, aggregated per layer

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `cost-model`, `routing`, `method`

## Context

Every placement, capacity and concurrency figure in this plan takes one input from outside the checkpoint: the
distribution of expert selections. Until recently that input was the engine's stored expert-stats file. The file is a
decayed cumulative counter, written at unload by a run whose placement was already adaptive, and it carries near-zero
dust entries, down to 1e-27 for experts that were once touched and never again.

Two errors followed from using it, and neither was about the mathematics. The plan's distinct-expert union was about 2
times too high by batch 32, measured at 10.35 times topk against a carried 21.91 times, while the closed-form
independence model itself predicts 32.2 against 32.1 measured at batch 4. The formula was right and the input was wrong.
Separately, one wrong aggregation inflated concave statistics: layer 0 stood for the model's distribution, when layer
0 touches 289 of 512 experts in 1920 picks, and one collapsed vector stood for 48 per-layer vectors, which inflates the
union from 10.6 to 22.8 times and mis-states residence hit rate from 99.3 to 74.5 percent. That single
aggregation error is worth a factor of 6.6 in predicted throughput.

The stakes are not cosmetic. A flat routing profile was the argument against building the prefill path, and live routing
reversed it: 24.3 percent of experts cross the eligibility bar at 2048 rows and carry 94.3 percent of the picks, where
the stored profile said 0.4 percent carry 0.6 percent.

## Decision

We will take planning routing input from traces of a real generator on real text, aggregated per layer, and we will use
the committed trace profiles as the reproducible source. The stored expert-stats file stays a priming input for
placement and nothing else, and any figure derived from it is labelled an upper bound, with the gate that the live
resident share must not exceed it. Order statistics and unions are computed per layer and never from a collapsed
distribution.

## Consequences

Positive:

* Reproducibility is explicit: the profiles are committed, the planners read them through one environment variable, and a
  stored output matches a re-run.
* Three separate build-or-not decisions in this plan were moved by this correction, so the input rule is load-bearing
  rather than tidy.
* The independence model is retained and validated, which keeps the analytic predictors usable where no trace exists.

Negative:

* Any placement claim for an untraced model is now inadmissible until a trace exists. GLM has none, so its hot-tail share
  is unmeasured rather than small, and it is the model where the difference matters most.
* A trace is a population. Prose and code differ by about 10 percent in union breadth, and pooling sessions by about 2
  percent, so a deployment outside the traced domains reopens the numbers.
* Concurrent-session union beyond batch 6 cannot be measured directly, because the engine steps sequences one at a time.
  It is obtained by pooling traces, which is an approximation this record accepts and names.

Neutral:

* Traces must pass a validity gate on their time axis before use. One captured trace failed it, was discarded, and the
  dwell conclusion rests on the two that passed. See ADR-0039.

## Alternatives considered

* Keep the stored profile with a safety factor: rejected, because the error is 2 times, directional, and different per
  model, so no single factor fixes it.
* Synthesise routing from expert count and topk under independence: rejected as an input, though the formula is retained,
  because independence is accurate and the marginal distribution is not the checkpoint's.
* Aggregate one profile per model to simplify the planners: rejected, because collapsing the per-layer vectors inflates
  every concave statistic the plans depend on.
* Trace only one layer to keep the capture cheap: rejected on measurement, because layers differ by more than the sampling
  saving.

## Links

* [`doc/port/b70-decisions.md`](../port/b70-decisions.md) D12
* [`notes/b70/out_live_trace.txt`](../../notes/b70/out_live_trace.txt),
  [`notes/b70/analyze_live_trace.py`](../../notes/b70/analyze_live_trace.py),
  [`notes/b70/profiles/live/`](../../notes/b70/profiles/live/)
* [`notes/b70/LESSONS.md`](../../notes/b70/LESSONS.md) item 63, item 64, item 89
* Related: ADR-0012, ADR-0013, ADR-0014, ADR-0024, ADR-0039

## Amendment

Three separate findings in this plan each took an order statistic after collapsing a distribution, and each was defended
at the time. The rule is now written where the input enters rather than only where the error appeared.