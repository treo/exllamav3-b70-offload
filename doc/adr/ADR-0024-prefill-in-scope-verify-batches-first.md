# ADR-0024: Prefill is in scope, and verify batches come first

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `prefill`, `scope`, `speculative-decoding`

## Context

Prefill on the card was first written as a non-goal, on the argument that a chunk-wide GEMM never becomes
compute-bound at this model's row distribution. The number behind that argument was wrong twice. It read 272
rows per expert, which is MACs per byte for a one-byte-per-weight format, while trellis weights are 0.375
bytes each and the integer route spends four byte-MACs per weight-token. The corrected bar is about 26 rows per
expert at the copy peak, or about 59 at the rate this kernel family achieves. It also used a per-layer mean
mixture, which flattens the hot tail. Recomputed per layer against live routing at 2048 rows, 124 of 512
experts reach 26 rows and carry 94.3 percent of the picks, and 81 reach 59 rows carrying 86 percent.

Separately, the cheapest measured prefill-adjacent win does not need a big-M kernel at all. Verification
batches, where a draft head proposes M tokens and the model scores them in one step, already exist as an engine
path. Batching M rows on the card costs 1.34, 1.53 and 1.85 times less than M independent decodes at M of 4, 8
and 16, and about 2.5 times less at M of 32.

## Decision

We will treat card prefill as in scope, and we will build the verify and MTP batch case first, at M of 4 to 16.
Chunk-wide big-M GEMM stays behind the row-eligibility bar, computed per layer from live routing at the chunk
size in use. We will not reuse a Qwen-shaped prefill measurement for a GLM geometry, and we will not charge a
shared expert the per-bucket traffic law, because it is a dense path.

## Consequences

Positive:

* The near-term win is on a path the engine already dispatches, with its own worker and budget per model
  component, which is where ADR-0007's keyed registration pays.
* The mechanism is deduplication rather than tile width: 160 picks at M of 16 hit 73 experts while rows per
  expert is only 2.19, so the existing 16-row tile is already the right shape. Perfect dedup bounds the gain at
  4.9 times.
* Eligibility is predictable at load from the routing profile and the chunk size, so the planner can say which
  experts will qualify before any kernel is written.

Negative:

* The win was priced from Qwen live routing, and the checkpoints that ship a draft head are GLM ones. The
  Qwen3.8 exports carry no MTP layer and no MTP tensors, so the prize is currently available where it was not
  measured. Either the batch cost is re-priced on GLM routing, or the intended drafting mechanism on Qwen has
  to be identified.
* A draft head is not free. GLM's MTP layer is a 43rd MoE layer routing to 288 experts of its own, at the same
  9 MiB expert size.
* M of 16 is where the card stops being free: a batched layer costs 310.6 µs against the parent's 195.6 µs of
  non-expert work, so the gain is real only while the parent's leg stays longer.
* A GLM token pays eight routed picks plus one shared expert, about 12.5 percent more expert work than topk
  alone implies, and that share belongs to the parent's dense path rather than to placement.

Neutral:

* This record is reopened by a routing distribution flatter than the live trace, which fine-tuned and
  reinforced-training checkpoints produce, and which moves the prize back toward deduplication batching and away
  from matrix-unit prefill.

## Alternatives considered

* Keep prefill out of scope: superseded by operator direction and by the corrected eligibility bar.
* Build a chunk-wide GEMM first: rejected, because both mechanisms that would beat the per-bucket traffic law
  were built and lost. See ADR-0034.
* Treat the shared expert as another bucketed MoE path: rejected as an error, not a preference. Charging it the
  16-row bucket law produced 256 re-reads of 25 MiB per layer, about 1.5 s per chunk of fiction.

## Links

* [`doc/port/b70-decisions.md`](../port/b70-decisions.md) D22, D23
* [`doc/port/b70-prefill.md`](../port/b70-prefill.md) §2, §3
* [`notes/b70/out_verify_batch.txt`](../../notes/b70/out_verify_batch.txt),
  [`notes/b70/out_glm_geometry.txt`](../../notes/b70/out_glm_geometry.txt)
* Related: ADR-0007, ADR-0021, ADR-0029, ADR-0031, ADR-0034, ADR-0038

## Amendment

This record reversed a prior non-goal. The reversal is kept visible rather than edited to read as though the
plan always said prefill, because the reason for the reversal, a units error plus a collapsed distribution, is
the reusable finding.