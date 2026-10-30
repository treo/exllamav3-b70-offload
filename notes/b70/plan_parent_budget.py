#!/usr/bin/env python3
"""
plan_parent_budget.py - the 3090 is not an expert device with free hands.

§2's placement rule ("hottest experts on the fastest device") compared two peak read rates and ignored
the work the 3090 is already doing. This script splits that into the two bills that actually matter,
because they pull in opposite directions:

  CAPACITY  what must sit in the 3090's 24 GiB regardless of tokens: attention and MLP weights,
            embeddings, lm_head, the n-gram tables, KV, and the recurrent states of a hybrid model.
            Whatever is left is the expert slice, and it sets how many experts CAN have a 3090 home.
  TRAFFIC   what a token actually reads: resident weights per layer + KV/state. This is what competes
            with expert reads for bandwidth, and it is far smaller than the capacity number suggests -
            the n-gram/embedding tables are looked up, not streamed.

Then it evaluates the two placement policies against one objective:

    wall/layer = max(T_parent + picked_bytes(S_g)/rate_g,     <- 3090 work is SERIAL with the parent
                     picked_bytes(S_b)/rate_b,                <- B70 runs concurrently
                     picked_bytes(S_c)/rate_cpu)              <- CPU worker runs concurrently

  P_order - the plan today: frequency-sorted, hottest first into S_g, then S_b, then S_c.
  P_lpt   - "distribute the hot experts fairly, keep the sets disjoint": walk the hot list once and
            give each expert to the home whose resulting term is smallest (LPT greedy, the standard
            4/5-approximation for minimising the maximum load).

Rates are the measured ones, matched to the footprint each home presents (out_rates_footprint.txt);
the 3090 uses its peak 936 GB/s, which is the generous reading of a quantity nobody has measured under
load - that measurement is E18. T_parent for GLM is a placeholder because E10 has not run.
"""
import collections
import glob
import json
import math
import os
import random

MODELS = {
    "Qwen3.8@2.68": dict(dirname="Qwen3.8-Flash-Next-exl3-2.68bpw_h6_ng8", prof="2.68bpw",
                         E=512, eb=1.465, layers=48, topk=10, t0=250.0, rate_b=292.0, rate_g=936.0,
                         calib=True,      # CPU-home (S_c) cost measured on this host (out_cpu_worker_calib.txt)
                         union={1: 1.0, 2: 1.99, 4: 3.88, 8: 7.27, 16: 13.12, 32: 21.91}),
    "GLM@3.05": dict(dirname="GLM-5.3-Flash-exl3@3.05bpw", prof="3.05bpw",
                     E=288, eb=9.000, layers=42, topk=8, t0=None, rate_b=132.0, rate_g=936.0,
                     calib=True,      # measured as a CPU home too (out_glm_cpu_calib.txt) - see CPU_ASGN_US
                     union={1: 1.0, 2: 1.98, 4: 3.78, 8: 6.89, 16: 12.01, 32: 19.14}),
}
ROOT = "/home/treo/projects/vendor/tabbyAPI/models"
VRAM_GIB, CPU_RATE, GIB = 24.0, 47.4, 2**30
MIBS_PER_US = 1048.576 / 1000.0        # MiB served per us at 1 GB/s

# --- measured parent (3090) legs, out_parent_leg.txt ------------------------------------------------------
# Both numbers come from the box itself rather than the datasheet:
#   PARENT_STREAM_GBPS  860 - best-of-N fp16 read bandwidth. The 936 used until now is the SPEC figure and the
#                     card does not reach it (individual samples spanned 639-864, so only best-of-N is quotable).
#   PARENT_EXPERT_GBPS 190 - the rate the REAL fused kernel (ext.exl3_moe) sustains on the parent's own expert
#                     bytes at decode batch sizes: flat at 170-215 GB/s across b=1..16, i.e. that leg is
#                     kernel-bound, not bandwidth-bound. Charging it at a byte rate understated it 4-5x.
PARENT_STREAM_GBPS = 860.0
PARENT_EXPERT_GBPS = 190.0

