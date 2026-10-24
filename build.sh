source /opt/intel/oneapi/setvars.sh
export CUDAHOSTCXX=g++-15 CC=gcc CXX=g++ PATH=/usr/local/cuda-13.2/bin/:$PATH
uv run python -m build -n
