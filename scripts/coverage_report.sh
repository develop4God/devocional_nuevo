#!/usr/bin/env bash
# scripts/coverage_report.sh
#
# Thin wrapper around scripts/coverage_report.py, the single source of truth
# for coverage reporting used both here and by
# .github/workflows/🚀Flutter CI.yml (merge-coverage job).
#
# Usage:
#   flutter test --coverage <test paths...>
#   scripts/coverage_report.sh [file-substring-filter]
#
# Example:
#   scripts/coverage_report.sh onboarding

set -euo pipefail

FILTER="${1:-}"

python3 "$(dirname "$0")/coverage_report.py" --filter "$FILTER"
