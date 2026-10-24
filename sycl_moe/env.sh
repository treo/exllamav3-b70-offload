# Source this before building/running anything torch- or SYCL-related in this repo.
# The torch JIT extension cache keys on the environment; keep this exact recipe so the
# prebuilt ~190-object CUDA extension is reused (gcc-16 vs nvcc otherwise breaks rebuilds:
# the shim makes plain g++ = g++-15 for any full rebuild).
source /opt/intel/oneapi/setvars.sh >/dev/null
export PATH=/home/treo/projects/pdc/exllamav3/.toolfix:$PATH
export CUDAHOSTCXX=g++-15 CC=gcc-15 CXX=g++-15
export EXL3_MOE_B70_LIB=/home/treo/projects/pdc/exllamav3/sycl_moe/libb70moe.so
