# ADR-0019: Decode sends one compact message and pushes one partial back

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `decode`, `protocol`, `payload`

## Context

A decode slot today is four fixed-capacity sections: activations, expert ids, weights and output, sized
for 64 rows. On Qwen3.8 that is a 320 KiB activation section, 2.5 KiB of ids, 1.25 KiB of weights, a 640
KiB output section, and a 963.8 KiB slot. A one-row decode job has about 5 KiB of real payload, spread
across three of those sections.

For a CPU worker this costs nothing extra, because the worker reads the sections it wants with ordinary
loads. For a card worker the payload must cross the link as a transfer, so the choices are three separate
transfers, or one transfer of almost a megabyte of mostly empty space. At the measured link rate a whole
slot is about 70 µs, which is more than the entire decode layer the job is meant to hide.

The return direction has its own asymmetry, resolved in ADR-0005: the result is written by the kernel
straight into the pinned slot.

## Decision

For card workers we will have the parent's issue kernel write one dense message: a 64-byte header with
sequence, rows, topk, widths and flags, then ids, weights, the per-row quantiser records, and the int8
activations. The engine moves that one buffer with one copy. The output stays at a fixed slot offset, so
the parent's collect kernel is unchanged. The CPU worker keeps the existing four-section layout.

## Consequences

Positive:

* One submission per job instead of three, at 7.6 to 8.9 µs for 16 KiB including the flag, and 15 µs for
  128 KiB. See [`notes/b70/out_transport.txt`](../../notes/b70/out_transport.txt).
* The empty job stays empty: with no card-selected expert the layer costs one host spin miss and a collect
  kernel that exits, which is cheaper than the CPU path's 20 µs because the wait retires immediately.
* The collect kernel and every invariant that depends on it are untouched, because the output position and
  the flag protocol do not change.

Negative:

* Two slot formats now exist. They live in different regions owned by different workers, so no shared code
  must agree on both, but the geometry calculation is duplicated and each format needs its own tests.
* The issue kernel gains a payload mode, which puts packing of the quantiser records on the correctness
  surface. A wrong offset there is silent, so the assertion rule of ADR-0006 applies to the message as well
  as to the output.
* The layout is fixed by the header, so adding a field is a protocol change rather than a section resize.

Neutral:

* Prefill uses a larger per-job row capacity, 256 rows rather than 64, for the same reason: each job carries
  a 7 to 9 µs handshake, so 32 jobs per layer add a quarter of a millisecond per layer of pure
  protocol.

## Alternatives considered

* Three contiguous copies, one per section: rejected, because three submissions cost more than the payload.
* One copy of the whole slot: rejected, about 70 µs for a mostly empty buffer at the measured link rate.
* Let the card read the parent's memory directly: not available cross-vendor on this box, and it is the named
  open item of ADR-0025.
* Compress the payload: rejected as unnecessary, because 5 KiB per layer per token already hides entirely.

## Links

* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §3 P1
* [`doc/prep/moe-cpu-offload-data-paths.md`](../prep/moe-cpu-offload-data-paths.md) §1, §2
* Related: ADR-0003, ADR-0005, ADR-0020, ADR-0023
