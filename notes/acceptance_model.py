"""Level-1 acceptance measurement: whole-model agreement of the CPU-offloaded paths.

    python notes/acceptance_model.py MODEL_DIR [--placements ref,split,split_pa,layer20]
                                   [--profile cold|warm] [--prompt 256] [--decode 24]
                                   [--dump-acts /tmp/acts.pt] [--out /tmp/accept_model.pt]

Loads the model once per placement and records, on the fixed REFERENCE_TEXT the test suite uses:

  * teacher-forced cache-less logits             (testlib.e2e.forward_logits)
  * cached prefill + single-token decode logits  (testlib.e2e.prefill_decode_logits)
  * greedy token ids                             (testlib.e2e.greedy)
  * the model's own noise floor                  (testlib.e2e.noise_floor)

saving them to --out for notes/acceptance_report.py to score with testlib.e2e.assert_logits_agree's
tolerance policy. Placement state is controlled per placement (the hot-expert profile otherwise
leaks between runs, measured-costs.md §8.3): EXPERT_STATS_DIR is redirected to a fresh scratch
directory, or seeded from --ref-profile with --profile warm. With --dump-acts a pre-forward hook on
the first MoE layer captures real hidden states for the kernel-level harness.
"""
import argparse
import json
import os
import shutil
import sys

import torch

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)
sys.path.insert(0, os.path.join(ROOT, "tests"))

from testlib import e2e                                       # noqa: E402
from exllamav3.modules import block_sparse_mlp_cpu            # noqa: E402

# name -> (model_init args, extra env vars)
PLACEMENTS = {
    "ref": ([], {}),
    "split": (["-mcs", "192"], {}),
    "split_pa": (["-mcs", "192", "-mcpa"], {}),
    "split_all": (["-mcs", "255"], {}),
    "split_nowide": (["-mcs", "192"], {"EXL3_MOE_CPU_WIDE": "0"}),
    "split_noswz": (["-mcs", "192"], {"EXL3_MOE_CPU_SWIZZLE": "0"}),
    "layer20": (["-mcl", "20"], {}),
    "layer_all": (["-mcl", "40"], {}),
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("model_dir")
    ap.add_argument("--placements", default = "ref,split,split_pa,layer20")
    ap.add_argument("--profile", choices = ["cold", "warm"], default = "cold")
    ap.add_argument("--ref-profile", default = os.path.join(ROOT, "notes", "refprofile_q35.json"))
    ap.add_argument("--prompt", type = int, default = 256)
    ap.add_argument("--decode", type = int, default = 24)
    ap.add_argument("--cache", type = int, default = 4096)
    ap.add_argument("--out", default = "/tmp/accept_model.pt")
    ap.add_argument("--dump-acts", default = "")
    a = ap.parse_args()

    results = {}
    dump_patch = None
    for name in a.placements.split(","):
        args, env = PLACEMENTS[name]
        for k, v in env.items():
            os.environ[k] = v
        stats = f"/tmp/accept_stats_{name}"
        os.makedirs(stats, exist_ok = True)
        for f in os.listdir(stats):
            os.remove(os.path.join(stats, f))
        if a.profile == "warm" and os.path.exists(a.ref_profile):
            shutil.copy(a.ref_profile, os.path.join(stats, os.path.basename(a.ref_profile)))
        block_sparse_mlp_cpu.EXPERT_STATS_DIR = stats
        # the split size must not exceed the model's expert count
        args = list(args)
        print(f"## loading {name}: {' '.join(args)} {env} (profile={a.profile})", flush = True)

        with e2e.load_model(a.model_dir, None, *args, cache_tokens = a.cache) as lm:
            ids = lm.encode(max_tokens = a.prompt)
            acts = []
            handle = None
            if a.dump_acts and name == "ref":
                from exllamav3.modules import block_sparse_mlp as bsm
                orig_fwd = bsm.BlockSparseMLP.forward

                def patched(self, x, params, out_dtype = None):
                    if len(acts) < 8:
                        res = params.get("residual") if getattr(self, "alt_residual_channel", False) else None
                        src = res if res is not None else x
                        acts.append(src.detach().float().cpu().clone().reshape(-1, src.shape[-1]))
                    return orig_fwd(self, x, params, out_dtype = out_dtype)
                bsm.BlockSparseMLP.forward = patched
                dump_patch = (bsm, orig_fwd)

            full = e2e.forward_logits(lm, ids)[0]
            pdl = e2e.prefill_decode_logits(lm, ids, decode_steps = a.decode)
            toks, glg, _ = e2e.greedy(lm.generator(), ids, a.decode, return_logits = True)
            floor = e2e.noise_floor(lm, ids, min(8, a.decode), full_logits = full)
            n_moe = sum(1 for m in lm.model if type(m).__name__ == "BlockSparseMLP")
            # what the loader actually did: per-MoE-module placement summary
            place = {}
            for m in lm.model:
                if type(m).__name__ != "BlockSparseMLP":
                    continue
                key = "layer_offload" if getattr(m, "cpu_offload", False) else (
                    f"split@{m.cpu_split_first}" if getattr(m, "cpu_split_first", None) is not None
                    else "gpu")
                if getattr(m, "_split_perm", None) is not None:
                    key += "+perm"
                place[key] = place.get(key, 0) + 1
        if dump_patch is not None:
            dump_patch[0].BlockSparseMLP.forward = dump_patch[1]
            dump_patch = None
        for k in env:
            del os.environ[k]

        results[name] = dict(full = full, pdl = pdl, greedy = torch.tensor(toks, dtype = torch.long),
                             greedy_logits = (glg[:, :lm.tokenizer.actual_vocab_size].half()
                                              if glg is not None else None),
                             floor = floor, n_moe = n_moe, args = args, env = env, place = place)
        print(f"   logits {tuple(full.shape)} / decode {tuple(pdl.shape)} / greedy {len(toks)} tokens; "
              f"noise-floor median {floor.median().item():.2e}; placement {place}", flush = True)
        if a.dump_acts and acts and name == "ref":
            torch.save({"prefill": [x for x in acts if x.shape[0] > 1][:1],
                        "decode": [x for x in acts if x.shape[0] == 1][:2],
                        "hidden": int(acts[0].shape[-1]) if acts else 0}, a.dump_acts)
            print(f"   captured activations -> {a.dump_acts} "
                  f"({[tuple(t.shape) for t in acts[:3]]})", flush = True)

    torch.save(results, a.out)
    print(json.dumps({k: {"floor_median": float(v["floor"].median()),
                          "greedy_first8": v["greedy"].tolist()[:8]}
                      for k, v in results.items()}, indent = 1), flush = True)


if __name__ == "__main__":
    main()