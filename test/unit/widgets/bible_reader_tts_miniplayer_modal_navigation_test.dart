@Tags(['unit', 'widgets'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Source-level regression tests for the TTS modal navigation bug fix.
///
/// These tests assert directly against the production source files to catch
/// regressions if the fix is accidentally reverted.
///
/// ## Bug History
/// Both the modal builder AND [BibleReaderPage._handleTtsStateChange] were
/// calling `Navigator.pop(context)` when TTS completed.  Because
/// `showModalBottomSheet` does NOT push a route onto the Navigator stack,
/// the extra `pop` in `_handleTtsStateChange` was dismissing
/// `BibleReaderPage` itself — taking the user back to the devotionals list.
///
/// ## Fix
/// - `_handleTtsStateChange` now only calls `resetModalState()` to clear the
///   internal flag; it never calls `Navigator.pop()`.
/// - The modal's builder uses `Navigator.of(ctx).pop()` with `ctx` (the
///   modal's own [BuildContext]) to close itself correctly.
void main() {
  late String pageSource;
  late String presenterSource;

  setUpAll(() async {
    pageSource = await File('lib/pages/bible_reader_page.dart').readAsString();
    presenterSource = await File(
      'lib/widgets/bible/bible_reader_tts_miniplayer_presenter.dart',
    ).readAsString();
  });

  group('BibleReaderTtsMiniplayerPresenter Navigation Fix', () {
    test(
      'BibleReaderPage._handleTtsStateChange does not call Navigator.pop(context)',
      () {
        final methodStart = pageSource.indexOf('void _handleTtsStateChange()');
        expect(
          methodStart,
          greaterThan(0),
          reason: '_handleTtsStateChange must exist in bible_reader_page.dart',
        );

        // Inspect enough source after the method declaration to cover the
        // full body (~2 000 characters is well beyond the ~40-line method).
        final methodSection =
            pageSource.substring(methodStart, methodStart + 2000);

        expect(
          methodSection.contains('Navigator.pop(context)'),
          isFalse,
          reason: '_handleTtsStateChange must NOT call Navigator.pop(context). '
              'Calling pop with the page context dismisses BibleReaderPage '
              'instead of just closing the modal bottom sheet.',
        );
      },
    );

    test(
      'BibleReaderPage._handleTtsStateChange calls resetModalState() on TTS completion',
      () {
        final methodStart = pageSource.indexOf('void _handleTtsStateChange()');
        expect(methodStart, greaterThan(0));

        final methodSection =
            pageSource.substring(methodStart, methodStart + 2000);

        expect(
          methodSection.contains('resetModalState()'),
          isTrue,
          reason: '_handleTtsStateChange must call resetModalState() to clear '
              'the internal isShowing flag when TTS completes, so a new '
              'modal can be opened on the next playback.',
        );
      },
    );

    test(
      'Presenter showMiniplayerModal uses the modal context (ctx) — not the '
      'page context — to close the bottom sheet',
      () {
        final methodStart =
            presenterSource.indexOf('void showMiniplayerModal(');
        expect(
          methodStart,
          greaterThan(0),
          reason: 'showMiniplayerModal must exist in '
              'bible_reader_tts_miniplayer_presenter.dart',
        );

        final methodSection = presenterSource.substring(methodStart);

        // The builder's context variable is `ctx`; closing must use it.
        expect(
          methodSection.contains('Navigator.of(ctx).pop()'),
          isTrue,
          reason: 'showMiniplayerModal must close via Navigator.of(ctx).pop() '
              'using the modal builder context (ctx), not the page context, '
              'to dismiss only the bottom sheet.',
        );
      },
    );

    test(
      'isShowing flag is reset via whenComplete callback after modal closes',
      () {
        expect(
          presenterSource.contains('_isModalShowing = false'),
          isTrue,
          reason: 'The presenter must reset _isModalShowing so subsequent TTS '
              'playbacks can open a new modal.',
        );
      },
    );
  });
}
