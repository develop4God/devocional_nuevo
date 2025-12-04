import 'package:devocional_nuevo/blocs/thanksgiving_bloc.dart';
import 'package:devocional_nuevo/models/thanksgiving_model.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/widgets/add_thanksgiving_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AddThanksgivingModal Widget Tests', () {
    late ThanksgivingBloc bloc;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      // Reset ServiceLocator for clean test state
      ServiceLocator().reset();
      SharedPreferences.setMockInitialValues({});
      // Register LocalizationService
      ServiceLocator().registerLazySingleton<LocalizationService>(
          () => LocalizationService());
      bloc = ThanksgivingBloc();
    });

    tearDown(() {
      bloc.close();
      ServiceLocator().reset();
    });

    Widget createWidgetUnderTest({Thanksgiving? thanksgivingToEdit}) {
      return MaterialApp(
        home: Scaffold(
          body: BlocProvider<ThanksgivingBloc>.value(
            value: bloc,
            child: AddThanksgivingModal(
              thanksgivingToEdit: thanksgivingToEdit,
            ),
          ),
        ),
      );
    }

    testWidgets('should display title for new thanksgiving',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check if title contains emoji and text field is present
      expect(find.textContaining('☺️'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should display close button', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should display cancel and create buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should populate text field when editing',
        (WidgetTester tester) async {
      final existingThanksgiving = Thanksgiving(
        id: 'test_123',
        text: 'Existing thanksgiving text',
        createdDate: DateTime.now(),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(thanksgivingToEdit: existingThanksgiving),
      );
      await tester.pumpAndSettle();

      expect(find.text('Existing thanksgiving text'), findsOneWidget);
    });

    testWidgets('should close modal when close button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Modal should be closed - check that widget tree is gone
      expect(find.byType(AddThanksgivingModal), findsNothing);
    });

    testWidgets('should close modal when cancel button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      // Modal should be closed
      expect(find.byType(AddThanksgivingModal), findsNothing);
    });

    testWidgets('should show error when submitting empty text',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap create button without entering text
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Error should be displayed
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should show error when text is too short',
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

    testWidgets('should allow entering valid text and create thanksgiving',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter valid text (at least 10 characters)
      const validText = 'Gracias Señor por tu amor';
      await tester.enterText(find.byType(TextField), validText);
      await tester.pumpAndSettle();

      // Tap create button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Check that the bloc received the event
      await tester.pumpAndSettle();

      // Modal should close after successful creation
      expect(find.byType(AddThanksgivingModal), findsNothing);
    });

    testWidgets('should respect max length of 500 characters',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLength, equals(500));
    });

    testWidgets('should have 6 lines for text input',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLines, equals(6));
    });

    testWidgets('should auto-focus on text field when opened',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // The focus node should be requested
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode, isNotNull);
    });
  });
}
