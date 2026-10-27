# Harness, tools, and lab inventory

## Production code

| file | role |
|---|---|
| `moe_sycl.hpp` / `moe_sycl.cpp` | pipeline kernels + host-side `MoeSyclLayer` (forward, `ensure_ws`, repack, X-macro rate lists, `int8_pick`) |
| `b70_lib.cpp` | the C ABI the worker dlopens: `b70_init/_register_layer_n/_forward/_warm/_free_layer/_update_expert`, VRAM budget, arena, poison latch, alloc log |
| `libb70moe.so` | build product (see README build line); `env.sh` exports its path |
| Hooks upstream | `exllamav3_ext/cpu/moe_mul1.cpp` (`B70Backend`, forward redirect, native-layout swizzle gate) + one `int64_t b70` field in `moe_mul1.h` |
| `exl3_ref.h`, `exl3ref_dup.h` | host transcription of the mul1 tile decoder (`decode_state_scalar`, `make_tc_perm`, fixed splitmix `exl3ref::Rng`) |
| `moe_host_ref.hpp` | fp32 transcription of the CPU scalar LAYER forward — the spec the device is judged against |

## `bench_layer.cpp` — the standalone harness (no exllamav3 needed)

Flags: `--e --rows --topk --iters --act {0 silu,1 gelu-erf,3 swiglu_oai} --bits --hb --gateless
--v --load <xval_dir> --nocheck --bare --skew <exp> --alt <N> --i8trace`.

- Default mode: synthetic data + check vs `moe_host_ref` (~3e-6 max_rel across E/rows/topk/bits/hb/act).
- `--skew <exp>`: zipf expert selection (models the per-expert m skew of fresh placement
  profiles); `<0` = the "all-minus-1" degenerate job probe (zero-entry tokens).
- `--alt N`: alternating-dataset stress, chained via `pre_dep` like production. This is what
  caught the queue-ordering relapse; static data cannot expose cross-launch races.
  `MOE_ALTDUP` for A,A,B,B patterns.
- `--bare`: barrier-only round trip (the 33 µs/command figure came from this).
- `--v`: per-kernel spans/gaps — DIAGNOSTIC ONLY, inflates the pipeline ~40 µs (`measurement-discipline.md`).
- `--i8trace`: external per-stage integer verifier for the int8 tier (stages B..G; all must print
  OK). Stage semantics live in the harness source; it mirrors production knobs via
  `layer.i8slim()`, `layer.i8nsl()`, `i8fuse()`, and collapses `[slot][nsl][8][N]` split-K acc
  buffers.
- External probes: `EXL3_MOE_STAGEPROBE` (tout/tind readbacks incl. all-chunks tind vs host
  recompute), `EXL3_MOE_B70_CTRDBG` (coop epilogue fire counters), `EXL3_MOE_NSLG/NSLD`
  (float split-K per kernel).

**The trace harness was NOT the innocent arbiter it pretended to be.** Bugs found IN the
harness after it had already sent us chasing device bugs:
- stage D/G folded `-510*B` with an EXTRA ×128 (`gb` already summed B over the 128 i-iters) —
  would have demanded a 16384x fold from the kernel; the MAXM8-era "act3 stage-D failure" (1
  column, abs 1.4e-8 at a |gv|~1e-4 cancellation) was the harness accumulating `gb += B` over 128
  float iterations instead of the kernel's one-shot `128.0f*(B0+B1)` (sequential-add drift ~1e-4
  RELATIVE on the fold). Deterministic, seed-stable, NOT a device bug.
- gateless `tin` readback was half-size (K1 writes `ts=2j` slots even when nm=1) → NaN garbage
  compared as "want 00000000";
- swiglu_oai applied `uv` twice (`av=(uv+1)*sigmoid*gv`, then `hv=av*uv`);
- float stage-check block ran even when int8 was active;
- stage G gate had to be loosened to rel 1e-3 / abs 1e-6 (fp32 endpoint + atomic ordering ulp noise);
- int8 tier is judged by **rms ≤ 3%**, NOT max_rel (max_rel cancels pathologically);
- the t30 lab harness ENCODED the kernel's window formula, so it could not catch a shared
  misconception — independent checkers must be written from the FORMAT spec;
- `bench_b70_py.py` hardcoded `gated=1` (gateless dumps then score rms ~1.05 and look catastrophic);
- a `--gateless` xval WITHOUT `--scalar` compares against the AVX2 tier → rms 1.38e-2 = exactly
  the documented AVX2-vs-scalar deviation, and both plugin builds matched it to the last digit
  ("identical old and new" = harness artifact reflex);
