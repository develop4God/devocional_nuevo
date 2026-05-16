// lib/services/i_google_drive_auth_service.dart
//
// Abstract interface for [GoogleDriveAuthService].
// Depend on this interface (not the concrete class) for
// Dependency Inversion and easy test mocking.

import 'package:googleapis/drive/v3.dart' as drive show DriveApi;
import 'package:http/http.dart' as http;

/// Abstract interface defining Google Drive authentication service capabilities.
abstract class IGoogleDriveAuthService {
  /// Check if user is currently signed in to Google Drive.
  Future<bool> isSignedIn();

  /// Sign in to Google Drive. Returns true on success, null if cancelled, false on error.
  Future<bool?> signIn();

  /// Sign out from Google Drive.
  Future<void> signOut();

  /// Get current user email.
  Future<String?> getUserEmail();

  /// Get authenticated HTTP client for Google APIs.
  Future<http.Client?> getAuthClient();

  /// Get Drive API instance.
  Future<drive.DriveApi?> getDriveApi();

  /// Dispose resources.
  void dispose();
}
