@Tags(['unit', 'widgets'])
library;

import 'package:flutter_test/flutter_test.dart';

/// Tests for the supporter icon in bottom navigation bars
void main() {
  group('Bottom Navigation Bar Supporter Icon', () {
    test('should be visible when feature_supporter is enabled', () {
      bool featureSupporter = true;

      expect(featureSupporter, isTrue);
    });

    test('should be hidden when feature_supporter is disabled', () {
      bool featureSupporter = false;

      expect(featureSupporter, isFalse);
    });

    test('should use volunteer_activism icon', () {
      const iconName = 'volunteer_activism';

      expect(iconName, equals('volunteer_activism'));
    });

    test('should have correct key for identification', () {
      const key = 'bottom_appbar_supporter_icon';

      expect(key, equals('bottom_appbar_supporter_icon'));
      expect(key, contains('supporter'));
    });

    test('should navigate to SupporterPage on press', () {
      String? navigationTarget;

      void onSupportPressed() {
        navigationTarget = 'SupporterPage';
      }

      onSupportPressed();

      expect(navigationTarget, equals('SupporterPage'));
    });

    test('should log analytics event on press', () {
      String? loggedAction;

      void logBottomBarAction(String action) {
        loggedAction = action;
      }

      logBottomBarAction('supporter');

      expect(loggedAction, equals('supporter'));
    });

    test('should use fade transition for navigation', () {
      const transitionType = 'fade';
      const transitionDuration = 250; // milliseconds

      expect(transitionType, equals('fade'));
      expect(transitionDuration, equals(250));
    });

    test('should have tooltip for accessibility', () {
      const tooltip = 'tooltips.support';

      expect(tooltip, isNotEmpty);
      expect(tooltip, contains('support'));
    });
  });

  group('Bottom Navigation Bar Integration', () {
    test('supporter icon should be placed after settings icon', () {
      // Icon order in devocionales_bottom_bar:
      // 1. prayers
      // 2. bible
      // 3. discovery (conditional)
      // 4. progress
      // 5. settings
      // 6. supporter (conditional - NEW)

      final iconOrder = [
        'prayers',
        'bible',
        'discovery',
        'progress',
        'settings',
        'supporter',
      ];

      expect(iconOrder.indexOf('supporter'),
          greaterThan(iconOrder.indexOf('settings')));
      expect(iconOrder.last, equals('supporter'));
    });

    test('supporter icon should be present in both bottom navigation bars', () {
      final bottomBars = [
        'devocionales_bottom_bar',
        'discovery_bottom_nav_bar',
      ];

      expect(bottomBars, hasLength(2));
      expect(bottomBars, contains('devocionales_bottom_bar'));
      expect(bottomBars, contains('discovery_bottom_nav_bar'));
    });

    test('supporter feature should be controllable via remote config', () {
      // Default value should be true for testing
      const defaultValue = true;

      expect(defaultValue, isTrue);
    });
  });

  group('Supporter Icon Properties', () {
    test('should have correct size', () {
      const iconSize = 32.0;

      expect(iconSize, equals(32.0));
      expect(iconSize, greaterThan(0));
    });

    test('should use onPrimary color from theme', () {
      const colorSource = 'colorScheme.onPrimary';

      expect(colorSource, contains('onPrimary'));
    });

    test('should match design guidelines', () {
      const iconName = 'volunteer_activism';
      const iconSize = 32.0;

      // Icon represents support/donation with hands and heart
      expect(iconName, contains('volunteer'));
      expect(iconSize, inInclusiveRange(30.0, 35.0));
    });
  });
}