- bench chunkers indexed `per_expert[-1]` on the `nc==0` degenerate job;
- a debug probe sized for I floats but filled with H floats presented as `malloc(): invalid size`
  heap corruption.

## Python tools

| tool | purpose |
|---|---|
| `xval_cpu.py` | dump real-extension inputs/outputs (`--E --rows --topk --bits --hb --outdir --gateless --scalar`); needs CUDA+ext. Feed the dir to `bench_layer --load`. **Always pass `--scalar`** for gateless comparisons. |
| `bench_b70_py.py` | time the plugin C ABI on a saved layer (`python3 bench_b70_py.py xval_s`); the honest per-forward decode number and the rms guard that catches silent upload bugs. |
| `test_arena_update.py <xval_dir>` | three BYTE-EXACT substitution identities for the in-place install path (idempotent reinstall, slot←src mapping, fan-out overwrite). The ONLY thing that exercises `b70_update_expert` — tier guards mean model runs never install onto a registered layer. Run after ANY upload/ABI change; gateless needs a `--gateless --scalar` dump. |
| `regbench.py <lib> [E] [N]` | synthetic E=256 registrations through the C ABI: registration throughput without a 4-minute model load per data point. |
| `attrib_faults.py <alloc.log> <va>...` | attribute xe-driver UA page faults to plugin USM allocations using the `EXL3_MOE_B70_ALLOCLOG` A/F + J records (rebuilds the live map AND searches freed history; 48-bit sign-extension handled). This tool found the stale-pool-pointer bug. |
| `env.sh` | source before ANY torch-ext python: oneAPI setvars + `.toolfix` gcc-15 shim + `CUDAHOSTCXX=g++-15` + `EXL3_MOE_B70_LIB`. The torch JIT cache keys on the environment; without it a full 190-file CUDA rebuild explodes in ninja (system g++ 16 vs nvcc ≤15). |

## Micro-labs (what each one settles — keep them, they are the citation trail)

