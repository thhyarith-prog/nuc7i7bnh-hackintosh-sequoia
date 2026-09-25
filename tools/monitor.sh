#!/bin/bash
# monitor.sh <outfile> : every ~5 s log epoch, stage, CPU temp, core temps, package W, CPU MHz, GPU MHz/busy, thermal pressure
OUT=$1; echo "epoch,stage,cpu_c,core1_c,core2_c,pkg_w,cpu_mhz,gpu_mhz,gpu_busy,pressure,cpu_pct" > "$OUT"
while [ ! -f /tmp/bench/STOP ]; do
  st=$(cat /tmp/bench/STAGE 2>/dev/null)
  pm=$(sudo powermetrics -n 1 -i 1500 --samplers cpu_power,gpu_power,thermal 2>/dev/null)
  w=$(echo "$pm" | awk -F': ' '/package power/{gsub("W","",$2);print $2}')
  mhz=$(echo "$pm" | awk '/System Average frequency/{gsub(/[()]/,"",$(NF-1));print $(NF-1)}')
  gf=$(echo "$pm" | awk '/GPU 0 average active frequency/{v=$NF; gsub(/[()Mhz]/,"",v); print v; exit}')
  gb=$(echo "$pm" | awk -F': ' '/GPU 0 GPU Busy/{gsub(/[% ]/,"",$2); print $2; exit}')
  pr=$(echo "$pm" | awk -F': ' '/pressure level/{print $2}')
  t=$(/tmp/smctemp); c=$(echo "$t"|awk '/TC0D/{print $4}'); c1=$(echo "$t"|awk '/TC1C/{print $4}'); c2=$(echo "$t"|awk '/TC2C/{print $4}')
  u=$(top -l 2 -n 0 -s 1 | awk '/CPU usage/{gsub("%","",$3);gsub("%","",$5);v=$3+$5} END{printf "%.1f",v}')
  echo "$(date +%s),$st,$c,$c1,$c2,$w,$mhz,$gf,$gb,$pr,$u" >> "$OUT"
  sleep 1.5
done
