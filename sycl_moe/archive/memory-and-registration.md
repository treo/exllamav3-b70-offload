# Device memory: budget, workspace pool, arenas, registration

Ownership model, the incidents that shaped it, and the tools that catch regressions.

## Budget + rollback governance (learned the hard way)

Registration deliberately WARMS the machinery: workspaces + bounce + pinned staging are
pre-sized at `b70_register_layer` so the first real forward allocates nothing (the
`cap_rows`-known startup reservation of the whole pool is separately rejected, below). Warming
too big is its own trap: primes were (rows 64, chunks 1024) early on, then (2048, 1024) — which
inflated the SHARED pool ~1.2 GB under the whole weight set and collapsed later registrations
(wedged staging ring, 100% CPU spin in the parent at warmup). Today they are (512, 512).
**Bump the warm geometry in `b70_register_layer` whenever slot geometry grows**, and never past
what the pool may legally occupy next to the weights.

Why the guards exist (full story in `platform-pitfalls.md` P3): NEO/L0 does not reliably fail
`malloc_device` near capacity; the error shows up later as an async
`UR_RESULT_ERROR_OUT_OF_DEVICE_MEMORY` throw across the plugin's C ABI. In `b70_lib.cpp`:
1. soft budget = fraction of `global_mem_size` (`EXL3_MOE_B70_BUDGET`) checked BEFORE every alloc;
2. every alloc recorded before its copy so any throw rolls back completely;
3. `b70_register_layer` catches everything → -1, layer stays on CPU, sets `dev_full`;
4. `b70_forward` returns int; nonzero → `moe_mul1` pins the layer to CPU for good;
5. `g.poison` latch: after the first forward exception, every later forward returns 3 instantly
   (never touches the dead queue) and completion waits are bounded (15 s deadline).
   Before the latch, one fault = infinite parent spin at warmup.

Budget calibration: per-layer workspace allocation is a trap — the ws pool is PROCESS-WIDE
(layers run one at a time). 2.05bpw @256 experts x 31 split layers ≈ 8 GB B70. Default budget
0.70 (sweep: 0.60 → 17 layers resident, 46.9 t/s; 0.75 → 21-22 layers, 50.4 t/s, stable). The
workspace pool bytes are NOT counted in the registration budget (commit `0d420807`) so a big
prefill's pool growth cannot starve runtime expert installs.

## Per-layer weight ARENA + threaded fill (2026-10-27)

Pattern source: the CUDA side of the house — (1) the handoff segment is ONE pre-sized shm arena
(ctrl + num_slots*slot_size + num_wslots*wslot_size), everything an offset, `cudaHostRegister`
once, host+device views both carved from the base; (2) the streamed-prefill VRAM ring is carved
at LOAD time and reused via events — no allocator in any hot path; (3) the CPU worker's
`thread_local ForwardArena` "grows but never shrinks"; (4) pinned-budget yielding (arena chunks
handed back last-first, so the thing that MUST be pinned gets in).

Our upload path was the anti-pattern: ~2.4k individual `malloc_device` per layer (~115k/process,
all live at once — the forensics run counted 110799), each with its own synchronous
`q->memcpy().wait()`, per-tensor budget accounting, a fragile "uploads.back()" ownership dance
during updates, and a free+repoint+reupload install path in `b70_update_expert` that could leave
a half-installed mix of old and new weights on partial failure.

NEW DESIGN (assumption: the `-mcpa` pinned-arena regime is ALWAYS on, so dynamic installs are
permanent traffic): ONE device arena per layer with a REGULAR per-expert block layout
`[gate|up|down] x [trellis|suh|svh|bias]`, sections 64B-aligned, gate cat omitted for gateless:
- registration = fill host staging (parallel) + ONE H2D memcpy + ONE wait; budget/rollback
  account ONE size (one free on any failure — the `keep[]` walk is gone);
- `b70_update_expert` = refill one block in staging + ONE in-place memcpy. **Data pointers DO
  NOT CHANGE** (`d_tab` rows keep pointing into the block); only bias presence can toggle, so the
  table republish is idempotent. Fill-before-copy makes the install ATOMIC: any host-side failure
  leaves the previous weights byte-intact. No free, no realloc, no budget motion. `n_sub`
  non-members alias block 0 exactly as before (stray chunks read finite weights);
- driver object count collapses 115k → 48 device allocations: less bookkeeping, and crucially
  less VA fragmentation pressure exactly where the ~300 MB workspace pool likes to grow late in a
  near-full run (the old registration-collapse family);
- upload staging = process-static pageable vector (grows, never shrinks). **PAGEABLE ON
  PURPOSE**: the worker's pinned budget is precious and the wire penalty is small — measured
  pinned 14.1 vs pageable 12.5 GB/s for a one-shot 310 MB copy (`t44_upload`).

