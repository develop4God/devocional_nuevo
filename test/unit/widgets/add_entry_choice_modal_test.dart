@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/widgets/add_entry_choice_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await registerTestServicesWithFakes();
  });

  Future<void> pumpModal(
    WidgetTester tester, {
    required VoidCallback onAddPrayer,
    required VoidCallback onAddThanksgiving,
    required VoidCallback onAddTestimony,
    String source = 'unknown',
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => AddEntryChoiceModal(
                    onAddPrayer: onAddPrayer,
                    onAddThanksgiving: onAddThanksgiving,
                    onAddTestimony: onAddTestimony,
                    source: source,
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  group('AddEntryChoiceModal', () {
    testWidgets('displays all three choice labels', (tester) async {
      await pumpModal(
        tester,
        onAddPrayer: () {},
        onAddThanksgiving: () {},
        onAddTestimony: () {},
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('prayer.prayer'), findsOneWidget);
      expect(find.text('thanksgiving.thanksgiving'), findsOneWidget);
      expect(find.text('testimony.testimony'), findsOneWidget);
      expect(find.text('devotionals.choose_option'), findsOneWidget);
    });

    testWidgets('tapping prayer choice invokes onAddPrayer and closes modal', (
      tester,
    ) async {
      var prayerTapped = false;
      await pumpModal(
        tester,
        onAddPrayer: () => prayerTapped = true,
        onAddThanksgiving: () {},
        onAddTestimony: () {},
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('prayer.prayer'));
      await tester.pumpAndSettle();

      expect(prayerTapped, isTrue);
      expect(find.text('devotionals.choose_option'), findsNothing);
    });

    testWidgets(
      'tapping thanksgiving choice invokes onAddThanksgiving and closes modal',
      (tester) async {
        var thanksgivingTapped = false;
        await pumpModal(
          tester,
          onAddPrayer: () {},
          onAddThanksgiving: () => thanksgivingTapped = true,
          onAddTestimony: () {},
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('thanksgiving.thanksgiving'));
        await tester.pumpAndSettle();

        expect(thanksgivingTapped, isTrue);
        expect(find.text('devotionals.choose_option'), findsNothing);
      },
    );

    testWidgets(
      'tapping testimony choice invokes onAddTestimony and closes modal',
      (tester) async {
        var testimonyTapped = false;
        await pumpModal(
          tester,
          onAddPrayer: () {},
          onAddThanksgiving: () {},
          onAddTestimony: () => testimonyTapped = true,
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('testimony.testimony'));
        await tester.pumpAndSettle();

        expect(testimonyTapped, isTrue);
        expect(find.text('devotionals.choose_option'), findsNothing);
      },
    );

    testWidgets('only the tapped choice callback fires', (tester) async {
      var prayerTapped = false;
      var thanksgivingTapped = false;
      var testimonyTapped = false;

      await pumpModal(
        tester,
        onAddPrayer: () => prayerTapped = true,
        onAddThanksgiving: () => thanksgivingTapped = true,
        onAddTestimony: () => testimonyTapped = true,
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('testimony.testimony'));
      await tester.pumpAndSettle();

      expect(testimonyTapped, isTrue);
      expect(prayerTapped, isFalse);
      expect(thanksgivingTapped, isFalse);
    });
  });
}
