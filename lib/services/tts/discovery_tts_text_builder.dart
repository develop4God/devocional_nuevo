import 'package:devocional_nuevo/models/discovery_card_model.dart';

/// Builds formatted TTS text from a [DiscoveryCard] for voice playback.
///
/// Follows Single Responsibility Principle: only responsible for converting
/// Discovery study card content into TTS-ready text. Mirrors the fields
/// rendered by `DiscoveryDetailPage._buildCardContent` so narration matches
/// what is visually shown, in the same order.
class DiscoveryTtsTextBuilder {
  const DiscoveryTtsTextBuilder._();

  /// Build a TTS-ready string from [card].
  static String build(DiscoveryCard card) {
    final buffer = StringBuffer();

    void addLine(String? value) {
      if (value != null && value.trim().isNotEmpty) {
        buffer.write('${value.trim()}\n');
      }
    }

    addLine(card.title);
    addLine(card.subtitle);
    addLine(card.content);

    if (card.revelationKey != null) addLine(card.revelationKey);

    if (card.scriptureAnchor != null) {
      addLine(card.scriptureAnchor!.reference);
      addLine(card.scriptureAnchor!.text);
    }

    if (card.scriptureConnections != null) {
      for (final verse in card.scriptureConnections!) {
        addLine(verse.reference);
        addLine(verse.text);
      }
    }

    if (card.scriptureReferences != null) {
      for (final verse in card.scriptureReferences!) {
        addLine(verse.reference);
        addLine(verse.text);
      }
    }

    if (card.greekWords != null) {
      for (final word in card.greekWords!) {
        addLine(word.word);
        addLine(word.meaning);
        addLine(word.revelation);
      }
    }

    if (card.discoveryQuestions != null) {
      for (final question in card.discoveryQuestions!) {
        addLine(question.question);
      }
    }

    if (card.prayer != null) {
      addLine(card.prayer!.title);
      addLine(card.prayer!.content);
    }

    return buffer.toString().trim();
  }
}
