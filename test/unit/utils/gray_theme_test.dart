@Tags(['unit', 'utils'])
library;

import 'package:devocional_nuevo/utils/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Gray Theme Tests', () {
    group('Theme Registry', () {
      test('Gray theme is present in appThemeFamilies', () {
        expect(appThemeFamilies.containsKey('Gray'), isTrue);
      });

      test('Gray theme has both light and dark variants', () {
        expect(appThemeFamilies['Gray']!.containsKey('light'), isTrue);
        expect(appThemeFamilies['Gray']!.containsKey('dark'), isTrue);
      });

      test('Gray display name is Serenidad', () {
        expect(themeDisplayNames['Gray'], equals('Serenidad'));
      });
    });

    group('Gray Light Theme', () {
      late ThemeData lightTheme;

      setUp(() {
        lightTheme = appThemeFamilies['Gray']!['light']!;
      });

      test('has light brightness', () {
        expect(lightTheme.colorScheme.brightness, equals(Brightness.light));
      });

      test('AppBar has grey background and white foreground', () {
        expect(
          lightTheme.appBarTheme.backgroundColor,
          equals(Colors.grey[600]),
        );
        expect(lightTheme.appBarTheme.foregroundColor, equals(Colors.white));
      });

      test('color scheme surface is white', () {
        expect(lightTheme.colorScheme.surface, equals(const Color(0xFFFAFAFA)));
      });

      test('color scheme onSurface is black87', () {
        expect(
          lightTheme.colorScheme.onSurface,
          equals(Colors.black87),
        );
      });

      test('elevated button background is grey[600]', () {
        final style = lightTheme.elevatedButtonTheme.style!;
        final bg = style.backgroundColor?.resolve({WidgetState.pressed});
        expect(bg, equals(Colors.grey[600]));
      });

      test('slider active track color is grey[600]', () {
        expect(
          lightTheme.sliderTheme.activeTrackColor,
          equals(Colors.grey[600]),
        );
      });

      test('slider thumb color is grey[600]', () {
        expect(lightTheme.sliderTheme.thumbColor, equals(Colors.grey[600]));
      });

      test('input decoration fill color is paper gray', () {
        expect(
          lightTheme.inputDecorationTheme.fillColor,
          equals(const Color(0xFFFAFAFA)),
        );
        expect(lightTheme.inputDecorationTheme.filled, isTrue);
      });
    });

    group('Gray Dark Theme', () {
      late ThemeData darkTheme;

      setUp(() {
        darkTheme = appThemeFamilies['Gray']!['dark']!;
      });

      test('has dark brightness', () {
        expect(darkTheme.colorScheme.brightness, equals(Brightness.dark));
      });

      test('AppBar has dark gray background and white foreground', () {
        expect(
          darkTheme.appBarTheme.backgroundColor,
          equals(const Color(0xFF1F1F1F)),
        );
        expect(darkTheme.appBarTheme.foregroundColor, equals(Colors.white));
      });

      test('color scheme primary is grey[500]', () {
        expect(darkTheme.colorScheme.primary, equals(Colors.grey[500]));
      });

      test('color scheme surface is dark', () {
        expect(
          darkTheme.colorScheme.surface,
          equals(const Color(0xFF2A2A2A)),
        );
      });

      test('color scheme onSurface is white', () {
        expect(darkTheme.colorScheme.onSurface, equals(Colors.white));
      });

      test('elevated button background is grey[700]', () {
        final style = darkTheme.elevatedButtonTheme.style!;
        final bg = style.backgroundColor?.resolve({WidgetState.pressed});
        expect(bg, equals(Colors.grey[700]));
      });

      test('slider active track color is grey[400]', () {
        expect(
          darkTheme.sliderTheme.activeTrackColor,
          equals(Colors.grey[400]),
        );
      });

      test('slider thumb color is grey[400]', () {
        expect(darkTheme.sliderTheme.thumbColor, equals(Colors.grey[400]));
      });

      test('input decoration fill color is grey container', () {
        expect(
          darkTheme.inputDecorationTheme.fillColor,
          equals(const Color(0xFF3A3A3A)),
        );
        expect(darkTheme.inputDecorationTheme.filled, isTrue);
      });
    });

    group('Existing Themes Unaffected', () {
      test('Cyan theme still present', () {
        expect(appThemeFamilies.containsKey('Cyan'), isTrue);
      });

      test('Deep Purple theme still present', () {
        expect(appThemeFamilies.containsKey('Deep Purple'), isTrue);
      });

      test('Green theme still present', () {
        expect(appThemeFamilies.containsKey('Green'), isTrue);
      });

      test('Pink theme still present', () {
        expect(appThemeFamilies.containsKey('Pink'), isTrue);
      });

      test('Light Blue theme still present', () {
        expect(appThemeFamilies.containsKey('Light Blue'), isTrue);
      });

      test('Total theme count is now 6', () {
        expect(appThemeFamilies.length, equals(6));
      });

      test('Cyan AppBar color unchanged', () {
        final cyanLight = appThemeFamilies['Cyan']!['light']!;
        expect(
          cyanLight.appBarTheme.backgroundColor,
          equals(Colors.cyan),
        );
      });
    });
  });
}
