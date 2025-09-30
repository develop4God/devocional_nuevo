// lib/pages/onboarding/onboarding_backup_configuration_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/backup_bloc.dart';
import '../../blocs/backup_state.dart';
import '../../blocs/onboarding/onboarding_bloc.dart';
import '../../blocs/onboarding/onboarding_event.dart';
import '../../extensions/string_extensions.dart';
import '../../widgets/backup_settings_content.dart';

class OnboardingBackupConfigurationPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocListener<BackupBloc, BackupState>(
      listener: (context, state) {
        // Only handle errors in onboarding
        if (state is BackupError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message.tr()),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
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
                // Onboarding header
                _buildOnboardingHeader(context),

                // Reuse BackupSettingsContent
                Expanded(
                  child: BackupSettingsContent(isOnboardingMode: true),
                ),

                // Onboarding footer (conditional)
                _buildOnboardingFooter(context),
              ],
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
          // Hide "Skip" button if already connected
          final isConnected = state is BackupLoaded &&
              state.isAuthenticated &&
              state.autoBackupEnabled;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: onBack,
                child: Text('onboarding.onboarding_back'.tr()),
              ),
              if (!isConnected)
                TextButton(
                  onPressed: () {
                    context
                        .read<OnboardingBloc>()
                        .add(const SkipBackupForNow());
                    onSkip();
                  },
                  child: Text('onboarding.onboarding_config_later'.tr()),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOnboardingFooter(BuildContext context) {
    return BlocBuilder<BackupBloc, BackupState>(
      builder: (context, state) {
        // Only show "Continue" button if authenticated AND auto-backup enabled
        final canContinue = state is BackupLoaded &&
            state.isAuthenticated &&
            state.autoBackupEnabled;

        if (!canContinue) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Inform OnboardingBloc that backup was configured
                  context
                      .read<OnboardingBloc>()
                      .add(const ConfigureBackupOption(true));

                  // Navigate to next step
                  onNext();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'onboarding.onboarding_next'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
