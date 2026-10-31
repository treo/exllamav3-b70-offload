#!/usr/bin/env python3
"""Measure the parent's REAL per-layer decode cost with the engine's own code, to settle the 122-vs-257 us gap.

    source notes/env.sh
    python3 notes/bench_engine_step.py -m <ckpt> -mcs 255 -cs 8192 [--ctx 4096] [--tokens 64] [--lmhead]

Why this exists. Two numbers claim to be the 3090's non-expert cost per MoE layer at b=1: 122 us, composed
bottom-up from separate benches of attention (SDPA), streamed non-expert weights and recurrent-state traffic
(out_parent_leg.txt), and 257 us, what plan_concurrency.py gets after calibrating a `fixed` overhead so the
parent bill reproduces the inherited ~250 us/layer window. LESSONS 61 says those cannot both be used
interchangeably - single-stream t/s differs 2.1x by which one you pick - and that the disagreement is not
resolvable by more micro-benchmarking, because the floor excluded whatever the window absorbs. So this measures
the engine itself: the same model, the same kernels, the same cache/state machinery, batch 1.

What it does, and why each part is needed:
  1. Loads the model with the CPU expert split active (`-mcs`), the shipping configuration for these checkpoints
     (they do not fit in 24 GiB). The expert leg then runs on host cores concurrently, so the GPU step time is the
     parent's NON-expert work plus whatever the handoff costs - which is precisely the disputed quantity.
  2. Times the decode loop with CUDA events (wall, per token). Uses prof_e2e.py's trick of supplying `past_len`
     and `cache.get_test_state()` without a real prefill: attention cost depends on the cached length, not its
     contents, and the recurrent state only needs to exist.
  3. Runs the same loop under torch.profiler and buckets device time by kernel-name pattern, printing every
     bucket per layer and the top kernels inside the two biggest ones, so the classification is auditable rather
     than asserted. `expert` kernels should be ~0 with -mcs, which doubles as a check that the split is active.
  4. Optionally adds lm_head + a greedy argmax per token (`--lmhead`), because those are per-token costs the
     per-layer window silently contains and the bottom-up floor explicitly does not.

Read the output as: measured non-expert us/layer (event timing, minus the handoff bucket) vs the floor vs the
calibrated figure. If the measured value lands near the floor, `fixed` is padding that the plan should stop
charging; if it lands near 257, the floor is missing real work and every offload-benefit claim is understated.
"""
import argparse
import os
import sys

import torch

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)

from exllamav3 import model_init                                        # noqa: E402
from torch.profiler import ProfilerActivity, profile                    # noqa: E402

# Buckets by lowercase substring of the kernel/activity name. Order matters: first match wins, so the specific
# (moe/handoff) patterns come before the generic ones. Anything unmatched lands in `other`, which is printed in
# full for the top rows so nothing hides there unnoticed.
BUCKETS = [
    ("expert",     ("moe", "expert", "gemv", "dp4a", "unswizzle", "trellis", "handoff", "flag", "issue")),
    ("copy",       ("memcpy", "copy_", "memset", "DtoH", "HtoD")),
    ("attn",       ("attn", "attention", "flash", "sdpa", "softmax", "rope", "kv_")),
    ("linstate",   ("gdn", "linear_attn", "recurrent", "conv", "ssm", "delta", "chunk")),
    ("gemm",       ("gemm", "matmul", "sgemm", "cutlass", "nvjet", "wmma", "tensorop")),
    ("norm",       ("norm", "silu", "activation", "elementwise", "vectorized", "reduce")),
]


def classify(name):
    low = name.lower()
    for tag, pats in BUCKETS:
        if any(p in low for p in pats):
            return tag
    return "other"


