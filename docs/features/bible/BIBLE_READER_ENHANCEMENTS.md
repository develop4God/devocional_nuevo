# Bible Reader Enhancements - User Guide

## Overview
This document describes the three new enhancements added to the Bible reader based on user feedback.

---

## 1. Font Size Adjustment

### How to Use
- Look for the font size controls below the book/chapter selectors
- **Decrease font size**: Tap the `-A` button
- **Increase font size**: Tap the `+A` button
- Current font size is displayed in the center

### Features
- **Range**: 12 to 30 pixels
- **Step**: Adjusts by 2 pixels each tap
- **Persistence**: Your font size preference is saved and restored when you reopen the app
- **Visual feedback**: The current size is shown in a badge between the buttons

### Example
```
Starting size: 18
Tap [+A] → 20
Tap [+A] → 22
Tap [-A] → 20
```

---

## 2. Persistent Verse Highlighting

### How to Use
- **Mark a verse**: Long press (press and hold) on any verse
- **Unmark a verse**: Long press again on the same verse
- Marked verses appear with underline decoration

### Features
- **Visual indicator**: Marked verses are underlined with secondary theme color
- **Persistence**: Marked verses are saved and restored across app sessions
- **Independent**: Works separately from verse selection for sharing
- **Theme-aware**: Underline color adapts to light/dark theme

### Visual Style
- **Underline color**: Secondary theme color
- **Underline thickness**: 2 pixels
- **Text weight**: Medium bold (500)

### Difference from Selection
- **Selection** (single tap): Temporary, for sharing/copying
  - Shows with border and background highlight
  - Cleared when changing chapters
  
- **Marking** (long press): Permanent, for bookmarking
  - Shows with underline
  - Persists across sessions and navigation

### Tip
Look for the info icon (ℹ️) next to the font controls for a quick reminder:
_"Long press verses to mark/unmark permanently"_

---

## 3. Enhanced Reading Position Tracking

### How It Works
The app automatically saves your reading position and restores it when you:
- Close and reopen the app
- Navigate to other pages and return to Bible reader

### What Gets Saved
- Current book (e.g., "Juan", "Genesis")
- Current chapter number
- Bible version (e.g., "RVR1960")
- Language code

### Behavior
- **On app startup**: Automatically navigates to your last reading position
- **On book change**: Position is updated and saved
- **On chapter change**: Position is updated and saved
- **No more Genesis 1**: You'll continue where you left off!

### Example Flow
1. User reads Juan 3:16
2. User closes app
3. User reopens app
4. → App opens directly to Juan chapter 3 ✅

---

## Technical Details

### Data Storage
All preferences are stored using `SharedPreferences`:

```dart
// Font size
'bible_font_size': double (default: 18.0)

// Marked verses
'bible_marked_verses': List<String> (format: "book|chapter|verse")

// Reading position
'bible_last_book': String
'bible_last_book_number': int
'bible_last_chapter': int
'bible_last_verse': int
'bible_last_version': String
'bible_last_language': String
```

### Verse Key Format
Verses are identified using the format: `"bookName|chapter|verse"`

Examples:
- `"Juan|3|16"` → Gospel of John, Chapter 3, Verse 16
- `"Genesis|1|1"` → Genesis, Chapter 1, Verse 1
- `"1 Corintios|13|4"` → 1 Corinthians, Chapter 13, Verse 4

---

## UI Layout

### Font Controls Bar
```
┌─────────────────────────────────────────────┐
│  [-A]    [18]    [+A]    [ℹ️ Info]          │
└─────────────────────────────────────────────┘
```

### Verse Display
```
Normal verse:
  1 En el principio creó Dios...

Selected verse (for sharing):
  ╔═══════════════════════════════════════╗
  ║ 1 En el principio creó Dios...       ║
  ╚═══════════════════════════════════════╝

Marked verse (persistent):
  1 En el principio creó Dios...
    ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

Selected + Marked verse:
  ╔═══════════════════════════════════════╗
  ║ 1 En el principio creó Dios...       ║
  ║   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾        ║
  ╚═══════════════════════════════════════╝
```

---

## Testing

### Manual Testing Checklist

#### Font Size
- [ ] Decrease font size from 18 to 16, 14, 12
- [ ] Try to decrease below 12 (should not decrease)
- [ ] Increase font size from 18 to 20, 22, 24
- [ ] Increase to maximum (30)
- [ ] Try to increase above 30 (should not increase)
- [ ] Close and reopen app (font size should be restored)

#### Marked Verses
- [ ] Long press on a verse to mark it
- [ ] Verify underline appears
- [ ] Long press again to unmark
- [ ] Verify underline disappears
- [ ] Mark multiple verses in same chapter
- [ ] Navigate to different chapter and back
- [ ] Verify marks persist
- [ ] Close and reopen app
- [ ] Verify marks persist across sessions

#### Reading Position
- [ ] Open to Genesis 1
- [ ] Navigate to Juan 3
- [ ] Close app
- [ ] Reopen app
- [ ] Verify it opens to Juan 3 (not Genesis 1)
- [ ] Navigate to Exodus 20
- [ ] Switch to different Bible version
- [ ] Navigate to Psalms 23
- [ ] Close and reopen
- [ ] Verify position is restored

### Automated Tests
All features are covered by unit tests:
- Font size: 6 tests ✅
- Marked verses: 5 tests ✅
- Position persistence: 5 tests ✅

Run tests with:
```bash
flutter test test/unit/pages/bible_reader_enhancements_test.dart
```

---

## Troubleshooting

### Font size doesn't change
- Check if buttons are responsive
- Verify you're not at min (12) or max (30) limit
- Clear app data and restart

### Marked verses disappeared
- Check if you're in the correct book/chapter
- Marked verses are book+chapter+verse specific
- Clear app cache may remove marks (by design)

### Position not restored
- Verify you're using the same Bible version
- Check if the book/chapter exists in current version
- Some Bible versions may have different book numberings

---

## Future Enhancements (Optional)

Possible improvements for future releases:
1. Export/import marked verses
2. Organize marks by tags or categories
3. Add notes to marked verses
4. Highlight with different colors
5. Sync marks across devices
6. Search within marked verses only
