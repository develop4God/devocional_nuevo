# Favorites Page - Bible Studies Tab Infinite Spinner Bug Fix

## Date: January 24, 2026

## Problem Summary

**Critical Bug:** When navigating to the Favorites page and switching to the Bible Studies tab for
the first time, the page showed an infinite spinner and never loaded the Bible study favorites.

**Root Cause:** The `BlocConsumer` listener only fires when there's a **state transition**. If the
`DiscoveryBloc` was already in `DiscoveryInitial` state when the widget built, the listener wouldn't
fire because there was no state change - it was just building with the existing initial state.

## Technical Analysis

### Previous (Broken) Implementation

```dart
Widget _buildBibleStudiesFavorites(BuildContext context, ThemeData theme) {
  return BlocConsumer<DiscoveryBloc, DiscoveryState>(
    listener: (context, state) {
      // ❌ PROBLEM: Listener only fires on state CHANGES
      // If DiscoveryBloc is already in DiscoveryInitial, this never fires!
      if (state is DiscoveryInitial) {
        context.read<DiscoveryBloc>().add(LoadDiscoveryStudies());
      }
    },
    builder: (context, state) {
      if (state is DiscoveryInitial) {
        // Shows spinner forever because listener never fired
        return const Center(child: CircularProgressIndicator());
      }
      // ... rest of builder
    },
  );
}
```

**Why it failed:**

1. App starts → DiscoveryBloc created in `DiscoveryInitial` state
2. User opens Favorites page → switches to Bible Studies tab
3. Widget builds for first time with `DiscoveryInitial` state
4. **Listener doesn't fire** because there's no state transition (was Initial, still Initial)
5. Builder shows spinner
6. **No event dispatched** → Bloc stays in Initial state forever
7. **Result:** Infinite spinner 😱

### Fixed Implementation

```dart
Widget _buildBibleStudiesFavorites(BuildContext context, ThemeData theme) {
  return BlocConsumer<DiscoveryBloc, DiscoveryState>(
    listener: (context, state) {
      // Listener fires on state changes only
      // Initial state handling is done in builder
    },
    builder: (context, state) {
      // ✅ Handle initial state - trigger load on first build
      if (state is DiscoveryInitial) {
        // Use postFrameCallback to avoid dispatching during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.read<DiscoveryBloc>().add(LoadDiscoveryStudies());
          }
        });
        return const Center(child: CircularProgressIndicator());
      }

      if (state is DiscoveryLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (state is DiscoveryLoaded) {
        // Show favorites list
      }

      if (state is DiscoveryError) {
        // Show error UI
      }

      return const Center(child: CircularProgressIndicator());
    },
  );
}
```

## Key Fix Points

### 1. Event Dispatch in Builder ✅

**Why:** The `builder` method is called on first build when the state is already `DiscoveryInitial`,
so we must check and dispatch there.

**How:** Use `postFrameCallback` to dispatch the event after the build phase completes:

```dart
WidgetsBinding.instance.addPostFrameCallback
(
(_) {
if (context.mounted) {
context.read<DiscoveryBloc>().add(LoadDiscoveryStudies());
}
});
```

**Benefits:**

- Dispatches event on first build when in Initial state
- Respects Flutter's build cycle (no dispatch during build)
- Includes safety check (`context.mounted`)
- Works correctly when DiscoveryBloc starts in Initial state

### 2. Context Mounted Check ✅

**Why:** Prevents dispatching events to a disposed widget.

**How:** Check `context.mounted` before accessing the Bloc.

### 3. Post Frame Callback Pattern ✅

**Why:** Flutter best practice - don't dispatch events during the build phase.

**How:** Use `WidgetsBinding.instance.addPostFrameCallback()` to defer the event dispatch until
after the frame is built.

## State Flow After Fix

```
User Action: Open Favorites → Switch to Bible Studies tab
┌─────────────────────────────────────────────────────────┐
│ 1. Widget builds with DiscoveryBloc in Initial state   │
│                                                         │
│ 2. Builder checks: state is DiscoveryInitial?  ✓      │
│                                                         │
│ 3. Schedules postFrameCallback to dispatch event        │
│                                                         │
│ 4. Returns CircularProgressIndicator                    │
│                                                         │
│ 5. Frame completes, postFrameCallback fires             │
│                                                         │
│ 6. Dispatches LoadDiscoveryStudies event     ✓         │
│                                                         │
│ 7. DiscoveryBloc transitions: Initial → Loading        │
│                                                         │
│ 8. Widget rebuilds with Loading state                  │
│                                                         │
│ 9. Fetches data from repository                        │
│                                                         │
│ 10. DiscoveryBloc transitions: Loading → Loaded        │
│                                                         │
│ 11. Widget rebuilds showing favorites list    ✓        │
└─────────────────────────────────────────────────────────┘
```

## Testing Strategy

### Manual Testing

1. Fresh app install / clear app data
2. Open app → Navigate to Favorites page
3. Switch to Bible Studies tab
4. **Expected:** Loading indicator briefly, then empty state or favorites list
5. **Actual:** ✅ Works correctly - no infinite spinner

### Edge Cases Covered

- ✅ First time opening Bible Studies tab (DiscoveryInitial state)
- ✅ Switching between tabs multiple times
- ✅ Language change triggering re-initialization
- ✅ Network errors showing error state
- ✅ Empty favorites showing empty state

## Files Modified

1. **lib/pages/favorites_page.dart**
    - Modified `_buildBibleStudiesFavorites()` method
    - Added postFrameCallback pattern
    - Kept all existing state handling (Loading, Loaded, Error)

2. **docs/FAVORITES_INFINITE_SPINNER_FIX.md**
    - Updated documentation with correct fix approach

## Validation

```bash
# 1. Code compiles without errors
flutter analyze --no-fatal-infos
# Result: No issues found!

# 2. Code is properly formatted
dart format lib/pages/favorites_page.dart
# Result: Formatted 1 file (0 changed)

# 3. File-specific analysis
dart analyze lib/pages/favorites_page.dart
# Result: No issues found!
```

## Impact

- ✅ Fixes critical bug affecting all users on first use
- ✅ Improves UX - no more infinite spinner
- ✅ Follows Flutter best practices (postFrameCallback pattern)
- ✅ No breaking changes to existing functionality
- ✅ Maintains all existing state handling logic

## Related Issues

This fix addresses the issue mentioned in the user's requirements:
> "on first time entering the favorites page the bible studies not initialize or enter the mode,
> show infinite spinner only after enter the mode"

## Commit Message

```
fix: Bible Studies tab infinite spinner on first open

- Add postFrameCallback to dispatch LoadDiscoveryStudies in builder
- Fix BlocConsumer listener not firing on first build with Initial state
- Maintain existing state handling for Loading, Loaded, Error states
- Add context.mounted safety check

Fixes critical UX bug where Bible Studies tab showed infinite spinner
on first open because LoadDiscoveryStudies event was never dispatched.

The listener only fires on state *changes*, not on initial build, so
we must check and dispatch in the builder using postFrameCallback.
```
