# B70 MoE offload — SYCL/Level-Zero expert compute for the CPU-MoE worker

Computes the CPU-offloaded `exl3_moe_cpu_forward` expert layer on an Intel Arc GPU
(Xe2 / BMG-G31, developed on an Arc Pro B70) instead of on the CPU, through a dlopened
plugin (`libb70moe.so`). The MoE weights stay in the CPU worker's arena *and* get a full
copy uploaded to the GPU once per layer at load time; per token only the activations
cross PCIe. Everything else (STAGE jobs, CUDA-resident experts, the parent process) is
untouched, and any layer the GPU can't take falls back to the normal CPU kernels.

Compute semantics match the CPU worker's **scalar (fp32) tier** — cross-validated against
the real extension at ~6e-7 rms (see Benchmarks below), and bit-checked per-kernel against
the tile decoder. The AVX2/int8 tier deviates ~1.4% from scalar; B70 output is *closer* to
the fp32 reference than that tier.

Multi-row jobs (any forward with ≥2 token rows: prefill chunks, wide decodes, spec batches)
run the **int8 / XMX DPAS tier**: joint_matrix m8n16k32 with the mul1 product words fed as
VNNI-packed u8 B operands and always-wide vh/vl int8 activation rows — the same integer
identity the CPU VNNI tier computes. It is stage-bit-exact against the external
`bench_layer --i8trace` model, ~1.4e-3 rms vs the CPU scalar extension, and ≤0.25% wikitext
ppl on all three Qwen3.8-Flash-Next models (≈10× closer than the CPU AVX2 tier). Sustained
worker-layer A/B (bench_layer, min-of-2 sustained): speedup x1.49 at 2 rows, x1.90 at 4,
x2.10 at 8, **x3.2 at 32-64** — up to 8 tokens ride one weight stream per chunk (two m8
fragments share every staged B band), while the fp32 tier pays per (chunk × row) and caps
at 4 rows. Narrow-chunk passes (every chunk ≤4 tokens) run a slimmer DPAS instantiation
without the second fragment, and the whole int8 pipeline is two commands shorter than
float (fused prep+quantize, owner-gather epilogue — no tin round-trip, no out memset,
no atomics). Single-row decode still ends ~9% behind fp32 (m8 fragments run 12% full and
the per-forward command floor ~33 µs binds), so auto mode keeps rows=1 forwards on the
fp32 scalar-semantics pipeline; `EXL3_MOE_B70_INT8=1/0` forces either tier. End-to-end
(2.05bpw -mcs256): prefill 2048 1456 (CPU worker) → 1711 (B70 fp32) → **1869-1880 tok/s**
(B70 auto/int8), decode ~70-72 (fp32 tier; forced int8 measures 67.8 — float wins m=1
in the real model too). See `archive/int8-dpas-tier.md` (packed-VNNI dataflow, the
negative-splat trap, tier policy) and `archive/measurement-discipline.md` (why short benchmark
windows lie about this GPU; sustained A/B tables in `archive/measurements-ledger.md`).

## Requirements

- Intel Arc Pro B70 (or Xe2) GPU, `xe` kernel driver, compute-runtime ≥ 26.x
- oneAPI Base Toolkit with `icpx` (developed on 2026.2). Builds use `-O3` (verified:
  bit-identical results, ~2.6% faster synthetic decode; an earlier '-O3 crashes icpx'
  note turned out unreproducible — see `archive/platform-pitfalls.md` P10; if the compiler ever
  dies on these TUs, fall back to `-O2` and re-file).
- **FP flags are part of correctness**: always build with `-ffp-contract=off
  -foffload-fp32-prec-div`. Without them the device's fused mul+round and approximate
  `127/amax`-style divisions flip int8-quantization ties vs the CPU reference (visible
  as ±1 x8 steps at rounding boundaries; the `--i8trace` stage-B gate catches it).
