import 'package:devocional_nuevo/blocs/testimony_bloc.dart';
import 'package:devocional_nuevo/models/testimony_model.dart';
import 'package:devocional_nuevo/widgets/add_testimony_modal.dart';
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

  group('AddTestimonyModal Widget Tests', () {
    late TestimonyBloc bloc;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      registerTestServices();
      bloc = TestimonyBloc();
    });

    tearDown(() {
      bloc.close();
    });

    Widget createWidgetUnderTest({Testimony? testimonyToEdit}) {
      return MaterialApp(
        home: Scaffold(
          body: BlocProvider<TestimonyBloc>.value(
            value: bloc,
            child: AddTestimonyModal(testimonyToEdit: testimonyToEdit),
          ),
        ),
      );
    }

    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(AddTestimonyModal), findsOneWidget);
    });

    testWidgets('displays title for new testimony',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check if the widget contains sparkle emoji
      expect(find.textContaining('✨'), findsOneWidget);
    });

    testWidgets('displays close button', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('displays text field for testimony input',
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

    testWidgets('displays edit icon when editing testimony',
        (WidgetTester tester) async {
      final existingTestimony = Testimony(
        id: 'test_123',
        text: 'Existing testimony text',
        createdDate: DateTime.now(),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(testimonyToEdit: existingTestimony),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('displays add icon when creating new testimony',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    });

    testWidgets('populates text field when editing',
        (WidgetTester tester) async {
      final existingTestimony = Testimony(
        id: 'test_123',
        text: 'God has blessed me greatly',
        createdDate: DateTime.now(),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(testimonyToEdit: existingTestimony),
      );
      await tester.pumpAndSettle();

      expect(find.text('God has blessed me greatly'), findsOneWidget);
    });

    testWidgets('closes modal when close button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Modal should be closed
      expect(find.byType(AddTestimonyModal), findsNothing);
    });

    testWidgets('closes modal when cancel button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      // Modal should be closed
      expect(find.byType(AddTestimonyModal), findsNothing);
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

      const validText = 'God answered my prayer for healing and restoration';
      await tester.enterText(find.byType(TextField), validText);
      await tester.pumpAndSettle();

      expect(find.text(validText), findsOneWidget);
    });

    testWidgets('text field has correct max length',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLength, equals(850));
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

    testWidgets('handles long testimony text gracefully',
        (WidgetTester tester) async {
      final longText = 'I praise God for His goodness. ' * 30;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), longText);
      await tester.pumpAndSettle();

      // Should handle long text without errors
      expect(find.byType(TextField), findsOneWidget);
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
      final existingTestimony = Testimony(
        id: 'test_123',
        text: 'Existing testimony',
        createdDate: DateTime.now(),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(testimonyToEdit: existingTestimony),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsNothing);
    });

    testWidgets('submit button changes state when processing',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      const validText = 'Valid testimony text for testing purposes';
      await tester.enterText(find.byType(TextField), validText);
      await tester.pump();

      // Tap create button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(); // Don't settle, check intermediate state

      // Should handle the action without crashing
      expect(find.byType(AddTestimonyModal), findsAny);
    });

    testWidgets('respects character limit counter',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter text and verify counter is present
      await tester.enterText(find.byType(TextField), 'Some testimony text');
      await tester.pumpAndSettle();

      // The TextField should show character counter (maxLength is set)
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLength, isNotNull);
    });
  });
}
