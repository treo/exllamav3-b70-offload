#!/usr/bin/env python3
"""
plan_concurrency.py - aggregate throughput vs rows, and what that says about prefill.

The decode figures elsewhere in these notes are per-layer at b=1. Throughput at concurrency `rows` is
set by three worker terms per layer that scale differently:

  T_parent(rows) = fixed + (streamed_non_expert + rows * (state_rw + kv_per_layer)) / 936
      fixed absorbs launch/latency overhead that does NOT scale (calibrated so T_parent(1) matches the
      measured 250 us/layer for Qwen3.8; GLM has no measurement, so its rows-axis is printed for a range
      and flagged). Weight reads are batch-independent; the recurrent state is per SEQUENCE (3 MiB/layer
      read + written on Qwen3.8) and KV grows with rows x ctx, so the parent does have a rows slope - it
      is just much smaller than the expert term.
  T_b70(rows)    = h * |union(rows)| * per_expert_layer_us(rows)   [measured, plan_decode_cost.py]
      REPLACES the old bytes/rate formula. Every kernel through rev H was instruction/routing-bound
      (b70-kernels 2b/2c), so bytes over a bandwidth curve was the wrong model for THOSE kernels; the
      measured per-expert cost is per weight and per row count. Dispatch has since collapsed to one family
      (rev J, transposed tiles) for K = 2..16, with dp4a kept only for layouts that cannot be permuted at
      K > 5 - see doc/port/b70-decode-closeout.md. Rev J itself runs at ~90 % of the measured stream slope,
      so for the selected kernel bytes do bind again.
      distinct experts is the union over rows, i.e. this ALREADY assumes perfect intra-step weight
      reuse: an expert read once per layer per step, however many rows picked it (the bucketed GEMM the
      CPU path uses). That is the right model, and it is why B70 work saturates instead of growing
      without bound: the union can never exceed E.
  T_cpu(rows)    = distinct_experts(rows) * (1 - h) * expert_bytes / 47.4

aggregate tok/s = rows / (MoE layers x max(three terms)).

Then the question the prefill design rests on: when does the B70 become compute-bound rather than
byte-bound, i.e. when do the XMX routes earn their keep? Arithmetic intensity of an expert GEMM is
(rows_per_expert x params_per_weight_byte) MAC/byte, so the crossover is

    rows/expert  >=  XMX_MAC_per_byte = (367e12 / 2) / 674e9  = 272

which is a statement about the whole plan, not a detail: it says a chunk needs ~272 rows HITTING THE
SAME EXPERT before FP/int8 matrix throughput binds. Print where real workloads land.
"""
import glob
import importlib.util
import json
import os

_spec = importlib.util.spec_from_file_location("ppb", os.path.join(os.path.dirname(__file__),
                                                                   "plan_parent_budget.py"))
ppb = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(ppb)
_spec2 = importlib.util.spec_from_file_location("pq", os.path.join(os.path.dirname(__file__),
                                                                   "plan_quant_scaling.py"))
pq = importlib.util.module_from_spec(_spec2)
_spec2.loader.exec_module(pq)
_spec3 = importlib.util.spec_from_file_location("pdc", os.path.join(os.path.dirname(__file__),
                                                      "plan_decode_cost.py"))
pdc = importlib.util.module_from_spec(_spec3)
_spec3.loader.exec_module(pdc)

CTX = 4096
CALIB = {"Qwen3.8": 250.0}          # measured T_layer at b=1, us (doc/prep); GLM unmeasured
# Two defensible parent models exist now, and they differ ~2x (see out_parent_leg.txt, LESSONS 61):
#   calibrated - the inherited route: subtract the streamed bytes from the observed ~250 us/layer window and
#                call the remainder "fixed overhead". Contains the sampler, lm_head, graphs, everything the
#                window contains; reproduces the window by construction, so it cannot corroborate it.
#   floor      - the measured route: use the composed floor from the 3090 benches (attention + streamed
#                weights + state traffic). Excludes those overheads, so it is a LOWER bound on parent time and
#                the t/s it prints is an upper bound on what the box can do.
# Switch with B70_PARENT_MODEL=calibrated|floor|engine. `engine` (the default) uses the measured level for the
# profiles bench_engine_step.py covers and falls back to `calibrated` elsewhere, marking those rows '=' in the
# binds column; `floor` is only measured to b=16 and marks rows beyond it '~'.
PARENT_MODEL = os.environ.get("B70_PARENT_MODEL", "engine")


