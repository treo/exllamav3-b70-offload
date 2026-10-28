#!/bin/bash
# subprof.sh — interleaved, repeated per-stage host attribution of the decode forward.
#
# Why this exists: the per-stage numbers from EXL3_MOE_B70_HOSTPROF drift by +-25% between runs of
# the SAME binary (K1 measured 11.9, 13.0, 13.5, 15.9 and 17.3 us across runs). A single run per arm
# therefore cannot support a claim like "knob X moves the cost" - one such claim was made and has to
# be retracted because the knob in question was never implemented, and the two arms were the same
# binary measured twice. This script runs every arm once per round, ROUNDS rounds, and reports the
# MIN per stage across rounds (min-of-N is this project's discipline for a drifting box) plus the
# spread, so an arm is only called different if its min beats the control's min.
#
# Usage: sycl_moe/subprof.sh "LABEL=ENV" "LABEL=ENV" ...      (LABEL=... arms, env may be empty)
#   sycl_moe/subprof.sh "" "PROBE=EXL3_MOE_B70_PROBE_FIRST=1" "CE0=SYCL_PI_LEVEL_ZERO_USE_COPY_ENGINE=0"
set -u
cd /home/treo/projects/pdc/exllamav3
# NOTE: `set -u` must NOT wrap the env sourcing - oneAPI's setvars.sh references OCL_ICD_FILENAMES
# unbound and aborts under nounset (this bit the first cut of this script).
set +u
source sycl_moe/env.sh >/dev/null
set -u
M=$HOME/projects/vendor/tabbyAPI/models/Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4
ROUNDS=${SUBPROF_ROUNDS:-3}
ARGS=${SUBPROF_ARGS:--mcs 256 -ngr -mct 15 -mcpa --max_length 4096 -spf -dr 3}
OUT=/tmp/subprof.$$
mkdir -p "$OUT"
declare -a ARMS=("$@")
echo "subprof: ${#ARMS[@]} arms x $ROUNDS rounds  args=[$ARGS]"
for ((r = 1; r <= ROUNDS; r++)); do
  for ((i = 0; i < ${#ARMS[@]}; i++)); do
    arm="${ARMS[$i]}"
    log="$OUT/arm${i}_r${r}.log"
    # shellcheck disable=SC2086
    # `env` is REQUIRED, not stylistic: bash picks the command word at PARSE time, so in
    # `VAR=1 VAR2=1 $arm cmd` an expanded $arm that looks like an assignment BECOMES the command
    # ("EXL3_MOE_B70_INORDER=1: command not found"). That bug made every knob arm in the first two
    # versions of this script die instantly with an empty log - which is how "the env knobs change
    # nothing" came to be concluded from runs that never ran. Empty/no-window arms now fail loudly.
    env EXL3_MOE_B70=1 EXL3_MOE_B70_HOSTPROF=1 $arm timeout 1200 \
        ./.venv/bin/python eval/perf.py -m "$M" $ARGS > "$log" 2>&1
    rc=$?
    if ! grep -q "hostprof\[decode-float\]" "$log"; then
        echo "  !! arm$i r$r [$arm] produced NO decode-float window (rc=$rc); tail:"
        tail -2 "$log" | sed 's/^/       /'
    fi
    line=$(grep "hostprof\[decode-float\]" "$log" | tail -1)
    reg=$(grep -o "registered=[0-9]*" "$log" | tail -1)
    printf "  r%-2d arm%-2d [%s] %s %s\n" "$r" "$i" "${arm:-control}" "$(echo "$line" | grep -o 'host [0-9.]* us/fwd')" "$reg"
    echo "$line" > "$OUT/stage_arm${i}_r${r}.txt"
  done
done
echo "--- per-stage minimum over rounds (us; pre|enq|body) ---"
python3 - "$OUT" "${#ARMS[@]}" <<'PY'
import sys, re, glob, os, collections
out, nar = sys.argv[1], int(sys.argv[2])
# stage label order is fixed by the instrument; keep the union across rounds
best = collections.defaultdict(dict)     # arm -> stage -> (pre, enq, body)
pat = re.compile(r'\[(\d+) (\S+) ([\d.]+)\|([\d.]+)\|b([\d.]+)\]')
for i in range(nar):
    for f in glob.glob(f"{out}/stage_arm{i}_r*.txt"):
        for m in pat.finditer(open(f).read()):
            idx, nm, pre, enq, body = m.group(1), m.group(2), *map(float, m.groups()[2:])
            key = f"{idx} {nm}"
            cur = best[i].get(key)
            if cur is None or enq < cur[1]: best[i][key] = (float(pre), float(enq), float(body))
tot = {}
for i in range(nar):
    for f in glob.glob(f"{out}/stage_arm{i}_r*.txt"):
        h = re.search(r'host ([\d.]+) us/fwd', open(f).read())
        if h: tot[i] = min(tot.get(i, 1e30), float(h.group(1)))
labels = []
for i in range(nar): labels += list(best[i].keys())
seen = list(dict.fromkeys(labels))
print(f"{'stage':<22}" + "".join(f"arm{i:<2}(enq|body)   " for i in range(nar)))
for k in seen:
    row = f"{k:<22}"
    for i in range(nar):
        v = best[i].get(k)
        row += f"{v[1]:7.2f}|{v[2]:5.2f}    " if v else " " * 16
    print(row)
print(f"{'TOTAL host us/fwd':<22}" + "".join(f"{tot.get(i, float('nan')):7.2f}          " for i in range(nar)))
PY
echo "(logs in $OUT)"