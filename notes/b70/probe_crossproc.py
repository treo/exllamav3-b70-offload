#!/usr/bin/env python
"""
Open question 1 of doc/port/b70-architecture.md, answered: can the engine live in a *child
process* and still attach to the handoff region the parent owns?

This is the exact arrangement the port plans to use:
  parent  multiprocessing.shared_memory segment, cudaHostRegister(PORTABLE|MAPPED) - which is what
          MoeCpuHost.ensure_started does today (moe_cpu_host.py:1050, 1187)
  child   maps the same segment (its own VA, as the CPU worker does today), calls
          sycl::ext::oneapi::experimental::register_host_memory on it, and runs kernels there.

Claims checked, in the order the protocol needs them:
  X1  the child's kernel writes its own mapping; the parent sees the bytes at the *other* mapping
  X2  the parent's 3090 stream memop lands in the region and the child's kernel reads it back
  X3  the child publishes a flag with a fenced store and a 3090 cuStreamWaitValue32 retires on it
  X4  the 3090 can DMA the region the child's kernels have been writing to
  X5  two registrations of the same bytes (parent-side CUDA, child-side SYCL) do not fight

run:  source /opt/intel/oneapi/setvars.sh && source notes/env.sh && python -u probe_crossproc.py
"""
import ctypes
import multiprocessing as mp
import os
import sys
import time
from multiprocessing import shared_memory

import numpy as np
import torch

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
from exllamav3.ext import exllamav3_ext as ext                                   # noqa: E402
from exllamav3.model.model_tp_cuda import CUDA_HOST_REGISTER_MAPPED, CUDA_HOST_REGISTER_PORTABLE  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
SHIM = os.path.join(HERE, "libb70shim.so")
WORDS = 4096                 # payload words
FLAGW = WORDS                # flag word index
SIZE = 1 << 20               # region size, plenty of slack for page-rounded registration

results = []


def check(name, ok, detail=""):
    results.append((name, bool(ok)))
    print(f"  [{'PASS' if ok else 'FAIL'}] {name}{': ' + detail if detail else ''}", flush = True)


def load_shim():
    shim = ctypes.CDLL(SHIM)
    shim.b70_shim_init.restype = ctypes.c_int
    shim.b70_touch_foreign.restype = ctypes.c_int
    shim.b70_touch_foreign.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_uint]
    shim.b70_write_flag.restype = ctypes.c_int
    shim.b70_write_flag.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_uint]
    shim.b70_echo_flag.restype = ctypes.c_int
    shim.b70_echo_flag.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_ulong, ctypes.c_uint]
    shim.b70_last_error.restype = ctypes.c_char_p
    assert shim.b70_shim_init() == 0, shim.b70_last_error().decode()
    return shim


def child_main(name, size, q):
    """The engine-child stand-in: attach, register with the B70 runtime, use it, report, detach.
    Also watches two words the parent writes - one with a plain CPU store, one with a 3090 stream
    memop - to see whether *both* directions are visible across the process boundary."""
    try:
        shim = load_shim()
        shm = shared_memory.SharedMemory(name = name)
        base = shm.buf
        p = ctypes.addressof(ctypes.c_char.from_buffer(base))
        rc = shim.b70_write_flag(ctypes.c_void_p(p), WORDS, 0xBEEF)          # X1: publish from a kernel
        err1 = shim.b70_last_error().decode()
        q.put(("child", rc, err1, None, p))

        w_cpu, w_mem = FLAGW + 8, FLAGW + 16
        seen_cpu = seen_mem = 0
        deadline, polls = time.time() + 12.0, 0
        while time.time() < deadline:
            polls += 1
            seen_cpu = ctypes.c_uint32.from_address(p + w_cpu * 4).value
            seen_mem = ctypes.c_uint32.from_address(p + w_mem * 4).value
            if seen_cpu == 0xC0FFEE and seen_mem == 0x5A5A:
                break
            time.sleep(0.002)
        rc2 = shim.b70_echo_flag(ctypes.c_void_p(p), w_mem, 5000, 0)          # X2: kernel reads it back
        q.put(("child-obs", seen_cpu, seen_mem, polls, (rc2, shim.b70_last_error().decode())))
        shm.close()
    except Exception as e:                                       # noqa: BLE001
        q.put(("child-error", repr(e), None, None, None))


