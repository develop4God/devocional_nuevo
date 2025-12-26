import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Página de debug solo visible en modo desarrollo.
class DebugPage extends StatelessWidget {
  const DebugPage({super.key});

  // MethodChannel para Crashlytics nativo
  static const platform =
      MethodChannel('com.develop4god.devocional_nuevo/crashlytics');

  Future<void> _forceCrash(BuildContext context) async {
    try {
      // Intenta forzar el crash desde el lado nativo (Android/iOS)
      await platform.invokeMethod('forceCrash');
      // Si llega aquí, la excepción no se lanzó como se esperaba
      debugPrint('❌ La app no crasheó como se esperaba desde el lado nativo.');

      // Fallback: usar el metodo de Crashlytics de Flutter
      debugPrint(
          '⚠️ Intentando forzar crash desde Flutter con FirebaseCrashlytics.instance.crash()');
      FirebaseCrashlytics.instance.crash();
    } on PlatformException catch (e) {
      // Este error significa que el canal no está configurado o falló
      debugPrint('❌ Error de plataforma al invocar forceCrash: ${e.message}');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error de plataforma: ${e.message}\nIntentando método alternativo...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Fallback: usar el metodo de Crashlytics de Flutter
      await Future.delayed(const Duration(seconds: 2));
      debugPrint(
          '⚠️ Forzando crash desde Flutter con FirebaseCrashlytics.instance.crash()');
      FirebaseCrashlytics.instance.crash();
    } catch (e) {
      // Cualquier otro error
      debugPrint('❌ Error inesperado: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inesperado: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      // Ocultar la página en release
      return const SizedBox.shrink();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Tools'),
        backgroundColor: Colors.red.shade700,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Presiona el botón para forzar un fallo de Crashlytics:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _forceCrash(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('FORZAR FALLO AHORA'),
            ),
          ],
        ),
      ),
    );
  }
}
