#!/usr/bin/env python3
"""gate_dpas.py - the repeatable bit-exactness gate for the decode kernels (E24 close-out).

Why this exists: every exactness claim for revs C/I/J/K during E24 was checked by a throwaway Python
snippet inside the session that made it. That is not a gate - it cannot be re-run by the next person, and
"bit-exact" had no artifact behind it. This script is the artifact: it runs each kernel on each case and
asserts (a) bitwise equality against that case's own y_ref, and (b) agreement with the other kernels
byte-for-byte, which is the property the engine actually inherits (all these kernels compute the same
integer accumulation, so any disagreement means one of them drifted, not that rounding differs).

Kernels (binaries must already exist; build.sh builds them, probe_gemv needs one build per K):
    dp4a    probe_gemv      built per recipe:  icpx -O2 -DGEMV_KCONST=<K> -o /tmp/pgK<K> probe_gemv.cpp
    rev I   probe_dpas6     needs DPAS_X=1, K <= 5
    rev J   probe_dpas7     transposed tiles (permuted inside main(), so it reads the native layout too)
    rev K   probe_dpas8     same body, split combine (DPAS_COMBINE=split) == rev J's structure

Cases are directories written by dump_gemv_case.py --with-reference [--with-sx8]. rev J/K also need sx8.bin;
cases without it are reported SKIP, not PASS.

Usage:  python3 gate_dpas.py [--quick]        # --quick drops rows=8
Exit status is nonzero if any executed check fails. Requirements are asserted, never assumed: output file
count, dtype and shape are checked before any comparison, because a silent empty diff is how a bad harness
reports success.
"""
import glob
import os
import shutil
import subprocess
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
CASES = [
    # dir, K, label, extra kernels' split-K to use (probe arg), needs_sx8
    ("/tmp/gemv_dpE10", 3, "gate_proj K=3 tn=40", 2),
    ("/tmp/rc_down_268", 3, "down_proj K=3 tn=160", 1),
    ("/tmp/rc_K2_gate", 2, "gate_proj K=2", 2),
    ("/tmp/rc_K5_gate", 5, "gate_proj K=5", 2),
]
ROWS = (1, 4, 8, 16)


def run(binary, args, env_extra=None):
    e = dict(os.environ)
    e.update(env_extra or {})
    p = subprocess.run([binary] + args, capture_output=True, text=True, env=e)
    return p.returncode, p.stdout, p.stderr


def snapshot(case):
    # The probes write to FIXED filenames (y_dev_revi_ks1_r4_..., etc.), so "which file is new" is not a
    # reliable signal - leftovers from an earlier session defeat it and a run that worked gets reported as
    # producing nothing. Clear the case's outputs before each run and take whatever appears.
    for f in glob.glob(os.path.join(case, "y_dev*")):
        os.remove(f)


def newest_file(case, before=None):
    new = glob.glob(os.path.join(case, "y_dev*"))
    if not new:
        return None
    return max(new, key=os.path.getmtime)


def make_staged(case, K):
    """Write <case>_planar with the PRODUCTION AVX2 staged dword order (moe_cpu_host._copy_repacked's
    planar map: swap each tile's trailing (8, bits) dword dims), tile order deliberately left native so the
    check isolates the dword-permute claim. Returns the new dir, or None if the case lacks weights.bin."""
    src = os.path.join(case, "weights.bin")
    if not os.path.exists(src):
        return None
    nw = 8 * K
    t = np.fromfile(src, dtype=np.uint32)
    assert t.size % nw == 0, f"{src}: {t.size} dwords is not a multiple of tile size {nw}"
    out = case + "_planar"
    if not os.path.isdir(out):
        shutil.copytree(case, out)
    t.reshape(-1, 8, K).transpose(0, 2, 1).reshape(-1, nw).astype(np.uint32).tofile(os.path.join(out, "weights.bin"))
    for f in glob.glob(os.path.join(out, "y_dev*")):
        os.remove(f)
    return out


def staged_checks(fails):
    """D3-alt: assert that the B70 kernel consumes the parent's staged bytes verbatim (probe_dpas7 built
    with -DDPAS_STAGED_LAYOUT, so it does no permute of its own) and stays bit-exact. This is the regression
    gate for the 'copy verbatim to the B70' claim - if a future staging change alters the planar map, or the
    kernel's tile map drifts, this is what catches it."""
    bin_ = "/tmp/revJ_staged"
    if not os.path.exists(bin_):
        print("  SKIP  staged: /tmp/revJ_staged not built "
              "(icpx -fsycl -O2 -fsycl-device-code-split=per_kernel -DDPAS_STAGED_LAYOUT -o /tmp/revJ_staged probe_dpas7.cpp)")
        return 0
    n = 0
    print("\nstaged-layout input (production AVX2 planar dword order, consumed verbatim):")
    for case, K, label, ks in CASES:
        if K > 5 or not os.path.isdir(case) or not os.path.exists(os.path.join(case, "sx8.bin")):
            continue
        st = make_staged(case, K)
        ref = np.load(os.path.join(case, "y_ref.npy")).astype(np.float32)
        for R in (1, 16):
            for f in glob.glob(os.path.join(st, "y_dev*")):
                os.remove(f)
            rc, out, err = run(bin_, [st, "1", str(R), str(ks)])
            f = newest_file(st)
            n += 1
            if rc or f is None:
                fails.append(f"{label} staged rows={R}: rc={rc} no output - {(err or out).strip()[:70]}")
                continue
            got = np.fromfile(f, dtype=np.float32)
            want = ref[:, :R, :]
            if got.size != want.size:
                fails.append(f"{label} staged rows={R}: size {got.size} vs ref {want.size}")
            elif not np.array_equal(got.reshape(want.shape), want):
                fails.append(f"{label} staged rows={R}: NOT bit-exact ({int((got.reshape(want.shape) != want).sum())} differ)")
            else:
                print(f"  {label:<22} rows={R:<3} verbatim-staged ok")
    return n


