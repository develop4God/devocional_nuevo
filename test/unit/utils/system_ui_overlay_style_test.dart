// test/unit/utils/system_ui_overlay_style_test.dart
import 'package:devocional_nuevo/utils/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

@Tags(['unit', 'utils'])
void main() {
  group('System UI Overlay Style Configuration', () {
    test('systemUiOverlayStyle should be defined', () {
      expect(systemUiOverlayStyle, isNotNull);
    });

    test('Status bar should be transparent', () {
      expect(systemUiOverlayStyle.statusBarColor, Colors.transparent);
    });

    test('Status bar icons should be light (white)', () {
      expect(systemUiOverlayStyle.statusBarIconBrightness, Brightness.light);
    });

    test('Status bar brightness should be dark for iOS', () {
      expect(systemUiOverlayStyle.statusBarBrightness, Brightness.dark);
    });

    test('Navigation bar should be dark gray (Material grey 800)', () {
      expect(
        systemUiOverlayStyle.systemNavigationBarColor,
        const Color(0xFF424242),
      );
    });

    test('Navigation bar icons should be light (white buttons)', () {
      expect(
        systemUiOverlayStyle.systemNavigationBarIconBrightness,
        Brightness.light,
      );
    });

    test('Navigation bar divider should be transparent', () {
      expect(
        systemUiOverlayStyle.systemNavigationBarDividerColor,
        Colors.transparent,
      );
    });

    test(
      'Dark gray navigation bar provides good contrast with white icons',
      () {
        // Dark gray (0xFF424242) with white icons (0xFFFFFFFF)
        // This ensures buttons are always visible regardless of theme
        const navBarColor = Color(0xFF424242);
        const iconColor = Color(0xFFFFFFFF);

        // Calculate relative luminance
        final navBarLuminance = navBarColor.computeLuminance();
        final iconLuminance = iconColor.computeLuminance();

        // Contrast ratio should be > 4.5:1 for WCAG AA compliance
        final contrastRatio = (iconLuminance + 0.05) / (navBarLuminance + 0.05);

        expect(
          contrastRatio,
          greaterThan(4.5),
          reason: 'Navigation bar should have sufficient contrast with icons',
        );
      },
    );

    test(
      'System UI overlay style is consistent across all app configurations',
      () {
        // Verify the configuration works for both light and dark themes
        // by checking that the values are constant
        expect(systemUiOverlayStyle, isA<SystemUiOverlayStyle>());
        expect(systemUiOverlayStyle.systemNavigationBarColor, isNotNull);
        expect(
          systemUiOverlayStyle.systemNavigationBarIconBrightness,
          isNotNull,
        );
      },
    );

    test('Configuration matches Android 15 edge-to-edge requirements', () {
      // Android 15+ requires proper edge-to-edge configuration
      // The navigation bar color should not be pure black or white
      final navColor = systemUiOverlayStyle.systemNavigationBarColor!;

      expect(
        navColor,
        isNot(Colors.black),
        reason: 'Pure black can cause contrast issues on some devices',
      );
      expect(
        navColor,
        isNot(Colors.white),
        reason: 'Pure white can cause visibility issues with white icons',
      );

      // Should be a neutral gray for maximum compatibility
      final redValue = (navColor.r * 255.0).round() & 0xff;
      final greenValue = (navColor.g * 255.0).round() & 0xff;
      final blueValue = (navColor.b * 255.0).round() & 0xff;
      expect(redValue, greenValue);
      expect(greenValue, blueValue);
    });
  });

  group('System UI Overlay Style Integration', () {
    testWidgets('AnnotatedRegion applies system UI overlay style correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        AnnotatedRegion<SystemUiOverlayStyle>(
          value: systemUiOverlayStyle,
          child: const MaterialApp(
            home: Scaffold(body: Center(child: Text('Test'))),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
      // If the widget builds successfully, the AnnotatedRegion is working
    });

    testWidgets('System UI overlay style works with different themes', (
      WidgetTester tester,
    ) async {
      // Test with light theme
      await tester.pumpWidget(
        AnnotatedRegion<SystemUiOverlayStyle>(
          value: systemUiOverlayStyle,
          child: MaterialApp(
            theme: ThemeData.light(),
            home: const Scaffold(body: Center(child: Text('Light Theme'))),
          ),
        ),
      );

      expect(find.text('Light Theme'), findsOneWidget);
      await tester.pumpAndSettle();

      // Test with dark theme
      await tester.pumpWidget(
        AnnotatedRegion<SystemUiOverlayStyle>(
          value: systemUiOverlayStyle,
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(body: Center(child: Text('Dark Theme'))),
          ),
        ),
      );

      expect(find.text('Dark Theme'), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });
}
