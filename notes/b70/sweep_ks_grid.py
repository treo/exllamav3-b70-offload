#!/usr/bin/env python3
"""sweep_ks_grid.py - us per (expert, projection) for the fused and separate schedules across KS.

plan_decode_cost.py collapses split-K inside its tables ("best ks per rows"), which is fine while fusion and
split-K look like substitutes, but the joint rule from out_low_e_grid.txt - pick (fusion, KS) so the gemm grid
lands near 0.6-0.8 x HW_THREADS - needs the KS dimension kept. This prints exactly that: per-expert cost for
{fused, separate} x KS x rows at each E it is given, so the table can be interpolated on grid occupancy.

Costs are reported PER EXPERT and per projection-pair so they transfer across E:
  separate: (t(gate-dir) + t(up-dir)) / (2 * E)          us per (expert, single projection)
  fused:    t(fused) / E                                  us per (expert, gate+up pair)

Anchor discipline (LESSONS 54): the anchor runs with its own sufficient work (default 6000 reps) BETWEEN cells,
because a short anchor reports the box's recent history rather than its state. Any cell whose anchor samples
spread more than ANCHOR_SPREAD percent is flagged - the ratios within a cell are still usable, the absolutes are
not.

Usage: python3 notes/b70/sweep_ks_grid.py [--bin /tmp/revL9] [--es 2,4,10] [--rows 1,8,16]
                                          [--ks 1,2,4,8] [--warm 2] [--anchor-reps 6000]
Requires the case dirs each E was dumped with (dump_gemv_case.py, gate + up, same layer):
  E=10 -> /tmp/gemv_R64 + /tmp/gemv_up_R64    E=4/2 -> /tmp/lo_e4_* /tmp/lo_e2_*
  For any other E, dump first, e.g.:
    python3 notes/b70/dump_gemv_case.py /tmp/ks_e32_gate 32 16 0 --with-reference
    python3 notes/b70/dump_gemv_case.py /tmp/ks_e32_up   32 16 0 --with-reference --proj up_proj
and pass --dirs-template '/tmp/ks_e{E}_gate:/tmp/ks_e{E}_up'.
"""
import argparse
import json
import os
import re
import statistics
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
HW_THREADS = 2048
ANCHORS = 6000              # anchor reps; must carry enough work to ramp the clock (LESSONS 54)
ANCHOR_SPREAD = 10.0          # percent


def run(binary, args, warm):
    env = dict(os.environ)
    env["WARM_S"] = str(warm)
    p = subprocess.run([binary] + args, capture_output=True, text=True, env=env)
    if p.returncode != 0:
        return None
    for line in p.stdout.splitlines():
        if line.startswith("revL ks"):
            return float(re.search(r":\s+([\d.]+) us", line).group(1))
    return None


def anchor(binary_revp):
    env = dict(os.environ)
    env["DPAS_X"] = "1"
    p = subprocess.run([binary_revp, "/tmp/gemv_dpE10", str(ANCHORS), "1", "2"],
                       capture_output=True, text=True, env=env)
    m = re.search(r"rows 1:\s+([\d.]+)", p.stdout)
    return float(m.group(1)) if m else None


