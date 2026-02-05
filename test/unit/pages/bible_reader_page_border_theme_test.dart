@Tags(['unit', 'pages'])
library;

import 'package:devocional_nuevo/utils/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BibleReaderPage Border Theme Integration Tests', () {
    testWidgets('OutlinedButton respects theme border color in light mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appThemeFamilies['Deep Purple']!['light'],
          home: Scaffold(
            body: OutlinedButton(
              onPressed: () {},
              child: const Text('Test Button'),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify theme has black border for light mode
      final theme = appThemeFamilies['Deep Purple']!['light']!;
      final borderSide = theme.outlinedButtonTheme.style?.side?.resolve({});
      expect(
        borderSide?.color,
        Colors.black,
        reason: 'Deep Purple light theme should have black border',
      );
    });

    testWidgets('OutlinedButton respects theme border color in dark mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appThemeFamilies['Deep Purple']!['dark'],
          home: Scaffold(
            body: OutlinedButton(
              onPressed: () {},
              child: const Text('Test Button'),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify theme has white border for dark mode
      final theme = appThemeFamilies['Deep Purple']!['dark']!;
      final borderSide = theme.outlinedButtonTheme.style?.side?.resolve({});
      expect(
        borderSide?.color,
        Colors.white,
        reason: 'Deep Purple dark theme should have white border',
      );
    });

    test('Theme border color can be extracted for custom containers', () {
      // Test light theme
      final lightTheme = appThemeFamilies['Green']!['light']!;
      final lightBorderColor =
          lightTheme.outlinedButtonTheme.style?.side?.resolve({})?.color;
      expect(
        lightBorderColor,
        Colors.black,
        reason:
            'Light theme border color should be black for custom containers',
      );

      // Test dark theme
      final darkTheme = appThemeFamilies['Green']!['dark']!;
      final darkBorderColor =
          darkTheme.outlinedButtonTheme.style?.side?.resolve({})?.color;
      expect(
        darkBorderColor,
        Colors.white,
        reason: 'Dark theme border color should be white for custom containers',
      );
    });

    testWidgets('Container can use theme border color via Theme.of(context)', (
      WidgetTester tester,
    ) async {
      Color? capturedBorderColor;

      await tester.pumpWidget(
        MaterialApp(
          theme: appThemeFamilies['Pink']!['light'],
          home: Scaffold(
            body: Builder(
              builder: (context) {
                capturedBorderColor = Theme.of(
                  context,
                ).outlinedButtonTheme.style?.side?.resolve({})?.color;
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: capturedBorderColor ?? Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      expect(
        capturedBorderColor,
        Colors.black,
        reason:
            'Pink light theme should provide black border color via Theme.of(context)',
      );
    });

    test('All themes provide correct border color', () {
      for (final themeEntry in appThemeFamilies.entries) {
        final themeName = themeEntry.key;

        // Test light mode
        final lightTheme = themeEntry.value['light']!;
        final lightBorderColor =
            lightTheme.outlinedButtonTheme.style?.side?.resolve({})?.color;
        expect(
          lightBorderColor,
          Colors.black,
          reason: '$themeName light theme should provide black border',
        );

        // Test dark mode
        final darkTheme = themeEntry.value['dark']!;
        final darkBorderColor =
            darkTheme.outlinedButtonTheme.style?.side?.resolve({})?.color;
        expect(
          darkBorderColor,
          Colors.white,
          reason: '$themeName dark theme should provide white border',
        );
      }
    });
  });
}
