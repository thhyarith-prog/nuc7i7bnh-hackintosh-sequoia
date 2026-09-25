#!/bin/bash
# wait_cool_then_run.sh : wait until the idle CPU temp stops falling (no new low for 3 min, max 20 min), then run run.sh
cd /tmp/bench; echo waitcool > STAGE; : > cooldown.log
low=999; since=0; start=$(date +%s)
while :; do
  t=$(/tmp/smctemp | awk '/TC0D/{print int($4)}'); now=$(date +%s)
  echo "$now $t" >> cooldown.log
  if [ "$t" -lt "$low" ]; then low=$t; since=$now; fi
  if [ $((now-since)) -ge 180 ]; then echo "$now STABLE low=$low" >> cooldown.log; break; fi
  if [ $((now-start)) -ge 1200 ]; then echo "$now TIMEOUT low=$low" >> cooldown.log; break; fi
  sleep 15
done
exec ./run.sh
