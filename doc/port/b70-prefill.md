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
   * Rows per expert at realistic chunks (`out_concurrency.txt`, Qwen3.8@2.68, topk 10, E 512):
       R=512  → max  26 rows/expert,  0 of 512 above the 272-MAC crossover
       R=2048 → max 105 rows/expert,  0 above 272
       R=8192 → max 419 rows/expert, 49 of 512 above 272
     so at chunk sizes the 3090 can actually feed in one pass, MoE prefill on this model class is
     **bandwidth-bound, not compute-bound** - which is good news: it means the kernel does not need high MFU,
     it needs to read each weight byte once.
   * XMX/DPAS ceiling: 367e12/2 MAC/s against 674e9 B/s ⇒ ~272 MAC per byte, ~102 rows/expert for the 0.375
     B/weight trellis (corrected units in §12); 49 of 512 experts pass it only at R=8192.
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
   Per MoE layer, one 2048-token chunk, Qwen3.8@2.68 (750 MiB of expert weights, ~105 rows/expert):
     weights read ONCE           750 MiB → 1.17 ms/layer at 674 GB/s   →  56 ms/chunk → 36.6k tok/s
     weights read ⌈105/16⌉=7×   5.2 GiB → 7.9 ms/layer                 → 380 ms/chunk →  5.4k tok/s
   Compute ceiling for the same chunk (48 layers, 3 projections, 2 MACs per multiply-accumulate): 2.2 ms/layer
   → 105 ms/chunk → 19.2k tok/s, i.e. **at R=2048 the bucketed kernel is bandwidth-bound at 1/7 of the memory
   roof and lands below its own compute ceiling** - it is the worst of both. The same ratio at R=8192 is
   ~27×. So the prefill case for the B70 is decided by a single property: does an expert's weight bytes get
   read once per chunk, or once per 16 rows?
   For GLM the arithmetic is harsher in capacity and gentler in traffic: 2.53 GiB/layer cannot be resident on
   one 31.9 GiB card across 42 layers (106 GiB), so prefill there is a residency-policy question first - and
   its rows/expert at R=2048 is ~2048×8/288 = 57, i.e. four buckets today.

4. THE DESIGN THAT AVOIDS THE SPILL - AND THE EXPERIMENT THAT TESTS IT
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

5. WHAT THIS DOES NOT CLAIM
   * No prefill number in this note is measured on the B70 yet: §3's throughput figures are the card's own
     measured bandwidth and MAC ceilings applied to measured byte counts, i.e. roofs, not observations. The
     first observation worth having is experiment (B) at rows=32.
   * Activation traffic, scheduler and the engine's chunking (chunk_size 4096 default) are not modelled here;
     at R=2048 activations are ~5% of the bytes, so the omission is safe for the roofline and not for a
     wall-clock prediction.
   * The matched prefill baseline now exists (partially). Same instrument as the decode baselines, same model,
     2048-token chunk, real text, `-mct 15` (`notes/b70/run_prefill_baseline.sh`):
       Qwen3.8@2.05, `-mcs 256` (256 of 512 experts on the CPU home): 3125.4 ms → **655 tok/s** (31.9 µs/layer)
       Qwen3.8@2.68, `-mcs 384`:                                     4276.3 ms → **479 tok/s** (43.5 µs/layer)
     Against decode's 58.3 tok/s at b=1 on 2.68, prefill is only ~8x faster than single-stream decode - which
     is the point. Prefill touches essentially every expert per layer, so on a capacity-starved split it is
     dominated by remote work, and the roofline in §3 (56 ms/chunk at 674 GB/s with weights read ONCE, i.e.
     ~36.6k tok/s) is ~75x above what the shipping stack achieves. Two honest limits on that comparison: the
     all-GPU control arm failed structurally (this tracer needs the CPU split's counters to trace, so
     `-mcs 0` exits before measuring - the acceptance-era 5043 tok/s on Qwen3.5 stands as the only no-offload
     reference, on a different model), and the numbers are cold-placement single passes, not a tuned prefill
     configuration. Neither caveat closes a 75x gap.
   * Residency policy under prefill (which experts to hold while a chunk streams through 48 layers) is the
     same machinery as decode placement, and the live-trace finding that routing is far more concentrated than
     the stored profiles (`out_live_trace.txt`) applies to prefill picks too - unverified, since the traces
     were decode-only.

Next actions, in order: (1) `probe_gemm.cpp` variants A/B at rows/expert 32 and 64, measuring traffic
amplification; (2) ~~the matched prefill baseline~~ **done for the CPU-split arms** (655 / 479 tok/s at
`-mcs` 256 / 384, above), still owed: an all-GPU control on Qwen3.8's shapes and a warm-placement repeat, since
cold placement is known to be worth 1.6-1.8x on decode; (3) then R1-vs-R2 at fixed traffic, which §4 argues is
the cheap part. Update §12's row when (1) lands.