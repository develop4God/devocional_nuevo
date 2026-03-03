#!/bin/bash
# tests.sh - Run a single targeted test file (avoids full-suite reporter crash)
# CONTINGENCY: Always run via background terminal + get_terminal_output
#   id = run_in_terminal("bash tests.sh test/unit/providers/devocional_provider_test.dart 2>&1; echo EXIT=$?", isBackground=true)
#   get_terminal_output(id)
#
# Usage:
#   bash tests.sh <test_file>         run one specific test file
#   bash tests.sh                     run safe default (devocional_provider_test.dart)
#
# DO NOT run without an argument against the full suite — it will crash the
# Flutter test reporter (RangeError / StateError: LiveTest closed).

export PATH="$PATH:/home/develop4god/development/flutter/bin"
export FLUTTER_ROOT="/home/develop4god/development/flutter"

FLUTTER="/home/develop4god/development/flutter/bin/flutter"
PROJECT="/home/develop4god/projects/devocional_nuevo"

echo "=== WORKSPACE: $PROJECT ==="
echo "=== DATE: $(date) ==="
echo ""

# Default to a fast, known-good test file if no argument supplied
TEST_FILE="${1:-test/unit/providers/devocional_provider_test.dart}"

echo "--- Running: flutter test $TEST_FILE --reporter compact ---"
echo ""

OUTPUT="$("$FLUTTER" test "$PROJECT/$TEST_FILE" --reporter compact 2>&1)"
TEST_EXIT=$?

echo "=== TEST REPORT ==="
echo "$OUTPUT"
echo "=== END REPORT ==="

if echo "$OUTPUT" | grep -qiE 'error|failure|failed'; then
    echo "RESULT=TESTS_FAILED"
    exit 1
else
    echo "RESULT=ALL_TESTS_PASSED"
    exit 0
fi