import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock FlutterTts for testing
class MockFlutterTts extends FlutterTts {
  bool speakCalled = false;
  bool pauseCalled = false;
  bool stopCalled = false;
  String? lastSpokenText;
  double? lastSpeechRate;
  VoidCallback? _completionHandler;

  @override
  VoidCallback? get completionHandler => _completionHandler;

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    speakCalled = true;
    lastSpokenText = text;
    return 1;
  }

  @override
  Future<dynamic> pause() async {
    pauseCalled = true;
    return 1;
  }

  @override
  Future<dynamic> stop() async {
    stopCalled = true;
    return 1;
  }

  @override
  Future<dynamic> setSpeechRate(double rate) async {
    lastSpeechRate = rate;
    return 1;
  }

  @override
  void setCompletionHandler(VoidCallback handler) {
    _completionHandler = handler;
  }

  void triggerCompletion() {
    if (_completionHandler != null) {
      _completionHandler!();
    }
  }
}

/// Widget tests for TTS Player user flows
/// Tests real user behavior scenarios with mocked dependencies
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group('TTS Player Widget - User Flow Tests', () {
    late MockFlutterTts mockTts;
    late TtsAudioController controller;
    late VoiceSettingsService voiceSettingsService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ServiceLocator().reset();
      mockTts = MockFlutterTts();
      controller = TtsAudioController(flutterTts: mockTts);
      voiceSettingsService = VoiceSettingsService();

      // Register the VoiceSettingsService
      ServiceLocator()
          .registerSingleton<VoiceSettingsService>(voiceSettingsService);
    });

    tearDown(() {
      controller.dispose();
      ServiceLocator().reset();
    });

    group('Scenario 1: First Time User', () {
      test('First time user has no saved voice', () async {
        // GIVEN: User has never selected a voice
        final hasVoice = await voiceSettingsService.hasUserSavedVoice('es');

        // THEN: No voice is saved
        expect(hasVoice, isFalse);
      });

      test('After saving voice, user has saved voice', () async {
        // GIVEN: User has never selected a voice
        expect(await voiceSettingsService.hasUserSavedVoice('es'), isFalse);

        // WHEN: User selects and saves voice
        await voiceSettingsService.setUserSavedVoice('es');

        // THEN: Voice is now saved
        expect(await voiceSettingsService.hasUserSavedVoice('es'), isTrue);
      });
    });

    group('Scenario 2: Returning User', () {
      test('Returning user has saved voice available', () async {
        // GIVEN: User has previously saved a voice
        await voiceSettingsService.setUserSavedVoice('es');

        // WHEN: User checks for saved voice (simulating app return)
        final hasVoice = await voiceSettingsService.hasUserSavedVoice('es');

        // THEN: Saved voice is available
        expect(hasVoice, isTrue);
      });

      test('Returning user with saved voice can play immediately', () async {
        // GIVEN: User has saved voice
        await voiceSettingsService.setUserSavedVoice('es');

        // WHEN: Controller is ready to play
        controller.setText('Test text for playback');

        // THEN: Controller can play (voice check would pass)
        expect(await voiceSettingsService.hasUserSavedVoice('es'), isTrue);
        expect(controller.state.value, equals(TtsPlayerState.idle));
      });
    });

    group('Scenario 3: Language Switcher', () {
      test('User switching language has no voice for new language', () async {
        // GIVEN: User has Spanish voice saved
        await voiceSettingsService.setUserSavedVoice('es');

        // WHEN: User switches to English
        final hasEnglishVoice =
            await voiceSettingsService.hasUserSavedVoice('en');

        // THEN: No English voice saved
        expect(hasEnglishVoice, isFalse);
        // AND: Spanish voice remains saved
        expect(await voiceSettingsService.hasUserSavedVoice('es'), isTrue);
      });

      test('Each language maintains independent voice selection', () async {
        // GIVEN: User saves Spanish voice
        await voiceSettingsService.setUserSavedVoice('es');

        // AND: User saves English voice
        await voiceSettingsService.setUserSavedVoice('en');

        // WHEN: User switches back to Spanish
        final hasSpanish = await voiceSettingsService.hasUserSavedVoice('es');
        final hasEnglish = await voiceSettingsService.hasUserSavedVoice('en');

        // THEN: Both voices remain saved independently
        expect(hasSpanish, isTrue);
        expect(hasEnglish, isTrue);
      });
    });

    group('Scenario 4: Playback Controls', () {
      test('Initial state is idle', () {
        // GIVEN: Fresh controller
        // THEN: State is idle
        expect(controller.state.value, equals(TtsPlayerState.idle));
      });

      test('play() transitions from idle to playing', () async {
        // GIVEN: Controller with text set
        controller.setText('Test playback text');

        // WHEN: play() is called
        await controller.play();

        // THEN: State transitions through loading to playing
        expect(controller.state.value, equals(TtsPlayerState.playing));
        expect(mockTts.speakCalled, isTrue);
      });

      test('pause() transitions from playing to paused', () async {
        // GIVEN: Controller is playing
        controller.setText('Test text');
        await controller.play();
        expect(controller.state.value, equals(TtsPlayerState.playing));

        // WHEN: pause() is called
        await controller.pause();

        // THEN: State is paused
        expect(controller.state.value, equals(TtsPlayerState.paused));
        expect(mockTts.pauseCalled, isTrue);
      });

      test('stop() transitions from any state to idle', () async {
        // GIVEN: Controller is playing
        controller.setText('Test text');
        await controller.play();

        // WHEN: stop() is called
        await controller.stop();

        // THEN: State is idle
        expect(controller.state.value, equals(TtsPlayerState.idle));
        expect(mockTts.stopCalled, isTrue);
      });

      test('play() applies saved speech rate', () async {
        // GIVEN: Custom speech rate is saved
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('tts_rate', 0.8);

        // WHEN: play() is called
        controller.setText('Test text');
        await controller.play();

        // THEN: Speech rate is applied
        expect(mockTts.lastSpeechRate, equals(0.8));
      });
    });

    group('Scenario 5: Completion Tracking', () {
      test('Completion handler changes state to completed', () async {
        // GIVEN: Controller is playing
        controller.setText('Test text');
        await controller.play();
        expect(controller.state.value, equals(TtsPlayerState.playing));

        // WHEN: Audio completes
        mockTts.triggerCompletion();

        // THEN: State is completed
        expect(controller.state.value, equals(TtsPlayerState.completed));
      });

      test('complete() method sets state to completed', () {
        // GIVEN: Controller exists
        // WHEN: complete() is called directly
        controller.complete();

        // THEN: State is completed
        expect(controller.state.value, equals(TtsPlayerState.completed));
      });

      test('Controller can be stopped from completed state', () async {
        // GIVEN: Controller is in completed state
        controller.complete();
        expect(controller.state.value, equals(TtsPlayerState.completed));

        // WHEN: stop() is called
        await controller.stop();

        // THEN: State returns to idle
        expect(controller.state.value, equals(TtsPlayerState.idle));
      });
    });

    group('Controller Error Handling', () {
      test('play() with empty text sets error state', () async {
        // GIVEN: No text set
        // WHEN: play() is called
        await controller.play();

        // THEN: State is error
        expect(controller.state.value, equals(TtsPlayerState.error));
      });

      test('play() with null text sets error state', () async {
        // GIVEN: Text is explicitly not set
        // WHEN: play() is called without setText
        await controller.play();

        // THEN: State is error
        expect(controller.state.value, equals(TtsPlayerState.error));
      });

      test('error() method sets error state', () {
        // WHEN: error() is called
        controller.error();

        // THEN: State is error
        expect(controller.state.value, equals(TtsPlayerState.error));
      });
    });

    group('Controller State Transitions', () {
      test('Multiple rapid play/pause cycles work correctly', () async {
        controller.setText('Test text');

        // Cycle 1
        await controller.play();
        expect(controller.state.value, equals(TtsPlayerState.playing));
        await controller.pause();
        expect(controller.state.value, equals(TtsPlayerState.paused));

        // Cycle 2
        await controller.play();
        expect(controller.state.value, equals(TtsPlayerState.playing));
        await controller.pause();
        expect(controller.state.value, equals(TtsPlayerState.paused));

        // Final stop
        await controller.stop();
        expect(controller.state.value, equals(TtsPlayerState.idle));
      });

      test('setText updates text for playback', () async {
        // GIVEN: Text is set
        controller.setText('First text');
        await controller.play();
        expect(mockTts.lastSpokenText, equals('First text'));

        // WHEN: Text is updated and played again
        await controller.stop();
        controller.setText('Second text');
        await controller.play();

        // THEN: New text is spoken
        expect(mockTts.lastSpokenText, equals('Second text'));
      });
    });
  });
}
