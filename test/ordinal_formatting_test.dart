import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Ordinal Formatting Tests', () {
    late TtsService ttsService;

    setUp(() {
      // Set up method channel mocks for TTS
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'setLanguage':
            case 'setSpeechRate':
            case 'setVolume':
            case 'setPitch':
            case 'awaitSpeakCompletion':
            case 'speak':
            case 'pause':
            case 'stop':
              return null;
            default:
              return null;
          }
        },
      );

      // Set up SharedPreferences mock
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getAll') {
            return <String, dynamic>{}; // Return empty preferences
          }
          return null;
        },
      );

      ttsService = TtsService();
    });

    tearDown(() {
      ttsService.dispose();

      // Clean up method channel mocks
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        null,
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        null,
      );
    });

    test('should format Spanish ordinals correctly', () {
      ttsService.setLanguageContext('es', 'RVR1960');

      expect(ttsService.formatBibleBook('1 Juan'), contains('Primera de Juan'));
      expect(ttsService.formatBibleBook('2 Corintios'),
          contains('Segunda de Corintios'));
      expect(ttsService.formatBibleBook('3 Juan'), contains('Tercera de Juan'));
      expect(ttsService.formatBibleBook('Génesis'),
          equals('Génesis')); // No ordinal change
    });

    test('should format English ordinals correctly', () {
      ttsService.setLanguageContext('en', 'KJV');

      expect(ttsService.formatBibleBook('1 John'), contains('First John'));
      expect(ttsService.formatBibleBook('2 Corinthians'),
          contains('Second Corinthians'));
      expect(ttsService.formatBibleBook('3 John'), contains('Third John'));
      expect(ttsService.formatBibleBook('Genesis'),
          equals('Genesis')); // No ordinal change
    });

    test('should format Portuguese ordinals correctly', () {
      ttsService.setLanguageContext('pt', 'ARC');

      expect(ttsService.formatBibleBook('1 João'), contains('Primeiro João'));
      expect(ttsService.formatBibleBook('2 Coríntios'),
          contains('Segundo Coríntios'));
      expect(ttsService.formatBibleBook('3 João'), contains('Terceiro João'));
      expect(ttsService.formatBibleBook('Gênesis'),
          equals('Gênesis')); // No ordinal change
    });

    test('should format French ordinals correctly', () {
      ttsService.setLanguageContext('fr', 'LSG1910');

      expect(ttsService.formatBibleBook('1 Jean'), contains('Premier Jean'));
      expect(ttsService.formatBibleBook('2 Corinthiens'),
          contains('Deuxième Corinthiens'));
      expect(ttsService.formatBibleBook('3 Jean'), contains('Troisième Jean'));
      expect(ttsService.formatBibleBook('Genèse'),
          equals('Genèse')); // No ordinal change
    });

    test('should default to Spanish when language context is not set', () {
      // Reset to default Spanish context
      ttsService.setLanguageContext('es', 'RVR1960');

      final result = ttsService.formatBibleBook('1 Juan');
      // Using debugPrint instead of print for test output
      expect(result, contains('Primera de Juan'));
      expect(
          ttsService.formatBibleBook('2 Pedro'), contains('Segunda de Pedro'));
    });

    test('should handle unknown language by defaulting to Spanish', () {
      ttsService.setLanguageContext('unknown', 'UNKNOWN');

      expect(ttsService.formatBibleBook('1 Juan'), contains('Primera de Juan'));
      expect(
          ttsService.formatBibleBook('2 Pedro'), contains('Segunda de Pedro'));
    });
  });
}
