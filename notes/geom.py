"""Geometry calculator for the CPU MoE offload handoff region and the streamed-prefill ring.

Mirrors the constants in exllamav3/model/moe_cpu_host.py and exllamav3/exllamav3_ext/cpu/moe_handoff.h
(no imports from the repo, so it runs without torch/build env). Used to produce the shape tables in
doc/prep/.
"""

MOE_JOB_RING = 256
MOE_MAX_SLOTS = 8
MOE_MAX_WSLOTS = 8
MOE_JOB_MAX_EXPERTS = 256
MOE_JOB_BYTES = (7 + MOE_JOB_MAX_EXPERTS + 1) * 4
MOE_CTRL_JOBS_OFFSET = 384
MOE_SLOT_FLAGS_OFFSET = MOE_CTRL_JOBS_OFFSET + MOE_JOB_RING * MOE_JOB_BYTES
MOE_FLAGS_SIZE = 3 * 64 * MOE_MAX_SLOTS + 2 * 64 * MOE_MAX_WSLOTS
MOE_STAGE_RING = 64
MOE_STAGE_JOBS_OFFSET = MOE_SLOT_FLAGS_OFFSET + MOE_FLAGS_SIZE + 128
MOE_CTRL_SIZE = MOE_STAGE_JOBS_OFFSET + MOE_STAGE_RING * MOE_JOB_BYTES


def align64(x):
    return (x + 63) & ~63


def tile_words(K):
    """uint16 words per 16x16 tile at rate K (half-integer rates add 8)"""
    return int(16 * K) if float(16 * K).is_integer() else None


def proj_bytes(k, n, K):
    """packed trellis bytes of one projection: (k/16, n/16, 16K) int16"""
    return (k // 16) * (n // 16) * int(16 * K) * 2


def slot_geometry(cap_rows, hi, ho, topk, num_slots):
    off_x = 0
    off_sel = align64(off_x + cap_rows * hi * 2)
    off_w = align64(off_sel + cap_rows * topk * 4)
    off_out = align64(off_w + cap_rows * topk * 2)
    slot_size = align64(off_out + cap_rows * ho * 4)
    return dict(off_x=off_x, off_sel=off_sel, off_w=off_w, off_out=off_out,
                slot_size=slot_size, all_slots=num_slots * slot_size)


MODELS = {
    # name: (hidden, interm, K_expert, E, topk, layers)
    "Qwen3.8-Flash-Next @2.68 (experts 2.5bpw)": (2560, 640, 2.5, 512, 10, 48),
    "Qwen3.8-Flash-Next @2.05 (experts 2bpw)":   (2560, 640, 2.0, 512, 10, 48),
    "Qwen3.5-35B-A3B @3.17 (experts 2.5bpw)":    (2048, 512, 2.5, 256, 8, 40),
}

if __name__ == "__main__":
    print(f"control region: jobs@{MOE_CTRL_JOBS_OFFSET} ({MOE_JOB_BYTES} B/job x {MOE_JOB_RING}), "
          f"flags@{MOE_SLOT_FLAGS_OFFSET}, stage jobs@{MOE_STAGE_JOBS_OFFSET}, "
          f"MOE_CTRL_SIZE={MOE_CTRL_SIZE} B ({MOE_CTRL_SIZE/1024:.1f} KiB)")
    print()
    for name, (H, I, K, E, topk, L) in MODELS.items():
        gb = proj_bytes(H, I, K)
        ub = proj_bytes(H, I, K)
        db = proj_bytes(I, H, K)
        eb = gb + ub + db
        print(f"== {name}: H={H} I={I} K={K} E={E} topk={topk} layers={L}")
        print(f"   per-expert trellis bytes g/u/d = {gb}/{ub}/{db} -> expert block {eb} B "
              f"({eb/2**20:.3f} MiB); layer total {E*eb/2**30:.2f} GiB; all layers {E*eb*L/2**30:.1f} GiB")
        for cap_rows, slots in ((64, 4), (32, 4), (128, 4), (64, 8)):
            g = slot_geometry(cap_rows, H, H, topk, slots)
            print(f"   slot geo cap_rows={cap_rows} slots={slots}: "
                  f"x@{g['off_x']} ({cap_rows*H*2/1024:.0f} KiB) sel@{g['off_sel']} w@{g['off_w']} "
                  f"out@{g['off_out']} ({cap_rows*H*4/1024:.0f} KiB) slot_size={g['slot_size']/1024:.1f} KiB "
                  f"all={g['all_slots']/2**20:.2f} MiB")
        for wmb, batch in ((32, 24), (32, 18), (64, 24)):
            wslot = wmb * 2**20
            per_slot = min(wslot // eb, batch, MOE_JOB_MAX_EXPERTS)
            print(f"   wslot {wmb} MiB, batch_experts {batch}: experts per stage batch = {per_slot}, "
                  f"bytes/batch = {per_slot*eb/2**20:.1f} MiB, "
                  f"DMA at 50 GB/s = {per_slot*eb/50e9*1e3:.2f} ms")