#!/bin/bash
# Prefill-regime quality gate (qa_stream.py): CPU worker vs B70 with hot-pick streaming vs
# B70 with the classic anti-theft rule. Identical model flags; only the routing policy moves.
cd /home/treo/projects/pdc/exllamav3/sycl_moe
source env.sh >/dev/null
M=$HOME/projects/vendor/tabbyAPI/models/Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4
ARGS="-m $M -mcs 256 -mcpa -ngr -mct 15 -cs 12288 -tok 8192 -chunk 1024"
{
for arm in "cpu:EXL3_MOE_B70=0" "k1:EXL3_MOE_B70=1" "k0:EXL3_MOE_B70=1 EXL3_MOE_B70_STREAM_HOT=0"; do
  tag=${arm%%:*}; ev=${arm#*:}
  printf "%-4s " $tag
  timeout 1200 env $ev ../.venv/bin/python qa_stream.py $ARGS 2>&1 | grep -E "QA_RESULT|Error" | tail -1
done
echo QA_DONE
} > /tmp/qa.txt 2>&1