#!/usr/bin/env python3
"""Bucket the PARENT's real chunked-prefill forward by kernel, so its NON-EXPERT prefill term is measured.

Why this exists. The -mcs slope fit (notes/b70/run_mcs_slope.sh, out_prefill_mcpa.txt) says a 4096-token
2.05bpw prefill costs

        time = 1988 ms  +  10.24 ms x (experts homed on the CPU)

The slope is the expert term and is now understood (57 % of the step at -mcs 258). The INTERCEPT - 1988 ms, all
of the model's non-expert work plus whatever expert work the 3090 still does locally - has never been
decomposed. It is the last unknown that turns "the B70 could make prefill 1.9-2.7x faster" into a number,
because it decides whether the card's expert leg ADDS to throughput or hides underneath work the parent performs
anyway. Nothing measured so far can answer it: bench_engine_step.py only ever forwards ONE token (a decode
step), and every prefill figure to date came from wall-clock throughput, which cannot be split by kernel.

Method. Feed the engine a prompt of (reps + 1) x chunk_size tokens and ask for one new token, letting the
engine's OWN chunker split it. Cache bookkeeping, transposition, attention regimes and MoE prefill paths are
then the ones production uses - deliberately NOT a hand-rolled model.forward(N tokens), which is how this kind
of measurement usually lies. Device time is attributed per kernel via torch.profiler and classified with
bench_engine_step.classify (imported, so the two benches cannot drift apart on what counts as "expert").

The first chunk is warm-up (autotuner, first-touch) and is excluded from per-chunk device attribution by
default; --all-chunks keeps it, and the difference bounds the warm-up error on every other prefill number in
this plan.

Corpus. notes/b70/fixtures/prefill_pool.txt - 12 DISTINCT in-repo documents concatenated once each, the corpus
that replaced repeated text after LESSONS 76 measured periodic text inflating prefill by +4.2 % while cutting
expert coverage 4.4 %. A bucket study on repeated text would inherit that bias silently. Truncation below the
requested size is fatal unless --allow-short (LESSONS 75: prompt length moves prefill tok/s by ~410 ms per
forward, so a short prompt is a different experiment).

Usage (needs a quiet machine - the CPU worker competes with everything else here):
    source /opt/intel/oneapi/setvars.sh; source notes/env.sh
    python3 notes/b70/bench_parent_prefill.py --model <path> --chunk 4096 --reps 3 -- -mcs 256 -mct 15
    python3 notes/b70/bench_parent_prefill.py --model <path> -- -mcs 256 -mct 15 -mcpa
Everything after "--" is handed verbatim to model_init, so any engine flag works without this script changing.
"""
from __future__ import annotations

import argparse
import os
import statistics
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
for p in (ROOT, os.path.join(ROOT, "tests"), os.path.join(ROOT, "notes"), HERE):
    if p not in sys.path:
        sys.path.insert(0, p)

import torch                                                 # noqa: E402
from torch.profiler import ProfilerActivity, profile          # noqa: E402
from exllamav3 import Job                                     # noqa: E402
from exllamav3.generator.sampler import ArgmaxSampler          # noqa: E402
from testlib import e2e                                       # noqa: E402
from bench_engine_step import classify                        # noqa: E402 - one classifier, two benches

POOL = os.path.join(HERE, "fixtures", "prefill_pool.txt")


def meminfo_kb() -> dict:
    out = {}
    with open("/proc/meminfo") as fh:
        for line in fh:
            p = line.split(":")
            if len(p) == 2:
                out[p[0].strip()] = int(p[1].strip().split()[0])
    return out


