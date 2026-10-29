#!/usr/bin/env python3
"""
dump_gemv_case.py - real mul1 trellis data + a NumPy reference for probe_gemv.cpp.

Everything the probe needs comes from the checkpoint or from tests/testlib/trellis.py, never from this
file's memory of the format:

  * gate_proj.trellis of layer L, experts 0..E-1  -> the packed uint16 ring stream the kernel reads
    (Qwen3.8 layer 0 is K = 3.0: shape (160, 40, 48) uint16, i.e. tiles_k x tiles_n x 16K).
  * x8 / q / sum_x8                              -> the int8 activation contract of exl3_moe_cpu_forward.
  * reference y                                   -> the identity in moe_mul1.h line 38-41:
        w(s) = (bytesum(s * 0x83DCD12D) - 510) * k_inv,   k_inv = fp16(0x1eee)
        sum_k w_kn x_k = k_inv * q * (SUM_k bytesum(s_kn * M) * x8_k - 510 * SUM_k x8_k)
    with the windows from trellis.unpack() and the element order from trellis.tile_perm().
  * reference bytesums for one tile               -> an EXACT int16 check of the kernel's ring/window
    extractor, so a bit-order mistake is caught before it can hide inside a tolerance on y.

Usage: dump_gemv_case.py OUTDIR EXPERTS ROWS [LAYER] [--with-reference] [--ckpt NAME] [--proj gate_proj]
"""
import json
import os
import struct
import sys

import numpy as np
import torch

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))
from tests.testlib import trellis as TR          # noqa: E402

ROOT = "/home/treo/projects/vendor/tabbyAPI/models"
CKPT = "Qwen3.8-Flash-Next-exl3-2.68bpw_h6_ng8"
MUL1_MULT = np.uint32(0x83DCD12D)


def read_tensors(layer, experts, proj="gate_proj", ckpt=None):
    """Real packed trellis bytes, via safetensors (no hand-rolled header parsing)."""
    from safetensors import safe_open
    d = os.path.join(ROOT, ckpt or CKPT)
    idx = json.load(open(os.path.join(d, "model.safetensors.index.json")))
    name_of = lambda e: f"model.language_model.layers.{layer}.mlp.experts.{e}.{proj}.trellis"
    by_shard = {}
    for e in experts:
        by_shard.setdefault(idx["weight_map"][name_of(e)], []).append(e)
    out, shape = {}, None
    for shard, es in by_shard.items():
        with safe_open(os.path.join(d, shard), framework="pt") as f:
            for e in es:
                t = f.get_tensor(name_of(e))
                if shape is None:
                    shape = tuple(t.shape)
                assert tuple(t.shape) == shape, (e, t.shape, shape)
                out[e] = t.numpy().astype(np.int16)
    tk, tn, last = shape
    K = last / 16.0
    return np.stack([out[e] for e in experts]), tk, tn, K, shape


def bytesums(win):
    x = (win.astype(np.uint32) * MUL1_MULT) & np.uint32(0xFFFFFFFF)
    return (((x >> np.uint32(0)) & 255).astype(np.int32) + ((x >> np.uint32(8)) & 255).astype(np.int32)
            + ((x >> np.uint32(16)) & 255).astype(np.int32) + ((x >> np.uint32(24)) & 255).astype(np.int32))


def k_inv_f32():
    return float(np.frombuffer(np.uint16(0x1EEE).tobytes(), dtype=np.float16)[0])


def _flag(name, default):
    for i, a in enumerate(sys.argv):
        if a == name and i + 1 < len(sys.argv):
            return sys.argv[i + 1]
        if a.startswith(name + "="):
            return a.split("=", 1)[1]
    return default


