# B70 as a promotion destination: how `-mcpa` changes the plan for big models and big quants

Status: design note. Everything marked **measured** came from this tree's instruments (dates 2025-11,
`out_prefill_mcpa.txt`, `out_host_mem.txt`, `out_prefill_long.txt`); **derived** is arithmetic on those;
**open** is unmeasured and named as such. This note does not re-decide anything in
`b70-architecture.md` §“HOME vs JOB” or the `P_order`/`P_lpt` table — it constrains them with new numbers.

## 1. THE SHORT ANSWER

`-mcpa` and the B70 worker are **partly substitutes and partly complements, and which one dominates depends on
how much VRAM slack the parent has** — which is exactly the axis that separates “fits comfortably” (Qwen3.8@2.05)
from “big model / big quant” (GLM, 2.68+):

| regime | 3090 slack to promote into | `-mcpa` measured | B70 relationship |
|---|---|---|---|
| Qwen3.8@2.05, `-mcs 256` | comfortable | **+30 %** prefill (858 → 1114 tok/s) | **substitute** over one term: combined cap 1.69×, incremental only 1.34× |
| Qwen3.8@2.68, `-mcs 384` | thin | **+50 %** (490 → 736) | mostly substitute, larger prize because the CPU leg is bigger |
| GLM@3.05, 109.3 GiB of experts vs 24 GiB — and **87 % of host RAM** (125 GiB box, pinned staging on top), so the CPU home has no reserve either: a GLM `+ -mcpa` chunked-prefill arm hard-hung this machine (LESSONS 87) | essentially none | **−29 % at decode b=1 (16.0 → 11.4 tok/s)**; **+33 % at prefill (126 → 167 tok/s)**, measured in a watchdogged attended run — the sign flips with the phase, not the model | **complement and then some**: the parent is 71 % exposed stall, so the card is the only way to lift the step; but promotion must be throttled hard, since a GLM expert upload costs 0.66 ms |

Derived, and it is the load-bearing arithmetic: on 2.05 prefill the CPU expert leg is **2619 ms of a 4609 ms
chunk (57 %)**, `-mcpa` removes **948 ms of that term (36 %)**, and moving the whole expert leg to the card costs
**734 ms**. The floor is therefore **2724 ms = 1.69×**, and it is the *same floor* whether `-mcpa` is on or not —
because the second mechanism cannot remove bytes the first already moved. Claiming 1.69 × 1.26 would be counting
one term twice (LESSONS 82). §6.1 reports this tested against measurement, including the two things the model did
not predict: `-mcpa` costs +221 ms of overhead, and its relief saturates because the promoted set is a fixed-size
window.

## 2. CAPACITY GEOMETRY — WHY BIG MODELS ARE THE GOOD CASE

**Measured** (safetensors census ÷ experts ÷ layers; loader agrees within 3 %):

| config | MiB/expert | GiB/one layer | all experts | B70 31.9 GiB holds | B70 spread over all layers |
|---|---|---|---|---|---|
| Qwen3.8@2.05 | 1.21 | 0.61 | 29.2 GiB | 52 layers' worth | 512 experts/layer (everything) |
| Qwen3.8@2.68 | 1.56 | 0.78 | 37.5 GiB | 41 layers' worth | 512 experts/layer |
| GLM@3.05 | 9.03 | 2.54 | 109.3 GiB (43 expert-bearing layers: 42 serving + 1 MTP head) | 12.6 layers' worth | **84 of 288 experts/layer (29 %)** |

Live routing puts half a layer's picks in ~24 experts on Qwen3.8 (`out_live_trace.txt`), so a half-mass tail costs
**1.4 GiB (2.05)**, **1.8 GiB (2.68)** and, at the same relative concentration, **~5.3 GiB (GLM)** — all of it
inside the card's budget alongside a decode working set, with room for the warm band above the tail. The 3090 has
no comparable room: at `-mcs 384` on 2.68 it keeps 128 of 512 experts while holding the model and cache, and for
GLM it holds a fraction of a tenth of the expert set.

