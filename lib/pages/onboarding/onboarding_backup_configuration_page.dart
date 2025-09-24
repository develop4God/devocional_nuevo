import 'dart:async';

import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/backup_event.dart';
import 'package:devocional_nuevo/blocs/backup_state.dart';
import 'package:devocional_nuevo/blocs/prayer_bloc.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/providers/devocional_provider.dart';
import 'package:devocional_nuevo/services/backup_scheduler_service.dart';
import 'package:devocional_nuevo/services/connectivity_service.dart';
import 'package:devocional_nuevo/services/google_drive_auth_service.dart';
import 'package:devocional_nuevo/services/google_drive_backup_service.dart';
import 'package:devocional_nuevo/services/spiritual_stats_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class OnboardingBackupConfigurationPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  const OnboardingBackupConfigurationPage({
    super.key,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  @override
  State<OnboardingBackupConfigurationPage> createState() =>
      _OnboardingBackupConfigurationPageState();
}

class _OnboardingBackupConfigurationPageState
    extends State<OnboardingBackupConfigurationPage> {
  bool _isConnecting = false;
  bool _isNavigating = false;
  Timer? _timeoutTimer;

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️ [DEBUG] OnboardingBackupConfigurationPage build iniciado');

    // Create services with dependencies - same as BackupSettingsPage
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
        // 🔧 CRÍTICO: Crear BackupSchedulerService igual que en BackupSettingsPage
        final schedulerService = BackupSchedulerService(
          backupService: backupService,
          connectivityService: connectivityService,
        );
        debugPrint('🔧 [DEBUG] BackupSchedulerService creado para onboarding');

        final bloc = BackupBloc(
          backupService: backupService,
          schedulerService: schedulerService, // 🔧 AGREGADO
          devocionalProvider: Provider.of<DevocionalProvider>(
            context,
            listen: false,
          ),
          prayerBloc: context.read<PrayerBloc>(), // 🔧 AGREGADO
        );

        // Load initial settings
        bloc.add(const LoadBackupSettings());
        return bloc;
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Navigation buttons
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: widget.onBack,
                        child: Text('onboarding.onboarding_back'.tr()),
                      ),
                      TextButton(
                        onPressed: widget.onSkip,
                        child: Text('onboarding.onboarding_config_later'.tr()),
                      ),
                    ],
                  ),
                ),
                // Main content with proper state management
                Expanded(
                  child: BlocListener<BackupBloc, BackupState>(
                    listener: (context, state) {
                      debugPrint(
                          '🔄 [DEBUG] OnboardingBlocListener recibió estado: ${state.runtimeType}');

                      if (state is BackupError) {
                        debugPrint(
                            '❌ [DEBUG] OnboardingBackupError recibido: ${state.message}');
                        _clearConnectingState();
                        _showError(context, state.message);
                      }
                      // 🔧 AGREGADO: Manejar BackupInitial para cancelación de usuario
                      else if (state is BackupInitial) {
                        debugPrint(
                            '🔄 [DEBUG] OnboardingBackupInitial recibido - usuario canceló o estado inicial');
                        _clearConnectingState();
                      } else if (state is BackupLoaded &&
                          state.isAuthenticated) {
                        debugPrint(
                            '✅ [DEBUG] OnboardingBackupLoaded autenticado recibido');
                        _timeoutTimer?.cancel();
                        _autoConfigureBackup(context);

                        // Check if we need to create initial backup for new users
                        _checkAndCreateInitialBackup(context, state);

                        setState(() {
                          _isNavigating = true;
                        });
                        // Delay to allow auto-configuration to complete
                        Future.delayed(const Duration(milliseconds: 2500), () {
                          if (mounted) {
                            debugPrint(
                                '🚀 [DEBUG] Navegando al siguiente paso del onboarding');
                            widget.onNext();
                          }
                        });
                      } else if (state is BackupSuccess) {
                        debugPrint(
                            '✅ [DEBUG] OnboardingBackupSuccess recibido: ${state.title}');
                      } else if (state is BackupRestored) {
                        debugPrint(
                            '✅ [DEBUG] OnboardingBackupRestored recibido');
                      }
                    },
                    child: BlocBuilder<BackupBloc, BackupState>(
                      builder: (context, state) {
                        if (state is BackupLoading && !_isConnecting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: _buildContent(context, state),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, BackupState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildConnectionPrompt(context),
        const SizedBox(height: 32),
        _buildSecurityInfo(context),
      ],
    );
  }

  Widget _buildConnectionPrompt(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Google Drive icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.cloud,
            color: Colors.white,
            size: 50,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'backup.description_title'.tr(),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'backup.description_text'.tr(),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_isConnecting || _isNavigating)
                ? null
                : () => _connectGoogleDrive(context),
            icon: (_isConnecting || _isNavigating)
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_to_drive_outlined),
            label: Text(
              (_isConnecting || _isNavigating)
                  ? 'onboarding.onboarding_connecting'.tr()
                  : 'backup.google_drive_connection'.tr(),
              style: const TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'backup.security_text'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _connectGoogleDrive(BuildContext context) {
    debugPrint('🔄 [DEBUG] Onboarding Usuario tapeó conectar Google Drive');
    setState(() {
      _isConnecting = true;
    });

    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (_isConnecting && mounted) {
        _clearConnectingState();
        _showError(context, 'backup.connection_timeout'.tr());
      }
    });

    debugPrint('🔄 [DEBUG] Onboarding Enviando SignInToGoogleDrive event');
    context.read<BackupBloc>().add(const SignInToGoogleDrive());
  }

  void _autoConfigureBackup(BuildContext context) {
    debugPrint(
        '⚙️ [DEBUG] Onboarding Auto-configurando backup con configuración óptima');

    // Activate automatic backup with all defaults - same as BackupSettingsPage
    context.read<BackupBloc>().add(const ToggleAutoBackup(true));
    context.read<BackupBloc>().add(const ToggleWifiOnly(true));
    context.read<BackupBloc>().add(const ToggleCompression(true));

    debugPrint('✅ [DEBUG] Onboarding Auto-configuración enviada');
  }

  void _checkAndCreateInitialBackup(BuildContext context, BackupLoaded state) {
    // Check if this is first time connecting (same logic as BackupSettingsPage)
    final hasConnectedBefore =
        state.lastBackupTime != null || state.autoBackupEnabled;

    debugPrint('🔍 [DEBUG] hasConnectedBefore: $hasConnectedBefore');
    debugPrint('🔍 [DEBUG] lastBackupTime: ${state.lastBackupTime}');
    debugPrint('🔍 [DEBUG] autoBackupEnabled: ${state.autoBackupEnabled}');

    if (!hasConnectedBefore) {
      debugPrint('🆕 [DEBUG] Usuario nuevo detectado - creando primer backup');
      // Create initial backup for new users
      context.read<BackupBloc>().add(const CreateManualBackup());
    } else {
      debugPrint('✅ [DEBUG] Usuario existente - no necesita backup inicial');
    }
  }

  void _clearConnectingState() {
    _timeoutTimer?.cancel();
    if (mounted) {
      setState(() {
        _isConnecting = false;
        _isNavigating = false;
      });
      debugPrint('🔄 [DEBUG] Estado de connecting limpiado en onboarding');
    }
  }

  void _showError(BuildContext context, String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.tr()),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
