#!/usr/bin/env python3
"""Heavy registration probe: synthetic E=256 layer (real Qwen3.8 geometry, 2bit) through
the plugin C ABI. Usage: regbench2.py <lib> [E=256] [N=6]"""
import ctypes, numpy as np, sys, os, time
lib = ctypes.CDLL(sys.argv[1])
E = int(sys.argv[2]) if len(sys.argv) > 2 else 256
NL = int(sys.argv[3]) if len(sys.argv) > 3 else 6
H, I, bits, hb = 2560, 640, 2, 0
lib.b70_init.restype = ctypes.c_int
lib.b70_register_layer.restype = ctypes.c_longlong
assert lib.b70_init() == 0
k2 = 2 * bits + hb
tri = (H // 16) * (I // 16) * 8 * k2           # u16 per gu/dn trellis
def mk(n): return np.zeros(n, dtype=np.uint16)
bufs, trs, suhs, svhs = [], [], [], []
for e in range(E):
    t = mk(tri); s1 = mk(H); s2 = mk(I)
    bufs += [t, s1, s2]; trs.append(t.ctypes.data); suhs.append(s1.ctypes.data); svhs.append(s2.ctypes.data)
def ptrs(lst): return (ctypes.c_uint64 * E)(*lst)
gt, gs, gv = ptrs(trs), ptrs(suhs), ptrs(svhs)
ut, us, uv = ptrs(trs), ptrs(suhs), ptrs(svhs)
dt, ds, dv = ptrs(trs), ptrs(suhs), ptrs(svhs)
t0 = time.perf_counter()
for ii in range(NL):
    t1 = time.perf_counter()
    h = lib.b70_register_layer(E, H, I, bits, hb, 0, ctypes.c_float(0.0), 1,
                               gt, gs, gv, None, ut, us, uv, None, dt, ds, dv, None)
    assert h >= 0, "registration failed"
    print(f"  layer {ii}: {(time.perf_counter()-t1)*1000:.0f} ms")
el = time.perf_counter() - t0
print(f"{os.path.basename(sys.argv[1])}: E={E} {NL} layers in {el*1000:.0f} ms ({el/NL*1000:.0f} ms/layer)")