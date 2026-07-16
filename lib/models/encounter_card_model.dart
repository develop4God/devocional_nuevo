// lib/models/encounter_card_model.dart

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/models/encounter_card_contract.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

/// Union-type model for all encounter card types.
///
/// Supported types:
///   cinematic_scene | scripture_moment | character_moment |
///   theological_depth | discovery_activation | completion |
///   interactive_moment | unknown
///
/// See encounter_card_contract.dart (kEncounterCardRenderedFields) for the
/// authoritative list of which fields each card `type` renders. Do not
/// trust per-widget inspection alone — check the contract map first.
class EncounterCard {
  final int order;
  final String type;

  // Shared optional fields
  final String? mood;
  final String? imageUrl;
  final String? imageVersion; // NEW — for cacheKey construction
  final String? encounterId; // NEW — for cacheKey construction
  final String? title;
  final String? narrative;

  /// Rendered via _ModernVerseOverlay. One of three verse mechanisms — see verseReference/verseText and scriptureConnections.
  final VerseRef? verseOverlay;

  /// Rendered via _ModernRevelationKey. See kEncounterCardRenderedFields in encounter_card_contract.dart for which card types render this.
  final String? revelationKey;

  /// Reserved for future implementation — not yet rendered by any card widget.
  final String? ambientSound;

  /// Reserved for future implementation — not yet rendered by any card widget.
  final String? haptic;
  final String? icon;
  final String? subtitle;
  final String? content;

  /// Flat inline verse pair. Rendered together by ScriptureMomentCard. Use verseOverlay instead for a styled single-verse moment.
  final String? verseReference;

  /// Flat inline verse pair. Rendered together by ScriptureMomentCard. Use verseOverlay instead for a styled single-verse moment.
  final String? verseText;
  final String? reflection;
  final List<EncounterDiscoveryQuestion>? discoveryQuestions;
  final EncounterPrayer? prayer;
  final VerseRef? completionVerse;
  final String? reflectionPrompt;

  /// Rendered via _ScriptureConnectionsSection. List-of-supporting-verses role — distinct from the single-emphasis verseOverlay.
  final List<VerseRef>? scriptureConnections;

  const EncounterCard({
    required this.order,
    required this.type,
    this.mood,
    this.imageUrl,
    this.imageVersion, // NEW
    this.encounterId, // NEW
    this.title,
    this.narrative,
    this.verseOverlay,
    this.revelationKey,
    this.ambientSound,
    this.haptic,
    this.icon,
    this.subtitle,
    this.content,
    this.verseReference,
    this.verseText,
    this.reflection,
    this.discoveryQuestions,
    this.prayer,
    this.completionVerse,
    this.reflectionPrompt,
    this.scriptureConnections,
  });

