@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/controllers/tts_audio_controller.dart';
import 'package:devocional_nuevo/widgets/tts_miniplayer_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUp(() async {
    await registerTestServices();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => TtsMiniplayerModal(
                    positionListenable: ValueNotifier(Duration.zero),
                    totalDurationListenable: ValueNotifier(
                      const Duration(minutes: 1),
                    ),
                    stateListenable: ValueNotifier(TtsPlayerState.playing),
                    playbackRateListenable: ValueNotifier(1.0),
                    playbackRates: const [1.0, 1.25, 1.5],
                    onStop: () {},
                    onSeek: (_) {},
                    onTogglePlay: () {},
                    onCycleRate: () {},
                    onVoiceSelector: () {},
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  group('TtsMiniplayerModal swipe-down chevron cue', () {
    testWidgets('tapping the chevron dismisses the modal', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('open'));
      // The chevron's pulse animation repeats forever, so settle the sheet's
      // entrance transition with a bounded pump instead of pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TtsMiniplayerModal), findsOneWidget);

      await tester.tap(find.byIcon(Icons.expand_circle_down_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TtsMiniplayerModal), findsNothing);
    });

    testWidgets('chevron scale pulses over time', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('open'));
      await tester.pump();

      Transform findChevronScale() => tester.widget<Transform>(
            find.ancestor(
              of: find.byIcon(Icons.expand_circle_down_outlined),
              matching: find.byType(Transform),
            ),
          );

      final initialScale = findChevronScale().transform.getMaxScaleOnAxis();

      await tester.pump(const Duration(milliseconds: 500));
      final laterScale = findChevronScale().transform.getMaxScaleOnAxis();

      expect(laterScale, isNot(equals(initialScale)));

      // Clean up the still-animating sheet without leaking timers.
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
