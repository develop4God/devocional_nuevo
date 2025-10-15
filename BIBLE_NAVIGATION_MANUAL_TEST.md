# Bible Verse Navigation Manual Testing Guide

## Overview
This guide provides detailed steps to manually test the new ScrollablePositionedList-based Bible verse navigation and chapter grid selector.

## Test Environment Setup
1. Build and install the app on a test device or emulator
2. Navigate to the Bible reader page
3. Select a Bible version (e.g., RVR1960 for Spanish or KJV for English)

## Test Cases

### Test 1: Psalm 119 Distant Verse Navigation
**Objective:** Verify that scrolling to distant verses in Psalm 119 works accurately regardless of font size.

**Steps:**
1. Open the Bible reader
2. Search for "Salmos 119" (or "Psalms 119" in English)
3. Navigate to Psalm 119, Chapter 119
4. Test the verse grid selector:
   - Tap the "V. 1" button in the top right
   - Select verse 1 - verify it scrolls to verse 1
   - Select verse 20 - verify it scrolls to verse 20
   - Select verse 50 - verify it scrolls to verse 50
   - Select verse 100 - verify it scrolls to verse 100
   - Select verse 176 (last verse) - verify it scrolls to verse 176
5. Increase font size using the font size controls:
   - Tap the format_size icon in the app bar
   - Increase font size to maximum
   - Repeat verse navigation tests (verses 1, 20, 50, 100, 176)
   - Verify all verses scroll correctly
6. Decrease font size to minimum and repeat verse navigation tests
7. Return to normal font size

**Expected Results:**
- ✅ All verse navigation should be accurate regardless of font size
- ✅ Selected verse should appear near the top of the screen (10% from top)
- ✅ No manual offset calculations should cause incorrect positioning
- ✅ Navigation should work smoothly with large and small font sizes

### Test 2: Chapter Grid Selector
**Objective:** Verify the new chapter grid selector works correctly and replaces the dropdown.

**Steps:**
1. Open the Bible reader
2. Navigate to any book (e.g., Genesis)
3. Verify the chapter selector UI:
   - The chapter selector should show as a clickable box with "Cap. 1" (or "Ch. 1")
   - It should have a dropdown arrow icon
   - Tap on the chapter selector
4. In the chapter grid dialog:
   - Verify it shows a grid of chapters (8 columns)
   - Verify the current chapter is highlighted
   - Verify the book name is shown in the header
   - Verify scrollbar appears for books with many chapters
5. Select different chapters:
   - Tap chapter 5 - verify it navigates to chapter 5
   - Tap chapter 10 - verify it navigates to chapter 10
   - Tap chapter 1 - verify it navigates back to chapter 1
6. Test with a book with many chapters:
   - Navigate to Psalms (150 chapters)
   - Open chapter grid selector
   - Scroll through the grid
   - Select chapter 119
   - Verify it loads correctly
7. Test with a single-chapter book:
   - Navigate to Obadiah (1 chapter)
   - Chapter selector should still work
   - Grid should show only chapter 1

**Expected Results:**
- ✅ Chapter grid selector dialog opens smoothly
- ✅ Grid displays chapters in an 8-column layout
- ✅ Current chapter is visually highlighted
- ✅ Scrollbar appears for long books (like Psalms)
- ✅ Chapter selection works and navigates correctly
- ✅ After selection, the page scrolls to the top of the new chapter
- ✅ Selected verses are cleared when changing chapters

### Test 3: Existing Features Regression Test
**Objective:** Ensure all existing Bible reader features still work correctly.

**Steps:**
1. **Verse Selection and Highlighting:**
   - Navigate to John 3
   - Tap on verse 16 - verify it highlights
   - Tap on verse 17 - verify it also highlights
   - Both verses should be selected
   - Bottom sheet should appear with action buttons

2. **Verse Actions (Bottom Sheet):**
   - With verses selected, verify bottom sheet shows:
     - Selected verses count
     - Copy button
     - Share button
     - Save button
   - Test Copy:
     - Tap Copy
     - Verify "Copied to clipboard" message appears
     - Paste in another app to verify content
   - Test Share:
     - Tap Share
     - Verify share dialog opens
   - Test Save (Persistent Marking):
     - Tap Save
     - Verify "Save marked verses" message appears
     - Verses should now be underlined
     - Navigate to another chapter and back
     - Verify marked verses remain underlined

3. **Long Press to Toggle Persistent Mark:**
   - Long press on a verse
   - Verify it gets underlined (persistent mark)
   - Long press again
   - Verify underline is removed

4. **Verse Search:**
   - Enter "amor" (or "love" in English) in search box
   - Press Enter or Search
   - Verify search results appear with highlighted search terms
   - Tap on a search result
   - Verify it navigates to that verse and scrolls to it

