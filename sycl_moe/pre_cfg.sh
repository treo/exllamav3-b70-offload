#!/bin/bash
# flexible perf A/B driver.
#   ./pre_cfg.sh <tag> "<ENV PREFIX>" "<perf.py args...>"
# Runs eval/perf.py on the 2.05bpw target model, logs to /tmp/cfg_<tag>.log, prints prefill.
set -u
cd /home/treo/projects/pdc/exllamav3
source sycl_moe/env.sh >/dev/null
M=$HOME/projects/vendor/tabbyAPI/models/Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4
TAG=$1; ENVP=$2; ARGS=$3
LOG=/tmp/cfg_${TAG}.log
{
echo "=== tag=$TAG env=[$ENVP] args=[$ARGS] start=$(date +%T)"
# shellcheck disable=SC2086
env $ENVP ./.venv/bin/python eval/perf.py -m "$M" $ARGS 2>&1 | grep -vE "${NOGA:-^\[b70moe\] (registered layer|warm done)}"
echo "=== end=$(date +%T) rc=$?"
} > "$LOG" 2>&1
echo "--- $TAG"
grep -E "Length|Context " "$LOG" | sed 's/\x1b\[[0-9;]*m//g'
grep -E "registered=|fallback=|out of device memory|forward failed" "$LOG" | tail -4