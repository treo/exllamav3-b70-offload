# `notes/b70/` — Arc Pro B70 capability probes

Dev scaffolding for the B70 MoE-offload port (design in [`../../doc/port/README.md`](../../doc/port/README.md)).
Nothing here is library code. Every number below was measured on this box on 2026-10-28 with
oneAPI 2026.2 (`icpx -fsycl`), Level Zero 1.18, driver 26.35 (`neovega` on the `xe` driver), an
Arc Pro B70 (BMG-G31, 32 Xe cores / 256 vector engines, 31.9 GiB) behind a PCIe switch at
`0000:0f:00.0`, next to an RTX 3090 at `0000:0c:00.0` on a Ryzen 9 5950X.

Build everything, then run the Python probe with the repo venv as well:

```
bash build.sh                                     # setvars.sh is sourced inside
source ../env.sh && python -u probe_cross.py      # needs torch + exllamav3_ext (CUDA)
```

Each probe's raw output is kept next to it (`out_*.txt`) and is what the tables below quote. They
were re-run after the fact to confirm reproducibility: the flag-poll job cost came back at 5.0–6.3 µs
across runs, the 1 MiB DMA at 13.1 GB/s, and both cross-vendor probes at their recorded pass counts.

| file | what it answers |
|---|---|
| `probe_transport.cpp` | device properties; pinned↔device copy bandwidth vs size; what a submission costs when completion is taken with `.wait()`; what a kernel paying attention to host memory costs |
| `probe_notify.cpp` | the same job shapes completed by **polling a flag the device wrote** instead of `.wait()` — the number the protocol actually pays |
| `probe_doorbell.cpp` | the minimal correct parked-kernel poll loop (three mechanisms, one work-item) |
| `probe_resident.cpp` | resident engine sizing: groups × lanes × poll backoff × payload, with SIMD-uniform polling |
| `b70_shim.cpp` + `probe_cross.py` | cross-vendor sharing: one page-locked region used by the 3090 *and* the B70, in both directions, including stream memops (8/9 — the one failure is by design: `cudaHostRegister` refuses xe-pinned memory, `LESSONS` 8) |
| `probe_crossproc.py` | the same, with the B70 engine in a **child process** on a `multiprocessing.shared_memory` segment the parent registered with CUDA — 10/10, so the engine may be a separate process |
| `probe_stores.cpp`, `probe_stores2.cpp`, `probe_unreg.cpp` | which store pattern actually reaches host memory (answer: plain stores do, 100/100; `sycl::atomic_ref` on a registered pointer does not, and costs the device) |
| `probe_coherency.cpp` | the disproved theory: it is not CPU-vs-GPU cache staleness (kept because the reasoning that led to it is the useful part) |
| `probe_rates.cpp` | what the card sustains on the **real decode tile walk**: native vs banded layout, no-arithmetic vs realistic arithmetic density, scattered vs clustered work-item ordering; plus the four measurement traps this probe had to overcome (see its header and `LESSONS` 15) |
| `plan_placement.py` | joins the safetensors census to the **real per-layer expert-selection counts** persisted by dynamic placement and answers, per model and per home-size: `h` (device-resident pick share), `\|res\|` (the migration set), one-time `fill` seconds, `σ`, and the CPU residue in ms/token (`out_placement.txt`) |

## The measured facts that shape the design

