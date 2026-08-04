@Tags(['unit', 'pages'])
library;

import 'package:devocional_nuevo/pages/app_navigation_shell.dart';
import 'package:devocional_nuevo/widgets/app_bottom_nav_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppNavigationShell.selectTab', () {
    test('is a safe no-op when no shell is mounted', () {
      // Call sites (SnackBar actions, dialogs) may fire when the shell is
      // gone (e.g. during app teardown) — must not throw.
      expect(
        () => AppNavigationShell.selectTab(AppTab.settings),
        returnsNormally,
      );
      expect(() => AppNavigationShell.selectTab(AppTab.home), returnsNormally);
    });

    test('shellKey is stable across accesses', () {
      expect(
        identical(AppNavigationShell.shellKey, AppNavigationShell.shellKey),
        isTrue,
      );
    });
  });

  group('AppNavigationShell.navigateToBibleReference', () {
    test('is a safe no-op when no shell is mounted', () {
      // Mirrors selectTab's no-op guard — a saved note or deep link may fire
      // this when the shell is gone (e.g. during app teardown).
      expect(
        () => AppNavigationShell.navigateToBibleReference(
          bookName: 'Genesis',
          chapter: 1,
          verse: 1,
        ),
        returnsNormally,
      );
    });
  });
}
