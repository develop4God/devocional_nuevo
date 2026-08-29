@Tags(['unit', 'widgets'])
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:devocional_nuevo/widgets/devocionales/devocional_hero_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('DevocionalHeroSection', () {
    late bool favoriteToggled;
    late bool shared;
    late bool streakTapped;
    late bool fontSizeToggled;

    setUp(() {
      registerTestServicesWithFakes();
      favoriteToggled = false;
      shared = false;
      streakTapped = false;
      fontSizeToggled = false;
    });

    Widget buildWidget({bool isFavorite = false}) {
      return MaterialApp(
        home: Scaffold(
          drawer: const Drawer(child: Text('drawer content')),
          body: DevocionalHeroSection(
            imageUrl: 'https://example.com/hero.webp',
            titleText: 'My Intimate Space',
            date: '25 de diciembre de 2025',
            currentStreak: 5,
            streakFuture: Future.value(5),
            isFavorite: isFavorite,
            onFavoriteToggle: () => favoriteToggled = true,
            onShare: () => shared = true,
            onStreakTap: () => streakTapped = true,
            onFontSizeToggle: () => fontSizeToggled = true,
          ),
        ),
      );
    }

    testWidgets('renders the hero image, title and header row', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(CachedNetworkImage), findsOneWidget);
      expect(find.text('My Intimate Space'), findsOneWidget);
      expect(find.text('25 de diciembre de 2025'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    });

    testWidgets('tapping the menu icon opens the scaffold drawer', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('drawer content'), findsOneWidget);
    });

    testWidgets('tapping the font-size icon calls onFontSizeToggle', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.text_increase_outlined));
      expect(fontSizeToggled, isTrue);
    });

    testWidgets('tapping favorite and share icons fires their callbacks', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      expect(favoriteToggled, isTrue);

      await tester.tap(find.byIcon(Icons.share_rounded));
      expect(shared, isTrue);
    });

    testWidgets('tapping the streak badge fires onStreakTap', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      final streakBadge = find.ancestor(
        of: find.textContaining('5'),
        matching: find.byType(InkWell),
      );
      await tester.tap(streakBadge.first);
      expect(streakTapped, isTrue);
    });
  });
}
