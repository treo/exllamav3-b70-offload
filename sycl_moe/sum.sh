#!/bin/bash
# usage: sum.sh [glob]   -> one line per perf log: tag, 256..4096 prefill, plus notes
cd /tmp
for f in ${1:-cfg_*.log}; do
  vals=$(sed 's/\x1b\[[0-9;]*m//g' "$f" | awk '/^Length/{printf "%6.0f ", $3}')
  dec=$(sed 's/\x1b\[[0-9;]*m//g' "$f" | awk '/^Context/{for(i=1;i<=NF;i++) if($i=="tokens/s") {printf "%5.1f ", $(i-1); break}}')
  err=$(grep -cE "forward failed|out of device memory|sycl error|Traceback" "$f")
  printf "%-18s PRE[%s] DEC[%s] err=%s\n" "${f%.log}" "$vals" "$dec" "$err"
done