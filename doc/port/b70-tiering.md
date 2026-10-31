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
| GLM@3.05, 109.3 GiB of experts vs 24 GiB | essentially none | not measured | **complement**: the card is the only home with slack, and it is also what removes the `S_c` residue that the `P_order` table keeps winning on |

Derived, and it is the load-bearing arithmetic: on 2.05 prefill the CPU expert leg is **2619 ms of a 4609 ms
chunk (57 %)**, `-mcpa` removes **948 ms of that term (36 %)**, and moving the whole expert leg to the card costs
**734 ms**. The floor is therefore **2724 ms = 1.69×**, and it is the *same floor* whether `-mcpa` is on or not —
because the second mechanism cannot remove bytes the first already moved. Claiming 1.69 × 1.26 would be counting
one term twice (LESSONS 82). §5.1 reports this tested against measurement, including the two things the model did
not predict: `-mcpa` costs +221 ms of overhead, and its relief saturates because the promoted set is a fixed-size
window.

## 2. CAPACITY GEOMETRY — WHY BIG MODELS ARE THE GOOD CASE

**Measured** (safetensors census ÷ experts ÷ layers; loader agrees within 3 %):

| config | MiB/expert | GiB/one layer | all experts | B70 31.9 GiB holds | B70 spread over all layers |
|---|---|---|---|---|---|
| Qwen3.8@2.05 | 1.21 | 0.61 | 29.2 GiB | 52 layers' worth | 512 experts/layer (everything) |
| Qwen3.8@2.68 | 1.56 | 0.78 | 37.5 GiB | 41 layers' worth | 512 experts/layer |
| GLM@3.05 | 9.25 | 2.60 | 109.3 GiB | 12.3 layers' worth | **84 of 288 experts/layer (29 %)** |

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

## 5. OPEN, IN PRIORITY ORDER

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