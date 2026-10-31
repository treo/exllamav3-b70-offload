# ADR-0008: The shipping execution tier is one command list per job

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `execution-model`, `latency`

## Context

Three ways exist to run one job on the card, and they differ in how the phases of a job are separated
and in what they cost.

Tier T0 issues each phase as a separate kernel: bucket, gate and up, transform and activation, down,
accumulate, publish. It costs about 2 µs of host time per submission and 2 to 5 µs of device turnaround
per phase. Tier T1 submits one pre-recorded graph or reused command list per job, rebuilt only when the
shape class changes. It measures 5.0 to 6.3 µs end to end for an empty job, and 7.6 to 9 µs with a
16 KiB transfer. Tier T2 runs a resident kernel that watches a doorbell, and costs a 3.2 µs round trip.

The gap that matters is between T1 and T2: about 2 to 5 µs per layer. The measurement noise on this box
between windows is larger than that, in one recorded case by a factor of 2.3. A tier choice that cannot
be measured on the target workload is not a decision, so it must be gated rather than adopted.

T2 also permanently occupies the card, and its phases are separated by device-wide barriers inside the
resident kernel. Card-side barriers are expensive here: 1.6 µs at 256 work-items, 2.5 µs at 1024 and
6.2 µs at the 2048 capacity, against a 2.9 µs launch.

## Decision

We will ship T1, one reused command list per job. T0 is the first thing that operates at all, because it
is the honest baseline and the easiest place to bisect a wrong number. T2 stays behind a gate that
requires a measured saving of at least 20 µs per token, and requires drain and device-loss evidence.

## Consequences

Positive:

* T1 removes the phase-boundary cost of T0 without occupying the card, so a second client of the device
  is not blocked.
* Command-list rebuild is triggered by shape class, so the cost is bounded by the number of distinct
  shapes and not by the number of jobs.
* Keeping T2 gated leaves a measured upgrade path for later, with the instrument to price it already
  written.

Negative:

* T1 needs the graph or command-list path in this toolchain, which is experimental. A capability probe
  at startup decides the tier, so the fallback must stay working.
* A queue error surfaces per submission rather than per phase, which makes T0 the bisect tool and T1
  the configuration in which some bugs appear.
* The command-list cache is keyed by shape, so an unexpected shape spread becomes a build-time cost
  during generation. See ADR-0032.

Neutral:

* The engine thread spins on `data_ready` in host memory with an ordinary host load, exactly as the CPU
  worker does. Notification does not use the link in any tier.
* The gate's unit is weaker than it first looks, and this record states it rather than smoothing it over. At 48 MoE
  layers, 20 µs per token is about 0.4 µs per layer. The projected 2 to 5 µs per layer clears the bar on
  arithmetic alone, so what the gate tests is a realised end-to-end saving against the occupancy and drain cost, not
  the projected one. Restating the gate in one unit is open work.

## Alternatives considered

* Ship T0: rejected as the shipping tier, because about 2 to 5 µs per phase across five to eight phases
  is most of the handshake budget, but adopted as the bring-up tier.
* Ship T2 now: rejected, because 2 to 5 µs per layer is below the resolution of the measurements that
  justifies a permanently occupied card, a spin barrier and a drain test.
* Choose the tier at run time per job: rejected, because a per-job tier decision adds a branch to the
  path it is meant to speed up.

## Links

* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §5
* [`notes/b70/out_transport.txt`](../../notes/b70/out_transport.txt),
  [`notes/b70/out_notify.txt`](../../notes/b70/out_notify.txt),
  [`notes/b70/out_resident.txt`](../../notes/b70/out_resident.txt),
  [`notes/b70/out_e25c_barrier.txt`](../../notes/b70/out_e25c_barrier.txt)
* Related: ADR-0004, ADR-0035, ADR-0039
