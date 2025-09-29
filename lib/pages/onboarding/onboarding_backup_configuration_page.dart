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

import '../../blocs/onboarding/onboarding_bloc.dart';
import '../../blocs/onboarding/onboarding_event.dart';

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
  bool _hasAutoConfigured = false;
  bool _hasNavigated = false;
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
    final connectivityService = ConnectivityService();
    final statsService = SpiritualStatsService();
    final backupService = GoogleDriveBackupService(
      authService: authService,
      connectivityService: connectivityService,
      statsService: statsService,
    );

    return BlocProvider(
      create: (context) {
        final schedulerService = BackupSchedulerService(
          backupService: backupService,
          connectivityService: connectivityService,
        );

        final bloc = BackupBloc(
          backupService: backupService,
          schedulerService: schedulerService,
          devocionalProvider: Provider.of<DevocionalProvider>(
            context,
            listen: false,
          ),
          prayerBloc: context.read<PrayerBloc>(),
        );

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
                        onPressed: () {
                          context
                              .read<OnboardingBloc>()
                              .add(const SkipBackupForNow());
                          widget.onSkip();
                        },
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
                            '❌ [DEBUG] OnboardingBackupError: ${state.message}');
                        _clearTimeoutTimer();
                        _showError(context, state.message);
                      } else if (state is BackupInitial) {
                        debugPrint(
                            '🔄 [DEBUG] BackupInitial - usuario canceló o estado inicial');
                        _clearTimeoutTimer();
                      } else if (state is BackupLoaded) {
                        _handleBackupLoadedState(context, state);
                      } else if (state is BackupRestoring) {
                        debugPrint('🔄 [DEBUG] BackupRestoring detectado');
                      } else if (state is BackupRestored) {
                        debugPrint('✅ [DEBUG] BackupRestored detectado');
                      }
                    },
                    child: BlocBuilder<BackupBloc, BackupState>(
                      builder: (context, state) {
                        if (state is BackupLoading) {
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

  void _handleBackupLoadedState(BuildContext context, BackupLoaded state) {
    debugPrint(
        '🔍 [DEBUG] BackupLoaded - isAuth: ${state.isAuthenticated}, autoEnabled: ${state.autoBackupEnabled}, hasConfigured: $_hasAutoConfigured, hasNavigated: $_hasNavigated');

    // Usuario ya estaba autenticado (session persistida)
    if (state.isAuthenticated &&
        !_hasAutoConfigured &&
        !_hasNavigated &&
        state.autoBackupEnabled) {
      debugPrint(
          '✅ [DEBUG] Usuario ya autenticado con backup activo - navegando');
      _hasNavigated = true;
      _clearTimeoutTimer();

      context.read<OnboardingBloc>().add(const ConfigureBackupOption(true));

      // Navegar inmediatamente
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onNext();
        }
      });
      return;
    }

    // Usuario acaba de autenticarse (nuevo login)
    if (state.isAuthenticated && !_hasAutoConfigured) {
      debugPrint('🔧 [DEBUG] Usuario recién autenticado - auto-configurando');
      _hasAutoConfigured = true;
      _clearTimeoutTimer();

      // Auto-configurar backup
      context.read<BackupBloc>().add(const ToggleAutoBackup(true));
      context.read<BackupBloc>().add(const ToggleWifiOnly(true));
      context.read<BackupBloc>().add(const ToggleCompression(true));

      // Informar al OnboardingBloc
      context.read<OnboardingBloc>().add(const ConfigureBackupOption(true));

      // Crear backup inicial si es usuario nuevo
      _checkAndCreateInitialBackup(context, state);
      return;
    }

    // Verificar si ya está todo configurado para navegar
    if (state.isAuthenticated &&
        state.autoBackupEnabled &&
        _hasAutoConfigured &&
        !_hasNavigated) {
      debugPrint('🚀 [DEBUG] Backup configurado completamente - navegando');
      _hasNavigated = true;

      // Navegar inmediatamente
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onNext();
        }
      });
    }
  }

  Widget _buildContent(BuildContext context, BackupState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildConnectionPrompt(context, state),
        const SizedBox(height: 32),
        _buildSecurityInfo(context),
      ],
    );
  }

  Widget _buildConnectionPrompt(BuildContext context, BackupState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determinar texto del botón según estado
    String buttonText = 'backup.google_drive_connection'.tr();
    bool isDisabled = false;

    if (state is BackupLoading) {
      buttonText = 'onboarding.onboarding_connecting'.tr();
      isDisabled = true;
    } else if (state is BackupRestoring) {
      buttonText = 'backup.restoring_data'.tr();
      isDisabled = true;
    } else if (state is BackupLoaded && state.isAuthenticated) {
      if (!state.autoBackupEnabled && _hasAutoConfigured) {
        buttonText = 'backup.configuring_backup'.tr();
        isDisabled = true;
      } else if (state.autoBackupEnabled) {
        buttonText = 'backup.backup_configured'.tr();
        isDisabled = true;
      }
    }

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
            onPressed: isDisabled ? null : () => _connectGoogleDrive(context),
            icon: isDisabled
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_to_drive_outlined),
            label: Text(
              buttonText,
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

    // Iniciar timeout de 30 segundos
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (!_hasNavigated && mounted) {
        _showError(context, 'backup.connection_timeout'.tr());
      }
    });

    debugPrint('🔄 [DEBUG] Onboarding Enviando SignInToGoogleDrive event');
    context.read<BackupBloc>().add(const SignInToGoogleDrive());
  }

  void _checkAndCreateInitialBackup(BuildContext context, BackupLoaded state) {
    final hasConnectedBefore =
        state.lastBackupTime != null || state.autoBackupEnabled;

    debugPrint('🔍 [DEBUG] hasConnectedBefore: $hasConnectedBefore');

    if (!hasConnectedBefore) {
      debugPrint('🆕 [DEBUG] Usuario nuevo - creando primer backup');
      context.read<BackupBloc>().add(const CreateManualBackup());
    }
  }

  void _clearTimeoutTimer() {
    _timeoutTimer?.cancel();
    debugPrint('⏱️ [DEBUG] Timeout timer cancelado');
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
