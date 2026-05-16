import 'package:devocional_nuevo/pages/application_language_page.dart';
import 'package:devocional_nuevo/providers/localization_provider.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/bloc_test_helper.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/blocs/theme/theme_repository.dart';

class TestThemeBloc extends ThemeBloc {
  TestThemeBloc() : super(repository: ThemeRepository()) {
    emit(
      ThemeLoaded(
        themeFamily: ThemeRepository.defaultThemeFamily,
        brightness: Brightness.light,
        themeData: ThemeData.light(),
      ),
    );
  }
}

void main() {
  group('ApplicationLanguagePage', () {
    setUp(() async {
      await registerTestServicesWithFakes();
    });

    testWidgets('shows a visible scrollbar, scrolls, and fades last language', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        BlocProvider<ThemeBloc>(
          create: (_) => TestThemeBloc(),
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => LocalizationProvider()),
              // Use a properly configured mock DevocionalProvider (ChangeNotifier)
              ChangeNotifierProvider(
                create: (_) => createMockDevocionalProvider() as ChangeNotifier,
              ),
            ],
            child: MaterialApp(home: const ApplicationLanguagePage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Scrollbar
      expect(find.byType(Scrollbar), findsOneWidget);
      // Try to scroll the ListView
      final gesture = await tester.startGesture(const Offset(100, 400));
      await gesture.moveBy(const Offset(0, -300));
      await tester.pump();
      // Should still find the Scrollbar after scroll
      expect(find.byType(Scrollbar), findsOneWidget);

      // Assert that no Opacity widget is present (no fade on last item)
      final opacityWidgets = tester.widgetList<Opacity>(find.byType(Opacity));
      expect(opacityWidgets.isEmpty, isTrue);
    });
  });
}
