# PLAN: persistent B70 worker (kill the per-layer command round trip)

Status: **CLOSED by measurement on 2026-10-28 - see §11 for the numbers and §12 for what would
reopen it.** Gate G0 failed on both of its criteria: a resident thin-gemv grid needs ~256 of the
machine's ~448-512 team slots to reach 195 GB/s (§11.2), and at the geometry the shipped plugin
actually launches the engine measured **75.6-97.1 µs/job against the split path's 28.9 µs/job** — it
had to beat 9 µs (§11.3a). Gate G1 also failed: the pinned-USM doorbell — the whole premise — is
dependable for only a few pings; the sole trigger that completed every ping was a 4-byte H2D **command**
per job, i.e. the cost the design exists to remove. Along the way §3.1's premise that a decode job
needs "~20-40 WGs" was found to be wrong by 5× (it is 200). Kept above as the reasoning record,
because §1-§4 are still the correct statement of the prize and of what was already ruled out.

Original status: *not started.* Run **gate G0 (§3.0) first** - it is a half-day of lab work that can
kill the whole idea cheaply, and a measured predecessor already lost this fight once (megakernel:
466 us vs 183 at rows=1, starvation not barriers). Only if G0 passes does the §2 trigger experiment
(~45 min) matter. No production code until §5's gates are met. Owner notes: SESSION_20261028.md
2026-10-29 (08:20-13:05); budget data in `archive/measurements-ledger.md` §"Decode forward budget,
IN THE MODEL" and `archive/decode-command-latency.md` §2026-10-29 + §"Megakernel experiment".
Complements `PLAN_L0.md` (see §8 for why that one stays closed).

---

## 1. The prize, and why it is the last big one

Decode budget measured **in the model** (2.05bpw, 29.4k rows=1 jobs, ALLOCLOG phase fields):

```
prep 0.8 | h2d 3.2 | sub 27.2 | d2h 2.9 | wait 28.6 | cp 0.4   = 66.1 us p50 (mean 72.7, p90 88.7)
t(nc) = 57.6 us FIXED + 6.3 us per expert   (marginal = 195 GB/s of packed bytes; lab ceiling 254)
48 layers -> 3.2 ms of a 14.7 ms token = 22% of decode, 87% of it FIXED
EXL3_MOE_B70 on/off: 68.1 vs 64.2 dec_avg (+6.1%) -> the leg is worth something
```

The marginal work is already at ~the machine's ceiling, so nothing remains there. What remains is the
fixed 57.6 µs per layer-step, of which **27.2 µs is parent-thread time enqueueing 5 actions** and
~28.6 µs is the device chain plus completion signalling.

Everything cheap that could attack it has been measured and is closed:

| idea | verdict | evidence |
|---|---|---|
| fewer API layers (`oneapiext::nd_launch`, no handler, raw args) | **no** 2.66 vs 2.63 µs | `lab_submit_busy.cpp` regimes K–O |
| runtime knobs (EG cleanup, `SYCL_DISABLE_*`) | **no** | same stage profile |
| command graphs (wall axis) | **no** ~1.2 µs/command | `lab_graph4.cpp` |
| command graphs (host axis) | **no** replay 12.24 vs chain 9.95 µs | `lab_graph4.cpp` host arm |
| kernel fusion (`CoopGuK`) | **wash** | arrival chain costs what the dropped command saved |
| faster gemv | **invisible** | `MOE_GEMV_NC=16` halved gu (51.5→31.7 µs span), decode −1.6% |
| native L0 command lists | doubtful by inheritance | cost is the L0 commit, not SYCL bookkeeping |

Only one design removes the round trip instead of trimming it: **one resident kernel per layer-handle
that waits for work instead of being launched per job.**

Terminology trap, checked against the installed headers: `aspect::ext_oneapi_device_wait` is NOT a
device-thread parking primitive - it backs the HOST-side `sycl::device::ext_oneapi_wait()`
(`device.hpp:392`, "wait until the device is idle"; see `test-e2e/DeviceWait/basic.cpp`, which is a
host-side multi-queue test). SYCL gives a device thread no way to block on a host store, so a resident
engine necessarily *polls*. The only no-spin parks available are command-level
(`ext_oneapi_wait_external_semaphore`, or a native `zeCommandListAppendMemoryWait` on the doorbell
address via `ext_codeplay_enqueue_native_command`) and those may cost an enqueue per job - i.e. the
thing we are trying to avoid. Aspects probed on this device: `ext_oneapi_graph` (with node updates)
YES, `ext_oneapi_limited_graph` YES, `ext_oneapi_external_semaphore_import` YES,
`ext_oneapi_device_wait` YES (= host-side wait), images no; geometry 256 CUs, 128 KB SLM,
max_work_group_size 1024, 64 sub-groups/WG.

Ceiling: the whole 57.6 µs → ~2.8 ms/token → **~19% decode** at 2.05bpw, and much more on 4.05bpw
where the B70 path dominates. Realistic capture 50-70% of that.

---

## 2. Step 2 (gate G1): is the stall an idle-state artifact?

`lab_doorbell.cpp` measured the good part: host store → device observe → work → device store → host
observe = **p50 2.4-3.1 µs at 1 WG**, ~8-11 µs at 16-64 WGs, ~3 µs with two-level fan-in at 8-16 WGs.
It also measured the blocker: **20-75% of pings exceed 20 ms**, bimodal, and the lab cannot currently
tell which side stalls.

Two clues point at GPU idle/clock states rather than coherence:
* a resident spinner makes a *second* queue's 16 MB fill **faster** (17.5 µs vs 34.0 us unspun);
* the card draws ~80 W of 275 W during decode and falls as the run proceeds (user-observed), and with
  nothing resident xpu-smi reports 0% util.

**Revised ranking after the evidence check (§10): driver preemption/timeslicing is the leading
hypothesis, not clock ramp.** This kernel compiles `CONFIG_DRM_I915_TIMESLICE_DURATION=1` (ms) with
`PREEMPT_TIMEOUT=640` / `PREEMPT_TIMEOUT_COMPUTE=7500` ms, and `CONFIG_DRM_XE_JOB_TIMEOUT_MIN/MAX = 1 /
10000` ms. A *spinning* kernel never reaches an arbitration point, so it is preempted by escalation
rather than cooperatively - which is exactly the shape of "sometimes 2-3 us, sometimes >20 ms". The lab
also ran two contexts (q and q2) against each other. Discriminators, cheapest first: (i) run with ONE
queue (drop q2 entirely, including the interference probe); (ii) `taskset -c` + `chrt` the pinging
thread to rule out host scheduling; (iii) the device-side poll counter (§2a), which separates
"device observed late" from "host observed late"; (iv) count preemptions from
`/sys/class/drm/card*/device/gt*/...` or `perf` if available.

