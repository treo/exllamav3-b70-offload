# B70 decode kernels — chapter close-out (E24)

Status: **closed for GEMV/DPAS optimization.** One kernel family selected, one decision escalated, a
repeatable exactness gate in place, and a ranked handoff. This page is the summary of record; `b70-kernels.md`
§2c keeps the item-by-item history (13 → 13x) and `notes/b70/out_dpas.txt` / `out_gemv.txt` hold the raw
measurements.

## Decision record

| # | Decision | State | Basis |
|---|---|---|---|
| D1 | **Rev J (transposed tiles) is the decode kernel** for K = 2–16 | **adopted, pending D3** | 1.27–1.46× over rev I, 2.5–3.1× over rev G at every measured point; bit-exact; `out_dpas.txt` |
| D2 | **Combine stays a separate launch.** Do not fuse it into the producer with atomics | **adopted (refuted the alternative)** | fused costs +6.4…+8.4 µs gate / +13.6…+15.8 µs down; the atomic protocol alone is ~8.7 µs against 1.9 µs of saved round trip (13w) |
| D3 | **Accept the intra-tile permuted device layout** (`dword q·K+i → i·8+q`, produced when weights are staged into VRAM) | **ACCEPTED (owner decision), and now priced** | It is what buys D1's win: same bytes, same capacity, same DRAM traffic, bit-identical outputs, but the VRAM tensor is no longer byte-identical to the checkpoint. Measured (`probe_permute`, `out_permute.txt`): a device permute of the whole 512 MiB resident set costs **3.46 ms** at K=3 (4.24 ms at K=6) against 1.19 ms for a straight device copy — i.e. **+5.4 % on a load that already takes ~64 ms** over the measured 8.37 GB/s link. Doing it on the parent instead is worse: a host permute-copy runs at **6.8 GiB/s (K=3) to 9.1 GiB/s (K=6)** against memcpy's 20.4 GiB/s, and the link itself is ~7.8 GiB/s, so for K=3 staging becomes permute-bound (+~20 %) while also burning parent cores that §6 prices as scarce. **Recommendation adopted: ordinary DMA staging + a device-side permute at admit.** One caveat on "pay it once": that is true only for experts that never leave VRAM — a readmit after eviction pays it again, 226 µs per 14 MiB admission (+13 % of that admission's transfer). §4a's cache tier therefore permutes **on admit**, not once per process |
| D4 | **One expert per thread, always** (`DPAS_X=1`, equivalently `DPAS_EPT=1`) | **adopted** | Confirmed from two independent lineages: expert grid on revs G/H/I, and an `DPAS_EPT` sweep on rev J (1 → 14.0 µs, 2 → 21.1, 5 → 39.7). It is a latency requirement, not only a partial-traffic one |
| D5 | **dp4a (rev C + compile-time K) keeps exactly one niche:** layouts that cannot be permuted *and* K > 5 | **adopted** | Rev C is ~43 µs of non-byte cost against rev J's 6.2 µs above floor; ~5 instructions/weight vs 0.29 (13x). Rev I already owns the no-permute, K ≤ 5 case |
| D6 | **Epilogues must be written contraction-safe**, or device code compiled `-ffp-contract=off` | **adopted as a rule** | icpx contracts FMA by default and nothing in the repo sets it. Rev K's form (`CQ * ((float)s − DR)`, scalar differences rounded on the host) is the pattern. Existing certifications re-checked: revs I/J byte-identical with the flag off |
| D7 | **Split-K is a per-(projection, rows) dispatch parameter**, never quoted as a bare speedup | **adopted** | The same optimization measured ×1.42 at ks=1 and ×1.90 at ks=4; extra split-K now *hurts* the winning kernel |

## The number that ends the optimization chase

At rows=1, gate_proj: **14.0 µs = 437 GB/s effective** against a measured 484 GB/s stream slope and 674 GB/s
copy peak. **~90 % of achievable**, i.e. the streaming path is at the wall. Its own floor mode says the kernel
is balanced rather than dominated (`NO_MAD` 12.5 > `FETCH_ONLY` 8.9 and > `ALU_ONLY` 10.9; components sum to
21.3 vs 14.0 — ~35 % overlap). Unpack instruction count is no longer the lever.

What is left, in measured order of size:

1. **Fixed cost per projection ≈ 7.8 µs (gate) / 8.4 µs (down)** — ~24 µs of a 43.6 µs b=1 layer is launches,
   per-thread setup and the combine kernel. Attack: gate+up in one launch (E25), one combine per *layer*
   instead of per projection, cheaper per-thread setup.
2. **Bytes and locality**, now that streaming is at the wall: placement, ordering, the 18.35 GiB threshold.
3. **Routing**, if D3 is declined: it is this device's recurring tax, measured three ways — rev H's `iselect`
   cascade (+86 % when doubled), rev I's gathers (~2× better still), rev C's operand re-packing (48 % of its
   loop). Rev J escapes it because the *layout* removes it, which is the real argument for D3.

## Refuted along the way — do not re-attempt without new evidence

- "Decode is bandwidth-bound" as a design premise (true of the model from day one, true of the machine only at
  rev J); and its successor "decode is instruction-bound", true of every kernel through rev H.
- Materializing/expanded-byte operand layouts at load time (rev D), dense contiguous stores (confounded, never
  cleanly tested — item 13i), deeper trellis prefetch (null on revs F/H/I/J), in-register B via `apply`
  (`DPAS_REG=1`, bit-exact and much slower), sub-group barriers on transposed geometry (hurt),
  `NTOK < 16` single-row DPAS (rejected by the backend: minimum accumulator area), and a standalone
  legal-shape oracle for `joint_matrix` (it rejected a shape rev G runs daily — LESSONS 40).
- Loading optimizations as a rescue for the dp4a path (this page's D5; the trade is a wash by measurement).

## Known unknowns handed forward

| Item | Why it matters | Cheapest way to close it |
|---|---|---|
| Rows > 16 unmeasured | every 64–1024 token figure in the planning artifacts is clamped-to-16 and therefore optimistic | bucketed row-tiling probe, or one measurement at rows=32/64 |
| ~~D3 pricing (permute)~~ | **done** — `probe_permute` / `out_permute.txt`: 3.46 ms per 512 MiB device-side, host permute-copy below link rate for K=3, so permute on the device at admit | — |
| Parent side past b=1, and attention | at low batch the parent binds again, and it is calibrated only at b=1 | parent-budget re-run at b=4/8/16 with an attention term |
| Low-E models | X/EPT=1 was validated at E=10 | one case with E=2/4 and large tn |
| Per-launch vs per-thread-share split of the 7.8 µs floor | sets the ceiling for item 1 above | extend `DPAS_FLOOR` with a no-combine, no-setup mode |
| Sustained power/thermals during decode | all rates are warm-window, not soak | harness E-items with the power monitor at duty cycle |

## Precedent in the tree: the parent already ships repacked weights, and the device already fixes layout

D3 is not a new architectural departure — it is the second instance of a pattern already in production, and the
first instance's cost data argues for keeping the work on the device:

- The CPU MoE path **requires** a repacked ("swizzled") trellis layout: tiles are reordered into groups of 8
  (`exl3_moe_cpu_swizzle_group`) so a worker's k-stream is contiguous in DRAM — measured **3.4× over
  per-output-column traversal on cold stacks** (`moe_mul1.cpp` header notes). The caller repacks each tensor at
  load; `make_matrix` only checks that the flag matches the bytes.
- The staged bytes are then "copied verbatim, packed or not", and **the GPU restores native order after the
  DMA** (`moe_unswizzle.cu::moe_unswizzle_trellis`) — chosen explicitly because on-device it is "one read + one
  write at VRAM bandwidth instead of `tiles_k × groups` scattered memcpys" on the parent. The note records what
  the alternative cost when someone tried it on the stager thread: **~17 % of a fully streamed 119 B model at
  32 K — the entire VBMI-vs-VNNI prefill gap.**

So: intra-device layout transforms at admit are established practice, and the parent has already been measured
to be the wrong place to pay for them. That is the strongest available argument for D3's exact shape (DMA then
permute on device, +5.4 % of load) over making a permuted form primary on the parent.

Two axes must also be kept distinct, because they compose rather than compete: the existing swizzle is a
**tile-order** permutation (which tile lives where — a DRAM-streaming property), while rev J's transpose is
**intra-tile** (dword order inside the 8·K dwords of one tile — an operand-assembly property). Adopting the
intra-tile transpose would therefore not disturb the CPU's 3.4× traversal win, and the two could share one
pass. Whether it *helps* the CPU is a separate, open question: the CPU needs "16 k × 4 columns" per `vpdpbusd`
and obtains its expanded bytes through "compile-time (bits, row) index tables for `vpermt2var` plus immediate
funnel shifts" — i.e. CPU-side operand routing, the same tax the transpose deletes on the GPU. But the CPU path
is cold-DRAM-bound by construction (that is *why* it swizzles) and its extraction is already a small number of
wide shuffles, so the plausible upside is modest and it is an experiment, not a format change:
feed the existing kernel intra-tile-transposed bytes with adjusted extraction tables, hold bit-exactness against
the current kernel's output, and measure ns/weight plus cold-expert throughput. If it is under ~5 %, native
stays primary and the permuted form remains a device-resident representation.

## Verification consequence of D3 (new gate needed)

Device bytes no longer match checkpoint bytes, so "the staging path is correct" is no longer something Gate A
can see: A compares *outputs*, and outputs only exercise the experts routing picked. Two instruments close that
hole, and `probe_permute` already demonstrates the first — its self-check runs the device permutation and
compares against a host-computed reference dword-for-dword (exact, 0 of 98 304 differ):

1. **Layout conformance at admit**: after staging, un-permute (or re-permute) a sampled slice of the VRAM copy
   and `memcmp` against the checkpoint bytes. Cheap, deterministic, covers experts that were never routed to.
2. **Keep the checkpoint as the source of truth for every oracle.** `dump_gemv_case.py` writes native-layout
   `weights.bin`; revs J/K permute internally in `main()`, so existing case dirs and `y_ref` files remain valid
   and `gate_dpas.py` needs no change. Nothing in the verification chain may start from a permuted artifact.

Capacity and quantization arguments are untouched: the permute is a permutation, so `expert_bytes`, the
18.35 GiB resident thresholds, `h`/`h_min` accounting and `plan_quant_scaling.py` all stand as written.

## How to reproduce this chapter

```bash
source /opt/intel/oneapi/setvars.sh; source notes/env.sh
notes/b70/build.sh                                   # probes, including revs I/J/K
icpx -fsycl -O2 -DGEMV_KCONST=<K> -o /tmp/pgK<K> notes/b70/probe_gemv.cpp   # one dp4a build per recipe
python3 notes/b70/dump_gemv_case.py /tmp/<case> 10 16 0 --with-reference --with-sx8 [--ckpt ... --proj ...]
python3 notes/b70/gate_dpas.py                       # 112 comparisons: dp4a/rev I/rev J/rev K, all bit-exact
./probe_permute 3                                    # D3 cost: device permute vs device copy vs host permute-copy
python3 notes/b70/plan_decode_cost.py                # measured cost model + dispatch (rev J wins everywhere)
```

Timing discipline (violating any of these produced a wrong number somewhere in §2c): ~15–20 s sustained
warm-up before timing, round-robin interleaving of configurations, min-of-N with per-round drift reported,
absolute µs read as ±15–20 % between windows (ratios are only meaningful within one window), and no number
enters a doc unless a finished command printed it. ISA dumps need
`NEO_CACHE_PERSISTENT=0 IGC_ShaderDumpEnable=1 IGC_DumpToCustomDir=<dir>` — without the first variable the
Level-Zero shader cache means IGC never runs and the dump is silently empty.