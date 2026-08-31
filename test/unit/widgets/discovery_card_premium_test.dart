@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/models/devocional_model.dart';
import 'package:devocional_nuevo/widgets/discovery_card_premium.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

Devocional _makeDevocional() => Devocional(
      id: 'test_1',
      versiculo: 'John 3:16',
      reflexion: 'Test reflection',
      paraMeditar: [],
      oracion: 'Test prayer',
      date: DateTime.now(),
    );

Widget _wrap(Widget child, {required Size size, double textScale = 1.0}) =>
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await registerTestServices();
  });

  Widget createWidgetUnderTest({required String title, String? subtitle}) {
    return DevotionalCardPremium(
      devocional: _makeDevocional(),
      title: title,
      subtitle: subtitle,
      isFavorite: false,
      onTap: () {},
      onFavoriteToggle: () {},
      isDark: false,
    );
  }

  testWidgets('renders without overflow with a short title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        createWidgetUnderTest(title: 'Faith'),
        size: const Size(360, 640),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DevotionalCardPremium), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'does not overflow the fixed-height card when the hero content '
    '(long title + subtitle) needs more vertical space than the '
    'flexible hero section has',
    (WidgetTester tester) async {
      // Reproduces the reported bug: the card has a fixed height (380) and
      // the hero Column (emoji + title + optional subtitle) must fit inside
      // its Flexible slot without overflowing, even with a long title and a
      // subtitle present at the same time.
      await tester.pumpWidget(
        _wrap(
          createWidgetUnderTest(
            title:
                'A very long devotional study title that spans several lines '
                'of text and pushes the hero section to its limit',
            subtitle: 'An equally long subtitle describing the study in more '
                'detail than usual',
          ),
          size: const Size(320, 640),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DevotionalCardPremium), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'does not overflow the fixed-height card with a long title + subtitle '
    'at an increased system text scale',
    (WidgetTester tester) async {
      // Reproduces the reported bug: at a larger text scale factor (common
      // on real devices with accessibility text size increased) the hero
      // Column (emoji + title + subtitle) overflowed its Flexible slot by a
      // few pixels even though the synthetic default-scale test above did
      // not catch it.
      await tester.pumpWidget(
        _wrap(
          createWidgetUnderTest(
            title:
                'A very long devotional study title that spans several lines '
                'of text and pushes the hero section to its limit',
            subtitle: 'An equally long subtitle describing the study in more '
                'detail than usual',
          ),
          size: const Size(320, 568),
          textScale: 1.3,
        ),
      );
      await tester.pump();

      expect(find.byType(DevotionalCardPremium), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