# Non-expert parent floor per layer, us, measured (attention + streamed non-expert weights + linear-state
# traffic; excludes the expert leg, and excludes sampler/lm_head/graph overheads, so it is a FLOOR). Measured on
# Qwen3.8 shapes only; other profiles keep the t0 sweep and are labelled uncalibrated.
PARENT_FLOOR_US = {
    (1, 4096): 122.0, (2, 4096): 129.0, (4, 4096): 144.0, (8, 4096): 176.0, (16, 4096): 238.0,
    (1, 16384): 133.0, (2, 16384): 151.0, (4, 16384): 181.0, (8, 16384): 247.0, (16, 16384): 371.0,
}


def parent_floor_us(b, ctx):
    """Measured non-expert parent cost per layer: nearest measured (batch, context), never extrapolated. The
    floor grows with b*ctx (KV and recurrent state); past b=16 / ctx=16384 nothing says what it does."""
    bs = sorted({k[0] for k in PARENT_FLOOR_US}); cs = sorted({k[1] for k in PARENT_FLOOR_US})
    if b > bs[-1] or ctx > cs[-1]:
        raise ValueError(f"parent floor not measured for b={b}, ctx={ctx} (max b={bs[-1]}, ctx={cs[-1]})")
    bb = min(bs, key=lambda x: abs(x - b)); cc = min(cs, key=lambda x: abs(x - ctx))
    return PARENT_FLOOR_US[(bb, cc)], (bb, cc)

# --- measured CPU-home (S_c) cost (out_cpu_worker_calib.txt) -----------------------------------------
# The CPU home is NOT byte-bound on this host: making every touched expert L3-resident bought only 15 % over
# cold DRAM reads, and the implied byte rate does not rise when the data is warm. What the kernel actually
# costs is per (token, expert) assignment, which falls mildly with batch because one expert's weights serve more
# tokens. Microseconds per assignment, real checkpoint tensors, layer 5, topk=10, uniform-random routing, cold
# experts, by kernel thread count. Replaces the old term(bytes, CPU_RATE) leg, which assumed 47.4 GiB/s and a
# byte-bound regime that measurement says the worker never operates in.
CPU_ASGN_US = {
    # Qwen3.8@2.68 (1.465 MiB/expert, topk 10, K=3): compute-bound.
    "Qwen3.8@2.68": {
        4:  {1: 124.2, 2: 119.5, 4: 113.0, 8: 102.5, 16: 83.9},
        8:  {1:  65.6, 2:  62.3, 4:  58.6, 8:  52.4, 16: 43.1},
        16: {1:  39.2, 2:  35.1, 4:  32.0, 8:  28.4, 16: 23.0},
    },
    # GLM@3.05 (9 MiB/expert, topk 8, moe_intermediate 2048): much closer to bandwidth-bound - 4 -> 8 -> 16
    # threads buys only 1.8x (Qwen buys 3.2x), i.e. it hits the DRAM roof, and warm residency lifts the rate
    # 1.6x where Qwen's does not move at all.
    "GLM@3.05": {
        4:  {1: 370.3, 2: 362.1, 4: 330.7, 8: 288.3, 16: 238.6},
        8:  {1: 227.8, 2: 226.1, 4: 217.6, 8: 156.2, 16: 130.1},
        16: {1: 205.4, 2: 199.4, 4: 180.2, 8: 141.4, 16: 107.6},
    },
}
CPU_RATE_MEASURED = {"Qwen3.8@2.68": 37.9, "GLM@3.05": 43.1}   # best observed GiB/s, cold
CPU_THR = int(os.environ.get("CPU_THR", "16"))   # kernel threads the CPU worker is allowed


def cpu_asgn_us(prof, b, thr=CPU_THR):
    """Measured us/assignment at batch b, log-interpolated in b between the measured points, and between the
    nearest measured thread counts. Extrapolation beyond rows=16 is refused rather than invented: at large b the
    cost per assignment should flatten towards the arithmetic roofline, but that has not been measured here."""
    tbl_p = CPU_ASGN_US[prof]
    def interp(tbl, x):
        ks = sorted(tbl)
        if x <= ks[0]:
            return tbl[ks[0]]
        if x > ks[-1]:
            raise ValueError(f"batch {x} exceeds the measured range (max {ks[-1]}); extend the cpu-home sweep")
        lo = max(k for k in ks if k <= x); hi = min(k for k in ks if k >= x)
        if lo == hi:
            return tbl[lo]
        w = (math.log(x) - math.log(lo)) / (math.log(hi) - math.log(lo))
        return tbl[lo] + w * (tbl[hi] - tbl[lo])
    ts = sorted(tbl_p)
    if thr in tbl_p:
        return interp(tbl_p[thr], b)
    lo = max(t for t in ts if t <= thr) if min(ts) <= thr else ts[0]
    hi = min(t for t in ts if t >= thr) if max(ts) >= thr else ts[-1]
    if lo == hi:
        return interp(tbl_p[lo], b)
    w = (math.log(thr) - math.log(lo)) / (math.log(hi) - math.log(lo))
    return interp(tbl_p[lo], b) * (1 - w) + interp(tbl_p[hi], b) * w


