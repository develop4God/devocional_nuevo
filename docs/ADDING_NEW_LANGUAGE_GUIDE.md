# Complete Guide: Adding a New Language to the Application

This guide provides a comprehensive, step-by-step process for adding support for any new language to the Devocionales application.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Language Configuration](#language-configuration)
3. [Bible Version Setup](#bible-version-setup)
4. [Localization Setup](#localization-setup)
5. [TTS Configuration](#tts-configuration)
6. [Copyright Information](#copyright-information)
7. [Devotional Content](#devotional-content)
8. [Testing](#testing)
9. [Checklist](#checklist)

---

## Prerequisites

Before adding a new language, gather the following:

- **Language Code**: ISO 639-1 code (e.g., 'hi' for Hindi, 'de' for German, 'ru' for Russian)
- **Language Name**: Native name (e.g., 'हिन्दी' for Hindi, 'Deutsch' for German)
- **Bible Database Files**: SQLite3 database files with Bible text in the target language
- **Bible Version Names**: Names of Bible versions in the target language
- **TTS Locale Code**: Text-to-Speech locale (e.g., 'hi-IN', 'de-DE', 'ru-RU')
- **Default Bible Version**: Which version should be the default for this language

---

## Language Configuration

### Step 1: Update Constants

**File:** `lib/utils/constants.dart`

#### 1.1 Add to Supported Languages Map

```dart
static const Map<String, String> supportedLanguages = {
  'es': 'Español',
  'en': 'English',
  'pt': 'Português',
  'fr': 'Français',
  'ja': '日本語',
  'zh': '中文',
  'hi': 'हिन्दी',
  // Add your language here:
  'XX': 'LanguageName',  // Replace XX with ISO code
};
```

#### 1.2 Add Bible Versions for the Language

```dart
static const Map<String, List<String>> bibleVersionsByLanguage = {
  'es': ['RVR1960', 'NVI'],
  // ... other languages
  'XX': ['Version1', 'Version2'],  // Add your versions
};
```

#### 1.3 Set Default Bible Version

```dart
static const Map<String, String> defaultVersionByLanguage = {
  'es': 'RVR1960',
  // ... other languages
  'XX': 'Version1',  // Set default version
};
```

---

## Bible Version Setup

### Step 2: Update Bible Version Registry

**File:** `bible_reader_core/lib/src/bible_version_registry.dart`

#### 2.1 Add Language Name

```dart
static const Map<String, String> _languageNames = {
  'es': 'Español',
  // ... other languages
  'XX': 'LanguageName',
};
```

#### 2.2 Add Bible Version Mappings

```dart
static const Map<String, List<Map<String, String>>> _versionsByLanguage = {
  'es': [
    {'name': 'RVR1960', 'dbFile': 'RVR1960_es.SQLite3'},
    {'name': 'NVI', 'dbFile': 'NVI_es.SQLite3'},
  ],
  // ... other languages
  'XX': [
    {'name': 'Version1', 'dbFile': 'VERSION1_XX.SQLite3'},
    {'name': 'Version2', 'dbFile': 'VERSION2_XX.SQLite3'},
  ],
};
```

**Naming Convention:** `{VERSION_CODE}_{LANGUAGE_CODE}.SQLite3`

Examples:
- English KJV: `KJV_en.SQLite3`
- Hindi ERV: `ERV_hi.SQLite3`
- German Luther: `LUTHER_de.SQLite3`

### Step 3: Prepare Bible Database Files

#### 3.1 Database Schema Requirements

Your SQLite database must contain Bible text. Common schemas include:

**Option A: Standard Schema**
```sql
CREATE TABLE books (
  id INTEGER PRIMARY KEY,
  name TEXT,
  testament TEXT,
  chapter_count INTEGER
);

CREATE TABLE verses (
  id INTEGER PRIMARY KEY,
  book_id INTEGER,
  chapter INTEGER,
  verse INTEGER,
  text TEXT,
  FOREIGN KEY(book_id) REFERENCES books(id)
);
```

**Option B: Flat Schema**
```sql
CREATE TABLE bible (
  book TEXT,
  chapter INTEGER,
  verse INTEGER,
  text TEXT
);
```

Check existing databases in `assets/biblia/*.SQLite3.gz` to see the actual schema used.

#### 3.2 File Preparation Steps

1. **Extract** (if compressed):
   ```bash
   unzip bible-files.zip -d /tmp/bible
   ```

2. **Rename** to follow convention:
   ```bash
   mv original_filename.SQLite3 VERSION_XX.SQLite3
   ```

3. **Verify** database structure:
   ```bash
   sqlite3 VERSION_XX.SQLite3 ".schema"
   sqlite3 VERSION_XX.SQLite3 "SELECT COUNT(*) FROM verses;"
   ```

4. **Compress** to .gz:
   ```bash
   gzip -c VERSION_XX.SQLite3 > VERSION_XX.SQLite3.gz
   ```

5. **Add to assets**:
   ```bash
   cp VERSION_XX.SQLite3.gz assets/biblia/
   ```

6. **Verify** in pubspec.yaml:
   ```yaml
   flutter:
     assets:
       - assets/biblia/
   ```

---

## Localization Setup

### Step 4: Create Translation File

#### 4.1 Create Language JSON File

**File:** `i18n/XX.json` (replace XX with your language code)

```bash
# Copy English template
cp i18n/en.json i18n/XX.json
```

#### 4.2 Update Translation Validator

**File:** `lib/utils/translation_validator.dart`

```dart
const supportedLanguages = [
  'es',
  'en',
  'pt',
  'fr',
  'ja',
  'zh',
  'hi',
  'XX',  // Add your language code
];
```

#### 4.3 Run Validator

```bash
dart run lib/utils/translation_validator.dart XX
```

This will:
- Check for missing keys
- Add "PENDING" placeholders for untranslated strings
- Report validation status

#### 4.4 Translate Strings

Open `i18n/XX.json` and replace all "PENDING" values with actual translations.

**Priority translations** (most visible to users):
- `app.title`
- `devotionals.app_title`
- `settings.*`
- `bible_reader.*`
- `application_language.*`

### Step 5: Add Localization Service Support

**File:** `lib/services/localization_service.dart`

#### 5.1 Add TTS Locale Mapping

```dart
String getTtsLocale() {
  switch (_currentLocale.languageCode) {
    case 'es':
      return 'es-ES';
    // ... other languages
    case 'XX':
      return 'XX-YY';  // e.g., 'hi-IN', 'de-DE'
    default:
      return 'es-ES';
  }
}
```

#### 5.2 Add Language Name

```dart
String getLanguageName(String languageCode) {
  switch (languageCode) {
    case 'es':
      return 'Español';
    // ... other languages
    case 'XX':
      return 'LanguageName';
    default:
      return languageCode;
  }
}
```

---

## TTS Configuration

### Step 6: Configure Text-to-Speech

#### 6.1 Update TTS Service

**File:** `lib/services/tts_service.dart`

```dart
String _getTtsLocaleForLanguage(String language) {
  switch (language) {
    case 'es':
      return 'es-US';
    // ... other languages
    case 'XX':
      return 'XX-YY';  // TTS locale code
    default:
      return 'es-ES';
  }
}
```

#### 6.2 Update Application Language Page

**File:** `lib/pages/application_language_page.dart`

```dart
String _getDefaultLocaleForLanguage(String languageCode) {
  switch (languageCode) {
    case 'es':
      return 'es-ES';
    // ... other languages
    case 'XX':
      return 'XX-YY';
    default:
      return '$languageCode-${languageCode.toUpperCase()}';
  }
}
```

**Common TTS Locale Codes:**
- Hindi: `hi-IN`
- German: `de-DE`
- Russian: `ru-RU`
- Italian: `it-IT`
- Korean: `ko-KR`
- Arabic: `ar-SA`

---

## Copyright Information

### Step 7: Add Copyright Notices

**File:** `lib/utils/copyright_utils.dart`

#### 7.1 Add Copyright Text

```dart
static String getCopyrightText(String language, String version) {
  const Map<String, Map<String, String>> copyrightMap = {
    'es': {
      'RVR1960': '...',
      // ... other versions
    },
    // ... other languages
    'XX': {
      'Version1': 'Copyright text for Version1',
      'Version2': 'Copyright text for Version2',
      'default': 'Default copyright text',
    },
  };
  
  final langMap = copyrightMap[language] ?? copyrightMap['en']!;
  return langMap[version] ?? langMap['default']!;
}
```

#### 7.2 Add Display Names

```dart
static String getBibleVersionDisplayName(String language, String version) {
  final Map<String, Map<String, String>> versionNames = {
    'es': {
      'RVR1960': 'Reina Valera 1960',
      // ...
    },
    // ... other languages
    'XX': {
      'Version1': 'Full Display Name for Version 1',
      'Version2': 'Full Display Name for Version 2',
    },
  };
  
  return versionNames[language]?[version] ?? version;
}
```

**Copyright Guidelines:**
- Research the actual copyright status of each Bible version
- Use exact copyright notices as provided by publishers
- Indicate if a version is Public Domain
- Include © symbol and year when applicable
- Mention the copyright holder's name

---

## Devotional Content

### Step 8: Prepare Devotional JSON Files

Devotionals are stored in a separate GitHub repository: `develop4God/Devocionales-json`

#### 8.1 Create Devotional Files

**Naming Convention:** `Devocional_year_{YEAR}_{LANGUAGE}_{VERSION}.json`

Example for Hindi with ERV version for 2025:
```
Devocional_year_2025_hi_पवित्र बाइबिल (ओ.वी.).json
```

#### 8.2 JSON Structure

```json
[
  {
    "id": "2025-01-01",
    "date": "2025-01-01",
    "versiculo": "Bible verse text",
    "reflexion": "Reflection text",
    "paraMeditar": [
      "Meditation point 1",
      "Meditation point 2",
      "Meditation point 3"
    ],
    "oracion": "Prayer text",
    "version": "Version Name",
    "language": "XX",
    "tags": ["faith", "hope", "love"],
    "imageUrl": "",
    "emoji": "🙏"
  }
]
```

#### 8.3 Upload to Repository

1. Fork/clone `develop4God/Devocionales-json`
2. Add your JSON files to the main branch
3. Commit with descriptive message
4. Create pull request

**URL Format Generated:**
```
https://raw.githubusercontent.com/develop4God/Devocionales-json/refs/heads/main/Devocional_year_{YEAR}_{LANGUAGE}_{VERSION}.json
```

---

## Testing

### Step 9: Comprehensive Testing

#### 9.1 Build and Run

```bash
# Clean build
flutter clean
flutter pub get

# Run tests
flutter test

# Run app
flutter run
```

#### 9.2 Test Language Selection

1. **Navigate to Settings** → Application Language
2. **Select your new language**
3. **Verify download progress** indicator works
4. **Confirm language changes** throughout the app

#### 9.3 Test Bible Reader

1. **Open Bible Reader**
2. **Verify text** displays correctly in the new language
3. **Switch between versions** for the language
4. **Test search functionality**
5. **Test verse selection and navigation**

#### 9.4 Test Devotionals

1. **Go to Devotionals page**
2. **Verify devotionals load** for the new language
3. **Check formatting** of verse, reflection, meditation, prayer
4. **Test navigation** (previous/next devotional)
5. **Test favorites** and sharing features

#### 9.5 Test TTS (Text-to-Speech)

1. **Open a devotional**
2. **Tap the audio/TTS button**
3. **Verify speech** is in correct language
4. **Test pause/resume/stop** controls
5. **Verify voice selection** shows appropriate voices

#### 9.6 Test Offline Mode

1. **Download devotionals** for offline use
2. **Turn off internet connection**
3. **Verify devotionals** still load
4. **Verify Bible reader** still works

---

## Checklist

Use this checklist to ensure all steps are complete:

### Configuration
- [ ] Added language to `supportedLanguages` in Constants
- [ ] Added Bible versions to `bibleVersionsByLanguage`
- [ ] Set default version in `defaultVersionByLanguage`
- [ ] Added language name to Bible Version Registry
- [ ] Added version mappings in `_versionsByLanguage`

### Bible Database Files
- [ ] Prepared SQLite database files
- [ ] Renamed files following naming convention
- [ ] Compressed files to .gz format
- [ ] Added files to `assets/biblia/`
- [ ] Verified files in pubspec.yaml

### Localization
- [ ] Created `i18n/XX.json` file
- [ ] Added language to translation validator
- [ ] Ran translation validator
- [ ] Translated all strings (no "PENDING" values)
- [ ] Added TTS locale in localization service
- [ ] Added language name in localization service

### TTS Configuration
- [ ] Updated `_getTtsLocaleForLanguage()` in TTS service
- [ ] Updated `_getDefaultLocaleForLanguage()` in Application Language page
- [ ] Tested TTS with the new language

### Copyright
- [ ] Added copyright text for each Bible version
- [ ] Added display names for Bible versions
- [ ] Verified copyright accuracy
- [ ] Included proper attribution

### Devotionals
- [ ] Created devotional JSON files
- [ ] Uploaded to Devocionales-json repository
- [ ] Verified URL accessibility
- [ ] Tested devotional loading

### Testing
- [ ] Built app successfully
- [ ] Tested language selection in UI
- [ ] Tested Bible reader with new language
- [ ] Tested devotionals loading
- [ ] Tested TTS functionality
- [ ] Tested offline mode
- [ ] Ran automated tests (`flutter test`)
- [ ] No regression in existing languages

### Documentation
- [ ] Updated README with new language support
- [ ] Documented any language-specific quirks
- [ ] Added example screenshots (optional)

---

## Example: Adding German Language

Here's a concrete example for adding German (de):

### 1. Constants
```dart
'de': 'Deutsch',  // in supportedLanguages
'de': ['LUTHER', 'ELB'],  // in bibleVersionsByLanguage
'de': 'LUTHER',  // in defaultVersionByLanguage
```

### 2. Bible Version Registry
```dart
'de': 'Deutsch',  // in _languageNames
'de': [
  {'name': 'LUTHER', 'dbFile': 'LUTHER_de.SQLite3'},
  {'name': 'ELB', 'dbFile': 'ELB_de.SQLite3'},
],  // in _versionsByLanguage
```

### 3. Files
- `assets/biblia/LUTHER_de.SQLite3.gz`
- `assets/biblia/ELB_de.SQLite3.gz`
- `i18n/de.json`

### 4. TTS Locale
```dart
case 'de':
  return 'de-DE';
```

### 5. Copyright
```dart
'de': {
  'LUTHER': 'Luther Bibel 1984 © Deutsche Bibelgesellschaft.',
  'ELB': 'Elberfelder Bibel © R. Brockhaus Verlag.',
  'default': 'Luther Bibel 1984 © Deutsche Bibelgesellschaft.',
},
```

---

## Troubleshooting

### Common Issues

**Issue:** Language doesn't appear in settings
- **Solution:** Verify language is added to `supportedLanguages` in Constants
- Run `flutter clean` and `flutter pub get`

**Issue:** Bible text doesn't load
- **Solution:** Check database file names match exactly in Bible Version Registry
- Verify `.gz` files are in `assets/biblia/`
- Check database schema is compatible

**Issue:** Devotionals don't load
- **Solution:** Verify JSON files exist in Devocionales-json repository
- Check URL format is correct
- Verify internet connectivity

**Issue:** TTS doesn't work
- **Solution:** Verify TTS locale code is correct
- Check device has TTS voices for the language installed
- Test on physical device (TTS is limited on emulators)

**Issue:** Translations show as PENDING
- **Solution:** Run translation validator: `dart run lib/utils/translation_validator.dart XX`
- Manually edit `i18n/XX.json` to add translations

---

## Resources

### Useful Links
- ISO 639-1 Language Codes: https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
- TTS Locale Codes: https://cloud.google.com/speech-to-text/docs/languages
- SQLite Documentation: https://www.sqlite.org/docs.html
- Flutter Localization: https://flutter.dev/docs/development/accessibility-and-localization/internationalization

### Bible Resources
- Bible.com API: https://scripture.api.bible/
- Bible Gateway: https://www.biblegateway.com/
- YouVersion: https://www.youversion.com/

### Contact
For questions or issues, open an issue on GitHub or contact the development team.

---

**Last Updated:** February 2026
**Version:** 1.0
**Maintainer:** develop4God Team
