#!/usr/bin/env bash
# Build the B70 probes. Everything needs the oneAPI environment; the Python probe additionally
# needs the repo venv (for torch + the CUDA extension), so source notes/env.sh after setvars.
set -euo pipefail
source /opt/intel/oneapi/setvars.sh >/dev/null
cd "$(dirname "$0")"
for f in probe_transport probe_doorbell probe_notify probe_resident; do
    icpx -fsycl -O2 -o "$f" "$f.cpp"
    echo "built $f"
done
icpx -fsycl -O2 -shared -fPIC -o libb70shim.so b70_shim.cpp
echo "built libb70shim.so"
