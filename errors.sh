#!/bin/bash
export PATH="$PATH:/home/develop4god/development/flutter/bin"
export FLUTTER_ROOT="/home/develop4god/development/flutter"

REPORT_FILE="/home/develop4god/projects/devocional_nuevo/analyze_report.txt"

echo "Flutter version:"
/home/develop4god/development/flutter/bin/flutter --version

echo ""
echo "=== ANALYZE REPORT ==="
/home/develop4god/development/flutter/bin/dart analyze 2>&1 | tee "$REPORT_FILE"
echo "=== END REPORT ==="

if grep -qE 'error|warning|info' "$REPORT_FILE"; then
    echo "ISSUES_FOUND"
    exit 1
else
    echo "CLEAN"
    exit 0
fi
