#!/bin/bash
# errors.sh - Run formatting, analysis, and grep for errors, warnings, and info

set -e

echo "Running dart format..."
dart format .

echo "Running flutter analyze with info level (including warnings and errors)..."
flutter analyze --fatal-infos

echo "Grep for errors, warnings, and info in analysis output..."
flutter analyze --fatal-infos | grep -E 'error|warning|info' || true
