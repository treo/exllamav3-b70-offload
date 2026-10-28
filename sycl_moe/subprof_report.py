#!/usr/bin/env python3
"""subprof_report.py — summarize sycl_moe/subprof.sh per-stage host attribution.

Reads the saved stage lines (one instrument print per arm/round) and reports, per stage, the MINIMUM
over rounds of both the mean and the minimum, plus the per-forward total. Min-over-rounds is the
honest statistic on this box: single windows of the SAME binary have been observed to differ by 25%
(prologue 0.7 vs 5.7 us, K1 5.3 vs 17.3 us) because a few preemption-length samples move a mean.

The regex tracks HostProf's print format in moe_sycl.cpp:
    [ <idx> <label> mean <us> min <us>|b<body us> ]
An empty stage table means the parser is out of sync with the instrument - that is a tool bug, not a
result (rule 11: never read silence as a zero).

  usage: subprof_report.py <logdir> [narms]
"""
import collections
import glob
import re
import sys

# group 1 = stage index, 2 = label, 3 = mean, 4 = min, 5 = max, 6 = slow(>10us) count,
# 7 = body (older format, kept parseable so past logs still read)
PAT = re.compile(r"\[(\d+) (\S+) mean ([\d.]+) min ([\d.]+)"
                 r"(?:\|max ([\d.]+)\|slow (\d+)|\|b([\d.]+))?\]")
TOT = re.compile(r"host ([\d.]+) us/fwd")


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    out = sys.argv[1].rstrip("/")
    narm = int(sys.argv[2]) if len(sys.argv) > 2 else None
    files = sorted(glob.glob(f"{out}/stage_arm*_r*.txt"))
    if not files:
        print(f"no stage files in {out}")
        return 1
    if narm is None:
        narm = 1 + max(int(re.search(r"stage_arm(\d+)_", f).group(1)) for f in files)
    arms = collections.defaultdict(lambda: collections.defaultdict(dict))   # arm -> round -> stage
    tot = collections.defaultdict(dict)                                     # arm -> round -> total
    for f in files:
        m = re.search(r"stage_arm(\d+)_r(\d+)\.txt$", f)
        arm, rnd = int(m.group(1)), int(m.group(2))
        txt = open(f, errors="ignore").read()
        for mm in PAT.finditer(txt):
            arms[arm][rnd][f"{mm.group(1)} {mm.group(2)}"] = (
                float(mm.group(3)), float(mm.group(4)),
                float(mm.group(5) or 0.0), int(mm.group(6) or 0), float(mm.group(7) or 0.0))
        t = TOT.search(txt)
        if t:
            tot[arm][rnd] = float(t.group(1))
    stages = list(dict.fromkeys(s for a in arms.values() for r in a.values() for s in r))
    if not stages:
        print("NO STAGES PARSED - extractor out of sync with the instrument. Not a result.")
        return 1
    hdr = f"{'stage':<20}" + "".join(f"{'arm' + str(i):<30}" for i in range(narm))
    print(hdr)
    print("-" * len(hdr))
    for s in stages:
        row = f"{s:<20}"
        for i in range(narm):
            vals = [r[s] for r in arms[i].values() if s in r]
            if not vals:
                row += " " * 30
                continue
            # min over rounds of (min, mean, max) and the smallest slow-count seen
            row += (f"min {min(v[1] for v in vals):5.2f} mean {min(v[0] for v in vals):5.2f}"
                    f" max {max(v[2] for v in vals):4.0f} slow {min(v[3] for v in vals):3d} ")
        print(row)
    row = f"{'TOTAL us/fwd':<20}"
    for i in range(narm):
        row += f"{min(tot[i].values()):30.2f} " if tot[i] else " " * 30
    print(row)
    print("\nmin = what every layer job demonstrably pays; max/slow = whether a stage is expensive or")
    print("just erratic. A stage with min ~= its siblings but mean 3x them is a TAIL problem, not a")
    print("fixed cost - which is what this instrument said about K1-prep (min 5.0, mean 13.8).")
    return 0


if __name__ == "__main__":
    sys.exit(main())