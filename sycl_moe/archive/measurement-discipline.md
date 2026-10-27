# Measurement discipline (how to not fool yourself on this box)

Every "big win" and "big regression" in this project that turned out to be false was a
measurement artifact, not a kernel result. The rules are summarized in `../NOTES.md`; this is
the evidence behind them.

## Clock ramp inverts rankings (Xe2)

Light-duty microbenches rank variants differently depending on how warm the GPU is. A cold
run said flat-bytesum beats the mask chain 2.6x; with 1.5 s burn-in the effect FLIPS (flat
turns out +6%). Same class of error flipped the "-510 folding" adoption and made the
depth-4-prefetch disaster look worse than it was.

→ Burn in (≥1.5 s continuous launch), interleave variants, ≥2 rounds, take min-of-3 (or
min-of-2 for very long runs).

## Profilers inflate; spans are diagnostic only

- `enable_profiling` events INFLATE the 6-kernel pipeline by ~40 µs (NEO timestamp patches).
  A/B decisions must be made UNPROFILED. "span" = command_start→end of the submit event;
  inter-kernel "gap" is host submit latency (K1→K2 gap ~17 µs under profiler, near 0 in
  production where submits pipeline ahead of the GPU).
- Earlier "K6 costs 15 µs at rows=1" was profiler bubble inflation; real ≈7 µs.
- Sustained MEDIAN and SUM-OF-SPANS differ by ~60 µs at rows=1 (222 vs 160): every kernel
  boundary in a per-iter-synced chain costs ~8 µs of dispatch that spans do not show. Never
  "spend" span sums as reachable sustained time at decode shapes.
- VTune gpu-hotspots: must SPAWN the process (`-target-pid` attach captures NO compute-task
  data for Intel GPU), and a background heater process starves the PMU (single client) —
  neither workaround works. Run ≥1000 iterations inside the measured process, then trust
  min-of-3 interleaved.
- `enable_profiling` aside, `EXL3_MOE_PROF` per-kernel spans are for diagnosis only.

## The polling quantum (single biggest measurement error in the log)

`b70_forward` used to poll completion with 20 µs sleeps. That showed medians of 181-188 µs
where `event::wait()` shows 102-113 µs: BOTH experimental and control modes paid +70 µs on
nearly every call (one mode "got lucky"). Fix = wake-first bounded wait (yield-spin <1 ms,
100 µs sleeps <5 ms, 500 µs after), commit `efc7244d`.

→ Every pre-existing C-ABI number recorded before that fix is suspect in one direction or the
other, including the once-famous "fp32 tier 110.7 µs". Production decode jobs were losing
~70 µs/layer to poll slop = ~3.4 ms/token on fully offloaded models. Re-measure anything taken
through the old polling loop before trusting deltas under ~15%.

## Pin the auto policy when A/B-ing tiers

