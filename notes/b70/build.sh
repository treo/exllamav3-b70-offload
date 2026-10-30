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
# rev J (probe_dpas7): transposed tiles - current fastest, but needs the permuted device layout. Instantiates
# K_MIN..K_MAX x 5 M configurations, so the binary is ~8.5 MB and the build is slow; keep per_kernel splitting.
# rev J (probe_dpas7): transposed tiles - the current fastest decode kernel. Instantiates K_MIN..K_MAX x 5 M
# configurations, so the binary is ~8.5 MB and the build is slow; keep per_kernel splitting.
icpx -fsycl -O2 -fsycl-device-code-split=per_kernel -o probe_dpas7 probe_dpas7.cpp
echo "built probe_dpas7"
# D3-alt: the same kernel reading the parent's PRODUCTION staged bytes (AVX2 planar dword order) with no
# internal permute. gate_dpas.py --staged asserts this stays bit-exact - it is the regression gate behind
# "the B70 copy can be verbatim".
icpx -fsycl -O2 -fsycl-device-code-split=per_kernel -DDPAS_STAGED_LAYOUT -o /tmp/revJ_staged probe_dpas7.cpp
echo "built /tmp/revJ_staged (staged-layout input)"
# rev K (probe_dpas8): rev J + fused combine + DPAS_FLOOR. The fused combine is REFUTED (doc/port/
# b70-decode-closeout.md D2); keep this build because DPAS_FLOOR is the only instrument that separates fixed
# cost from per-tile work, and DPAS_COMBINE=split reproduces rev J's structure for A/B runs.
icpx -fsycl -O2 -fsycl-device-code-split=per_kernel -o probe_dpas8 probe_dpas8.cpp
echo "built probe_dpas8"

# D3 cost model: what the intra-tile permute charges for staging (device permute vs device copy vs host
# permute-copy). Takes an optional K argument; results in out_permute.txt.
icpx -fsycl -O2 -o probe_permute probe_permute.cpp
echo "built probe_permute"

# dp4a path: one binary per trellis K, since compile-time K is worth x1.2-1.5 at rows=1 (out_gemv.txt).
# gate_dpas.py expects /tmp/pgK<K>; it reports a clear SKIP when one is missing rather than passing silently.
for k in 2 3 4 5 6; do
    icpx -fsycl -O2 -DGEMV_KCONST=$k -o /tmp/pgK$k probe_gemv.cpp
done
echo "built /tmp/pgK2..6 (dp4a, rev C + compile-time K)"
echo "exactness gate: python3 gate_dpas.py   # dp4a / rev I / rev J / rev K, bit-exact vs y_ref and byte-identical to each other"
icpx -fsycl -O2 -shared -fPIC -o libb70shim.so b70_shim.cpp
echo "built libb70shim.so"
