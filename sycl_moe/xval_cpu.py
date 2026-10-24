#!/usr/bin/env python3
"""Cross-validate the SYCL MoE layer against the real exllamav3 CPU MoE kernels.

Synthesizes a layer of mul1 expert tensors, runs exl3_moe_cpu_forward (scalar tier for a
pure-fp reference and/or native ISA tier for the deployed path), saves tensors + inputs so
the SYCL harness can load the exact same data and be compared.
"""
import argparse, os, sys, numpy as np, torch
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
if "--scalar" in sys.argv:
    os.environ["EXL3_MOE_CPU_MAX_ISA"] = "scalar"
from exllamav3 import ext
T = ext.exllamav3_ext


def tile_u16(bits, hb):
    return 8 * (2 * bits + hb)


def make_layer(E, H, I, bits, hb, seed, gated=True):
    g = torch.Generator().manual_seed(seed)
    tw = tile_u16(bits, hb)
    def mats(k, n):
        tr = [torch.randint(0, 65536, (k // 16, n // 16, tw), generator=g, dtype=torch.int32).to(torch.uint16) for _ in range(E)]
        suh = [torch.randn(k, generator=g).abs().clamp(0.02, 1.0).half() * 0.05 for _ in range(E)]
        svh = [torch.randn(n, generator=g).abs().clamp(0.02, 1.0).half() * 0.05 for _ in range(E)]
        return tr, suh, svh
    gt, gs, gv = mats(H, I)
    ut, us, uv = mats(H, I)
    dt, ds, dv = mats(I, H)
    empty = []
    args = (gt if gated else empty, gs if gated else empty, gv if gated else empty,
            ut, us, uv, dt, ds, dv, empty, empty, empty,
            0 if gated else 2, 0.0, 0)
    h = T.exl3_moe_cpu_make_layer(*args)
    return h, (gt, gs, gv, ut, us, uv, dt, ds, dv)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--E", type=int, default=12)
    ap.add_argument("--rows", type=int, default=1)
    ap.add_argument("--topk", type=int, default=10)
    ap.add_argument("--bits", type=int, default=2)
    ap.add_argument("--hb", type=int, default=0)
    ap.add_argument("--act", type=int, default=0)
    ap.add_argument("--gateless", action="store_true")
    ap.add_argument("--scalar", action="store_true")
    ap.add_argument("--seed", type=int, default=5)
    ap.add_argument("--iters", type=int, default=30)
    ap.add_argument("--outdir", type=str, default="xval")
    args = ap.parse_args()
    os.makedirs(args.outdir, exist_ok=True)

    H, I = 2560, 640
    g = torch.Generator().manual_seed(args.seed + 1)
    sel = torch.stack([torch.randperm(args.E, generator=g)[:args.topk] for _ in range(args.rows)]).to(torch.int64)
    wts = (torch.rand(args.rows, args.topk, generator=g) * 0.5 + 0.05).half() / args.topk
    x = (torch.randn(args.rows, H, generator=g) * 0.5).half().contiguous()

    print("ISA:", "SCALAR" if args.scalar else "native")
    h, tensors = make_layer(args.E, H, I, args.bits, args.hb, args.seed, gated=not args.gateless)

    out = torch.zeros(args.rows, H, dtype=torch.float32)
    T.exl3_moe_cpu_forward(h, x, sel, wts, out, os.cpu_count() or 4)

    # save everything for the SYCL harness
    def save(name, t):
        t = t.detach().contiguous()
        if t.dtype == torch.uint16:
            t = t.view(torch.int16)
        elif t.dtype in (torch.int32, torch.int64):
            pass
        t.numpy().tofile(os.path.join(args.outdir, name + ".bin"))
    with open(os.path.join(args.outdir, "meta.txt"), "w") as f:
        f.write(f"E {args.E}\nH {H}\nI {I}\nbits {args.bits}\nhb {args.hb}\n"
                f"act {args.act}\ngateless {1 if args.gateless else 0}\n"
                f"rows {args.rows}\ntopk {args.topk}\n")
    save("x", x)
    save("sel", sel.to(torch.int32))
    save("wts", wts)
    save("out_cpu", out)
    names = ["gate_tr", "gate_suh", "gate_svh", "up_tr", "up_suh", "up_svh", "down_tr", "down_suh", "down_svh"]
    for nm, grp in zip(names, tensors):
        if grp is None or len(grp) == 0:
            open(os.path.join(args.outdir, nm + ".present"), "w").write("0")
            continue
        open(os.path.join(args.outdir, nm + ".present"), "w").write("1")
        for e, t in enumerate(grp):
            save(f"{nm}_{e}", t)
    print("saved layer + CPU output to", args.outdir, "| out rms", out.square().mean().sqrt().item())

    # timing of the deployed (native ISA) path
    import time
    threads = os.cpu_count() or 4
    for _ in range(3):
        T.exl3_moe_cpu_forward(h, x, sel, wts, out, threads)
    t0 = time.perf_counter()
    for _ in range(args.iters):
        T.exl3_moe_cpu_forward(h, x, sel, wts, out, threads)
    t1 = time.perf_counter()
    print(f"CPU native forward: {(t1 - t0) / args.iters * 1e3:.3f} ms/layer "
          f"(rows={args.rows} topk={args.topk} E={args.E} threads={threads})")


if __name__ == "__main__":
    main()