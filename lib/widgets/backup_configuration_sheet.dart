// lib/widgets/backup_configuration_sheet_optimized.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/backup_bloc.dart';
import '../blocs/backup_event.dart';
import '../blocs/backup_state.dart';
import '../extensions/string_extensions.dart';

/// Modal de configuración de backup optimizado - Funcionalidad migrada
class BackupConfigurationSheet extends StatelessWidget {
  final BackupLoaded state;
  final BackupBloc backupBloc;

  const BackupConfigurationSheet({
    super.key,
    required this.state,
    required this.backupBloc,
  });

  static void show(BuildContext context, BackupLoaded state) {
    final backupBloc = context.read<BackupBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => BackupConfigurationSheet(
        state: state,
        backupBloc: backupBloc,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocProvider.value(
      value: backupBloc,
      child: BlocBuilder<BackupBloc, BackupState>(
        builder: (context, currentState) {
          final displayState =
              currentState is BackupLoaded ? currentState : state;

          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.98),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.85,
              expand: false,
              builder: (context, scrollController) => Column(
                children: [
                  // Handle compacto
                  Container(
                    width: 32,
                    height: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header compacto
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
                    child: Row(
                      children: [
                        Icon(Icons.tune, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'backup.configuration'.tr(),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            minimumSize: const Size(32, 32),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Contenido principal
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sección principal de backup automático (MIGRADA)
                          _buildAutoBackupSection(context, displayState),

                          const SizedBox(height: 16),

                          // Opciones de optimización
                          _buildOptimizationSection(context, displayState),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Sección principal de backup automático (MIGRADA del card)
  Widget _buildAutoBackupSection(
      BuildContext context, BackupLoaded displayState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'backup.automatic_backups'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),

        // Switch principal de backup automático (MIGRADO)
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              backupBloc.add(ToggleAutoBackup(!displayState.autoBackupEnabled));
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.autorenew,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'backup.enable_auto_backup'.tr(),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Protege automáticamente tu progreso espiritual',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildLargerSwitch(
                          context, displayState.autoBackupEnabled, (value) {
                        backupBloc.add(ToggleAutoBackup(value));
                      }),
                    ],
                  ),

                  // Información de frecuencia (solo cuando está habilitado)
                  if (displayState.autoBackupEnabled) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'backup.frequency_daily_2am'.tr(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Sección de optimización
  Widget _buildOptimizationSection(
      BuildContext context, BackupLoaded displayState) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Optimización',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        _buildCompactToggle(
          context,
          icon: Icons.wifi,
          title: 'backup.wifi_only'.tr(),
          subtitle: 'backup.wifi_only_subtitle'.tr(),
          value: displayState.wifiOnlyEnabled,
          onChanged: (value) => backupBloc.add(ToggleWifiOnly(value)),
        ),
        const SizedBox(height: 8),
        _buildCompactToggle(
          context,
          icon: Icons.compress,
          title: 'backup.compress_data'.tr(),
          subtitle: 'backup.compress_data_subtitle'.tr(),
          value: displayState.compressionEnabled,
          onChanged: (value) => backupBloc.add(ToggleCompression(value)),
        ),
      ],
    );
  }

  Widget _buildCompactToggle(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildLargerSwitch(context, value, onChanged),
          ],
        ),
      ),
    );
  }

  // Switch más grande y cómodo
  Widget _buildLargerSwitch(
    BuildContext context,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: value ? colorScheme.primary : colorScheme.outline,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