**Upload cost is not the obstacle, and I had that wrong by three orders of magnitude when I first reasoned about
it** (I estimated 0.63 s per GLM expert; 9.25 MiB at 14.4 GB/s is **0.68 ms**). Derived from the measured link
rate: one Qwen expert 0.089 ms, one GLM expert 0.68 ms, an entire GLM half-mass tail 0.40 s, an entire Qwen@2.68
tail 0.13 s. Against the marginal CPU cost of a homed expert — **10.23 ms per expert per 4096-token chunk**,
measured — a promoted expert pays for itself in a fraction of one chunk, so the admission break-even is about
*dwell time*, not bandwidth.

## 3. CHURN IS THE REAL CONSTRAINT, AND IT IS MEASURED ON THE PARENT

Promotion counters under `-mcpa` (this session, 4096-token prefill, 48 layers): **403 promotions *and 403
demotions*** on 2.05 `-mcs 256` — 8.4 experts promoted per layer, and the symmetry says the set is **oscillating,
not accumulating**. Chunk size moves it (11.8/layer at chunk 1024, 3.8/layer at chunk 4096), which is what
sub-chunk churn looks like. LESSONS 66 measured the same shape on decode: plain performs **zero** promotions,
`-mcpa` 3,689, and throughput reaches parity by pass 2.

Three consequences for the design:

1. **Capacity converts churn from a cost into a non-event.** A 3090 that can keep 8 experts warm per layer is
   playing a ranking game on a knife edge — every swap is visible. The card can hold 84 GLM experts per layer, or
   a whole Qwen layer set. The right use of the B70 in a promoted world is therefore **to hold the tail so that
   promotion stops mattering**, not to be a faster/cheaper promotion target.
2. **But do not inherit the parent's promotion cadence.** The architecture doc's HOME-vs-JOB rule (“re-deciding
   per job is what makes the CPU path's promote hook cost 2-3 ms/token”) exists for good reason, and per-expert
   upload to the card, while cheap (0.09-0.68 ms), is not free at 2-3 ms/token rates of reconsideration. Keep
   decisions at home granularity over a window, as already decided; the new numbers just set the amortisation
   scale — a dwell time of **one chunk** is already profitable, so the policy can afford to decide rarely.
3. **`EXL3_MOE_B70_PROMOTE_BUDGET` should be sized against measured churn, not taste**: the parent churns ~8-12
   experts/layer per session; a card-side budget near that scale, with hysteresis, is the comparable baseline.

## 4. WHAT THIS DOES TO THE COST MODEL (concrete edits, not vibes)

* **The CPU term must stop using a datasheet rate.** `bytes / 47.4` assumes 2× DDR4-3200 peak; measured achievable
  is **42.6 GiB/s read** (copy 24.1), so the term is ~11 % optimistic. Cross-check that lands well: the plan's
  `μ_cpu ≈ 199 µs` per assignment against a GLM expert (9.25 MiB) implies **49.7 GB/s**, i.e. ~9 % above what this
  host can sustain, and my Qwen@2.05 measurement (26.5 µs/pick for 1.21 MiB = 45.7 GB/s) is right at the ceiling.
  So `μ_cpu` is a *good* constant for rows ≈ 1 and needs no regime correction there.
* **At prefill rows it does need one.** Same kernel drops to ~half the ceiling as rows/expert grows (42.5-45.7
  GiB/s at rows 1-16 → 20.6 GiB/s at rows 96 on a large pool), and the directly measured prefill primitive is
  **10.23 ms per CPU-homed expert per 4096-token chunk**, linear to <2 ms over a 1.4× range of `-mcs`. For prefill
  costing, use that primitive; `bytes / rate` is the wrong shape there — the same “do not derive a cost from bytes”
  rule that D11 established for the parent's non-expert leg, now applied to the CPU home.
* **Baselines must be re-taken with `-mcpa` on, or the plan's speedups are inflated.** Every “today” number in the
  chapter (58.3 tok/s decode at b=1, 873 tok/s prefill) is plain-mode. `-mcpa` is a flag anyone can set, it is
  free at steady state on decode (LESSONS 66: parity by pass 2), and it is worth +30-50 % on prefill. Quote the
  B70's gain against the promoted baseline and treat the two as competing for the same term.

## 5. SHOULD THE TWO CARDS SPLIT THE EXPERT LOAD EQUALLY?

Only by accident. The plan's own objective (`plan_parent_budget.py` line 18, and the planner already passes the
measured `PARENT_EXPERT_GBPS = 190` for calibrated models, so this is not a stale-rate artefact) is

    wall/layer = max( T_parent + bytes(S_g)/190 ,  bytes(S_b)/rate_b ,  bytes(S_c)/42.6 )

