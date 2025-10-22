# Manual Testing Checklist - System Navigation Bar Fix

## Prerequisites
- Android device or emulator with API level 21+
- Debug APK built with the fix: `flutter build apk --debug`
- Screenshots tool ready (Android Studio screenshot or device screenshot)

## Installation
```bash
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk
```

## Test 1: Verify Navigation Bar on All Pages

### Expected Result
Navigation bar should be **dark gray (#424242)** with **white navigation buttons** on all pages, regardless of theme.

| Page | Light Theme | Dark Theme | Status |
|------|------------|------------|--------|
| devocionales_page | ⬜ Dark gray + white buttons | ⬜ Dark gray + white buttons | ⬜ |
| settings_page | ⬜ Dark gray + white buttons | ⬜ Dark gray + white buttons | ⬜ |
| prayers_page | ⬜ Dark gray + white buttons | ⬜ Dark gray + white buttons | ⬜ |
| favorites_page | ⬜ Dark gray + white buttons | ⬜ Dark gray + white buttons | ⬜ |
| progress_page (stats) | ⬜ Dark gray + white buttons | ⬜ Dark gray + white buttons | ⬜ |
| bible_reader_page | ⬜ Dark gray + white buttons | ⬜ Dark gray + white buttons | ⬜ |
| about_page | ⬜ Dark gray + white buttons | ⬜ Dark gray + white buttons | ⬜ |

**Screenshot naming convention**: `page-name_theme-mode.png`
Example: `devocionales_light.png`, `settings_dark.png`

## Test 2: Verify Navigation Bar Across All Themes

### Theme: Deep Purple (Realeza)
- [ ] Light mode: Dark gray nav bar with white buttons visible
- [ ] Dark mode: Dark gray nav bar with white buttons visible
- [ ] Screenshot: `theme_deep_purple_light.png`, `theme_deep_purple_dark.png`

### Theme: Green (Vida)
- [ ] Light mode: Dark gray nav bar with white buttons visible
- [ ] Dark mode: Dark gray nav bar with white buttons visible
- [ ] Screenshot: `theme_green_light.png`, `theme_green_dark.png`

### Theme: Pink (Pureza)
- [ ] Light mode: Dark gray nav bar with white buttons visible
- [ ] Dark mode: Dark gray nav bar with white buttons visible
- [ ] Screenshot: `theme_pink_light.png`, `theme_pink_dark.png`

### Theme: Cyan (Obediencia)
- [ ] Light mode: Dark gray nav bar with white buttons visible
- [ ] Dark mode: Dark gray nav bar with white buttons visible
- [ ] Screenshot: `theme_cyan_light.png`, `theme_cyan_dark.png`

### Theme: Light Blue (Celestial)
- [ ] Light mode: Dark gray nav bar with white buttons visible
- [ ] Dark mode: Dark gray nav bar with white buttons visible
- [ ] Screenshot: `theme_light_blue_light.png`, `theme_light_blue_dark.png`

## Test 3: Navigation Bar Persistence

### Page Navigation
1. [ ] Start on devocionales_page
2. [ ] Navigate to settings_page
3. [ ] Verify navigation bar stays consistent (no color change)
4. [ ] Navigate to prayers_page
5. [ ] Verify navigation bar stays consistent
6. [ ] Use back button to return to previous page
7. [ ] Verify navigation bar stays consistent

### App State Changes
1. [ ] Open app (fresh start)
2. [ ] Verify navigation bar is dark gray with white buttons
3. [ ] Switch to another app (home button)
4. [ ] Return to app (recent apps)
5. [ ] Verify navigation bar remains consistent
6. [ ] Lock device
7. [ ] Unlock device
8. [ ] Verify navigation bar remains consistent

## Test 4: Device Rotation

1. [ ] Start in portrait mode
2. [ ] Verify navigation bar appearance
3. [ ] Rotate to landscape mode
4. [ ] Verify navigation bar stays consistent (no flicker)
5. [ ] Rotate back to portrait
6. [ ] Verify navigation bar stays consistent

## Test 5: Before/After Comparison

### Before Fix (if available on older build)
Take screenshots showing the problem:
- [ ] devocionales_page: Purple navigation bar
- [ ] settings_page (light): White nav bar with white buttons (not visible)
- [ ] settings_page (dark): Black nav bar with white buttons

### After Fix (current build)
Take screenshots showing the solution:
- [ ] devocionales_page: Dark gray nav bar with white buttons
- [ ] settings_page (light): Dark gray nav bar with white buttons
- [ ] settings_page (dark): Dark gray nav bar with white buttons

## Test 6: Edge Cases

1. [ ] Open app in split-screen mode (if supported)
2. [ ] Verify navigation bar appearance
3. [ ] Test on device with gesture navigation (if available)
4. [ ] Verify navigation bar appearance
5. [ ] Test on device with button navigation (if available)
6. [ ] Verify navigation bar appearance

## Test 7: Visual Inspection

Check that navigation buttons are clearly visible:
- [ ] Back button is white and visible
- [ ] Home button is white and visible
- [ ] Recent apps button is white and visible
- [ ] No color blending or transparency issues
- [ ] Contrast is sufficient for accessibility

## Screenshot Checklist

Save all screenshots to `docs/screenshots/system_navigation_bar/`:

**Critical Screenshots (Minimum Required)**:
1. [ ] `devocionales_page_before.png` - Shows the problem (purple nav bar)
2. [ ] `devocionales_page_after.png` - Shows the fix (dark gray nav bar)
3. [ ] `settings_light_before.png` - Shows white-on-white issue
4. [ ] `settings_light_after.png` - Shows dark gray nav bar
5. [ ] `all_themes_light.png` - Shows consistency across themes
6. [ ] `all_themes_dark.png` - Shows consistency across themes

**Additional Screenshots**:
- Individual page screenshots for each theme
- Rotation test screenshots
- Before/after comparisons

## Gradle Build Verification

Run Gradle build and verify no edge-to-edge warnings:

```bash
cd android
./gradlew assembleDebug 2>&1 | tee build_log.txt
grep -i "deprecated\|warning\|edge-to-edge\|setStatusBarColor\|setNavigationBarColor" build_log.txt
```

Expected: No warnings related to:
- `setStatusBarColor`
- `setNavigationBarColor`
- `setNavigationBarDividerColor`
- Edge-to-edge deprecation

## Final Verification

- [ ] All automated tests pass (20 unit tests + 8 integration tests)
- [ ] Flutter analyze shows no new warnings
- [ ] Gradle build completes without edge-to-edge warnings
- [ ] Navigation bar is consistently dark gray with white buttons
- [ ] Navigation buttons are visible and functional on all pages
- [ ] No visual regressions in app appearance
- [ ] App performance is not affected

## Sign-off

Tested by: __________________
Date: __________________
Device/Emulator: __________________
Android Version: __________________

✅ All tests passed
❌ Issues found (describe): __________________

## Notes

Add any additional observations or issues discovered during testing:

---

