#!/usr/bin/env python3
"""Prefill-regime quality probe (the gate eval/ppl.py cannot provide).

eval/ppl.py scores ONE row per forward, so with EXL3_MOE_STREAM_MIN_ROWS=32 it never enters
the streamed-prefill tier - i.e. it cannot gate the hot-pick streaming policy
(EXL3_MOE_B70_STREAM_HOT) at all. This script walks a long wikitext span through the cache
exactly like eval/perf.py's prefill measurement does (>=32 MoE rows per forward, so the
streamed tier and the worker tail both run) and reports perplexity plus a mean-|logit|
fingerprint.

Run once per arm with IDENTICAL model flags and compare against the CPU worker:
  ../.venv/bin/python qa_stream.py -m <model> -mcs 256 -mcpa -ngr -mct 15 -tok 8192
  EXL3_MOE_B70=1 ../.venv/bin/python qa_stream.py ...        # B70, hot-pick streaming
  EXL3_MOE_B70=1 EXL3_MOE_B70_STREAM_HOT=0 ...               # B70, classic anti-theft
Tolerance: the recorded int8-tier budget is |dPPL| <= 0.25% on 20x2048
(sycl_moe/archive/measurements-ledger.md); run both arms over the same span, so here any
difference above ~0.1% is the mechanism, not the corpus.
"""
import sys, os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import argparse
import torch
from exllamav3 import model_init


def wikitext_ids(tokenizer, needed):
    """Same cached wikitext-2 raw text as eval/perf.py, tokenized."""
    import tempfile, zipfile, pathlib, urllib.request
    url = "https://huggingface.co/datasets/ggml-org/ci/resolve/main/wikitext-2-raw-v1.zip"
    d = pathlib.Path(tempfile.gettempdir()) / "llama_cpp_ppl_wikitext2"
    p = d / "wikitext-2-raw" / "wiki.test.raw"
    if not p.exists():
        d.mkdir(parents = True, exist_ok = True)
        z = d / "wikitext-2-raw-v1.zip"
        urllib.request.urlretrieve(url, str(z))
        with zipfile.ZipFile(str(z), "r") as zf:
            zf.extractall(str(d))
    ids = tokenizer.encode(open(p, "r", encoding = "utf-8").read())
    while ids.shape[-1] < needed:
        ids = torch.cat([ids, ids], dim = -1)
    return ids[:, :needed]


@torch.inference_mode()
def main(args):
    assert args.chunk >= 32, "chunk below EXL3_MOE_STREAM_MIN_ROWS: the streamed tier never runs"
    model, config, cache, tokenizer = model_init.init(args)
    ids = wikitext_ids(tokenizer, args.tok + 1)
    n = min(ids.shape[-1] - 1, args.cache_size)

    ce, fp, done = 0.0, 0.0, 0
    is_recurrent = model.caps.get("recurrent_states", False)
    for s in range(0, n, args.chunk):
        e = min(s + args.chunk, n)
        if e - 1 <= s:
            break
        # Same handshake eval/perf.py's prefill uses: a recurrent-capable model needs a test
        # state for the prefix, and it must be freed before the next chunk's state is taken.
        recurrent = [cache.get_test_state(s)] if is_recurrent else None
        params = {"attn_mode": "flash_attn", "cache": cache, "past_len": s,
                  "batch_shape": (1, max(e, 256)), "recurrent_states": recurrent}
        logits = model.forward(ids[:, s:e], params)          # [1, len, vocab] (see eval/ppl.py)
        tgt = ids[:, s + 1:e + 1].to(logits.device)
        nt = tgt.shape[1]
        lg = logits[0]
        del logits
        for p0 in range(0, nt, 256):                     # slice the CE: vocab × rows is huge
            p1 = min(p0 + 256, nt)
            ce += torch.nn.functional.cross_entropy(
                lg[p0:p1].float(), tgt[0, p0:p1], reduction = "sum").item()
            fp += float(lg[p0:p1].abs().mean().item()) * (p1 - p0)
        done += nt
        del lg, tgt, params
        if recurrent:
            recurrent[0].free()
        torch.cuda.empty_cache()
    ppl = torch.exp(torch.tensor(ce / done)).item()
    print(f"QA_RESULT tokens {done} ppl {ppl:.6f} logit_meanabs {fp / done:.6f}")


if __name__ == "__main__":
    ap = argparse.ArgumentParser(allow_abbrev = False)
    model_init.add_args(ap, default_cache_size = 32768, default_autosplit_max_batch_size = 1,
                        default_chunk_size = 4096)
    ap.add_argument("-tok", "--tok", type = int, default = 8192, help = "tokens to score")
    ap.add_argument("-chunk", "--chunk", type = int, default = 1024, help = "rows per prefill forward")
    main(ap.parse_args())