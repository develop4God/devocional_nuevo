@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/utils/constants/bubble_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeLocalizationService extends LocalizationService {
  @override
  String translate(String key, [Map<String, dynamic>? params]) => key;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ServiceLocator().reset();
    ServiceLocator().registerSingleton<LocalizationService>(
      FakeLocalizationService(),
    );
  });

  tearDown(() {
    ServiceLocator().reset();
  });

  Widget wrap(String bubbleId) {
    return MaterialApp(
      home: Scaffold(
        body: const Text('target').newBubbleWithId(bubbleId),
      ),
    );
  }

  testWidgets('shows the bubble for an unseen id', (tester) async {
    await tester.pumpWidget(wrap('unseen_bubble_1'));
    await tester.pumpAndSettle();

    expect(find.text('bubble_constants.new_feature'), findsOneWidget);
  });

  testWidgets(
    'bubble disappears reactively when marked as shown elsewhere, without rebuilding the tree',
    (tester) async {
      const bubbleId = 'reactive_bubble_1';
      await tester.pumpWidget(wrap(bubbleId));
      await tester.pumpAndSettle();

      expect(find.text('bubble_constants.new_feature'), findsOneWidget);

      await tester.runAsync(() => BubbleUtils.markAsShown(bubbleId));
      await tester.pumpAndSettle();

      expect(find.text('bubble_constants.new_feature'), findsNothing);
    },
  );

  testWidgets(
    'disposing a bubble widget does not throw when the manager later notifies',
    (tester) async {
      const bubbleId = 'disposed_bubble_1';
      await tester.pumpWidget(wrap(bubbleId));
      await tester.pumpAndSettle();

      // Dispose the bubble by replacing the tree entirely.
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pumpAndSettle();

      await tester.runAsync(() => BubbleUtils.markAsShown(bubbleId));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}
