# Bug Fix: Devotional Branch Switching Not Updating Sidecar & Cache

**Date:** March 30, 2026  
**Issue:** When changing devotionals to a different branch (e.g., from `main` to `dev`) on the developer debug page, the app was not fetching devotionals from the new branch. Instead, it continued serving old cached data.

**Root Cause:** 
When the branch was changed via `DebugFlags.debugBranchDevotionals`, the repository's index cache was never invalidated. The cache contained stale data from the previous branch, and subsequent calls to `_ensureIndexFetched()` would return immediately without refreshing from the new branch URL.

## Solution

### 1. **Added `resetCache()` method to the repository interface** (`lib/repositories/devocional_repository.dart`)
   - Added a public method to reset the index cache when switching branches
   - This allows the provider to invalidate cached data when needed

### 2. **Implemented `resetCache()` in the repository** (`lib/repositories/devocional_repository_impl.dart`)
   - Renamed the private `resetIndexCache()` method to the public `resetCache()` method
   - Added `@override` annotation to ensure it implements the interface
   - Resets:
     - `_cachedIndex` = null (clears the index data)
     - `_indexUnreachable` = false (resets offline flag)
     - `_indexFetched` = false (forces re-fetch on next call)

### 3. **Added `refreshDevocionals()` public method to DevocionalProvider** (`lib/providers/devocional_provider.dart`)
   - New public method that:
     1. Calls `_devocionalRepository.resetCache()` to clear the index cache
     2. Calls `_fetchAllDevocionalesForLanguage()` to re-fetch from the new branch
   - Used by the debug page when the branch is changed

### 4. **Updated Debug Page UI** (`lib/pages/debug_page.dart`)
   - Added import for `DevocionalProvider`
   - Changed the branch selector's `onChanged` callback to:
     1. Show a loading snackbar: "Refreshing devotionals from new branch..."
     2. Call `context.read<DevocionalProvider>().refreshDevocionals()`
     3. Show success snackbar on completion
     4. Show error snackbar if refresh fails
   - Updated the note text from "Reload app to fetch from new branch" to "Devotionals will refresh automatically when branch is changed"

### 5. **Updated Tests** (`test/unit/repositories/devocional_repository_test.dart`)
   - Changed all occurrences of `resetIndexCache()` to `resetCache()` (5 instances)
   - All tests now pass and compile without errors

## How It Works

```
User changes branch in Debug Page
    ↓
onChanged callback fires
    ↓
setState() updates DebugFlags.debugBranchDevotionals
    ↓
context.read<DevocionalProvider>().refreshDevocionals()
    ↓
_devocionalRepository.resetCache()  // Clear old index
    ↓
_fetchAllDevocionalesForLanguage()  // Fetch from new branch
    ↓
_devocionalRepository.fetchAll()
    ↓
Constants.getDevocionalesApiUrlMultilingual() uses updated DebugFlags.debugBranchDevotionals
    ↓
HTTP request goes to new branch URL
    ↓
Results displayed to user with success snackbar
```

## Testing the Fix

1. Open the app in debug mode
2. Navigate to the Debug Page
3. Look for the "Devotionals Branch" section (blue container)
4. Change the branch from "main" to "dev" (or another available branch)
5. You should see:
   - A loading message: "Refreshing devotionals from new branch..."
   - A success message: "✅ Successfully loaded devotionals from: dev"
   - The devocionales list in the app should now show content from the dev branch
   - The sidecar cache files will be invalidated and re-fetched

## Files Modified

- `lib/repositories/devocional_repository.dart` - Added `resetCache()` method signature
- `lib/repositories/devocional_repository_impl.dart` - Implemented `resetCache()` (renamed from `resetIndexCache()`)
- `lib/providers/devocional_provider.dart` - Added `refreshDevocionals()` method
- `lib/pages/debug_page.dart` - Updated branch selector to trigger refresh automatically
- `test/unit/repositories/devocional_repository_test.dart` - Updated test calls to use new method name

## Verification

✅ All files compile without errors  
✅ All tests pass  
✅ Code formatted with `dart format`  
✅ No issues found by `dart analyze`  

## Branch URLs

When you change branches, the app now correctly fetches from:

```
# Before fix (stayed on old branch)
https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_2025_es_RVR1960.json

# After fix (correctly uses new branch)
https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/dev/Devocional_year_2025_es_RVR1960.json
```

The index URL also updates correctly:
```
https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/dev/index.json
```

## Related Code References

- `DebugFlags.debugBranchDevotionals` - Global flag that controls which branch to fetch from
- `Constants.getDevocionalesApiUrlMultilingual()` - Uses the flag to build URLs
- `Constants.getDevocionalIndexUrl()` - Uses the flag for index URL
- `DevocionalRepositoryImpl._ensureIndexFetched()` - Only fetches once; now properly re-fetches after cache reset
- `DevocionalIndexService` - Handles index fetching and caching

## Future Improvements

Consider adding:
1. A `--watch` mode for the debug page to auto-refresh when files change in the repository
2. A progress indicator showing the fetching status
3. A timestamp showing when the branch was last updated
4. Ability to manually trigger a cache clear for any branch

