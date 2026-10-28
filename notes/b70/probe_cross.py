#!/usr/bin/env python
"""
Cross-vendor sharing probe: can ONE page-locked host region be written by the RTX 3090 and by
the Arc Pro B70, with the ordering the MoE handoff protocol needs?

The CPU offload rests on exactly this: the 3090 stores the payload straight into pinned memory,
the worker reads it there, and the 3090's stream waits on flags somebody else writes
(cuStreamWaitValue32). If the B70 can play the worker's role on the same bytes, the parent side
of the port is literally unchanged.

Four claims, each checked independently:
  A1  a B70 kernel reads and writes memory the CUDA driver pinned (torch pin_memory)
  A2  a value written by the 3090 (stream memop, no kernel) is visible to a B70 kernel
  A3  a value written by a B70 kernel satisfies a 3090 cuStreamWaitValue32 (the done-flag path)
  A4  memory pinned by the *B70* runtime can be registered with CUDA and used both ways

run:  source notes/env.sh && python notes/b70/probe_cross.py
"""
import ctypes
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

import numpy as np
import torch

from exllamav3.ext import exllamav3_ext as ext
from exllamav3.model.model_tp_cuda import CUDA_HOST_REGISTER_MAPPED, CUDA_HOST_REGISTER_PORTABLE

HERE = os.path.dirname(os.path.abspath(__file__))
SHIM = os.path.join(HERE, "libb70shim.so")

PORTABLE = CUDA_HOST_REGISTER_PORTABLE
MAPPED = CUDA_HOST_REGISTER_MAPPED

results = []


def check(name, ok, detail=""):
    results.append((name, bool(ok)))
    print(f"  [{'PASS' if ok else 'FAIL'}] {name}{': ' + detail if detail else ''}")


shim = ctypes.CDLL(SHIM)
shim.b70_shim_init.restype = ctypes.c_int
shim.b70_touch_foreign.restype = ctypes.c_int
shim.b70_touch_foreign.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_uint]
shim.b70_write_flag.restype = ctypes.c_int
shim.b70_write_flag.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_uint]
shim.b70_echo_flag.restype = ctypes.c_int
shim.b70_echo_flag.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_ulong, ctypes.c_uint]
shim.b70_alloc_pinned.restype = ctypes.c_void_p
shim.b70_alloc_pinned.argtypes = [ctypes.c_ulong]
shim.b70_free_pinned.argtypes = [ctypes.c_void_p]
shim.b70_fill_pinned.restype = ctypes.c_int
shim.b70_fill_pinned.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_uint]
shim.b70_last_error.restype = ctypes.c_char_p

if shim.b70_shim_init() != 0:
    print("B70 shim init failed:", shim.b70_last_error().decode())
    sys.exit(1)

torch.cuda.init()
dev = torch.device("cuda:0")
print(f"CUDA: {torch.cuda.get_device_name(0)}   B70 shim: loaded")

N = 4096
FLAG = N          # flag word index in the region below

print("== A1 B70 kernel reads/writes CUDA-pinned memory (torch pin_memory)")
t = torch.empty(N + 8192, dtype=torch.int32, pin_memory = True)   # slack so a page-rounded registration stays inside the allocation
host = t.numpy()
t.fill_(0)
host[:] = np.arange(N + 8192, dtype = np.int32)
rc = shim.b70_touch_foreign(ctypes.c_void_p(t.data_ptr()), N, 1000)
want = np.arange(N, dtype = np.int64) + 1000 + np.arange(N, dtype = np.int64)
ok = rc == 0 and np.array_equal(host[:N].astype(np.int64), want)
check("A1 B70 -> CUDA-pinned payload", ok, f"rc={rc} err={shim.b70_last_error().decode()!r} word0={host[0]} want={want[0]}")
# and the 3090 can still DMA the same region normally after the B70 touched it
g = t[:N].to(dev)
check("A1b 3090 copies the same region after the B70 wrote it",
      bool((g.cpu().numpy().astype(np.int64) == want).all()))

print("== A2 value written by the 3090 (stream memop) seen by a B70 kernel")
host[:] = 0
torch.cuda.synchronize()
ext.exl3_moe_flag_write(t.data_ptr() + FLAG * 4, 0x5A5A)     # cuStreamWriteValue32, no kernel
torch.cuda.synchronize()
rc = shim.b70_echo_flag(ctypes.c_void_p(t.data_ptr()), FLAG, 0, 0)
ok = rc == 0 and host[0] == 0x5A5A
check("A2 CUDA memop write -> B70 kernel read", ok, f"rc={rc} echoed={host[0]:#x} err={shim.b70_last_error().decode()!r}")

