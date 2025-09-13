// lib/services/google_drive_auth_service.dart
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
    print('🔧 [DEBUG] GoogleDriveAuthService constructor iniciado');
    _googleSignIn = GoogleSignIn(
      scopes: _scopes,
    );
    print('🔧 [DEBUG] GoogleSignIn inicializado con scopes: $_scopes');
    print('🔧 [DEBUG] GoogleSignIn clientId: ${_googleSignIn?.clientId}');
  }

  /// Check if user is currently signed in to Google Drive
  Future<bool> isSignedIn() async {
    print('🔍 [DEBUG] Verificando si usuario está signed in...');
    final prefs = await SharedPreferences.getInstance();
    final isSignedIn = prefs.getBool(_isSignedInKey) ?? false;
    print('🔍 [DEBUG] Estado guardado en SharedPreferences: $isSignedIn');
    print('🔍 [DEBUG] isSignedIn resultado final: $isSignedIn');
    return isSignedIn;
  }

  /// Sign in to Google Drive
  Future<bool> signIn() async {
    print('🔑 [DEBUG] ===== INICIANDO SIGN IN =====');
    print('🔑 [DEBUG] GoogleSignIn es null: ${_googleSignIn == null}');
    try {
      if (_googleSignIn == null) {
        print('❌ [DEBUG] GoogleSignIn no inicializado');
        throw Exception('Google Sign-In not initialized');
      }

      print('🔑 [DEBUG] Llamando a _googleSignIn.signIn()...');
      print('🔑 [DEBUG] Scopes configurados: ${_googleSignIn!.scopes}');
      print('🔑 [DEBUG] ClientId: ${_googleSignIn!.clientId}');

      _currentUser = await _googleSignIn!.signIn();
      print('🔑 [DEBUG] _googleSignIn.signIn() completado');
      print('🔑 [DEBUG] _currentUser: ${_currentUser?.email}');
      print('🔑 [DEBUG] _currentUser ID: ${_currentUser?.id}');
      print(
          '🔑 [DEBUG] _currentUser displayName: ${_currentUser?.displayName}');

      if (_currentUser != null) {
        print('🔑 [DEBUG] Usuario obtenido, obteniendo authentication...');
        final auth = await _currentUser!.authentication;
        print('🔑 [DEBUG] Authentication obtenido');
        print('🔑 [DEBUG] AccessToken existe: ${auth.accessToken != null}');
        print('🔑 [DEBUG] IdToken existe: ${auth.idToken != null}');

        // Check if we have valid tokens
        if (auth.accessToken == null) {
          print(
              '❌ [DEBUG] No access token recibido - problema de configuración OAuth');
          print(
              'Google Sign-In error: No access token received. Check OAuth configuration.');
          throw Exception(
              'OAuth not configured. Please check google-services.json has OAuth clients.');
        }

        print('🔑 [DEBUG] Creando AuthClient...');
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
        print('🔑 [DEBUG] AuthClient creado exitosamente');

        // Save sign-in state
        print('🔑 [DEBUG] Guardando estado en SharedPreferences...');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isSignedInKey, true);
        await prefs.setString(_userEmailKey, _currentUser!.email);
        print('🔑 [DEBUG] Estado guardado en SharedPreferences');

        print(
            '✅ [DEBUG] Google Drive sign-in successful: ${_currentUser!.email}');
        return true;
      }

      print('❌ [DEBUG] _currentUser es null - usuario canceló el sign in');
      print('Google Sign-In cancelled by user');
      return false;
    } catch (e, stackTrace) {
      print('❌ [DEBUG] ===== ERROR EN SIGN IN =====');
      print('❌ [DEBUG] Error: $e');
      print('❌ [DEBUG] Tipo de error: ${e.runtimeType}');
      print('❌ [DEBUG] StackTrace: $stackTrace');
      print('Google Drive sign-in error: $e');

      // Provide more specific error context
      if (e.toString().contains('OAuth') ||
          e.toString().contains('client') ||
          e.toString().contains('CONFIGURATION_NOT_FOUND')) {
        print('❌ [DEBUG] ERROR DE CONFIGURACIÓN OAUTH DETECTADO');
        print(
            'OAuth Configuration Issue: Ensure google-services.json contains OAuth clients for Google Sign-In');
      }

      if (e.toString().contains('ApiException: 10')) {
        print('❌ [DEBUG] DEVELOPER_ERROR (10) - Problema de configuración');
        print('❌ [DEBUG] Posibles causas:');
        print(
            '❌ [DEBUG] 1. SHA-1 fingerprint no configurado en Google Console');
        print('❌ [DEBUG] 2. Package name incorrecto');
        print('❌ [DEBUG] 3. google-services.json mal configurado');
      }

      await _clearSignInState();
      return false;
    }
  }

  /// Sign out from Google Drive
  Future<void> signOut() async {
    print('🔓 [DEBUG] Iniciando sign out...');
    try {
      if (_googleSignIn != null) {
        print('🔓 [DEBUG] Llamando _googleSignIn.signOut()...');
        await _googleSignIn!.signOut();
        print('🔓 [DEBUG] _googleSignIn.signOut() completado');
      }

      _currentUser = null;
      _authClient?.close();
      _authClient = null;

      print('🔓 [DEBUG] Limpiando estado...');
      await _clearSignInState();
      print('✅ [DEBUG] Google Drive sign-out successful');
    } catch (e) {
      print('❌ [DEBUG] Google Drive sign-out error: $e');
    }
  }

  /// Get current user email
  Future<String?> getUserEmail() async {
    print('👤 [DEBUG] Obteniendo user email...');
    if (_currentUser != null) {
      print('👤 [DEBUG] Email desde _currentUser: ${_currentUser!.email}');
      return _currentUser!.email;
    }

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_userEmailKey);
    print('👤 [DEBUG] Email desde SharedPreferences: $email');
    return email;
  }

  /// Get authenticated client for Google APIs
  Future<AuthClient?> getAuthClient() async {
    print('🔐 [DEBUG] Obteniendo AuthClient...');

    if (_authClient != null) {
      print('🔐 [DEBUG] AuthClient ya existe');
      return _authClient;
    }

    print('🔐 [DEBUG] AuthClient no existe, verificando si está signed in...');

    // If user is signed in but _authClient is null, try to recreate it
    if (await isSignedIn()) {
      print(
          '🔄 [DEBUG] Usuario signed in pero AuthClient es null, intentando recrear...');

      try {
        // Try to sign in silently to recreate the auth client
        if (_googleSignIn == null) {
          print('❌ [DEBUG] GoogleSignIn no inicializado para recreación');
          await _clearSignInState();
          return null;
        }

        final GoogleSignInAccount? googleUser =
            await _googleSignIn!.signInSilently();

        if (googleUser != null) {
          print('🔄 [DEBUG] signInSilently exitoso: ${googleUser.email}');
          _currentUser = googleUser;

          final GoogleSignInAuthentication googleAuth =
              await googleUser.authentication;

          if (googleAuth.accessToken != null) {
            print('🔄 [DEBUG] Access token obtenido, recreando AuthClient...');

            final credentials = AccessCredentials(
              AccessToken('Bearer', googleAuth.accessToken!,
                  DateTime.now().toUtc().add(const Duration(hours: 1))),
              googleAuth.idToken,
              _scopes,
            );

            _authClient = authenticatedClient(http.Client(), credentials);
            print('✅ [DEBUG] AuthClient recreado exitosamente');
            return _authClient;
          } else {
            print('❌ [DEBUG] No access token en recreación');
          }
        } else {
          print('❌ [DEBUG] signInSilently falló - usuario no disponible');
        }
      } catch (e) {
        print('❌ [DEBUG] Error recreando AuthClient: $e');
      }

      // If recreation failed, clear inconsistent state
      print('🧹 [DEBUG] Recreación falló, limpiando estado inconsistente');
      await _clearSignInState();
      return null;
    }

    print('🔐 [DEBUG] Usuario no signed in, devolviendo null');
    return null;
  }

  /// Clear sign-in state
  Future<void> _clearSignInState() async {
    print('🧹 [DEBUG] Limpiando sign-in state...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isSignedInKey);
    await prefs.remove(_userEmailKey);
    print('🧹 [DEBUG] Sign-in state limpiado');
  }

  /// Get Drive API instance
  Future<drive.DriveApi?> getDriveApi() async {
    print('📁 [DEBUG] Obteniendo Drive API...');
    final authClient = await getAuthClient();
    if (authClient != null) {
      print('📁 [DEBUG] AuthClient obtenido, creando DriveApi...');
      final driveApi = drive.DriveApi(authClient);
      print('📁 [DEBUG] DriveApi creado exitosamente');
      return driveApi;
    }
    print('📁 [DEBUG] AuthClient es null, devolviendo null');
    return null;
  }

  /// Dispose resources
  void dispose() {
    print('🗑️ [DEBUG] Disposing GoogleDriveAuthService...');
    _authClient?.close();
    print('🗑️ [DEBUG] GoogleDriveAuthService disposed');
  }
}
