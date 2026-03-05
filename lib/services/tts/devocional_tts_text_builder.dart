import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/tts/bible_text_formatter.dart';

import '../../extensions/string_extensions.dart';

/// Builds formatted TTS text from a [Devocional] for voice playback.
///
/// Follows Single Responsibility Principle: only responsible for
/// converting devotional content into TTS-ready text format.
/// Uses [BibleTextFormatter] for language-aware text normalization.
class DevocionalTtsTextBuilder {
  const DevocionalTtsTextBuilder._();

  /// Build a TTS-ready string from a [devocional] for the given [language].
  ///
  /// Includes verse, reflection, meditations (if any), and prayer sections,
  /// each prefixed with a localized label.
  static String build(Devocional devocional, String language) {
    final verseLabel = 'devotionals.verse'.tr().replaceAll(':', '');
    final reflectionLabel = 'devotionals.reflection'.tr().replaceAll(':', '');
    final meditateLabel = 'devotionals.to_meditate'.tr().replaceAll(':', '');
    final prayerLabel = 'devotionals.prayer'.tr().replaceAll(':', '');

    final StringBuffer ttsBuffer = StringBuffer();
    ttsBuffer.write('$verseLabel: ');
    ttsBuffer.write(
      BibleTextFormatter.normalizeTtsText(
        devocional.versiculo,
        language,
        devocional.version,
      ),
    );
    ttsBuffer.write('\n$reflectionLabel: ');
    ttsBuffer.write(
      BibleTextFormatter.normalizeTtsText(
        devocional.reflexion,
        language,
        devocional.version,
      ),
    );
    if (devocional.paraMeditar.isNotEmpty) {
      ttsBuffer.write('\n$meditateLabel: ');
      ttsBuffer.write(
        devocional.paraMeditar.map((m) {
          return '${BibleTextFormatter.normalizeTtsText(m.cita, language, devocional.version)}: ${m.texto}';
        }).join('\n'),
      );
    }
    ttsBuffer.write('\n$prayerLabel: ');
    ttsBuffer.write(
      BibleTextFormatter.normalizeTtsText(
        devocional.oracion,
        language,
        devocional.version,
      ),
    );
    return ttsBuffer.toString();
  }
}
