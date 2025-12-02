# Bible Module Features - Usage Examples

## 1. Bible Text Normalization

### Before (Old Regex)
```
Verse text [36†] continues here
```
❌ The `[36†]` would NOT be removed (regex only matched `\w+`)

### After (New Regex)
```
Verse text  continues here
```
✅ The `[36†]` IS removed (regex now matches all bracketed content)

**Other Examples Handled:**
- `[1]` → removed
- `[a]` → removed  
- `[36†]` → removed ✨
- `[a1]` → removed ✨
- `[note]` → removed ✨
- `[*]` → removed ✨

---

## 2. Search Term Highlighting

### Search Query: "amor"

**Before:**
```
Plain text display:
Juan 3:16 - Porque de tal manera amó Dios al mundo...
```

**After:**
```
Highlighted display:
Juan 3:16 - Porque de tal manera [AMOR]ó Dios al mundo...
              (where [AMOR] is bold, underlined, and highlighted)
```

### Visual Styling (Theme-Aware)

**Light Mode:**
- Background: Light primary color container
- Text: Bold, underlined
- Border: Primary color

**Dark Mode:**
- Background: Dark primary color container  
- Text: Bold, underlined
- Border: Primary color

**Multiple Occurrences:**
All instances of the search term are highlighted, case-insensitive.

---

## 3. Direct Bible Reference Navigation

### Supported Reference Formats

#### Spanish Examples:
```
Input: "Juan 3:16"
Result: ✅ Navigates to Gospel of John, Chapter 3, Verse 16

Input: "Génesis 1:1"  
Result: ✅ Navigates to Genesis, Chapter 1, Verse 1

Input: "Gn 9:4"
Result: ✅ Navigates to Genesis, Chapter 9, Verse 4

Input: "1 Juan 3:16"
Result: ✅ Navigates to 1 John, Chapter 3, Verse 16

Input: "1 Corintios 13"
Result: ✅ Navigates to 1 Corinthians, Chapter 13 (all verses)

Input: "S.Juan 3:16"
Result: ✅ Navigates to Gospel of John, Chapter 3, Verse 16
```

#### English Examples:
```
Input: "John 3:16"
Result: ✅ Navigates to Gospel of John, Chapter 3, Verse 16

Input: "Genesis 1:1"
Result: ✅ Navigates to Genesis, Chapter 1, Verse 1

Input: "1 John 5:7"
Result: ✅ Navigates to 1 John, Chapter 5, Verse 7

Input: "Revelation 21"
Result: ✅ Navigates to Revelation, Chapter 21 (all verses)
```

#### Multi-word Book Names:
```
Input: "1 Corintios 13:4"
Result: ✅ Navigates to 1 Corinthians, Chapter 13, Verse 4

Input: "2 Samuel 7:12"
Result: ✅ Navigates to 2 Samuel, Chapter 7, Verse 12
```

### Fallback Behavior

#### Non-Reference Text Search:
```
Input: "amor de Dios"
Result: ✅ Falls back to text search, shows all verses containing "amor de Dios"

Input: "salvación"
Result: ✅ Falls back to text search, shows all verses containing "salvación"
```

#### Invalid References:
```
Input: "InvalidBook 1:1"
Result: ✅ Falls back to text search (book not found)

Input: "Juan 999:1"
Result: ✅ Falls back to text search (chapter doesn't exist)
```

---

## How It Works Together

### User Workflow Example 1: Reference Search
1. User opens Bible reader
2. Types "Juan 3:16" in search box
3. Presses Enter
4. **Result:** Immediately navigates to Gospel of John, Chapter 3
   - The chapter view displays all verses
   - User can immediately read verse 16

### User Workflow Example 2: Text Search
1. User opens Bible reader
2. Types "amor" in search box
3. Presses Enter
4. **Result:** Shows list of search results
   - Each result shows book name, chapter:verse
   - Search term "amor" is highlighted in bold/underline/color
   - All bracketed references are removed from verse text
   - User can tap any result to jump to that verse

### User Workflow Example 3: Abbreviated Reference
1. User opens Bible reader
2. Types "Gn 1:1" in search box
3. Presses Enter
4. **Result:** Parser recognizes "Gn" as Genesis abbreviation
   - Database lookup finds book by short name "Gn"
   - Navigates to Genesis Chapter 1
   - Shows verse 1 and all verses in the chapter

---

## Technical Implementation Notes

### Parser Regex Patterns

**With Verse:**
```regex
^(\d+\s+)?([a-záéíóúñü\s\.]+?)\s+(\d+):(\d+)$
```
Matches: `[number] BookName chapter:verse`

**Without Verse:**
```regex
^(\d+\s+)?([a-záéíóúñü\s\.]+?)\s+(\d+)$
```
Matches: `[number] BookName chapter`

### Database Lookup Strategy

1. **Exact Match:** Case-insensitive exact match on long_name or short_name
2. **Starts With:** If no exact match, find books starting with search term
3. **Contains:** If still no match, find books containing search term

This ensures maximum flexibility in finding books regardless of how the user types the name.

---

## Benefits Summary

### For Users:
1. **Cleaner Reading:** No distracting bracketed references
2. **Easier Searching:** Highlighted terms jump out visually  
3. **Faster Navigation:** Type reference, jump directly there
4. **Flexible Input:** Works with full names, abbreviations, multiple languages

### For Developers:
1. **Maintainable:** Simple, well-tested code
2. **Extensible:** Easy to add more abbreviations or languages
3. **Robust:** Comprehensive test coverage
4. **Backward Compatible:** Graceful fallback to text search
