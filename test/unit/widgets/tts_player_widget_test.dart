import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/widgets/tts_player_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

// MockFlutterTts para pruebas

@Tags(['unit', 'widgets'])
class MockFlutterTts extends FlutterTts {
  bool speakCalled = false;
  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    speakCalled = true;
    return 1;
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    registerTestServices();
  });

  testWidgets('TtsPlayerWidget renders and play button is present', (
    WidgetTester tester,
  ) async {
    final dev = Devocional(
      id: 'test_1',
      versiculo: 'John 3:16',
      reflexion: 'Test reflection',
      paraMeditar: [],
      oracion: 'Test prayer',
      date: DateTime.now(),
    );
    final mockTts = MockFlutterTts();
    final controller = TtsAudioController(flutterTts: mockTts);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => DevocionalProvider(),
          child: Scaffold(
            body: Center(
              child: TtsPlayerWidget(
                devocional: dev,
                audioController: controller,
                onCompleted: () {},
              ),
            ),
          ),
        ),
      ),
    );

    // Wait for widget to settle
    await tester.pumpAndSettle();

    // Check for play button (IconButton with play icon)
    expect(find.byType(TtsPlayerWidget), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsWidgets);
  });
}
