"""Handoff-hop microbenchmark: each step of the decode (P1) and weight-staging paths, against a
real shared-memory segment and a worker loop running in this process (tests/testlib/moe_handoff).

    python notes/bench_handoff.py <model_dir> [--layer 7] [--experts 128] [--threads 15]

Sections (comma-list to skip with --skip):
  flags     host/GPU flag write + wait: enqueue cost and cross-direction visibility
  copies    pinned D2H / H2D of the slot payload at several row counts
  loop      end-to-end fused issue -> worker compute -> collect (serial: the full cost of a layer)
  empty     same with an all -1 selection (payload and readback skipped)
  stage     STAGE job: worker memcpy of N experts into a pinned slot, then the H2D DMA
  unswizzle moe_unswizzle_trellis over a full staged batch
"""
import argparse
import json
import os
import sys
import time

import numpy as np
import torch

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "tests"))

from exllamav3.ext import exllamav3_ext as ext                       # noqa: E402
from exllamav3.loader.safetensors import SafetensorsCollection       # noqa: E402
from testlib.moe import repack_trellis                               # noqa: E402
from testlib.moe_handoff import (Segment, MOE_CTRL_SIZE, QUIT, JOBS_TAIL, JOBS_HEAD, DATA_READY,
                                 DONE, CONSUMED, STAGE_DONE, PINNED_FREE, MOE_STAGE_TAIL_OFFSET,
                                 MOE_STAGE_HEAD_OFFSET)              # noqa: E402


def wall(f, n = 200, warm = 20):
    for _ in range(warm):
        f()
    t0 = time.perf_counter()
    for _ in range(n):
        f()
    return (time.perf_counter() - t0) / n


def rate_of(width):
    k, rem = divmod(width, 16)
    return k if rem == 0 else (k + 0.5 if rem == 8 else None)


