# ADR-0029: Rows are bucketed by expert before any schedule choice

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `kernel`, `grid`, `cost-model`

## Context

The cost model says a layer's expert traffic is the union of the experts its rows touch, times each expert's byte
size. That is true only if the kernel reads an expert once per layer per step, whatever the number of rows that pick it.
It is a claim about the grid, not a property of memory.

The vendor's own decode kernels are the cautionary case: they are laid out per route, one work-item per routed pick,
and rely on cache to absorb the duplicates. Only their grouped prefill kernels bucket by expert. On a batch of 8 with
topk 10, a per-route grid reads about five times the modelled bytes, which makes every concurrency figure in
this plan optimistic in exactly the batch band where the card becomes the binding worker, which ADR-0048 places
between batch 16 and 64.

Two measured facts make bucketing cheap here. The parent already sorts each row's picks by expert id before any
kernel runs, and the payoff is large: at M of 16, 160 picks hit 73 experts rather than 160, so dedup alone is worth
up to 4.9 times on the batched path. The related trap is activation traffic: with one output column per work-item,
each item re-reads the whole activation row, which is a megabyte of cache traffic per route for a 4 KiB tensor.

## Decision

We will bucket rows by expert as a precondition of the cost model, not as an optimisation. One bucket is one
expert plus its assigned row range, and it is the unit of grid work, built in the expert-sorted order the parent already
produces, and the activation gather is folded into the load rather than done as a separate pass. Every batch gate
reports bytes actually read, not bytes touched. Where a large-row case needs a different grid, we will run it as a
second schedule over one unpack path, and not as a second arithmetic implementation.

## Consequences

Positive:

* The byte floor the placement and concurrency models rest on becomes a measured property of the kernel.
* Bucketing is what makes the locality rules of ADR-0028 expressible, because consecutive items in a bucket read
  neighbouring tiles of one expert.
* The bucketing pass is small and unit-testable on its own: the permutation must be stable, and the counts must sum
  to the number of picks.

Negative:

* One more device pass, `b70_bucket_sel`, in front of every job, with its own correctness surface.
* A second schedule over one unpack path still needs the locality property twice. The grid differs between the
  small-row and large-row forms, so the ordering rules of ADR-0028 must hold in both, and each form is scored
  against the same byte floor.
* Padding a bucket is forbidden and this must be enforced by the tiler, not by convention. 24 rows expressed as one
  padded 32-row launch costs 61.8 µs, while 16 plus 8 as two buckets costs about 38 µs.
* Rows per expert must be logged per layer, because the same distribution decides matrix-unit eligibility in
  ADR-0024 and a bucketing bug moves both at once.

Neutral:

* Sorting on the host is not an option, because it needs a readback and the parent must never block. The bucket
  list is built on the device.

## Alternatives considered

* A per-route grid, as the vendor's decode kernels use: rejected, it reads an expert once per pick and breaks the
  byte model at exactly the batch sizes that matter.
* Rely on L2 to absorb duplicate reads: rejected, a prefill layer's resident set is about 750 MiB against a 24 MiB
  cache.
* Bucket by column band instead of by expert: rejected, because it dedups nothing across picks and splits the
  activation reuse that the expert bucket provides.
* Skip bucketing at batch 1, where each expert takes about one row: rejected, because it is a second grid
  layout to maintain for a case the bucketed form already handles.

## Links

* [`doc/port/b70-kernels.md`](../port/b70-kernels.md) §2b items 3 and 6, §3b
* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §12, byte-floor row
* [`notes/b70/out_verify_batch.txt`](../../notes/b70/out_verify_batch.txt),
  [`notes/b70/out_kernel_split.txt`](../../notes/b70/out_kernel_split.txt)
* [`doc/port/b70-harness.md`](../port/b70-harness.md) gate E23
* Related: ADR-0026, ADR-0028, ADR-0031, ADR-0036
