#!/usr/bin/env bash
# Second half of the home matrix: the -mcpa arms (pinned arena), which the first pass of run_home_matrix.sh
# never actually ran - bench_live_trace.py's own parser ate "-mcpa" as "-m cpa" and crashed at load. Each arm
# runs twice through one stats directory: pass 1 = placement warming up, pass 2 = converged, which is the number
# to charge. Ends with the Qwen3.5 device-bucket runs that give exact kernel splits with the fixed printer and a
# clean generator-vs-forward comparison (that model can hold every expert on the GPU).
#
#   nohup bash notes/b70/run_mcpa_arms.sh > /tmp/mcpa_arms.txt 2>&1 &
set -u
cd "$(dirname "$0")/../.." || exit 1
source notes/env.sh >/dev/null 2>&1
M=/home/treo/projects/vendor/tabbyAPI/models
T=/tmp/hometrace

arm() {   # arm <label> <ckpt> <mcs> <threads> [extra]
    local label="$1" ckpt="$2" mcs="$3" thr="$4" extra="${5:-}"
    echo "### $label ($(date +%H:%M:%S))"
    for pass in 1 2; do
        # shellcheck disable=SC2086
        python3 -u notes/bench_live_trace.py -m "$M/$ckpt" -mcs "$mcs" -mct "$thr" $extra \
            --decode 192 --stats-dir "$T/$label" --out "$T/$label-p$pass.json" 2>&1 |
            grep -E "decode wall|serialized|pipelining|routing:|no split modules|Error|error" |
            sed "s/^/  p$pass/"
        # never let a silent arm look like a slow arm
        [ -s "$T/$label-p$pass.json" ] || echo "  p$pass NO OUTPUT FILE - arm failed, do not read anything into it"
    done
}

arm 268_t15_pa Qwen3.8-Flash-Next-exl3-2.68bpw_h6_ng8 384 15 -mcpa
arm 205_t15_pa Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4  256 15 -mcpa
arm q35_t15_pa Qwen3.5-35B-A3B-3bpw-hq2                128 15 -mcpa

echo "### q35 device buckets, all experts on GPU ($(date +%H:%M:%S))"
python3 -u notes/bench_engine_step.py -m "$M/Qwen3.5-35B-A3B-3bpw-hq2" -cs 8192 --ctx 4096 --tokens 48 2>&1 |
    sed -n '/engine step bench/,$p'
echo "### q35 device buckets, -mcs 128 -mcpa ($(date +%H:%M:%S))"
python3 -u notes/bench_engine_step.py -m "$M/Qwen3.5-35B-A3B-3bpw-hq2" -mcs 128 -mct 15 -mcpa -cs 8192 \
    --ctx 4096 --tokens 48 2>&1 | sed -n '/engine step bench/,$p'
echo "### mcpa arms done $(date +%H:%M:%S)"