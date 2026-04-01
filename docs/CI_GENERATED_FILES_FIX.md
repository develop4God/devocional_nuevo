# CI Workflow Fix: Auto-Generated Files Management

**Date**: April 1, 2026  
**Status**: ✅ COMPLETED  
**Commits**: `53dbe1ed`, `e024613c`

---

## Problem Statement

The CI workflow (`.github/workflows/🚀Flutter CI.yml`) was automatically committing **auto-generated Flutter plugin registrant files** to the repository, causing:

- **Commit noise**: Multiple commits updating only generated files
- **Merge conflicts**: Frequent conflicts on generated files during rebases
- **Confusion**: Developers couldn't distinguish real changes from auto-generated ones
- **CI unpredictability**: Every CI run would potentially create new commits

### Affected Files
```
macos/Flutter/GeneratedPluginRegistrant.swift
linux/flutter/generated_plugin_registrant.cc
linux/flutter/generated_plugin_registrant.h
windows/flutter/generated_plugin_registrant.cc
windows/flutter/generated_plugin_registrant.h
```

---

## Root Cause Analysis

### Why Files Were Being Committed

The CI workflow had two steps that used `git add .`:

```yaml
# ❌ BEFORE — Problematic
- name: 🎨 Assert no diff after build_runner
  run: |
    dart format .
    git add .  # ← Stages ALL files, ignoring .gitignore for tracked files
    git commit -m "🎨 Auto-format code with dart format [skip ci]"
    git push origin "$BRANCH"

- name: 🧹 Remove unused imports (dart fix)
  run: |
    dart fix --apply
    git add .  # ← Same issue
    git commit -m "🧹 Remove unused imports and auto-fix code [skip ci]"
    git push origin "$BRANCH"
```

### Why `.gitignore` Didn't Help

**Important Git Behavior**: When a file is already tracked in git, `git add .` will re-stage it **even if it's in `.gitignore`**.

**The cycle:**
1. Generated file was committed (mistake, historical)
2. File is in `.gitignore` (correct)
3. CI runs → `flutter pub get` regenerates file
4. CI runs → `git add .` re-stages the file (because it was already tracked)
5. CI commits and pushes
6. File keeps changing because `flutter pub get` regenerates it

### Why Generated Files Keep Changing

Flutter auto-generates these files based on:
- `pubspec.lock` dependencies
- `build.yaml` configuration
- Installed plugins

When CI runs `flutter pub get`, the generated files may have different content:
- Different import order
- Formatting changes
- Plugin registry updates

---

## Solution Implemented

### Step 1: Remove Generated Files from Git Index

**Commit**: `53dbe1ed`

Removed all auto-generated files from git's tracking:

```bash
git rm --cached \
  macos/Flutter/GeneratedPluginRegistrant.swift \
  linux/flutter/generated_plugin_registrant.cc \
  linux/flutter/generated_plugin_registrant.h \
  windows/flutter/generated_plugin_registrant.cc \
  windows/flutter/generated_plugin_registrant.h
```

**Result**: Files are deleted from git history but still exist locally in `.gitignore`

### Step 2: Update CI Workflow

**Commit**: `e024613c`

Modified two steps in `.github/workflows/🚀Flutter CI.yml`:

#### Step 1: Dart Format Step (Lines 95-107)

```yaml
# ✅ AFTER — Fixed
if ! git diff --quiet; then
  # ⚠️ Exclude auto-generated files from commit
  git add lib/ test/ pubspec.yaml pubspec.lock i18n/ docs/
  git reset -- '**/GeneratedPluginRegistrant*' '**/generated_plugin_registrant*' 2>/dev/null || true
  
  # Only commit if source files changed (not just generated files)
  if ! git diff --cached --quiet; then
    git commit -m "🎨 Auto-format code with dart format [skip ci]"
    git push origin "$BRANCH"
  else
    echo "ℹ️ Only generated files were reformatted, skipping commit"
    git checkout -- .
  fi
fi
```

#### Step 2: Dart Fix Step (Lines 128-140)

```yaml
# ✅ AFTER — Fixed
if ! git diff --quiet; then
  # ⚠️ Exclude auto-generated files from commit
  git add lib/ test/ pubspec.yaml pubspec.lock i18n/ docs/
  git reset -- '**/GeneratedPluginRegistrant*' '**/generated_plugin_registrant*' 2>/dev/null || true
  
  # Only commit if source files changed (not just generated files)
  if ! git diff --cached --quiet; then
    git commit -m "🧹 Remove unused imports and auto-fix code [skip ci]"
    git push origin "$BRANCH"
  else
    echo "ℹ️ Only generated files were modified by dart fix, skipping commit"
    git checkout -- .
  fi
fi
```

**Key Changes**:
1. **Selective `git add`**: Only adds source directories, not everything
2. **Explicit reset**: Removes generated files from staging area
3. **Conditional commit**: Only commits if source files actually changed
4. **Graceful fallback**: Discards generated file changes if no source changes

---

## How It Works Now

