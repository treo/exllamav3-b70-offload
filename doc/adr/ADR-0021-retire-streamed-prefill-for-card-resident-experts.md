# ADR-0021: Streamed prefill is retired for card-resident experts

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `prefill`, `dead-code`, `link`

## Context

The CPU path streams an expert's weights to the parent when the expert is hot enough, because a 45 GB/s CPU
read loses to a 13 GB/s transfer that then reads at GPU speed. That machinery is large: three compute tiers,
weight-staging rings, a stager thread, a batch-reconstruct path, and a device kernel that restores the native
trellis order after each transfer. It costs 28.6 percent of device time during a profiled 2048-token prefill
chunk, against 8 percent for the fused MoE kernel itself.

Whether the same machinery pays for itself on the card is arithmetic rather than taste. Streaming one expert
costs its byte size over the link, once if the bytes come from host memory and twice if they come from card
memory. Computing it on the card costs that expert's share of the rows, in and out, over the same link. The
two are equal at about 200 rows per expert with int8 in and fp16 out, and at about 120 rows with fp32 out. At
2048 rows over 512 experts with topk 10, the mean expert sees 40 rows, and the experts that clear clear 200
are mostly the ones already resident on the parent.

## Decision

We will ship the rows for experts homed on the card, and we will retire the streamed path for those experts:
the weight-staging rings, the stager thread, the batch and reconstruct tiers, and the unswizzle restore pass
are dead code for a card-resident layer. We keep all of it for host-resident experts, where the same argument
still favours streaming, and we recalibrate the streaming threshold for that tier against the measured link
instead of inheriting the inherited constant.

## Consequences

Positive:

* The 28.6 percent device-time share of expert transfer disappears from card-resident prefill.
* No packed-to-native restore is needed for card bytes, so the layout question stays inside one device. See
  ADR-0027.
* The card prefill path needs no host synchronisation to decide what to stream, because the device decides per
  row which rows it owns. The count readback and the tail-compression machinery are skipped.

Negative:

* Two regimes coexist inside one phase. A layer with a host residue still streams, so path selection must
  consult the expert's home and not only the row count.
* The streaming threshold for the host tier has never been calibrated against a card-era configuration. The
  inherited value stays provisional until gate E7 measures the comparison directly.
* Retiring code paths is a test burden rather than a saving in this phase: each retired path must be shown
  unreachable for card-resident layers and still live for host-resident ones.

Neutral:

* Chunking for the card's prefill jobs uses 256 rows per slot, four slots deep, which keeps transfers and
  compute pipelined at 8 jobs per layer for a 2048-row chunk.
* Retiring expert streaming does not retire activation transfer. The remaining transfer tax belongs to
  ADR-0025.

## Alternatives considered

* Stream card-resident experts to the parent when they get hot: rejected by the byte and rate crossover above
  200 rows, a regime that the resident-on-parent experts already occupy.
* Upload the expert to the card per chunk on demand: rejected, because admission is a home decision taken over
  a window, not a job decision. See ADR-0014.
* Keep the streaming machinery for uniformity with the CPU path: rejected, because it costs a quarter of
  prefill device time on the path it makes uniform.

## Links

* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §3 P2, §3 P3
* [`doc/prep/measured-costs.md`](../prep/measured-costs.md) §7, §8
* [`doc/port/b70-harness.md`](../port/b70-harness.md) gates E5, E7
* Related: ADR-0014, ADR-0024, ADR-0025, ADR-0027, ADR-0036

## Amendment

The headline "28.6 percent" is the CPU path's measured share, not a card measurement. It is quoted as the
cost of the machinery being retired, which is what the decision removes, and not as a promised saving on the
card. The distinction is in this sentence because a reader can reasonably take the figure as a card forecast.