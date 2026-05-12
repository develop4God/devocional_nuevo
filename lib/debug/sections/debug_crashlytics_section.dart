// ignore_for_file: use_build_context_synchronously
import 'package:devocional_nuevo/pages/backup_settings_page.dart';
import 'package:devocional_nuevo/services/in_app_review_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Debug section for Crashlytics force-crash, Backup navigation, and Review FAB.
/// Single Responsibility: only handles crash testing and supporting debug actions.
class DebugCrashlyticsSection extends StatelessWidget {
  const DebugCrashlyticsSection({super.key});

  static const _platform = MethodChannel(
    'com.develop4god.devocional_nuevo/crashlytics',
  );

  Future<void> _forceCrash(BuildContext context) async {
    try {
      await _platform.invokeMethod('forceCrash');
      debugPrint('❌ La app no crasheó como se esperaba desde el lado nativo.');
      FirebaseCrashlytics.instance.crash();
    } on PlatformException catch (e) {
      debugPrint('❌ Error de plataforma al invocar forceCrash: ${e.message}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error de plataforma: ${e.message}\nIntentando método alternativo...',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      await Future.delayed(const Duration(seconds: 2));
      FirebaseCrashlytics.instance.crash();
    } catch (e) {
      debugPrint('❌ Error inesperado: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error inesperado: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Crashlytics
        const Text(
          'Presiona el botón para forzar un fallo de Crashlytics:',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 32),

        // Backup Settings
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.backup, size: 48, color: Colors.blue),
              const SizedBox(height: 8),
              const Text(
                'Test Backup Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BackupSettingsPage()),
                ),
                icon: const Icon(Icons.settings_backup_restore),
                label: const Text('Open Backup Page'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Debug mode only - not visible in production',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Review FAB
        FloatingActionButton(
          onPressed: () async {
            debugPrint('🟣 [Debug] Botón de evaluación presionado.');
            await InAppReviewService.requestInAppReview(context);
          },
          backgroundColor: Colors.deepPurple,
          tooltip: 'Abrir diálogo de evaluación',
          child: const Icon(Icons.reviews_rounded),
        ),
      ],
    );
  }
}
