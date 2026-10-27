#!/bin/bash
# arms.sh <tag> "<ENV>" [extra pb args] — one labelled prefill arm of the 2.05bpw target.
# Steady-state in-process measurement (load once, reps of a 4096-row prefill, min-of-reps).
set -u
cd /home/treo/projects/pdc/exllamav3
source sycl_moe/env.sh >/dev/null
M=$HOME/projects/vendor/tabbyAPI/models/Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4
TAG=$1; ENVP="EXL3_MOE_B70=1 $2"; shift 2
LOG=/tmp/arms_${TAG}.log
{
echo "=== tag=$TAG env=[$ENVP] extra=[$*] start=$(date +%T)"
# shellcheck disable=SC2086
env $ENVP PB_TAG=$TAG ./.venv/bin/python sycl_moe/pb.py -m "$M" -mcs 256 -ngr -mct 15 -mcpa \
    -lens 4096 -reps 4 "$@" 2>&1 | grep -vE "registered layer|warm done|CPU split experts"
echo "=== end=$(date +%T)"
} > "$LOG" 2>&1
grep -E "PB len|PB_RESULT" "$LOG" | sed 's/tag=.*/tag/' | tail -5
grep -cE "Traceback|sycl error|forward failed|DEVICE_LOST" "$LOG" | sed 's/^/errors=/'