import 'package:devocional_nuevo/services/tts_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TtsService emergency timer estimation', () {
    test('Japanese chunks get appropriate timer duration', () {
      final chunk = List.filled(10, 'これは日本語のテキストです。').join(); // ~220-260 chars
      final estimated = TtsService.computeEstimatedEmergencyMs(chunk, 'ja');

      // Para japonés esperamos que el cálculo use caracteres/6 -> wordCount ~= chunk.length/6
      final expectedWordCount = (chunk.trim().length / 6).ceil();
      final minTimer = expectedWordCount < 10 ? 2500 : 4000;
      const maxTimer = 10000;
      final expected =
          ((expectedWordCount * 180).clamp(minTimer, maxTimer)).toInt();

      expect(estimated, expected);
      expect(estimated <= maxTimer, true);
      expect(estimated >= minTimer, true);
    });

    test('Non-Japanese chunks use whitespace word count', () {
      final chunk =
          'This is a sample English sentence with several words repeated. ' * 5;
      final estimated = TtsService.computeEstimatedEmergencyMs(chunk, 'en');

      final expectedWordCount = chunk.trim().split(RegExp(r'\s+')).length;
      final minTimer = expectedWordCount < 10 ? 2500 : 4000;
      const maxTimer = 10000;
      final expected =
          ((expectedWordCount * 180).clamp(minTimer, maxTimer)).toInt();

      expect(estimated, expected);
      expect(estimated <= maxTimer, true);
      expect(estimated >= minTimer, true);
    });
  });
}
