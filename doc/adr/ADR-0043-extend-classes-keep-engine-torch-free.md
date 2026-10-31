# ADR-0043: Extend the existing classes, and keep the engine torch-free

- Status: Accepted
- Date: 2026-10-31
- Deciders: Operator (product owner), design agent (measurement record)
- Tags: `code-structure`, `build`, `integration`

## Context

The card path needs new code in five places: the engine and kernels, a locating and build helper, a host object that owns
the region and the child, changes to the CUDA issue kernel, and changes to the module-level placement and dispatch. Two
build facts constrain how that code is organised. The CUDA extension build walks `.c`, `.cpp` and `.cu` sources, so a SYCL
translation unit inside that tree breaks the CUDA build. And there is no torch accelerator backend for this card in this
environment, which is a consequence rather than an obstacle, since ADR-0001 already rules out a second device.

The alternative to extending the existing classes is to write a card-only sibling module. That is faster for one sprint and
leaves two copies of a protocol with safety-critical invariants, which is the exact structure that Level D exists to test.

## Decision

We will factor the protocol half of the CPU host object out, rather than fork it, and keep the CPU-specific half in place.
Until that refactor lands, a card host may subclass and override, and every override is listed in the code-impact table so
the Level-D suite runs against both workers. The engine and kernels build as a shared library with a C ABI and no
framework dependency, loaded through ctypes, with a build and capability probe that mirrors the existing extension helper.
The probe decides, at startup, whether the device is present, whether host registration works, whether the command-list
path exists, and whether each shipped kernel reports zero spills. No SYCL source enters the CUDA build.

## Consequences

Positive:

* One protocol implementation means one set of flag, ring and watchdog semantics, and the CPU suite keeps covering the card
  path through the shared layer.
* Keeping `-fsycl` out of the CUDA build means a machine without the vendor toolchain is unaffected by this feature's
  presence in the tree.
* A capability probe at startup is the only honest way to handle a runtime whose documented extensions are newer than the
  installed driver, and it turns an unsupported machine into a refused configuration rather than a crash.
* The CUDA-side changes stay additive: a payload mode on the issue kernel, and the unswizzle kernel untouched while card
  tiles stay native.

Negative:

* The refactor touches a load path guarded by hundreds of tests, so it is itself a risk and is gated by ADR-0042.
* A C ABI boundary makes a job description a struct, so adding a field is a change in two languages plus a test in both.
* Dual-worker testing costs real time while the subclassing shortcut is in force, and the list of overrides must be kept
  current by hand.

Neutral:

* The worker-side thread, affinity and arena helpers are reused as-is. The card has no thread pool to size, because the card
  schedules its own engines.

## Alternatives considered

* Build the SYCL sources into the main extension: rejected, because the CUDA build's source walker would choke on them and
  every CUDA user would inherit a oneAPI dependency.
* Fork the CPU host into a card-only module: rejected, because two copies of a protocol each need their own coherency and
  liveness evidence, and drift between them is silent.
* Bind through the framework's tensor layer: rejected, because there is no backend here, and it would put a dispatcher in
  the hot path that ADR-0004 exists to keep out.
* Defer the refactor until the card works: rejected, because the first card commit needs the seams, and retrofitting them
  later is the fork by another name.

## Links

* [`doc/port/b70-architecture.md`](../port/b70-architecture.md) §7, §13
* [`notes/b70/b70_shim.cpp`](../../notes/b70/b70_shim.cpp),
  [`notes/b70/build.sh`](../../notes/b70/build.sh)
* Related: ADR-0001, ADR-0002, ADR-0003, ADR-0007, ADR-0042, ADR-0044

## Amendment

The code-impact map originally listed "subclass and override" as the plan. This record promotes the factor-out to the plan
and demotes subclassing to a transitional step with a published override list, because an undocumented override is the way a
Level-D invariant quietly stops being tested for one worker.