# ADR-0039: One measurement protocol binds every performance claim

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `method`, `benchmark`, `harness`

## Context

Almost every retraction in this plan was a protocol failure rather than a wrong hypothesis. The device idles at 1200 MHz
and needs tens of milliseconds of continuous work to leave that state, so the same kernel measures 44.0 µs cold and 19.2
µs warm. A batch of short separate processes measures whatever clock the card happened to sit at, uniformly,
including on binaries nobody touched. Absolute rates move about 2 times with working-set size and non-monotonically. The
placement profile carries across runs and is worth 12 to 22 percent. A single-shot interference comparison once said the
engine ran 30 percent faster while the card was saturated, which was order and warm drift rather than an effect, and the
interleaved pair measured none. Repeated text in a prefill corpus adds 4.2 percent throughput while
removing 4.4 percent of distinct experts touched. A missing runtime library once produced a full table of confident zeros,
because a failed cell printed 0.000 rather than a failure.

## Decision

We will apply one protocol to every performance claim, and a number published without its state is not admissible. The
rules, each with the quantity it protects:

1. Warm up inside the timing process, with continuous executed work, and hold a fixed anchor kernel in every batch.
2. Interleave comparison arms inside one process, and report absolute levels only within a window.
3. State the working-set size next to any rate, and the footprint next to any latency.
4. Match the measurement condition to the workload's operating point: topk, batch and resident share, not the
   checkpoint's totals.
5. Compare designs at matched batch, and over a horizon at least as long as the adaptation the design performs.
6. Pin or erase the placement profile per run, and print which start was used.
7. Use real, non-repeating text for anything routing-sensitive, and refuse a truncated prompt.
8. Report the measured link rate with every bandwidth figure, because sysfs on this box says `2.5 GT/s x1` while carrying
   14.4 GB/s.
9. Report profiled runs separately from timed runs, and never use a blocking wait as instrumentation.
10. Make every gate exit nonzero on failure, and print a visible marker when a probe cell cannot be measured.

## Consequences

Positive:

* The protocol explains the retractions, so it prevents their recurrence more cheaply than any additional probe.
* Claims become comparable across sessions, which is what lets the harness hold a rolling baseline with per-gate
  tolerances.
* Anchors and self-tests turned "the number moved" from a narrative into a measurement.

Negative:

* It is slower. A credible A/B is an interleaved pair inside one process, so the cheap one-shot number that answers "is
  this obviously broken" is not admissible evidence, and must be labelled as triage.
* Some figures stop being quotable. Absolute throughput across processes carries a 2.4 percent band, so cross-session
  comparisons must be stated as ratios.
* Protocol violations are invisible unless someone looks, which is why rule 10 exists as code rather than as advice.

Neutral:

* Warm-up is measured in executed work, not in elapsed sleep and not in repetition count. Convergence happens at about one
  second, and the earlier 15 to 20 second convention was waste that was still correct about continuity.
* This box's benchmark card shares the machine with the desktop, so the anchor is also the detector for external load.

## Alternatives considered

* Measure once per configuration and rely on reproducibility: rejected, windows differ by 2.3 times.
* Quote throughput without its input size: rejected, prompt length alone moves prefill throughput 1.8 times at a fixed
  chunk size.
* Compare each design at its best batch: rejected, because that is how a 28 times artifact was produced from a baseline
  that collapsed between batch 1 and 2.
* Use the profiler to settle performance questions: rejected, because the profiler costs about 30 percent, and the
  standing rule is to run the power and profile instruments before changing code, not instead of it.

## Links

* [`notes/b70/LESSONS.md`](../../notes/b70/LESSONS.md) items 15, 17, 19, 37, 45, 46, 54, 56, 66, 73, 75, 76
* [`doc/port/b70-harness.md`](../port/b70-harness.md) hygiene rules and cadence
* [`doc/prep/measured-costs.md`](../prep/measured-costs.md) §8.3
* Related: ADR-0036, ADR-0037, ADR-0038, ADR-0040, ADR-0041, ADR-0046

## Amendment

The harness previously required a 15 to 20 second warm-up. A warm-up sweep showed convergence at one second and nothing
after, so the requirement was corrected in duration while keeping its continuity clause, and the correction is recorded
because the old number is quoted in three artifacts.