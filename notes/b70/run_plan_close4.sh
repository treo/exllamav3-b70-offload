#!/usr/bin/env bash
# Attended tail of the plan phase. Two things, both deliberately excluded from the unattended queue:
#   A) GLM dwell trace  - needs --allow-tight (its expert set is 87 % of host RAM), so it runs with a watcher.
#   B) E36 interference REDONE - the first attempt compared ONE engine-alone run against ONE engine-with-card run
#      and reported the engine running 30 % FASTER while the card was saturated. That is not an interference
#      result, it is run order / warm-state drift, so this alternates A,B,A,B,A,B and compares medians.
set +e
cd "$(dirname "$0")/../.." || exit 1
ROOT=$PWD
source /opt/intel/oneapi/setvars.sh >/dev/null 2>&1
source notes/env.sh >/dev/null 2>&1
MD=/home/treo/projects/vendor/tabbyAPI/models
B=notes/b70
LOG=$B/logs
CS=$HOME/.cache/b70cases
mkdir -p $LOG $CS
say() { echo "### $* $(date '+%H:%M:%S')" | tee -a $LOG/progress.txt; }
mem() { awk '/MemAvailable/{printf "  MemAvailable %.0f GiB\n", $2/1048576}' /proc/meminfo | tee -a $LOG/progress.txt; }

Q2=$MD/Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4
ENG() { timeout 900 python3 -u "$ROOT/notes/bench_engine_step.py" -m "$Q2" -cs 8192 --ctx 4096 --tokens 32 \
            -mcs 256 -mct 15 --no-prof 2>&1 | grep "model.forward"; }
hammer() { WARM_S=6 timeout 600 "$ROOT/$B/probe_gemm" $CS/ix_case 2500 16 4; }

# ---------------------------------------------------------------- B) interference, alternating
say "E36v2 alternating interference"
{ echo "=== E36v2 co-execution interference (run_plan_close4.sh). Alternating engine-alone / engine+card, 3 pairs."
  echo "=== The first attempt (one run each) said the engine was 30 % FASTER with the card saturated, which is"
  echo "=== order/warm-state drift, not interference. Design change: interleave and compare medians."
  echo "--- card ALONE (3 windows, its own launch time):"
  for i in 1 2 3; do hammer; done | grep -E "revL|gemm [AB]"
  echo "--- alternating:"
  for i in 1 2 3; do
      echo "  pair $i engine-alone : $(ENG)"
      ( hammer > $LOG/card_ovl_$i.txt 2>&1 ) & HP=$!
      sleep 15
      echo "  pair $i engine+card  : $(ENG)"
      wait $HP
      echo "  pair $i card-under-load: $(grep -E 'revL|gemm [AB]' $LOG/card_ovl_$i.txt | head -2)"
  done; } > $B/out_interference.txt 2>&1
say "E36v2 done -> $B/out_interference.txt"

# ---------------------------------------------------------------- A) GLM dwell (ATTENDED: --allow-tight)
mem
say "GLM dwell trace (attended, guard overridden with --allow-tight; -cs 4096 keeps the cache small)"
timeout 3000 python3 -u notes/bench_live_trace.py -m "$MD/GLM-5.3-Flash-exl3@3.05bpw" \
    -cs 4096 --decode 384 --reps 2 -mcs 258 -mct 15 --allow-tight \
    --dump-snaps $B/profiles/live/dwell_glm.json > $LOG/dwell_glm_fixed.txt 2>&1
echo "  rc=$? -> $(grep -E 'raw trace|rotated|REFUSING' $LOG/dwell_glm_fixed.txt | tail -2 | tr '\n' '|')" | tee -a $LOG/progress.txt
mem
say "close4 COMPLETE"