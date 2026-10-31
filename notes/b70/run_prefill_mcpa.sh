#!/usr/bin/env bash
# Does hot-expert promotion (-mcpa) pay for prefill, and over what horizon?
#
# WHY THIS COULD BE THE BIGGEST PREFILL LEVER ON THIS SYSTEM. A 4096-token chunk on Qwen3.8 touches ~418 of 512
# experts per layer at ~98 rows/expert (measured, out_prefill_long.txt), so in the plain mode the parent streams
# the bulk of a layer's expert bytes from the CPU home at ~13-14 GB/s on EVERY chunk. -mcpa lets hot experts
# migrate CPU->GPU, so the ones carrying most of the rows can be served from VRAM afterwards. Two predictions
# follow, and both are testable here:
#   (a) the benefit needs a HORIZON - the first touch pays a copy, later touches save traffic. On decode this
#       made -mcpa look like a regression when measured on one pass (LESSONS 66: 3,689 promotions vs plain's
#       ZERO, parity by pass 2), so every arm runs the same prefill 5 times and prints each pass.
#   (b) the benefit should GROW as the engine's chunk shrinks below the prompt, because each extra sub-chunk is
#       another pass over the same hot experts: k1024 (4 sub-chunks) should gain more than k4096 (1 chunk, no
#       intra-forward repetition at all). If k4096 gains as much as k1024, the mechanism is not sub-chunk
#       repetition and this explanation is wrong.
#
#   nohup bash notes/b70/run_prefill_mcpa.sh > /tmp/prefill_mcpa.txt 2>&1 &
set -u
cd "$(dirname "$0")/../.." || exit 1
source notes/env.sh >/dev/null 2>&1
M=/home/treo/projects/vendor/tabbyAPI/models
OUT=/tmp/prefill_mcpa
mkdir -p "$OUT"

run() {   # run <label> <ckpt> <chunk> <extra args...>
    local label="$1" ckpt="$2" cs="$3"; shift 3
    local log="$OUT/$label.log"
    echo "### $label chunk=$cs $* ($(date +%H:%M:%S))"
    python3 -u notes/bench_live_trace.py -m "$M/$ckpt" -cs 16384 --prefill 4096 --prefill-reps 5 \
        --corpus varied --decode 32 --reps 6 -chunk_size "$cs" --stats-dir "$OUT/$label" \
        --out "$OUT/$label.json" "$@" > "$log" 2>&1
    local rc=$?
    grep -E "pass [0-9]+:|prefill 4096 tokens|experts touched|placement migration|MEASURING|unrecognised|Traceback|FAILED" \
        "$log" | sed 's/^/  /'
    if grep -qE "MEASURING|Traceback|FAILED" "$log" || ! grep -q "prefill 4096 tokens" "$log"; then
        echo "  ARM FAILED (rc=$rc) - read nothing into the table"
    else
        echo "  -> ok"
    fi
}

S=Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4
L=Qwen3.8-Flash-Next-exl3-2.68bpw_h6_ng8
# control: same repetitions, no promotion mechanism, so any per-pass drift is warmth and not -mcpa
run p205_k2048_plain   "$S" 2048 -mcs 256 -mct 15
run p205_k2048_mcpa    "$S" 2048 -mcs 256 -mct 15 -mcpa
run p205_k1024_mcpa    "$S" 1024 -mcs 256 -mct 15 -mcpa
run p205_k4096_mcpa    "$S" 4096 -mcs 256 -mct 15 -mcpa
run p268_k2048_plain   "$L" 2048 -mcs 384 -mct 15
run p268_k2048_mcpa    "$L" 2048 -mcs 384 -mct 15 -mcpa
echo "### mcpa prefill arms done $(date +%H:%M:%S)"