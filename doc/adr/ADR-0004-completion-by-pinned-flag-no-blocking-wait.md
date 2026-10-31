# ADR-0004: Completion comes from a pinned flag, and no job path blocks

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `protocol`, `latency`

## Context

A decode job on the card is small. The measured decode layer costs 43.6 µs at batch 1, and a single
projection is 14.0 µs. A handshake round trip is therefore a first-order term, not overhead. Three
completion mechanisms are available on this box, and their measured costs differ by a factor of eight.

A SYCL event or queue wait costs 24.8 µs for a job that does nothing else. Polling a flag that the
device wrote in pinned memory costs 5.0 to 6.3 µs. A resident kernel that watches a doorbell costs a
3.2 µs round trip, at the price of holding the device. The CPU path today costs about 20 µs per layer
for an empty job, and the parent's own non-expert work per layer is 141.9 µs on Qwen3.8 at 2.05 bpw
and 195.6 µs at 2.68. A 25 µs tax per layer would consume the whole hiding margin that justifies the
port.

The failure mode matters as much as the number: a blocking wait that sneaks into a job path is silent.
It shows up as a uniform slowdown, and the CPU-path history shows that every unexplained slowdown was
handshake or policy related, never kernel related.

## Decision

We will publish completion as a flag in pinned memory and observe it by polling. We will use no
blocking wait, no event wait and no queue synchronisation on any job path. Blocking waits belong to
setup, teardown, and the engine thread's idle path only. The build counts blocking calls in an
instrumented configuration and asserts that the count stays zero during generation.

## Consequences

Positive:

* A card job costs 5.0 to 8.9 µs of handshake instead of 24.8 µs, so the handshake hides behind the
  parent's per-layer work.
* The rule is machine-checked by an instrumented build, so a regression fails a test instead of
  appearing as a tuning puzzle.
* The same flag region serves the doorbell and the completion, so no second signalling path exists.

Negative:

* Polling spends host cycles. The polling core is the single reserved host core, and its budget is
  already tight. See ADR-0007.
* The gate must be tightened if a future change makes jobs larger, because a fixed 6 µs is a
  diminishing fraction of a 300 µs job.

Neutral:

* The resident engine, at 3.2 µs, saves about 2 to 5 µs per layer over the flag path. That is inside
  the noise of the measurements that would justify it, so it stays behind a gate. See ADR-0008.

## Alternatives considered

* `sycl::event::wait()` or queue synchronisation per job: rejected, at 24.8 µs measured against the
  whole job.
* A resident kernel with a doorbell: deferred, not rejected, and gated on a measured saving of at
  least 20 µs per token. It also needs device-loss and drain semantics that the flag path does not.
* A second `register_host_memory` call per job: rejected, because a second registration costs the same
  order as a blocking wait.
* Timing the job with device clocks: not available. `clock<clock_scope::device>` is missing in this
  runtime, so timing uses host timestamps around the flag.

## Links

* [`notes/b70/out_transport.txt`](../../notes/b70/out_transport.txt),
  [`notes/b70/out_notify.txt`](../../notes/b70/out_notify.txt),
  [`notes/b70/out_doorbell.txt`](../../notes/b70/out_doorbell.txt)
* [`notes/b70/LESSONS.md`](../../notes/b70/LESSONS.md) item 1, item 10
* Related: ADR-0003, ADR-0005, ADR-0008, ADR-0039