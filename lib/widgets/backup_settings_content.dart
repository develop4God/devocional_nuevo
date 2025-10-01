// lib/widgets/backup_settings_content.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/backup_bloc.dart';
import '../blocs/backup_event.dart';
import '../blocs/backup_state.dart';
import '../extensions/string_extensions.dart';
import '../widgets/backup_configuration_sheet.dart';

enum ConnectionButtonState {
  idle,
  connecting,
  transferring,
  configuring,
  complete
}

class BackupSettingsContent extends StatefulWidget {
  final bool isOnboardingMode;
  final VoidCallback? onConnectionComplete;

  const BackupSettingsContent({
    super.key,
    this.isOnboardingMode = false,
    this.onConnectionComplete,
  });

  @override
  State<BackupSettingsContent> createState() => _BackupSettingsContentState();
}

class _BackupSettingsContentState extends State<BackupSettingsContent> {
  ConnectionButtonState _connectionState = ConnectionButtonState.idle;
  bool _isProcessing = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BackupBloc, BackupState>(
      listener: (context, state) {
        // Manejar estados en tiempo real
        if (state is BackupLoaded && state.isAuthenticated) {
          if (_connectionState == ConnectionButtonState.connecting) {
            setState(() {
              _connectionState = ConnectionButtonState.transferring;
              _isProcessing = true;
            });
          }
        }

        // Cuando termine todo el proceso, desbloquear
        if (state is BackupLoaded &&
            state.isAuthenticated &&
            _connectionState == ConnectionButtonState.complete) {
          setState(() => _isProcessing = false);
        }
      },
      builder: (context, state) {
        if (state is BackupError) {
          setState(() {
            _connectionState = ConnectionButtonState.idle;
            _isProcessing = false;
          });
          return _buildErrorState(context, state);
        }

        if (state is BackupLoaded) {
          return Stack(
            children: [
              _buildContent(context, state),
              if (_isProcessing)
                Positioned.fill(
                  child: AbsorbPointer(
                    absorbing: true,
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
            ],
          );
        }

        // Si llega BackupLoading o cualquier otro estado, mantener el contenido
        // Crear un estado temporal BackupLoaded con isAuthenticated = false
        final tempState = BackupLoaded(
          isAuthenticated: false,
          autoBackupEnabled: false,
          wifiOnlyEnabled: true,
          compressionEnabled: true,
          backupFrequency: 'daily',
          backupOptions: const {},
          lastBackupTime: null,
          nextBackupTime: null,
          estimatedSize: 0,
          storageInfo: const {},
          userEmail: null,
        );
        return Stack(
          children: [
            _buildContent(context, tempState),
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, BackupLoaded state) {
    if (widget.isOnboardingMode && state.isAuthenticated) {
      // Onboarding: auto-configurar y avanzar
      if (_connectionState == ConnectionButtonState.transferring) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(
                () => _connectionState = ConnectionButtonState.configuring);
            context.read<BackupBloc>().add(const ToggleAutoBackup(true));
            context.read<BackupBloc>().add(const ToggleWifiOnly(true));
            context.read<BackupBloc>().add(const ToggleCompression(true));

            Future.delayed(const Duration(milliseconds: 1000), () {
              if (mounted) {
                setState(
                    () => _connectionState = ConnectionButtonState.complete);
                Future.delayed(const Duration(milliseconds: 1000), () {
                  if (mounted && widget.onConnectionComplete != null) {
                    widget.onConnectionComplete!();
                  }
                });
              }
            });
          }
        });
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16)
          .copyWith(bottom: widget.isOnboardingMode ? 16 : 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIntroSection(context),
          const SizedBox(height: 16),
          if (!state.isAuthenticated) ...[
            _buildConnectionPrompt(context),
          ] else if (widget.isOnboardingMode) ...[
            _buildOnboardingConnectedState(context, state),
          ] else if (state.autoBackupEnabled) ...[
            const SizedBox(height: 8),
            _buildProtectionTitle(context),
            const SizedBox(height: 12),
            _buildAutoBackupActiveState(context, state),
          ] else ...[
            const SizedBox(height: 8),
            _buildManualBackupState(context, state),
          ],
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
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
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

    Color buttonColor;
    IconData buttonIcon;
    String buttonText;
    bool isDisabled;

    switch (_connectionState) {
      case ConnectionButtonState.connecting:
        buttonColor = colorScheme.primary;
        buttonIcon = Icons.login;
        buttonText = 'Conectando...';
        isDisabled = true;
        break;
      case ConnectionButtonState.transferring:
        buttonColor = colorScheme.primary;
        buttonIcon = Icons.sync;
        buttonText = 'Transfiriendo datos...';
        isDisabled = true;
        break;
      case ConnectionButtonState.configuring:
        buttonColor = colorScheme.primary;
        buttonIcon = Icons.settings;
        buttonText = 'Configurando respaldo...';
        isDisabled = true;
        break;
      case ConnectionButtonState.complete:
        buttonColor = colorScheme.primary;
        buttonIcon = Icons.check_circle;
        buttonText = '¡Completado!';
        isDisabled = true;
        break;
      default:
        buttonColor = colorScheme.primary;
        buttonIcon = Icons.account_circle;
        buttonText = 'backup.google_drive_connection'.tr();
        isDisabled = false;
    }

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: isDisabled ? null : _handleConnect,
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
                  onPressed: isDisabled ? null : _handleConnect,
                  icon: _connectionState == ConnectionButtonState.idle
                      ? Icon(buttonIcon)
                      : SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                  label: Text(
                    buttonText,
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: buttonColor.withValues(alpha: 0.7),
                    disabledForegroundColor:
                        Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleConnect() {
    setState(() {
      _connectionState = ConnectionButtonState.connecting;
      _isProcessing = false;
    });
    context.read<BackupBloc>().add(const SignInToGoogleDrive());
  }

  Widget _buildOnboardingConnectedState(
      BuildContext context, BackupLoaded state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String statusText;
    IconData statusIcon;
    Color statusColor;

    switch (_connectionState) {
      case ConnectionButtonState.transferring:
        statusText = 'Transfiriendo memoria...';
        statusIcon = Icons.sync;
        statusColor = colorScheme.primary;
        break;
      case ConnectionButtonState.configuring:
        statusText = 'Configurando respaldo automático...';
        statusIcon = Icons.settings;
        statusColor = colorScheme.primary;
        break;
      case ConnectionButtonState.complete:
        statusText = '¡Respaldo activado exitosamente!';
        statusIcon = Icons.check_circle;
        statusColor = colorScheme.primary;
        break;
      default:
        statusText = 'Conectado';
        statusIcon = Icons.cloud_done;
        statusColor = colorScheme.primary;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(statusIcon, size: 48, color: statusColor),
          const SizedBox(height: 16),
          Text(
            statusText,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: statusColor,
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
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProtectionTitle(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(Icons.security, color: colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            'backup.protection_active'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
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
              setState(() => _connectionState = ConnectionButtonState.idle);
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
