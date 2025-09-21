// lib/pages/backup_settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../blocs/backup_bloc.dart';
import '../blocs/backup_event.dart';
import '../blocs/backup_state.dart';
import '../blocs/prayer_bloc.dart';
import '../extensions/string_extensions.dart';
import '../providers/devocional_provider.dart';
import '../services/backup_scheduler_service.dart';
import '../services/connectivity_service.dart';
import '../services/google_drive_auth_service.dart';
import '../services/google_drive_backup_service.dart';
import '../services/spiritual_stats_service.dart';
import '../widgets/backup_configuration_sheet.dart';

/// BackupSettingsPage with simplified progressive UI
class BackupSettingsPage extends StatelessWidget {
  final BackupBloc? bloc; // Optional bloc for testing

  const BackupSettingsPage({super.key, this.bloc});

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️ [DEBUG] BackupSettingsPage build iniciado');

    // If bloc is provided (e.g., in tests), use it directly
    if (bloc != null) {
      return BlocProvider.value(
        value: bloc!,
        child: const _BackupSettingsView(),
      );
    }

    // Otherwise, create services with dependencies (production)
    final authService = GoogleDriveAuthService();
    debugPrint('🔧 [DEBUG] GoogleDriveAuthService creado');

    final connectivityService = ConnectivityService();
    debugPrint('🔧 [DEBUG] ConnectivityService creado');

    final statsService = SpiritualStatsService();
    debugPrint('🔧 [DEBUG] SpiritualStatsService creado');

    final backupService = GoogleDriveBackupService(
      authService: authService,
      connectivityService: connectivityService,
      statsService: statsService,
    );
    debugPrint('🔧 [DEBUG] GoogleDriveBackupService creado con dependencias');

    return BlocProvider(
      create: (context) {
        final schedulerService = BackupSchedulerService(
          backupService: backupService,
          connectivityService: connectivityService,
        );

        final bloc = BackupBloc(
          backupService: backupService,
          schedulerService: schedulerService,
          devocionalProvider:
              Provider.of<DevocionalProvider>(context, listen: false),
          prayerBloc: context.read<PrayerBloc>(),
        );

        bloc.add(const LoadBackupSettings());
        return bloc;
      },
      child: const _BackupSettingsView(),
    );
  }
}

