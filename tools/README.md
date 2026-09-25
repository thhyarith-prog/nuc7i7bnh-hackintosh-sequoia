# Tools

These are small, self-contained test tools. They are compiled on the NUC with Apple's Command Line Tools, and nothing is installed.

| File | What it does | Build |
|---|---|---|
| `smctemp.c` | Reads SMC sensors (CPU die/core temperatures) through IOKit. Read-only | `clang -O2 -framework IOKit -o smctemp smctemp.c` |
| `cpuburn.c` | `cpuburn <threads> <seconds>`: floating-point and integer load. Prints throughput every 5 s | `clang -O2 -o cpuburn cpuburn.c -lpthread` |
| `memburn.c` | `memburn <MB> <seconds>`: memcpy bandwidth, GB/s every 5 s | `clang -O2 -o memburn memburn.c` |
| `gpuburn.swift` | `gpuburn <seconds>`: Metal compute load on the iGPU, GFLOPS every 5 s | `swiftc -O -o gpuburn gpuburn.swift` |
| `monitor.sh` | Every ~5 s, writes the CPU temperature, package W, CPU/GPU MHz, GPU busy and thermal pressure to a CSV (needs `sudo` for `powermetrics`) | – |
| `run.sh` | Staged benchmark: idle → light → medium → heavy → max → recovery. Logs to `/tmp/bench` | – |

**To run it:** copy everything to `/tmp/bench`, build the programs, copy `smctemp` to `/tmp/smctemp`, then run `./run.sh`. The full run takes about 26 minutes.
