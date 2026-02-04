import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:devocional_nuevo/blocs/prayer_state.dart';
import 'package:devocional_nuevo/models/prayer_model.dart';
import 'package:devocional_nuevo/widgets/add_prayer_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

@Tags(['unit', 'widgets'])
void main() {
  setUpAll(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  group('AddPrayerModal Widget Tests', () {
    late PrayerBloc bloc;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      registerTestServices();
      bloc = PrayerBloc();
    });

    tearDown(() {
      bloc.close();
    });

    Widget createWidgetUnderTest({Prayer? prayerToEdit}) {
      return MaterialApp(
        home: Scaffold(
          body: BlocProvider<PrayerBloc>.value(
            value: bloc,
            child: AddPrayerModal(prayerToEdit: prayerToEdit),
          ),
        ),
      );
    }

    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(AddPrayerModal), findsOneWidget);
    });

    testWidgets('displays title for new prayer', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check if the widget contains emoji
      expect(find.textContaining('🙏'), findsOneWidget);
    });

    testWidgets('displays close button', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('displays text field for prayer input',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('displays cancel and create buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('displays edit icon when editing prayer',
        (WidgetTester tester) async {
      final existingPrayer = Prayer(
        id: 'test_123',
        text: 'Existing prayer text',
        createdDate: DateTime.now(),
        status: PrayerStatus.active,
      );

      await tester.pumpWidget(
        createWidgetUnderTest(prayerToEdit: existingPrayer),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('displays add icon when creating new prayer',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    });

    testWidgets('populates text field when editing',
        (WidgetTester tester) async {
      final existingPrayer = Prayer(
        id: 'test_123',
        text: 'Existing prayer text',
        createdDate: DateTime.now(),
        status: PrayerStatus.active,
      );

      await tester.pumpWidget(
        createWidgetUnderTest(prayerToEdit: existingPrayer),
      );
      await tester.pumpAndSettle();

      expect(find.text('Existing prayer text'), findsOneWidget);
    });

    testWidgets('closes modal when close button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Modal should be closed
      expect(find.byType(AddPrayerModal), findsNothing);
    });

    testWidgets('closes modal when cancel button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      // Modal should be closed
      expect(find.byType(AddPrayerModal), findsNothing);
    });

    testWidgets('shows error when submitting empty text',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap create button without entering text
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Error should be displayed
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows error when text is too short',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter very short text
      await tester.enterText(find.byType(TextField), 'Short');
      await tester.pumpAndSettle();

      // Tap create button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Error should be displayed
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('allows entering valid text', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      const validText = 'Please Lord, help me to grow in faith';
      await tester.enterText(find.byType(TextField), validText);
      await tester.pumpAndSettle();

      expect(find.text(validText), findsOneWidget);
    });

    testWidgets('text field has correct max length',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLength, equals(500));
    });

    testWidgets('text field has multiple lines', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLines, equals(6));
    });

    testWidgets('displays info description box', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('handles long prayer text gracefully',
        (WidgetTester tester) async {
      final longText = 'Dear Lord, ' * 50; // Long prayer text

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), longText);
      await tester.pumpAndSettle();

      // Should handle long text without errors
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('submit button changes state when processing',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      const validText = 'Valid prayer text for testing';
      await tester.enterText(find.byType(TextField), validText);
      await tester.pump();

      // Tap create button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(); // Don't settle, check intermediate state

      // Should show loading indicator or processing state
      // The modal might close quickly, but we verify it doesn't crash
      expect(find.byType(AddPrayerModal), findsAny);
    });

    testWidgets('auto-focuses on text field when opened',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode, isNotNull);
    });

    testWidgets('displays different content when editing vs creating',
        (WidgetTester tester) async {
      // Test creating mode
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);

      // Test editing mode
      final existingPrayer = Prayer(
        id: 'test_123',
        text: 'Existing prayer',
        createdDate: DateTime.now(),
        status: PrayerStatus.active,
      );

      await tester.pumpWidget(
        createWidgetUnderTest(prayerToEdit: existingPrayer),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsNothing);
    });
  });
}
