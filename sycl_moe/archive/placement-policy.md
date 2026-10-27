# Placement, tiering and streaming policy (what the knobs should be)

Which experts the B70 should own, and how the 3090's pinned arena should cooperate. Numbers
quoted here are catalogued in `measurements-ledger.md`. Knob semantics: `../README.md`.

## Hardware truths that bound everything

- main GPU = RTX 3090, link trains **Gen4 x8** (max x16 — the board bifurcates the 5950X's 24
  lanes); pinned→device probe 13.4 GB/s = 92% of link.
- B70 pinned H2D/D2H 12.9-14.5 GB/s (same physical class of link). **sysfs lies for the Arc**
  (shows x1 / max-x1): ignore it, trust measured copies.
- ⇒ the streamed-prefill weight DMA is HARD link-bound; no software knob beats ~13.5 GB/s. A
  chassis that gives the 3090 x16 would lift prefill directly.
- Decode anatomy (2.05bpw): 14.2 ms/token; rows1 b70 compute 18 µs x 48 = 0.86 ms + exposed
  collect ~10 µs x 48 = 0.5 ms — **the offload path is ~10% of the budget**, the rest is the
  3090's captured-graph replay floor. Prefill is limited by (a) 3090 expert GEMV + streamed
  recon throughput and (b) the link. Offload-path software is at its plateau; further gains need
  kernel work on one side (b70 prefill job ~11 µs/row) or the lane bifurcation fix (hardware).

## The `cap_rows` / `SLOT_ROWS` / `MAXM` hierarchy (do not conflate three "chunks")

- `cap_rows` (`EXL3_MOE_CPU_SLOT_ROWS`, python `TUNING:101` → `_issue_compute
  "for a in range(0,rows,cap)"`): **TOKEN ROWS PER WORKER JOB**. Sizes the pinned handoff slot
  (x/sel/w/out block layout single-sourced from `cap_rows` in BOTH `moe_cpu_host.py:1245-1294`
  and `moe_handoff.cu:470`), the collect window (= num_slots jobs), the b70 bounce/stage via
  `ensure_capacity`, and the tmap blob. It is the analogue of a micro-batch, NOT the DPAS tile.
- `MOE_MAXM=8` (`ChunkDev` rows): the **DPAS chunk width** = the true analogue of CUDA's
  `MOE_TILESIZE_M`. Raising it further is the wide-M tier project (new instantiations; acc/a8
  layout constants derive from it), separate from `cap_rows`.
- Why bigger `cap_rows` wins prefill (measured, E512 bench, µs/token-row): 54.6@64 → 36.5@128 →
  22.7@256 → 18.3@512 → 15.9@1024 — sublinear because slots fill toward 8 rows and the per-job
  chain (stage D2H + kernel chain + readback + collect) amortizes over more rows.
  Memory management needed for the raise: NONE functionally (device buffers grow on demand:
  `ensure_ws` by nc, `ensure_capacity` by rows) — but see `memory-and-registration.md` for the
  two real bugs a raise exposed. Default stayed 128 (512 buys ~10% more prefill on 2.68/4.05).

## Verdict: default placement is an economic optimum, not laziness

Placement-policy campaign v2 (honest plugin: real >64-row jobs, `exec_mu`, growth fix). Moving
HOT experts to the worker device LOSES ~18% prefill (invert/hot2 1375-1526 vs base 1645-1882)
while B70 utilization rises 20%→30% and power 91W→111W. Campaign v1's "invert +21% prefill" was
entirely the FATAL-refusal bug: big tail jobs returned instantly with stale slot contents, so the
"winning" runs simply skipped the work. Decode: all policies 67-73, no separation.

Why B70 loses hot work: at model shapes a prefill tail job costs ~11-13 µs/ROW (~2.2 µs/pick-row)
vs the 3090's streamed reconstruct at ~1.5-2 µs/pick-row once the ~93 µs/expert PCIe stage
amortizes over ≥11 rows. Per hot pick the 3090 path wins ~5x and only overlap makes it palatable.
**B70 wins where picks are SPARSE** (cold experts: read once, few rows, and crucially NO PCIe at
all) — which is exactly what the default placement gives it.

