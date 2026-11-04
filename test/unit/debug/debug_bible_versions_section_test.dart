@Tags(['unit', 'debug'])
library;

import 'package:devocional_nuevo/debug/debug_flags.dart';
import 'package:devocional_nuevo/debug/sections/debug_bible_versions_section.dart';
import 'package:devocional_nuevo/repositories/i_bible_index_debug_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockControls extends Mock implements IBibleIndexDebugControls {}

void main() {
  late MockControls controls;

  setUp(() {
    controls = MockControls();
    DebugFlags.debugBibleVersionsBranch = 'main';
    when(() => controls.refreshIndex()).thenAnswer(
      (_) async => const BibleIndexRefreshResult(
        versionsByLanguage: {},
        servedFromCache: false,
      ),
    );
  });

  Future<void> pumpSection(WidgetTester tester,
      {List<String> branches = const ['main', 'dev'],
      bool loading = false,
      String? warning}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DebugBibleVersionsSection(
              controls: controls,
              branches: branches,
              loadingBranches: loading,
              branchWarning: warning,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('selecting a branch updates the debug flag', (tester) async {
    await pumpSection(tester);

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('dev').last);
    await tester.pumpAndSettle();

    expect(DebugFlags.debugBibleVersionsBranch, 'dev');
  });

  testWidgets('refresh clears the cache before re-fetching the index',
      (tester) async {
    await pumpSection(tester);

    await tester.tap(find.text('Refresh Index'));
    await tester.pumpAndSettle();

    verify(() => controls.refreshIndex()).called(1);
    expect(find.textContaining('refreshed from: main'), findsOneWidget);
  });

  testWidgets('refresh lists the versions in the index per language',
      (tester) async {
    when(() => controls.refreshIndex()).thenAnswer(
      (_) async => const BibleIndexRefreshResult(
        versionsByLanguage: {
          'es': ['LBLA', 'NTBT'],
          'en': [],
        },
        servedFromCache: false,
      ),
    );
    await pumpSection(tester);

    await tester.tap(find.text('Refresh Index'));
    await tester.pumpAndSettle();

    expect(find.text('es: LBLA, NTBT'), findsOneWidget);
    expect(find.text('en: (none)'), findsOneWidget);
  });

  testWidgets('refresh failure shows an error and re-enables the button',
      (tester) async {
    when(() => controls.refreshIndex()).thenThrow(Exception('offline'));
    await pumpSection(tester);

    await tester.tap(find.text('Refresh Index'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Error refreshing'), findsOneWidget);
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('keeps showing the active branch even if the list dropped it',
      (tester) async {
    DebugFlags.debugBibleVersionsBranch = 'gone';
    await pumpSection(tester, branches: const ['main', 'dev']);

    expect(find.text('gone'), findsOneWidget);
    expect(DebugFlags.debugBibleVersionsBranch, 'gone');
  });

  testWidgets('shows a spinner instead of the dropdown while loading',
      (tester) async {
    await pumpSection(tester, loading: true);

    expect(find.byType(DropdownButton<String>), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('refresh served from cache is reported as a warning, not success',
      (tester) async {
    when(() => controls.refreshIndex()).thenAnswer(
      (_) async => const BibleIndexRefreshResult(
        versionsByLanguage: {},
        servedFromCache: true,
      ),
    );
    await pumpSection(tester);

    await tester.tap(find.text('Refresh Index'));
    await tester.pumpAndSettle();

    expect(find.textContaining('CACHED index'), findsOneWidget);
    expect(find.textContaining('refreshed from'), findsNothing);
  });

  testWidgets('shows the branch listing warning', (tester) async {
    await pumpSection(tester, warning: 'GitHub rate limit hit');

    expect(find.textContaining('GitHub rate limit hit'), findsOneWidget);
  });
}
