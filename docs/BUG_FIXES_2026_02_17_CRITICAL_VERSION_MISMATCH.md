# Critical Bug Fix - Language/Version Mismatch & Stuck UI

**Date:** February 17, 2026  
**Priority:** CRITICAL  
**Status:** ✅ RESOLVED

---

## Problem Description

### Symptoms

1. **App crashes on startup** with error: "Bad state: No devotionals available after initialization"
2. **User stuck** - unable to navigate, no bottom app bar visible
3. **404 errors** when loading devotionals
4. **Language/Version mismatch** - Spanish language trying to load Hindi Bible version

### Log Evidence

```
I/flutter: Loading from API for year 2025, language: es, version: पवित्र बाइबिल (ओ.वी.)
I/flutter: 🔍 Requesting URL: .../Devocional_year_2025_es_पवित्र बाइबिल (ओ.वी.).json
I/flutter: ⚠️ Failed to load year 2025 from API: 404
I/flutter: Error en _fetchAllDevocionalesForLanguage: Exception: No devotionals loaded from any year
[log] Failed to initialize BLoC: Bad state: No devotionals available after initialization
```

### Root Cause Analysis

**Primary Issue:** Invalid saved Bible version for current language

When the user:

1. Selected Hindi language (set version to `पवित्र बाइबिल (ओ.वी.)`)
2. Then switched back to Spanish (but version remained as Hindi)
3. On next app start, tried to load Spanish devotionals with Hindi version
4. Result: 404 errors, no devotionals loaded, BLoC initialization failed

**Secondary Issue:** No error recovery in UI

- Error scaffold had no navigation options
- User was completely stuck
- No way to access settings to fix the configuration

---

## Solution Implemented

### 1. Version Validation on Initialization ✅

**File:** `lib/providers/devocional_provider.dart`

Added validation to ensure saved Bible version is valid for current language:

```dart
// BEFORE: No validation - accepts any saved version
String savedVersion = prefs.getString('selectedVersion') ?? '';
_selectedVersion = savedVersion.isNotEmpty
?
savedVersion : defaultVersion;

// AFTER: Validates version against language
List<String> validVersions =
    Constants.bibleVersionsByLanguage[_selectedLanguage] ?? ['RVR1960'];

if (
savedVersion.isNotEmpty && validVersions.contains(savedVersion)) {
_selectedVersion = savedVersion;
} else {
// Invalid version for this language, reset to default
_selectedVersion = defaultVersion;
await prefs.setString('selectedVersion', defaultVersion);
debugPrint('⚠️ Version "$savedVersion" not valid for language "$_selectedLanguage", reset to "$defaultVersion"');
}
```

**Benefits:**

- Automatically fixes language/version mismatches
- Prevents 404 errors from invalid URLs
- Logs the fix for debugging
- Saves corrected version to preferences

### 2. Improved Error Scaffold with Navigation ✅

**File:** `lib/pages/devocionales_page.dart`

Enhanced error screen to prevent users from being stuck:

**Added Features:**

- ✅ Unique key for widget testing: `Key('devocionales_error_scaffold')`
- ✅ Better icon: Changed from `error_outline` to `cloud_off_outlined`
- ✅ Better error message with fallback
- ✅ "Go to Settings" button to fix configuration
- ✅ **Bottom navigation bar** with 4 buttons:
    - Home (retry)
    - Bible
    - Prayers
    - Settings

**Before:**

```dart
// Single retry button, no way to navigate away
FilledButton.icon
(
onPressed: () => _initializeNavigationBloc(),
icon: const Icon(Icons.refresh),
label: Text('devotionals.retry'.tr()),
)
,
```

**After:**

```dart
// Retry + Settings buttons
Row
(
children: [
FilledButton.icon(...), // Retry
OutlinedButton.icon(...), // Go to Settings
],
)

// Bottom navigation bar (CRITICAL FIX)
bottomNavigationBar: BottomAppBar(
child: Row(
children: [
IconButton(icon: Icon(Icons.home), onPressed: retry),
IconButton(icon: Icon(Icons.menu_book), onPressed: _goToBible),
IconButton(icon: Icon(Icons.favorite), onPressed: _goToPrayers),
IconButton(icon: Icon(Icons.settings), onPressed: settings),
],
),
),
```

### 3. Added Translation Keys ✅

**Files:** `i18n/en.json`, `i18n/es.json`

Added missing translations:

**English:**

```json
{
  "common": {
    "home": "Home",
    "bible": "Bible",
    "prayers": "Prayers",
    "settings": "Settings"
  },
  "devotionals": {
    "error_no_content": "Unable to load devotional content. Please check your internet connection or try changing the language/version in settings.",
    "go_to_settings": "Go to Settings"
  }
}
```

**Spanish:**

