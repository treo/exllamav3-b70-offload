#!/usr/bin/env python
"""
Expert-set capacity and cache economics for the B70 offload (dev scaffolding).

Answers the two questions doc/port/b70-architecture.md §4a is about, per checkpoint that is present,
straight from the safetensors headers (no model load):

  how much routed-expert trellis is there, and what fraction of it fits each tier;
  given the measured rates, what does an admission cost, when is it worth it, and what hit rate must
  the placement policy reach for the cache to converge at decode.

The economics are all ratios of byte-proportional rates, so they are stable across models; what
changes is expert_bytes, which sets both the admission latency and the per-layer prefetch pressure.

usage:
    python scan_expert_capacity.py                      # every model under the default root
    python scan_expert_capacity.py --capacity 31.9      # GiB of offload-device VRAM
    python scan_expert_capacity.py --link 14.4 --cpu 47.4 --dev 420 --layer-us 400
"""
import argparse
import glob
import json
import os
import re
import struct
import sys
from collections import defaultdict

DEFAULT_ROOT = "/home/treo/projects/vendor/tabbyAPI/models"
PROJ = ("gate_proj", "up_proj", "down_proj")
EXP_RE = re.compile(r"^(.*)\.experts\.(\d+)\.(%s)\.trellis$" % "|".join(PROJ))
DTYPE_SIZE = {"I32": 4, "U32": 4, "I16": 2, "U16": 2, "F16": 2, "BF16": 2, "I8": 1, "U8": 1, "F32": 4}


def header(path):
    with open(path, "rb") as f:
        n = struct.unpack("<Q", f.read(8))[0]
        return json.loads(f.read(n).decode())


def text_config(model_dir):
    """hidden_size / n_routed_experts / num_experts_per_tok, wherever the config nests them"""
    try:
        with open(os.path.join(model_dir, "config.json")) as f:
            c = json.load(f)
    except Exception:                                              # noqa: BLE001
        return {}
    for cand in (c, c.get("text_config", {}), c.get("llm_config", {})):
        if isinstance(cand, dict) and ("hidden_size" in cand or "n_routed_experts" in cand):
            return cand
    return c


