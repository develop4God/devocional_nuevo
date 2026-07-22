import 'package:devocional_nuevo/models/encounter_card_contract.dart';
import 'package:devocional_nuevo/models/encounter_card_model.dart';

/// Builds formatted TTS text from an [EncounterCard] for voice playback.
///
/// Follows Single Responsibility Principle: only responsible for converting
/// encounter card content into TTS-ready text. Reads only the fields
/// [kEncounterCardRenderedFields] marks as rendered for the card's `type`,
/// so narration always matches what is visually shown.
class EncounterTtsTextBuilder {
  const EncounterTtsTextBuilder._();

  /// Build a TTS-ready string from [card].
  ///
  /// Throws a [StateError] for a card `type` absent from
  /// [kEncounterCardRenderedFields] — narrating unknown content silently
  /// would hide a contract gap that should surface during development.
  static String build(EncounterCard card) {
    final renderedFields = kEncounterCardRenderedFields[card.type];
    if (renderedFields == null) {
      throw StateError(
        'EncounterTtsTextBuilder: no rendered-fields contract for card '
        'type "${card.type}" — see kEncounterCardRenderedFields in '
        'encounter_card_contract.dart',
      );
    }

    final buffer = StringBuffer();

    void addLine(String? value) {
      if (value != null && value.trim().isNotEmpty) {
        buffer.write('${value.trim()}\n');
      }
    }

    if (renderedFields.contains('title')) addLine(card.title);
    if (renderedFields.contains('subtitle')) addLine(card.subtitle);
    if (renderedFields.contains('narrative')) addLine(card.narrative);
    if (renderedFields.contains('content')) addLine(card.content);

    if (renderedFields.contains('verseOverlay') && card.verseOverlay != null) {
      addLine(card.verseOverlay!.reference);
      addLine(card.verseOverlay!.text);
    }

    if (renderedFields.contains('verseReference')) addLine(card.verseReference);
    if (renderedFields.contains('verseText')) addLine(card.verseText);

    if (renderedFields.contains('reflection')) addLine(card.reflection);

    if (renderedFields.contains('scriptureConnections') &&
        card.scriptureConnections != null) {
      for (final verse in card.scriptureConnections!) {
        addLine(verse.reference);
        addLine(verse.text);
      }
    }

    if (renderedFields.contains('revelationKey')) addLine(card.revelationKey);

    if (renderedFields.contains('discoveryQuestions') &&
        card.discoveryQuestions != null) {
      for (final question in card.discoveryQuestions!) {
        addLine(question.question);
      }
    }

    if (renderedFields.contains('prayer') && card.prayer != null) {
      addLine(card.prayer!.title);
      addLine(card.prayer!.content);
    }

    if (renderedFields.contains('completionVerse') &&
        card.completionVerse != null) {
      addLine(card.completionVerse!.reference);
      addLine(card.completionVerse!.text);
    }

    if (renderedFields.contains('reflectionPrompt')) {
      addLine(card.reflectionPrompt);
    }

    return buffer.toString().trim();
  }
}