- `EXL3_MOE_I8FUSE=0` — split the fused prep+quantize kernel back into K1+Q1 (lab A/B;
  fused is the default int8 path and sets `i8fuse()`, which i8trace stage B mirrors by
  host-preping x with `moe_ref::prep_row` instead of reading the never-written tin).
- `EXL3_MOE_I8SLIM=0` — lab-forbid the slim decode kernel. When every chunk carries
  ≤4 tokens the int8 pipeline auto-selects an `F1=false` Gemv8 instantiation that drops
  the second m8 fragment (load, DPAS, store) and a matching QuantIn that skips frag1
  zero-fill; rows 2–4 run ~10–16% faster. acc rows 8–15 are stale on that path
  (never read; the trace knows via `i8slim()`).
- `EXL3_MOE_I8W=1` — lab-only 128-lane wide workgroups (8 column tiles per WG).
  Measured ≤ 0 everywhere (weight-stream latency, not thread occupancy, binds); kept
  as documentation of the negative result. (Superseded for the fat path by `I8RING`,
  which uses the wide geometry plus SLM-staged A and is a large win — see below.)
- `EXL3_MOE_I8RING` (`default 1`; `=0` opts out) — cooperative A staging for the fat int8 gemvs (gu+down, prefill
  shapes; slim decode unaffected). The `joint_matrix` global A load lowers to a per-lane
  byte gather costing ~2.8x the kernel (labs t39 st4 vs st18); wide WGs + a 4 KB contiguous
  copy per k-group into 4 rotating SLM regions + local fragment loads recover the no-A-cost
  ceiling. Measured bit-exact (full i8trace + fingerprint battery): E128/rows128 −32%,
  E256/rows128 −33%, E512/rows128 −43%, rows32 −21…−24%, decode neutral. Lab: t39/t40.
- `EXL3_MOE_I8NSLU/-NSLD` — per-kernel int8 split-K overrides (1–8), applied after
  `MOE_NSL`; used to retune the gu fill target to 136000 lanes post-MAXM8.
- Linux (the plugin hooks are `__linux__`-only; nothing changes on other platforms)

## Build

```bash
source sycl_moe/env.sh          # oneAPI setvars + torch-JIT env recipe + EXL3_MOE_B70_LIB
cd sycl_moe
icpx -fsycl -O3 -ffp-contract=off -foffload-fp32-prec-div -fPIC -shared \
    b70_lib.cpp moe_sycl.cpp -o libb70moe.so \
    -Xlinker -rpath -Xlinker /opt/intel/oneapi/compiler/2026.2/lib
```

The exllamav3 extension itself needs no separate build step — the torch JIT extension
rebuilds when `cpu/moe_mul1.cpp` changed (it dlopens the plugin lazily at runtime).

## Activating

```bash
source sycl_moe/env.sh                  # exports EXL3_MOE_B70_LIB (path to libb70moe.so)
EXL3_MOE_B70=1 python your_script.py --moe_cpu_split N ...   # or -mcs N
```

