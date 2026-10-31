#!/usr/bin/env bash
# GPU queue for the remaining plan-phase items. Everything here is GPU/engine work and MUST stay serial: two
# concurrent engine processes would share the 15-core CPU worker and invalidate both measurements (LESSONS: the
# matched-batch rule exists because this box is not idle).
#
# Sections:
#   S1  parent PREFILL decomposition by kernel  -> blocker 1 (what is the 1988 ms intercept made of?)
#   S2  co-execution interference (E36)         -> blocker 2 (does max(device terms) survive real overlap?)
#   S3  GLM-geometry and high-K bucket cost     -> cheap wins 6 + 7
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

# ---------------------------------------------------------------- S1: prefill decomposition
PREF="$B/bench_parent_prefill.py"
run_pre() { # tag model chunk reps mcs extra
  local tag=$1 mdl=$2 chunk=$3 reps=$4 mcs=$5; shift 5
  say "S1 $tag (chunk $chunk reps $reps mcs $mcs $*)"
  timeout 2700 python3 -u "$PREF" --model "$MD/$mdl" --chunk "$chunk" --reps "$reps" -- -mcs "$mcs" -mct 15 "$@" \
      > "$Q/pre_$tag.log" 2>&1
  echo "  rc=$? -> $(grep -E 'NON-EXPERT PREFILL|device-time per chunk|tok/s' $Q/pre_$tag.log | tail -3 | tr '\n' '|')" \
      | tee -a $Q/progress.txt
}
run_pre q205_mcs256 Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4 4096 3 256
run_pre q205_mcs448 Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4 4096 3 448
run_pre q205_mcpa   Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4 4096 3 256 -mcpa
run_pre q268_mcs384 Qwen3.8-Flash-Next-exl3-2.68bpw_h6_ng8 4096 3 384
run_pre q268_mcpa   Qwen3.8-Flash-Next-exl3-2.68bpw_h6_ng8 4096 3 384 -mcpa
# GLM first at chunk 4096 x2 chunks; if the cache/VRAM refuses, retry smaller so the arm still produces data.
run_pre glm_c4096  GLM-5.3-Flash-exl3@3.05bpw 4096 1 258
grep -q "NON-EXPERT PREFILL" $Q/pre_glm_c4096.log || { say "S1 GLM c4096 failed, retrying c2048";
  run_pre glm_c2048 GLM-5.3-Flash-exl3@3.05bpw 2048 2 258; }
grep -q "NON-EXPERT PREFILL" $Q/pre_glm_c4096.log && GLMARG=(2048 2 258) || GLMARG=(2048 2 258)
run_pre glm_mcpa   GLM-5.3-Flash-exl3@3.05bpw ${GLMARG[0]} ${GLMARG[1]} ${GLMARG[2]} -mcpa

# ---------------------------------------------------------------- S2: co-execution interference (E36)
say "S3-pre dump interference case (E=64 R=16)"
timeout 900 python3 $B/dump_gemv_case.py /tmp/ix_case 64 16 12 --ckpt "$MD/Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4" \
    > $Q/dump_ix.log 2>&1; echo "  dump rc=$?" | tee -a $Q/progress.txt
hammer() { WARM_S=6 timeout 600 "$ROOT/notes/b70/probe_gemm" /tmp/ix_case 2500 16 4; }
say "S2a card ALONE (baseline for its own launch time)"
for i in 1 2 3; do hammer > $Q/card_solo_$i.txt 2>&1; done
say "S2b engine ALONE (baseline wall)"
timeout 1800 python3 -u "$ROOT/notes/bench_engine_step.py" -m $MD/Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4 \
    -cs 8192 --ctx 4096 --tokens 48 -mcs 256 -mct 15 --no-prof > $Q/eng_solo.txt 2>&1
echo "  -> $(grep 'model.forward' $Q/eng_solo.txt | head -1 | tr -s ' ')" | tee -a $Q/progress.txt
say "S2c BOTH (engine while card is hammered)"
( for i in 1 2 3 4 5 6; do hammer > $Q/card_ovl_$i.txt 2>&1; done ) & HPID=$!
sleep 20
timeout 1800 python3 -u "$ROOT/notes/bench_engine_step.py" -m $MD/Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4 \
    -cs 8192 --ctx 4096 --tokens 48 -mcs 256 -mct 15 --no-prof > $Q/eng_ovl.txt 2>&1
EC=$?
wait $HPID
echo "  engine rc=$EC -> $(grep 'model.forward' $Q/eng_ovl.txt | head -1 | tr -s ' ')" | tee -a $Q/progress.txt
{ echo "=== E36 co-execution interference"; echo "--- engine alone:"; grep 'model.forward' $Q/eng_solo.txt
  echo "--- engine while card busy:"; grep 'model.forward' $Q/eng_ovl.txt
  echo "--- card launch time ALONE (last two runs, gate/up/down rows=16 ks=4):"
  grep -E "rows|us|GB/s" $Q/card_solo_3.txt | tail -12
  echo "--- card launch time UNDER ENGINE LOAD (same lines, runs 2..5):"
  for i in 2 3 4 5; do grep -E "rows|us|GB/s" $Q/card_ovl_$i.txt | tail -12; done; } > $B/out_interference_raw.txt 2>&1
say "S2 done -> $B/out_interference_raw.txt"

# ---------------------------------------------------------------- S3: GLM geometry + high-K buckets
say "S3a dump GLM case (E=64 R=64 K=3 tn=128)"
timeout 1200 python3 $B/dump_gemv_case.py /tmp/gg_glm64 64 64 12 --ckpt "$MD/GLM-5.3-Flash-exl3@3.05bpw" \
    > $Q/dump_glm.log 2>&1; echo "  rc=$?" | tee -a $Q/progress.txt
cd "$ROOT" || exit 1
for m in A B; do say "S3a probe_gemm GLM mode $m"; GEMM_MODE=$m WARM_S=3 timeout 900 ./notes/b70/probe_gemm /tmp/gg_glm64 600 64 2 ; done \
    > $B/out_probe_gemm_glm.txt 2>&1
say "S3b dump high-K cases (4.05 K=4, 6.05 K=6) at E=512 R=64"
cd ../.. || exit 1
timeout 1500 python3 $B/dump_gemv_case.py /tmp/gg_q405_E512 512 64 12 --ckpt "$MD/Qwen3.8-Flash-Next-exl3-4.05bpw_h6_ng6" > $Q/dump_405.log 2>&1
echo "  405 dump rc=$?" | tee -a $Q/progress.txt
timeout 1500 python3 $B/dump_gemv_case.py /tmp/gg_q605_E512 512 64 12 --ckpt "$MD/Qwen3.8-Flash-Next-exl3-6.05bpw_h6_ng8" > $Q/dump_605.log 2>&1
echo "  605 dump rc=$?" | tee -a $Q/progress.txt
cd "$ROOT" || exit 1
for c in /tmp/gg_q405_E512 /tmp/gg_q605_E512; do
  say "S3b probe_gemm A on $c"
  GEMM_MODE=A WARM_S=3 timeout 900 ./notes/b70/probe_gemm $c 400 64 2
done > $B/out_prefill_kscale.txt 2>&1
say "QUEUE COMPLETE"