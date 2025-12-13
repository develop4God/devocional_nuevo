import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/widgets/tts_player_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helpers.dart';

// Test helper provider that overrides recordDevocionalHeard
class TestDevocionalProvider extends DevocionalProvider {
  bool heardCalled = false;
  String? lastId;

  @override
  Future<String> recordDevocionalHeard(String devocionalId,
      double listenedPercentage, BuildContext context) async {
    heardCalled = true;
    lastId = devocionalId;
    return 'guardado';
  }
}

// Mock FlutterTts for testing
class MockFlutterTts extends FlutterTts {
  VoidCallback? _completionHandler;

  @override
  VoidCallback? get completionHandler => _completionHandler;

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    return 1;
  }

  @override
  Future<dynamic> pause() async {
    return 1;
  }

  @override
  Future<dynamic> stop() async {
    return 1;
  }

  @override
  Future<dynamic> setSpeechRate(double rate) async {
    return 1;
  }

  @override
  Future<dynamic> setLanguage(String language) async {
    return 1;
  }

  @override
  Future<dynamic> setVolume(double volume) async {
    return 1;
  }

  @override
  Future<dynamic> setPitch(double pitch) async {
    return 1;
  }

  @override
  set setCompletionHandler(VoidCallback? value) {
    _completionHandler = value;
  }

  void triggerCompletion() {
    _completionHandler?.call();
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    registerTestServices();
  });

  testWidgets('TtsPlayerWidget registers devotional as heard on completed',
      (WidgetTester tester) async {
    // Arrange: create a sample devotional
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

    // Create provider and inject into tree
    final testProvider = TestDevocionalProvider();

    // Build widget
    await tester.pumpWidget(
      MaterialApp(
        home: Provider<DevocionalProvider>.value(
          value: testProvider,
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

    // Act: simulate TTS completed
    controller.complete();

    // Allow async callbacks to run
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // Assert
    expect(testProvider.heardCalled, isTrue);
    expect(testProvider.lastId, equals('test_1'));

    // Cleanup
    controller.dispose();
  });
}
