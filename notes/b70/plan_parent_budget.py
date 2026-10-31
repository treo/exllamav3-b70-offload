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
import statistics

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
# CPU_RATE is the DATASHEET peak of this host (2 x DDR4-3200 x 8 B = 51.2 GB/s = 47.7 GiB/s), and it is used only
# by the legacy bytes/rate fallback below. Measured ceilings (notes/b70/probe_mem.c, out_host_mem.txt): 45.8 GB/s
# read = 42.6 GiB/s (89 % of datasheet) and 25.9 GB/s copy, with L3 at 523.8 GB/s - 11x DRAM. Two consequences.
# (1) As a ceiling CPU_RATE is 11 % optimistic; as a target for the expert kernel it is unreachable by ~25 %, since
# the best observed kernel rate is CPU_RATE_MEASURED below. (2) It must NOT be applied to prefill-shaped work at
# all: at ~98 rows/expert the CPU expert path is compute-bound (AVX2, no VNNI), and a 4096-token chunk's unique
# remote expert bytes would occupy only ~10 % of the chunk's time at the measured read ceiling, which is why
# -mcpa buys +30-50 % on prefill and ~nothing on decode (out_prefill_mcpa.txt). Use CPU_ASGN_US there.
HOST_DRAM_READ_GIBS, HOST_L3_READ_GIBS, HOST_DRAM_COPY_GIBS = 42.6, 484.7, 24.1   # measured, 15 threads
PINNED_LINK_GIBS = 13.4        # 14.4 GB/s, out_rates_footprint.txt: 3.2x BELOW host DRAM, so transfers are
                               # link-bound rather than host-memory-bound - the plan's transfer tier is safe
# Where the per-expert selection profiles come from. Defaults to the engine's own cache; B70_PROFILE_DIR points it
# at a live trace converted by notes/b70/analyze_live_trace.py --emit-profile, which is how the plan's routing
# assumptions get tested against measured ones rather than argued about (out_live_trace.txt).
PROF_DIR = os.path.expanduser(os.environ.get("B70_PROFILE_DIR", "~/.cache/exllamav3/expert_stats"))
# `legacy` keeps the hand-transcribed union multipliers; the default recomputes them from whichever profile
# PROF_DIR holds (B70_UNION=legacy restores the old numbers for comparison).
UNION_MODE = os.environ.get("B70_UNION", "from_profile")


def layer_profiles(sub, E):
    """Normalized per-expert pick shares, ONE VECTOR PER LAYER, from whichever profile PROF_DIR holds."""
    vecs = []
    for f in glob.glob(os.path.join(PROF_DIR, "*.json")):
        d = json.load(open(f))
        if sub in str(d.get("model_dir", "")) and isinstance(d.get("layers"), dict):
            L = d["layers"]
            if all(len(v) == E for v in L.values()):
                for v in L.values():
                    s = float(sum(v))
                    if s > 0:
                        vecs.append([x / s for x in v])
            if vecs:
                break
    if not vecs:
        raise SystemExit(f"no profile for {sub}/{E} in {PROF_DIR}")
    return vecs


def mixture_counts(sub, E):
    """Expected pick share per expert index, averaged over the profile's LAYERS (for placement, where one
    vector over experts is what the model consumes).

    The original `counts_for` returned layer 0's array and every consumer treated it as 'the' distribution. On a
    live trace that turned out to be badly unrepresentative - layer 0 of Qwen3.8@2.68 touched 289 of 512 experts
    in 1,920 picks with top-10 mass 0.177, while other layers are far more concentrated - so a single layer's
    shape biased every batch-scaling number downstream of it.

    IMPORTANT: the average is only valid for LINEAR consumers like this one. Distinct-expert counts are concave
    in the distribution, so averaging distributions first OVERSTATES them (measured: 22.8x vs 10.9x at b=32 on
    one profile). Anything computing a union must use `union_mult` over `layer_profiles`.
    """
    vecs = layer_profiles(sub, E)
    return [sum(v[i] for v in vecs) / len(vecs) for i in range(E)], len(vecs)


