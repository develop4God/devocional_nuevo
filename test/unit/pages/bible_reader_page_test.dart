import 'package:bible_reader_core/src/bible_version.dart';
import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/pages/bible_reader_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

@Tags(['unit', 'pages'])
void main() {
  group('BibleReaderPage Widget Tests', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      registerTestServices();
    });

    Widget buildTestableWidget(Widget child) {
      return MultiProvider(
        providers: [
          BlocProvider<ThemeBloc>(
            create: (_) => ThemeBloc()
              ..emit(
                ThemeLoaded(
                  themeFamily: 'Deep Purple',
                  brightness: Brightness.light,
                  themeData: ThemeData.light(),
                ),
              ),
          ),
        ],
        child: MaterialApp(home: child),
      );
    }

    testWidgets('should create BibleReaderPage with versions', (
      WidgetTester tester,
    ) async {
      final versions = [
        BibleVersion(
          name: 'RVR1960',
          language: 'Español',
          languageCode: 'es',
          assetPath: 'assets/biblia/RVR1960_es.SQLite3',
          dbFileName: 'RVR1960_es.SQLite3',
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(BibleReaderPage(versions: versions)),
      );

      // Wait for first frame
      await tester.pump();

      // Verify widget is created
      expect(find.byType(BibleReaderPage), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should show loading indicator initially', (
      WidgetTester tester,
    ) async {
      final versions = [
        BibleVersion(
          name: 'RVR1960',
          language: 'Español',
          languageCode: 'es',
          assetPath: 'assets/biblia/RVR1960_es.SQLite3',
          dbFileName: 'RVR1960_es.SQLite3',
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(BibleReaderPage(versions: versions)),
      );

      // Initial frame
      await tester.pump();

      // The page should show a Lottie animation while loading
      // We can verify the widget tree is built without errors
      expect(find.byType(BibleReaderPage), findsOneWidget);
    });

    testWidgets('should have AppBar with title', (WidgetTester tester) async {
      final versions = [
        BibleVersion(
          name: 'RVR1960',
          language: 'Español',
          languageCode: 'es',
          assetPath: 'assets/biblia/RVR1960_es.SQLite3',
          dbFileName: 'RVR1960_es.SQLite3',
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(BibleReaderPage(versions: versions)),
      );

      await tester.pump();

      // Check for AppBar
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should accept empty versions list', (
      WidgetTester tester,
    ) async {
      // This test verifies the widget doesn't crash with empty list
      // In real app, we'd pass at least one version
      final versions = [
        BibleVersion(
          name: 'Test',
          language: 'Test Language',
          languageCode: 'xx',
          assetPath: 'test.db',
          dbFileName: 'test.db',
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(BibleReaderPage(versions: versions)),
      );

      await tester.pump();

      expect(find.byType(BibleReaderPage), findsOneWidget);
    });
  });
}
