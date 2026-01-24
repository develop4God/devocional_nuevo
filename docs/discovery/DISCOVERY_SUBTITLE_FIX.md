# Discovery Bible Studies - Subtitle & Reading Time Fix

## Issue

After adding `subtitles` and `estimated_reading_minutes` to the Discovery index JSON, the Bible
studies were not showing in the app.

## Root Cause

The filtering logic in `discovery_bloc.dart` (line 75) was too strict. It only included studies if
the exact locale existed in the `files` map:

```dart
if (filesMap != null && filesMap.containsKey(locale)) {
filteredStudyIds.add(id);
// ...
}
```

This caused all studies to be filtered out if:

- The device locale didn't exactly match the available locales
- Any locale mismatch occurred

## Solution

Modified the filtering condition to check for the requested locale OR fallback locales ('es' or '
en'):

```dart
// Check if study has files for current locale OR fallback locales
final hasValidFile = filesMap != null &&
    (filesMap.containsKey(locale) ||
        filesMap.containsKey('es') ||
        filesMap.containsKey('en'));

if (
hasValidFile) {
filteredStudyIds.add(id);
// ...
}
```

## Files Modified

### 1. `/lib/blocs/discovery/discovery_bloc.dart`

- **Lines 75-81**: Updated filtering logic to include fallback locales
- This ensures studies with 'es' or 'en' files are always included, even if the exact locale doesn't
  match

### 2. `/test/critical_coverage/discovery_bloc_test.dart`

- **Lines 67-88**: Updated mock index structure to use new JSON format:
    - `title` → `titles` (Map with locale keys)
    - `subtitle` → `subtitles` (Map with locale keys)
    - Added `estimated_reading_minutes` (Map with locale keys)

- **Multiple DiscoveryLoaded instances**: Added required parameters:
    - `studySubtitles: {}`
    - `studyReadingMinutes: {}`

- **Lines 278-300**: Updated RefreshDiscoveryStudies mock index to match new format

## New JSON Structure

The index now supports localized content:

```json
{
  "studies": [
    {
      "id": "morning_star_001",
      "version": "1.2",
      "emoji": "🌟",
      "files": {
        "es": "morning_star_es_001.json",
        "en": "morning_star_en_001.json"
      },
      "titles": {
        "es": "Estrella de la Mañana",
        "en": "The Herald of Light"
      },
      "subtitles": {
        "es": "El testimonio más poderoso sobre la identidad de Jesús",
        "en": "The eternal connection between creation, prophecy, and your heart"
      },
      "estimated_reading_minutes": {
        "es": 6,
        "en": 6
      }
    }
  ]
}
```

## Validation

1. ✅ Code compiles without errors
2. ✅ All test file errors resolved
3. ✅ Fallback mechanism ensures studies always show if they have 'es' or 'en' files

## Testing

Run the following commands to verify:

```bash
# Format code
dart format lib/blocs/discovery/discovery_bloc.dart test/critical_coverage/discovery_bloc_test.dart

# Analyze code
dart analyze lib/blocs/discovery/discovery_bloc.dart

# Run tests
flutter test test/critical_coverage/discovery_bloc_test.dart
```

## Expected Behavior

- Studies will now appear in the app even if the device locale doesn't exactly match
- Studies with 'es' or 'en' files will always be included
- The subtitle and reading time will be displayed correctly from the new JSON structure
