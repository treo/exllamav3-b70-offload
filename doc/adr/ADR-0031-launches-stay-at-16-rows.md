# ADR-0031: Launches stay at 16 rows above 16 rows

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `kernel`, `prefill`, `schedule`, `registers`

## Context

The selected kernel computes a 16-row slab per work-item, and 16 is not a taste. The register file is 128 entries per
thread, and accumulators plus the matrix operand plus the prefetch ring fill it at exactly that row count. Spill
measures 0 bytes at 8 and 16 rows, 1792 bytes at 32 and 7808 bytes at 64. Consequently the cost of more rows is
additive in launches: twice the rows cost 2.00 times, three times cost 2.98 and four times cost 3.96, with each bucket
bit-exact against its own output slice.

That law has an uncomfortable implication for prefill. At 2048 rows it re-reads each touched expert 7.01 times, and at
8192 rows 26.29 times. Two mechanisms designed to remove the re-reads were built and measured, and both lost. See
ADR-0034. The reason they lost is the finding that decides this record: at these shapes the binding resource is
register pressure and device fill, not bytes. A controlled test showed 2560 work-items cost the same against 6.6 MiB
and against 13.2 MiB of weights, 1.3 percent apart.

Where the traffic does start to bind is scale. At 512 experts a launch holds 251 MiB of weights per projection, ten
times the cache, and there co-scheduling the row buckets inside one launch wins 9 to 16 percent.

## Decision

We will keep 16-row launches above 16 rows, and choose split-K to fill the device. We will not pad a bucket. When one
launch's weight footprint greatly exceeds the cache, measured to flip near four times the cache rather than at the ten
times first assumed, we will issue those 16-row buckets as co-resident slabs of one launch, with the slab index varying
fastest. We will budget the resulting traffic amplification as capacity and energy, not as time.

## Consequences

Positive:

* The kernel stays spill-free, which is the condition the whole register-budget argument turns on.
* Co-scheduling is worth 5 to 6 percent at the actual prefill operating point, measured at 128 experts and 64 rows, and
  0.943 times the sequential form. It is worth 9 to 16 percent at 512 experts and nothing at 16 experts, where both
  forms sit near device capacity.
* The dispatch rule is stated in the quantity that decides it, which is experts per launch, and is measured at three
  rungs plus a second geometry: GLM at 64 experts and 64 rows measures 0.873 times.
* The same fill logic that governs fusion governs slabs: at 8 experts, where one bucket under-fills, one launch of 1280
  items beats two of 640 by 1.59 times.

Negative:

* Device traffic is real and unpaid in time terms, so it shows up in energy. A configuration can look fast per launch
  and cost 7 times the DRAM bytes, which is why the power channel of ADR-0041 carries it.
* The sign of a schedule comparison at a convenient size is not the sign at the operating size, so each new geometry
  needs its own rung before the rule is applied. Two earlier conclusions in this chapter reversed on exactly this axis.
* Slab dispatch is a grid change with its own partial-sum indexing, and it must reproduce the control's number at one
  slab to be interpretable at more.

Neutral:

* The amplification law is a property of this kernel family at these shapes. A kernel that bends it reopens this
  record, and no candidate for such a kernel survives measurement today.

## Alternatives considered

* One wider launch: implemented and measured, bit-exact at 24 and 32 rows, and the slowest option measured at 64.8 µs
  against 41.5 µs for two 16-row launches.
* Rows-deep items that read each tile once per chunk: rejected, 1.07, 1.47 and 2.01 times worse at 16, 32 and 64 rows.
  See ADR-0034.
* A shared weight stream across row buckets inside one item: rejected, 53.3 µs against 41.5 µs, because sharing rows is
  bought with the prefetch ring and the trade is a wash at best. See ADR-0034.
* Sequential buckets always: rejected at high expert counts, because it gives up a measured 9 to 16 percent.

## Links

* [`doc/port/b70-decisions.md`](../port/b70-decisions.md) D17
* [`notes/b70/out_probe_gemm.txt`](../../notes/b70/out_probe_gemm.txt),
  [`notes/b70/out_probe_gemm_midE.txt`](../../notes/b70/out_probe_gemm_midE.txt),
  [`notes/b70/out_probe_gemm_glm.txt`](../../notes/b70/out_probe_gemm_glm.txt),
  [`notes/b70/out_rows_gt16.txt`](../../notes/b70/out_rows_gt16.txt),
  [`notes/b70/out_prefill_scale.txt`](../../notes/b70/out_prefill_scale.txt)
* [`doc/port/b70-prefill.md`](../port/b70-prefill.md) §3, §3a
* Related: ADR-0024, ADR-0029, ADR-0030, ADR-0034, ADR-0036

## Amendment

This record first read "co-scheduling does not buy re-use", from a measurement at 16 experts. The verdict reversed at
512 experts and was narrowed at the operating point, so the rule is now conditional on experts per launch. The
invented threshold of ten times the cache was replaced by a measured flip near four times.