# ADR-0032: The trellis rate is a compile-time parameter, and the engine owns every shape

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `kernel`, `codegen`, `dispatch`

## Context

Several facts that a kernel needs are known before it is written: the trellis rate in bits per weight, the tile band
group, and the matrix geometry. Passing them at run time is the natural design and it costs real throughput.

With the trellis rate as a run-time value, every window shift inside the unpacker is a variable shift and the
straddle select cannot fold away. The intra-dword bit offset of a lane's window group turns out to be lane-invariant,
a function of the lane index and the rate only, which holds for every shipped rate. Compiling the rate in
makes every shift a constant, and it measured 1.90 times on gate and 1.89 times on down at one row, with output
bit-identical to the run-time build. The same mechanism produced a false alarm earlier in the same chapter: a kernel
read its band stride from a struct field, reported 19 percent slower, and the deficit vanished when the band became a
template parameter. The vendor's kernels show the same effect, where a 1.19 times banding tax disappeared once the
divisor became a shift.

## Decision

We will instantiate the decode and prefill kernels per trellis rate, per band group and per matrix geometry. The
values come from the admit path, where they are already known. We will keep a measured dispatch table keyed on
geometry, experts per launch, rows and rate, and we will not interpolate on experts per launch. A launch that cannot
find its cell must
print which fallback rung it used, and every instantiation carries its own exactness and spill evidence.

## Consequences

Positive:

* About 1.9 times at one row costs nothing but build time, and the per-layer batch-1 figure moves from 226.0 to 126.1
  µs on the dot-product line. The gain is present at every rate measured, from 1.23 to 1.90 times, and it is
  bit-exact at each.
* A dispatch table is the honest form of what the measurements support. Split-K is a per-projection, per-row
  parameter, and hard-coding one value misprices small expert counts by 1.13 to 2.49 times.
* Owning every shape is also a defence against the runtime: the vendor's own kernels warn that an unanticipated
  matrix shape falls back to a generic path with a recompile per new shape.

Negative:

* Instantiation count grows with rates, bands, geometries and fusion settings, so build time and code size are now
  budget items, and each instantiation needs a `spillMemSize == 0` assertion rather than one global assumption.
* Cells outside the measured grid fall back to a penalty-averse rung. That is only safe if the fallback is loud, and a
  silent fallback once disabled the joint dispatch across an entire sweep while every number continued to print.
* Rates above 6 bpw compile and are declared but not certified, because no local checkpoint carries them.

Neutral:

* The gain shrinks as rows grow, to 1.09 to 1.13 times at four rows, because fixed cost becomes a smaller share. The
  crossover to the matrix schedule is unaffected by this record.

## Alternatives considered

* Pass the rate and band at run time: rejected on measurement, about 1.9 times at one row, and rejected twice by
  independent instruments.
* Autotune per launch at run time: rejected, because tuning inside generation is a stall, and the shape set is small
  and knowable at load.
* One generic kernel with a heuristic for split-K and fusion: rejected at the band edges, where heuristics got the
  sign wrong on identical byte counts.
* Instantiate per batch size as well: rejected, because the fusion and split-K bands do not move with rows, so the
  extra instantiations buy nothing measurable.

## Links

* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §4, compile-in-rate bullet
* [`doc/port/b70-kernels.md`](../port/b70-kernels.md) §2c items M12, M17
* [`notes/b70/out_cpu_layout.txt`](../../notes/b70/out_cpu_layout.txt),
  [`notes/b70/out_gemv.txt`](../../notes/b70/out_gemv.txt),
  [`notes/b70/sweep_ks_grid.py`](../../notes/b70/sweep_ks_grid.py)
* [`notes/b70/LESSONS.md`](../../notes/b70/LESSONS.md) item 34, item 49, item 67
* Related: ADR-0026, ADR-0030, ADR-0031, ADR-0040

## Amendment

The compile-in rate was first recorded as a probe flag used to measure a ceiling. It is a shipping requirement now, and
the earlier framing as an experiment is what let the engine plan continue to assume one instantiation per projection.