Three mechanism rules already established — do not re-derive them, build on them:
1. polling SYSMEM with an acquire **load** goes deaf after a few pings (legal lowering to a cached
   load): the doorbell must be an atomic **RMW** (`rmw0<system>`);
2. N WGs RMW-polling one **device** line serializes catastrophically (>20 ms/job from 8 WGs up):
   fan-out must use per-WG slots or a device-side wait, never one hot line;
3. completion must be **level-triggered** (`done >= want`, signed distance): the device coalesces
   doorbells, so an equality test waits forever for a skipped id.

### 2a. Experiment: locate the stall (add to `lab_doorbell.cpp`, ~1 h)

The single most diagnostic number we lack: **did the device see the doorbell late, or did its
completion reach the host late?** Get it without a profiler by having the device publish its own poll
counter at the moment it observes the doorbell. Each poll iteration costs ~fixed time, so the counter
difference converts to device-side elapsed time, and it is stamped into sysmem in the same store as
`done`:

```
struct Mailbox: +unsigned polls_at_observe, +unsigned polls_total, +unsigned obs_seq
```
Host side: read the counter pair, divide by the lab's measured poll rate (report it once per mode).
Reporting `host_latency` split into `->device observe` and `->host observe` turns "20 ms stall" into a
diagnosis in one run.

Then run the arms, each 300 pings, at 1 WG and 16 WGs:

| arm | what | decides |
|---|---|---|
| S0 | no keepalive | baseline stall rate (should reproduce 20-75%) |
| S1 | keepalive `single_task` on q2 every 2 ms (**mode 7, already coded**) | does ordinary traffic cure it? |
| S2 | keepalive every 10 ms (**mode 8, coded**) | how little is enough → the amortised cost |
| S3 | no-spin park, command-level: `ext_oneapi_wait_external_semaphore`, or a native `zeCommandListAppendMemoryWait` on the doorbell address via `ext_codeplay_enqueue_native_command` | can the engine avoid burning an EU on polling - and does the park itself cost an enqueue per job (which would defeat the design)? |
| S4 | spinner + a *long-running* filler kernel on q2 (not a trickle) | separates "clocks up" from "traffic present" |
| S5 | like S0 but the device also writes sysmem on every poll (heartbeats) | does a device->sysmem WRITE stream keep the path warm? Writes never stalled this session; reads did |
| S6 | completion detection only (no engine): current `get_info(command_execution_status)` yield-poll vs `event.wait()` vs host-side `device.ext_oneapi_wait()` | the wait leg is 28.6 us of the 66; a cheaper host-side wait is a small independent win and needs no resident kernel at all |

Sample power/util during every arm (`xpu-smi stats -d 0`, or `mon.py`) and put the W numbers in the
table: the correlation between "stall rate" and "card in a low power state" is the finding, not a
footnote.

**Gate (must all hold to continue):**
* stall rate (>20 ms) < 1% **and** p99 < 200 µs in some arm;
* that arm's keepalive cost, amortised, is < 2 µs per job (e.g. a 2.6 µs command every 2 ms while
  decode issues ~66 jobs/2 ms ≈ 30 µs of parent work → charge it honestly);
* the split is attributable (≤ 50% of the stall remains on the host-observe side).

**If no arm passes:** record it here, mark lever 1b CLOSED, and stop. Do not integrate a trigger that
occasionally takes tens of milliseconds: the plugin's completion poll is yield-spin with a 15 s
deadline, so a 20 ms stall is survivable but a tail of them destroys decode latency, and we would be
trading a stable 57.6 µs for a lottery. Also re-test the assumption that the child's wall is on the
critical path (§7) before concluding the *prize* is gone.

---

## 3. Step 3: prototype the engine over the REAL chain (lab only, ~half a day)

Only after G0 **and** G1 pass. **Read §3.0 first: this design collides with a measured failure, and the
plan is only valid if §3.0's gate passes.**

### 3.0 The megakernel objection, and the one gate that answers it

A resident kernel cannot launch other kernels (no device-side launch on this stack; `PLAN_L0`'s probe
found no IPA/mutable-calls either), so "resident engine" == "megakernel". We have already built and
buried one: `archive/decode-command-latency.md` §"Megakernel experiment" - six pipeline stages as
phases of one persistent kernel with grid-wide arrival barriers, real kernel bodies behind a
virtualized-coord seam. It worked, and it was **2.5-6x SLOWER than the split pipeline at every shape,
including rows=1 decode: 466 us vs 183 us**. The recorded verdict: barrier mechanics cost what t38
predicted (~2-5 us/barrier at 32-128 WGs), but *phasing serialises the device* - a megakernel grid
must be <= co-residency, DPAS WGs are register-fat (GRID=96 never completed), and at safe grids (16-32)
"the per-command overhead it removed was never the dominant cost - starvation is".

Why the decode case might still be different, and how to know cheaply:

* **Do not phrase the blocker as "no grid-sync primitive exists"** - Level Zero specifies one:
  `zeCommandListAppendLaunchCooperativeKernel` plus `zeKernelSuggestMaxCooperativeGroupCount` are both
  in the installed header (`/usr/include/level_zero/ze_api.h:9619`, `:9016`), and `isCooperative` is a
  kernel-descriptor flag (`:8351`). The open question is whether Intel's compute runtime (NEO)
  implements it for Xe2, which is a ~20-line probe through `sycl::aspect`/interop - and
  `zeKernelSuggestMaxCooperativeGroupCount` would answer G0's residency bound **authoritatively from
  the driver** instead of by measurement. Run that probe as G0a, before the bandwidth sweep.
  What *is* confirmed absent: any device-side launch entry point in the L0 header (no CDP equivalent),
  so a resident engine must contain the code - the megakernel identification stands.
* The buried attempt ran the **int8/DPAS** tier, whose WGs are register-fat. Decode at rows=1 uses the
  **float** tier: `GemvK` WGs are thin (no DPAS fragments, ~10-20 live regs), and t38's *thin*-kernel
  co-residency ceiling was 160-280 WGs versus 16-32 for the fat ones.
