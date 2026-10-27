#!/usr/bin/env python3
"""Prefill bench: load the model ONCE, then time repeated prefill forwards of fixed length.

Motivation: eval/perf.py's 4096 figure is derived (one 2048-row forward minus half the
measured 2048 time) and every arm costs a fresh ~70 s model load. This harness measures the
thing directly - wall time of a single `rows`-row prefill forward, min/median over reps - and
stamps every rep with wall-clock time so an external link/B70 monitor (mon.sh) can be
aligned to the timed window.

  python pb.py -m <model> -mcs 256 -ngr -mct 15 -mcpa -lens 4096 -reps 5
  python pb.py ... -lens 1024,2048,4096            # several lengths, interleaved by round
  PB_TAG=mytag python pb.py ...                    # label the REP lines

Output lines (grep these):
  PB len=<n> rep=<i> tok_s=<x> sec=<t> t=<epoch>     one per timed rep
  PB_RESULT len=<n> min=<x> med=<y> reps=<k>         per-length summary
Numbers are NOT interchangeable with perf.py's (different past_len and no derived-half);
use them for A/B, and confirm any win with perf.py before writing it down.
"""
import sys, os, time, argparse
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import torch
from exllamav3.util.misc import Timer, cuda_sync_active
from exllamav3 import model_init

TAG = os.environ.get("PB_TAG", "pb")


@torch.inference_mode()
def main(args):
    import eval.perf as perfmod
    model, config, cache, tokenizer = model_init.init(args)
    perfmod.load_workload_ids(tokenizer, args.max_needed)
    bpw_layer, bpw_head, vram_bits = model.get_storage_info()
    print(f"PB model {args.model_dir} bitrate {bpw_layer:.2f} bpw", flush = True)

    lens = [int(x) for x in args.lens.split(",")]
    is_recurrent = model.caps.get("recurrent_states", False)

    def one(length, offset):
        recurrent = [cache.get_test_state(0)] if is_recurrent else None
        params = {
            "attn_mode": "flash_attn",
            "cache": cache,
            "past_len": 0,
            "batch_shape": (1, max(length, 256)),
            "recurrent_states": recurrent,
        }
        model.prefill(perfmod.workload_ids(offset, length), params)
        cuda_sync_active()
        if is_recurrent:
            recurrent[0].free()

    # Warm the shapes (CUDA graphs, autotune, tier guards) then measure. Offset advances per
    # rep so no replayed pattern is measured and routing statistics stay realistic.
    for length in lens:
        one(length, 0)
    torch.cuda.synchronize()
    results = {l: [] for l in lens}
    for rep in range(args.reps):
        for length in lens:
            off = (rep + 1) * (args.max_needed // 2) + rep * 613
            cuda_sync_active()
            t0 = time.time()
            with Timer() as t:
                one(length, off)
            rate = length / t.interval
            results[length].append(rate)
            print(f"PB len={length} rep={rep} tok_s={rate:.2f} sec={t.interval:.4f} "
                  f"t={t0:.3f} tag={TAG}", flush = True)
    for length in lens:
        r = sorted(results[length])
        print(f"PB_RESULT len={length} min={r[0]:.2f} med={r[len(r)//2]:.2f} max={r[-1]:.2f} "
              f"reps={len(r)} tag={TAG}", flush = True)

    if args.profile:
        # Diagnosis only (sycl_moe/NOTES.md measurement rule 2: never A/B under a profiler).
        # Kineto gives per-kernel device time + gaps on the 3090; the trace JSON opens in
        # ui.perfetto.dev for the timeline view.
        from torch.profiler import profile as kprof, ProfilerActivity
        length = lens[-1]
        one(length, 7919)   # keep the shape warm inside the profiler region's preamble
        torch.cuda.synchronize()
        with kprof(activities = [ProfilerActivity.CPU, ProfilerActivity.CUDA],
                   record_shapes = False, profile_memory = False) as prof:
            one(length, 8101)
            torch.cuda.synchronize()
        out = f"/tmp/pb_prof_{TAG}.json"
        prof.export_chrome_trace(out)
        ka = prof.key_averages()
        print(f"PROF trace -> {out}")
        print(ka.table(sort_by = "self_cuda_time_total", row_limit = args.top, max_name_column_width = 60))
        tot = sum(e.self_device_time_total for e in ka)
        print(f"PROF sum of device kernel+memcpy time {tot/1e3:.1f} ms over a {length / 1:.0f}-row prefill")
    print(f"PB_DONE tag={TAG}", flush = True)


if __name__ == "__main__":
    ap = argparse.ArgumentParser(allow_abbrev = False)
    model_init.add_args(ap, default_cache_size = 32768, default_autosplit_max_batch_size = 1,
                        default_chunk_size = 4096)
    ap.add_argument("-lens", "--lens", default = "4096", help = "comma-separated row counts")
    ap.add_argument("-reps", "--reps", type = int, default = 5)
    ap.add_argument("-max_needed", "--max_needed", type = int, default = 40000,
                    help = "tokens of workload stream to prepare")
    ap.add_argument("-prof", "--profile", action = "store_true",
                    help = "after the timed reps, profile one rep of the last length (kineto)")
    ap.add_argument("-top", "--top", type = int, default = 30, help = "rows in the profiler table")
    main(ap.parse_args())