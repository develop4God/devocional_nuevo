#!/bin/bash
# errors.sh - Run formatting, analysis, and report issues
# CONTINGENCY: Always run via background terminal + get_terminal_output
#   id = run_in_terminal("bash errors.sh 2>&1; echo EXIT=$?", isBackground=true)
#   get_terminal_output(id)

set -e

FLUTTER="/home/develop4god/development/flutter/bin/flutter"
DART="/home/develop4god/development/flutter/bin/dart"
REPORT_FILE="/home/develop4god/projects/devocional_nuevo/analyze_report.txt"
PROJECT="/home/develop4god/projects/devocional_nuevo"

echo "=== WORKSPACE: $PROJECT ==="
echo "=== DATE: $(date) ==="
echo ""

echo "--- Flutter version ---"
"$FLUTTER" --version 2>&1 | head -3
echo ""

echo "--- dart format ---"
"$DART" format "$PROJECT" --set-exit-if-changed 2>&1
FORMAT_EXIT=$?
echo "FORMAT_EXIT=$FORMAT_EXIT"
echo ""

echo "--- dart analyze ---"
"$DART" analyze "$PROJECT" 2>&1 | tee "$REPORT_FILE"
ANALYZE_EXIT=${PIPESTATUS[0]}
echo "ANALYZE_EXIT=$ANALYZE_EXIT"
echo ""

echo "--- Grep: errors / warnings / infos ---"
grep -E 'error|warning|info' "$REPORT_FILE" || echo "(none found)"
echo ""

if grep -qE 'error|warning|info' "$REPORT_FILE"; then
    echo "RESULT=ISSUES_FOUND"
    exit 1
else
    echo "RESULT=CLEAN"
    exit 0
fi