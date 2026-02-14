#!/usr/bin/env bash
# Simple Flutter/Dart checker: format -> fix -> analyze
# Shows all output in terminal, stops on first failure

set -e  # Exit on any command failure

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "================================================"
echo "Flutter Check - $(date '+%Y-%m-%d %H:%M:%S')"
echo "Project: $PROJECT_ROOT"
echo "================================================"

cd "$PROJECT_ROOT"

# Step 1: Format
echo ""
echo "▶ Running: dart format ."
echo "------------------------------------------------"
dart format .
echo "✓ Format complete"

# Step 2: Fix
echo ""
echo "▶ Running: dart fix --apply"
echo "------------------------------------------------"
dart fix --apply
echo "✓ Fix complete"

# Step 3: Analyze
echo ""
echo "▶ Running: flutter analyze --fatal-infos ."
echo "------------------------------------------------"
flutter analyze --fatal-infos .
echo "✓ Analyze complete"

echo ""
echo "================================================"
echo "✓ All checks passed!"
echo "================================================"