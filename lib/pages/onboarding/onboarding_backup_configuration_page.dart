import 'dart:async';

import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/backup_event.dart';
import 'package:devocional_nuevo/blocs/backup_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  Timer? _timeoutTimer;

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    if (state is BackupLoaded && state.isAuthenticated) {
                      _clearConnectingState();
                      _autoConfigureBackup(context);
                      // Advance directly without showing success state
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          widget.onNext();
                        }
                      });
                    } else if (state is BackupError) {
                      _clearConnectingState();
                      _showError(context, state.message);
                    } else if (state is BackupLoaded &&
                        !state.isAuthenticated &&
                        _isConnecting) {
                      _clearConnectingState();
                    }
                  },
                  child: BlocBuilder<BackupBloc, BackupState>(
                    builder: (context, state) {
                      if (state is BackupLoading && !_isConnecting) {
                        return const Center(child: CircularProgressIndicator());
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
            onPressed:
                _isConnecting ? null : () => _connectGoogleDrive(context),
            icon: _isConnecting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_to_drive_outlined),
            label: Text(
              _isConnecting
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

    context.read<BackupBloc>().add(const SignInToGoogleDrive());
  }

  void _autoConfigureBackup(BuildContext context) {
    context.read<BackupBloc>().add(const ToggleAutoBackup(true));
    context.read<BackupBloc>().add(const ChangeBackupFrequency('daily'));
    context.read<BackupBloc>().add(const ToggleWifiOnly(true));
    context.read<BackupBloc>().add(const ToggleCompression(true));
    context.read<BackupBloc>().add(
          const UpdateBackupOptions({
            'spiritual_stats': true,
            'favorite_devotionals': true,
            'saved_prayers': true,
          }),
        );
  }

  void _clearConnectingState() {
    _timeoutTimer?.cancel();
    if (mounted) {
      setState(() {
        _isConnecting = false;
      });
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
