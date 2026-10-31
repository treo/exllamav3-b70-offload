# ADR-0026: The decode kernel is the transposed-tile integer DPAS family

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `kernel`, `decode`, `xmx`

## Context

Six kernel generations were measured before one was selected. The sequence, with its reason, is the content of
this decision, because each step deleted a mechanism that a reader otherwise assumes was necessary.

The first real trellis GEMV ran the checkpoint bytes bit-exactly and reached 61.4 GB/s at one row, against the
287 to 292 GB/s that the same bytes sustain with no arithmetic. An instruction-count model predicted the
measurement within 10 percent, which moved the problem from memory to instructions per weight. Moving the
products into registers and using one integer dot per weight and row lifted that to 116.4 GB/s. Moving tokens
onto the matrix unit's M dimension removed the per-row instruction term. Selecting the ring words with a gather
instead of a register-indexed select doubled the rate again. The last step was a layout change: store each
tile's `8·K` dwords transposed to `K·8`, so a column group's words are plain register rows with compile-time
shifts. That removed operand routing altogether and reached 437 GB/s effective, about 90 percent of the
measured 484 GB/s stream slope.

## Decision

We will implement the engine's decode kernel as that final family, rev L in
[`notes/b70/probe_dpas9.cpp`](../../notes/b70/probe_dpas9.cpp), which is the transposed-tile layout with one
fused gate and up launch and one combine launch. We will give one work-item exactly one expert. We will choose
fusion and split-K from the measured dispatch tables rather than from a rule of thumb, and we will treat
split-K as a dispatch parameter that is never quoted as a bare speedup. We keep the older integer dot-product
path only for the case the selected kernel cannot serve: a layout that cannot be permuted, at a trellis rate
above 5. Shipped kernels are gated bit-exact against the trellis reference at every supported rate and row
count.

## Consequences

Positive:

* A batch-1 MoE layer costs 43.6 µs on the card in three launches, or 40.9 µs with the fused pair of
  ADR-0030, against a measured parent non-expert leg of 195.6 µs, so decode
  work hides with margin.
* The streaming path is at the wall, so remaining gains are bytes, locality and fixed cost rather than
  instructions. The kernel is balanced rather than dominated: its own floor modes put fetch and arithmetic at
  8.9 and 10.9 µs against a 14.0 µs measurement.
* The dense recipes are covered. The selected layout reads K dwords per column group, so 6.05 bpw is verified
  bit-exact on real checkpoint data, and the whole 2.05 to 6.05 ladder costs about 3 percent more time for three
  times the bytes at one row.
* Exactness is a gate with teeth: 206 comparisons, zero failures, and byte-identity between kernel families that
  compute the same integer sum. See [`notes/b70/out_gate_dpas.txt`](../../notes/b70/out_gate_dpas.txt).

Negative:

* Fixed cost is now the largest remaining term. About 7.8 µs per gate launch and 8.4 µs per down launch, roughly
  24 µs of a 43.6 µs layer, is launches, per-thread setup and the combine.
* One expert per work-item is a latency requirement, not only a traffic one, so a model with few experts must add
  split-K to the grid to fill the device. The tables are measured at E of 2, 4, 8, 10, 12, 16, 20, 24, 32, 48,
  64, 80 and 96, and cells outside them fall back to a penalty-averse rung and must say so.
* Rate figures at small resident sets are partly cache rather than memory. A 10-expert case is 5.9 MiB against a
  24 MiB L2, so capacity and DRAM claims must use the large-E measurements.
* Rates above 6 bpw are compiled and declared but not certified, because no local checkpoint has them.

Neutral:

* Above 16 rows the engine issues more 16-row launches. See ADR-0031.

## Alternatives considered

* Keep the integer dot-product GEMV as the main kernel: rejected, 2.2 to 3 times slower above one row, and 48
  percent of its loop instructions were operand re-packing.
* Materialise expanded byte weights at load so the inner loop is trivial: rejected, measured slower at every row
  count, and 4 bytes per weight cuts the resident pick share to about 8 percent.
* Feed the matrix unit through the framework matrix abstraction: superseded, because the register-operand route
  removed 48 local-memory stores, 88 synchronisations and 11 spill references per kernel.
* Convert weights to fp16: rejected for decode, because the integer accumulation is exact, the value range fits in
  the product bytes, and a conversion costs an instruction per weight.

## Links

* [`doc/port/b70-decode-closeout.md`](../port/b70-decode-closeout.md) D1, D4, D5, D7
* [`doc/port/b70-kernels.md`](../port/b70-kernels.md) §2a, §2c
* [`notes/b70/out_revl.txt`](../../notes/b70/out_revl.txt),
  [`notes/b70/out_ks_grid.txt`](../../notes/b70/out_ks_grid.txt),
  [`notes/b70/gate_dpas.py`](../../notes/b70/gate_dpas.py)
* Related: ADR-0027, ADR-0028, ADR-0029, ADR-0030, ADR-0031, ADR-0032, ADR-0033

## Amendment

Earlier drafts of the plan carried a two-kernel dispatch, integer dot-product at one row and the matrix route
above that. Measurement removed the batch exception: one kernel family now wins at every row count measured, and
the surviving exception is by layout and rate. The change is recorded because the two-path policy is still
present in the planning scripts and must not be read as current intent.