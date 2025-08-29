import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Issue #46 - Multilingual Ordinals Integration Test', () {
    late TtsService ttsService;

    setUp(() {
      // Set up method channel mocks for TTS
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        (MethodCall methodCall) async {
          return null;
        },
      );

      // Set up SharedPreferences mock
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getAll') {
            return <String, dynamic>{};
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

    test('Issue #46: Ordinals should work for all languages based on context', () {
      // Test the main issue: formatBibleBook should respect language context
      
      // Spanish context - should work as before (maintaining compatibility)
      ttsService.setLanguageContext('es', 'RVR1960');
      expect(ttsService.formatBibleBook('1 Juan'), equals('Primera de Juan'));
      expect(ttsService.formatBibleBook('2 Pedro'), equals('Segunda de Pedro'));
      expect(ttsService.formatBibleBook('3 Juan'), equals('Tercera de Juan'));
      
      // English context - NEW: should format in English
      ttsService.setLanguageContext('en', 'KJV');
      expect(ttsService.formatBibleBook('1 John'), equals('First John'));
      expect(ttsService.formatBibleBook('2 Corinthians'), equals('Second Corinthians'));
      expect(ttsService.formatBibleBook('3 John'), equals('Third John'));
      
      // Portuguese context - NEW: should format in Portuguese  
      ttsService.setLanguageContext('pt', 'ARC');
      expect(ttsService.formatBibleBook('1 João'), equals('Primeiro João'));
      expect(ttsService.formatBibleBook('2 Coríntios'), equals('Segundo Coríntios'));
      expect(ttsService.formatBibleBook('3 João'), equals('Terceiro João'));
      
      // French context - NEW: should format in French
      ttsService.setLanguageContext('fr', 'LSG1910');
      expect(ttsService.formatBibleBook('1 Jean'), equals('Premier Jean'));
      expect(ttsService.formatBibleBook('2 Corinthiens'), equals('Deuxième Corinthiens'));
      expect(ttsService.formatBibleBook('3 Jean'), equals('Troisième Jean'));
    });

    test('Issue #46: TTS service is now modularized and maintainable', () {
      // Verify that the service still works but is now using modules internally
      
      // Test that the service can switch between languages correctly
      ttsService.setLanguageContext('es', 'RVR1960');
      String result = ttsService.formatBibleBook('1 Corintios');
      expect(result, contains('Primera de'));
      
      ttsService.setLanguageContext('en', 'KJV');
      result = ttsService.formatBibleBook('1 Corinthians');
      expect(result, contains('First'));
      
      // Verify service is still functional
      expect(ttsService.currentState, equals(TtsState.idle));
    });

    test('Issue #46: Spanish functionality remains unchanged (backward compatibility)', () {
      // Ensure production Spanish users see no changes
      ttsService.setLanguageContext('es', 'RVR1960');
      
      expect(ttsService.formatBibleBook('1 Juan'), equals('Primera de Juan'));
      expect(ttsService.formatBibleBook('2 Timoteo'), equals('Segunda de Timoteo'));
      expect(ttsService.formatBibleBook('3 Juan'), equals('Tercera de Juan'));
      expect(ttsService.formatBibleBook('Génesis'), equals('Génesis')); // No ordinal
      expect(ttsService.formatBibleBook('Apocalipsis'), equals('Apocalipsis')); // No ordinal
    });
  });
}