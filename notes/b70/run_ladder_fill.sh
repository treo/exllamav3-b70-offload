#!/usr/bin/env bash
# Fill the E ladder between the measured rungs, so best_launch()'s brackets agree instead of disagreeing in 91%
# of cells (measured in out_live_trace.txt / the P4 note in plan_decode_cost.best_launch). Waits for the
# home-throughput matrix to release the device first, because both need the card alone.
#
#   nohup bash notes/b70/run_ladder_fill.sh > /tmp/ladder_fill.txt 2>&1 &
# NOTE: no `set -u` here - sourcing /opt/intel/oneapi/setvars.sh under it aborts the script silently
# (observed: 0 bytes of output, no dump directories). The other arm scripts source notes/env.sh only.
cd "$(dirname "$0")/../.." || exit 1
# BOTH are required: notes/env.sh alone leaves the SYCL runtime out of the picture and every probe
# then fails (which the sweep used to record as a table of 0.000 us - see sweep_ks_grid.py).
source /opt/intel/oneapi/setvars.sh >/dev/null 2>&1 || true
source notes/env.sh >/dev/null 2>&1

# wait until no notes/bench_*.py process is live (the card must be alone for timing)
while pgrep -f "notes/bench_(live_trace|engine_step)" >/dev/null; do sleep 20; done

for E in 8 12 48 80; do
    for P in gate up; do
        d=/tmp/ks_e${E}_${P}
        [ -s "$d/meta.json" ] && { echo "have $d"; continue; }
        echo "### dump E=$E $P  ($(date +%H:%M:%S))"
        if [ "$P" = gate ]; then EXTRA=""; else EXTRA="--proj up_proj"; fi
        python3 notes/b70/dump_gemv_case.py "$d" "$E" 16 0 --with-reference $EXTRA 2>&1 | tail -2
    done
done

echo "### sweep  ($(date +%H:%M:%S))"
python3 -u notes/b70/sweep_ks_grid.py --bin notes/b70/probe_dpas9 --es 8,12,48,80 --rows 1,8,16 --ks 1,2,4,8 \
    --dirs-template '/tmp/ks_e{E}_gate:/tmp/ks_e{E}_up' --warm 2
echo "### ladder fill done $(date +%H:%M:%S)"