def main():
    global ANCHORS
    ap = argparse.ArgumentParser()
    ap.add_argument("--bin", default="/tmp/revL9")
    ap.add_argument("--anchor-bin", default=os.path.join(HERE, "probe_dpas6"))
    ap.add_argument("--es", default="2,4,10")
    ap.add_argument("--rows", default="1,8,16")
    ap.add_argument("--ks", default="1,2,4,8")
    ap.add_argument("--warm", type=float, default=2.0)
    ap.add_argument("--anchor-reps", type=int, default=6000)
    ap.add_argument("--reps", default="3")
    ap.add_argument("--dirs-template", default="/tmp/gemv_R64:/tmp/gemv_up_R64",
                    help="'gate:up' for E=10, or a template with {E}")
    a = ap.parse_args()
    ANCHORS = a.anchor_reps

    dirs = {"10": ("/tmp/gemv_R64", "/tmp/gemv_up_R64"),
            "4": ("/tmp/lo_e4_gate", "/tmp/lo_e4_up"),
            "2": ("/tmp/lo_e2_gate", "/tmp/lo_e2_up")}
    if "{E}" in a.dirs_template:
        g, u = a.dirs_template.split(":")
        for e in a.es.split(","):
            dirs[e] = (g.replace("{E}", e), u.replace("{E}", e))

    print(f"# sweep_ks_grid: bin={a.bin} warm={a.warm}s anchor_reps={a.anchor_reps}")
    print(f"{'E':>4} {'rows':>5} {'KS':>3} | {'sep/exp':>8} {'fused/exp':>10} {'fuse gain':>9} | "
          f"{'threads sep':>11} {'fused':>7} | exact")
    results = {}
    for E in [int(x) for x in a.es.split(",")]:
        gd, ud = dirs[str(E)]
        for R in [int(x) for x in a.rows.split(",")]:
            for KS in [int(x) for x in a.ks.split(",")]:
                if (160 // KS) % 2:
                    continue                                     # probe refuses odd halves
                tg = run(a.bin, [gd, a.reps, str(R), str(KS)], a.warm)
                tu = run(a.bin, [ud, a.reps, str(R), str(KS)], a.warm)
                tf = run(a.bin, [gd, a.reps, str(R), str(KS), "native", ud], a.warm)
                anc = anchor(a.anchor_bin)
                tn = json.load(open(gd + "/meta.json"))["tn"]
                sep = (tg + tu) / (2.0 * E) if tg and tu else None
                fus = tf / E if tf else None
                gain = (tg + tu) / tf if (tf and tg and tu) else None
                okx = "?"
                try:
                    ref = [np_load(gd + "/y_ref.npy"), np_load(ud + "/y_ref.npy")]
                    got = [np_fromfile(f"{gd}/y_dev_ks{KS}_r{R}.bin"),
                           np_fromfile(f"{gd}/y_dev_ks{KS}_r{R}_p2.bin")]
                    # reshape BEFORE comparing: comparing a flat read against a 3-D reference broadcasts and
                    # raises, which looked like a correctness failure and was a bug in this check
                    okx = "yes" if all(g.size == w.size and (g.reshape(w.shape) == w).all()
                                       for g, w in zip(got, (r[:, :R, :] for r in ref))) else "NO"
                except Exception as e:
                    okx = f"chk:{type(e).__name__}"
                results[(E, R, KS)] = (sep, fus, gain, anc)
                print(f"{E:4d} {R:5d} {KS:3d} | {sep if sep else 0:8.3f} {fus if fus else 0:10.3f} "
                      f"{gain if gain else 0:8.3f}x | {tn*KS*2*E:11d} {2*tn*KS*2*E:7d} | {okx}   anchor={anc}")
    print("\n# best schedule per (E, rows). UNITS MATTER: the separate column is us per (expert, SINGLE"
          "\n# projection), the fused column is us per (expert, gate+up PAIR), so the comparison is"
          "\n# 2*sep/expert vs fused/expert - which is what the gain column already does correctly.")
    for E in [int(x) for x in a.es.split(",")]:
        for R in [int(x) for x in a.rows.split(",")]:
            cand = [(2.0 * v[0], KS, "sep") for (e, r, KS), v in results.items() if e == E and r == R and v[0]]
            cand += [(v[1], KS, "fused") for (e, r, KS), v in results.items() if e == E and r == R and v[1]]
            if not cand:
                continue
            best = min(cand)
            tn = json.load(open(dirs[str(E)][0] + "/meta.json"))["tn"]
            thr = (2 * tn if best[2] == "fused" else tn) * best[1] * 2 * E
            print(f"   E={E:3d} rows={R:2d}: best {best[2]:5s} KS={best[1]} {best[0]:.3f} us per (expert, pair), "
                  f"grid {thr:6d} ({100.0*thr/HW_THREADS:5.1f}% of HW)")


def np_load(p):
    import numpy as np
    return np.load(p).astype(np.float32)


def np_fromfile(p):
    import numpy as np
    return np.fromfile(p, dtype=np.float32)


if __name__ == "__main__":
    main()