# ADR-0027: The weight layout is normalised at admit, not selected in the kernel

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `layout`, `correctness`, `kernel`

## Context

The selected decode kernel reads each tile's dwords in a transposed order. The bytes are the same, the capacity
is the same, the traffic is the same and the output bits are the same, but the card-resident tensor is no longer
byte-identical to the checkpoint. Something has to produce that order, and the format already has two
layout-dependent choices in the tree: the CPU worker's tile-order swizzle, whose group depends on the host ISA
and the rate, and its planar dword form, which is produced only on the AVX2 tier at integer rates.

Three places to pay exist. The parent can permute while staging, which is measured to be the worst option: a host
permute-copy manages 6.8 GiB/s at 3 bpw, below the 7.8 GiB/s link, so staging becomes permute-bound while burning
the parent cores this plan prices as scarce. The card can permute after an ordinary transfer, which costs 3.46 ms
per 512 MiB against 1.19 ms for a plain device copy, about 5.4 percent on a load that already takes 64 ms.
Or the kernel can be told which layout it received, through a marker in the handoff.

The marker option has a specific and unacceptable failure mode. If a kernel reads bytes with the wrong tile map,
output is wrong only for the experts that routing happens to select, which is exactly what the format-level
bit-exactness gate cannot see.

## Decision

We will normalise to one canonical card layout at admit. When the parent's staged bytes already match it, the copy
is verbatim. When they do not, the card permutes on admit. The layout is a fact about one function, checked where
the bytes arrive, and invisible to the compute kernel. No layout marker reaches a kernel, and an unrecognised
combination of band group, planar flag and rate rejects the admission instead of falling through to a default map.

## Consequences

Positive:

* Measured support for the cheapest case: on this AVX2 host the production staged dword order is already the
  kernel's order, byte-identical over 1.536 million dwords, and the kernel consumes the full staged form, planar
  dwords plus group-2 banding, bit-exactly at 16 of 16 configurations with a negative control that feeds the same
  bytes to the checkpoint tile map and rejects them every time. Banding costs between minus 4.6 and plus 1.0
  percent. See [`notes/b70/out_cpu_layout.txt`](../../notes/b70/out_cpu_layout.txt).
* Two code paths through the compute kernel collapse into one, and the invariant is testable by sampling the
  tensor at admit, which covers experts that routing never picks.
* Pay-on-admit is the right place for the cache tier too: an expert that is evicted and readmitted pays the
  permute again, 226 µs per 14 MiB admission, and that cost is charged where it is incurred.

Negative:

* Card bytes differ from checkpoint bytes, so the format gate is no longer sufficient on its own and the conformance
  sample at admit becomes load-bearing rather than optional.
* The AVX-512 staging tiers are asserted rather than measured, because this host has no AVX-512. The build ships the
  conformance check rather than an assumption, and a host whose staged bytes fail the sample falls back to the
  native layout path.
* The permute is one more pass with its own addressing, and an out-of-bounds read here does not report an error. It
  loses the device.

Neutral:

* The intra-tile dword order and the CPU's tile-order swizzle are different axes that compose. Adopting one does not
  disturb the CPU's measured 3.4 times cold-traversal gain, and a shared single pass is possible but unmeasured.

## Alternatives considered

* Pass a layout marker into the compute kernel: rejected, because its failure mode is silent and its cost is a
  branch in the hot path for a fact that admit already knows.
* Permute on the parent while staging: rejected on measurement, below link rate for the same bytes.
* Rewrite the on-disk format to the permuted order: rejected, because it would break byte-interchangeability with
  every existing kernel for a benefit that admit-time normalisation already provides.
* Require the parent to stage canonically on every tier and delete the card permute: deferred, and it is the right
  shape if the AVX-512 tiers can be measured. It needs the staged-layout marker the ban above removes, so the
  conformance check has to move rather than disappear.

## Links

* [`doc/port/b70-decode-closeout.md`](../port/b70-decode-closeout.md) D3, D3-alt
* [`notes/b70/out_permute.txt`](../../notes/b70/out_permute.txt),
  [`notes/b70/probe_permute.cpp`](../../notes/b70/probe_permute.cpp)
* [`notes/b70/LESSONS.md`](../../notes/b70/LESSONS.md) item 24, item 49
* Related: ADR-0021, ADR-0026, ADR-0028, ADR-0040, ADR-0045

## Amendment

D3 first accepted the device permute at admit as the answer. D3-alt then showed the parent already stages that
order on this host, and the remaining contractual question was resolved by moving the decision to admit rather than
into the kernel. Both steps are kept in this one record so that the sequence is visible.