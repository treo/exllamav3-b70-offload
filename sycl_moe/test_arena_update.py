#!/usr/bin/env python3
"""Numerical test of the arena in-place install path (b70_update_expert) via the C ABI.

Uses the saved xval_s layer (E=12, 2bit, rows=1, deterministic float tier):
  T1 idempotence: rewrite every expert with its OWN bytes -> forward must be bit-equal.
  T2 mapping: install expert 7's bytes into slot 3 -> forward that routes to 3 must be
     bit-equal to the baseline forward routing the same input row to 7 (only the sel id
     changes). Catches any block-e/index-0 confusion in the update path.
  T3 fan-out: install expert 0's bytes into ALL slots -> a forward routing everything to
     expert 5 must equal the baseline forward routing everything to expert 0.
Usage: test_arena_update.py [xval_dir=../xval_s]"""
import ctypes, numpy as np, sys, os
d = sys.argv[1] if len(sys.argv) > 1 else '../xval_s'
lib = ctypes.CDLL(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'libb70moe.so'))
lib.b70_init.restype = ctypes.c_int
lib.b70_register_layer.restype = ctypes.c_longlong
lib.b70_update_expert.restype = ctypes.c_int
lib.b70_update_expert.argtypes = [ctypes.c_longlong, ctypes.c_int] + [ctypes.c_uint64] * 12
lib.b70_forward.argtypes = [ctypes.c_longlong, ctypes.c_void_p, ctypes.POINTER(ctypes.c_int32),
                            ctypes.c_void_p, ctypes.POINTER(ctypes.c_float), ctypes.c_int, ctypes.c_int]
assert lib.b70_init() == 0
meta = dict(l.split() for l in open(f'{d}/meta.txt'))
E, H, I, bits, hb = int(meta['E']), int(meta['H']), int(meta['I']), int(meta['bits']), int(meta['hb'])
keep = {}
def arr(name, dtype=np.uint16):
    a = np.fromfile(f'{d}/{name}.bin', dtype=dtype); keep[name] = a.copy(); return a
T, SU, SV = [], [], []          # per-expert arrays
for pre in ('gate', 'up', 'down'):
    T.append([arr(f'{pre}_tr_{e}') for e in range(E)])
    SU.append([arr(f'{pre}_suh_{e}', np.float16) for e in range(E)])
    SV.append([arr(f'{pre}_svh_{e}', np.float16) for e in range(E)])
def ptrs(lst): return (ctypes.c_uint64 * E)(*[a.ctypes.data for a in lst])
gT, gS, gV = ptrs(T[0]), ptrs(SU[0]), ptrs(SV[0])
uT, uS, uV = ptrs(T[1]), ptrs(SU[1]), ptrs(SV[1])
dT, dS, dV = ptrs(T[2]), ptrs(SU[2]), ptrs(SV[2])
h = lib.b70_register_layer(E, H, I, bits, hb, 0, ctypes.c_float(0.0), int(meta.get('gateless','0')) == 0,
                           gT, gS, gV, None, uT, uS, uV, None, dT, dS, dV, None)
assert h >= 0
x = arr('x'); sel_all = arr('sel', np.int32); w = arr('wts')
def forward(row, e):
    """rows=1, topk=1: token 'row' of x through expert e, routing weight 1.0"""
    xp = ctypes.c_void_p(x.ctypes.data + row * H * 2)
    wp = ctypes.c_void_p(w.ctypes.data)                     # weight[0] = first fp16
    sel = np.array([e], dtype=np.int32)
    out = np.zeros(H, dtype=np.float32)
    rc = lib.b70_forward(h, xp, sel.ctypes.data_as(ctypes.POINTER(ctypes.c_int32)), wp,
                         out.ctypes.data_as(ctypes.POINTER(ctypes.c_float)), 1, 1)
    assert rc == 0, f"forward rc {rc}"
    return out
def call_update(slot, src):
    """install expert `src`'s current host bytes into device slot `slot`"""
    gp = [(ctypes.c_uint64 * 1)(T[0][src].ctypes.data), (ctypes.c_uint64 * 1)(SU[0][src].ctypes.data),
          (ctypes.c_uint64 * 1)(SV[0][src].ctypes.data), (ctypes.c_uint64 * 1)(0)]
    up = [(ctypes.c_uint64 * 1)(T[1][src].ctypes.data), (ctypes.c_uint64 * 1)(SU[1][src].ctypes.data),
          (ctypes.c_uint64 * 1)(SV[1][src].ctypes.data), (ctypes.c_uint64 * 1)(0)]
    dn = [(ctypes.c_uint64 * 1)(T[2][src].ctypes.data), (ctypes.c_uint64 * 1)(SU[2][src].ctypes.data),
          (ctypes.c_uint64 * 1)(SV[2][src].ctypes.data), (ctypes.c_uint64 * 1)(0)]
    # C expects uint64_t ARRAYS (one entry); pass the ADDRESS of each array, not the
    # tensor pointer stored inside it
    a = [ctypes.addressof(v) for v in gp + up + dn]
    return lib.b70_update_expert(h, slot, *a)
row = 0
base3, base7, base0, base5 = (forward(row, e) for e in (3, 7, 0, 5))
# T1: rewrite every expert with its own bytes (host arrays untouched), outputs must not move
for e in range(E):
    assert call_update(e, e) == 0, f"update {e} failed"
ok1 = all(np.array_equal(forward(row, e), b) for e, b in ((3, base3), (7, base7), (0, base0), (5, base5)))
# T2: slot 3 := expert 7 bytes -> routed-to-3 equals baseline routed-to-7
assert call_update(3, 7) == 0
ok2 = np.array_equal(forward(row, 3), base7)
# T3: all slots := expert 0 bytes -> routed-to-5 equals baseline routed-to-0
for e in range(E):
    assert call_update(e, 0) == 0
ok3 = np.array_equal(forward(row, 5), base0)
print(f"T1 idempotent reinstall : {'PASS' if ok1 else 'FAIL'}")
print(f"T2 slot-gets-src mapping: {'PASS' if ok2 else 'FAIL'}")
print(f"T3 fan-out overwrite    : {'PASS' if ok3 else 'FAIL'}")
sys.exit(0 if (ok1 and ok2 and ok3) else 1)