⇒ The real lever for B70 share (and utilization) is KERNEL-SIDE, not placement: bench
E128/rows128 was 3457 µs against a ~250 µs distinct-expert DRAM floor (13x off — later
RE-interpretated, see `int8-dpas-tier.md`: the floor itself was miscomputed and the term was the
A-operand gather). The DPAS path is latency/scheduling-bound at m8n16k32 with 8-token chunks, not
bandwidth-bound; closing that (bigger m per DPAS chain, more co-resident WGs, 128-lane groups
revisited now that the pipeline is DRAM-latency-clean) is what would let hot2/invert pay off.

## Three-tier placement (SUB) — the campaign (4.05bpw -mcs 420, pinned arena, ring, budget 0.70)

| placement | pre | dec |
|---|---|---|
| no B70 (pure CPU + pinned streaming) | 226 | 37.5 |
| classic full-layer (21/48 registered) | 590 | 48.1 |
| SUB=0.20 (48/48, tier 84) | 447 | 46.9 |
| SUB=0.35 (tier 148) | ~495 | 54.0 |
| SUB=0.50 (tier 212) | 532 | 54.2 |
| SUB=0.70 (tier 294) | 558 | 51.4 |
| SUB=auto (fair share, tier 201) | 577 | 51.0 |

- Decode is where three-tier pays: +6 t/s (+13%) over full-layer at SUB 0.35-0.5 — the hot
  experts of ALL layers hit device VRAM instead of 27 layers' CPU compute. The `-mcpa` anti-theft
  masks (streaming + promote-on-miss skip B70-tier slots) are a NECESSARY half: without them the
  pinned arena strips the B70 of exactly that work.
- Prefill wants BIG device tiers (monotone in SUB): mixed jobs put the CPU-tier tail through the
  CPU pool, and the pool is slower than either GPU. Full-layer + aggressive streamed prefill
  still wins prefill by ~8% at equal budget.
- `auto` (deferred fair-share at worker start; also kills the load-time register/forward race
  entirely) lands prefill-best of any three-tier config with dec 51.
- `std::async` overlap of the mixed-job halves: ±0 at tier 0.5, -1.5 at 0.2 (thread handoff + a
  core outside the pinned pool). REMOVED then; re-added later as
  `EXL3_MOE_B70_OVERLAP` (default on for rows≥16) at a measured "0-4%, noise-bound" — kept
  because it is mechanistically sound, not because it scored.
- budget 0.82 + subsets: registration fault storm gone (footprint now bounded per layer); keep
  0.70 as the sane default anyway.

## stream_t interacts strongly with tier size (rounds 7-9)

