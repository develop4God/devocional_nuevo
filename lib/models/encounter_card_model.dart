// lib/models/encounter_card_model.dart

import 'package:devocional_nuevo/utils/constants.dart';

/// Union-type model for all encounter card types.
///
/// Supported types:
///   cinematic_scene | scripture_moment | character_moment |
///   theological_depth | discovery_activation | completion |
///   interactive_moment | unknown
class EncounterCard {
  final int order;
  final String type;

  // Shared optional fields
  final String? mood;
  final String? imageUrl;
  final String? title;
  final String? narrative;
  final EncounterVerseOverlay? verseOverlay;
  final String? revelationKey;
  final String? ambientSound;
  final String? haptic;
  final String? icon;
  final String? subtitle;
  final String? content;
  final String? verseReference;
  final String? verseText;
  final String? reflection;
  final List<EncounterDiscoveryQuestion>? discoveryQuestions;
  final EncounterPrayer? prayer;
  final EncounterCompletionVerse? completionVerse;
  final String? reflectionPrompt;
  final List<EncounterScriptureConnection>? scriptureConnections;

  const EncounterCard({
    required this.order,
    required this.type,
    this.mood,
    this.imageUrl,
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
  /// - Otherwise treats it as a bare filename and builds the full raw GitHub URL.
  static String? _resolveImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    return Constants.getEncounterImageUrl(raw);
  }

  factory EncounterCard.fromJson(Map<String, dynamic> json) {
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

    return EncounterCard(
      order: json['order'] as int? ?? 0,
      type: type,
      mood: json['mood'] as String?,
      imageUrl: _resolveImageUrl(json['image_url'] as String?),
      title: json['title'] as String?,
      narrative: json['narrative'] as String?,
      verseOverlay: json['verse_overlay'] != null
          ? EncounterVerseOverlay.fromJson(
              json['verse_overlay'] as Map<String, dynamic>)
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
          ?.map((e) =>
              EncounterDiscoveryQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      prayer: json['prayer'] != null
          ? EncounterPrayer.fromJson(json['prayer'] as Map<String, dynamic>)
          : null,
      completionVerse: json['completion_verse'] != null
          ? EncounterCompletionVerse.fromJson(
              json['completion_verse'] as Map<String, dynamic>)
          : null,
      reflectionPrompt: json['reflection_prompt'] as String?,
      scriptureConnections: (json['scripture_connections'] as List<dynamic>?)
          ?.map((e) =>
              EncounterScriptureConnection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
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

class EncounterVerseOverlay {
  final String reference;
  final String text;

  const EncounterVerseOverlay({required this.reference, required this.text});

  factory EncounterVerseOverlay.fromJson(Map<String, dynamic> json) =>
      EncounterVerseOverlay(
        reference: json['reference'] as String? ?? '',
        text: json['text'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'reference': reference, 'text': text};
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

class EncounterCompletionVerse {
  final String reference;
  final String text;

  const EncounterCompletionVerse({required this.reference, required this.text});

  factory EncounterCompletionVerse.fromJson(Map<String, dynamic> json) =>
      EncounterCompletionVerse(
        reference: json['reference'] as String? ?? '',
        text: json['text'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'reference': reference, 'text': text};
}

class EncounterDiscoveryQuestion {
  final String category;
  final String question;

  const EncounterDiscoveryQuestion(
      {required this.category, required this.question});

  factory EncounterDiscoveryQuestion.fromJson(Map<String, dynamic> json) =>
      EncounterDiscoveryQuestion(
        category: json['category'] as String? ?? '',
        question: json['question'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'category': category, 'question': question};
}

class EncounterScriptureConnection {
  final String reference;
  final String text;

  const EncounterScriptureConnection(
      {required this.reference, required this.text});

  factory EncounterScriptureConnection.fromJson(Map<String, dynamic> json) =>
      EncounterScriptureConnection(
        reference: json['reference'] as String? ?? '',
        text: json['text'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'reference': reference, 'text': text};
}

class EncounterKeyVerse {
  final String reference;
  final String text;

  const EncounterKeyVerse({required this.reference, required this.text});

  factory EncounterKeyVerse.fromJson(Map<String, dynamic> json) =>
      EncounterKeyVerse(
        reference: json['reference'] as String? ?? '',
        text: json['text'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'reference': reference, 'text': text};
}
