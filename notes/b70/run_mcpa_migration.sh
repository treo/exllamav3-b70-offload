#!/usr/bin/env bash
# Does --moe_cpu_pinned_arena (-mcpa) actually earn its keep, and through which mechanism?
# Throughput says no on this box at b=1 (measured: 2.05 71.8 -> 63.0 tok/s, 2.68 58.3 -> 48.8, Qwen3.5 126.9 ->
# 82.1 - the last one reproducing the recorded acceptance figure of ~100 -> ~78). But the operational claim about
# -mcpa is about PLACEMENT mobility - a pinned, shared arena lets hot experts migrate CPU->GPU - and migration
# pays over a horizon longer than a single decode pass. So compare the engine's own promotion/demotion counters,
# with a long enough run for sweeps to happen, not just the token rate.
#
#   nohup bash notes/b70/run_mcpa_migration.sh > /tmp/mcpa_migration.txt 2>&1 &
set -u
cd "$(dirname "$0")/../.." || exit 1
source notes/env.sh >/dev/null 2>&1
M=/home/treo/projects/vendor/tabbyAPI/models
CK=$M/Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4

while pgrep -f bench_engine_step >/dev/null; do sleep 20; done

for arm in plain pinned; do
    extra=""
    [ "$arm" = pinned ] && extra="-mcpa"
    echo "### $arm ($(date +%H:%M:%S))"
    for pass in 1 2; do
        python3 -u notes/bench_live_trace.py -m "$CK" -mcs 256 -mct 15 $extra \
            --decode 384 --stats-dir "/tmp/mig/$arm" --out "/tmp/mig/$arm-p$pass.json" 2>&1 |
            grep -E "decode wall|placement migration|routing:|no split" | sed "s/^/  p$pass/"
        [ -s "/tmp/mig/$arm-p$pass.json" ] || echo "  p$pass NO OUTPUT FILE - arm failed"
    done
done
echo "### done $(date +%H:%M:%S)"