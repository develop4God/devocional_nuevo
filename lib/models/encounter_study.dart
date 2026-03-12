// lib/models/encounter_study.dart

import 'package:devocional_nuevo/models/encounter_card_model.dart';

/// Model for an individual encounter study JSON file.
class EncounterStudy {
  final String id;
  final String? type;
  final String? schemaVersion;
  final String? language;
  final String? bibleVersion;
  final String? version;
  final int? estimatedReadingMinutes;
  final Map<String, dynamic>? meta;
  final EncounterKeyVerse? keyVerse;
  final List<EncounterCard> cards;

  const EncounterStudy({
    required this.id,
    this.type,
    this.schemaVersion,
    this.language,
    this.bibleVersion,
    this.version,
    this.estimatedReadingMinutes,
    this.meta,
    this.keyVerse,
    required this.cards,
  });

  int get cardCount => cards.length;

  factory EncounterStudy.fromJson(Map<String, dynamic> json) {
    final encounterId = json['id'] as String? ?? '';
    return EncounterStudy(
      id: encounterId,
      type: json['type'] as String?,
      schemaVersion: json['schema_version'] as String?,
      language: json['language'] as String?,
      bibleVersion: json['bible_version'] as String?,
      version: json['version'] as String?,
      estimatedReadingMinutes: json['estimated_reading_minutes'] as int?,
      meta: json['meta'] as Map<String, dynamic>?,
      keyVerse: json['key_verse'] != null
          ? EncounterKeyVerse.fromJson(
              json['key_verse'] as Map<String, dynamic>)
          : null,
      cards: (json['cards'] as List<dynamic>?)
              ?.map((e) => EncounterCard.fromJson(e as Map<String, dynamic>,
                  encounterId: encounterId))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (type != null) 'type': type,
        if (schemaVersion != null) 'schema_version': schemaVersion,
        if (language != null) 'language': language,
        if (bibleVersion != null) 'bible_version': bibleVersion,
        if (version != null) 'version': version,
        if (estimatedReadingMinutes != null)
          'estimated_reading_minutes': estimatedReadingMinutes,
        if (meta != null) 'meta': meta,
        if (keyVerse != null) 'key_verse': keyVerse!.toJson(),
        'cards': cards.map((c) => c.toJson()).toList(),
      };
}
