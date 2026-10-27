#!/usr/bin/env python3
"""mon.py <outprefix> [seconds] — sample both cards while a benchmark runs.

  <prefix>_nv.csv   : t  gpu_sm%  gpu_mem%  rxpci_MBps  txpci_MBps     (RTX 3090, dmon 1 Hz)
  <prefix>_b70.csv  : t  cmp%  W  MHz  memBW%  pcie_rd_KBps  pcie_wr_KBps  used_MiB  (~2 Hz)

Align with `pb.py`'s PB rep lines (they print t=<epoch>). Ctrl-C / SIGTERM closes both files.
Sampling costs a little host CPU: for record timings run WITHOUT a monitor.
"""
import sys, os, json, signal, subprocess, threading, time, collections

pre = sys.argv[1]
dur = float(sys.argv[2]) if len(sys.argv) > 2 else 300.0
stop = time.time() + dur
rows_nv = []
rows_b70 = []
lock = threading.Lock()

def nvidia_loop():
    p = subprocess.Popen(["nvidia-smi", "dmon", "-s", "umt", "-d", "1", "-c", "20000"],
                         stdout = subprocess.PIPE, stderr = subprocess.DEVNULL, text = True)
    # Column layout depends on the -s flags: resolve it from the header comment lines
    # ('# gpu  sm  mem  ...  rxpci  txpci' then a units line) instead of hardcoding indices.
    cols = {}
    for line in p.stdout:
        if line.startswith("#"):
            names = line.lstrip("#").split()
            if "gpu" in names:
                cols = {n: i for i, n in enumerate(names)}
            continue
        break
    def proc(line):
        f = line.split()
        if not f or not f[0].isdigit() or "rxpci" not in cols:
            return
        try:
            rec = (time.time(),
                   float(f[cols["sm"]]) if "sm" in cols else float("nan"),
                   float(f[cols["mem"]]) if "mem" in cols else float("nan"),
                   float(f[cols["rxpci"]]), float(f[cols["txpci"]]))
        except (ValueError, IndexError):
            return
        with lock:
            rows_nv.append(rec)
    proc(line)
    for line in p.stdout:
        proc(line)
    try:
        p.kill()
    except Exception:
        pass

def xpu_once():
    try:
        out = subprocess.run(["xpu-smi", "stats", "-d", "0", "-e", "-j", "--samples", "1"],
                             stdout = subprocess.PIPE, stderr = subprocess.DEVNULL,
                             timeout = 5, text = True).stdout
        d = json.loads(out)
        u = d["utilization"]; pw = d["power"]; fr = d["frequency"]; mm = d["memory"]; pc = d["pcie"]
        return (time.time(),
                u["compute_percent"]["tile_0"],
                pw["gpu_power_w"]["tile_0"]["avg"],
                fr["gpu_frequency_mhz"]["tile_0"]["avg"],
                mm["bandwidth_percent"]["tile_0"]["avg"],
                pc["read_kbps"]["avg"], pc["write_kbps"]["avg"],
                mm["used_mib"]["tile_0"]["avg"])
    except Exception:
        return None

def write_out():
    with lock:
        with open(pre + "_nv.csv", "w") as f:
            f.write("t gpu_sm gpu_mem rxpci_MBps txpci_MBps\n")
            for r in rows_nv:
                f.write(" ".join(f"{x:.2f}" for x in r) + "\n")
        with open(pre + "_b70.csv", "w") as f:
            f.write("t b70_cmp b70_W b70_MHz b70_memBWpc b70_pcie_rd_KBps b70_pcie_wr_KBps b70_used_MiB\n")
            for r in rows_b70:
                f.write(" ".join(f"{x:.2f}" for x in r) + "\n")
    print(f"mon: wrote {len(rows_nv)} nv + {len(rows_b70)} b70 samples to {pre}_*.csv", flush = True)

def onsig(*a):
    write_out()
    os._exit(0)

signal.signal(signal.SIGTERM, onsig)
signal.signal(signal.SIGINT, onsig)

threading.Thread(target = nvidia_loop, daemon = True).start()
while time.time() < stop:
    t0 = time.time()
    rec = xpu_once()
    if rec:
        with lock:
            rows_b70.append(rec)
    time.sleep(max(0.05, 0.5 - (time.time() - t0)))
write_out()