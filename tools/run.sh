#!/bin/bash
# run.sh : staged stability benchmark. Logs in /tmp/bench
cd /tmp/bench; rm -f STOP; : > perf.log; echo "boot" > STAGE
./monitor.sh /tmp/bench/sensors.csv & MON=$!
stage(){ echo "$1" > STAGE; echo "$(date +%s) STAGE $1" >> perf.log; }
stage idle;      sleep 60
stage light;     ./cpuburn 1 240 | sed 's/^/light /' >> perf.log
stage cool1;     sleep 90
stage medium;    ./cpuburn 2 240 | sed 's/^/medium /' >> perf.log
stage cool2;     sleep 90
stage heavy;     ./cpuburn 4 300 | sed 's/^/heavy /' >> perf.log
stage cool3;     sleep 90
stage max;       (./cpuburn 4 300 | sed 's/^/max /' >> perf.log) & P1=$!; (./gpuburn 300 | sed 's/^/max /' >> perf.log) & P2=$!; (./memburn 1024 300 | sed 's/^/max /' >> perf.log) & P3=$!; wait $P1 $P2 $P3
stage recovery;  sleep 120
stage done; touch STOP; wait $MON; echo "$(date +%s) ALL_DONE" >> perf.log
