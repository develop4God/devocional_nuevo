@Tags(['unit', 'widgets'])
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:devocional_nuevo/widgets/encounter/encounter_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('EncounterImageWidget', () {
    Widget buildWidget({Color? fallbackColor}) {
      return MaterialApp(
        home: Scaffold(
          body: EncounterImageWidget(
            baseFilename: 'peter_intro',
            encounterId: 'peter',
            imageVersion: 'v1',
            fallbackColor: fallbackColor,
          ),
        ),
      );
    }

    testWidgets('shows a fallback container before the pref flag resolves', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(buildWidget(fallbackColor: Colors.red));

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.color, Colors.red);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('loads the AVIF url when no fallback flag is persisted', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.imageUrl, contains('.avif'));
      expect(image.cacheKey, endsWith('_avif'));
    });

    testWidgets('loads the PNG url when a fallback flag is already persisted', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'img_fallback_peter_v1': true,
      });

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.imageUrl, contains('.png'));
      expect(image.cacheKey, endsWith('_png'));
    });

    testWidgets('errorWidget falls back to a transparent container by default',
        (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      final fallback = image.errorWidget!(
          tester.element(find.byType(CachedNetworkImage)),
          image.imageUrl,
          Exception('codec failure')) as Container;
      expect(fallback.color, Colors.transparent);
    });
  });
}
