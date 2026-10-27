#!/bin/bash
# perfab.sh <label> "<ENV1>" "<ENV2>" ... — the same round-robin A/B as ab.sh but with the
# project's official end-to-end metric (eval/perf.py), one full process per arm per round.
#   ./perfab.sh mytest "EXL3_MOE_B70=1" "EXL3_MOE_B70=1 EXL3_MOE_STREAM_T=24 ..."
# Env: PERFAB_ARGS (perf.py args, default "-mcs 256 -ngr -mct 15 -mcpa --max_length 4096 -dr 5"),
#      PERFAB_ROUNDS (default 2). Summary = max over rounds per length (min-of-N discipline:
#      per NOTES rule 6 the first run under-registers, so 'best of rounds' is the honest filter).
set -u
cd /home/treo/projects/pdc/exllamav3
source sycl_moe/env.sh >/dev/null
M=$HOME/projects/vendor/tabbyAPI/models/Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4
LABEL=$1; shift
ARGS=${PERFAB_ARGS:--mcs 256 -ngr -mct 15 -mcpa --max_length 4096 -dr 5}
ROUNDS=${PERFAB_ROUNDS:-2}
OUT=/tmp/perfab_$LABEL
mkdir -p $OUT
declare -a ARMS=("$@")
echo "perfab[$LABEL]: ${#ARMS[@]} arms x $ROUNDS rounds, args=[$ARGS]"
for ((r = 1; r <= ROUNDS; r++)); do
  for ((i = 0; i < ${#ARMS[@]}; i++)); do
    log=$OUT/arm${i}_r${r}.log
    {
      echo "=== arm=$i round=$r env=[${ARMS[$i]}] start=$(date +%T)"
      # shellcheck disable=SC2086
      env ${ARMS[$i]} ./.venv/bin/python eval/perf.py -m "$M" $ARGS 2>&1 \
          | grep -vE "registered layer|warm done|CPU split experts"
      echo "=== end=$(date +%T)"
    } > "$log" 2>&1
    printf "  arm%-2s r%s pre[%s] dec[%s]\n" "$i" "$r" \
      "$(sed 's/\x1b\[[0-9;]*m//g' "$log" | awk '/^Length/{printf "%.0f ", $3}')" \
      "$(sed 's/\x1b\[[0-9;]*m//g' "$log" | awk '/^Context/{for(j=1;j<=NF;j++) if($j=="tokens/s"){printf "%.1f ", $(j-1); break}}')"
  done
done
echo "--- summary $LABEL (best of rounds) ---"
python3 - "$OUT" <<'PY'
import sys, os, re, glob, collections
out = sys.argv[1]
best = collections.defaultdict(lambda: ({}, []))
envs = {}
for p in sorted(glob.glob(os.path.join(out, "arm*_r*.log"))):
    arm = re.search(r"arm(\d+)_", p).group(1)
    txt = open(p, errors = "replace").read()
    m = re.search(r"env=\[(.*?)\]", txt)
    if m: envs[arm] = m.group(1)
    clean = re.sub(r"\x1b\[[0-9;]*m", "", txt)
    pre = {int(L): float(v) for L, v in re.findall(r"^Length\s+(\d+):\s+([\d.]+)", clean, re.M)}
    dec = [float(v) for v in re.findall(r"^Context\s+\d+:\s+S=1\s+([\d.]+)", clean, re.M)]
    bpre, bdec = best[arm]
    for L, v in pre.items(): bpre[L] = max(bpre.get(L, 0.0), v)
    if dec: bdec.append(sum(dec) / len(dec))
lens = sorted({L for a, (p, _) in best.items() for L in p})
print(" arm  " + "".join(f"{l:>8}" for l in lens) + "    dec_avg  env")
for arm in sorted(best, key=int):
    p, dcs = best[arm]
    dec = max(dcs) if dcs else float("nan")
    print(f"{arm:>4}  " + "".join(f"{p.get(l, float('nan')):8.0f}" for l in lens) + f"  {dec:8.1f}  {envs.get(arm,'?')[:80]}")
PY