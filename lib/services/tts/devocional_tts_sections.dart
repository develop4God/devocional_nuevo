import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/tts/bible_text_formatter.dart';
import 'package:devocional_nuevo/services/tts/tts_verse_index_resolver.dart';

import '../../extensions/string_extensions.dart';

/// Kind of a devotional TTS unit, so the content widget knows how to render it.
enum DevotionalUnitKind {
  /// A section title ("Reflexión:", "Oración:", …) — rendered bold + primary.
  label,

  /// The main verse block — rendered as its verse card.
  verse,

  /// One sentence of the reflection or prayer — rendered inline body text.
  sentence,

  /// One "Para meditar" citation + text — rendered as its own card.
  meditateItem,
}

/// One highlightable unit of a devotional, in spoken order.
///
/// The unit list is the devotional equivalent of the Bible reader's verse rows:
/// the current unit highlights (bold, others dim) exactly the same way. Verse
/// and meditate items are whole-block units; the reflection and prayer are
/// broken into sentence units so the highlight follows the audio closely and
/// device-independently (a sentence is a property of the text, not the layout).
class DevotionalUnit {
  final DevotionalUnitKind kind;

  /// Text to render for this unit (the sentence, verse, label, or item text).
  final String text;

  /// For [DevotionalUnitKind.meditateItem]: the citation shown as a bold prefix.
  final String? citation;

  const DevotionalUnit({
    required this.kind,
    required this.text,
    this.citation,
  });
}

/// Ordered, highlightable units of a devotional plus the char→unit mapping used
/// to follow TTS playback. Char lengths mirror `TtsPlayerWidget._buildTtsText`
/// so the offsets the TTS progress handler reports line up with these units.
///
/// Reuses [TtsVerseIndexResolver] for the char/fraction → index math (the Bible
/// reader uses the same resolver); this class only knows how a devotional's
/// spoken text is assembled and split.
class DevocionalTtsSections {
  final List<DevotionalUnit> units;
  final TtsVerseIndexResolver _resolver;

  DevocionalTtsSections._(this.units, this._resolver);

  int get length => units.length;

  /// Total spoken-text character span, for continuous scroll mapping.
  int get totalChars => _resolver.totalChars;

  /// Continuous scroll fraction (0.0..1.0) for a global char [offset], so the
  /// scroll creeps smoothly with the words instead of jumping per unit.
  double? scrollFractionForOffset(int offset) {
    final total = _resolver.totalChars;
    if (total <= 0) return null;
    return (offset / total).clamp(0.0, 1.0);
  }

  /// Unit index for a global character [charOffset] from the TTS progress
  /// handler, or null when empty.
  int? indexForCharOffset(int charOffset) =>
      _resolver.indexForCharOffset(charOffset);

  /// Unit index for a playback [fraction] (estimated fallback), or null.
  int? indexForFraction(double fraction) =>
      _resolver.indexForFraction(fraction);

