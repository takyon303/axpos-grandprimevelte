#!/usr/bin/env bash
# Snapshots (kmsg/logcat/ps/cmdline) every ~2 s while a device answers adb.
# Snap = whatever state adbd allows right now (device may be live ~minutes).
# REBOOT detection = dmesg shrank or first timestamp went backwards → copies
# the pre-death snapshot pair as reboot-N.{kmsg,cmdline} for wall analysis.
# Usage: bootwatch.sh [capture-dir]   (default /tmp/opencode/romboot)
set -u
DIR="${1:-/tmp/opencode/romboot}"
SER="4b137f8a21d67200"
mkdir -p "$DIR"
cd "$DIR"

n=$(( ${last:-120} + 1 ))
r=0
last_size=0
last_first=""
echo "bootwatch: snapshots from n=$n, reboot counter r=$r $(date -Is)" >> watcher.log

while true; do
  if ! adb -s "$SER" wait-for-device 2>>watcher.log; then
    sleep 2; continue
  fi
  adb -s "$SER" shell cat /proc/cmdline > "snap-$n.cmdline" 2>/dev/null
  adb -s "$SER" shell dmesg > "snap-$n.kmsg" 2>/dev/null
  size=$(stat -c%s "snap-$n.kmsg" 2>/dev/null || echo 0)
  first=$(head -1 "snap-$n.kmsg" 2>/dev/null | grep -o '\[ *[0-9]*\.' | head -1)
  # real reboot detection: dmesg shrank or its first timestamp went backwards
  if [ "$size" -lt "${last_size:-0}" ] || [ -n "${last_first:-}" ] && [ -n "$first" ] && \
     awk "BEGIN{exit !($first < $last_first)}" 2>/dev/null; then
    echo "$(date -Is) REBOOT detected at snap-$n (size $last_size -> $size, first $last_first -> $first)" >> watcher.log
    r=$(( r + 1 ))
    cp "snap-$n.kmsg" "reboot-$r.kmsg"; cp "snap-$n.cmdline" "reboot-$r.cmdline"
  fi
  last_size=$size
  last_first=$first
  # state snapshot (only while attached): what actually came up
  adb -s "$SER" shell "mount | grep -E ' /system| /vendor| / '; ps | grep -E 'init|zygote|adbd|logd|surfaceflinger|servicemanager|vold' | grep -v grep" > "ps-$n.txt" 2>/dev/null
  adb -s "$SER" shell logcat -d 2>/dev/null | head -100 > "logcat-$n.txt"
  n=$(( n + 1 ))
  sleep 2
done
