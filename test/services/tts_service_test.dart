import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFlutterTts extends FlutterTts {
  bool speakCalled = false;
  String? lastText;

  @override
  Future<dynamic> speak(String text, {bool? focus}) async {
    speakCalled = true;
    lastText = text;
    return Future.value();
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
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
}
