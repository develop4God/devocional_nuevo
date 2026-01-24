// lib/utils/discovery_share_helper.dart

import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/models/discovery_devotional_model.dart';

/// Utility class for generating shareable text from Discovery Bible Studies
///
/// Formats studies for sharing on WhatsApp and other platforms with
/// emojis, proper structure, and app download link.
class DiscoveryShareHelper {
  /// Generate text for sharing a Discovery study
  ///
  /// [study] - The Discovery devotional to share
  /// [resumen] - If true, generates a summary version. If false, generates full study
  static String generarTextoParaCompartir(
    DiscoveryDevotional study, {
    bool resumen = true,
  }) {
    if (resumen) {
      return _generarResumen(study);
    } else {
      return _generarEstudioCompleto(study);
    }
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

  /// Generate a summary version optimized for WhatsApp sharing
  static String _generarResumen(DiscoveryDevotional study) {
    final keyVerse = study.keyVerse;
    final firstCard = study.cards.isNotEmpty ? study.cards[0] : null;

    // Find discovery activation card
    final discoveryCard = study.cards.firstWhere(
      (card) => card.type == 'discovery_activation',
      orElse: () => study.cards.last,
    );

    final firstQuestion = discoveryCard.discoveryQuestions?.isNotEmpty == true
        ? discoveryCard.discoveryQuestions!.first.question
        : null;

    final buffer = StringBuffer();

    // Bible Study title with emoji and translation key
    final emoji = study.emoji ?? '📖';
    buffer.writeln(
        '$emoji *${_translateKey('discovery.daily_bible_study', fallback: 'Estudio Bíblico Diario')}*');
    if (study.subtitle != null && study.subtitle!.isNotEmpty) {
      buffer.writeln('_${study.subtitle}_');
    }
    buffer.writeln();

    // Key verse with reference FIRST (only keep this, remove duplicated initial verse)
    if (keyVerse != null) {
      buffer.writeln('📖 *${keyVerse.reference}*');
      buffer.writeln('"${keyVerse.text}"');
      buffer.writeln();
    }

    // First card content
    if (firstCard != null) {
      final icon = firstCard.icon ?? '📝';
      buffer.writeln('$icon *${firstCard.title}*');
      if (firstCard.content != null) {
        buffer.writeln(_extraerPuntosClave(firstCard.content!));
      }
      buffer.writeln();

      // Revelation key
      if (firstCard.revelationKey != null) {
        buffer.writeln(
            '💡 *${_translateKey('discovery.revelation', fallback: 'Revelación')}:*');
        buffer.writeln(firstCard.revelationKey);
        buffer.writeln();
      }
    }

    // First discovery question
    if (firstQuestion != null) {
      buffer.writeln(
          '❓ *${_translateKey('discovery.reflection_questions', fallback: 'Preguntas de Reflexión')}:*');
      buffer.writeln(firstQuestion);
      buffer.writeln();
    }

    // App download link
    buffer.writeln('━━━━━━━━━━━━━━━━');
    buffer.writeln(
        '🔥 *${_translateKey('discovery.share_footer_title', fallback: 'Esto es solo el comienzo...')}*');
    buffer.writeln();
    buffer.writeln(_translateKey(
      'discovery.share_footer_complete_study',
      fallback: 'El estudio completo incluye:',
    ));
    buffer.writeln(
        '✓ ${_translateKey('discovery.share_footer_greek_analysis', fallback: 'Análisis de palabras en griego original')}');
    buffer.writeln(
        '✓ ${_translateKey('discovery.share_footer_historical_context', fallback: 'Contexto histórico profundo')}');
    buffer.writeln(
        '✓ ${_translateKey('discovery.share_footer_biblical_connections', fallback: 'Conexiones bíblicas reveladoras')}');
    buffer.writeln(
        '✓ ${_translateKey('discovery.share_footer_activation_questions', fallback: 'Preguntas de activación personal')}');
    buffer.writeln();
    buffer.writeln(
        '📲 *${_translateKey('discovery.share_footer_download', fallback: 'Descarga: Devocionales Cristianos')}*');
    buffer.writeln(_translateKey(
      'discovery.share_footer_benefits',
      fallback: '100% gratis | Sin anuncios | Uso offline',
    ));
    buffer.writeln(
        'https://play.google.com/store/apps/details?id=com.develop4god.devocional_nuevo');
    buffer.write(_translateKey('discovery.share_footer_developer',
        fallback: 'Develop4God'));

    return buffer.toString();
  }

  /// Generate complete study text for full sharing
  static String _generarEstudioCompleto(DiscoveryDevotional study) {
    final buffer = StringBuffer();
    final emoji = study.emoji ?? '📖';
    buffer.writeln(
        '$emoji *${_translateKey('discovery.daily_bible_study', fallback: 'ESTUDIO BÍBLICO DIARIO').toUpperCase()} DISCOVERY: ${study.versiculo.toUpperCase()}*');
    buffer.writeln();

    if (study.keyVerse != null) {
      buffer.write('📖 *${study.keyVerse!.reference}*');
      if (study.version != null) {
        buffer.write(' (${study.version})');
      }
      buffer.writeln();
      buffer.writeln('"${study.keyVerse!.text}"');
      buffer.writeln();
    }

    // Process each card
    for (var card in study.cards) {
      // Skip discovery activation card for now (save for the end)
      if (card.type == 'discovery_activation') continue;

      buffer.writeln('━━━━━━━━━━━━━━━━');
      final icon = card.icon ?? '📝';
      buffer.writeln('$icon ${card.title.toUpperCase()}');
      buffer.writeln();

      if (card.subtitle != null) {
        buffer.writeln('_${card.subtitle}_');
        buffer.writeln();
      }

      if (card.content != null) {
        buffer.writeln(_formatearContenido(card.content!));
        buffer.writeln();
      }

      // Scripture connections - show reference FIRST
      if (card.scriptureConnections != null &&
          card.scriptureConnections!.isNotEmpty) {
        buffer.writeln(
            '📖 *${_translateKey('discovery.scripture_connections', fallback: 'Conexiones Bíblicas')}:*');
        for (var connection in card.scriptureConnections!) {
          buffer.writeln('*${connection.reference}*');
          buffer.writeln('"${connection.text}"');
          buffer.writeln();
        }
      }

      // Greek words
      if (card.greekWords != null && card.greekWords!.isNotEmpty) {
        buffer.writeln(
            '🔤 *${_translateKey('discovery.greek_words', fallback: 'Palabras Griegas')}:*');
        for (var word in card.greekWords!) {
          buffer.writeln(
              '• *${word.word}* (${word.transliteration ?? word.word}): ${word.meaning}');
        }
        buffer.writeln();
      }

      // Revelation key
      if (card.revelationKey != null) {
        buffer.writeln(
            '💡 *${_translateKey('discovery.revelation', fallback: 'Revelación')}:*');
        buffer.writeln(card.revelationKey);
        buffer.writeln();
      }
    }

    // Discovery questions section
    final discoveryCard = study.cards.firstWhere(
      (card) => card.type == 'discovery_activation',
      orElse: () => study.cards.last,
    );

    if (discoveryCard.discoveryQuestions != null &&
        discoveryCard.discoveryQuestions!.isNotEmpty) {
      buffer.writeln('━━━━━━━━━━━━━━━━');
      buffer.writeln(
          '🙏 *${_translateKey('discovery.reflection_questions', fallback: 'PREGUNTAS DE REFLEXIÓN').toUpperCase()}:*');
      buffer.writeln();

      int i = 1;
      for (var question in discoveryCard.discoveryQuestions!) {
        buffer.writeln('$i. ${question.question}');
        buffer.writeln();
        i++;
      }
    }

    // Prayer
    if (discoveryCard.prayer != null) {
      buffer.writeln('━━━━━━━━━━━━━━━━');
      buffer.writeln(
          '🙏 *${discoveryCard.prayer!.title ?? _translateKey('discovery.activation_prayer', fallback: 'ORACIÓN DE ACTIVACIÓN')}*');
      buffer.writeln();
      buffer.writeln(discoveryCard.prayer!.content);
      buffer.writeln();
    }

    // Footer
    buffer.writeln('━━━━━━━━━━━━━━━━');
    buffer.writeln(
        '🔥 *${_translateKey('discovery.share_footer_title', fallback: 'Esto es solo el comienzo...')}*');
    buffer.writeln();
    buffer.writeln(_translateKey(
      'discovery.share_footer_complete_study',
      fallback: 'El estudio completo incluye:',
    ));
    buffer.writeln(
        '✓ ${_translateKey('discovery.share_footer_greek_analysis', fallback: 'Análisis de palabras en griego original')}');
    buffer.writeln(
        '✓ ${_translateKey('discovery.share_footer_historical_context', fallback: 'Contexto histórico profundo')}');
    buffer.writeln(
        '✓ ${_translateKey('discovery.share_footer_biblical_connections', fallback: 'Conexiones bíblicas reveladoras')}');
    buffer.writeln(
        '✓ ${_translateKey('discovery.share_footer_activation_questions', fallback: 'Preguntas de activación personal')}');
    buffer.writeln();
    buffer.writeln(
        '📲 *${_translateKey('discovery.share_footer_download', fallback: 'Descarga: Devocionales Cristianos')}*');
    buffer.writeln(_translateKey(
      'discovery.share_footer_benefits',
      fallback: '100% gratis | Sin anuncios | Uso offline',
    ));
    buffer.writeln(
        'https://play.google.com/store/apps/details?id=com.develop4god.devocional_nuevo');
    buffer.write(_translateKey('discovery.share_footer_developer',
        fallback: 'Develop4God'));

    return buffer.toString();
  }

  /// Format content maintaining bullets and emojis
  static String _formatearContenido(String content) {
    return content
        .replaceAll('•', '•') // Ensure consistent bullets
        .replaceAll('\n\n\n', '\n\n') // Clean extra spaces
        .trim();
  }

  /// Extract key points from content (first 3-4 bullets or impactful lines)
  static String _extraerPuntosClave(String content) {
    final lines = content.split('\n').where((line) => line.trim().isNotEmpty);

    // Get lines with bullets or numbered items or emojis
    final puntosClave = lines.where((line) {
      final trimmed = line.trim();
      return trimmed.contains('•') ||
          trimmed.contains('1️⃣') ||
          trimmed.contains('2️⃣') ||
          trimmed.contains('3️⃣') ||
          trimmed.contains('💔') ||
          trimmed.contains('✨') ||
          trimmed.contains('🌟') ||
          trimmed.startsWith('•') ||
          (trimmed.length > 10 && RegExp(r'^[•\-\*]\s').hasMatch(trimmed));
    }).take(3);

    if (puntosClave.isEmpty) {
      // If no bullets found, take first 2 meaningful lines
      return lines.take(2).join('\n');
    }

    return puntosClave.join('\n');
  }
}