def main():
    mp_start = mp.get_context("spawn")
    q = mp_start.Queue()
    torch.cuda.init()
    dev = torch.device("cuda:0")

    shm = shared_memory.SharedMemory(create = True, size = SIZE)
    holder = None
    try:
        holder = ctypes.c_char.from_buffer(shm.buf)      # kept so the export can be released before close
        p = ctypes.addressof(holder)
        arr = np.frombuffer(shm.buf, dtype = np.uint32)
        arr[:] = 0
        ext.cuda_host_register(p, SIZE, CUDA_HOST_REGISTER_PORTABLE | CUDA_HOST_REGISTER_MAPPED)
        gpubase = ext.cuda_host_get_device_pointer(p)
        print(f"parent: shm={shm.name} host={p:#x} gpu={gpubase:#x} (UVA identity: {gpubase == p})")

        # re-spawn now that the name exists
        proc = mp_start.Process(target = child_main, args = (shm.name, SIZE, q), daemon = True)
        proc.start()

        tag, rc, err1, echoed, cbase = q.get(timeout = 60)
        check("X0 child attached, registered the region and ran a kernel",
              tag == "child" and rc == 0, f"tag={tag} rc={rc} err={err1!r} child_va={cbase and hex(cbase)}")
        check("X0b child maps the bytes at a different virtual address",
              cbase is not None and cbase != p, f"parent {p:#x} vs child {cbase and hex(cbase)}")

        want = [(0xC0FFEE00 + i) & 0xFFFFFFFF for i in range(4096)]
        got = arr[:WORDS].tolist()
        check("X1 child kernel's payload visible to the parent", got == want,
              f"word10={got[10]:#x} want {want[10]:#x}; flag={arr[FLAGW]:#x}")
        check("X1b flag published by the fenced store", int(arr[FLAGW]) == 0xBEEF, f"{int(arr[FLAGW]):#x}")

        # X2: CUDA stream memop writes a second flag; the child polls for it and echoes it
        arr[FLAGW + 8] = 0xC0FFEE                 # plain CPU store, parent mapping
        ext.exl3_moe_flag_write(p + (FLAGW + 16) * 4, 0x5A5A)   # 3090 stream memop
        torch.cuda.synchronize()
        time.sleep(0.05)
        print(f"  (parent view: cpu-stored word=0x{int(arr[FLAGW + 8]):x}, memop word=0x{int(arr[FLAGW + 16]):x})")
        if not proc.is_alive():
            print(f"  child died early, exitcode={proc.exitcode}")
        res = q.get(timeout = 60)
        assert res[0] == "child-obs", res
        seen_cpu, seen_mem, polls, echoed = res[1], res[2], res[3], res[4]
        print(f"  (after {polls} polls: child saw cpu-word 0x{seen_cpu:x}, memop-word 0x{seen_mem:x})")
        check("X2a parent's plain CPU store visible in the child", seen_cpu == 0xC0FFEE, f"saw 0x{seen_cpu:x}")
        check("X2b parent's 3090 stream memop visible in the child", seen_mem == 0x5A5A, f"saw 0x{seen_mem:x}")
        check("X2c a kernel in the child process reads the memop-written word back",
              echoed is not None and echoed[0] == 0 and int(arr[5000]) == 0x5A5A,
              f"echo={echoed} slot={int(arr[5000]):#x}")

        # X3: the 3090's stream waits on the flag a kernel in the *other process* published.
        # The value is already in the region (X1), so a satisfied wait proves both the cross-process
        # visibility and that cuStreamWaitValue32 accepts memory the xe driver also has mapped.
        # Deliberately no unbounded wait: arm the abort word first, then wait with a host-side
        # deadline, because a memop wait that is never satisfied parks the stream forever.
        ext.exl3_moe_flag_wait(p + FLAGW * 4, 0xBEEF, p + (FLAGW + 32) * 4)
        ev = torch.cuda.Event(); ev.record()
        t0 = time.time()
        while not ev.query() and time.time() - t0 < 5.0:
            time.sleep(0.005)
        check("X3 3090 stream wait retires on a flag published by the child's kernel", ev.query(),
              f"retired in {(time.time() - t0) * 1e3:.2f} ms")

        # X4: DMA the region the child wrote (raw memcpy, so no torch view keeps an export on the
        # mmap and blocks shm.close() afterwards)
        dst = torch.empty(WORDS, dtype=torch.uint32, device=dev)
        ext.cuda_memcpy_async(dst.data_ptr(), p, WORDS * 4, 1)          # H2D
        torch.cuda.synchronize()
        back = dst.cpu().numpy().astype(np.uint32)
        check("X4 3090 DMAs the child-written region", bool((back == np.array(want, dtype = np.uint32)).all()),
              f"word10={back[10]:#x} want {want[10]:#x}")

        proc.join(10)
        check("X5 child exited cleanly (registration released)", proc.exitcode == 0, f"exitcode={proc.exitcode}")
    finally:
        ext.cuda_host_unregister(p)
        holder = None
        import gc; gc.collect()          # numpy/torch views over shm.buf must be gone first
        try:
            shm.close()
            shm.unlink()
        except BufferError as e:
            print(f" (note: shm cleanup hit {e}; the segment leaks until the resource tracker runs)")

    bad = [n for n, ok in results if not ok]
    print(f"{len(results) - len(bad)}/{len(results)} passed")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