Phase timings (t44_upload + regbench probe, E=256 2bit geometry, 310 MB/layer):

| phase | old per-tensor | arena | arena+threaded fill |
|---|---|---|---|
| fill (host) | ~in-line, sync | 100 ms | ~20 ms (hw_concurrency/2 threads) |
| upload | ~140 ms (2.4k waits) | 26 ms | 26 ms |
| malloc/rollback | 2.4k frees | 2.5 ms | 2.5 ms |
| warm(512)+init | same | ~5 ms | ~5 ms |
| **TOTAL/layer** | **168 ms** | **133 ms** | **50 ms** (48 layers: -5.7 s load) |

xval rms unchanged 6.043e-07; `bench_b70_py` forward unchanged.

TRAP (caught only because the C-ABI harness checks rms): the fill threads first shipped as
`emplace_back([&]{ for e=t; ... })` — loop variable captured BY REFERENCE: every thread read the
racing final value of `t`, whole expert ranges were never filled, **rms 0.41 with no error
anywhere**. Lambdas taking loop indices capture `[&, i]` BY VALUE and re-verify numerically; a
silent wrong-weights upload is exactly the class of bug this project opened with.

Keep `t44_upload.cpp` as the phase-timing lab and `regbench.py` as the registration-throughput
probe (synthetic E=256 registrations through the C ABI — the only honest way to measure
registration without a 4-minute model load per data point).

## STILL on demand (deliberate): workspace pool, bounce, stage buffers

`cap_rows`-known startup preallocation of the pool remains REJECTED: the naive nc bound
(`rows*topk` under skew) is ~11 GB at `SLOT_ROWS=512` (`tout`/`toutd` alone 3.4 GB each, they
budget nsl=8 unconditionally) parked on a card whose VRAM is the weight-residency currency; and
warm-time pool inflation under the weight set is the documented registration-collapse trap
(below). Grows are rare new-high-water events, and the expensive part is the prefault `memset`,
which preallocation only MOVES, not removes.

## STALE POOL POINTER — the `cap_rows>=512` DEVICE_LOST bug, root-caused and fixed (2026-10-27)

One sentence: `MoeSyclLayer::ensure_ws` only rebound its float-tier workspace members
(`w_tin/w_tout/w_h/w_tind/w_toutd`) when THIS LAYER's `nc` exceeded THIS LAYER's `cap_nc` memo —
but the pool is PROCESS-WIDE, so when another layer grew a slot (free old + alloc new), every
other layer kept a DANGLING member pointer, and their next SMALL job (`nc <= own cap_nc`, e.g.
the first decode after a big prefill) had kernels reading/writing FREED device memory → UA page
fault → DEVICE_LOST/wedge → pin cascade.

Why every observation fit:
- `cap<=128` clean: warm primes the pool at (512,512); rows≤128 jobs never produce nc>512, the
  pool never grows mid-run, nothing dangles.
- `cap=512` + fresh placement + full-tier registration (h4/2.05): 512-row prefill jobs hit
  nc=521 > 512 → first mid-run grow → armed. The WEDGED job was a rows=1 FLOAT decode right after
  successful 512-row int8 jobs (their exits were honest; the decode's float members pointed at the
  freed pre-grow buffers).
- h6 models clean at 512: SUB tiers filter jobs to tier members → per-job nc stayed ≤512 → no
  grow. Warmed profiles likewise (placement converged, smaller nc).
