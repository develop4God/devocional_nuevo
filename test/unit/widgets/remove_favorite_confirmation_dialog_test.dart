@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/delete_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await registerTestServices();
    final localizationService = getService<LocalizationService>();
    await localizationService.initialize();
    await localizationService.changeLocale(const Locale('en'));
  });

  Future<Future<bool> Function()> showDialogUnderTest(
    WidgetTester tester, {
    String contentKey = 'devotionals.remove_from_favorites_confirmation',
  }) async {
    Future<bool>? dialogResult;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                dialogResult = DeleteConfirmationDialog.show(
                  context: context,
                  titleKey: 'devotionals.remove_from_favorites',
                  contentKey: contentKey,
                );
              },
              child: const Text('Show dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show dialog'));
    await tester.pumpAndSettle();
    return () => dialogResult!;
  }

  testWidgets('shows the shared favorite-removal copy', (tester) async {
    await showDialogUnderTest(tester);

    expect(find.text('Remove from favorites'), findsNWidgets(2));
    expect(
      find.text(
          'Are you sure you want to remove this devotional from your favorites?'),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('uses the Bible Studies message passed by its caller', (
    tester,
  ) async {
    await showDialogUnderTest(
      tester,
      contentKey: 'discovery.remove_from_favorites_confirmation',
    );

    expect(
      find.text(
          'Are you sure you want to remove this Bible study from your favorites?'),
      findsOneWidget,
    );
  });

  testWidgets('returns false when the user cancels', (tester) async {
    final dialogResult = await showDialogUnderTest(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(await dialogResult(), isFalse);
  });

  testWidgets('returns true when the user confirms removal', (tester) async {
    final dialogResult = await showDialogUnderTest(tester);

    await tester.tap(find.text('Remove from favorites').last);
    await tester.pumpAndSettle();

    expect(await dialogResult(), isTrue);
  });
}
