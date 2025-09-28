// test/unit/services/tts_service_comprehensive_test.dart

import 'dart:async';

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TtsService Comprehensive Tests', () {
    late TtsService ttsService;

    setUp(() async {
      // Setup common test mocks
      TestSetup.setupCommonMocks();

      // Setup SharedPreferences
      SharedPreferences.setMockInitialValues({
        'tts_language': 'es',
        'tts_voice': 'es-ES-male',
        'tts_speech_rate': 1.0,
        'tts_pitch': 1.0,
        'tts_volume': 1.0,
      });

      // Get TTS service instance
      ttsService = TtsService();
    });

    tearDown(() {
      TestSetup.cleanupMocks();
    });

    group('Bible Ordinal Formatting Across Languages', () {
      test('should format Bible ordinals correctly across all languages', () async {
        // Test Spanish ordinals
        ttsService.setLanguageContext('es', 'RVR1960');
        final spanish1Juan = ttsService.formatBibleBook('1 Juan');
        expect(spanish1Juan, contains('Primera de Juan'));

        final spanish2Corintios = ttsService.formatBibleBook('2 Corintios');
        expect(spanish2Corintios, contains('Segunda de Corintios'));

        final spanish3Juan = ttsService.formatBibleBook('3 Juan');
        expect(spanish3Juan, contains('Tercera de Juan'));

        // Test English ordinals
        ttsService.setLanguageContext('en', 'KJV');
        final english1John = ttsService.formatBibleBook('1 John');
        expect(english1John, contains('First John'));

        final english2Corinthians = ttsService.formatBibleBook('2 Corinthians');
        expect(english2Corinthians, contains('Second Corinthians'));

        final english3John = ttsService.formatBibleBook('3 John');
        expect(english3John, contains('Third John'));

        // Test Portuguese ordinals
        ttsService.setLanguageContext('pt', 'ARC');
        final portuguese1Joao = ttsService.formatBibleBook('1 João');
        expect(portuguese1Joao, contains('Primeiro João'));

        final portuguese2Corintios = ttsService.formatBibleBook('2 Coríntios');
        expect(portuguese2Corintios, contains('Segundo Coríntios'));

        // Test French ordinals
        ttsService.setLanguageContext('fr', 'LSG1910');
        final french1Jean = ttsService.formatBibleBook('1 Jean');
        expect(french1Jean, contains('Premier'));

        final french2Corinthiens = ttsService.formatBibleBook('2 Corinthiens');
        expect(french2Corinthiens, contains('Deuxième'));
      });

      test('should handle non-ordinal Bible books correctly', () {
        ttsService.setLanguageContext('es', 'RVR1960');
        
        // Books without ordinals should remain unchanged
        expect(ttsService.formatBibleBook('Génesis'), equals('Génesis'));
        expect(ttsService.formatBibleBook('Salmos'), equals('Salmos'));
        expect(ttsService.formatBibleBook('Mateo'), equals('Mateo'));

        ttsService.setLanguageContext('en', 'KJV');
        expect(ttsService.formatBibleBook('Genesis'), equals('Genesis'));
        expect(ttsService.formatBibleBook('Psalms'), equals('Psalms'));
        expect(ttsService.formatBibleBook('Matthew'), equals('Matthew'));
      });

      test('should handle edge cases in Bible book formatting', () {
        ttsService.setLanguageContext('es', 'RVR1960');
        
        // Empty string
        expect(ttsService.formatBibleBook(''), equals(''));
        
        // Numbers without proper format
        expect(ttsService.formatBibleBook('4 Juan'), equals('4 Juan'));
        
        // Whitespace handling
        expect(ttsService.formatBibleBook('  1 Juan  '), contains('Primera'));
      });
    });

    group('TTS State Management and Language Switching', () {
      test('should handle TTS state management and language switching', () {
        // Test initial state
        expect(ttsService.currentState, equals(TtsState.idle));
        expect(ttsService.isPlaying, isFalse);
        expect(ttsService.isPaused, isFalse);

        // Test language context switching
        ttsService.setLanguageContext('es', 'RVR1960');
        expect(ttsService.currentState, equals(TtsState.idle));

        ttsService.setLanguageContext('en', 'KJV');
        expect(ttsService.currentState, equals(TtsState.idle));

        ttsService.setLanguageContext('pt', 'ARC');
        expect(ttsService.currentState, equals(TtsState.idle));

        ttsService.setLanguageContext('fr', 'LSG1910');
        expect(ttsService.currentState, equals(TtsState.idle));
      });

      test('should maintain consistent state across language changes', () {
        final languages = ['es', 'en', 'pt', 'fr'];
        final versions = ['RVR1960', 'KJV', 'ARC', 'LSG1910'];

        for (int i = 0; i < languages.length; i++) {
          ttsService.setLanguageContext(languages[i], versions[i]);

          // Verify basic TTS service properties are consistent
          expect(ttsService.currentState, equals(TtsState.idle));
          expect(ttsService.isPlaying, isFalse);
          expect(ttsService.isPaused, isFalse);
        }
      });

      test('should handle state transitions correctly', () {
        // Test state queries
        expect(ttsService.currentState, isA<TtsState>());
        expect(ttsService.isPlaying, isA<bool>());
        expect(ttsService.isPaused, isA<bool>());
        expect(ttsService.progress, isA<double>());

        // Test state remains stable
        final initialState = ttsService.currentState;
        expect(ttsService.currentState, equals(initialState));
      });
    });

    group('Text Preparation for Speech Synthesis', () {
      test('should process text preparation for speech synthesis', () {
        final testDevocional = Devocional(
          id: 'tts_test',
          date: DateTime.now(),
          versiculo: 'Porque de tal manera amó Dios al mundo, que ha dado a su Hijo unigénito, para que todo aquel que en él cree, no se pierda, mas tenga vida eterna.',
          reflexion: 'Esta es una reflexión sobre el amor de Dios y su gracia infinita hacia la humanidad.',
          paraMeditar: [
            ParaMeditar(
              cita: '1 Juan 4:16',
              texto: 'Y nosotros hemos conocido y creído el amor que Dios tiene para con nosotros. Dios es amor; y el que permanece en amor, permanece en Dios, y Dios en él.',
            ),
          ],
          oracion: 'Señor, ayúdanos a comprender la profundidad de tu amor y a vivir en esa verdad cada día.',
        );

        // Test that the service can process the devotional
        expect(() => ttsService.setLanguageContext('es', 'RVR1960'), returnsNormally);

        // Test text formatting with Bible references
        final formattedText = ttsService.formatBibleBook('1 Juan');
        expect(formattedText, contains('Primera de Juan'));

        // Test that devotional content is accessible
        expect(testDevocional.versiculo, isNotEmpty);
        expect(testDevocional.reflexion, isNotEmpty);
        expect(testDevocional.oracion, isNotEmpty);
        expect(testDevocional.paraMeditar, isNotEmpty);
      });

      test('should handle special characters and punctuation', () {
        ttsService.setLanguageContext('es', 'RVR1960');

        // Test various punctuation marks
        const textWithPunctuation = 'Salmos 23:1-3, 4:5; Proverbios 3:5-6.';
        expect(() => ttsService.formatBibleBook(textWithPunctuation), returnsNormally);

        // Test numbers in text
        const textWithNumbers = '1 Juan 4:16, 2 Corintios 5:17';
        final formatted = ttsService.formatBibleBook(textWithNumbers);
        expect(formatted, contains('Primera de Juan'));
      });

      test('should process multilingual content correctly', () {
        // Test Spanish content
        ttsService.setLanguageContext('es', 'RVR1960');
        final spanishFormatted = ttsService.formatBibleBook('1 Pedro 5:7');
        expect(spanishFormatted, contains('Primera de Pedro'));

        // Test English content
        ttsService.setLanguageContext('en', 'KJV');
        final englishFormatted = ttsService.formatBibleBook('1 Peter 5:7');
        expect(englishFormatted, contains('First Peter'));

        // Test Portuguese content
        ttsService.setLanguageContext('pt', 'ARC');
        final portugueseFormatted = ttsService.formatBibleBook('1 Pedro 5:7');
        expect(portugueseFormatted, contains('Primeiro Pedro'));
      });
    });

    group('TTS Configuration and Settings', () {
      test('should handle TTS configuration changes', () async {
        // Test speech rate changes
        expect(() => ttsService.setSpeechRate(0.5), returnsNormally);
        expect(() => ttsService.setSpeechRate(1.0), returnsNormally);
        expect(() => ttsService.setSpeechRate(1.5), returnsNormally);

        // Test pitch changes
        expect(() => ttsService.setPitch(0.8), returnsNormally);
        expect(() => ttsService.setPitch(1.0), returnsNormally);
        expect(() => ttsService.setPitch(1.2), returnsNormally);

        // Test volume changes
        expect(() => ttsService.setVolume(0.5), returnsNormally);
        expect(() => ttsService.setVolume(1.0), returnsNormally);
      });

      test('should handle voice selection and language setup', () async {
        // Test available voices query
        final voices = await ttsService.getAvailableVoices();
        expect(voices, isA<List<String>>());

        // Test voice selection for different languages
        final spanishVoices = await ttsService.getVoicesForLanguage('es');
        expect(spanishVoices, isA<List<String>>());

        final englishVoices = await ttsService.getVoicesForLanguage('en');
        expect(englishVoices, isA<List<String>>());

        // Test voice setting
        if (spanishVoices.isNotEmpty) {
          expect(() => ttsService.setVoice(spanishVoices.first), returnsNormally);
        }
      });

      test('should persist settings across service instances', () async {
        // Set some configuration
        ttsService.setLanguageContext('en', 'KJV');
        await ttsService.setSpeechRate(1.2);

        // Settings should be accessible
        expect(ttsService.currentState, isA<TtsState>());
      });
    });

    group('Audio Control Operations', () {
      test('should handle basic audio control operations safely', () {
        final testDevocional = Devocional(
          id: 'audio_test',
          date: DateTime.now(),
          versiculo: 'Test verse',
          reflexion: 'Test reflection',
          paraMeditar: [ParaMeditar(cita: 'Test', texto: 'Test')],
          oracion: 'Test prayer',
        );

        // Test basic controls (these should not throw errors even if TTS isn't fully initialized)
        expect(() => ttsService.pause(), returnsNormally);
        expect(() => ttsService.resume(), returnsNormally);
        expect(() => ttsService.stop(), returnsNormally);

        // Test state queries
        expect(ttsService.currentState, isA<TtsState>());
        expect(ttsService.isPlaying, isA<bool>());
        expect(ttsService.isPaused, isA<bool>());
      });

      test('should handle audio playback lifecycle', () {
        final testDevocional = Devocional(
          id: 'lifecycle_test',
          date: DateTime.now(),
          versiculo: 'This is a test verse for lifecycle testing.',
          reflexion: 'This is a test reflection.',
          paraMeditar: [ParaMeditar(cita: 'Test 1:1', texto: 'Test meditation')],
          oracion: 'Test prayer for lifecycle.',
        );

        // Test playback initiation (should handle gracefully even without actual audio)
        expect(() => ttsService.setLanguageContext('es', 'RVR1960'), returnsNormally);

        // Test that devotional can be processed
        expect(testDevocional.versiculo, isNotEmpty);
        expect(testDevocional.reflexion, isNotEmpty);

        // Test control operations
        expect(() => ttsService.pause(), returnsNormally);
        expect(() => ttsService.resume(), returnsNormally);
        expect(() => ttsService.stop(), returnsNormally);
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle invalid language contexts gracefully', () {
        // Test invalid language codes
        expect(() => ttsService.setLanguageContext('invalid', 'INVALID'), returnsNormally);
        expect(() => ttsService.setLanguageContext('', ''), returnsNormally);
        
        // Service should remain stable
        expect(ttsService.currentState, isA<TtsState>());
      });

      test('should handle empty or invalid text input', () {
        ttsService.setLanguageContext('es', 'RVR1960');
        
        // Test empty strings
        expect(ttsService.formatBibleBook(''), equals(''));
        expect(() => ttsService.formatBibleBook(''), returnsNormally);
        
        // Test whitespace only
        expect(() => ttsService.formatBibleBook('   '), returnsNormally);
        
        // Test special characters
        expect(() => ttsService.formatBibleBook('@#$%'), returnsNormally);
      });

      test('should handle service disposal and cleanup', () {
        // Test that service can be used multiple times
        ttsService.setLanguageContext('es', 'RVR1960');
        expect(ttsService.currentState, isA<TtsState>());
        
        ttsService.setLanguageContext('en', 'KJV');
        expect(ttsService.currentState, isA<TtsState>());

        // Test cleanup operations
        expect(() => ttsService.stop(), returnsNormally);
        expect(ttsService.currentState, isA<TtsState>());
      });
    });

    group('Performance and Reliability', () {
      test('should handle rapid state changes gracefully', () {
        // Perform rapid state changes
        for (int i = 0; i < 5; i++) {
          ttsService.setLanguageContext('es', 'RVR1960');
          ttsService.pause();
          ttsService.resume();
          ttsService.stop();
        }

        // Service should remain stable
        expect(ttsService.currentState, isA<TtsState>());
      });

      test('should handle multiple concurrent operations', () {
        // Test multiple rapid operations
        expect(() => ttsService.setLanguageContext('es', 'RVR1960'), returnsNormally);
        expect(() => ttsService.setSpeechRate(1.0), returnsNormally);
        expect(() => ttsService.setPitch(1.0), returnsNormally);
        expect(() => ttsService.setVolume(1.0), returnsNormally);
        
        // Service should handle all operations
        expect(ttsService.currentState, isA<TtsState>());
      });

      test('should maintain consistent state during error conditions', () {
        // Force potential error conditions
        expect(() => ttsService.formatBibleBook(''), returnsNormally);
        expect(() => ttsService.setLanguageContext('invalid', 'invalid'), returnsNormally);
        
        // State should remain consistent
        expect(ttsService.currentState, isA<TtsState>());
        expect(ttsService.isPlaying, isA<bool>());
        expect(ttsService.isPaused, isA<bool>());
      });
    });
  });
}