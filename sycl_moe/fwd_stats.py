#!/usr/bin/env python3
"""Analyse an EXL3_MOE_B70_ALLOCLOG: per-job rows/nc/duration, aggregate time in the
plugin, and the effective weight-stream bandwidth (bytes/expert from the arena math).

usage: fwd_stats.py /tmp/attr_k1.log [--eb BYTES_PER_EXPERT] [--tail N]
"""
import re, sys, collections

path = sys.argv[1]
eb = 2457600
if "--eb" in sys.argv:
    eb = int(sys.argv[sys.argv.index("--eb") + 1])

enter = {}
rows_sum = collections.Counter()          # rows -> jobs
dur_sum = collections.Counter()           # rows -> us
nc_sum = collections.Counter()            # rows -> chunks
pairs = []
pat_e = re.compile(r"^(\d+\.\d+) (\d+) FWD enter h (-?\d+) rows (\d+) topk (\d+)")
pat_x = re.compile(r"^(\d+\.\d+) (\d+) FWD exit h (-?\d+) rows (\d+) nc (\d+)")
nj = 0
for line in open(path, errors = "replace"):
    m = pat_e.match(line)
    if m:
        enter[(m.group(2), m.group(3))] = (float(m.group(1)), int(m.group(4)))
        continue
    m = pat_x.match(line)
    if m:
        k = (m.group(2), m.group(3))
        if k not in enter:
            continue
        t0, rows = enter.pop(k)
        t1, nc = float(m.group(1)), int(m.group(5)) or 0
        us = max((t1 - t0) * 1e6, 1e-3)
        rows_sum[rows] += 1
        dur_sum[rows] += us
        nc_sum[rows] += nc
        pairs.append((t0, rows, nc, us))
        nj += 1

print(f"jobs={nj}")
print(f"{'rows':>6} {'jobs':>6} {'chunks':>8} {'tot_ms':>9} {'us/job':>8} {'us/row':>7} {'GB/s(wt)':>9}")
tot_us = tot_bytes = 0.0
for rows in sorted(rows_sum, key = lambda r: -dur_sum[r]):
    n, us, nc = rows_sum[rows], dur_sum[rows], nc_sum[rows]
    byts = nc * eb
    tot_us += us; tot_bytes += byts
    print(f"{rows:6d} {n:6d} {nc:8d} {us/1e3:9.1f} {us/n:8.1f} {us/n/rows:7.2f} {byts/us/1e3:9.1f}")
print(f"TOTAL in-plugin {tot_us/1e3:.1f} ms, weight streams {tot_bytes/1e9:.2f} GB, "
      f"mean {tot_bytes/max(tot_us,1)/1e3:.1f} GB/s")
span = (max(p[0] for p in pairs) - min(p[0] for p in pairs)) * 1e6 if pairs else 0
print(f"wall span of logged forwards {span/1e3:.1f} ms -> duty cycle {100*tot_us/max(span,1):.1f}%")