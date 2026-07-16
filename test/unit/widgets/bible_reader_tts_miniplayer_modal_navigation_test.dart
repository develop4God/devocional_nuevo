@Tags(['unit', 'widgets'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Source-level regression tests for the TTS modal close-on-completion logic.
///
/// These tests assert directly against the production source files to catch
/// regressions if the fix is accidentally reverted.
///
/// ## Bug History
/// 1. Originally BOTH the modal builder AND
///    [BibleReaderPage._handleTtsStateChange] popped on TTS completion,
///    producing a double pop that dismissed BibleReaderPage itself.
/// 2. The first fix removed the page-side pop entirely, relying on the
///    modal builder to close itself. But the page listener is registered
///    first on the state ValueNotifier, so its resetModalState() cleared
///    _shouldAutoCloseOnCompletion BEFORE the builder's listener ran,
///    defusing the builder's auto-close — the miniplayer never closed.
///
/// ## Current contract (mirrors devocionales_page, production-validated)
/// - `_handleTtsStateChange` calls `resetModalState()` (which defuses the
///   builder's auto-close, guaranteeing a single closer) and then performs
///   the one guarded pop in a post-frame callback.
/// - The pop is guarded by `Navigator.canPop(context)` so it only dismisses
///   the modal sheet, never the page.
void main() {
  late String pageSource;
  late String presenterSource;

  setUpAll(() async {
    pageSource = await File('lib/pages/bible_reader_page.dart').readAsString();
    presenterSource = await File(
      'lib/widgets/bible/bible_reader_tts_miniplayer_presenter.dart',
    ).readAsString();
  });

  group('BibleReader TTS modal close-on-completion', () {
    late String methodSection;

    setUpAll(() {
      final methodStart = pageSource.indexOf('void _handleTtsStateChange()');
      expect(
        methodStart,
        greaterThan(0),
        reason: '_handleTtsStateChange must exist in bible_reader_page.dart',
      );
      // Inspect enough source after the method declaration to cover the
      // full body (~2 500 characters is well beyond the method length).
      methodSection = pageSource.substring(methodStart, methodStart + 2500);
    });

    test('_handleTtsStateChange calls resetModalState() on TTS completion', () {
      expect(
        methodSection.contains('resetModalState()'),
        isTrue,
        reason: '_handleTtsStateChange must call resetModalState() first: '
            'it defuses the modal builder\'s own auto-close (single-closer '
            'guarantee) and clears isShowing for the next playback.',
      );
    });

    test(
      '_handleTtsStateChange closes the modal itself with a guarded pop',
      () {
        // The page listener runs BEFORE the modal builder's listener, so
        // after resetModalState() the builder will NOT close the sheet —
        // the page must pop it, exactly like devocionales_page does.
        expect(
          methodSection.contains('Navigator.of(context).pop()'),
          isTrue,
          reason: '_handleTtsStateChange must pop the miniplayer sheet on '
              'completion; the builder\'s auto-close is defused by '
              'resetModalState() and will never fire.',
        );
        expect(
          methodSection.contains('Navigator.canPop(context)'),
          isTrue,
          reason: 'The pop must be guarded by Navigator.canPop(context) so '
              'it only dismisses the modal sheet, never BibleReaderPage.',
        );
        expect(
          methodSection.contains('addPostFrameCallback'),
          isTrue,
          reason: 'The pop must run in a post-frame callback to avoid '
              'navigating during a ValueNotifier notification frame.',
        );
      },
    );

    test(
        'Presenter showMiniplayerModal uses the modal context (ctx) — not the '
        'page context — to close the bottom sheet', () {
      final methodStart = presenterSource.indexOf('void showMiniplayerModal(');
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
    });

    test(
      'isShowing flag is reset via whenComplete callback after modal closes',
      () {
        // _shouldAutoCloseOnCompletion represents "modal is showing".
        // The whenComplete callback resets it to false (not showing)
        // to allow the next modal to open.
        expect(
          presenterSource.contains('_shouldAutoCloseOnCompletion = false'),
          isTrue,
          reason:
              'The presenter must reset _shouldAutoCloseOnCompletion to false '
              'in the whenComplete callback so subsequent TTS playbacks can open '
              'a new modal.',
        );
      },
    );
  });
}
