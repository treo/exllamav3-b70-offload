#!/usr/bin/env python3
"""Time b70_forward through the plugin C ABI on the saved xval layer."""
import ctypes, numpy as np, sys, time, os
d = sys.argv[1] if len(sys.argv) > 1 else 'xval_s'
lib = ctypes.CDLL(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'libb70moe.so'))
lib.b70_init.restype = ctypes.c_int
lib.b70_register_layer.restype = ctypes.c_longlong
lib.b70_forward.argtypes = [ctypes.c_longlong, ctypes.c_void_p, ctypes.POINTER(ctypes.c_int32),
                            ctypes.c_void_p, ctypes.POINTER(ctypes.c_float), ctypes.c_int, ctypes.c_int]
assert lib.b70_init() == 0
meta = dict(l.split() for l in open(f'{d}/meta.txt'))
E, H, I, bits, hb = int(meta['E']), int(meta['H']), int(meta['I']), int(meta['bits']), int(meta['hb'])
keep = {}
def arr(name, dtype=np.uint16):
    a = np.fromfile(f'{d}/{name}.bin', dtype=dtype); keep[name] = a; return a
def group(pre):
    tr = (ctypes.c_uint64*E)(*[arr(f'{pre}_tr_{e}').ctypes.data_as(ctypes.c_void_p).value for e in range(E)])
    su = (ctypes.c_uint64*E)(*[arr(f'{pre}_suh_{e}', np.float16).ctypes.data_as(ctypes.c_void_p).value for e in range(E)])
    sv = (ctypes.c_uint64*E)(*[arr(f'{pre}_svh_{e}', np.float16).ctypes.data_as(ctypes.c_void_p).value for e in range(E)])
    return tr, su, sv
gt, gs, gv = group('gate'); ut, us, uv = group('up'); dt, ds, dv = group('down')
h = lib.b70_register_layer(E, H, I, bits, hb, 0, ctypes.c_float(0.0),
                           int(meta.get('gateless', '0')) == 0,
                           gt, gs, gv, None, ut, us, uv, None, dt, ds, dv, None)
x = arr('x'); sel = arr('sel', np.int32); w = arr('wts')
out = np.zeros(int(meta['rows']) * H, dtype=np.float32)
ref = np.fromfile(f'{d}/out_cpu.bin', dtype=np.float32)
xp = ctypes.cast(x.ctypes.data, ctypes.c_void_p)
wp = ctypes.cast(w.ctypes.data, ctypes.c_void_p)
sp = sel.ctypes.data_as(ctypes.POINTER(ctypes.c_int32))
op = out.ctypes.data_as(ctypes.POINTER(ctypes.c_float))
rows, topk = int(meta['rows']), int(meta['topk'])
lib.b70_forward.argtypes = [ctypes.c_longlong, ctypes.c_void_p, ctypes.POINTER(ctypes.c_int32),
                            ctypes.c_void_p, ctypes.POINTER(ctypes.c_float), ctypes.c_int, ctypes.c_int]
rc0 = lib.b70_forward(h, xp, sp, wp, op, rows, topk)
out0 = out.copy(); out[:] = 0.0
print('rms_rel vs ref', float(np.sqrt(((out0 - ref) ** 2).sum() / max((ref ** 2).sum(), 1e-30))), 'rc', rc0)
N = 300
times = []
for _ in range(N):
    t0 = time.perf_counter()
    rc = lib.b70_forward(h, xp, sp, wp, op, rows, topk)
    times.append((time.perf_counter() - t0) * 1e6)
    assert rc == 0, f'forward failed rc={rc} at {len(times)}'
times.sort()
print(f'steady {rows}-row forward: {times[N // 2]:.1f} us/call  (min {times[0]:.1f}, p90 {times[int(0.9 * N)]:.1f})')
out[:] = 0.0
lib.b70_forward(h, xp, sp, wp, op, rows, topk)
print('rms after loop', float(np.sqrt(((out - ref) ** 2).sum() / max((ref ** 2).sum(), 1e-30))))