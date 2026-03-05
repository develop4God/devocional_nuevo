# Testing Checklist - Hindi & Chinese Language Support Fix

## Pre-Testing Verification ✅

- [x] Code compiles without errors
- [x] No analyzer warnings
- [x] Code properly formatted
- [x] Hindi added to `_supportedLanguages` in DevocionalProvider
- [x] Hindi TTS locale added to TtsService
- [x] Chinese TTS locale added to TtsService
- [x] Documentation created

---

## Manual Testing Steps

### Test 1: Hindi Language Switch

1. [ ] Launch the app
2. [ ] Navigate to Settings → Language
3. [ ] Select **हिन्दी (Hindi)**
4. [ ] Wait for devotionals to load
5. [ ] **Expected:** Devotionals load successfully (no 404 errors)
6. [ ] **Verify:** Language displays as Hindi in UI
7. [ ] **Verify:** Bible version shows as "पवित्र बाइबिल (ओ.वी.)"
8. [ ] Open a devotional and tap the TTS/audio button
9. [ ] **Expected:** Hindi voice reads the text
10. [ ] Check logs for correct URL:
    ```
    Requesting URL: .../Devocional_year_2025_hi_पवित्र बाइबिल (ओ.वी.).json
    ```

### Test 2: Chinese Language Switch

1. [ ] Navigate to Settings → Language
2. [ ] Select **中文 (Chinese)**
3. [ ] Wait for devotionals to load
4. [ ] **Expected:** Devotionals load successfully
5. [ ] **Verify:** Language displays as Chinese in UI
6. [ ] **Verify:** Bible version shows as "和合本1919"
7. [ ] Open a devotional and tap the TTS/audio button
8. [ ] **Expected:** Chinese voice reads the text
9. [ ] Check logs for correct URL:
    ```
    Requesting URL: .../Devocional_year_2025_zh_和合本1919.json
    ```

### Test 3: Switch Between Languages

1. [ ] Start with Spanish (Español)
2. [ ] Switch to Hindi (हिन्दी)
3. [ ] **Expected:** Clean transition, devotionals reload
4. [ ] Switch to Chinese (中文)
5. [ ] **Expected:** Clean transition, devotionals reload
6. [ ] Switch to Japanese (日本語)
7. [ ] **Expected:** Clean transition, devotionals reload
8. [ ] Switch back to Spanish (Español)
9. [ ] **Expected:** Clean transition, devotionals reload

### Test 4: Bible Version Selection (Hindi)

1. [ ] Set language to Hindi
2. [ ] Open drawer menu
3. [ ] Tap on Bible Version selector
4. [ ] **Verify:** Two versions available:
    - पवित्र बाइबिल (ओ.वी.)
    - पवित्र बाइबिल
5. [ ] Switch between versions
6. [ ] **Expected:** Smooth version change, devotionals reload

### Test 5: Bible Version Selection (Chinese)

1. [ ] Set language to Chinese
2. [ ] Open drawer menu
3. [ ] Tap on Bible Version selector
4. [ ] **Verify:** Two versions available:
    - 和合本1919
    - 新译本
5. [ ] Switch between versions
6. [ ] **Expected:** Smooth version change, devotionals reload

### Test 6: TTS Voice Selection

1. [ ] Set language to Hindi
2. [ ] Go to Settings → TTS Settings
3. [ ] **Verify:** Hindi voices are available and selectable
4. [ ] Select a Hindi voice
5. [ ] Test playback
6. [ ] Repeat for Chinese

### Test 7: Discovery Studies (if enabled)

1. [ ] Set language to Hindi
2. [ ] Navigate to Discovery Studies
3. [ ] **Expected:** Studies load in Hindi (if available)
4. [ ] Repeat for Chinese

---

## Log Verification

### ✅ Success Indicators

Look for these in the logs:

```
✅ Loading from API for year 2025, language: hi, version: पवित्र बाइबिल (ओ.वी.)
✅ Requesting URL: .../Devocional_year_2025_hi_पवित्र बाइबिल (ओ.वी.).json
✅ Data saved to local storage: .../devocional_2025_hi.json
✅ TTS: Language context set to hi (पवित्र बाइबिल (ओ.वी.))
✅ TTS: Changing voice language to hi-IN
```

### ❌ Error Indicators (should NOT appear)

```
❌ Loading from API for year 2025, language: es, version: पवित्र बाइबिल (ओ.वी.)
❌ Failed to load year 2025 from API: 404
❌ Language hi not available, using es
❌ Exception: No devotionals loaded from any year
```

---

## Automated Tests

Run these test suites:

```bash
# Hindi language support tests
flutter test test/unit/utils/hindi_language_support_test.dart

# Chinese language integration tests
flutter test test/unit/chinese_language_integration_test.dart

# Constants validation tests
flutter test test/unit/utils/constants_validation_test.dart

# DevocionalProvider tests
flutter test test/unit/providers/devocional_provider_working_test.dart
```

### Expected Results

- All tests should pass ✅
- No test failures
- No warnings or errors

---

## Regression Testing

### Languages That Should Still Work

1. [ ] Spanish (Español) - Default
2. [ ] English (English)
3. [ ] Portuguese (Português)
4. [ ] French (Français)
5. [ ] Japanese (日本語)

### Features That Should Still Work

1. [ ] Favorites (add/remove)
2. [ ] Reading tracking
3. [ ] Daily notifications
4. [ ] Offline mode
5. [ ] Share functionality
6. [ ] Bible reader integration
7. [ ] Prayer journal
8. [ ] Statistics/badges

---

## Performance Checks

1. [ ] App starts without delays
2. [ ] Language switching is responsive (< 2 seconds)
3. [ ] TTS initialization doesn't block UI
4. [ ] Devotionals load in reasonable time
5. [ ] No memory leaks when switching languages multiple times

---

## Edge Cases

### Test: No Internet Connection

1. [ ] Turn off internet
2. [ ] Switch to Hindi
3. [ ] **Expected:** Uses cached devotionals if available
4. [ ] **Expected:** Shows offline mode indicator

### Test: First Time Language Selection

1. [ ] Clear app data
2. [ ] Launch app
3. [ ] Select Hindi as first language
4. [ ] **Expected:** Downloads Hindi devotionals
5. [ ] **Expected:** Sets Hindi as default

### Test: Missing Devotional Files

1. [ ] Use Debug page to switch to test branch
2. [ ] Switch to Hindi
3. [ ] **Expected:** Falls back to default version if file missing
4. [ ] **Expected:** Shows error message if no version available

---

## Documentation Verification

1. [ ] Bug fix documentation created
2. [ ] Technical details documented
3. [ ] Testing steps documented
4. [ ] Known limitations documented (if any)

---

## Sign-off

**Tester Name:** _________________  
**Date:** _________________  
**Result:** [ ] Pass [ ] Fail

**Notes:**
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________

---

## Known Limitations

1. **TTS Voice Availability:** Hindi and Chinese TTS depend on device having appropriate voices
   installed
2. **Devotional Content:** Hindi/Chinese devotionals must exist in the repository
3. **Internet Required:** First-time language switch requires internet to download devotionals

---

## Rollback Plan (If Needed)

If critical issues are found:

1. Remove `'hi'` from `_supportedLanguages` in `lib/providers/devocional_provider.dart`
2. Remove Hindi/Chinese cases from `_updateTtsLanguageSettings()` in `lib/services/tts_service.dart`
3. Rebuild and redeploy
4. This will restore pre-fix behavior (Hindi/Chinese disabled)

**Note:** Only use rollback if critical production issues occur. Otherwise, fix forward.

