import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/widgets/app_gradient_dialog.dart';
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
    return AppGradientDialog(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                icon: const Icon(Icons.settings_voice),
                label: const Text('Configurar voces'),
                onPressed: onConfigure,
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.secondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onPressed: onContinue,
                child: Text(
                  'app.skip'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.normal,
                        fontSize:
                            Theme.of(context).textTheme.titleMedium?.fontSize !=
                                    null
                                ? Theme.of(context)
                                        .textTheme
                                        .titleMedium!
                                        .fontSize! *
                                    1.2
                                : 20,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
