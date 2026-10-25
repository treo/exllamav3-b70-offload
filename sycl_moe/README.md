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

## Requirements

- Intel Arc Pro B70 (or Xe2) GPU, `xe` kernel driver, compute-runtime ≥ 26.x
- oneAPI Base Toolkit with `icpx` (developed on 2026.2). Builds use `-O3` (verified:
  bit-identical results, ~2.6% faster synthetic decode; an earlier '-O3 crashes icpx'
  note turned out unreproducible — see NOTES if the compiler ever dies on these TUs,
  fall back to `-O2` and re-file).
- Linux (the plugin hooks are `__linux__`-only; nothing changes on other platforms)

## Build

```bash
source sycl_moe/env.sh          # oneAPI setvars + torch-JIT env recipe + EXL3_MOE_B70_LIB
cd sycl_moe
icpx -fsycl -O3 -fPIC -shared b70_lib.cpp moe_sycl.cpp -o libb70moe.so \
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
| `EXL3_MOE_B70_BUDGET` | Fraction of GPU VRAM the plugin may hold weights in (default `0.70`). Layers past the budget register-fail and stay on CPU — this is safe and automatic. |
| `MOE_NSL=0..8` | Override the split-K degree of the GEMV kernels (default: auto per matrix class). Tuning knob for experiments. |

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
icpx -fsycl -O3 moe_sycl.cpp bench_layer.cpp -o bench_layer
./bench_layer --e 12 --rows 1 --topk 10 --iters 50         # checks against fp32 host ref
./bench_layer --e 12 --rows 1 --topk 10 --iters 50 --v     # + per-kernel spans/gaps
./bench_layer --bits 2 --hb 1 ...                          # 2.5bpw tile family (K=5)
./bench_layer --bits 4 --hb 6 ...                          # 4.5bpw family (K2=14 fallback)
./bench_layer --gateless ...                               # relu2 gateless experts
./bench_layer --e 12 --rows 1 --topk 10 --act 1            # gelu-erf (0=silu default, 3=swiglu_oai)
```

Methodology note (cost us a day, see NOTES.md): **never A/B with `--v`** — SYCL
event profiling inflates the 6-kernel pipeline ~40µs on this driver. Interleave runs of
the binaries and take min-of-3 on the unprofiled median.

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

- `moe_sycl.{hpp,cpp}` — the six kernels (prep_gu, gemv_gu, act+prep_d fused, gemv_d,
  gather) + host-side layer object. Weights are stored in the **native** mul1 tile layout,
  stream-repacked at upload so a GEMV thread reads a contiguous bit window
  (`repack_native_to_stream_words`, exact bit formulas documented in the header comment).
- `b70_lib.cpp` — the C ABI the worker dlopens (`b70_init/_register_layer/_forward/_warm/
  _free_layer`), VRAM budget + rollback, workspace pool shared across layers.
- Hooks on the exllamav3 side: `exllamav3_ext/cpu/moe_mul1.cpp` (`B70Backend`, forward
  redirect, native-layout swizzle gate) and one `int64_t b70` field in `moe_mul1.h`.
- `NOTES.md` — the full debug/optimization log: tile bit-layout derivation, the queue
  ordering bugs, RNG gotchas, device-OOM governance, tuning table.