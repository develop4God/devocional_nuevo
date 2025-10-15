# Bible Verse Grid Selector - Manual Testing Guide

## Quick Start
This guide provides step-by-step instructions for manually testing the new verse grid selector feature.

## Prerequisites
- App installed and running
- Access to Bible reader
- Different Bible versions installed (RVR1960, KJV, etc.)

---

## Test Scenario 1: Basic Grid Display

### Steps:
1. Open the app
2. Navigate to Bible tab
3. Select any book (e.g., Genesis)
4. Select chapter 1
5. Click on the verse button (shows "V. 1")

### Expected Results:
- ✅ Grid dialog opens
- ✅ Header shows "Select verse"
- ✅ Header shows "Genesis 1"
- ✅ Shows "31 verses available"
- ✅ Grid displays verses 1-31 in 8 columns
- ✅ Verse 1 is highlighted (primary color)
- ✅ Close button (X) is visible

### Screenshot Points:
- Grid layout with 8 columns
- Header with book and chapter
- Highlighted selected verse
- Scrollbar (if applicable)

---

## Test Scenario 2: Verse Selection and Navigation

### Steps:
1. Open verse grid (as in Scenario 1)
2. Scroll through the grid
3. Tap on verse 16
4. Observe the Bible reader

### Expected Results:
- ✅ Dialog closes automatically
- ✅ Bible reader scrolls to verse 16
- ✅ Verse 16 is positioned in viewport (around 10-20% from top)
- ✅ Verse button now shows "V. 16"

### Test Multiple Selections:
Repeat with verses: 1, 10, 25, 31
- ✅ Each selection updates the button
- ✅ Each selection scrolls to correct verse
- ✅ No lag or stuttering

---

## Test Scenario 3: Psalm 119 (Long Chapter)

### Steps:
1. Navigate to Psalms
2. Select chapter 119
3. Click verse button
4. Observe the grid

### Expected Results:
- ✅ Header shows "Psalms 119"
- ✅ Shows "176 verses available"
- ✅ Scrollbar is visible and functional
- ✅ Can scroll to see all 176 verses
- ✅ Grid remains responsive with many items

### Navigation Test:
1. Tap verse 1 → verify scroll
2. Reopen grid
3. Scroll to bottom
4. Tap verse 176 → verify scroll
5. Reopen grid
6. Tap verse 88 (middle) → verify scroll

### Performance Check:
- ✅ Grid opens quickly (<500ms)
- ✅ Scrolling is smooth
- ✅ No frame drops or lag
- ✅ Taps are responsive

---

## Test Scenario 4: Different Books and Chapters

### Books to Test:

#### Genesis 1 (31 verses)
- ✅ Grid displays 31 items
- ✅ Last verse is 31

#### John 3 (36 verses)
- ✅ Grid displays 36 items
- ✅ Famous verse 16 is accessible

#### Romans 8 (39 verses)
- ✅ Grid displays 39 items
- ✅ All verses accessible

#### Psalm 23 (6 verses)
- ✅ Grid displays 6 items
- ✅ Small grid, no scrolling needed

#### Revelation 22 (21 verses)
- ✅ Grid displays 21 items
- ✅ Last verse is 21

---

## Test Scenario 5: Close Dialog

### Methods to Close:

#### Method 1: Close Button
1. Open verse grid
2. Click X button in header
- ✅ Dialog closes
- ✅ No verse selection made
- ✅ Bible reader remains at current position

#### Method 2: Tap Outside
1. Open verse grid
2. Tap outside the dialog (on gray overlay)
- ✅ Dialog closes
- ✅ No verse selection made

#### Method 3: Select Verse
1. Open verse grid
2. Tap any verse
- ✅ Dialog closes automatically
- ✅ Verse is selected
- ✅ Reader scrolls to verse

---

## Test Scenario 6: Consecutive Selections

### Steps:
1. Navigate to any chapter with 50+ verses
2. Open verse grid
3. Select verse 5
4. Open grid again
5. Select verse 10
6. Repeat for verses: 15, 20, 25, 30, 35, 40, 45, 50

### Expected Results:
- ✅ All 10 selections work correctly
- ✅ No performance degradation
- ✅ Each verse is properly highlighted in grid
- ✅ Each scroll is accurate
- ✅ Button updates each time

---

## Test Scenario 7: Multi-Language Support

### Languages to Test:
- Spanish (es)
- English (en)
- Portuguese (pt)
- French (fr)
- Japanese (ja)

### For Each Language:
1. Change app language in settings
2. Open Bible reader
3. Open verse grid
4. Verify translations:
   - ✅ "Select verse" / "Seleccionar versículo" / etc.
   - ✅ "{count} verses available" / "{count} versículos disponibles" / etc.
   - ✅ "Close" / "Cerrar" / etc.

### Spanish Example:
- Header: "Seleccionar versículo"
- Info: "31 versículos disponibles"
- Button: "Cerrar"

---

## Test Scenario 8: Different Bible Versions

### Versions to Test:
- RVR1960 (Spanish)
- KJV (English)
- NVI (Spanish)
- Any other installed versions

### For Each Version:
1. Switch Bible version
2. Navigate to Genesis 1
3. Open verse grid
4. Verify all functionality works
   - ✅ Grid displays correctly
   - ✅ Verse count matches
   - ✅ Selection works
   - ✅ Scrolling works

---

## Test Scenario 9: Edge Cases

