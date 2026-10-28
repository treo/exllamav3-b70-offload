#!/bin/bash
# subprof_len.sh — is the H2D->first-kernel surcharge a function of how long the B70 idles between
# layer jobs? Longer context => more attention work per layer on the parent GPU => bigger gap
# between consecutive B70 forwards => the copy path's fast-submission ring may time out and the
# first kernel after the copies inherits a kernel-driver submission (Intel's own patch notes the
# copy-engine ULLS ring used to shut down after 1 s idle; https://phoronix.com, xe/DRM 7.4).
#
# Runs the instrumented plugin at several context lengths, interleaved in rounds, and reports the
# per-stage minimum over rounds plus the MEASURED inter-forward gap from the ALLOCLOG timestamps
# (so the correlation is between two measured quantities, not an assumed one).
#
#   sycl_moe/subprof_len.sh [rounds]
set -u
cd /home/treo/projects/pdc/exllamav3
set +u
source sycl_moe/env.sh >/dev/null
set -u
M=$HOME/projects/vendor/tabbyAPI/models/Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4
ROUNDS=${1:-2}
OUT=/tmp/subprof_len
rm -rf "$OUT"; mkdir -p "$OUT"
LENS=(1024 2048 4096)
echo "subprof_len: ${#LENS[@]} lengths x $ROUNDS rounds"
for ((r = 1; r <= ROUNDS; r++)); do
  for L in "${LENS[@]}"; do
    log="$OUT/len${L}_r${r}.log"
    EXL3_MOE_B70=1 EXL3_MOE_B70_HOSTPROF=1 EXL3_MOE_B70_ALLOCLOG="$OUT/alloc_${L}_r${r}.log" \
      timeout 1200 ./.venv/bin/python eval/perf.py -m "$M" -mcs 256 -ngr -mct 15 -mcpa \
        --max_length "$L" -spf -dr 2 > "$log" 2>&1
    line=$(grep "hostprof\[decode-float\]" "$log" | tail -1)
    printf "  r%-2d len%-6s %s  %s\n" "$r" "$L" "$(echo "$line" | grep -o 'host [0-9.]* us/fwd')" \
        "$(grep -o 'registered=[0-9]*' "$log" | tail -1)"
    echo "$line" > "$OUT/stage_len${L}_r${r}.txt"
  done
done
echo "--- per-stage min over rounds (us) + measured gap between consecutive rows=1 forwards ---"
python3 - "$OUT" <<'PY'
import sys, re, glob, statistics as st
from collections import defaultdict
out = sys.argv[1]
pat = re.compile(r'\[(\d+) (\S+) ([\d.]+)\|([\d.]+)\|b([\d.]+)\]')
best = defaultdict(dict)
for f in glob.glob(f"{out}/stage_len*_r*.txt"):
    L = re.search(r'len(\d+)', f).group(1)
    txt = open(f).read()
    for m in pat.finditer(txt):
        i, nm, pre, enq, body = m.group(1), m.group(2), *map(float, m.groups()[2:])
        k = f"{nm}"
        if k not in best[L] or enq < best[L][k][1]: best[L][k] = (pre, enq, body)
    h = re.search(r'host ([\d.]+) us/fwd', txt)
    if h: best[L]['TOTAL'] = (0.0, float(h.group(1)), 0.0)
# measured inter-forward gap: timestamps of FWD exit lines with rows 1
gaps = defaultdict(list)
for f in glob.glob(f"{out}/alloc_*_r*.log"):
    L = re.search(r'alloc_(\d+)_', f).group(1)
    prev = None
    for line in open(f, errors='ignore'):
        if ' FWD exit ' not in line or ' rows 1 ' not in line: continue
        t = float(line.split()[0])
        if prev is not None and 0 < (t - prev) < 0.05: gaps[L].append((t - prev) * 1e6)
        prev = t
stages = ['prologue', 'blob-h2d', 'K1-prep', 'gemv', 'K34-act', 'K56-coopdn', 'TOTAL']
print(f"{'len':>6} {'gap p50 us':>11} {'gap p90 us':>11} " + " ".join(f"{s:>11}" for s in stages))
for L in sorted(best, key=int):
    g = sorted(gaps.get(L, []))
    gp50 = g[len(g)//2] if g else float('nan')
    gp90 = g[int(len(g)*.9)] if g else float('nan')
    row = f"{L:>6} {gp50:>11.0f} {gp90:>11.0f} "
    for s in stages:
        v = best[L].get(s)
        row += f"{v[1]:>11.2f} " if v else f"{'-':>11} "
    print(row + f"  (n_gap={len(g)})")
print("\nK1-prep is the stage that carries the H2D->kernel edge; TOTAL is the whole host window")
print("(prologue + blob pack + every submit). If K1 tracks the gap while the others do not, the")
print("fixed cost is a cold submission path, not per-action API work.")
PY