# B70 decode kernels — chapter close-out (E24)

Status: **closed for GEMV/DPAS optimization.** One kernel family selected, one decision escalated, a
repeatable exactness gate in place, and a ranked handoff. This page is the summary of record; `b70-kernels.md`
§2c keeps the item-by-item history (13 → 13x) and `notes/b70/out_dpas.txt` / `out_gemv.txt` hold the raw
measurements.

## Decision record

| # | Decision | State | Basis |
|---|---|---|---|
| D1 | **Rev J (transposed tiles) is the decode kernel** for K = 2–16 | **adopted, pending D3** | 1.27–1.46× over rev I, 2.5–3.1× over rev G at every measured point; bit-exact; `out_dpas.txt` |
| D2 | **Combine stays a separate launch.** Do not fuse it into the producer with atomics | **adopted (refuted the alternative)** | fused costs +6.4…+8.4 µs gate / +13.6…+15.8 µs down; the atomic protocol alone is ~8.7 µs against 1.9 µs of saved round trip (13w) |
| D3 | **Accept the intra-tile permuted device layout** (`dword q·K+i → i·8+q`, done once at staging) | **OPEN — needs an owner** | It is what buys D1's win: same bytes, same DRAM traffic, bit-identical outputs, ~1.5 ms one-time per 512 MB, but the VRAM tensor stops being byte-identical to the checkpoint. Declining costs +27–46 % (fall back to rev I). Unmeasured: the permute kernel's throughput, and whether permuting during the parent's copy slows the ~9 GB/s transfer |
| D4 | **One expert per thread, always** (`DPAS_X=1`, equivalently `DPAS_EPT=1`) | **adopted** | Confirmed from two independent lineages: expert grid on revs G/H/I, and an `DPAS_EPT` sweep on rev J (1 → 14.0 µs, 2 → 21.1, 5 → 39.7). It is a latency requirement, not only a partial-traffic one |
| D5 | **dp4a (rev C + compile-time K) keeps exactly one niche:** layouts that cannot be permuted *and* K > 5 | **adopted** | Rev C is ~43 µs of non-byte cost against rev J's 6.2 µs above floor; ~5 instructions/weight vs 0.29 (13x). Rev I already owns the no-permute, K ≤ 5 case |
| D6 | **Epilogues must be written contraction-safe**, or device code compiled `-ffp-contract=off` | **adopted as a rule** | icpx contracts FMA by default and nothing in the repo sets it. Rev K's form (`CQ * ((float)s − DR)`, scalar differences rounded on the host) is the pattern. Existing certifications re-checked: revs I/J byte-identical with the flag off |
| D7 | **Split-K is a per-(projection, rows) dispatch parameter**, never quoted as a bare speedup | **adopted** | The same optimization measured ×1.42 at ks=1 and ×1.90 at ks=4; extra split-K now *hurts* the winning kernel |

## The number that ends the optimization chase

At rows=1, gate_proj: **14.0 µs = 437 GB/s effective** against a measured 484 GB/s stream slope and 674 GB/s
copy peak. **~90 % of achievable**, i.e. the streaming path is at the wall. Its own floor mode says the kernel
is balanced rather than dominated (`NO_MAD` 12.5 > `FETCH_ONLY` 8.9 and > `ALU_ONLY` 10.9; components sum to
21.3 vs 14.0 — ~35 % overlap). Unpack instruction count is no longer the lever.

What is left, in measured order of size:

1. **Fixed cost per projection ≈ 7.8 µs (gate) / 8.4 µs (down)** — ~24 µs of a 43.6 µs b=1 layer is launches,
   per-thread setup and the combine kernel. Attack: gate+up in one launch (E25), one combine per *layer*
   instead of per projection, cheaper per-thread setup.
2. **Bytes and locality**, now that streaming is at the wall: placement, ordering, the 18.35 GiB threshold.
3. **Routing**, if D3 is declined: it is this device's recurring tax, measured three ways — rev H's `iselect`
   cascade (+86 % when doubled), rev I's gathers (~2× better still), rev C's operand re-packing (48 % of its
   loop). Rev J escapes it because the *layout* removes it, which is the real argument for D3.

## Refuted along the way — do not re-attempt without new evidence

- "Decode is bandwidth-bound" as a design premise (true of the model from day one, true of the machine only at
  rev J); and its successor "decode is instruction-bound", true of every kernel through rev H.
- Materializing/expanded-byte operand layouts at load time (rev D), dense contiguous stores (confounded, never
  cleanly tested — item 13i), deeper trellis prefetch (null on revs F/H/I/J), in-register B via `apply`
  (`DPAS_REG=1`, bit-exact and much slower), sub-group barriers on transposed geometry (hurt),
  `NTOK < 16` single-row DPAS (rejected by the backend: minimum accumulator area), and a standalone
  legal-shape oracle for `joint_matrix` (it rejected a shape rev G runs daily — LESSONS 40).
- Loading optimizations as a rescue for the dp4a path (this page's D5; the trade is a wash by measurement).

## Known unknowns handed forward

| Item | Why it matters | Cheapest way to close it |
|---|---|---|
| Rows > 16 unmeasured | every 64–1024 token figure in the planning artifacts is clamped-to-16 and therefore optimistic | bucketed row-tiling probe, or one measurement at rows=32/64 |
| D3 pricing (permute) | decides which kernel the engine implements | time a device permute vs a straight copy; time parent-side permute during staging |
| Parent side past b=1, and attention | at low batch the parent binds again, and it is calibrated only at b=1 | parent-budget re-run at b=4/8/16 with an attention term |
| Low-E models | X/EPT=1 was validated at E=10 | one case with E=2/4 and large tn |
| Per-launch vs per-thread-share split of the 7.8 µs floor | sets the ceiling for item 1 above | extend `DPAS_FLOOR` with a no-combine, no-setup mode |
| Sustained power/thermals during decode | all rates are warm-window, not soak | harness E-items with the power monitor at duty cycle |

## How to reproduce this chapter

```bash
source /opt/intel/oneapi/setvars.sh; source notes/env.sh
notes/b70/build.sh                                   # probes, including revs I/J/K
icpx -fsycl -O2 -DGEMV_KCONST=<K> -o /tmp/pgK<K> notes/b70/probe_gemv.cpp   # one dp4a build per recipe
python3 notes/b70/dump_gemv_case.py /tmp/<case> 10 16 0 --with-reference --with-sx8 [--ckpt ... --proj ...]
python3 notes/b70/gate_dpas.py                       # 112 comparisons: dp4a/rev I/rev J/rev K, all bit-exact
python3 notes/b70/plan_decode_cost.py                # measured cost model + dispatch (rev J wins everywhere)
```

Timing discipline (violating any of these produced a wrong number somewhere in §2c): ~15–20 s sustained
warm-up before timing, round-robin interleaving of configurations, min-of-N with per-round drift reported,
absolute µs read as ±15–20 % between windows (ratios are only meaningful within one window), and no number
enters a doc unless a finished command printed it. ISA dumps need
`NEO_CACHE_PERSISTENT=0 IGC_ShaderDumpEnable=1 IGC_DumpToCustomDir=<dir>` — without the first variable the
Level-Zero shader cache means IGC never runs and the dump is silently empty.