def hit_rate(vecs, n_res):
    """Share of picks served by the n_res hottest experts, averaged over layers - the way the engine actually
    places them (each layer keeps its OWN resident set).

    Computing it from a layer-mean distribution instead is systematically pessimistic, because a globally
    chosen top-N is a worse selector than N per-layer top-Ns: on Qwen3.8@2.68 the per-layer value is 99.8% at
    n_res=256 while the mixture-based one reads a few points lower, and the difference lands entirely on the
    CPU home's pick count (measured effect: 6.05 bpw throughput moved 344 -> 197 t/s at b=16 before this
    function existed). Live anchor: notes/b70/out_live_trace.txt residency-curve table.
    """
    return sum(sum(sorted(v, reverse=True)[:n_res]) for v in vecs) / len(vecs)


def union_mult(vecs, b, topk):
    """Expected distinct experts touched by b concurrent sequences, as a multiplier on topk, computed PER LAYER
    and averaged: expert e is missed with probability (1-p_e)^(b.topk) under independent draws, so
    E[distinct] = sum_e 1-(1-p_e)^(b.topk). The closed form deliberately matches what the plan's hard-coded
    multipliers were built from (popularity x independence); notes/b70/analyze_live_trace.py checked that
    assumption against a real trace - measured random-window unions and this formula agree to ~1.5% on the same
    layer, so whatever gap remains against the plan's numbers IS the profile, not the math."""
    n = b * topk
    return statistics.mean(sum(1.0 - (1.0 - pi) ** n for pi in v) / topk for v in vecs)
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


# Measured INSIDE the engine (notes/bench_engine_step.py -> out_engine_step.txt): the 3090's own DEVICE time per
# MoE layer at b=1, ctx 4096, with the routed experts served elsewhere, i.e. the work that stays on the parent no
# matter where the experts live. Profiled kernel buckets, `device_total - expert_bucket`, which is routing-
# independent so the harness's synthetic input distribution does not bias it.
#   2.05 bpw: 141.9 us/layer   (device 267.2, expert 125.3; hyper-connections alone are 81.8 of the 141.9)
#   2.68 bpw: 195.6 us/layer   (device 284.8, expert  89.2; hyper-connections 82.8)
# Neither of the two previously contested estimates was right: the bottom-up microbench floor said 122 for 2.68
# (it had no term for hyper-connections and over-priced attention 3x) and the window-calibrated figure said 259
# (it folds in stalls and per-token overheads the parent does not have to pay). See LESSONS 61 for why the two
# differed at all, and out_engine_step.txt section 3 for the reconciliation.
PARENT_ENGINE_US = {"2.05bpw": 141.9, "2.68bpw": 195.6,
                    # added 2025-11 by notes/b70/run_parent_ladder.sh (out_engine_step.txt 10). Every value is
                    # device-time minus the expert bucket at ctx 4096 / b=1 / -mct 15, and each was taken at the
                    # SMALLEST -mcs that loads for that recipe (448 for the four largest), so the -mcs differs
                    # between entries: that is a property of the shipping stack, not a free variable.
                    "4.05bpw": 190.8, "4.18bpw": 207.9, "5.05bpw": 207.3, "6.05bpw": 207.5,
                    # GLM is measured under a DIFFERENT arm than the ladder above (ctx 2048, -cs 4096, -mcs 258,
                    # plain -mct 15), because GLM will not fit the 4096/8192 configuration. Two consequences when
                    # reading GLM rows: the level is ctx-2048 (so ctx-scaling reuses the Qwen SHAPE, which is a
                    # real approximation, not a measurement), and the GLM step is 71% exposed STALL (wall 1392.2
                    # vs device 406.7 us/layer) that this device-derived level does not represent at all - any
                    # GLM verdict from parent_us() is therefore a device-term bound, not a wall-clock forecast.
                    "3.05bpw": 101.1}