def routed_expert_gib(model_dir: str) -> float:
    """Sum routed-expert bytes straight from the safetensors HEADERS.

    Not from model.safetensors.index.json: on GLM-5.3 that file is stale by ~3,530 tensors (it predates the MTP
    head), and a capacity guard that reads it would under-estimate exactly the model that needs guarding
    (LESSONS 86). Header-only reads, so this is ~1 s even at 17 shards.
    """
    import glob
    import json as _json
    import re
    import struct
    pat = re.compile(r"\.mlp\.experts\.")
    els = {"F32": 4, "F16": 2, "BF16": 2, "I64": 8, "I32": 4, "I8": 1, "U8": 1, "I16": 2, "BOOL": 1}
    tot = 0
    for f in sorted(glob.glob(os.path.join(model_dir, "*.safetensors"))):
        with open(f, "rb") as fh:
            n = struct.unpack("<Q", fh.read(8))[0]
            hdr = _json.loads(fh.read(n))
        for k, v in hdr.items():
            if k == "__metadata__" or not pat.search(k):
                continue
            nb = 1
            for d in v.get("shape", []):
                nb *= int(d)
            tot += nb * els.get(str(v.get("dtype")), 1)
    return tot / 2.0 ** 30


def mem_preflight(model_dir: str, mcpa: bool, allow_tight: bool) -> None:
    """Refuse to start an arm that leaves the box no memory reserve.

    WHY (this is a post-mortem, not paranoia). GLM-5.3's routed experts are 109.3 GiB on a 125 GiB machine = 87 %
    of host RAM, and the CPU home holds PINNED pages (weight staging slots, huge-page arena hint) which survive
    neither reclaim nor swap-out when the page cache is squeezed. A GLM + -mcpa + chunked-prefill arm queued
    unattended hard-hung the machine and forced a reboot; the engine had warned about arena memory in an earlier
    session and I had dismissed the wording as self-contradictory (LESSONS 87).
    """
    mi = meminfo_kb()
    tot_g, avail_g = mi["MemTotal"] / 2.0 ** 20, mi["MemAvailable"] / 2.0 ** 20
    swap_g = mi.get("SwapTotal", 0) / 2.0 ** 20
    rgib = routed_expert_gib(model_dir)
    # Demand is not "a few GiB of arena": loading this model puts ~rgib of expert bytes under memory pressure,
    # and on top of it the CPU home pins staging slots that cannot be reclaimed. So the test is availability vs
    # the WHOLE footprint, not vs a nominal reserve. The first version of this guard asked for 40 GiB and waved
    # through the arm that hung the machine, which is the difference between a guard and a formality.
    need = rgib + (12.0 if not mcpa else 24.0)
    need = max(need, 0.25 * tot_g)
    print(f"  preflight: MemTotal {tot_g:.0f} GiB, MemAvailable {avail_g:.0f} GiB, swap {swap_g:.0f} GiB, "
          f"routed experts {rgib:.1f} GiB ({100 * rgib / tot_g:.0f} % of RAM) -> needs >= {need:.0f} GiB free")
    if 0.8 * tot_g < rgib <= 1.0 * tot_g:
        print(f"  WARNING: this model's expert set alone is {100 * rgib / tot_g:.0f} % of host RAM. Load is "
              f"possible but there is no reserve; run it attended.")
    if avail_g < need and not allow_tight:
        raise SystemExit(
            f"REFUSING to run: {avail_g:.0f} GiB available, {need:.0f} GiB wanted (footprint {rgib:.0f} GiB of "
            f"experts + staging"
            + (" + promotion arenas" if mcpa else "") +
            "). This model's expert set is "
            f"{100 * rgib / tot_g:.0f} % of host RAM and the CPU home pins pages for staging"
            + (" while -mcpa asks for more" if mcpa else "") +
            ". Free memory or drop the arm: a hard hang costs the whole queue and the logs in /tmp with it. "
            "--allow-tight overrides (and should be used only when you are watching the box).")



from mem_guard import require_headroom as mem_preflight   # noqa: E402  (the local definitions below are the
                                                           # originals, kept only as a fallback; this binding wins)


