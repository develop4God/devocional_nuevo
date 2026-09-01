#!/usr/bin/env bash
# scripts/emulator_stop.sh
#
# Stops any running emulator (qemu-system) and scrcpy processes and reports
# what was stopped. No confirmation prompt. See docs/EMULATOR.md.
#
# Usage:
#   scripts/emulator_stop.sh

set -euo pipefail

echo "Scanning for emulator/scrcpy processes..."
echo ""

PIDS=$(pgrep -f "qemu-system|scrcpy" || true)

if [ -z "$PIDS" ]; then
  echo "Nothing running. Nothing to stop."
  exit 0
fi

echo "Found the following process(es):"
echo ""
ps -o pid,etime,cmd -p $PIDS
echo ""

for PID in $PIDS; do
  CMD=$(ps -o cmd= -p "$PID" 2>/dev/null || echo "unknown")
  kill -9 "$PID" 2>/dev/null || true
  echo "Stopped PID $PID: $CMD"
done

sleep 1

STILL_RUNNING=$(pgrep -f "qemu-system|scrcpy" || true)
if [ -z "$STILL_RUNNING" ]; then
  echo ""
  echo "All emulator/scrcpy processes stopped."
else
  echo ""
  echo "Warning: some processes are still running:"
  ps -o pid,etime,cmd -p $STILL_RUNNING
fi