```json
{
  "common": {
    "home": "Inicio",
    "bible": "Biblia",
    "prayers": "Oraciones",
    "settings": "Configuración"
  },
  "devotionals": {
    "error_no_content": "No se pudo cargar el contenido devocional. Por favor verifica tu conexión a internet o intenta cambiar el idioma/versión en configuración.",
    "go_to_settings": "Ir a Configuración"
  }
}
```

---

## Technical Details

### Validation Logic Flow

```
1. Load saved language → Validate → Apply fallback if needed
2. Load saved version → NEW: Validate against language
3. If version invalid:
   - Reset to default for language
   - Save corrected version
   - Log warning
4. Proceed with data loading
```

### Error Recovery Flow

```
1. Initialization fails
2. Set state to _PageInitializationState.error
3. Show error scaffold with:
   - Friendly message
   - Retry button
   - Settings button
   - Bottom navigation bar (4 options)
4. User can:
   - Retry initialization
   - Go to settings to fix config
   - Navigate to Bible/Prayers
   - Keep using app
```

---

## Testing Scenarios

### Scenario 1: Language/Version Mismatch ✅

```
1. User has Spanish language with Hindi version saved
2. App detects mismatch on startup
3. Resets version to Spanish default (RVR1960)
4. Logs: "Version 'पवित्र बाइबिल (ओ.वी.)' not valid for language 'es', reset to 'RVR1960'"
5. Devotionals load successfully
```

### Scenario 2: Network Error with Recovery ✅

```
1. Device has no internet
2. No local cache available
3. Error scaffold shown with:
   - Clear error message
   - Retry button (when connection restored)
   - Settings button (to change language/version)
   - Bottom bar (to navigate away)
4. User can access Settings → Change to cached language
5. Or wait for connection and retry
```

### Scenario 3: User Stuck → Now Can Navigate ✅

```
Before Fix:
- Error screen
- Only retry button
- No bottom bar
- User STUCK ❌

After Fix:
- Error screen
- Retry + Settings buttons
- Bottom bar with 4 navigation options
- User CAN navigate ✅
```

---

## Files Modified

1. ✅ `/lib/providers/devocional_provider.dart`
    - Added version validation in `initializeData()`

2. ✅ `/lib/pages/devocionales_page.dart`
    - Enhanced `_buildErrorScaffold()` with navigation
    - Added widget keys for testing

3. ✅ `/i18n/en.json`
    - Added `common` section with navigation labels
    - Added error messages

4. ✅ `/i18n/es.json`
    - Added `common` section with navigation labels
    - Added error messages

---

## Prevention Measures

### For Future Language Additions

Always update these in sync:

1. ✅ `Constants.supportedLanguages`
2. ✅ `Constants.bibleVersionsByLanguage`
3. ✅ `Constants.defaultVersionByLanguage`
4. ✅ `DevocionalProvider._supportedLanguages`
5. ✅ `TtsService` locale mappings
6. ✅ Translation files

### Validation Checklist

- [ ] Version validation on app start
- [ ] Version validation on language change
- [ ] Version validation on version change
- [ ] Error recovery UI with navigation
- [ ] Translation keys complete
- [ ] Widget keys for testing

---

## Impact Assessment

**Severity:** CRITICAL - App unusable for affected users  
**Affected Users:** Anyone who switched languages then restarted app  
**Resolution:** Immediate (automatic fix on next app start)  
**User Action Required:** None (auto-fixed) or navigate to settings

---

## Validation

✅ Code compiles without errors  
✅ No analyzer warnings  
✅ Code properly formatted  
✅ Version validation works  
✅ Error recovery UI functional  
✅ Navigation never blocked  
✅ Translation keys added

---

## Expected Behavior After Fix

### On App Start (Auto-Fix):

```
I/flutter: Loading from API for year 2025, language: es, version: RVR1960
I/flutter: 🔍 Requesting URL: .../Devocional_year_2025.json
I/flutter: ✅ Data saved to local storage: .../devocional_2025_es.json
```

### If Error Occurs (Recovery):

```
1. User sees friendly error message
2. Can retry loading
3. Can go to settings
4. Can navigate to Bible/Prayers
5. Never stuck!
```

---

## Related Issues Fixed

- [x] Hindi/Chinese language support (previous fix in same session)
- [x] Devotionals branch selector (feature in same session)
- [x] Language/version mismatch (this fix)
- [x] Stuck UI with no navigation (this fix)

---

## Notes

This fix demonstrates the importance of:

1. **Data validation** at boundaries (loading saved preferences)
2. **Error recovery UX** - always provide escape routes
3. **Defensive programming** - never assume saved data is valid
4. **User-friendly error messages** with actionable solutions

The validation logic now acts as a "self-healing" mechanism that automatically corrects invalid
configurations without user intervention.

