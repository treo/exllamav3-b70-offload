#!/usr/bin/env bash
# Second GPU queue: (A) re-run the prefill decomposition with the FIXED attribution (the first pass divided by
# chunks-1 to "drop" the warm-up chunk, which inflated every bucket by 33 % and cannot be undone by hand for the
# per-kernel rows), then (B) capture the raw routing time series that dwell analysis needs.
#
# It waits for run_plan_close.sh to finish rather than racing it: two engine processes on this box share the
# 15-core CPU worker and both numbers become meaningless.
set +e
cd "$(dirname "$0")/../.." || exit 1
ROOT=$PWD
source /opt/intel/oneapi/setvars.sh >/dev/null 2>&1
source notes/env.sh >/dev/null 2>&1
MD=/home/treo/projects/vendor/tabbyAPI/models
B=notes/b70
Q=/tmp/queue
mkdir -p $Q
say() { echo "### $* $(date +%H:%M:%S)" | tee -a $Q/progress.txt; }

while pgrep -f "b70/[r]un_plan_close.sh" >/dev/null; do sleep 30; done
say "QUEUE2 START (queue1 finished)"

run_pre() {
  local tag=$1 mdl=$2 chunk=$3 reps=$4 mcs=$5; shift 5
  say "S1r $tag (chunk $chunk reps $reps mcs $mcs $*)"
  timeout 2700 python3 -u "$B/bench_parent_prefill.py" --model "$MD/$mdl" --chunk "$chunk" --reps "$reps" \
      -- -mcs "$mcs" -mct 15 "$@" > "$Q/pr2_$tag.log" 2>&1
  echo "  rc=$? -> $(grep -E 'NON-EXPERT PREFILL|device-time per chunk|tok/s' $Q/pr2_$tag.log | tail -3 | tr '\n' '|')" \
      | tee -a $Q/progress.txt
}
run_pre q205_mcs256 Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4 4096 3 256
run_pre q205_mcs448 Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4 4096 3 448
run_pre q205_mcpa   Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4 4096 3 256 -mcpa
run_pre q268_mcs384 Qwen3.8-Flash-Next-exl3-2.68bpw_h6_ng8 4096 3 384
run_pre glm_c2048   GLM-5.3-Flash-exl3@3.05bpw 2048 2 258
run_pre glm_mcpa    GLM-5.3-Flash-exl3@3.05bpw 2048 2 258 -mcpa

# ---------------------------------------------------------------- B: dwell traces
say "S4 dwell trace 2.05 (256 decode steps, permutation-stable: no -mcpa)"
timeout 2400 python3 -u notes/bench_live_trace.py -m $MD/Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4 \
    -cs 16384 --decode 256 --reps 2 -mcs 256 -mct 15 \
    --dump-snaps $B/profiles/live/dwell_q205.json > $Q/dwell_205.txt 2>&1
echo "  rc=$? -> $(grep -E 'raw trace|CONCURRENT|WARNING' $Q/dwell_205.txt | tail -2 | tr '\n' '|')" | tee -a $Q/progress.txt
say "S4 dwell trace 2.68"
timeout 2400 python3 -u notes/bench_live_trace.py -m $MD/Qwen3.8-Flash-Next-exl3-2.68bpw_h6_ng8 \
    -cs 16384 --decode 256 --reps 2 -mcs 384 -mct 15 \
    --dump-snaps $B/profiles/live/dwell_q268.json > $Q/dwell_268.txt 2>&1
echo "  rc=$?" | tee -a $Q/progress.txt
say "S4 dwell trace GLM (its working arm; shorter run because GLM decodes at 11-16 tok/s)"
timeout 2400 python3 -u notes/bench_live_trace.py -m "$MD/GLM-5.3-Flash-exl3@3.05bpw" \
    -cs 8192 --decode 128 --reps 2 -mcs 258 -mct 15 \
    --dump-snaps $B/profiles/live/dwell_glm.json > $Q/dwell_glm.txt 2>&1
echo "  rc=$?" | tee -a $Q/progress.txt

for f in dwell_q205 dwell_q268 dwell_glm; do
  [ -s "$B/profiles/live/$f.json" ] || { echo "  skip $f (no trace)" | tee -a $Q/progress.txt; continue; }
  { echo "== $f"; python3 $B/analyze_dwell.py "$B/profiles/live/$f.json" --k 8,32,64,84,128,256 --window 32 --layers 0; } \
      >> $B/out_dwell.txt 2>&1
done
say "QUEUE2 COMPLETE"