* A decode job needs only ~20-40 WGs (gu = nc x nm x I/128 ~= 20 at nc=2; down ~= 40). The failed
  attempt needed 1240 tile-units to fill the machine, so phase-lockstep starved it. At decode the
  required grid and the co-residency ceiling are the same order of magnitude - which is precisely the
  regime where the trade can flip.
* The interior must therefore **not** be bulk-synchronous. The dependency graph is block-diagonal per
  expert: for one (expert, token), gate/up -> act -> down is self-contained apart from needing that
  expert's whole intermediate `h` (640 floats). So a *cluster* of a few WGs owns one expert's chain and
  syncs only within the cluster (per-expert arrival counters - the existing `ctrG`/`ctr1`/`ctr2`
  machinery already keys on (chunk, block), so it is per-expert-shaped already). Different clusters are
  then in different phases concurrently: no grid-wide barrier, no lockstep, no global phase.
  (One WG per expert would need no sync at all, but it fails the arithmetic: a single WG cannot pull
  1.19 MiB at anything like 195 GB/s.)

**Gate G0 (do this before any trigger work - it is cheaper and more fatal): measure the sustained
packed-read bandwidth of N resident thin gemv workgroups**, N in {16, 32, 64, 96, 128}, using the
float `GemvK` shape (or `lab_gemv_shape.cpp`, which already sweeps columns-per-WG at fixed work).
Two variants: (i) WGs doing work only, (ii) WGs resident-and-polling between jobs (the real engine
shape, includes the doorbell poll loop). Requirements to continue:

* co-residency: the grid must be *permanently* resident, i.e. N <= what the float tier can hold with
  the plugin's own scratch/SLM reservations (the mega's GRID=96 hang is the failure to avoid - test
  residency explicitly, not just throughput);
