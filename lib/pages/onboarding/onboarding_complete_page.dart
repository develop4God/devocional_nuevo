import 'dart:math' as math;

import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/onboarding/onboarding_bloc.dart';
import '../../blocs/onboarding/onboarding_state.dart';

class OnboardingCompletePage extends StatefulWidget {
  final VoidCallback onStartApp;

  const OnboardingCompletePage({super.key, required this.onStartApp});

  @override
  State<OnboardingCompletePage> createState() => _OnboardingCompletePageState();
}

class _OnboardingCompletePageState extends State<OnboardingCompletePage>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _particleController;
  late AnimationController _pulseController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _celebrationController.forward();
    _particleController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [
              colorScheme.primary.withValues(alpha: 0.08),
              colorScheme.primaryContainer.withValues(alpha: 0.03),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Celebration icon with particles
                SizedBox(
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background particles
                      ...List.generate(8, (index) {
                        return AnimatedBuilder(
                          animation: _particleAnimation,
                          builder: (context, child) {
                            final angle = (index * 45.0) * (math.pi / 180);
                            final distance =
                                60 + (40 * _particleAnimation.value);
                            final x = distance *
                                math.cos(angle +
                                    _particleAnimation.value * 2 * math.pi);
                            final y = distance *
                                math.sin(angle +
                                    _particleAnimation.value * 2 * math.pi);

                            return Transform.translate(
                              offset: Offset(x, y),
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.3 * (1 - _particleAnimation.value),
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                        );
                      }),

                      // Main celebration icon
                      AnimatedBuilder(
                        animation: Listenable.merge(
                            [_scaleAnimation, _pulseAnimation]),
                        builder: (context, child) {
                          return Transform.scale(
                            scale:
                                _scaleAnimation.value * _pulseAnimation.value,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary,
                                    colorScheme.secondary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.celebration_outlined,
                                color: colorScheme.onPrimary,
                                size: 70,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Title with animation
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Text(
                          'onboarding.onboarding_complete_title'.tr(),
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Subtitle
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Text(
                          'onboarding.onboarding_complete_subtitle'.tr(),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Setup summary card
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - _fadeAnimation.value)),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: _buildSetupSummaryCard(context),
                      ),
                    );
                  },
                ),

                const Spacer(flex: 2),

                // Start button
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.secondary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: widget.onStartApp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'onboarding.onboarding_start_app'.tr(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetupSummaryCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        Map<String, dynamic> configurations = {};
        if (state is OnboardingCompleted) {
          configurations = state.appliedConfigurations;
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                colorScheme.surfaceContainer.withValues(alpha: 0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'onboarding.onboarding_your_setup'.tr(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Theme configuration
              _buildSetupItem(
                context,
                Icons.palette_outlined,
                _getThemeStatusMessage(configurations),
                true,
              ),

              const SizedBox(height: 16),

              // Backup configuration
              _buildSetupItem(
                context,
                _getBackupStatusIcon(configurations),
                _getBackupStatusMessage(configurations),
                _isBackupConfigured(configurations) ||
                    _wasBackupSkipped(configurations),
              ),

              const SizedBox(height: 16),

              // Data protection
              _buildSetupItem(
                context,
                Icons.shield_outlined,
                'Protección de datos activada',
                true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSetupItem(
    BuildContext context,
    IconData icon,
    String text,
    bool isConfigured,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isConfigured
                ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                : colorScheme.outline.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isConfigured
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.6),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isConfigured
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isConfigured
                ? colorScheme.primary.withValues(alpha: 0.1)
                : colorScheme.outline.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isConfigured ? Icons.check : Icons.remove,
            color: isConfigured
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.6),
            size: 16,
          ),
        ),
      ],
    );
  }

  bool _isBackupConfigured(Map<String, dynamic> configurations) {
    return configurations['backupEnabled'] == true;
  }

  bool _wasBackupSkipped(Map<String, dynamic> configurations) {
    return configurations['backupSkipped'] == true;
  }

  IconData _getBackupStatusIcon(Map<String, dynamic> configurations) {
    if (_isBackupConfigured(configurations)) {
      return Icons.cloud_done_outlined;
    } else if (_wasBackupSkipped(configurations)) {
      return Icons.schedule_outlined;
    } else {
      return Icons.cloud_off_outlined;
    }
  }

  String _getBackupStatusMessage(Map<String, dynamic> configurations) {
    if (_isBackupConfigured(configurations)) {
      return 'Respaldo automático configurado';
    } else if (_wasBackupSkipped(configurations)) {
      return 'Podrás configurar el respaldo más tarde';
    } else {
      return 'Respaldo omitido';
    }
  }

  String _getThemeStatusMessage(Map<String, dynamic> configurations) {
    final selectedTheme = configurations['selectedThemeFamily'] as String?;
    if (selectedTheme != null && selectedTheme.isNotEmpty) {
      return 'Tema "$selectedTheme" seleccionado';
    }
    return 'Tema personalizado seleccionado';
  }
}
