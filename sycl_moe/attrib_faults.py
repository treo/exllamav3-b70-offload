#!/usr/bin/env python3
"""Attribute xe-driver GPU page faults to plugin USM allocations.

usage: attrib.py alloc.log fault_addr [more addrs...]
Uses the timestamped A/F alloc/free + J geometry log (EXL3_MOE_B70_ALLOCLOG).
For each fault address: rebuild the live allocation map at the LAST log record,
list the containing allocation (if any) and the nearest allocations below/above.
Kernel logs 48-bit VAs; user canonical VAs are sign-extended -> try both.
"""
import sys, re, bisect

def load(path):
    recs, jobs = [], []
    for line in open(path):
        m = re.match(r"(\d+\.\d+) (\d+) ([AF]) (\S+) (0x[0-9a-f]+) (\d+)", line)
        if m:
            ts, pid, kind, site, ptr, size = m.groups()
            recs.append((float(ts), int(pid), kind, site, int(ptr, 16), int(size), line.strip()))
            continue
        m = re.match(r"(\d+\.\d+) (\d+) (J|FWD) ", line)
        if m:
            jobs.append((float(m.group(1)), int(m.group(2)), line.strip()))
    recs.sort(key=lambda r: r[0]); jobs.sort(key=lambda j: j[0])
    return recs, jobs

def live_map(recs, ts=None):
    live = {}
    for r in recs:
        t, pid, kind, site, ptr, size, _ = r
        if ts is not None and t > ts: break
        if kind == 'A' and ptr: live[ptr] = (site, size, t)
        elif kind == 'F': live.pop(ptr, None)
    return live

def main():
    path = sys.argv[1]
    addrs = [int(a, 16) for a in sys.argv[2:]]
    recs, jobs = load(path)
    if not recs:
        print("empty alloc log"); return
    live = live_map(recs)
    starts = sorted(live.keys())
    print(f"log: {len(recs)} alloc records, {len(jobs)} job lines; live allocations: {len(live)}")
    print("last jobs:")
    for j in jobs[-6:]:
        print("  " + j[2][:250])
    for a0 in addrs:
        cands = [a0, a0 | (0xFFFF << 48)] if a0 >> 47 == 0 else [a0]
        print(f"\nfault 0x{a0:016x}")
        for a in cands:
            i = bisect.bisect_right(starts, a) - 1
            hit = None
            if i >= 0:
                base = starts[i]
                site, size, ats = live[base]
                if a < base + size:
                    hit = (base, site, size, a - base)
            if hit:
                print(f"  0x{a:016x}: INSIDE {hit[1]} base 0x{hit[0]:x} size {hit[2]} off +0x{hit[3]:x}")
            else:
                prev = (f"{live[starts[i]][0]} 0x{starts[i]:x}+0x{live[starts[i]][1]:x} "
                        f"(ends 0x{starts[i]+live[starts[i]][1]:x}, gap +{a-(starts[i]+live[starts[i]][1])})") if i >= 0 else "none below"
                nxt = (f"{live[starts[i+1]][0]} 0x{starts[i+1]:x} (gap -{starts[i+1]-a})") if i+1 < len(starts) else "none above"
                print(f"  0x{a:016x}: UNMAPPED. below: {prev} | above: {nxt}")

main()