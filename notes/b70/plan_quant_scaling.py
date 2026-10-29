#!/usr/bin/env python3
"""
plan_quant_scaling.py - does §2.1a's placement arithmetic survive the bigger Qwen3.8 recipes?

Three inputs move with bits/weight, and they do not all move the same way:

  expert_bytes        grows ~2.4x from 2.68 to 6.05 bpw, so a decode layer's footprint grows with it and
                     the FOOTPRINT-MATCHED RATE changes row (measured for K = 4/5/6 in
                     out_rates_footprint_hiq.txt, not extrapolated).
  device capacity     the B70 slice is fixed at 31.9 GiB, so the same quota holds fewer experts; the
                     residue (and therefore the CPU term, the one term the fair-split policy damages)
                     grows super-linearly because routing is peaked: capacity falls, h falls with it, and
                     the CPU term is bytes/47.4.
  streamed non-expert does NOT scale: the recipe keeps the attention/embedding/lm_head tensors near a
                     fixed width, so the parent's byte bill stays 69-101 MiB/layer across every quant and
                     its bandwidth duty stays 31-45%. An earlier draft of this file assumed proportional
                     growth and was wrong by ~2x at 6.05 bpw.

Policy comparison and the min-max objective are the ones established in plan_parent_budget.py, reused
here by import so the two files cannot drift apart.
"""
import glob
import importlib.util
import json
import os

_spec = importlib.util.spec_from_file_location("ppb", os.path.join(os.path.dirname(__file__),
                                                                   "plan_parent_budget.py"))
ppb = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(ppb)

# measured footprint bands: (MiB, scattered GB/s, clustered GB/s)
BANDS = {
    "K2.5": [(64, 291.8, 558.3), (128, 200.1, 278.4), (256, 229.8, 346.9), (512, 248.6, 364.9),
             (1024, 274.0, 545.8), (2048, 257.0, 369.5)],
    "K3.0": [(64, 253.7, 320.6), (128, 208.0, 224.9), (256, 231.6, 293.1), (512, 252.4, 300.0),
             (1024, 254.7, 321.3), (2048, 260.3, 321.9)],
    "K4.0": [(64, 294.4, 495.4), (128, 245.3, 383.1), (256, 230.9, 329.4), (512, 284.7, 391.6),
             (1024, 254.9, 324.8), (2048, 289.5, 373.1)],
    "K5.0": [(64, 289.8, 522.5), (128, 214.2, 341.3), (256, 212.7, 265.0), (512, 240.5, 279.9),
             (1024, 249.7, 307.2), (2048, 283.0, 357.4)],
    # K=6 at 64 MiB measured 754 GB/s, ABOVE the card's 674 GB/s copy peak: not a DRAM number, so the
    # row is dropped rather than used. See out_rates_footprint_hiq.txt.
    "K6.0": [(128, 243.2, 336.6), (256, 206.9, 224.5), (512, 247.9, 296.1), (1024, 279.8, 339.7),
             (2048, 286.0, 357.5)],
}
QUANTS = [("2.05", "Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4", "2.05bpw", "K2.5"),
          ("2.68", "Qwen3.8-Flash-Next-exl3-2.68bpw_h6_ng8", "2.68bpw", "K2.5"),
          ("4.05", "Qwen3.8-Flash-Next-exl3-4.05bpw_h6_ng6", "4.05bpw", "K4.0"),
          ("5.05", "Qwen3.8-Flash-Next-exl3-5.05bpw_h6_ng8", "5.05bpw", "K5.0"),
          ("6.05", "Qwen3.8-Flash-Next-exl3-6.05bpw_h6_ng8", "6.05bpw", "K6.0")]
CTX, ROWS, B70_GIB, RESERVE = 4096, 1, 31.9, 1.5


def counts_for(sub, E):
    for f in glob.glob(os.path.expanduser("~/.cache/exllamav3/expert_stats/*.json")):
        d = json.load(open(f))
        if sub in str(d.get("model_dir", "")) and isinstance(d.get("layers"), dict):
            L = d["layers"]
            if len(L[sorted(L)[0]]) == E:
                return list(L[sorted(L)[0]])
    return None


def interp(band, mib, col):
    if mib <= band[0][0]:
        return band[0][col]
    if mib >= band[-1][0]:
        return band[-1][col]
    for (x0, s0, c0), (x1, s1, c1) in zip(band, band[1:]):
        if x0 <= mib <= x1:
            f = (mib - x0) / (x1 - x0)
            return s0 + f * (s1 - s0) if col == 1 else c0 + f * (c1 - c0)
    return band[-1][col]


def union_mult(counts, topk, E):
    """Distinct experts per layer at b=1/4/8, Monte-Carlo over the real counts (same sampler as
    plan_operating_point.py)."""
    import random
    rng = random.Random(11)
    tot = sum(counts) or 1.0
    p = [c / tot for c in counts]
    out = {}
    for B, tag in ((1, 1), (4, 4), (8, 8)):
        acc = 0
        for _ in range(2000):
            seen = [False] * E
            k = 0
            for _b in range(B):
                for _ in range(topk):
                    r, s, ch = rng.random(), 0.0, E - 1
                    for i in range(E):
                        if seen[i]:
                            continue
                        s += p[i]
                        if s >= r:
                            ch = i
                            break
                    if not seen[ch]:
                        seen[ch] = True
                        k += 1
            acc += k
        out[tag] = acc / 2000.0
    return {1: 1.0, 4: out[4] / out[1], 8: out[8] / out[1]}


