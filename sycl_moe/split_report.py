#!/usr/bin/env python3
"""Group sycl_moe stream-debug lines by prefill forward and summarize the workload split.

  python split_report.py /tmp/arms_diag24.log [--fwd last]

A forward's lines are recognized by the layer index restarting (L index is not necessarily
dense: layers that stream nothing print no line at all). Reports per forward: layer-calls
logged, rows, streamed experts, streamed/tail assignments, tail rows, and the implied
per-leg cost at the calibrated rates (3090 streamed DMA = expert_bytes/link, etc).
"""
import re, sys

PAT = re.compile(
    r"tail L(\d+): rows (\d+) n_tail (\d+) streamed_experts (\d+)/(\d+) "
    r"streamed_assign (\d+) tail_assign (\d+) of (\d+) exp_b (\d+) per_slot (\d+)")
BATCH = re.compile(r"batch L(\d+) ws(\d+): (\d+) experts, fused_t (\d+), n_fused (\d+)")

fwd, fwds = [], []
lastL = -1
for line in open(sys.argv[1], errors = "replace"):
    m = PAT.search(line)
    if not m:
        continue
    L, r, nt, se, E, sa, ta, tt, eb, ps = map(int, m.groups())
    if L <= lastL:
        if fwd:
            fwds.append(fwd); fwd = []
    lastL = L
    fwd.append((L, r, nt, se, E, sa, ta, tt, eb, ps))
if fwd:
    fwds.append(fwd)

nb = sys.argv.index("--fwd") + 1 if "--fwd" in sys.argv else None
pick = range(len(fwds)) if nb is None or nb >= len(fwds) else [len(fwds) - 1]
for i in pick:
    f = fwds[i]
    n = len(f)
    rows = sum(x[1] for x in f) // n
    trows = sum(x[2] for x in f) // n
    sexp = sum(x[3] for x in f) / n
    E = f[0][4]
    sa = sum(x[5] for x in f) / n
    ta = sum(x[6] for x in f) / n
    tt = sum(x[7] for x in f) / n
    eb = f[0][8]
    # batches the streamed loop will run: per_slot experts each, rounded up per layer
    nbatch = sum((x[3] + f[0][9] - 1) // f[0][9] for x in f) / n
    print(f"fwd{i}: layers_logged={n}/48 rows={rows} E={E} streamed_experts/layer={sexp:5.1f} "
          f"({100*sexp/E:4.1f}%) batches/layer={nbatch:4.1f}")
    print(f"        assignments/layer: worker={tt:7.0f} streamed={sa:7.0f} ({100*sa/max(tt,1):5.1f}%) "
          f"tail={ta:6.0f}  tail_rows/layer={trows:5.0f}  picks/tail_row={ta/max(trows,1):4.2f}")
    print(f"        per-layer cost model: 3090 DMA {sexp*eb/13.4e9*1e3:6.1f} ms  "
          f"B70 tail (11.8us per 8-pick chunk) {sum((x[6]//8 + (1 if x[6]%8 else 0)) for x in f)/n*11.8/1e3:6.1f} ms "
          f"(lower bound; chunks are per expert per job)")