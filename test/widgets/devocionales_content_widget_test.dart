import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devocional_nuevo/widgets/devocionales/devocionales_content_widget.dart';
import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:provider/provider.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/services/localization_service.dart';

class FakeDevocionalProvider extends ChangeNotifier implements DevocionalProvider {
  @override
  String get selectedLanguage => 'es';
  @override
  String get selectedVersion => 'RVR1960';
  // Solo los métodos/getters usados en los tests
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLocalizationService extends LocalizationService {
  @override
  String translate(String key, [Map<String, dynamic>? params]) {
    if (params != null && params.isNotEmpty) {
      return key + params.values.join(', ');
    }
    return key;
  }
}

void main() {
  setUpAll(() {
    // Registrar un LocalizationService falso para los tests
    final locator = serviceLocator;
    if (!locator.isRegistered<LocalizationService>()) {
      locator.registerSingleton<LocalizationService>(FakeLocalizationService());
    }
  });

  group('DevocionalesContentWidget', () {
    late Devocional devocional;
    late FakeDevocionalProvider fakeProvider;
    late bool verseCopied;
    late bool streakTapped;

    setUp(() {
      devocional = Devocional(
        id: 'test-id',
        versiculo: 'Juan 3:16',
        reflexion: 'Reflexión de prueba',
        paraMeditar: [
          ParaMeditar(cita: 'Salmo 23:1', texto: 'El Señor es mi pastor'),
        ],
        oracion: 'Oración de prueba',
        date: DateTime(2025, 12, 25),
        version: 'RVR1960',
        language: 'es',
        tags: ['fe', 'amor'],
      );
      fakeProvider = FakeDevocionalProvider();
      verseCopied = false;
      streakTapped = false;
    });

    Widget buildWidget({int streak = 5, String? formattedDate, Future<int>? streakFuture}) {
      return MaterialApp(
        home: ChangeNotifierProvider<DevocionalProvider>.value(
          value: fakeProvider,
          child: DevocionalesContentWidget(
            devocional: devocional,
            fontSize: 16,
            onVerseCopy: () => verseCopied = true,
            onStreakBadgeTap: () => streakTapped = true,
            currentStreak: streak,
            streakFuture: streakFuture ?? Future.value(streak),
            getLocalizedDateFormat: (_) => formattedDate ?? '25 de diciembre de 2025',
          ),
        ),
      );
    }

    testWidgets('renders all main sections', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Juan 3:16'), findsOneWidget);
      expect(find.text('Reflexión de prueba'), findsOneWidget);
      expect(find.textContaining('Salmo 23:1'), findsOneWidget);
      expect(find.text('Oración de prueba'), findsOneWidget);
      expect(find.textContaining('RVR1960'), findsWidgets);
      expect(find.textContaining('fe, amor'), findsOneWidget);
      expect(find.text('25 de diciembre de 2025'), findsOneWidget);
    });

    testWidgets('calls onVerseCopy when verse tapped', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.text('Juan 3:16'));
      expect(verseCopied, isTrue);
    });

    testWidgets('calls onStreakBadgeTap when streak badge tapped', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      final badges = find.byType(InkWell);
      if (badges.evaluate().isNotEmpty) {
        await tester.tap(badges.last);
        expect(streakTapped, isTrue);
      } else {
        expect(false, isTrue, reason: 'No InkWell found for streak badge');
      }
    });

    testWidgets('hides streak badge if streak is zero', (tester) async {
      await tester.pumpWidget(buildWidget(streak: 0));
      await tester.pumpAndSettle();
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('handles empty meditations and tags gracefully', (tester) async {
      devocional = Devocional(
        id: 'test-id-2',
        versiculo: 'Juan 3:16',
        reflexion: 'Reflexión',
        paraMeditar: [],
        oracion: 'Oración',
        date: DateTime(2025, 12, 25),
        version: null,
        language: null,
        tags: [],
      );
      await tester.pumpWidget(buildWidget());
      expect(find.textContaining('devotionals.topics'), findsNothing);
      expect(find.textContaining('devotionals.version'), findsNothing);
    });
  });
}
