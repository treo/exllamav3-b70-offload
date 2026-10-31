#!/usr/bin/env bash
# Parent legs for the rest of the quant ladder, and for GLM.
#
# WHY. doc/port/b70-tiering.md 5 computes the two-card split from max(T_parent + bytes_g/190, bytes_b/rate_b),
# and PARENT_ENGINE_US currently holds two entries (2.05 = 141.9, 2.68 = 195.6 us/layer) while every bigger recipe
# and GLM are ASSUMED. The GLM row is the one that matters most: it is the config where the split answer flips to
# ~50/50, and 595 us/layer in that calculation is a placeholder, not a measurement (D11 says the parent is charged
# engine-measured or not at all, so the tiering table is violating its own rule for exactly the interesting case).
#
# -mcs selection: the 3090's expert share shrinks as bits grow, so the smallest working split grows with the
# recipe. Each arm tries the listed value and steps down if the load fails, because "Insufficient VRAM in split"
# is a load-time abort, not a warning - and an arm that never loaded must never contribute a number (LESSONS 52).
#
#   nohup bash notes/b70/run_parent_ladder.sh > /tmp/parent_ladder.txt 2>&1 &
set -u
cd "$(dirname "$0")/../.." || exit 1
source notes/env.sh >/dev/null 2>&1
M=/home/treo/projects/vendor/tabbyAPI/models
OUT=/tmp/parent_ladder
mkdir -p "$OUT"

arm() {   # arm <label> <ckpt> <mcs candidates...>
    local label="$1" ckpt="$2"; shift 2
    for mcs in "$@"; do
        local log="$OUT/${label}_mcs$mcs.log"
        echo "=== $label -mcs $mcs ($(date +%H:%M:%S))"
        timeout 2400 python3 -u notes/bench_engine_step.py -m "$M/$ckpt" -mcs "$mcs" -mct 15 -cs 8192 \
            --ctx 4096 --tokens 48 > "$log" 2>&1
        local rc=$?
        if grep -q "Insufficient VRAM" "$log"; then
            echo "    load failed at -mcs $mcs (Insufficient VRAM); trying the next value"
            continue
        fi
        if [ $rc -ne 0 ] || [ ! -s "$log" ]; then
            echo "    ARM FAILED rc=$rc at -mcs $mcs - read nothing into the table"
            continue
        fi
        grep -E "non-expert|expert|TOTAL|us/layer|hyper|buckets|top kernels" "$log" | head -22 | sed 's/^/    /'
        echo "    -> $log"
        return 0
    done
    echo "    $label: no -mcs value loaded; NO NUMBER for this recipe"
}

# Qwen3.8 ladder. 2.05/2.68 are already in out_engine_step.txt; the rest are what this adds.
arm q405 Qwen3.8-Flash-Next-exl3-4.05bpw_h6_ng6 448 384 256
arm q418 Qwen3.8-Flash-Next-exl3-4.18bpw_h6_ng8 448 384 256
arm q505 Qwen3.8-Flash-Next-exl3-5.05bpw_h6_ng8 448 384
arm q605 Qwen3.8-Flash-Next-exl3-6.05bpw_h6_ng8 448 384
# GLM: 42 layers, 288 experts, 109.3 GiB of experts. Long load; this is the number the tiering table needs.
arm glm  GLM-5.3-Flash-exl3@3.05bpw 448 384
echo "### parent ladder done $(date +%H:%M:%S)"