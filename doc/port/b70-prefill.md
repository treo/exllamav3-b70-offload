B70 prefill: what changes when the weights are resident, and the one kernel that has to exist for it
=====================================================================================================
Status: **in scope** (operator direction). This note replaces the "non-goal" disposition this chapter first
wrote for architecture.md §12 row "DPAS route R1 vs R2", and it exists because that row's gate - "E4/E7 prefill
sweep at 32/128/512 rows" - names an experiment no kernel in this tree can run: `probe_dpas9` supports M ≤ 16
rows per launch, and everything larger is row-bucketing, which E29 measured as **additive in weight traffic**
(x2.00 / x2.98 / x3.96 at 32 / 48 / 64 rows, `out_rows_gt16.txt`).

1. WHY THE OLD "PREFILL IS DEAD FOR S_b" CONCLUSION DOES NOT DECIDE THIS
   That conclusion was about *streaming/staging* weights from the host per chunk over the link (measured 13.3
   GB/s pinned→device, 16.3 GB/s staged memcpy, ~175 µs/job, port-acceptance E5) - a byte/rate argument that
   applies when the card cannot hold the expert set. A B70 holding routed experts changes the traffic model
   outright: prefill then reads **weights once per chunk** and streams only activations (R × H × 2 B per layer
   per chunk, ~40 MB at R=2048 on Qwen3.8, vs ~786 MB of weights). The relevant sentence in
   `out_concurrency.txt` is still true - "the binding quantity for prefill is the same one as for decode: bytes
   per layer per step" - but with residency the bytes-per-layer term is a constant (E × expert_bytes), so
   prefill cost per TOKEN falls in proportion to chunk size, which is exactly the behaviour the plan said the
   B70 could not have.

