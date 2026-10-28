#!/usr/bin/env bash
# A/B the effect of the saved hot-expert profile on the CPU-offload measurements.
#
#   bash notes/run_profile_ab.sh
#
# The dynamic placement modes write a per-model expert-frequency profile
# (~/.cache/exllamav3/expert_stats/<sha1(dir|E)>.json) at unload and permute experts hot-to-cold
# from it on the next load (block_sparse_mlp_cpu.py:55-75). The key covers the model directory and
# the expert count only, NOT the split size or placement mode, so consecutive runs of different
# configurations inherit each other's placement - every cross-run number in
# doc/prep/measured-costs.md §8 that came after the first offloaded run is "warm".
#
# For each configuration this runs eval/perf.py twice: once with the profile moved away (identity
# placement from the checkpoint order) and once with a fixed reference profile restored (same
# starting placement for every configuration). Reference profiles live in notes/refprofile_*.json.
set -u
cd "$(dirname "$0")/.."
source notes/env.sh

M35=/home/treo/projects/vendor/tabbyAPI/models/Qwen3.5-35B-A3B-3bpw-hq2
STATS=$HOME/.cache/exllamav3/expert_stats
KEY35=f7a562c02a09fb0d.json
REF=notes/refprofile_q35.json
PERF=${PERF_ARGS:--cs 8192 -chunk_size 4096 -max_length 2048 -dr 1}

[ -f "$REF" ] || { cp "$STATS/$KEY35" "$REF" && echo "saved reference profile -> $REF"; }

run_case() {
    local name=$1 state=$2; shift 2
    local out=notes/m_prof_ab_${name}_${state}.txt
    if [ "$state" = cold ]; then rm -f "$STATS/$KEY35"; else cp "$REF" "$STATS/$KEY35"; fi
    echo "=== $name / $state placement start"
    ( timeout 1500 python -u eval/perf.py -m "$M35" $PERF "$@" ) > "$out" 2>&1
    echo "    exit=$?"
    sed 's/\x1b\[[0-9;]*m//g' "$out" | grep -E "^Length    2048|^Context   (256|1024|1792):|saved profile" \
        | sed 's/^/      /'
}

for args in "split192:-mcs 192" "split192pa:-mcs 192 -mcpa"; do
    name=${args%%:*}; flags=${args#*:}
    for state in cold warm; do
        run_case "$name" "$state" $flags
    done
done
rm -f "$STATS/$KEY35"; cp "$REF" "$STATS/$KEY35"
echo "restored reference profile"
