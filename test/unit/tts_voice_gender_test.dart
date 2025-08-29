import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TTS Voice Gender Detection Tests', () {
    late TtsService ttsService;

    setUp(() {
      ttsService = TtsService();
    });

    test('should identify female voices correctly', () {
      // Test common female voice names
      final femaleVoices = [
        'Samantha',
        'Anna',
        'Karen',
        'com.apple.ttsbundle.samantha-compact',
        'microsoft-zira-voice',
        'Maria',
        'Sofia',
        'Paloma',
        'Alice',
        'Amelie',
        'Joanna',
        'Nicole',
        'Any Name with Female',
      ];

      for (final voiceName in femaleVoices) {
        final result = ttsService._getVoiceGenderInfo(voiceName);
        expect(result, contains('♀'));
        expect(result, contains('Female'));
      }
    });

    test('should identify male voices correctly', () {
      // Test common male voice names
      final maleVoices = [
        'Alex',
        'Daniel',
        'Diego',
        'Carlos',
        'Thomas',
        'David',
        'microsoft-david-voice',
        'com.apple.speech.synthesis.voice.alex',
        'Antonio',
        'Francisco',
        'Miguel',
        'James',
        'Any Name with Male',
      ];

      for (final voiceName in maleVoices) {
        final result = ttsService._getVoiceGenderInfo(voiceName);
        expect(result, contains('♂'));
        expect(result, contains('Male'));
      }
    });

    test('should return empty string for unknown voices', () {
      final unknownVoices = [
        'UnknownVoice',
        'RandomName',
        'SomeOtherVoice',
        '',
      ];

      for (final voiceName in unknownVoices) {
        final result = ttsService._getVoiceGenderInfo(voiceName);
        expect(result, isEmpty);
      }
    });

    test('should be case insensitive', () {
      final testCases = [
        'SAMANTHA',
        'samantha',
        'Samantha',
        'ALEX',
        'alex',
        'Alex',
      ];

      for (final voiceName in testCases) {
        final result = ttsService._getVoiceGenderInfo(voiceName);
        expect(result, isNotEmpty);
      }
    });
  });

  group('TTS Voice Prioritization Tests', () {
    test('should prioritize US voices in sorting', () {
      final mockVoices = [
        {'name': 'Karen', 'locale': 'en-AU'},
        {'name': 'Samantha (♀ Female)', 'locale': 'en-US'},
        {'name': 'Alex (♂ Male)', 'locale': 'en-US'},
        {'name': 'Daniel', 'locale': 'en-GB'},
      ];

      // Note: This is a conceptual test - actual implementation would need
      // access to the sorting logic in getVoicesForLanguage
      // In a real implementation, you'd extract the sorting logic to a 
      // separate testable method
    });

    test('should prioritize female voices over male voices', () {
      final mockVoices = [
        'Alex (♂ Male) (en-US)',
        'Samantha (♀ Female) (en-US)',
        'Daniel (♂ Male) (en-GB)',
        'Karen (♀ Female) (en-AU)',
      ];

      // Conceptual test for gender-based sorting
      // Female voices should come before male voices in the same region
    });
  });
}