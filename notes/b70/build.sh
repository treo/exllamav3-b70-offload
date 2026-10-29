#!/usr/bin/env bash
# Build the B70 probes and the ctypes shim.
#
# setvars.sh is sourced first on purpose: `set -u` makes it abort on an unbound variable
# (OCL_ICD_FILENAMES), which cost one confusing debugging pass.
#
# The Python probes need the repo venv on top of this:
#   bash build.sh && source ../env.sh && python -u probe_cross.py && python -u probe_crossproc.py
source /opt/intel/oneapi/setvars.sh >/dev/null || true
set -eo pipefail
cd "$(dirname "$0")"

for f in probe_transport probe_doorbell probe_notify probe_resident probe_stores probe_stores2 \
         probe_unreg probe_coherency probe_rates probe_gemv probe_dpas probe_dpas2 probe_unpack; do
    icpx -fsycl -O2 -o "$f" "$f.cpp"
    echo "built $f"
done
# probe_dpas3 instantiates every DPAS_F switch combination (2^4 variants x 2 operand sources). Without
# per-kernel code split the whole module is one device binary and the first launch JIT-compiles all of
# them - harmless for min-of-N timing but it makes a cold first process look anomalous.
icpx -fsycl -O2 -fsycl-device-code-split=per_kernel -o probe_dpas3 probe_dpas3.cpp
echo "built probe_dpas3"
icpx -fsycl -O2 -shared -fPIC -o libb70shim.so b70_shim.cpp
echo "built libb70shim.so"