def selftest():
    """The scale check that would have caught the 1000x bug in term(): assert known conversions.
    106 MiB at 292 GB/s must be ~380 us, not ~0.4 us. Cheap insurance on every run."""
    def term(mib, r):
        return mib * 1048576.0 / (r * 1000.0)
    for mib, r, want in ((106.0, 292.0, 380.0), (14.65, 292.0, 52.6), (51.0, 132.0, 405.3),
                         (1.0, 936.0, 1.12), (14.65, 936.0, 16.4)):
        got = term(mib, r)
        assert abs(got - want) / want < 0.03, f"scale check failed: {mib} MiB @{r} = {got:.2f} us, want {want}"
    print("scale selftest ok (MiB/GB/s -> us)")


def counts_for(sub, E):
    for f in glob.glob(os.path.expanduser("~/.cache/exllamav3/expert_stats/*.json")):
        d = json.load(open(f))
        if sub in str(d.get("model_dir", "")) and isinstance(d.get("layers"), dict):
            L = d["layers"]
            if len(L[sorted(L)[0]]) == E:
                return list(L[sorted(L)[0]])
    raise SystemExit(f"no profile for {sub}/{E}")


def census(dirname):
    """Shard-header census, grouped by what the decode path DOES with the bytes."""
    cat = collections.Counter()
    for p in glob.glob(os.path.join(ROOT, dirname, "*.safetensors")):
        with open(p, "rb") as f:
            n = int.from_bytes(f.read(8), "little")
            h = json.loads(f.read(n).decode())
        for name, v in h.items():
            if name == "__metadata__":
                continue
            b = v["data_offsets"][1] - v["data_offsets"][0]
            if "mlp.experts." in name:
                cat["routed"] += b
            elif any(s in name for s in ("ngram", "embed_tokens", "lm_head")):
                cat["lookup"] += b            # capacity only: a few rows read per token
            else:
                cat["read"] += b               # streamed every token
    return cat


def state_budget(cfg):
    tc = cfg.get("text_config", cfg)
    lt = tc.get("layer_types", [])
    lac = tc.get("linear_attn_config", {}) or {}      # GLM nests it, Qwen keeps it flat
    vh = tc.get("linear_num_value_heads") or lac.get("num_heads", 0)
    kd = tc.get("linear_key_head_dim") or lac.get("head_dim", 0)
    vd = tc.get("linear_value_head_dim") or lac.get("head_dim", 0)
    lin_layer_mib = vh * kd * vd * 4 / 2**20          # fp32 recurrent state, per sequence per layer
    kv_tok = 2 * tc.get("num_key_value_heads", 0) * tc.get("head_dim", 0) * 2
    mla_tok = 2 * (tc.get("kv_lora_rank", 0) + tc.get("qk_rope_head_dim", 0)) * 2
    n_lin, n_full = lt.count("linear_attention"), lt.count("full_attention")
    n_mla = sum(1 for x in lt if "sparse_attention" in x or "mla" in x)
    return dict(n_lin=n_lin, n_full=n_full, n_mla=n_mla,
                lin_mib=n_lin * lin_layer_mib, lin_layer_mib=lin_layer_mib,
                tok_kib=(n_full * kv_tok + n_mla * mla_tok) / 1024)


