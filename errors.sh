#!/bin/bash
# errors.sh - Run formatting, analysis, and grep for errors, warnings, and info

set -e

export PATH="$PATH:/home/develop4god/development/flutter/bin"
export FLUTTER_ROOT="/home/develop4god/development/flutter"
REPORT_FILE="/home/develop4god/projects/devocional_nuevo/analyze_report.txt"

echo "Flutter version:"
/home/develop4god/development/flutter/bin/flutter --version
echo ""

echo "Running dart format..."
/home/develop4god/development/flutter/bin/dart format .
echo ""

echo "=== ANALYZE REPORT ==="
/home/develop4god/development/flutter/bin/flutter analyze --fatal-infos 2>&1 | tee "$REPORT_FILE"
echo "=== END REPORT ==="
echo ""

echo "Grep for errors, warnings, and info in analysis output..."
grep -E 'error|warning|info' "$REPORT_FILE" || true

if grep -qE 'error|warning|info' "$REPORT_FILE"; then
    echo "ISSUES_FOUND"
    exit 1
else
    echo "CLEAN"
    exit 0
fi