### Test 1: First Verse
1. Navigate to any chapter
2. Open grid
3. Select verse 1
- ✅ Scrolls to top of chapter
- ✅ No errors

### Test 2: Last Verse
1. Navigate to Psalm 119
2. Open grid
3. Scroll to bottom
4. Select verse 176
- ✅ Scrolls to bottom of chapter
- ✅ Verse is visible

### Test 3: Rapid Tapping
1. Open grid
2. Quickly tap multiple verses (5-10 taps in 2 seconds)
- ✅ No crashes
- ✅ Last tap wins
- ✅ Scroll is smooth

### Test 4: Chapter Change
1. Select Genesis 1, verse 20
2. Change to chapter 2
3. Click verse button
- ✅ Grid shows Genesis 2 verses
- ✅ Verse resets to 1
- ✅ Correct verse count

---

## Test Scenario 10: Visual Consistency

### Theme Compatibility:
Test with both Light and Dark modes

#### Light Mode:
- ✅ Grid background is light
- ✅ Selected verse has primary color background
- ✅ Text is readable
- ✅ Icons are visible

#### Dark Mode:
- ✅ Grid background is dark
- ✅ Selected verse has primary color background
- ✅ Text is readable (light on dark)
- ✅ Icons are visible

### Visual Elements:
- ✅ Border radius matches app style
- ✅ Spacing is consistent
- ✅ Font sizes are appropriate
- ✅ Icons match app icon set
- ✅ Colors follow material design

---

## Test Scenario 11: Accessibility

### Font Size:
1. Increase device font size
2. Open verse grid
- ✅ Text scales appropriately
- ✅ Grid remains usable
- ✅ No overflow

### Screen Reader (if applicable):
- ✅ Header is announced
- ✅ Verse numbers are announced
- ✅ Close button is labeled

---

## Test Scenario 12: Performance

### Metrics to Observe:

#### Grid Opening Speed:
- Genesis 1 (31 verses): < 200ms
- Psalm 119 (176 verses): < 500ms

#### Scrolling Performance:
- ✅ Smooth scrolling (60fps)
- ✅ No stuttering
- ✅ Responsive to touch

#### Memory Usage:
- ✅ No memory leaks
- ✅ Consistent performance over time

---

## Common Issues to Watch For

### ❌ Issues NOT Expected:
- Grid doesn't open
- Wrong verse count displayed
- Selected verse not highlighted
- Scroll doesn't work
- Dialog doesn't close
- Verse selection doesn't scroll reader
- Crashes or freezes
- Performance issues
- Translation missing
- Visual glitches

### ✅ Expected Behavior:
- Smooth, responsive grid
- Accurate verse counts
- Proper scrolling
- Clean close/open
- Correct translations
- Visual consistency
- No performance issues

---

## Regression Testing

### Verify Existing Features Still Work:

#### Verse Scrolling:
- ✅ GlobalKey-based scrolling works
- ✅ Scrolling is accurate
- ✅ Works with all font sizes

#### Verse Highlighting:
- ✅ Tap to select verses (for sharing)
- ✅ Long press to mark verses
- ✅ Highlighted verses persist

#### Font Controls:
- ✅ Increase/decrease font
- ✅ Font persists across sessions
- ✅ Scrolling works at all font sizes

#### Chapter Navigation:
- ✅ Previous/next chapter buttons work
- ✅ Chapter dropdown works
- ✅ Book selector works

#### Search:
- ✅ Bible search works
- ✅ Direct reference navigation works
- ✅ Results are accurate

---

## Test Result Template

```
Date: _____________
Tester: _____________
Device: _____________
OS Version: _____________
App Version: _____________

Scenario 1: Basic Grid Display         [ ] Pass  [ ] Fail
Scenario 2: Verse Selection            [ ] Pass  [ ] Fail
Scenario 3: Psalm 119                  [ ] Pass  [ ] Fail
Scenario 4: Different Books            [ ] Pass  [ ] Fail
Scenario 5: Close Dialog               [ ] Pass  [ ] Fail
Scenario 6: Consecutive Selections     [ ] Pass  [ ] Fail
Scenario 7: Multi-Language             [ ] Pass  [ ] Fail
Scenario 8: Different Versions         [ ] Pass  [ ] Fail
Scenario 9: Edge Cases                 [ ] Pass  [ ] Fail
Scenario 10: Visual Consistency        [ ] Pass  [ ] Fail
Scenario 11: Accessibility             [ ] Pass  [ ] Fail
Scenario 12: Performance               [ ] Pass  [ ] Fail
Regression Tests                       [ ] Pass  [ ] Fail

Notes:
_________________________________
_________________________________
_________________________________
```

---

## Video Recording Checklist

If recording a demo video, include:
1. Opening the Bible reader
2. Selecting a book and chapter
3. Clicking the verse button
4. Scrolling through the grid
5. Selecting different verses
6. Showing the reader scrolling to each verse
7. Testing with Psalm 119 (long chapter)
8. Closing the dialog different ways
9. Changing language to show translations

**Recommended Duration:** 2-3 minutes

---

## Contact for Issues

If you encounter any bugs or unexpected behavior during testing:
1. Note the exact steps to reproduce
2. Take screenshots/screen recording
3. Note device and OS version
4. Document expected vs actual behavior
5. Report through the issue tracking system

---

**Last Updated:** October 2025  
**Feature Version:** 1.0  
**Test Coverage:** 15 automated tests + manual scenarios
