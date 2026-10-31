#!/usr/bin/env bash
# ATTENDED: GLM prefill, plain vs -mcpa, with a memory watchdog.
#
# Why attended and why watchdogged. The unattended version of this arm hard-hung the box on 2025-11: GLM's routed
# experts are 109.3 GiB on a 125 GiB machine and -mcpa requests PINNED promotion pages on top (LESSONS 87), so the
# memory guard now refuses GLM arms outright. This overrides that deliberately:
#   * smallest useful footprint (chunk 1024, one timed chunk => cache 2560, vs 16896 in the arm that survived and
#     6656 in the one that hung it),
#   * a watchdog that kills the bench when MemAvailable drops under 8 GiB, so the failure mode is a stopped
#     experiment rather than a reboot,
#   * both arms in the same process order (plain first, then -mcpa) because cross-process LEVELS on this box vary
#     ~2.4 % and the question is a paired comparison.
#
# Question owned by D20 in doc/port/b70-decisions.md: -mcpa costs GLM DECODE 29 % (copy bucket 0.2 -> 151.2
# us/layer) but wins +30/+50 % on Qwen PREFILL. Is the sign per-model or per-phase? Nothing measured so far can
# say, and GLM is the model where the card's case is strongest.
set +e
cd "$(dirname "$0")/../.." || exit 1
ROOT=$PWD
source notes/env.sh >/dev/null 2>&1
G=/home/treo/projects/vendor/tabbyAPI/models/GLM-5.3-Flash-exl3@3.05bpw
LOG=$ROOT/notes/b70/logs
mkdir -p $LOG

watchdog() {   # kill the bench, not the box
  local low=8192000   # KiB, ~8 GiB
  while sleep 3; do
    local avail
    avail=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
    echo "$(date +%H:%M:%S) avail=$((avail/1048576))GiB" >> $LOG/watchdog_glm.txt
    if [ "$avail" -lt "$low" ]; then
      echo "$(date +%H:%M:%S) BELOW THRESHOLD -> killing bench" >> $LOG/watchdog_glm.txt
      pkill -f "bench_parent_[p]refill" 2>/dev/null
      echo "WATCHDOG FIRED at avail=$((avail/1048576))GiB" | tee -a $LOG/progress.txt
      break
    fi
  done
}

echo "=== GLM prefill, chunk 1024, one timed chunk, -mcs 258 -mct 15 (watchdogged)" > $LOG/glm_mcpa_prefill.txt
tail -f /dev/null & TAIL=$!
watchdog & WD=$!
for flag in "" "-mcpa"; do
  tag=${flag:-plain}
  echo "### GLM prefill $tag $(date +%H:%M:%S)" | tee -a $LOG/progress.txt
  timeout 1800 python3 -u notes/b70/bench_parent_prefill.py --model "$G" --chunk 1024 --reps 1 --allow-tight \
      -- -mcs 258 -mct 15 $flag 2>&1 | tee -a $LOG/glm_mcpa_prefill.txt | grep -E "mem guard|tok/s|device-time|NON-EXPERT|>>>|REFUS|Error"
  av=$(awk '/MemAvailable/{print int($2/1048576)}' /proc/meminfo)
  echo "  rc=${PIPESTATUS[0]} $(date +%H:%M:%S)  avail=${av}GiB" | tee -a $LOG/progress.txt
done
kill $WD $TAIL 2>/dev/null
echo "### GLM -mcpa prefill attempt done $(date +%H:%M:%S)" | tee -a $LOG/progress.txt