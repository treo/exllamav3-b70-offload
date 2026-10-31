#!/usr/bin/env bash
# Long-chunk prefill baseline. notes/b70/run_prefill_baseline.sh measured 2048 tokens, which is too short to
# read the parent's per-chunk FIXED cost off of: whatever the step spends per forward (cache/position setup,
# graph replay, launch ramp, the non-expert leg) is amortized over 2048 tokens there and over 4096/8192 here.
# The operator's guidance is that 2048-4096 is this machine's optimum, so a realistic prefill speed has to be
# measured AT 4096 tokens of prefill, with 8192 as the fixed-cost discriminator.
#
# Each arm prints its own prefill tok/s; a missing output file is reported as a failed arm and nothing is read
# into the table (LESSONS 52: a probe that fails and still prints a number is worse than one that does not run).
#
#   nohup bash notes/b70/run_prefill_long.sh > /tmp/prefill_long.txt 2>&1 &
set -u
cd "$(dirname "$0")/../.." || exit 1
source notes/env.sh >/dev/null 2>&1
M=/home/treo/projects/vendor/tabbyAPI/models
OUT=/tmp/prefill_long
mkdir -p "$OUT"

run() {   # run <label> <ckpt> <prefill> <chunk|-> [extra args]
    local label="$1" ckpt="$2" pf="$3" cs="$4"; shift 4
    local extra=()
    [ "$cs" != "-" ] && extra+=(-chunk_size "$cs")
    echo "### $label  prefill=$pf chunk=$cs ($(date +%H:%M:%S))"
    python3 -u notes/bench_live_trace.py -m "$M/$ckpt" -cs 16384 "$@" "${extra[@]}" \
        --reps 6 --prefill "$pf" --decode 8 --stats-dir "$OUT/$label" --out "$OUT/$label.json" 2>&1 |
        grep -E "prefill [0-9]+ tokens|prefill measurement FAILED|prefill: prompt|decode wall|routing:|Error|error" |
        sed "s/^/  /"
    local rc=$?
    if [ -s "$OUT/$label.json" ]; then
        echo "  -> $OUT/$label.json ok"
    else
        echo "  ARM FAILED (pipe rc=$rc, no json) - read nothing into the table"
    fi
}

# 2.05, smallest split that loads. 4096 with the harness default chunk, then the chunk arms that decide whether
# chunking at 2048 costs or buys at this size, then 8192 to separate per-chunk fixed cost from per-token cost.
run long_205_4096_dflt  Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4 4096 -    -mcs 256 -mct 15
run long_205_4096_c2048 Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4 4096 2048 -mcs 256 -mct 15
run long_205_8192_c4096 Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4 8192 4096 -mcs 256 -mct 15
run long_268_4096_dflt  Qwen3.8-Flash-Next-exl3-2.68bpw_h6_ng8 4096 -    -mcs 384 -mct 15
echo "### long prefill baseline done $(date +%H:%M:%S)"