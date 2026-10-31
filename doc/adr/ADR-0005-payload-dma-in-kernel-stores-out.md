# ADR-0005: Payload enters by DMA and leaves by kernel stores

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `protocol`, `memory`, `latency`

## Context

A job crosses the device boundary twice: the activations go out to the card, and the partial result
comes back. Both directions have two mechanisms, and on this card they are not symmetric.

A card kernel that reads host memory is latency-bound. Sixteen KiB read as one dependent chain of
loads costs 258 to 283 µs, against about 2 µs for the same bytes moved by the copy engine. A card
kernel that writes host memory is not latency-bound: plain volatile stores reach host memory reliably,
at 100 of 100 repetitions, cold lines and host-dirtied lines, in process and across processes. Moving
16 KiB out with stores plus a flag costs 7.0 to 9.0 µs end to end.

The asymmetry is the whole decision. The inbound direction must use the copy engine, and the outbound
direction can use stores, which removes a device-to-host copy, a second submission and an
extra completion from the return path.

## Decision

We will move a job's payload in with one contiguous copy-engine transfer into card memory, and we will
move its result out with kernel stores into the pinned slot. The store sequence in the last kernel is:
write the payload, apply a system-scope acquire-release fence, then write the flag. We will not let a
kernel follow host pointers to read an input.

## Consequences

Positive:

* The inbound hop costs 7.6 to 8.9 µs for 16 KiB including the flag, against 258 to 283 µs for the
  kernel-read form. See [`notes/b70/out_transport.txt`](../../notes/b70/out_transport.txt).
* The outbound hop needs no copy-engine transfer, so it does not contend with weight transfers, and no
  extra submission means no extra latency term.
* The result lands where the parent's collect kernel already reads it, so the collect path is
  unchanged.

Negative:

* The two directions now use two different engines, so completion for the inbound half is ordered by
  the queue and completion for the outbound half is ordered by a fence. Both need their own test.
* The fence is load-bearing and invisible. A future edit that replaces the fenced volatile store with
  a library atomic breaks the device instead of breaking the test. See ADR-0006.
* Large outbound payloads eventually make the store path the limit, which is why fp16 output is kept
  as an option. See ADR-0020.

Neutral:

* Wide stores are used deliberately, as the CUDA path uses `int4` stores.

## Alternatives considered

* Kernel reads for the inbound payload: rejected, 258 to 283 µs measured, and the failure is
  latency-bound rather than bandwidth-bound, so more lanes make it worse rather than better.
* A copy-engine transfer for the outbound partial: rejected, because it adds a submission and a
  completion to the return path for no measured gain, and the stores already cost about 2 µs.
* Direct peer-to-peer between the two GPUs: not available. Cross-vendor P2P on this root complex is
  unproven, and it is the named open item in ADR-0025.

## Links

* [`notes/b70/out_stores.txt`](../../notes/b70/out_stores.txt),
  [`notes/b70/out_stores2.txt`](../../notes/b70/out_stores2.txt),
  [`notes/b70/out_unreg.txt`](../../notes/b70/out_unreg.txt)
* [`notes/b70/LESSONS.md`](../../notes/b70/LESSONS.md) item 7
* Related: ADR-0004, ADR-0006, ADR-0019