PARENT_ENGINE_HEAD_US_PER_LAYER = 14.0    # Qwen3.5 control: generator 196.9 vs forward-only 182.6 us/layer


# What the shipping path (3090 + CPU expert split) ACTUALLY costs per layer today, measured end to end with the
# real generator on real text (notes/bench_live_trace.py -> out_engine_step.txt). "Converged" = second pass
# through the same placement-profile directory, i.e. after the dynamic placement has warmed; the first pass was
# 1.6-1.8x slower (2.68: 649.4 -> 357.1 us/layer), which is the plan's "churn unmeasured" row finally measured.
# The split size is whatever fits in 24 GiB, NOT a tuned choice: 256 of 512 for 2.05, 384 for 2.68, 448 for the
# heavier quants (those three are badly VRAM-starved and their numbers should not be read as a CPU-path optimum).
PARENT_TODAY_US = {
    "2.05bpw": dict(us_layer=290.2, tps=71.8, mcs=256, thr=15),
    "2.68bpw": dict(us_layer=357.1, tps=58.3, mcs=384, thr=15),
    "4.05bpw": dict(us_layer=820.9, tps=25.4, mcs=448, thr=16),   # single pass only, not converged
    "5.05bpw": dict(us_layer=962.1, tps=21.7, mcs=448, thr=16),   # single pass only, not converged
    "6.05bpw": dict(us_layer=1109.6, tps=18.8, mcs=448, thr=16),  # single pass only, not converged
}


def parent_engine_us(prof, b, ctx, calibrated_at_b1, calibrated_here):
    """Engine-mode parent term: LEVEL measured at b=1/ctx 4096, SHAPE from the calibrated model.

    Only b=1 at ctx 4096 is measured, so the batch and context dependence cannot come from data. Rather than
    invent one, this rescales the calibrated model's own growth curve so that it passes through the measurement:
        parent(b, ctx) = measured_1x4k * calibrated(b, ctx) / calibrated(1, 4k)
    The shape is defensible (per-token work is ~linear in b; attention is ~linear in b*ctx; hyper-connections are
    per-token) while the LEVEL, which is where the two earlier estimates disagreed, is measured. Callers must
    print that this is an anchored extrapolation, not a measurement, for every cell except b=1/ctx=4096.
    """
    if prof not in PARENT_ENGINE_US:
        raise KeyError(f"no engine-measured parent term for {prof}; "
                       f"measured: {sorted(PARENT_ENGINE_US)}")
    scale = calibrated_here / calibrated_at_b1 if calibrated_at_b1 else 1.0
    return PARENT_ENGINE_US[prof] * scale, scale