2. MEASURED INPUTS (all from this tree, nothing assumed)
   FIRST, A UNITS CORRECTION to the version of this note that cited "272 rows". That figure is
   (367e12/2 MAC/s) ÷ 674e9 B/s = 272 **MAC per byte**, which belongs to 1-byte-per-weight formats.
   Trellis weights are 0.375 B each and the integer-DPAS route spends 4 MACs per weight-token
   (kernels.md §2c item M1), so the arithmetic-intensity bar is 4/0.375 ≈ 10.7 MAC/byte and the
   **eligibility crossover is ~26 rows/expert at the 674 GB/s copy peak, or ~59 at the 292 GB/s this
   GEMV family actually achieves** (kernels.md §4 says exactly this; this note had it wrong).

   Rows per expert at realistic chunks, from the LIVE traced routing (`profiles/live/live_268.json`,
   mean over 48 layers; the stored profile said something much worse - see the last bullet):
       R= 512: mean 10 rows/expert; 10.4% of experts ≥ 26 rows, and they carry 75.0% of the picks
                                          (4.3% / 51.4% against the stricter 59-row bar)
       R=2048: mean 40 rows/expert; 24.3% of experts ≥ 26 rows, carrying 94.3% of the picks
                                          (15.8% / 85.6% against the 59-row bar); hottest ≈ 1,029 rows
       R=8192: mean 160 rows/expert; 40.2% of experts ≥ 26 rows, carrying 100% of picks
   So the honest statement is the opposite of "prefill is bandwidth-bound, the kernel does not need the
   matrix unit": **a minority of experts per layer carries nearly all the work, and those experts are
   already past the XMX bar at every chunk size worth running.** The design consequence is per-expert
   tiering (kernels.md §2c item 2: tile height ≤ rows/expert, `MS_=4` vs `MS_=1` because a 64-row tile
   "wastes ~60/64 rows" at small M), not one kernel for the whole chunk.
   Under the STORED profile the same R=2048 / 59-row test qualifies 0.4% of experts carrying 0.6% of
   picks - i.e. the flat routing profile had been quietly arguing AGAINST building the prefill path, and
   it was the wrong input (out_live_trace.txt), which is the second time this week that input changed a
   build/no-build decision.
   * Weight bytes per layer, from the census (`out_placement.txt`): Qwen3.8@2.05 599 MiB, @2.68 750 MiB,
     @4.05 1.17 GiB, @5.05 1.47 GiB, @6.05 1.76 GiB, GLM@3.05 2.53 GiB; B70 usable 31.9 GiB against expert
     sets of 28.1 / 36.3 / 56.3 / 70.3 / 84.4 GiB. **Residency is the first constraint, not the kernel.**
   * Decode-side rates the same kernel family already achieves: 437 GB/s effective (rev L, small resident set,
     partly L2), 492 GB/s at E=96 rows=1, 287-292 GB/s at E=96 rows=16 (`out_quant_ladder.txt`); copy peak
     674 GB/s; sustained power caps the box near 285 W with DRAM at ~54% of peak (`out_sustained_power.txt`).
   * Kernel-shape constraints that any prefill route inherits: 128 GRF/thread budget, and M>16 per thread
     spills 1,856-3,584 B/thread to scratch (E29); a work-group may hold at most 64 work-items for kernels of
     this register footprint (E25c's `Total number of work-items in a work-group cannot exceed 64`); SLM is
     128 KiB per group and a group-scoped barrier is free (−0.03…+0.22 µs, `out_e25c_groupscoped.txt`).

3. THE ARITHMETIC, WHICH SAYS WHY THE KERNEL MATTERS MORE THAN THE ROUTE
   Bucket amplification, computed on the live routing (each touched expert's bytes re-read once per 16-row
   bucket, Qwen3.8@2.68, equal bytes/expert, mean over 48 layers):
       R= 512 -> 2.24x      R=2048 -> 7.01x      R=8192 -> 26.29x
   (support caveat: "touched" is the 205.7 experts the 192-token trace ever selected, so the true tail -
   experts with small but non-zero p - dilutes these slightly downward; the numbers are per-layer means.)

   Per MoE layer for one 2048-token chunk, Qwen3.8@2.68 (750 MiB of expert weights):
     weights read ONCE      750 MiB → 1.17 ms/layer at 674 GB/s  →  56 ms/chunk → 36.6k tok/s
     weights read 7.01x    5.26 GiB → 8.2 ms/layer               → 393 ms/chunk →  5.2k tok/s
   Compute ceiling for the same chunk (48 layers, 3 projections, the 4-MAC-per-weight-token integer route):
   ~2.2 ms/layer → 105 ms/chunk → 19.2k tok/s, i.e. **the bucketed kernel sits at 1/7 of the memory roof and
   still below its own compute ceiling - the worst of both**, and the gap widens with chunk size (26.29x at
   R=8192). So the prefill case for the B70 is decided by one property: does an expert's weight bytes get read
   once per chunk, or once per 16 rows? **Measurement answered this: once per 16 rows, and it does not matter.**
   Two escapes were built and tested — co-resident row slabs (`probe_gemm`) and rows-deep items that read each
   tile once (`probe_xmx`) — and neither beat 16-row launches (1.47x / 2.01x worse at 32 / 64 rows for the
   latter), because the constraint at these shapes is register pressure and device fill, not bytes
   (`out_probe_gemm.txt`, `out_probe_xmx.txt`). Read the amplification table below as a **capacity and energy**
   statement, not a time statement.
   For GLM the arithmetic is harsher in capacity and gentler in traffic: 2.53 GiB/layer cannot be resident on
   one 31.9 GiB card across 42 layers (106 GiB), so prefill there is a residency-policy question first - and
   its rows/expert at R=2048 is ~2048×8/288 ≈ 57 mean, ≈ 4 buckets today. GLM has no live trace, so unlike
   Qwen3.8 its hot-tail share (§2's 94%-of-picks number) is unmeasured, not small.

**3a. MEASURED AT REAL CHUNK SIZES** (`out_prefill_scale.txt`; E=512 so weights per projection = 251 MiB =
10.5× L2, WARM_S=3, anchor 19.1 µs, down_proj measured rather than scaled, expert leg only):

       R      buckets/layer   ms/chunk (48 layers)   tok/s (expert leg)   traffic amplification
    1024         770.8             210.9                   4856                3.71x
    2048        1396.5             382.1                   5360                6.72x
    4096        2683.1             734.1                   5580               12.90x

The byte model and the measurement agree: §3's one-read roofline of 36.6k tok/s divided by the measured 6.72×
amplification gives 5.45k against 5.36k measured at R=2048 (1.6 %). Cost is **linear in R** — buckets ≈
R·topk/16 — so larger chunks do not help much; only lowering the amplification does, and the two mechanisms that
could (rows-deep items, SLM staging) both measured worse, leaving **co-scheduled slabs at 9–16 %** as the only
demonstrated softening. Against the parent's measured prefill at matched size (873 tok/s plain, **1114 tok/s
with `-mcpa`**, 4096 tokens, whole step), the B70's expert leg alone is
~8×, but the honest end-to-end number needs the parent's non-expert prefill cost, which has never been
measured (§5's owed item 1 is now the blocking one).

4. THE DESIGN THAT AVOIDS THE SPILL — SUPERSEDED BELOW by `probe_slm` measurements; read §4a as the design
   Register pressure is what caps M at 16, so do not raise M per thread. Keep **an expert's B tile resident in
   SLM and loop its row-slabs inside the kernel**: each work-item still computes a 16-row slab (the shape that
   provably fits 128 GRFs), but the weights come from SLM instead of DRAM, so the DRAM traffic per chunk is
   one read per expert regardless of how many slabs the expert needs. Group budget: 64 items × (B fragment
   registers + 16-row accumulator) is the same footprint that already works at decode; SLM at 128 KiB/group
   cannot hold a whole expert (Qwen3.8 gate is 0.49 MiB), so B is staged per K-chunk and the K-loop, not the
   M-loop, drives SLM turnover - the traffic question is whether a K-chunk's B bytes are re-read per M-slab
   from SLM (cheap, on-chip) rather than from DRAM (the failure mode we are removing).
   Named experiment (call it `probe_gemm.cpp`, decode-probe lineage, same timing protocol):
     * shapes: real Qwen3.8@2.68 gate/up/down tiles at E ∈ {10, 96}, rows/expert ∈ {16, 32, 64, 128};
     * variants: (A) today's bucketing, as the control; (B) SLM-staged B, M-slab looped, integer/u8 operands
       (**route R2**); (C) same but B dequantised to fp16 on load (**route R1**);
     * the measured quantity is **effective weight bytes per chunk** (derive from G-w/s × K ÷ 8, the chapter's
       convention) not just µs, because the whole question is traffic amplification;
     * pass: ≥437 GB/s effective AND ≤1.15× one-read traffic at rows/expert = 64; fail: traffic scaling with
       ⌈rows/16⌉, which means the route is settled but the mechanism is wrong;
     * R1-vs-R2 discriminator: their ALU costs differ (R1 pays dequant per load: 4 unpacked bytes → fp16;
       R2 keeps the integer domain and scales in the epilogue, which D6 already requires contraction-safe) but
       their DRAM traffic is identical, so at rows/expert ≤ 105 - where §2 says prefill lives - **the routes
       should be indistinguishable and the choice is dequant ALU headroom**, measurable as the delta B-vs-C at
       fixed traffic. That is a much cheaper question than the one §12 posed, and it is answerable at
       rows=32/64, not 512.
   Constraint to design around, already measured: 64 work-items per group. At 16-row slabs that is 1,024 rows
   of M coverage per group per K-chunk - comfortably above the 105 rows/expert the measured distribution
   needs, so the cap is not the binding term for prefill (it was, decisively, for E25c's cross-dependency
   fusion, where one group had to cover a whole expert's tiles).

**4a. WHAT MEASUREMENT SAID (probe_slm, `notes/b70/out_prefill_gemm.txt`) — the SLM mechanism above is
   refuted outright; what replaces it is a HYPOTHESIS, not a measurement.** With identical ALU per dword and,
   after the ISA showed the first comparison was scalar-vs-vector, identical `load.ugm.d32x4` widths in all
   three modes:
     * **SLM staging is 1.44× / 2.51× / 6.03× slower** than reading globally at 20 / 40 / 80 KiB per group,
       degrading as the staged region grows. The ISA gives the mechanism: the same walk costs 1177 instructions
       instead of 719, because staging adds 89 `store.slm` plus 80 `load.slm` on top of the 80 global loads it
       was meant to replace. No scratch traffic in any mode, so this is not a spill story — and to keep the
       accounting honest, the two 40 KiB bodies here spill comparably (256–320 B of `%scratch`, 10 scratch
       loads / 8 stores each), so spills are not the differentiator either.
     * I also wrote that concurrent global re-reads are *cheaper* than unique reads (1689 vs 1348 GB/s of
       unique bytes at 40 KiB; 1581 vs 1130 at 80 KiB). **Retracted as a measurement** — see the CONFIDENCE
       block in the artifact: both probe bodies turn out to be dominated by scalar address arithmetic (149
       `add`, 100 `shl` against 32 vector loads) and the reuse mode does 32× the loads per iteration for a
       near-identical time, which is math-bound behaviour, not memory-bound. It remains a reasonable
       *hypothesis* (and matches llm-scaler's group-major rule 4), to be tested by `probe_gemm`.
   Scope note on the refutation: the probe reads SLM with a per-lane strided vector pattern. A layout designed
   for SLM broadcast — llm-scaler's linearized `asyncCopyTile<AOS,true>` layouts — might not show this, and
   that is untested; what is tested is that *my* proposed staging shape is a non-starter, and the fact that
   llm-scaler went to real trouble over AOS layout is consistent with SLM being easy to misuse.
   Design that follows: **(expert, column tile, k-slice) → work-group**, **(16-row slab) → work-item**, one
   launch per chunk, B read from global exactly as decode does it today. No staging pass. The E25c cap of 64
   work-items/group allows 1,024 rows of M coverage per group against the ~105 rows/expert measured, so the cap
   is not binding here (unlike E25c's cross-dependency case).
   This also *explains* E29's additive bucket law instead of contradicting it: buckets are separate launches,
   so by the time bucket 2 revisits an expert far more than L2 has streamed past and the reuse distance is
   gone. Same bytes, same kernel, different co-scheduling — which is why the fix is a mapping change.
   The experiment list above stands with one amendment: variant (B) becomes the group-mapped global-read kernel
   (not SLM-staged), and the pass criterion stays traffic-based (≤1.15× one read per expert per chunk at
   rows/expert 64) with the ISA checked for scratch. The failure mode to watch for is a kernel that puts row-
   slabs in successive iterations of *one item's* loop — that recreates the bucket pattern's reuse distance
   inside a single thread and will look correct while paying 7×.

5. WHAT THIS DOES NOT CLAIM
   * No prefill number in this note is measured on the B70 yet: §3's throughput figures are the card's own
     measured bandwidth and MAC ceilings applied to measured byte counts, i.e. roofs, not observations. The
     first observation worth having is experiment (B) at rows=32.
   * Activation traffic, scheduler and the engine's chunking (chunk_size 4096 default) are not modelled here;
     at R=2048 activations are ~5% of the bytes, so the omission is safe for the roofline and not for a
     wall-clock prediction.
   * The matched prefill baseline exists and has been **re-measured at realistic size**; the 2048-token figures
     this section first published are superseded, because the parent pays a fixed cost per forward that 2048
     tokens cannot amortize (`notes/b70/run_prefill_long.sh`, `out_prefill_long.txt`; varied-document corpus,
     `-mct 15`, same instrument as the decode baselines):
       Qwen3.8@2.05, `-mcs 256`:  2048 tok → 655 tok/s (superseded) · **4096 tok → 873 tok/s** (23.9 µs/layer/tok)
       Qwen3.8@2.68, `-mcs 384`:  2048 tok → 479 tok/s (superseded) · **4096 tok → 518 tok/s** (40.2 µs/layer/tok)
     Chunk size is a weak lever (+5.8 % from 1024 → 2048, **0.0 %** from 2048 → 4096, i.e. the operator's
     2048-4096 band is a flat optimum costing ~90 ms per chunk boundary), while prompt length is a strong one
     (~410 ms fixed per forward: the same chunk size yields 459 tok/s at 1024 tokens and 825 at 4096), so
     **prefill tok/s must never be quoted without its prompt length**. Repeat text adds a further upward bias of
     **+4.2 %** measured against a distinct-document corpus, and it moves exactly as predicted - throughput up,
     distinct experts touched down 4.4 % - which is why the baseline corpus is now non-repeating (`--corpus`) and
     why a short prompt is a hard error rather than a warning.
     **`-mcpa` is the largest prefill lever found so far and it is a flag, not a kernel** (`out_prefill_mcpa.txt`):
     **+30 % on 2.05 (858 → 1114 tok/s) and +50 % on 2.68 (490 → 736)**, present on pass 1 of a cold process, so
     unlike decode it needs no adaptation horizon. Leading explanation is **arithmetic migration**, not bandwidth:
     the host moves 42.6 GiB/s from DRAM (`out_host_mem.txt`) and a 4096-token chunk's *unique* remote expert
     bytes (11.5 GiB = 209 experts × 1.172 MiB × 48 layers) occupy only **5.7 %** of the chunk's time, while the
     CPU expert path runs on AVX2 **without VNNI**. It survives the discriminating arm at chunk = prompt = 4096,
     where each expert's bytes are needed exactly once per forward (876 → 1064 tok/s), and it is larger on the
     capacity-tight 2.68. Two things this does **not** explain, both open:
       * `MAX_M = 4` is **not** the lever it looked like — sweeping rows 1..128 shows no cost stair at multiples
         of 4, so job granularity does not re-stream weights the way the estimate assumed (falsified without a
         rebuild);
       * the CPU expert leg **is** in the prefill path and it is the majority of it: sweeping `-mcs` at fixed
         prompt (4096) and chunk (2048) fits **time = 1992 ms + 10.23 ms × mcs with residuals under 2 ms**, so the
         parent's 4609 ms decomposes into **~2619 ms (57 %) CPU expert work + 1992 ms everything else**
         (`out_host_mem.txt` §6, `run_mcs_slope.sh`; two arms below `-mcs 128` fail to load, reproducing the
         operator's split floor). That is why `-mcpa` is worth +30 % — it removes part of a majority term. The
         B70's own all-expert leg at the same chunk is ~734 ms, so end-to-end prefill lands between
         **1.7 and 2.4 s (1.9× to 2.7×)**; the spread is exactly one unknown — how much of the 1992 ms intercept
         is the **3090's own expert leg**, which also leaves the parent when the card holds the experts. Pinning it
         is an engine-side prefill profile bucketed by kernel, not a probe.
         Precision discipline: within one process the arms fit a line to <2 ms, but the same configuration in a
         different process varies by 2.4 % (115 ms), so slopes are trustworthy and absolute levels are not — which
         is why every comparison in this chapter is a within-process arm pair.
         (Retracted: this bullet previously reported the bench's "478 ms/layer with one assignment per pick" as a
         possible CPU-side aggregation bug. The column read was `asgn/expert` = `rows × topk / distinct experts`,
         which is *picks* per expert — a derived routing statistic, not an assignment count. The header in
         `bench_cpu_moe.py` is now `picks/exp` / `ns/pick` because the old name caused the error.)
     Against decode's 58.3 tok/s at b=1 on 2.68, prefill is ~9x faster than single-stream decode, so the point
     stands but the magnitude moved: prefill touches essentially every expert per layer (measured: **418 of 512
     experts per layer at 4096 tokens, ~98 rows/expert**), so on a capacity-starved split it is dominated by
     remote work, and the roofline in §3 (~36.6k tok/s with weights read ONCE) is ~42x above the plain parent and
     ~33x above the promoted-placement one - not 75x. Two honest limits remain: the all-GPU control arm failed
     structurally (this tracer needs the CPU split's counters, so `-mcs 0` exits before measuring; the
     acceptance-era 5043 tok/s on Qwen3.5 stands as the only no-offload reference, on a different model), and the
     parent's **non-expert** prefill cost has never been bucketed, so none of these figures decompose into what
     the B70 could actually remove from them.
   * Residency policy under prefill (which experts to hold while a chunk streams through 48 layers) is the
     same machinery as decode placement, and the live-trace finding that routing is far more concentrated than
     the stored profiles (`out_live_trace.txt`) applies to prefill picks too - unverified, since the traces
     were decode-only.

Next actions, in order: (1) `probe_gemm.cpp` variants A/B at rows/expert 32 and 64, measuring traffic
amplification; (2) ~~the matched prefill baseline~~ **done for the CPU-split arms** (655 / 479 tok/s at
`-mcs` 256 / 384, above), still owed: an all-GPU control on Qwen3.8's shapes and a warm-placement repeat, since
cold placement is known to be worth 1.6-1.8x on decode; (3) then R1-vs-R2 at fixed traffic, which §4 argues is
the cheap part. Update §12's row when (1) lands.

6. EXPERIMENT SPEC FOR `probe_gemm` (written so the next session implements it in one pass)
   Rev L has NO bucket loop -- above 16 rows the engine buckets *launches* (additive law, `out_rows_gt16.txt`),
   which is exactly why the buckets are temporally separated and cannot re-use. So the experiment is a grid
   change, not new arithmetic. Base: `notes/b70/probe_dpas9.cpp`, whose decomposition is
   `sub = gid & 1; tile = (gid>>1) % TN; ks; expert`.
     * **Variant B (concurrent slabs).** Replace the `2` axis (the abandoned E25c dual-projection slot) with
       `NSLAB`: `threads = TN * KS * NSLAB * E`, slab index varying FASTEST so that items differing only in slab
       are adjacent and therefore co-resident. Row base per item = `slab * 16`. Pad `XA` to `NSLAB * 16` rows
       with zeros so every item computes a full `MR=16` tile and no masking is needed in the inner loop; the
       combine picks the slab owning each real row and reduces over `(ks, slab)`. `PART` gains the slab index.
     * **Variant A (control, sequential buckets).** Same kernel, one item loops `for s in 0..NSLAB` over row
       bases. This must reproduce the additive law if the law is real.
     * **Scoring, in order of evidential weight.** (1) *Positive control:* B at `NSLAB=1` must reproduce rev L's
       number within noise -- that isolates the reordering's own cost, and if it fails nothing else is
       interpretable. (2) *Bend the law:* B at `NSLAB=2,4` (rows 32, 64) versus A at the same rows; A/B is the
       traffic-amplification ratio, i.e. the thing §3 measured as 7.01x analytically. (3) *Bit-exactness* against
       the host reference for rows 17..64 (`gate_gemv.py`'s oracle; a partial-ordering bug shows up here first).
       (4) *ISA on both*, before comparing timings: equal `load.ugm.d32x4` counts, no scratch ld/st, accumulator
       still in registers -- the mistake that made `probe_slm`'s first run meaningless (LESSONS 68), and
       B's whole claim is that a register-resident accumulator plus co-resident slabs is cheaper than a re-read.
     * Shapes: E in {8, 16, 32}, Qwen3.8@2.68 gate/up geometry (tn=40, k=4096), rows in {16, 32, 64}, KS swept
       per cell because split-K trades against slabs for the same 2048 slots (`best_launch`'s tables). If B wins
       at fixed rows, the winner is a *dispatch* change the engine can adopt without touching the arithmetic; if
       B ties A, the additive law is real and prefill's traffic cost stands as §3 computed it -- also worth
       knowing, because it settles the R1/R2 question by removing R2's main motivation.

   **RESULT (executed, and the answer came back different from what this section assumed).** Step (1) became
   `probe_slm` (SLM staging is 1.5–6.0x slower than global reads — solid — while its "concurrent re-reads are
   cheaper" claim did not survive a second ISA read; see `out_prefill_gemm.txt`). Step (2) became `probe_gemm`
   (slab axis, bit-exact, no re-use gain; the A/B difference is device fill) and then `probe_xmx`, a
   clean-room rows-deep kernel built because probe_gemm carried too much decode heritage — 12/12 bit-exact and
   1.07x / 1.47x / 2.01x WORSE than 16-row bucketing at rows 16 / 32 / 64, with the spill cliff (0 B at NF=1/2,
   1792 B at NF=4, 7808 B at NF=8) sitting exactly where rev L's "16 rows" cap sat. Step (3) is therefore
   moot: rows never reach a regime where the matrix unit's compute advantage is accessible through more rows
   per item, because registers bound rows per item at 16 first. The surviving recommendation for prefill is
   16-row launches with split-K chosen for fill, plus the residency/admission policy in §2 — and the open
   question that would change the verdict is weights-per-launch exceeding L2 (E=128/256 on this probe), not a
   better GEMM.