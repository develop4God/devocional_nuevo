import 'dart:async';
import 'dart:developer' as developer;

import 'package:devocional_nuevo/services/localization_service.dart';
import 'package:devocional_nuevo/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A minimal test widget that demonstrates the mounted check pattern
/// used in lib/main.dart's _initializeApp() method
class TestMountedCheckWidget extends StatefulWidget {
  final Completer<String> resultCompleter;

  const TestMountedCheckWidget({super.key, required this.resultCompleter});

  @override
  State<TestMountedCheckWidget> createState() => _TestMountedCheckWidgetState();
}

class _TestMountedCheckWidgetState extends State<TestMountedCheckWidget> {
  @override
  void initState() {
    super.initState();
    _initializeWithMountedCheck();
  }

  /// Simulates the async initialization pattern with mounted checks
  /// from lib/main.dart lines 191-199 and 216-224
  Future<void> _initializeWithMountedCheck() async {
    try {
      // Simulate first async operation (like localizationProvider.initialize())
      await Future.delayed(const Duration(milliseconds: 100));

      // Check if widget is still mounted after async operation
      if (!mounted) {
        developer.log(
          'Test: Widget unmounted during initialization, aborting safely',
          name: 'TestMountedCheck',
        );
        widget.resultCompleter.complete('unmounted_safely');
        return;
      }

      // Simulate second async operation (like OnboardingService check)
      await Future.delayed(const Duration(milliseconds: 100));

      // Check again after second async operation
      if (!mounted) {
        developer.log(
          'Test: Widget unmounted during second operation, aborting safely',
          name: 'TestMountedCheck',
        );
        widget.resultCompleter.complete('unmounted_safely');
        return;
      }

      widget.resultCompleter.complete('completed_normally');
    } catch (e) {
      widget.resultCompleter.completeError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Reset ServiceLocator for clean test state
    ServiceLocator().reset();

    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Setup ServiceLocator with required services
    setupServiceLocator();
  });

  tearDown(() {
    ServiceLocator().reset();
  });

  group('Context Safety - Mounted Check Pattern Tests', () {
    testWidgets(
      'Mounted check prevents context-after-dispose when widget unmounts during async',
      (WidgetTester tester) async {
        final resultCompleter = Completer<String>();

        // Build the test widget
        await tester.pumpWidget(
          TestMountedCheckWidget(resultCompleter: resultCompleter),
        );

        // Allow first async operation to start
        await tester.pump(const Duration(milliseconds: 50));

        // Unmount widget mid-initialization
        await tester.pumpWidget(const SizedBox.shrink());

        // Wait for async operations to complete
        await tester.pump(const Duration(milliseconds: 200));

        // Verify the widget detected unmount and exited safely
        final result = await resultCompleter.future;
        expect(result, equals('unmounted_safely'));
      },
    );

    testWidgets('Initialization completes normally when widget stays mounted', (
      WidgetTester tester,
    ) async {
      final resultCompleter = Completer<String>();

      // Build the test widget
      await tester.pumpWidget(
        TestMountedCheckWidget(resultCompleter: resultCompleter),
      );

      // Let the widget complete its initialization
      await tester.pump(const Duration(milliseconds: 300));

      // Verify initialization completed normally
      final result = await resultCompleter.future;
      expect(result, equals('completed_normally'));
    });

    testWidgets('Multiple rapid mount/unmount cycles are handled safely', (
      WidgetTester tester,
    ) async {
      final completers = <Completer<String>>[];

      // First mount
      final completer1 = Completer<String>();
      completers.add(completer1);
      await tester.pumpWidget(
        TestMountedCheckWidget(resultCompleter: completer1),
      );
      await tester.pump(const Duration(milliseconds: 30));

      // Unmount
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 30));

      // Second mount
      final completer2 = Completer<String>();
      completers.add(completer2);
      await tester.pumpWidget(
        TestMountedCheckWidget(resultCompleter: completer2),
      );
      await tester.pump(const Duration(milliseconds: 30));

      // Unmount again
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 200));

      // All completers should have completed (either normally or with unmount detection)
      for (final completer in completers) {
        final result = await completer.future;
        expect(
          result,
          anyOf(equals('unmounted_safely'), equals('completed_normally')),
        );
      }
    });
  });

  group('LocalizationService Integration', () {
    test(
      'LocalizationService initializes correctly via ServiceLocator',
      () async {
        final localizationService = getService<LocalizationService>();
        await localizationService.initialize();

        // Should have a valid locale
        expect(localizationService.currentLocale, isNotNull);
        expect(
          LocalizationService.supportedLocales.map((l) => l.languageCode),
          contains(localizationService.currentLocale.languageCode),
        );
      },
    );
  });
}
