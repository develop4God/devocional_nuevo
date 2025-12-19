import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:devocional_nuevo/services/tts/voice_settings_service.dart';
import 'package:provider/provider.dart';
import 'package:devocional_nuevo/providers/localization_provider.dart';

/// Página de debug para borrar flags y otras opciones de pruebas (solo modo debug)
class DebugFlagPage extends StatelessWidget {
  const DebugFlagPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      // No mostrar nada en release/profile
      return const SizedBox.shrink();
    }
    final localizationProvider = Provider.of<LocalizationProvider>(context);
    final voiceSettingsService =
        Provider.of<VoiceSettingsService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug: Flags y opciones'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            label: const Text('Borrar flag de voz (pruebas)',
                style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red, width: 2.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
            onPressed: () async {
              final language = localizationProvider.currentLocale.languageCode;
              await voiceSettingsService.clearUserSavedVoiceFlag(language);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Flag de voz borrado. Puedes probar el diálogo de selección de voz.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 24),
          // Aquí puedes agregar más botones de debug en el futuro
          OutlinedButton.icon(
            icon: const Icon(Icons.bug_report, color: Colors.blue),
            label: const Text('Opción de debug extra',
                style: TextStyle(color: Colors.blue)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.blue, width: 2.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Botón de debug extra presionado.'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
