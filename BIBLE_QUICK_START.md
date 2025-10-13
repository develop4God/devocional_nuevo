# Bible Multi-Version Support - Quick Start Guide

## For Users

### Opening the Bible

1. Tap the Bible icon from the main menu
2. The app automatically detects your device language
3. You'll see only Bible versions in your language

### Switching Versions

1. Look for the **book icon** in the top-right of the Bible reader
2. Tap it to see available versions
3. Select your preferred version
4. The Bible will reload with your selection

### Searching for Verses

1. Use the **search bar** at the top of the Bible reader
2. Type any word or phrase (e.g., "faith", "love")
3. Press Enter or the search icon
4. Tap any result to jump to that verse
5. Tap the **X** to clear search and return to reading

### Reading Position

- Your position is **automatically saved** when you navigate
- Close the app and reopen - you'll return to where you left off
- Includes book, chapter, and version

### Selecting and Sharing Verses

1. Tap any verse to select it
2. Selected verses are highlighted
3. A bottom sheet appears with options to:
    - **Share** selected verses
    - **Copy** to clipboard
    - **Clear** selection

## For Developers

### Key Components

#### BibleVersionRegistry

```dart
// Get versions for a language
final versions = await
BibleVersionRegistry.getVersionsForLanguage
('es
'
);

// Get all supported languages
final languages
=
BibleVersionRegistry
.
getSupportedLanguages
(
);
// Returns: ['es', 'en', 'pt', 'fr']
```

#### BibleReadingPositionService

```dart

final positionService = BibleReadingPositionService();

// Save position
await
positionService.savePosition
(
bookName: 'John',
bookNumber: 43,
chapter: 3,
verse: 16,
version: 'RVR1960',
languageCode: 'es',
);

// Get last position
final position = await positionService.getLastPosition();
// Returns: {bookName: 'John', bookNumber: 43, chapter: 3, verse: 16, ...}
```

#### BibleDbService Search

```dart

final service = BibleDbService();
await
service.initDb
('assets/biblia/RVR1960_es.SQLite3
'
,
'
RVR1960_es.SQLite3
'
);

// Search for verses
final results = await service.searchVerses('amor');
// Returns: List of up to 100 matching verses with book info
```

### Supported Versions

| Language   | Code | Versions Available |
|------------|------|--------------------|
| Spanish    | es   | RVR1960, NVI       |
| English    | en   | KJV, NIV           |
| Portuguese | pt   | ARC                |
| French     | fr   | LSG1910            |

### Database Files

All Bible databases are located in `assets/biblia/`:

- `RVR1960_es.SQLite3`
- `NVI_es.SQLite3`
- `KJV_en.SQLite3`
- `NIV_en.SQLite3`
- `ARC_pt.SQLite3`
- `LSG1910_fr.SQLite3`

### Integration Example

```dart
import 'dart:ui' as ui;
import 'package:devocional_nuevo/utils/bible_version_registry.dart';
import 'package:devocional_nuevo/pages/bible_verse_formatter.dart';

// In your widget
void openBible() async {
  // Get device language
  final deviceLanguage = ui.PlatformDispatcher.instance.locale.languageCode;

  // Get versions for that language
  List<BibleVersion> versions =
  await BibleVersionRegistry.getVersionsForLanguage(deviceLanguage);

  // Fallback to Spanish if needed
  if (versions.isEmpty) {
    versions = await BibleVersionRegistry.getVersionsForLanguage('es');
  }

  // Navigate to Bible reader
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => BibleReaderPage(versions: versions),
    ),
  );
}
```

### Testing

Run all Bible tests:

```bash
flutter test test/unit/models/bible_version_test.dart \
             test/unit/pages/bible_reader_page_test.dart \
             test/unit/services/bible_db_service_test.dart \
             test/unit/services/bible_reading_position_service_test.dart \
             test/unit/utils/bible_version_registry_test.dart \
             test/bible_text_formatter_test.dart
```

Expected: 30/30 tests passing

### Translations Required

For any new UI elements, add translations to:

- `i18n/en.json`
- `i18n/es.json`
- `i18n/pt.json`
- `i18n/fr.json`

Bible-specific keys are under `"bible": { ... }`

## FAQ

**Q: Can users manually change the language?**  
A: No. The Bible reader only shows versions for the device language. To see other language versions,
users need to change their device language.

**Q: What happens if a user's language isn't supported?**  
A: The app falls back to Spanish (the primary language of the app).

**Q: Do Bible versions download on-demand?**  
A: No. All versions are bundled with the app and work completely offline.

**Q: How is the reading position stored?**  
A: Using `SharedPreferences` in the device's local storage. It persists across app sessions.

**Q: Can I add a new Bible version?**  
A: Yes! Add the SQLite3 file to `assets/biblia/`, then update
`BibleVersionRegistry._versionsByLanguage` with the version info.

**Q: Is there a limit to search results?**  
A: Yes, searches return a maximum of 100 results for performance.

**Q: Can users select multiple verses?**  
A: Yes, tap multiple verses and use the bottom sheet to share or copy them all.

## Architecture

```
User Opens Bible
    ↓
Device Language Detection (ui.PlatformDispatcher)
    ↓
BibleVersionRegistry.getVersionsForLanguage()
    ↓
BibleReaderPage receives filtered versions
    ↓
BibleReadingPositionService.getLastPosition()
    ↓
If position exists → Restore to saved book/chapter
If not → Start at Genesis 1
    ↓
User Reads/Searches/Navigates
    ↓
On chapter change → BibleReadingPositionService.savePosition()
```

## Performance Notes

- **Database Loading**: Databases are lazy-loaded when a version is first selected
- **Search**: Limited to 100 results to prevent UI lag
- **Position Saving**: Debounced - only saves on chapter navigation, not verse taps
- **Memory**: Only one Bible database loaded at a time
- **Assets**: All databases included in app bundle (~34 MB total)

## Future Extensions

The implementation supports:

- ✅ Online version downloads (via `isDownloaded` flag)
- ✅ Verse-level navigation (verse number already saved)
- ✅ Advanced search (current infrastructure can be extended)
- ✅ Cross-version comparison (multiple versions can be loaded)
- ✅ Highlighting system (position service provides foundation)
