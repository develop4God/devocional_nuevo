@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/widgets/discovery_actions_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiscoveryActionsBar Widget Tests', () {
    Widget createWidgetUnderTest({
      bool isDownloaded = false,
      bool isDownloading = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: DiscoveryActionsBar(
            isDownloaded: isDownloaded,
            isDownloading: isDownloading,
            downloadLabel: 'Download',
            shareLabel: 'Share',
            favoritesLabel: 'Favorites',
            readLabel: 'Read',
            nextLabel: 'Next',
            onDownload: () {},
            onShare: () {},
            onOpenFavorites: () {},
            onRead: () {},
            onNext: () {},
          ),
        ),
      );
    }

    testWidgets('renders all five action buttons with correct icons',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Download icons (one of the possible states)
      expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);

      // Share
      expect(find.byIcon(Icons.share_rounded), findsOneWidget);

      // Favorites
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);

      // Read
      expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);

      // Next
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    });

    testWidgets('disables download tap while isDownloading is true',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoveryActionsBar(
              isDownloaded: false,
              isDownloading: true,
              downloadLabel: 'Download',
              shareLabel: 'Share',
              favoritesLabel: 'Favorites',
              readLabel: 'Read',
              nextLabel: 'Next',
              onDownload: () {
                tapped = true;
              },
              onShare: () {},
              onOpenFavorites: () {},
              onRead: () {},
              onNext: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.sync_rounded));
      await tester.pumpAndSettle();

      expect(tapped, isFalse);
    });

    testWidgets('shows completed download icon when isDownloaded is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(isDownloaded: true));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.file_download_done_rounded), findsOneWidget);
      expect(find.byIcon(Icons.file_download_outlined), findsNothing);
    });
  });
}
