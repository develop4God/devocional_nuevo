// lib/pages/backup_settings_page.dart
import 'package:devocional_nuevo/widgets/devocionales/app_bar_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../blocs/backup_bloc.dart';
import '../blocs/backup_event.dart';
import '../blocs/backup_state.dart';
import '../blocs/prayer_bloc.dart';
import '../blocs/theme/theme_bloc.dart';
import '../blocs/theme/theme_state.dart';
import '../extensions/string_extensions.dart';
import '../models/backup_content_summary.dart';
import '../providers/devocional_provider.dart';
import '../services/backup/i_google_drive_backup_service.dart';
import '../services/service_locator.dart';
import '../widgets/backup_configuration_sheet.dart';
import 'package:devocional_nuevo/utils/constants/constants.dart';

List<({IconData icon, String label, int count})> _summaryItems(
  BackupContentSummary summary,
) =>
    [
      (
        icon: Icons.local_fire_department_outlined,
        label: 'backup.saved_prayers'.tr(),
        count: summary.prayersCount,
      ),
      (
        icon: Icons.sentiment_very_satisfied,
        label: 'thanksgiving.thanksgivings'.tr(),
        count: summary.thanksgivingsCount,
      ),
      (
        icon: Icons.photo_filter_outlined,
        label: 'testimony.testimonies'.tr(),
        count: summary.testimoniesCount,
      ),
      (
        icon: Icons.star_border_outlined,
        label: 'backup.favorite_devotionals'.tr(),
        count: summary.favoritesCount,
      ),
      (
        icon: Icons.location_history_outlined,
        label: 'encounters.section_title'.tr(),
        count: summary.encountersCount,
      ),
      (
        icon: Icons.school_outlined,
        label: 'discovery.discovery_studies'.tr(),
        count: summary.discoveryCount,
      ),
      (
        icon: Icons.auto_stories_outlined,
        label: 'backup.read_devotionals'.tr(),
        count: summary.readDevocionalesCount,
      ),
      (
        icon: Icons.bookmark,
        label: 'backup.saved_verses'.tr(),
        count: summary.versesCount,
      ),
      (
        icon: Icons.check_circle_outline,
        label: 'prayer.answered_prayers'.tr(),
        count: summary.answeredPrayersCount,
      ),
    ].where((e) => e.count > 0).toList();

/// BackupSettingsPage with simplified progressive UI
class BackupSettingsPage extends StatelessWidget {
  final BackupBloc? bloc; // Optional bloc for testing

  const BackupSettingsPage({super.key, this.bloc});

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️ [DEBUG] BackupSettingsPage build started');

    // If bloc is provided (e.g., in tests), use it directly
    if (bloc != null) {
      return BlocProvider.value(
        value: bloc!,
        child: const _BackupSettingsView(),
      );
    }

    // Otherwise, resolve services via DI (production)
    return BlocProvider(
      create: (context) {
        final backupBloc = BackupBloc(
          backupService: getService<IGoogleDriveBackupService>(),
          devocionalProvider: Provider.of<DevocionalProvider>(
            context,
            listen: false,
          ),
          prayerBloc: context.read<PrayerBloc>(), // 🔧 RESTAURADO
        );

        backupBloc.add(const LoadBackupSettings());
        return backupBloc;
      },
      child: const _BackupSettingsView(),
    );
  }
}

class _BackupSettingsView extends StatefulWidget {
  const _BackupSettingsView();

  @override
  State<_BackupSettingsView> createState() => _BackupSettingsViewState();
}

