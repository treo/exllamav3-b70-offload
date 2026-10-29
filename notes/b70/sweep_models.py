#!/usr/bin/env python3
"""sweep_models.py - measure the real mul1 trellis GEMV at every MoE geometry on disk.

Why this exists: every rate in the design so far came from ONE geometry (Qwen3.8 layer 0, k=2560,
n=640, K=3.0). The checkpoints on disk differ from that in three ways that all reach the kernel:

  * k and n per projection differ, and down_proj transposes them (GLM k=2048/n=4096, Qwen3.5/3.6
    down k=512/n=2048), changing accumulations per output and how an activation load amortises;
  * trellis K (bits per weight) spans 2..6 across recipes, changing bytes per weight and the ring
    stride the extractor walks;
  * tn spans 32..256, and tn is a grid dimension, so the same expert count yields 8x different
    work-group counts.

Estimator: min over REPEAT interleaved runs of (median over REPS internally timed iterations), with
configs interleaved rather than blocked - single medians at small shapes swing +-40% (LESSONS 28).

Phases:
  --validate  one case per distinct trellis K, with a NumPy reference, checking rev B AND rev C
              bit-exact. Rates at a recipe are meaningless until this passes for that recipe; the
              dumper's reference path used to refuse K != 3.0 outright.
  --sweep     model x projection x experts x rows grid for rev B and rev C, then the derived
              per-layer decode time (2 x gate + down: gate and up share a shape but are separate
              reads).
"""
import argparse, json, os, re, shutil, subprocess, sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = "/home/treo/projects/vendor/tabbyAPI/models"
PROBE = os.environ.get("PROBE", os.path.join(HERE, "probe_gemv"))
DUMPER = os.path.join(HERE, "dump_gemv_case.py")
TIMED = re.compile(r"^impl (\d) order (\d) \(.*?\):\s+([\d.]+) us\s+([\d.]+) GB/s\s+([\d.]+) "
                   r"G-weights/s.*?round trip\s+([\d.]+) us\s+=\s+([\d.]+) GB/s,\s+([\d.]+)", re.M)
# interleaved repeats per config; 3 keeps the whole grid inside a coffee break, and the spread column
# below is what tells you whether 3 was enough (LESSONS 28: single medians at small shapes lie)
REP = int(os.environ.get("REPEAT", "3"))


