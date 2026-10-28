# `notes/` — measurement scaffolding

Scratch harnesses and raw logs behind `doc/prep/`. Not library code; nothing here is imported by
`exllamav3`. Consolidated results live in the docs — this directory keeps the way there.

## Setup

```
source env.sh          # repo venv + CUDAHOSTCXX=g++-15 + /usr/local/cuda-13.2/bin on PATH
```

The system `gcc` is 16.2, which the installed nvcc refuses; the extension is built on demand by
`exllamav3/ext.py` on first import (a cold build takes ~20 min with ccache, a warm one ~15 s).

## Harnesses

| script | produces | used by |
|---|---|---|
| `geom.py` | handoff-region / slot / weight-ring geometry tables (`geom.txt`) | data-paths §1, measured-costs §1 |
| `scan_widths.py` | tile-width (bitrate) census per module class, from safetensors headers (`widths.txt`) | mul1-trellis §1 |
| `scan_mixed_rates.py` | per-layer bitrate uniformity check per model (catches mixed-rate layers) | mul1-trellis §1, README watch-outs |
| `verify_trellis.py` | the five format checks ([1] tail-biting, [2] NumPy-vs-`reconstruct`, [3] codebook, [4] packed-layout round trip, [5] int8 identity) | every claim in mul1-trellis |
| `bench_cpu_moe.py` | cold-expert CPU GEMV sweep vs rows and thread count | measured-costs §5 (`m_cpu_*.txt`) |
| `bench_handoff.py` | flags, pinned copies, decode loop (real + empty job), stage job, unswizzle | measured-costs §3, §4, §7 (`m_handoff_*.txt`) |
| `bench_link.py` | pinned H2D bandwidth and the negotiated PCIe gen/width, idle and under SM load | measured-costs §2 |
| `prof_e2e.py` | torch-profiler kernel breakdown of N decode steps and one prefill chunk | measured-costs §6, §7 (`m_prof_e2e*.txt`) |
| `run_e2e.sh` | `eval/perf.py` over named knob configs (`m_e2e_<cfg>.txt`) | measured-costs §8 |
| `run_profile_ab.sh` | controlled 2×2 of cold vs warm starting placement (`m_prof_ab_*.txt`, reference profile in `refprofile_q35.json`) | measured-costs §8.3 |
| `probe_handoff.py` | single-step walkthrough printer (debug aid for the fused issue/collect calls) | — |

Typical invocations (all take a model directory, e.g.
`/home/treo/projects/vendor/tabbyAPI/models/Qwen3.5-35B-A3B-3bpw-hq2`):

```
python bench_cpu_moe.py $M --experts 256 --rows 1,4,16,64 --threads 1,4,8,12,16 --iters 400
python bench_handoff.py $M --experts 256 --threads 15                  # everything
python bench_handoff.py $M --experts 256 --skip loop,empty --stage_threads 1
NO_MEMOPS=1 python bench_handoff.py $M --experts 256 --skip stage,unswizzle
python prof_e2e.py -m $M -cs 8192 -mcs 192 -decode 32 -prefill 2048
PERF_ARGS="-cs 8192 -chunk_size 4096 -max_length 2048 -dr 1" bash run_e2e.sh split192 streamT0
```

`run_e2e.sh` names: `split192`, `split192pa`, `split255`, `split255pa`, `layer20`, `layer40`,
`prof_split`, `streamdbg`, `nomemops`, `slots8`, `slotrows32`, `threads8`, `nostatic`, `streamT0`,
`streamT4`, `batch48`, `minrows`, `noswizzle`, `nowide`, `fusedT64`, `nobatchrecon`.

## Reading the logs

* `m_e2e_*.txt` end with the `eval/perf.py` result tables (`Length …` prefill, `Context …` decode).
  Lines with `-- handoff prof` / `-- moe_cpu prof` come from the **worker process** (shared stdout);
  `-- split prof [...]` and `-- stream ...` come from the parent.
* `m_e2e_prof_split.txt` is the profiler-enabled run: it is ~30% slower than the same configuration
  without profilers, which is itself a datum (see measured-costs §0, §5).
* Model loading prints one `-- CPU split experts (worker, dynamic): … [64..256) of 256` line per
  offloaded layer; those 40 lines are the cheapest check that the intended placement was reached.

## Known rough edges

* **Placement state persists between runs and contaminates comparisons.** Dynamic placement writes
  `~/.cache/exllamav3/expert_stats/<sha1(model_dir|E)>.json` at unload and reseeds from it at load;
  the key ignores split size and placement mode. `run_profile_ab.sh` shows the pattern for
  controlling it (move the file away, or restore a fixed reference copy before each run). Real-text
  effect measured in `m_ab_text_{cold,warm}.txt`: 5.87 vs 4.42 CPU picks per token.
* `prof_e2e.py` feeds random token ids, so its routing (and therefore how many experts cross
  `stream_t`) is not representative of real text — including the profile effect, which vanishes on
  uniform-random routing. Use `eval/perf.py` (wikitext) for anything placement-sensitive.
* `bench_handoff.py`'s `loop` section must issue and collect in pairs; issuing several jobs without
  collecting them deadlocks the stream by design (each issue waits its slot's `consumed` flag).
* `prof_e2e.py` feeds random token ids, so its routing is not representative of text; combine it
  with `EXL3_MOE_STREAM_DEBUG=1` and count the `batch L…` lines when byte totals matter
  (`m_prof_e2e_sd.txt` is that run).
* `bench_cpu_moe.py` sizes its own timing loop as `iters // max(1, rows/4)`; larger row counts do
  fewer iterations, so the low-row-count entries are the statistically stronger ones.