#!/usr/bin/env bash
# scripts/coverage_report.sh
#
# Per-file line coverage from coverage/lcov.info, computed by parsing raw
# DA: records directly. `lcov --list` mis-renders the per-file Rate column
# under LCOV 2.0-1 (Num stays correct, Rate shows 0.0% for every file even
# when the aggregate --summary is correct) — do not use `lcov --list` with
# this toolchain version. This script is the trustworthy replacement.
#
# Usage:
#   flutter test --coverage <test paths...>
#   scripts/coverage_report.sh [file-substring-filter]
#
# Example:
#   scripts/coverage_report.sh onboarding

set -euo pipefail

LCOV_FILE="${LCOV_FILE:-coverage/lcov.info}"
FILTER="${1:-}"

if [[ ! -f "$LCOV_FILE" ]]; then
  echo "error: $LCOV_FILE not found. Run 'flutter test --coverage <paths>' first." >&2
  exit 1
fi

python3 - "$LCOV_FILE" "$FILTER" <<'EOF'
import sys

lcov_path, filt = sys.argv[1], sys.argv[2]

with open(lcov_path) as f:
    content = f.read()

records = content.split("SF:")[1:]
results = []
for rec in records:
    lines = rec.splitlines()
    filename = lines[0].strip()
    if filt and filt not in filename:
        continue
    hit = total = 0
    for line in lines[1:]:
        if line.startswith("DA:"):
            total += 1
            if int(line[3:].split(",")[1]) > 0:
                hit += 1
    results.append((filename, hit, total))

results.sort(key=lambda r: (r[1] / r[2] if r[2] else 1.0))

for filename, hit, total in results:
    pct = (hit / total * 100) if total else 100.0
    print(f"{pct:6.1f}%  {hit:4d}/{total:<4d}  {filename}")

th = sum(h for _, h, _ in results)
tt = sum(t for _, _, t in results)
if tt:
    print(f"\nTOTAL: {th}/{tt} = {th/tt*100:.1f}%")
EOF