4.05 / SUB=0.5 prefill: st auto(11) 530 | st6 575 | st16 495 | st24 444. With three tiers the
streamed SET is only CPU-tier experts, so the classic conservative threshold starves the fast
path; lowering it streams more, colder experts and still wins (they'd cost the CPU pool more).
But optima are model/depth-specific: 4.05 st3 + auto-tier COLLAPSED to 452 (deep
oversubscription: streamed bytes outrun the DMA), while 2.68 auto-tier runs 748 prefill / 53.3
decode WITHOUT any stream_t override.
⇒ keep the adaptive auto probe as default; `SUB=auto` is the recommended setting for any model
whose expert bytes exceed 3090+B70; explicit `stream_t` is a per-model trim knob, worth ~8% on
4.05 (st4: 599/53.8 — beats classic on BOTH axes). no-mcpa pays only ~9% prefill at auto-tier on
2.68: the tier wins even without page-locked streaming.

## The guard trade-off is a real fork (rounds 15-17)

2.68bpw, same build, pre/dec:

| regime | pre | dec |
|---|---|---|
| pre-guard (`SWAP_TIER=0` era) | **748** | 53.3 |
| hard guard (tier-only sources) | 484 | 58.7 |
| soft guard (`HOTMULT=4`) | 512 | 59.2 |
| soft guard + st2 | 558 | 59.1 |
| soft guard + st4 | 528 | 58.3 |
| sub0.7 + st4 | 562 | 56.5 |

4.05: pre-guard auto 577/51.0 → guarded default 491-508/57.3-57.9; SUB=0.5+st4 guarded 598/54.7.
Keeping hot experts B70-resident (guard) buys +5..6 decode t/s and costs prefill proportionally to
how much hot mass the sweep would have moved to the 3090; streaming can partly compensate (st2
recovers ~46 on 2.68) but the ~750 prefill number belongs to the steal-from-B70 regime.
HOTMULT 8 vs 4 vs 2: no material prefill difference (outliers are rare); 2 kept decode best.

**RECOMMENDED DEFAULTS AS SHIPPED**: guard on (decode-weighted; this box is decode-poor),
stream_t auto probe, tier auto. Prefill-priority deployments:
`EXL3_MOE_CPU_SWAP_TIER=0` (+ optionally pinned streaming) reverts to the 748-era behavior —
documented knob, not default.

## Sweep results that confirm the defaults (2.05bpw, auto/B70)

- `mcs` (worker-share experts): 256 is the FLOOR on this box — 224/192 die in `_load_autosplit`
  with "Insufficient VRAM in split" (3090 is full); 320 prefill 1480 (-22%); 384 prefill ~1300
  + only 46/48 registrations (B70 VRAM edge). **512 = NOT SUPPORTED** (all experts offloaded =
  zero GPU-resident experts: runs but falls apart, B70 53 / CPU 39 dec, 1036/822 prefill, and
  >VRAM. Boss: don't offload all.) Raising mcs buys nothing on 2.05 (decode flat ~70-72, prefill
  drops monotonically): at 256 offloaded experts the per-token routed work already covers
  topk=10; extra CPU→B70 headroom does not convert. mcs384 decode +1.7% at -27% prefill is not a
  trade to bake in. **KEEP -mcs defaults**; the win scales with offload SHARE only on heavy
  models (4.05@mcs448).
- `EXL3_MOE_STREAM_T` (hot-expert threshold): 8 → 1779, auto (=11 via the live bandwidth probe)
  → **1886**, 16 → 1757, 32 → 1590, off → 1493. The probe nails the peak and is bandwidth-scaled,
  so the x8 link is already priced in. (An earlier independent sweep reached the same conclusion:
  tightening (t=2, +PCIe thrash) and loosening (t=32/64) both lose prefill. No rebalance is needed
  for B70+int8 — the streaming decision is about PCIe vs main GPU, and B70-side speed cancels.)
- `WSLOTS` / `WSLOT_MB` / `STAGE_THREADS` / `BATCH_EXPERTS` / `FUSED_ROWS`: all defaults win
  (1735-1880 range, none above noise).
- `CPU_SWAP=0` (static placement, kills the 3.7 s/run stager): decode identical, prefill -1.5% —
  the staging churn pays for itself.

## Recommended recipe per class

- Model fits both GPUs (2.05 class): pure defaults, and **the streamed tier now takes hot picks
  from B70-resident slots** (`EXL3_MOE_B70_STREAM_HOT=1`, default). The earlier rule - "full tier
  + anti-theft means streaming is blocked on fully registered layers by design (that is correct,
  not a bug)" - is RETRACTED: measured 2026-10-27 it cost 37% prefill vs the CPU worker
  (1197-1202 vs 1871-1903 @4096), because a fully registered layer then re-streams every
  expert once per 8-pick chunk per `cap_rows` job (32 jobs × ~142 chunks per 4096-token layer)
  while the streamed path pays one DMA per expert per chunk. Allowing hot picks to stream keeps
  the arena copy (so decode is untouched, measured 65-68 t/s either way) and masks the streamed
  picks out of the worker job, so nothing is computed twice - see `../NOTES.md` Standing
  decisions and `measurements-ledger.md`.
- Oversubscribed (2.68 / 4.05 / 4.18):
  `EXL3_MOE_B70=1 EXL3_MOE_I8RING=1 EXL3_MOE_B70_SUB=auto EXL3_MOE_PINNED_ARENA=1`,
  and on deep oversubscription (4.05) `EXL3_MOE_B70_SUB=0.50 EXL3_MOE_STREAM_T=4`.