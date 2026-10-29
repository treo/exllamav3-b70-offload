#!/usr/bin/env python3
"""Correctness gate + rate matrix for probe_gemv rev C.

Gate: rev B (submit<>) is bit-exact against tests/testlib/trellis.py, and every rev C partial is an
int32 integer sum, so the k-slice / subset / column-pair regrouping cannot change the value - rev C
must equal rev B BIT FOR BIT at any shape, not merely approximately. That is a much wider gate than
the one case that has y_ref.npy, so it is what we run everywhere.

Usage: gate_gemv.py BIN [cases...] [--rows 1,4,8] [--ks 1,4,8,16] [--orders 0,1] [--rates]
"""
import argparse, json, os, re, subprocess, sys

import numpy as np

RUN = re.compile(r"^\s*(?:clustered|scattered)|^impl (\d) order (\d) \(.*?\):\s+([\d.]+) us\s+([\d.]+) GB/s")


def run(bin_, case, order, reps, rows, impl, ks):
    cmd = [bin_, case, str(order), str(reps), str(rows), str(impl), str(ks)]
    p = subprocess.run(cmd, capture_output=True, text=True)
    if p.returncode != 0:
        return None, (p.stdout + p.stderr).strip().splitlines()[-1:]
    us = gb = None
    for line in p.stdout.splitlines():
        m = RUN.match(line)
        if m and m.group(1):
            us, gb = float(m.group(3)), float(m.group(4))
    return (us, gb), p.stdout


def yfile(case, order, impl):
    return os.path.join(case, f"y_dev_order{order}_impl{impl}.bin")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("bin")
    ap.add_argument("cases", nargs="+")
    ap.add_argument("--rows", default="1,4,8")
    ap.add_argument("--ks", default="1,4,8,16")
    ap.add_argument("--orders", default="0,1")
    ap.add_argument("--reps", type=int, default=5)
    args = ap.parse_args()

    rows_l = [int(v) for v in args.rows.split(",")]
    ks_l = [int(v) for v in args.ks.split(",")]
    orders = [int(v) for v in args.orders.split(",")]

    print(f"{'case':>10} {'R':>4} {'ks':>3} {'ord':>4} {'us':>10} {'GB/s':>8}  gate")
    nfail = 0
    for case in args.cases:
        meta = json.load(open(os.path.join(case, "meta.json")))
        rb = {}
        for rows in rows_l:
            if rows > meta["R"]:
                print(f"{os.path.basename(case):>10} {rows:>4}  --  skipped: fixture has R={meta['R']}")
                continue
            for order in orders:
                run(getattr(args, "bin"), case, order, args.reps, rows, 0, 1)
                rb[(rows, order)] = np.fromfile(yfile(case, order, 0), dtype=np.float32)
            for ks in ks_l:
                for order in orders:
                    got, _ = run(getattr(args, "bin"), case, order, args.reps, rows, 1, ks)
                    yc = np.fromfile(yfile(case, order, 1), dtype=np.float32)
                    same = bool(np.array_equal(yc, rb[(rows, order)]))
                    if not same:
                        nfail += 1
                    us, gb = got if got else (float("nan"), float("nan"))
                    print(f"{os.path.basename(case):>10} {rows:>4} {ks:>3} {order:>4} "
                          f"{us:>10.1f} {gb:>8.1f}  {'bit-exact vs revB' if same else 'MISMATCH'}")
    print(f"\ngate failures: {nfail}")
    return 1 if nfail else 0


if __name__ == "__main__":
    sys.exit(main())