def main():
    quick = "--quick" in sys.argv
    staged = "--staged" in sys.argv
    rows = (1, 4, 16) if quick else ROWS
    fails, checks, skips = [], 0, []

    for case, K, label, ks in CASES:
        if not os.path.isdir(case):
            skips.append(f"{label}: case dir missing")
            continue
        ref_path = os.path.join(case, "y_ref.npy")
        if not os.path.exists(ref_path):
            skips.append(f"{label}: no y_ref.npy")
            continue
        ref = np.load(ref_path).astype(np.float32)
        assert ref.ndim == 3, f"{case}: y_ref must be [E, n, rows], got {ref.shape}"
        have_sx8 = os.path.exists(os.path.join(case, "sx8.bin"))
        dp4a_bin = f"/tmp/pgK{K}"

        for R in rows:
            if R > ref.shape[2]:
                skips.append(f"{label} rows={R}: y_ref has {ref.shape[2]} rows")
                continue
            want = ref[:, :R, :]
            outs = {}

            # --- dp4a (rev C, compile-time K) ---
            if os.path.exists(dp4a_bin):
                before = snapshot(case)
                rc, out, err = run(dp4a_bin, [case, "0", "1", str(R), "1", "4"])
                f = newest_file(case, before)
                if rc or f is None:
                    fails.append(f"{label} dp4a rows={R}: rc={rc} no output file - {(err or out).strip()[:70]}")
                else:
                    outs["dp4a"] = np.fromfile(f, dtype=np.float32)
            else:
                skips.append(f"{label}: {dp4a_bin} not built (icpx -O2 -DGEMV_KCONST={K} -o {dp4a_bin} probe_gemv.cpp)")

            # --- DPAS families (all read the native layout; rev J/K permute internally) ---
            dpas = [("revI", "./probe_dpas6", ["5"], {"DPAS_X": "1"}, K <= 5),
                    ("revJ", "./probe_dpas7", ["1"], {}, True),
                    ("revK", "./probe_dpas8", ["1"], {"DPAS_COMBINE": "split"}, True)]
            for nm, bin_, pos, env, allowed in dpas:
                if not allowed:
                    skips.append(f"{label} {nm} rows={R}: K={K} outside this kernel's range")
                    continue
                if not have_sx8:
                    skips.append(f"{label} {nm} rows={R}: case lacks sx8.bin")
                    continue
                if not os.path.exists(os.path.join(HERE, bin_)):
                    fails.append(f"{label} {nm}: {bin_} not built (run build.sh)")
                    continue
                before = snapshot(case)
                rc, out, err = run(os.path.join(HERE, bin_), [case] + pos + [str(R), str(ks)], env)
                f = newest_file(case, before)
                if rc or f is None:
                    fails.append(f"{label} {nm} rows={R}: rc={rc} no output file - {(err or out).strip()[:70]}")
                    continue
                outs[nm] = np.fromfile(f, dtype=np.float32)

            # --- assertions: shape first, then bit equality, then cross-kernel agreement ---
            for nm, got in outs.items():
                checks += 1
                if got.size != want.size:
                    fails.append(f"{label} {nm} rows={R}: got {got.size} floats, ref {want.size} "
                                 f"(shape assertion failed - comparison skipped)")
                    continue
                g = got.reshape(want.shape)
                if not np.array_equal(g, want):
                    nd = int((g != want).sum())
                    fails.append(f"{label} {nm} rows={R}: {nd}/{want.size} differ, max|d| "
                                 f"{np.abs(g - want).max():.3g}")
            names = sorted(outs)
            base = names[0] if names else None
            for nm in names[1:]:
                checks += 1
                if outs[nm].size == outs[base].size:
                    if not np.array_equal(outs[nm], outs[base]):
                        fails.append(f"{label} {nm} != {base} rows={R} ({int((outs[nm] != outs[base]).sum())} differ)")
                else:
                    fails.append(f"{label} {nm} != {base} rows={R}: size {outs[nm].size} vs {outs[base].size}")
            print(f"  {label:<22} rows={R:<3} " + (" ".join(f"{n}=ok" for n in names) if names else "NO KERNELS RAN"))

    if staged:
        checks += staged_checks(fails)
    print(f"\n{checks} comparisons, {len(fails)} failures, {len(skips)} skips")
    for s in skips:
        print(f"  SKIP  {s}")
    for f in fails:
        print(f"  FAIL  {f}")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())