| Env var | Meaning |
|---|---|
| `EXL3_MOE_B70=1` | Route layers registered with the CPU MoE worker to the GPU. Unset/`0` = CPU as before. |
| `EXL3_MOE_B70_LIB` | Path to `libb70moe.so` (default `libb70moe.so` on the loader path). Set by `env.sh`. |
| `EXL3_MOE_B70_BUDGET` | Fraction of GPU VRAM the plugin may hold weights in (default `0.82`; the plugin also needs room for per-forward workspaces — if forwards start faulting, lower it). Layers past the budget register-fail and stay on CPU — this is safe and automatic. |
| `EXL3_MOE_B70_SUB` | Three-tier placement: keep only the first `n` (or fraction `f<1.0`) experts of EVERY layer device-resident on the B70; the coldest slots of every layer fall back to CPU/RAM compute (arena + streaming). `auto` = defer all B70 registrations to worker start, then size every tier as the fair share of the remaining device budget across the (now known) layer count. Recommended for models whose expert set exceeds both GPUs (2.68bpw: +43% prefill, +12% decode vs classic; 4.05bpw: pair with `EXL3_MOE_STREAM_T=4..6`). `Unset = full-slice registration (classic whole-layer tier). Hot experts then live on the B70 across all layers instead of a prefix of layers owning everything. The parent respects the tier: pinned-arena streaming and promote-on-miss only target CPU-tier slots, so `-mcpa` no longer steals B70 work. |
| `MOE_NSL=0..8` | Override the split-K degree of the GEMV kernels (default: auto per matrix class). Tuning knob for experiments. `EXL3_MOE_NSLG`/`EXL3_MOE_NSLD` set the float tier's gate/up and down degrees separately. |
| `EXL3_MOE_B70_COOP` | `0` disables the counter-fed fused DOWN kernel (float tier, `rows<=8`, compile-time-specialized rates: K5+K6 in ONE launch with CUDA-`exl3_moe_coop`-style arrival counters; `NSL_D=1` keeps the row sum in registers, no float atomics, summation order bit-stable vs the split path). Default on: ~-11us per decode forward (C-ABI 113→101 us on the xval shape). Sub-switches: `EXL3_MOE_B70_COOPDN=0` restores classic K5+K6; `EXL3_MOE_B70_COOPGU=1` opts into the parked (currently ~neutral) K2+K34 fusion. |
| `EXL3_MOE_B70_MCAP=4\|8` | Lab override of the int8 chunk width cap (default 8; the fp32 tier is always capped at 4). |
| `EXL3_MOE_B70_OVERLAP` | `0` disables prefill-size mixed-job overlap (B70 half on a borrowed thread while the CPU pool works the other half; default on for `rows>=16`, sequential for decode sizes). 0-4% prefill on 4.05bpw (noise-bound), neutral elsewhere. |
| `EXL3_MOE_B70_INT8` | `1` force the int8/DPAS tier, `0` force fp32; unset = auto (int8 iff the forward has ≥2 token rows). ALL eleven contract rates (K2∈{2,3,4,5,6,7,8,10,12,14,16}, halves only ≤3.5 — see `archive/mul1-trellis-spec.md`) are compile-time specialized on both tiers; out-of-contract rates fall to the runtime float `GemvFallback`, never a fault. |
| `EXL3_MOE_B70_ALLOCLOG` | Path to a fault-attribution log (USM alloc/free + per-forward geometry, wall-clock stamped). Correlate with `journalctl -k` "Faulted Address" lines to attribute GPU UA faults to a specific buffer - this found the cap_rows=512 stale-pool-pointer bug. Zero cost when unset. |

Works with `--moe_cpu_split` (dynamic, placement-profile driven) and `--moe_cpu_offload`.
`-mcs` values that used to be CPU-bound benefit most: the win scales with the share of
experts offloaded (see numbers below).

What you'll see in the log of the MoE worker child process:

```
[b70moe] device: Intel(R) Arc(R) Pro B70 Graphics
[b70moe] registered layer: E 448, B70 bytes so far 1.06 GB     (one per layer)
[b70moe] warm done rows 64 chunks 1024; B70 bytes ...          (pipeline pre-sizing)
```

and, on over-budget / device failure (never fatal):

```
[b70moe] registration out of device memory; layer stays on CPU
[b70] forward failed; layer pinned to CPU
```

If the plugin is missing or no SYCL GPU exists, everything falls back to the CPU worker
silently (`[b70] dlopen failed; falling back to CPU` / `[b70moe] no SYCL GPU: ...`).
Caveat: a *malformed* `ONEAPI_DEVICE_SELECTOR` value (e.g. `opencl:none`) aborts inside the
oneAPI runtime during dlopen, before any plugin code runs — the selector is parsed by
adapter static init. Use a valid value or unset it.

### Recipe: models whose expert set exceeds both GPUs (2.68/4.05bpw class)

```bash
EXL3_MOE_B70=1 EXL3_MOE_I8RING=1 EXL3_MOE_B70_SUB=auto \
EXL3_MOE_PINNED_ARENA=1   # -mcpa: page-locked arena + streamed prefill + promote-on-miss
```

The B70 holds the hot tier of *every* layer (fair budget share, sized at worker start);
`-mcpa` mechanisms then cooperate instead of stealing: streaming, promote-on-miss and the
placement sweep only take CPU-tier slots (prefill-priority deployments may trade ~10% prefill
for that protection - `EXL3_MOE_CPU_SWAP_TIER=0` reverts to the steal-friendly classic regime,
which measured the best raw prefill on 2.68bpw). On deep oversubscription (4.05bpw) `EXL3_MOE_B70_SUB=0.50
EXL3_MOE_STREAM_T=4` measured ~580-600 prefill / 54 decode (overlap adds 0-4%, noise-bound).
Measured (this box, 3090+B70):
2.68bpw 748 prefill / 53.3 decode (+43%/+12% vs the classic whole-layer tier),
4.05bpw ~590/54 (beats classic decode clearly, prefill parity-to-+1%; +160%/+45% vs CPU-only).

## Benchmarks

### End-to-end (needs the GPU + model; run from the repo root after `source sycl_moe/env.sh`)

```bash
# speed: decode tok/s at several context sizes + prefill tok/s
EXL3_MOE_B70=1 .venv/bin/python eval/perf.py -m <model_dir> -mcs 256 -max_length 2048 -cs 8192 -dr 2
# compare with the CPU worker by dropping EXL3_MOE_B70=1