- int8 never faulted as culprit although the ring was prime suspect: its `grow_p` calls are
  UNCONDITIONAL (the old `ensure_ws` comment literally said "sizing must happen on EVERY nc/nsl
  combination" — the float slots lacked exactly that discipline).
- `bench --skew 3.0` could never reproduce: SINGLE layer per process. Staleness requires layer A
  growing the pool and layer B skipping the rebind. 48 layers + big jobs + later small jobs is the
  recipe, not skew per se (skew only matters by pushing nc past 512).

Forensics tool (keep in the toolbox): the xe kernel driver logs UA faults with VA
(`journalctl -k | grep 'Faulted Address'`, `FaultType 0` = GGTT miss, sign-extended 48-bit).
Added `EXL3_MOE_B70_ALLOCLOG=<file>`: every USM alloc/free (A/F site ptr bytes) + every forward
(J line: rows/nc/tier/knobs/all pool bases), wall-clock stamped. One repro run placed the fault
VAs in the FIRST 416 KB of a FREED 0x14000000 pool buffer (`tout`/`toutd`@nc=512, freed when
another layer grew to nc=521), with group stride 0x14000 = `NSL_D*MAXM*H*4/2` = the K6 `toutd`
slice stride, 3 pages per group = a 10 KB row block. Freed buffer + legible stride = stale base,
not bad arithmetic. `attrib_faults.py` pattern: rebuild the LIVE map at fault time from A/F
records AND search the freed history — the bug was invisible in the live map (the fault sits in a
hole between pools).

FIX (`moe_sycl.cpp::ensure_ws`): `grow_p` for slots 0..4 now runs on EVERY forward (when it fits
it is a pure `p = g_ws.buf[slot]` rebind — the int8 slots already worked that way); `cap_nc` kept
only as a stat. PLUS growth is STEPPED (size for nc rounded up to 64 chunks, ~120 MB max
headroom) so the observed nc staircase (341→405→417→521) costs ONE realloc per slot instead of
five — without it every new high-water mark frees and re-prefaults up to ~335 MB.

Verification (same-command A/B): pre-fix binary → 1 wedge + 48 pins mid-warmup; post-fix → 79151
forwards incl. the nc=521 grow + thousands of decodes, ZERO kernel faults (journal), zero forward
errors, 48/48 registered. i8trace battery (rows 2/5 gateless/8/32-2.5bit) all stages OK; xval
6.043e-07 unchanged. Model perf numbers from that run are VOID for the table (27 GB hf download
concurrent + hot B70 — both documented confounders). Status: `cap_rows` default can go back to
512 once a clean cool-box A/B at 512 reproduces the +28..40% prefill on oversubscribed models with
zero pins; keep 128 until then. The instrumentation stays (env-gated, zero cost when unset) — it
is the fastest way to answer "who touched what device memory when" on this stack.

## Precursor entries (kept for the reasoning trail)

- **OPEN BUG (now resolved above): DEVICE_LOST at cap_rows>=512, h4/DPAS tier, skewed worker
  jobs.** Repro: 2.05bpw, EMPTY `expert_stats` dir (fresh identity placement ⇒ hot experts on the
  worker side ⇒ skewed per-expert m in every job), `SLOT_ROWS=512`, auto tier: first 2048-prefill
  pass → every layer logs `forward sycl error: UR_RESULT_ERROR_DEVICE_LOST` once. 2/2
  deterministic; CLEAN: warmed profile, fresh x cap≤128, fresh x h6 models, bench E256/512
  rows512 tk10 uniform (both tiers, single layer). Budget 0.60 (15 GB weights, <75% VRAM) still
  faulted ⇒ NOT pressure. The initial guess ("an address fault in the fat int8 path that only
  skew reaches") was wrong in tier AND in cause: skew only mattered by pushing nc past 512.
- **Fault forensics round 2 + poison latch.** Not memory pressure (17.78 GiB constant at fault,
  budget 0.35 still faults); pipeline-only ingredients remained (48 layers + ring staging +
  multi-thread job arrival). The fix that matters regardless is the `g.poison` latch + bounded
  completion wait, verified on the previously-UNHELLABLE config (fresh+float+512): one fault,
  clean pinning cascade, full eval completes (exit 0). Cap default stayed 128; 512 is safe on the
  h6 float tier and on ANY model with warmed profiles + int8; the forbidden regime at the time was
  h4 shapes + fresh placement + big jobs. `bench_layer` gained `--skew <exp>` (zipf selection;
  `<0` = all-minus-1 degenerate job probe).

## Arena verification matrix (all four Qwen3.8-Flash-Next quants, -mcpa, SLOT_ROWS=512)

| model (K2) | registration | run stability | numerics |
|---|---|---|---|
| 2.05bpw h4 (4) | 48/48, 15.3 GB | 79k jobs incl. nc=521 pool grow: 0 faults, 0 pins | xval 6.04e-7 |
| 2.68bpw h6 (5) | 48/48 | 0 faults / 0 errors | battery green |
| 4.05bpw h6 (8) | 47/48 + 1 graceful budget refusal @0.70 | 0 faults / 0 errors | battery green |
| 4.18bpw h6 (8+10 HYBRID) | 45/48 | 0 faults / 0 errors — FIRST EVER K2=10 GemvFallback traffic at model scale | coherent 854 pre / 42 dec |

Absolute tok/s in those logs are CONTAMINATED (concurrent 27 GB download, back-to-back hot B70);
the gates were stability + correctness, and they pass. 4.18bpw is a HYBRID: `bits=4.16` shows up
per-layer as k2 ∈ {8,10} (the J-line log made this obvious in one grep).

`test_arena_update.py` (the ONLY thing that actually exercises `b70_update_expert` — in all four
gates the tier guard meant no install ever targeted a registered layer, `UPD ok = 0`) must run
after ANY upload/ABI change; three byte-exact substitution identities: idempotent reinstall,
slot←src mapping (install e7's bytes into slot 3: route-to-3 must equal baseline route-to-7),
fan-out overwrite.

Foreign oddity, monitoring only: one bcs (blitter-engine) UA fault at 12:00:37, same VA in two
ASIDs, AFTER the 2.05 gate process had exited and outside any forward window; no compute-engine
(ccs) faults all session. Not ours by every indicator; revisit if a future run pins with ccs
faults at teardown.