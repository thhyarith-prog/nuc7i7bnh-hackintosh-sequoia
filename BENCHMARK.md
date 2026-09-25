# Stability benchmark (2026-09-25)

**Verdict: ✅ stable.** Across four runs there were no kernel panics, no GPU resets and no thermal throttling. The highest temperature recorded was **84 °C**, well below TjMax (100 °C). The only limit found is **power-budget throttling of the CPU when the GPU is also fully loaded** (see [Max load explained](#max-load-explained)).

- Tools: [`tools/`](tools/)
- Raw data for each run: [`benchmark/`](benchmark/). `sensors.csv` has one sample about every 5 s, and `perf.log` has throughput every 5 s.

## Contents
- [Test method](#test-method)
- [Summary of all runs](#summary-of-all-runs)
- [Run 1: no external fans (baseline)](#run-1-no-external-fans-baseline)
- [Run 2: external fans, top blowing in](#run-2-external-fans-top-blowing-in)
- [Run 3: external fans flipped, bottom blowing in](#run-3-external-fans-flipped-bottom-blowing-in)
- [Run 4: repeat of run 3 from a cold start](#run-4-repeat-of-run-3-from-a-cold-start)
- [Max load explained](#max-load-explained)
- [Findings](#findings)
- [Recommendations](#recommendations)

---

## Test method

### System state for every run
All runs were made **after the BIOS and macOS tuning** in the [README](README.md):

| Area | State |
|---|---|
| macOS | Sequoia 15.7.7, SIP on |
| Bootloader | OpenCore 1.0.6, quiet boot, 3 unused kexts off |
| BIOS | Secure Boot off, Fast Boot off, UEFI only. **Power limits left at the Intel default (PL1 / PL2 ≈ 28 W / 33 W)**. Fan mode was left at its default |
| macOS power | Sleep, standby, Power Nap and hibernation off (`pmset`) |
| macOS background | Siri, analytics and automatic update downloads off; all UI animations off |
| Thermal paste | Replaced before testing |
| Network | Ethernet. The test was run over SSH, with no GUI apps open |

### Stages

| Stage | Load | Tool | Duration |
|---|---|---|---|
| Idle | none | – | 1 min |
| Light | 1 thread | `cpuburn 1` | 4 min |
| Medium | 2 threads | `cpuburn 2` | 4 min |
| Heavy | 4 threads (every logical CPU) | `cpuburn 4` | 5 min |
| Max | 4 threads + iGPU + memory | `cpuburn 4` + `gpuburn` (Metal) + `memburn` | 5 min |
| Recovery | none | – | 2 min |

There is a 1.5 min cool-down between load stages. A full run takes about 26 minutes.

### What was measured
| Column | Source |
|---|---|
| CPU temperature (package, core 1, core 2) | SMC through IOKit (`tools/smctemp.c`) |
| Package power, CPU MHz, GPU MHz, GPU busy %, thermal pressure | `powermetrics` |
| CPU usage % (runs 3 and 4 only) | `ps`, added to `monitor.sh` after run 1 |
| CPU score | `cpuburn` operations per 5 s (higher is better) |
| GPU score | `gpuburn` GFLOPS (FP32, Metal compute) |
| Memory bandwidth | `memburn` memcpy GB/s |

> Room temperature was **not** measured. Runs 2–4 were in a warmer room (top floor, sun-heated wall) than run 1, so the real benefit of the external fans is larger than the raw numbers show.

---

## Summary of all runs

| | Run 1 | Run 2 | Run 3 | Run 4 |
|---|---|---|---|---|
| Time | 11:17 | 14:38 | 15:21 | 15:59 |
| Location | Downstairs (cooler room) | Top floor (warmer) | Top floor | Top floor |
| Case | Lid and bottom plate **on** | Lid and bottom plate **off** | Off | Off |
| External fans | **None** (a desk fan in the room) | 2 × 120 mm, top **in**, bottom **out** | 2 × 120 mm, bottom **in**, top **out** | Same as run 3 |
| Test | Full | Heavy stage only | Full | Full, started from a fully cooled idle |

**CPU temperature, average / peak (°C)**

| Stage | Run 1: no external fans | Run 2: fans top-in | Run 3: fans flipped | Run 4: fans flipped, cold start | Best vs run 1 |
|---|---|---|---|---|---|
| Idle | 46.6 / 48 | 37 | **38.8 / 43** | 38.9 / 53\* | **−8** |
| Light | 66.6 / 74 | – | **60.1 / 66** | 60.4 / 64 | **−7** |
| Medium | 78.2 / **84** | – | **66.5 / 75** | 68.2 / 76 | **−12** |
| Heavy | 76.6 / 82 | 76.1 / 79 | **73.8 / 78** | 75.6 / 82 | −3 |
| Max | 72.1 / 78 | – | **70.4 / 78** | 72.5 / 80 | −2 |
| Recovery, end | 43 | – | **40** | 41 | −3 |

\* A brief spike right at the start of the stage. The idle average is the same as run 3.

**Performance was identical in every run** (within 1%), so cooling changed temperature and power draw, not speed.

---

## Run 1: no external fans (baseline)

**Setup:** downstairs, in the cooler room. The NUC's lid and bottom plate were on, as it ships. There were **no external fans on the NUC**; a desk fan was blowing in the room. It ran on its own internal blower only. BIOS and macOS were already tuned. The stuck `rpcsvchost` service was fixed *after* this run.

Raw data: [`benchmark/run1-downstairs/`](benchmark/run1-downstairs/)

| Stage | Samples | CPU °C avg / peak (min) | Start → end °C | Package W avg (max) | CPU MHz avg (min) | GPU MHz / busy | Thermal pressure | Score |
|---|---|---|---|---|---|---|---|---|
| Idle | 12 | 46.6 / 48 (45) | 48 → 45 | 1.8 (3.0) | 1,362 (1,203) | – / 0% | Nominal | – |
| Light | 47 | 66.6 / 74 (54) | 60 → 54 | 10.4 (11.8) | 3,977 (3,338) | – / 0% | Nominal | CPU 220,272 |
| Medium | 46 | 78.2 / **84** (70) | 70 → 78 | 17.9 (18.5) | 3,900 (3,900) | – / 0% | Nominal | CPU 431,634 |
| Heavy | 56 | 76.6 / 82 (67) | 67 → 82 | 19.7 (20.1) | 3,900 (3,900) | – / 0% | Nominal | CPU 850,586 |
| Max | 52 | 72.1 / 78 (66) | 66 → 75 | 26.9 (**33.0**) | 1,016 (583) | 300 / 92% | Nominal | CPU 159,792 · GPU 1,201 GFLOPS · RAM 6.3 GB/s |
| Recovery | 23 | 49.9 / 63 (43) | 63 → 43 | 3.4 (4.7) | 1,444 (1,036) | – / 0% | Nominal | – |

**Reading:**
- Even with no extra cooling, the NUC is **stable and never throttles for heat**. It holds 3.9–4.0 GHz under every CPU-only load.
- The medium stage (2 threads) was the hottest, at **84 °C peak**. The heavy stage ran slightly cooler on average, but was still climbing at the end (82 °C), so a longer heavy load would likely go higher.
- Out of the box, the stock cooler keeps the CPU below 85 °C. That's safe, but warm for a machine that runs 24/7.

---

## Run 2: external fans, top blowing in

**Setup:** top floor (a warmer room, near the ceiling and a sun-heated wall). Lid and bottom plate **off**. Two 120 mm fans (12 V, 0.25 A, 4-pin) at 100%, powered from a 12 V SATA port: the **top fan blows in and the bottom fan blows out**. Only the heavy stage was run.

| Stage | CPU °C avg / peak | Package W | Result |
|---|---|---|---|
| Idle (before the test) | 37 | – | – |
| Heavy (5 min) | 76.1 / 79 | 17.7 | Completed with no errors |

The CPU score wasn't saved: a loose Ethernet cable dropped the SSH session during the test. The test itself completed, and the NUC didn't crash. There is no raw data folder for this run.

**Reading:** 3 °C cooler at peak than run 1 under heavy load, in a warmer room, and 2 W less power for the same work. The fan direction was then flipped for run 3.

---

## Run 3: external fans flipped, bottom blowing in

**Setup:** same place as run 2, with the fans **flipped: the bottom fan blows in, the top fan blows out**. Hot air rises, so this works with natural convection. `rpcsvchost` had been fixed by this run. CPU usage % was added to the monitor.

Raw data: [`benchmark/run3-topfloor-fans-flipped/`](benchmark/run3-topfloor-fans-flipped/)

| Stage | Samples | CPU usage | CPU °C avg / peak (min) | Start → end °C | Package W avg (max) | CPU MHz avg (min) | GPU MHz / busy | Thermal pressure | Score |
|---|---|---|---|---|---|---|---|---|---|
| Idle | 14 | 4.5% | **38.8** / 43 (38) | 39 → 38 | 2.2 (3.0) | 1,273 (1,135) | 300 / 1% | Nominal | – |
| Light | 56 | 27.4% | **60.1** / 66 (52) | 56 → 61 | 10.4 (11.4) | 3,992 (3,979) | – / 0% | Nominal | CPU 220,402 |
| Medium | 56 | 51.6% | **66.5** / 75 (53) | 56 → 53 | 15.4 (16.0) | 3,900 (3,882) | – / 0% | Nominal | CPU 432,226 |
| Heavy | 66 | 100% | **73.8** / 78 (63) | 63 → 75 | 17.6 (18.1) | 3,900 (3,900) | – / 0% | Nominal | CPU 843,951 |
| Max | 52 | 98.2% + GPU 91% | **70.4** / 78 (62) | 62 → 69 | 26.8 (33.0) | 1,161 (600) | 294 / 91% | Nominal | CPU 159,303 · GPU 1,212 GFLOPS · RAM 6.2 GB/s |
| Recovery | 27 | 3.1% | 47.5 / 64 (40) | 60 → **40** | 1.6 (2.2) | 2,199 (1,898) | – / 0% | Nominal | – |

**Reading:** the best result. **7–12 °C cooler** than run 1 at idle, light and medium load, and 3–4 °C cooler at full CPU load. Power at medium and heavy load dropped by about 2 W for the same work, because a cooler chip leaks less current.

---

## Run 4: repeat of run 3 from a cold start

**Setup:** same place and fans as run 3. Before starting, the script waited until the idle temperature stopped falling (no new low for 3 minutes; see `cooldown.log`). It settled at **37 °C** within about 30 s.

Raw data: [`benchmark/run4-topfloor-fans-flipped-cold-start/`](benchmark/run4-topfloor-fans-flipped-cold-start/)

| Stage | Samples | CPU usage | CPU °C avg / peak (min) | Start → end °C | Package W avg (max) | CPU MHz avg (min) | GPU MHz / busy | Thermal pressure | Score |
|---|---|---|---|---|---|---|---|---|---|
| Idle | 14 | 3.0% | 38.9 / 53\* (37) | 44 → 40 | 1.5 (2.1) | 2,076 (1,756) | – / 0% | Nominal | – |
| Light | 56 | 27.4% | 60.4 / 64 (52) | 55 → 61 | 10.2 (10.9) | 3,994 (3,983) | – / 0% | Nominal | CPU 220,863 |
| Medium | 56 | 51.6% | 68.2 / 76 (53) | 58 → 53 | 15.4 (16.1) | 3,899 (3,839) | – / 0% | Nominal | CPU 432,090 |
| Heavy | 67 | 98.5% | 75.6 / 82 (64) | 64 → 77 | 17.7 (18.2) | 3,900 (3,900) | – / 0% | Nominal | CPU 844,219 |
| Max | 51 | 98.8% + GPU 93% | 72.5 / 80 (66) | 66 → 74 | 27.1 (33.0) | 1,111 (583) | 300 / 93% | Nominal | CPU 159,410 · GPU 1,209 GFLOPS · RAM 6.3 GB/s |
| Recovery | 28 | 3.0% | 49.6 / 67 (41) | 67 → 41 | 1.6 (2.2) | 2,206 (1,812) | – / 0% | Nominal | – |

**Reading:** it matches run 3 within 0–2 °C, with identical performance (±0.2%), so **the results are repeatable**. Run 4 was slightly warmer under sustained load, which fits the room warming up through the afternoon. Starting from a fully cooled idle made no real difference: each stage reaches its steady temperature within 2–3 minutes anyway.

---

## Max load explained

```
time →      0s    35s   40s   45s ... 300s
CPU MHz    3500  3500  ~1900  600 ...  600
Package W    33    33    33    26 ...   26
GPU busy    97%   97%   95%   91% ...  91%
```

For about the first 35 s, the chip runs at its short-term turbo limit (PL2, ~33 W). It then drops to the sustained limit (PL1, ~26–28 W). Intel's power controller gives most of that budget to the **iGPU** and cuts the CPU to ~600 MHz. Temperatures were only 70–80 °C and thermal pressure stayed *Nominal*, so this is **power-budget throttling, not overheating**.

Everyday work (terminals, browsers, compiling, containers, AI tools) is CPU-heavy with little GPU load, and runs at the full 3.9 GHz. Only sustained combined CPU + GPU work, such as a video export or 3D alongside a CPU job, is affected.

## Findings
1. **Stable in every configuration.** No panics, GPU restarts or crash reports in any run. Thermal pressure was *Nominal* in all 700+ samples.
2. **Even without external fans (run 1), there's no thermal throttling.** The peak was 84 °C, with 16 °C of headroom.
3. **External fans, with the bottom blowing in and the top blowing out, work best:** 7–12 °C cooler at idle, light and medium load, 3–4 °C cooler at full CPU load, and about 2 W less power.
4. **Under full CPU load, the internal cooler is the limit.** External fans cool the board, RAM and SSD well, but CPU heat must still pass through the small internal heatsink and blower.
5. **Max load hits the power limit, not a thermal limit.**
6. **Performance is repeatable:** CPU scores within 1% across all runs.

## Recommendations
1. Keep the external fans with the **bottom blowing in and the top blowing out**. Add a magnetic dust filter on the intake, since the bottom plate is off.
2. **Keep the BIOS power limits at their defaults.** Lowering PL1 cuts sustained speed. Optionally raise PL1 to about 30 W to help mixed CPU + GPU work; there is thermal headroom.
3. Optional: BIOS *Fan Control Mode → Cool* for a few more degrees under sustained load.
4. For future runs, **measure the room temperature** and compare *CPU minus room* temperature. Re-run `tools/run.sh` after any hardware or BIOS change.
5. Upgrade RAM to 16–32 GB (2 × DDR4 SO-DIMM, matched pair). 8 GB is tight for a 24/7 main host.
