#!/bin/bash
export PATH="$PATH:/home/develop4god/development/flutter/bin"
export FLUTTER_ROOT="/home/develop4god/development/flutter"

OUTPUT=$(/home/develop4god/development/flutter/bin/flutter test --fail-fast 2>&1)

echo "=== TEST REPORT ==="
echo "$OUTPUT"
echo "=== END REPORT ==="

if echo "$OUTPUT" | grep -qiE 'error|failure|failed'; then
    echo "TESTS_FAILED"
    exit 1
else
    echo "ALL_TESTS_PASSED"
    exit 0
fi