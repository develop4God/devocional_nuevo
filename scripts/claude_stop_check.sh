#!/usr/bin/env bash
# Claude Code Stop hook: format changed Dart files + analyze the whole project.
# Silent on success; on failure prints to stderr and exits 2 so the agent keeps working.
# After MAX_BLOCKS consecutive failures in one session it lets the agent stop, to avoid endless loops.
set -uo pipefail

MAX_BLOCKS=3

command -v dart >/dev/null 2>&1 || export PATH="${FLUTTER_ROOT:-$HOME/development/flutter}/bin:$PATH"
if ! command -v dart >/dev/null 2>&1; then echo "claude_stop_check: skipped, dart not found" >&2; exit 0; fi
# Resolve first: `cd ""` succeeds in bash, which would hide a failed rev-parse.
ROOT=$(git rev-parse --show-toplevel 2>/dev/null) && cd "$ROOT" || { echo "claude_stop_check: skipped, cannot cd to repo root" >&2; exit 0; }

SESSION_ID=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("session_id","default"))' 2>/dev/null || echo default)
COUNTER="${TMPDIR:-/tmp}/claude_stop_check_${SESSION_ID//[^A-Za-z0-9_-]/_}"
GAVE_UP="$COUNTER.gaveup"

CHANGED=$( { git diff -z --name-only --diff-filter=ACMR HEAD; git ls-files -z --others --exclude-standard; } \
  | tr '\0' '\n' | grep -E '^(lib|test)/.*\.dart$' | grep -vE '\.(g|freezed|mocks)\.dart$' | sort -u)
if [[ -z "$CHANGED" ]]; then rm -f "$COUNTER" "$GAVE_UP"; exit 0; fi

OUT=""
FMT=$(echo "$CHANGED" | xargs -d '\n' dart format --output=none --set-exit-if-changed 2>&1) \
  || OUT+="dart format needed (run dart format on the changed files listed below):"$'\n'"$FMT"$'\n'
# Whole project, so changes that break untouched files are caught. dart analyze fails on infos too,
# intentionally (zero-warnings target).
ANA=$(dart analyze lib test 2>&1) \
  || OUT+="dart analyze errors/warnings (analyze covers the whole project, so issues may be in files you did not edit):"$'\n'"$ANA"$'\n'

if [[ -z "$OUT" ]]; then rm -f "$COUNTER" "$GAVE_UP"; exit 0; fi
# Already gave up in this session: stay silent until a run is clean.
if [[ -e "$GAVE_UP" ]]; then exit 0; fi

BLOCKS=$(( $(cat "$COUNTER" 2>/dev/null || echo 0) + 1 ))
if (( BLOCKS > MAX_BLOCKS )); then
  MSG="claude_stop_check: giving up after $MAX_BLOCKS blocks; issues remain"$'\n'"$OUT"
  echo "$MSG" >&2
  { echo "[$(date -Is)] session=$SESSION_ID"; echo "$MSG"; } >> "${TMPDIR:-/tmp}/claude_stop_check.log"
  rm -f "$COUNTER"; touch "$GAVE_UP"; exit 0
fi
echo "$BLOCKS" > "$COUNTER"
echo "$OUT" >&2
exit 2
