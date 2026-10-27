#!/usr/bin/env python3
"""Analyze a kineto chrome trace for GPU busy/idle structure (diagnosis, not A/B).

  python tl_analyze.py /tmp/pb_prof_X.json [--min-gap 200] [--top 15]

Prints: wall span, per-stream busy time, union busy/idle, the largest idle windows (with the
kernels that bracket them), and top device activities by total duration.
"""
import json, sys, collections

path = sys.argv[1]
mingap = float(sys.argv[sys.argv.index("--min-gap") + 1]) if "--min-gap" in sys.argv else 200.0
topn = int(sys.argv[sys.argv.index("--top") + 1]) if "--top" in sys.argv else 15

d = json.load(open(path))
ev = d["traceEvents"] if isinstance(d, dict) else d
streams = collections.defaultdict(list)
for e in ev:
    if e.get("ph") != "X":
        continue
    cat = e.get("cat", "")
    if cat in ("kernel", "gpu_memcpy", "gpu_memset"):
        streams[(e.get("tid"), e.get("pid"))].append((e["ts"], e.get("dur", 0), e.get("name", "?")))

if not streams:
    print("no GPU events (wrong trace?)"); sys.exit(1)

t0 = min(v[0][0] for v in streams.values())
t1 = max(a + b for v in streams.values() for a, b, _ in v)
print(f"wall span {(t1 - t0) / 1e3:.1f} ms over {len(streams)} GPU streams")
for k, v in sorted(streams.items(), key = lambda kv: -sum(x[1] for x in kv[1])):
    busy = sum(x[1] for x in v)
    kinds = collections.Counter("memcpy" if "Memcpy" in x[2] or "memset" in x[2] else "kernel" for x in v)
    print(f"  stream tid={k[0]}: {len(v)} ops ({dict(kinds)}), busy {busy/1e3:8.1f} ms "
          f"= {100*busy/(t1-t0):5.1f}% of span")

# Union busy interval across all streams -> true GPU idle
ivs = sorted((a, a + b) for v in streams.values() for a, b, _ in v)
merged = []
for a, b in ivs:
    if merged and a <= merged[-1][1]:
        merged[-1][1] = max(merged[-1][1], b)
    else:
        merged.append([a, b])
ubusy = sum(b - a for a, b in merged)
print(f"UNION busy {ubusy/1e3:.1f} ms = {100*ubusy/(t1-t0):.1f}% of span; "
      f"GPU idle {(t1-t0-ubusy)/1e3:.1f} ms in {len(merged)-1} gaps")
gaps = [(merged[i+1][0] - merged[i][1], merged[i][1]) for i in range(len(merged) - 1)]
gaps.sort(reverse = True)
big = [g for g in gaps if g[0] >= mingap]
print(f"gaps >= {mingap:.0f} us: {len(big)}, total {sum(g for g, _ in big)/1e3:.1f} ms")

# What brackets the biggest gaps?
def near(ts, w = 60):
    out = []
    for k, v in streams.items():
        for a, b, n in v:
            if abs(a - ts) < w * 1000 or abs(b - ts) < w * 1000:
                out.append((a, n[:58]))
    out.sort()
    return out[:6]
for g, end in big[:12]:
    print(f"  gap {g/1e3:6.2f} ms at +{(end-t0)/1e3:8.1f} ms; neighbours:")
    for a, n in near(end):
        print(f"      +{(a-t0)/1e3:8.2f} {n}")

tot = collections.Counter()
cnt = collections.Counter()
for v in streams.values():
    for a, b, n in v:
        tot[n[:70]] += b; cnt[n[:70]] += 1
print(f"\ntop {topn} device activities by total duration:")
for n, t in tot.most_common(topn):
    print(f"  {t/1e3:8.1f} ms  {cnt[n]:6d}x  {n}")