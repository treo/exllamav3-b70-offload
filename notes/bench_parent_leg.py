#!/usr/bin/env python3
"""bench_parent_leg.py - measure the PARENT's per-layer decode cost on the 3090, past b=1.

Why this exists: plan_parent_budget.py charges the parent a single inherited constant, t0 = 250 us/layer, and its
placement verdicts ("binding returns to the parent at b<=8") turn on how that number moves with batch and
context. It had only ever been taken at b=1, and the chapter had assumed this box could not measure it. It can:
the 3090 is in the machine (PCI 0c:00.0), exllamav3_ext is built with CUDA, and tests/testlib/moe.py already
knows how to assemble the real fused-MoE kernel's argument list. So the expert leg here is ext.exl3_moe itself,
not a matmul proxy.

Legs measured, per (batch, ctx):
  expert   the parent's own expert work: ext.exl3_moe over the assignments a decode step produces at that
           batch (A = b*topk rows spread across topk*union[b] distinct experts, Qwen3.8 shapes H=2560 I=640
           K=2.5-ish rates via testlib.rand_experts). ALSO the calibration for the planner's S_g/rate_g term:
           if the kernel is slower than bytes/rate_g, a byte rate is the wrong currency for the parent too.
  attn     one full_attention layer (24 q-heads x 256, 2 kv-heads, ctx) through SDPA fp16, x12 layers.
  linstate the 36 linear_attention layers have no KV cache but a recurrent state per sequence; that state is
           read and written every layer, so it is charged as traffic at the measured device rate. PROXY: the
           real kernel's arithmetic is not modelled, only its memory.
  stream   non-expert weights streamed per layer (attention projections, shared expert, router, norms) from the
           shard census the planners already use, at the measured rate.
  rate     direct measurement of read bandwidth, to replace the inherited 936 GB/s with a number or confirm it.

Deliberately NOT modelled: sampler/lm_head (per token, not per layer), CUDA graph and launch overheads of the
rest of the network, and any of the CPU-side work. The composed number is therefore a floor for the parent, and
it is compared against the inherited 250 us/layer as a credibility check before anyone ships it.

Usage: python3 notes/bench_parent_leg.py [--batches 1,2,4,8,16] [--ctx 4096,16384] [--iters 30]
"""
import argparse
import json
import os
import sys
import time

import torch

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "tests"))

from exllamav3.ext import exllamav3_ext as ext                       # noqa: E402
from testlib.moe import contiguous_layout, expert_ptr_tables, experts_to, moe_buffers  # noqa: E402
from testlib.exl3 import rand_experts                                # noqa: E402

CKPT = "/home/treo/projects/vendor/tabbyAPI/models/Qwen3.8-Flash-Next-exl3-2.68bpw_h6_ng8"
UNION = {1: 1.0, 2: 1.99, 4: 3.88, 8: 7.27, 16: 13.12, 32: 21.91}
CAP = 128


