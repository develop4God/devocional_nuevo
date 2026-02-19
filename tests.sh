#!/bin/bash
# tests.sh - Run flutter test, stop on first failure, and grep only errors

flutter test --fail-fast 2>&1 | grep -i 'error' || echo "No errors found."