* sustained aggregate >= **195 GB/s of packed bytes** (today's measured marginal rate) at the chosen
  N, else the engine is slower per expert than the split path and the ~27 us of submit it saves is
  already spent;
* and it must beat 84 us/nc=5 * net: `engine_wall < split_wall - 20 us` at the same nc.

**If G0 fails, close lever 1b permanently** and record it against the post-mortem's restart condition
(b) - "an actual grid-sync primitive (cooperative launch / CLC) allowing full-size disjoint grids per
phase". Do not re-open this without that primitive, and do not spend a day on trigger mechanics (§2)
for an engine that cannot feed itself.

### 3.1 Prototype requirements

Requirements:

* Reuse the `lab_graph4.cpp` emitter pattern: **one code path, two back ends** (submit vs engine), so
  the engine runs the same kernels `moe_sycl::forward` runs — K1 prep, K2 gemv_gu, K34 act+prep_d,
  K56 coop-down — not toy stand-ins. Import or #include the real launch bodies if practical; the
  three-sided-geometry rule says the device, `moe_host_ref.hpp` and the harness must agree, so
  prototype against `bench_layer`'s CPU reference, not against itself.
* Job intake = the existing pinned **job blob** (chunk descriptors, token map, counters zone, scales).
  Its layout stays in `moe_sycl.hpp`/`moe_layout.hpp` — single source. Engine reads it after observing
  the doorbell; nothing about the blob format changes.
* Internal sequencing reuses what `CoopGuK`/`CoopDownK` already prove works on this hardware:
  device-scope arrival counters (`ctrG`, `ctr1`, `ctr2`) and the blob-zeroed counter zone. That is the
  whole reason this design is plausible: device-side stage sequencing is not new, only its lifetime is.
* Fan-out obeys rule 2: per-WG slots (or a small tree), never one shared line. Target from §2
  measurements: ≤ 5 µs of trigger+fanned-in completion at 16-64 WGs (decode jobs need ~20-40 WGs:
  gu = nc·nm·(I/ncwg)·nsl ≈ 20 WGs at the shipped geometry; down ≈ 40).
* Completion: engine publishes `done` to sysmem (device→sysmem stores worked in every run this
  session) and the plugin's existing bounded poll observes it.

Measures (per `nc ∈ {1,2,5,10}`, 300+ jobs, interleaved against the submit path, min-of-3):

| metric | submit path today | target to justify step 3 |
|---|---|---|
| child wall p50 | 66 µs (nc 2) / 84 µs (nc 5, parity) | ≤ 45 µs / ≤ 60 µs |
| parent host time per job (`sub`) | 27.2 µs | ≤ 8 µs |
| p99 | ~89 µs | < 200 µs, no >20 ms events |
| other-queue interference | n/a | 16 MB fill within 10% of 34 µs baseline |
| results | bit-identical | bit-identical (same kernels, same args, same order) |

Correctness gate: `bench_layer` accuracy line unchanged to the last digit (float rows=1
max_rel 1.882e-06 / rms_rel 1.070e-06), `--load ../xval_s` rms_rel **6.530e-07**, `--i8trace` B..G OK.
Anything less than bit-identical means the engine changed summation order — stop and fix, because the
whole feature is supposed to be a plumbing change.

---

## 4. Step 4: production integration (only if step 3 pays)

Shape of the change, sized honestly at 1-2 days plus a full gate battery:

* **ABI unchanged.** `b70_forward(handle, x, sel, w, out, rows, topk)` stays synchronous — the child
  process is the only caller and its pipeline already assumes sync + poison semantics. Internally:
  if the engine is armed for this (layer, geometry class), fill the pinned blob + ring the doorbell +
  poll `done`; else run today's submit path. One flag, one fallback, no new ABI.
* **Engine lifecycle.** Start lazily on the first qualifying job, stop on `b70_free_layer`/teardown
  and on poison. Hard rules: (i) the stop path must be bounded (the lab's `wait_bounded` pattern —
  never `q.wait()` on a kernel that may not see the sentinel); (ii) the engine must exit on its own
  poll bound, because an abandoned resident kernel's only way out IS that bound: at ~2 us per sysmem
  poll, the first cut's `SPIN_MAX = 400e6` meant up to ~13 minutes of an occupied EU after the host
  died, so keep `SPIN_MAX_SYS` in the 1-3 s range and also carry an explicit QUIT sentinel on the
  doorbell; (iii) the 15 s completion timeout and poison flag semantics stay.
* **Scope: decode only, at first.** Arm only for `rows == 1` (and maybe rows ≤ 2), and only when the
  GPU is not mid-prefill. Prefill jobs are 1.9-2.0 k tok/s, dominated by int8/DPAS throughput where a
  resident engine adds risk and no mechanism gain. Define the switchover explicitly (rows, nc, and a
  "prefill in flight" check) and make the fallback path the *current* code, untouched.
* **Resource contract.** A resident grid of G WGs is permanently occupied: measure prefill t/s and
  B70 power/thermals with the engine idle-but-resident, and decide (a) keep the engine small and let
  jobs use more WGs by borrowing the same grid in waves, or (b) tear it down when rows > 1 and rebuild
  lazily (rebuild cost = one submit, ~5 µs, plus engine start — measure it).
* **Locking.** `g.exec_mu` today serialises forwards, which conveniently serialises doorbell/completion
  ids. Keep that invariant in step 3; multi-threaded issue is a separate, later question.
* **Id/protocol invariants** (each earned a stall this session): monotone job ids; level-triggered
  completion; RMW on the sysmem doorbell; per-WG fan-out slots; engine must never write sysmem outside
  its own padded cache lines; every mapped flag initialised on both sides before the doorbell rings.
* Docs: README instrument/knob sections, NOTES lever 1b → status, env_vars.md if a knob ships
  (propose `EXL3_MOE_B70_ENGINE=0|1|auto`, default off until it wins an A/B).

---

## 5. Decision gates, restated — VERDICTS 2026-10-28 (see §11)

0. **gate G0 (§3.0): a permanently-resident grid of thin float-gemv WGs must sustain >= 195 GB/s of
   packed bytes at a grid the device actually keeps resident, and beat the split path's wall by > 20 us
   at the same nc** -> **FAIL, both halves** (§11.2: 195 GB/s needs >= 256 of ~448-512 resident teams,
   and 576 collapses 25x; §11.3: engine 84-92 us/job vs split 56.0 us/job, gate was < 36 us).
   -> **lever 1b CLOSED.**
1. gate G1 (§2): a keepalive/wait strategy with stall rate < 1%, p99 < 200 us, cost < 2 us/job ->
   **FAIL** (§11.4): every host-store doorbell flavour loses 68-100% of pings to >5 ms stalls with a
   resident poller and no keepalive cures it; the only 0-stall trigger is a per-job H2D command.
   The §2a poll counter located the stall on the host->device leg (the engine polled the line ~1.2e7
   times during one stalled ping without seeing the store).
2. §3 gate: bit-identical results **and** child wall p50 ≤ 45 µs at nc≈2 **and** parent host ≤ 8 µs
   → **not reached** (gates 0 and 1 failed; no engine prototype was built over the real chain).
3. §4 gate: interleaved model A/B, 3 rounds, both placement layouts, decode ≥ +3% (noise floor ±3%)
   with prefill within ±1% → ship default-on; +1-3% → ship default-off with docs; ≤ +1% → close.
   → **not reached.**

Side results that ARE kept (§11.5): ULLS/direct submission is active and worth ~78 us per 4-command
chain (A/B with `NEOReadDebugKeys=1 EnableDirectSubmission=0/1`); and there is a device-idle cliff
(56 us warm -> 247 us after 20 ms idle -> 410 us after 100 ms) that decode's ~300 us cadence does not
touch but every post-pause first call does.

## 6. Risks and the cheapest test for each

| risk | cheapest test |
|---|---|
| stalls are inherent (driver preemption/timeslice), not idle states | S1/S4: if only *heavy continuous* traffic cures them, cure costs as much as submits → dead |
| cure requires so much keepalive that it re-adds the submit cost it saved | report µs-of-keepalive per job in the §2 table |
| resident grid starves prefill (256 CUs is a lot, but DPAS prefill wants them all) | §4 resource contract measurement; run `pb.py -reps 3` with engine resident |
| a wedged engine locks the card / poisons the process | teardown bound + `wait_bounded` + poison path in the §3 lab, before any integration |
| numerics drift because the engine reorders accumulation | bit-identical gate in §3 (this is a hard gate, not a soft one) |
| multi-queue dependency bugs (plugin chains explicit `depends_on`; implicit in-order ordering is untrusted here) | engine must own its dependencies entirely device-side; only the doorbell/`done` cross the boundary |
| we optimise a cost that is mostly hidden anyway | §7 - re-measure visibility before and after, in both layouts |
| **the engine starves, as the megakernel did (466 vs 183 us at rows=1)** | **gate G0 (§3.0): sustained GB/s vs resident thin-WG count, measured before any trigger work** |

## 7. Measurement discipline specific to this plan

* **Regime first.** Under `EXL3_MOE_CPU_SPLIT_LAYOUT=tail` the child's wall is largely slack behind the
  parent's per-layer GPU work — proven by `MOE_GEMV_NC=16` (2× gu win, no e2e movement, even under
  parity at ~neutral). So judge every step in the **parity** regime (child on the critical path: 100%
  of layer-steps issue a B70 job, 4.9 picks/job, ~115 W) *and* report the tail numbers for the shipped
  config. Never conclude "no prize" from a tail-regime null.
* NOTES rules apply: burn-in ≥1.5 s, interleave arms, min-of-N, never A/B under a profiler
  (`--v` inflates ~40 µs/6-kernel pipeline), pin the tier (`EXL3_MOE_B70_INT8=0`), converged placement
  only, and **rule 11** — every instrument prints its denominator and at least one unconditional line
  per window, because a silent HostProf once cost us a wrong conclusion about graphs.
* Noise floors: decode ±3%, prefill ±3.5%. A gate below that is not a result; use `perfab.sh`
  (official metric) for §5/§4 gates and `lab_*`/`bench_layer` only for mechanism numbers.
* Do not trust `bench_layer`'s absolute decode wall: it spends ~21 µs/submit because its queue drains
  between forwards (`--bare` floor 33.5 µs) — ~2.4× the model's 66 µs.

## 8. Explicitly out of scope (do not reopen without new evidence)

Command graphs (both axes), handler-free enqueue / `raw_kernel_arg`, runtime-env submission knobs,
`CoopGuK` fusion as a latency fix, decode gemv micro-optimisation and any weight-representation repack
(states are 16-bit advancing K2/2 bits → 32/K2 = 8× duplication at K2=4), pre-decoded int8 tier
(4× bytes for nothing byte-alignment already gives at equal density), and `PLAN_L0.md` as written —
its premise ("avoid the runtime's per-action cost") is now measured to be worth ≤ 0.5 µs/action over
the handler-free path, i.e. the commit itself is the cost.

