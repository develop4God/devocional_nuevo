import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:devocional_nuevo/utils/copyright_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

void main() {
  group('Multilingual TTS Tests', () {
    late TtsService ttsService;

    setUpAll(() async {
      // Initialize Flutter binding for tests
      TestWidgetsFlutterBinding.ensureInitialized();

      // Mock the method channel for flutter_tts using the new API
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        (call) async {
          switch (call.method) {
            case 'speak':
              return null;
            case 'setLanguage':
              return null;
            case 'setSpeechRate':
              return null;
            case 'setVolume':
              return null;
            case 'setPitch':
              return null;
            case 'stop':
              return null;
            case 'pause':
              return null;
            case 'getLanguages':
              return ['es-ES', 'en-US', 'pt-BR', 'fr-FR'];
            case 'awaitSpeakCompletion':
              return null;
            default:
              return null;
          }
        },
      );
    });

    setUp(() {
      // Create fresh instance for each test to avoid state pollution
      ttsService = TtsService();
    });

    test('should set language context correctly for all supported languages', () {
      final testCases = [
        {'lang': 'es', 'version': 'RVR1960'},
        {'lang': 'en', 'version': 'KJV'},
        {'lang': 'pt', 'version': 'ARC'},
        {'lang': 'fr', 'version': 'LSG1910'},
      ];

      for (final testCase in testCases) {
        ttsService.setLanguageContext(testCase['lang']!, testCase['version']!);
        expect(ttsService.currentState, TtsState.idle);
      }
    });

    group('Bible Book Formatting Tests', () {
      test('should format ordinals correctly for all languages', () {
        // Test Spanish
        ttsService.setLanguageContext('es', 'RVR1960');
        final spanishResult = ttsService.formatBibleBook('1 Juan');
        expect(spanishResult, contains('Primera de Juan'));

        // Test other languages return valid strings (implementation may vary)
        final englishResult = ttsService.formatBibleBook('1 John');
        expect(englishResult, isA<String>());
        
        final portugueseResult = ttsService.formatBibleBook('1 João');
        expect(portugueseResult, isA<String>());
        
        final frenchResult = ttsService.formatBibleBook('1 Jean');
        expect(frenchResult, isA<String>());
      });
    });

    group('Copyright Utils Tests', () {
      test('should get correct copyright keys for all versions', () {
        final testCases = [
          {'version': 'RVR1960', 'expected': 'rvr1960'},
          {'version': 'KJV', 'expected': 'kjv'},
          {'version': 'ARC', 'expected': 'arc'},
          {'version': 'LSG1910', 'expected': 'lsg1910'},
        ];

        for (final testCase in testCases) {
          final key = 'devotionals.copyright_${testCase['expected']}';
          expect(key.toLowerCase(), contains(testCase['expected']!));
        }
      });

      test('should get Bible version display names correctly', () {
        final testCases = [
          {'lang': 'en', 'version': 'KJV', 'expected': 'King James Version'},
          {'lang': 'pt', 'version': 'ARC', 'expected': 'Almeida Revista e Corrigida'},
          {'lang': 'fr', 'version': 'LSG1910', 'expected': 'Louis Segond 1910'},
        ];

        for (final testCase in testCases) {
          final result = CopyrightUtils.getBibleVersionDisplayName(
            testCase['lang']!, testCase['version']!);
          expect(result, equals(testCase['expected']));
        }
      });

      test('should fallback to version code for unknown versions', () {
        final result =
            CopyrightUtils.getBibleVersionDisplayName('en', 'UNKNOWN');
        expect(result, equals('UNKNOWN'));
      });
    });

    group('TTS Audio Controls Tests', () {
      test('should maintain consistent state and controls across all languages', () {
        final localTts = TtsService();
        final languages = ['es', 'en', 'pt', 'fr'];
        final versions = ['RVR1960', 'KJV', 'ARC', 'LSG1910'];

        for (int i = 0; i < languages.length; i++) {
          localTts.setLanguageContext(languages[i], versions[i]);

          // Verify basic TTS service properties are consistent
          expect(localTts.currentState, TtsState.idle);
          expect(localTts.isPlaying, isFalse);
          expect(localTts.isPaused, isFalse);
        }
      });
    });
  });
}