def union_at(cnt, E, topk, rows, rng_seed=5, trials=400):
    """Mean distinct experts touched by `rows` tokens, each drawing topk WITHOUT replacement from the
    empirical routing distribution. Vectorised with numpy: the pure-python version was 10^9 inner steps
    at rows=256 and did not finish."""
    import numpy as np
    rng = np.random.default_rng(rng_seed)
    p = np.asarray(cnt, dtype=float)
    p = p / p.sum()
    idx = np.arange(E)
    out = 0
    for _ in range(trials):
        seen = np.zeros(E, dtype=bool)
        for _b in range(rows):
            seen[rng.choice(idx, size=topk, replace=False, p=p)] = True
        out += int(seen.sum())
    return out / trials


def main():
    ppb.selftest()
    # UNITS, corrected per kernels.md 4: 272 is MACs per BYTE at 1 byte/weight. Trellis is 0.375 B/weight and
    # the integer-DPAS route spends 4 MACs per weight-token (kernels.md 2c item 13b), so the eligibility bar in
    # ROWS per expert is (0.375 x 183.5e12) / (4 x rate) = ~26 rows at the 674 GB/s copy peak, ~59 rows at the
    # 292 GB/s this GEMV family actually achieves. Quoting 272 rows for trellis shapes is the same mistake as
    # quoting GB/s across quantizations with different bytes per weight.
    print("XMX crossover: 367e12/2 MAC/s over 674e9 B/s = 272 MAC per byte; for trellis (0.375 B/weight, "
          "4 MACs per weight-token) that is ~26 rows/expert at the copy peak, ~59 at the achieved GEMV rate\n")
    for lab, dirname, prof, bandk in pq.QUANTS:
        cat = ppb.census(dirname)
        cfg = json.load(open(os.path.join(ppb.ROOT, dirname, "config.json")))
        tc = cfg.get("text_config", cfg)
        nl, E = tc["num_hidden_layers"], tc.get("n_routed_experts") or tc.get("num_experts")
        topk = tc.get("num_experts_per_tok") or tc.get("topk")
        eb = cat["routed"] / nl / E / 2**20
        st = ppb.state_budget(cfg)
        cnt = ppb.counts_for(prof, E)          # per-layer profile, layer-mean vector (supersedes
                                               # pq.counts_for, which returned layer 0 and ignored
                                               # B70_PROFILE_DIR)
        vecs = ppb.layer_profiles(prof, E)
        if cnt is None:
            continue
        tot = sum(cnt) or 1.0
        order = sorted(cnt, reverse=True)
        sg = max(0.0, 24.0 - cat["read"] / 2**30 - st["tok_kib"] * 1024 * CTX / 2**30
                 - st["lin_mib"] / 1024 - 1.5)
        cap_b = 31.9 * 2**30 / nl
        n_res = min(E, int(sg * 2**30 / (eb * 2**20) / nl) + int(cap_b / (eb * 2**20)))
        h = ppb.hit_rate(vecs, n_res)          # per-layer: each layer keeps its own resident set
        _h_mix = sum(order[:n_res]) / tot       # mixture-based value, kept only for the print below
        rd_l = cat["read"] / nl / 2**20                      # MiB/layer, batch-independent
        state_l = st["lin_mib"] / nl * 2                     # MiB/layer/sequence, read + write
        # st["tok_kib"] is ALREADY summed over the full/MLA layers, so per-layer is /nl - dividing by
        # 1024 only (an earlier draft used it per layer and inflated the parent's KV term nl-fold).
        kv_l = st["tok_kib"] / nl / 1024 * CTX               # MiB/layer/sequence at this ctx
        calib = CALIB.get("Qwen3.8")
        us = lambda mib, r: mib * 1048576.0 / (r * 1000.0)
        fixed = calib - us(rd_l + state_l + kv_l, 936.0) if calib else 0.0
        assert fixed > 0, f"calibration went negative: parent bill alone exceeds {calib} us"
        # Cross-check this composed parent model against the DIRECT measurement on the 3090
        # (notes/bench_parent_leg.py -> out_parent_leg.txt): the floor there is non-expert only, so the
        # comparison is fixed + streamed weights, not tp(b) with KV/state included.
        floor_meas = ppb.PARENT_FLOOR_US[(1, 4096)]
        floor_model = fixed + us(rd_l + 1 * (state_l + kv_l), ppb.PARENT_STREAM_GBPS)
        if PARENT_MODEL == "engine":
            td = ppb.PARENT_TODAY_US.get(lab + "bpw")
            print(f"   PARENT MODEL = engine: level measured inside the engine at b=1/ctx 4096 "
                  f"({ppb.PARENT_ENGINE_US.get(lab + 'bpw', 'n/a')} us/layer of parent device work, "
                  f"out_engine_step.txt); scaled by the calibrated curve's shape elsewhere (^). "
                  f"Today's shipping path (3090 + CPU split, real text, converged) measured "
                  f"{td['us_layer']:.1f} us/layer = {td['tps']:.1f} tok/s with -mcs {td['mcs']}"
                  if td else f"   PARENT MODEL = engine: no measurement for {lab}; using the calibrated model (=)")
        print(f"parent model cross-check at b=1/ctx=4096: this planner's non-expert figure {floor_model:.0f} us vs "
              f"the measured floor {floor_meas:.0f} us (out_parent_leg.txt) -> {floor_model / floor_meas:.2f}x. "
              f"The gap is NOT a contradiction: the measured number is a FLOOR (attention + streamed weights + "
              f"state traffic only), while `fixed` here was calibrated so the parent bill reproduces the "
              f"inherited ~250 us window, so the difference is the overhead that window absorbs - sampler, "
              f"lm_head, CUDA-graph and the rest of the network - which this bench does not model. Use the floor "
              f"for 'what could offloading save' and the calibrated figure for 'what the box actually costs'. "
              f"Streamed reads charged at {ppb.PARENT_STREAM_GBPS:.0f} GB/s (measured), not the 936 spec figure.")
        print(f"Qwen3.8 {lab} bpw: eb {eb:.3f} MiB, h {h*100:.1f} %, parent bill "
              f"(h {h*100:.1f}% per-layer; a mixture-based estimate would read {_h_mix*100:.1f}%, and that deficit "  # noqa: E501
              f"is the pessimism this avoids) "
              f"{rd_l:.0f} MiB/layer weights + {state_l:.1f} state + {kv_l:.1f} KV per sequence-layer; "
              f"fixed overhead {fixed:.0f} us"
              + ("   PARENT MODEL = measured floor: ms/step and tok/s are UPPER BOUNDS; rows above the "
                 "measured b<=16 range fall back to the calibrated model and are marked ~"
                 if PARENT_MODEL == "floor" else ""))
        print(f"  {'rows':>5s} {'union':>7s} {'parent':>8s} {'B70':>8s} {'CPU':>8s} {'binds':>7s} "
              f"{'ms/step':>8s} {'tok/s':>7s} {'vs b=1':>7s} {'rows/exp':>9s}")
        # E25a/D8: price gate+up as one launch where that is cheaper, using the SAME shared rule and geometry
        # as plan_operating_point (plan_decode_cost.GATE_TILES_N) so the two planners cannot drift apart.
        tiles_n = pdc.GATE_TILES_N.get("Qwen3.8")
        fused_rows = []
        base = None
        band = pq.BANDS[bandk]
        for rows in (1, 2, 4, 8, 16, 32, 64, 128, 256):
            # Distinct experts touched by `rows` concurrent sequences, computed PER LAYER and averaged.
            # The old call fed union_at a single distribution (layer 0 of the profile, then the layer mean
            # after counts_for changed), and either way mixing layers first OVERSTATES the union because
            # distinct-count is concave in the distribution - measured 22.8x vs 10.9x at b=32 on one
            # profile (out_live_trace.txt). ppb.union_mult applies the closed form per layer.
            u = ppb.union_mult(vecs, rows, topk) * topk
            dev_mib = u * h * eb
            rate = pq.interp(band, dev_mib, 1)      # diagnostic only now: footprint, not a rate driver
            if PARENT_MODEL == "engine":
                # level from the engine measurement, shape from the calibrated curve (only b=1/ctx 4096 measured)
                cal_b1 = fixed + us(rd_l + 1 * (state_l + kv_l), ppb.PARENT_STREAM_GBPS)
                cal_here = fixed + us(rd_l + rows * (state_l + kv_l), ppb.PARENT_STREAM_GBPS)
                try:
                    tp, _sc = ppb.parent_engine_us(lab + "bpw", rows, CTX, cal_b1, cal_here)
                    pmark = "" if (rows == 1 and CTX == 4096) else "^"
                except KeyError:
                    tp = cal_here
                    pmark = "="          # no engine measurement for this profile: calibrated model, labelled
            elif PARENT_MODEL == "floor" and rows <= 16:
                tp, pmark = ppb.parent_floor_us(rows, CTX)[0], ""
            elif PARENT_MODEL == "floor":
                # above the measured b range the floor has no cell, so this row falls back to the calibrated
                # model and says so - the mark must NOT appear in calibrated mode, where every row would carry
                # it meaninglessly (it used to, which read as "these rows are suspect" rather than "this row is")
                tp, pmark = fixed + us(rd_l + rows * (state_l + kv_l), ppb.PARENT_STREAM_GBPS), "~"
            else:
                tp, pmark = fixed + us(rd_l + rows * (state_l + kv_l), ppb.PARENT_STREAM_GBPS), ""
            # Measured decode cost, priced PER EXPERT at the row count that expert actually sees. One step's
            # `rows` tokens make rows*topk selections spread over union(rows) touched experts, so the average
            # per-expert row count is rows*topk/union - the "rows/exp" column below - NOT the global row count.
            # An earlier revision charged every touched expert the global count (clamped to the 16-row
            # measurement limit), which inflates the device term whenever topk > 1: at b=8 with topk=8 it
            # priced ~1 row as if it were 16. cost() is measured at 1/2/4/8/16 and, above 16, buckets
            # additively (out_rows_gt16.txt), so we round the per-expert count UP to the next measured point
            # rather than interpolating a curve that is flat below ~9 rows and stepped above.
            rpe = rows * topk / max(u, 1.0)
            rr = next((m for m in pdc.MEASURED_ROWS if m >= rpe), rpe)
            tb, kern = pdc.layer_us(u * h, rr, pdc.scale_from_eb(eb, float(lab)))
            if tiles_n and rr in (1, 2, 4, 8, 16):
                try:
                    tf_, jshape, jks, _jn = pdc.layer_us_joint(u * h, rr, tiles_n, eb / 3.0,
                                                               pdc.scale_from_eb(eb, float(lab)))
                except ValueError:
                    tf_ = None      # joint tables cover rows 1/8/16 only; fall back, do not extrapolate
                if tf_ is not None and tf_ < tb:
                    tb, kern = tf_, f"joint-{jshape}-KS{jks}"
                    fused_rows.append(rows)
            tc_ = us(u * (1 - h) * eb, ppb.CPU_RATE)
            wall = max(tp, tb, tc_)
            binds = "parent" + pmark if wall == tp else (f"B70:{kern[0].upper()}" if wall == tb else "CPU")
            step = wall * nl / 1000.0
            tput = rows / (step / 1000.0)
            if rows == 1:
                base = tput
            print(f"  {rows:5d} {u:7.1f} {tp:8.0f} {tb:8.0f} {tc_:8.0f} {binds:>7s} "
                  f"{step:8.2f} {tput:7.0f} {tput/base:6.1f}x {u and rows*topk/max(u,1):9.1f}")
        print("  B70 pricing: E25a fused gate+up (KS=1) applied at rows " +
              (", ".join(str(r) for r in fused_rows) if fused_rows else "(none)") +
              f"; elsewhere three separate projections. tiles_n={tiles_n} from plan_decode_cost.GATE_TILES_N"
              " (absent for a model means fusion was not evaluated there).")
        print()
    print("""Prefill: a chunk of R tokens touches many experts per layer, so the B70's byte cost per LAYER is
bounded by (experts touched) x expert_bytes while its MAC cost grows with R*topk. The averages are misleading
and the peaks are not: at R=2048 the mean is 40 rows/expert but under LIVE routing the experts at or above the
~26-row XMX bar are a ~24% minority carrying ~94% of the picks; at the stricter 59-row bar it is 15.8% of
experts carrying 85.6% of picks. The STORED profile tells the opposite story at that bar - 0.4% of experts,
0.6% of picks, because it is near-uniform so every expert looks identically marginal at ~40 rows - i.e. the
input distribution, not the arithmetic, was deciding whether to build the matrix path at all
(out_live_trace.txt). So the XMX
routes DO bind for most of the work at every chunk size worth running, and the correct design is two-speed
prefill - matrix tiles for experts above the bar, streaming GEMV below - with tile height <= rows/expert
(kernels.md 2c item 2). The remaining question is traffic, not arithmetic: 16-row bucketing re-reads each
touched expert ceil(rows/16) times, measured 2.24x / 7.01x / 26.29x at R = 512 / 2048 / 8192, which
probe_slm shows is a scheduling property rather than a hardware limit (out_prefill_gemm.txt).
Marked per-quant below; the numbers assume the profile in effect (B70_PROFILE_DIR).""")


    print("""Prefill and the XMX routes: rows/expert averaged over the union is the wrong statistic,
because routing is peaked - the hot experts are exactly the ones a chunk concentrates. The table below
takes each expert's real pick frequency and asks how many rows of a chunk of R tokens land on it, then
counts how many experts cross the 272 rows/expert crossover where FP/int8 matrix throughput starts to
bind. Two-speed prefill (XMX for the experts above the line, streaming GEMV for those below) is what the
numbers support; a single chunk-wide GEMM is not.
""")
    for lab, dirname, prof, bandk in pq.QUANTS:
        cfg = json.load(open(os.path.join(ppb.ROOT, dirname, "config.json")))
        tc = cfg.get("text_config", cfg)
        E = tc.get("n_routed_experts") or tc.get("num_experts")
        topk = tc.get("num_experts_per_tok") or tc.get("topk")
        cnt = ppb.counts_for(prof, E)          # per-layer profile, layer-mean vector (supersedes
                                               # pq.counts_for, which returned layer 0 and ignored
                                               # B70_PROFILE_DIR)
        vecs = ppb.layer_profiles(prof, E)
        if cnt is None:
            continue
        tot = sum(cnt) or 1.0
        freq = sorted((c / tot for c in cnt), reverse=True)
        # PER LAYER, then averaged. Qualification is an ORDER statistic on each layer's own distribution, and
        # `cnt` is the layer-mean mixture - which flattens the hot tail exactly enough to invert the conclusion
        # (mixture: max 105 rows/expert and 83/512 past the 59-row bar carrying 29% of picks; per layer: max
        # ~1,029 rows and 15.8% of experts carrying 85.6%). LESSONS 63, second victim.
        stats = {R: [0.0, 0.0, 0.0, 0.0, 0.0] for R in (512, 2048, 8192)}
        for v in vecs:
            f = sorted(v, reverse=True)
            for R in (512, 2048, 8192):
                rows_e = [R * topk * x for x in f]
                tr = sum(rows_e) or 1.0
                st = stats[R]
                st[0] += rows_e[0] / len(vecs)        # mean over layers of THAT layer's hottest expert
                st[1] += sum(1 for x in rows_e if x >= 26) / len(vecs)
                st[2] += sum(x for x in rows_e if x >= 26) / tr / len(vecs)
                st[3] += sum(1 for x in rows_e if x >= 59) / len(vecs)
                st[4] += sum(x for x in rows_e if x >= 59) / tr / len(vecs)
        print(f"  {lab} bpw (topk {topk}, E {E}):", end="")
        for R in (512, 2048, 8192):
            mx, n26, s26, n59, s59 = stats[R]
            print(f"   R={R}: hot expert {mx:6.0f} rows/expert, {n26:5.1f} of E >=26 carrying {s26*100:3.0f}% "
                  f"| {n59:5.1f} >=59 carrying {s59*100:3.0f}%", end="  |")
        print()


if __name__ == "__main__":
    main()