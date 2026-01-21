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

import '../test/helpers/test_helpers.dart';

// Mock para DevocionalProvider
class MockDevocionalProvider extends Mock implements DevocionalProvider {}

void main() {
  late MockDevocionalProvider mockDevocionalProvider;

  setUp(() {
    // Initialize Flutter binding for tests
    TestWidgetsFlutterBinding.ensureInitialized();
    // Initialize SharedPreferences mock for each test
    SharedPreferences.setMockInitialValues({});

    // Register all services including LocalizationService
    registerTestServices();

    mockDevocionalProvider = MockDevocionalProvider();

    // Stubs para los getters requeridos
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
          // Get theme from BLoC
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
        // Mock sin datos locales
        when(
          () => mockDevocionalProvider.hasTargetYearsLocalData(),
        ).thenAnswer((_) async => false);

        await tester.pumpWidget(createWidgetUnderTest());

        // Abre el drawer
        await tester.tap(find.text('Open Drawer'));
        await tester.pumpAndSettle();

        // Verify the main text "Descargar devocionales"
        expect(find.text('Descargar devocionales'), findsOneWidget);

        // Verify subtitle text for offline use
        expect(find.text('Para uso sin internet'), findsOneWidget);

        // Verify download icon is present
        expect(
          find.byIcon(Icons.download_for_offline_outlined),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should show "Disfruta contenido sin internet" with offline pin icon when local data exists',
      (WidgetTester tester) async {
        // Mock con datos locales
        when(
          () => mockDevocionalProvider.hasTargetYearsLocalData(),
        ).thenAnswer((_) async => true);

        await tester.pumpWidget(createWidgetUnderTest());

        // Abre el drawer
        await tester.tap(find.text('Open Drawer'));
        await tester.pumpAndSettle();

        // Verify the main text "Descargar devocionales"
        expect(find.text('Descargar devocionales'), findsOneWidget);

        // Verify subtitle text indicating content is ready
        expect(find.text('Disfruta contenido sin internet'), findsOneWidget);

        // Verify offline pin icon is present
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

      // Abre el drawer
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      // Find and tap the download devotionals option
      final downloadButton = find.byKey(
        const Key('drawer_download_devotionals'),
      );
      expect(downloadButton, findsOneWidget);

      await tester.tap(downloadButton);
      await tester.pumpAndSettle();

      // Verify dialog opened with expected content
      // Look for the dialog title
      expect(find.text('⬇️✨ Confirmar descarga'), findsOneWidget);

      // Look for the dialog content
      expect(
        find.textContaining('Esta descarga se realiza una sola vez'),
        findsOneWidget,
      );

      // Verify action buttons are present
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

      // Abre el drawer
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      // Verify drawer is present
      expect(find.byType(DevocionalesDrawer), findsOneWidget);

      // Check for key drawer elements
      expect(find.text('Tu Biblia, tu estilo'), findsOneWidget); // Drawer title

      // Bible version selector
      expect(
        find.byKey(const Key('drawer_bible_version_selector')),
        findsOneWidget,
      );

      // Check for main menu items
      expect(find.text('Favoritos guardados'), findsOneWidget);
      expect(find.text('Oraciones y agradecimientos'), findsOneWidget);
      expect(find.text('Comparte app Devocionales Cristianos'), findsOneWidget);
      expect(find.text('Descargar devocionales'), findsOneWidget);
      expect(find.text('Configuración de notificaciones'), findsOneWidget);

      // Theme selector text should be present
      expect(find.text('Selecciona color de tema'), findsOneWidget);
    });
  });
}
