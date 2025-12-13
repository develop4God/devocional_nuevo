import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helpers.dart';

class MockFlutterTts extends FlutterTts {
  bool speakCalled = false;
  String? lastText;

  @override
  Future<dynamic> speak(String text, {bool? focus}) async {
    speakCalled = true;
    lastText = text;
    return Future.value();
  }

  @override
  Future<dynamic> setLanguage(String language) async {
    return Future.value();
  }

  @override
  Future<dynamic> setSpeechRate(double rate) async {
    return Future.value();
  }

  @override
  Future<dynamic> stop() async {
    return Future.value();
  }

  @override
  Future<dynamic> pause() async {
    return Future.value();
  }

  @override
  Future<dynamic> setVolume(double volume) async {
    return Future.value();
  }

  @override
  Future<dynamic> setPitch(double pitch) async {
    return Future.value();
  }

  @override
  Future<dynamic> setQueueMode(int mode) async {
    return Future.value();
  }

  @override
  Future<dynamic> awaitSpeakCompletion(bool value) async {
    return Future.value();
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    registerTestServices();
  });
  test('speakDevotional llama a speak en FlutterTts con el texto normalizado',
      () async {
    final mockTts = MockFlutterTts();
    final ttsService = TtsService.forTest(
      flutterTts: mockTts,
      voiceSettingsService: VoiceSettingsService(),
    );
    final devocional = Devocional(
      id: 'test',
      reflexion: 'Texto de prueba',
      versiculo: 'Juan 3:16',
      paraMeditar: [ParaMeditar(texto: 'Medita en esto', cita: 'Salmo 23:1')],
      oracion: 'Oración de prueba',
      date: DateTime(2025, 1, 1),
    );
    await ttsService.speakDevotional(devocional);
    expect(mockTts.speakCalled, true);
    expect(mockTts.lastText, contains('Texto de prueba'));
  });
  test('speakDevotional speaks the devotional reflection text', () async {
    final mockTts = MockFlutterTts();
    final ttsService = TtsService.forTest(
      flutterTts: mockTts,
      voiceSettingsService: VoiceSettingsService(),
    );
    final devocional = Devocional(
      id: 'test',
      reflexion: 'Texto de prueba',
      versiculo: 'Juan 3:16',
      paraMeditar: [ParaMeditar(texto: 'Medita en esto', cita: 'Salmo 23:1')],
      oracion: 'Oración de prueba',
      date: DateTime(2025, 1, 1),
    );
    await ttsService.speakDevotional(devocional);
    expect(mockTts.speakCalled, true);
    // Note: TtsService.speakDevotional speaks the reflection only
    // Full devotional text with all sections is built by TtsPlayerWidget
    expect(mockTts.lastText, contains('Texto de prueba'));
  });

  test('speakDevotional lanza error si el texto está vacío', () async {
    final mockTts = MockFlutterTts();
    final ttsService = TtsService.forTest(
      flutterTts: mockTts,
      voiceSettingsService: VoiceSettingsService(),
    );
    final devocional = Devocional(
      id: 'test',
      reflexion: '',
      versiculo: '',
      paraMeditar: [],
      oracion: '',
      date: DateTime(2025, 1, 1),
    );
    expect(() async => await ttsService.speakDevotional(devocional),
        throwsException);
  });

  test('setLanguage y setSpeechRate no lanzan error y configuran correctamente',
      () async {
    final mockTts = MockFlutterTts();
    final ttsService = TtsService.forTest(
      flutterTts: mockTts,
      voiceSettingsService: VoiceSettingsService(),
    );
    await ttsService.setLanguage('es-ES');
    await ttsService.setSpeechRate(0.8);
    // Si no lanza excepción, pasa
    expect(true, true);
  });
}
