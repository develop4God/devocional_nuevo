@Tags(['unit', 'services'])
library;

import 'package:devocional_nuevo/services/backup/google_drive_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('GoogleDriveAuthService', () {
    late GoogleDriveAuthService service;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = GoogleDriveAuthService(prefs: prefs);
    });

    // ── isSignedIn ──────────────────────────────────────────────────────────

    test('isSignedIn returns false when prefs key is absent', () async {
      expect(await service.isSignedIn(), isFalse);
    });

    test('isSignedIn returns true when prefs key is set to true', () async {
      await prefs.setBool('google_drive_signed_in', true);
      expect(await service.isSignedIn(), isTrue);
    });

    // ── getUserEmail ────────────────────────────────────────────────────────

    test('getUserEmail returns null when no email stored', () async {
      expect(await service.getUserEmail(), isNull);
    });

    test('getUserEmail returns stored email from prefs', () async {
      await prefs.setString('google_drive_user_email', 'test@example.com');
      expect(await service.getUserEmail(), equals('test@example.com'));
    });

    // ── getAuthClient ───────────────────────────────────────────────────────

    test('getAuthClient returns null when user is not signed in', () async {
      // No sign-in state → should return null without hanging
      expect(await service.getAuthClient(), isNull);
    });

    // ── dispose ─────────────────────────────────────────────────────────────

    test('dispose does not throw when no auth client is active', () {
      expect(() => service.dispose(), returnsNormally);
    });

    // ── constructor ─────────────────────────────────────────────────────────

    test('constructor accepts SharedPreferences and creates a new instance',
        () {
      final second = GoogleDriveAuthService(prefs: prefs);
      // Plain class — locator controls singleton; each call is a distinct object
      expect(second, isA<GoogleDriveAuthService>());
    });
  });
}
