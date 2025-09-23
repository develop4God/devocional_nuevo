import 'dart:async';

import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/backup_event.dart';
import 'package:devocional_nuevo/blocs/backup_state.dart';
import 'package:devocional_nuevo/utils/localization_extension.dart';
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
                      child: Text('onboarding_back'.tr()),
                    ),
                    TextButton(
                      onPressed: widget.onSkip,
                      child: Text('onboarding_skip_for_now'.tr()),
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                          size: 40,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Title
                      Text(
                        'onboarding_backup_title'.tr(),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Subtitle
                      Text(
                        'onboarding_backup_subtitle'.tr(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                              height: 1.5,
                            ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 48),

                      // Connect Google Drive button
                      BlocConsumer<BackupBloc, BackupState>(
                        listener: (context, state) {
                          if (state is BackupLoaded && state.isAuthenticated) {
                            setState(() {
                              _isConnecting = false;
                            });
                            // Auto-configure cuando se conecta exitosamente
                            _autoConfigureBackup(context);
                            widget.onNext();
                          } else if (state is BackupError) {
                            setState(() {
                              _isConnecting = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(state.message),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else if (state is BackupLoaded && !state.isAuthenticated && _isConnecting) {
                            // Handle case where user cancelled the authentication
                            setState(() {
                              _isConnecting = false;
                            });
                          }
                        },
                        builder: (context, state) {
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isConnecting
                                  ? null
                                  : () => _connectGoogleDrive(context),
                              icon: _isConnecting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.cloud_upload),
                              label: Text(
                                _isConnecting
                                    ? 'onboarding_connecting'.tr()
                                    : 'onboarding_connect_google_drive'.tr(),
                                style: const TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Recommended badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'onboarding_recommended'.tr(),
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Security info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'onboarding_backup_security_info'.tr(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.8),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Configure later button
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: widget.onNext,
                    child: Text(
                      'onboarding_configure_later'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _connectGoogleDrive(BuildContext context) {
    setState(() {
      _isConnecting = true;
    });

    // Add timeout protection to prevent infinite connecting state
    Timer(const Duration(seconds: 30), () {
      if (_isConnecting && mounted) {
        setState(() {
          _isConnecting = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('onboarding_connection_timeout'.tr()),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });

    context.read<BackupBloc>().add(const SignInToGoogleDrive());
  }

  void _autoConfigureBackup(BuildContext context) {
    // Configurar backup automático con configuración óptima
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Drive conectado y configurado automáticamente'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
