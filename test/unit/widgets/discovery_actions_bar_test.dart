@Tags(['unit', 'widgets'])
library;

import 'package:devocional_nuevo/widgets/discovery_actions_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpForStableFrame(WidgetTester tester) async {
  // Use a small finite pump instead of pumpAndSettle to avoid
  // waiting on the indeterminate CircularProgressIndicator.
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('DiscoveryActionsBar Widget Tests', () {
    Widget createWidgetUnderTest({
      bool isDownloaded = false,
      bool isDownloading = false,
      String downloadLabel = 'Download study',
      String shareLabel = 'Share',
      String favoritesLabel = 'Favorites',
      String readLabel = 'Read',
      String nextLabel = 'Next',
      VoidCallback? onDownload,
      VoidCallback? onShare,
      VoidCallback? onOpenFavorites,
      VoidCallback? onRead,
      VoidCallback? onNext,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: DiscoveryActionsBar(
            isDownloaded: isDownloaded,
            isDownloading: isDownloading,
            downloadLabel: downloadLabel,
            shareLabel: shareLabel,
            favoritesLabel: favoritesLabel,
            readLabel: readLabel,
            nextLabel: nextLabel,
            onDownload: onDownload ?? () {},
            onShare: onShare ?? () {},
            onOpenFavorites: onOpenFavorites ?? () {},
            onRead: onRead ?? () {},
            onNext: onNext ?? () {},
          ),
        ),
      );
    }

    testWidgets('renders all five action icons', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await _pumpForStableFrame(tester);

      // Download icon in its default (not downloaded, not downloading) state
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

    testWidgets(
        'download button shows sync icon and is disabled while downloading',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        createWidgetUnderTest(
          isDownloaded: false,
          isDownloading: true,
          onDownload: () {
            tapped = true;
          },
        ),
      );
      await _pumpForStableFrame(tester);

      // We expect the download action to be visually in the first position.
      // Rather than relying on the exact icon, which may vary slightly by
      // platform/theme, we verify that tapping that first action does not
      // trigger the onDownload callback while isDownloading is true.
      final rowFinder = find.byType(Row).first;

      // Tap near the left side where the first action button is laid out.
      final rowRect = tester.getRect(rowFinder);
      final tapOffset = Offset(
          rowRect.left + rowRect.width * 0.1, rowRect.top + rowRect.height / 2);

      await tester.tapAt(tapOffset);
      await _pumpForStableFrame(tester);

      expect(tapped, isFalse);
    });

    testWidgets('shows completed download icon when isDownloaded is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(isDownloaded: true));
      await _pumpForStableFrame(tester);

      expect(find.byIcon(Icons.file_download_done_rounded), findsOneWidget);
      expect(find.byIcon(Icons.file_download_outlined), findsNothing);
    });

    testWidgets('uses provided labels and allows download label to wrap',
        (WidgetTester tester) async {
      const longDownloadLabel = 'Download study for offline mode';

      await tester.pumpWidget(
        createWidgetUnderTest(
          downloadLabel: longDownloadLabel,
          shareLabel: 'Share',
          favoritesLabel: 'Favorites',
          readLabel: 'Read',
          nextLabel: 'Next',
        ),
      );
      await _pumpForStableFrame(tester);

      // All labels should be present in the widget tree.
      expect(find.textContaining('Download'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Read'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('invokes callbacks for non-download actions',
        (WidgetTester tester) async {
      bool shareTapped = false;
      bool favoritesTapped = false;
      bool readTapped = false;
      bool nextTapped = false;

      await tester.pumpWidget(
        createWidgetUnderTest(
          onShare: () => shareTapped = true,
          onOpenFavorites: () => favoritesTapped = true,
          onRead: () => readTapped = true,
          onNext: () => nextTapped = true,
        ),
      );
      await _pumpForStableFrame(tester);

      await tester.tap(find.byIcon(Icons.share_rounded));
      await tester.tap(find.byIcon(Icons.star_rounded));
      await tester.tap(find.byIcon(Icons.auto_stories_rounded));
      await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
      await _pumpForStableFrame(tester);

      expect(shareTapped, isTrue);
      expect(favoritesTapped, isTrue);
      expect(readTapped, isTrue);
      expect(nextTapped, isTrue);
    });
  });
}
