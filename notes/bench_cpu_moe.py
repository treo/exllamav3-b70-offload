"""CPU expert-GEMM microbenchmark on real checkpoint tensors.

    python notes/bench_cpu_moe.py <model_dir> [--layer N] [--experts M] [--rows 1,4,16,64]
                                  [--topk T] [--threads 1,4,8,15] [--warm]

Registers a synthetic layer of M real experts (gate/up/down trellis + suh/svh, packed with the
same rule the worker's arena loader uses), then times exl3_moe_cpu_forward for a few row counts.
Prints per-call microseconds, assignments, distinct experts, trellis bytes touched and the
implied DRAM read rate.
"""
import argparse
import json
import os
import sys
import time

import numpy as np
import torch

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "tests"))

from exllamav3.ext import exllamav3_ext as ext           # noqa: E402
from exllamav3.loader.safetensors import SafetensorsCollection  # noqa: E402
from testlib.moe import repack_trellis                    # noqa: E402


def rate_of(width):
    k, rem = divmod(width, 16)
    return k if rem == 0 else (k + 0.5 if rem == 8 else None)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("model_dir")
    ap.add_argument("--layer", type = int, default = 5)
    ap.add_argument("--experts", type = int, default = 64)
    ap.add_argument("--rows", default = "1,2,4,8,16,32,64")
    ap.add_argument("--topk", type = int, default = 0)
    ap.add_argument("--threads", default = "1,4,8,16")
    ap.add_argument("--iters", type = int, default = 200)
    ap.add_argument("--wide", type = int, default = 1)
    ap.add_argument("--swizzle", type = int, default = 1)
    a = ap.parse_args()

    os.environ.setdefault("EXL3_MOE_CPU_WIDE", "1" if a.wide else "0")
    cfg = json.load(open(os.path.join(a.model_dir, "config.json")))
    tc = cfg.get("text_config", cfg)
    H = tc["hidden_size"]
    I = tc["moe_intermediate_size"]
    E_all = tc["num_experts"]
    topk = a.topk or tc["num_experts_per_tok"]
    E = min(a.experts, E_all)

    stc = SafetensorsCollection(a.model_dir)
    cpu = torch.device("cpu")
    pref = None
    for cand in (f"model.language_model.layers.{a.layer}.mlp.experts",
                 f"layers.{a.layer}.mlp.experts",
                 f"model.layers.{a.layer}.mlp.experts"):
        if f"{cand}.0.up_proj.trellis" in stc.tensor_file_map:
            pref = cand
            break
    assert pref is not None, "no routed experts found"

    def key(e, proj, suf):
        return f"{pref}.{e}.{proj}_proj.{suf}"

    shapes = stc.list_tensors(key(0, "up", "trellis"))
    w = shapes[key(0, "up", "trellis")]["shape"][-1]
    K = rate_of(w)
    print(f"# {os.path.basename(a.model_dir.rstrip('/'))} layer {a.layer}: {E}/{E_all} experts, "
          f"H={H} I={I} K={K} topk={topk} swizzle={a.swizzle} wide={a.wide}")
    print(f"# isa avx2={ext.exl3_moe_cpu_has_avx2()} bw={ext.exl3_moe_cpu_has_avx512_bw()} "
          f"vnni={ext.exl3_moe_cpu_has_avx512_vnni()} vbmi={ext.exl3_moe_cpu_has_avx512_vbmi()} "
          f"| group(K)={ext.exl3_moe_cpu_swizzle_group(K)} planar(K)={ext.exl3_moe_cpu_planar_layout(K)}")

    g_t, g_u, g_v, u_t, u_u, u_v, d_t, d_u, d_v = [], [], [], [], [], [], [], [], []
    t0 = time.time()
    for e in range(E):
        for proj, tl, us, vs in (("gate", g_t, g_u, g_v), ("up", u_t, u_u, u_v), ("down", d_t, d_u, d_v)):
            t = stc.get_tensor(key(e, proj, "trellis"), cpu)
            if a.swizzle:
                grp = ext.exl3_moe_cpu_swizzle_group(rate_of(t.shape[2]))
                pln = bool(grp and ext.exl3_moe_cpu_planar_layout(rate_of(t.shape[2])))
                t = repack_trellis(t, grp, pln)
            tl.append(t.contiguous())
            us.append(stc.get_tensor(key(e, proj, "suh"), cpu).contiguous())
            vs.append(stc.get_tensor(key(e, proj, "svh"), cpu).contiguous())
    load_s = time.time() - t0
    per_expert = g_t[0].numel() * 2 + u_t[0].numel() * 2 + d_t[0].numel() * 2
    print(f"# loaded+repacked {E} experts ({per_expert / 2**20:.3f} MiB/expert) in {load_s:.2f} s")

    handle = ext.exl3_moe_cpu_make_layer(
        g_t, g_u, g_v, u_t, u_u, u_v, d_t, d_u, d_v, [], [], [], 0, 0.0, int(bool(a.swizzle)))

    gen = torch.Generator().manual_seed(7)
    rows_list = [int(r) for r in a.rows.split(",")]
    thr_list = [int(t) for t in a.threads.split(",")]
    torch.set_num_threads(1)

    print(f"{'rows':>5} {'thr':>4} {'us/call':>10} {'us/token':>9} {'ns/asgn':>8} "
          f"{'experts':>7} {'GiB/s':>7} {'asgn/exp':>8}")
    # Distinct selections cycled across the timing loop: reusing one selection would keep its
    # experts' trellis in L3 (64 MiB here) and report warm-cache rates instead of the cold-expert
    # reads a real decode step does
    n_sel = max(2, min(a.iters, 64))
    for rows in rows_list:
        x = (torch.randn(rows, H, generator = gen) * 0.5).half()
        sels = torch.randint(0, E, (n_sel, rows, topk), generator = gen, dtype = torch.long)
        wts_all = torch.rand(n_sel, rows, topk, generator = gen).half() + 0.1
        out = torch.empty(rows, H, dtype = torch.float)
        for thr in thr_list:
            for _ in range(20):
                ext.exl3_moe_cpu_forward(handle, x, sels[_ % n_sel], wts_all[_ % n_sel], out, thr)
            t0 = time.perf_counter()
            n = max(1, int(a.iters // max(1, rows / 4)))
            for i in range(n):
                ext.exl3_moe_cpu_forward(handle, x, sels[i % n_sel], wts_all[i % n_sel], out, thr)
            dt = (time.perf_counter() - t0) / n
            uniq = float(np.mean([np.unique(sels[i % n_sel].numpy()).size for i in range(min(n, n_sel))]))
            bytes_ = uniq * per_expert
            print(f"{rows:5d} {thr:4d} {dt*1e6:10.1f} {dt*1e6/rows:9.1f} "
                  f"{dt*1e9/(rows*topk):8.1f} {uniq:7.1f} {bytes_/dt/1e9:7.2f} {rows*topk/max(uniq,1):8.2f}")
    # Reference: single-threaded sequential read of the same bytes (peak cold-stream rate)
    buf = torch.empty(64 << 20, dtype = torch.uint8)
    src = g_t[0].view(torch.uint8).reshape(-1).clone()
    reps = max(1, (256 << 20) // src.numel())
    t0 = time.perf_counter()
    for i in range(reps):
        buf[:src.numel()] = src
    read_s = (time.perf_counter() - t0) / reps
    print(f"# reference: single-thread copy of a {src.numel()/2**20:.2f} MiB block "
          f"= {src.numel()/read_s/1e9:.1f} GB/s read+write (1 thread)")
    ext.exl3_moe_cpu_free_layer(handle)


if __name__ == "__main__":
    main()