"""Level-0 acceptance measurement: the CPU expert kernel against an independent fp64 oracle.

    python notes/acceptance_kernel.py MODEL_DIR [--layer 5] [--experts 64] [--rows 1,4,16]
                                                [--threads 15] [--acts /tmp/acts.pt] [--reps 50]

Rebuilds one layer's routed experts from the checkpoint and evaluates, in float64 on CPU and with
**no extension code in the reference path** (tests/testlib/trellis.py: ring unpack, mul1 decode,
Hadamard/scale composition):

    W_e = diag(suh) H_128 Ŵ H_128 diag(svh)        expert_e(x) = down(act(gate(x)), up(x))
    out[t] = sum_k w[t,k] * expert_{sel[t,k]}(x[t])

then compares it with `exl3_moe_cpu_forward` (int8 activations, packed trellis, AVX tier) and with
the GPU reconstruct path (`ext.reconstruct` + `hgemm` + `had_r_128`), which is what the same experts
would do on the device. Reports relative RMS / max-abs error per path, the CPU-vs-GPU error ratio,
and a bitwise-reproducibility check of the CPU kernel.

Activation inputs come from --acts (captured hidden states from notes/acceptance_model.py
--dump-acts) when available, otherwise from randn plus a large shared component, which is the
statistics that trips the wide-row path (EXL3_MOE_CPU_WIDE).
"""
import argparse
import json
import os
import sys

import numpy as np
import torch

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)
sys.path.insert(0, os.path.join(ROOT, "tests"))

from exllamav3.ext import exllamav3_ext as ext                       # noqa: E402
from exllamav3.loader.safetensors import SafetensorsCollection       # noqa: E402
from testlib import trellis as T                                     # noqa: E402
from testlib.moe import repack_trellis                                # noqa: E402


def rate_of(width):
    k, rem = divmod(width, 16)
    return k if rem == 0 else (k + 0.5 if rem == 8 else None)


def dense_w(trellis, suh, svh):
    """(k, n) float64 original-basis weight of one projection, pure NumPy/torch reference"""
    K = rate_of(trellis.shape[2])
    return T.dequant(trellis, suh.double(), svh.double(), K, "mul1")


def expert_fwd(x, wg, ug, dg, gated):
    """float64 expert MLP on (m, k) x, weights as (k, n) float64; silu gating"""
    g = x @ (wg if gated else ug)
    u = x @ ug
    a = torch.nn.functional.silu(g) * u if gated else torch.nn.functional.relu(u) ** 2
    return a @ dg


