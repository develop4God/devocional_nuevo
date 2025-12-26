import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Página de debug solo visible en modo desarrollo.
class DebugPage extends StatelessWidget {
  const DebugPage({super.key});

  // MethodChannel para Crashlytics nativo
  static const platform = MethodChannel('com.develop4god.devocional_nuevo/crashlytics');

  Future<void> _forceCrash(BuildContext context) async {
    try {
      await platform.invokeMethod('forceCrash');
      // Si llega aquí, la excepción no se lanzó como se esperaba
      debugPrint('❌ La app no crasheó como se esperaba.');
    } on PlatformException catch (e) {
      debugPrint('Error al invocar el método para forzar el fallo: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al forzar crash: ${e.message}')),
      );
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
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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

