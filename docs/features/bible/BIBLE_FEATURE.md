# Bible Feature Documentation

## Overview
The Bible feature provides users with access to read the complete Bible directly within the Devocionales Cristianos app. This feature is integrated from the habitus_faith repository and provides a seamless reading experience.

## Features
- **Complete Bible Access**: Read the full Bible using the RVR1960 (Reina Valera 1960) version
- **Easy Navigation**: Select books and chapters using dropdown menus
- **Verse Selection**: Tap verses to select them for sharing or copying
- **Share Functionality**: Share selected verses via any installed sharing app
- **Copy to Clipboard**: Copy selected verses for use in other apps
- **Multi-language Support**: UI translated to Spanish, English, Portuguese, French, and Japanese

## Technical Implementation

### Database
- **SQLite Database**: Uses sqflite package to store Bible data
- **Database File**: `RVR1960.SQLite3` (5.4 MB) stored in `assets/biblia/`
- **Database Schema**:
  - `books` table: Contains book information (book_number, short_name, long_name)
  - `verses` table: Contains all verses (book_number, chapter, verse, text)

### Components

#### 1. BibleVersion Model (`lib/models/bible_version.dart`)
```dart
class BibleVersion {
  final String name;
  final String assetPath;
  final String dbFileName;
  BibleDbService? service;
}
```

#### 2. BibleDbService (`lib/services/bible_db_service.dart`)
Database service that handles:
- Database initialization and copying from assets
- Querying books, chapters, and verses
- Providing read-only access to Bible data

#### 3. BibleReaderPage (`lib/pages/bible_reader_page.dart`)
Main UI component that provides:
- Book and chapter selection dropdowns
- Verse display with formatting
- Verse selection and highlighting
- Bottom sheet for sharing/copying selected verses

### User Interface

#### Access Point
- **Location**: Bottom bar in Devocionales page
- **Icon**: `Icons.menu_book_outlined` (book icon)
- **Tooltip**: Localized "Bible" text

#### Navigation Flow
1. User taps Bible icon in bottom bar
2. App navigates to BibleReaderPage
3. Page loads with Genesis Chapter 1 by default
4. User can select different books and chapters
5. User can tap verses to select them
6. User can share or copy selected verses

### Translations

All UI text is available in 5 languages:
- **Spanish**: Biblia, Capítulo, etc.
- **English**: Bible, Chapter, etc.
- **Portuguese**: Bíblia, Capítulo, etc.
- **French**: Bible, Chapitre, etc.
- **Japanese**: 聖書, 章, etc.

Translation keys in `i18n/*.json`:
```json
{
  "bible": {
    "title": "Bible",
    "loading": "Loading Bible...",
    "chapter": "Ch. {number}",
    "selected_verses": "{count} verses selected",
    "share": "Share",
    "copy": "Copy",
    "clear_selection": "Clear selection",
    "copied_to_clipboard": "Copied to clipboard",
    "no_verses": "No verses"
  }
}
```

### Testing

Created 13 unit tests covering:
- **BibleVersion Model**: Creation, initialization, service assignment
- **BibleDbService**: Service creation and method availability
- **BibleReaderPage**: Widget creation, loading states, navigation

All tests pass successfully.

## Dependencies

New dependencies added to `pubspec.yaml`:
- `sqflite: ^2.3.0` - SQLite database
- `path: ^1.9.0` - Path manipulation

Existing dependencies used:
- `path_provider: ^2.1.5` - Get document directory for database
- `share_plus: ^11.0.0` - Share functionality
- `flutter/services.dart` - Clipboard and asset loading

## Future Enhancements

Potential improvements:
1. Add more Bible versions (NIV, NVI, KJV, etc.)
2. Add search functionality
3. Add bookmarks and highlights
4. Add reading plans
5. Add notes and annotations
6. Add verse-by-verse audio
7. Sync across devices

## File Structure

```
lib/
├── models/
│   └── bible_version.dart          # Bible version model
├── services/
│   └── bible_db_service.dart       # Database service
└── pages/
    └── bible_reader_page.dart      # Main Bible reader UI

assets/
└── biblia/
    └── RVR1960.SQLite3             # Bible database (5.4 MB)

test/
└── unit/
    ├── models/
    │   └── bible_version_test.dart
    ├── services/
    │   └── bible_db_service_test.dart
    └── pages/
        └── bible_reader_page_test.dart

i18n/
├── es.json                         # Spanish translations
├── en.json                         # English translations
├── pt.json                         # Portuguese translations
├── fr.json                         # French translations
└── ja.json                         # Japanese translations
```

## Maintenance Notes

- Database is read-only to prevent accidental modifications
- Database is copied from assets to documents directory on first use
- Subsequent app launches use the copied database for faster access
- Database file should not be modified directly
- To update Bible content, replace the SQLite file in assets and increment app version

## Integration with Devocionales Page

The Bible feature is integrated into the main Devocionales page:
- Added Bible icon button to bottom navigation bar
- Icon positioned between Prayers and Share icons
- Uses existing app theme and styling
- Maintains consistent navigation patterns
- Does not interfere with existing functionality

## Performance Considerations

- Database size: 5.4 MB (acceptable for mobile apps)
- Initial load: Database copied from assets on first launch
- Query performance: Indexed by book_number and chapter
- Memory usage: Only loads one chapter at a time
- Lazy loading: Database service initialized when needed
