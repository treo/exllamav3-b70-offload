#!/usr/bin/env bash
# The prefill baseline doc/port/b70-prefill.md section 5 says must exist before any B70-prefill speedup is
# claimed: the SAME model and chunk measured on the shipping stack, at three points along the capacity curve -
#   2.05 with the smallest split that loads (256 of 512 experts remote)
#   2.68 with the smallest split that loads (384 of 512 remote)
#   Qwen3.5 with NOTHING remote (its experts fit on the GPU) - the no-offload roofline
# Prefill touches essentially every expert per layer, so unlike decode this is where the split size bites hardest.
#
#   nohup bash notes/b70/run_prefill_baseline.sh > /tmp/prefill_baseline.txt 2>&1 &
set -u
cd "$(dirname "$0")/../.." || exit 1
source notes/env.sh >/dev/null 2>&1
M=/home/treo/projects/vendor/tabbyAPI/models

run() {   # run <label> <ckpt> [extra model_init args]
    local label="$1" ckpt="$2"; shift 2
    echo "### $label ($(date +%H:%M:%S))"
    python3 -u notes/bench_live_trace.py -m "$M/$ckpt" "$@" \
        --reps 14 --prefill 2048 --decode 32 --stats-dir "/tmp/prefill/$label" \
        --out "/tmp/prefill/$label.json" 2>&1 |
        grep -E "prefill [0-9]+ tokens|prefill measurement FAILED|prefill: prompt|decode wall|routing:" |
        sed "s/^/  /"
    [ -s "/tmp/prefill/$label.json" ] || echo "  NO OUTPUT FILE - arm failed, read nothing into it"
}

mkdir -p /tmp/prefill
run 205_split256 Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4 -mcs 256 -mct 15
run 268_split384 Qwen3.8-Flash-Next-exl3-2.68bpw_h6_ng8 -mcs 384 -mct 15
run q35_allgpu   Qwen3.5-35B-A3B-3bpw-hq2 -mcs 0 -mct 15
echo "### prefill baseline done $(date +%H:%M:%S)"