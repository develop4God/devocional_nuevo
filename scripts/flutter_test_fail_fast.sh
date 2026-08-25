#!/usr/bin/env bash
# Run Flutter tests sequentially and stop at the first failure.
# By default, only failing-test details are printed to keep the report focused.
#
# Usage:
#   scripts/flutter_test_fail_fast.sh [test path or flutter test options...]
#
# Examples:
#   scripts/flutter_test_fail_fast.sh test/unit/models/bible_version_test.dart
#   scripts/flutter_test_fail_fast.sh --tags unit
#   FLUTTER_TEST_VERBOSE=1 scripts/flutter_test_fail_fast.sh test/some_test.dart
#
# Failure logs are saved to .dart_tool/test-failures/. Set FLUTTER_TEST_LOG_DIR
# to store them elsewhere.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

LOG_DIR="${FLUTTER_TEST_LOG_DIR:-$PROJECT_ROOT/.dart_tool/test-failures}"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/flutter-test-$(date '+%Y%m%d-%H%M%S').log"

command=(flutter test --fail-fast --concurrency=1 --reporter=failures-only)
if [[ "${FLUTTER_TEST_VERBOSE:-0}" == "1" ]]; then
  command=(flutter --verbose test --fail-fast --concurrency=1 --reporter=failures-only)
fi

set +e
{
  printf '+ '
  printf '%q ' "${command[@]}" "$@"
  printf '\n'
  "${command[@]}" "$@"
} 2>&1 | tee "$LOG_FILE"
test_status=${PIPESTATUS[0]}
set -e

if (( test_status != 0 )); then
  echo "Test failed. Full log saved to: $LOG_FILE" >&2
  exit "$test_status"
fi

echo "Test passed. Log saved to: $LOG_FILE"
