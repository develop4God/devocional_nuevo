// Crear archivo: test_google_signin.dart
// Reemplaza tu GoogleDriveAuthService temporalmente con esto

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SimpleGoogleTest {
  // ⚡ TEST 1: Solo email (más básico posible)
  static final GoogleSignIn _googleSignInBasic = GoogleSignIn(
    scopes: ['email'], // Solo email, sin Drive
  );

  // ⚡ TEST 2: Con Drive scopes (tu configuración actual)
  static final GoogleSignIn _googleSignInDrive = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/drive'
    ],
  );

  // 🧪 TEST BÁSICO - Solo email
  static Future<void> testBasicSignIn() async {
    debugPrint('🧪 [TEST] Iniciando test básico (solo email)...');

    try {
      final account = await _googleSignInBasic.signIn();

      if (account != null) {
        debugPrint('✅ [TEST] ¡ÉXITO BÁSICO! Email: ${account.email}');
        debugPrint('✅ [TEST] Display Name: ${account.displayName}');
        debugPrint('✅ [TEST] ID: ${account.id}');

        // Sign out inmediatamente
        await _googleSignInBasic.signOut();
        debugPrint('✅ [TEST] Sign out básico exitoso');
      } else {
        debugPrint('❌ [TEST] Usuario canceló el sign in básico');
      }
    } catch (e) {
      debugPrint('❌ [TEST] Error en sign in básico: $e');
      debugPrint('❌ [TEST] Tipo de error: ${e.runtimeType}');
    }
  }

  // 🧪 TEST DRIVE - Con Drive scopes
  static Future<void> testDriveSignIn() async {
    debugPrint('🧪 [TEST] Iniciando test con Drive scopes...');

    try {
      final account = await _googleSignInDrive.signIn();

      if (account != null) {
        debugPrint('✅ [TEST] ¡ÉXITO CON DRIVE! Email: ${account.email}');

        // Intentar obtener tokens
        final auth = await account.authentication;
        debugPrint('✅ [TEST] Access Token existe: ${auth.accessToken != null}');
        debugPrint('✅ [TEST] ID Token existe: ${auth.idToken != null}');

        // Sign out inmediatamente
        await _googleSignInDrive.signOut();
        debugPrint('✅ [TEST] Sign out Drive exitoso');
      } else {
        debugPrint('❌ [TEST] Usuario canceló el sign in Drive');
      }
    } catch (e) {
      debugPrint('❌ [TEST] Error en sign in Drive: $e');
      debugPrint('❌ [TEST] Tipo de error: ${e.runtimeType}');
    }
  }

  // 🧪 TEST COMPLETO - Ejecuta ambos
  static Future<void> runAllTests() async {
    debugPrint('🚀 [TEST] ===== INICIANDO TESTS RÁPIDOS =====');

    debugPrint('');
    debugPrint('📱 [TEST] Test 1: Google Sign-In básico (solo email)');
    await testBasicSignIn();

    debugPrint('');
    debugPrint('📱 [TEST] Test 2: Google Sign-In con Drive scopes');
    await testDriveSignIn();

    debugPrint('');
    debugPrint('🏁 [TEST] ===== TESTS COMPLETADOS =====');
  }
}

// Widget para botón de test
class QuickTestWidget extends StatelessWidget {
  const QuickTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Google Sign-In')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => SimpleGoogleTest.testBasicSignIn(),
              child: Text('Test Básico (Solo Email)'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => SimpleGoogleTest.testDriveSignIn(),
              child: Text('Test Drive Scopes'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => SimpleGoogleTest.runAllTests(),
              child: Text('Ejecutar Todos los Tests'),
            ),
          ],
        ),
      ),
    );
  }
}
