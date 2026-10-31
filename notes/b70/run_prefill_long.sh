#!/usr/bin/env bash
# Long-chunk prefill baseline, on the fixed instrument.
#
# WHY THIS EXISTS. notes/b70/run_prefill_baseline.sh measured 2048 tokens, which cannot resolve the parent's
# FIXED per-chunk cost: whatever a forward spends regardless of length is amortized over 2048 tokens there. The
# operator's guidance is that chunk 2048-4096 is this machine's optimum, so realistic prefill speed has to be
# measured with a prompt of >= 4096 tokens and chunk size as the swept variable.
#
# TWO TRAPS THIS SCRIPT CLOSES (both found the hard way, both in LESSONS.md):
#  1. The prompt corpus used to be REFERENCE_TEXT x --reps, so a --prefill 4096 request silently measured 1158
#     tokens and printed a number. bench_live_trace.py now refuses that unless --prefill-allow-short, and the
#     prefill arm reads from a pool of DISTINCT in-repo documents instead of repeating text - because repeated
#     text routes every window to the same experts, which collapses distinct-expert coverage and inflates
#     prefill throughput. --corpus repeat is kept as the control that measures how big that bias is.
#  2. An arm that dies must not contribute a row. Each arm's own log is checked for the requested token count,
#     and a mismatch or missing line is reported as INVALID rather than read into the table.
#
#   nohup bash notes/b70/run_prefill_long.sh > /tmp/prefill_long.txt 2>&1 &
set -u
cd "$(dirname "$0")/../.." || exit 1
source notes/env.sh >/dev/null 2>&1
M=/home/treo/projects/vendor/tabbyAPI/models
OUT=/tmp/prefill_long
mkdir -p "$OUT"

# run <label> <ckpt> <prefill> <chunk> <corpus> [extra model_init args...]
run() {
    local label="$1" ckpt="$2" pf="$3" cs="$4" corpus="$5"; shift 5
    local log="$OUT/$label.log"
    echo "### $label  prefill=$pf chunk=$cs corpus=$corpus  ($(date +%H:%M:%S))"
    python3 -u notes/bench_live_trace.py -m "$M/$ckpt" -cs 16384 --prefill "$pf" --corpus "$corpus" \
        --decode 32 --reps 6 --stats-dir "$OUT/$label" --out "$OUT/$label.json" \
        ${cs:+-chunk_size} ${cs:+"$cs"} "$@" > "$log" 2>&1
    local rc=$?
    grep -E "prefill corpus:|prefill [0-9]+ tokens|experts touched|MEASURING|unrecognised|Traceback|SystemExit|FAILED|decode wall|placement migration" \
        "$log" | sed 's/^/  /'
    # Arm validity: the measured token count must equal what was requested, or the row is not a $pf-token number.
    if grep -q "MEASURING" "$log"; then
        echo "  ARM INVALID (short prompt measured); not usable as a $pf-token number"
    elif ! grep -q "prefill $pf tokens" "$log"; then
        echo "  ARM FAILED (rc=$rc, no 'prefill $pf tokens' line) - read nothing into the table"
    else
        echo "  -> ok, $OUT/$label.json"
    fi
}

# 2.05, smallest split that loads (256 of 512 experts remote). Chunk swept across and past the operator's band;
# 8192 tokens shows whether the fixed cost is per chunk or per forward.
run c205_4096_k1024 Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4 4096 1024 varied -mcs 256 -mct 15
run c205_4096_k2048 Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4 4096 2048 varied -mcs 256 -mct 15
run c205_4096_k4096 Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4 4096 4096 varied -mcs 256 -mct 15
run c205_8192_k4096 Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4 8192 4096 varied -mcs 256 -mct 15
# The control the user's objection demands: same tokens, same chunk, periodic text. If prefill gets faster and
# expert coverage drops, the varied corpus was load-bearing and no repeated-text baseline can be trusted.
run c205_4096_k4096_repeat Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4 4096 4096 repeat -mcs 256 -mct 15
# 2.68, the capacity-tight recipe.
run c268_4096_k2048 Qwen3.8-Flash-Next-exl3-2.68bpw_h6_ng8 4096 2048 varied -mcs 384 -mct 15
run c268_4096_k4096 Qwen3.8-Flash-Next-exl3-2.68bpw_h6_ng8 4096 4096 varied -mcs 384 -mct 15
echo "### long prefill baseline done $(date +%H:%M:%S)"