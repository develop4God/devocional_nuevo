@Tags(['unit', 'widgets'])
library;

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devocional_nuevo/widgets/key_verse_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await setupServiceLocator();

    final locator = ServiceLocator();

    locator.registerSingleton<LocalizationService>(
      _TestLocalizationService(),
    );

    if (locator.isRegistered<IVerseResolverService>()) {
      locator.unregister<IVerseResolverService>();
    }
    locator.registerSingleton<IVerseResolverService>(
      _FakeVerseResolverService(),
    );
  });
  group('KeyVerseCard Widget Tests', () {
    testWidgets('should display key verse reference and text', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        final keyVerse = VerseRef(
          reference: 'Hechos 1:9',
          text:
              'Y habiendo dicho estas cosas, viéndolo ellos, fue alzado, y le recibió una nube que le ocultó de sus ojos.',
        );

        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => DevocionalProvider(),
            child: MaterialApp(
              home: Scaffold(body: KeyVerseCard(keyVerse: keyVerse)),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('VERSÍCULO CLAVE'), findsOneWidget);
        expect(find.text('HECHOS 1:9'), findsOneWidget);
        expect(find.textContaining('fue alzado'), findsOneWidget);
        expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);
      });
    });

    testWidgets('should display formatted verse text with quotes', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        final keyVerse = VerseRef(
          reference: 'Juan 3:16',
          text: 'Porque de tal manera amó Dios al mundo...',
        );

        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => DevocionalProvider(),
            child: MaterialApp(
              home: Scaffold(body: KeyVerseCard(keyVerse: keyVerse)),
            ),
          ),
        );
        await tester.pump();

        expect(find.textContaining('"'), findsWidgets);
        expect(find.textContaining('Porque de tal manera'), findsOneWidget);
      });
    });

    testWidgets('should have proper styling and layout', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        final keyVerse = VerseRef(
          reference: '2 Pedro 1:19',
          text: 'Tenemos también la palabra profética más segura',
        );

        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => DevocionalProvider(),
            child: MaterialApp(
              home: Scaffold(body: KeyVerseCard(keyVerse: keyVerse)),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(Container), findsWidgets);
        expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);
        expect(find.text('2 PEDRO 1:19'), findsOneWidget);
      });
    });

    testWidgets('should render in dark mode', (WidgetTester tester) async {
      await tester.runAsync(() async {
        final keyVerse = VerseRef(
          reference: 'Mateo 5:16',
          text: 'Así alumbre vuestra luz delante de los hombres',
        );

        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => DevocionalProvider(),
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: Scaffold(body: KeyVerseCard(keyVerse: keyVerse)),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('VERSÍCULO CLAVE'), findsOneWidget);
        expect(find.text('MATEO 5:16'), findsOneWidget);
      });
    });

    testWidgets('should handle long verse text', (WidgetTester tester) async {
      await tester.runAsync(() async {
        final keyVerse = VerseRef(
          reference: 'Juan 1:1-3',
          text:
              'En el principio era el Verbo, y el Verbo era con Dios, y el Verbo era Dios. Este era en el principio con Dios. Todas las cosas por él fueron hechas, y sin él nada de lo que ha sido hecho, fue hecho.',
        );

        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => DevocionalProvider(),
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: KeyVerseCard(keyVerse: keyVerse),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('JUAN 1:1-3'), findsOneWidget);
        expect(find.textContaining('En el principio'), findsOneWidget);
      });
    });
  });
}

class _FakeVerseResolverService implements IVerseResolverService {
  @override
  Future<String?> resolveVerseText({
    required String reference,
    required String versionCode,
  }) async =>
      null;
}

class _TestLocalizationService extends LocalizationService {
  @override
  String translate(String key, [Map<String, dynamic>? params]) {
    const map = {'discovery.key_verse': 'VERSÍCULO CLAVE'};
    return map[key] ?? key;
  }
}
