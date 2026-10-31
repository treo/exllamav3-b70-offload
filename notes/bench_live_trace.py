#!/usr/bin/env python3
"""Live routing trace + real-text throughput on the shipping CPU-split path (closes plan items P1-text and P2).

    source notes/env.sh
    python3 notes/bench_live_trace.py -m <ckpt> -mcs 256 -mct 16 --decode 256 [--out /tmp/live_trace.json]

Two questions in one run, because both need the engine loaded with the CPU expert split active.

(1) THROUGHPUT ON REAL TEXT. notes/bench_engine_step.py drives `model.forward` with random token ids, which is
    right for bucketing kernel time but wrong for routing: uniform-random inputs pick experts uniformly, so the
    CPU-split leg does more work per step than real text does. This runs the real generator (prefill + greedy
    decode of actual model output) and reports us/token and us/layer with the sampler and lm_head included - the
    quantity the inherited ~250 us/layer window was supposed to represent.

(2) LIVE ROUTING TRACE. The plan's concentration statistics (`h`, `sigma`, `union(rows)`, "spanning ~ 1") come
    from cumulative placement profiles that architecture.md section 12 itself labels "upper bounds, not
    promises", and closing them needed "E14 (fresh trace) / E13 (real co-occurrence trace)". The split modules
    already keep a raw per-expert selection histogram (`_split_hist`, updated by the routing path); snapshotting
    it after every token and diffing yields that token's EXACT expert set per layer, with no engine change and no
    new kernel. From that: empirical union(b) for real windows of consecutive tokens (co-occurrence, not the
    independence approximation the planner uses), per-layer concentration, and the resident-set size needed to
    reach a given hit rate.

Timing and tracing are separate passes: per-token host-side snapshots would otherwise contaminate the very
numbers being measured. `--cold-start` begins from an empty profile directory (placement = identity, which is
what a first-ever run sees) whereas the default seeds the profile so placement is warm; both are reported
because the plan's numbers assume warm.
"""
import argparse
import json
import math
import os
import statistics
import sys
import time

import torch

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)
sys.path.insert(0, os.path.join(ROOT, "tests"))

from exllamav3.modules import block_sparse_mlp_cpu                  # noqa: E402
from testlib import e2e                                             # noqa: E402

CORPUS_REPS = 4          # REFERENCE_TEXT is short; repeating real text is still real text



