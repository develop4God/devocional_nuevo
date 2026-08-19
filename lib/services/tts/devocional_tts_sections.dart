import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/tts/bible_text_formatter.dart';
import 'package:devocional_nuevo/services/tts/tts_verse_index_resolver.dart';

import '../../extensions/string_extensions.dart';

/// The ordered, highlightable sections of a devotional as spoken by TTS.
enum DevotionalSection { verse, reflection, meditate, prayer }

/// Maps a TTS playback signal (word-accurate char offset, or estimated
/// fraction) onto the devotional [DevotionalSection] being read.
///
/// The devotional is continuous prose, not discrete items, so the "items" here
/// are its four coarse sections. Section char-lengths are computed to match the
/// exact string TtsPlayerWidget hands to the engine, so the offsets the TTS
/// progress handler reports line up with these ranges.
///
/// Reuses [TtsVerseIndexResolver] for the char/fraction → index math; this
/// class only knows how a devotional's spoken text is assembled.
class DevocionalTtsSections {
  /// The sections present for this devotional, in spoken order. `meditate` is
  /// omitted when the devotional has no `paraMeditar` entries — matching the
  /// builder, which skips that block.
  final List<DevotionalSection> sections;

  final TtsVerseIndexResolver _resolver;

  DevocionalTtsSections._(this.sections, this._resolver);

  int get length => sections.length;

  /// Section index for a global character [charOffset] from the TTS progress
  /// handler, or null when empty.
  int? indexForCharOffset(int charOffset) =>
      _resolver.indexForCharOffset(charOffset);

  /// Section index for a playback [fraction] (estimated fallback), or null.
  int? indexForFraction(double fraction) =>
      _resolver.indexForFraction(fraction);

  /// Build from a [devocional] and [language], mirroring
  /// `TtsPlayerWidget._buildTtsText` character-for-character.
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

    final orderedSections = <DevotionalSection>[];
    final charCounts = <int>[];

    // Verse: "$verseLabel: " + normalizedVerse
    orderedSections.add(DevotionalSection.verse);
    charCounts.add('$verseLabel: '.length + norm(devocional.versiculo).length);

    // Reflection: "\n$reflectionLabel: " + normalizedReflection
    orderedSections.add(DevotionalSection.reflection);
    charCounts.add(
      '\n$reflectionLabel: '.length + norm(devocional.reflexion).length,
    );

    // Meditate (optional): "\n$meditateLabel: " + joined "cita: texto"
    if (devocional.paraMeditar.isNotEmpty) {
      final body = devocional.paraMeditar
          .map((m) => '${norm(m.cita)}: ${m.texto}')
          .join('\n');
      orderedSections.add(DevotionalSection.meditate);
      charCounts.add('\n$meditateLabel: '.length + body.length);
    }

    // Prayer: "\n$prayerLabel: " + normalizedPrayer
    orderedSections.add(DevotionalSection.prayer);
    charCounts.add('\n$prayerLabel: '.length + norm(devocional.oracion).length);

    final resolver = TtsVerseIndexResolver.fromCharCounts(
      charCounts,
      headerChars: 0,
    );
    return DevocionalTtsSections._(orderedSections, resolver);
  }
}
