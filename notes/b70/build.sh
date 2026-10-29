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
         probe_unreg probe_coherency probe_rates; do
    icpx -fsycl -O2 -o "$f" "$f.cpp"
    echo "built $f"
done
icpx -fsycl -O2 -shared -fPIC -o libb70shim.so b70_shim.cpp
echo "built libb70shim.so"