def discover():
    """Every MoE checkpoint on disk, geometry read from the tensors and config, never hardcoded."""
    from safetensors import safe_open
    out = []
    for name in sorted(os.listdir(ROOT)):
        d = os.path.join(ROOT, name)
        if not os.path.isdir(d):
            continue
        cfg = json.load(open(os.path.join(d, "config.json")))
        tc = cfg.get("text_config", cfg)
        g = lambda *ns: next((tc[n] for n in ns if n in tc), None)
        topk = g("num_experts_per_tok", "topk", "moe_topk")
        nex = g("n_routed_experts", "num_experts")
        idx = os.path.join(d, "model.safetensors.index.json")
        if not (topk and nex and os.path.exists(idx)):
            continue                                       # dense: no routed experts to measure
        wm = json.load(open(idx))["weight_map"]
        shapes, layer = {}, None
        for proj in ("gate_proj", "up_proj", "down_proj"):
            hit = next((k for k in wm if f".experts.0.{proj}.trellis" in k), None)
            if hit is None:
                continue
            # which layer holds the experts comes from the index: GLM's first MoE layer is not 0
            ml = re.search(r"layers\.(\d+)\.mlp\.experts\.0\.", hit)
            if ml:
                layer = int(ml.group(1)) if layer is None else layer
            with safe_open(os.path.join(d, wm[hit]), framework="pt") as f:
                tk, tn, last = (int(v) for v in f.get_tensor(hit).shape)
            shapes[proj] = dict(tk=tk, tn=tn, K=last // 16, bytes_p=tk * tn * last * 2)
        if len(shapes) == 3 and layer is not None:
            out.append(dict(name=name, topk=int(topk), experts=int(nex), layer=layer,
                            layers=int(g("num_hidden_layers") or 0), shapes=shapes))
    return out


def dump(case, model, proj, E, R, ref=False, layer=0):
    shutil.rmtree(case, ignore_errors=True)
    cmd = [sys.executable, DUMPER, case, str(E), str(R), str(layer), "--ckpt", model, "--proj", proj]
    if ref:
        cmd.append("--with-reference")
    p = subprocess.run(cmd, capture_output=True, text=True)
    if p.returncode != 0:
        raise RuntimeError((p.stdout + p.stderr).strip().splitlines()[-1][:200:])
    return p.stdout.strip().splitlines()[-1]


def one_run(case, order, reps, rows, impl, ks):
    p = subprocess.run([PROBE, case, str(order), str(reps), str(rows), str(impl), str(ks)],
                       capture_output=True, text=True)
    if p.returncode != 0:
        return None
    m = TIMED.search(p.stdout)
    if not m:
        return None
    # (tp_us, tp_gbps, tp_gw, lat_us, lat_gbps, lat_gw)
    return tuple(float(m.group(i)) for i in (3, 4, 5, 6, 7, 8))


def best_of(case, rows, impl, ks, reps=11, repeat=REP):
    """min-of-`repeat` interleaved runs, ranked on throughput mode; None if unsupported."""
    v = [x for x in (one_run(case, 0, reps, rows, impl, ks) for _ in range(repeat)) if x]
    if not v:
        return None
    b = min(v, key=lambda x: x[0])          # fastest sustained run
    spread = (max(x[0] for x in v) - b[0]) / b[0] * 100.0
    return b + (spread,)


def gate_exact(case, impl):
    ref = np.load(os.path.join(case, "y_ref.npy")).astype(np.float32)
    got = np.fromfile(os.path.join(case, f"y_dev_order0_impl{impl}.bin"), dtype=np.float32)
    if got.size != ref.size:
        return f"shape {got.size} != {ref.size}"
    return "bit-exact" if bool(np.array_equal(got.reshape(ref.shape), ref)) else "MISMATCH"


def validate(models, tmp):
    print("=== numerics per trellis recipe (K = bits per weight in the ring) ===")
    print(f"{'K':>2} {'model':<26} {'shape':>14}  revB          revC")
    seen, ok = set(), True
    for m in models:
        sh = m["shapes"]["gate_proj"]
        K = sh["K"]
        if K in seen:
            continue
        seen.add(K)
        case = os.path.join(tmp, f"val_K{K}")
        try:
            dump(case, m["name"], "gate_proj", 2, 4, ref=True, layer=m["layer"])
        except RuntimeError as e:
            print(f"{K:>2} {m['name']:<26}  dump/reference failed: {e}")
            ok = False
            continue
        res = []
        for impl in (0, 1):
            one_run(case, 0, 1, 0, impl, 1)
            res.append(gate_exact(case, impl))
        ok &= all(r == "bit-exact" for r in res)
        shape = f"k{sh['tk'] * 16} n{sh['tn'] * 16}"
        print(f"{K:>2} {m['name']:<26} {shape:>14}  {res[0]:<13} {res[1]}")
    print(f"validate: {'ALL RECIPES BIT-EXACT' if ok else 'FAILURES PRESENT'}")
    return 0 if ok else 1


def sweep(models, tmp, es_l, rows_l, ks_l):
    print("\n=== decode rate at each model's own geometry ===")
    print("# revC is ranked on the sustained (burst-of-16) mode. For planning, use the lat column:")
    print("# b=1 decode keeps the card at a few percent duty cycle, so it runs at boost clocks with one")
    print("# completion round trip per layer; lat includes that ~5 us tax, so it is the conservative one.")
    print(f"{'model':<26} {'proj':<10} {'k':>5} {'n':>5} {'K':>2} {'tn':>4} {'E':>3} {'R':>2} "
          f"{'revB lat':>9} {'revC tp':>8} {'revC lat':>9} {'ks':>3} "
          f"{'tp GB/s':>8} {'tp Gw/s':>8} {'lat Gw/s':>9} {'sprd':>6}")
    per, recs = {}, []
    for m in models:
        for proj in ("gate_proj", "down_proj"):
            sh = m["shapes"][proj]
            for E in sorted(set([e for e in es_l if e <= min(m["experts"], 2 * m["topk"])] + [m["topk"]])):
                case = os.path.join(tmp, f"{m['name'][:20]}_{proj}_E{E}")
                try:
                    dump(case, m["name"], proj, E, max(rows_l), layer=m["layer"])
                except RuntimeError as e:
                    print(f"{m['name'][:26]:<26} {proj:<10} dump failed: {e}")
                    continue
                for rows in rows_l:
                    b = one_run(case, 0, 11, rows, 0, 1)
                    best = None
                    for ks in ks_l:
                        r = best_of(case, rows, 1, ks)
                        if r and (best is None or r[0] < best[0]):
                            best = r + (ks,)
                    if not best:
                        print(f"{m['name'][:26]:<26} {proj:<10} -- no result (E {E}, rows {rows})")
                        continue
                    tp_us, tp_gb, tp_gw, lat_us, lat_gb, lat_gw, spread, ks = best
                    per[(m["name"], proj, E, rows)] = dict(tp=tp_us, lat=lat_us)
                    recs.append(dict(model=m["name"], proj=proj, K=sh["K"], tn=sh["tn"], E=E, rows=rows,
                                     tp_gb=tp_gb, tp_gw=tp_gw, lat_gb=lat_gb, lat_gw=lat_gw,
                                     tp_us=tp_us, lat_us=lat_us, revb_lat=(b[3] if b else None),
                                     weights=E * sh["tk"] * sh["tn"] * 256))
                    if b:
                        print(f"{m['name'][:26]:<26} {proj:<10} {sh['tk']*16:>5} {sh['tn']*16:>5} "
                              f"{sh['K']:>2} {sh['tn']:>4} {E:>3} {rows:>2} "
                              f"{b[3]:>9.1f} {tp_us:>8.1f} {lat_us:>9.1f} {ks:>3} "
                              f"{tp_gb:>8.1f} {tp_gw:>8.1f} {lat_gw:>9.1f} {spread:>5.1f}%")

    # The comparable metric across recipes is weights/s, not bytes/s: at K bits per weight,
    # GB/s = G-w/s * K / 8, so a rate in GB/s cannot be compared between 2.05 and 6.05 bpw.
    print("\n=== is decode limited by bytes or by weights? pool every measurement by trellis K ===")
    print(f"{'K':>2} {'n':>4} {'median lat G-w/s':>17} {'median lat GB/s':>16} {'predicted GB/s at 200 G-w/s':>26}")
    for K in sorted({r["K"] for r in recs}):
        v = [r for r in recs if r["K"] == K]
        gw = float(np.median([r["lat_gw"] for r in v]))
        gb = float(np.median([r["lat_gb"] for r in v]))
        print(f"{K:>2} {len(v):>4} {gw:>17.1f} {gb:>16.1f} {200.0 * K / 8.0:>26.1f}")
    print("\n=== and by grid width tn (tn is a grid dimension, so it sets work-groups = E * tn) ===")
    print(f"{'tn':>4} {'groups=E*tn':>12} {'n':>4} {'median lat G-w/s':>17}")
    for tn in sorted({r["tn"] for r in recs}):
        v = [r for r in recs if r["tn"] == tn]
        print(f"{tn:>4} {v[0]['E'] * tn if v else 0:>12} {len(v):>4} "
              f"{float(np.median([r['lat_gw'] for r in v])):>17.1f}")

    print("\n=== derived per-layer decode time (2 x gate + down, latency mode, E = topk) ===")
    print(f"{'model':<26} {'R':>2} {'E':>3} {'MiB/layer':>9} {'gate lat':>9} {'down lat':>9} "
          f"{'layer us':>9} {'GB/s':>7} {'G-w/s':>7} {'tok/s ceiling':>13}")
    for m in models:
        for rows in rows_l:
            E = m["topk"]
            kg = per.get((m["name"], "gate_proj", E, rows))
            kd = per.get((m["name"], "down_proj", E, rows))
            if not (kg and kd):
                continue
            sh = m["shapes"]
            mib = E * (2 * sh["gate_proj"]["bytes_p"] + sh["down_proj"]["bytes_p"]) / 2**20
            weights = E * (2 * sh["gate_proj"]["tk"] * sh["gate_proj"]["tn"]
                           + sh["down_proj"]["tk"] * sh["down_proj"]["tn"]) * 256
            layer_us = 2 * kg["lat"] + kd["lat"]
            rate = mib * 2**20 / (layer_us * 1e-6) / 1e9
            gw = weights / (layer_us * 1e-6) / 1e9
            tok = 1e6 / (layer_us * m["layers"])   # ignores parent, link, attention: a ceiling
            print(f"{m['name'][:26]:<26} {rows:>2} {E:>3} {mib:>9.2f} {kg['lat']:>9.1f} "
                  f"{kd['lat']:>9.1f} {layer_us:>9.1f} {rate:>7.1f} {gw:>7.1f} {tok:>13.1f}")
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--validate", action="store_true")
    ap.add_argument("--sweep", action="store_true")
    ap.add_argument("--es", default="1,2,4,8")
    ap.add_argument("--rows", default="1,4,8")
    ap.add_argument("--ks", default="1,4")
    ap.add_argument("--tmp", default="/tmp/gemv_m")
    args = ap.parse_args()
    os.makedirs(args.tmp, exist_ok=True)
    models = discover()
    print(f"# {len(models)} MoE checkpoints: " + ", ".join(
        f"{m['name'].split('-exl3')[0].split('@')[0]} topk{m['topk']}/{m['experts']}e K{m['shapes']['gate_proj']['K']}"
        for m in models))
    rc = 0
    if args.validate or not args.sweep:
        rc |= validate(models, args.tmp)
    if args.sweep:
        rc |= sweep(models, args.tmp, [int(v) for v in args.es.split(",")],
                    [int(v) for v in args.rows.split(",")], [int(v) for v in args.ks.split(",")])
    return rc


if __name__ == "__main__":
    sys.exit(main())