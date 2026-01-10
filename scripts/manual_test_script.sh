#!/bin/bash
# Complete AAB Migration Test - Build to Verification
# Usage: ./test_migration.sh <package.name>

set -e

PACKAGE=${1:-"com.develop4god.devocional_nuevo"}

echo "=== Complete Migration Test ==="
echo "Package: $PACKAGE"
echo ""

# Check device
if ! adb devices | grep -q "device$"; then
  echo "❌ No device connected"
  exit 1
fi

echo "✅ Device connected"
echo ""

# Step 1: Build old version
echo "=== Step 1: Building OLD version (main branch) ==="
git checkout main
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk old-version.apk
echo "✅ Old version saved: old-version.apk"
echo ""

# Step 2: Build new version
echo "=== Step 2: Building NEW version (fix branch) ==="
git checkout fix/favorites-no-read
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk new-version.apk
echo "✅ New version saved: new-version.apk"
echo ""

# Step 3: Install old version
echo "=== Step 3: Installing OLD version ==="
adb install -r old-version.apk

echo ""
echo "🎯 ACTION REQUIRED:"
echo "  1. Open the app"
echo "  2. Add 3-5 favorites"
echo "  3. Press ENTER when done..."
read

# Step 4: Migration with logging
echo ""
echo "=== Step 4: Installing NEW version (capturing logs) ==="
adb logcat -c
adb logcat -s "Favorites:V" "*:S" | tee migration.log | grep --line-buffered "FAVORITES_" &
LOGPID=$!

sleep 2
adb install -r new-version.apk

echo "🎯 Launching app..."
adb shell am start -n "$PACKAGE/.MainActivity"

echo "⏳ Waiting 15 seconds for migration..."
sleep 15

kill $LOGPID 2>/dev/null || true

# Step 5: Analyze results
echo ""
echo "=== Step 5: Migration Analysis ==="

MIGRATE=$(grep -c "FAVORITES_MIGRATE" migration.log)
MIGRATE=${MIGRATE:-0}
CLEANUP=$(grep -c "FAVORITES_CLEANUP" migration.log)
CLEANUP=${CLEANUP:-0}
SAVE=$(grep -c "FAVORITES_SAVE" migration.log)
SAVE=${SAVE:-0}
SYNC=$(grep -c "FAVORITES_SYNC" migration.log)
SYNC=${SYNC:-0}
ERRORS=$(grep -c "FAVORITES_ERROR" migration.log)
ERRORS=${ERRORS:-0}
WARNS=$(grep -c "FAVORITES_WARN" migration.log)
WARNS=${WARNS:-0}

echo "Results:"
echo "  Migration: $MIGRATE"
echo "  Cleanup:   $CLEANUP"
echo "  Save:      $SAVE"
echo "  Sync:      $SYNC"
echo "  Errors:    $ERRORS"
echo "  Warnings:  $WARNS"
echo ""

if [ "$MIGRATE" -gt 0 ]; then
  echo "✅ Migration executed:"
  grep "FAVORITES_MIGRATE" migration.log
fi

if [ "$CLEANUP" -gt 0 ]; then
  echo "✅ Legacy cleanup:"
  grep "FAVORITES_CLEANUP" migration.log
fi

if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "❌ ERRORS DETECTED:"
  grep "FAVORITES_ERROR" migration.log
fi

if [ "$WARNS" -gt 0 ]; then
  echo ""
  echo "⚠️ WARNINGS:"
  grep "FAVORITES_WARN" migration.log
fi

echo ""
echo "📋 Full log saved: migration.log"
echo ""
echo "=== Step 6: Manual Verification ==="
echo "🎯 Check in app:"
echo "  1. ✓ Favorites still exist?"
echo "  2. ✓ Count matches what you added?"
echo "  3. ✓ Add/remove new favorites works?"
echo ""
echo "All checks passed? (y/n)"
read RESULT

echo ""
if [ "$RESULT" = "y" ]; then
  echo "✅ MIGRATION TEST PASSED"
  echo ""
  echo "Next steps:"
  echo "  - Review migration.log for details"
  echo "  - Test language switching"
  echo "  - Test app restart"
  exit 0
else
  echo "❌ MIGRATION TEST FAILED"
  echo "Review migration.log for details"
  exit 1
fi
