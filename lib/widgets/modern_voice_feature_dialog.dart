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
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaler = MediaQuery.textScalerOf(context);
    final isCompact = screenWidth < 380; // Small phones

    return AppGradientDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'app.voice_feature_title'.tr(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                  fontSize: textScaler.scale(
                      Theme.of(context).textTheme.titleLarge?.fontSize ?? 20),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'app.voice_feature_description'.tr(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: textScaler.scale(
                      Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: isCompact ? 8 : 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.secondary,
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 12 : 18,
                      vertical: isCompact ? 8 : 12,
                    ),
                  ),
                  onPressed: onContinue,
                  child: Text(
                    'app.skip'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.normal,
                          fontSize: textScaler.scale((Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.fontSize ??
                                  16) *
                              1.2),
                        ),
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 12 : 18,
                      vertical: isCompact ? 8 : 12,
                    ),
                  ),
                  icon: Icon(Icons.settings_voice, size: isCompact ? 18 : 20),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'app.voice_feature_configure'.tr(),
                      style: TextStyle(
                        fontSize: textScaler.scale((Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.fontSize ??
                                16) *
                            1.0),
                      ),
                    ),
                  ),
                  onPressed: onConfigure,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
