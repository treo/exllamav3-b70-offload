"""Verification harness for the mul1 trellis specification notes.

Checks, against real checkpoint tensors:
  1. tail-biting ring property of the unpacked 16-bit windows (integer and half-integer rates)
  2. tile_perm order and the codebook: testlib/trellis.dequant_rotated == ext.reconstruct (GPU)
  3. mul1 codebook: affine in the byte sum, its value histogram, collisions and spacing
  4. the CPU packed (band-swizzled / planar) layouts round-trip through the parent-side inverse
  5. the int8 fusion identity the CPU GEMV relies on
"""
import os
import sys

import numpy as np
import torch

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "tests"))

from exllamav3.ext import exllamav3_ext as ext                       # noqa: E402
from exllamav3.loader.safetensors import SafetensorsCollection       # noqa: E402
from testlib import trellis as T                                     # noqa: E402
from testlib.moe import repack_trellis                                # noqa: E402

MODEL = "/home/treo/projects/vendor/tabbyAPI/models/Qwen3.8-Flash-Next-exl3-2.68bpw_h6_ng8"


def get_trellis(path, key):
    stc = SafetensorsCollection(path)
    return stc.get_tensor(key, torch.device("cpu"))


def main():
    stc = SafetensorsCollection(MODEL)
    tmap = stc.list_tensors("model.language_model.layers.7.mlp.experts.0.up_proj.trellis")
    for layer, name in ((1, "up"), (7, "up"), (7, "down")):
        key = f"model.language_model.layers.{layer}.mlp.experts.0.{name}_proj.trellis"
        t = stc.get_tensor(key, torch.device("cpu"))
        width = t.shape[2]
        K = width / 16          # 16 * K uint16 per tile; whole words at half-integer rates too
        w = t.numpy().reshape(-1, width)
        words = T.unpack(w, K)
        print(f"[1] {key}: shape {tuple(t.shape)} tile words {width} -> K={K}")
        print(f"    tail-biting ring: {T.is_tail_biting(words, K)}; "
              f"distinct 16-bit windows in this tensor: {len(np.unique(words))} of {words.size}")

    # ---- 2. reconstruction matches the GPU kernel ----------------------------------------
    for layer, K_exp in ((1, 3), (7, 2.5)):
        key = f"model.language_model.layers.{layer}.mlp.experts.0.up_proj.trellis"
        t = stc.get_tensor(key, torch.device("cpu")).contiguous()
        K = t.shape[2] / 16
        ref = torch.from_numpy(T.dequant_rotated(t.numpy(), K, "mul1"))
        w = torch.empty((t.shape[0] * 16, t.shape[1] * 16), dtype = torch.half, device = "cuda")
        ext.reconstruct(w, t.to("cuda"), K, False, True)
        diff = (w.cpu().float() - ref.float()).abs().max().item()
        print(f"[2] layer {layer} K={K}: testlib dequant_rotated vs ext.reconstruct "
              f"max |diff| = {diff}  (shape {tuple(w.shape)})")

    # ---- 3. the mul1 codebook ------------------------------------------------------------
    s = np.arange(1 << 16, dtype = np.uint64)
    prod = (s * np.uint64(0x83DCD12D)) & np.uint64(0xFFFFFFFF)
    bsum = ((prod & np.uint64(0xFF)).astype(np.int64) + ((prod >> np.uint64(8)) & np.uint64(0xFF)).astype(np.int64)
            + ((prod >> np.uint64(16)) & np.uint64(0xFF)).astype(np.int64) + ((prod >> np.uint64(24))).astype(np.int64))
    vals = T.decode(np.arange(1 << 16), "mul1").astype(np.float64)
    uvals, counts = np.unique(vals, return_counts = True)
    gaps = np.diff(uvals)
    print(f"[3] mul1: {len(uvals)} distinct fp16 values over 65536 states, "
          f"range [{vals.min():.4f}, {vals.max():.4f}], mean {vals.mean():.4f}, "
          f"std {vals.std():.4f}; largest class {counts.max()} states share one value; "
          f"spacing min {gaps.min():.6f} max {gaps.max():.6f}")
    k_inv = float(np.frombuffer(bytes([0xee, 0x1e]), dtype = np.uint16).view(np.float16)[0])
    aff = ((bsum - 510) * k_inv).astype(np.float16).astype(np.float64)
    print(f"    affine-in-bytesum check: max |codebook - (bsum-510)*k_inv| = "
          f"{np.abs(vals - aff).max():.3e} (k_inv = {k_inv})")
    # histogram vs a normal with the same moments
    qs = np.percentile(vals, [1, 25, 50, 75, 99])
    print(f"    percentiles 1/25/50/75/99: {np.round(qs, 4)}; Gaussian equivalents "
          f"(mu={vals.mean():.4f}, sd={vals.std():.4f}): "
          f"{np.round(vals.mean() + vals.std() * np.array([-2.3263, -0.6745, 0.0, 0.6745, 2.3263]), 4)}")

    # ---- 4. packed CPU layouts round-trip -------------------------------------------------
    for K in (1, 2, 2.5, 3, 8):
        g = ext.exl3_moe_cpu_swizzle_group(K)
        p = ext.exl3_moe_cpu_planar_layout(K)
        t = torch.randint(-30000, 30000, (4, 8, int(16 * K) if float(16 * K).is_integer() else 16 * int(K) + 8),
                          dtype = torch.int16)
        r = repack_trellis(t, g, bool(p))
        back = torch.empty_like(r)
        tk, tn, ps = t.shape
        wd = ps // 2
        if g and p:
            back.view(torch.int32).view(tk, tn // g, g, 8, wd // 8).copy_(
                r.view(torch.int32).view(tn // g, tk, g, wd // 8, 8).permute(1, 0, 2, 4, 3))
        elif g:
            back.view(tk, tn // g, g, ps).copy_(
                r.view(tn // g, tk, g, ps).permute(1, 0, 2, 3))
        else:
            back.copy_(r)
        print(f"[4] K={K}: group={g} planar={p} round-trip equal: {bool(torch.equal(back, t))}")

    # ---- 5. the fusion identity ----------------------------------------------------------
    rng = np.random.default_rng(5)
    states = rng.integers(0, 1 << 16, size = 4096, dtype = np.int64)
    x8 = rng.integers(-127, 128, size = 4096, dtype = np.int64)
    wv = T.decode(states, "mul1").astype(np.float64)
    lhs = float(np.dot(wv, x8))
    bs = (states.astype(np.uint64) * np.uint64(0x83DCD12D)) & np.uint64(0xFFFFFFFF)
    bsum = ((bs & np.uint64(0xFF)).astype(np.int64) + ((bs >> np.uint64(8)) & np.uint64(0xFF)).astype(np.int64)
            + ((bs >> np.uint64(16)) & np.uint64(0xFF)).astype(np.int64) + (bs >> np.uint64(24)).astype(np.int64))
    lhs = float(np.dot(wv, x8))
    rhs = k_inv * (float(np.dot(bsum, x8)) - 510 * float(x8.sum()))
    print(f"[5] one-dot-product identity: direct {lhs:.6f} vs bytesum-form {rhs:.6f} "
          f"(rel {abs(lhs-rhs)/max(abs(lhs),1e-9):.2e})")


if __name__ == "__main__":
    main()