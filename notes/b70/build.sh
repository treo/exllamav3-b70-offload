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
# rev G (tokens on M) also instantiates one kernel per M in {1,2,4,8} and per KS path, so it wants the
# same per-kernel code split probe_dpas3 needs.
icpx -fsycl -O2 -fsycl-device-code-split=per_kernel -o probe_dpas4 probe_dpas4.cpp
echo "built probe_dpas4"
# rev H is ESIMD with K and M as template parameters (20 variants); per-kernel split keeps a run from
# JIT-compiling all of them.
icpx -fsycl -O2 -fsycl-device-code-split=per_kernel -o probe_dpas5 probe_dpas5.cpp
echo "built probe_dpas5"
# rev I (probe_dpas6): rev H with esimd::gather ring routing - the current fastest decode kernel.
icpx -fsycl -O2 -fsycl-device-code-split=per_kernel -o probe_dpas6 probe_dpas6.cpp
echo "built probe_dpas6"
icpx -fsycl -O2 -shared -fPIC -o libb70shim.so b70_shim.cpp
echo "built libb70shim.so"
