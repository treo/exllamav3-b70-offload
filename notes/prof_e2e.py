"""Kernel-level breakdown of one decode step and one prefill chunk with the CPU MoE split active.

    python notes/prof_e2e.py -m <model_dir> [-mcs 192] [-cs 8192] [--decode 32] [--prefill 2048]

Accepts every model_init argument (so -mcs/-mcl/-mcpa/-mct work). Prints, per phase, the CUDA
kernels/copies that dominate by self device time (total, calls, us/call) plus the host-side
enqueue cost of the MoE/handoff calls. Complements EXL3_SPLIT_PROF and EXL3_MOE_HANDOFF_PROF,
which measure the handoff segments but not the GPU work that runs between them.
"""
import os
import sys

import torch

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from exllamav3 import model_init                      # noqa: E402
from torch.profiler import ProfilerActivity, profile  # noqa: E402


def report(prof, title, top = 20):
    rows = []
    for e in prof.key_averages():
        cuda = float(getattr(e, "self_device_time_total", 0) or 0)
        if cuda > 0:
            rows.append((cuda, e.count, e.key))
    rows.sort(reverse = True)
    total = sum(r[0] for r in rows)
    print(f"\n### {title}: {total/1e3:.2f} ms device time, {len(rows)} distinct activities")
    print(f"{'ms total':>9} {'%':>6} {'calls':>7} {'us/call':>9}  key")
    for cuda, count, key in rows[:top]:
        print(f"{cuda/1e3:9.3f} {100*cuda/total:6.2f} {count:7d} {cuda/max(count,1):9.2f}  "
              f"{key[:86]}")
    return total


@torch.inference_mode()
def main():
    import argparse
    parser = argparse.ArgumentParser(allow_abbrev = False)
    model_init.add_args(parser, default_cache_size = 8192, default_autosplit_max_batch_size = 1,
                        default_chunk_size = 4096)
    parser.add_argument("-decode", type = int, default = 32)
    parser.add_argument("-prefill", type = int, default = 2048)
    args = parser.parse_args()

    model, config, cache, tokenizer = model_init.init(args, quiet = True, progress = False)

    ids = torch.randint(1000, 200000, (1, max(args.prefill, args.decode) + 64), device = "cpu")
    is_recurrent = model.caps.get("recurrent_states", False)

    def run_decode(i):
        rec = [cache.get_test_state(i)] if is_recurrent else None
        params = {"cache": cache, "attn_mode": "flash_attn", "past_len": i, "pos": i,
                  "batch_shape": (1, ((i + 512 + 255) // 256) * 256), "recurrent_states": rec}
        model.forward(ids[:, i:i + 1], params)
        if rec:
            rec[0].free()

    def run_prefill():
        rec = [cache.get_test_state(0)] if is_recurrent else None
        params = {"cache": cache, "attn_mode": "flash_attn", "past_len": 0, "pos": 0,
                  "batch_shape": (1, max(args.prefill, 256)), "recurrent_states": rec}
        model.forward(ids[:, :args.prefill], params)
        if rec:
            rec[0].free()

    for i in range(8):
        run_decode(i)
    torch.cuda.synchronize()
    with profile(activities = [ProfilerActivity.CPU, ProfilerActivity.CUDA]) as pdec:
        for i in range(8, 8 + args.decode):
            run_decode(i)
        torch.cuda.synchronize()
    dec_ms = report(pdec, f"decode x{args.decode}")
    print(f" -> {dec_ms/1e3/args.decode:.3f} ms of device time per token")

    host = {}
    for e in pdec.key_averages():
        h = float(getattr(e, "self_cpu_time_total", 0) or 0)
        k = e.key
        if h > 0 and any(t in k.lower() for t in ("moe_split", "memcpy", "moe", "copy_", "flag",
                                                  "cudaLaunch", "StreamWait", "StreamWrite")):
            host[k] = (h, e.count)
    print("### decode: host-side cost of the handoff / MoE calls")
    for k, (h, c) in sorted(host.items(), key = lambda kv: -kv[1][0])[:16]:
        print(f"{h/1e3:9.3f} ms {c:7d} {h/max(c,1):9.2f} us/call  {k[:70]}")

    for _ in range(1):
        run_prefill()
    torch.cuda.synchronize()
    with profile(activities = [ProfilerActivity.CPU, ProfilerActivity.CUDA]) as ppre:
        run_prefill()
        torch.cuda.synchronize()
    pre_ms = report(ppre, f"prefill {args.prefill} rows", top = 22)
    print(f" -> {args.prefill / (pre_ms/1e6):.0f} tok/s of device time "
          f"({pre_ms/1e3:.1f} ms for {args.prefill} rows)")


if __name__ == "__main__":
    main()