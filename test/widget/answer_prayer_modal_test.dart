import 'package:devocional_nuevo/models/prayer_model.dart';
import 'package:devocional_nuevo/widgets/answer_prayer_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    registerTestServices();
  });

  testWidgets('AnswerPrayerModal allows up to 400 characters',
      (WidgetTester tester) async {
    final prayer = Prayer(
      id: 'test-prayer',
      text: 'Sample',
      createdDate: DateTime.now(),
      status: PrayerStatus.active,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<PrayerBloc>(
            create: (_) => PrayerBloc(),
            child: AnswerPrayerModal(prayer: prayer),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final finder = find.byType(TextField);
    expect(finder, findsOneWidget);

    final long400 = List.filled(400, 'a').join();
    await tester.enterText(finder, long400);
    await tester.pump();

    // Valida que el contador muestre 400/400
    expect(find.text('400/400'), findsOneWidget);

    // Valida que el texto tenga 400 caracteres
    final TextField tf1 = tester.widget(finder);
    expect(tf1.controller!.text.length, equals(400));

    // Intentar meter más de 400 caracteres
    final long450 = List.filled(450, 'b').join();
    await tester.enterText(finder, long450);
    await tester.pump();

    // El controller debe contener como máximo 400
    final TextField tf2 = tester.widget(finder);
    expect(tf2.controller!.text.length, equals(400));
    expect(find.text('400/400'), findsOneWidget);
  });
}
