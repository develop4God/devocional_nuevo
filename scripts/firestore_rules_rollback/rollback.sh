#!/usr/bin/env bash
# Rollback script for the 2026-07-15 Firestore rules deploy.
#
# Restores the EXACT rules that were live on devocional-app before this
# deploy (captured directly from the Firebase Console before deploying,
# not reconstructed). Does NOT touch indexes (additive, safe to leave) or
# Cloud Functions (separate deploy target, not covered by this script).
#
# Usage:
#   scripts/firestore_rules_rollback/rollback.sh          # deploy the rollback
#   scripts/firestore_rules_rollback/rollback.sh --dry-run # preview only

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ROLLBACK_RULES="$SCRIPT_DIR/PRE_DEPLOY_2026_07_15.rules"
LIVE_RULES="$REPO_ROOT/firestore.rules"

if [ ! -f "$ROLLBACK_RULES" ]; then
  echo "FATAL: rollback rules file not found at $ROLLBACK_RULES"
  exit 1
fi

echo "This will replace $LIVE_RULES with the pre-2026-07-15-deploy rules"
echo "and deploy that to the LIVE devocional-app Firestore project."
echo ""

BACKUP="$REPO_ROOT/firestore.rules.pre-rollback-backup"
cp "$LIVE_RULES" "$BACKUP"
echo "Current firestore.rules backed up to: $BACKUP"

cp "$ROLLBACK_RULES" "$LIVE_RULES"
echo "firestore.rules replaced with the pre-deploy version."

DRY_RUN_FLAG=""
if [ "${1:-}" == "--dry-run" ]; then
  DRY_RUN_FLAG="--dry-run"
  echo ""
  echo "=== DRY RUN — nothing will actually deploy ==="
fi

cd "$REPO_ROOT"
firebase deploy --only firestore:rules --project devocional-app $DRY_RUN_FLAG

echo ""
if [ -z "$DRY_RUN_FLAG" ]; then
  echo "Rollback deployed. The working-tree firestore.rules now reflects the"
  echo "rolled-back (pre-2026-07-15) rules. Your previous firestore.rules"
  echo "(the hardened version) is saved at: $BACKUP"
  echo ""
  echo "To restore the hardened rules again later:"
  echo "  cp $BACKUP $LIVE_RULES && firebase deploy --only firestore:rules --project devocional-app"
else
  echo "Dry run complete — no changes were made to the live project."
  echo "Restoring firestore.rules to its pre-rollback-script state..."
  cp "$BACKUP" "$LIVE_RULES"
  rm "$BACKUP"
  echo "Done — firestore.rules restored, nothing changed."
fi