## 9. First session, concretely — DONE 2026-10-28, results in §11, closure in §12

1. `git pull`; read NOTES levers 1a/1b/1c, this file, **and the megakernel post-mortem in
   `archive/decode-command-latency.md`**; rebuild `lab_doorbell` (`icpx -fsycl -O2 -w
   lab_doorbell.cpp -o lab_doorbell`, ~3 s; note `env.sh` exits nonzero - chain with `;` not `&&`).
2. **Run gate G0 (§3.0) first**: sustained bandwidth vs resident thin-WG count. Half a day at most,
   and it can end the whole idea cheaply, which is the point of putting it first.
3. If G0 passes, implement the poll-counter instrumentation (§2a) + arms S3/S5/S6, then run S0-S6 with
   `LAB_MODES`/`LAB_NPING` and xpu-smi sampling. Budget: one focused afternoon, most of it reading two
   tables.
4. Write the result into this file (G0 numbers, §2 table + gate verdict) **before** touching anything
   else, then either proceed to §3.1 or record the closure.

---

## 10. External evidence check (2026-10-29) - what held, what didn't

Claims from §1-§4 put against vendor docs, the SYCL spec, the installed headers, and the local kernel
config. Two were refuted, one design assumption is now a hard constraint, and the stall hypothesis
changed.

