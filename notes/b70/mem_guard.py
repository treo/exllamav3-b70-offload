#!/usr/bin/env python3
"""One memory guard for every model-loading bench in this plan.

Why this is a MODULE and not a few lines in each script: on 2025-11 a GLM + `-mcpa` + chunked-prefill arm that I
queued unattended hard-hung the box and forced a reboot. The cause was arithmetic, not chance — GLM-5.3's routed
experts are 109.3 GiB on a 125 GiB machine (87 % of host RAM) and the CPU MoE home holds PINNED pages (weight
staging slots, huge-page arena) that neither reclaim nor zram can take back. The engine had already reported an
arena shortage in an earlier session and I dismissed the wording as self-contradictory (LESSONS 87).

Hours later the same class of failure nearly recurred for a different reason: I edited the queue script to drop
GLM arms, the edit call was REFUSED because two of its edits overlapped, and I did not re-read the file — so a
GLM dwell trace ran unattended anyway (it survived). A policy that lives in a shell loop is a note to self; a
policy that lives in the loader path is a guard. So `bench_engine_step.py`, `bench_live_trace.py` and
`bench_parent_prefill.py` all call `require_headroom()` here, keyed on the checkpoint they are about to open,
BEFORE any tensor is read.

The predicate is deliberately crude: available RAM must exceed the model's own routed-expert footprint plus a
reserve, with a bigger reserve when `-mcpa` is in play, because that mechanism exists to lock more pages. Expert
bytes come from the SHARD HEADERS, never `model.safetensors.index.json`, which on GLM is stale by the entire MTP
head (LESSONS 86).
"""
from __future__ import annotations

import glob
import json
import os
import re
import struct

_ELS = {"F32": 4, "F16": 2, "BF16": 2, "I64": 8, "I32": 4, "I8": 1, "U8": 1, "I16": 2, "BOOL": 1}
_EXPERT_RE = re.compile(r"\.mlp\.experts\.")
_CACHE: dict = {}


def meminfo_kb() -> dict:
    out = {}
    with open("/proc/meminfo") as fh:
        for line in fh:
            p = line.split(":")
            if len(p) == 2:
                out[p[0].strip()] = int(p[1].strip().split()[0])
    return out


def routed_expert_gib(model_dir: str) -> float:
    """GiB of routed-expert weights in this checkpoint, summed from safetensors headers (~1 s per 17 shards)."""
    key = os.path.realpath(model_dir)
    if key in _CACHE:
        return _CACHE[key]
    tot = 0
    shards = sorted(glob.glob(os.path.join(model_dir, "*.safetensors")))
    if not shards:
        raise SystemExit(f"{model_dir}: no .safetensors files - cannot size the memory footprint")
    for f in shards:
        with open(f, "rb") as fh:
            n = struct.unpack("<Q", fh.read(8))[0]
            hdr = json.loads(fh.read(n))
        for k, v in hdr.items():
            if k == "__metadata__" or not _EXPERT_RE.search(k):
                continue
            nb = 1
            for d in v.get("shape", []):
                nb *= int(d)
            tot += nb * _ELS.get(str(v.get("dtype")), 1)
    gib = tot / 2.0 ** 30
    _CACHE[key] = gib
    return gib


def require_headroom(model_dir: str, mcpa: bool = False, allow_tight: bool = False, quiet: bool = False) -> float:
    """Refuse to open a checkpoint that would leave the box without a memory reserve. Returns GiB of experts.

    Pass `allow_tight=True` only when a human is watching MemAvailable. The refusal is a SystemExit with the
    arithmetic in it, because "the guard said no" without numbers is how a guard gets ignored.
    """
    mi = meminfo_kb()
    tot_g = mi["MemTotal"] / 2.0 ** 20
    avail_g = mi["MemAvailable"] / 2.0 ** 20
    swap_g = mi.get("SwapTotal", 0) / 2.0 ** 20
    rgib = routed_expert_gib(model_dir)
    need = max(rgib + (12.0 if not mcpa else 24.0), 0.25 * tot_g)
    if not quiet:
        print(f"  mem guard: MemTotal {tot_g:.0f} GiB, MemAvailable {avail_g:.0f} GiB, swap {swap_g:.0f} GiB, "
              f"routed experts {rgib:.1f} GiB ({100 * rgib / tot_g:.0f} % of RAM) -> needs >= {need:.0f} GiB")
    if 0.8 * tot_g < rgib <= 1.05 * tot_g:
        print("  mem guard WARNING: this model's expert set alone is most of host RAM; run it ATTENDED.")
    if avail_g < need and not allow_tight:
        raise SystemExit(
            f"REFUSING to open {model_dir}: {avail_g:.0f} GiB available, {need:.0f} GiB wanted "
            f"({rgib:.0f} GiB of routed experts + staging{' + promotion arenas for -mcpa' if mcpa else ''}). "
            f"This is the configuration that hard-hung the machine on 2025-11 (LESSONS 87): the CPU MoE home "
            f"pins pages, so 'available' is not the resource that matters - the RESERVE is. Free memory, lower "
            f"-mcs, drop -mcpa, or pass --allow-tight when you are watching the box.")
    return rgib


if __name__ == "__main__":
    MD = "/home/treo/projects/vendor/tabbyAPI/models"
    print("selftest: the guard must allow Qwen arms and refuse GLM arms without --allow-tight")
    ok = []
    for tag, mdl, mcpa in (("q205 plain", "Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4", False),
                           ("q205 -mcpa", "Qwen3.8-Flash-Next-exl3-2.05bpw_h4_ng4", True),
                           ("q268 plain", "Qwen3.8-Flash-Next-exl3-2.68bpw_h6_ng8", False),
                           ("GLM plain", "GLM-5.3-Flash-exl3@3.05bpw", False),
                           ("GLM -mcpa", "GLM-5.3-Flash-exl3@3.05bpw", True)):
        try:
            g = require_headroom(os.path.join(MD, mdl), mcpa, False, quiet=True)
            ok.append((tag, "ALLOWED", g))
        except SystemExit:
            ok.append((tag, "REFUSED", routed_expert_gib(os.path.join(MD, mdl))))
    for tag, verdict, g in ok:
        print(f"   {tag:<12} {verdict:<8} {g:6.1f} GiB experts")
    v = {t: x for t, x, _ in ok}
    assert v["q205 plain"] == "ALLOWED" and v["GLM plain"] == "REFUSED" and v["GLM -mcpa"] == "REFUSED", v
    print("   (GLM refused on this box by design: 109 GiB of experts vs 126 GiB RAM. GLM runs are ATTENDED: "
          "pass --allow-tight explicitly.)")