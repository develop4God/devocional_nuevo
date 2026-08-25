@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/widgets/devocionales/salvation_prayer_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/bloc_test_helper.mocks.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late MockDevocionalProvider devocionalProvider;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await registerTestServices();

    devocionalProvider = MockDevocionalProvider();
    when(
      devocionalProvider.setInvitationDialogVisibility(any),
    ).thenAnswer((_) async {});
  });

  Future<void> pumpHost(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<DevocionalProvider>.value(
          value: devocionalProvider,
          child: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SalvationPrayerDialog.show(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('SalvationPrayerDialog', () {
    testWidgets('does not show when user has opted out', (tester) async {
      when(devocionalProvider.showInvitationDialog).thenReturn(false);

      await pumpHost(tester);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('salvation_prayer_dialog')), findsNothing);
    });

    testWidgets('shows dialog when user has not opted out', (tester) async {
      when(devocionalProvider.showInvitationDialog).thenReturn(true);

      await pumpHost(tester);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('salvation_prayer_dialog')), findsOneWidget);
    });

    testWidgets('barrier is not dismissible by tapping outside', (
      tester,
    ) async {
      when(devocionalProvider.showInvitationDialog).thenReturn(true);

      await pumpHost(tester);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('salvation_prayer_dialog')), findsOneWidget);
    });

    testWidgets(
      'continue button with checkbox unchecked keeps dialog visible next time',
      (tester) async {
        when(devocionalProvider.showInvitationDialog).thenReturn(true);

        await pumpHost(tester);
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('salvation_prayer_continue_button')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('salvation_prayer_dialog')),
          findsNothing,
        );
        verify(
          devocionalProvider.setInvitationDialogVisibility(true),
        ).called(1);
      },
    );

    testWidgets(
      'checking "do not show again" and continuing disables future dialogs',
      (tester) async {
        when(devocionalProvider.showInvitationDialog).thenReturn(true);

        await pumpHost(tester);
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('salvation_prayer_continue_button')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('salvation_prayer_dialog')),
          findsNothing,
        );
        verify(
          devocionalProvider.setInvitationDialogVisibility(false),
        ).called(1);
      },
    );

    testWidgets('renders the salvation prayer text content', (tester) async {
      when(devocionalProvider.showInvitationDialog).thenReturn(true);

      await pumpHost(tester);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.text('devotionals.salvation_prayer_title'),
        findsOneWidget,
      );
      expect(find.text('devotionals.salvation_prayer_intro'), findsOneWidget);
      expect(find.text('devotionals.salvation_prayer'), findsOneWidget);
      expect(find.text('devotionals.salvation_promise'), findsOneWidget);
      expect(find.text('prayer.already_prayed'), findsOneWidget);
      expect(find.text('devotionals.continue'), findsOneWidget);
    });
  });
}
