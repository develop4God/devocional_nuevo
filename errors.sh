#!/bin/bash
export PATH="$PATH:/home/develop4god/development/flutter/bin"

OUTPUT=$(dart analyze 2>&1)
EXIT_CODE=$?

echo "$OUTPUT"

if [ $EXIT_CODE -ne 0 ] || echo "$OUTPUT" | grep -E 'error|warning|info' > /dev/null 2>&1; then
    echo "ISSUES_FOUND"
    exit 1
else
    echo "CLEAN"
    exit 0
fi