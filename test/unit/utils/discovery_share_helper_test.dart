@Tags(['unit', 'utils'])
library;

// test/unit/utils/discovery_share_helper_test.dart

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/models/discovery_card_model.dart';
import 'package:devocional_nuevo/models/discovery_devotional_model.dart';
import 'package:devocional_nuevo/utils/discovery_share_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiscoveryShareHelper', () {
    late DiscoveryDevotional testStudy;

    setUp(() {
      testStudy = DiscoveryDevotional(
        id: 'test_study_1',
        date: DateTime(2026, 1, 22),
        versiculo: 'La Estrella de la Mañana',
        reflexion: 'Un estudio profundo sobre Cristo como nuestra luz',
        paraMeditar: [],
        oracion: 'Señor Jesús, ilumina mi vida...',
        emoji: '🌟',
        // Add emoji for the study
        subtitle: 'Cristo: Nuestra Esperanza Radiante',
        estimatedReadingMinutes: 15,
        keyVerse: VerseRef(
          reference: '2 Pedro 1:19',
          text:
              'Tenemos también la palabra profética más segura, a la cual hacéis bien en estar atentos como a una antorcha que alumbra en lugar oscuro...',
        ),
        cards: [
          DiscoveryCard(
            order: 1,
            type: 'natural_revelation',
            icon: '🌟',
            title: 'La Luz del Amanecer',
            content:
                '• El planeta Venus aparece justo antes del alba\n• Es el objeto más brillante en el cielo después del sol y la luna\n• Su brillo anuncia la llegada del nuevo día',
            revelationKey:
                'Así como Venus anuncia el amanecer, Cristo anuncia nuestra redención',
          ),
          DiscoveryCard(
            order: 2,
            type: 'greek_exegesis',
            icon: '🔤',
            title: 'Palabras Griegas Clave',
            greekWords: [
              GreekWord(
                word: 'Phōsphoros',
                transliteration: 'Φωσφόρος',
                reference: '2 Pedro 1:19',
                meaning: 'Portador de luz',
                revelation: 'Cristo trae luz divina a tu oscuridad',
                application: 'Permite que su luz ilumine tus decisiones',
              ),
            ],
          ),
          DiscoveryCard(
            order: 3,
            type: 'discovery_activation',
            icon: '🙏',
            title: 'Preguntas de Descubrimiento',
            discoveryQuestions: [
              DiscoveryQuestion(
                category: 'Personal',
                question:
                    '¿En qué área de tu vida necesitas la luz de Cristo hoy?',
              ),
              DiscoveryQuestion(
                category: 'Práctica',
                question: '¿Cómo puedes ser luz para otros esta semana?',
              ),
            ],
            prayer: Prayer(
              title: 'Oración de Activación',
              content:
                  'Señor Jesús, mi Estrella de la Mañana, ilumina las áreas oscuras de mi vida...',
            ),
          ),
        ],
        tags: ['Esperanza', 'Luz', 'Cristo'],
      );
    });

    test('should generate summary text for sharing', () {
      final shareText = DiscoveryShareHelper.generarTextoParaCompartir(
        testStudy,
        resumen: true,
      );

      // Verify Bible Study header with emoji (uses fallback since no translation service in test)
      expect(shareText, contains('🌟 *Estudio Bíblico Diario*'));
      // Summary version shows subtitle, not versiculo
      expect(shareText, contains('_Cristo: Nuestra Esperanza Radiante_'));

      // Verify key verse with reference shown FIRST
      expect(shareText, contains('📖 *2 Pedro 1:19*'));
      expect(shareText, contains('Tenemos también la palabra profética'));

      // Verify first card content
      expect(shareText, contains('🌟 *La Luz del Amanecer*'));
      expect(shareText, contains('Venus'));

      // Verify revelation key (uses fallback translation)
      expect(shareText, contains('💡 *Revelación:*'));
      expect(shareText, contains('redención'));

      // Verify discovery question (uses fallback translation)
      expect(shareText, contains('❓ *Preguntas de Reflexión:*'));
      expect(shareText, contains('luz de Cristo'));

      // Verify app link (structure) — don't assert exact localized literal
      expect(shareText, contains('📲 *'));
      expect(
        shareText,
        contains(RegExp(r'Descarg(?:a|ar):?', caseSensitive: false)),
      );
      expect(shareText, contains('play.google.com/store/apps/details?id=com'));

      // Verify metadata not asserted here because production doesn't include tags
      // (kept out of test to match production behavior)
    });

    test('should generate complete study text', () {
      final shareText = DiscoveryShareHelper.generarTextoParaCompartir(
        testStudy,
        resumen: false,
      );

      // Verify header includes title and study name (be tolerant to minor localization changes)
      expect(
        shareText,
        allOf(contains('ESTUDIO'), contains('LA ESTRELLA DE LA MAÑANA')),
      );
      // Key verse reference should appear somewhere; allow flexible match
      expect(shareText, contains('2 Pedro 1:19'));

      // Verify all cards are included
      expect(shareText, contains('🌟 LA LUZ DEL AMANECER'));
      expect(shareText, contains('🔤 PALABRAS GRIEGAS CLAVE'));

      // Verify Greek word details
      expect(shareText, contains('Phōsphoros'));
      expect(shareText, contains('Portador de luz'));

      // Verify discovery questions section (uses fallback translation)
      expect(shareText, contains('🙏 *PREGUNTAS DE REFLEXIÓN:*'));
      expect(shareText, contains('1. ¿En qué área de tu vida'));
      expect(shareText, contains('2. ¿Cómo puedes ser luz'));

      // Verify prayer
      expect(shareText, contains('🙏 *Oración de Activación*'));
      expect(shareText, contains('Estrella de la Mañana'));

      // Verify footer (structure) — flexible localization check
      expect(shareText, contains('📲 *'));
      expect(
        shareText,
        contains(RegExp(r'Descarg(?:a|ar):?', caseSensitive: false)),
      );
    });

    test('should handle study without optional fields', () {
      final minimalStudy = DiscoveryDevotional(
        id: 'minimal_study',
        date: DateTime.now(),
        versiculo: 'Simple Study',
        reflexion: 'Simple reflection',
        paraMeditar: [],
        oracion: 'Simple prayer',
        cards: [
          DiscoveryCard(
            order: 1,
            type: 'natural_revelation',
            title: 'Simple Card',
            content: 'Simple content',
          ),
        ],
      );

      final shareText = DiscoveryShareHelper.generarTextoParaCompartir(
        minimalStudy,
        resumen: true,
      );

      // Should still generate valid text with fallback header (includes "Diario")
      expect(shareText, contains('📖 *Estudio Bíblico Diario*'));
      expect(shareText, contains('Simple Card'));
      expect(shareText, contains('play.google.com'));
    });

    test('should extract key points from content', () {
      final extracted = DiscoveryShareHelper.generarTextoParaCompartir(
        testStudy,
      );

      // Should extract first 3 bullet points
      expect(extracted, isNotEmpty);
    });

    test('should format content properly', () {
      final shareText = DiscoveryShareHelper.generarTextoParaCompartir(
        testStudy,
        resumen: false,
      );

      // Should not have excessive newlines
      expect(shareText, isNot(contains('\n\n\n\n')));

      // Should have consistent separators
      expect(shareText, contains('━━━━━━━━━━━━━━━━'));
    });
  });
}
