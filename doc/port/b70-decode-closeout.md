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
| D3-alt | **One staged in-RAM layout, consumed verbatim by the B70**, with the CUDA path still unpacking to native from that different base | **demonstrated end-to-end on AVX2** (planar dwords + group-2 banding, 16/16 bit-exact with negative controls, banding rate-neutral); remaining work is the layout marker in the handoff and keeping D3 for non-planar tiers | The production AVX2 repack (`_copy_repacked`, planar) already emits exactly rev J's dword order — byte-identical over 1.536 M dwords — and rev J reads the full staged form bit-exactly at the same rate (−1.3…+2.0 % planar; −4.6…+1.0 % banded) (`out_cpu_layout.txt`, `gate_dpas.py --staged`). D3's device permute survives as the fallback for tiers where staging is not planar (AVX-512 group 8; non-integer rates group 0), which is what makes the marker mandatory rather than cosmetic |
| D8 | **Fuse gate+up into one launch at KS=1 when the separate launches under-fill the device**; keep launches separate otherwise | **adopted (measured), and tested off E=10** | Fused gate+up beats the best unfused schedule at every row count (x1.04 at rows=1, x1.13 at 8, x1.17 at 16), bit-exact, and halves the gemm launches in the layer. The condition is occupancy, not taste: fusion and split-K both buy parallelism, so the fused kernel wants KS=1 (`out_e25_fuse.txt`). **Grid sweep at E=10/32/96 (`out_egrid.txt`)**: the rule predicted correctly in 15 of 18 cells, and all three misses are fusion winning by 3-6% where the rule said "separate" — i.e. the 0.6·HW_THREADS cutoff marks *where the benefit disappears*, not where fusion starts to hurt. Read it that way: below the cutoff fuse (1.35-1.63x); above it the choice is a wash within ±6%, so prefer fewer launches**. **Joint form, from E=2/E=4 (`out_low_e_grid.txt`):** fusion and split-K are two purchases of the same thing, so pick them together — the optimum at every E measured lands with the gemm grid at ~0.6–0.8 × HW_THREADS (E=2 fused KS=4 → 1280; E=4 fused KS=2 → 1280; E=10 fused KS=1 → 1600; E=96 needs neither). At E=2 the best schedule is fused *and* KS=4 (9.7 µs vs 17.6 fused KS=1, 14.1 separate KS=4), so the E25a phrasing "they are substitutes, fuse at KS=1" was an E=10 artifact. **Second condition, added after measuring the E=32 result below: fusion also has a cache cost** — a fused launch holds both projections' streams at once, so it loses its advantage once `2·E·bytes > L2` while a single stream still fits. Fuse only when *both* the fill test and the L2 test pass; `plan_decode_cost.best_launch()` implements both and prints `~tie` / penalty-band reasons (`out_ks_grid.txt`) |
| D9 | **One combine launch for the fused gate+up pair, with one work-item producing both projections** (grid = output count, not 2×) | **adopted (measured)** | Beats the two-launch form at rows=8 (−1.1 µs) and ties at 1/16, so the layer loses a launch without losing time; the naive merge (one launch, 2× grid) *lost* by 1.9–3.8 µs, and four explanations (dirty L2, timing protocol, runtime-`KS` address folding, non-contiguous partial allocations) were tested and refuted before grid shape was isolated by per-stage attribution. Folding SiLU into the same kernel changes its own runtime by <0.2 µs — its value is eliminating the elementwise pass, which this probe cannot price (`out_e25b_combine.txt`) |
| D10 | **Do not fuse across a data dependency: keep gate/up, the elementwise, and down in separate launches.** E25c (all three projections in one launch) is rejected without building it | **rejected (priced, not built)** | Down's input is produced by other work-items, so one launch needs a device-wide barrier. Measured (probe_barrier.cpp): 1.59 µs at 256 work-items, 2.49 at 1024, **6.17 µs at 2048 — the device's full capacity** — against the ~2.9 µs the saved launch is worth; and at the friendliest geometry (E=10, rows=1, barrier at ~1600 slots ≈ 4 µs) it is already net negative. Past capacity a spin barrier is illegal-by-API (co-residence is not promised), where completion at 3072/4096 came with 16–20 µs barriers anyway. Plus the register bill: sequential phases force max(phase registers), and E29 showed that budget is zero-sum at rows > 1. **The device rule this generalises: launches are cheap, in-kernel coordination is not** — merge work only where it is embarrassingly parallel (D8/D9), never across a dependency (`out_e25c_barrier.txt`) |
| D4 | **One expert per thread, always** (`DPAS_X=1`, equivalently `DPAS_EPT=1`) | **adopted** | Confirmed from two independent lineages: expert grid on revs G/H/I, and an `DPAS_EPT` sweep on rev J (1 → 14.0 µs, 2 → 21.1, 5 → 39.7). It is a latency requirement, not only a partial-traffic one |
| D5 | **dp4a (rev C + compile-time K) keeps exactly one niche:** layouts that cannot be permuted *and* K > 5 | **adopted** | Rev C is ~43 µs of non-byte cost against rev J's 6.2 µs above floor; ~5 instructions/weight vs 0.29 (13x). Rev I already owns the no-permute, K ≤ 5 case |
| D6 | **Epilogues must be written contraction-safe**, or device code compiled `-ffp-contract=off` | **adopted as a rule** | icpx contracts FMA by default and nothing in the repo sets it. Rev K's form (`CQ * ((float)s − DR)`, scalar differences rounded on the host) is the pattern. Existing certifications re-checked: revs I/J byte-identical with the flag off |
| D7 | **Split-K is a per-(projection, rows) dispatch parameter**, never quoted as a bare speedup | **adopted** | The same optimization measured ×1.42 at ks=1 and ×1.90 at ks=4; extra split-K now *hurts* the winning kernel |