def census(model_dir):
    """(expert_bytes per expert, layer count, experts per layer, total trellis bytes) from headers"""
    per = defaultdict(lambda: [0, 0])     # (layer, expert) -> [bytes, projections seen]
    layers = set()
    experts = defaultdict(set)
    other = 0
    for st in sorted(glob.glob(os.path.join(model_dir, "*.safetensors"))):
        for k, v in header(st).items():
            if k == "__metadata__":
                continue
            m = EXP_RE.match(k)
            sz = DTYPE_SIZE.get(v.get("dtype", "U16"), 2)
            n = 1
            for d in v["shape"]:
                n *= int(d)
            nbytes = n * sz
            if not m:
                if k.endswith(".trellis"):
                    other += nbytes
                continue
            layer, e = m.group(1), int(m.group(2))
            per[(layer, e)][0] += nbytes
            layers.add(layer)
            experts[layer].add(e)
    if not per:
        return None
    # Split by module family: an MTP / draft head carries its own experts, often at a different
    # rate (Qwen3.5's MTP experts are 4 bpw against the text model's 3 bpw), and it is a separate
    # capacity consumer that every speculative verify step touches. Lumping them reports the wrong
    # per-expert size for the tier math.
    fams = defaultdict(lambda: dict(bytes=[], layers=set(), experts=set()))
    for (layer, e), (nb, _) in per.items():
        fam = layer.split(".layers.")[0]
        fams[fam]["bytes"].append(nb)
        fams[fam]["layers"].add(layer)
        fams[fam]["experts"].add((layer, e))
    out = {}
    for fam, v in fams.items():
        pl = {l: sum(per[(l, e)][0] for e in experts[l] if (l, e) in v["experts"]) for l in v["layers"]}
        out[fam] = dict(expert_bytes=max(v["bytes"]), expert_bytes_min=min(v["bytes"]),
                        n_experts=len(v["experts"]), n_layers=len(v["layers"]),
                        total=sum(v["bytes"]), per_layer=pl)
    return dict(families=out, other=other)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=DEFAULT_ROOT)
    ap.add_argument("--capacity", type=float, default=31.9, help="offload-tier VRAM, GiB")
    ap.add_argument("--link", type=float, default=14.4, help="measured pinned<->device GB/s")
    ap.add_argument("--cpu", type=float, default=47.4, help="CPU worker expert read rate, GB/s")
    ap.add_argument("--dev", type=float, default=420.0, help="achieved expert read rate on the device, GB/s")
    ap.add_argument("--disk", type=float, default=5.0, help="checkpoint read rate, GB/s")
    ap.add_argument("--layer-us", type=float, default=400.0, help="parent GPU work per MoE layer, us")
    a = ap.parse_args()
    cap = a.capacity * (1 << 30)

    print(f"tiers: offload VRAM {a.capacity:g} GiB, link {a.link} GB/s, CPU {a.cpu} GB/s, "
          f"device {a.dev} GB/s, disk {a.disk} GB/s, parent layer work {a.layer_us:g} us\n")
    hdr = (f"{'checkpoint':44s} {'E':>5s} {'experts':>8s} {'exp MiB':>8s} {'total GiB':>10s} "
           f"{'fit %':>6s} {'quota/lay':>9s} {'admit ms':>9s} {'CPU/use':>8s} {'brk-even':>8s} {'h_min':>6s}")
    print(hdr)
    print("-" * len(hdr))
    for d in sorted(os.listdir(a.root)):
        md = os.path.join(a.root, d)
        if not os.path.isdir(md):
            continue
        c = census(md)
        if not c:
            print(f"{d[:44]:44s} {'-':>5s}  (no routed experts)")
            continue
        cfg = text_config(md)
        topk = cfg.get("num_experts_per_tok") or cfg.get("top_k") or 0
        # the tier math uses the *text model* family (the one every token walks); other families are
        # reported as extra capacity in the trailing column
        fams = c["families"]
        fam = "model.language_model" if "model.language_model" in fams else \
              max(fams, key=lambda k: fams[k]["total"])
        extra = sum(f["total"] for k, f in fams.items() if k != fam)
        c = fams[fam]
        eb = c["expert_bytes"]
        fit = min(1.0, cap / c["total"])
        quota = cap / c["n_layers"] / eb
        admit = eb / (a.link * 1e9) * 1e6
        cpu_use = eb / (a.cpu * 1e9) * 1e6
        dev_use = eb / (a.dev * 1e9) * 1e6
        be = admit / max(1e-9, cpu_use - dev_use)
        budget = a.link * 1e9 * a.layer_us * 1e-6                 # bytes prefetchable per layer
        hmin = float("nan") if not topk else max(0.0, 1.0 - budget / (topk * eb))
        print(f"{d[:44]:44s} {topk:>5d} {c['n_experts'] / c['n_layers']:>8.0f} {eb / 2**20:>8.2f} "
              f"{c['total'] / 2**30:>10.2f} {100 * fit:>6.1f} {quota:>9.1f} {admit / 1000:>9.3f} "
              f"{cpu_use:>7.0f}u {be:>8.1f} {100 * hmin:>5.1f}%"
              + ("  <-- oversized: prefetch alone cannot converge" if topk and hmin > 0.90 else "")
              + (f"   +{extra / 2**30:.1f} GiB in other families (MTP/draft)" if extra else ""))
    print("""
columns:  fit %   = fraction of the routed-expert trellis that fits one offload tier
          quota/lay = experts per layer if capacity is split evenly by bytes across layers (§4a rule 2)
          admit ms  = one expert uploaded over the link;  add expert_bytes/disk for the S_d path
          brk-even  = uses per window before admission pays for itself (scale-invariant, ~3-4)
          h_min     = 1 - link*T_layer/(topk*expert_bytes): the hit rate the cache must exceed
Read h_min > 90 % as: the model needs more than one B70, or the CPU worker must serve the misses.""")
    return 0


if __name__ == "__main__":
    sys.exit(main())
