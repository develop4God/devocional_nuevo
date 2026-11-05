#!/usr/bin/env bash
# Simple Flutter/Dart checker: format -> fix -> analyze
# Shows all output in terminal, stops on first failure

set -e  # Exit on any command failure

# Git exports GIT_DIR / GIT_WORK_TREE / GIT_INDEX_FILE to hooks. Flutter runs git
# inside its own SDK checkout to read its version; with these set it queries
# this repo instead and reports "0.0.0-unknown", so `pub get` fails and every
# push from a hook is rejected. Clear them before invoking dart/flutter.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR \
  GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES

# Add Dart and Flutter to PATH for all environments (fixes Android Studio UI push)
export PATH="$PATH:/home/develop4god/development/flutter/bin"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Debug: Print environment and path info for hook troubleshooting
(
  echo "[DEBUG] Current PATH: $PATH"
  echo "[DEBUG] which dart: $(which dart || echo 'dart not found')"
  echo "[DEBUG] which flutter: $(which flutter || echo 'flutter not found')"
  echo "[DEBUG] whoami: $(whoami)"
  echo "[DEBUG] SHELL: $SHELL"
  echo "[DEBUG] env (filtered):"
  env | grep -E 'PATH|DART|FLUTTER' || true
) >&2

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