def forward_only_pass(lm, ids, nl):
    """Time model.forward on real token ids without the generator, using the engine's own cache path.

    Deliberately mirrors notes/bench_engine_step.py's step(): a 1-row forward at position `past_len`, recurrent
    state borrowed from the cache's test-state allocator. It runs AFTER the generator pass, so the KV cache is
    populated with the real prompt and the attention work is the same work the generator paid for.
    """
    model, cache = lm.model, lm.cache
    is_rec = model.caps.get("recurrent_states", False)
    ctxmgr = torch.inference_mode()      # the engine writes into its cache in-place; outside inference_mode that
    ctxmgr.__enter__()                    # raises "Inplace update to inference tensor outside InferenceMode" 
    n = min(24, ids.shape[1] - 2)
    lat = []
    for j in range(n):
        pos = ids.shape[1] - n + j
        rec = [cache.get_test_state(pos)] if is_rec else None
        params = {"cache": cache, "attn_mode": "flash_attn", "past_len": pos, "pos": pos,
                  "batch_shape": (1, ((pos + 512 + 255) // 256) * 256), "recurrent_states": rec}
        e0, e1 = torch.cuda.Event(True), torch.cuda.Event(True)
        torch.cuda.synchronize()
        e0.record()
        model.forward(ids[:, pos:pos + 1], params)
        e1.record()
        torch.cuda.synchronize()
        lat.append(e0.elapsed_time(e1) / 1000.0)
        if rec:
            rec[0].free()
    return statistics.median(lat)


def hist_snapshot(mods):
    """Selection counts per split layer, in CHECKPOINT expert order (undoing the load-time permutation)."""
    out = []
    for m in mods:
        h = m._split_hist
        if h is None:
            out.append(None)
            continue
        vals = h.tolist()
        perm = getattr(m, "_split_perm", None)
        if perm and len(perm) == len(vals):
            un = [0.0] * len(vals)
            for i, e in enumerate(perm):
                un[e] = vals[i]
            vals = un
        out.append(vals)
    return out


def main():
    ap = argparse.ArgumentParser(allow_abbrev=False)
    ap.add_argument("-m", "--model_dir", required=True)
    ap.add_argument("-mcs", type=int, default=256, help="tail N experts per layer on the CPU (0 = no split)")
    ap.add_argument("-mct", type=int, default=16)
    ap.add_argument("-mcl", type=int, default=0)
    # Declared explicitly because `-mcpa` is NOT unknown-safe here: this parser owns -m/--model_dir, so
    # an unrecognised `-mcpa` parses as `-m cpa` and silently overwrites the model path (observed:
    # FileNotFoundError 'cpa/config.json'). Anything else unknown is now fatal for the same reason.
    ap.add_argument("-mcpa", "--moe_cpu_pinned_arena", dest="mcpa", action="store_true",
                    help="back the CPU worker expert arena with pinned shared memory (lets hot experts migrate CPU->GPU)")
    ap.add_argument("-cs", "--cache_size", type=int, default=8192)
    ap.add_argument("-chunk_size", "--chunk_size", dest="chunk_size", type=int, default=None,
                    help="forward the engine's prefill chunk size (default: whatever model_init picks). This is "
                         "the independent variable of a prefill-throughput measurement - the parent pays a "
                         "fixed cost per chunk - so it must be settable, and it must appear in the header line")
    ap.add_argument("--decode", type=int, default=256)
    ap.add_argument("--reps", type=int, default=CORPUS_REPS)
    ap.add_argument("--prompt-file", default=None,
                    help="use THIS file's text as the session prompt instead of REFERENCE_TEXT "
                         "(a second domain is the only way to test whether the cross-session "
                         "agreement with independence is a corpus artifact)")
    ap.add_argument("--stats-dir", default="/tmp/live_stats")
    ap.add_argument("--dump-snaps", default="",
                    help="write the raw per-token per-layer expert-delta trace (sparse JSON) to this path. The "
                         "aggregated profiles under profiles/live/ hold per-expert TOTALS, which are invariant "
                         "under reordering in time, so the questions that need a time axis - how long a hot set "
                         "stays hot, does a STATIC resident tier beat dynamic promotion (D16's reopening "
                         "condition) - could not be answered from stored data at all. Analyze with "
                         "notes/b70/analyze_dwell.py.")
    ap.add_argument("--prefill", type=int, default=0,
                    help="also time a single N-token prefill (0 = skip). Reported as tokens/s of the whole "
                         "prompt, which is the unit the acceptance figures use, and the number "
                         "doc/port/b70-prefill.md says must exist before any B70-prefill speedup is claimed")
    ap.add_argument("--prefill-allow-short", action="store_true",
                    help="let a prefill arm measure fewer tokens than --prefill asked for, loudly. Default is "
                         "fatal: a 4096-token request answered by 1158 tokens is a different measurement, and "
                         "the first version of this script printed it as if it were the one requested")
    ap.add_argument("--corpus", choices=("varied", "repeat"), default="varied",
                    help="what feeds a prefill arm that needs more tokens than the reference corpus holds: "
                         "'varied' (default) uses the deterministic pool of DISTINCT in-repo documents; "
                         "'repeat' re-uses REFERENCE_TEXT periodically and exists only as the control that "
                         "measures how far periodic text inflates prefill speed by collapsing expert coverage")
    ap.add_argument("--prefill-reps", type=int, default=1,
                    help="run the timed prefill forward N times, printing each pass. Necessary for any "
                         "adaptive-placement question (-mcpa): promotion costs a copy the FIRST time and saves "
                         "traffic afterwards, so a single pass measures the cost and hides the gain - the same "
                         "adaptation-horizon trap that made plain-vs-mcpa look like a regression on decode")
    ap.add_argument("--cold-start", action="store_true")
    ap.add_argument("--jobs", type=int, default=1,
                    help="run N CONCURRENT sessions (different prompt slices): the only way to measure "
                         "union(rows) for what the plan means by it - b parallel streams - instead of "
                         "approximating it with independence over one stream")
    ap.add_argument("--out", default="/tmp/live_trace.json")
    args, unknown = ap.parse_known_args()
    if unknown:
        raise SystemExit(f"unrecognised arguments {unknown}: add them explicitly rather than letting "
                         f"argparse re-split a short option (e.g. -mcpa -> -m cpa)")

    os.makedirs(args.stats_dir, exist_ok=True)
    if not args.cold_start:
        # seed from the operator's accumulated profile so placement is warm, as the plan assumes
        dflt = os.path.join(os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache"),
                            "exllamav3", "expert_stats")
        for f in os.listdir(dflt) if os.path.isdir(dflt) else []:
            try:
                os.link(os.path.join(dflt, f), os.path.join(args.stats_dir, f))
            except OSError:
                pass
    block_sparse_mlp_cpu.EXPERT_STATS_DIR = args.stats_dir

    init_args = []
    if args.chunk_size:
        init_args += ["-chunk_size", str(args.chunk_size)]
    if args.mcs:
        init_args += ["-mcs", str(args.mcs), "-mct", str(args.mct)]
    if args.mcl:
        init_args += ["-mcl", str(args.mcl)]
    if args.mcpa:
        init_args.append("-mcpa")

    with e2e.load_model(args.model_dir, None, *init_args, cache_tokens=args.cache_size, warmup=True) as lm:
        nl = len(getattr(lm.model, "blocks", [])) or getattr(lm.config, "num_hidden_layers", 0)
        # N DIFFERENT sessions, not N copies. Greedy decode of identical prompts is identical, so identical jobs
        # would measure union(1) and label it union(N) - the first version of this did exactly that and the
        # distinctness guard below caught it. The corpus is repeated real text, and each session gets a
        # non-commensurate window (313-token strides against a ~193-token period) so the slices cannot coincide;
        # the guard still checks rather than trusting the arithmetic.
        reps = max(args.reps, 2 * args.jobs + 2)
        if args.prompt_file:
            raw = open(args.prompt_file, encoding="utf-8", errors="replace").read()
            body = raw * max(1, reps) if len(raw) < 4000 * 4 else raw
        else:
            body = " ".join([e2e.REFERENCE_TEXT] * reps)
        all_ids = lm.tokenizer.encode(body).to(torch.long).reshape(1, -1)
        total = all_ids.shape[1]
        # A prefill arm needs >= --prefill tokens, and HOW it gets them changes what it measures. The corpus
        # used to be exactly REFERENCE_TEXT x --reps, so --reps silently CAPPED any --prefill request (6 reps x
        # ~193 tokens = 1158) and the arm printed a number anyway. Growing that repetition would fix the length
        # while wrecking the measurement: repeated text makes every window route like every other window, so a
        # 4096-token chunk touches far fewer DISTINCT experts than real text would - fewer experts means fewer
        # weight reads and a prefill number that is too fast. So: the decode/routing sessions keep the reference
        # corpus exactly as before (out_live_trace.txt stays comparable), and only the PREFILL arm draws on the
        # varied pool - 12 distinct in-repo documents, each appearing once, nothing repeated. 'repeat' stays
        # available as the control that measures the size of the bias rather than assuming it.
        pool = os.path.join(os.path.dirname(os.path.abspath(__file__)), "b70", "fixtures", "prefill_pool.txt")
        need = int(args.prefill or 0)
        pf_ids, pf_corpus = all_ids, "reference corpus"
        if need and total < need:
            if args.corpus == "repeat":
                one = max(1, lm.tokenizer.encode(e2e.REFERENCE_TEXT).shape[1])
                pf_ids = lm.tokenizer.encode(" ".join([e2e.REFERENCE_TEXT] * (need // one + 2))
                                             ).to(torch.long).reshape(1, -1)
                pf_corpus = f"REFERENCE_TEXT repeated, period ~{one} (PERIODIC CONTROL)"
            elif os.path.isfile(pool):
                pf_ids = lm.tokenizer.encode(open(pool, encoding="utf-8", errors="replace").read()
                                             ).to(torch.long).reshape(1, -1)
                pf_corpus = "varied pool (12 distinct docs, each once)"
            else:
                raise SystemExit(f"need {need} prefill tokens, the reference corpus holds {total}, and the varied "
                                 f"pool {pool} is missing; restore it or pass --corpus repeat explicitly")
            print(f"  prefill corpus: {pf_corpus}; {pf_ids.shape[1]} tokens available")
        n_prompt = min(772, max(64, (total - (args.jobs - 1) * 313) if args.jobs > 1 else total))
        sessions = [all_ids[:, j * 313: j * 313 + n_prompt] for j in range(args.jobs)]
        if any(x.shape[1] < 16 for x in sessions):
            raise SystemExit(f"corpus too short for {args.jobs} sessions of {n_prompt} tokens ({total} total)")
        if args.jobs > 1 and len({tuple(x[0, :32].tolist()) for x in sessions}) != len(sessions):
            raise SystemExit("session prompts collide; widen the slice stride before measuring union(N)")
        ids = sessions[0]
        n_prompt = ids.shape[1]
        # The split-module registry hangs off the CONFIG's infer_params (block_sparse_mlp_cpu.py:505), not the
        # model object - the model class differs per architecture, the config does not.
        ip = getattr(lm.model, "infer_params", None) or getattr(lm.config, "infer_params", None)
        mods = [m for m in (getattr(ip, "moe_cpu_swap_modules", None) or [])
                if m._split_hist is not None and not getattr(m, "tid2eid_key", None)]
        print(f"live trace: {os.path.basename(args.model_dir.rstrip('/'))}  layers {nl}  "
              f"prompt {n_prompt} tok  decode {args.decode}  split experts/layer {args.mcs}  "
              f"tracked layers {len(mods)}  profile {'COLD' if args.cold_start else 'warm'}")
        if not mods:
            raise SystemExit("no split modules: -mcs must be > 0 for a routing trace")

        # The snapshot-diff trace is only valid while each module's load-time permutation is STABLE: the counts
        # are stored in permuted order, so a placement swap mid-pass reorders them and a diff would attribute
        # picks to the wrong experts (inflating apparent diversity). Plain -mcs never swaps (measured: 0
        # promotions / 0 demotions over 10 sweeps); -mcpa does (3,689 promotions), so traces from pinned-arena
        # runs must be labelled, not trusted. Count the changes instead of assuming.
        perm_seen = {id(m): [tuple(getattr(m, "_split_perm", ()) or ())] for m in mods}

        def perm_changes():
            n = 0
            for m in mods:
                cur = tuple(getattr(m, "_split_perm", ()) or ())
                if cur != perm_seen[id(m)][-1]:
                    n += 1
                    perm_seen[id(m)].append(cur)
            return n

        def run(n, trace=False):
            gen = lm.generator()
            snaps = []
            prev = hist_snapshot(mods) if trace else None
            per_tok = []
            from exllamav3 import Job
            from exllamav3.generator.sampler import ArgmaxSampler
            for sess in sessions:
                gen.enqueue(Job(input_ids=sess, max_new_tokens=n, sampler=ArgmaxSampler(),
                                stop_conditions=[], return_logits=False))
            got = 0
            nperm_changes[0] = 0
            t0 = time.perf_counter()
            while gen.num_remaining_jobs():
                for r in gen.iterate():
                    if r["stage"] != "streaming" or r.get("token_ids") is None:
                        continue
                    k = len(r["token_ids"].view(-1).tolist())
                    t1 = time.perf_counter()
                    per_tok.append((t1 - t0) / max(k, 1))
                    t0 = t1
                    got += k
                    if trace:
                        nperm_changes[0] += perm_changes()
                        cur = hist_snapshot(mods)
                        # With N jobs stepping together this snapshot's diff IS the batch's expert set, so its
                        # size is a direct measurement of union(N) - no independence assumption anywhere.
                        snaps.append([[(c[i] - p[i]) if c[i] is not None and p[i] is not None else None
                                       for i in range(len(c))] for c, p in zip(cur, prev)])
                        prev = cur
            return per_tok, snaps

        # Migration counters: hot/cold swapping between the CPU arena and the GPU slots. Throughput alone cannot
        # tell "the pinned arena is slower" from "the pinned arena lets hot experts migrate up, which pays off
        # later", and the operator claim under test is specifically about migration (bench_live_trace was run
        # with and without -mcpa for exactly this reason).
        def mig_counters():
            pr = sum(getattr(m, "_split_promo_n", 0) for m in mods)
            dm = sum(getattr(m, "_split_demo_n", 0) for m in mods)
            tick = max((getattr(m, "_swap_tick_count", 0) for m in mods), default=0)
            return pr, dm, tick
        pr0, dm0, tk0 = mig_counters()

        nperm_changes = [0]
        pt, _ = run(args.decode)                      # pass A: timing only (generator: head + sampler in)
        _pt2, snaps = run(args.decode, trace=True)     # pass B: tracing only
        med = statistics.median(pt) * 1e6
        tail = sorted(pt)[int(0.9 * len(pt))] * 1e6
        print(f"  decode wall: median {med:8.1f} us/token  p90 {tail:8.1f}  -> {1e6/med:6.1f} tok/s  "
              f"= {med/nl:6.1f} us/layer (sampler + lm_head INCLUDED)")
        print(f"  (traced pass median {statistics.median(_pt2)*1e6:8.1f} us/token - the snapshot cost, for scale)")

        # Pass C: model.forward with NO generator/sampler/head, one token at a time, SYNCHRONIZED per token, on
        # the same real ids. It does NOT isolate the head cost - it came out SLOWER than the generator pass
        # (2.68: 542.8 vs 359.7 us/layer), because synchronizing every token forbids the overlap that lets the
        # generator hide the CPU expert leg behind later layers' GPU work. So the delta measures pipelining, not
        # the head: (serialized - pipelined) is what a synchronous worker design would cost per layer. The head
        # is isolated only by comparing two pipelined passes, which is what Qwen3.5's all-GPU numbers do
        # (out_engine_step.txt), since that model has no CPU leg to hide.
        cache = lm.cache if hasattr(lm, "cache") else None
        try:
            fwd = forward_only_pass(lm, ids, nl)
            print(f"  serialized forward-only (sync per token, no generator): {fwd*1e6:8.1f} us/token "
                  f"= {fwd*1e6/nl:6.1f} us/layer")
            print(f"     -> pipelining value = serialized - generator = {(fwd - med/1e6)*1e6:7.1f} us/token "
                  f"= {(fwd - med/1e6)*1e6/nl:6.1f} us/layer  (what a SYNCHRONOUS worker design pays; "
                  f"negative means the serialized pass was faster, i.e. nothing was being hidden)")
        except Exception as exc:                                    # noqa: BLE001 - report, never hide
            print(f"  model.forward-only pass FAILED ({type(exc).__name__}: {str(exc)[:90]}) - head/sampler split "
                  f"stays unmeasured for this model")

        if nperm_changes[0]:
            print(f"  WARNING: the expert permutation changed {nperm_changes[0]} times DURING the traced pass - "
                  f"the per-token sets above may attribute picks to wrong experts (diversity inflated). Traces "
                  f"are trustworthy only with a stable permutation, i.e. without -mcpa, or with swapping off.")
        if args.jobs > 1:
            sizes = [[sum(1 for v in s[L] if v and v > 0) for s in snaps] for L in range(len(mods))]
            per_layer = [statistics.median(x) for x in sizes]
            print(f"  CONCURRENT union({args.jobs}): median distinct experts touched per step, per layer - "
                  f"mean {statistics.mean(per_layer):.1f}, min {min(per_layer):.1f}, max {max(per_layer):.1f} "
                  f"(measured on live parallel streams, not modelled)")
        if args.dump_snaps:
            os.makedirs(os.path.dirname(os.path.abspath(args.dump_snaps)), exist_ok=True)
            with open(args.dump_snaps, "w") as fh:
                json.dump({"model_dir": str(args.model_dir), "decode_steps": args.decode, "jobs": args.jobs,
                           "engine_args": list(init_args), "mcpa": bool(getattr(args, "mcpa", False)),
                           "layers": [getattr(m, "name", f"layer{i}") for i, m in enumerate(mods)],
                           "steps": [[[ [i, int(v)] for i, v in enumerate(Lv) if v] for Lv in s] for s in snaps]},
                          fh)
            nz = sum(len(Lv) for s in snaps for Lv in s)
            print(f"  raw trace -> {args.dump_snaps}  ({len(snaps)} steps x {len(mods)} layers, {nz} nonzero "
                  f"(expert,delta) pairs; ~{os.path.getsize(args.dump_snaps)/1e6:.1f} MB)")
        if args.prefill:
            # One N-token prefill, timed with events, pipelined (sync only around the whole call) - the same
            # accounting the decode passes use. Chunking is the engine's business (-cs/--chunk_size); this
            # measures what the configured stack actually does with the chunk it is given.
            n = args.prefill
            if pf_ids.shape[1] < n and not args.prefill_allow_short:
                raise SystemExit(
                    f"prefill: corpus holds {pf_ids.shape[1]} tokens but {n} were requested. That is a "
                    f"measurement of a different quantity, not a smaller version of the same one (the parent's "
                    f"per-chunk fixed cost amortizes differently). Lengthen the pool, raise --reps, or use "
                    f"--prefill-allow-short to record the short number explicitly.")
            body = pf_ids[:, :n]
            if body.shape[1] < n:
                print(f"  prefill: MEASURING {body.shape[1]} TOKENS, NOT THE REQUESTED {n} "
                      f"(--prefill-allow-short). Do not table this as a {n}-token number.")
            # Membership diagnostic for the chunk: snapshot the routing histograms before the forward and diff
            # after it. A positive diff means that expert was picked by at least one token of the chunk; decay
            # wrecks the magnitudes but not membership, and membership is what decides whether a corpus is a
            # fair proxy (periodic text scores LOW here and prefills FAST, and the two move together).
            pf_pre = hist_snapshot(mods) if mods else None
            # Each pass timed separately: for -mcpa the first pass pays a CPU->GPU copy and later passes read the
            # promoted experts from VRAM, so a single number cannot answer "is it worth it" (LESSONS 66).
            passes = []
            from exllamav3 import Job
            from exllamav3.generator.sampler import ArgmaxSampler
            gen = lm.generator()
            try:
                for rep in range(max(1, args.prefill_reps)):
                    torch.cuda.synchronize()
                    t0 = time.perf_counter()
                    gen = lm.generator()
                    gen.enqueue(Job(input_ids=body, max_new_tokens=1, sampler=ArgmaxSampler(),
                                    stop_conditions=[], return_logits=False))
                    while gen.num_remaining_jobs():
                        for _ in gen.iterate():
                            pass
                    torch.cuda.synchronize()
                    dt = time.perf_counter() - t0
                    passes.append(dt)
                    if max(1, args.prefill_reps) > 1:
                        print(f"    pass {rep+1}: {dt*1000:8.1f} ms  ->  {body.shape[1]/dt:7.0f} tok/s")
                dt = passes[0] if len(passes) == 1 else statistics.median(passes)
                cov = []
                if pf_pre is not None:
                    pf_post = hist_snapshot(mods)
                    for L in range(len(mods)):
                        c, p = pf_post[L], pf_pre[L]
                        cov.append(sum(1 for i in range(len(c))
                                       if c[i] is not None and p[i] is not None and c[i] - p[i] > 0))
                tk_cfg = getattr(lm.config, "num_experts_per_tok", None) or getattr(lm.config, "topk", None)
                tag = f"median of {len(passes)}" if len(passes) > 1 else "single pass"
                print(f"  prefill {body.shape[1]} tokens [{pf_corpus}] ({tag}): {dt*1000:8.1f} ms  ->  "
                      f"{body.shape[1]/dt:7.0f} tok/s  "
                      f"({dt*1e6/(nl*body.shape[1]):6.1f} us per MoE layer per token)"
                      + (f"  [first pass {body.shape[1]/passes[0]:.0f} tok/s]" if len(passes) > 1 else ""))
                if cov:
                    cov_m = statistics.mean(cov)
                    print(f"  experts touched by this chunk: mean {cov_m:.1f} of {len(pf_pre[0])} per layer "
                          f"(min {min(cov)}, max {max(cov)})"
                          + (f"; implied rows/expert {body.shape[1]*float(tk_cfg)/cov_m:.1f}" if tk_cfg else ""))
            except Exception as exc:                                # noqa: BLE001 - report, never hide
                print(f"  prefill measurement FAILED ({type(exc).__name__}: {str(exc)[:100]})")

        pr1, dm1, tk1 = mig_counters()
        print(f"  placement migration over this pass: {pr1-pr0} promotions CPU->GPU, {dm1-dm0} demotions "
              f"GPU->CPU across {len(mods)} layers ({tk1-tk0} sweeps)")

        # --- empirical routing statistics from the per-token expert sets -------------------------------
        # `_split_hist` holds DECAYED counts (the placement sweep multiplies them down), so a per-token diff is
        # positive for picked experts and slightly NEGATIVE for unpicked ones (decay), not zero. Taking "the
        # positives" is therefore fragile; taking the largest `topk` diffs is exact, provided topk is right - so
        # topk is measured from the data (modal number of positive diffs) and printed for audit.
        pos_counts = [sum(1 for v in tl[L] if v and v > 0) for L in range(len(mods)) for tl in snaps]
        tk = statistics.mode(pos_counts)
        sel = []
        for L in range(len(mods)):
            tl = []
            for s in snaps:
                row = s[L]
                idx = [i for i in range(len(row)) if row[i] and row[i] > 0]
                idx.sort(key=lambda i: -row[i])
                tl.append(idx[:tk])
            sel.append(tl)
        E = max(len(s[L]) for L in range(len(mods)) for s in snaps)
        topk_emp = statistics.mean(len(sel[L][t]) for L in range(len(mods)) for t in range(len(snaps)))
        unions = {}
        skipped = []
        for b in (2, 4, 8, 16, 32):
            us = []
            for tl in sel:
                for s in range(0, len(tl) - b + 1, max(1, b // 2)):
                    us.append(len({e for row in tl[s:s + b] for e in row}))
            # A window wider than the traced pass has no samples; averaging an empty list used to raise
            # StatisticsError AFTER the numbers already printed, losing the whole run's JSON (--decode 8 with
            # union(32) requested). Skip it, say so, and let the caller lengthen --decode instead.
            if not us:
                skipped.append(b)
                continue
            unions[b] = statistics.mean(us)
        if skipped:
            print(f"  NOTE: union windows {skipped} skipped - only {len(snaps)} traced tokens (raise --decode "
                  f"above {max(skipped)}); their rows are absent from the JSON rather than zero")
        # concentration: how many experts cover half the picks, and the effective support
        freqs = []
        for tl in sel:
            cnt = {}
            for row in tl:
                for e in row:
                    cnt[e] = cnt.get(e, 0) + 1
            tot = sum(cnt.values())
            p = sorted((c / tot for c in cnt.values()), reverse=True)
            cum, half = 0.0, E
            for i, pi in enumerate(p):
                cum += pi
                if cum >= 0.5:
                    half = i + 1
                    break
            ent = -sum(x * math.log(x) for x in p if x > 0)
            freqs.append((half, math.exp(ent), len(p)))
        half_mean = statistics.mean(f[0] for f in freqs)
        sup_mean = statistics.mean(f[1] for f in freqs)
        seen_mean = statistics.mean(f[2] for f in freqs)
        print(f"  routing: topk observed {topk_emp:.2f} per layer-token (modal positive-diff count {tk}); "
              f"E {E}; experts covering half of picks {half_mean:.1f}; effective support exp(H) "
              f"{sup_mean:.1f}; experts ever seen {seen_mean:.1f} of {E}")
        print(f"  {'rows b':>7} {'union (measured)':>17} {'planned':>9} {'ratio':>7}")
        planned = {2: 1.99, 4: 3.88, 8: 7.27, 16: 13.12, 32: 21.91}   # distinct-expert multipliers x topk
        tk = round(topk_emp)
        # -mcpa re-permutes each module's split histogram when it promotes/demotes, so snapshot diffs attribute
        # picks to the wrong experts and the modal positive-diff count collapses to 0 (observed: a ZeroDivisionError
        # in the ratio below, AFTER the prefill timing had already printed). Skip the routing report explicitly
        # rather than printing numbers that are meaningless - the timings and migration counters stay valid.
        if tk < 1:
            print(f"  ROUTING REPORT SKIPPED: measured topk = {topk_emp:.2f} (expected ~10). Under -mcpa the "
                  f"histogram order is not stable between snapshots, so union/coverage numbers from this run "
                  f"are not evidence; prefill and decode timings above are unaffected.")
        else:
            for b, u in unions.items():
                p = planned.get(b, float("nan")) * tk
                print(f"  {b:7d} {u:17.1f} {p:9.1f} {u/p if p == p and p else float('nan'):6.2f}x")
        json.dump({"model": args.model_dir, "layers": len(mods), "E": E, "topk": tk,
                   "union_measured": unions, "half_mass_experts": half_mean,
                   "effective_support": sup_mean, "us_per_token_median": med,
                   "us_layer_forward_only_note": "sampler+lm_head included here",
                   "trace": sel},                      # FULL per-token expert sets, [layer][token][experts]
                  open(args.out, "w"))
        print(f"  full per-token expert sets ({len(mods)} layers x {len(snaps)} tokens) -> {args.out}")


if __name__ == "__main__":
    main()