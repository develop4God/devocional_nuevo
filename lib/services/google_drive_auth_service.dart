// lib/services/google_drive_auth_service.dart
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing Google Drive authentication
class GoogleDriveAuthService {
  static const List<String> _scopes = [
    drive.DriveApi.driveFileScope,
    drive.DriveApi.driveScope,
  ];

  static const String _isSignedInKey = 'google_drive_signed_in';
  static const String _userEmailKey = 'google_drive_user_email';

  GoogleSignIn? _googleSignIn;
  GoogleSignInAccount? _currentUser;
  AuthClient? _authClient;

  GoogleDriveAuthService() {
    _googleSignIn = GoogleSignIn(
      scopes: _scopes,
    );
  }

  /// Check if user is currently signed in to Google Drive
  Future<bool> isSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isSignedIn = prefs.getBool(_isSignedInKey) ?? false;

    if (isSignedIn && _googleSignIn != null) {
      // Try to sign in silently
      try {
        _currentUser = await _googleSignIn!.signInSilently();
        return _currentUser != null;
      } catch (e) {
        debugPrint('Silent sign-in failed: $e');
        await _clearSignInState();
        return false;
      }
    }

    return false;
  }

  /// Sign in to Google Drive
  Future<bool> signIn() async {
    try {
      if (_googleSignIn == null) {
        throw Exception('Google Sign-In not initialized');
      }

      _currentUser = await _googleSignIn!.signIn();

      if (_currentUser != null) {
        final auth = await _currentUser!.authentication;

        // Check if we have valid tokens
        if (auth.accessToken == null) {
          debugPrint(
              'Google Sign-In error: No access token received. Check OAuth configuration.');
          throw Exception(
              'OAuth not configured. Please check google-services.json has OAuth clients.');
        }

        _authClient = authenticatedClient(
          http.Client(),
          AccessCredentials(
            AccessToken(
              'Bearer',
              auth.accessToken!,
              DateTime.now().add(const Duration(hours: 1)),
            ),
            auth.idToken,
            _scopes,
          ),
        );

        // Save sign-in state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isSignedInKey, true);
        await prefs.setString(_userEmailKey, _currentUser!.email);

        debugPrint('Google Drive sign-in successful: ${_currentUser!.email}');
        return true;
      }

      debugPrint('Google Sign-In cancelled by user');
      return false;
    } catch (e) {
      debugPrint('Google Drive sign-in error: $e');

      // Provide more specific error context
      if (e.toString().contains('OAuth') ||
          e.toString().contains('client') ||
          e.toString().contains('CONFIGURATION_NOT_FOUND')) {
        debugPrint(
            'OAuth Configuration Issue: Ensure google-services.json contains OAuth clients for Google Sign-In');
      }

      await _clearSignInState();
      return false;
    }
  }

  /// Sign out from Google Drive
  Future<void> signOut() async {
    try {
      if (_googleSignIn != null) {
        await _googleSignIn!.signOut();
      }

      _currentUser = null;
      _authClient?.close();
      _authClient = null;

      await _clearSignInState();

      debugPrint('Google Drive sign-out successful');
    } catch (e) {
      debugPrint('Google Drive sign-out error: $e');
    }
  }

  /// Get current user email
  Future<String?> getUserEmail() async {
    if (_currentUser != null) {
      return _currentUser!.email;
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  /// Get authenticated client for Google APIs
  Future<AuthClient?> getAuthClient() async {
    if (_authClient != null) {
      return _authClient;
    }

    // Try to refresh authentication
    if (await isSignedIn()) {
      return _authClient;
    }

    return null;
  }

  /// Clear sign-in state
  Future<void> _clearSignInState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isSignedInKey);
    await prefs.remove(_userEmailKey);
  }

  /// Get Drive API instance
  Future<drive.DriveApi?> getDriveApi() async {
    final authClient = await getAuthClient();
    if (authClient != null) {
      return drive.DriveApi(authClient);
    }
    return null;
  }

  /// Dispose resources
  void dispose() {
    _authClient?.close();
  }
}
