#!/usr/bin/env python
"""
Placement planner for the multi-home MoE offload (dev scaffolding for doc/port §2.1, §4, §4a).

Everything the last section of the architecture used to *assume* is computable before a single B70
kernel exists, because two ingredients already sit on disk:

  * safetensors headers      -> bytes per expert, per layer, per module family (scan_expert_capacity)
  * expert-stats profiles    -> how often each expert was actually picked, per layer, by real text
                               (~/.cache/exllamav3/expert_stats/<sha1(dir|E)>.json, written by
                               dynamic placement; `layers` maps module -> per-expert decayed counts)

Given those and four measured rates it answers, per layer and per model:

  h        the device-resident pick share for a candidate pair of home sizes  (§4a's central quantity)
  sigma    the spanning fraction: how many rows get computed in more than one piece
  ms/token what the residue on the CPU costs, and what migrating it would cost instead

`h` is exact given the profile (it is just the pick mass inside the resident set). `sigma` is NOT
exact: co-occurrence within a row is not in the profile, so it uses the independence approximation
P(row wholly inside home A) = p_A**topk, which is the assumption E13 exists to falsify against a real
trace. Treat sigma as a lower bound on spanning (independence understates co-occurrence, and
co-occurrence is what makes rows span) and read the trend across home sizes, not the absolute value.

usage:
    python plan_placement.py                       # every model with a profile, default capacities
    python plan_placement.py --b70-gib 31.9 --gpu-gib 2
    python plan_placement.py --model GLM           # substring filter
"""
import argparse
import glob
import importlib.util
import json
import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.path.expanduser("~/.cache/exllamav3/expert_stats")

# the capacity/rate census lives one level up; loaded by path so this stays standalone
_spec = importlib.util.spec_from_file_location("sec", os.path.join(HERE, "..", "scan_expert_capacity.py"))
sec = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(sec)


def profiles():
    """(model_dir, {layer_module: [counts]}) for every profile on disk"""
    out = []
    for f in sorted(glob.glob(os.path.join(CACHE, "*.json"))):
        try:
            with open(f) as fh:
                d = json.load(fh)
        except Exception:                                          # noqa: BLE001
            continue
        if isinstance(d, dict) and d.get("model_dir") and isinstance(d.get("layers"), dict):
            out.append((d["model_dir"], d["layers"], f))
    return out


