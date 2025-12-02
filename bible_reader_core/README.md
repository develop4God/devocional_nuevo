# Bible Reader Core

Core Flutter package for Bible reading functionality in the Devocionales Cristianos app.

## Features

This package provides the core infrastructure for Bible reading functionality:

- **BibleDbService** - SQLite database management for Bible data
- **BiblePreferencesService** - User preferences for Bible reading (version, font size, etc.)
- **BibleReaderController** - Main controller for Bible reading state and navigation
- **BibleReaderService** - Service layer for Bible content operations
- **BibleReaderState** - Immutable state management for Bible reader
- **BibleReadingPositionService** - Save and restore reading positions
- **BibleReferenceParser** - Parse Bible references (e.g., "John 3:16")
- **BibleTextNormalizer** - Normalize text for consistent display
- **BibleVerseFormatter** - Format verses for display
- **BibleVersion** - Bible version model and metadata
- **BibleVersionRegistry** - Registry of available Bible versions

## Getting Started

This package is used internally by the Devocionales Cristianos app and is not intended for standalone use.

### Dependencies

```yaml
dependencies:
  bible_reader_core:
    path: bible_reader_core
```

## Usage

```dart
import 'package:bible_reader_core/bible_reader_core.dart';

// Initialize Bible database
final dbService = BibleDbService();
await dbService.initialize();

// Get verses
final verses = await dbService.getVerses(book: 'Genesis', chapter: 1);
```

## Architecture

```
lib/
├── bible_reader_core.dart        # Package exports
└── src/
    ├── bible_db_service.dart           # Database operations
    ├── bible_preferences_service.dart  # User preferences
    ├── bible_reader_controller.dart    # Main controller
    ├── bible_reader_service.dart       # Service layer
    ├── bible_reader_state.dart         # State management
    ├── bible_reading_position_service.dart  # Position tracking
    ├── bible_reference_parser.dart     # Reference parsing
    ├── bible_text_normalizer.dart      # Text normalization
    ├── bible_verse_formatter.dart      # Verse formatting
    ├── bible_version.dart              # Version model
    └── bible_version_registry.dart     # Version registry
```

## License

This package is part of the Devocionales Cristianos project and is licensed under the [CC BY-NC 4.0 License](../LICENSE).