def timed(fn, iters, warm=5):
    for _ in range(warm):
        fn()
    torch.cuda.synchronize()
    t0 = time.perf_counter()
    for _ in range(iters):
        fn()
    torch.cuda.synchronize()
    return (time.perf_counter() - t0) / iters * 1e6          # us


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--batches", default="1,2,4,8,16")
    ap.add_argument("--ctx", default="4096,16384")
    ap.add_argument("--iters", type=int, default=30)
    a = ap.parse_args()

    cfg = json.load(open(os.path.join(CKPT, "config.json")))
    tc = cfg.get("text_config", cfg)
    H = tc["hidden_size"]; nl = tc["num_hidden_layers"]
    lt = tc["layer_types"]; n_full = lt.count("full_attention"); n_lin = lt.count("linear_attention")
    topk = tc["num_experts_per_tok"]; I = tc["moe_intermediate_size"]
    qh, kvh, hd = tc["num_attention_heads"], tc["num_key_value_heads"], tc["head_dim"]
    E_all = tc["num_experts"]
    dev = torch.device("cuda:0")
    print(f"# {torch.cuda.get_device_name(0)}  H={H} I={I} topk={topk} layers={nl} ({n_full} full / {n_lin} linear)"
          f"  q/kv heads {qh}/{kvh} head_dim {hd}")

    # --- rate: what a pure read costs on this card ---------------------------------------------------------
    # Repeated, min-of-N, and the spread is printed: a single sample of this moved 638 -> 850 GB/s between runs
    # of identical code, which is exactly the trap the B70 chapter keeps documenting (LESSONS 46/54). Only the
    # repeat-stable part of the number is quotable.
    big = torch.empty((256 << 20) // 2, dtype=torch.half, device=dev)      # 256 MiB, exceeds L2 comfortably
    rates = []
    for _ in range(3):
        s = big.sum()
    torch.cuda.synchronize()
    for _ in range(7):
        t0 = time.perf_counter()
        for _ in range(10):
            s = big.sum()
        torch.cuda.synchronize()
        rates.append((big.numel() * 2 * 10) / (time.perf_counter() - t0) / 1e9)
    rate = max(rates)                                                      # best-case = what a kernel can hope for
    print(f"# measured read bandwidth (fp16 sum, 256 MiB): best {rate:.0f} GB/s, all {sorted(int(r) for r in rates)}"
          f"   (planner assumes 936)")

    # --- expert leg: the real kernel ----------------------------------------------------------------------
    gen = torch.Generator().manual_seed(5)
    ex_all = experts_to(rand_experts(min(E_all, 208), H, I, 3, gen), dev)
    bufs = moe_buffers(H, I, CAP, dev)
    # Pointer tables must cover exactly the experts the call references, so they are rebuilt per batch from a
    # prefix of the expert set (cheap: tables, not weights).
    def tables_for(n):
        return expert_ptr_tables({p: ex_all[p][:n] for p in ex_all}, dev)
    bufs = moe_buffers(H, I, CAP, dev)
    # Non-expert weight traffic per layer, from the census the planners use (Qwen3.8: 4.05 GiB of streamed
    # non-expert weights over 48 layers). Recomputed here so the number printed is this run's, not a remembered one.
    rd_layer_mib = 4.05 * 1024 / nl
    lin_layer_mib = 108.0 / n_lin if n_lin else 0.0                        # state per sequence / linear layers

    exp_us = {}
    for b in [int(x) for x in a.batches.split(",")]:
        A = b * topk
        distinct = min(len(ex_all["g"]), max(1, round(topk * UNION.get(b, UNION[max(UNION)]))))
        base, rem = divmod(A, distinct)
        counts = [base + (1 if i < rem else 0) for i in range(distinct)]
        counts = [c for c in counts if c > 0]
        distinct = len(counts)
        tabs = tables_for(distinct)
        token_sorted, expert_count, _ = contiguous_layout(counts, dev)
        weight_sorted = (torch.rand((A,), generator=gen) * 0.5 + 0.5).half().to(dev)
        y = (torch.randn((A, H), generator=gen) * 0.05).half().to(dev)
        out = torch.zeros((A, H), dtype=torch.float, device=dev)
        f = lambda: ext.exl3_moe(y, out, expert_count, token_sorted, weight_sorted, *bufs, 0, 3, 3, 3,
                                 *tabs["g"], *tabs["u"], *tabs["d"], False, True, False, True, False, True,
                                 0.0, -1, None, None, 1, CAP, 16)
        us = timed(f, a.iters)
        bytes_experts = distinct * (3 * H * I * 3 / 8) / 2**20              # 3 projections, K=3 bits/weight
        exp_us[b] = (us, distinct, A, bytes_experts)

    # --- attention leg: DECODE shape, i.e. one new query row per sequence against the cached KV ------------
    # (The first version of this measured q = [b, heads, ctx, hd], which is prefill: it returned 114 ms per
    # layer and would have poisoned every composed number below. Decode reads KV, it does not recompute it.)
    att_us = {}
    for b in [int(x) for x in a.batches.split(",")]:
        for ctx in [int(x) for x in a.ctx.split(",")]:
            q = torch.randn((b, qh, 1, hd), dtype=torch.half, device=dev) * 0.05
            k = torch.randn((b, kvh, ctx, hd), dtype=torch.half, device=dev) * 0.05
            v = torch.randn((b, kvh, ctx, hd), dtype=torch.half, device=dev) * 0.05
            kw = {}
            try:
                torch.nn.functional.scaled_dot_product_attention(q, k, v, is_causal=False, enable_gqa=True)
                kw["enable_gqa"] = True
            except TypeError:
                k = k.repeat_interleave(qh // kvh, dim=1)
                v = v.repeat_interleave(qh // kvh, dim=1)
            o = torch.nn.functional.scaled_dot_product_attention(q, k, v, is_causal=False, **kw)
            us = timed(lambda: torch.nn.functional.scaled_dot_product_attention(q, k, v, is_causal=False, **kw),
                       a.iters)
            kv_mib = 2 * b * kvh * ctx * hd * 2 / 2**20                     # k and v, fp16, one layer
            print(f"   attn decode b={b:2d} ctx={ctx:6d}: {us:6.1f} us/layer   "
                  f"(KV {kv_mib:6.2f} MiB -> {kv_mib * 2**20 / (us * 1e-6) / 1e9:5.0f} GB/s implied)"
                  + ("" if kw else "   [no enable_gqa: kv materialised, traffic inflated]"))
            att_us[(b, ctx)] = us
            del q, k, v, o
            torch.cuda.empty_cache()

    print(f"\n{'b':>3} {'A':>4} {'exp':>4} | {'expert us':>10} {'GiB/s impl':>11} | {'us/layer bytes/rate':>20} "
          f"| {'full-attn us (ctx 4k / 16k)':>28} | {'stream us':>10} {'linstate us':>12}")
    for b in sorted(exp_us):
        us, distinct, A, mib = exp_us[b]
        impl = mib * 2**20 / (us * 1e-6) / 1e9
        byterate_us = mib * 2**20 / (rate * 1e9) * 1e6
        a4k = att_us.get((b, 4096), 0) * n_full
        a16k = att_us.get((b, 16384), 0) * n_full
        stream = rd_layer_mib * 2**20 / (rate * 1e9) * 1e6
        lin = (lin_layer_mib * b * 2) * 2**20 / (rate * 1e9) * 1e6          # read + write of state, per layer
        print(f"{b:3d} {A:4d} {distinct:4d} | {us:10.1f} {impl:11.0f} | {byterate_us:20.1f} "
              f"| {a4k:12.1f} {a16k:13.1f} | {stream:10.1f} {lin:12.1f}")

    print("\nREADING THIS")
    print("  'expert us' is the real ext.exl3_moe kernel on Qwen3.8 shapes; 'us/layer bytes/rate' is what the")
    print("  planner WOULD have charged for the same bytes. Their ratio is the error in using a byte rate for")
    print("  the parent's expert leg. 'full-attn us' is summed over the 12 full-attention layers; 'linstate'")
    print("  charges the 36 linear layers' recurrent-state traffic as memory only (a PROXY - the kernels'")
    print("  arithmetic is not modelled), and 'stream' is non-expert weight traffic at the measured rate.")
    print("\nComposed per-layer parent time at ctx=4096, averaged over the real 12-full/36-linear mix"
          " (expert leg + that layer's attention cost + streamed non-expert weights):")
    for b in sorted(exp_us):
        attn_per_layer = (att_us.get((b, 4096), 0) * n_full) / nl            # 12 of 48 layers carry full attn
        stream = rd_layer_mib * 2**20 / (rate * 1e9) * 1e6                   # non-expert weights, per layer
        lin = (lin_layer_mib * b * 2) * 2**20 / (rate * 1e9) * 1e6           # linear-state read+write, per lin layer
        lin_per_layer = lin * n_lin / nl
        tot = exp_us[b][0] + attn_per_layer + stream + lin_per_layer
        print(f"   b={b:2d}: {tot:7.1f} us/layer   [expert {exp_us[b][0]:6.1f} + attn {attn_per_layer:5.1f}"
              f" + stream {stream:5.1f} + linstate {lin_per_layer:5.1f}]"
              f"   (inherited constant for b=1: 250 us)")
    print("\nNot modelled: sampler/lm_head, CUDA graph and launch overheads elsewhere in the network, any CPU")
    print("work. Treat the composed figure as a floor, and check it against the inherited 250 us before use.")


if __name__ == "__main__":
    main()