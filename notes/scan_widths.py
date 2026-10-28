"""Scan EXL3 checkpoints for the trellis widths actually used, per module class.

Prints, for each model: distinct (last-dim of .trellis) -> rate K, with the tensor classes that
carry it and byte sizes. Real data for the mul1 trellis spec.
"""
import glob
import json
import os
import re
import struct
import sys
from collections import defaultdict

MODELS = sys.argv[1:] or sorted(glob.glob("/home/treo/projects/vendor/tabbyAPI/models/*exl3*"))


def rate(width):
    k, rem = divmod(width, 16)
    if rem == 0:
        return str(k)
    if rem == 8:
        return f"{k}.5"
    return f"?{width}"


def cls(key):
    key = re.sub(r"^model\.(language_model|vision_model)\.", "", key)
    key = re.sub(r"layers\.\d+\.", "layers.N.", key)
    key = re.sub(r"experts\.\d+\.", "experts.N.", key)
    key = re.sub(r"\.(trellis|suh|svh|bias|mul1|mcg)$", "", key)
    return key


for d in MODELS:
    if not os.path.isdir(d):
        continue
    try:
        qc = json.load(open(os.path.join(d, "quantization_config.json")))
    except OSError:
        continue
    print("==" * 30)
    print(d.split("/")[-1], "| bits", qc.get("bits"), "| codebook", qc.get("codebook"),
          "| head_bits", qc.get("head_bits"), "| mtp_bits", qc.get("mtp_bits"))
    widths = defaultdict(lambda: [0, 0, set()])
    for f in sorted(glob.glob(os.path.join(d, "model*.safetensors"))):
        with open(f, "rb") as fh:
            n = struct.unpack("<Q", fh.read(8))[0]
            h = json.loads(fh.read(n))
        for k, v in h.items():
            if k == "__metadata__" or not k.endswith(".trellis"):
                continue
            w = v["shape"][-1]
            e = widths[w]
            e[0] += 1
            e[1] += v["shape"][0] * v["shape"][1] * w * 2
            if len(e[2]) < 14:
                e[2].add(cls(k))
    for w in sorted(widths):
        c, b, cs = widths[w]
        print(f"  tile w={w:3d}  K={rate(w):>4s} bpw  tensors={c:7d}  bytes={b/2**30:7.2f} GiB")
        for x in sorted(cs):
            print(f"        {x}")