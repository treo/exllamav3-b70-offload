# Architecture decision records: the B70 MoE offload

This directory holds the decision contract for running the offloaded MoE expert computation on an Intel
Arc Pro B70. It converts the planning record into one file per decision, so that a builder can read one
short page, see the evidence, and see what would reopen the question.

Sources of record, in the order they should be read:

| document | what it holds |
|---|---|
| [`../prep/`](../prep/README.md) | the study of the CUDA plus CPU offload that this port builds on, with file and line anchors |
| [`../port/`](../port/README.md) | the design: architecture, kernels, harness, prefill, tiering, the decode close-out, and the vertical-slice spec |
| [`../../notes/b70/`](../../notes/b70/README.md) | the probes, the planners, the raw measurements, and [`LESSONS.md`](../../notes/b70/LESSONS.md) |
| this directory | the decisions, their status, their evidence, and their reopening conditions |

Nothing here restates a measurement in full. Each record cites the artifact that printed it. Where a
number moved, the record says what it was and why.

## Writing standard

The prose follows ASD-STE100 Simplified Technical English in plain mode: short sentences, active voice,
one idea per sentence, a term defined at first use, and no semicolons or dashes between statements.
[`check_adrs.py`](check_adrs.py) enforces a subset mechanically: template shape, resolvable references,
sentence length, banned modals, and banned filler. It exits nonzero, because a check that only prints is
decoration. No tool can guarantee full ASD-STE100 compliance, and the standard is a free download at
asd-ste100.org.

Each record uses the project template, with one addition. A template section named `Amendment` is
permitted at the end, and it is used only to say what an earlier version of that decision claimed and
what replaced it. A reopening condition is not a section: it is written as a `Neutral` consequence, so
that a reader who skims Consequences cannot miss it.

Run the checks before commit:

```
python3 doc/adr/check_adrs.py
```

## Terms used across the set

| term | meaning |
|---|---|
| card | the Intel Arc Pro B70 accelerator |
| parent | the CUDA device that runs the model, an RTX 3090 on this box |
| worker | a process that takes jobs from a ring and writes results |
| job | one layer's routed-expert work for a set of rows |
| slot | the pinned memory region that carries one job |
| pinned memory | page-locked host memory that both devices and both processes can reach |
| home | the memory where an expert's bytes live and where that expert is computed |
| admit | to copy an expert's bytes into card memory and make it resident |
| trellis | the mul1 bit-ring container that holds quantised weights |
| rate, K | trellis bits per weight: 2.05 bpw means K of 2, and so on |
| row | one token's activation inside a batch |
| decode | token generation, one to a few rows |
| prefill | prompt processing, hundreds to thousands of rows |
| residue | the picks that no device home holds, so the CPU computes them |
| h | the share of a step's picks whose expert has a device home |
| sigma | the spanning fraction: the share of rows computed in more than one home |
| handshake | one publish and completion round trip for one job |
| DPAS, XMX | the matrix-unit instruction, and the unit that executes it |
| split-K, KS | a division of one matrix problem along k, used to fill the device |
| dwell | how long an expert stays inside a hot set |
| churn | the share of a resident set that is replaced per token |
| stall | wall time minus device time |
| link | the PCIe path between the host and a device |
| **[M]**, **[P]** | measured on this box, or projected and gated |

## Index

