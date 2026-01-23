// lib/utils/devotional_share_helper.dart

import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';

/// Utility class for generating shareable text from Daily Devotionals
///
/// Formats devotionals for sharing on WhatsApp and other platforms with
/// emojis, proper structure, and app download link with FOMO footer.
class DevotionalShareHelper {
  /// Generate text for sharing a devotional
  ///
  /// [devocional] - The devotional to share
  static String generarTextoParaCompartir(Devocional devocional) {
    final buffer = StringBuffer();

    // Title with emoji
    buffer.writeln(
        '📖 *${_translateKey('devotionals.devotional_of_the_day', fallback: 'Devocional del día')}*');
    buffer.writeln();

    // Verse section with emoji
    buffer.writeln(
        '✝️ *${_translateKey('devotionals.verse', fallback: 'Versículo:')}*');
    buffer.writeln(devocional.versiculo);
    buffer.writeln();

    // Reflection section with emoji
    buffer.writeln(
        '💭 *${_translateKey('devotionals.reflection', fallback: 'Reflexión:')}*');
    buffer.writeln(_formatText(devocional.reflexion));
    buffer.writeln();

    // Meditation section with emoji
    if (devocional.paraMeditar.isNotEmpty) {
      buffer.writeln(
          '🙏 *${_translateKey('devotionals.to_meditate', fallback: 'Para Meditar:')}*');
      for (var meditacion in devocional.paraMeditar) {
        buffer.writeln('📌 *${meditacion.cita}*');
        buffer.writeln(meditacion.texto);
        buffer.writeln();
      }
    }

    // Prayer section with emoji
    buffer.writeln(
        '🕊️ *${_translateKey('devotionals.prayer', fallback: 'Oración:')}*');
    buffer.writeln(_formatText(devocional.oracion));
    buffer.writeln();

    // Enhanced FOMO Footer
    buffer.writeln('━━━━━━━━━━━━━━━━');
    buffer.writeln(
        '🔥 *${_translateKey('devotionals.share_footer_title', fallback: 'Esto es solo el comienzo...')}*');
    buffer.writeln();
    buffer.writeln(_translateKey(
      'devotionals.share_footer_complete_app',
      fallback: 'La app completa incluye:',
    ));
    buffer.writeln(
        '✓ ${_translateKey('devotionals.share_footer_daily_devotionals', fallback: 'Devocionales diarios actualizados')}');
    buffer.writeln(
        '✓ ${_translateKey('devotionals.share_footer_audio_reading', fallback: 'Lectura en audio con voces naturales')}');
    buffer.writeln(
        '✓ ${_translateKey('devotionals.share_footer_bible_studies', fallback: 'Estudios bíblicos profundos')}');
    buffer.writeln(
        '✓ ${_translateKey('devotionals.share_footer_bible_versions', fallback: 'Biblia completa en múltiples versiones')}');
    buffer.writeln(
        '✓ ${_translateKey('devotionals.share_footer_and_more', fallback: 'Y mucho más...')}');
    buffer.writeln();
    buffer.writeln(
        '📲 *${_translateKey('devotionals.share_footer_download', fallback: 'Descarga: Devocionales Cristianos')}*');
    buffer.writeln(_translateKey(
      'devotionals.share_footer_benefits',
      fallback: '100% gratis | Sin anuncios | Uso offline',
    ));
    buffer.writeln(
        'https://play.google.com/store/apps/details?id=com.develop4god.devocional_nuevo');
    buffer.write(_translateKey('devotionals.share_footer_developer',
        fallback: 'Develop4God'));

    return buffer.toString();
  }

  static String _translateKey(String key, {String fallback = ''}) {
    try {
      final translated = key.tr();
      if (translated == key) {
        // If translation service is not available, fallback
        return fallback.isNotEmpty ? fallback : key;
      }
      return translated;
    } catch (_) {
      return fallback.isNotEmpty ? fallback : key;
    }
  }

  /// Format text to ensure proper line breaks and formatting
  static String _formatText(String text) {
    return text
        .replaceAll('\n\n\n', '\n\n') // Clean extra spaces
        .trim();
  }
}
