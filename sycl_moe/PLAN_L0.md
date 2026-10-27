# PLAN: native-L0 submission for the int8 decode chain (next big decode lever)

## Why
Decode jobs spend ~60 us of ~240 us wall in command-chain overhead (6 dependent
`queue::submit`s through UR->PI->L0, immediate-commandlist mode). Raw appends on the
queue's OWN immediate list measured 15-21 us for the same chain (labs t35-t37, commit
728d932e). Applied to 48 layers/token: +8-10% decode expected. Prefill barely cares
(host time hidden behind GPU work); the target is the rows<=8 slim path.

## Proven facts (do not re-derive)
- SYCL RT-JIT kernel handles DO NOT launch through `zeCommandListAppendLaunchKernel`
  (accepted, timestamps fire, memory untouched). Must ship OWN SPIR-V module.
- Own-module path proven end-to-end incl. nd_item builtins AND subgroup collectives:
  `icpx -fsycl -fsycl-targets=spir64 -save-temps -c k.cpp` ->
  `sycl-post-link k.bc -ir-output-only -spec-const=native -o tl` ->
  `llvm-spirv tl -o k.spv` -> `zeModuleCreate(IL_SPIRV)` on `get_native(context)` ->
  launch on `get_native(queue)`'s `ze_command_list_handle_t` (in-order immediate).
  (t37k.cpp / t37drive.cpp.)
- `zeCommandListAppendLaunchKernelWithArguments(list, k, group_count{x,y,z},
  group_size{x,y,z}, args, ...)` takes a flat `void**` arg array; local (SLM) size is a
  separate kernel-set-attribute or per-launch local-memory arg - mirror what the SYCL
  runtime passes: LAST kernel param is the local pointer for kernels using local_accessors.
- Level Zero headers installed: /usr/include/level_zero; link -lze_loader.

## Scope for v1 (gate: EXL3_MOE_I8L0=1, default off)
Int8 DECODE chain only (the one the slim path runs at rows 1-8 on registered layers):
  PrepQuantI8 (or K1+Q1 unfused), Gemv8<K2V,1,false> gu, K34 (act), Quant-d,
  Gemv8<K2V,1,false> down, K6 owner-gather. Float tier and fat/ring paths stay SYCL.
All six exist in moe_sycl.cpp already; keep them compiling into a dedicated TU
`moe_l0k.inl` instantiated ONLY for the slim widths (K2V 4/5/8), built by the plugin
build script into `libb70moe.spv` shipped next to the .so (locate via dladdr; if the
.spv is missing, silently stay on SYCL - same posture as the .so fallback).

## Integration sketch
1. `sycl_moe/build_plugin.sh`: add SPV step + copy .so and .spv together.
2. `moe_sycl.cpp`: `struct L0Chain { ze_module_handle_t mod; ze_kernel_handle_t k[6]; }`
   created lazily per (k2v, gated) on first forward; arg arrays are POD-stable per layer
   (params live in MoeSyclLayer): PRE-BUILD the arg buffer once at registration from the
   device-pointer inventory (they never move: buffers are per-layer persistent, sized in
   init; growth paths (ensure_capacity) must REBUILD the arg buffer on realloc - audit
   every pointer that can move! that is the main footgun).
3. forward(): replace the six submits with appends on the native list + ONE flush; keep
   the returned event as a ze_event synced to the final append (b70_lib waits on it).
4. Ordering: appends on one in-order list are sequential: the `depends_on(dep)` dance
   (external x-upload event) becomes `AppendBarrierAndWaitEvents`? Simpler: x-upload
   memcpy is already appended on the SAME queue (q->memcpy USM->USM) - verify it lands
   on the same immediate list (it does when using the native queue handle); then plain
   append order suffices.
5. Gates: `--i8trace` bit-exact battery + t32/t33/t41 + 2.05/4.05 decode A/B (paired,
   decode deltas >=1 t/s are trustworthy per NOTES noise discipline).

## Known traps (this session's tally)
- exec_mu already serializes warm/forward/update - keep holding it across the whole
  append+flush (same contract as today).
- Never trust piped build rc; check logs. Numbers: verify the CSV exists.
- q.copy from pageable host mem can SEGV in standalone labs (q.memcpy fine).
- Spec constants: the slim kernels use none (templates only) - KEEP it that way in
  moe_l0k.inl or the arg array shifts.
- `reqd_sub_group_size(16)` metadata: pass group_size {16,1,1} exactly; verify with a
  host-checked fold before believing perf (t37 protocol).