| claim in this plan | verdict | evidence |
|---|---|---|
| a resident kernel cannot launch other kernels (no CDP equivalent) | **supported** | no device-side launch entry point anywhere in `/usr/include/level_zero/ze_api.h`; no SYCL API for it |
| `ext_oneapi_device_wait` lets a *device* thread block on a host store | **REFUTED** | it is `sycl::device::ext_oneapi_wait()` (`device.hpp:392`), a host-side wait-for-idle; `test-e2e/DeviceWait/basic.cpp` is a host-side multi-queue test. Corrected in NOTES lever 1b and the archive |
| "restart condition (b): we need an actual grid-sync primitive" | **partly REFUTED** | L0 *specifies* cooperative launch (`zeCommandListAppendLaunchCooperativeKernel`, header:9619) and exposes `zeKernelSuggestMaxCooperativeGroupCount` (header:9016). NEO's Xe2 implementation is untested -> new gate **G0a** (20-line probe), which also answers the residency bound from the driver |
| host<->device atomics on pinned USM are a sound doorbell | **REFUTED as a guarantee** | SYCL §4.15.5 grants host/device atomic and fence interoperability *only* when the device advertises `usm_atomic_host_allocations` or `usm_atomic_shared_allocations` (Khronos SYCL_Reference, "Interaction with host code"). **This B70 advertises neither** (probed: both `no`; `usm_system_allocations`/`usm_host`/`usm_shared` are YES). So the measured behaviour - a few pings at 2-3 us then permanent deafness on an acquire load, longer life under RMW - is what using an unspecified operation looks like. Consequence: the *engine trigger must not be designed on top of it*. Either find a contractual mechanism (L0 event/semaphore, `usm::alloc::system` + verified support, or a documented NEO guarantee obtained from Intel), or treat the whole approach as unsupported-hardware territory and close it |
| ~20 ms stalls are GPU idle/clock-ramp | **WEAKENED, demoted to #2** | this kernel: `CONFIG_DRM_I915_TIMESLICE_DURATION=1` ms, `PREEMPT_TIMEOUT=640` ms, `PREEMPT_TIMEOUT_COMPUTE=7500` ms, `DRM_I915_REQUEST_TIMEOUT=20000` ms, `DRM_XE_JOB_TIMEOUT_MIN/MAX=1/10000` ms. A spinner that never hits an arbitration point gets preempted by escalation, and the lab ran two contexts against each other -> preemption is a better fit for a 2-3 us / >20 ms bimodal distribution than microsecond-scale power-state exits. Discriminators in §2 |
| megakernels are inherently starved (i.e. the direction is dead because ours lost) | **REFUTED as a general statement** | MPK / Mirage Persistent Kernel (arXiv:2512.22219) compiles LLM inference into ONE persistent kernel with an *SM-level task graph*, "decentralized scheduling across SMs", cross-operator software pipelining, and reports up to **1.7x lower end-to-end latency** than kernel-per-operator serving. PERKS (arXiv:2204.02064) and Concordia (arXiv:2606.23521, host-side submission <100 ns on a coherent platform) are the same idea in other settings. Our own loss had the specific, named cause those systems avoid: **grid-wide phases + a grid capped by co-residency**, not persistence per se. Reinforces §3.0's per-expert-cluster interior |
| GPU spec numbers used as denominators | **CONFIRMED (with one nuance)** | ARK, Intel Arc Pro B70: 32 GB **GDDR6**, 256-bit, **608 GB/s**, 32 Xe-cores / 256 XMX / 256 vector engines, 22.94 TFLOPS FP32, **TBP 230 W (LP 160-290)** - so "275 W" is a programmable limit, not the nominal envelope. Measured here: H2D 13.6-14.4 GB/s, D2H 13.8-14.3 GB/s (so the prefill analysis' ~12.8 GB/s link denominator was the right order, and "the link is not the ceiling" stands), D2D 597-860 GB/s. Nuance: our D2D exceeds ARK's 608 GB/s, so treat 608 as conservative and re-measure D2D before quoting a utilization percentage |

### New hard requirements this adds to the design

1. **Contractual trigger, or nothing.** No USM-host atomic interoperability guarantee on this device
   (§10 row 5). Step 1 must therefore end with one of: (a) a mechanism with a documented guarantee,
   (b) an explicit written/observed NEO guarantee, or (c) closure of lever 1b. A design that "works on
   our box" is not enough here, because the failure mode we already saw is silent and intermittent.
2. **The engine cannot be immortal.** With i915 request timeout 20 s / xe job timeout up to 10 s and a
   2.5 s heartbeat, a kernel that never retires fights the driver's watchdog design. Plan for periodic
   voluntary retirement + relaunch (a retire interval of T seconds costs one submit per T/N jobs), and
   re-do the prize arithmetic with that amortisation included: if the engine must relaunch every ~5 s
   and decode issues ~66 layer-jobs/s, that is one submit per ~330 jobs - negligible; if the driver
   forces preemption every few hundred ms, it is not.
3. **Single-queue measurement discipline in the lab.** The two-context setup is now a suspect for the
   stalls, so S0 must be re-run one-queue-only before any conclusion is drawn from stall rates.

Sources: Khronos SYCL_Reference "Interaction with host code" (= SYCL 2020 §4.15.5); Level Zero
`ze_api.h` as installed; Intel oneAPI HPC-cluster installation guide, "Allow Long-running GPU Kernels"
(disable hangcheck, `i915.request_timeout_ms=200000`, zero `preempt_timeout_ms`, zero
`heartbeat_interval_ms` - i.e. Intel's own documented answer to long-running kernels is to reconfigure
the driver, which is a deployment cost worth naming); Intel ARK product page for Arc Pro B70;
arXiv:2512.22219 (MPK), arXiv:2204.02064 (PERKS), arXiv:2606.23521 (Concordia); local
`/boot/config-$(uname -r)` DRM_{I915,XE} timeout values; local aspect probe and PCIe bandwidth probe.
---

## 11. Gate results (2026-10-28) — G0 FAIL, G1 FAIL, lever 1b closed

Lab: **`lab_resident_bw.cpp`** (`icpx -fsycl -O2 -ffp-contract=off -w lab_resident_bw.cpp -o
lab_resident_bw`; arms `A` residency+bandwidth, `C` split-path control, `B` engine+doorbell;
`LAB_SK=2` reproduces production's decode split-K geometry, `LAB_PER_PING`, `LAB_IDLE_US`,
`LAB_KEEPALIVE_US`, `LAB_ENG_TRIG/FOUT/FAN`). Capability probe: **`l0_coop_probe.cpp`** (`-lze_loader`).
Min-of-3 windows after burn-in unless a row says otherwise (the §11.4 trigger matrix is a single
1-window pass of 60 pings per cell, and its reruns vary ~10%); every arm prints its own `n`, so a
truncated run cannot masquerade as a full one. No profiler was attached to any number here.

### 11.1 G0a — cooperative launch: capability YES, and it would not have saved anything

`l0_coop_probe`: loader exports both entry points; the driver advertises **no** cooperative
*extension* among its 63, but command-queue **group 0 flags = COMPUTE COPY COOPERATIVE_KERNELS**
(numQueues 1; group 1 = COPY). So §10's correction stands and NEO's grid-barrier path is at least
addressable — but the functional probe (own SPIR-V module on the queue's own immediate list, per the
`t36/t37` recipe in `archive/decode-command-latency.md`, which still carries the unresolved SLM
binding blocker) was **not** run, because the engine design does not need a grid-wide barrier:
§3.0's interior is per-expert clusters. What G0 actually turned on was a different failure.

### 11.2 G0 criterion "sustained >= 195 GB/s from a permanently resident grid" — FAIL at any sane grid

Sustained packed-read rate of N co-resident thin float-gemv teams (128 threads = one 128-column
block, `GemvK<4,false>` inner loop, 2.458 MB = one nc=2 decode job per "job"):

| teams | 16 | 32 | 64 | 96 | 128 | 160 | 192 | **256** | 320 | 448 | 576 | 704 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| GB/s | 20.7 | 41.1 | 79.9 | 100.8 | 144.1 | 157.7 | 177.6 | **207.3** | 214.8 | 215.1 | 8.5 | 4.4 |
| us/job | 118 | 59.8 | 30.8 | 24.4 | 17.1 | 15.6 | 13.8 | 11.9 | 11.4 | 11.4 | 288 | 558 |
| residency | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | **✓ (ceiling)** | ✗ pipelined | ✗ |

* **Co-residency ceiling ≈ 448 verified-simultaneous teams, max observed 516-532** (57-65 k threads;
  ~2× the 256 CUs, i.e. the shape fills the machine's thread slots). Tested two ways and they agree:
  team 0 waits for N entries before opening a release gate, *and* every team independently samples
  `entered − exited`; at 576 teams only 516-532 are ever alive at once. Crossing the ceiling is not a
  gentle rolloff, it is a **25× throughput collapse** (11.4 → 288 µs/job) — starvation, exactly the
  megakernel's epitaph, now measured as a function of grid size instead of inferred.
* **195 GB/s requires >= 256 resident teams** — 57% of the whole machine's capacity, permanently,
  for an engine whose jobs need 60-120. The plan's premise that decode's small grid ("~20-40 WGs")
  sits *below* the co-residency ceiling and is therefore safe from starvation is **true but
  irrelevant**: the ceiling is not the binding constraint, the *bandwidth per team* is. A small
  resident grid starves just as surely as a big one; it just starves quietly.
* **Why the model nevertheless shows 195 GB/s marginal, and why that is the kill shot rather than a
  contradiction.** Production does not read one expert with 60 units: the float decode gemv is
  split-K (`NSL_GU` is 2 by C-ABI tune and 7 by bench tune, times `nm`=2, times `I/ncwg`=5, times
  `nc`=2 ⇒ ~40-140 teams for gu, ~80 for down). Read that way, today's marginal rate is *consistent
  with* this lab's 207-215 GB/s point at 256-448 teams — i.e. the split path already occupies most of
  the machine's team slots **during the job** and gives them back between jobs. A resident engine has
  to hold them **forever** to get the same rate, which is exactly the §4 resource contract it cannot
  satisfy alongside prefill. (Inference from the shipped geometry, not a direct measurement: the
  number to check if anyone disputes it is the decode gu/down grid printed by `bench_layer --v`.)

### 11.3 G0 criterion "engine_wall < split_wall − 20 us" — FAIL at every geometry tried

Same bytes, same shapes, same process. The split arm issues blob H2D + gu launch + down launch + D2H
+ one wait (4 commands — production issues 5-6, so this control is *faster* than production's, which
raises the bar rather than lowering it):

| arm | µs/job | GB/s |
|---|---|---|
| **C — split path, 4 commands + wait** (control) | **56.0** | 43.9 |
| A2 — same work as ONE launch of 120 teams + wait (no protocol at all) | 43.0 | 57.2 |
| **B — engine, 128 teams, dma trigger, per_ping=1** | **84.4 / 92.3** (two runs) | 29.1 |
| B — engine, 64 teams | 111.5 | 22.0 |
| B — engine, 128 teams, per_ping=4 (not available to real decode) | 44.1 | — |
| B — engine, 128 teams, per_ping=16 (not available to real decode) | 25.3 | — |

(That table is `LAB_SK=2`, i.e. one k-slice per 128-column block doubled. §11.3a repeats it at the
geometry the shipped plugin actually launches, which is the number to quote.)

#### 11.3a Correction to §3.1's premise, and the measurement that matters

**A decode job is not "~20-40 WGs".** `moe_sycl.cpp` auto-scales `NSL_GU` with
`while (w < 8 && base*w*128 < 80000) ++w` where `base = nc*nm*(I/128)` = 20 at nc=2 — so it saturates
at **8**, and coop-D pins `NSL_D = 1`. Therefore gu launches `nc*nm*(I/128)*NSL_GU = **160**` units and
down `nc*(H/128)*NSL_D = **40**`: **200 128-thread units per decode job**, five times the grid §3.1
assumed. `LAB_SK=8 LAB_SK_DN=1` reproduces that exactly, and the same three arms then measure:

| arm (shipped geometry, 200 units/job, 2.458 MB) | µs/job | GB/s | tail |
|---|---|---|---|
| **C — split path (4 commands + wait)** | **28.9** | 85 | p99 49.9, n=200 |
| A2 — same work, ONE launch of 200 teams + wait | 19.4 | 127 | engine's own lower bound |
| **B — engine, 128 teams** (under-sized: 128 < 200 units) | **75.6** | 33 | 0 stalls, p99 107 |
| **B — engine, 200 teams** (the grid its work needs) | **97.1** | 25 | p99 **3424**, 4.8% >5 ms |
| B — engine, 256 teams | — | — | **never answered: 100% stalled** |

Needed to pass: **< 9 µs**. Got 75.6 µs at a grid *smaller than the job's own unit count*, and at the
correct grid the engine is 3.4× the split path with a 3.4 ms p99 — it does not just run slower there,
it stops being dependable, because the fan-in and the work now compete on the same 200 teams. Both
facts point the same way: the larger the grid the engine needs to be worth building, the worse the
engine gets.

Needed: < 36 µs even at the softer `LAB_SK=2` geometry. Got: 84 µs at the only operating point decode
can use — **one job per trigger**,
because layer k+1's input is layer k's output, so `per_ping` > 1 is available to this lab and to a
hypothetical batch-of-layers scheduler, **not** to autoregressive decode. (The `per_ping` rows are
included precisely to show what the gate would have needed: the engine approaches the split path
only when it is allowed to do work it cannot have.)

Sub-budget, protocol-only (`LAB_NOWORK=1`, dma trigger, 0 stalls in 100 pings at every grid size):
**21 µs per round trip at 16 teams, 36.1 µs at 128 teams.** So at the grid an engine would actually
need, the *trigger + fanned-out arrival + completion alone* already costs more than the 27.2 µs of
parent `sub` it exists to erase — before any work is done inside it, and that is on top of the
work-rate penalty above.

### 11.4 G1 — the doorbell: not a stall to be cured, a mechanism that does not exist here

Protocol-only engine, 16 teams, broadcast fan-out, two-level fan-in, 60 pings, stall = > 5 ms:

| host→device trigger | idle 0 | idle 100 ms | idle 100 ms + keepalive every 2 ms |
|---|---|---|---|
| atomic store to pinned USM | p50 14.8 µs, **68% stalled** | **no reply** | **no reply** |
| non-temporal store (`_mm_stream_si32`+sfence) | p50 12.8 µs, **78% stalled** | **no reply** | **no reply** |
| store + `clflush` | same class | **no reply** | **no reply** |
| **4-byte H2D `memcpy` into device memory** | **p50 18.9 µs (21.0 on a min-of-3 rerun), 0% stalled** | **p50 38.1 µs, 0% stalled** | (n/a — already a command) |
| `single_task` writing a device flag | no reply — **not a fair test, see note** | — | — |

Note on the `task` row: the trigger kernel read the job id from *sysmem* (`mb->tg_seq`), so it
inherits the store-visibility failure above instead of testing the mechanism. A fair version would
stage the id in device memory first (i.e. be an H2D + a kernel, strictly more expensive than the dma
row) — not worth running, since one command per job is already the point at which the design stops
paying.

The §2a attribution counter settled the direction that §2 said was "the single most diagnostic number
we lack": during a stalled ping **team 0's poll counter kept climbing ~12 million** — the engine was
spinning on the doorbell line the whole time and *not seeing the host's store*. The stall is on the
host→device leg, not the completion leg. Three consequences:

1. **Rule 1 was half the story.** An atomic RMW fixes the *device's* side of the poll; it does not
   make the *host's* store visible on a device that advertises neither
   `usm_atomic_host_allocations` nor `usm_atomic_shared_allocations` (§10). Warm it works for a few
   dozen pings, then loses the majority. §10's "the engine trigger must not be designed on top of
   it" is now measured, not inferred — and no host-side store flavour (release / NT / clflush) and no
   background traffic fixes it.
2. **The only dependable trigger is a command.** Which means the design's ceiling is not "zero
   submits per layer" but "**one** submit per layer instead of five": ~4 × 5.4 µs of parent time
   ≈ 21 µs, against a 19 µs protocol round trip and a 28 µs work-rate penalty at 128 teams. Negative.
3. **`lab_doorbell`'s 20-75% stall rate is explained** without invoking clock ramp *or* preemption:
   the ping loop's own waits (up to its 100 ms ceiling, plus the between-mode setup) put the device
   into the state below, and a store doorbell cannot recover from it.

### 11.5 Independent finding: the idle cliff, and it is not decode's problem

Same split-path chain, preceded by a host busy-wait of `gap` (min-of-3 p50, µs):

| gap | 0 | 0.2 ms | 1 ms | 2 ms | 3 ms | 5 ms | 10 ms | 20 ms | 50 ms | 100 ms |
|---|---|---|---|---|---|---|---|---|---|---|
| default | 55.6 | 56.3 | 56.7 | 56.8 | 57.6 | 58.9 | 70.6 | **247** | **404** | **410** |
| `EnableDirectSubmission=0` | 134 | 127 | 139 | — | — | — | 412 | 413 | 417 | 425 |

* **ULLS/direct submission is ACTIVE and worth ~78 µs per 4-command chain** (55.6 vs 134 µs at gap 0)
  — the doc's A/B test, run. Forced *on* equals default (96.6 vs 97.7), so there is nothing left on
  that knob.
* Beyond ~10 ms of device idleness the chain pays **+280-355 µs regardless of ULLS** (the cliff is
  still there with direct submission off, so it is device-side idle, not just a dropped ULLS ring).
  A keepalive drip (trivial `single_task` on a third queue every 0.5-2 ms) flattens it to ~91-105 µs
  — i.e. it removes the cliff but lands 35-50 µs *above* the warm floor, so it is a cure for long
  idles, not a win for busy ones.
* **Decode's own inter-job gap is ~300 µs** (48 layer-jobs per 14.7 ms token), deep inside the flat
  zone. So this cliff does **not** explain the fixed 57.6 µs/forward, and closing lever 1b does not
  make it go away. Where it *does* bite: the first B70 job after any pause > ~10 ms — a long prompt's
  prefill→decode transition, a user think-time gap, or a stream that stalls in python. Worth its own
  cheap follow-up (see §12.3), separate from this plan.

### 11.6 Two lab traps found the results above (both now documented in NOTES)

* `q.copy(a, b)` is `(Src, Dest)` — the P3/P4/P5 trap, hit *again* in a new lab: my residency readback
  wrote host zeros into the device counters, so every grid size reported "NON-RESIDENT 0/N" while the
  bandwidth numbers next to it were perfectly good. A silently inverted readback is the most dangerous
  kind of instrument error because it agrees with the hypothesis you were afraid of.
* A poll-**count** bound is not a time bound here. `lab_doorbell` assumed ~1.5-2 µs per sysmem poll;
  measured on this box it is **~60 ns (1.7e7 polls/s)**. So the plan's "SPIN_MAX_SYS in the 1-3 s
  range" means **~2e7 polls**, and the first cut's 1e6 was 60 ms — the engine was killing itself mid
  run and I read that as "the doorbell stalled". Also: the residency test itself must not violate rule
  2 — the first version had N team leaders *RMW-polling* one ticket line, which both hung for minutes
  and depressed the throughput it was measuring.

---

## 12. Closure, restart conditions, and the one loose end worth chasing

### 12.1 Closed

**Lever 1b (persistent B70 worker) is CLOSED.** Recorded against the megakernel post-mortem's
restart condition (b) exactly as §3.0 instructed. Three independent reasons, any one sufficient:

1. **Feeding itself needs half the machine, permanently.** A decode job is 200 128-thread units
   (§11.3a — `NSL_GU` saturates at 8), and this gemv shape only reaches today's 195 GB/s marginal rate
   at >= 256 co-resident teams; the co-residency ceiling is ~448-512 and 576 collapses throughput 25×.
   So the engine must hold ~half the machine's thread slots **forever** to match a rate the split path
   buys **per job** - and §4's "keep the engine small and let prefill have the rest" is the option that
   does not feed itself.
2. **It loses on wall clock anyway, at every geometry.** Shipped geometry: **75.6 µs/job** (engine, at
   an under-sized grid) and **97.1 µs/job** (at the 200-team grid its work needs, p99 3.4 ms) against
   **28.9 µs/job** for the split path — where the gate was "beat it by 20 µs", i.e. < 9 µs. At the
   softer `LAB_SK=2` geometry: 84-92 vs 56.0. Both protocols, both fan-out styles, and the only
   dependable trigger were used in the engine's favour.
3. **The trigger costs a command.** The only mechanism that completed every ping is an H2D copy —
   one submit per job, which is ~4×5.4 µs of the 27.2 µs prize handed straight back, on top of a
   ~19 µs round trip. And the doorbell premise itself (§1-§4) is not supported by this device's
   advertised capabilities (§10 row 5), now confirmed behaviourally: a resident poller stops seeing
   host stores, with the device spinning on the line at 1.7e7/s and never observing the update.

What survives of the plan's reasoning: the prize arithmetic (§1) was real, and the *reason* it is
unreachable is not the one §1 feared ("no dependable trigger" was right, but the mechanism is
host→device store visibility, not clock ramp, not preemption, and not barrier cost).

### 12.2 Restart conditions (all three, or nothing)

Do not reopen 1b unless **all** of these are true, because each has now been measured to be
necessary:

1. A **contractual** host→device trigger with no per-job command: either a driver/runtime that
   advertises `usm_atomic_shared_allocations` (or documents host-store→device-poll coherence for
   pinned USM), or an imported external semaphore / `zeCommandListAppendMemoryWait` path that parks
   without burning an enqueue. Re-test with `lab_resident_bw B` (`LAB_ENG_TRIG=0..4`): the bar is 0
   stalls in 300 pings at idle 0 **and** idle 100 ms.
2. Evidence that the **work inside** a persistent grid is not penalised: `lab_resident_bw B 2 …` with
   `LAB_PER_PING=1` must beat `./lab_resident_bw C` (which prints its own A2 "work-only one launch"
   reference). Until the engine is faster than 43-56 µs at 120-128 teams, there is nothing to integrate.
3. A scheduler that can legitimately keep >= 256 teams busy *without* stealing them from prefill —
   which is a different architecture (e.g. resident-throughput designs like MPK's SM-level task graph)
   and would be a new plan, not a revival of this one.

### 12.3 The loose end worth its own hour: the >10 ms idle cliff

§11.5 is a fresh, reproducible platform fact: the same 4-command chain costs 56 µs warm and 247-410 µs
after >= 20 ms of B70 idleness, and a keepalive drip flattens it to ~91-105 µs. Decode's own cadence
(~300 µs between jobs) is in the flat zone, so this is **not** the decode fixed cost — but every
"first B70 call after a pause" pays it: prefill→decode transitions, the first token after streaming
input arrives, `bench_b70_py.py`-style microbenchmarks that sleep, and any interactive use. Cheapest
follow-ups, in order: (i) confirm it in the model — timestamp-to-first-B70-job after a deliberate
pause, with the existing ALLOCLOG phase fields; (ii) decide whether the plugin should keep the B70
warm during input streaming (a `single_task` every ~2 ms while the parent is tokenising/prefilling,
cost ~0.05% duty); (iii) check whether it survives `xe` sysfs frequency pinning / `enable_dc=0`
(requires root — note in README rather than shipping).