def main():
    ppb.selftest()
    print("\nquant  exp MiB  resid GiB  S_g GiB  slots  h/live  CPU ms/tok  dev MiB/L  GB/s  us/layer"
          "  order  lpt   b=8: order  lpt")
    print("=" * 132)
    for lab, dirname, prof, bandk in QUANTS:
        cat = ppb.census(dirname)
        cfg = json.load(open(os.path.join(ppb.ROOT, dirname, "config.json")))
        tc = cfg.get("text_config", cfg)
        nl = tc["num_hidden_layers"]
        E = tc.get("n_routed_experts") or tc.get("num_experts")          # GLM and Qwen spell it differently
        topk = tc.get("num_experts_per_tok") or tc.get("topk")
        layers = min(nl, 48)
        eb = cat["routed"] / nl / E / 2**20
        st = ppb.state_budget(cfg)
        kv = st["tok_kib"] * 1024 * CTX * ROWS / 2**30
        seq = st["lin_mib"] / 1024 * ROWS
        sg_gib = max(0.0, 24.0 - cat["read"] / 2**30 - kv - seq - RESERVE)
        slots = sg_gib * 2**30 / (eb * 2**20) / layers
        cnt = counts_for(prof, E)
        if cnt is None:
            print(f"{lab:>5s}  {eb:6.3f}   (no routing profile)")
            continue
        tot = sum(cnt) or 1.0
        # The persisted profiles are decayed cumulatives: experts that never fired sit at ~1e-27, so
        # "h = 100.0 %" can be a dust artifact rather than residency. Report the LIVE count alongside.
        mx = max(cnt)
        live = sum(1 for c in cnt if c > 1e-6 * mx)          # experts with a real (non-dust) count
        order = sorted(cnt, reverse=True)
        n_res = min(E, int(slots) + int(B70_GIB * 2**30 / (eb * 2**20) / layers))
        h = sum(order[:n_res]) / tot
        cpu_ms = (1 - h) * topk * eb * 1048576.0 / (ppb.CPU_RATE * 1e3) * layers / 1000.0
        um = union_mult(cnt, topk, E)
        band = BANDS[bandk]
        dev_mib = h * topk * um[1] * eb
        rate = interp(band, dev_mib, 1)
        us = dev_mib * 1048576.0 / (rate * 1000.0)
        cap_b = B70_GIB * 1024 / layers

        def wall(scale, lpt, tparent=250.0):
            w, (ug, ub, uc), _ = ppb.policy(lpt, cnt, E, eb, sg_gib * 1024 / layers, cap_b,
                                            936.0, interp(band, dev_mib, 1), tparent, topk, scale)
            return w
        w1o, w1l = wall(1.0, False), wall(1.0, True)
        w8o, w8l = wall(um[8], False), wall(um[8], True)
        print(f"{lab:>5s}  {eb:6.3f}  {cat['routed']/2**30:8.2f}  {sg_gib:7.2f} {slots:6.1f}  "
              f"{h*100:5.1f}%/{live:3d}L {cpu_ms:7.2f}    {dev_mib:7.1f}  {rate:5.0f}  {us:8.0f}  "
              f"{w1o:6.0f} {w1l:5.0f}   {w8o:8.0f} {w8l:5.0f}  {'lpt' if w8l < w8o-1 else 'order/tie'}")
    print("""What changes with bits, and what does not
* expert_bytes drives everything. From 2.68 to 6.05 bpw it grows 2.4x, so with the same two slices the
  resident COUNT per layer falls 512 -> ~104, h falls, and the CPU residue - the term that makes the
  fair split harmful - becomes the binding one.
* The matched rate does not collapse: K=4/5/6 tiles measure 207-295 GB/s scattered, the same band as
  K=2.5/3.0, so the B70's per-byte cost grows only because there are more bytes per expert. (One K=6
  point read 754 GB/s, above the 674 GB/s copy peak, and is discarded rather than believed.)
* The parent's duty cycle stays 31-45% across all five quants because the recipe does not quantise the
  streamed non-expert weights in proportion to the experts. That is why §2.1a's "3090 is latency-bound,
  with spare bandwidth" holds at every recipe on this model, not just at 2.68.
* h/live column: h is the pick-mass upper bound from the decayed cumulative profile, `NNNL` is how many
  experts have a non-dust count. Where slots exceed the live set the 100.0 % readings are honest (every
  expert that ever fires is homed); where slots fall below it (4.05, 6.05) the residue is real, and the
  CPU term that follows is what decides the policy contest below.
* Banding gets mildly more attractive as tiles fatten: banded/native reaches 1.06-1.07x at 64-128 MiB
  for K=5/6 versus 0.96-1.05x at K=2.5/3.0. Still inconsistent in sign across footprints, so it stays
  an E4c question rather than a decision - but "repacking buys nothing" was measured on thin tiles, and
  the fatter the tile, the more per-item contiguity should matter. That trend is now on the record.
* The §2.1a policy rule survives and predicts itself: the fair split (lpt) wins at b=8 for every quant
  whose residue is zero or dust-small (2.05/2.68/5.05, and 4.05 by a narrow 3%), and loses at 6.05
  (order 547 vs lpt 782 us/layer) exactly where a real 9.6% CPU residue has to be protected. So one
  sentence covers all recipes: pick the rule by whether the residue term binds, which is what
  EXL3_MOE_B70_BALANCE=auto does, and its input h should be read against the LIVE expert count, not the
  dust-inflated upper bound.""")


if __name__ == "__main__":
    main()