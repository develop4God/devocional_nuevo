// lib/pages/backup_settings_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// BackupSettingsPage with WhatsApp-style UI and BLoC architecture
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
      ),
      body: BlocListener<BackupBloc, BackupState>(
        listener: (context, state) {
          debugPrint(
              '🔄 [DEBUG] BlocListener recibió estado: ${state.runtimeType}');
          if (state is BackupError) {
            debugPrint('❌ [DEBUG] BackupError recibido: ${state.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message.tr()),
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
                      state.message,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16).copyWith(
          bottom:
              100), // Add extra bottom padding for Android navigation buttons
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description card
          _buildDescriptionCard(context),
          const SizedBox(height: 24),

          // Google Drive connection + last backup info
          _buildConnectionCard(context),
          const SizedBox(height: 24),

          // Automatic backup settings (NEW - MAIN FEATURE)
          _buildAutomaticBackupSection(context),
          const SizedBox(height: 24),

          // Manual backup options with size estimates
          _buildManualBackupSection(context),
          const SizedBox(height: 24),

          // Create backup button
          _buildCreateBackupButton(context),
          const SizedBox(height: 24),

          // Security info
          _buildSecurityCard(context),

          // Extra spacing to ensure security section is fully visible
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Changed to plain text without container/card as requested
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'backup.description_title'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'backup.description_text'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () {
        debugPrint(
            '🔄 [DEBUG] Usuario tapeó Google Drive connection - iniciando SignIn');
        debugPrint(
            '🔄 [DEBUG] Estado actual isAuthenticated: ${state.isAuthenticated}');

        // ✅ SOLO UNA llamada al evento
        context.read<BackupBloc>().add(const SignInToGoogleDrive());

        debugPrint('🔄 [DEBUG] Evento SignInToGoogleDrive enviado al Bloc');
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Google Drive icon
                  Icon(
                    state.isAuthenticated
                        ? Icons.backup_outlined
                        : Icons.add_to_drive_outlined,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  // CAMBIO: Título condicional
                  Text(
                    state.isAuthenticated
                        ? 'backup.connected_to_google_drive'.tr()
                        : 'backup.connect_to_google_drive'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Login indicator
                  if (state.isAuthenticated)
                    Icon(Icons.cloud_done_outlined, color: colorScheme.primary)
                  else
                    Icon(Icons.cloud_off_outlined, color: colorScheme.primary),
                ],
              ),
              const SizedBox(height: 12),

              // Authentication status and last backup info
              if (state.isAuthenticated) ...[
                if (state.lastBackupTime != null) ...[
                  _buildInfoRow(
                    context,
                    Icons.schedule,
                    'backup.last_backup'.tr(),
                    _formatLastBackupTime(context, state.lastBackupTime!),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    Icons.data_usage,
                    'backup.size'.tr(),
                    _formatSize(state.estimatedSize),
                  ),
                  if (state.nextBackupTime != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      Icons.schedule_send,
                      'backup.next_backup'.tr(),
                      _formatNextBackupTime(context, state.nextBackupTime!),
                    ),
                  ],
                ] else ...[
                  Text(
                    'backup.no_backup_yet'.tr(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ] else ...[
                Text(
                  'backup.not_connected'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                // CAMBIO: Mensaje cuando no conectado
                Text(
                  'backup.tap_to_connect_protect'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutomaticBackupSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'backup.automatic_backups'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Auto backup toggle
            _buildSwitchTile(
              context,
              'backup.enable_auto_backup'.tr(),
              state.autoBackupEnabled,
              (value) {
                context.read<BackupBloc>().add(ToggleAutoBackup(value));
              },
            ),

            if (state.autoBackupEnabled) ...[
              const SizedBox(height: 16),

              // Frequency selector
              _buildFrequencySelector(context),
              const SizedBox(height: 16),

              // WiFi only toggle
              _buildSwitchTile(
                context,
                'backup.wifi_only'.tr(),
                state.wifiOnlyEnabled,
                (value) {
                  context.read<BackupBloc>().add(ToggleWifiOnly(value));
                },
                subtitle: 'backup.wifi_only_subtitle'.tr(),
              ),
              const SizedBox(height: 8),

              // Compression toggle
              _buildSwitchTile(
                context,
                'backup.compress_data'.tr(),
                state.compressionEnabled,
                (value) {
                  context.read<BackupBloc>().add(ToggleCompression(value));
                },
                subtitle: 'backup.compress_data_subtitle'.tr(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencySelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAuthenticated = state.isAuthenticated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'backup.frequency'.tr(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: isAuthenticated
                ? null
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: isAuthenticated ? 1.0 : 0.5,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: state.backupFrequency,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                items: [
                  DropdownMenuItem(
                    value: GoogleDriveBackupService.frequencyDaily,
                    child: Text('backup.frequency_daily_2am'.tr()),
                  ),
                  DropdownMenuItem(
                    value: GoogleDriveBackupService.frequencyManual,
                    child: Text('backup.frequency_manual_only'.tr()),
                  ),
                  DropdownMenuItem(
                    value: GoogleDriveBackupService.frequencyDeactivated,
                    child: Text('backup.frequency_deactivated'.tr()),
                  ),
                ],
                onChanged: isAuthenticated
                    ? (value) {
                        if (value != null) {
                          context
                              .read<BackupBloc>()
                              .add(ChangeBackupFrequency(value));
                        }
                      }
                    : null, // Disable until authentication
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualBackupSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.file_upload_outlined, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'backup.manual_backup_options'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Backup options with dynamic size estimates
            FutureBuilder<Map<String, dynamic>>(
              future: _getDynamicBackupOptions(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final backupData = snapshot.data ?? {};
                return Column(
                  children: [
                    _buildBackupOptionTile(
                      context,
                      'backup.spiritual_stats'.tr(),
                      _formatBackupOptionSize(backupData['spiritual_stats']),
                      state.backupOptions['spiritual_stats'] ?? true,
                      (value) => _updateBackupOption(
                          context, 'spiritual_stats', value),
                    ),
                    _buildBackupOptionTile(
                      context,
                      'backup.favorite_devotionals'.tr(),
                      _formatBackupOptionSize(
                          backupData['favorite_devotionals']),
                      state.backupOptions['favorite_devotionals'] ?? true,
                      (value) => _updateBackupOption(
                          context, 'favorite_devotionals', value),
                    ),
                    _buildBackupOptionTile(
                      context,
                      'backup.saved_prayers'.tr(),
                      _formatBackupOptionSize(backupData['saved_prayers']),
                      state.backupOptions['saved_prayers'] ?? true,
                      (value) =>
                          _updateBackupOption(context, 'saved_prayers', value),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Get dynamic backup options with actual file sizes
  Future<Map<String, dynamic>> _getDynamicBackupOptions(
      BuildContext context) async {
    try {
      debugPrint('📊 [DEBUG] Obteniendo opciones dinámicas de backup...');
      // Get actual data from services
      final statsService = SpiritualStatsService();
      final devocionalProvider =
          Provider.of<DevocionalProvider>(context, listen: false);
      debugPrint('📊 [DEBUG] Servicios obtenidos para calcular tamaños');

      // Get spiritual stats data
      final statsData = await statsService.getAllStats();
      final statsSize = _calculateJsonSize(statsData);

      // Get favorite devotionals count and size
      final favoriteCount = devocionalProvider.favoriteDevocionales.length;
      final favoritesSize =
          _calculateJsonSize(devocionalProvider.favoriteDevocionales);

      // Get saved prayers data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final prayersJson = prefs.getString('prayers') ?? '[]';
      final prayersList = json.decode(prayersJson) as List<dynamic>;
      final prayersCount = prayersList.length;
      final prayersSize = _calculateJsonSize(prayersList);

      return {
        'spiritual_stats': {
          'count': 1, // Always 1 stats file
          'size': statsSize,
          'description': '~${_formatSize(statsSize)}',
        },
        'favorite_devotionals': {
          'count': favoriteCount,
          'size': favoritesSize,
          'description':
              '$favoriteCount ${favoriteCount == 1 ? 'elemento' : 'elementos'}, ~${_formatSize(favoritesSize)}',
        },
        'saved_prayers': {
          'count': prayersCount,
          'size': prayersSize,
          'description':
              '$prayersCount ${prayersCount == 1 ? 'elemento' : 'elementos'}, ~${_formatSize(prayersSize)}',
        },
      };
    } catch (e) {
      debugPrint('❌ [DEBUG] Error getting dynamic backup options: $e');
      debugPrint('❌ [DEBUG] Stack trace: ${StackTrace.current}');
      debugPrint('Error getting dynamic backup options: $e');
      // Return empty/zero values as fallback
      return {
        'spiritual_stats': {
          'count': 0,
          'size': 0,
          'description': '0 KB',
        },
        'favorite_devotionals': {
          'count': 0,
          'size': 0,
          'description': '0 elementos, 0 KB',
        },
        'saved_prayers': {
          'count': 0,
          'size': 0,
          'description': '0 elementos, 0 KB',
        },
      };
    }
  }

  /// Calculate the JSON size of data
  int _calculateJsonSize(dynamic data) {
    try {
      final jsonString = jsonEncode(data);
      return utf8.encode(jsonString).length;
    } catch (e) {
      return 0;
    }
  }

  /// Format backup option size description
  String _formatBackupOptionSize(Map<String, dynamic>? optionData) {
    if (optionData == null) return '0 KB';
    return optionData['description'] ?? '0 KB';
  }

  Widget _buildCreateBackupButton(BuildContext context) {
    return BlocBuilder<BackupBloc, BackupState>(
      builder: (context, state) {
        final isCreating = state is BackupCreating;
        final isAuthenticated = state is BackupLoaded && state.isAuthenticated;

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (isCreating ||
                    !isAuthenticated) // Disable until authentication is successful
                ? null
                : () {
                    context.read<BackupBloc>().add(const CreateManualBackup());
                  },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isCreating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'backup.create_backup'.tr(),
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSecurityCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Changed to plain text without container/card as requested
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'backup.security_title'.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'backup.security_text'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    final isAuthenticated = state.isAuthenticated;

    return InkWell(
      onTap: isAuthenticated
          ? () => onChanged(!value)
          : null, // Disable until authentication
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: isAuthenticated ? 1.0 : 0.5, // Gray out when disabled
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isAuthenticated
                            ? null
                            : theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: isAuthenticated ? 0.8 : 0.4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: isAuthenticated
                    ? onChanged
                    : null, // Disable until authentication
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackupOptionTile(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final theme = Theme.of(context);
    final isAuthenticated = state.isAuthenticated;

    return InkWell(
      onTap: isAuthenticated
          ? () => onChanged(!value)
          : null, // Disable until authentication
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: isAuthenticated ? 1.0 : 0.5, // Gray out when disabled
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              Checkbox(
                value: value,
                onChanged: isAuthenticated
                    ? (newValue) => onChanged(newValue ?? false)
                    : null, // Disable until authentication
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isAuthenticated
                            ? null
                            : theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: isAuthenticated ? 0.8 : 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  void _updateBackupOption(BuildContext context, String key, bool value) {
    final currentOptions = Map<String, bool>.from(state.backupOptions);
    currentOptions[key] = value;
    context.read<BackupBloc>().add(UpdateBackupOptions(currentOptions));
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

    // Comparar solo las fechas (sin horas)
    final nowDate = DateTime(now.year, now.month, now.day);
    final timeDate = DateTime(time.year, time.month, time.day);
    final daysDifference = timeDate.difference(nowDate).inDays;

    if (daysDifference == 0) {
      return 'backup.today'.tr();
    } else if (daysDifference == 1) {
      return 'backup.tomorrow'.tr();
    } else {
      return 'backup.in_days'
          .tr()
          .replaceAll('{days}', daysDifference.toString());
    }
  }

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