```
┌─────────────────────────────────────────────────────────────┐
│                    CI Runs: flutter pub get                 │
│              (Regenerates GeneratedPluginRegistrant.swift)   │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                    dart format .                             │
│   (Formats source files AND generated files)                │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│            Check: git diff --quiet                           │
│   (Are there any changes?)                                  │
└────────────────────────┬────────────────────────────────────┘
                         ↓
                  Yes, changes found
                         ↓
┌─────────────────────────────────────────────────────────────┐
│         git add lib/ test/ pubspec.yaml i18n/ docs/         │
│      (Add ONLY source files, exclude generated files)       │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│  git reset -- '**/GeneratedPluginRegistrant*'               │
│  (Remove generated files from staging area)                 │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│          Check: git diff --cached --quiet                    │
│   (Are there staged source file changes?)                   │
└────────────────┬──────────────────────────┬─────────────────┘
                 ↓                          ↓
            YES (commit)              NO (skip)
                 ↓                          ↓
        ┌────────────────┐        ┌────────────────┐
        │ git commit     │        │ git checkout   │
        │ git push       │        │    (discard)   │
        └────────────────┘        └────────────────┘
                 ↓                          ↓
    ✅ Commit with source changes      ✅ No commit
       (clean history)              (generated only)
```

---

## Verification Checklist

### ✅ Generated Files Are NOT Tracked
```bash
$ git ls-files | grep -E '(GeneratedPluginRegistrant|generated_plugin_registrant)'
# (no output)
```

### ✅ Generated Files Are in .gitignore
```bash
$ grep "GeneratedPluginRegistrant\|generated_plugin_registrant" .gitignore
macos/Flutter/GeneratedPluginRegistrant.swift
linux/flutter/generated_plugin_registrant.cc
linux/flutter/generated_plugin_registrant.h
windows/flutter/generated_plugin_registrant.cc
windows/flutter/generated_plugin_registrant.h
```

### ✅ Generated Files Still Exist Locally
```bash
$ ls -la macos/Flutter/GeneratedPluginRegistrant.swift
-rw-r-w- 1 user user 2.1K Mar 31 12:00 GeneratedPluginRegistrant.swift
```

### ✅ CI Changes Are Committed
```bash
$ git log --oneline -2
e024613c ♻️ CI: Exclude auto-generated files from git add during format/fix steps
53dbe1ed 🚀 Remove auto-generated Flutter plugin registrant files from version control
```

### ✅ Working Directory Is Clean
```bash
$ git status
On branch feature/new-german-version-de
nothing to commit, working tree clean
```

---

## Expected Behavior Going Forward

### Future CI Runs
1. **Flutter pub get** → Regenerates generated files
2. **dart format** → Formats all files
3. **CI detects changes** → Files staged and reset
4. **CI checks source changes**:
   - **If source files changed** → Commits (clean history) ✅
   - **If only generated files changed** → Skips (no noise) ✅

### Expected Results
- ✅ **No spurious commits** for generated files
- ✅ **Clean git history** with only meaningful changes
- ✅ **No merge conflicts** from generated files
- ✅ **Predictable CI behavior**

---

## Files Modified

### 1. `.github/workflows/🚀Flutter CI.yml`
- **Lines 95-107**: Modified dart format step
- **Lines 128-140**: Modified dart fix step
- **Changes**: Selective `git add`, explicit file reset, conditional commit

### 2. Git History (Deleted Files)
- `linux/flutter/generated_plugin_registrant.cc`
- `linux/flutter/generated_plugin_registrant.h`
- `macos/Flutter/GeneratedPluginRegistrant.swift`
- `windows/flutter/generated_plugin_registrant.cc`
- `windows/flutter/generated_plugin_registrant.h`

### 3. `.gitignore` (Unchanged)
- Already had correct entries for all generated files
- No changes needed

---

## Related Issues

### Before This Fix
```
4d8c2232 🧹 Remove unused imports [GeneratedPluginRegistrant.swift +2]
f105c744 refactor: remove unused Plugin [GeneratedPluginRegistrant.swift -1]
98384c50 🧹 Remove unused imports [GeneratedPluginRegistrant.swift changed]
...
```

**Issue**: Endless cycle of auto-generated file changes

### After This Fix
```
e024613c ♻️ CI: Exclude auto-generated files from git add
53dbe1ed 🚀 Remove auto-generated Flutter plugin registrant files
[Future commits will be clean]
```

**Resolution**: Generated files are removed and CI is fixed ✅

---

## Additional Notes

### Why Generated Files Exist
Flutter generates these files for platform-specific plugin registration:
- macOS needs `GeneratedPluginRegistrant.swift` to register native plugins
- Linux/Windows need similar C++ files
- These files are rebuilt every time `flutter pub get` runs

### Why They Shouldn't Be Tracked
- They change frequently based on `pubspec.lock`
- They're easily regenerated (no manual work needed)
- Tracking them causes merge conflicts and commit noise
- Standard Flutter best practice is to ignore them

### How Flutter Developers Handle This
- All generated files go in `.gitignore` ✅
- They're generated as part of the build process ✅
- Never manually edited or committed ✅
- This repository now follows best practices ✅

---

## References

- **Flutter Docs**: [pubspec.lock and .gitignore](https://docs.flutter.dev/development/best-practices)
- **Git Behavior**: `git add` bypasses `.gitignore` for already-tracked files
- **CI Workflow File**: `.github/workflows/🚀Flutter CI.yml`
- **Related Commits**: `53dbe1ed`, `e024613c`

---

**Document Status**: Complete ✅  
**Last Updated**: April 1, 2026  
**Applicable Branches**: All (especially feature/new-german-version-de)

