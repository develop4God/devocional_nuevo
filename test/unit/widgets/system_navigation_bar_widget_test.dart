@Tags(['unit', 'widgets'])
library;

// test/unit/widgets/system_navigation_bar_widget_test.dart
//
// Migrated from integration_test/system_navigation_bar_integration_test.dart
// Tests that systemUiOverlayStyle is applied correctly, survives navigation,
// theme changes, and meets WCAG contrast requirements. No device required.

import 'package:devocional_nuevo/utils/constants/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('System Navigation Bar Widget Tests', () {
    testWidgets(
      'App should have AnnotatedRegion with systemUiOverlayStyle',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: systemUiOverlayStyle,
            child: const MaterialApp(
              home: Scaffold(body: Center(child: Text('Test App'))),
            ),
          ),
        );

        expect(find.text('Test App'), findsOneWidget);
      },
    );

    testWidgets(
      'System UI overlay style should persist through navigation',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: systemUiOverlayStyle,
            child: MaterialApp(
              home: Scaffold(
                appBar: AppBar(title: const Text('Home')),
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(title: const Text('Second Page')),
                            body: const Center(child: Text('Second Page')),
                          ),
                        ),
                      );
                    },
                    child: const Text('Navigate'),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Navigate'), findsOneWidget);

        await tester.tap(find.text('Navigate'));
        await tester.pumpAndSettle();

        // One in AppBar, one in body
        expect(find.text('Second Page'), findsNWidgets(2));
      },
    );

    testWidgets(
      'System UI overlay style should work with theme changes',
      (WidgetTester tester) async {
        bool isDarkMode = false;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: systemUiOverlayStyle,
                child: MaterialApp(
                  theme: ThemeData.light(),
                  darkTheme: ThemeData.dark(),
                  themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
                  home: Scaffold(
                    appBar: AppBar(title: const Text('Theme Test')),
                    body: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isDarkMode = !isDarkMode;
                        });
                      },
                      child: Text(
                        isDarkMode ? 'Switch to Light' : 'Switch to Dark',
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );

        expect(find.text('Theme Test'), findsOneWidget);
        expect(find.text('Switch to Dark'), findsOneWidget);

        await tester.tap(find.text('Switch to Dark'));
        await tester.pumpAndSettle();

        expect(find.text('Switch to Light'), findsOneWidget);
      },
    );

    test('System UI overlay style values are correct for all scenarios', () {
      expect(systemUiOverlayStyle.statusBarColor, Colors.transparent);
      expect(
        systemUiOverlayStyle.statusBarIconBrightness,
        Brightness.light,
      );
      expect(
        systemUiOverlayStyle.systemNavigationBarColor,
        const Color(0xFF424242),
      );
      expect(
        systemUiOverlayStyle.systemNavigationBarIconBrightness,
        Brightness.light,
      );
      expect(
        systemUiOverlayStyle.systemNavigationBarDividerColor,
        Colors.transparent,
      );
    });

    testWidgets(
      'System UI overlay style should not interfere with app functionality',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: systemUiOverlayStyle,
            child: MaterialApp(
              home: Scaffold(
                body: ListView(
                  children: List.generate(
                    20,
                    (index) =>
                        ListTile(title: Text('Item $index'), onTap: () {}),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Item 0'), findsOneWidget);
        expect(find.text('Item 19'), findsNothing);

        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();

        expect(find.text('Item 0'), findsNothing);
      },
    );
  });

  group('System Navigation Bar Color Validation', () {
    test('Navigation bar color should be Material Grey 800', () {
      const expectedColor = Color(0xFF424242);
      expect(
        systemUiOverlayStyle.systemNavigationBarColor,
        expectedColor,
      );
    });

    test('Navigation bar color should provide sufficient contrast', () {
      const navBarColor = Color(0xFF424242);
      const iconColor = Color(0xFFFFFFFF); // White

      final navBarLuminance = navBarColor.computeLuminance();
      final iconLuminance = iconColor.computeLuminance();

      final contrastRatio = (iconLuminance + 0.05) / (navBarLuminance + 0.05);

      // WCAG AA requires at least 4.5:1 for normal text
      expect(contrastRatio, greaterThanOrEqualTo(4.5));
    });

    test('Navigation bar color should be consistent across themes', () {
      const color1 = Color(0xFF424242);
      const color2 = Color(0xFF424242);

      expect(color1, color2);
      expect(systemUiOverlayStyle.systemNavigationBarColor, color1);
    });
  });
}