@torch.inference_mode()
def main():
    ap = argparse.ArgumentParser(allow_abbrev=False)
    model_init.add_args(ap, default_cache_size=8192, default_autosplit_max_batch_size=1,
                        default_chunk_size=4096)
    ap.add_argument("--ctx", type=int, default=4096)
    ap.add_argument("--tokens", type=int, default=64)
    ap.add_argument("--warm", type=int, default=12)
    ap.add_argument("--lmhead", action="store_true")
    ap.add_argument("--no-prof", action="store_true")
    ap.add_argument("--allow-tight", action="store_true",
                    help="run even when the memory guard objects (see notes/b70/mem_guard.py; this is the "
                         "configuration that hard-hung the box on 2025-11, so it needs a watching human)")
    args = ap.parse_args()

    # Memory guard BEFORE any tensor is read. An unattended GLM arm rebooted this machine; the guard belongs in
    # the loader path, not in a queue script's list of arms (mem_guard.py explains why, LESSONS 87).
    import os as _os
    import sys as _sys
    _sys.path.insert(0, _os.path.join(_os.path.dirname(_os.path.abspath(__file__)), "b70"))
    from mem_guard import require_headroom as _guard                        # noqa: E402
    _mdir = str(getattr(args, "model_dir", "") or getattr(args, "model", "") or "")
    if _mdir:
        _guard(_mdir, bool(getattr(args, "mcpa", False) or getattr(args, "moe_cpu_pinned_arena", False)),
               args.allow_tight, quiet=True)
    model, config, cache, tokenizer = model_init.init(args, quiet=True, progress=False)
    nl = getattr(config, "num_hidden_layers", None) or len(model.blocks)
    is_rec = model.caps.get("recurrent_states", False)
    dev = torch.device("cuda")
    # Synthetic ids must stay inside THIS model's vocab. The range used to be a hardcoded [1000, 200000), which
    # was harmless on Qwen3.8 (vocab_size 248,320) and produced IndexError: index out of range in self on GLM
    # (vocab_size 154,880) - a bench bug that looked exactly like a GLM harness/capacity failure and cost a
    # measurement attempt. Stay 8192 below the top so pad/eos-adjacent ids (GLM pads at 154,820) are never used.
    n_vocab = int(getattr(config, "vocab_size", 0) or 0)
    id_hi = min(200000, n_vocab - 8192) if n_vocab else 200000
    if id_hi <= 1100:
        raise SystemExit(f"vocab_size {n_vocab} leaves no room for the synthetic id range")
    ids = torch.randint(1000, id_hi, (1, args.ctx + args.tokens + args.warm + 64), device="cpu")
    print(f"\nengine step bench: {getattr(config, '_name', 'model')}  layers {nl}  ctx {args.ctx}  "
          f"b=1  recurrent_states={is_rec}  mcs={args.moe_cpu_split} mcl={args.moe_cpu_offload}  "
          f"ids in [1000,{id_hi}) of vocab {n_vocab or 'unknown'}")

    def step(i, with_head=False):
        rec = [cache.get_test_state(i)] if is_rec else None
        params = {"cache": cache, "attn_mode": "flash_attn", "past_len": i, "pos": i,
                  "batch_shape": (1, ((i + 512 + 255) // 256) * 256), "recurrent_states": rec}
        out = model.forward(ids[:, i:i + 1], params)
        if with_head:
            # The engine's own head+argmax entry point (model/model.py:393). model.forward alone returns the
            # final hidden state, so timing it without this omits exactly the per-token cost the inherited
            # 250 us/layer window is alleged to contain.
            if not hasattr(model, "lm_head_argmax"):
                raise SystemExit("model.lm_head_argmax missing: cannot price the head; drop --lmhead")
            model.lm_head_argmax(out, params)
        if rec:
            rec[0].free()

    def bench(n, warm, **kw):
        for j in range(warm):
            step(args.ctx + j, **kw)
        torch.cuda.synchronize()
        ev0, ev1 = torch.cuda.Event(True), torch.cuda.Event(True)
        ev0.record()
        for j in range(n):
            step(args.ctx + warm + j, **kw)
        ev1.record()
        torch.cuda.synchronize()
        return ev0.elapsed_time(ev1) / n

    ms_fwd = bench(args.tokens, args.warm)
    print(f"  model.forward, b=1: {ms_fwd*1000:8.1f} us/token  = {ms_fwd*1000/nl:6.1f} us/layer  "
          f"({1000/ms_fwd:6.1f} tok/s of parent step time)")
    if args.lmhead:
        # The engine's head path faults on a reused params dict (observed: SIGABRT inside BC_Linear.run_alloc
        # when called after model.forward with the decode params). Reported, not swallowed: without it the
        # per-token head cost stays unmeasured, and that is precisely the quantity the inherited 250 us window
        # is accused of absorbing, so a silent omission here would bias the whole comparison toward the floor.
        try:
            ms_full = bench(args.tokens, args.warm, with_head=True)
            print(f"  + lm_head/argmax:  {ms_full*1000:8.1f} us/token  ({1000/ms_full:6.1f} tok/s)   "
                  f"-> head costs {ms_full*1000 - ms_fwd*1000:7.1f} us/token "
                  f"= {(ms_full - ms_fwd)*1000/nl:5.1f} us/layer equivalent")
        except Exception as exc:                                   # noqa: BLE001 - report, do not hide
            print(f"  + lm_head/argmax: FAILED ({type(exc).__name__}: {str(exc)[:80]}) - head cost UNMEASURED, "
                  f"so treat the us/layer figures as excluding sampler+head")

    if args.no_prof:
        return
    with profile(activities=[ProfilerActivity.CPU, ProfilerActivity.CUDA]) as prof:
        for j in range(args.tokens):
            step(args.ctx + args.warm + j)
        torch.cuda.synchronize()

    tot, per_bucket, rows = 0.0, {}, []
    for e in prof.key_averages():
        # self_device_time_total is MICROseconds already (prof_e2e.py divides by 1e3 to print ms).
        d = float(getattr(e, "self_device_time_total", 0) or 0)
        if d <= 0:
            continue
        tot += d
        b = classify(e.key)
        per_bucket[b] = per_bucket.get(b, 0.0) + d
        rows.append((d, e.count, b, e.key))
    per_tok = tot / args.tokens                      # us/token
    print(f"  device-time total {per_tok:8.1f} us/token = {per_tok/nl:6.1f} us/layer "
          f"(profiler adds overhead; trust the event number for wall)")
    print(f"  {'bucket':>10} {'us/layer':>9} {'%':>6}")
    for b, v in sorted(per_bucket.items(), key=lambda kv: -kv[1]):
        print(f"  {b:>10} {v/args.tokens/nl:9.1f} {100*v/tot:5.1f}%")
    print("  top kernels (us/layer, calls/layer, bucket):")
    for d, c, b, k in sorted(rows, reverse=True)[:14]:
        print(f"    {d/args.tokens/nl:8.1f} {c/args.tokens:8.1f}  {b:>9}  {k[:74]}")
    exp = per_bucket.get("expert", 0.0) / args.tokens / nl
    if exp > 0.15 * per_tok:
        print(f"  NOTE: {100*exp/per_tok:.0f}% of device time is classified expert - the CPU split may not be "
              f"active for this checkpoint, or the pattern list is over-broad. Check before quoting the rest.")


if __name__ == "__main__":
    main()