#!/bin/bash
export PATH="$PATH:/home/develop4god/development/flutter/bin"
export FLUTTER_ROOT="/home/develop4god/development/flutter"

OUTPUT=$(/home/develop4god/development/flutter/bin/dart analyze 2>&1)

echo "=== ANALYZE REPORT ==="
echo "$OUTPUT"
echo "=== END REPORT ==="

if echo "$OUTPUT" | grep -qE 'error|warning|info'; then
    echo "ISSUES_FOUND"
    exit 1
else
    echo "CLEAN"
    exit 0
fi