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
for MCS in 32 128 256 384 448; do
    log="$OUT/mcs$MCS.log"
    python3 -u notes/bench_live_trace.py -m "$M" -cs 16384 --prefill 4096 --prefill-reps 3 \
        --corpus varied --decode 32 --reps 6 -chunk_size 2048 --stats-dir "$OUT/stats$MCS" \
        --out "$OUT/mcs$MCS.json" -mcs "$MCS" -mct 15 > "$log" 2>&1
    med=$(grep -oE "\(median of [0-9]+\): +[0-9.]+ ms +-> +[0-9]+ tok/s" "$log" | head -1)
    prom=$(grep -oE "[0-9]+ promotions" "$log" | head -1)
    note=""
    grep -q "Insufficient VRAM" "$log" && note="load failed: split too small for model+cache"
    [ -z "$med" ] && [ -z "$note" ] && note="no prefill measurement (rc!=0?) - read nothing"
    printf "%-7s %4s   %-30s %-13s %s\n" "mcs" "$MCS" "${med:- -}" "${prom:--}" "$note"
done
echo "# fit time = C + s*mcs from the surviving rows; s is the marginal cost of one CPU-homed expert per chunk,"
echo "# C is everything that is not CPU expert work. Measured 2025-11 (3 surviving arms: 256/384/448):"
echo "#   time = 1991.6 ms + 10.23 ms * mcs, residuals < 2 ms over a 1.4x range of remote-expert counts"
echo "#   -> 2.05 prefill at 4096 tokens: ~2619 ms (57%) CPU expert work, ~1992 ms everything else"
echo "#   -> arms at -mcs 32 and 128 fail to load ('Insufficient VRAM in split for model and cache'): the split"
echo "#      floor the operator reported, reproduced here as a by-product of the slope design"
echo "# NOTE on precision: within one process the arms fit this line to <2 ms, but the same -mcs value measured"
echo "# in a different process varied by 2.4% (4608.9 vs 4723.9 ms). Trust the slope, not the absolute level."