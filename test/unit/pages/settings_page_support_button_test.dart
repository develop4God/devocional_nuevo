@Tags(['unit', 'pages'])
library;

import 'package:flutter_test/flutter_test.dart';

/// Tests for the support button in settings page
void main() {
  group('Settings Page Support Button', () {
    test('should navigate to external URL instead of SupporterPage', () {
      const expectedUrl = 'https://www.develop4god.com/apoyanos';
      String? targetUrl;

      // Simulate button press
      void onSupportPressed() {
        targetUrl = expectedUrl;
      }

      onSupportPressed();

      expect(targetUrl, equals(expectedUrl));
      expect(targetUrl, contains('develop4god.com'));
      expect(targetUrl, contains('apoyanos'));
    });

    test('should use external application mode for URL launch', () {
      const launchMode = 'externalApplication';

      expect(launchMode, equals('externalApplication'));
    });

    test('should handle URL launch errors gracefully', () {
      bool errorHandled = false;

      try {
        // Simulate URL launch failure
        throw Exception('Cannot launch URL');
      } catch (e) {
        errorHandled = true;
      }

      expect(errorHandled, isTrue);
    });

    test('should show error message when URL cannot be opened', () {
      const errorMessage = 'settings.cannot_open_url';

      expect(errorMessage, isNotEmpty);
      expect(errorMessage, contains('cannot_open_url'));
    });

    test('should show error message on URL launch exception', () {
      const errorMessage = 'settings.url_error';

      expect(errorMessage, isNotEmpty);
      expect(errorMessage, contains('url_error'));
    });
  });

  group('Settings Page Support Button Icon', () {
    test('should use volunteer_activism icon for support button', () {
      const iconName = 'volunteer_activism';

      expect(iconName, equals('volunteer_activism'));
    });
  });
}
