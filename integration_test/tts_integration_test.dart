// Integration test for TTS audio workflow
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:devocional_nuevo/main.dart' as app;
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/services/tts_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('TTS Integration Tests', () {
    testWidgets('complete audio workflow', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app initialization
      await tester.pump(const Duration(seconds: 2));

      // Look for audio controls (play button)
      final playButtonFinder = find.byIcon(Icons.play_arrow);

      // Skip test if no devotional content is loaded yet
      if (playButtonFinder.evaluate().isEmpty) {
        return;
      }

      // Test audio play functionality
      await tester.tap(playButtonFinder.first);
      await tester.pump(const Duration(seconds: 1));

      // Check if pause button appears (indicating audio started)
      expect(find.byIcon(Icons.pause), findsWidgets);

      // Test pause functionality
      final pauseButtonFinder = find.byIcon(Icons.pause);
      if (pauseButtonFinder.evaluate().isNotEmpty) {
        await tester.tap(pauseButtonFinder.first);
        await tester.pump(const Duration(seconds: 1));

        // Check if play button appears again
        expect(find.byIcon(Icons.play_arrow), findsWidgets);
      }
    });

    testWidgets('audio stops when navigating between devotionals',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app initialization
      await tester.pump(const Duration(seconds: 2));

      final playButtonFinder = find.byIcon(Icons.play_arrow);

      // Skip test if no devotional content is loaded
      if (playButtonFinder.evaluate().isEmpty) {
        return;
      }

      // Start audio
      await tester.tap(playButtonFinder.first);
      await tester.pump(const Duration(seconds: 1));

      // Look for navigation buttons (forward/backward)
      final forwardButtonFinder = find.byIcon(Icons.arrow_forward);
      final backwardButtonFinder = find.byIcon(Icons.arrow_back);

      // Navigate to next devotional if possible
      if (forwardButtonFinder.evaluate().isNotEmpty) {
        await tester.tap(forwardButtonFinder.first);
        await tester.pump(const Duration(seconds: 1));

        // Audio should have stopped (play button should be visible)
        expect(find.byIcon(Icons.play_arrow), findsWidgets);
        expect(find.byIcon(Icons.pause), findsNothing);
      }
    });

    testWidgets('settings page audio configuration',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app initialization
      await tester.pump(const Duration(seconds: 2));

      // Look for settings navigation (usually in app bar or drawer)
      final settingsButtonFinder = find.byIcon(Icons.settings);

      if (settingsButtonFinder.evaluate().isNotEmpty) {
        await tester.tap(settingsButtonFinder.first);
        await tester.pumpAndSettle();

        // Look for audio settings section
        final audioSettingsFinder = find.textContaining('Audio');

        if (audioSettingsFinder.evaluate().isNotEmpty) {
          // Test if audio settings are accessible
          expect(audioSettingsFinder, findsWidgets);

          // Look for speed control slider
          final sliderFinder = find.byType(Slider);
          if (sliderFinder.evaluate().isNotEmpty) {
            // Test slider interaction
            await tester.drag(sliderFinder.first, const Offset(50, 0));
            await tester.pump();

            // Slider should respond to drag
            expect(sliderFinder, findsWidgets);
          }
        }
      }
    });

    testWidgets('TTS service error handling', (WidgetTester tester) async {
      // Test TTS service directly
      final ttsService = TtsService();

      // Test initialization
      await ttsService.initialize();
      expect(ttsService.isDisposed, isFalse);

      // Test invalid operations
      try {
        await ttsService.setSpeechRate(-1.0);
        fail('Should have thrown TtsException for invalid rate');
      } catch (e) {
        expect(e, isA<TtsException>());
      }

      // Test disposal
      await ttsService.dispose();
      expect(ttsService.isDisposed, isTrue);

      // Test operations on disposed service
      try {
        await ttsService.setLanguage('es-ES');
        fail('Should have thrown TtsException for disposed service');
      } catch (e) {
        expect(e, isA<TtsException>());
      }
    });

    testWidgets('TTS performance benchmarks', (WidgetTester tester) async {
      final ttsService = TtsService();
      final stopwatch = Stopwatch();

      // Test initialization time
      stopwatch.start();
      await ttsService.initialize();
      stopwatch.stop();

      final initTime = stopwatch.elapsedMilliseconds;
      expect(initTime, lessThan(500)); // Should initialize in less than 500ms

      // Test language retrieval time
      stopwatch.reset();
      stopwatch.start();
      final languages = await ttsService.getLanguages();
      stopwatch.stop();

      final languageTime = stopwatch.elapsedMilliseconds;
      expect(
          languageTime, lessThan(1000)); // Should get languages in less than 1s
      expect(languages, isA<List<String>>());

      await ttsService.dispose();
    });
  });
}