# quality gate (this is how the port was validated; expect identical ppl to <0.3%):
.venv/bin/python        eval/ppl.py -m <model_dir> -mcs 384 -r 20 -l 2048   # CPU
EXL3_MOE_B70=1 .venv/bin/python eval/ppl.py -m <model_dir> -mcs 384 -r 20 -l 2048
```

Measured, this machine (Arc Pro B70 + RTX 3090, one model each):

| model | config | CPU worker | + B70 |
|---|---|---|---|
| Qwen3.8-Flash-Next-2.05bpw | `-mcs 256` | 68–70 t/s dec, ~1511 pre | **70–71 t/s, 1876 pre (+24%)** |
| Qwen3.8-Flash-Next-2.68bpw | `-mcs 448` | 40.2 t/s dec | **56.2 t/s (+40%)** |
| Qwen3.8-Flash-Next-4.05bpw | `-mcs 448` | 25.0 t/s dec | **51.0 t/s (+104%)** |
| ppl wikitext-2 (20×2048) | 2.05 / 2.68 / 4.05 | 3.96007 / 3.82400 / 3.73050 | 3.96836 / 3.82209 / 3.73007 |
| ppl qbench trace (8 rows, 15874 tok) | 2.05bpw `-mcs 384` | 1.479306 | 1.479269 |

The win is proportional to how much of the model the 3090 can't hold: at `-mcs 256` on
2.05bpw decode is not MoE-CPU-bound, at `-mcs 448` on 4.05bpw it completely is.

### Layer microbenchmark (standalone, no exllamav3 needed)

```bash
cd sycl_moe
icpx -fsycl -O3 -ffp-contract=off -foffload-fp32-prec-div moe_sycl.cpp bench_layer.cpp -o bench_layer
./bench_layer --e 12 --rows 1 --topk 10 --iters 50         # checks against fp32 host ref
./bench_layer --e 12 --rows 1 --topk 10 --iters 50 --v     # + per-kernel spans/gaps
./bench_layer --bits 2 --hb 1 ...                          # 2.5bpw tile family (K=5)
./bench_layer --bits 4 --hb 6 ...                          # 4.5bpw family (K2=14 fallback)
./bench_layer --gateless ...                               # relu2 gateless experts
./bench_layer --e 12 --rows 1 --topk 10 --act 1            # gelu-erf (0=silu default, 3=swiglu_oai)
EXL3_MOE_B70_INT8=1 ./bench_layer ... --i8trace            # int8 tier + per-stage integer verifier
                                                         # (stages B..G must all print OK)