With auto default ON, "control" runs at rows≥2 silently ran the int8 tier and reported ratio
1.000. Tier A/B must set `EXL3_MOE_B70_INT8=0/1` explicitly (and `EXL3_MOE_B70_MCAP`,
`EXL3_MOE_I8SLIM`, `EXL3_MOE_I8RING` when they're in play). The honest sustained table is in
`measurements-ledger.md`.

## Ablation variants must not remove work

The t31 "wins" (V6/V8/V9 at 37 µs vs 62 µs) were an artifact: the band-store and second-mad
blocks were gated by `#if VARIANT == 0||1||4`, so variants 6/8/9 silently SKIPPED HALF THE
WORK (second tile of every pair). → Make removed-work variants by toggling a RUNTIME FLAG
inside always-coded source, or diff the generated asm, before believing an ablation delta.
Compile-time gating is required when the point is to keep loads alive (runtime gates get DCE'd).

## Machine state contaminates model gates

- **VRAM-reclaim lag under-registers the B70.** First run after a heavy GPU job can lose tens
  of GB of apparent VRAM: 4.05bpw mcs448 OOM'd the plugin at 9.5 GB (27 layers → CPU, 36 t/s)
  and the identical rerun minutes later hit the normal 23.91 GB residency (49-51 t/s). 120 s
  idle did NOT prevent it (1380 t/s, layers lost); the run IMMEDIATELY after a free always
  registers fully (48/48).
  → **Standing protocol: run model gates TWICE, score the second run.** Time gaps are not a
  control. Also check `registered=N fallback=M` in the log for each run and discard points
  where it moved (e.g. "decode 33" in a sweep was layers on CPU).
- **Power/thermal throttling.** 29 t/s decode with the SAME 19 registrations as the 50 t/s run;
  a 3-minute idle restored 29.25 → 49.13. → If decode is ~0.6x of record but registration count
  matches, cool down and re-run before believing any regression.
- Other confounders seen: a concurrent 27 GB huggingface download invalidated an otherwise
  clean verification run ("these perf numbers are VOID for the table").
- The 3090 SW power-cap counters: it boosts down under sustained load; interleaving matters.

## Noise floors (what delta is real)

- Decode tok/s: run-to-run band ±3% (single-config repeats 67-73). Deltas ≥1 t/s are
  trustworthy from one run; smaller ones need reps.
- Prefill tok/s: ±3.5% (608 / 568 / 576 for ONE config overnight). Single-digit-percent
  prefill deltas need 3 reps or a cooled interleaved pair.
- Synthetic bench: run noise dominates differences under ~10 µs at decode shapes (nsl 4/6/8
  indistinguishable in a 165-175 µs band).
- Sleeps "between" runs were LONGER than whole evals — scoring rounds matter more than spacing.
- Correctness gates that are safe at 1-decimal resolution: i8trace stages are INTEGER-exact,
  xval rms to 3 sig figs, `test_arena_update` byte identities.

## Know where your reference comes from

- Compare the device against the SPEC (host reference), not sim-vs-device: a shared bug hides.
  The 16-bit masking bug produced plausible-looking garbage that agreed with itself.
- Do NOT recompute a reference from the kernel's OWN dumped states and call it ground truth —
  circular. The t30 lab harness encoded the kernel's window formula and therefore could not
  catch a shared misconception; the independent checker for the coalesced-load experiment had
  to be written from the FORMAT spec (and then flagged the checker, not the kernel: `G` is
  negative, ring-normalize first).
- Always verify layouts on RANDOM data from the FIXED splitmix RNG (`exl3ref::Rng`): xorshift's
  slow start filled early ring words with zeros and silently vacuomed tests.
- "0 bad" deserves suspicion: check the reference itself is non-trivial.
- Suspicious 12x rms in int8 v1 came from DEBUG scaffolding, not the pipeline: the float
  fingerprint dumper matched every unit with `jmu==0 && blk==0` across all NSL slices, and
  slices end at DIFFERENT tile rows (`tk_hi-1`), so `dbg[70..77]` held slice 7's tail row.
  With `tk==0 && unit==0` gating the rows are IDENTICAL. Companion probes that DID work and
  are worth keeping: uniform-A (x8=+1) ⇒ C = Σbs; uniform-B=1 ⇒ C = 4·Σx8; A=q+1 with
  B=1-only-quad0 ⇒ C must be exactly `n_frags*4` (permutation-sensitive).
- Uniform (`CONSTW`) probes HIDE rounding-tie bugs; random signed data exposes them fast
  (the t30 `rnd` mode reproduced in 10 minutes what weeks of pipeline tracing did not).

## Bookkeeping habits

- Never trust piped build rc (`icpx ... | grep`); check the log file exists and echo rc.
  Two "results" in this log came from stale binaries.
- CHECK THE CSV EXISTS BEFORE BELIEVING A NUMBER. One session narrated the results of a round
  that had died on a missing `chmod +x`; the commit carrying those phantom numbers was amended.
- Two `[b70moe] device:` lines per run is NORMAL (the parent process also creates a tiny
  queue-only plugin context via the swizzle gate), not a double-upload.
- Placement persists in `~/.cache/exllamav3/expert_stats/*.json` ("placement from saved
  profile"): profile churn across short runs changes the B70/CPU expert split between runs,
  so two runs of the same command are not comparable across cache states.