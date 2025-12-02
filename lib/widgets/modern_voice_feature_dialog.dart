import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';

class ModernVoiceFeatureDialog extends StatelessWidget {
  final VoidCallback onConfigure;
  final VoidCallback onContinue;

  const ModernVoiceFeatureDialog({
    super.key,
    required this.onConfigure,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface.withAlpha(255),
          // fondo sólido opaco
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withAlpha(180), // más intenso
              colorScheme.secondary.withAlpha(200),
              colorScheme.surface.withAlpha(220),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withAlpha(180), width: 2),
          // borde blanco semitransparente
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withAlpha(60),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🎤✨ ¡Nueva función disponible! ✨🎤',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Ahora puedes elegir entre distintas voces para la lectura devocional. Personaliza tu experiencia y disfruta de una lectura más agradable y moderna. 😃🔊',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                    icon: const Icon(Icons.settings_voice),
                    label: const Text('Configurar voces'),
                    onPressed: onConfigure,
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.secondary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                    child: Text('app.omit'.tr()),
                    // Usar clave i18n correctamente
                    onPressed: onContinue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
