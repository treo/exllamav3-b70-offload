#!/usr/bin/env bash
# End-to-end MoE-CPU-offload measurement driver.
#
#   bash notes/run_e2e.sh <name> [<name> ...]      # run selected configs
#   bash notes/run_e2e.sh all
#
# Each config is one eval/perf.py process (env vars are read once per process, which is how most
# knobs are specified). Results land in notes/m_e2e_<name>.txt.
set -u
cd "$(dirname "$0")/.."
source notes/env.sh

MODEL=${MODEL:-/home/treo/projects/vendor/tabbyAPI/models/Qwen3.5-35B-A3B-3bpw-hq2}
PERF_ARGS=${PERF_ARGS:--cs 8192 -chunk_size 4096 -max_length 4096 -dr 2}

run() {
    name=$1; envs=$2; args=$3
    out=notes/m_e2e_${name}.txt
    echo "=== $name: [$envs] $args"
    ( env $envs timeout 1500 python -u eval/perf.py -m "$MODEL" $PERF_ARGS $args ) > "$out" 2>&1
    echo "    exit=$? -> $out"
}

one() {
case "$1" in
    prof_split)   run prof_split   "EXL3_MOE_HANDOFF_PROF=1 EXL3_MOE_CPU_PROF=1 EXL3_SPLIT_PROF=1" "-mcs 192" ;;
    split192)     run split192     "" "-mcs 192" ;;
    split192pa)   run split192pa   "" "-mcs 192 -mcpa" ;;
    split255)     run split255     "" "-mcs 255" ;;
    split255pa)   run split255pa   "" "-mcs 255 -mcpa" ;;
    layer20)      run layer20      "" "-mcl 20" ;;
    layer40)      run layer40      "" "-mcl 40" ;;
    streamdbg)    run streamdbg    "EXL3_MOE_STREAM_DEBUG=1" "-mcs 192" ;;
    nomemops)     run nomemops     "EXL3_MOE_MEMOPS=0" "-mcs 192" ;;
    slots8)       run slots8       "EXL3_MOE_CPU_SLOTS=8 EXL3_MOE_CPU_SLOT_ROWS=128" "-mcs 192" ;;
    slotrows32)   run slotrows32   "EXL3_MOE_CPU_SLOT_ROWS=32" "-mcs 192" ;;
    threads8)     run threads8     "" "-mcs 192 -mct 8" ;;
    nostatic)     run nostatic     "EXL3_MOE_CPU_SWAP=0" "-mcs 192" ;;
    streamT0)     run streamT0     "EXL3_MOE_STREAM_T=1000000" "-mcs 192" ;;
    streamT4)     run streamT4     "EXL3_MOE_STREAM_T=4" "-mcs 192" ;;
    batch48)      run batch48      "EXL3_MOE_STREAM_BATCH_EXPERTS=48 EXL3_MOE_CPU_WSLOT_MB=96" "-mcs 192" ;;
    minrows)      run minrows      "EXL3_MOE_STREAM_MIN_ROWS=4096" "-mcs 192" ;;
    noswizzle)    run noswizzle    "EXL3_MOE_CPU_SWIZZLE=0" "-mcs 192" ;;
    nowide)       run nowide       "EXL3_MOE_CPU_WIDE=0" "-mcs 192" ;;
    fusedT64)     run fusedT64     "EXL3_MOE_STREAM_FUSED_T=64" "-mcs 192" ;;
    fusedT64nb)   run fusedT64nb   "EXL3_MOE_STREAM_FUSED_T=64 EXL3_MOE_STREAM_BATCH_RECON=0" "-mcs 192" ;;
    fusedT32dbg)  run fusedT32dbg  "EXL3_MOE_STREAM_FUSED_T=32 EXL3_MOE_STREAM_DEBUG=1" "-mcs 192" ;;
    nobatchrecon) run nobatchrecon "EXL3_MOE_STREAM_BATCH_RECON=0" "-mcs 192" ;;
    all)
        for c in split192 split192pa split255 layer20 streamdbg; do one "$c"; done ;;
    *) echo "unknown config: $1"; exit 1 ;;
esac
}

if [ $# -eq 0 ]; then set -- all; fi
for c in "$@"; do one "$c"; done