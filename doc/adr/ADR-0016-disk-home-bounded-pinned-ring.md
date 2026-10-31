# ADR-0016: The disk home uses a bounded pinned ring, and the host arena is capped

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `capacity`, `memory`, `oversized`

## Context

For a large model the expert set exceeds every tier. GLM-5.3-Flash at 3.05 bpw carries 108.84 GiB of
routed-expert trellis. This box has 31.9 GiB of card memory and 125.6 GiB of host DRAM, and the parent
holds a model of its own. A full host arena for that checkpoint leaves about 14 GiB for the parent
process, the pinned ring, in-flight weights and the page cache, which is not a working margin. An
attempted GLM chunked-prefill run with promotion on hard-hung this machine, so the risk is not
hypothetical.

At the same time, disk is not exotic on this box for this class of model: the read rate measured 5.0 to
5.2 GB/s, and a 117 GB checkpoint takes minutes to load anyway. The question is how to reach disk without
letting a transient allocation grow without bound during generation.

## Decision

We will treat disk as the fourth home, reached through a bounded pinned ring: read a chunk into pinned
memory, transfer it, and recycle the buffer. We will cap the host arena, and experts below the cap live
only on disk. The placement table records the home of every expert, so a miss knows whether to pay 655 µs
from host memory or about 2.5 ms from disk, and the eviction rule prefers a victim that still has a host
copy.

## Consequences

Positive:

* Host memory has a stated ceiling, so an oversized model degrades into a hit-rate problem instead of an
  out-of-memory crash.
* Two prices for one operation make eviction a policy instead of an accident.
* The existing loader's deferred and paged reads are reused, so the disk path is not a new I/O stack.

Negative:

* A disk admission is 2.5 ms and cannot be hidden inside a decode layer, so the admission budget and the
  break-even rule of ADR-0014 do the work and disk misses must be rare or prefetched.
* Ring sizing is a new knob with a real failure mode: too small starves the link, too large re-creates the
  memory problem the cap exists to prevent.
* The card's residency claim in every table must be re-derived for the deployment's context and batch,
  because the same model is oversized at 6.05 bpw and comfortable at 2.05 bpw.

Neutral:

* Scaling out is the intended fix for this class, and the curve is computed from real selection counts rather than
  argued: the
  CPU-served residue for GLM falls 19.6, 6.9 then 0.9 ms per token at one, two and three cards. Combining
  homes as a maximum rather than a sum then says the third card buys nothing until the parent's leg drops
  below about 135 µs per layer. See ADR-0037.
* Dropping the host arena entirely is an opt-in mode, offered only when every expert fits the card, and it
  forbids eviction because an evicted expert has nowhere to go.

## Alternatives considered

* An unbounded arena, as the CPU worker uses today: rejected, because 109 GiB of pinned or pageable arena
  on a 125 GiB box leaves no reserve for the parent, and the guard that refuses such a configuration is
  already in the loader path. See ADR-0045.
* Memory-map the checkpoint and let the page cache serve experts: rejected for the hot path, because the
  transfer to the card still needs a pinned buffer, and an unmapped page fault inside a job path puts
  disk latency in front of the parent.
* Keep only a subset of layers resident and leave the rest to the CPU permanently: rejected, because a
  layer with no resident expert pays the CPU rate on every token, which ADR-0013 prevents.

## Links

* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §4a
* [`notes/m_expert_capacity.txt`](../../notes/m_expert_capacity.txt),
  [`notes/scan_expert_capacity.py`](../../notes/scan_expert_capacity.py)
* [`notes/b70/mem_guard.py`](../../notes/b70/mem_guard.py)
* Related: ADR-0009, ADR-0010, ADR-0013, ADR-0014, ADR-0045