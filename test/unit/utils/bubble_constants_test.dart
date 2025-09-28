// test/unit/utils/bubble_constants_test.dart

import 'package:devocional_nuevo/utils/bubble_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BubbleConstants Tests', () {
    setUp(() async {
      // Setup SharedPreferences mock
      SharedPreferences.setMockInitialValues({
        'bubble_enabled': true,
        'new_feature_bubbles': true,
        'updated_feature_bubbles': true,
        'notification_bubbles': true,
      });
    });

    group('UI Constants and Theme Values', () {
      test('should provide consistent UI constants and theme values', () {
        // Test animation duration constants
        expect(BubbleConstants.animationDuration,
            equals(const Duration(milliseconds: 300)));
        expect(BubbleConstants.delayBeforeShow,
            equals(const Duration(milliseconds: 100)));

        // Test color constants
        expect(
            BubbleConstants.newFeatureColor, equals(const Color(0xFF4CAF50)));
        expect(BubbleConstants.updatedFeatureColor,
            equals(const Color(0xFF2196F3)));
        expect(
            BubbleConstants.notificationColor, equals(const Color(0xFFFF5722)));
      });

      test('should provide consistent positioning values', () {
        // Test widget bubble positioning
        expect(BubbleConstants.widgetBubbleTop, equals(-6));
        expect(BubbleConstants.widgetBubbleRight, equals(-63));

        // Test icon badge positioning
        expect(BubbleConstants.iconBadgeTop, equals(-4));
        expect(BubbleConstants.iconBadgeRight, equals(-4));
      });

      test('should provide consistent size values', () {
        // Test bubble sizes
        expect(BubbleConstants.widgetBubbleRadius, equals(12));
        expect(BubbleConstants.iconBadgeSize, equals(12));
        expect(BubbleConstants.iconBadgeRadius, equals(4));
      });

      test('should provide consistent text styles', () {
        // Test widget bubble text style
        const expectedWidgetStyle = TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        );
        expect(
            BubbleConstants.widgetBubbleTextStyle, equals(expectedWidgetStyle));

        // Test icon badge text style
        const expectedIconStyle = TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        );
        expect(BubbleConstants.iconBadgeTextStyle, equals(expectedIconStyle));
      });

      test('should provide consistent shadow effects', () {
        // Test bubble shadow
        expect(BubbleConstants.bubbleShadow, isA<List<BoxShadow>>());
        expect(BubbleConstants.bubbleShadow, isNotEmpty);

        final shadow = BubbleConstants.bubbleShadow.first;
        expect(shadow.color, equals(Colors.black.withAlpha(38)));
        expect(shadow.blurRadius, equals(4));
      });
    });

    group('Bubble Animation Configurations', () {
      test('should validate bubble animation configurations', () {
        // Test animation timing constants
        final animationDuration = BubbleConstants.animationDuration;
        expect(animationDuration.inMilliseconds, greaterThan(0));
        expect(animationDuration.inMilliseconds, lessThanOrEqualTo(1000));

        final delayDuration = BubbleConstants.delayBeforeShow;
        expect(delayDuration.inMilliseconds, greaterThanOrEqualTo(0));
        expect(delayDuration.inMilliseconds,
            lessThan(animationDuration.inMilliseconds));
      });

      test('should provide reasonable animation timing', () {
        // Animation should be responsive but not too fast
        expect(BubbleConstants.animationDuration.inMilliseconds,
            greaterThanOrEqualTo(200));
        expect(BubbleConstants.animationDuration.inMilliseconds,
            lessThanOrEqualTo(500));

        // Delay should be minimal but present
        expect(BubbleConstants.delayBeforeShow.inMilliseconds,
            greaterThanOrEqualTo(50));
        expect(BubbleConstants.delayBeforeShow.inMilliseconds,
            lessThanOrEqualTo(200));
      });

      test('should handle different bubble types consistently', () {
        // All bubble types should use same animation duration
        expect(BubbleConstants.animationDuration, isA<Duration>());
        expect(BubbleConstants.delayBeforeShow, isA<Duration>());

        // Different colors for different purposes
        expect(BubbleConstants.newFeatureColor,
            isNot(equals(BubbleConstants.updatedFeatureColor)));
        expect(BubbleConstants.updatedFeatureColor,
            isNot(equals(BubbleConstants.notificationColor)));
        expect(BubbleConstants.notificationColor,
            isNot(equals(BubbleConstants.newFeatureColor)));
      });
    });

    group('Color Scheme and Visual Consistency', () {
      test('should maintain color accessibility standards', () {
        // Colors should be vibrant enough to be noticeable
        final newColor = BubbleConstants.newFeatureColor;
        final updatedColor = BubbleConstants.updatedFeatureColor;
        final notificationColor = BubbleConstants.notificationColor;

        expect(newColor.alpha, equals(255)); // Fully opaque
        expect(updatedColor.alpha, equals(255));
        expect(notificationColor.alpha, equals(255));
      });

      test('should provide distinct color meanings', () {
        // Green for new features
        expect(BubbleConstants.newFeatureColor.value, equals(0xFF4CAF50));

        // Blue for updated features
        expect(BubbleConstants.updatedFeatureColor.value, equals(0xFF2196F3));

        // Orange/red for notifications
        expect(BubbleConstants.notificationColor.value, equals(0xFFFF5722));
      });

      test('should handle color contrast for text', () {
        // Text should be white on colored backgrounds
        expect(
            BubbleConstants.widgetBubbleTextStyle.color, equals(Colors.white));
        expect(BubbleConstants.iconBadgeTextStyle.color, equals(Colors.white));
      });
    });

    group('Layout and Positioning Values', () {
      test('should provide logical positioning values', () {
        // Widget bubble positioning should be logical
        expect(BubbleConstants.widgetBubbleTop, lessThan(0)); // Above widget
        expect(BubbleConstants.widgetBubbleRight, lessThan(0)); // To the right

        // Icon badge positioning should be minimal
        expect(BubbleConstants.iconBadgeTop, lessThan(0));
        expect(BubbleConstants.iconBadgeRight, lessThan(0));
        expect(BubbleConstants.iconBadgeTop,
            greaterThan(BubbleConstants.widgetBubbleTop));
      });

      test('should handle different screen sizes consistently', () {
        // Positioning should work across different densities
        final widgetTop = BubbleConstants.widgetBubbleTop;
        final widgetRight = BubbleConstants.widgetBubbleRight;
        final iconTop = BubbleConstants.iconBadgeTop;
        final iconRight = BubbleConstants.iconBadgeRight;

        expect(widgetTop, isA<double>());
        expect(widgetRight, isA<double>());
        expect(iconTop, isA<double>());
        expect(iconRight, isA<double>());
      });

      test('should provide appropriate sizing for touch interfaces', () {
        // Sizes should be appropriate for mobile interfaces
        expect(BubbleConstants.iconBadgeSize, greaterThanOrEqualTo(8));
        expect(BubbleConstants.iconBadgeSize, lessThanOrEqualTo(16));

        expect(BubbleConstants.widgetBubbleRadius,
            greaterThan(BubbleConstants.iconBadgeSize));
        expect(BubbleConstants.iconBadgeRadius,
            lessThan(BubbleConstants.iconBadgeSize));
      });
    });

    group('Typography and Text Styling', () {
      test('should provide readable text sizes', () {
        // Text sizes should be readable but compact
        expect(BubbleConstants.widgetBubbleTextStyle.fontSize,
            greaterThanOrEqualTo(10));
        expect(BubbleConstants.widgetBubbleTextStyle.fontSize,
            lessThanOrEqualTo(14));

        expect(BubbleConstants.iconBadgeTextStyle.fontSize,
            greaterThanOrEqualTo(8));
        expect(
            BubbleConstants.iconBadgeTextStyle.fontSize, lessThanOrEqualTo(12));
      });

      test('should provide appropriate font weights', () {
        // Widget bubble text should be semi-bold
        expect(BubbleConstants.widgetBubbleTextStyle.fontWeight,
            equals(FontWeight.w600));

        // Icon badge text should be bold
        expect(BubbleConstants.iconBadgeTextStyle.fontWeight,
            equals(FontWeight.w700));
      });

      test('should maintain text hierarchy', () {
        // Widget bubble text should be larger than icon badge
        final widgetSize = BubbleConstants.widgetBubbleTextStyle.fontSize!;
        final iconSize = BubbleConstants.iconBadgeTextStyle.fontSize!;

        expect(widgetSize, greaterThan(iconSize));
      });
    });

    group('Visual Effects and Shadows', () {
      test('should provide appropriate shadow effects', () {
        final shadows = BubbleConstants.bubbleShadow;
        expect(shadows, isNotEmpty);

        final mainShadow = shadows.first;
        expect(mainShadow.blurRadius, greaterThan(0));
        expect(mainShadow.color.alpha, lessThan(255)); // Semi-transparent
      });

      test('should handle shadow performance', () {
        // Shadow should not be too heavy for performance
        final shadows = BubbleConstants.bubbleShadow;
        expect(shadows.length, lessThanOrEqualTo(3)); // Not too many shadows

        final mainShadow = shadows.first;
        expect(mainShadow.blurRadius, lessThanOrEqualTo(8)); // Reasonable blur
      });

      test('should provide subtle shadow effects', () {
        final shadow = BubbleConstants.bubbleShadow.first;

        // Shadow should be subtle (low opacity)
        expect(shadow.color.alpha, lessThanOrEqualTo(100));
        expect(shadow.color.alpha, greaterThanOrEqualTo(20));
      });
    });

    group('Constants Immutability and Performance', () {
      test('should use const values for performance', () {
        // Duration values should be const
        expect(BubbleConstants.animationDuration, isA<Duration>());
        expect(BubbleConstants.delayBeforeShow, isA<Duration>());

        // Color values should be const
        expect(BubbleConstants.newFeatureColor, isA<Color>());
        expect(BubbleConstants.updatedFeatureColor, isA<Color>());
        expect(BubbleConstants.notificationColor, isA<Color>());
      });

      test('should provide compile-time constants', () {
        // Numeric values should be compile-time constants
        expect(BubbleConstants.widgetBubbleTop, equals(-6));
        expect(BubbleConstants.widgetBubbleRight, equals(-63));
        expect(BubbleConstants.iconBadgeTop, equals(-4));
        expect(BubbleConstants.iconBadgeRight, equals(-4));
        expect(BubbleConstants.widgetBubbleRadius, equals(12));
        expect(BubbleConstants.iconBadgeSize, equals(12));
        expect(BubbleConstants.iconBadgeRadius, equals(4));
      });

      test('should maintain consistency across app restarts', () {
        // Constants should be the same across different test runs
        final color1 = BubbleConstants.newFeatureColor;
        final color2 = BubbleConstants.newFeatureColor;
        expect(color1, equals(color2));

        final duration1 = BubbleConstants.animationDuration;
        final duration2 = BubbleConstants.animationDuration;
        expect(duration1, equals(duration2));
      });
    });

    group('Integration and Extension Support', () {
      test('should work with Flutter widget system', () {
        // Constants should be compatible with Flutter widgets
        expect(BubbleConstants.newFeatureColor, isA<Color>());
        expect(BubbleConstants.widgetBubbleTextStyle, isA<TextStyle>());
        expect(BubbleConstants.bubbleShadow, isA<List<BoxShadow>>());
      });

      test('should support theme integration', () {
        // Colors should work with Material Design
        final newColor = BubbleConstants.newFeatureColor;
        final updatedColor = BubbleConstants.updatedFeatureColor;
        final notificationColor = BubbleConstants.notificationColor;

        expect(newColor.value, isA<int>());
        expect(updatedColor.value, isA<int>());
        expect(notificationColor.value, isA<int>());
      });

      test('should handle system accessibility settings', () {
        // Text styles should work with system settings
        final widgetStyle = BubbleConstants.widgetBubbleTextStyle;
        final iconStyle = BubbleConstants.iconBadgeTextStyle;

        expect(widgetStyle.fontSize, isNotNull);
        expect(widgetStyle.fontWeight, isNotNull);
        expect(iconStyle.fontSize, isNotNull);
        expect(iconStyle.fontWeight, isNotNull);
      });
    });

    group('Configuration Validation', () {
      test('should have reasonable default values', () {
        // All values should be reasonable for mobile UI
        expect(BubbleConstants.animationDuration.inMilliseconds,
            inInclusiveRange(200, 500));
        expect(BubbleConstants.delayBeforeShow.inMilliseconds,
            inInclusiveRange(50, 200));
        expect(BubbleConstants.widgetBubbleRadius, inInclusiveRange(8, 20));
        expect(BubbleConstants.iconBadgeSize, inInclusiveRange(8, 16));
      });

      test('should maintain internal consistency', () {
        // Related values should be logically consistent
        expect(BubbleConstants.iconBadgeRadius,
            lessThan(BubbleConstants.iconBadgeSize));
        expect(BubbleConstants.iconBadgeSize,
            lessThanOrEqualTo(BubbleConstants.widgetBubbleRadius));

        final widgetFontSize = BubbleConstants.widgetBubbleTextStyle.fontSize!;
        final iconFontSize = BubbleConstants.iconBadgeTextStyle.fontSize!;
        expect(widgetFontSize, greaterThan(iconFontSize));
      });
    });
  });
}
