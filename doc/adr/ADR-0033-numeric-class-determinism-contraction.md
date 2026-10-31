# ADR-0033: The numeric class, determinism and contraction rules bind

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `numerics`, `determinism`, `kernel`

## Context

The port is a new implementation of an existing contract, and three numeric properties of that contract are inherited
rather than chosen.

The first is the class of the arithmetic: int8 activations, fp32 transforms, and an integer weight accumulation that
is exact. The mul1 codebook makes the weighted sum an integer dot product, so the accumulation carries no rounding at
all, and the scale and zero-point correction is applied once per output in an affine epilogue. The second is
determinism: repeated identical calls produce bit-identical output, which is what makes a replayed greedy
generation debuggable. The third is that the toolchain fuses multiply-add pairs into a single floating instruction by
default, and nothing in this repository turns that off, so an expression's result can depend on which kernel built it.

Three separate silent-corruption bugs were caught in this chapter by bit-exactness rather than by tolerance: a wrong
`dot_acc` overload that read negative activations as 128 to 255, a pre-splat that multiplied a signed value so the
negate borrow under-contributed three quarters of a byte-sum, and a kernel that reported success while storing
nothing.

## Decision

We will keep the CPU path's numeric class, with integer accumulation and the affine epilogue, and we will not
materialise a float weight in any inner loop. We will write epilogues so that no multiply feeds an add, and we will
also compile device code with `-ffp-contract=off`, so that the guarantee does not depend on either defence alone. We
will keep reductions free of atomics and free of load-dependent work splitting, so that output is bit-identical over
repeated calls and unchanged when the k-slice count changes for one shape. Any change of class, for example a
bf16 or fp8 matrix route, requires a new level-B measurement rather than a relaxed threshold. We keep the stricter
`k` limit of 8192 that the CPU path uses, so both backends see the same inputs.

## Consequences

Positive:

* A difference between the card and the CPU at identical quantised inputs isolates arithmetic, which is the only way
  the new kernels can be graded against the incumbent. See ADR-0020.
* Bit-exactness is available for free here, because every partial is an integer sum, so regrouping cannot change a
  value. That licenses a wide, cheap correctness gate across many shapes at once.
* Contraction safety is durable: kernels certified earlier were rebuilt with the flag off and stayed byte-identical,
  which turns an accident into a property.

Negative:

* fp32 or bf16 accumulation is off the table even where it would be faster, and the split-operand routes that would
  need it are excluded from decode by this record rather than by measurement.
* Two defences must both be maintained: the contraction-safe expression form and the compile flag. A reviewer who does
  not know why the flag is set will remove it as noise.
* Determinism constrains the scheduler. Where a slice count varies with load it must vary with shape only, which rules
  out work stealing across a reduction.

Neutral:

* Bit-exactness between the card, the CPU and the parent paths is a stated non-goal, because they differ by
  construction in accumulation order. What is graded is the distribution of the difference. See ADR-0040.
* Repeatability holds for a fixed shape. Changing the per-slot row capacity changes chunking and therefore changes
  results, which is expected and is not a determinism failure.

## Alternatives considered

* Accumulate in fp32 inside the matrix unit: rejected, it changes the class, and the integer route is exact.
* Grade with a tolerance instead of bit-exactness: rejected, because all three silent bugs described above produced
  plausible-looking numbers inside any tolerance worth having.
* Rely on the contraction-safe expression without the flag: rejected, because a later edit can reintroduce a fusable
  pair without noticing.
* Rely on the flag without the expression form: rejected, because the flag is per translation unit and the epilogue
  crosses a host-side rounding step that the flag does not cover.

## Links

* [`doc/prep/mul1-trellis.md`](../prep/mul1-trellis.md) §3.1, §5
* [`doc/prep/port-acceptance.md`](../prep/port-acceptance.md) Levels B and C
* [`doc/port/b70-kernels.md`](../port/b70-kernels.md) §2.4, §3
* [`notes/b70/LESSONS.md`](../../notes/b70/LESSONS.md) item 25, item 31, item 44
* Related: ADR-0020, ADR-0023, ADR-0026, ADR-0040

## Amendment

Gate D6 of the decode chapter was recorded as a rule about epilogues. The flag is added here as a second, independent
defence, because the rule alone depends on every future author knowing the reason.