#!/usr/bin/env bash
# CPU-home baseline matrix: -mcpa (pinned arena, lets hot experts migrate CPU->GPU) x worker threads, each arm run
# twice through the SAME stats directory so the first pass shows what placement learning is worth and the second is
# the converged number the plan should charge. Threads capped at 15: this box has 16 physical cores and the engine
# pins the worker to 16 logical processors, so one is left for GPU<->CPU traffic.
#
#   nohup bash notes/b70/run_home_matrix.sh > /tmp/home_matrix.txt 2>&1 &
set -u
M=/home/treo/projects/vendor/tabbyAPI/models
TRACE=/tmp/hometrace
mkdir -p "$TRACE"

run() {   # run <label> <ckpt-basename> <mcs> <extra model_init args...>
    local label="$1" ckpt="$2" mcs="$3"; shift 3
    echo "### $label  ($(date +%H:%M:%S))"
    for pass in 1 2; do
        python3 -u notes/bench_live_trace.py -m "$M/$ckpt" -mcs "$mcs" "$@" \
            --decode 192 --stats-dir "$TRACE/$label" --out "$TRACE/$label-p$pass.json" 2>&1 |
            grep -E "^live trace|decode wall|serialized|pipelining|routing:|union multiplier" |
            sed "s/^/  p$pass/"
    done
}

cd "$(dirname "$0")/../.." || exit 1
source notes/env.sh >/dev/null 2>&1

# Qwen3.8@2.68 - the plan's primary profile. 384 of 512 experts on the CPU is the smallest split that loads.
run 268_t15_pa   Qwen3.8-Flash-Next-exl3-2.68bpw_h6_ng8 384 -mct 15 -mcpa
run 268_t15      Qwen3.8-Flash-Next-exl3-2.68bpw_h6_ng8 384 -mct 15
# Qwen3.8@2.05 - 256 is the smallest split that loads.
run 205_t15_pa   Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4 256 -mct 15 -mcpa
run 205_t15      Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4 256 -mct 15
# Qwen3.5 - fits entirely on the GPU, so it is the control where "no CPU leg exists": gives the clean
# generator-vs-forward-only difference (head + sampler) and exact kernel buckets with the fixed printer.
run q35_t15_pa   Qwen3.5-35B-A3B-3bpw-hq2 128 -mct 15 -mcpa
echo "### matrix done $(date +%H:%M:%S)"