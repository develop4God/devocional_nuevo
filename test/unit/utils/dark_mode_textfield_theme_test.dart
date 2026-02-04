import 'package:devocional_nuevo/utils/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

@Tags(['unit', 'utils'])
void main() {
  group('Theme Constants Dark Mode TextField Tests', () {
    group('Dark Mode Input Decoration Theme', () {
      test(
        'Deep Purple dark theme should have grey.shade800 as fillColor for text fields',
        () {
          final darkTheme = appThemeFamilies['Deep Purple']!['dark']!;
          final inputDecorationTheme = darkTheme.inputDecorationTheme;

          expect(inputDecorationTheme.filled, isTrue);
          expect(inputDecorationTheme.fillColor, equals(Colors.grey.shade800));
        },
      );

      test(
        'Green dark theme should have grey.shade800 as fillColor for text fields',
        () {
          final darkTheme = appThemeFamilies['Green']!['dark']!;
          final inputDecorationTheme = darkTheme.inputDecorationTheme;

          expect(inputDecorationTheme.filled, isTrue);
          expect(inputDecorationTheme.fillColor, equals(Colors.grey.shade800));
        },
      );

      test(
        'Pink dark theme should have grey.shade800 as fillColor for text fields',
        () {
          final darkTheme = appThemeFamilies['Pink']!['dark']!;
          final inputDecorationTheme = darkTheme.inputDecorationTheme;

          expect(inputDecorationTheme.filled, isTrue);
          expect(inputDecorationTheme.fillColor, equals(Colors.grey.shade800));
        },
      );

      test(
        'Cyan dark theme should have grey.shade800 as fillColor for text fields',
        () {
          final darkTheme = appThemeFamilies['Cyan']!['dark']!;
          final inputDecorationTheme = darkTheme.inputDecorationTheme;

          expect(inputDecorationTheme.filled, isTrue);
          expect(inputDecorationTheme.fillColor, equals(Colors.grey.shade800));
        },
      );

      test(
        'Light Blue dark theme should have grey.shade800 as fillColor for text fields',
        () {
          final darkTheme = appThemeFamilies['Light Blue']!['dark']!;
          final inputDecorationTheme = darkTheme.inputDecorationTheme;

          expect(inputDecorationTheme.filled, isTrue);
          expect(inputDecorationTheme.fillColor, equals(Colors.grey.shade800));
        },
      );
    });

    group('Light Mode Input Decoration Theme', () {
      test(
        'Deep Purple light theme should have white as fillColor for text fields',
        () {
          final lightTheme = appThemeFamilies['Deep Purple']!['light']!;
          final inputDecorationTheme = lightTheme.inputDecorationTheme;

          expect(inputDecorationTheme.filled, isTrue);
          expect(inputDecorationTheme.fillColor, equals(Colors.white));
        },
      );

      test(
        'Green light theme should have white as fillColor for text fields',
        () {
          final lightTheme = appThemeFamilies['Green']!['light']!;
          final inputDecorationTheme = lightTheme.inputDecorationTheme;

          expect(inputDecorationTheme.filled, isTrue);
          expect(inputDecorationTheme.fillColor, equals(Colors.white));
        },
      );

      test(
        'Pink light theme should have white as fillColor for text fields',
        () {
          final lightTheme = appThemeFamilies['Pink']!['light']!;
          final inputDecorationTheme = lightTheme.inputDecorationTheme;

          expect(inputDecorationTheme.filled, isTrue);
          expect(inputDecorationTheme.fillColor, equals(Colors.white));
        },
      );

      test(
        'Cyan light theme should have white as fillColor for text fields',
        () {
          final lightTheme = appThemeFamilies['Cyan']!['light']!;
          final inputDecorationTheme = lightTheme.inputDecorationTheme;

          expect(inputDecorationTheme.filled, isTrue);
          expect(inputDecorationTheme.fillColor, equals(Colors.white));
        },
      );

      test(
        'Light Blue light theme should have white as fillColor for text fields',
        () {
          final lightTheme = appThemeFamilies['Light Blue']!['light']!;
          final inputDecorationTheme = lightTheme.inputDecorationTheme;

          expect(inputDecorationTheme.filled, isTrue);
          expect(inputDecorationTheme.fillColor, equals(Colors.white));
        },
      );
    });

    group('Color Scheme Tests', () {
      test('Dark themes should have dark surface color', () {
        for (final themeName in appThemeFamilies.keys) {
          final darkTheme = appThemeFamilies[themeName]!['dark']!;
          expect(
            darkTheme.colorScheme.brightness,
            equals(Brightness.dark),
            reason: '$themeName dark theme should have dark brightness',
          );
        }
      });

      test('Light themes should have light surface color', () {
        for (final themeName in appThemeFamilies.keys) {
          final lightTheme = appThemeFamilies[themeName]!['light']!;
          expect(
            lightTheme.colorScheme.brightness,
            equals(Brightness.light),
            reason: '$themeName light theme should have light brightness',
          );
        }
      });
    });
  });
}
