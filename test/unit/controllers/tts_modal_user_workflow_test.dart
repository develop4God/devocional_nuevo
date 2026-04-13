@Tags(['unit', 'controllers', 'tts'])
library;

import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock for FlutterTts to simulate audio playback
class MockFlutterTts extends Mock implements FlutterTts {
  @override
  Future<dynamic> speak(String text, {bool focus = false}) async => 1;

  @override
  Future<dynamic> pause() async => 1;

  @override
  Future<dynamic> stop() async => 1;

  @override
  Future<dynamic> setSpeechRate(double rate) async => 1;

  @override
  Future<dynamic> awaitSpeakCompletion(bool awaitCompletion) async => 1;

  @override
  void setCompletionHandler(VoidCallback handler) {}

  @override
  void setStartHandler(VoidCallback handler) {}

  @override
  void setCancelHandler(VoidCallback handler) {}

  @override
  void setErrorHandler(Function(dynamic) handler) {}
}

void main() {
  group('TTS Modal - Real User Behavior Tests', () {
    late MockFlutterTts mockTts;
    late TtsAudioController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ServiceLocator().reset();
      setupServiceLocator();

      mockTts = MockFlutterTts();
      controller = TtsAudioController(
        flutterTts: mockTts,
        voiceSettingsService: VoiceSettingsService(),
      );
    });

    tearDown(() {
      controller.dispose();
      ServiceLocator().reset();
    });

    test(
      'User plays devotional audio and modal shows expected states',
      () async {
        // GIVEN: User has a devotional text to listen to
        const devotionalText = '''
        Versículo: Juan 3:16 - Porque de tal manera amó Dios al mundo
        Reflexión: Una profunda reflexión sobre el amor de Dios
        Oración: Padre celestial, gracias por tu amor incondicional
      ''';

        // WHEN: User sets up the audio
        controller.setText(devotionalText);

        // THEN: Duration should be calculated at 1.0x speed
        await Future.delayed(const Duration(milliseconds: 100));
        final duration = controller.totalDuration.value;
        expect(
          duration.inSeconds,
          greaterThan(0),
          reason: 'Duration should be calculated based on text',
        );

        // WHEN: User presses play
        final playFuture = controller.play();

        // Wait a bit for state to transition
        await Future.delayed(const Duration(milliseconds: 100));

        // THEN: State transitions to loading then playing
        expect(
          [TtsPlayerState.loading, TtsPlayerState.playing]
              .contains(controller.state.value),
          isTrue,
        );
        await Future.delayed(const Duration(milliseconds: 500));
        await playFuture;

        expect(controller.state.value, TtsPlayerState.playing);

        // WHEN: User pauses playback
        await controller.pause();

        // THEN: State changes to paused
        expect(controller.state.value, TtsPlayerState.paused);

        // WHEN: User resumes playback
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        // THEN: State returns to playing
        expect(controller.state.value, TtsPlayerState.playing);

        // WHEN: User stops playback completely
        await controller.stop();

        // THEN: State is idle and position resets
        expect(controller.state.value, TtsPlayerState.idle);
        expect(controller.currentPosition.value, Duration.zero);
      },
    );

    test('User changes playback speed and duration remains constant', () async {
      // GIVEN: User has audio loaded
      const text =
          'Este es un texto de prueba para TTS que debe durar varios segundos cuando se reproduce a velocidad normal.';
      controller.setText(text);

      await Future.delayed(const Duration(milliseconds: 100));
      final originalDuration = controller.totalDuration.value;

      // WHEN: User cycles through playback speeds
      for (int i = 0; i < 3; i++) {
        await controller.cyclePlaybackRate();
        await Future.delayed(const Duration(milliseconds: 100));

        // THEN: Duration remains constant (calculated at 1.0x speed)
        expect(
          controller.totalDuration.value,
          equals(originalDuration),
          reason:
              'Duration should remain constant regardless of playback speed',
        );
      }
    });

    test('User seeks to different positions in audio', () async {
      // GIVEN: User has audio set up
      final text = 'Un texto largo para probar la funcionalidad de seek ' * 10;
      controller.setText(text);

      final totalDuration = controller.totalDuration.value;

      // WHEN: User seeks to 25% position
      final seekPosition = Duration(
        milliseconds: (totalDuration.inMilliseconds * 0.25).round(),
      );
      controller.seek(seekPosition);

      // THEN: Position updates correctly
      await Future.delayed(const Duration(milliseconds: 100));
      expect(
        controller.currentPosition.value.inSeconds,
        closeTo(seekPosition.inSeconds, 2),
        reason: 'Position should be close to seek target',
      );

      // WHEN: User seeks to 75% position
      final seekPosition2 = Duration(
        milliseconds: (totalDuration.inMilliseconds * 0.75).round(),
      );
      controller.seek(seekPosition2);

      // THEN: Position updates again
      await Future.delayed(const Duration(milliseconds: 100));
      expect(
        controller.currentPosition.value.inSeconds,
        closeTo(seekPosition2.inSeconds, 2),
        reason: 'Position should update on second seek',
      );
    });

    test(
      'User completes audio playback and state transitions correctly',
      () async {
        // GIVEN: User starts audio playback
        const text = 'Texto breve';
        controller.setText(text);
        await controller.play();
        await Future.delayed(const Duration(milliseconds: 500));

        expect(controller.state.value, TtsPlayerState.playing);

        // WHEN: Audio completes (simulated)
        controller.complete();

        // THEN: State is completed
        expect(controller.state.value, TtsPlayerState.completed);
        expect(
          controller.currentPosition.value,
          controller.totalDuration.value,
          reason: 'Position should be at end when completed',
        );
      },
    );

    test('User stops and restarts audio multiple times', () async {
      // Scenario: User frequently stops and restarts to re-listen to parts
      const text = 'Texto de prueba para escuchar repetidamente';
      controller.setText(text);

      // First playback
      await controller.play();
      await Future.delayed(const Duration(milliseconds: 300));
      expect(controller.state.value, TtsPlayerState.playing);

      await controller.stop();
      expect(controller.state.value, TtsPlayerState.idle);
      expect(controller.currentPosition.value, Duration.zero);

      // Second playback
      await controller.play();
      await Future.delayed(const Duration(milliseconds: 300));
      expect(controller.state.value, TtsPlayerState.playing);

      await controller.stop();
      expect(controller.state.value, TtsPlayerState.idle);

      // Third playback
      await controller.play();
      await Future.delayed(const Duration(milliseconds: 300));
      expect(controller.state.value, TtsPlayerState.playing);
    });

    test('User rapidly changes controls (stress test)', () async {
      // Scenario: User quickly taps multiple controls
      const text = 'Texto para prueba de estrés';
      controller.setText(text);

      // Rapid play/pause cycles
      await controller.play();
      await Future.delayed(const Duration(milliseconds: 50));
      await controller.pause();
      await Future.delayed(const Duration(milliseconds: 50));
      await controller.play();
      await Future.delayed(const Duration(milliseconds: 50));
      await controller.pause();

      // Should still be in a valid state
      expect(controller.state.value, TtsPlayerState.paused);

      // Rapid speed changes — supported rates are 0.5, 1.0, 1.5
      for (int i = 0; i < 5; i++) {
        await controller.cyclePlaybackRate();
        await Future.delayed(const Duration(milliseconds: 20));
      }

      // Should still be functional
      expect(
        controller.playbackRate.value,
        isIn([0.5, 1.0, 1.5]),
        reason: 'Playback rate should be one of the supported rates',
      );
    });

    test('User workflow: Play, adjust speed, seek, then close', () async {
      // Complete user journey
      const text = 'Reflexión completa del devocional de hoy';
      controller.setText(text);
      await controller.play();
      await Future.delayed(const Duration(milliseconds: 400));

      expect(controller.state.value, TtsPlayerState.playing);
      final initialRate = controller.playbackRate.value;

      // User adjusts speed
      await controller.cyclePlaybackRate();
      expect(controller.playbackRate.value, isNot(equals(initialRate)));

      // User seeks forward
      final duration = controller.totalDuration.value;
      controller.seek(Duration(milliseconds: duration.inMilliseconds ~/ 2));
      await Future.delayed(const Duration(milliseconds: 100));

      // User closes modal by stopping
      await controller.stop();
      expect(controller.state.value, TtsPlayerState.idle);
    });

    test('Edge case: Very short text', () async {
      // GIVEN: Very short text
      controller.setText('Hola');

      // WHEN: User tries to play
      await controller.play();
      await Future.delayed(const Duration(milliseconds: 300));

      // THEN: Should still work correctly
      expect([
        TtsPlayerState.playing,
        TtsPlayerState.loading,
      ], contains(controller.state.value));

      // Cleanup
      await controller.stop();
    });

    test('Edge case: User seeks beyond duration', () async {
      // GIVEN: Audio with known duration
      controller.setText('Texto de prueba');
      final duration = controller.totalDuration.value;

      // WHEN: User tries to seek beyond end
      controller.seek(Duration(seconds: duration.inSeconds + 100));

      // THEN: Position should be clamped to duration
      await Future.delayed(const Duration(milliseconds: 100));
      expect(
        controller.currentPosition.value.inSeconds,
        lessThanOrEqualTo(duration.inSeconds),
      );
    });

    test('State persistence: Duration survives speed changes', () async {
      // Tests architectural requirement: duration calculated once at 1.0x
      controller.setText('Texto de prueba para verificar persistencia');
      final originalDuration = controller.totalDuration.value;

      // Change speed multiple times
      await controller.cyclePlaybackRate();
      expect(controller.totalDuration.value, equals(originalDuration));

      await controller.cyclePlaybackRate();
      expect(controller.totalDuration.value, equals(originalDuration));

      await controller.cyclePlaybackRate();
      expect(controller.totalDuration.value, equals(originalDuration));

      // Verify it's architecturally sound
      expect(
        originalDuration.inSeconds,
        greaterThan(0),
        reason: 'Duration should be meaningful',
      );
    });
  });
}