```

Methodology note (cost us days, see `archive/measurement-discipline.md`): **never A/B with
`--v`** — SYCL event profiling inflates the 6-kernel pipeline ~40µs on this driver. Interleave
runs of the binaries and take min-of-3 on the unprofiled median.

### Plugin-ABI tools (run after ANY upload/register/change to the C ABI)

```bash
python3 test_arena_update.py ../xval_s   # byte-exact in-place install identities (T1..T3);
                                         # the only thing that exercises b70_update_expert -
                                         # tier guards mean model runs never install onto
                                         # registered layers
python3 test_arena_update.py /tmp/xval_gl # gateless too (xval_cpu.py --gateless --scalar;
                                         # without --scalar the ref carries the real 1.4e-2
                                         # AVX2-vs-scalar delta and 'rms 0.0138' is EXPECTED)
python3 regbench.py ./libb70moe.so 256 6 # synthetic E=256 registration throughput, no model
```

### Cross-validation against the real CPU extension

```bash
cd sycl_moe
.venv/bin/python xval_cpu.py --E 12 --rows 1 --topk 10 --bits 2 --hb 0 --outdir xval_s   # needs CUDA/ext
./bench_layer --load xval_s        # rms vs the extension's own output (expect ~1e-6)
.venv/bin/python bench_b70_py.py xval_s   # times the plugin C ABI on the saved layer
```

Notes:
- Run-to-run bitwise determinism does NOT hold on the GPU path: the expert combine in K6
  uses relaxed fp32 atomics, so summation order varies per launch. Effect measured over
  repeated 25-row wikitext passes: ppl spread < 1e-4 relative. Sampling-level comparisons
  (logit argmax drift) can occasionally flip a token, like any CUDA LLM backend.

## Design map (for hacking on it)

- `moe_sycl.{hpp,cpp}` — the pipeline kernels (prep_gu, gemv_gu, act+prep_d fused, gemv_d,
  gather; in coop float mode `CoopDownK` merges gemv_d+gather into one counter-fed launch)
  + host-side layer object. Weights are stored in the **native** mul1 tile layout,
  stream-repacked at upload so a GEMV thread reads a contiguous bit window
  (`repack_native_to_stream_words`, exact bit formulas documented in the header comment).
  Coop arrival counters live in the control blob (zeroed by its H2D and re-zeroed by K1
  on the render engine); same-launch cross-WG reads use device-scope relaxed atomic loads
  (`coop_load` - the annotated_ptr read_hint form never demonstrated L1 bypass here).
- `b70_lib.cpp` — the C ABI the worker dlopens (`b70_init/_register_layer_n/_forward/_warm/
  _free_layer/_update_expert`). Weights live in ONE device ARENA per layer with a regular
  per-expert block layout (registration = one threaded host fill + one H2D copy; a dynamic-
  placement install is an atomic in-place block overwrite - no free, no repoint). VRAM budget
  + rollback on that one allocation; scratch lives in the workspace pool shared across layers
  (rebound on every forward - never cache pool pointers per layer, see
  `archive/memory-and-registration.md` 'STALE POOL POINTER').
- Hooks on the exllamav3 side: `exllamav3_ext/cpu/moe_mul1.cpp` (`B70Backend`, forward
  redirect, native-layout swizzle gate) and one `int64_t b70` field in `moe_mul1.h`.
- `NOTES.md` — the distilled must-read: current state, measurement/verification rules, platform
  traps, standing decisions, ranked levers.
- `archive/` — the full debug/optimization log split by topic (`archive/INDEX.md` lists files and
  a symptom -> page lookup): tile bit-layout derivation, queue ordering bugs, the DPAS arc,
  placement campaigns, memory forensics, lab inventory.