def load_layer(model_dir, layer, n_experts):
    cfg = json.load(open(os.path.join(model_dir, "config.json")))
    tc = cfg.get("text_config", cfg)
    H, I, E_all = tc["hidden_size"], tc["moe_intermediate_size"], tc["num_experts"]
    topk = tc["num_experts_per_tok"]
    stc = SafetensorsCollection(model_dir)
    cpu = torch.device("cpu")
    pref = None
    for cand in (f"model.language_model.layers.{layer}.mlp.experts", f"layers.{layer}.mlp.experts"):
        if f"{cand}.0.up_proj.trellis" in stc.tensor_file_map:
            pref = cand
            break
    E = min(n_experts, E_all)

    def get(e, proj, suf):
        return stc.get_tensor(f"{pref}.{e}.{proj}_proj.{suf}", cpu)

    cols, su, sv = {"g": [], "u": [], "d": []}, {"g": [], "u": [], "d": []}, {"g": [], "u": [], "d": []}
    for e in range(E):
        for proj, c in (("gate", "g"), ("up", "u"), ("down", "d")):
            t = get(e, proj, "trellis")
            K = rate_of(t.shape[2])
            grp = ext.exl3_moe_cpu_swizzle_group(K)
            pln = bool(grp and ext.exl3_moe_cpu_planar_layout(K))
            cols[c].append(repack_trellis(t, grp, pln).contiguous())
            su[c].append(get(e, proj, "suh").contiguous())
            sv[c].append(get(e, proj, "svh").contiguous())
    handle = ext.exl3_moe_cpu_make_layer(
        cols["g"], su["g"], sv["g"], cols["u"], su["u"], sv["u"], cols["d"], su["d"], sv["d"],
        [], [], [], 0, 0.0, 1)
    dims = {c: (cols[c][0].shape[0] * 16, cols[c][0].shape[1] * 16, rate_of(cols[c][0].shape[2]))
            for c in "gud"}
    exp_b = sum(t.numel() * 2 for c in "gud" for t in cols[c][0:1])
    return dict(handle = handle, H = H, I = I, E = E, topk = topk, dims = dims, exp_b = exp_b)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("model_dir")
    ap.add_argument("--layer", type = int, default = 7)
    ap.add_argument("--experts", type = int, default = 128)
    ap.add_argument("--threads", type = int, default = 15)
    ap.add_argument("--stage_threads", type = int, default = 4)
    ap.add_argument("--cap_rows", type = int, default = 64)
    ap.add_argument("--slots", type = int, default = 4)
    ap.add_argument("--wslots", type = int, default = 2)
    ap.add_argument("--wslot_mb", type = int, default = 32)
    ap.add_argument("--skip", default = "")
    a = ap.parse_args()
    skip = set(a.skip.split(","))

    L = load_layer(a.model_dir, a.layer, a.experts)
    H, topk, E = L["H"], L["topk"], L["E"]
    dev = torch.device("cuda")
    torch.cuda.init()
    seg = Segment(a.slots, a.cap_rows, H, H, topk, a.wslots, a.wslot_mb * 2**20)
    seg.register()
    ext.exl3_moe_cpu_set_memops(os.environ.get("NO_MEMOPS", "0") != "1")
    seg.start(threads = a.threads, stage_threads = a.stage_threads)
    print(f"# layer {a.layer}: H={H} I={L['I']} K={L['dims']['u'][2]} E={L['E']} topk={topk} "
          f"expert={L['exp_b']/2**20:.3f} MiB | slots={a.slots} cap_rows={a.cap_rows} "
          f"slot={seg.slot_size/1024:.1f} KiB region={seg.size/2**20:.1f} MiB "
          f"memops={os.environ.get('NO_MEMOPS','0') != '1'} threads={a.threads}")

    def sptr(slot, name):
        return seg.dev_base + MOE_CTRL_SIZE + slot * seg.slot_size + {
            "x": seg.off_x, "sel": seg.off_sel, "w": seg.off_w, "out": seg.off_out}[name]

    # ---------------------------------------------------------------- flags
    if "flags" not in skip:
        w_enq = wall(lambda: ext.exl3_moe_flag_write(seg.dev_base + DATA_READY, 1), n = 5000) * 1e6
        torch.cuda.synchronize()
        t_enq = wall(lambda: ext.exl3_moe_flag_wait(seg.dev_base + DATA_READY, 1, seg.dev_base + 128),
                     n = 5000) * 1e6
        torch.cuda.synchronize()
        print(f"flags: host enqueue: write {w_enq:.2f} us, satisfied wait {t_enq:.2f} us")
        # Ping-pong: host lifts A, stream (parked on A) lifts B, host polls B. One round trip
        # of both directions plus the memop dispatch, which is the handshake's real cost
        def pingpong(settle):
            seg.set_flag(DATA_READY, 3, 0)
            seg.set_flag(DONE, 3, 0)
            torch.cuda.synchronize()
            time.sleep(settle)
            t0 = time.perf_counter()
            ext.exl3_moe_flag_wait(seg.dev_base + DATA_READY + 3 * 64, 1, seg.dev_base + 128)
            ext.exl3_moe_flag_write(seg.dev_base + DONE + 3 * 64, 1)
            seg.set_flag(DATA_READY, 3, 1)
            while seg.flag(DONE, 3) != 1:
                if time.perf_counter() - t0 > 2.0:
                    raise TimeoutError("ping-pong stuck")
            return (time.perf_counter() - t0) * 1e6
        for settle in (0.0, 0.002):
            pp = [pingpong(settle) for _ in range(200)]
            print(f"flags: handshake round trip (stream idle {settle*1e3:.0f} ms beforehand): "
                  f"med {np.median(pp):.1f} us p90 {np.percentile(pp, 90):.1f} us "
                  f"max {max(pp):.1f} us")
        # GPU writes, host polls: visibility
        vis = []
        for i in range(100):
            seg.set_flag(DONE, 0, 0)
            torch.cuda.synchronize()
            t0 = time.perf_counter()
            ext.exl3_moe_flag_write(seg.dev_base + DONE, 5)
            while seg.flag(DONE, 0) != 5:
                pass
            vis.append((time.perf_counter() - t0) * 1e6)
        print(f"flags: GPU write -> host sees it (incl. enqueue+launch): med {np.median(vis):.1f} us "
              f"p90 {np.percentile(vis, 90):.1f} us")

    # ---------------------------------------------------------------- copies
    if "copies" not in skip:
        def gpu_time(f, n = 50):
            ev0, ev1 = torch.cuda.Event(enable_timing = True), torch.cuda.Event(enable_timing = True)
            for _ in range(3):
                f()
            torch.cuda.synchronize()
            ev0.record()
            for _ in range(n):
                f()
            ev1.record()
            torch.cuda.synchronize()
            return ev0.elapsed_time(ev1) / n * 1e3      # us

        for rows in sorted({1, 4, 16, 32, a.cap_rows}):
            if rows > a.cap_rows:
                continue
            y = torch.randn(rows, H, dtype = torch.half, device = dev)
            xf = torch.empty(rows, H, dtype = torch.float, device = dev)
            sx, so = seg.section(0, "x")[:rows], seg.section(0, "out")[:rows]
            t1 = gpu_time(lambda: sx.copy_(y, non_blocking = True))
            t2 = gpu_time(lambda: xf.copy_(so, non_blocking = True))
            e1 = wall(lambda: sx.copy_(y, non_blocking = True), n = 2000) * 1e6
            print(f"copies rows={rows:3d}: D2H {rows*H*2/1024:6.0f} KiB stream {t1:6.1f} us "
                  f"({rows*H*2/(t1*1e-6)/1e9:5.1f} GB/s), enqueue {e1:4.1f} us | H2D "
                  f"{rows*H*4/1024:6.0f} KiB stream {t2:6.1f} us ({rows*H*4/(t2*1e-6)/1e9:5.1f} GB/s)")
        big = torch.empty(64 << 20, dtype = torch.int8, device = dev)
        pb = torch.frombuffer(bytearray(64 << 20), dtype = torch.int8)
        t = gpu_time(lambda: big.copy_(pb, non_blocking = True), n = 20)
        t2 = gpu_time(lambda: pb.copy_(big, non_blocking = True), n = 20)
        print(f"reference pinned H2D 64 MiB: {t:.0f} us ({(64<<20)/(t*1e-6)/1e9:.1f} GB/s); "
              f"D2H {t2:.0f} us ({(64<<20)/(t2*1e-6)/1e9:.1f} GB/s)")

    # ---------------------------------------------------------------- decode loop
    state = {"seq": 0}

    def make_job(rows, slot, vals, y, selt, wt, cnt):
        state["seq"] += 1
        n = state["seq"]
        ok = ext.exl3_moe_split_issue_fused(
            seg.base, n, L["handle"], rows, topk, slot, state.get("last_seq", {}).get(slot, 0),
            selt, None, None, y, wt, sptr(slot, "sel"), sptr(slot, "x"), sptr(slot, "w"),
            cnt, H, 0, seg.dev_base + DATA_READY + slot * 64,
            seg.dev_base + CONSUMED + slot * 64, seg.dev_base + 128)
        assert ok, "job ring full"
        state.setdefault("last_seq", {})[slot] = n
        return n

    if not ({"loop", "empty"} <= skip):
        rng = np.random.default_rng(11)
        for rows in (1, 2, 4, 8, 16, 32):
            slot = 0
            vals = rng.integers(0, E, size = (rows, topk))
            y = torch.randn(rows, H, dtype = torch.half, device = dev)
            selt = torch.from_numpy(vals).long().to(dev).reshape(-1).contiguous()
            wt = (torch.rand(rows, topk, device = dev) + 0.1).half().contiguous()
            cnt = torch.zeros(a.slots, dtype = torch.int32, device = dev)
            fin = torch.zeros(rows, H, dtype = torch.float, device = dev)
            n = make_job(rows, slot, selt, y, selt, wt, cnt)
            ext.exl3_moe_split_collect_fused(fin, sptr(slot, "out"), cnt, slot, H,
                                             seg.dev_base + DONE + slot * 64, n,
                                             seg.dev_base + CONSUMED + slot * 64, seg.dev_base + 128)
            torch.cuda.synchronize()
            def collect(nn, slot, cnt, fin):
                ext.exl3_moe_split_collect_fused(fin, sptr(slot, "out"), cnt, slot, H,
                                                 seg.dev_base + DONE + slot * 64, nn,
                                                 seg.dev_base + CONSUMED + slot * 64,
                                                 seg.dev_base + 128)

            def pair():
                nn = make_job(rows, slot, selt, y, selt, wt, cnt)
                collect(nn, slot, cnt, fin)

            if "loop" not in skip:
                # host-side enqueue cost of both calls, in steady state (no sync inside)
                enq = []
                for i in range(100):
                    t0 = time.perf_counter()
                    pair()
                    enq.append((time.perf_counter() - t0) * 1e6)
                torch.cuda.synchronize()
                seg.wait(CONSUMED, slot, state["seq"])
                # fully serial: one layer's whole round trip, nothing else in flight
                tot = []
                for i in range(100):
                    t0 = time.perf_counter()
                    pair()
                    torch.cuda.synchronize()
                    tot.append((time.perf_counter() - t0) * 1e6)
                # stream-time split of one serial layer
                ev0, ev1, ev2 = (torch.cuda.Event(enable_timing = True) for _ in range(3))
                ev0.record()
                nn = make_job(rows, slot, selt, y, selt, wt, cnt)
                ev1.record()
                collect(nn, slot, cnt, fin)
                ev2.record()
                torch.cuda.synchronize()
                # pipelined: 48 layers back to back (one decode step of a 48-layer model),
                # one sync at the end: what the worker's throughput costs per layer
                pip = []
                for k in range(20):
                    t0 = time.perf_counter()
                    for i in range(48):
                        pair()
                    torch.cuda.synchronize()
                    pip.append((time.perf_counter() - t0) * 1e6 / 48)
                print(f"loop rows={rows:3d}: host enqueue issue+collect {np.median(enq):6.1f} us | "
                      f"serial layer med {np.median(tot):7.1f} us p90 {np.percentile(tot,90):7.1f} | "
                      f"stream issue {ev0.elapsed_time(ev1)*1e3:6.1f} us collect "
                      f"{ev1.elapsed_time(ev2)*1e3:7.1f} us | 48-layer pipeline {np.median(pip):7.1f} "
                      f"us/layer (experts {len(set(np.array(vals).reshape(-1)))}/{E})")
            if "empty" not in skip:
                s2 = torch.full((rows * topk,), -1, dtype = torch.long, device = dev)

                def epair():
                    nn = make_job(rows, slot, s2, y, s2, wt, cnt)
                    collect(nn, slot, cnt, fin)

                tot = []
                for i in range(200):
                    t0 = time.perf_counter()
                    epair()
                    torch.cuda.synchronize()
                    tot.append((time.perf_counter() - t0) * 1e6)
                pip = []
                for k in range(20):
                    t0 = time.perf_counter()
                    for i in range(48):
                        epair()
                    torch.cuda.synchronize()
                    pip.append((time.perf_counter() - t0) * 1e6 / 48)
                print(f"empty rows={rows:3d}: serial layer med {np.median(tot):7.1f} us "
                      f"p90 {np.percentile(tot,90):7.1f} | 48-layer pipeline {np.median(pip):7.1f} us/layer")

    # ---------------------------------------------------------------- staging
    if "stage" not in skip:
        per_slot = min(a.wslot_mb * 2**20 // L["exp_b"], 256, E)
        for nexp in (1, 6, per_slot):
            ids = list(range(nexp))
            ws = 0
            seq = int(seg.word(MOE_STAGE_TAIL_OFFSET)) + 1
            seg.push_stage(seq, L["handle"], ids, ws, prev_seq = 0)
            t_memcpy = []
            t_dma = []
            sseq = seq
            rg = np.random.default_rng(3)
            used = (nexp * L["exp_b"]) // 2
            dst = torch.empty(used, dtype = torch.int16, device = dev)
            wview = torch.frombuffer(seg.shm.buf, dtype = torch.int16, count = a.wslot_mb * 2**20 // 2,
                                     offset = seg.wstage_off + ws * a.wslot_mb * 2**20)
            for i in range(40):
                ids = [int(x) for x in rg.integers(0, E, size = nexp)]
                sseq += 1
                t0 = time.perf_counter()
                seg.push_stage(sseq, L["handle"], ids, ws, prev_seq = 0)
                seg.wait(STAGE_DONE, ws, sseq)
                t_memcpy.append((time.perf_counter() - t0) * 1e6)
                ev0, ev1 = torch.cuda.Event(enable_timing = True), torch.cuda.Event(enable_timing = True)
                torch.cuda.synchronize()
                ev0.record()
                dst.copy_(wview[:used], non_blocking = True)
                ev1.record()
                ev1.synchronize()
                t_dma.append(ev0.elapsed_time(ev1) * 1e3)
            b = nexp * L["exp_b"]
            print(f"stage n={nexp:3d} ({b/2**20:6.1f} MiB): worker memcpy med "
                  f"{np.median(t_memcpy):8.1f} us ({b/np.median(t_memcpy)/1e3:5.1f} GB/s, "
                  f"{a.stage_threads} threads) | pinned->VRAM DMA med {np.median(t_dma):8.1f} us "
                  f"({b/np.median(t_dma)/1e3:5.1f} GB/s)")

    # ---------------------------------------------------------------- unswizzle
    if "unswizzle" not in skip:
        k, n, K = L["dims"]["u"]
        per_slot = min(a.wslot_mb * 2**20 // L["exp_b"], 256, E)
        nexp = per_slot
        src = torch.randint(-30000, 30000, (nexp * L["exp_b"] // 2,), dtype = torch.int16, device = dev)
        dst = torch.empty_like(src)
        grp = ext.exl3_moe_cpu_swizzle_group(K)
        pln = int(bool(grp and ext.exl3_moe_cpu_planar_layout(K)))
        gb = L["dims"]["g"][0] // 16 * (L["dims"]["g"][1] // 16) * int(16 * L["dims"]["g"][2]) * 2
        for proj in ("g", "u", "d"):
            kk, nn, KK = L["dims"][proj]
            off = 0 if proj == "g" else (gb if proj == "u" else
                                         gb + L["dims"]["u"][0] // 16 * (L["dims"]["u"][1] // 16) * int(16 * L["dims"]["u"][2]) * 2)
            g = ext.exl3_moe_cpu_swizzle_group(KK)
            p = int(bool(g and ext.exl3_moe_cpu_planar_layout(KK)))
            f = lambda: ext.moe_unswizzle_trellis(src, dst, nexp, L["exp_b"], off, kk // 16, nn // 16,
                                                  KK, g, p)
            t = wall(lambda: (f(), torch.cuda.synchronize()), n = 100)
            b = nexp * (kk // 16) * (nn // 16) * int(16 * KK) * 2
            print(f"unswizzle {proj}: {nexp} experts {b/2**20:6.1f} MiB r+w, group={g} planar={p}: "
                  f"{t*1e6:7.1f} us ({2*b/t/1e9:5.1f} GB/s effective)")

    seg.set_word(QUIT, 1)
    time.sleep(0.05)
    seg.stop()


if __name__ == "__main__":
    main()