def analyse(model_dir, layers, a):
    cen = sec.census(model_dir)
    if not cen:
        return None
    fams = cen["families"]
    fam = "model.language_model" if "model.language_model" in fams else max(fams, key=lambda k: fams[k]["total"])
    c = fams[fam]
    cfg = sec.text_config(model_dir)
    topk = int(cfg.get("num_experts_per_tok") or cfg.get("top_k") or 0)
    if not topk:
        return None
    eb_max, eb_min = c["expert_bytes"], c["expert_bytes_min"]
    # per-layer expert size, because a model may mix rates across layers (Qwen3.8 @2.68 keeps 2.5 bpw
    # in layers 4-43 and 3 bpw in 0-3/44-47, so a byte budget buys a different number of experts per
    # layer). The census reports per-layer totals under the same '<prefix>.layers.N.mlp' key the
    # profile uses, so dividing by E gives that layer's own expert size.
    per_layer_bytes = c["per_layer"]
    GiB = 1 << 30

    # per-layer pick distributions, restricted to the layers the profile actually covers
    dist = {}
    for mod, cnts in layers.items():
        if ".layers." not in mod or "experts" in mod:
            continue
        v = [max(0.0, float(x)) for x in cnts]
        tot = sum(v)
        if tot <= 0 or len(v) < 8:
            continue
        dist[mod] = (sorted((x / tot for x in v), reverse=True), len(v))
    if not dist:
        return None

    # byte budgets -> expert counts, per layer (experts in one layer share a rate locally, but
    # NOT across layers: Qwen3.8 mixes 2.5 and 3 bpw, so the quota is computed per layer)
    b70_bytes = a.b70_gib * GiB / len(dist)
    gpu_bytes = a.gpu_gib * GiB / len(dist)

    rows, sig_tot, h_tot = [], 0.0, 0.0
    for mod, (p_sorted, e) in dist.items():
        # this layer's own expert size when the census covers it, else the max across layers
        plb = per_layer_bytes.get(mod)
        eb = (plb // e) if plb else eb_max
        if eb <= 0:
            eb = eb_max
        n_b = max(0, min(e, int(b70_bytes // eb)))
        n_g = max(0, min(e - n_b, int(gpu_bytes // eb)))
        pg = sum(p_sorted[:n_g])
        pb = sum(p_sorted[n_g:n_g + n_b])
        pc = 1.0 - pg - pb
        h = pg + pb
        # independence approximation; see the docstring
        single = pg ** topk + pb ** topk + pc ** topk
        sigma = 1.0 - single
        rows.append((mod, e, n_g, n_b, h, sigma, pc))
        h_tot += h
        sig_tot += sigma
    n = len(rows)
    h, sig = h_tot / n, sig_tot / n

    # economics at the measured rates
    eb = eb_max
    cpu_use = eb / (a.cpu * 1e9) * 1e6                      # us per CPU-computed pick
    dev_use = eb / (a.dev * 1e9) * 1e6
    admit = eb / (a.link * 1e9) * 1e6
    per_layer = {}
    distinct_residue = []
    for mod, e, n_g, n_b, hl, s, pc in rows:
        plb = per_layer_bytes.get(mod)
        ebl = (plb // e) if plb else eb
        per_layer[mod] = topk * pc * (ebl / (a.cpu * 1e9) * 1e6)   # us/token of CPU work in this layer
        # distinct experts that a layer actually wants but has no device home for: the size of the
        # set that would have to be migrated in, once. This - not picks - is what admission costs
        # are charged against; an earlier version of this tool charged them per pick and made
        # migration look ~50x more expensive than it is.
        p_raw = [max(0.0, float(x)) for x in layers[mod]]
        distinct_residue.append(sum(1 for x in p_raw[n_g + n_b:] if x > 0.0))
    cpu_ms = sum(per_layer.values()) / 1000.0
    n_res = sum(distinct_residue) / len(distinct_residue)
    # one-time cost of making the residue resident, and the steady-state cost of churning it
    fill_s = n_res * len(rows) * admit / 1e6
    tlayer = a.layer_us or 400.0
    hmin = max(0.0, 1.0 - (a.link * 1e9 * tlayer * 1e-6) / (topk * eb))
    return dict(model=os.path.basename(model_dir.rstrip("/")), layers=n, e=rows[0][1], topk=topk,
                eb=eb, total=c["total"], h=h, sigma=sig, cpu_ms=cpu_ms, fill_s=fill_s, n_res=n_res,
                hmin=hmin, cpu_use=cpu_use, dev_use=dev_use, admit=admit,
                resident=int(b70_bytes // eb) + int(gpu_bytes // eb),
                worst=max(per_layer.values()) / 1000.0, worst_layer=max(per_layer, key=per_layer.get))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--b70-gib", type=float, default=31.9)
    ap.add_argument("--gpu-gib", type=float, default=2.0, help="VRAM the 3090 can spare to experts")
    ap.add_argument("--link", type=float, default=14.4)
    ap.add_argument("--cpu", type=float, default=47.4)
    ap.add_argument("--dev", type=float, default=300.0, help="achieved B70 read rate GB/s (probe_rates scatter figure)")
    ap.add_argument("--layer-us", type=float, default=0.0, help="parent GPU work per MoE layer; 0 = use 400")
    ap.add_argument("--model", default="", help="substring filter on the model dir")
    a = ap.parse_args()

    print(f"capacities: B70 {a.b70_gib:g} GiB, 3090 {a.gpu_gib:g} GiB | rates: link {a.link}, "
          f"cpu {a.cpu}, device {a.dev} GB/s\n")
    hdr = (f"{'model':40s} {'L':>3s} {'E':>4s} {'k':>2s} {'exp':>5s} {'tot GiB':>8s} {'res':>4s} "
           f"{'h':>6s} {'sigma':>6s} {'CPU ms/tok':>10s} {'|res|':>6s} {'fill s':>7s} {'h_min':>6s}")
    print(hdr)
    print("-" * len(hdr))
    seen = set()
    for model_dir, layers, path in profiles():
        if a.model and a.model.lower() not in model_dir.lower():
            continue
        if model_dir in seen:
            continue
        seen.add(model_dir)
        r = analyse(model_dir, layers, a)
        if not r:
            continue
        print(f"{r['model'][:40]:40s} {r['layers']:>3d} {r['e']:>4d} {r['topk']:>2d} "
              f"{r['eb'] / 2**20:>5.2f} {r['total'] / 2**30:>8.2f} {r['resident']:>4d} "
              f"{100 * r['h']:>5.1f}% {100 * r['sigma']:>5.1f}% {r['cpu_ms']:>10.2f} "
              f"{r['n_res']:>6.0f} {r['fill_s']:>7.1f} {100 * r['hmin']:>5.1f}%")
    print(f"""
columns:  res     experts per layer given a home on a device (B70 slice then 3090 slice)
          h       device-resident pick share from REAL routing counts (exact, given the profile)
          sigma   rows computed in more than one piece - independence approximation, see header
          CPU ms  what the CPU-served picks cost per token at {a.cpu} GB/s (steady state, recurrent)
          |res|   distinct experts per layer that have picks but no device home: the migration set
          fill s  link seconds to make that set resident ONCE (one expert upload each); in steady
                  state the recurring cost is only the churn of that set, i.e.
                  |res| x churn_fraction x one upload
          h_min   pick share migration over the link must sustain at T_layer={a.layer_us or 400:g}us
Note the asymmetry that an earlier revision of this tool got wrong: CPU cost accrues per PICK and
never stops, admission cost is paid once per newly resident EXPERT. Comparing them per token requires
the churn rate, which only a live run gives (gate E11); |res| and fill s are its upper bounds.
The profile is a decayed cumulative count from a run whose placement was already adaptive, so h is an
upper bound and |res| a lower bound - E14/E13 measure both honestly from a fresh routing trace.""")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())