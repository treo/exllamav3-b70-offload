"""Step-by-step probe of the fused issue/collect handoff (debug aid for bench_handoff.py)."""
import os
import sys
import time

import numpy as np
import torch

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "tests"))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from exllamav3.ext import exllamav3_ext as ext              # noqa: E402
from testlib.moe_handoff import (Segment, MOE_CTRL_SIZE, JOBS_TAIL, JOBS_HEAD, DATA_READY,  # noqa: E402
                                 DONE, CONSUMED, QUIT)
from bench_handoff import load_layer                        # noqa: E402

MODEL = sys.argv[1] if len(sys.argv) > 1 else \
    "/home/treo/projects/vendor/tabbyAPI/models/Qwen3.5-35B-A3B-3bpw-hq2"
L = load_layer(MODEL, 7, 8)
H, topk, E = L["H"], L["topk"], L["E"]
seg = Segment(2, 16, H, H, topk, 1, 1 << 20)
seg.register()
seg.start(threads = 4, stage_threads = 1)
print("worker ready, jobs tail/head", seg.word(JOBS_TAIL), seg.word(JOBS_HEAD))

rows = 1
dev = torch.device("cuda")
y = torch.randn(rows, H, dtype = torch.half, device = dev)
sel = torch.randint(0, E, (rows * topk,), dtype = torch.long, device = dev)
w = (torch.rand(rows, topk, device = dev) + .1).half()
cnt = torch.zeros(2, dtype = torch.int32, device = dev)
fin = torch.zeros(rows, H, dtype = torch.float, device = dev)


def sptr(slot, name):
    return seg.dev_base + MOE_CTRL_SIZE + slot * seg.slot_size + {
        "x": seg.off_x, "sel": seg.off_sel, "w": seg.off_w, "out": seg.off_out}[name]


ok = ext.exl3_moe_split_issue_fused(
    seg.base, 1, L["handle"], rows, topk, 0, 0, sel, None, None, y, w,
    sptr(0, "sel"), sptr(0, "x"), sptr(0, "w"), cnt, H, 0,
    seg.dev_base + DATA_READY, seg.dev_base + CONSUMED, seg.dev_base + 128)
print("issue call ok:", ok, "tail/head now", seg.word(JOBS_TAIL), seg.word(JOBS_HEAD))
sys.stdout.flush()
torch.cuda.synchronize()
print("after sync: data_ready", seg.flag(DATA_READY, 0), "jobs_head", seg.word(JOBS_HEAD))
t0 = time.time()
while time.time() - t0 < 5:
    if seg.flag(DONE, 0) >= 1:
        break
    time.sleep(0.001)
print("done flag:", seg.flag(DONE, 0), "head", seg.word(JOBS_HEAD),
      "err", seg.error, "after", time.time() - t0)
ext.exl3_moe_split_collect_fused(fin, sptr(0, "out"), cnt, 0, H, seg.dev_base + DONE, 1,
                                 seg.dev_base + CONSUMED, seg.dev_base + 128)
torch.cuda.synchronize()
print("collect synced, consumed:", seg.flag(CONSUMED, 0), "sum", float(fin.sum()))
seg.set_word(QUIT, 1)
time.sleep(0.05)
print("stopped", seg.stop())