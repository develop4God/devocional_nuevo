# Adding Hindi Bible Database Files

**Note**: The Hindi Bible files have already been added to the repository as of the latest update. This document is kept for reference purposes.

## Current Status

The following files are already present in `assets/biblia/`:
1. **HIOV_hi.SQLite3.gz** - पवित्र बाइबिल (ओ.वी.) (Hindi O.V. Version) - PRIMARY/DEFAULT
2. **ERV_hi.SQLite3.gz** - पवित्र बाइबिल (Easy-to-Read Version) - SECONDARY

## Overview (Historical)

The original issue mentioned two Bible database files, but the correct versions are:
1. **HIOV** - पवित्र बाइबिल (ओ.वी.) (Hindi O.V. Version) - Primary version
2. **ERV-hi** - पवित्र बाइबिल (Easy-to-Read Version) - Secondary version

These need to be:
1. Downloaded from the GitHub issue attachments
2. Extracted
3. Renamed to follow the naming convention
4. Compressed to `.gz` format
5. Added to `assets/biblia/` directory

## Step-by-Step Instructions

### 1. Download the Files

From the GitHub issue #[issue_number], download:
- [BDS.zip](https://github.com/user-attachments/files/25353623/BDS.zip)
- [ERV-hi.zip](https://github.com/user-attachments/files/25353635/ERV-hi.zip)

### 2. Extract the ZIP Files

```bash
# Extract BDS.zip
unzip BDS.zip -d /tmp/bds_extract

# Extract ERV-hi.zip
unzip ERV-hi.zip -d /tmp/erv_extract
```

### 3. Identify the SQLite Database Files

Look for files with `.SQLite3` or `.db` extension in the extracted folders:

```bash
find /tmp/bds_extract -name "*.SQLite3" -o -name "*.db"
find /tmp/erv_extract -name "*.SQLite3" -o -name "*.db"
```

### 4. Rename According to Schema

The files must follow the naming convention: `{VERSION}_{LANGUAGE}.SQLite3`

- BDS Bible → `BDS_hi.SQLite3`
- ERV-hi Bible → `ERV_hi.SQLite3`

```bash
# Example (adjust paths based on actual extracted structure)
cp /tmp/bds_extract/[actual_filename].SQLite3 /tmp/BDS_hi.SQLite3
cp /tmp/erv_extract/[actual_filename].SQLite3 /tmp/ERV_hi.SQLite3
```

### 5. Compress to .gz Format

```bash
# Compress BDS
gzip -c /tmp/BDS_hi.SQLite3 > /tmp/BDS_hi.SQLite3.gz

# Compress ERV
gzip -c /tmp/ERV_hi.SQLite3 > /tmp/ERV_hi.SQLite3.gz
```

### 6. Add to Assets Directory

```bash
# Copy to assets directory
cp /tmp/BDS_hi.SQLite3.gz assets/biblia/
cp /tmp/ERV_hi.SQLite3.gz assets/biblia/
```

### 7. Verify Files

```bash
# Check files are in place
ls -lh assets/biblia/*_hi.SQLite3.gz

# Verify compressed files can be extracted
gunzip -t assets/biblia/BDS_hi.SQLite3.gz
gunzip -t assets/biblia/ERV_hi.SQLite3.gz
```

### 8. Verify Database Structure

After extraction, verify the database has the correct schema:

```bash
# Extract temporarily for testing
gunzip -c assets/biblia/BDS_hi.SQLite3.gz > /tmp/test_bds.db

# Check schema
sqlite3 /tmp/test_bds.db ".schema"

# Expected tables should include:
# - books (id, name, testament, etc.)
# - verses (book_id, chapter, verse, text)
# Or similar structure depending on the database format
```

## Expected File Sizes

The compressed `.gz` files should be around 1.5-2.5 MB each (similar to other Bible versions in `assets/biblia/`).

Current Bible files for reference:
```bash
$ ls -lh assets/biblia/
-rw-r--r-- 1 user user 1.9M ARC_pt.SQLite3.gz
-rw-r--r-- 1 user user 2.2M BDS_fr.SQLite3.gz
-rw-r--r-- 1 user user 1.9M CNVS_zh.SQLite3.gz
# ... etc
```

## Configuration Already Completed

The following configuration has already been added to the codebase:

### Bible Version Registry (`bible_reader_core/lib/src/bible_version_registry.dart`)
```dart
'hi': [
  {'name': 'पवित्र बाइबिल (ओ.वी.)', 'dbFile': 'HIOV_hi.SQLite3'},
  {'name': 'पवित्र बाइबिल', 'dbFile': 'ERV_hi.SQLite3'},
],
```

### Constants (`lib/utils/constants.dart`)
```dart
static const Map<String, String> supportedLanguages = {
  // ...
  'hi': 'हिन्दी',
};

static const Map<String, List<String>> bibleVersionsByLanguage = {
  // ...
  'hi': ['पवित्र बाइबिल (ओ.वी.)', 'पवित्र बाइबिल'],
};

static const Map<String, String> defaultVersionByLanguage = {
  // ...
  'hi': 'पवित्र बाइबिल (ओ.वी.)',
};
```

### Copyright Information (`lib/utils/copyright_utils.dart`)
```dart
'hi': {
  'पवित्र बाइबिल (ओ.वी.)':
      'पवित्र बाइबिल हिन्दी ओ.वी. संस्करण (HIOV) © Bible Society of India. सभी अधिकार सुरक्षित।',
  'पवित्र बाइबिल':
      'पवित्र बाइबिल आसान हिंदी संस्करण (ERV) © 2010 World Bible Translation Center. सभी अधिकार सुरक्षित।',
  'default':
      'पवित्र बाइबिल हिन्दी ओ.वी. संस्करण (HIOV) © Bible Society of India. सभी अधिकार सुरक्षित।',
},
```

## Verification After Adding Files

1. **Build the app:**
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --debug
   ```

2. **Run the app:**
   ```bash
   flutter run
   ```

3. **Test Hindi language:**
   - Go to Settings → Application Language
   - Select "हिन्दी" (Hindi)
   - Wait for download to complete
   - Verify Bible reader opens with Hindi text
   - Switch between the two Hindi Bible versions

4. **Test devotionals:**
   - Ensure devotionals load for Hindi (requires JSON files in the repository)
   - Test TTS (text-to-speech) with Hindi text

## Troubleshooting

### File Not Found Error
- Verify file names exactly match: `BDS_hi.SQLite3.gz` and `ERV_hi.SQLite3.gz`
- Check files are in `assets/biblia/` directory
- Run `flutter clean` and `flutter pub get`

### Database Schema Error
- Verify the database structure matches expected format
- Compare with existing Bible databases (e.g., `RVR1960_es.SQLite3.gz`)
- Check tables and columns match the expected schema

### Compression Issues
- Ensure files are properly compressed with gzip
- Test extraction: `gunzip -t filename.gz`
- Verify compressed file is not corrupted

## Next Steps

After adding the Bible files:
1. Create devotional JSON files for Hindi in the Devocionales-json repository
2. Test the complete Hindi experience (Bible + Devotionals + TTS)
3. Add Hindi translations to `i18n/hi.json` (currently using English as template)
4. Test with real Hindi users for feedback

## Related Files

- Bible Version Registry: `bible_reader_core/lib/src/bible_version_registry.dart`
- Constants: `lib/utils/constants.dart`
- Copyright Utils: `lib/utils/copyright_utils.dart`
- Localization: `lib/services/localization_service.dart`
- TTS Service: `lib/services/tts_service.dart`
- Hindi Translations: `i18n/hi.json`
