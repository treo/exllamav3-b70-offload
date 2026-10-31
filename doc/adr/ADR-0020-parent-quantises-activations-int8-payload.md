# ADR-0020: The parent quantises activations and sends int8

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `payload`, `numerics`, `prefill`

## Context

The CPU path copies activations to the slot as fp16 and quantises them to int8 inside the worker. That
division of labour is free for a CPU worker, which reads the slot from the same memory it writes, and
expensive for a card worker, which must move those bytes over a link.

Quantising before the transfer halves the payload, from `hi` bytes per row instead of `2·hi`, and only the
minority of rows that need the 15-bit second plane pay the larger size again. It also has a verification
benefit: with the quantisation done on one side, the card kernel and the CPU kernel consume identical
inputs, which is the only condition under which a numeric comparison separates quantiser drift from
arithmetic drift.

There is a cost. The quantiser becomes a second implementation of a rule that currently exists once, and
its rule is not one line: scale is `amax/127`, and a row where more than one sixteenth of the values rounds
to zero instead uses `amax/16256` with a 128-step high plane.

## Decision

We will quantise activations on the parent, inside the issue kernel, and send int8 with the per-row scale,
the per-row byte sum and the wide flag. The card returns fp32 partials by default, with fp16 output as a
measured option that is scored separately. Both transform implementations exist, on the parent and on the
card, and the harness compares the two quantised tensors bit for bit, not their outputs.

## Consequences

Positive:

* The payload halves, which is the term that limits prefill link efficiency.
* The card kernel's input contract matches the CPU kernel's, so the fixed-input numeric gate is meaningful.
  See ADR-0040.
* A bit-for-bit diff of two independent quantisers catches Hadamard normalisation, scale-vector indexing and
  rounding-mode drift, all of which are invisible inside a 2.5e-2 output error budget.

Negative:

* The quantiser is duplicated, so tie-breaking in the round-to-nearest int8 cast and the wide-row threshold
  must match exactly or the numeric gate becomes unachievable and every later difference is ambiguous.
* fp16 output halves the uplink but changes the accumulation the model sees, so it must be re-scored rather
  than folded into the default numbers.
* At batch 256 the activation path is a computed 31 percent of the card's own time, from measured byte volumes and
  measured link rate, which is where fp16 output and
  card-side summation of the partials the card owns stop being optional and start being requirements.

Neutral:

* Moving the transform to the card is a supported mode, and it is the configuration used for numeric
  bisection rather than for throughput.

## Alternatives considered

* Keep fp16 activations and quantise on the card: rejected as the default, because it doubles the payload for
  no gain, but kept as a mode because the alternate implementation is what proves the first one.
* Use bf16 or fp8 activations: rejected, because it changes the numeric class that the acceptance level
  pins, and needs a new measurement rather than a relaxed threshold. See ADR-0033.
* Send fp32 activations: rejected, twice the bytes of fp16 for no precision benefit the int8 weights can use.
* Sum the card's own partials on the card: adopted for large batch as a design item, and it is the larger win
  of the two there, because topk 10 partials collapse to one per row.

## Links

* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §2.3, §5
* [`doc/prep/moe-cpu-offload-data-paths.md`](../prep/moe-cpu-offload-data-paths.md) §6
* [`doc/port/b70-kernels.md`](../port/b70-kernels.md) §5
* Related: ADR-0019, ADR-0025, ADR-0033, ADR-0040

## Amendment

The first version of this record said card-side summation of the card's own partials was optional. The batch sweep
made it a requirement at the largest batch in that model, 256, where the computed share is 31 percent of the card's
time, and the sentence was corrected here rather than left as a note in a different document.