  /// Build from a [devocional] and [language], mirroring
  /// `TtsPlayerWidget._buildTtsText` character-for-character so the char ranges
  /// align with the offsets the engine reports.
  factory DevocionalTtsSections.build(Devocional devocional, String language) {
    final verseLabel = 'devotionals.verse'.tr().replaceAll(':', '');
    final reflectionLabel = 'devotionals.reflection'.tr().replaceAll(':', '');
    final meditateLabel = 'devotionals.to_meditate'.tr().replaceAll(':', '');
    final prayerLabel = 'devotionals.prayer'.tr().replaceAll(':', '');

    String norm(String text) => BibleTextFormatter.normalizeTtsText(
          text,
          language,
          devocional.version,
        );

    final units = <DevotionalUnit>[];
    final charCounts = <int>[];

    void add(DevotionalUnit unit, int spokenChars) {
      units.add(unit);
      charCounts.add(spokenChars);
    }

    // ── Verse: "$verseLabel: " + normalizedVerse ─────────────────────────────
    // Spoken as one block; rendered as one verse card → one unit. Its char
    // length covers the label prefix + the whole (normalized) verse.
    add(
      DevotionalUnit(
          kind: DevotionalUnitKind.verse, text: devocional.versiculo),
      '$verseLabel: '.length + norm(devocional.versiculo).length,
    );

    // ── Reflection: "\n$reflectionLabel: " + sentences ───────────────────────
    // The label prefix is folded into the first sentence's char length so the
    // spoken offsets stay aligned; the label itself is a separate render unit.
    _addLabelAndSentences(
      add: add,
      norm: norm,
      label: reflectionLabel,
      labelPrefix: '\n$reflectionLabel: ',
      body: devocional.reflexion,
    );

    // ── Meditate (optional): "\n$meditateLabel: " + "cita: texto" per item ───
    if (devocional.paraMeditar.isNotEmpty) {
      add(
        DevotionalUnit(kind: DevotionalUnitKind.label, text: meditateLabel),
        '\n$meditateLabel: '.length,
      );
      for (int i = 0; i < devocional.paraMeditar.length; i++) {
        final m = devocional.paraMeditar[i];
        // Builder joins items with '\n' — the separator's 1 char is attributed
        // to items after the first, matching the spoken string length.
        final sep = i == 0 ? 0 : '\n'.length;
        add(
          DevotionalUnit(
            kind: DevotionalUnitKind.meditateItem,
            text: m.texto,
            citation: m.cita,
          ),
          sep + '${norm(m.cita)}: ${m.texto}'.length,
        );
      }
    }

    // ── Prayer: "\n$prayerLabel: " + sentences ───────────────────────────────
    _addLabelAndSentences(
      add: add,
      norm: norm,
      label: prayerLabel,
      labelPrefix: '\n$prayerLabel: ',
      body: devocional.oracion,
    );

    final resolver =
        TtsVerseIndexResolver.fromCharCounts(charCounts, headerChars: 0);
    return DevocionalTtsSections._(units, resolver);
  }

  /// Adds a label unit then one unit per sentence of [body]. The [labelPrefix]
  /// (spoken but not part of the rendered sentence) is folded into the label
  /// unit's char length. Rendered sentence text is split from the *raw* body
  /// (unchanged rendering), but char lengths come from the *whole-body
  /// normalized* text — matching `TtsPlayerWidget._buildTtsText`, which
  /// normalizes the entire body in one call rather than per sentence — split
  /// at the same sentence boundaries, so each unit's length is the real gap to
  /// the next sentence (or to the end) instead of a fixed "+1" guess for the
  /// separator. Keeps the running total exactly equal to the real spoken
  /// length instead of drifting as sentence count grows.
  static void _addLabelAndSentences({
    required void Function(DevotionalUnit, int) add,
    required String Function(String) norm,
    required String label,
    required String labelPrefix,
    required String body,
  }) {
    add(
      DevotionalUnit(kind: DevotionalUnitKind.label, text: label),
      labelPrefix.length,
    );
    final sentences = TtsVerseIndexResolver.splitSentences(body);
    if (sentences.isEmpty) return;

    // Split the whole-body normalized text (what's actually spoken) at the
    // same sentence-boundary pattern used to split the raw body, so each
    // sentence's char length is its real length in the spoken text plus the
    // real trailing separator — no fixed "+1" guess.
    final normalizedSentences =
        TtsVerseIndexResolver.splitSentences(norm(body));
    final sameSplit = normalizedSentences.length == sentences.length;

    for (int i = 0; i < sentences.length; i++) {
      final spokenChars = sameSplit
          ? normalizedSentences[i].length + (i == sentences.length - 1 ? 0 : 1)
          // +1 approximates the whitespace the splitter consumed between
          // sentences; harmless for mapping and keeps the running total
          // close to the spoken length.
          : norm(sentences[i]).length + 1;
      add(
        DevotionalUnit(kind: DevotionalUnitKind.sentence, text: sentences[i]),
        spokenChars,
      );
    }
  }
}
