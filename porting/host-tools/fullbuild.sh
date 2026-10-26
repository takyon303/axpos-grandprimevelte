#!/bin/bash
# fullbuild.sh — detached FULLBUILD runner (wall-fix loop standard, 2026-10-26).
# Replaces the ad-hoc launch lines from earlier wall relaunches. Contract:
#   log  : /tmp/opencode/fullbuild.log (out-redirected, appended)
#   final: "FULLBUILD rc=N <timestamp>" line — build-watch.sh waits for it.
#   env  : wall-#43 mke2fs conf + axp-libs + ~/.local/bin (all permanent here).
# Usage: setsid -f bash porting/host-tools/fullbuild.sh [target] &
#   (default target: bacon). Run from anywhere; it cds into the workspace.
LOG="${LOG:-/tmp/opencode/fullbuild.log}"
TARGET="${1:-bacon}"
WS=/home/anvil/Projects/axos-work
export MKE2FS_CONFIG=/home/anvil/Projects/axpos-grandprimevelte/porting/host-tools/mke2fs-1.44.conf
export LD_LIBRARY_PATH="$HOME/opt/axp-libs${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PATH="$HOME/.local/bin:$PATH"
cd "$WS" || { echo "FULLBUILD rc=99 $(date -Is)" >> "$LOG"; exit 99; }
{
echo "===== FULLBUILD launch $(date -Is) target=$TARGET"
set +e
source build/envsetup.sh
lunch lineage_grandprimevelte-userdebug
mka "$TARGET" -j4
rc=$?
echo "FULLBUILD rc=$rc $(date -Is)"
exit $rc
} >> "$LOG" 2>&1
