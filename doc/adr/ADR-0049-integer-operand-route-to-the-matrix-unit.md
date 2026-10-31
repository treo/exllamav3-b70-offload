# ADR-0049: Weights reach the matrix unit as integer product bytes, not as fp16

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `kernel`, `xmx`, `numerics`, `layout`

## Context

The mul1 codebook spans values from -510 to 495, which is eleven bits. That single fact generated three
candidate operand designs for the matrix unit, and the plan carried all three as open for a long time.

The first feeds the matrix unit fp16 values, produced by dequantising each weight. The second feeds it the
four bytes of the product `window * 0x83DCD12D` directly, which are genuinely unsigned bytes, against
activations replicated four times along k. The third dequantises an expert into a floating scratch tile once
and runs an ordinary matrix multiply on it, which is what the parent's reconstruct tier does.

The choice looks like a throughput question that only a sweep at 32, 128 and 512 rows per expert can settle.
Measurement moved it earlier than that. A weight that needs eleven bits never has to exist, because the value
is recovered in the epilogue from an integer accumulation, and the byte-replicated form spends the same dword
lane in every fragment of a sixteen-row tile, so no shuffle is needed to assemble the operand. The
conversions that the fp16 route exists to do are the thing the integer route deletes.

## Decision

We will carry integer product bytes to the matrix unit, with an int32 accumulator, in decode and in prefill.
We will not convert a trellis weight to fp16 inside any inner loop, and we will keep fp16 storage only for
tensors that are already fp16, such as a bias or a scale vector. We will not build the dequantise-to-scratch
route at all, because its cost is a scratch write and read of two bytes per weight per use, on a kernel family
whose register file is already full at sixteen rows.

## Consequences

Positive:

* One operand path exists, so the exactness gate of ADR-0040 has one surface to cover rather than three that
  must agree.
* The accumulation stays exact, which is what licenses the bit-identity between kernel families and keeps the
  numeric class of ADR-0033 intact.
* The route question that the plan carried as an open gate closes without a sweep, because the sweep's premise,
  that many rows per item are reachable, is false on this register budget. See ADR-0034.
* The scale and zero-point correction rides in the epilogue as a single multiply and subtract per output, which
  is where it already sits on the CPU path.

Negative:

* The matrix unit's k dimension is consumed four times faster than an fp16 route consumes it, because four
  product bytes stand in for one value. That is affordable here, because the operand is free and the arithmetic
  was never the binding term.
* An unsigned-signed mistake in the operand is silent. The wrong overload reads a negative activation as 128 to
  255 and produces plausible garbage, so the exactness gate is the only defence and it must run on real
  checkpoint bytes.
* A future codebook whose values do not fold into a byte product needs this decision revisited, and the
  fp16 argument returns with it.

Neutral:

* The eight-bit integer matrix shape on this part is limited to eight rows per instruction, so int8 costs twice
  the M tiles of an fp16 route. That trade is chosen on bytes and on operand assembly together, never on byte
  width alone.

## Alternatives considered

* Feed the matrix unit fp16 values: rejected, because it requires a conversion per weight in the loop that the
  integer form deletes, and because the value range it unlocks is already recovered in the epilogue.
* Dequantise an expert into a floating scratch tile: rejected, because it adds two bytes per weight of scratch
  traffic per use on a kernel that is register-bound rather than memory-bound at these shapes.
* Keep both integer and fp16 routes behind a runtime switch, chosen per rate: rejected, because the sweep that
  picks between them cannot be run at the row counts that decide it, so the switch is a permanent
  untested path.
* Revisit once a rows-deep kernel exists: rejected as a written condition rather than a preference, because a
  rows-deep kernel must first beat the register cliff of ADR-0034, and that cliff is the reason the fp16 route
  has no advantage to exploit.

## Links

* [`doc/port/b70-kernels.md`](../port/b70-kernels.md) §2.4, §2c items M1 and M4, §4 route table
* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §12, the R1-versus-R2 row
* [`notes/b70/LESSONS.md`](../../notes/b70/LESSONS.md) item 25, item 31
* Related: ADR-0026, ADR-0033, ADR-0034, ADR-0040