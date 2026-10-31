# ADR-0022: Whole-layer decode offload is a split, not a path

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `decode`, `modes`, `cleanup`

## Context

The engine has two offload modes. The split mode puts a tail slice of each layer's experts on the worker, and
uses the fused decode handoff, where the parent's kernel writes the payload directly into pinned memory and
the result is folded back in place. The whole-layer mode puts every routed expert of a layer on the worker,
and uses an older copy path built from explicit host-to-device and device-to-host copies.

The copy path costs about 26 µs per layer of parent-side device work against the fused path's 20 µs, and the
gap is pure protocol overhead. It was tolerated because the copy path was the only one that existed before the
fused handoff, and because the compute behind it was 200 µs or more. On a card the compute behind it is 43.6
µs at batch 1, so a 6 µs protocol penalty is a seventh of the job.

The two modes are also not independent features: a layer with all of its experts offloaded is the split with
the cut point at zero.

## Decision

We will not carry the whole-layer copy path over to the card. We will express whole-layer offload as a split
size of zero local experts on the fused path, which already handles an arbitrary cut point, and we will let
the parent's own shared-expert and resident work provide the overlap exactly as the split mode does today.

## Consequences

Positive:

* One decode handoff exists for the card, so the payload shape, the flag protocol and the tests are single
  sourced. See ADR-0019.
* The 6 µs per layer protocol gap does not come to the card at all.
* Empty jobs keep the fused path's property of writing no payload and skipping the readback.

Negative:

* The whole-layer mode's existing behaviours must be shown to survive the change, in particular the case
  where a layer has no parent-resident expert left to overlap with. That is the one configuration where the
  fused path has nothing to hide behind, and it needs its own measurement rather than an assumption.
* Two engine flags now select one mechanism, so the compatibility mapping has to be documented and the older
  flag has to keep working.

Neutral:

* The copy path stays in the tree for the CPU worker, where it is in use and where its cost is a small
  fraction of the compute behind it.

## Alternatives considered

* Port the copy path as well: rejected, because it duplicates the handoff for a configuration the split mode
  already expresses.
* Make the card refuse whole-layer offload: rejected, because it is a legitimate configuration for a small
  model whose experts all fit one card, and refusing it would push users onto the CPU worker.
* Rewrite the CPU path onto the fused handoff in the same change: deferred, because it touches a working path
  that is the numeric oracle for the new one.

## Links

* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §3 P1
* [`doc/prep/moe-cpu-offload-data-paths.md`](../prep/moe-cpu-offload-data-paths.md) §3
* [`doc/prep/measured-costs.md`](../prep/measured-costs.md) §4
* Related: ADR-0019, ADR-0009, ADR-0040

## Amendment

The measurement that motivated this record, 26 µs against 20 µs, is a CPU-path measurement. It is used here as
a relative protocol cost, which is the only claim it supports, and not as a card-side prediction.