def policy(lpt, counts, E, eb, cap_g, cap_b, rate_g, rate_b, tparent, topk, scale=1.0, b=None, thr=CPU_THR,
           prof=None, rate_floor=37.9, parent_expert_rate=None):
    """Assign every expert to one home; scale = distinct-experts multiplier for the batch.

    `b` is the batch (rows). When it is given, the CPU home is booked with the measured per-assignment cost
    (out_cpu_worker_calib.txt) and the byte rate only acts as a floor; when it is None - profiles that have not been
    calibrated - the old bytes/CPU_RATE model is used and the output says so.

    `parent_expert_rate` overrides the rate charged for experts homed on the parent: pass PARENT_EXPERT_GBPS to
    charge the measured fused-kernel rate instead of a byte rate (out_parent_leg.txt)."""
    tot = sum(counts) or 1.0
    rg = parent_expert_rate or rate_g      # measured kernel rate for the parent's expert leg, when supplied

    def term(mib, r):
        # us to move `mib` MiB at `r` GB/s: bytes / (r * 1e9 B/s) * 1e6
        return mib * 1048576.0 / (r * 1000.0)

    def leg_c(us_bytes, asgn):
        if b is None:
            return us_bytes
        return max(asgn * cpu_asgn_us(prof, b, thr), us_bytes)

    bg = bb = bc = 0.0
    ac = 0.0
    cg = cb = 0.0
    ng = nb = nc = 0
    for i in sorted(range(E), key=lambda j: -counts[j]):
        frac = counts[i] / tot
        pick = frac * topk * eb * scale                # MiB read per step by this expert
        asgn = frac * topk * b if b else 0.0           # (token, expert) assignments landing on it per step
        if not lpt:
            tgt = 0 if cg + eb <= cap_g else (1 if cb + eb <= cap_b else 2)
        else:
            opts = []
            if cg + eb <= cap_g:
                opts.append((term(bg + pick, rg), 0))
            if cb + eb <= cap_b:
                opts.append((term(bb + pick, rate_b), 1))
            opts.append((leg_c(term(bc + pick, CPU_RATE), ac + asgn), 2))
            tgt = min(opts)[1]
        if tgt == 0:
            bg += pick; cg += eb; ng += 1
        elif tgt == 1:
            bb += pick; cb += eb; nb += 1
        else:
            bc += pick; ac += asgn; nc += 1
    ug, ub, uc = term(bg, rg), term(bb, rate_b), leg_c(term(bc, CPU_RATE), ac)
    return max(tparent + ug, ub, uc), (ug, ub, uc), (ng, nb, nc)


