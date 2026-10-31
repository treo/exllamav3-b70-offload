# ADR-0034: Rejected: the three escapes for the 16-row traffic law

- Status: Rejected
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `kernel`, `prefill`, `refuted`, `registers`

## Context

The 16-row launch cap of ADR-0031 re-reads an expert's weights once per 16 rows, which is a 7.01 times traffic
amplification at 2048 rows and 26.29 times at 8192 rows. Three mechanisms were designed to remove that re-read. All
three were built, all three were measured bit-exact where that was possible, and all three lost. They are recorded here
as rejected so that the same three ideas are not rebuilt from the same arithmetic, which is what made them look
promising.

The reason all three lost is one fact that none of the designs contained: at these shapes the binding resource is the
register file and device fill, not bytes.

## Decision

We will not implement staged local-memory reads of weight tiles, we will not implement items that carry more than 16
rows, and we will not implement a shared weight stream across row buckets inside one item. 16-row launches, with
split-K for fill and co-resident slabs at scale, remain the schedule. Reopening any of the three requires a kernel that
bends the additive law itself, not a new argument about why the law is weak.

## Consequences

What each mechanism cost, and why:

* Local-memory staging: 1.52, 2.52 and 6.02 times slower than reading the same tiles globally at 20, 40 and 80 KiB per
  group, and the penalty grows with tile size. The instruction census gives the mechanism. The staged body is 1177
  instructions against 719 for the identical global walk, because it adds 80 local-memory loads and 89 local-memory
  stores on top of the 80 global loads it was meant to replace. Local memory is also capped at 128 KiB per group, which
  cannot hold a 0.49 MiB projection tile. One related hazard came from the vendor's post-mortem and applies to any future
  attempt: a named barrier orders execution but does not make local-memory stores visible to other sub-groups, so a
  cross-sub-group exchange needs a full barrier.
* Rows-deep items: a clean-room kernel with the row dimension inside the item, 12 of 12 cells bit-exact, measured 1.07,
  1.47 and 2.01 times worse than bucketing at 16, 32 and 64 rows. Its spill size is 0 bytes at 8 and 16 rows, 1792 at 32
  and 7808 at 64, so the cliff sits exactly where the 16-row cap sits, because accumulators and the matrix operand both
  grow with rows. Streaming the operand instead of holding it removes the spill at 32 rows and costs 29 percent, so mild
  spill is cheaper than the fix.
* A shared weight stream across buckets: implemented as specced, all buckets bit-exact, and 53.3 µs against 41.5 µs for
  additive launches at 32 rows. Starving the prefetch ring makes it spill-free and brings it to 44.4 µs, within 5 percent
  of additive, which is the honest form of the refutation. Sharing rows is bought with prefetch, and at the rate this
  kernel already achieves the transaction is a wash.

Two measurement lessons travel with these results, and both are why the third verdict is trustworthy. The first
apparent fault was a host-side allocation sized for one bucket while the kernel read several, which produced a
non-monotonic "compiler edge case" pattern that was pure address-layout noise. Read the kernel log before theorising
about the driver. The second is that a faulted and reset card is indistinguishable from an un-ramped one, which is what
the fixed anchor in the harness exists to separate.

## Alternatives considered

These are the three rejected mechanisms themselves, each of which had a written rationale before it was built:

* Stage one expert's tile in local memory and loop the row slabs: rejected as above, and the design that proposed it is
  superseded by a group-mapped global read. A layout designed for local-memory broadcast, as the vendor's kernels use,
  is untested here. That is the honest scope limit of this rejection.
* Put rows inside the item so a tile is read once per chunk: rejected as above.
* Reuse one unpacked tile across several row buckets in one item: rejected as above.
* Reduce the amplification by holding more experts resident so fewer launches are needed: not a kernel mechanism, and
  already the subject of ADR-0010 and ADR-0013.

## Links

* [`notes/b70/out_prefill_gemm.txt`](../../notes/b70/out_prefill_gemm.txt),
  [`notes/b70/out_prefill_slm.txt`](../../notes/b70/out_prefill_slm.txt),
  [`notes/b70/out_probe_xmx.txt`](../../notes/b70/out_probe_xmx.txt),
  [`notes/b70/out_e29_share.txt`](../../notes/b70/out_e29_share.txt)
* [`doc/port/b70-decode-closeout.md`](../port/b70-decode-closeout.md) E29 result
* [`doc/port/b70-prefill.md`](../port/b70-prefill.md) §4a, §6
* [`notes/b70/LESSONS.md`](../../notes/b70/LESSONS.md) item 48, item 68, item 70, item 72
* Related: ADR-0026, ADR-0029, ADR-0031, ADR-0035

## Amendment

One number first reported from the staging probe, that concurrent global re-reads were cheaper than unique reads, is
retracted as a measurement. Both probe bodies turned out to be dominated by scalar address arithmetic, so the result
said nothing about memory. It survives only as a hypothesis for the co-scheduling test. That test measured a benefit of 5
to 16 percent, where the retracted figure had implied about 25 percent of cheaper re-reads.