def main() -> None:
    ap = argparse.ArgumentParser(allow_abbrev=False, description=__doc__.split("\n")[0])
    ap.add_argument("--model", "-m", required=True)
    ap.add_argument("--chunk", type=int, default=4096,
                    help="tokens per prefill chunk; also passed as -chunk_size so the engine's chunker agrees "
                         "with our divisor. Refuses to run if you also pass -chunk_size with another value.")
    ap.add_argument("--reps", type=int, default=3, help="timed chunks (one extra chunk is prepended as warm-up)")
    ap.add_argument("--cache", type=int, default=0, help="cache tokens (default: exactly what we will feed)")
    ap.add_argument("--all-chunks", action="store_true", help="no-op kept for the record: the aggregate "
                    "profiler cannot separate the warm-up chunk, so attribution is over all chunks either way")
    ap.add_argument("--allow-tight", action="store_true", help="run anyway when the memory preflight objects "
                    "(see mem_preflight: this is the arm that rebooted the box once)")
    ap.add_argument("--allow-short", action="store_true", help="permit a corpus shorter than requested")
    args, engine_args = ap.parse_known_args()
    # argparse hands the "--" separator itself back in the extras on this path, and the engine's parser - which
    # defines no positionals - then rejects everything after it. Strip it.
    engine_args = [a for a in engine_args if a != "--"]
    if any(str(a).startswith("--") for a in engine_args):
        raise SystemExit(f"engine args must use the engine's single-dash form: {engine_args}")

    if "-chunk_size" in engine_args:
        got = int(engine_args[engine_args.index("-chunk_size") + 1])
        if got != args.chunk:
            raise SystemExit(f"-chunk_size {got} conflicts with --chunk {args.chunk}: the per-chunk divisor "
                             f"would be wrong. Pass --chunk only.")
    else:
        engine_args = engine_args + ["-chunk_size", str(args.chunk)]

    nchunks = args.reps + 1
    want = nchunks * args.chunk
    raw = open(POOL, encoding="utf-8", errors="replace").read()
    cache_tokens = args.cache or (want + 512)
    if cache_tokens < want + 8:
        raise SystemExit(f"--cache {cache_tokens} cannot hold {want} prompt tokens + 1 decode")

    # BEFORE the load, not after it: the arm that hung the box died inside loading/first-forward, so a guard that
    # runs once the weights are resident is a post-mortem, not a guard.
    mem_preflight(args.model, "-mcpa" in engine_args, args.allow_tight)

    with e2e.load_model(args.model, None, *engine_args, cache_tokens=cache_tokens, warmup=True) as lm:
        model, cache, config = lm.model, lm.cache, lm.config
        nl = getattr(config, "num_hidden_layers", None) or len(model.blocks)
        ids = lm.tokenizer.encode(raw).to(torch.long).reshape(1, -1)
        if ids.shape[1] < want:
            if not args.allow_short:
                raise SystemExit(f"corpus gives {ids.shape[1]} tokens, need {want} ({nchunks} chunks x "
                                 f"{args.chunk}). Lower --reps/--chunk, enlarge the pool, or --allow-short "
                                 f"(which silently changes the experiment - see LESSONS 75).")
            nchunks = max(1, ids.shape[1] // args.chunk)
            want = nchunks * args.chunk
        ids = ids[:, :want]
        mcpa = "-mcpa" in engine_args
        print(f"\nparent prefill bench: {getattr(config, '_name', 'model')}  layers {nl}  "
              f"{nchunks} chunks x {args.chunk} tokens  cache {cache_tokens}  mcpa={'on' if mcpa else 'off'}  "
              f"engine args: {' '.join(engine_args)}")

        def drain(prof=None) -> float:
            """One engine-correct multi-chunk prefill; returns wall ms PER CHUNK."""
            gen = lm.generator()
            gen.enqueue(Job(input_ids=ids, max_new_tokens=1, sampler=ArgmaxSampler(), return_logits=False,
                            stop_conditions=[], identifier=0))
            t0 = time.perf_counter()
            if prof is None:
                while gen.num_remaining_jobs():
                    for _ in gen.iterate():
                        pass
            else:
                with prof:
                    while gen.num_remaining_jobs():
                        for _ in gen.iterate():
                            pass
            torch.cuda.synchronize()
            return (time.perf_counter() - t0) * 1000.0 / nchunks

        _ = drain()                                          # autotuner/pipeline warm before anything counts
        walls = [drain() for _ in range(3)]
        import resource
        rss = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 2.0 ** 10
        print(f"  peak RSS this process: {rss:.1f} GiB (pinned arenas are charged outside this number)")
        med = statistics.median(walls)
        print(f"  wall per chunk: median {med:8.1f} ms  (passes: {' '.join(f'{w:.0f}' for w in walls)})")
        print(f"  -> {args.chunk / med * 1000.0:7.0f} tok/s  =  {med * 1000 / nl:7.1f} us/layer")

        # The profiler aggregates over the WHOLE run, so a per-chunk split cannot be recovered from
        # key_averages() and chunk 1's warm-up kernels ARE included. Dividing by (nchunks - 1) to "drop" the
        # warm-up did not drop it - it inflated every bucket by 33 % and made expert + non-expert exceed the
        # device total. Attribute over all chunks and state the contamination rather than hiding it.
        used = nchunks
        lab = f"all {nchunks} chunks (aggregate profiler cannot exclude the warm-up chunk)"
        prof = profile(activities=[ProfilerActivity.CPU, ProfilerActivity.CUDA])
        prof_wall = drain(prof)
        tot, per_bucket, rows = 0.0, {}, []
        for e in prof.key_averages():
            d = float(getattr(e, "self_device_time_total", 0) or 0)
            if d <= 0:
                continue
            tot += d
            b = classify(e.key)
            per_bucket[b] = per_bucket.get(b, 0.0) + d
            rows.append((d, e.count, b, e.key))
        per_chunk = tot / nchunks / 1000.0                           # us -> ms per chunk
        # prof_wall is ALREADY per-chunk (drain divides); multiplying by nchunks again reported 22.6 % busy for
        # a run that is ~90 % device-busy.
        busy = 100.0 * per_chunk / prof_wall
        print(f"  device-time per chunk: {per_chunk:8.1f} ms on {prof_wall:.1f} ms wall -> {busy:5.1f} % "
              f"device-busy, {100 - busy:5.1f} % STALL (non-overlapped)")
        print(f"  {'bucket':>10} {'ms/chunk':>10} {'us/layer':>9} {'%':>6}")
        for b, v in sorted(per_bucket.items(), key=lambda kv: -kv[1]):
            print(f"  {b:>10} {v / used / 1000:10.1f} {v / used / nl:9.1f} {100 * v / tot:5.1f}%")
        print("  top kernels (ms/chunk, calls/chunk, bucket):")
        for d, c, b, k in sorted(rows, reverse=True)[:18]:
            print(f"    {d / used / 1000:9.3f} {c / used:9.1f}  {b:>9}  {k[:70]}")
        exp = per_bucket.get("expert", 0.0) / used / 1000.0
        nonexp = (tot - per_bucket.get("expert", 0.0)) / used / 1000.0
        print(f"\n  >>> NON-EXPERT PREFILL = {nonexp:.1f} ms/chunk of {args.chunk} tokens "
              f"[{lab}]; GPU-side expert = {exp:.1f} ms/chunk. Diff this against the -mcs arms to see how much "
              f"of the 1988 ms intercept survives once experts leave the GPU.")
        if exp > 0.5 * (exp + nonexp):
            print("  NOTE: over half of device time classifies as expert - check that the CPU split is actually "
                  "active for this checkpoint before trusting the non-expert figure.")


if __name__ == "__main__":
    main()