def main():
    selftest()
    print("plan_parent_budget.py - capacity vs traffic on the parent, and what that implies for placement")
    print("=" * 104)
    for name, m in MODELS.items():
        cfg = json.load(open(os.path.join(ROOT, m["dirname"], "config.json")))
        cat, st = census(m["dirname"]), state_budget(cfg)
        nl = cfg.get("text_config", cfg).get("num_hidden_layers") or m["layers"]
        rd_l = cat["read"] / nl / 2**20
        print(f"\n{name}:  checkpoint {sum(cat.values())/GIB:.2f} GiB, {nl} layers, "
              f"{m['E']} experts/layer, expert block {m['eb']:.3f} MiB, topk {m['topk']}")
        print("  CAPACITY (GiB)                     TRAFFIC AT DECODE")
        print(f"    routed experts    {cat['routed']/GIB:7.2f}                    "
              f"resident-read {rd_l:7.2f} MiB/layer/token = {rd_l*nl/1024:.2f} GiB/token")
        print(f"    streamed non-exp. {cat['read']/GIB:7.2f}   attn, shared/dense MLP, router, norms"
              f"  -> {rd_l*1048.576/PARENT_STREAM_GBPS:5.1f} us/layer of 3090 DRAM time at the measured"
              f" {PARENT_STREAM_GBPS:.0f} GB/s")
        print(f"    lookup tables     {cat['lookup']/GIB:7.2f}   embed, lm_head, n-gram: row-gathered from")
        print(f"                                                        host/disk (ngram_gather_cpu) - NOT VRAM,")
        print(f"                                                        not per-token traffic: excluded below")
        print(f"  attention: {st['n_lin']} linear / {st['n_full']} full / {st['n_mla']} MLA-sparse of {nl}"
              f" | state {st['lin_mib']:.0f} MiB/sequence | KV {st['tok_kib']:.0f} KiB/token")
        print(f"  {'ctx':>7s} {'rows':>5s} {'KV+state':>9s} {'3090 free for experts':>22s} {'slots/layer':>12s} {'of E':>6s}")
        for ctx in (4096, 16384, 65536):
            for b in (1, 8):
                kv = st["tok_kib"] * 1024 * ctx * b / GIB
                seq = st["lin_mib"] / 1024 * b
                free = VRAM_GIB - cat["read"] / GIB - kv - seq - 1.5
                slots = max(0.0, free * GIB / (m["eb"] * 2**20) / nl)
                print(f"  {ctx:7d} {b:5d} {kv+seq:8.2f}G {free:21.2f} GiB {slots:12.1f} {100*slots/m['E']:5.1f}%")
    print("\n" + "=" * 104)
    print("PLACEMENT: P_order (hottest->3090 first, the plan today) vs P_lpt (hot list, each expert to the")
    print("least-loaded home, sets still disjoint).  wall = max(T_parent + S_g/rate_g, S_b/rate_b, CPU leg)")
    print(f"  CPU home (S_c): measured per-assignment cost at {CPU_THR} threads, per profile"
          f" (out_cpu_worker_calib.txt, out_glm_cpu_calib.txt); any profile without a measured table falls back"
          f" to bytes/{CPU_RATE} GiB/s and says so")
    print(f"  {'model':13s} {'rows':>5s} {'ctx':>6s} {'T_par':>6s} {'S_g slots':>9s} {'P_order':>28s} {'P_lpt':>28s}  verdict")
    for name, m in MODELS.items():
        cnt = counts_for(m["prof"], m["E"])
        cap_b = 31.9 * 1024 / m["layers"]
        # Measured profiles get the parent floor from out_parent_leg.py (per batch and context) and the measured
        # fused-kernel rate for GPU-homed experts; unmeasured ones keep the old t0 sweep so the gap is visible.
        ctxs = (4096, 16384) if m.get("calib") else (None,)
        for ctx in ctxs:
            for b in (1, 4, 8, 16):
                if ctx:
                    tpar, used = parent_floor_us(b, ctx)
                else:
                    tpar, used = (m["t0"] or 250.0), None
                for slots_g in (5.0, 30.0, 120.0):
                    cg = slots_g * m["eb"]
                    bb_ = b if m.get("calib") else None      # per-assignment cost measured for this profile only
                    per = PARENT_EXPERT_GBPS if m.get("calib") else None
                    args = dict(b=bb_, prof=name, rate_floor=CPU_RATE_MEASURED.get(name, CPU_RATE),
                                parent_expert_rate=per)
                    wo, go, so = policy(False, cnt, m["E"], m["eb"], cg, cap_b, m["rate_g"], m["rate_b"], tpar, m["topk"], m["union"][b], **args)
                    wl, gl, sl = policy(True, cnt, m["E"], m["eb"], cg, cap_b, m["rate_g"], m["rate_b"], tpar, m["topk"], m["union"][b], **args)
                    f = lambda u, s: f"{u:6.0f} ({s[0]:3d}/{s[1]:3d}/{s[2]:3d})"
                    v = "lpt" if wl < wo - 1 else ("tie" if abs(wl - wo) <= 1 else "order")
                    cx = f"{ctx:6d}" if ctx else "     -"
                    print(f"  {name:13s} {b:5d} {cx} {tpar:6.0f} {slots_g:8.0f} {f(wo, so):>28s} {f(wl, sl):>28s}  {v}"
                          + (f"   [floor at measured b={used[0]},ctx={used[1]}]" if used and used != (b, ctx) else ""))
        print(f"  (cells are wall us/layer, then expert slots on 3090/B70/CPU. "
              f"{'parent floor = measured non-expert cost (out_parent_leg.txt); parent expert bytes charged at the' if m.get('calib') else 'T_par swept: this profile has no measured parent leg'}"
              f"{' measured fused-kernel rate (190 GB/s), not a byte rate' if m.get('calib') else ''}; "
              f"{'CPU home measured per-assignment' if m.get('calib') else 'CPU home = bytes/' + str(CPU_RATE) + ' GiB/s (UNCALIBRATED)'}"
              f"; streamed reads at {PARENT_STREAM_GBPS:.0f} GB/s measured)...")


if __name__ == "__main__":
    main()