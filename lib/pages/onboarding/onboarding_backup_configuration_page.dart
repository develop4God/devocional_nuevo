// lib/pages/onboarding/onboarding_backup_configuration_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/backup_bloc.dart';
import '../../blocs/backup_event.dart';
import '../../blocs/backup_state.dart';
import '../../blocs/onboarding/onboarding_bloc.dart';
import '../../blocs/onboarding/onboarding_event.dart';
import '../../blocs/onboarding/onboarding_state.dart';
import '../../blocs/prayer_bloc.dart';
import '../../extensions/string_extensions.dart';
import '../../providers/devocional_provider.dart';
import '../../services/backup/i_google_drive_backup_service.dart';
import '../../services/service_locator.dart';
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

  /// True when the onboarding bloc already recorded backup as configured
  /// on entry to this page (e.g. the user connected, moved on, then came
  /// back). In that case there is nothing left to configure or undo, so
  /// the auto-configure/auto-advance flow below must not re-run.
  late final bool _wasAlreadyConfiguredOnEntry;

  @override
  void initState() {
    super.initState();
    final onboardingState = context.read<OnboardingBloc>().state;
    _wasAlreadyConfiguredOnEntry = onboardingState is OnboardingStepActive &&
        onboardingState.userSelections['backupEnabled'] == true;
    _hasConfiguredBackup = _wasAlreadyConfiguredOnEntry;
  }

  @override
  Widget build(BuildContext context) {
    // Use services from the service locator
    final backupService = getService<IGoogleDriveBackupService>();

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
                content: Text(state.localizedMessage),
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
              '✅ [ONBOARDING] Usuario autenticado, configurando backup UNA VEZ',
            );
            _hasConfiguredBackup = true; // ← Evita re-ejecuciones

            // Configurar backup en OnboardingBloc
            context.read<OnboardingBloc>().add(
                  const ConfigureBackupOption(true),
                );

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
              top: false,
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
                  // Safeguard: if backup is already connected (e.g. the
                  // one-shot auto-advance above never ran because the
                  // page was entered in an already-configured state),
                  // always offer an explicit way forward instead of
                  // leaving the user stranded with Back disabled and
                  // Skip hidden.
                  BlocBuilder<BackupBloc, BackupState>(
                    builder: (context, state) {
                      final isConnected =
                          state is BackupLoaded && state.isAuthenticated;
                      if (!isConnected) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isNavigating
                                ? null
                                : () {
                                    _isNavigating = true;
                                    widget.onNext();
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'onboarding.onboarding_next'.tr(),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      );
                    },
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
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: BlocBuilder<BackupBloc, BackupState>(
        builder: (context, state) {
          final isConnected = state is BackupLoaded && state.isAuthenticated;
          final isLoading = state is BackupLoading;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: TextButton(
                  // Once connected there is nothing to go back and undo —
                  // disable Back so the user can't re-trigger sign-in by
                  // navigating away and back to this step.
                  onPressed: (isLoading || isConnected || _isNavigating)
                      ? null
                      : widget.onBack,
                  child: Text(
                    'onboarding.onboarding_back'.tr(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (!isConnected && !_isNavigating)
                Flexible(
                  child: TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            if (!_isNavigating) {
                              _isNavigating = true;
                              context.read<OnboardingBloc>().add(
                                    const SkipBackupForNow(),
                                  );
                              widget.onSkip();
                            }
                          },
                    child: Text(
                      'onboarding.onboarding_config_later'.tr(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
