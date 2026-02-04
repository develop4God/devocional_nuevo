# Discovery Tab Test Hanging Issue - Fix Report

**Date:** February 4, 2026
**File:** `test/widget/favorites_page_discovery_tab_test.dart`
**Issue:** Test hanging for 35+ minutes despite refactor that was supposed to make it fast

## Problem Analysis

### Root Cause

The test was **still using `pumpAndSettle()`** which was supposed to be removed during the refactor
documented in `DISCOVERY_BLOC_TEST_OPTIMIZATION.md`. This method waits for ALL animations to
complete, but `CircularProgressIndicator` widgets have infinite animations that never complete.

### Why the Refactor Wasn't Complete

The refactor documentation stated:

- **Kept**: 1 integration test for critical user flow
- **Optimizations**: Replaced `pumpAndSettle()` with explicit `pump()` calls
- **Expected Result**: ~2-3 seconds execution time

However, the test file still contained `pumpAndSettle()` calls that caused indefinite hanging.

## Fixes Applied

### 1. Replaced `pumpAndSettle()` with bounded `pump()` calls

```dart
// BEFORE (hangs indefinitely):
await
tester.pumpAndSettle
();

// AFTER (completes quickly):
await
tester.pump
();
```

### 2. Wrapped test in `runAsync()` for proper async handling

```dart
testWidgets
('...
'
, (WidgetTester tester) async {
await tester.runAsync(() async {
// Test code here
});
});
```

### 3. Added small delays for BLoC event processing

```dart
await
tester.tap
(
find.byIcon(Icons.star_rounded));
await tester.pump();
// Allow time for BLoC event to be added
await Future.delayed(const Duration(milliseconds: 50));
await
tester
.
pump
(
);
```

## File Changes

**Modified:** `test/widget/favorites_page_discovery_tab_test.dart`

- ✅ Removed all `pumpAndSettle()` calls
- ✅ Wrapped test in `runAsync()`
- ✅ Added explicit delays for async operations
- ✅ Kept file structure and test purpose intact

## Test Execution Time

- **Before Fix:** 35+ minutes (hung indefinitely)
- **After Fix:** Should complete in ~3-5 seconds (still marked as `@Tags(['slow'])` for widget test
  overhead)

## How to Run

```bash
# Run just this test:
flutter test test/widget/favorites_page_discovery_tab_test.dart

# Run fast tests only (excludes this slow widget test):
flutter test --exclude-tags=slow

# Run full test suite:
flutter test
```

## Prevention

This issue highlights the importance of:

1. **Complete refactors:** When documentation says "replace X with Y", ensure ALL occurrences are
   replaced
2. **Test the tests:** After refactoring tests, actually run them to verify they work as expected
3. **Never use `pumpAndSettle()` with CircularProgressIndicator:** Always use explicit `pump()`
   calls
4. **Use `runAsync()` for widget tests with real BLoC operations:** This properly handles async
   operations in tests

## Related Documentation

- `docs/DISCOVERY_BLOC_TEST_OPTIMIZATION.md` - Original refactor plan
- `docs/SLOW_TESTS_LOG.md` - Documents the `pumpAndSettle()` issue
- `test/README_DISCOVERY_BLOC_TESTS.md` - Test suite overview

## Current Test Status

The hanging issue is **COMPLETELY RESOLVED**. The test now completes in 4 seconds instead of 35+
minutes.

However, the test is currently **failing** with this assertion error:

```
Expected: not <Instance of 'DiscoveryInitial'>
  Actual: <Instance of 'DiscoveryInitial'>
BLoC should transition from Initial after tab switch
```

This is a **separate issue** from the hanging problem - the test logic itself needs review. The BLoC
is not transitioning from Initial state after tab switch, which suggests either:

1. The tab switching logic in FavoritesPage needs investigation
2. The test needs to wait longer for the event to process
3. The mock setup is incomplete

**This is actually good news** - the test is now fast enough to show us the real logic issues that
were hidden by the infinite hanging before!

---

**Status:** ✅ HANGING FIXED - Test completes in 4 seconds  
**Status:** ⚠️ TEST LOGIC - Needs investigation (separate from hanging issue)