print("== A3 value written by a B70 kernel satisfies a 3090 stream wait")
host[FLAG] = 0
host[1:N] = 0
# n_words must equal FLAG: the shim publishes the flag word right after the payload it wrote
rc = shim.b70_write_flag(ctypes.c_void_p(t.data_ptr()), FLAG, 0x1234)
landed = (int(host[10]) & 0xFFFFFFFF) == (0xC0FFEE00 + 10)
check("A3a B70 published payload+flag", rc == 0 and host[FLAG] == 0x1234,
      f"rc={rc} flag={host[FLAG]:#x} payload_word10={host[10]:#x} landed={landed}")
# the wait is the protocol's actual primitive: GEQ compare on the *host* address (UVA)
if host[FLAG] == 0x1234:
    ext.exl3_moe_flag_wait(t.data_ptr() + FLAG * 4, 0x1234, t.data_ptr() + (FLAG + 16) * 4)
    torch.cuda.synchronize()
    check("A3b 3090 stream wait on the B70-written flag retired", True, "no hang, stream advanced")
else:
    # a memop wait has no timeout: waiting on a flag nobody wrote would hang the stream
    # (learned the hard way - this killed the first run of this probe)
    check("A3b 3090 stream wait on the B70-written flag retired", False, "skipped: flag never published")
host[FLAG] = 0
torch.cuda.synchronize()
ext.exl3_moe_flag_write(t.data_ptr() + FLAG * 4, 0x99)
ext.exl3_moe_flag_wait(t.data_ptr() + FLAG * 4, 0x99, t.data_ptr() + (FLAG + 16) * 4)
torch.cuda.synchronize()
check("A3c control: same wait satisfied by a CUDA-side write", True)

print("== A4 memory pinned by the B70 runtime registered with CUDA")
p = shim.b70_alloc_pinned(1 << 20)
if not p:
    check("A4a sycl::malloc_host", False, shim.b70_last_error().decode())
else:
    check("A4a sycl::malloc_host returns", True, f"ptr={p:#x}")
    rc = shim.b70_fill_pinned(ctypes.c_void_p(p), 1024, 7)
    arr = (ctypes.c_uint32 * 1024).from_address(p)
    ok = rc == 0 and arr[10] == 7 + 10
    check("A4b B70 kernel wrote its own pinned region", ok, f"arr[10]={arr[10]} want 17")
    try:
        ext.cuda_host_register(p, 1 << 20, PORTABLE | MAPPED)
        reg = True
    except Exception as e:
        reg = False
        check("A4c cudaHostRegister on B70-pinned memory", False, str(e)[:120])
    if reg:
        check("A4c cudaHostRegister on B70-pinned memory", True)
        try:
            gptr = ext.cuda_host_get_device_pointer(p)
            check("A4d cudaHostGetDevicePointer", True, f"gpu ptr={gptr:#x} (same as host: {gptr == p})")
        except Exception as e:
            gptr = p
            check("A4d cudaHostGetDevicePointer", False, f"{str(e)[:80]}; using host VA under UVA")
        # 3090 writes a flag there, B70 region, then a CUDA-side wait on it
        ext.exl3_moe_flag_write(gptr + 4096, 0x77)
        torch.cuda.synchronize()
        a2 = (ctypes.c_uint32 * 1).from_address(p + 4096)
        check("A4e 3090 memop write lands in the B70-pinned region", a2[0] == 0x77, f"got {a2[0]:#x}")
        # and the 3090 can read the whole region with a DMA
        dst = torch.empty(1024, dtype=torch.int32, device=dev)
        ext.cuda_memcpy_async(dst.data_ptr(), p, 4096, 1)   # H2D
        torch.cuda.synchronize()
        vals = dst.cpu().numpy()
        check("A4f 3090 DMA reads B70-pinned memory", bool((vals[:1024] == (np.arange(1024) + 7)).all()),
              f"first={vals[3]} want {3 + 7}")
        ext.cuda_host_unregister(p)

print("== summary")
bad = [n for n, ok in results if not ok]
for n, ok in results:
    print(f"  {'ok  ' if ok else 'FAIL'}  {n}")
print(f"{len(results) - len(bad)}/{len(results)} passed")
sys.exit(1 if bad else 0)