  /// Resolves an image_url value from JSON:
  /// - Returns null if the value is null or empty.
  /// - Returns the value as-is if it already starts with 'http'.
  /// - Otherwise strips extension and returns base name only.
  ///   EncounterImageWidget owns format + URL resolution (SRP).
  static String? _resolveImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) {
      return raw; // absolute URLs: pass through unchanged
    }
    // Store base name only — EncounterImageWidget owns format + URL resolution (SRP)
    return raw.contains('.') ? raw.substring(0, raw.lastIndexOf('.')) : raw;
  }

  factory EncounterCard.fromJson(
    Map<String, dynamic> json, {
    required String encounterId,
    String? imageVersion, // NEW
  }) {
    // Unknown type handling — never crash
    final String rawType = json['type'] as String? ?? 'unknown';
    const knownTypes = {
      'cinematic_scene',
      'scripture_moment',
      'character_moment',
      'theological_depth',
      'discovery_activation',
      'completion',
      'interactive_moment',
    };
    final String type = knownTypes.contains(rawType) ? rawType : 'unknown';

    final card = EncounterCard(
      order: json['order'] as int? ?? 0,
      type: type,
      mood: json['mood'] as String?,
      imageUrl: _resolveImageUrl(json['image_url'] as String?),
      imageVersion: imageVersion, // NEW — passed from EncounterStudy.fromJson
      encounterId: encounterId, // NEW — passed from EncounterStudy.fromJson
      title: json['title'] as String?,
      narrative: json['narrative'] as String?,
      verseOverlay: json['verse_overlay'] != null
          ? VerseRef.fromJson(json['verse_overlay'] as Map<String, dynamic>)
          : null,
      revelationKey: json['revelation_key'] as String?,
      ambientSound: json['ambient_sound'] as String?,
      haptic: json['haptic'] as String?,
      icon: json['icon'] as String?,
      subtitle: json['subtitle'] as String?,
      content: json['content'] as String?,
      verseReference: json['verse_reference'] as String?,
      verseText: json['verse_text'] as String?,
      reflection: json['reflection'] as String?,
      discoveryQuestions: (json['discovery_questions'] as List<dynamic>?)
          ?.map(
            (e) =>
                EncounterDiscoveryQuestion.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      prayer: json['prayer'] != null
          ? EncounterPrayer.fromJson(json['prayer'] as Map<String, dynamic>)
          : null,
      completionVerse: json['completion_verse'] != null
          ? VerseRef.fromJson(json['completion_verse'] as Map<String, dynamic>)
          : null,
      reflectionPrompt: json['reflection_prompt'] as String?,
      scriptureConnections: (json['scripture_connections'] as List<dynamic>?)
          ?.map((e) => VerseRef.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

    _debugCheckEncounterCardContract(card);

    return card;
  }

  Map<String, dynamic> toJson() => {
        'order': order,
        'type': type,
        if (mood != null) 'mood': mood,
        if (imageUrl != null) 'image_url': imageUrl,
        if (title != null) 'title': title,
        if (narrative != null) 'narrative': narrative,
        if (verseOverlay != null) 'verse_overlay': verseOverlay!.toJson(),
        if (revelationKey != null) 'revelation_key': revelationKey,
        if (ambientSound != null) 'ambient_sound': ambientSound,
        if (haptic != null) 'haptic': haptic,
        if (icon != null) 'icon': icon,
        if (subtitle != null) 'subtitle': subtitle,
        if (content != null) 'content': content,
        if (verseReference != null) 'verse_reference': verseReference,
        if (verseText != null) 'verse_text': verseText,
        if (reflection != null) 'reflection': reflection,
        if (discoveryQuestions != null)
          'discovery_questions':
              discoveryQuestions!.map((q) => q.toJson()).toList(),
        if (prayer != null) 'prayer': prayer!.toJson(),
        if (completionVerse != null)
          'completion_verse': completionVerse!.toJson(),
        if (reflectionPrompt != null) 'reflection_prompt': reflectionPrompt,
        if (scriptureConnections != null)
          'scripture_connections':
              scriptureConnections!.map((s) => s.toJson()).toList(),
      };
}

/// Debug-only: warns when [card] has a non-null field that is neither in
/// this type's rendered-fields contract nor explicitly deferred. Silent in
/// release builds — zero production cost.
void _debugCheckEncounterCardContract(EncounterCard card) {
  if (!kDebugMode) return;

  final renderedFields = kEncounterCardRenderedFields[card.type];
  if (renderedFields == null) return;

  final populated = <String>{
    if (card.mood != null) 'mood',
    if (card.imageUrl != null) 'imageUrl',
    if (card.title != null) 'title',
    if (card.narrative != null) 'narrative',
    if (card.verseOverlay != null) 'verseOverlay',
    if (card.revelationKey != null) 'revelationKey',
    if (card.ambientSound != null) 'ambientSound',
    if (card.haptic != null) 'haptic',
    if (card.icon != null) 'icon',
    if (card.subtitle != null) 'subtitle',
    if (card.content != null) 'content',
    if (card.verseReference != null) 'verseReference',
    if (card.verseText != null) 'verseText',
    if (card.reflection != null) 'reflection',
    if (card.discoveryQuestions != null) 'discoveryQuestions',
    if (card.prayer != null) 'prayer',
    if (card.completionVerse != null) 'completionVerse',
    if (card.reflectionPrompt != null) 'reflectionPrompt',
    if (card.scriptureConnections != null) 'scriptureConnections',
  };

  final orphaned = populated
      .difference(renderedFields)
      .difference(kDeferredEncounterCardFields);

  if (orphaned.isNotEmpty) {
    debugPrint(
      '⚠️ [EncounterCardContract] card order=${card.order} type="${card.type}" '
      'has content in field(s) $orphaned with no renderer registered in '
      'kEncounterCardRenderedFields["${card.type}"]. Either wire a renderer '
      'and add the field to the contract map, or add it to '
      'kDeferredEncounterCardFields if intentionally deferred.',
    );
  }
}

class EncounterPrayer {
  final String? title;
  final String content;

  const EncounterPrayer({this.title, required this.content});

  factory EncounterPrayer.fromJson(Map<String, dynamic> json) =>
      EncounterPrayer(
        title: json['title'] as String?,
        content: json['content'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        if (title != null) 'title': title,
        'content': content,
      };
}

class EncounterDiscoveryQuestion {
  final String category;
  final String question;

  const EncounterDiscoveryQuestion({
    required this.category,
    required this.question,
  });

  factory EncounterDiscoveryQuestion.fromJson(Map<String, dynamic> json) =>
      EncounterDiscoveryQuestion(
        category: json['category'] as String? ?? '',
        question: json['question'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'category': category, 'question': question};
}
