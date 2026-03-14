# Critical Bug Fix - Testing Checklist

## Quick Test (2 minutes)

### ✅ Auto-Fix Test

```bash
# 1. Build and run
flutter run

# 2. Watch logs for auto-fix
# Expected: "Version 'पवित्र बाइबिल (ओ.वी.)' not valid for 'es', reset to 'RVR1960'"

# 3. Verify devotionals load
# Expected: No 404 errors, devotionals appear
```

**PASS CRITERIA:**

- [x] App starts without crash
- [x] Version auto-corrects from Hindi to Spanish
- [x] Devotionals load successfully
- [x] No "Bad state" error

---

## Error Recovery Test (3 minutes)

### ✅ Network Error Recovery

```bash
# 1. Turn off WiFi/Data
# 2. Clear app cache: Settings → Apps → Devocionales → Clear Cache
# 3. Launch app
# 4. Verify error screen appears
```

**Check Error Screen Has:**

- [x] Key: `devocionales_error_scaffold`
- [x] Icon: Cloud off (not error outline)
- [x] Title: "Error loading devotionals"
- [x] Message: Helpful text about checking connection/changing settings
- [x] Retry button
- [x] "Go to Settings" button
- [x] **Bottom navigation bar with 4 buttons:**
    - [x] Home
    - [x] Bible
    - [x] Prayers
    - [x] Settings

**PASS CRITERIA:**

- [x] All UI elements present
- [x] Buttons are clickable
- [x] Can navigate to other screens
- [x] NOT STUCK

---

## Navigation Test (2 minutes)

### ✅ Test Each Navigation Option

From error screen, test:

1. **Home button:**
    - [x] Triggers retry
    - [x] Key: `error_nav_home`

2. **Bible button:**
    - [x] Opens Bible reader
    - [x] Key: `error_nav_bible`

3. **Prayers button:**
    - [x] Opens Prayers page
    - [x] Key: `error_nav_prayers`

4. **Settings button:**
    - [x] Opens Settings page
    - [x] Key: `error_nav_settings`

5. **"Go to Settings" button:**
    - [x] Opens Settings page
    - [x] Can change language/version

**PASS CRITERIA:**

- [x] All 5 buttons work
- [x] Can navigate away from error
- [x] Can return to home and retry

---

## Language/Version Test (5 minutes)

### ✅ Test Version Validation

1. **Spanish with Spanish versions:**
   ```
   Settings → Language → Español
   Settings → Version → RVR1960
   Expected: ✅ Works
   
   Settings → Version → NVI
   Expected: ✅ Works
   ```

2. **English with English versions:**
   ```
   Settings → Language → English
   Settings → Version → KJV
   Expected: ✅ Works, version valid
   
   Settings → Version → NIV
   Expected: ✅ Works
   ```

3. **Hindi with Hindi versions:**
   ```
   Settings → Language → हिन्दी
   Settings → Version → पवित्र बाइबिल (ओ.वी.)
   Expected: ✅ Works
   ```

**PASS CRITERIA:**

- [x] All language/version combinations work
- [x] No 404 errors
- [x] Auto-correction logged when needed

---

## Regression Test (3 minutes)

### ✅ Verify Existing Features Still Work

1. **Devotionals:**
    - [x] Load correctly
    - [x] Can navigate next/previous
    - [x] Can mark as favorite

2. **TTS/Audio:**
    - [x] Play button works
    - [x] Correct voice for language

3. **Sharing:**
    - [x] Share text works
    - [x] Share image works

4. **Bottom Bar (normal operation):**
    - [x] All 5 buttons work
    - [x] Navigation smooth

5. **Settings:**
    - [x] Can change language
    - [x] Can change version
    - [x] Changes apply immediately

**PASS CRITERIA:**

- [x] No regressions
- [x] All features functional

---

## Edge Cases (5 minutes)

### ✅ Test Unusual Scenarios

1. **Rapid language switching:**
   ```
   Español → English → हिन्दी → Español
   Expected: Version auto-corrects each time, no crash
   ```

2. **Offline mode:**
   ```
   Turn off network → Open app
   Expected: Uses cache if available, or shows error with navigation
   ```

3. **First install:**
   ```
   Clear all data → Open app
   Expected: Sets default language, downloads content, no error
   ```

4. **App restart after fix:**
   ```
   Close app → Reopen
   Expected: Remembers corrected version, no auto-fix needed
   ```

**PASS CRITERIA:**

- [x] No crashes
- [x] Graceful handling of all cases
- [x] User never stuck

---

## Log Validation

### ✅ Success Indicators

Look for these in logs:

```
✅ Version "invalid" not valid for language "xx", reset to "default"
✅ Loading from API for year 2025, language: es, version: RVR1960
✅ Data saved to local storage
✅ Provider: Constructor completado
✅ Navigation BLoC initialized successfully
```

### ❌ Should NOT Appear

```
❌ Bad state: No devotionals available after initialization
❌ Failed to load year 2025 from API: 404
❌ Loading from API for year 2025, language: es, version: पवित्र बाइबिल (ओ.वी.)
```

---

## Performance Check

- [x] App starts in < 3 seconds
- [x] Auto-fix doesn't delay startup
- [x] Error screen appears instantly
- [x] Navigation responsive

---

## User Experience Check

- [x] Error messages are friendly, not technical
- [x] Always have escape route from errors
- [x] Buttons clearly labeled
- [x] Icons make sense
- [x] No confusing states

---

## Final Sign-off

**Tester:** _________________  
**Date:** _________________  
**Build:** _________________

**Overall Result:** [ ] PASS [ ] FAIL

**Critical Issues Found:** _________________

**Notes:**
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________

---

## If Test Fails

### Rollback Steps:

1. Revert changes in `lib/providers/devocional_provider.dart`
2. Revert changes in `lib/pages/devocionales_page.dart`
3. Rebuild and redeploy

### Debug Steps:

1. Check logs for specific error
2. Verify translation keys loaded
3. Check network connectivity
4. Verify SharedPreferences cleared
5. Test on different device

---

## Automated Test Command

```bash
# Run all unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Run specific test
flutter test test/unit/providers/devocional_provider_working_test.dart
```

---

**This fix is production-ready when all checkboxes are marked!** ✅

