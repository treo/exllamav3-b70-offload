#!/usr/bin/env bash
# Is the CPU expert leg actually in the PARENT's prefill path, and how big is it?
#
# The bench-vs-engine cost gap (out_host_mem.txt 5) could only mean one of two things: the CPU worker is not on
# the prefill path the way it is on decode's, or bench_cpu_moe.py's absolute cost does not transfer (uniform
# routing charges every loaded expert 98 rows, while the experts added by raising -mcs are the coldest ones).
# Vary the confounder instead of arguing about it: hold prompt and chunk fixed and sweep -mcs, the number of
# CPU-homed experts. Time should be affine in it if the leg is real, and the slope IS its marginal cost.
#
# Arms chosen against the operator's known floors: -mcs 32 is expected to fail to load ("Insufficient VRAM in
# split for model and cache") and that failure is itself recorded, not suppressed.
#
#   nohup bash notes/b70/run_mcs_slope.sh > /tmp/mcs_slope.txt 2>&1 &
set -u
cd "$(dirname "$0")/../.." || exit 1
source notes/env.sh >/dev/null 2>&1
M=/home/treo/projects/vendor/tabbyAPI/models/Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4
OUT=/tmp/mcs_slope
mkdir -p "$OUT"

echo "label   mcs   median_prefill_ms   tok/s   promotions   note"
# MODE=plain reproduces the CPU-leg slope; MODE=mcpa re-fits it under promotion, which is the test of whether
# -mcpa and the B70 draw on the same term (they do: slope 10.24 -> 5.59 ms/expert, intercept +221 ms).
MODE="${1:-both}"
for FLAG in $( [ "$MODE" = mcpa ] && echo "-mcpa" ; [ "$MODE" = plain ] && echo "-" ; [ "$MODE" = both ] && echo "- -mcpa" ); do
  TAG=$([ "$FLAG" = "-" ] && echo plain || echo mcpa)
  for MCS in 32 128 256 384 448; do
    log="$OUT/${TAG}_mcs$MCS.log"
    extra=(); [ "$FLAG" != "-" ] && extra+=(-mcpa)
    python3 -u notes/bench_live_trace.py -m "$M" -cs 16384 --prefill 4096 --prefill-reps 3 \
        --corpus varied --decode 32 --reps 6 -chunk_size 2048 --stats-dir "$OUT/stats_${TAG}_$MCS" \
        --out "$OUT/${TAG}_mcs$MCS.json" -mcs "$MCS" -mct 15 "${extra[@]}" > "$log" 2>&1
    med=$(grep -oE "\(median of [0-9]+\): +[0-9.]+ ms +-> +[0-9]+ tok/s" "$log" | head -1)
    prom=$(grep -oE "[0-9]+ promotions" "$log" | head -1)
    note=""
    grep -q "Insufficient VRAM" "$log" && note="load failed: split too small for model+cache"
    [ -z "$med" ] && [ -z "$note" ] && note="no prefill measurement (rc!=0?) - read nothing"
    printf "%-6s %4s   %-30s %-13s %s\n" "$TAG" "$MCS" "${med:- -}" "${prom:--}" "$note"
  done
done
echo "# fit time = C + s*mcs per mode; s is the marginal cost of one CPU-homed expert per chunk and C is"
echo "# everything that is not CPU expert work. Measured 2025-11 (3 surviving arms each, 256/384/448):"
echo "#   plain: time = 1988 ms + 10.24 ms * mcs   residuals < 2 ms"
echo "#   -mcpa: time = 2210 ms +  5.59 ms * mcs   residuals < 30 ms, promotions ~385 at EVERY mcs (saturating)"
echo "#   -> CPU expert work is 57% of a 2.05 prefill (2619 ms of 4609 ms); -mcpa takes it to 39% at a cost of"
echo "#      +221 ms of non-expert overhead; the card's floor is 1988 + 734 = 2722 ms = 1.69x either way."
echo "# NOTE on precision: within one process the arms fit to <2 ms (plain) / <30 ms (-mcpa), but the same"
echo "# -mcs value across processes varied by 2.4%. Trust slopes; treat intercepts as +/- ~120 ms."