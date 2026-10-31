# ADR-0028: Tiles keep native order, and the locality rules bind

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `layout`, `locality`, `kernel`, `allocation`

## Context

Two independent properties change how fast the card reads weights, and they were measured on the same bytes.

The first is tile order. Banding, which rewrites a tile index so that one item's k-step drops from 3200 or 12288
bytes to 640 to 768 bytes, was measured against native order on two geometries across six working-set sizes. The
result is 0.96 to 1.05 times, with no consistent sign, and the instrument's own configuration variance moves
absolute rates by about 2 times, which is larger than the effect.

The second is the mapping of work-items to tiles. Keeping consecutive items on consecutive fragments of one
expert rather than spreading them across the tier is worth 1.08 to 1.99 times, measured across both geometries and
all six footprints, and never once below 1.08. Absolute rates for orientation: 132 to 292 GB/s scattered, and 216
to 558 GB/s clustered. That is a scheduling and allocation property, not a format property.

## Decision

We will store expert tiles in native order, with no load-time repack, and we will report that answer from one
function that the uploader, the spill reader and any transfer to the parent all read. We will treat the locality
rules as binding rather than advisory: grid order equals memory order, one layer's experts occupy one contiguous
block of card memory in expert order, one work-group covers one expert's fragment range, and cache-control hints
are measured only as an increment on top of those three.

## Consequences

Positive:

* Card bytes stay interchangeable with parent bytes, so an expert can move between the two devices as a copy. This
  protects the home-transfer economics of ADR-0014.
* No staging interaction and no restore pass, which is what keeps ADR-0021's retirement of streaming clean.
* The lever that works is free. Contiguous per-layer allocation is a loader choice, and a grid-order choice is one
  line. The failure mode this prevents is a GEMV that measures about 200 GB/s, where the cause turns out to be
  one line of ordering.
* The rules are falsifiable. One measurement, the same kernel in both orderings at one footprint, must land in the
  1.08 to 1.99 times band. Landing at the bottom of the scattered band means the rules are not implemented, not that
  the card is slow.

Negative:

* The layout decision rests on engineering grounds rather than a closed measurement, and the null was established on
  thin tiles. At 5 and 6 bpw banding turns mildly positive, 1.06 to 1.07 times, so the rule must be re-tested at the
  deployment's actual rate.
* The intra-tile dword order of ADR-0027 is a different axis and can be confused with this one. Tile order is a
  streaming property, intra-tile order is an operand-assembly property, and only the second is being changed.
* Intel's own kernels repack for dequant ergonomics, with a wide mask-free inner loop as the reward. That is a
  different repack from the one measured here, it is untested on this format, and its price is the byte
  interchangeability this decision protects.

Neutral:

* Hot-set reuse across consecutive tokens is plausible and unmeasured. A batch-1 job reads about 12 MiB against a 24
  MiB L2, so the clustered figure can be a floor rather than a ceiling. The rate gate measures first-touch and
  repeated-expert conditions separately.
* A consistent win inside the real GEMV, large enough to pay for a load-time pass and for losing byte-identity,
  reopens the layout half of this record.

## Alternatives considered

* Band tiles at load for locality: rejected, no reliable gain, and it costs migration interchangeability.
* Allocate each expert separately in the device heap: rejected, because it scatters a job's eight to ten experts
  across a 32 GiB heap and forfeits the gain even when the kernel orders itself perfectly.
* Rely on evict-first cache hints and prefetch instead of ordering: rejected as a substitute, and kept as a
  measured increment, because hints were second-order at every footprint tested and prefetch was measured as
  harmful, at 0.58 times, on the decode loop.
* Defer both until the kernel works: rejected, because grid order is not separable from the kernel that measures it.

## Links

* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §2.2,
  [`doc/port/b70-kernels.md`](../port/b70-kernels.md) §3a
* [`notes/b70/out_rates_footprint.txt`](../../notes/b70/out_rates_footprint.txt),
  [`notes/b70/out_rates_footprint_hiq.txt`](../../notes/b70/out_rates_footprint_hiq.txt),
  [`notes/b70/out_rates_repeat.txt`](../../notes/b70/out_rates_repeat.txt)
* [`doc/port/b70-harness.md`](../port/b70-harness.md) gates E4, E4b, E4c, check A9
* [`notes/b70/LESSONS.md`](../../notes/b70/LESSONS.md) item 17, item 54
* Related: ADR-0026, ADR-0027, ADR-0029, ADR-0036, ADR-0039
