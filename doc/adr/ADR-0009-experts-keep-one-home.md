# ADR-0009: Experts keep one home, and homes stay disjoint

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `placement`, `capacity`

## Context

A *home* is the memory where an expert's bytes live and where that expert is computed. Four exist:
parent memory, card memory, host memory, and disk. An expert has exactly one home, and its home does
its arithmetic.

The original argument for one home was a rate argument: the two accelerators were said to read within
1.5 times of each other, so a replica on the second card buys only capacity that neither has.
That argument was spec-to-spec and did not survive measurement. Footprint-matched, the homes are 3.2
times apart on Qwen3.8 and 7 times apart on GLM. On the parent the measured rate gap is wider still:
its expert leg is kernel-bound at about 190 GB/s while it streams non-expert weights at 860 GB/s.

The surviving argument is a capacity argument, and it is stronger where capacity is scarce. Every GiB
that holds a duplicate is a GiB that cannot hold a different expert. On an oversized model that GiB is
the difference between the CPU computing a pick in 199 µs and the card computing it in about 31 µs.
One measured case runs against this argument: Qwen3.8 at 2.68 bpw reaches full residency with about
12 GiB of parent memory to spare, and spare capacity has no cheap use other than a replica.

## Decision

We will give every expert exactly one home, with no replication between the two accelerators. Placement
is a partition over three or four homes, cut on one frequency-sorted permutation per layer. We will add
a test that asserts the two device sets are disjoint and that each device's local id mapping is
injective.

## Consequences

Positive:

* Capacity goes to distinct experts, which is the term that decides the residue.
* Membership decides routing, so no per-pick steering logic exists to load-balance or to get wrong.
* The partition is expressible with existing machinery: two cut points on the sorted permutation, which
  is the existing translate generalised from a threshold to a range.

Negative:

* A row whose picks sit in more than one home is computed in pieces, with one job per home and a
  duplicated activation payload. That is the normal case, not an edge case. See ADR-0023.
* Load imbalance cannot be fixed by moving a pick. It is fixed offline by moving a home.
* A replica is the only mechanism that decouples placement from load-balancing, and this decision
  declines it for now. Gate E20 promotes it if the surplus survives real context lengths.

Neutral:

* A host copy stays for card-resident experts by default, because the host arena is also the source for
  admission and for streamed prefill. Dropping it is an opt-in mode that forbids eviction. See
  ADR-0016.
* Group-limited routing, where a router confines each token to `topk_group` of `n_group` groups, bounds
  how many homes a token can touch. That is a placement lever this record did not consider, so the first
  model that ships `n_group > 1` reopens it.

## Alternatives considered

* Replicate the hottest experts on both cards and steer each pick to the busier home: deferred behind
  gate E20, and only for models with measured surplus capacity. It must beat load-balanced placement by
  more than 5 percent at batch 4 or higher to justify abandoning disjointness.
* Split one expert across tiers by 128-column band: rejected, because an expert is 1 to 9 MiB against
  tier capacities three orders larger, so granularity is already about a thousand experts per tier, and
  striping needs a second partial-combine path.
* Let the card hold a replica of the parent's hot slice so that routing never spans: rejected, because
  that is replication with the same cost and a worse capacity trade.

## Links

* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §2.1, §2.1a
* [`notes/b70/out_parent_leg.txt`](../../notes/b70/out_parent_leg.txt),
  [`notes/b70/out_placement.txt`](../../notes/b70/out_placement.txt)
* [`doc/port/b70-harness.md`](../port/b70-harness.md) gate E20
* Related: ADR-0011, ADR-0012, ADR-0014, ADR-0023