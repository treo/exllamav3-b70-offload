"""Score notes/acceptance_model.py's output against testlib.e2e.assert_logits_agree's policy.

    python notes/acceptance_report.py /tmp/accept_model.pt [--floor-factor 4] [--cpu-median-kl 1e-2]

Prints, for each non-reference placement, the actual KL median/mean/max, the model's noise floor, the
confident-position top-1 agreement, the resulting pass/fail under the project's thresholds, and the
greedy divergence point (first token where the argmax differs, plus whether the reference's choice led
by less than the 0.25-logit near-tie allowance).
"""
import argparse
import os
import sys

import torch

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)
sys.path.insert(0, os.path.join(ROOT, "tests"))

from testlib.compare import confident_top1_agreement, kl_divergence  # noqa: E402


def score(name, ref, got, floor, ff, abs_med, abs_mean, min_top1, margin, tag):
    kl = kl_divergence(ref, got)
    med, mean, mx = kl.median().item(), kl.mean().item(), kl.max().item()
    f_med = floor.median().item()
    f_mean = floor.mean().item()
    agree, n = confident_top1_agreement(ref, got, margin)
    ok_med = med < max(abs_med, ff * f_med)
    ok_mean = mean < max(abs_mean, ff * f_mean)
    ok_top1 = agree >= min_top1
    finite = bool(torch.isfinite(got).all())
    print(f"{tag:>18}  KL med {med:9.2e} mean {mean:9.2e} max {mx:9.2e} | "
          f"floor med {f_med:8.2e} mean {f_mean:8.2e} | "
          f"top1 {agree:5.3f} of {n:4d} | "
          f"{'PASS' if (ok_med and ok_mean and ok_top1 and finite) else 'FAIL'}"
          f"{'' if ok_med else ' [median]'}{'' if ok_mean else ' [mean]'}"
          f"{'' if ok_top1 else ' [top1]'}{'' if finite else ' [nonfinite]'} | "
          f"headroom med x{max(abs_med, ff * f_med) / max(med, 1e-12):.1f}")
    return dict(med = med, mean = mean, max = mx, agree = agree, n = n,
                ok = ok_med and ok_mean and ok_top1 and finite)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("data")
    ap.add_argument("--floor-factor", type = float, default = 4.0)
    ap.add_argument("--cpu-median-kl", type = float, default = 1e-2)
    ap.add_argument("--abs-mean-kl", type = float, default = 0.05)
    ap.add_argument("--min-top1", type = float, default = 0.97)
    ap.add_argument("--margin", type = float, default = 1.0)
    ap.add_argument("--near-tie", type = float, default = 0.25)
    a = ap.parse_args()

    d = torch.load(a.data)
    ref = d["ref"]
    print(f"# reference: all-GPU load; noise-floor median {ref['floor'].median():.2e} "
          f"mean {ref['floor'].mean():.2e}; placement {ref['place']}")
    print("\n## teacher-forced cache-less logits (forward_logits)")
    for name, v in d.items():
        if name == "ref":
            continue
        score(name, ref["full"], v["full"], ref["floor"], a.floor_factor, a.cpu_median_kl,
              a.abs_mean_kl, a.min_top1, a.margin, "forward")
    print("\n## cached prefill + single-token decode logits (prefill_decode_logits)")
    for name, v in d.items():
        if name == "ref":
            continue
        rp, gp = ref["pdl"], v["pdl"]
        nrow = min(rp.shape[0], gp.shape[0])
        score(name, rp[:nrow], gp[:nrow], ref["floor"], a.floor_factor, a.cpu_median_kl,
              a.abs_mean_kl, a.min_top1, a.margin, "prefill+decode")
    print("\n## greedy trajectory (informational: the CPU path is NOT required to be greedy-identical;\n"
          "   test_moe_offload asserts statistical agreement instead. Near-tie judgement needs the\n"
          "   run's own generated logits, captured by acceptance_model.py --decode ...)")
    for name, v in d.items():
        if name == "ref":
            continue
        rt = ref["greedy"].tolist()
        gt = v["greedy"].tolist()
        div = next((i for i in range(min(len(rt), len(gt))) if rt[i] != gt[i]), None)
        if div is None:
            print(f"{name:>18}  identical tokens ({len(gt)})")
            continue
        rgl, ggl = ref.get("greedy_logits"), v.get("greedy_logits")
        if rgl is not None and div < rgl.shape[0]:
            row = rgl[div].float()
            gap = (row[rt[div]] - row[gt[div]]).item()
            verdict = "near-tie (allowed)" if gap < a.near_tie else "exceeds near-tie"
            print(f"{name:>18}  diverges at token {div}/{len(rt)}; reference lead there "
                  f"{gap:+.3f} logits -> {verdict}")
        else:
            print(f"{name:>18}  diverges at token {div}/{len(rt)} (no generated logits captured "
                  f"in this run: re-run acceptance_model.py to judge the near-tie)")
    print("\n## placement actually reached")
    for name, v in d.items():
        print(f"{name:>18}  {' '.join(v['args']) or '(none)':<24} {v['env']} -> {v['place']}")


if __name__ == "__main__":
    main()