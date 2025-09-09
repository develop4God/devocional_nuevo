// lib/pages/backup_settings_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../blocs/backup_bloc.dart';
import '../blocs/backup_event.dart';
import '../blocs/backup_state.dart';
import '../extensions/string_extensions.dart';
import '../providers/devocional_provider.dart';
import '../services/connectivity_service.dart';
import '../services/google_drive_auth_service.dart';
import '../services/google_drive_backup_service.dart';
import '../services/spiritual_stats_service.dart';

/// BackupSettingsPage with WhatsApp-style UI and BLoC architecture
class BackupSettingsPage extends StatelessWidget {
  const BackupSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Create services with dependencies
    final authService = GoogleDriveAuthService();
    final connectivityService = ConnectivityService();
    final statsService = SpiritualStatsService();

    final backupService = GoogleDriveBackupService(
      authService: authService,
      connectivityService: connectivityService,
      statsService: statsService,
    );

    return BlocProvider(
      create: (context) => BackupBloc(
        backupService: backupService,
        devocionalProvider:
            Provider.of<DevocionalProvider>(context, listen: false),
      )..add(const LoadBackupSettings()),
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
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: BlocListener<BackupBloc, BackupState>(
        listener: (context, state) {
          if (state is BackupError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.error,
              ),
            );
          } else if (state is BackupCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('backup.created_successfully'.tr()),
                backgroundColor: colorScheme.primary,
              ),
            );
          } else if (state is BackupRestored) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('backup.restored_successfully'.tr()),
                backgroundColor: colorScheme.primary,
              ),
            );
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
}

class _BackupSettingsContent extends StatelessWidget {
  final BackupLoaded state;

  const _BackupSettingsContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plain text without icon as requested
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
      ),
    );
  }

  Widget _buildConnectionCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () {
        // Handle Google Drive login
        context.read<BackupBloc>().add(const SignInToGoogleDrive());
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
                  Icon(Icons.cloud, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'backup.google_drive_connection'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Login indicator
                  if (state.isAuthenticated) 
                    Icon(Icons.check_circle, color: Colors.green)
                  else
                    Icon(Icons.login, color: colorScheme.primary),
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
                Text(
                  'backup.tap_to_connect'.tr(),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'backup.frequency'.tr(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
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
              onChanged: (value) {
                if (value != null) {
                  context.read<BackupBloc>().add(ChangeBackupFrequency(value));
                }
              },
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
                Icon(Icons.backup, color: colorScheme.primary),
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
                      (value) => _updateBackupOption(context, 'spiritual_stats', value),
                    ),
                    _buildBackupOptionTile(
                      context,
                      'backup.favorite_devotionals'.tr(),
                      _formatBackupOptionSize(backupData['favorite_devotionals']),
                      state.backupOptions['favorite_devotionals'] ?? true,
                      (value) =>
                          _updateBackupOption(context, 'favorite_devotionals', value),
                    ),
                    _buildBackupOptionTile(
                      context,
                      'backup.saved_prayers'.tr(),
                      _formatBackupOptionSize(backupData['saved_prayers']),
                      state.backupOptions['saved_prayers'] ?? true,
                      (value) => _updateBackupOption(context, 'saved_prayers', value),
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
  Future<Map<String, dynamic>> _getDynamicBackupOptions(BuildContext context) async {
    try {
      // Get actual data from services
      final statsService = SpiritualStatsService();
      final devocionalProvider = Provider.of<DevocionalProvider>(context, listen: false);
      
      // Get spiritual stats data
      final statsData = await statsService.getAllStats();
      final statsSize = _calculateJsonSize(statsData);
      
      // Get favorite devotionals count and size
      final favoriteCount = devocionalProvider.favoriteDevocionales.length;
      final favoritesSize = _calculateJsonSize(devocionalProvider.favoriteDevocionales);
      
      // Get saved prayers data (mock for now since prayers service might not exist)
      final prayersCount = 0; // TODO: Replace with actual prayers count when prayers service exists
      final prayersSize = 0;
      
      return {
        'spiritual_stats': {
          'count': 1, // Always 1 stats file
          'size': statsSize,
          'description': '~${_formatSize(statsSize)}',
        },
        'favorite_devotionals': {
          'count': favoriteCount,
          'size': favoritesSize,
          'description': '$favoriteCount ${favoriteCount == 1 ? 'elemento' : 'elementos'}, ~${_formatSize(favoritesSize)}',
        },
        'saved_prayers': {
          'count': prayersCount,
          'size': prayersSize,
          'description': '$prayersCount ${prayersCount == 1 ? 'elemento' : 'elementos'}, ~${_formatSize(prayersSize)}',
        },
      };
    } catch (e) {
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

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isCreating
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

    return Card(
      child: Padding(
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

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
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
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
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

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (newValue) => onChanged(newValue ?? false),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge,
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    final difference = time.difference(now);

    if (difference.inDays == 0) {
      return 'backup.today'.tr();
    } else if (difference.inDays == 1) {
      return 'backup.tomorrow'.tr();
    } else {
      return 'backup.in_days'
          .tr()
          .replaceAll('{days}', difference.inDays.toString());
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