| ID | Record | Status |
|---|---|---|
| ADR-0001 | [The card runs as a job worker, not as a second device](ADR-0001-card-is-a-worker-not-a-device.md) | Accepted |
| ADR-0002 | [The card engine runs in a child process](ADR-0002-engine-runs-in-a-child-process.md) | Accepted |
| ADR-0003 | [The four-flag handoff protocol carries over unchanged](ADR-0003-four-flag-protocol-carries-over.md) | Accepted |
| ADR-0004 | [Completion comes from a pinned flag, and no job path blocks](ADR-0004-completion-by-pinned-flag-no-blocking-wait.md) | Accepted |
| ADR-0005 | [Payload enters by DMA and leaves by kernel stores](ADR-0005-payload-dma-in-kernel-stores-out.md) | Accepted |
| ADR-0006 | [Library atomics never touch the shared region](ADR-0006-no-library-atomics-on-the-shared-region.md) | Accepted |
| ADR-0007 | [The card reuses the existing slot, staging and flag architecture](ADR-0007-reuse-the-existing-slot-and-flag-architecture.md) | Accepted |
| ADR-0008 | [The shipping execution tier is one command list per job](ADR-0008-shipping-execution-tier-is-one-command-list-per-job.md) | Accepted |
| ADR-0009 | [Experts keep one home, and homes stay disjoint](ADR-0009-experts-keep-one-home.md) | Accepted |
| ADR-0010 | [Size the parent's expert slice from a computed byte bill](ADR-0010-parent-expert-slice-from-a-byte-bill.md) | Accepted |
| ADR-0011 | [Set the two-card split at the crossing point, not by equal shares](ADR-0011-two-card-split-at-the-crossing-point.md) | Accepted |
| ADR-0012 | [Placement minimises the per-layer maximum](ADR-0012-placement-minimises-the-per-layer-maximum.md) | Accepted |
| ADR-0013 | [The card tier is divided per layer in bytes](ADR-0013-card-tier-divided-per-layer-in-bytes.md) | Accepted |
| ADR-0014 | [Admit experts by window use count, never per job](ADR-0014-admit-experts-by-window-use-count.md) | Accepted |
| ADR-0015 | [The card holds a durable core, and only the boundary moves](ADR-0015-durable-core-moving-boundary.md) | Accepted |
| ADR-0016 | [The disk home uses a bounded pinned ring, and the host arena is capped](ADR-0016-disk-home-bounded-pinned-ring.md) | Accepted |
| ADR-0017 | [Promotion and the card are substitutes over one cost term](ADR-0017-promotion-and-card-are-substitutes.md) | Accepted |
| ADR-0018 | [Promotion is gated on upload cost and on phase](ADR-0018-promotion-gated-on-cost-and-phase.md) | Accepted |
| ADR-0019 | [Decode sends one compact message and pushes one partial back](ADR-0019-decode-compact-message-and-pushed-partial.md) | Accepted |
| ADR-0020 | [The parent quantises activations and sends int8](ADR-0020-parent-quantises-activations-int8-payload.md) | Accepted |
| ADR-0021 | [Streamed prefill is retired for card-resident experts](ADR-0021-retire-streamed-prefill-for-card-resident-experts.md) | Accepted |
| ADR-0022 | [Whole-layer decode offload is a split, not a path](ADR-0022-whole-layer-decode-offload-is-a-split.md) | Accepted |
| ADR-0023 | [Home partials combine in a fixed order, and spanning is the normal case](ADR-0023-fixed-order-combine-and-spanning.md) | Accepted |
| ADR-0024 | [Prefill is in scope, and verification batches come first](ADR-0024-prefill-in-scope-verify-batches-first.md) | Accepted |
| ADR-0025 | [Transfer is a first-class cost term, not overhead](ADR-0025-transfer-is-a-first-class-cost-term.md) | Proposed |
| ADR-0026 | [The decode kernel is the transposed-tile integer DPAS family](ADR-0026-decode-kernel-is-transposed-tile-dpas.md) | Accepted |
| ADR-0027 | [The weight layout is normalised at admit, not selected in the kernel](ADR-0027-normalise-weight-layout-at-admit.md) | Accepted |
| ADR-0028 | [Tiles keep native order, and the locality rules bind](ADR-0028-native-tile-order-and-locality-rules.md) | Accepted |
| ADR-0029 | [Rows are bucketed by expert before any schedule choice](ADR-0029-rows-bucketed-by-expert.md) | Accepted |
| ADR-0030 | [Gate and up fuse on a fill test, and the combine stays a separate launch](ADR-0030-gate-up-fusion-and-the-combine-launch.md) | Accepted |
| ADR-0031 | [Launches stay at 16 rows above 16 rows](ADR-0031-launches-stay-at-16-rows.md) | Accepted |
| ADR-0032 | [The trellis rate is a compile-time parameter, and the engine owns every shape](ADR-0032-compile-time-rate-and-owned-shapes.md) | Accepted |
| ADR-0033 | [The numeric class, determinism and contraction rules bind](ADR-0033-numeric-class-determinism-contraction.md) | Accepted |
| ADR-0034 | [Rejected: the three escapes for the 16-row traffic law](ADR-0034-rejected-traffic-law-escapes.md) | Rejected |
| ADR-0035 | [Rejected: synchronisation-based fusion](ADR-0035-rejected-synchronisation-based-fusion.md) | Rejected |
| ADR-0036 | [Each tier is priced by a measured primitive](ADR-0036-tiers-priced-by-measured-primitives.md) | Accepted |
| ADR-0037 | [Every performance claim reports wall time and device time](ADR-0037-report-wall-and-device-time.md) | Accepted |
| ADR-0038 | [Routing input comes from live traces, aggregated per layer](ADR-0038-routing-from-live-traces-per-layer.md) | Accepted |
| ADR-0039 | [One measurement protocol binds every performance claim](ADR-0039-one-measurement-protocol.md) | Accepted |
| ADR-0040 | [Six verification levels define done](ADR-0040-six-verification-levels-define-done.md) | Accepted |
| ADR-0041 | [Board power is the utilisation channel](ADR-0041-board-power-is-the-utilisation-channel.md) | Accepted |
| ADR-0042 | [The master flag's off state is bit-identical](ADR-0042-master-flag-off-is-bit-identical.md) | Accepted |
| ADR-0043 | [Extend the existing classes, and keep the engine torch-free](ADR-0043-extend-classes-keep-engine-torch-free.md) | Accepted |
| ADR-0044 | [Every knob has a name in one family and a line in the docs](ADR-0044-knob-family-and-documentation.md) | Accepted |
| ADR-0045 | [Load refuses a configuration the machine cannot hold](ADR-0045-load-refuses-unaffordable-configurations.md) | Accepted |
| ADR-0046 | [A gate is explained by measurement, never waived](ADR-0046-gates-may-be-explained-not-waived.md) | Accepted |
| ADR-0047 | [Implementation starts with a one-layer vertical slice](ADR-0047-start-with-a-one-layer-vertical-slice.md) | Accepted |

Groups: boundary and protocol, ADR-0001 to ADR-0008. Expert homes and placement, ADR-0009 to ADR-0018.
Data paths, ADR-0019 to ADR-0025. Kernels and layout, ADR-0026 to ADR-0035. Cost model and method,
ADR-0036 to ADR-0039. Delivery and verification, ADR-0040 to ADR-0047.

## Traceability to the planning ledgers

The design documents carry two decision ledgers. Every row of both maps to a record here.

| ledger row | decision in short | record |
|---|---|---|
| D1 | transposed-tile DPAS is the decode kernel | ADR-0026 |
| D2 | the combine stays a separate launch | ADR-0030, ADR-0035 |
| D3, D3-alt | accept the permuted device layout, and the parent's staged form already matches it | ADR-0027 |
| D4 | one expert per work-item | ADR-0026 |
| D5 | the integer dot-product path keeps one niche | ADR-0026 |
| D6 | contraction-safe epilogues | ADR-0033 |
| D7 | split-K is a dispatch parameter | ADR-0026, ADR-0032 |
| D8, D9 | fusion conditions, and one combine for the pair | ADR-0030 |
| D10 | no fusion across a data dependency | ADR-0035 |
| D11 | charge the parent its engine-measured cost | ADR-0036 |
| D12 | routing from live traces, per layer | ADR-0038 |
| D13 | matched batch, adaptation horizon | ADR-0039 |
| D14 | the two-card split by time after overhead | ADR-0011 |
| D15 | promotion and the card are substitutes | ADR-0017 |
| D16 | the card is capacity that removes promotion | ADR-0015 |
| D17 | 16-row launches, plus co-resident slabs at scale | ADR-0031 |
| D18 | primitives replace rates outside their regime | ADR-0036 |
| D19 | a device-only model is a lower bound | ADR-0037 |
| D20 | the sign of promotion is per model and per phase | ADR-0018 |
| D21 | reuse the engine's handoff architecture | ADR-0007 |
| D22 | verification batches are buildable | ADR-0024 |
| D23 | prefill is in scope | ADR-0024 |
| D24 | transfer is a first-class cost term | ADR-0025 |
| D25 | parent and card do not measurably interfere, in that scope | ADR-0025, ADR-0039 |

Selected rows from the architecture's finality table, which had no D number:

| architecture row | record |
|---|---|
| worker, not a second device, and the child-process engine | ADR-0001, ADR-0002 |
| completion by pinned flag, payload by DMA in and stores out, no atomics on shared memory, every-word assertions | ADR-0004, ADR-0005, ADR-0006, ADR-0040 |
| three disjoint homes, two cut points, no replication | ADR-0009 |
| native tile layout, and the locality rules that do pay | ADR-0028 |
| the byte floor holds only with expert bucketing | ADR-0029 |
| streamed and staged prefill is dead for card-resident experts | ADR-0021 |
| whole-layer decode offload as a split | ADR-0022 |
| admission economics, and migration judged on churn | ADR-0014, ADR-0015 |
| residency, spanning, and the parent's two bills | ADR-0010, ADR-0013, ADR-0023 |
| oversized models, the disk tier, and the arena cap | ADR-0016 |
| the int8 payload decision, and the numeric class | ADR-0020, ADR-0033 |
| execution tiers T0, T1 and T2 | ADR-0008 |
| code shape, knob family, and load-time refusals | ADR-0043, ADR-0044, ADR-0045 |
| normalise-at-admit is measured on AVX2 and asserted on AVX-512 | ADR-0027 |

## Gate map

Gates are defined in [`../port/b70-harness.md`](../port/b70-harness.md). This is where each one is
owned.

| gate | record |
|---|---|
| A format, A8 upload fidelity, A9 layout agreement | ADR-0040, ADR-0027 |
| B′1 to B′7 kernel numerics, determinism, spills | ADR-0040, ADR-0033 |
| C whole-model agreement | ADR-0040 |
| D protocol and liveness invariants | ADR-0003, ADR-0006 |
| E1 to E3 handshake and payload floors | ADR-0004, ADR-0005, ADR-0019 |
| E4, E4b, E4c rate, locality, banding | ADR-0026, ADR-0028 |
| E5, E7 link efficiency and the streaming choice | ADR-0021, ADR-0025 |
| E8 host cost on the reserved core | ADR-0007 |
| E9, E10 capacity curve and the parent window | ADR-0011, ADR-0012, ADR-0037 |
| E11, E12 churn and admission cost | ADR-0014, ADR-0015 |
| E13, E14 spanning and realised homes | ADR-0023, ADR-0038 |
| E18, E19, E20 parent spare bandwidth, balance rule, replication | ADR-0010, ADR-0012, ADR-0009 |
| E21 to E23 concurrency, eligibility, batched schedule | ADR-0011, ADR-0024, ADR-0029 |
| E24 to E29 decode kernel, fusion, launch tax, dispatch, rows | ADR-0026, ADR-0030, ADR-0031, ADR-0032 |
| U utilisation and power | ADR-0041 |

## What is still open

These are the decisions a measurement can still move. Each is a live risk, not a note.

| open item | record | what closes it |
|---|---|---|
| the card's activation path, which bounds the headline prefill number | ADR-0025 | one measured route among three candidates |
| replication of the hottest experts | ADR-0009 | gate E20, and only where capacity surplus survives real context |
| tile banding at the deployment's rate | ADR-0028 | gate E4c inside the real GEMV at that rate |
| the resident engine tier | ADR-0008 | a measured saving of at least 20 µs per token |
| the horizon a static tier must survive | ADR-0015 | a multi-session dwell trace |
| whether the maximum-over-homes balance holds | ADR-0037, ADR-0047 | the vertical slice, within 15 percent of wall |
| a kernel that bends the 16-row traffic law | ADR-0031, ADR-0034 | a kernel, not an argument |
| phase-aware promotion policy | ADR-0018 | engine work plus a per-phase cost gate |
| admit conformance on an AVX-512 host | ADR-0027 | the shipped conformance sample on that host |
| grouped routing, where `n_group` is greater than 1 | ADR-0009, ADR-0015 | the first model that ships it |
| hour-scale memory and voltage-regulator temperatures | ADR-0041 | a longer soak |
| hyper-connections, at about 83 µs per layer on the parent | ADR-0036 | profiling and modelling `hc_mix.cu`, which offloading cannot touch |

## Adding a record

1. Take the next free number. Never reuse a number, and never renumber an existing record, because
   numbers are cited in commits, artifacts and other records.
2. Copy the template, and keep the section order. Add an `Amendment` section only when an earlier claim
   in that same record needs to stay visible.
3. Write the status as one of Proposed, Accepted, Rejected, Deprecated, or Superseded by ADR-XXXX. A
   gated decision keeps an Accepted status and names its gate inside Consequences.
4. Put the reopening condition in Consequences as a Neutral item. A decision with no reopening condition
   is a preference, and should be challenged as one.
5. Cite artifacts by path. [`check_adrs.py`](check_adrs.py) fails a record whose links do not resolve, so
   cite the file that printed the number rather than a summary of it.
6. When a record replaces another, mark the old one Superseded by the new number and keep both files.
   History that is edited away stops being evidence.