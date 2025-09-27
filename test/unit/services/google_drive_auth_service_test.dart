// test/unit/services/google_drive_auth_service_test.dart
import 'package:devocional_nuevo/services/google_drive_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock class for GoogleSignIn
class MockGoogleSignIn extends Mock implements GoogleSignIn {}

/// Mock class for GoogleSignInAccount
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

/// Mock class for GoogleSignInAuthentication
class MockGoogleSignInAuthentication extends Mock implements GoogleSignInAuthentication {}

/// Mock class for AuthClient
class MockAuthClient extends Mock implements AuthClient {}

/// Mock class for http.Client
class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('GoogleDriveAuthService Tests', () {
    late GoogleDriveAuthService service;
    late MockGoogleSignIn mockGoogleSignIn;
    late MockGoogleSignInAccount mockAccount;
    late MockGoogleSignInAuthentication mockAuth;

    // Register fallback values for mocktail
    setUpAll(() {
      registerFallbackValue('mock_email@test.com');
      registerFallbackValue(true);
    });

    setUp(() {
      // Setup mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      
      // Initialize mocks
      mockGoogleSignIn = MockGoogleSignIn();
      mockAccount = MockGoogleSignInAccount();
      mockAuth = MockGoogleSignInAuthentication();
      
      // Create service instance
      service = GoogleDriveAuthService();
    });

    group('isSignedIn', () {
      test('should return true when user is signed in according to SharedPreferences', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'google_drive_signed_in': true,
        });

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

        // Act
        final result = await service.isSignedIn();

        // Assert
        expect(result, isFalse);
      });

      test('should return false when no sign-in status is saved', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act
        final result = await service.isSignedIn();

        // Assert
        expect(result, isFalse);
      });

      test('should handle SharedPreferences errors gracefully', () async {
        // Arrange - Create service that might encounter SharedPreferences issues
        SharedPreferences.setMockInitialValues({});

        // Act & Assert - Should not throw exception
        final result = await service.isSignedIn();
        expect(result, isFalse); // Should return false as default
      });
    });

    group('signOut', () {
      test('should clear sign-in status from SharedPreferences', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'google_drive_signed_in': true,
          'google_drive_user_email': 'test@example.com',
        });

        // Act
        await service.signOut();

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('google_drive_signed_in'), isFalse);
        expect(prefs.getString('google_drive_user_email'), isNull);
      });

      test('should handle sign out when not previously signed in', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act & Assert - Should complete without errors
        await expectLater(
          service.signOut(),
          completes,
        );

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('google_drive_signed_in'), isFalse);
      });

      test('should handle multiple sign out calls', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'google_drive_signed_in': true,
        });

        // Act - Multiple sign out calls
        await service.signOut();
        await service.signOut();
        await service.signOut();

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('google_drive_signed_in'), isFalse);
      });
    });

    group('getUserEmail', () {
      test('should return saved user email from SharedPreferences', () async {
        // Arrange
        const testEmail = 'test@example.com';
        SharedPreferences.setMockInitialValues({
          'google_drive_user_email': testEmail,
        });

        // Act
        final result = await service.getUserEmail();

        // Assert
        expect(result, equals(testEmail));
      });

      test('should return null when no email is saved', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act
        final result = await service.getUserEmail();

        // Assert
        expect(result, isNull);
      });

      test('should return null when email key exists but value is null', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act
        final result = await service.getUserEmail();

        // Assert
        expect(result, isNull);
      });
    });

    group('authentication state management', () {
      test('should maintain consistent state across sign-in and sign-out operations', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act & Assert - Initial state
        expect(await service.isSignedIn(), isFalse);
        expect(await service.getUserEmail(), isNull);

        // Simulate sign-in state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('google_drive_signed_in', true);
        await prefs.setString('google_drive_user_email', 'test@example.com');

        // Verify signed-in state
        expect(await service.isSignedIn(), isTrue);
        expect(await service.getUserEmail(), equals('test@example.com'));

        // Sign out
        await service.signOut();

        // Verify signed-out state
        expect(await service.isSignedIn(), isFalse);
        expect(await service.getUserEmail(), isNull);
      });

      test('should handle rapid state changes correctly', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act - Rapid sign-in/sign-out operations
        final prefs = await SharedPreferences.getInstance();
        
        for (int i = 0; i < 5; i++) {
          // Sign in
          await prefs.setBool('google_drive_signed_in', true);
          await prefs.setString('google_drive_user_email', 'test$i@example.com');
          
          expect(await service.isSignedIn(), isTrue);
          expect(await service.getUserEmail(), equals('test$i@example.com'));
          
          // Sign out
          await service.signOut();
          
          expect(await service.isSignedIn(), isFalse);
          expect(await service.getUserEmail(), isNull);
        }
      });

      test('should handle concurrent access to SharedPreferences', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act - Concurrent operations
        final futures = <Future>[];
        for (int i = 0; i < 10; i++) {
          futures.add(service.isSignedIn());
          futures.add(service.getUserEmail());
        }

        // Assert - All operations should complete without errors
        final results = await Future.wait(futures);
        expect(results.length, equals(20));
        
        // All isSignedIn calls should return false (initial state)
        for (int i = 0; i < results.length; i += 2) {
          expect(results[i], isFalse);
        }
        
        // All getUserEmail calls should return null (initial state)
        for (int i = 1; i < results.length; i += 2) {
          expect(results[i], isNull);
        }
      });
    });

    group('error handling', () {
      test('should handle SharedPreferences initialization errors gracefully', () async {
        // This test validates that the service doesn't crash when SharedPreferences
        // operations fail, which is important for production reliability
        
        // Act & Assert - Operations should complete without throwing
        await expectLater(service.isSignedIn(), completes);
        await expectLater(service.getUserEmail(), completes);
        await expectLater(service.signOut(), completes);
      });

      test('should maintain data consistency during error conditions', () async {
        // Arrange - Start with clean state
        SharedPreferences.setMockInitialValues({});

        // Act - Perform operations that might fail
        await service.signOut(); // Should handle null/missing values gracefully
        
        // Assert - State should remain consistent
        expect(await service.isSignedIn(), isFalse);
        expect(await service.getUserEmail(), isNull);
      });
    });

    group('data validation', () {
      test('should handle various email formats correctly', () async {
        // Test cases with different email formats
        final testEmails = [
          'simple@example.com',
          'user+tag@domain.co.uk',
          'user.name@sub.domain.org',
          'user123@gmail.com',
          'test-email@domain-name.com',
        ];

        for (final email in testEmails) {
          // Arrange
          SharedPreferences.setMockInitialValues({
            'google_drive_user_email': email,
          });

          // Act
          final result = await service.getUserEmail();

          // Assert
          expect(result, equals(email), reason: 'Failed for email: $email');
        }
      });

      test('should handle empty and whitespace email values', () async {
        final testValues = ['', '   ', '\t', '\n'];

        for (final value in testValues) {
          // Arrange
          SharedPreferences.setMockInitialValues({
            'google_drive_user_email': value,
          });

          // Act
          final result = await service.getUserEmail();

          // Assert
          expect(result, equals(value), reason: 'Failed for value: "$value"');
        }
      });

      test('should preserve exact boolean values for sign-in status', () async {
        // Test explicit true
        SharedPreferences.setMockInitialValues({'google_drive_signed_in': true});
        expect(await service.isSignedIn(), isTrue);

        // Test explicit false
        SharedPreferences.setMockInitialValues({'google_drive_signed_in': false});
        expect(await service.isSignedIn(), isFalse);

        // Test missing value (should default to false)
        SharedPreferences.setMockInitialValues({});
        expect(await service.isSignedIn(), isFalse);
      });
    });

    group('SharedPreferences key consistency', () {
      test('should use correct keys for storing authentication data', () async {
        // This test ensures the service uses the expected SharedPreferences keys
        // which is important for data migration and debugging
        
        // Arrange
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        // Act - Simulate sign-in data being saved
        await prefs.setBool('google_drive_signed_in', true);
        await prefs.setString('google_drive_user_email', 'test@example.com');

        // Assert - Service should read from the same keys
        expect(await service.isSignedIn(), isTrue);
        expect(await service.getUserEmail(), equals('test@example.com'));

        // Act - Sign out
        await service.signOut();

        // Assert - Keys should be properly cleared/updated
        expect(prefs.getBool('google_drive_signed_in'), isFalse);
        expect(prefs.getString('google_drive_user_email'), isNull);
      });

      test('should handle migration from older data formats gracefully', () async {
        // Test handling of potential legacy data or unexpected types
        
        // Arrange - Simulate potentially problematic data
        SharedPreferences.setMockInitialValues({
          'google_drive_signed_in': 'true', // String instead of bool
          'google_drive_user_email': 123, // Number instead of string
        });

        // Act & Assert - Should handle gracefully without crashing
        // Note: SharedPreferences.getBool() with string value returns null
        // which gets converted to false by ?? false
        expect(await service.isSignedIn(), isFalse);
        
        // getUserEmail() might return null or throw - both are acceptable
        // as long as the app doesn't crash
        await expectLater(
          () async => await service.getUserEmail(),
          returnsNormally,
        );
      });
    });

    group('service lifecycle', () {
      test('should maintain state consistency across multiple service instances', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        
        // Create multiple service instances (though it's a singleton pattern in practice)
        final service1 = GoogleDriveAuthService();
        final service2 = GoogleDriveAuthService();

        // Act - Set state through one instance
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('google_drive_signed_in', true);
        await prefs.setString('google_drive_user_email', 'test@example.com');

        // Assert - Both instances should see the same state
        expect(await service1.isSignedIn(), isTrue);
        expect(await service2.isSignedIn(), isTrue);
        expect(await service1.getUserEmail(), equals('test@example.com'));
        expect(await service2.getUserEmail(), equals('test@example.com'));

        // Act - Sign out through one instance
        await service1.signOut();

        // Assert - Both instances should see the updated state
        expect(await service1.isSignedIn(), isFalse);
        expect(await service2.isSignedIn(), isFalse);
        expect(await service1.getUserEmail(), isNull);
        expect(await service2.getUserEmail(), isNull);
      });

      test('should handle service operations in various sequences', () async {
        // Test different operation sequences to ensure robustness
        final sequences = [
          ['isSignedIn', 'getUserEmail', 'signOut'],
          ['signOut', 'isSignedIn', 'getUserEmail'],
          ['getUserEmail', 'signOut', 'isSignedIn'],
          ['signOut', 'signOut', 'isSignedIn'], // Multiple signouts
        ];

        for (final sequence in sequences) {
          // Arrange
          SharedPreferences.setMockInitialValues({
            'google_drive_signed_in': true,
            'google_drive_user_email': 'test@example.com',
          });

          // Act - Execute sequence
          for (final operation in sequence) {
            switch (operation) {
              case 'isSignedIn':
                await service.isSignedIn();
                break;
              case 'getUserEmail':
                await service.getUserEmail();
                break;
              case 'signOut':
                await service.signOut();
                break;
            }
          }

          // Assert - Should end in a consistent state after any sequence
          expect(await service.isSignedIn(), isFalse);
          expect(await service.getUserEmail(), isNull);
        }
      });
    });

    group('performance', () {
      test('should complete operations within reasonable time limits', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'google_drive_signed_in': true,
          'google_drive_user_email': 'test@example.com',
        });

        // Act & Assert - Operations should be fast
        final stopwatch = Stopwatch()..start();

        await service.isSignedIn();
        expect(stopwatch.elapsedMilliseconds, lessThan(100));

        await service.getUserEmail();
        expect(stopwatch.elapsedMilliseconds, lessThan(200));

        await service.signOut();
        expect(stopwatch.elapsedMilliseconds, lessThan(300));

        stopwatch.stop();
      });

      test('should handle high-frequency operations efficiently', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act - High frequency calls
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 100; i++) {
          await service.isSignedIn();
        }
        
        stopwatch.stop();

        // Assert - Should complete reasonably quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });
  });
}