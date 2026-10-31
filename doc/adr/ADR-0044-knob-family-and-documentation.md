# ADR-0044: Every knob has a name in one family and a line in the docs

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `flags`, `documentation`, `operations`

## Context

The CPU offload exposes about forty environment variables and a set of hard-coded constants that shape the data. The study
of them classifies each by what it changes: a shape, a decision, or only an implementation. That classification is what
makes a knob safe to touch, because a knob that changes a shape changes the meaning of every measured number next to it.

The same study found the failure modes of the existing set. Fourteen variables were live and undocumented. One document
described a streaming threshold base of 16 while the code used 8. A module docstring described a worker start at first
layer registration while the loader starts it before any module loads, deliberately. None of those three changed
behaviour, and all three are text a porter otherwise trusts. One variable, `EXL3_MOE_CPU_SLOT_ROWS`, turned out to
be a shape knob disguised as a chunk size, because the fused decode path refuses a row count above the slot capacity and
silently falls back to a slower path.

## Decision

We will name every new variable in one family, `EXL3_MOE_B70_*`, with command-line aliases next to the existing offload
flags, and we will classify each as shape, policy or implementation in the same table row that documents it. Every knob gets
its `doc/env_vars.md` entry in the commit that adds it. A default is either derived from a named measurement or marked
provisional in the table, and the rate-derived defaults are the only ones not so marked. Knobs that stop applying to
card-resident layers are listed by name rather than silently ignored, and inherited knobs keep their names.

## Consequences

Positive:

* An operator or a porter can see which lever changes the shape of the data before pulling it, which is the difference
  between tuning and invalidating a benchmark.
* The provisional marking makes the honest state of each default visible, instead of implying that 4 and 256 were measured.
* Listing retired knobs by name keeps the CPU tier's still-live semantics distinguishable from the card tier's dead ones,
  which ADR-0021 depends on.

Negative:

* A documentation row per knob is a real tax, and the table is machine-validated because a silently malformed row once
  reached the repository.
* Provisional defaults invite tuning claims, which is why each carries the gate that promotes or replaces it.
* The shape, policy and implementation classes will be argued about, and the argument belongs in the table rather than in
  the code comment.

Neutral:

* Card-side thread-count and pinning variables exist for the engine's two host threads only. There is no worker pool to
  size, so the CPU family's pool knobs have no card counterparts, and their absence is documented rather than incidental.
* `EXL3_MOE_B70_SLOTS` and `EXL3_MOE_B70_SLOT_ROWS` are shape knobs whose proposed values of 4 and 256 are provisional.
  On the CPU path a row capacity silently selected a different data path. The card must assert the interaction between slot
  capacity, verification width and fused eligibility instead of relying on a default.

## Alternatives considered

* Reuse the CPU knob names with card-side meanings: rejected, because a shape knob with two meanings silently changes the
  condition of every published measurement.
* Derive everything and expose nothing: rejected, because link rate, memory size and model geometry differ per machine, and
  the plan's own rule is that rate-derived values are re-probed at startup rather than inherited.
* Document the knobs at release time: rejected, because nine undocumented variables is how this problem arrived once.

## Links

* [`doc/prep/tuning-knobs.md`](../prep/tuning-knobs.md) classes and cheat sheet
* [`doc/prep/README.md`](../prep/README.md) undocumented and contradictory entries
* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §8
* [`notes/b70/check_tables.py`](../../notes/b70/check_tables.py)
* Related: ADR-0021, ADR-0039, ADR-0045, ADR-0046
