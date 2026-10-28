"""Find MoE layers whose routed experts do not all share one trellis bitrate.

    python notes/scan_mixed_rates.py MODEL_DIR [MODEL_DIR ...]

For each layer, collects the set of trellis tile widths (16*K uint16 per 16x16 tile) across
gate/up/down of every routed expert, and reports layers where more than one width occurs.
"""
import glob
import json
import os
import re
import struct
import sys
from collections import defaultdict


def rate(width):
    k, rem = divmod(width, 16)
    return f"{k}" if rem == 0 else f"{k}.5"


def scan(d):
    per = defaultdict(lambda: defaultdict(int))     # layer -> (proj, width) -> count
    nexp = defaultdict(set)
    files = sorted(glob.glob(os.path.join(d, "*.safetensors")))
    if not files:
        print(f"no safetensors under {d}")
        return
    for f in files:
        with open(f, "rb") as fh:
            ln = struct.unpack("<Q", fh.read(8))[0]
            hdr = json.loads(fh.read(ln))
        for k, v in hdr.items():
            if k == "__metadata__":
                continue
            m = re.search(r"^(.*?)layers\.(\d+)\.mlp\.experts\.(\d+)\.(up|gate|down)_proj\.trellis$", k)
            if not m or v["shape"][-1] == 0:
                continue
            scope = "mtp" if m.group(1).startswith("mtp.") else (
                "main" if "language_model" in m.group(1) else m.group(1) or "other")
            lay = f"{scope} {m.group(2)}"
            per[lay][(m.group(4), v["shape"][-1])] += 1
            nexp[lay].add(int(m.group(3)))
    print(f"== {os.path.basename(d.rstrip('/'))}")
    mixed = 0
    for lay in sorted(per, key = lambda x: (x.split()[0] != "main", int(x.split()[1]))):
        widths = {w for _, w in per[lay]}
        if len(widths) > 1:
            mixed += 1
            experts = len(nexp[lay])
            detail = ", ".join(f"{p}@{w}({rate(w)}bpw)x{c}" for (p, w), c in sorted(per[lay].items()))
            print(f"   layer {lay}: {experts} experts, widths {sorted(widths)} -> {detail}")
    if not mixed:
        print("   no mixed-rate layers; every layer uniform")
    # summary of uniform rates
    uni = defaultdict(int)
    for lay in per:
        for (p, w), c in per[lay].items():
            uni[(w, rate(w))] += c
    print("   all widths seen:", {f"{w} ({r} bpw)": c for (w, r), c in sorted(uni.items())})


if __name__ == "__main__":
    dirs = sys.argv[1:] or sorted(glob.glob("/home/treo/projects/vendor/tabbyAPI/models/*exl3*"))
    for d in dirs:
        scan(d)