# ADR-0045: Load refuses a configuration the machine cannot hold

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `safety`, `load-path`, `memory`

## Context

Two failure classes in this work ended the same way, with the machine unavailable rather than with an error. An oversized
model with promotion enabled asked for a host arena of 109 GiB on a 125 GiB box and hard-hung it from a queue script,
because the guard that would have refused the run lived in the benchmark wrapper and the script did not call it. The other
class is quieter and equally expensive: the code assumes properties that nothing enforces. The per-expert byte layout is
derived from expert 0's dimensions, while the loader permits a different rate per matrix. Every offloaded layer is assumed
to share widths, and that one is asserted. Rates do vary per layer in a shipped checkpoint, from 2.5 to 3 bpw inside one
model, so the assumption is currently true by luck of the local data.

A load-time refusal is also how the engine already protects itself elsewhere: two low split sizes fail to load, which
reproduces a floor the operator had reported independently, and a tensor-parallel load with an offload requested raises
instead of quietly dropping the offload.

## Decision

We will validate at load and refuse rather than degrade. The build does a host-memory preflight before it allocates, called
from the shared loader path so that no entry point can bypass it, and it requires a reserve. It asserts uniform widths and
topk across registered layers, and adds the missing assertion that every expert inside a layer shares one rate. It asserts
that the flag region and slot sizes match the configured slot counts. It refuses a tensor-parallel load that requests an
offload. It refuses a placement whose predicted resident pick share is unreachable, and every refusal prints the numbers it
used.

## Consequences

Positive:

* A hard hang becomes a message with quantities in it, which is the difference between a rebooted machine and a diagnosed
  one.
* Enforcing the layout and rate assumptions is also what makes the admit-time conformance sample of ADR-0027 sufficient,
  because a layout surprise can then only arrive through the staged bytes, which are sampled.
* Printed refusals make a wrong prediction attributable, which is what ADR-0014's offline planner needs in order to be
  falsifiable rather than decorative.

Negative:

* Configurations that would have limped along are now refused, so the message quality matters, and the escape hatch has to be
  a documented flag rather than an edit to a source file.
* One assertion is a behaviour change for existing checkpoints: a model with mixed rates inside a layer currently loads and
  would now be refused. No local checkpoint has that shape, and the assertion is the cheaper risk.
* A guard in a shared path is a dependency for every harness and every example script, which is where the original bypass
  came from.

Neutral:

* Refusing is not the same as clamping. A clamped placement silently measures a different design than the one requested.

## Alternatives considered

* Clamp the request to what fits and continue: rejected, because the resulting run answers a question nobody asked.
* Let the operating system decide through the out-of-memory path: rejected on experience, because the observed failure was a
  hard hang, not a raised error.
* Keep the memory guard in the benchmark wrappers: tried, and bypassed once by a queue script, which is why it moved into the
  loader path.
* Trust the rate assumption and document it: rejected, because the loader derives layout from expert 0 and a violated
  assumption corrupts bytes silently.

## Links

* [`notes/b70/mem_guard.py`](../../notes/b70/mem_guard.py),
  [`notes/b70/LESSONS.md`](../../notes/b70/LESSONS.md) item 87
* [`doc/prep/README.md`](../prep/README.md) uniformity watch-out
* [`doc/prep/moe-cpu-offload-data-paths.md`](../prep/moe-cpu-offload-data-paths.md) §1
* Related: ADR-0010, ADR-0013, ADR-0016, ADR-0027, ADR-0042

## Amendment

The memory preflight originally ran inside three benchmark scripts. It now runs in the loader path that all three call, and
the change is recorded because the guard's location, not its threshold, was the defect.