| quantity | B70 here | CUDA/3090 reference (`doc/prep/measured-costs.md`) |
|---|---|---|
| pinned ↔ device, 256 MiB | **14.4 GB/s** both directions | 13.3 GB/s (Gen4 ×8) |
| pinned ↔ device, 1 MiB | 13.1–13.3 GB/s | — |
| pinned ↔ device, 128 KiB | 7.7–8.5 GB/s | — |
| sysfs link state (idle *and* under load) | reports `2.5 GT/s x1` — **wrong**, ignore it | trains to Gen4 ×8 |
| job = submit + `.wait()` | **24.8 µs** | `cudaMemcpy`+sync, same order |
| job = submit + flag polled by host | **5.0–6.3 µs** (empty kernel) | handshake round trip 6.4 µs (memops) |
| 16 KiB in via DMA, then flag | 7.6–8.9 µs | `copy_` 3.5–4.7 µs |
| 16 KiB in via kernel loads, 4096 lanes | 8.1–10.7 µs | — |
| 16 KiB in via kernel loads, 1 dependent lane chain | **258–283 µs** | — |
| 16 KiB out via kernel stores + flag | 7.0–9.0 µs | collect kernel 4.0 µs |
| resident kernel doorbell round trip (1 poller, fenced) | **3.2 µs** (mean, 200 rounds; best 2.8) | memop round trip 6.4 µs |
| board power at idle (no context) | 14.6 W | — |
| board power idle *with a live SYCL context* | 45.6 W | — |
| power cap | 275 W (`power1_cap`), energy counter in µJ | — |
| `cudaHostRegister` on `sycl::malloc_host` memory | **fails** (`invalid argument`) | — |
| `sycl::atomic_ref` (any scope) on a `register_host_memory` pointer | **device lost** (`UR_RESULT_ERROR_DEVICE_LOST`); plain stores and fenced volatile stores are fine | — |
| engine in a child process, region registered in both | **works**: kernel payload visible to parent and to a 3090 DMA, 3090 memop visible to a kernel in the child | — |
| `register_host_memory` on CUDA-pinned memory | **works**, kernel reads+writes it, 3090 still DMAs it | — |
| 3090 `cuStreamWriteValue32` → B70 kernel sees it | **works** | — |
| B70 kernel store → 3090 `cuStreamWaitValue32` retires | **works** (plain volatile store + `sycl::atomic_fence(acq_rel, system)`) | — |
| device | 256 CUs reported, SG 16/32, SLM 128 KiB, 1024 max WG | — |
| **decode tile walk, native order** | **132–292 GB/s** scattered (Qwen3.8), **132–260** (GLM) — 22–48 % of 608; the spread is working-set size, not code | single-point rates are not card constants: `out_rates_footprint.txt` |
| same, consecutive work-items on consecutive tiles | **216–558 GB/s**; `LOCALITY payoff` **1.08–1.99×**, never negative | the CPU's band-8 repack exists for this reason; here the GPU analogue is grid order |
| same tiles, banded/repacked order | **0.96–1.05×** vs native, no consistent sign, and the probe's configuration variance exceeds the effect → E4c re-tests it in situ | band-2/band-8 + planar is worth ~20 % on x86 |
| mul1 decode arithmetic at real density (+47 lane-inst per 128 B of stream) | **−0.1 %** (GLM) to **−4.4 %** (Qwen3.8) of bandwidth at 1 GiB; up to **−14 %** at a 64 MiB footprint | decode is bandwidth-bound, with less margin at small footprints |
| hardware int8 dot vs manual byte-sum | **0.2–0.4 %** apart over three independent runs: not measurable | `vpdpbusd` vs `vpmaddubsw` fallback is a real gap on x86 |
| accumulator dependency | splitting into 8 chains is **1.2–1.4 % slower**, so the density cost is instruction count / register pressure, not latency | R9 exists to kill that explanation |
| routing breadth (from real selection counts) | Qwen3.8@2.68: 97.6 % of picks in 411/512 experts; GLM: 70.8 % in 91/288 (effective support 213–231) | the profile is a decayed cumulative, so both are upper bounds |

Read as: the B70's link is not the problem (it is a shade faster than the 3090's on this box),
and its compute is not the problem either (roughly 10x the CPU worker's expert-read rate). Two things
are load-bearing. The first is **how a job is published and how completion is observed**: anything
that costs 24 µs (`.wait()`, or a second `register_host_memory` per job) will dominate a 25 µs compute
job, while 5 µs (flag-poll) or 3 µs (resident doorbell) hides behind the parent's ~165 µs/layer of
decode work. The second is **memory ordering inside the card**: the same bytes read at 287 or at
490 GB/s depending on how work-items map to tiles, which is a bigger effect than any layout choice
and is why `doc/port/b70-kernels.md` §3a is normative rather than advisory.
