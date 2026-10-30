#!/usr/bin/env bash
# Claude Code Stop hook: format + analyze changed Dart files.
# Silent on success; on failure prints to stderr and exits 2 so the agent keeps working.
# After MAX_BLOCKS consecutive failures in one session it lets the agent stop, to avoid endless loops.
set -uo pipefail

MAX_BLOCKS=3

command -v dart >/dev/null 2>&1 || export PATH="${FLUTTER_ROOT:-$HOME/development/flutter}/bin:$PATH"
cd "$(git rev-parse --show-toplevel)" || exit 0

SESSION_ID=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("session_id","default"))' 2>/dev/null || echo default)
COUNTER="${TMPDIR:-/tmp}/claude_stop_check_${SESSION_ID//[^A-Za-z0-9_-]/_}"

CHANGED=$( { git diff -z --name-only --diff-filter=ACMR HEAD; git ls-files -z --others --exclude-standard; } \
  | tr '\0' '\n' | grep -E '^(lib|test)/.*\.dart$' | grep -vE '\.(g|freezed|mocks)\.dart$' | sort -u)
if [[ -z "$CHANGED" ]]; then rm -f "$COUNTER"; exit 0; fi

OUT=""
FMT=$(echo "$CHANGED" | xargs -d '\n' dart format --output=none --set-exit-if-changed 2>&1) \
  || OUT+="dart format needed (run: dart format lib test):"$'\n'"$FMT"$'\n'
ANA=$(echo "$CHANGED" | xargs -d '\n' dart analyze 2>&1) \
  || OUT+="dart analyze errors/warnings:"$'\n'"$ANA"$'\n'

if [[ -z "$OUT" ]]; then rm -f "$COUNTER"; exit 0; fi

BLOCKS=$(( $(cat "$COUNTER" 2>/dev/null || echo 0) + 1 ))
if (( BLOCKS > MAX_BLOCKS )); then rm -f "$COUNTER"; exit 0; fi
echo "$BLOCKS" > "$COUNTER"
echo "$OUT" >&2
exit 2
