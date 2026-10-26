#!/usr/bin/env bash
# ROM/recovery boot watcher: captures one kmsg + logcat snapshot per boot round.
# Round classification: `round-N.cmdline` — ROM-side boot when it does NOT
# contain recovery_mode=1 (TWRP rounds carry it; the ROM never did).
# Continues round numbering after whatever already exists in the capture dir.
# Usage: bootwatch.sh [capture-dir]   (default /tmp/opencode/romboot)
set -u
DIR="${1:-/tmp/opencode/romboot}"
SER="4b137f8a21d67200"
mkdir -p "$DIR"
cd "$DIR"

last=$(ls -1 round-*.kmsg 2>/dev/null | sed 's/round-\([0-9]*\)\.kmsg/\1/' | sort -n | tail -1)
n=$(( ${last:-0} + 1 ))
echo "bootwatch: starting at round-$n $(date -Is)" >> watcher.log

while true; do
  if ! adb -s "$SER" wait-for-device 2>>watcher.log; then
    sleep 2; continue
  fi
  adb -s "$SER" shell vdc 2>/dev/null >/dev/null # no-op settle for slow adbd
  adb -s "$SER" shell cat /proc/cmdline > "round-$n.cmdline" 2>/dev/null
  adb -s "$SER" shell dmesg > "round-$n.kmsg" 2>/dev/null
  adb -s "$SER" shell logcat -d > "round-$n.logcat" 2>/dev/null
  who=rom
  grep -q "recovery_mode=1" "round-$n.cmdline" 2>/dev/null && who=rom || who=ROM
  sizes=$(stat -c%s "round-$n.kmsg" 2>/dev/null || echo 0)
  sizes="$sizes/$(stat -c%s "round-$n.logcat" 2>/dev/null || echo 0)"
  echo "round-$n: $(date -Is) who=$who bytes=$sizes" >> watcher.log
  n=$(( n + 1 ))
  # device reboots on failure; on success no new attach events arrive —
  # stay looped and re-capture rounds only if the device drops (bootloop)
  sleep 3
done
