// lib/services/google_drive_auth_service.dart
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive show DriveApi;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'i_google_drive_auth_service.dart';

/// Service for managing Google Drive authentication.
///
/// Lifecycle is managed entirely by [ServiceLocator] via
/// `registerLazySingleton<IGoogleDriveAuthService>`.
/// Do NOT instantiate directly outside `service_locator.dart`.
class GoogleDriveAuthService implements IGoogleDriveAuthService {
  /// Constructor — [prefs] injected by the ServiceLocator.
  GoogleDriveAuthService({required SharedPreferences prefs}) : _prefs = prefs {
    debugPrint('🔧 [DEBUG] GoogleDriveAuthService constructor iniciado');
    _googleSignIn = GoogleSignIn(scopes: _scopes);
    debugPrint('🔧 [DEBUG] GoogleSignIn inicializado con scopes: $_scopes');
    debugPrint('🔧 [DEBUG] GoogleSignIn clientId: ${_googleSignIn?.clientId}');
  }

  final SharedPreferences _prefs;

  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/drive.file',
  ];

  static const String _isSignedInKey = 'google_drive_signed_in';
  static const String _userEmailKey = 'google_drive_user_email';

  GoogleSignIn? _googleSignIn;
  GoogleSignInAccount? _currentUser;
  http.Client? _authClient;
  bool _isRecreatingAuthClient = false;

  /// Check if user is currently signed in to Google Drive
  @override
  Future<bool> isSignedIn() async {
    debugPrint('🔍 [DEBUG] Verificando si usuario está signed in...');
    final isSignedIn = _prefs.getBool(_isSignedInKey) ?? false;
    debugPrint('🔍 [DEBUG] Estado guardado en SharedPreferences: $isSignedIn');
    debugPrint('🔍 [DEBUG] isSignedIn resultado final: $isSignedIn');
    return isSignedIn;
  }

  /// Sign in to Google Drive
  @override
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
        debugPrint(
          '🔑 [DEBUG] Usuario obtenido, creando authenticated client...',
        );

        // Use the extension method on GoogleSignIn to get authenticated client
        _authClient = await _googleSignIn!.authenticatedClient();

        if (_authClient == null) {
          debugPrint(
            '❌ [DEBUG] No authenticated client - problema de configuración OAuth',
          );
          throw Exception(
            'OAuth not configured. Please check google-services.json has OAuth clients.',
          );
        }

        debugPrint(
          '🔑 [DEBUG] AuthClient creado exitosamente usando extension',
        );

        // Save sign-in state
        debugPrint('🔑 [DEBUG] Guardando estado en SharedPreferences...');
        await _prefs.setBool(_isSignedInKey, true);
        await _prefs.setString(_userEmailKey, _currentUser!.email);
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
  @override
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
  @override
  Future<String?> getUserEmail() async {
    debugPrint('👤 [DEBUG] Obteniendo user email...');
    if (_currentUser != null) {
      debugPrint('👤 [DEBUG] Email desde _currentUser: ${_currentUser!.email}');
      return _currentUser!.email;
    }

    final email = _prefs.getString(_userEmailKey);
    debugPrint('👤 [DEBUG] Email desde SharedPreferences: $email');
    return email;
  }

  /// Get authenticated client for Google APIs
  @override
  Future<http.Client?> getAuthClient() async {
    debugPrint('🔐 [DEBUG] Obteniendo AuthClient...');

    if (_authClient != null) {
      debugPrint('🔐 [DEBUG] AuthClient ya existe');
      return _authClient;
    }
    // ← NUEVA PROTECCIÓN: Si ya está recreando, esperar con límite de intentos
    if (_isRecreatingAuthClient) {
      debugPrint('🔐 [DEBUG] Recreación ya en progreso, esperando...');
      int attempts = 0;
      while (_isRecreatingAuthClient && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 50));
        attempts++;
      }
      if (_isRecreatingAuthClient) {
        debugPrint('❌ [DEBUG] Timeout esperando recreación de AuthClient');
        return null; // hard exit — never recurse
      }
      return _authClient; // return whatever was set by the concurrent call
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

          // Use the extension method on GoogleSignIn to get authenticated client
          _authClient = await _googleSignIn!.authenticatedClient();

          if (_authClient != null) {
            debugPrint(
              '✅ [DEBUG] AuthClient recreado exitosamente usando extension',
            );
            return _authClient;
          } else {
            debugPrint(
              '❌ [DEBUG] No se pudo crear authenticated client en recreación',
            );
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
    await _prefs.remove(_isSignedInKey);
    await _prefs.remove(_userEmailKey);
    debugPrint('🧹 [DEBUG] Sign-in state limpiado');
  }

  /// Get Drive API instance
  @override
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
  @override
  void dispose() {
    debugPrint('🗑️ [DEBUG] Disposing GoogleDriveAuthService...');
    _authClient?.close();
    debugPrint('🗑️ [DEBUG] GoogleDriveAuthService disposed');
  }
}
