# Kernel micro-optimization log (what moved, what didn't)

Shape shorthand: E=12, rows=1, topk=10, 2bit (K2=4), gu matmul `2560x640`, B70. Times are
unprofiled sustained unless stated. Labs referenced (`t*`, `lab_*`) live in `sycl_moe/`.

## Where the float gemv time actually goes (original anatomy)

- apack register-addressed gemv: K2 216 µs / K5 56 µs (nsl=1), pipeline total 343 µs.
- split-K nsl=2 halved K2 (127 µs), total 260; nsl=4 adds more partial-sum cost than it saves.
- **Replacing per-weight `apack` extraction by CONSTANT addresses per `rk` was 3.5x faster
  (36 µs)**: the per-weight ADDRESS ARITHMETIC (u64 extract + derived dynamic indexes +
  64-bit variable shifts), not the loads, dominated. A rate-specialized path with constexpr
  shifts reached the same conclusion → `GemvK<K2V>` on the stream layout.
- K1/K3/K4/K6 together ~40 µs at rows=1; the cost there was hadamard via shared+barriers
  (now `had128_strided`, barrier-free).
- Issue-rate wall (VTune pass 2, pre-fix `gemv_gu`): ~61 lane-instructions per 3006 launches;
  at 4096 lanes x 2.8 GHz the FLOOR was 56 µs vs 70 µs measured, XVE active only 40%, 52% idle.
  Culprit: predicated-but-issued FMA chains for chunk slots 2..4 at m=1 (~30% of the body).
  Fix: `template GemvK<K2V, MMA>`, single-slot decode jobs take `MMA=false` → inst/launch -42%.
- Inner loop per state, float tier: ~9 int ALU (mul, 2x(and+add fused), shr, funnel pair) + cvt
  + fma. We are at the instruction-issue floor for the FLOAT-tier formulation; only an
  int8/DPAS tier redesign moves it further. (Confirmed later: at rows=1 both tiers are
  weight-traffic bound anyway.)

## ADOPTED

- **16-bit windows via 32-bit funnel shifts** `lo>>s | ((hi<<1)<<(31-s))` instead of
  `(uint64(hi)<<32|lo)>>s` — decode 174.0 → 169.2 µs mean (10 paired runs, funnel better
  8/10); `GemvFallback` also drops the 64-bit merge. Bit-identical results (xval 6.06e-7
  unchanged). Validated bit-exact against the cheat-sheet K=4 test vectors on B70 incl.
  tail-bit wrap (state 0) and edge states (`lab_dot.cpp` recipe B).
- **K3+K4 fusion** (act + prep-d): the activation tile never leaves SLM — saves a submit, a
  barrier round and ~256 KB of global roundtrip per chunk; fused span 3.6 µs, results
  identical to 1.8e-6.
- **Split-K auto cap 4 (gu) / smaller for down**: cap 4 beat 8 by ~10 µs at decode shapes
  (partial-sum traffic vs latency). Post-MAXM8 retune: the gu fill target moved to
  **136000 lanes** because chunks halved — rows=64 (~132k lanes) wants nsl=2 where the old
  80k-lane target picked 1 (-13%); nsl=3 costs the 61-70k shapes +0.8%. Down heuristic
  already tracked the per-kernel optimum (checked with `EXL3_MOE_NSLU/I8NSLU/NSLD` overrides;
  d ∈ {1,2,4}).
- **Depth-4 prefetch done RIGHT** (four NAMED word sets + 4x-unrolled group loop, t31 P22/V22,
  bit-exact vs the ring-normalized checker): G2 lab 55-62 → 54-56 µs (nsl2 -7%), shipped in
  Gemv8 for all K2. The earlier depth-4 DISASTER (105 → 149 µs) was a `(tk&3)`-indexed
  register ARRAY spilling and defeating the unroller, not the idea.
- **PKA pair-decode** helps in the pair-loop shape (-19%, V12 vs V0), ~neutral in single-tile
  (kept anyway).
- Full pair-loop ≈ single-tile ping-pong ≈ 55-62 µs for the gu lab shape (honest numbers,
  t31 V0/V12 + t30 tq).

## REJECTED (each measured, most after a false positive)

| idea | verdict |
|---|---|
| `dot_acc`/`dp4a` SYCL ext | not hardware-accelerated here; equals manual bytes |
| shared staging + per-tile WG barriers | SLOWER than plain global loads (barrier ~0.3-0.5 µs/iter at 128-wide groups) |
| large GRF (`-ze-intel-enable-auto-large-GRF-mode`) | **-25%** on the gemvs |
| `annotated_ptr` read_hint / streaming cache controls | no measurable effect (kept behind `MOE_GEMV_CACHEHINT`) |
| flat byte tree `(x&0xff)+(x>>8&0xff)+...` | +6%; IGC's pair-chain selection (fuses masks into dual-issued and/add pairs) is already optimal at stable clocks |
| folding `-510` (`acc += bs*x; nx -= 510*x`) | cold-run artifact; neutral-to-worse at stable clocks, and perturbs fp32-tier rounding for nothing |
| esimd `dp4a` in generic kernels | signed lowering gives wrong bytesums + 2.5x slower; see `platform-pitfalls.md` P9 |
| **coalesced weight-word loads + `select_from_group`** | CORRECT (bit-exact vs an independent ring-normalized host checker) but 77-104 µs vs V0's 57-62 at the gu lab shape (nsl 1..8). Indirect-lane shuffles lower worse than the redundant overlapped L1 loads they replace. The 5x word overlap was NOT the wall. Killed. |
| jb-from-global scratch | slower AND alignment-crashy: nsl values where `(slot*nsl+sl)*nfl*512 % 64 != 0` fault the 2D block engine (device loss) |
| 128-lane wide WG (`NSUB=8`, `EXL3_MOE_I8W=1`) | bit-exact but rows=1 unchanged and rows=64 **-8%**: the 23% thread occupancy was not the binding constraint (weight-stream latency is). Kept as documentation of the negative result. |

For context, the t31 ablation buckets (gu lab shape, nsl4, FULL work) that motivated the
coalesced experiment: skeleton 18 µs, +5-lane-word loads ~15, +STS ~11, +ja/jb operand moves
~23, +mads ~10. Every lane loads 5 of the 16 tile-row words and 16 lanes overlap ~5x on the
same 64B row — but that is L1 traffic, not DRAM (unique 8.2 MB = 13.5 µs). The operand-move
term was later understood properly via the joint_matrix A-gather finding (`int8-dpas-tier.md`).

## Plateau analysis (float tier)

- Steady synthetic decode/layer history: 343 → 260 (split-K) → ~172-186 (hints/fusion/nsl
  pass) → 165-172 (VTune pass 2 + MMA split). Production per-forward through the C ABI is
  lower (~101-113 µs) because the handoff path overlaps submits.
- gemv at rows=1 after the fixes is latency/idle-bound (~65% idle); split-K beyond 8 needs the
  workspace pool resized (see `platform-pitfalls.md` P11).
- Roofline sanity: both tiers at rows=1 are weight-traffic bound. At 2bit, both tiers read the
  SAME weight bytes, so DPAS only wins where the vector-ALU term matters (m≥2).
- Remaining big-ticket items identified by the manual roofline passes (decode is nowhere near
  608 GB/s): (1) native-L0 single immediate command list per forward, (2) XMX DPAS int8/s4
  tier (landed), (3) parallelize K6 over (chunk,blk) with atomics (landed differently:
  owner-gather, then counter-fed fusion — `decode-command-latency.md`).