and everything follows from the first two terms being **added differently**: the 3090's expert work sits *on top
of* its non-expert work, while the card's runs *in parallel with* it. So the target is not equal bytes, not equal
picks, and not even equal time — it is **equal time after each home absorbs its own overheads**, which yields:

**Rule. Put expert work on the card up to the point where the card's term equals the parent's
`T_parent + its expert share`. If the card's whole expert leg is already below `T_parent`, load it completely and
give the 3090 nothing — any byte handed back only lengthens the critical path.**

Solving that on the plan's constants (card 292 GB/s and 3090 190 GB/s for Qwen; GLM card 132 GB/s — its geometry
makes the card *slower* per byte than the 3090, which is the whole reason GLM's answer differs):

| config | rows | optimal **card** share | optimum µs/layer | 50/50 µs/layer | all-card µs/layer | gain of optimum over all-card |
|---|---|---|---|---|---|---|
| Qwen3.8@2.68 | 1 | 1.00 | 195.6 | 236.0 | 195.6 | 0 % (nothing to gain) |
| Qwen3.8@2.68 | 4 | 1.00 | 224.9 | 386.6 | 224.9 | 0 % |
| Qwen3.8@2.68 | 8 | 0.88 | 373.2 | 616.8 | 420.9 | **+12.8 %** |
| Qwen3.8@2.68 | 16 | 0.78 | 666.0 | 1028.2 | 841.7 | **+26.4 %** |
| Qwen3.8@2.05 | 16 | 0.77 | 505.8 | 774.7 | 648.1 | **+28.1 %** |
| GLM@3.05 | 1 | **0.51** | **296 µs/layer (measured T_parent)** | 300 | 574 | **+94 %** — splitting is mandatory at b=1 |
| GLM@3.05 | 4 | **0.44** | 1000.8 | 1147.7 | 2295.4 | **+129 %** |
| GLM@3.05 | 8 | **0.42** | 1941.9 | 2295.4 | 4590.9 | **+136 %** |
| GLM@3.05 | 16 | **0.42** | 3826.4 | 4590.9 | 9181.7 | **+140 %** |

Read the last three columns together: **equal splitting is between nothing and 54 % worse than the optimum**, and
it is closest to right exactly where the two homes have similar per-byte rates (GLM, where the card is *slower*
per byte on its geometry). For Qwen the optimum is 3–4× more work on the card than on the 3090, because the card
is 1.5× faster per byte *and* unencumbered — the 3090 is already spending 142–225 µs/layer on non-expert work
(hyper-connections included, D11). At rows ≤ 4 the answer degenerates: the card's entire expert leg hides under
that non-expert term, so **the split is irrelevant and a 50/50 policy is pure loss (+21 % at b=1, +72 % at b=4**
on 2.68**)**.

**Prefill: never split.** Measured card leg for a 4096-token chunk is 734 ms against a measured 1988 ms parent
non-expert term, so the card has ~1.25 s of free shadow and the parent has none: every expert byte moved to the
3090 adds to the critical path monotonically — 1988 → 2248 → 2509 → 3029 ms as the card share falls from 1.00 to
0.00. Capacity does not force otherwise either: the 3090 must hold experts only when the set exceeds 31.9 GiB
(2.68: 37.5 GiB), and then the leftover belongs on its *hot* end, not spread evenly.