| lab | settles |
|---|---|
| `poc_dequant.cpp` | PoC1: state extraction + mul1 dequant on B70 bit-exact vs host ref for K 1..8 incl .5 rates |
| `memq.cpp` | device memory query + "does malloc_device fail near capacity" probe (it does not, reliably) |
| `profile_gemv.cpp` | clean per-op profile (12800 threads x 2560 ops, 5 modes, DCE-proof) |
| `t7/t8.cpp` | K2 isolation (one chunk, gate matrix): kernel vs host sim |
| `t10.cpp` | the cold-call investigation (forward twice, dump ws after each) — the queue-ordering bug's crime scene |
| `t13.cpp` | streaming BW achievable for the K2 WG/access shape (80 KB/WG through shared, no math) |
| `t14/t18.cpp` | gemv inner-loop cost ladders (t18: padded-tile + vector loads, throughput only) |
| `t16.cpp` | subgroup-local shared staging with cheap barriers (slower — see pitfalls P10) |
| `t17.cpp` | in-process calibration: fp32 vector throughput + mem copy (b70-bench style) |
| `t19.cpp` | dp4a hardware check (not accelerated) |
| `t15_strip.cpp` | prototype "column-strip" weight layout (superseded by the stream layout) |
| `t21.cpp` | host validation of FAST-PATH extraction vs the scalar spec — caught the "aligned column window" flaw |
| `t22/t25.cpp` | differential bit-mapping of `decode_state` ((t,j) → physical (word,bit)) |
| `t23/t24/t26/t26b.cpp` | fitting/validating the position law `P(t) = P0 - (K2*t)/2` on random rings |
| `t27.cpp` | simulate kernel fast-path extraction against `decode_state` on a repacked tile |
| `t29.cpp` | **clean fast-path extraction verification for ALL rates K2 2..17** — the stream layout proof |
| `lab.cpp` | rigorous inner-loop A/B lab (same data shape as the real gemv, several lowerings, interleaved min-of-many) |
| `lab_dot.cpp` | mul1 bytesum on Xe2 per the Trellis cheat sheet: validates cheat-sheet K=4 vectors through Recipe-B extraction, A/Bs mask chain vs flat bytesum (the clock-ramp inversion lesson) |
| `lab_dpas*, lab_jm..jm6` | the DPAS dead ends: operand layout discovery (dpas2/dpas3/dpas5), generic-kernel dpas (jm), SLM-fed joint_matrix fixup cost (jm3/jm6), sustained inner loop (jm4) |
| `lab_jm7.cpp` | **the breakthrough**: B in `ext_intel_packed` (VNNI) — exact, 1.4 ns/fragment, ~0.27 lane-inst/weight |
| `lab_jm8.cpp` | production Gemv8 geometry in isolation: one tile of 16 mul1 words staging TWO k32 fragments into one 1 KB SLM slab (`slp`, `slp+512`, stride 64). Production staging mirrors this verbatim |
| `t30.cpp` | Gemv8 isolation with controlled A operands (modes hot/one/rnd/sat/q25/rneg…; `tm`/`tq` timing with production geometry). The `rnd` (random SIGNED A) mode is what exposed the negative-splat bug |
| `t31.cpp` | Gemv8P crash bisect + variant ablation lab (V0 full two-tile … V12 PKA pair-decode, P22/V22 depth-4 prefetch, VARIANT 20 coalesced+shuffle). Source of the "gated blocks skip work" ablation lesson |
| `t32_upd.cpp` | `b70_update_expert` functional test: register A, update slot to B, forward must equal a fresh B registration |
| `t33_cap.cpp` | bounce-cap growth regression (a job larger than the 64-row prime must run, not silently refuse) |
| `t34_load.cpp` | load-path repro: 48 sequential E=256 registrations as the worker child does during model load |
| `t35_l0.cpp` | per-command latency sources; can raw ze appends beat SYCL submit here (yes: 12-15 µs vs 23-44 µs) |
| `t36_l0mod.cpp` | can an EXTERNALLY created ze module run on the SYCL queue's own immediate list (yes; RT-JIT handles do not) |
| `t37k.cpp` / `t37drive.cpp` | SPV-from-SYCL pipeline + driver: nd_item builtins and subgroup collectives verified |
| `t38_bar.cpp` | grid-wide barrier feasibility/cost/residency ceiling on B70 (~2-5 µs/barrier at 32-128 WGs; thin-kernel ceiling 160-280 WGs) |
| `t39_stream.cpp` | the real Gemv8 B-ladder + band + fragment pipeline standalone, DPAS stage-gated 1..18 → **the global A gather is the whole regression**; production footprint roofline |
| `t40_esimd.cpp` | esimd endgame proof: per-thread `xmx::dpas<8,8,int>` with s8/u8, operand layouts impulse-verified, bit-exact, on par with fixed SIMT |
| `t41_sub.cpp` | three-tier subset registration: members `[0,n_sub)` bit-identical to full registration; non-member updates no-op |
| `t42_l0enum.cpp` | does `zeModuleCreate` accept the production TU's SPV + kernel name enumeration |
| `t43_abi.cpp` | the exact launch ABI for the production chain (captured args = by-value POD struct + local_accessor as one 8B ptr) |
| `t46_pub.cpp` | does `it.barrier(fence_space::global_space)` publish global stores to another WG's device-atomic load (yes, when launches are CHAINED — see pitfalls P1/P7) |
| `save/moe_sycl.o`, `*.bak*`, `bench_layer.*`, `libb70moe.so.pre-coop`, `*-host-*.ii/.s` | build leftovers / snapshots kept for diffing; safe to garbage-collect when disk pressure matters |

## Build recipes

```bash
source sycl_moe/env.sh
# plugin
icpx -fsycl -O3 -ffp-contract=off -foffload-fp32-prec-div -fPIC -shared \
    b70_lib.cpp moe_sycl.cpp -o libb70moe.so \
    -Xlinker -rpath -Xlinker /opt/intel/oneapi/compiler/2026.2/lib
# harness
icpx -fsycl -O3 -ffp-contract=off -foffload-fp32-prec-div moe_sycl.cpp bench_layer.cpp -o bench_layer
# one-off microbench: icpx -fsycl -O2 x.cpp -o x   (per-variant: -DVARIANT=n)
```

The exllamav3 extension itself needs no separate build step — the torch JIT rebuilds when
`cpu/moe_mul1.cpp` changed and dlopens the plugin lazily. `build.sh`'s `python -m build` is
broken by system g++ 16 (nvcc wants ≤15); the cached JIT `.so` at
`~/.cache/torch_extensions/py312_cu130/exllamav3_ext` loads fine — don't rebuild the CUDA ext
casually.