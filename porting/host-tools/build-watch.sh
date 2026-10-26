#!/bin/bash
# build-watch.sh — auto-notification shim for detached full builds.
#
# Why this exists: the full build must stay fully detached from the agent
# session (setsid -f; hardened after the Oct-25 SIGTERM group-kill incidents),
# so OpenCode's built-in background-command completion notification can't
# watch the build itself. Instead, attach this script as a BACKGROUND tool
# command — it only reads the log, exits when the build's terminal marker
# line appears, and the harness then notifies the agent automatically.
# No manual "check" needed anymore.
#
# Exit code mirrors the build result: 0 = build success (rc=0),
# 1 = build failure (rc=1), 2 = unknown (marker never written / no log).
#
# Usage: build-watch.sh [/path/to/fullbuild.log]
LOG="${1:-/tmp/opencode/fullbuild.log}"
[ -f "$LOG" ] || { echo "build-watch: log not found: $LOG"; exit 2; }

until grep -q "^FULLBUILD rc=" "$LOG" 2>/dev/null; do
  sleep 20
done

RC_LINE=$(grep "^FULLBUILD rc=" "$LOG" | tail -1)
RC=$(printf '%s' "$RC_LINE" | grep -oE "[0-9]+" | head -1); RC=${RC:-2}

echo "$RC_LINE"
if [ "$RC" != "0" ]; then
  echo "--- first failure context ---"
  grep -B2 -A8 "FAILED:" "$LOG" | grep -vE "^/bin/bash|^\[ [0-9]" | tail -24
fi
exit "$RC"