**Amended by the kernel decomposition (`notes/b70/out_prefill_decomp.txt`, D24) — conclusion stands, reason
changes.** The 1988 ms parent term is not one thing: measured at `-mcs 256`, it is ~1166 ms of model work and
~756 ms of `copy` belonging to the offload path itself (and 8886 ms of copy, 77 % of device time, at 4.05 bpw).
This weakens the *magnitude* of the parent's shadow but not the conclusion, because the irreducible part alone
(1166 ms) still exceeds the card's whole 734 ms expert leg: prefill still never splits. What does change is the
priority order — if a card home inherits the same host-staged round trip, the transfer tax comes with it, so the
card's activation path (two-hop host-staged, cross-vendor P2P if one exists, or per-layer batching) is now the
highest-value measurement in this plan, ahead of any remaining kernel work. Until it exists, quote the prefill
upside as bounded by **~1.15 s of real work per 4096-token chunk**, not by 1988 ms of "non-expert".

Three things this arithmetic is **not**, stated because they are the parts that could move the numbers:
  * † **GLM's parent leg is measured** (rows 4/8/16 recomputed from it on 2025-11; the versions of these rows
    that used the assumed `T_parent = 595` said 0.58/0.52/0.48 and +69/+89/+105 %, and are superseded): **non-expert = 101.1 µs/layer, device total 406.7, wall 1392.2 µs/layer** at
    ctx 2048 / b=1 / `-mcs 258` / `-mct 15` (`out_engine_step.txt` §11). Three things follow, and the first one
    corrected a row of this table that I had written on the assumed value:
    * `T_parent` is **5.9× smaller** than the 595 µs I assumed, so GLM's crossover is not at rows≈5 — **the card
      is already the binding worker at b=1**, and the optimum card share is 0.51 (296 vs 574 µs/layer all-card).
      Equal splitting really is right for GLM, but because the parent's non-expert shadow is tiny, not merely
      because the two homes have similar byte rates.
    * **71 % of the GLM step is exposed stall** (wall 1392 vs device 407 µs/layer). The parent is waiting on the
      CPU worker, not computing. That makes GLM the strongest case in this plan for the card — moving picks off
      the worker addresses the stall *and* the device term — and it also means the max(·) model here,
      which only balances device terms, understates the gain.
    * **`-mcpa` is not free at decode on GLM: 16.0 → 11.4 tok/s (−29 %)**, with the `copy` bucket going
      0.2 → 151.2 µs/layer, i.e. ~2.1 MiB per layer per token of promotion traffic. Promotion cost scales with
      expert size — 0.66 ms to upload a GLM expert against 0.09 ms for Qwen@2.05 — so the "free at decode steady
      state, +30-50 % on prefill" summary I wrote earlier holds only for small experts. On GLM the two
      mechanisms have to be priced separately per direction, and a card-side tier must be throttled far harder
      than the parent's (§3) or it will spend the step moving weights.
  * The parent non-expert growth with rows (×1.15 / ×1.5 / ×1.95 at b=4/8/16) borrows the `PARENT_FLOOR_US`
    *shape* and applies it to the engine-measured b=1 *level*. The b>1 device-bucket split is a known open
    measurement, so the crossover batch (`rows ≈ 5-6` on 2.68, where splitting starts to pay) is ±one row.
  * **`rate_b = 292 GB/s is optimistic in the prefill bucket regime, by 14-34 %.** Validated against the probe:
    the measured 734 ms/chunk implies 5.70 µs per expert-bucket (matching the probe's own 2×1.546 + 2.608 µs),
    whereas `bytes / 292` predicts 486-631 ms — effective **193-251 GB/s**. Same lesson as the CPU term and D11:
    a byte rate calibrated in one shape regime must not be carried into another; use the per-bucket primitive.

Also measured while checking whether splitting has a hidden cost: **it does, and it is small.** A token whose
picks straddle both homes needs its activations at both, so any non-trivial split duplicates one in+out copy per
token per layer — 140 ms per 4096-token chunk on 2.68 (19 % of the card's own expert leg, 7 % of the parent's
non-expert term). At topk = 10 essentially *every* token straddles unless one home holds all 10 of its picks, so
the duplication is a step function, not a fraction — which is a second, independent reason not to split prefill
and a reason the decode split should be chosen on whole-token affinity where possible.

Reproduce: the tables are computed from `plan_parent_budget.MODELS` constants by the arithmetic in this section;
`plan_parent_budget.policy(lpt=True, parent_expert_rate=190)` implements the same objective as a greedy cut and
already beats the frequency-ordered cut in exactly the rows where the table above says splitting pays.

## 6. GLM'S EXPERT STRUCTURE IS NOT QWEN'S — VERIFIED AGAINST THE TENSOR INVENTORY

The tiering arithmetic above leans on `plan_parent_budget.MODELS["GLM@3.05"]`, which I had reason to distrust. It
is **right**, and the two "corrections" I was about to make were both wrong; the audit (`safetensors` headers, no
model load) is recorded so nobody re-litigates it:

| quantity | value | how verified |
|---|---|---|
| routed experts | **288, uniform across every MoE layer** | 151,554 tensor names parsed; `distinct experts per layer = [288]` |
| MoE layers in the serving path | **42** (indices 3-44) — the plan's `layers=42` is correct | indices 3-45 carry `.mlp.experts.*`, but layer 45 also carries `enorm/eh_proj/hnorm` and `num_nextn_predict_layers = 1`: **it is the MTP layer**, not per-token serving |
| dense prefix | 3 layers (`first_k_dense_replace = 3`) | config + tensors |
| routed bytes | **109.3 GiB total, 2.54 GiB/layer, 9.03 MiB/expert** | summed `data_offsets`, gate/up/down exactly equal at 36.42 GiB each. Re-measured directly off the shard headers on 2025-11: 43 expert-bearing layers (ids 3..45) x 288 experts, **9.04 MiB/expert**, 1.15 GiB of non-routed `.mlp.` bytes — and `model.safetensors.index.json` is **stale** (~3,530 tensors missing, all of them the MTP head), so it must not be used as the inventory; the loader scans the shards (`loader/safetensors.py:403`), see LESSONS 86 |
| **shared experts** | present on all 42+1 MoE layers, **~25 MiB/layer**, plus routers at 2.25 MiB/layer (`e_score_correction_bias`, `topk_method = noaux_tc`, sigmoid, `norm_topk_prob`) | non-routed `.mlp.*` families, 1.15 GiB total |

Two things that look like errors in my own reasoning and are not, written down because each was about to become a
bad edit:

1. **"43 MoE layers" is wrong.** Counting tensor indices gives 3-45 inclusive = 43, but index 45 is the MTP head,
   which does not run per token. The plan's 42 stands. Counting layers is only correct if you know which layers
   the serving path walks.
2. **The shared expert does *not* go through the bucketed MoE path.** `block_sparse_mlp.py:460` holds
   `self.shared_experts` as a `GatedMLP` submodule of the MoE block — a dense MLP, tiled over all rows by the
   dense kernels. My first pass applied the ⌈rows/16⌉ law to it and produced 256 re-reads of 25 MiB per layer
   (1.5 s/chunk of pure fiction). The correct model charges it once per chunk on the dense path. It *does* add a
   fixed per-token expert leg that placement cannot move: **a GLM token pays topk 8 routed + 1 shared**, so
   per-token expert work is ~12.5 % higher than `topk` alone implies, and that share belongs to whichever card
   holds the dense path (the 3090), not to the placement decision at all.

**What actually changes for GLM prefill** (derived from measured primitives, not measured end to end —
flagged as derived): the routed experts are 9.03 MiB each and a 4096-token chunk puts ~114 rows on each, so the
bucket law reads each one 8 times: 4096 × 8 / 16 buckets/layer × 9.03 MiB = **20.3 GiB/layer, 854 GiB per chunk**.
At the card's *measured* prefill bucket cost that is roughly **3-5 s per 4096-token chunk** — about 5-7× Qwen@2.68's
measured 0.73 s — and unlike the Qwen case the byte volume, not fill, is the binding term (`rate_b` for GLM is 132
GB/s on decode shapes, the lowest in the ladder, because its geometry is `tiles_n = 128` and cannot fuse).
Consequences worth acting on: (i) **GLM is where a deeper-M kernel would actually pay**, since 8 buckets per expert
is exactly the amplification `probe_xmx` could not beat — but the same 128-GRF accumulator bound applies, and a
9 MiB expert makes the A-operand pressure worse, so the expectation should be pessimistic until measured;
(ii) `out_prefill_scale.txt`'s "prefill on the card" numbers **must not be reused for GLM** — they are Qwen-shaped
by construction; (iii) the honest next measurement is `probe_gemm` at GLM geometry (K = 3, tn = 128, E = 288,
rows = 64) rather than any extrapolation, and the quant ladder should extend to `K = 6` prefill buckets while it
is running.

## 7. OPEN, IN PRIORITY ORDER

1. ~~The falsifiable prediction of the substitution story~~ **TESTED, and it held — plus it exposed a sharper
   fact than the prediction itself.** Re-running the `-mcs` slope with `-mcpa` on (same prompt/chunk/reps):

       | fit                       | intercept C | slope s     | residuals   | promotions/arm |
       |---------------------------|-------------|-------------|-------------|----------------|
       | plain                     | 1988 ms     | **10.24 ms/expert** | −0.6/+1.7/−1.1 ms | 0 |
       | `-mcpa`                   | **2210 ms** | **5.59 ms/expert**  | +9.9/−29.8/+19.8 ms | 390/383/384 |

   * The slope flattens by **45 %** (predicted 36 %), so `-mcpa` demonstrably acts on the CPU-expert term and the
     substitute model is right: the card's floor is 1988 + 734 = **2722 ms = 1.69×**, `-mcpa` alone reaches
     3650 ms, and the card's **incremental** value on a promoted baseline is **1.34×**. Nothing multiplied.
   * **`-mcpa` is not free: its intercept rises +221 ms** (4.8 % of the plain chunk) — promotion/demotion work
     charged to non-expert time. That is the first quantitative cost of the mechanism on this box, and it is why
     the measured relief falls short of the bytes moved.
   * **The promoted set is a fixed-size window, so `-mcpa` saturates.** Promotions stayed at 383-390 across
     `-mcs` 256/384/448 (~8 experts/layer regardless of how many experts are remote), and per-interval relief
     decays (4.96 ms/expert saved from 256→384, 3.88 from 384→448). The fit is also visibly less clean under
     `-mcpa` (±30 ms vs ±2 ms), which is what a bounded mechanism looks like. **This is the strongest argument in
     this note for the B70 as a capacity tier rather than a faster ranking target**: ranking relief is bounded by
     the window the 3090 can spare (~8 experts/layer), while capacity relief scales — the card can hold 84 of 288
     GLM experts per layer, or the whole half-mass tail of any model here.
   * Break-even: `-mcpa` pays on prefill above ~**48** remote experts, i.e. for essentially every real split —
     and its value grows with `-mcs`, which is why 2.68 (`-mcs 384`) gained +50 % against 2.05's +30 %.
   * Caveat on linearity: the `-mcpa` slope is a 3-point fit with ±30 ms residuals, so treat 5.59 ms/expert as
     ±0.5, and note the two low `-mcs` arms still cannot be measured because they fail to load.
2. **Hot-set dwell time.** Does the identity of the top-24 experts per layer persist across chunks and across
   sessions? Churn counts are measured (and are fixed-size, per above), stability is not. This decides
   static-with-capacity versus dynamic promotion, and it is cheap: emit per-layer top-N sets per chunk from the
   live tracer and intersect them.
3. **GLM has no live trace and no `-mcpa` measurement** — and the saturation result above makes it the case where
   the difference matters most: if relief is capped at ~8 experts/layer whatever the remote count, then on a model
   with 288 experts/layer and no 3090 slack, `-mcpa` can only ever touch a few percent of the picks, and the card
   is the only mechanism that scales.
4. **Two promotion targets, one policy.** Nothing measured about interference when both the 3090 and the B70 can
   receive promotions: double-promotion, ping-pong between cards, and who owns admission when both are interested.
   The B70 worker's handoff already carries placement state; this is a design question before it is a bug.
5. **Prefill's 1992 ms intercept is still unsplit** (attention + dense + hyper-connections + the 3090's expert
   leg). It bounds what any expert-placement scheme — promoted, card-resident, or both — can deliver, and it is an
   engine-side profile, not a probe.

Reproduce:
    bash notes/b70/run_mcs_slope.sh          # slope, with the arms that fail to load recorded
    bash notes/b70/run_prefill_mcpa.sh       # plain vs -mcpa per chunk size, --prefill-reps for horizon
    grep -E "promotions|median of" /tmp/prefill_mcpa/*.log