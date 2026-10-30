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
    print("XMX crossover: 367e12/2 MAC/s over 674e9 B/s =", round(367e12 / 2 / 674e9),
          "MAC per byte -> a GEMM becomes compute-bound at ~272 rows hitting the SAME expert\n")
    for lab, dirname, prof, bandk in pq.QUANTS:
        cat = ppb.census(dirname)
        cfg = json.load(open(os.path.join(ppb.ROOT, dirname, "config.json")))
        tc = cfg.get("text_config", cfg)
        nl, E = tc["num_hidden_layers"], tc.get("n_routed_experts") or tc.get("num_experts")
        topk = tc.get("num_experts_per_tok") or tc.get("topk")
        eb = cat["routed"] / nl / E / 2**20
        st = ppb.state_budget(cfg)
        cnt = pq.counts_for(prof, E)
        if cnt is None:
            continue
        tot = sum(cnt) or 1.0
        order = sorted(cnt, reverse=True)
        sg = max(0.0, 24.0 - cat["read"] / 2**30 - st["tok_kib"] * 1024 * CTX / 2**30
                 - st["lin_mib"] / 1024 - 1.5)
        cap_b = 31.9 * 2**30 / nl
        n_res = min(E, int(sg * 2**30 / (eb * 2**20) / nl) + int(cap_b / (eb * 2**20)))
        h = sum(order[:n_res]) / tot
        rd_l = cat["read"] / nl / 2**20                      # MiB/layer, batch-independent
        state_l = st["lin_mib"] / nl * 2                     # MiB/layer/sequence, read + write
        # st["tok_kib"] is ALREADY summed over the full/MLA layers, so per-layer is /nl - dividing by
        # 1024 only (an earlier draft used it per layer and inflated the parent's KV term nl-fold).
        kv_l = st["tok_kib"] / nl / 1024 * CTX               # MiB/layer/sequence at this ctx
        calib = CALIB.get("Qwen3.8")
        us = lambda mib, r: mib * 1048576.0 / (r * 1000.0)
        fixed = calib - us(rd_l + state_l + kv_l, 936.0) if calib else 0.0
        assert fixed > 0, f"calibration went negative: parent bill alone exceeds {calib} us"
        print(f"Qwen3.8 {lab} bpw: eb {eb:.3f} MiB, h {h*100:.1f} %, parent bill "
              f"{rd_l:.0f} MiB/layer weights + {state_l:.1f} state + {kv_l:.1f} KV per sequence-layer; "
              f"fixed overhead {fixed:.0f} us")
        print(f"  {'rows':>5s} {'union':>7s} {'parent':>8s} {'B70':>8s} {'CPU':>8s} {'binds':>7s} "
              f"{'ms/step':>8s} {'tok/s':>7s} {'vs b=1':>7s} {'rows/exp':>9s}")
        # E25a/D8: price gate+up as one launch where that is cheaper, using the SAME shared rule and geometry
        # as plan_operating_point (plan_decode_cost.GATE_TILES_N) so the two planners cannot drift apart.
        tiles_n = pdc.GATE_TILES_N.get("Qwen3.8")
        fused_rows = []
        base = None
        band = pq.BANDS[bandk]
        for rows in (1, 2, 4, 8, 16, 32, 64, 128, 256):
            u = union_at(cnt, E, topk, rows)
            dev_mib = u * h * eb
            rate = pq.interp(band, dev_mib, 1)      # diagnostic only now: footprint, not a rate driver
            tp = fixed + us(rd_l + rows * (state_l + kv_l), 936.0)
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
            if tiles_n and rr in (1, 2, 4, 8, 16) and pdc.should_fuse(tiles_n, 1, max(1, int(round(u * h)))):
                tf_ = pdc.layer_us_fused(u * h, rr, pdc.scale_from_eb(eb, float(lab)))
                if tf_ < tb:
                    tb, kern = tf_, "E25a-fused"
                    fused_rows.append(rows)
            tc_ = us(u * (1 - h) * eb, ppb.CPU_RATE)
            wall = max(tp, tb, tc_)
            binds = "parent" if wall == tp else (f"B70:{kern[0].upper()}" if wall == tb else "CPU")
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
    print("""Prefill: a chunk of R tokens touches (almost) all E experts per layer, so the B70's byte
cost per LAYER is capped at E*expert_bytes regardless of R, while its MAC cost grows with R*topk. With
the 272 rows-per-expert crossover above, a 2048-token chunk at topk 10 over 512 experts averages 40
rows/expert - still 7x memory-bound; 8192-token chunks average 160, still under. So on this model class
the XMX routes do not become the limit for any chunk size the 3090 could feed in one pass, and the
binding quantity for prefill is the same one as for decode: bytes per layer per step, plus the link.""")


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
        cnt = pq.counts_for(prof, E)
        if cnt is None:
            continue
        tot = sum(cnt) or 1.0
        freq = sorted((c / tot for c in cnt), reverse=True)
        print(f"  {lab} bpw (topk {topk}, E {E}):", end="")
        for R in (512, 2048, 8192):
            rows_e = [R * topk * f for f in freq]
            n_hot = sum(1 for x in rows_e if x >= 272)
            print(f"   R={R}: max {rows_e[0]:6.0f} rows/expert, {n_hot:3d} of {E} above 272",
                  end="  |")
        print()


if __name__ == "__main__":
    main()