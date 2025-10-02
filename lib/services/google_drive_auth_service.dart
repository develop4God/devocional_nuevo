// lib/services/google_drive_auth_service.dart
import 'package:flutter/foundation.dart';
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
  bool _isRecreatingAuthClient = false;

  GoogleDriveAuthService() {
    debugPrint('🔧 [DEBUG] GoogleDriveAuthService constructor iniciado');
    _googleSignIn = GoogleSignIn(scopes: _scopes);
    debugPrint('🔧 [DEBUG] GoogleSignIn inicializado con scopes: $_scopes');
    debugPrint('🔧 [DEBUG] GoogleSignIn clientId: ${_googleSignIn?.clientId}');
  }

  /// Check if user is currently signed in to Google Drive
  Future<bool> isSignedIn() async {
    debugPrint('🔍 [DEBUG] Verificando si usuario está signed in...');
    final prefs = await SharedPreferences.getInstance();
    final isSignedIn = prefs.getBool(_isSignedInKey) ?? false;
    debugPrint('🔍 [DEBUG] Estado guardado en SharedPreferences: $isSignedIn');
    debugPrint('🔍 [DEBUG] isSignedIn resultado final: $isSignedIn');
    return isSignedIn;
  }

  /// Sign in to Google Drive
  Future<bool?> signIn() async {
    debugPrint('🔑 [DEBUG] ===== INICIANDO SIGN IN =====');
    debugPrint('🔑 [DEBUG] GoogleSignIn es null: ${_googleSignIn == null}');
    try {
      if (_googleSignIn == null) {
        debugPrint('❌ [DEBUG] GoogleSignIn no inicializado');
        throw Exception('Google Sign-In not initialized');
      }

      debugPrint('🔑 [DEBUG] Llamando a _googleSignIn.signIn()...');
      debugPrint('🔑 [DEBUG] Scopes configurados: ${_googleSignIn!.scopes}');
      debugPrint('🔑 [DEBUG] ClientId: ${_googleSignIn!.clientId}');

      _currentUser = await _googleSignIn!.signIn();
      debugPrint('🔑 [DEBUG] _googleSignIn.signIn() completado');
      debugPrint('🔑 [DEBUG] _currentUser: ${_currentUser?.email}');
      debugPrint('🔑 [DEBUG] _currentUser ID: ${_currentUser?.id}');
      debugPrint(
        '🔑 [DEBUG] _currentUser displayName: ${_currentUser?.displayName}',
      );

      if (_currentUser != null) {
        debugPrint('🔑 [DEBUG] Usuario obtenido, obteniendo authentication...');
        final auth = await _currentUser!.authentication;
        debugPrint('🔑 [DEBUG] Authentication obtenido');
        debugPrint(
          '🔑 [DEBUG] AccessToken existe: ${auth.accessToken != null}',
        );
        debugPrint('🔑 [DEBUG] IdToken existe: ${auth.idToken != null}');

        // Check if we have valid tokens
        if (auth.accessToken == null) {
          debugPrint(
            '❌ [DEBUG] No access token recibido - problema de configuración OAuth',
          );
          debugPrint(
            'Google Sign-In error: No access token received. Check OAuth configuration.',
          );
          throw Exception(
            'OAuth not configured. Please check google-services.json has OAuth clients.',
          );
        }

        debugPrint('🔑 [DEBUG] Creando AuthClient...');
        _authClient = authenticatedClient(
          http.Client(),
          AccessCredentials(
            AccessToken(
              'Bearer',
              auth.accessToken!,
              DateTime.now().toUtc().add(const Duration(hours: 1)),
            ),
            auth.idToken,
            _scopes,
          ),
        );
        debugPrint('🔑 [DEBUG] AuthClient creado exitosamente');

        // Save sign-in state
        debugPrint('🔑 [DEBUG] Guardando estado en SharedPreferences...');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isSignedInKey, true);
        await prefs.setString(_userEmailKey, _currentUser!.email);
        debugPrint('🔑 [DEBUG] Estado guardado en SharedPreferences');

        debugPrint(
          '✅ [DEBUG] Google Drive sign-in successful: ${_currentUser!.email}',
        );
        return true;
      }

      debugPrint('❌ [DEBUG] _currentUser es null - usuario canceló el sign in');
      debugPrint('Google Sign-In cancelled by user');
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ [DEBUG] ===== ERROR EN SIGN IN =====');
      debugPrint('❌ [DEBUG] Error: $e');
      debugPrint('❌ [DEBUG] Tipo de error: ${e.runtimeType}');
      debugPrint('❌ [DEBUG] StackTrace: $stackTrace');
      debugPrint('Google Drive sign-in error: $e');

      // Provide more specific error context
      if (e.toString().contains('OAuth') ||
          e.toString().contains('client') ||
          e.toString().contains('CONFIGURATION_NOT_FOUND')) {
        debugPrint('❌ [DEBUG] ERROR DE CONFIGURACIÓN OAUTH DETECTADO');
        debugPrint(
          'OAuth Configuration Issue: Ensure google-services.json contains OAuth clients for Google Sign-In',
        );
      }

      if (e.toString().contains('ApiException: 10')) {
        debugPrint(
          '❌ [DEBUG] DEVELOPER_ERROR (10) - Problema de configuración',
        );
        debugPrint('❌ [DEBUG] Posibles causas:');
        debugPrint(
          '❌ [DEBUG] 1. SHA-1 fingerdebugPrint no configurado en Google Console',
        );
        debugPrint('❌ [DEBUG] 2. Package name incorrecto');
        debugPrint('❌ [DEBUG] 3. google-services.json mal configurado');
      }

      await _clearSignInState();
      return false;
    }
  }

  /// Sign out from Google Drive
  Future<void> signOut() async {
    debugPrint('🔓 [DEBUG] Iniciando sign out...');
    try {
      if (_googleSignIn != null) {
        debugPrint('🔓 [DEBUG] Llamando _googleSignIn.signOut()...');
        await _googleSignIn!.signOut();
        debugPrint('🔓 [DEBUG] _googleSignIn.signOut() completado');
      }

      _currentUser = null;
      _authClient?.close();
      _authClient = null;

      debugPrint('🔓 [DEBUG] Limpiando estado...');
      await _clearSignInState();
      debugPrint('✅ [DEBUG] Google Drive sign-out successful');
    } catch (e) {
      debugPrint('❌ [DEBUG] Google Drive sign-out error: $e');
    }
  }

  /// Get current user email
  Future<String?> getUserEmail() async {
    debugPrint('👤 [DEBUG] Obteniendo user email...');
    if (_currentUser != null) {
      debugPrint('👤 [DEBUG] Email desde _currentUser: ${_currentUser!.email}');
      return _currentUser!.email;
    }

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_userEmailKey);
    debugPrint('👤 [DEBUG] Email desde SharedPreferences: $email');
    return email;
  }

  /// Get authenticated client for Google APIs
  Future<AuthClient?> getAuthClient() async {
    debugPrint('🔐 [DEBUG] Obteniendo AuthClient...');

    if (_authClient != null) {
      debugPrint('🔐 [DEBUG] AuthClient ya existe');
      return _authClient;
    }
    // ← NUEVA PROTECCIÓN: Si ya está recreando, esperar
    if (_isRecreatingAuthClient) {
      debugPrint('🔐 [DEBUG] Recreación ya en progreso, esperando...');
      await Future.delayed(const Duration(milliseconds: 50));
      return getAuthClient(); // Reintentar después de esperar
    }

    debugPrint(
      '🔐 [DEBUG] AuthClient no existe, verificando si está signed in...',
    );

    // If user is signed in but _authClient is null, try to recreate it
    if (await isSignedIn()) {
      _isRecreatingAuthClient = true;
      debugPrint(
        '🔄 [DEBUG] Usuario signed in pero AuthClient es null, intentando recrear...',
      );

      try {
        // Try to sign in silently to recreate the auth client
        if (_googleSignIn == null) {
          debugPrint('❌ [DEBUG] GoogleSignIn no inicializado para recreación');
          await _clearSignInState();
          return null;
        }

        final GoogleSignInAccount? googleUser =
            await _googleSignIn!.signInSilently();

        if (googleUser != null) {
          debugPrint('🔄 [DEBUG] signInSilently exitoso: ${googleUser.email}');
          _currentUser = googleUser;

          final GoogleSignInAuthentication googleAuth =
              await googleUser.authentication;

          if (googleAuth.accessToken != null) {
            debugPrint(
              '🔄 [DEBUG] Access token obtenido, recreando AuthClient...',
            );

            final credentials = AccessCredentials(
              AccessToken(
                'Bearer',
                googleAuth.accessToken!,
                DateTime.now().toUtc().add(const Duration(hours: 1)),
              ),
              googleAuth.idToken,
              _scopes,
            );

            _authClient = authenticatedClient(http.Client(), credentials);
            debugPrint('✅ [DEBUG] AuthClient recreado exitosamente');
            return _authClient;
          } else {
            debugPrint('❌ [DEBUG] No access token en recreación');
          }
        } else {
          debugPrint('❌ [DEBUG] signInSilently falló - usuario no disponible');
        }
      } catch (e) {
        debugPrint('❌ [DEBUG] Error recreando AuthClient: $e');
      } finally {
        _isRecreatingAuthClient = false; // ← DESACTIVAR FLAG SIEMPRE
      }

      // If recreation failed, clear inconsistent state
      debugPrint('🧹 [DEBUG] Recreación falló, limpiando estado inconsistente');
      await _clearSignInState();
      return null;
    }

    debugPrint('🔐 [DEBUG] Usuario no signed in, devolviendo null');
    return null;
  }

  /// Clear sign-in state
  Future<void> _clearSignInState() async {
    debugPrint('🧹 [DEBUG] Limpiando sign-in state...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isSignedInKey);
    await prefs.remove(_userEmailKey);
    debugPrint('🧹 [DEBUG] Sign-in state limpiado');
  }

  /// Get Drive API instance
  Future<drive.DriveApi?> getDriveApi() async {
    debugPrint('📁 [DEBUG] Obteniendo Drive API...');
    final authClient = await getAuthClient();
    if (authClient != null) {
      debugPrint('📁 [DEBUG] AuthClient obtenido, creando DriveApi...');
      final driveApi = drive.DriveApi(authClient);
      debugPrint('📁 [DEBUG] DriveApi creado exitosamente');
      return driveApi;
    }
    debugPrint('📁 [DEBUG] AuthClient es null, devolviendo null');
    return null;
  }

  /// Dispose resources
  void dispose() {
    debugPrint('🗑️ [DEBUG] Disposing GoogleDriveAuthService...');
    _authClient?.close();
    debugPrint('🗑️ [DEBUG] GoogleDriveAuthService disposed');
  }
}
