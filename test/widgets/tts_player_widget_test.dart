import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/widgets/tts_player_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

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

// Fake controller that exposes the minimal API needed by TtsPlayerWidget
class FakeTtsAudioController {
  final ValueNotifier<TtsPlayerState> state =
      ValueNotifier<TtsPlayerState>(TtsPlayerState.idle);
  final ValueNotifier<Duration> currentPosition = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> totalDuration = ValueNotifier(Duration.zero);
  final ValueNotifier<double> playbackRate = ValueNotifier(1.0);

  void setText(String _) {}

  Future<void> play() async => state.value = TtsPlayerState.playing;

  Future<void> pause() async => state.value = TtsPlayerState.paused;

  Future<void> stop() async => state.value = TtsPlayerState.idle;

  void seek(Duration _) {}

  void dispose() {
    state.dispose();
    currentPosition.dispose();
    totalDuration.dispose();
    playbackRate.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    final controller = FakeTtsAudioController();

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
                audioController: controller as dynamic,
                onCompleted: () {},
              ),
            ),
          ),
        ),
      ),
    );

    // Act: simulate TTS completed
    controller.state.value = TtsPlayerState.completed;

    // Allow async callbacks to run
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    // Assert
    expect(testProvider.heardCalled, isTrue);
    expect(testProvider.lastId, equals('test_1'));
  });
}
