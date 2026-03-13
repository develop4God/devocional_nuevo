// lib/models/encounter_index_entry.dart

/// Model for a single entry in the Encounters index.json.
///
/// Parses entries like:
/// ```json
/// {
///   "id": "peter_water_001",
///   "version": "1.0",
///   "emoji": "🌊",
///   "status": "published",
///   "mood_primary": "tense",
///   "accent_color": "#0f1828",
///   "has_interactive": false,
///   "testament": "new",
///   "character": "Peter",
///   "files": { "en": "peter_water_001_en.json" },
///   "titles": { "en": "Peter Walks on Water" },
///   "subtitles": { "en": "Faith Beyond the Storm" },
///   "scripture_reference": { "en": "Matthew 14:22-33" },
///   "estimated_reading_minutes": { "en": 10 }
/// }
/// ```
class EncounterIndexEntry {
  final String id;
  final String version;
  final String? emoji;
  final String status; // 'published' | 'coming_soon'
  final String? moodPrimary;
  final String? accentColor;
  final bool? hasInteractive;
  final String? testament;
  final String? character;

  /// Filename for the cinematic intro background image (bare filename, resolved via CDN).
  final String? introImage;

  /// Optional multilingual release hints shown on coming_soon cards.
  /// Maps language codes to human-readable release dates or labels
  /// (e.g., {"es": "Próxima semana", "en": "Next week"}).
  /// Empty map means no date is shown.
  final Map<String, String> releaseDate;

  final Map<String, String> files;
  final Map<String, String> titles;
  final Map<String, String> subtitles;
  final Map<String, String> scriptureReference;
  final Map<String, int> estimatedReadingMinutes;

  const EncounterIndexEntry({
    required this.id,
    required this.version,
    this.emoji,
    this.status = 'coming_soon',
    this.moodPrimary,
    this.accentColor,
    this.hasInteractive,
    this.testament,
    this.character,
    this.introImage,
    this.releaseDate = const {},
    required this.files,
    required this.titles,
    required this.subtitles,
    required this.scriptureReference,
    required this.estimatedReadingMinutes,
  });

  bool get isPublished => status == 'published';

  String titleFor(String lang) =>
      titles[lang] ?? titles['en'] ?? titles.values.firstOrNull ?? id;

  String subtitleFor(String lang) =>
      subtitles[lang] ?? subtitles['en'] ?? subtitles.values.firstOrNull ?? '';

  String scriptureFor(String lang) =>
      scriptureReference[lang] ??
      scriptureReference['en'] ??
      scriptureReference.values.firstOrNull ??
      '';

  int readingMinutesFor(String lang) =>
      estimatedReadingMinutes[lang] ??
      estimatedReadingMinutes['en'] ??
      estimatedReadingMinutes.values.firstOrNull ??
      5;

  String? fileFor(String lang) => files[lang] ?? files['en'];

  /// Returns the release hint for [lang], falling back to 'en',
  /// then any available value. Returns null if map is empty.
  String? releaseDateFor(String lang) {
    if (releaseDate.isEmpty) return null;
    return releaseDate[lang] ??
        releaseDate['en'] ??
        releaseDate.values.firstOrNull;
  }

  factory EncounterIndexEntry.fromJson(Map<String, dynamic> json) {
    Map<String, String> toStringMap(dynamic raw) {
      if (raw is Map) {
        return Map<String, String>.fromEntries(
          raw.entries.map(
            (e) => MapEntry(e.key.toString(), e.value?.toString() ?? ''),
          ),
        );
      }
      return {};
    }

    Map<String, int> toIntMap(dynamic raw) {
      if (raw is Map) {
        return Map<String, int>.fromEntries(
          raw.entries.map(
            (e) => MapEntry(
              e.key.toString(),
              int.tryParse(e.value?.toString() ?? '') ?? 5,
            ),
          ),
        );
      }
      return {};
    }

    return EncounterIndexEntry(
      id: json['id'] as String? ?? '',
      version: json['version'] as String? ?? '1.0',
      emoji: json['emoji'] as String?,
      status: json['status'] as String? ?? 'coming_soon',
      moodPrimary: json['mood_primary'] as String?,
      accentColor: json['accent_color'] as String?,
      hasInteractive: json['has_interactive'] as bool?,
      testament: json['testament'] as String?,
      character: json['character'] as String?,
      introImage: json['intro_image'] as String?,
      releaseDate: toStringMap(json['release_date']),
      files: toStringMap(json['files']),
      titles: toStringMap(json['titles']),
      subtitles: toStringMap(json['subtitles']),
      scriptureReference: toStringMap(json['scripture_reference']),
      estimatedReadingMinutes: toIntMap(json['estimated_reading_minutes']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'version': version,
        'emoji': emoji,
        'status': status,
        'mood_primary': moodPrimary,
        'accent_color': accentColor,
        'has_interactive': hasInteractive,
        'testament': testament,
        'character': character,
        'intro_image': introImage,
        'release_date': releaseDate.isEmpty ? null : releaseDate,
        'files': files,
        'titles': titles,
        'subtitles': subtitles,
        'scripture_reference': scriptureReference,
        'estimated_reading_minutes': estimatedReadingMinutes,
      };
}
