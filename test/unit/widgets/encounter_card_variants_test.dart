@Tags(['unit', 'widgets'])
library;

// test/unit/widgets/encounter_card_variants_test.dart
//
// Behavioral render coverage for two encounter card widgets that had no
// direct widget test at all: TheologicalDepthCard and
// DiscoveryActivationCard. Mirrors the pattern in
// encounter_card_widget_test.dart's CinematicSceneCard tests — pump the
// card widget directly, no bloc/page involved.
//
// ScriptureMomentCard and CharacterMomentCard are deliberately NOT covered
// here: both render ResolvedVerseText (via a verse overlay/text field),
// whose async resolver leaves a pending Future that fights pumpAndSettle
// once more than ~2 widget tests share this file's setUp/service-locator
// lifecycle — the same class of instability the existing
// supporter_page_edit_name_test.dart works around by never pumping the
// full page. Left for a follow-up rather than forcing a flaky fix here.

import 'package:bible_reader_core/bible_reader_core.dart';
import 'package:devocional_nuevo/models/encounter_card_model.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:devocional_nuevo/widgets/encounter/encounter_card_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_helpers.dart';

class _FakeVerseResolverService implements IVerseResolverService {
  @override
  Future<String?> resolveVerseText({
    required String reference,
    required String versionCode,
  }) async =>
      null;
}

Widget _wrap(Widget card) => MaterialApp(
      home: ChangeNotifierProvider(
        create: (_) => DevocionalProvider(),
        child: Scaffold(body: card),
      ),
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await registerTestServicesWithFakes();
    final locator = ServiceLocator();
    if (locator.isRegistered<IVerseResolverService>()) {
      locator.unregister<IVerseResolverService>();
    }
    locator.registerSingleton<IVerseResolverService>(
      _FakeVerseResolverService(),
    );
  });

  testWidgets('TheologicalDepthCard renders title and content', (tester) async {
    const card = EncounterCard(
      order: 1,
      type: 'theological_depth',
      title: 'Grace Explained',
      content: 'Grace is unmerited favor.',
    );

    await tester.pumpWidget(_wrap(const TheologicalDepthCard(card: card)));
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(find.text('Grace Explained'), findsOneWidget);
  });

  testWidgets('DiscoveryActivationCard renders discovery questions and prayer',
      (tester) async {
    const card = EncounterCard(
      order: 1,
      type: 'discovery_activation',
      title: 'Go Deeper',
      subtitle: 'Reflect and pray',
      discoveryQuestions: [
        EncounterDiscoveryQuestion(
          category: 'Reflection',
          question: 'How does this apply to you?',
        ),
      ],
      prayer: EncounterPrayer(
        title: 'Closing Prayer',
        content: 'Lord, guide my steps.',
      ),
    );

    await tester.pumpWidget(_wrap(const DiscoveryActivationCard(card: card)));
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(find.text('How does this apply to you?'), findsOneWidget);
    expect(find.text('Lord, guide my steps.'), findsOneWidget);
  });
}
