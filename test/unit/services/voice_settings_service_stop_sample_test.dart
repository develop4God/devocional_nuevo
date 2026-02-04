// test/unit/services/voice_settings_service_stop_sample_test.dart

import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'voice_settings_service_stop_sample_test.mocks.dart';

@Tags(['unit', 'services'])
@GenerateMocks([FlutterTts])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VoiceSettingsService voiceSettingsService;
  late MockFlutterTts mockFlutterTts;

  setUp(() {
    mockFlutterTts = MockFlutterTts();
    voiceSettingsService = VoiceSettingsService.withBothTts(
      mockFlutterTts,
      mockFlutterTts,
    );
  });

  group('VoiceSettingsService - Voice Sample Playback', () {
    test(
      'playVoiceSample should stop previous sample before playing new one',
      () async {
        // Arrange
        when(mockFlutterTts.stop()).thenAnswer((_) async => 1);
        when(mockFlutterTts.setVoice(any)).thenAnswer((_) async => 1);
        when(mockFlutterTts.setSpeechRate(any)).thenAnswer((_) async => 1);
        when(mockFlutterTts.speak(any)).thenAnswer((_) async => 1);

        // Act
        await voiceSettingsService.playVoiceSample(
          'en-us-x-tpf-local',
          'en-US',
          'Test sample text',
        );

        // Assert
        verify(mockFlutterTts.stop()).called(1);
        verify(mockFlutterTts.setVoice(any)).called(1);
        verify(mockFlutterTts.setSpeechRate(any)).called(1);
        verify(mockFlutterTts.speak(any)).called(1);
      },
    );

    test('playVoiceSample should handle multiple calls correctly', () async {
      // Arrange
      when(mockFlutterTts.stop()).thenAnswer((_) async => 1);
      when(mockFlutterTts.setVoice(any)).thenAnswer((_) async => 1);
      when(mockFlutterTts.setSpeechRate(any)).thenAnswer((_) async => 1);
      when(mockFlutterTts.speak(any)).thenAnswer((_) async => 1);

      // Act - Simulate double tap (play sample twice)
      await voiceSettingsService.playVoiceSample(
        'en-us-x-tpf-local',
        'en-US',
        'First sample',
      );
      await voiceSettingsService.playVoiceSample(
        'en-us-x-tpd-network',
        'en-US',
        'Second sample',
      );

      // Assert - Stop should be called twice (once for each play)
      verify(mockFlutterTts.stop()).called(2);
      verify(mockFlutterTts.setVoice(any)).called(2);
      verify(mockFlutterTts.setSpeechRate(any)).called(2);
      verify(mockFlutterTts.speak(any)).called(2);
    });

    test('stopVoiceSample should stop playing voice', () async {
      // Arrange
      when(mockFlutterTts.stop()).thenAnswer((_) async => 1);

      // Act
      await voiceSettingsService.stopVoiceSample();

      // Assert
      verify(mockFlutterTts.stop()).called(1);
    });

    test('playVoiceSample should handle errors gracefully', () async {
      // Arrange
      when(mockFlutterTts.stop()).thenThrow(Exception('Stop failed'));
      when(mockFlutterTts.setVoice(any)).thenAnswer((_) async => 1);
      when(mockFlutterTts.speak(any)).thenAnswer((_) async => 1);

      // Act & Assert - Should not throw
      await voiceSettingsService.playVoiceSample(
        'en-us-x-tpf-local',
        'en-US',
        'Test sample',
      );

      // Verify stop was attempted despite error
      verify(mockFlutterTts.stop()).called(1);
    });
  });
}