5. **Bible Reference Navigation:**
   - Search for "Juan 3:16" (or "John 3:16")
   - Press Enter
   - Verify it navigates directly to John 3:16
   - Test with other references:
     - "Genesis 1:1"
     - "Salmos 23:1" (or "Psalms 23:1")

6. **Book Selector:**
   - Tap on the book name in the selector bar
   - Verify book search dialog opens
   - Type "Juan" (or "John")
   - Verify filtered results appear
   - Select a book
   - Verify it navigates to that book

7. **Previous/Next Chapter Navigation:**
   - Use the arrow buttons in the bottom navigation bar
   - Tap Previous Chapter (<)
   - Verify it goes to previous chapter
   - Tap Next Chapter (>)
   - Verify it goes to next chapter
   - Test at book boundaries:
     - From Genesis 1, Previous should go to previous book (if any)
     - From last chapter of a book, Next should go to next book

8. **Font Size Controls:**
   - Tap the format_size icon
   - Tap + to increase font size
   - Verify text size increases
   - Tap - to decrease font size
   - Verify text size decreases
   - Close font controls
   - Navigate away and back
   - Verify font size is persisted

9. **Version Switching (if multiple versions available):**
   - Tap the menu icon (if multiple versions)
   - Select a different version
   - Verify version loads
   - Verify book/chapter position is maintained

10. **Last Reading Position:**
    - Navigate to a specific book and chapter (e.g., Romans 8)
    - Close the Bible reader
    - Close the app completely
    - Reopen the app
    - Open Bible reader
    - Verify it returns to Romans 8

**Expected Results:**
- ✅ All existing features should work exactly as before
- ✅ No regressions in functionality
- ✅ UI should be responsive and smooth
- ✅ Verse highlighting, marking, and selection work correctly
- ✅ Search and navigation features work correctly
- ✅ Font size controls work correctly
- ✅ Reading position is persisted

### Test 4: Edge Cases
**Objective:** Test edge cases and unusual scenarios.

**Steps:**
1. **Empty/Small Chapters:**
   - Navigate to 3 John 1 (single chapter with few verses)
   - Test verse navigation
   - Verify scrolling works correctly

2. **Very Long Chapters:**
   - Navigate to Psalm 119 (176 verses)
   - Test navigation to first, middle, and last verses
   - Verify performance is good

3. **Rapid Navigation:**
   - Open verse grid selector
   - Rapidly tap different verses (1, 50, 100, 20, 75)
   - Verify each navigation completes successfully

4. **Multiple Font Size Changes:**
   - Increase font to maximum
   - Navigate to verse 100
   - Decrease font to minimum
   - Verify verse 100 is still visible/correct
   - Navigate to verse 1
   - Verify scrolling still works

5. **Offline Usage:**
   - Enable airplane mode
   - Navigate through Bible
   - Verify all features work offline

**Expected Results:**
- ✅ All edge cases handled gracefully
- ✅ No crashes or errors
- ✅ Navigation remains accurate in all scenarios

## Test Results Template

### Test 1: Psalm 119 Distant Verse Navigation
- [ ] Verse 1 navigation: ___
- [ ] Verse 20 navigation: ___
- [ ] Verse 50 navigation: ___
- [ ] Verse 100 navigation: ___
- [ ] Verse 176 navigation: ___
- [ ] Large font size: ___
- [ ] Small font size: ___
- [ ] Normal font size: ___

### Test 2: Chapter Grid Selector
- [ ] Grid displays correctly: ___
- [ ] Chapter highlighting: ___
- [ ] Chapter selection: ___
- [ ] Psalms (150 chapters): ___
- [ ] Single chapter book: ___

### Test 3: Existing Features
- [ ] Verse selection: ___
- [ ] Copy verses: ___
- [ ] Share verses: ___
- [ ] Save/mark verses: ___
- [ ] Long press marking: ___
- [ ] Verse search: ___
- [ ] Reference navigation: ___
- [ ] Book selector: ___
- [ ] Previous/Next chapter: ___
- [ ] Font size controls: ___
- [ ] Version switching: ___
- [ ] Last reading position: ___

### Test 4: Edge Cases
- [ ] Small chapters: ___
- [ ] Very long chapters: ___
- [ ] Rapid navigation: ___
- [ ] Font size changes: ___
- [ ] Offline usage: ___

## Notes
- Add any issues or observations here
- Include screenshots if needed
- Note any unexpected behavior

## Sign-off
- Tester: _______________
- Date: _______________
- Device/Emulator: _______________
- OS Version: _______________
- App Version: _______________
- Result: [ ] PASS [ ] FAIL [ ] NEEDS REVIEW