def gpu_linear(x, trellis, suh, svh, K, scratch):
    """The device reconstruct path for one projection: had_in(x*suh) @ W_rot -> had_out*svh"""
    dev = x.device
    k, n = trellis.shape[0] * 16, trellis.shape[1] * 16
    xh = torch.empty_like(x)
    ext.had_r_128(x, xh, suh, None, 1.0)
    w = scratch[:k * n].view(k, n)
    ext.reconstruct(w, trellis, K, False, True)
    y = torch.empty((x.shape[0], n), dtype = torch.half, device = dev)
    ext.hgemm(xh, w, y)
    ext.had_r_128(y, y, None, svh, 1.0)
    return y


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("model_dir")
    ap.add_argument("--layer", type = int, default = 5)
    ap.add_argument("--experts", type = int, default = 48)
    ap.add_argument("--rows", default = "1,4,16")
    ap.add_argument("--threads", type = int, default = 15)
    ap.add_argument("--acts", default = "")
    ap.add_argument("--reps", type = int, default = 50)
    ap.add_argument("--seed", type = int, default = 3)
    ap.add_argument("--no-offset", action = "store_true",
                    help = "synthetic activations without the shared massive component")
    a = ap.parse_args()

    cfg = json.load(open(os.path.join(a.model_dir, "config.json")))
    tc = cfg.get("text_config", cfg)
    H, I, E_all = tc["hidden_size"], tc["moe_intermediate_size"], tc["num_experts"]
    topk = tc["num_experts_per_tok"]
    gated = tc.get("hidden_act", "silu") != "relu2"
    stc = SafetensorsCollection(a.model_dir)
    cpu = torch.device("cpu")
    pref = None
    for cand in (f"model.language_model.layers.{a.layer}.mlp.experts", f"layers.{a.layer}.mlp.experts"):
        if f"{cand}.0.up_proj.trellis" in stc.tensor_file_map:
            pref = cand
            break
    E = min(a.experts, E_all)

    def get(e, proj, suf):
        return stc.get_tensor(f"{pref}.{e}.{proj}_proj.{suf}", cpu).contiguous()

    K = rate_of(get(0, "up", "trellis").shape[2])
    nat, su, sv, packed = {}, {}, {}, {}
    for proj in ("gate", "up", "down"):
        nat[proj] = [get(e, proj, "trellis") for e in range(E)]
        su[proj] = [get(e, proj, "suh") for e in range(E)]
        sv[proj] = [get(e, proj, "svh") for e in range(E)]
        grp = ext.exl3_moe_cpu_swizzle_group(K)
        pln = bool(grp and ext.exl3_moe_cpu_planar_layout(K))
        packed[proj] = [repack_trellis(t, grp, pln) for t in nat[proj]]
    Wd = {proj: [dense_w(nat[proj][e], su[proj][e], sv[proj][e]) for e in range(E)]
          for proj in ("gate", "up", "down")}
    handle = ext.exl3_moe_cpu_make_layer(
        packed["gate"], su["gate"], sv["gate"], packed["up"], su["up"], sv["up"],
        packed["down"], su["down"], sv["down"], [], [], [], 0, 0.0, 1)
    wide = os.environ.get("EXL3_MOE_CPU_WIDE", "1") != "0"
    print(f"# {os.path.basename(a.model_dir.rstrip('/'))} layer {a.layer}: E={E} H={H} I={I} "
          f"K={K} topk={topk} gated={gated} ISA=avx2:{ext.exl3_moe_cpu_has_avx2()} "
          f"group={ext.exl3_moe_cpu_swizzle_group(K)} planar={ext.exl3_moe_cpu_planar_layout(K)} "
          f"wide={wide}")

    gen = torch.Generator().manual_seed(a.seed)
    acts = None
    if a.acts and os.path.exists(a.acts):
        d = torch.load(a.acts)
        acts = d
        print(f"# activations from {a.acts}: prefill {d.get('prefill') and tuple(d['prefill'][0].shape)}, "
              f"decode {d.get('decode') and tuple(d['decode'][0].shape)}")

    dev = torch.device("cuda")
    scratch = torch.empty(max(Wd["gate"][0].numel(), Wd["down"][0].numel()),
                          dtype = torch.half, device = dev)
    print(f"{'rows':>5} {'source':>9} {'CPU relRMS':>11} {'CPU maxabs':>10} {'GPU relRMS':>11} "
          f"{'CPU/GPU':>8} {'bitwise-stable':>15}")
    for rows in [int(r) for r in a.rows.split(",")]:
        # captured activations only apply to a model of the same hidden width
        use_acts = bool(acts) and int(acts.get("hidden") or (acts["prefill"][0].shape[-1]
                                                            if acts.get("prefill") else 0)) == H
        src = "randn"
        if use_acts and rows == 1 and acts.get("decode"):
            x64 = acts["decode"][0].reshape(1, -1)[:, :H].double()
            src = "real"
        elif use_acts and rows > 1 and acts.get("prefill"):
            x64 = acts["prefill"][0].reshape(-1, acts["prefill"][0].shape[-1])[:rows, :H].double()
            src = "real"
        else:
            x64 = torch.randn(rows, H, generator = gen, dtype = torch.float64) * 0.6
            if not a.no_offset:
                x64[:, :8] += 6.0              # massive shared component: stresses the wide-row path
        sel = torch.randint(0, E, (rows, topk), generator = gen, dtype = torch.long)
        w64 = torch.rand(rows, topk, generator = gen, dtype = torch.float64) + 0.05

        ref = torch.zeros(rows, H, dtype = torch.float64)
        for t in range(rows):
            for j in range(topk):
                e = int(sel[t, j])
                ref[t] += (w64[t, j] * expert_fwd(x64[t:t + 1], Wd["gate"][e], Wd["up"][e],
                                                 Wd["down"][e], gated)).reshape(-1)
        x16 = x64.float().half()
        xg16 = x16.to(dev)
        out = torch.zeros(rows, H, dtype = torch.float)
        ext.exl3_moe_cpu_forward(handle, x16, sel, w64.float().half(), out, a.threads)

        # GPU reconstruct path over the same selection, fp16 weights / fp32 accumulate
        gout = torch.zeros(rows, H, dtype = torch.float64)
        with torch.no_grad():
            for t in range(rows):
                for j in range(topk):
                    e = int(sel[t, j])
                    xx = xg16[t:t + 1]
                    g = gpu_linear(xx, nat["gate"][e].to(dev), su["gate"][e].to(dev),
                                   sv["gate"][e].to(dev), K, scratch)
                    u = gpu_linear(xx, nat["up"][e].to(dev), su["up"][e].to(dev),
                                   sv["up"][e].to(dev), K, scratch)
                    a16 = (torch.nn.functional.silu(g.float()) * u.float()).half() if gated else \
                        (torch.relu(u.float()) ** 2).half()
                    d = gpu_linear(a16, nat["down"][e].to(dev), su["down"][e].to(dev),
                                   sv["down"][e].to(dev), K, scratch)
                    gout[t] += (float(w64[t, j]) * d.double().cpu()).reshape(-1)
        scale = ref.norm(dim = -1).mean().item()
        ec = (out.double() - ref).norm(dim = -1).mean().item() / scale
        eg = (gout - ref).norm(dim = -1).mean().item() / scale
        mx = (out.double() - ref).abs().max().item()
        stable = True
        out2 = torch.zeros_like(out)
        for _ in range(a.reps):
            ext.exl3_moe_cpu_forward(handle, x16, sel, w64.float().half(), out2, a.threads)
            if not torch.equal(out, out2):
                stable = False
                break
        print(f"{rows:5d} {src:>9} {ec:11.3e} {mx:10.3e} {eg:11.3e} {ec / max(eg, 1e-12):8.2f} "
              f"{str(stable):>15}")
    ext.exl3_moe_cpu_free_layer(handle)


if __name__ == "__main__":
    main()