def main():
    outdir, E, R = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
    layer = int(sys.argv[4]) if len(sys.argv) > 4 and not sys.argv[4].startswith("--") else 0
    with_ref = "--with-reference" in sys.argv
    with_abytes = "--with-abytes" in sys.argv
    ckpt = _flag("--ckpt", CKPT)
    proj = _flag("--proj", "gate_proj")
    os.makedirs(outdir, exist_ok=True)
    experts = list(range(E))
    arr, tk, tn, K, shape = read_tensors(layer, experts, proj, ckpt)
    assert float(K).is_integer(), f"the probe's ring math assumes integer K, got {K}"
    kdim, ndim = tk * 16, tn * 16
    rng = np.random.default_rng(12345)
    x8 = rng.integers(-127, 128, size=(R, kdim), dtype=np.int8)
    amax = np.maximum(np.abs(x8.astype(np.int32)).max(axis=1), 1)
    q = (amax.astype(np.float32) / 127.0)
    sum_x8 = x8.astype(np.int32).sum(axis=1)

    with open(os.path.join(outdir, "weights.bin"), "wb") as f:
        f.write(arr.astype(np.int16).tobytes(order="C"))
    with open(os.path.join(outdir, "x8.bin"), "wb") as f:
        f.write(x8.tobytes(order="C"))
    with open(os.path.join(outdir, "q.bin"), "wb") as f:
        f.write(q.astype(np.float32).tobytes(order="C"))
    with open(os.path.join(outdir, "sx8.bin"), "wb") as f:
        f.write(sum_x8.astype(np.int32).tobytes(order="C"))
    with open(os.path.join(outdir, "meta.json"), "w") as f:
        json.dump(dict(E=E, R=R, tk=tk, tn=tn, K=K, k=kdim, n=ndim, layer=layer, ckpt=ckpt,
                       proj=proj, kinv=k_inv_f32(),
                       tile_words=int(8 * K), nbytes=int(arr.nbytes)), f, indent=1)
    if with_abytes:
        # Byte-expanded weights for the DPAS probe (E24 step 1): A[e, col, k*4+b] = byte b of
        # (window * MUL1). Summing A against activations replicated 4x along k reproduces
        # sum_k bytesum(prod_k) * x_k exactly in int32, so the matrix path can be tested for what it
        # is supposed to fix (the per-row instruction slot) with operand assembly made free. These
        # bytes come from the SAME authoritative unpacker as y_ref, never from the probe.
        assert K == int(K), f"byte expansion needs integer K, got {K}"
        perm = TR.tile_perm()
        win = TR.unpack(arr.reshape(-1, int(16 * K)), K).astype(np.uint32)
        prod = (win * MUL1_MULT) & np.uint32(0xFFFFFFFF)
        A = np.empty((E, tk, tn, 16, 16, 4), dtype=np.uint8)
        for b in range(4):
            bb = ((prod >> np.uint32(8 * b)) & np.uint32(255)).astype(np.uint8)
            bpp = np.empty_like(bb)
            bpp[:, perm] = bb
            A[..., b] = bpp.reshape(E, tk, tn, 16, 16)
        A = np.ascontiguousarray(A.transpose(0, 2, 4, 1, 3, 5)).reshape(E, tn * 16, tk * 16, 4)
        assert A.shape == (E, ndim, kdim, 4), A.shape
        A.tofile(os.path.join(outdir, "abytes.bin"))
        print(f"abytes: {A.shape} uint8 = {A.nbytes / 2**20:.1f} MiB "
              f"({A.nbytes / max(1, arr.nbytes):.1f}x the trellis bytes)")

    if with_ref:
        assert K == int(K), f"reference path needs integer K (ring is 256*K bits), got {K}"
        perm = TR.tile_perm()
        win = TR.unpack(arr.reshape(-1, int(16 * K)), K)           # (E*tk*tn, 256) uint16 windows
        bs = bytesums(win.astype(np.uint32))                       # (T, 256) int32
        # (E, tk, tn, 256) -> (E, k, n) in row-major tile-element order
        bsd = np.empty(bs.shape, dtype=np.int32)
        bsd[:, perm] = bs
        bsd = bsd.reshape(E, tk, tn, 16, 16).transpose(0, 1, 3, 2, 4).reshape(E, kdim, ndim)
        xs = x8.astype(np.int32)                                   # (R, k)
        y = np.empty((E, R, ndim), dtype=np.float32)
        for e in range(E):
            acc = xs @ bsd[e]                                      # (R, n) exact int arithmetic
            y[e] = (k_inv_f32() * q)[:, None] * (acc - 510 * sum_x8[:, None])
        np.save(os.path.join(outdir, "y_ref.npy"), y)
        # exact bytesum fixture for tile 0 of expert 0: catches ring/bit-order errors immediately
        np.save(os.path.join(outdir, "bs_ref_tile0.npy"), bs[0].astype(np.int16))
        print(f"reference: y {y.shape} max|y| {np.abs(y).max():.3f}; "
              f"tile0 bytesum min {bs[0].min()} max {bs[0].max()}")
    print(f"dumped E={E} R={R} k={kdim} n={ndim} K={K} tiles=({tk},{tn}) proj={proj} "
          f"weight bytes {arr.nbytes / 2**20:.1f} MiB -> {outdir}")


if __name__ == "__main__":
    main()