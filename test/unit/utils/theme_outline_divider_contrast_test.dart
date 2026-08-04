@Tags(['unit', 'utils'])
library;

import 'package:devocional_nuevo/utils/constants/theme_constants.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for a bug where card/field borders (e.g. the notes
/// list cards and the add-note text field) relied on the implicit
/// `ColorScheme.outline` / `ThemeData.dividerColor`, which
/// `ColorScheme.fromSwatch` derives from the *primary swatch's own*
/// estimated brightness rather than the theme's actual surface color.
/// That made the border resolve to white (invisible on a white card) for
/// Deep Purple, Green, Pink and Light Blue in light mode, while Cyan and
/// Gray happened to resolve to black and looked fine.
void main() {
  group('Theme outline/divider contrast against surface', () {
    for (final themeFamily in appThemeFamilies.keys) {
      for (final brightness in ['light', 'dark']) {
        test('$themeFamily $brightness outline contrasts with surface', () {
          final theme = appThemeFamilies[themeFamily]![brightness]!;
          final outline = theme.colorScheme.outline;
          final dividerColor = theme.dividerColor;
          final surface = theme.colorScheme.surface;

          expect(
            outline,
            isNot(equals(surface)),
            reason: '$themeFamily $brightness: colorScheme.outline must not '
                'match surface color, or borders become invisible',
          );
          expect(
            dividerColor,
            isNot(equals(surface)),
            reason: '$themeFamily $brightness: dividerColor must not match '
                'surface color, or borders become invisible',
          );
        });
      }
    }
  });
}
