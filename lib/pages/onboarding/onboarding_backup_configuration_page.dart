// lib/pages/onboarding/onboarding_backup_configuration_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/backup_bloc.dart';
import '../../blocs/backup_event.dart';
import '../../blocs/backup_state.dart';
import '../../blocs/onboarding/onboarding_bloc.dart';
import '../../blocs/onboarding/onboarding_event.dart';
import '../../blocs/prayer_bloc.dart';
import '../../extensions/string_extensions.dart';
import '../../providers/devocional_provider.dart';
import '../../services/connectivity_service.dart';
import '../../services/google_drive_auth_service.dart';
import '../../services/google_drive_backup_service.dart';
import '../../services/spiritual_stats_service.dart';
import '../../widgets/backup_settings_content.dart';

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
  // 🔧 CRÍTICO: Bandera para evitar múltiples configuraciones
  bool _hasConfiguredBackup = false;
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    // Create BackupBloc locally with all required services
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
        devocionalProvider: context.read<DevocionalProvider>(),
        prayerBloc: context.read<PrayerBloc>(),
      )..add(const LoadBackupSettings()),
      child: BlocListener<BackupBloc, BackupState>(
        listener: (context, state) {
          if (state is BackupError && !_isNavigating) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message.tr()),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }

          // 🔧 CRÍTICO: Solo configurar UNA VEZ cuando se autentique exitosamente
          if (state is BackupLoaded &&
              state.isAuthenticated &&
              !_hasConfiguredBackup &&
              !_isNavigating) {
            debugPrint(
                '✅ [ONBOARDING] Usuario autenticado, configurando backup UNA VEZ');
            _hasConfiguredBackup = true; // ← Evita re-ejecuciones

            // Configurar backup en OnboardingBloc
            context
                .read<OnboardingBloc>()
                .add(const ConfigureBackupOption(true));

            // Navegar después de un delay
            Future.delayed(const Duration(milliseconds: 2000), () {
              if (mounted && !_isNavigating) {
                _isNavigating = true;
                widget.onNext();
              }
            });
          }
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
                  _buildOnboardingHeader(context),
                  Expanded(
                    child: BackupSettingsContent(
                      isOnboardingMode: true,
                      onConnectionComplete: () {
                        if (!_isNavigating) {
                          _isNavigating = true;
                          widget.onNext();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: BlocBuilder<BackupBloc, BackupState>(
        builder: (context, state) {
          final isConnected = state is BackupLoaded && state.isAuthenticated;
          final isLoading = state is BackupLoading;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: (isLoading || _isNavigating) ? null : widget.onBack,
                child: Text('onboarding.onboarding_back'.tr()),
              ),
              if (!isConnected && !_isNavigating)
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          if (!_isNavigating) {
                            _isNavigating = true;
                            context
                                .read<OnboardingBloc>()
                                .add(const SkipBackupForNow());
                            widget.onSkip();
                          }
                        },
                  child: Text('onboarding.onboarding_config_later'.tr()),
                ),
            ],
          );
        },
      ),
    );
  }
}
