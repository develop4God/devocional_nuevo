// test/unit/services/google_drive_auth_service_optimized_test.dart
import 'package:devocional_nuevo/services/google_drive_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('GoogleDriveAuthService Tests', () {
    late GoogleDriveAuthService service;

    setUp(() {
      // Setup clean SharedPreferences state for each test
      SharedPreferences.setMockInitialValues({});
      service = GoogleDriveAuthService();
    });

    group('isSignedIn', () {
      test('should return true when user is signed in', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'google_drive_signed_in': true,
        });
        service = GoogleDriveAuthService();

        // Act
        final result = await service.isSignedIn();

        // Assert
        expect(result, isTrue);
      });

      test('should return false when user is not signed in', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'google_drive_signed_in': false,
        });
        service = GoogleDriveAuthService();

        // Act
        final result = await service.isSignedIn();

        // Assert
        expect(result, isFalse);
      });

      test('should return false when no sign-in status is saved', () async {
        // Arrange - Empty preferences
        SharedPreferences.setMockInitialValues({});
        service = GoogleDriveAuthService();

        // Act
        final result = await service.isSignedIn();

        // Assert
        expect(result, isFalse);
      });

      test('should handle multiple calls consistently', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'google_drive_signed_in': true,
        });
        service = GoogleDriveAuthService();

        // Act - Multiple calls
        final result1 = await service.isSignedIn();
        final result2 = await service.isSignedIn();

        // Assert - Both calls should return the same result
        expect(result1, equals(result2));
        expect(result1, isTrue);
      });
    });

    group('getUserEmail', () {
      test('should return saved email when available', () async {
        // Arrange
        const testEmail = 'test@example.com';
        SharedPreferences.setMockInitialValues({
          'google_drive_user_email': testEmail,
        });
        service = GoogleDriveAuthService();

        // Act
        final result = await service.getUserEmail();

        // Assert
        expect(result, equals(testEmail));
      });

      test('should return null when no email is saved', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        service = GoogleDriveAuthService();

        // Act
        final result = await service.getUserEmail();

        // Assert
        expect(result, isNull);
      });

      test('should handle various email formats', () async {
        final testEmails = [
          'user@gmail.com',
          'test.user@domain.co.uk',
          'simple@test.org',
        ];

        for (final email in testEmails) {
          // Arrange
          SharedPreferences.setMockInitialValues({
            'google_drive_user_email': email,
          });
          service = GoogleDriveAuthService();

          // Act
          final result = await service.getUserEmail();

          // Assert
          expect(result, equals(email));
        }
      });

      test('should return empty string when email is empty', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'google_drive_user_email': '',
        });
        service = GoogleDriveAuthService();

        // Act
        final result = await service.getUserEmail();

        // Assert
        expect(result, equals(''));
      });
    });

    group('signOut', () {
      test('should complete successfully when user is signed in', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'google_drive_signed_in': true,
          'google_drive_user_email': 'user@example.com',
        });
        service = GoogleDriveAuthService();

        // Act & Assert - Should complete without error
        await expectLater(service.signOut(), completes);
      });

      test('should handle signOut when user is not signed in', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'google_drive_signed_in': false,
        });
        service = GoogleDriveAuthService();

        // Act & Assert - Should complete without error
        await expectLater(service.signOut(), completes);
      });

      test('should handle signOut with empty preferences', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        service = GoogleDriveAuthService();

        // Act & Assert - Should complete without error
        await expectLater(service.signOut(), completes);
      });

      test('should be callable multiple times safely', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'google_drive_signed_in': true,
        });
        service = GoogleDriveAuthService();

        // Act - Multiple signOut calls
        await service.signOut();
        await service.signOut();
        await service.signOut();

        // Assert - Should complete without issues
        expect(true, isTrue); // Test passes if no exceptions thrown
      });
    });

    group('SharedPreferences integration', () {
      test('should use correct keys for data storage', () async {
        // Arrange
        const testEmail = 'integration@test.com';
        SharedPreferences.setMockInitialValues({
          'google_drive_signed_in': true,
          'google_drive_user_email': testEmail,
        });
        service = GoogleDriveAuthService();

        // Act
        final isSignedIn = await service.isSignedIn();
        final email = await service.getUserEmail();

        // Assert
        expect(isSignedIn, isTrue);
        expect(email, equals(testEmail));

        // Verify keys are being accessed correctly
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('google_drive_signed_in'), isTrue);
        expect(prefs.getString('google_drive_user_email'), equals(testEmail));
      });

      test('should handle missing preference keys gracefully', () async {
        // Arrange - Only one key present
        SharedPreferences.setMockInitialValues({
          'google_drive_signed_in': true,
          // Missing google_drive_user_email key
        });
        service = GoogleDriveAuthService();

        // Act
        final isSignedIn = await service.isSignedIn();
        final email = await service.getUserEmail();

        // Assert
        expect(isSignedIn, isTrue);
        expect(email, isNull); // Should handle missing key gracefully
      });
    });

    group('service lifecycle', () {
      test('should maintain consistent state across service instances',
          () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'google_drive_signed_in': true,
          'google_drive_user_email': 'lifecycle@test.com',
        });

        final service1 = GoogleDriveAuthService();
        final service2 = GoogleDriveAuthService();

        // Act
        final signedIn1 = await service1.isSignedIn();
        final signedIn2 = await service2.isSignedIn();
        final email1 = await service1.getUserEmail();
        final email2 = await service2.getUserEmail();

        // Assert - Both instances should see the same data
        expect(signedIn1, equals(signedIn2));
        expect(email1, equals(email2));
        expect(signedIn1, isTrue);
        expect(email1, equals('lifecycle@test.com'));
      });

      test('should handle rapid sequential operations', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'google_drive_signed_in': true,
          'google_drive_user_email': 'rapid@test.com',
        });
        service = GoogleDriveAuthService();

        // Act - Rapid operations
        final futures = <Future>[];
        for (int i = 0; i < 5; i++) {
          futures.add(service.isSignedIn());
          futures.add(service.getUserEmail());
        }

        // Assert - All should complete successfully
        final results = await Future.wait(futures);
        expect(results.length, equals(10));

        // Verify consistency
        for (int i = 0; i < results.length; i += 2) {
          expect(results[i], isTrue); // isSignedIn results
          expect(
              results[i + 1], equals('rapid@test.com')); // getUserEmail results
        }
      });
    });

    group('performance', () {
      test('should complete basic operations quickly', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'google_drive_signed_in': true,
          'google_drive_user_email': 'performance@test.com',
        });
        service = GoogleDriveAuthService();

        // Act - Time the operations
        final stopwatch = Stopwatch()..start();

        await service.isSignedIn();
        await service.getUserEmail();

        stopwatch.stop();

        // Assert - Should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(50),
            reason: 'Basic operations took ${stopwatch.elapsedMilliseconds}ms');
      });

      test('should handle multiple operations efficiently', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'google_drive_signed_in': true,
          'google_drive_user_email': 'efficient@test.com',
        });
        service = GoogleDriveAuthService();

        // Act - Multiple operations
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 10; i++) {
          await service.isSignedIn();
          await service.getUserEmail();
        }

        stopwatch.stop();

        // Assert - Should complete efficiently
        expect(stopwatch.elapsedMilliseconds, lessThan(200),
            reason: '20 operations took ${stopwatch.elapsedMilliseconds}ms');
      });
    });
  });
}