## The number that ends the optimization chase

At rows=1, gate_proj: **14.0 µs = 437 GB/s effective** against a measured 484 GB/s stream slope and 674 GB/s
copy peak. **~90 % of achievable**, i.e. the streaming path is at the wall. **Asterisk added later, and it
matters:** that case has E=10 and 5.9 MiB of weights, which fits the device's 24 MiB L2 (`devinfo`), and the
timing loop re-reads the same tensors — so 437 GB/s is partly L2 bandwidth, not DRAM. The DRAM-regime figures are
the large-E cases: E=96 fused achieves 492 GB/s at rows=1 and 287–292 GB/s at rows=16 (`out_egrid.txt`), and the
quantization ladder makes the point sharply — at E=10, 3× the bytes changes the time by 3% and reports up to
693 GB/s, which exceeds the 674 GB/s copy peak and so cannot be DRAM (`out_quant_ladder.txt`). Rule for reading
any rate here: check the working-set size against L2. Its own floor mode says the kernel
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
| ~~Rows > 16 unmeasured~~ | **done** — bucketing 16-row launches is additive: x2.00 / x2.98 / x3.96 at 32 / 48 / 64 rows, both projections, each bucket bit-exact against its own `y_ref` slice (`out_rows_gt16.txt`) | follow-up: a **shared-stream** bucket kernel would pay the weight stream once — projected x1.44 at rows=32 rising to x2.36 at rows=256 (upper bound from two measured points, unimplemented) |
| ~~D3 pricing (permute)~~ | **done** — `probe_permute` / `out_permute.txt`: 3.46 ms per 512 MiB device-side, host permute-copy below link rate for K=3, so permute on the device at admit | — |
| Parent side past b=1, and attention | at low batch the parent binds again, and it is calibrated only at b=1 | parent-budget re-run at b=4/8/16 with an attention term. **Partly done, and the part that is left is the part this box cannot do:** the CPU home (`S_c`) is now measured over b=1..16 (`out_cpu_worker_calib.txt`) — it is compute-bound, its assumed 47.4 GiB/s was unreachable, and correcting it moved the placement walls by 0-1 us because `S_c` was not the binding leg in any tested config. The 3090 parent leg (`T_parent` = 250 us/layer + `S_g`/936 GB/s) needs a CUDA box, so "binding returns to the parent at b<=8" still rests on an inherited number |
| ~~Low-E models~~ **closed for E=2/4** | X/EPT=1 was validated at E=10 | E=2 and E=4 measured (`out_low_e_grid.txt`): the layout is fine at a 320–640 thread grid, fusion pays *more* the emptier the device is (1.78–1.85x vs 1.35–1.63x at E=10), and the joint rule in D8 replaced the exclusive one. E=32/96 in `out_egrid.txt`. **Follow-up done:** `plan_decode_cost` now carries per-KS tables over E = 2/4/10/32/96 and `best_launch(E, rows)` returns the joint (fusion, KS) choice, measured with the anchor at 19.0–19.3 µs on every cell (`out_ks_grid.txt`) |
| ~~E=32 rows=1: separate KS=2 beats every fused option by 27 % at matched KS~~ **resolved — it is L2, not an anomaly** | it reproduced to 1 % across re-runs and was non-monotonic in E (E=16 and E=64 unaffected), which means a missing variable rather than noise | A fused launch's live weight footprint is the **union** of both streams (2·E·b) while separate launches hold one each (E·b): with L2 = 24 MiB and b = 0.585 MiB, fusion should stop paying near E ≈ 20 and the penalty band should close near E ≈ 41 — measuring E = 16/20/24/64 reproduced that shape exactly (fused wins at 10/16, separate at 20/24/32, indifferent at 64/96), with nothing fitted. Now D8's second condition and implemented in `best_launch()` given bytes/expert. Tested the same day on an independent checkpoint: at K=6 the crossover moved to E ≈ 10–16 exactly as the footprint argument predicts (fusion's gain at E=10 dropped 1.62× → 1.25×, already reversing by KS=2, and losing by 1.79× at E=16), though the penalty's **magnitude** is larger than footprint alone explains (1.79× vs 1.27× at equal live bytes) — `out_ks_grid.txt` separates what is confirmed from what is not |
| Fractional ownership, and per-KS cells outside K=3 | `best_launch` refuses to interpolate on E, and the tables are K=3 only | per-KS cells for K=2 and K=6 at E=2/32, then a decision on whether nearest-below-E or wave-rounded interpolation is defensible |
| Per-launch vs per-thread-share split of the 7.8 µs floor | sets the ceiling for item 1 above | extend `DPAS_FLOOR` with a no-combine, no-setup mode |
| ~~Sustained power/thermals during decode~~ **done** | all rates were warm-window, not soak | 150 s continuous fused decode at E=96 (`out_sustained_power.txt`): **+0.5% drift** (410.1 → 412.1 µs), so the chapter's numbers are not soak artifacts. But the part is **power-capped**: ~285 W mean / 294–306 W peaks against a 275 W cap, ~2.4 GHz with ~1% clock droop, compute 97–100% while DRAM bandwidth averages 54% of peak. Core plateaus at 71 °C; **memory (86 °C) and VR (94 °C) were still climbing at 150 s**, so hour-scale thermals remain open and the VR stage is the one to watch. Consequence: work eliminated beats latency hidden — you cannot buy speed without spending the same watts |

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

## D3-alt (open, and better than D3 if the CPU bears it): ONE staged layout, copied verbatim to the B70

The proposal worth investigating is narrower and stronger than "make the permuted form the file format": keep
the checkpoint as it is, and make the **in-RAM staged copy** the B70's permuted-plus-swizzled form. Then

- the B70 receives a **verbatim copy** — the device-side permute disappears, along with its 3.46 ms per 512 MiB
  and its per-admit 226 µs;
- there is **one** staged layout instead of a device-resident special case, so the staging path, the footprint
  arithmetic and the layout tests all speak about one thing;
- the 3090 path still unpacks from native order, it just starts from a different base — and it already runs
  exactly such a pass (`moe_unswizzle_trellis`: a read + write at VRAM bandwidth), so this is a change of index
  arithmetic inside an existing kernel, not a new pass;
- the parent's repack pass already exists (it produces the tile-order swizzle), so the intra-tile transpose is
  extra work in a pass that is already writing the bytes — not an additional pass.

Nothing about the on-disk format, `expert_bytes`, capacity thresholds, or oracle provenance changes: Gate A
still runs from native checkpoint bytes, with any permutation applied inside the harness rather than in the
references.

Evidence on the CPU's sign, from reading the extraction path rather than guessing: the CPU assembles its
`vpdpbusd` operands the same *shape* the GPU does — columns across lanes, per-half funnel shifts ("cols 0-7 use
`s0`, cols 8-15 use `s1`"; "a row's 8-column half can draw…"), with the cross-column collection done by
compile-time `vpermt2var` index tables. The transposed layout is exactly what makes that collection contiguous,
so **neutral-to-positive is the expectation**; the counter-argument is that the CPU already gets the
q-independence the transpose gives the GPU (its shift counts are per column-half, not per column), and it is
cold-DRAM-bound by construction, so the shuffle it deletes may not be on its critical path. Magnitude is
therefore an open measurement, not a foregone conclusion in either direction.

What has to be true before D3-alt can replace D3, in order of cost to check:

1. **CPU throughput is not hurt** (the experiment above; run it first, because it gates everything else).
2. **The B70 kernel accepts tile-grouped (swizzled) tile order**, not just checkpoint order. Intra-tile it is
   already right; the tile index map changes from `e*tk*tn + …` to a group-major one, which is addressing only —
   but revs J/K currently permute tiles *inside* `main()` starting from native order, so a staged-order case
   directory and a matching gate entry are needed before "verbatim copy works" can be claimed rather than
   assumed.
3. **CUDA's unswizzle is retargeted and re-validated** against the 3090's existing numerics (that path has its
   own acceptance history; it is not ours to break casually).
4. A **version marker** on the staged form, so a parent that does not swizzle (or swizzles with group 2 on the
   AVX2 tier — `exl3_moe_cpu_swizzle_group` already returns different groups per rate/ISA) cannot hand the B70
   bytes in a layout it will silently misread. This is the one item with a correctness-teeth risk: today the
   group depends on ISA and rate, so "the staged layout" is not a single constant, and the B70 side must be
told which one it got.

Until 1-2 are measured, D3 (device-side permute at admit) remains the implemented answer — it is cheap, it is
already priced, and it does not depend on any of the above.

### Resolved by measurement: on this (AVX2) host, D3-alt is confirmed — `out_cpu_layout.txt`

Checked on the AVX2-only box (Ryzen 9 5950X: `avx2` yes, no AVX-512, no VNNI), which is where the CPU kernels
actually run:

1. **The production staged dword order *is* rev J's intra-tile permutation.** `moe_cpu_host._copy_repacked`
   swaps each tile's trailing `(8, bits)` dword dims — dword `w → 8·(w % bits) + w // bits` — which over every
   dword of a real case (64 000 tiles × 24 dwords, K=3) is byte-identical to `probe_dpas7`'s internal
   `dst[i*8+q] = src[q*K+i]`. Same tile (16×16 weights = 8·K dwords = 96 B), same map.
2. **rev J consumes those staged bytes verbatim and stays bit-exact** — gate_proj and down_proj at rows 1/4/16,
   using a build flag (`-DDPAS_STAGED_LAYOUT`) that suppresses its internal permute. Tile order was deliberately
   left native in the test, to isolate the dword-permute claim from the tile-order claim.
3. **No measurable rate cost**: 14.0 vs 14.0, 20.4 vs 20.8, 15.9 vs 15.7, 30.5 vs 30.3 µs (−1.3 % … +2.0 %).
4. **And the CPU wanted this order for itself**: under the planar layout `avx2_gather_half_planar` frequently
   needs no shuffle at all (`if constexpr (planar_identity<…>()) return preg[reg];`), because a half-row's
   source dwords already occupy one register. That is the same mechanism rev J exploits on the GPU — the CPU
   reached for it first, which is why the two layouts coincide rather than merely being compatible.

So on this host the 3.46 ms per 512 MiB device permute is simply not paid: staging already emits the bytes the
B70's fastest kernel wants, and the copy is verbatim — and rev L confirms that at the rate, not just the byte
level (`out_revl.txt`): native 19.60 µs, planar-dwords-unbanded 19.60 µs, planar+banded (AVX2's group 2)
19.20 µs, group 8 19.30 µs, all bit-exact, anchor 19.5 µs. Getting to that sentence required killing a false
alarm: the first rev L measurement said banding cost the B70 **+19 %** (23.10 µs), which would have made the
parent's swizzle — worth 3.4× cold-traversal on the CPU — a tax on every B70 gemm, and would have revived the
admit-time reordering pass. It was a parameterization bug in the probe. Rev J read the band from
`#define DPAS_BAND`, so its stride arithmetic constant-folded; rev L read it from a struct field at run time.
Same source, same bytes, band forced to a compile-time constant: 19.70 µs for group 2 *and* group 8. `Band` is
now a template parameter specialized on {0, 2, 8}, and the engine inherits the rule:
**anything the admit path already knows belongs in the template parameter list, not a parameter block** — worth
19 % here, more than several algorithmic wins in this chapter, and invisible to every knob the harness swept.

**Two things stood between the verbatim-copy claim and shipping it.**

- ~~The B70 kernel's tile index map must follow the staged banding `(nt/group, kt, nt%group)` instead of
  checkpoint `(kt, nt)`~~ **done and measured**: `-DDPAS_BAND=g` implements it in three lines of addressing
  (`kstride = g·NW` instead of `tn·NW`, per-expert stride unchanged), and the complete staged form — planar
  dwords **and** group-2 banding — is bit-exact on gate and down at K = 2/3/5, rows 1/4/8/16 (**16/16**), each
  with a negative control that feeds the same bytes to the checkpoint tile map and is **rejected every time**.
  Banding's rate cost on the B70: **−4.6 % … +1.0 %** (free to mildly better, as expected for a kernel that
  reads whole tiles). Measured rather than assumed, because "cannot hurt" has been wrong repeatedly here.
- `planar` is returned **only for AVX2** (`exl3_moe_cpu_planar_layout`), and only at integer rates where
  group ≠ 0. On AVX-512 tiers staging keeps native dword order; at non-integer rates group is 0. So D3's
  device-side permute stays as the fallback path, and the handoff must carry an explicit **layout marker**
  (group ∈ {8, 2, 0} plus the planar flag) — without it the B70 silently misreads bytes for exactly those
  experts routing never selects, which is the hole Gate A cannot see.

`gate_dpas.py --staged` regenerates both staged case dirs, asserts bit-exactness through the matching tile map,
and asserts the **negative control** (checkpoint tile map must reject banded bytes), so this is a regression
gate with teeth rather than a finding. The only remaining item is contractual — resolved below as **normalize
at admit**: the engine keeps D3's device permute for tiers where staging is not planar, and the compute kernel
needs no marker at all.

## Closing the last open item: normalize the layout **at admit**, do not pass a marker to the kernel

D3-alt left one contractual requirement, and the obvious implementation — put `group` and `planar` in the
handoff so the compute kernel picks its tile map — is the weaker of two available designs. The hazard being
managed is a *silent* one: if a kernel reads staged bytes with the wrong tile map or dword convention, output is
wrong only for experts routing happens to select, which is exactly what Gate A cannot see.

| | A. marker → compute kernel | B. normalize at admit (**recommended**) |
|---|---|---|
| invariant | "device bytes are whatever the parent staged" | "device bytes are always B70-canonical (planar dwords + g-major tiles)" |
| who knows the layout | every kernel that touches weights | one function: the admit path |
| cost | a field per job (or per resident tensor), read and branched on in the hot path | nothing at compute time |
| verbatim vs permuted paths | two code paths through the kernel | converge at admit: verbatim when the staged form already matches, device permute (+5.4 % of load, `probe_permute`) when it does not |
| how a bug shows up | silently wrong numerics for rarely-routed experts | broken invariant, detectable by sampling the tensor at admit |

**What admit needs, and where it already exists.** The parent decides the layout in one place already —
`exl3_moe_cpu_swizzle_group` / `exl3_moe_cpu_planar_layout`, plus the tensor's own shape `[tk, tn, ps]` — and
moving weights into the device is already a distinct job kind in the production protocol (`MoeJob.kind == stage`
carrying `experts[]`, in `moe_handoff.h`). The information is therefore present exactly where normalization
would happen: no new per-layer payload, and the handshake's reserved area (128 B at offset 192, held by E8 for
extensions) stays free. Non-integer rates and the AVX-512 tiers, where staging is not planar, stop being
kernel-configuration cases and become one branch inside admit.

**Validation that makes the invariant real** — this is the part that removes the silent-failure mode:

1. **Per-admit conformance check**: sample a few tiles of the freshly staged device tensor, un-permute with the
   declared source layout, `memcmp` against the checkpoint bytes. Covers every expert, including ones routing
   never picks. It is precisely the self-check `probe_permute` already performs against a host-computed
   reference, moved onto the engine path.
2. **Gate entry**: `gate_dpas.py --staged` already asserts the B70 kernel accepts the parent's full staged form
   and *rejects* the wrong tile map; add a "staged ≠ canonical" case (AVX-512-shaped: group 8, native dwords)
   so the permute-on-admit branch is covered rather than assumed.
3. **Fail loud on unknown triples**: an unrecognized (group, planar, bits) must reject the admission rather than
   fall through to a default map.

The last "the handoff must carry X" item thus becomes a locality property: the layout is a fact about one
function, checked where the bytes arrive, and invisible to the decode kernel that measured 437 GB/s.

## E29 RESULT: shared-stream buckets implemented, and it LOSES — 53.3 µs vs 41.5 µs additive at rows=32

Implemented as specced (`-DDPAS_BKT=N`, `DPAS_SHARED=N`; five sites, no rewrite) and measured with the same
discipline as everything else: 3 s in-process warm-up, min of 3 repeats, every bucket checked bit-exact against
its own `y_ref` slice (**all buckets exact in every working configuration**), plus a regression check that the
refactor left `BKT=1` untouched (rows=16 20.6–21.3 µs vs the published 21.4 ✓).

To separate the two candidate causes I varied bucket *count* and bucket *width* so that accumulator registers
matched across a pair of runs — gate, E=10, K=3, ks2, µs for the stated total rows:

| | buckets | rows/bucket | total rows | acc GRF | time | vs additive |
|---|---|---|---|---|---|---|
| A | 1 | 16 (`NF=2`) | 16 | 16 | 20.9 | (baseline) |
| B | 2 | 8 (`NF=1`) | 16 | 16 | **— faults the device** | n/a |
| C | 4 | 8 (`NF=1`) | 32 | 32 | **60.7 / 61.4** | **x1.46 worse** (additive 41.5) |
| D | 2 | 16 (`NF=2`) | 32 | 32 | **53.3** | **x1.29 worse** (additive 41.5) |

Projected ideal for rows=32 was ~29–31 µs. **The mechanism is real and it still loses.**

**The hypothesis I wrote first, and what killed it.** I attributed the loss to occupancy — "doubling accumulator
registers halves threads per EU in a latency-hiding-bound kernel". C and D carry the *same* 32 GRF of
accumulators, yet differ by 14 % (and both lose to additive), so accumulator pressure is not the story. Worse for
that hypothesis: C does *more* buckets with *smaller* per-bucket accumulators and is the slowest of all. The
discrimination I built to test occupancy (cell B) was supposed to settle it, and B is the one configuration that
faults.

**What actually caused the fault: my host-side allocation sizing, not the compiler, not the driver, and not
spilling.** `journalctl -k` gave the fault records:

    kernel: xe 0000:0f:00.0: [drm] Tile0: GT0: Faulted Address: 0x0000d556b7a01000 / …a06000 / …a0b000
    kernel: xe 0000:0f:00.0: [drm] Tile0: GT0: Fault response: Unsuccessful -ENOENT
    kernel: xe 0000:0f:00.0: [drm] Tile0: GT0: Engine reset: engine_class=ccs ... in revJ_k2

Three things about that record were the actual evidence: the access was a **read**, the address was
**page-aligned**, and it **moved between runs**. A fixed bad base pointer would not move; scratch traffic would
not be reported as an unmapped read. Together they say "walked off the end of a live allocation, landing on
whatever the USM pool happened to map next" — which is exactly what my change did: with `DPAS_BKT > 1` the kernel
reads `BKT` activation buckets and writes `BKT` partial regions on **every** path, while the plain (non-shared)
host path allocated exactly **one** bucket of `XA` and one region of `PART`. Sizing those for `BKT` buckets
(zero-filled beyond bucket 0) removed the fault completely: cell B now runs, and fault records in the kernel log
went to zero across the whole subsequent sweep.

Two wrong hypotheses I held along the way, recorded because both were plausible and both were tested to death:

* **"Non-monotonic failure set (BKT 2 ✗, 3 ✗, 4 ✓, 8 ✗) means a codegen edge case."** No: whether an overrun
  faults depends only on what lies after the allocation, which is *not* a function of `BKT`. The apparent
  pattern was noise.
* **"The kernel spills 1856 B to scratch, so it exhausts local memory."** Spills are serviced inside a scratch
  region the runtime sizes from the kernel's *own* reported spill size, so spilling costs bandwidth, not faults.
  And the correlation was backwards — the faulting shape's dump showed *no* spill records while working shapes
  spilled more. That comparison was worthless anyway: a faulting run dies before IGC compiles the remaining
  kernels, so the absence of records was a **coverage artifact that I read as a measurement**.

**Why the shared stream loses, and it is about registers after all — just not occupancy.** Now that every shape
runs, spill size is measurable on equal footing, and it tracks the loss:

| shape for 32 rows | time | spill / thread |
|---|---|---|
| two separate 16-row launches (**baseline**) | **41.5 µs** | **none** |
| shared 2 buckets × 16 rows (D) | 53.7 µs | 2112 B |
| shared 4 buckets × 8 rows (C) | 60.5 µs | 1856 B |
| **native single 32-row launch (`NF=4`)** | **64.8 µs** | **3584 B** |
| native `NF=4` asked for 24 rows (pads to 32) | 61.8 µs | — |
| 2 buckets × 8 rows = 16 rows (B, occupancy-matched to A) | 24.9–25.1 µs | none |

**It is zero-sum, and the ring sweep proves it.** Varying the prefetch ring 96→576 dwords across four shapes
(`out_e29_share.txt`) turns the correlation into a controlled experiment rather than an observation:

| shape (32 rows unless noted) | ring 96 | ring 192 | ring 384 | ring 576 |
|---|---|---|---|---|
| **A** native `NF=2`, 16 rows (baseline) | 21.1 / 0 B | 21.7 / 0 B | 21.2 / 0 B | 21.4 / 0 B |
| **C** 4 buckets × 8 | **44.4 / 0 B** | 53.8 / 1536 | 60.7 / 1856 | 60.8 / 1856 |
| **D** 2 buckets × 16 | 48.1 / 1536 | 47.3 / 1536 | 53.8 / 2112 | 66.6 / 2688 |
| **E** native `NF=4` | 51.2 / 3072 | 51.2 / 3072 | 64.4 / 3584 | 77.2 / 4352 |

Inside each shape, time rises monotonically with spill. A is spill-free and *entirely insensitive* to a 6× ring
range — 16 rows plus prefetch fits with room to spare. Add a second 16-row bucket and **ring depth becomes the
currency**: C starved to ring 96 is spill-free at 44.4 µs, within 5 % of the additive baseline (~42.4 µs), and at
ring 576 it spills 1856 B and costs 60.8 µs. So sharing rows is bought *with* prefetch, and once you pay for it
the transaction is at best a wash — which is the honest form of "refuted": the mechanism works, the budget
accounting does not. E cannot even make that trade, because 32 rows of accumulators plus `Bop` plus one ring set
already spill at ring 96.

The pattern: **this kernel's register budget holds exactly 16 rows** — `NF=2` fragments of `MR=8` plus `Bop`
plus the prefetch ring fit 128 GRF spill-free, which is why rev J is spill-free across all its
instantiations. Anything carrying more row state across the weight stream must borrow from the ring, and
borrowing the ring costs about as much latency as the re-streamed weights cost at the ~450 GB/s this kernel
already achieves. Note B: with 8-row buckets and `acc` back to 16 GRF the kernel is spill-free again and
*sharing does pay* versus two separate 8-row launches (25.1 vs ~33 µs) — it just cannot beat a single 16-row
launch (20.9 µs), which is the shape the hardware wants. This also resolves the C-vs-D oddity I earlier said
had to be explained before anyone retried sharing: raw spill bytes are a proxy, not the mechanism, and the two
shapes simply sit at different points on the same prefetch-versus-accumulator trade-off.

**Conclusion, and what changes.** Bucketed 16-row launches stand as the rows>16 schedule and the additive law in
`plan_decode_cost.py` is the model, not a placeholder; a single wider launch is possible (`NF=4`, implemented,
bit-exact at 24 and 32 rows) and is the slowest option measured. Wider kernels are the wrong axis: the row dimension is
already at the register-budget ceiling, so the remaining fusion lever is **column/projection** reuse (E25
gate+up in one launch; the rev-J author's own note that two adjacent column tiles per thread would halve
per-tile bookkeeping *and* activation loads) — that amortizes the stream without adding row state. And a warning
for the engine's row-bucket tiler: never pad a bucket. 24 rows expressed as one padded `NF=4` launch costs
61.8 µs; 16+8 as two buckets costs ~38 µs.

**Operational note that applies beyond E29:** after a fault, an unwarmed run read 44.1 µs and the same run after
3 s of continuous work read 21.3 µs — a faulted-then-reset card looks *exactly* like an un-ramped one, so the
anchor is what separates "the device changed state" from "my code regressed", and `journalctl -k` settles it
definitively. Read the kernel log before theorising about the driver.

**Operational note that applies beyond E29:** after the fault, an unwarmed run read 44.1 µs and the same run
after 3 s of continuous work read 21.3 µs — i.e. a faulted-then-reset card looks *exactly* like an un-ramped one,
and the anchor is what distinguishes them from a real regression. `journalctl -k` distinguishes them definitively.

## E29 spec: the shared-stream row-bucket kernel (design is done; implementation is not)

## E25 RESULT: gate+up in one launch **WINS** — x1.04 at rows=1, x1.12 at rows=16 — but only at KS=1

The grid-level fusion (one launch spanning both projections' column tiles; a thread still serves exactly one
projection, so the accumulator bill is unchanged from the single-projection kernel) beats the best unfused
configuration at every row count measured, and is bit-exact against each projection's own `y_ref`:

| rows | best separate (two launches) | **fused, one launch** | gain |
|---|---|---|---|
| 1 | 26.4 µs (KS=2) | **25.7 µs (KS=1)** | x1.04 |
| 8 | 32.7 µs (KS=2) | **28.9 µs (KS=1)** | x1.13 |
| 16 | 40.8 µs (KS=2) | **35.0 µs (KS=1)** | x1.17 |

Layer time (fused gate+up + separate down, all KS=1): **40.9 µs at rows=1** (from 42.6) and **64.8 µs at
rows=16** (from 72.6), in 2 gemm launches per layer instead of 3.

**The mechanism is the interesting part, because it unifies E25 and E29:** *fusion and split-K are substitutes
for the same resource — parallelism.* The device reports ~2048 hardware thread slots; a gate launch at KS=1 is
`tn·KS·2·E = 800` threads, 39 % of capacity, so two separate launches run half-idle. Fusing them yields 1600
threads and near-full occupancy — worth 49 %. Once each launch already fills the machine (KS=2 ⇒ 1600 threads),
fusing buys nothing and leaves only its cost: two independent weight streams interleaved, measuring +7 %.
Hence the fused kernel's optimum *flips to KS=1*, and the engine rule is conditional rather than absolute:

```
if tiles_this_launch * KS * 2 * E < ~0.6 x HW_THREADS:  fuse projections, set KS = 1
else:                                                   keep launches separate, tune KS
```

with `HW_THREADS` read at startup (rev J already queries it for `DPAS_EPT`). This also revises the E29 lesson:
the register file bounds row state, but **grid-level** fusion sidesteps it entirely — which is precisely why it
wins where row bucketing lost.

Full sweep (nine configurations, ks 1/2/4 × rows 1/8/16), the two bugs this surfaced (a meta row-count override
that caused an OOB write into the *other* projection's output, and a duplicated tile-permutation that left the
second projection's weights untransposed), and the E25b/E25c follow-ups (fuse the two combines; try all three
projections in one launch) are in `out_e25_fuse.txt`.

## E29 spec: the shared-stream row-bucket kernel — **superseded by the RESULT above; kept because the reasoning was sound and the failure is instructive**

**Why it should work, structurally.** In `probe_dpas7.cpp` the unpacked weight tile already lives in registers
(`simd<uint32_t, 128> Bop[2]`, line 296) and `mad(a_tile)` consumes it (line 359). A second 16-row bucket is
therefore *another `mad` against the same `Bop`* plus its own accumulator set and partial store — **not a second
pass over the weight stream**. That is what makes the projected x1.44 (rows=32) … x2.36 (rows=256) plausible, and
it is a ~5-site change in one kernel, not a rewrite.

**Supporting measurement.** Bucketed launches are additive even though 5.86 MiB of weights would in principle
sit in L2, so the second launch is served from DRAM (13.7 µs for 5.86 MiB ≈ 450 GB/s, matching the 484 GB/s
stream slope) — whatever is evicting between launches (activation + partial traffic) does not discriminate
between "cache-friendly" and "cache-hostile" cases. The shared-stream kernel does not depend on retention at
all: the tile is read once and reused from registers, which is exactly why it should capture the projection
rather than a partial version of it.

**The five edits.**

| # | site | change |
|---|---|---|
| 1 | `acc[NF]` (345) | → `acc[BKT][NF]`; zero all buckets when `cti == 0` |
| 2 | `mad(a_tile)` (359) | → `mad(a_tile, int b)` writing `acc[b][f]`; `Bop` untouched — that is the whole point |
| 3 | `step()` (~398) | `for b < BKT: mad(ap + b * XBUCKET)`; `ap` still advances `ADW` per k-tile; `XBUCKET = ntile * ADW` |
| 4 | `store_part(e)` (346) | loop `b`, base `PART + b * PARTBUCKET` (bucket region = current `KS*2*E*RPAD*n`) |
| 5 | host | one contiguous `XA` of `BKT` buckets and one `PART` of `BKT` regions; `combine()` once per bucket against its own `Q`/`SX8`/`Y` (the `DPAS_BUCKETS` path already builds these per-bucket tensors — it currently hands them to separate launches) |

**Register budget (the risk).** Per bucket at `MR=8, NF=2` (16 rows): accumulators `2 × 8 = 16` GRF-equivalents
(each `simd<int32_t, MR*NCOL>` = 128 ints over 16 lanes = 8 regs). Plus `Bop` 16, activation tile `At`
(`ADW = 256` dwords = 16, transient per bucket), prefetch ring (`NSET × XW` ≈ 8), addressing/shift constants —
so `BKT=2` lands near **72–80 of 128 GRF** and should be spill-free; **`BKT=4` needs ~64 GRF of accumulators
alone (≈110 total)**, where spill is the likely outcome and the gain may invert. Consequences: build `BKT=2`
first (rows=32), check the ISA census for spills before believing any `BKT=4` number, and consider
`BKT=4 @ MR=8, NF=1` (8-row buckets) as the alternative shape if 16-row buckets do not fit.

**Second-order risk to watch:** per bucket the kernel loads a full activation tile (~1 KB) from L2 while the
weight tile is 96 B, so `BKT` multiplies L2 activation traffic even as it divides DRAM weight traffic. Above
~32 rows that traffic, not the stream, may become the wall — the `FETCH_ONLY` / `ALU_ONLY` switches separate
them, and the row-work slope measured so far (7.7 µs per 16 rows on gate) is the bound to compare against.

**Acceptance criteria (all measurable with what exists now).**
1. Each bucket bit-exact against its own `y_ref` slice — `gate_dpas.py` already has per-bucket slice checking.
2. Beat the additive baseline it replaces: rows=32 must come in under ~41.9 µs (target ≈ 29–31 µs from the
   two-point projection); anything above ~36 µs means the activation-traffic or spill cost ate the stream win.
3. Spill-free ISA census for every `BKT`/`M` combination actually shipped (`NEO_CACHE_PERSISTENT=0`, the
   archived-file rule from LESSONS 41).
4. In the cost model, `dpas_shared` becomes a family with its own measured table; `n_buckets()`'s additive law
   stays as the fallback for row counts the shared kernel does not cover.

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

Timing discipline, calibrated by measurement rather than habit (`out_rows_gt16.txt` has the sweep): warm up with
**1–5 s of continuous work inside the process that times** (an earlier version of this note said 15–20 s; a
0/1/3/5/20 s sweep converges by 1 s — 31.1 → 13.9 → 13.7 µs — and post-compile sleeps buy nothing), then
round-robin interleaving of configurations, min-of-N with per-round drift reported. **Cross-window absolute µs
must not be compared at all** — the earlier ±15–20 % allowance was too generous by an order of magnitude, a
2.3× swing was observed — and every batch carries an **anchor**: an unchanged binary on an unchanged case (here
rev I, gate rows=1, 19.4 µs), so a whole-window shift announces itself instead of being explained away. No
number enters a doc unless a finished command printed it. ISA dumps need
`NEO_CACHE_PERSISTENT=0 IGC_ShaderDumpEnable=1 IGC_DumpToCustomDir=<dir>` — without the first variable the
Level-Zero shader cache means IGC never runs and the dump is silently empty.