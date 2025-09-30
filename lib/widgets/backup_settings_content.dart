// lib/widgets/backup_settings_content.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/backup_bloc.dart';
import '../blocs/backup_event.dart';
import '../blocs/backup_state.dart';
import '../extensions/string_extensions.dart';
import '../widgets/backup_configuration_sheet.dart';

/// Reusable backup settings content for both settings page and onboarding
class BackupSettingsContent extends StatefulWidget {
  final bool isOnboardingMode;

  const BackupSettingsContent({
    super.key,
    this.isOnboardingMode = false,
  });

  @override
  State<BackupSettingsContent> createState() => _BackupSettingsContentState();
}

class _BackupSettingsContentState extends State<BackupSettingsContent> {
  bool _hasAutoConfigured = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BackupBloc, BackupState>(
      builder: (context, state) {
        if (state is BackupLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is BackupLoaded) {
          return _buildContent(context, state);
        }

        if (state is BackupError) {
          return _buildErrorState(context, state);
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildContent(BuildContext context, BackupLoaded state) {
    // In onboarding mode, show simple success if authenticated
    if (widget.isOnboardingMode && state.isAuthenticated) {
      // Auto-configure only once
      if (!_hasAutoConfigured) {
        _hasAutoConfigured = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<BackupBloc>().add(const ToggleAutoBackup(true));
          context.read<BackupBloc>().add(const ToggleWifiOnly(true));
          context.read<BackupBloc>().add(const ToggleCompression(true));
        });
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16).copyWith(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntroSection(context),
            const SizedBox(height: 16),
            _buildOnboardingSuccessCard(context, state),
            const SizedBox(height: 24),
            _buildSecurityInfo(context),
          ],
        ),
      );
    }

    // Regular settings mode
    final hasConnectedBefore =
        state.lastBackupTime != null || state.autoBackupEnabled;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16).copyWith(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIntroSection(context),
          const SizedBox(height: 8),
          if (!state.isAuthenticated) ...[
            _buildConnectionPrompt(context),
          ] else if (state.isAuthenticated && !hasConnectedBefore) ...[
            _buildJustConnectedState(context, state),
          ] else if (state.isAuthenticated && state.autoBackupEnabled) ...[
            const SizedBox(height: 8),
            _buildProtectionTitle(context),
            const SizedBox(height: 12),
            _buildAutoBackupActiveState(context, state),
          ] else if (state.isAuthenticated && !state.autoBackupEnabled) ...[
            const SizedBox(height: 8),
            _buildManualBackupState(context, state),
          ],
          const SizedBox(height: 24),
          _buildSecurityInfo(context),
        ],
      ),
    );
  }

  Widget _buildOnboardingSuccessCard(BuildContext context, BackupLoaded state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, color: colorScheme.primary, size: 56),
          const SizedBox(height: 16),
          Text(
            'backup.sign_in_success'.tr(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          if (state.userEmail != null) ...[
            const SizedBox(height: 8),
            Text(
              state.userEmail!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Protección automática activada',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
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
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              //Icon(Icons.shield_outlined, color: colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'backup.description_title'.tr(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: Text(
              'backup.description_text'.tr(),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
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
                    context.read<BackupBloc>().add(const SignInToGoogleDrive());
                  },
                  icon: const Icon(Icons.account_circle),
                  label: Text('backup.google_drive_connection'.tr()),
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

  Widget _buildJustConnectedState(BuildContext context, BackupLoaded state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.autorenew, color: colorScheme.primary),
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
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
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
                  onPressed: () => _showLogoutConfirmation(context),
                  child: Text('backup.prefer_manual'.tr()),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

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

  Widget _buildAutoBackupActiveState(BuildContext context, BackupLoaded state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'backup.enable_auto_backup'.tr(),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                Switch(
                  value: state.autoBackupEnabled,
                  onChanged: (value) {
                    if (value) {
                      context
                          .read<BackupBloc>()
                          .add(const ToggleAutoBackup(true));
                    } else {
                      _showLogoutConfirmation(context);
                    }
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () =>
                      BackupConfigurationSheet.show(context, state),
                  icon: Icon(Icons.more_vert, color: colorScheme.primary),
                  tooltip: 'backup.configuration'.tr(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.cloud_done,
                    size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'backup.connected_to_google_drive'.tr(),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  '${'backup.backup_email'.tr()}: ',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                Expanded(
                  child: Text(
                    state.userEmail ?? 'backup.no_email'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (state.lastBackupTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    '${'backup.last_backup'.tr()}: ',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  Expanded(
                    child: Text(
                      _formatLastBackupTime(context, state.lastBackupTime!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildManualBackupState(BuildContext context, BackupLoaded state) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.touch_app,
                    size: 48, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'backup.manual_backup_active'.tr(),
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
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
                Row(
                  children: [
                    Icon(Icons.cloud_done,
                        size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      'backup.connected_to_google_drive'.tr(),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (state.userEmail != null) ...[
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        '${'backup.backup_email'.tr()}: ',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      Expanded(
                        child: Text(
                          state.userEmail!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
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
              ],
            ),
          ),
        ),
        if (state.lastBackupTime != null) ...[
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.history,
                      color: theme.colorScheme.onSurfaceVariant),
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
          Icon(Icons.security, color: colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'backup.security_title'.tr(),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildErrorState(BuildContext context, BackupError state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text('backup.error_loading'.tr(), style: theme.textTheme.titleLarge),
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
              context.read<BackupBloc>().add(const LoadBackupSettings());
            },
            child: Text('backup.retry'.tr()),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('backup.backup_logout_confirmation_title'.tr()),
        content: Text('backup.backup_logout_confirmation_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'backup.backup_cancel'.tr(),
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<BackupBloc>().add(const SignOutFromGoogleDrive());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: Text('backup.backup_confirm'.tr()),
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
}
