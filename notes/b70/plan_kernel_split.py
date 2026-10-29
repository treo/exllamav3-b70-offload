#!/usr/bin/env python3
"""
plan_kernel_split.py - what a separate large-batch kernel could and could not rescue.

The concurrency table says the B70 binds from b~4 onward and that its cost is
union(rows) * h * expert_bytes / rate. Two of those factors are kernel-addressable and one is not:

  bytes            irreducible. Every touched expert's full weight block must be read once per layer
                   per step, and the model ALREADY credits that reuse (union, not rows*topk). A kernel
                   cannot go below E*expert_bytes as rows grow.
  rate             addressable, by up to the measured clustered factor (1.08-1.99x,
                   out_rates_footprint.txt). This is not a "better kernel" in the usual sense: it is
                   grid ORDER - neighbouring lanes reading neighbouring addresses - which a b=1 GEMV
                   cannot arrange (there are too few tiles to order) and a bucketed large-b GEMM can.
  flops            only addressable work if rows/expert >= 272 (the measured XMX crossover). At decode
                   rows/expert stays ~1-6 even at b=256, so a DPAS path buys nothing there; it is a
                   PREFILL mechanism, and only for the hot tail of big chunks.

Also priced here, because it is the second thing that changes with b: the activation path. x goes down
as rows * hidden * 1 B (int8) and partials come up as rows * topk * hidden * sz_out, at 14.4 GB/s, so at
large b the link becomes a real fraction of the card's time and the large-b variant has a reason to exist
even before considering compute.
"""
import importlib.util
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location("ppb", os.path.join(HERE, "plan_parent_budget.py"))
ppb = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(ppb)
_spec2 = importlib.util.spec_from_file_location("pq", os.path.join(HERE, "plan_quant_scaling.py"))
pq = importlib.util.module_from_spec(_spec2); _spec2.loader.exec_module(pq)
_spec3 = importlib.util.spec_from_file_location("pc", os.path.join(HERE, "plan_concurrency.py"))
pc = importlib.util.module_from_spec(_spec3); _spec3.loader.exec_module(pc)

LINK = 14.4          # GB/s, measured pinned<->device
CTX = 4096


def us(mib, gbjs):
    return mib * 1048576.0 / (gbjs * 1000.0)


def main():
    ppb.selftest()
    assert abs(us(763.0, 243.0) - 3291.0) < 60.0, us(763.0, 243.0)
    for lab, dirname, prof, bandk in pq.QUANTS:
        cat = ppb.census(dirname)
        cfg = json.load(open(os.path.join(ppb.ROOT, dirname, "config.json")))
        tc = cfg.get("text_config", cfg)
        nl, E = tc["num_hidden_layers"], tc.get("n_routed_experts") or tc.get("num_experts")
        topk, H = tc.get("num_experts_per_tok") or tc.get("topk"), tc["hidden_size"]
        eb = cat["routed"] / nl / E / 2**20
        st = ppb.state_budget(cfg)
        cnt = pq.counts_for(prof, E)
        tot = sum(cnt) or 1.0
        sg = max(0.0, 24.0 - cat["read"] / 2**30 - st["tok_kib"] * 1024 * CTX / 2**30
                 - st["lin_mib"] / 1024 - 1.5)
        n_res = min(E, int(sg * 2**30 / (eb * 2**20) / nl) + int(31.9 * 2**30 / nl / (eb * 2**20)))
        h = sum(sorted(cnt, reverse=True)[:n_res]) / tot
        rd_l = cat["read"] / nl / 2**20
        state_l, kv_l = st["lin_mib"] / nl * 2, st["tok_kib"] / nl / 1024 * CTX
        fixed = 250.0 - us(rd_l + state_l + kv_l, 936.0)
        band = pq.BANDS[bandk]
        print(f"\nQwen3.8 {lab} bpw   (h {h*100:.1f} %, expert {eb:.3f} MiB, E {E}, topk {topk}, H {H})")
        print(f"  {'rows':>5s} {'B70 MiB/L':>10s} {'scat us':>8s} {'clus us':>8s} {'parent':>7s} "
              f"{'link us':>8s} {'link/B70':>9s} {'tok/s scat':>11s} {'tok/s clus':>11s} {'rescue':>7s} {'r/exp':>6s}")
        for rows in (1, 4, 8, 32, 128, 256):
            u = pc.union_at(cnt, E, topk, rows, trials=250)
            mib = u * h * eb
            rate_s = pq.interp(band, mib, 1)
            rate_c = pq.interp(band, mib, 2)
            tb_s, tb_c = us(mib, rate_s), us(mib, rate_c)
            tp = fixed + us(rd_l + rows * (state_l + kv_l), 936.0)
            # activations per layer per step: x down (int8) + partials up (fp16)
            link_mib = rows * H * 1 / 2**20 + rows * topk * H * 2 / 2**20
            t_link = us(link_mib, LINK)
            w_s, w_c = max(tp, tb_s), max(tp, tb_c)
            t_s, t_c = rows / (w_s * nl / 1e6), rows / (w_c * nl / 1e6)
            print(f"  {rows:5d} {mib:10.1f} {tb_s:8.0f} {tb_c:8.0f} {tp:7.0f} {t_link:8.0f} "
                  f"{t_link/tb_s*100:8.0f}% {t_s:11.0f} {t_c:11.0f} {t_c/t_s:6.2f}x "
                  f"{rows*topk/max(u,1):6.1f}")
    print("""
Reading it
* The rescue is real but bounded, and it is the SAME 1.08-1.99x locality factor the microbenchmark
  measured, not a new mechanism. Its size depends on whether the parent retakes the lead: where
  clustered B70 time falls below T_parent, throughput is capped by the parent and the rest of the
  locality gain is wasted. So "write a large-b kernel" should be scored as "get the clustered rate at
  large b", with the ceiling being the parent's curve, not infinity.
* Rows/expert never approaches 272 at any concurrency the box can hold (it peaks near 5-6 at b=256),
  so a DPAS/XMX decode kernel is not the rescue. Bucketing rows by expert is, because bucketing is what
  makes the tile stream orderable - the win is in the memory system, arrived at through the schedule.
* The activation path is the second reason to specialise large b. Its share of the B70's time grows with
  rows and is the one term the 3090 side can shrink by itself (sz_out = fp16 -> bf16/int8-quantised
  partials, or letting the B70 add the partials of picks it owns). At the rows where the B70 binds, link
  time is a straight addition to the pipeline's critical path unless it is queued separately, which is
  the §5 low-priority-queue argument reappearing on the payload side.
* What it costs: two kernel families to keep bit-exact (gates A/B' multiply), plus a bucket/gather
  pass per layer per step. The cheap version of the split is not two unpack paths - Recipe stays shared -
  but two SCHEDULES over one unpack kernel, which is how the CPU path already does it (bucketed
  mul1/mul2 with different thread counts). Size the payoff against that, not against a rewrite.""")


if __name__ == "__main__":
    main()