class _BackupSettingsView extends StatelessWidget {
  const _BackupSettingsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('backup.title'.tr()),
        elevation: 0,
      ),
      body: BlocListener<BackupBloc, BackupState>(
        listener: (context, state) {
          debugPrint(
              '🔄 [DEBUG] BlocListener recibió estado: ${state.runtimeType}');

          if (state is BackupError) {
            debugPrint('❌ [DEBUG] BackupError recibido: ${state.message}');

            // 🆕 PUNTO #7: Errores más específicos
            String errorMessage;
            if (state.message.contains('network') ||
                state.message.contains('connection')) {
              errorMessage = 'backup.error_network'.tr();
            } else if (state.message.contains('auth') ||
                state.message.contains('sign')) {
              errorMessage = 'backup.error_auth_failed'.tr();
            } else if (state.message.contains('storage') ||
                state.message.contains('quota')) {
              errorMessage = 'backup.error_storage_full'.tr();
            } else if (state.message.contains('internet') ||
                state.message.contains('connectivity')) {
              errorMessage = 'backup.error_no_internet'.tr();
            } else {
              errorMessage = 'backup.error_generic'.tr();
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: colorScheme.error,
              ),
            );
          } else if (state is BackupCreated) {
            debugPrint('✅ [DEBUG] BackupCreated recibido');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('backup.created_successfully'.tr()),
                backgroundColor: colorScheme.primary,
              ),
            );
          } else if (state is BackupRestored) {
            debugPrint('✅ [DEBUG] BackupRestored recibido');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('backup.restored_successfully'.tr()),
                backgroundColor: colorScheme.primary,
              ),
            );
          } else if (state is BackupExistingFound) {
            debugPrint('📋 [DEBUG] BackupExistingFound recibido');
            _showExistingBackupDialog(context, state.backupInfo);
          }
        },
        child: BlocBuilder<BackupBloc, BackupState>(
          builder: (context, state) {
            if (state is BackupLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is BackupLoaded) {
              return _BackupSettingsContent(state: state);
            }

            if (state is BackupError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'backup.error_loading'.tr(),
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'backup.error_generic'.tr(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context
                            .read<BackupBloc>()
                            .add(const LoadBackupSettings());
                      },
                      child: Text('backup.retry'.tr()),
                    ),
                  ],
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  /// Show dialog when existing backup is found
  void _showExistingBackupDialog(
      BuildContext context, Map<String, dynamic> backupInfo) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('backup.existing_backup_found'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('backup.existing_backup_message'.tr()),
              const SizedBox(height: 16),
              if (backupInfo['modifiedTime'] != null) ...[
                Text(
                  '${'backup.backup_date'.tr()}: ${_formatBackupDate(backupInfo['modifiedTime'])}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (backupInfo['size'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${'backup.size'.tr()}: ${_formatSize(int.tryParse(backupInfo['size'].toString()) ?? 0)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<BackupBloc>().add(const SkipExistingBackup());
              },
              child: Text('backup.skip_restore'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context
                    .read<BackupBloc>()
                    .add(RestoreExistingBackup(backupInfo['fileId']));
              },
              child: Text('backup.restore_backup'.tr()),
            ),
          ],
        );
      },
    );
  }

  /// Format backup date for display
  String _formatBackupDate(String isoDateString) {
    try {
      final date = DateTime.parse(isoDateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'backup.today'.tr();
      } else if (difference.inDays == 1) {
        return 'backup.yesterday'.tr();
      } else if (difference.inDays < 7) {
        return 'backup.days_ago'
            .tr()
            .replaceAll('{days}', difference.inDays.toString());
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return isoDateString;
    }
  }

  /// Format size in bytes to human readable format
  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

class _BackupSettingsContent extends StatelessWidget {
  final BackupLoaded state;

  const _BackupSettingsContent({required this.state});

  @override
  Widget build(BuildContext context) {
    // Check if this is the first time connecting (no lastBackupTime and auto not configured yet)
    final hasConnectedBefore =
        state.lastBackupTime != null || state.autoBackupEnabled;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16).copyWith(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Always show intro section
          _buildIntroSection(context),
          const SizedBox(height: 20),

          // Progressive content based on state
          if (!state.isAuthenticated) ...[
            // State 1: Not connected - Only connection card
            _buildConnectionPrompt(context),
          ] else if (state.isAuthenticated && !hasConnectedBefore) ...[
            // State 2: Just connected - Show success and initial setup
            _buildJustConnectedState(context),
          ] else if (state.isAuthenticated && state.autoBackupEnabled) ...[
            // State 3: Auto backup is ON - Show protection title + simplified card
            _buildProtectionTitle(context),
            const SizedBox(height: 12),
            _buildAutoBackupActiveState(context),
          ] else if (state.isAuthenticated && !state.autoBackupEnabled) ...[
            // State 4: Auto backup is OFF - Show manual backup option
            _buildManualBackupState(context),
          ],

          // Security info (always at bottom)
          const SizedBox(height: 24),
          _buildSecurityInfo(context),
        ],
      ),
    );
  }

  Widget _buildIntroSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.3),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'backup.description_title'.tr(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'backup.description_text'.tr(),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionPrompt(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          debugPrint('🔄 [DEBUG] Usuario tapeó conectar Google Drive');
          context.read<BackupBloc>().add(const SignInToGoogleDrive());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 48,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'backup.connect_to_google_drive'.tr(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'backup.tap_to_connect_protect'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    debugPrint('🔄 [DEBUG] Botón conectar presionado');
                    context.read<BackupBloc>().add(const SignInToGoogleDrive());
                  },
                  icon: const Icon(Icons.account_circle),
                  label: Text('backup.connect_to_google_drive'.tr()),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJustConnectedState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Success message
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'backup.sign_in_success'.tr(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (state.userEmail != null) ...[
                Text(
                  '${'backup.backup_email'.tr()}: ${state.userEmail!}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Auto-enable automatic backup
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.autorenew,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'backup.automatic_protection_enabled'.tr(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '¿Quieres que respaldemos automáticamente todos los días a las 2:00 AM?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Activate automatic backup with all defaults
                      context
                          .read<BackupBloc>()
                          .add(const ToggleAutoBackup(true));
                      context
                          .read<BackupBloc>()
                          .add(const ToggleWifiOnly(true));
                      context
                          .read<BackupBloc>()
                          .add(const ToggleCompression(true));
                    },
                    child: Text('backup.activate_automatic'.tr()),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    // Skip to manual backup
                    context
                        .read<BackupBloc>()
                        .add(const ToggleAutoBackup(false));
                  },
                  child: Text('backup.prefer_manual'.tr()),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 🆕 PUNTO #1: Protection title outside the card (only when authenticated and auto backup active)
  Widget _buildProtectionTitle(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const Icon(Icons.security, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(
            'backup.protection_active'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 PUNTOS #1,2,3: Simplified auto backup active state with improvements
  Widget _buildAutoBackupActiveState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      key: const Key('auto_backup_active_card'), // 🆕 PUNTO #9: Testing key
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🆕 PUNTO #2: Three dots moved to top right corner
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  key: const Key('backup_settings_button'),
                  // 🆕 PUNTO #9: Testing key
                  onPressed: () =>
                      BackupConfigurationSheet.show(context, state),
                  icon: Icon(Icons.more_vert, color: colorScheme.primary),
                  tooltip:
                      'backup.configuration'.tr(), // 🆕 PUNTO #9: Accessibility
                ),
              ],
            ),

            // 🆕 PUNTO #1: Connected status with icon
            const _ConnectedStatusRow(),
            const SizedBox(height: 12),

            // User email info
            _BackupInfoRow(
              icon: Icons.person_outline,
              labelKey: 'backup.backup_email',
              value: state.userEmail ?? 'backup.no_email'.tr(),
            ),
            const SizedBox(height: 8),

            // Last backup info
            if (state.lastBackupTime != null) ...[
              _BackupInfoRow(
                icon: Icons.schedule,
                labelKey: 'backup.last_backup',
                value: _formatLastBackupTime(context, state.lastBackupTime!),
              ),
              const SizedBox(height: 8),
            ],

            // Next backup info
            if (state.nextBackupTime != null) ...[
              _BackupInfoRow(
                icon: Icons.schedule_send,
                labelKey: 'backup.next_backup',
                value: _formatNextBackupTime(context, state.nextBackupTime!),
              ),
              const SizedBox(height: 16),
            ],

            // 🆕 PUNTO #2,3: Switch row with proper layout, no subtitle
            const _BackupToggleRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildManualBackupState(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Manual backup card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.touch_app,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'backup.manual_backup_active'.tr(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'backup.manual_backup_description'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Show email in manual state too
                if (state.userEmail != null) ...[
                  Text(
                    '${'backup.backup_email'.tr()}: ${state.userEmail!}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<BackupBloc>()
                          .add(const CreateManualBackup());
                    },
                    icon: const Icon(Icons.backup),
                    label: Text('backup.create_backup'.tr()),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    context
                        .read<BackupBloc>()
                        .add(const ToggleAutoBackup(true));
                  },
                  child: Text('backup.enable_auto_backup'.tr()),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () =>
                      BackupConfigurationSheet.show(context, state),
                  icon: Icon(
                    Icons.more_vert,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text('backup.configuration'.tr()),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Last backup info if available
        if (state.lastBackupTime != null) ...[
          Card(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${'backup.last_backup'.tr()}: ${_formatLastBackupTime(context, state.lastBackupTime!)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSecurityInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.security,
            color: colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'backup.security_title'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'backup.security_text'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastBackupTime(BuildContext context, DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return 'backup.today'.tr();
    } else if (difference.inDays == 1) {
      return 'backup.yesterday'.tr();
    } else {
      return 'backup.days_ago'
          .tr()
          .replaceAll('{days}', difference.inDays.toString());
    }
  }

  String _formatNextBackupTime(BuildContext context, DateTime time) {
    final now = DateTime.now();
    final nowDate = DateTime(now.year, now.month, now.day);
    final timeDate = DateTime(time.year, time.month, time.day);
    final daysDifference = timeDate.difference(nowDate).inDays;

    // Formatear la hora exacta del backup programado
    final hour = time.hour;
    final minute = time.minute;
    String timeString;

    if (hour == 0 && minute == 0) {
      timeString = '12:00 AM';
    } else if (hour < 12) {
      timeString =
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} AM';
    } else if (hour == 12) {
      timeString = '12:${minute.toString().padLeft(2, '0')} PM';
    } else {
      timeString =
          '${(hour - 12).toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} PM';
    }

    // Casos especiales para 2:00 AM (más legible)
    if (hour == 2 && minute == 0) {
      timeString = '2:00 AM';
    }

    if (daysDifference == 0) {
      return '${'backup.today'.tr()} $timeString';
    } else if (daysDifference == 1) {
      return '${'backup.tomorrow'.tr()} $timeString';
    } else {
      return '${'backup.in_days'.tr().replaceAll('{days}', daysDifference.toString())} $timeString';
    }
  }
}

// 🆕 PUNTO #10: Optimized extracted widgets for performance

/// 🆕 PUNTO #1: Connected status row widget
class _ConnectedStatusRow extends StatelessWidget {
  const _ConnectedStatusRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          Icons.cloud_done,
          size: 20,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'backup.connected_to_google_drive'.tr(),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

/// 🆕 PUNTO #10: Reusable info row widget
class _BackupInfoRow extends StatelessWidget {
  final IconData icon;
  final String labelKey;
  final String value;

  const _BackupInfoRow({
    required this.icon,
    required this.labelKey,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '${labelKey.tr()}: ',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// 🆕 PUNTO #2,3: Toggle row widget with proper layout
class _BackupToggleRow extends StatelessWidget {
  const _BackupToggleRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<BackupBloc, BackupState>(
      builder: (context, state) {
        if (state is! BackupLoaded) return const SizedBox.shrink();

        return Row(
          children: [
            Expanded(
              child: Text(
                'backup.enable_auto_backup'.tr(),
                style: theme.textTheme.bodyLarge,
              ),
            ),
            // 🆕 PUNTO #2: Switch properly aligned to the right
            Semantics(
              // 🆕 PUNTO #9: Accessibility
              label: 'backup.enable_auto_backup'.tr(),
              child: Switch(
                key: const Key('auto_backup_switch'),
                // 🆕 PUNTO #9: Testing key
                value: state.autoBackupEnabled,
                onChanged: (value) {
                  context.read<BackupBloc>().add(ToggleAutoBackup(value));
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