class _BackupSettingsViewState extends State<_BackupSettingsView> {
  bool _successDialogShown = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final themeState = context.watch<ThemeBloc>().state as ThemeLoaded;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeState.systemUiOverlayStyle,
      child: Scaffold(
        appBar: CustomAppBar(titleText: 'backup.title'.tr()),
        body: BlocListener<BackupBloc, BackupState>(
          listener: (context, state) async {
            debugPrint(
              '🔄 [DEBUG] BlocListener recibió estado: ${state.runtimeType}',
            );

            // Reset success dialog flag when going back to initial/loaded state
            if (state is BackupLoaded || state is BackupInitial) {
              setState(() => _successDialogShown = false);
            }

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
              final messenger = ScaffoldMessenger.of(context);
              if (state.restoredVersion != null &&
                  state.restoredVersion!.isNotEmpty) {
                final provider = context.read<DevocionalProvider>();
                if (provider.selectedVersion != state.restoredVersion) {
                  await provider.setSelectedVersion(state.restoredVersion!);
                  debugPrint(
                    '🔄 [RESTORE] Bible version switched to ${state.restoredVersion}',
                  );
                }
              }
              messenger.showSnackBar(
                SnackBar(
                  content: Text('backup.restored_successfully'.tr()),
                  backgroundColor: colorScheme.primary,
                ),
              );
            } else if (state is BackupSuccess && !_successDialogShown) {
              debugPrint('✅ [DEBUG] BackupSuccess recibido — mostrando shield');
              setState(() => _successDialogShown = true);
              _showShieldSuccessDialog(context, state);
            }
          },
          child: BlocBuilder<BackupBloc, BackupState>(
            builder: (context, state) {
              if (state is BackupSigningIn) {
                return _buildGoogleDriveLottieScreen(
                  context,
                  isRestoring: false,
                );
              }

              if (state is BackupRestoring) {
                return _buildGoogleDriveLottieScreen(
                  context,
                  isRestoring: true,
                );
              }

              if (state is BackupLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is BackupLoaded) {
                return _BackupSettingsContent(state: state);
              }

              if (state is BackupSuccess) {
                // Show loaded content underneath while dialog is shown
                return const Center(child: CircularProgressIndicator());
              }

              if (state is BackupError) {
                // Solución: agregar la declaración de 'theme' en el metodo donde falta
                final theme = Theme.of(context);
                final colorScheme = theme.colorScheme;

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
                          context.read<BackupBloc>().add(
                                const LoadBackupSettings(),
                              );
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
      ),
    );
  }

  Widget _buildGoogleDriveLottieScreen(
    BuildContext context, {
    required bool isRestoring,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/lottie/google_logo.json',
              width: 180,
              height: 180,
            ),
            const SizedBox(height: 24),
            Text(
              isRestoring
                  ? 'backup.restoring_title'.tr()
                  : 'backup.signing_in_title'.tr(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isRestoring
                  ? 'backup.restoring_subtitle'.tr()
                  : 'backup.signing_in_subtitle'.tr(),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showShieldSuccessDialog(BuildContext context, BackupSuccess state) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ShieldSuccessDialog(state: state),
    );
  }
}

/// Full-screen dialog that plays the shield_check Lottie animation on success
/// and auto-dismisses after the animation completes.
class _ShieldSuccessDialog extends StatefulWidget {
  final BackupSuccess state;

  const _ShieldSuccessDialog({required this.state});

  @override
  State<_ShieldSuccessDialog> createState() => _ShieldSuccessDialogState();
}

class _ShieldSuccessDialogState extends State<_ShieldSuccessDialog> {
  @override
  void initState() {
    super.initState();
    // Auto-dismiss after 3 seconds so user returns to the updated screen
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  /// One-line horizontal summary of non-zero item counts.
  Widget _buildSummaryLine(BuildContext context, BackupContentSummary summary) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final items = _summaryItems(summary);

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: items
          .map(
            (item) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: 14, color: colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  '${item.label}: ${item.count}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/lottie/shield_check.json',
                    width: 220,
                    height: 220,
                    repeat: false,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'backup.protected_title'.tr(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'backup.protected_subtitle'.tr(),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Content summary
                  if (widget.state.contentSummary != null &&
                      !widget.state.contentSummary!.isEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSummaryLine(context, widget.state.contentSummary!),
                  ],
                ],
              ),
            ),
          ),
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
          const SizedBox(height: 8),

          // Progressive content based on state
          if (!state.isAuthenticated) ...[
            _buildConnectionPrompt(context),
          ] else if (state.isAuthenticated && !hasConnectedBefore) ...[
            _buildJustConnectedState(context),
          ] else if (state.isAuthenticated && state.autoBackupEnabled) ...[
            const SizedBox(height: 8),
            _buildProtectionTitle(context),
            const SizedBox(height: 12),
            _buildAutoBackupActiveState(context, state),
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

  Widget _buildJustConnectedState(BuildContext context) {
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
                      context.read<BackupBloc>().add(
                            const ToggleAutoBackup(true),
                          );
                      context.read<BackupBloc>().add(
                            const ToggleWifiOnly(true),
                          );
                      context.read<BackupBloc>().add(
                            const ToggleCompression(true),
                          );
                    },
                    child: Text('backup.activate_automatic'.tr()),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    _showLogoutConfirmation(context);
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

  Widget _buildProtectionTitle(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const Icon(Icons.security, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'backup.protection_active'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'backup.enable_auto_backup'.tr(),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: state.autoBackupEnabled,
                  onChanged: (value) {
                    if (value) {
                      context.read<BackupBloc>().add(ToggleAutoBackup(true));
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
                  tooltip: 'backup.more_options'.tr(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.cloud_done,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'backup.connected_to_google_drive'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '${'backup.backup_email'.tr()}: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
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
            const SizedBox(height: 8),
            // Last backup
            if (state.lastBackupTime != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${'backup.last_backup'.tr()}: ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
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
              const SizedBox(height: 8),
            ],
            // Next backup
            Row(
              children: [
                Icon(
                  Icons.schedule_send,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '${'backup.next_backup'.tr()}: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Text(
                    _formatNextBackupTime(context, state.lastBackupTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            // Content summary — what is protected
            if (state.contentSummary != null &&
                !state.contentSummary!.isEmpty) ...[
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 10),
              _buildContentSummaryChips(context, state.contentSummary!),
            ],
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
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
        );
      },
    );
  }

  /// Compact chip row showing non-zero item counts from the backup payload.
  ///
  /// Uses 100 % existing translation keys — no new keys except [backup.saved_verses].
  Widget _buildContentSummaryChips(
    BuildContext context,
    BackupContentSummary summary,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final items = _summaryItems(summary);

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 12, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                '${item.label}: ${item.count}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
      return 'backup.days_ago'.tr().replaceAll(
            '{days}',
            difference.inDays.toString(),
          );
    }
  }

  String _formatNextBackupTime(BuildContext context, DateTime? lastBackupTime) {
    if (lastBackupTime == null) {
      debugPrint('[BACKUP] No lastBackupTime found, showing no_backup_yet');
      return 'backup.no_backup_yet'.tr();
    }
    final now = DateTime.now();
    final elapsed = now.difference(lastBackupTime);
    final totalMinutes = elapsed.inMinutes;
    final minutesLeft = BackupSchedule.intervalHours * 60 - totalMinutes;

    debugPrint('[BACKUP] lastBackupTime: $lastBackupTime');
    debugPrint('[BACKUP] now: $now');
    debugPrint(
      '[BACKUP] elapsed: ${elapsed.inHours}h ${elapsed.inMinutes % 60}m',
    );
    debugPrint('[BACKUP] minutesLeft before next backup: $minutesLeft');

    if (minutesLeft <= 0) {
      return 'backup.next_backup_in_minutes'.tr().replaceAll('{minutes}', '0');
    } else if (minutesLeft < 60) {
      debugPrint('[BACKUP] Showing: Próxima copia en $minutesLeft minutos');
      return 'backup.next_backup_in_minutes'.tr().replaceAll(
            '{minutes}',
            minutesLeft.toString(),
          );
    } else {
      final hoursLeft = minutesLeft ~/ 60;
      debugPrint('[BACKUP] Showing: Próxima copia en $hoursLeft horas');
      return 'backup.next_backup_in_hours'.tr().replaceAll(
            '{hours}',
            hoursLeft.toString(),
          );
    }
  }
}
