#!/bin/bash
# ab.sh <label> "<ENV1>" "<ENV2>" ... — interleaved arm comparison, one model load per arm per round.
#
#   ./ab.sh mytest "EXL3_MOE_B70=1" "EXL3_MOE_B70=1 EXL3_MOE_STREAM_T=48 ..."
#
# Arms are given as full ENV strings (they replace, not extend). Every arm runs once per
# ROUND (default 2) in round-robin order, so thermal/clock drift hits all arms alike; the
# summary reports min-of-reps per length per arm over all rounds (sycl_moe/NOTES.md rule 1:
# burn-in, interleave, min-of-N; rule 6: first-run VRAM-reclaim effects only pollute round 1).
#
# Env: AB_LENS (default 4096), AB_REPS (reps per arm per round, default 3), AB_ROUNDS (default 2)
set -u
cd /home/treo/projects/pdc/exllamav3
source sycl_moe/env.sh >/dev/null
M=$HOME/projects/vendor/tabbyAPI/models/Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4
LABEL=$1; shift
LENS=${AB_LENS:-4096}; REPS=${AB_REPS:-3}; ROUNDS=${AB_ROUNDS:-2}
OUT=/tmp/ab_${LABEL}
mkdir -p $OUT
echo "ab[$LABEL]: $(( $# * ROUNDS )) runs, arms=$#, lens=$LENS, reps=$REPS -> $OUT"

run_arm () {          # $1 = arm index, $2 = round
  local i=$1 r=$2 ev=${ARMS[$1]}
  local log=$OUT/arm${i}_r${r}.log
  {
    echo "=== arm=$i round=$r env=[$ev] start=$(date +%T)"
    # shellcheck disable=SC2086
    env $ev PB_TAG=a${i}r${r} ./.venv/bin/python sycl_moe/pb.py -m "$M" \
        -mcs 256 -ngr -mct 15 -mcpa -lens "$LENS" -reps "$REPS" 2>&1 \
        | grep -vE "registered layer|warm done|CPU split experts"
    echo "=== end=$(date +%T) rc=$?"
  } > "$log" 2>&1
  printf "  arm%-2s r%s: %s\n" "$i" "$r" "$(grep -h PB_RESULT "$log" | sed 's/ min=/ m=/;s/ med=.*reps/ reps/;s/ tag=.*//' | tr '\n' ' ')"
}

declare -a ARMS=("$@")
for ((r = 1; r <= ROUNDS; r++)); do
  for ((i = 0; i < ${#ARMS[@]}; i++)); do run_arm $i $r; done
done

echo "--- summary $LABEL (min over rounds; per length tok/s) ---"
python3 - "$OUT" "$LABEL" <<'PY'
import sys, os, re, glob, collections
out, label = sys.argv[1], sys.argv[2]
best = collections.defaultdict(dict)          # arm -> len -> best
envs = {}
for p in sorted(glob.glob(os.path.join(out, "arm*_r*.log"))):
    arm = re.search(r"arm(\d+)_", p).group(1)
    txt = open(p, errors = "replace").read()
    m = re.search(r"env=\[(.*?)\]", txt)
    if m: envs[arm] = m.group(1)
    for L, mn in re.findall(r"PB_RESULT len=(\d+) min=([\d.]+)", txt):
        best[arm][int(L)] = max(best[arm].get(int(L), 0.0), float(mn))
lens = sorted({L for d in best.values() for L in d})
print(f"{'arm':>4} " + " ".join(f"{l:>8}" for l in lens) + "   env")
for arm in sorted(best, key = int):
    row = " ".join(f"{best[arm].get(l, float('nan')):8.0f}" for l in lens)
    print(f"{arm:>4} {row}   {envs.get(arm, '?')[:96]}")
PY