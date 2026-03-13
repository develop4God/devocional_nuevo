#!/bin/bash
# tests.sh - Comprehensive Test Runner with Identity Fingerprint Reliability
#
# This script runs ALL tests from test/ folder with clear, comprehensive results.
# Uses file redirection pattern for reliable output capture (workspace identity pattern).
#
# Usage:
#   bash tests.sh                     run ALL tests from test/ (with --fail-fast)
#   bash tests.sh <test_file>         run one specific test file
#   bash tests.sh --all-verbose       run ALL tests without fail-fast (verbose)
#
# Output: Clear metrics showing test count, timing, and failures
# This is your primary tool for testing troubleshooting and environmental debugging.

set -o pipefail

# ========== WORKSPACE IDENTITY FINGERPRINT ==========
export PATH="$PATH:/home/develop4god/development/flutter/bin"
export FLUTTER_ROOT="/home/develop4god/development/flutter"

FLUTTER="/home/develop4god/development/flutter/bin/flutter"
PROJECT="/home/develop4god/projects/devocional_nuevo"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
OUTPUT_FILE="/tmp/flutter_test_${TIMESTAMP}.log"
# shellcheck disable=SC2034
SUMMARY_FILE="/tmp/flutter_test_summary_${TIMESTAMP}.txt"

# ========== FUNCTIONS ==========

log_header() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║ $1"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
}

log_section() {
    echo ""
    echo "▶ $1"
    echo "─────────────────────────────────────────────────────────────────"
}

print_summary() {
    # shellcheck disable=SC2317
    local output="$1"
    # shellcheck disable=SC2034
    local start_time="$2"
    # shellcheck disable=SC2034
    local end_time="$3"

    # Extract test counts from output
    local total_tests=$(echo "$output" | grep -o '\+[0-9]\+' | tail -1 | tr -d '+')
    local failed_tests=$(echo "$output" | grep -o '\-[0-9]\+' | tail -1 | tr -d '-')
    local duration=$(echo "$output" | grep -oP '\d+:\d+' | tail -1)

    # Calculate metrics
    local passed=$((total_tests - (failed_tests == "-" ? 0 : ${failed_tests:-0})))

    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                       TEST RESULTS SUMMARY                      ║"
    echo "╠════════════════════════════════════════════════════════════════╣"

    if echo "$output" | grep -qE 'All tests passed|+[0-9]+ -0:'; then
        echo "║  ✅ STATUS: ALL TESTS PASSED                                    ║"
        echo "║  📊 Total Tests: $total_tests                                   ║"
        echo "║  ⏱️  Duration: $duration                                       ║"
    else
        echo "║  ❌ STATUS: SOME TESTS FAILED                                   ║"
        echo "║  📊 Total Tests: $total_tests                                   ║"
        echo "║  ✅ Passed: $passed                                              ║"
        echo "║  ❌ Failed: $failed_tests                                         ║"
        echo "║  ⏱️  Duration: $duration                                       ║"
    fi

    echo "║  📁 Output File: $OUTPUT_FILE                 ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
}

# ========== MAIN LOGIC ==========

log_header "🧪 FLUTTER TEST RUNNER - WORKSPACE: $PROJECT"

echo "📋 Workspace Identity:"
echo "   ├─ Project: devocional_nuevo"
echo "   ├─ Path: $PROJECT"
echo "   ├─ Flutter: 3.38.5 (stable)"
echo "   ├─ Platform: Pop!_OS 24.04 (Linux)"
echo "   └─ Time: $(date)"
echo ""

# Determine test mode
if [ "$1" = "--all-verbose" ]; then
    # Run all tests WITHOUT fail-fast (verbose)
    log_section "Running ALL tests (verbose, no fail-fast)"
    TEST_FLAGS="--reporter compact"
    TEST_TARGETS="$PROJECT/test"

elif [ -n "$1" ] && [ "$1" != "--all-verbose" ]; then
    # Run specific test file
    log_section "Running specific test file: $1"
    TEST_FLAGS="--reporter compact"
    TEST_TARGETS="$PROJECT/$1"

else
    # Default: run all tests with fail-fast
    log_section "Running ALL tests (fail-fast mode - stops at first failure)"
    TEST_FLAGS="--fail-fast --reporter compact"
    TEST_TARGETS="$PROJECT/test"
fi

echo "Command: $FLUTTER test $TEST_TARGETS $TEST_FLAGS"
echo "Output file: $OUTPUT_FILE"
echo ""

# ========== RUN TESTS WITH FILE REDIRECTION ==========
# Using identity fingerprint pattern: redirect to file for reliable capture

START_TIME=$(date +%s%N)
$FLUTTER test $TEST_TARGETS $TEST_FLAGS > "$OUTPUT_FILE" 2>&1
TEST_EXIT_CODE=$?
# shellcheck disable=SC2034
END_TIME=$(date +%s%N)

# ========== DISPLAY RESULTS ==========

if [ ! -f "$OUTPUT_FILE" ]; then
    echo "❌ ERROR: Output file not created at $OUTPUT_FILE"
    exit 1
fi

# Read output and display
OUTPUT_CONTENT=$(cat "$OUTPUT_FILE")

# Show test output
log_section "📋 Test Output"
echo "$OUTPUT_CONTENT"

# Show summary
log_section "📊 Summary"

if [ $TEST_EXIT_CODE -eq 0 ]; then
    PASSED_COUNT=$(echo "$OUTPUT_CONTENT" | grep -o '\+[0-9]\+' | tail -1 | tr -d '+')
    DURATION=$(echo "$OUTPUT_CONTENT" | grep -oP '\d+:\d+' | tail -1)

    echo "✅ ALL TESTS PASSED"
    echo ""
    echo "   📊 Test Count: $PASSED_COUNT passed"
    echo "   ⏱️  Duration: ${DURATION:-N/A}"
    echo "   📁 Log File: $OUTPUT_FILE"

    RESULT="ALL_TESTS_PASSED"
else
    TOTAL=$(echo "$OUTPUT_CONTENT" | grep -o '\+[0-9]\+' | tail -1 | tr -d '+')
    FAILED=$(echo "$OUTPUT_CONTENT" | grep -o '\-[0-9]\+' | tail -1 | tr -d '-')
    PASSED=$((TOTAL - (${FAILED:-0})))
    DURATION=$(echo "$OUTPUT_CONTENT" | grep -oP '\d+:\d+' | tail -1)

    echo "❌ TESTS FAILED"
    echo ""
    echo "   📊 Total Tests: $TOTAL"
    echo "   ✅ Passed: $PASSED"
    echo "   ❌ Failed: ${FAILED:-unknown}"
    echo "   ⏱️  Duration: ${DURATION:-N/A}"
    echo "   📁 Log File: $OUTPUT_FILE"
    echo ""
    echo "🔍 Scroll up to see failure details ↑"

    RESULT="TESTS_FAILED"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "RESULT=$RESULT (EXIT_CODE=$TEST_EXIT_CODE)"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Clean up older log files (keep last 10)
find /tmp -name "flutter_test_*.log" -type f | sort -r | tail -n +11 | xargs -r rm

exit $TEST_EXIT_CODE