def parent_us(prof, b, ctx):
    """Parent non-expert us/layer, best available: LEVEL engine-measured at b=1/ctx 4096 (PARENT_ENGINE_US),
    SHAPE from the microbench floor table (which has real b and ctx cells). Returns (us, provenance).

    Why split level from shape: the engine measurement is the only figure that includes what the bottom-up floor
    omitted (hyper-connections ~83 us/layer, exl3_mgemm density), but it exists at exactly one (b, ctx). The floor
    table has the grid but is 0.62x on level. Anchoring one to the other is honest if it is labelled, which the
    provenance string does. A profile with no engine measurement keeps the floor alone and says so.
    """
    floor_here, used = parent_floor_us(b, ctx)
    if prof not in PARENT_ENGINE_US:
        return floor_here, f"microbench floor (no engine measurement for {prof})"
    anchor = PARENT_ENGINE_US[prof] * floor_here / PARENT_FLOOR_US[(1, 4096)]
    tag = "engine-measured level x measured shape"
    if used != (b, ctx):
        tag += f" (floor shape taken at b={used[0]},ctx={used[1]})"
    if (b, ctx) != (1, 4096):
        tag += " [anchored, not measured]"
    return anchor, tag


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
    """Representative per-expert pick shares. Delegates to mixture_counts: it used to return layer 0's array, and
    a live trace showed layer 0 is not representative (see mixture_counts)."""
    return mixture_counts(sub, E)[0]


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
        cnt, nlay = mixture_counts(m["prof"], m["E"])
        vecs = layer_profiles(m["prof"], m["E"])
        cap_b = 31.9 * 1024 / m["layers"]
        uni = m["union"]
        if UNION_MODE != "legacy":
            uni = {b: union_mult(vecs, b, m["topk"]) for b in (1, 2, 4, 8, 16, 32)}
            print(f"  {name}: union multiplier on topk - inherited {m['union'][8]:.2f}x at b=8 / "
                  f"{m['union'][16]:.2f}x at b=16 / {m['union'][32]:.2f}x at b=32  vs  recomputed per layer "
                  f"from {PROF_DIR} ({nlay} layers): {uni[8]:.2f}x / {uni[16]:.2f}x / {uni[32]:.2f}x "
                  f"[{UNION_MODE}]")
        # Measured profiles get the parent floor from out_parent_leg.py (per batch and context) and the measured
        # fused-kernel rate for GPU-homed experts; unmeasured ones keep the old t0 sweep so the gap is visible.
        ctxs = (4096, 16384) if m.get("calib") else (None,)
        for ctx in ctxs:
            for b in (1, 4, 8, 16):
                if ctx:
                    tpar, used = parent_us(m["prof"], b, ctx)
                else:
                    tpar, used = (m["t0"] or 250.0), None
                for slots_g in (5.0, 30.0, 120.0):
                    cg = slots_g * m["eb"]
                    bb_ = b if m.get("calib") else None      # per-assignment cost measured for this profile only
                    per = PARENT_EXPERT_GBPS if m.get("calib") else None
                    args = dict(b=bb_, prof=name, rate_floor=CPU_RATE_MEASURED.get(name, CPU_RATE),
                                parent_expert_rate=per)
                    wo, go, so = policy(False, cnt, m["E"], m["eb"], cg, cap_b, m["rate_g"], m["rate_b"], tpar, m["topk"], uni[b], **args)
                    wl, gl, sl = policy(True, cnt, m["E"], m["eb"], cg, cap_b, m["rate_g"], m["rate_b"], tpar, m["topk"], uni[b], **args)
                    f = lambda u, s: f"{u:6.0f} ({s[0]:3d}/{s[1]:3d}/{s[2]:3d})"
                    v = "lpt" if wl < wo - 1 else ("tie" if abs(wl - wo) <= 1 else "order")
                    cx = f"{ctx:6d}" if ctx else "     -"
                    print(f"  {name:13s} {b:5d} {cx} {tpar:6.0f} {slots_g:8.0f} {f(wo, so):>28s} {f(wl, sl):>28s}  {v}"
                          + (f"   [{used}]" if isinstance(used, str) else
                             (f"   [floor at measured b={used[0]},ctx={used[1]}]" if used and used != (b, ctx) else "")))
        print(f"  (cells are wall us/layer, then expert slots on 3090/B70/CPU. "
              f"{'parent floor = measured non-expert cost (out_parent_leg.txt); parent expert bytes charged at the' if m.get('calib') else 'T_par swept: this profile has no measured parent leg'}"
              f"{' measured fused-kernel rate (190 GB/s), not a byte rate' if m.get('calib') else ''}; "
              f"{'CPU home measured per-assignment' if m.get('calib') else 'CPU home = bytes/' + str(CPU_RATE) + ' GiB/s (UNCALIBRATED)'}"
              f"; streamed reads at {PARENT_STREAM_GBPS:.0f} GB/s measured)...")


if __name__ == "__main__":
    main()