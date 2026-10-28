# Source this before any python run in this repo (build env for the JIT extension).
# CUDAHOSTCXX: the system gcc is 16.2 which nvcc (CUDA 13.2) rejects; g++-15 works.
source /home/treo/projects/pdc/exllamav3/.venv/bin/activate
export CUDAHOSTCXX=g++-15
export CC=gcc
export CXX=g++
export PATH=/usr/local/cuda-13.2/bin/:$PATH