# ADR-0041: Board power is the utilisation channel

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `harness`, `power`, `thermal`

## Context

Throughput cannot tell the difference between a card that is working, a card that is spinning, and a card that is
re-reading the same weights. All three can print the same tokens per second. Energy per token separates them, and the
sensors are already exposed: board energy in microjoules, package and memory temperatures, the power limit, and engine
activity and clock residency through the vendor's system-management interface.

Two measured facts make the channel usable rather than decorative. A process with a live API context draws 45.6 W while
the same board with no context draws 14.6 W, so a naive "power during generation" figure attributes 31 W of context
overhead to the kernels. And the box is power-limited under sustained decode: 285 W mean against a 275 W cap, with
compute units at 97 to 100 percent and memory bandwidth at 54 percent of peak, and kernel times drifting only 0.5 percent
over 150 seconds.

## Decision

We will treat power as a first-class measurement channel. A background sampler reads the sensors every 10 to 20 ms into a
timestamped log, the benchmark writes phase markers, and the report integrates energy per phase. Every throughput figure
is published with joules per token and joules per GiB of expert weights moved. The baseline is the same process with the
engine parked, never a cold board. Throttling is flagged by the temperature slope, not by wall time alone.

## Consequences

Positive:

* A resident engine that spins without work becomes visible, which is exactly the failure mode that ADR-0008 keeps behind a
  gate.
* The traffic amplification that ADR-0031 accepts as a time cost stops being invisible, because it is charged to energy.
* It gives a decision rule for optimisation: work eliminated beats latency hidden, because speed cannot be bought without
  spending the same watts on a power-capped part.
* A prefill run that never rises above about 120 W is not using the card, whatever it reports for throughput.

Negative:

* The published energy figures depend on the parked-engine baseline, so a change in how the engine is parked invalidates
  them, and that baseline must be recorded with the run.
* Hour-scale thermals are unmeasured. In the 150 second soak the core plateaued at 71 °C while memory at 86 °C and
  voltage-regulator at 94 °C were still climbing, so a plan that raises sustained load carries an unquantified risk in the
  voltage-regulator stage.
* Two questions this channel raises belong to the operator rather than to the design: whether about 87 W sustained is
  permitted in the target chassis, and how the card's draw interacts with the parent's in a shared power budget.

Neutral:

* Engine activity and stall counters complement power rather than replace it, because they separate "busy" from "stalled" but
  not "useful work" from "re-read".

## Alternatives considered

* Rely on throughput plus a utilisation percentage: rejected, because a device can be at 100 percent utilisation while
  doing redundant work, which is the specific failure this channel exists to catch.
* Measure energy at the wall socket: rejected, because it includes the parent, the host and the platform, and the
  difference between two configurations is small relative to that floor.
* Detect throttling from clock frequency alone: rejected as a sole signal, because the observed droop is about 1 percent,
  while the temperature slope is unmistakable.

## Links

* [`doc/port/b70-harness.md`](../port/b70-harness.md) Level U
* [`notes/b70/out_sustained_power.txt`](../../notes/b70/out_sustained_power.txt)
* [`notes/b70/LESSONS.md`](../../notes/b70/LESSONS.md) item 11
* Related: ADR-0008, ADR-0031, ADR-0039, ADR-0046

## Amendment

An earlier note in the plan warned that all decode rates were warm-window rather than soak measurements. The 150 second
soak retired that caveat for kernel time and replaced it with a narrower one, which is that hour-scale memory and
voltage-regulator temperatures remain unmeasured.