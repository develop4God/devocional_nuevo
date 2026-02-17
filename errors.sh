#!/bin/bash
# errors.sh - Format Dart code, analyze, and grep for errors/warnings

set -e

echo "Running dart format..."
dart format .

echo "Running flutter analyze --fatal-infos..."
flutter analyze 2>&1 | grep -E "(\bE\b|error|warning)" || echo "No errors or warnings found."

