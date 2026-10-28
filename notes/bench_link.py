"""Pinned->device bandwidth while the copy engine is loaded, plus the negotiated PCIe link.

    python notes/bench_link.py [mebibytes]

Explains the bandwidth probe in MoeCpuHost._ensure_stream_state (which scales the streaming
threshold EXL3_MOE_STREAM_T by sqrt(25/bw)): consumer boards frequently sit behind a chipset
link or run below their rated gen/width once the GPU is idle.
"""
import subprocess
import sys
import time

import torch

from exllamav3.model.model_tp_cuda import CUDA_HOST_REGISTER_PORTABLE, cuda_host_register


def link_state(addr="0000:0c:00.0"):
    out = []
    for f in ("current_link_speed", "current_link_width", "max_link_speed", "max_link_width"):
        try:
            out.append(f"{f}={open(f'/sys/bus/pci/devices/{addr}/{f}').read().strip()}")
        except OSError as e:
            out.append(f"{f}=({e})")
    return " ".join(out)


def main():
    mb = int(sys.argv[1]) if len(sys.argv) > 1 else 256
    nbytes = mb << 20
    src = torch.frombuffer(bytearray(nbytes), dtype = torch.int8)
    cuda_host_register(src.data_ptr(), nbytes, flags = CUDA_HOST_REGISTER_PORTABLE)
    dst = torch.empty(nbytes, dtype = torch.int8, device = "cuda")
    print("before load:", link_state())
    ev0, ev1 = torch.cuda.Event(enable_timing = True), torch.cuda.Event(enable_timing = True)
    for _ in range(2):
        dst.copy_(src, non_blocking = True)
    torch.cuda.synchronize()
    ev0.record()
    n = 8
    t0 = time.perf_counter()
    for _ in range(n):
        dst.copy_(src, non_blocking = True)
    ev1.record()
    ev1.synchronize()
    wall = (time.perf_counter() - t0) / n
    gpu = ev0.elapsed_time(ev1) / n / 1e3
    # same transfer on the compute stream vs a side stream is identical for a memcpy; report both
    print(f"H2D {mb} MiB pinned: stream time {gpu*1e3:.2f} ms = {nbytes/gpu/1e9:.1f} GB/s "
          f"(wall {wall*1e3:.2f} ms = {nbytes/wall/1e9:.1f} GB/s)")
    print("after load:", link_state())
    rev = subprocess.run(["lspci", "-s", "0c:00.0"], capture_output = True, text = True).stdout.strip()
    print("device:", rev)


if __name__ == "__main__":
    main()