@Tags(['unit', 'widgets'])
library;

// test/unit/widgets/drawer_offline_widget_test.dart
//
// Migrated from integration_test/drawer_offline_integration_test.dart
// Widget tests for DevocionalesDrawer offline/download behavior.
// Uses mocktail + BlocProvider. No Patrol or device required.

import 'package:devocional_nuevo/blocs/theme/theme_bloc.dart';
import 'package:devocional_nuevo/blocs/theme/theme_state.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/widgets/devocionales/devocionales_page_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

class _MockDevocionalProvider extends Mock implements DevocionalProvider {}

void main() {
  late _MockDevocionalProvider mockDevocionalProvider;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    registerTestServices();

    mockDevocionalProvider = _MockDevocionalProvider();

    when(() => mockDevocionalProvider.selectedVersion).thenReturn('RVR1960');
    when(
      () => mockDevocionalProvider.availableVersions,
    ).thenReturn(['RVR1960', 'NVI', 'KJV']);
    when(() => mockDevocionalProvider.isOfflineMode).thenReturn(false);
    when(() => mockDevocionalProvider.downloadStatus).thenReturn(null);
    when(() => mockDevocionalProvider.selectedLanguage).thenReturn('es');
  });

  Widget createWidgetUnderTest() {
    return BlocProvider(
      create: (_) => ThemeBloc(),
      child: Builder(
        builder: (context) {
          final themeState = context.watch<ThemeBloc>().state;
          final theme = themeState is ThemeLoaded
              ? themeState.themeData
              : ThemeData.light();

          return MaterialApp(
            theme: theme,
            home: ChangeNotifierProvider<DevocionalProvider>.value(
              value: mockDevocionalProvider,
              child: Scaffold(
                drawer: const DevocionalesDrawer(),
                appBar: AppBar(),
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    child: const Text('Open Drawer'),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  group('DevocionalesDrawer Offline Integration', () {
    testWidgets(
      'should show "Descargar devocionales" with download icon when no local data',
      (WidgetTester tester) async {
        when(
          () => mockDevocionalProvider.hasTargetYearsLocalData(),
        ).thenAnswer((_) async => false);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.tap(find.text('Open Drawer'));
        await tester.pumpAndSettle();

        expect(find.text('Descargar devocionales'), findsOneWidget);
        expect(find.text('Para uso sin internet'), findsOneWidget);
        expect(
          find.byIcon(Icons.download_for_offline_outlined),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should show "Disfruta contenido sin internet" with offline pin icon when local data exists',
      (WidgetTester tester) async {
        when(
          () => mockDevocionalProvider.hasTargetYearsLocalData(),
        ).thenAnswer((_) async => true);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.tap(find.text('Open Drawer'));
        await tester.pumpAndSettle();

        expect(find.text('Descargar devocionales'), findsOneWidget);
        expect(find.text('Disfruta contenido sin internet'), findsOneWidget);
        expect(find.byIcon(Icons.offline_pin_outlined), findsOneWidget);
      },
    );

    testWidgets('should open download confirmation dialog when tapped', (
      WidgetTester tester,
    ) async {
      when(
        () => mockDevocionalProvider.hasTargetYearsLocalData(),
      ).thenAnswer((_) async => false);
      when(
        () => mockDevocionalProvider.downloadDevocionalesWithProgress(
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      final downloadButton = find.byKey(
        const Key('drawer_download_devotionals'),
      );
      expect(downloadButton, findsOneWidget);

      await tester.tap(downloadButton);
      await tester.pumpAndSettle();

      expect(find.text('⬇️✨ Confirmar descarga'), findsOneWidget);
      expect(
        find.textContaining('Esta descarga se realiza una sola vez'),
        findsOneWidget,
      );
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Aceptar'), findsOneWidget);
    });

    testWidgets('should have proper drawer structure', (
      WidgetTester tester,
    ) async {
      when(
        () => mockDevocionalProvider.hasTargetYearsLocalData(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      expect(find.byType(DevocionalesDrawer), findsOneWidget);
      expect(find.text('Tu Biblia, tu estilo'), findsOneWidget);
      expect(
        find.byKey(const Key('drawer_bible_version_selector')),
        findsOneWidget,
      );
      expect(find.text('Favoritos guardados'), findsOneWidget);
      expect(find.text('Oraciones y agradecimientos'), findsOneWidget);
      expect(find.text('Comparte app Devocionales Cristianos'), findsOneWidget);
      expect(find.text('Descargar devocionales'), findsOneWidget);
      expect(
        find.text('Configuracion de notificaciones'),
        findsOneWidget,
      );
      expect(find.text('Selecciona color de tema'), findsOneWidget);
    });
  });
}
