# PLAN: persistent B70 worker (kill the per-layer command round trip)

Status: **not started.** Run **gate G0 (§3.0) first** - it is a half-day of lab work that can kill the
whole idea cheaply, and a measured predecessor already lost this fight once (megakernel: 466 us vs 183
at rows=1, starvation not barriers). Only if G0 passes does the §2 trigger experiment (~45 min) matter.
No production code until §5's gates are met. Owner notes: SESSION_20261028.md 2026-10-29
(08:20-13:05); budget data in `archive/measurements-ledger.md` §"Decode forward budget, IN THE MODEL"
and `archive/decode-command-latency.md` §2026-10-29 + §"Megakernel experiment". Complements
`PLAN_L0.md` (see §8 for why that one stays closed).

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
* a resident spinner makes a *second* queue's 16 MB fill **faster** (17.5 µs vs 34.0 µs unspun);
* the stalls show up while the card is otherwise doing nothing: it draws ~80 W of 275 W during decode
  and falls as the run proceeds (user-observed), and with nothing resident xpu-smi reports 0% util.

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

## 5. Decision gates, restated

0. **gate G0 (§3.0): a permanently-resident grid of thin float-gemv WGs must sustain >= 195 GB/s of
   packed bytes at a grid the device actually keeps resident, and beat the split path's wall by > 20 us
   at the same nc** -> else lever 1b is CLOSED (the megakernel already lost this fight once).
1. gate G1 (§2): a keepalive/wait strategy with stall rate < 1%, p99 < 200 us, cost < 2 us/job -> else
   STOP and mark 1b closed.
2. §3 gate: bit-identical results **and** child wall p50 ≤ 45 µs at nc≈2 **and** parent host ≤ 8 µs
   → else STOP (the win is inside the noise floor, see §7).
3. §4 gate: interleaved model A/B, 3 rounds, both placement layouts, decode ≥ +3% (noise floor ±3%)
   with prefill within ±1% → ship default-on; +1-3% → ship default-off with docs; ≤ +1% → close.

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

## 9. First session, concretely

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