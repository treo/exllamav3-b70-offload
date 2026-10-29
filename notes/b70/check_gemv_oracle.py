#!/usr/bin/env python3
"""Independent oracle for probe_gemv: reconstructs the raw int32 accumulator
acc[e,row,n] = sum_k bytesum(win*K * MUL1) * x8[k] from the checkpoint bytes, using
tests/testlib/trellis.py as the authority, and diffs it against whatever the device wrote.

Usage:  check_gemv_oracle.py CASE_DIR [--part FILE] [--y FILE]...

Asserts shapes on purpose: two earlier comparisons silently broadcast and produced
confident nonsense, which cost a whole debug session (LESSONS 26).
"""
import argparse, json, os, sys

import numpy as np

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
from tests.testlib import trellis as TR  # noqa: E402

MUL1_MULT = np.uint32(0x83DCD12D)


def oracle(case, xmode="real"):
    m = json.load(open(os.path.join(case, "meta.json")))
    E, R, tk, tn, K = m["E"], m["R"], m["tk"], m["tn"], int(m["K"])
    k, n = tk * 16, tn * 16
    w = np.fromfile(os.path.join(case, "weights.bin"), dtype=np.int16).reshape(E, tk, tn, 16 * K)
    x8 = np.fromfile(os.path.join(case, "x8.bin"), dtype=np.int8).reshape(R, k)
    if xmode == "zero":
        x8 = np.zeros_like(x8)
    elif xmode == "ones":
        x8 = np.ones_like(x8)

    win = TR.unpack(w.reshape(-1, 16 * K), K).astype(np.uint32)
    prod = (win * MUL1_MULT) & np.uint32(0xFFFFFFFF)
    bs = sum(((prod >> np.uint32(s)) & np.uint32(255)).astype(np.int64) for s in (0, 8, 16, 24))
    perm = TR.tile_perm()
    assert bs.shape[1] == 256 and perm.max() == 255
    bsd = np.empty_like(bs)
    bsd[:, perm] = bs                                   # ring order -> (row, col) inside a tile
    bsd = bsd.reshape(E, tk, tn, 16, 16).transpose(0, 1, 3, 2, 4).reshape(E, k, n)
    assert bsd.shape == (E, k, n), bsd.shape
    acc = np.einsum("ekn,rk->ern", bsd, x8.astype(np.int64))
    assert acc.shape == (E, R, n), acc.shape
    return m, acc, x8, bsd


def report(tag, X, acc):
    X = np.asarray(X)
    assert X.shape == acc.shape, f"{tag}: shape {X.shape} != oracle {acc.shape}"
    d = X.astype(np.int64) - acc
    nz = int((d != 0).sum())
    print(f"{tag:28s} exact={nz == 0!s:5s} mismatching {nz}/{d.size:<6d} "
          f"median {np.median(d):12.0f} sd {d.std():10.0f} min {d.min():12.0f} max {d.max():11.0f}")
    return nz == 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("case")
    ap.add_argument("--part", default="part_dev.bin", help="raw int32 partials dumped by the probe")
    ap.add_argument("--ks", type=int, default=1, help="number of k-slices in --part")
    ap.add_argument("--scale", type=int, default=1, help="multiply --part by this before diffing "
                                                        "(GEMV_ONETILE leaves PART = 4x one tile)")
    ap.add_argument("--xmode", default="real", choices=("real", "zero", "ones"),
                    help="must match the GEMV_ZERO_X / GEMV_ONE_X used for the run")
    args = ap.parse_args()

    m, acc, x8, bsd = oracle(args.case, args.xmode)
    E, R, n = m["E"], m["R"], m["n"]

    ok = True
    q = np.fromfile(os.path.join(args.case, "q.bin"), dtype=np.float32)
    sx8 = x8.astype(np.int64).sum(axis=1)
    y_pred = (m["kinv"] * q[None, :, None] * (acc.astype(np.float64) - 510.0 * sx8[None, :, None]))
    for impl in (0, 1):
        f = os.path.join(args.case, f"y_dev_order0_impl{impl}.bin")
        if not os.path.exists(f):
            continue
        y = np.fromfile(f, dtype=np.float32)
        assert y.size == E * R * n, (y.size, E * R * n)
        if args.xmode != "real":
            got = y.reshape(E, R, n).astype(np.float64)
            d = got - y_pred
            tol = 2.0 ** -20 * np.maximum(np.abs(y_pred), 1.0)   # float32 round-off on these sums
            bad = int((np.abs(d) > tol).sum())
            print(f"{'y impl' + str(impl) + ' vs oracle':28s} within-fp32={bad == 0!s:5s} "
                  f"worst {np.abs(d).max():12.3f}  (median {np.median(d):9.3f})")
            ok &= bad == 0
            continue
        got = y.reshape(E, R, n)
        ref = np.load(os.path.join(args.case, "y_ref.npy")).astype(np.float32).reshape(E, R, n)
        same = bool(np.array_equal(got, ref))
        print(f"{'y impl' + str(impl) + ' vs y_ref':28s} exact={same!s:5s} "
              f"median {(got - ref).astype(np.float64).mean():12.1f} sd {(got - ref).std():10.1f}")
        ok &= same

    p = os.path.join(args.case, args.part)
    if os.path.exists(p):
        P = np.fromfile(p, dtype=np.int32)
        if args.ks == 1:
            got = P.reshape(E, R, n).astype(np.int64) * args.scale
            ok &= report("PART vs oracle", got, acc)
        else:
            P = P.reshape(args.ks, E, R, n).astype(np.int64)
            tot = P.sum(axis=0) * args.scale
            ok &= report(f"PART(sum {args.ks} slices) vs oracle", tot, acc)
            tps = m["tk"] // args.ks
            for ks in range(args.ks):
                lo, hi = ks * tps * 16, (ks + 1) * tps * 16
                sl = np.einsum("ekn,rk->ern", bsd[:, lo:hi, :], x8[:, lo:hi].astype(np.int64))
                ok &= report(f"  slice {ks} (k {lo}:{hi})", P[ks] * args.scale, sl)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())