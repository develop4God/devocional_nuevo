import 'dart:math' as math;

import 'package:devocional_nuevo/blocs/onboarding/onboarding_bloc.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_state.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),

                    // Celebration icon with particles (responsive size)
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.25,
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
                                        alpha: 0.3 *
                                            (1 - _particleAnimation.value),
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
                                scale: _scaleAnimation.value *
                                    _pulseAnimation.value,
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

                    SizedBox(height: MediaQuery.of(context).size.height * 0.04),

                    // Title with animation (responsive sizing)
                    AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: Text(
                              'onboarding.onboarding_complete_title'.tr(),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                // Changed from headlineLarge
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

                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),

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
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),

                    // 🔧 UPDATED: Setup summary card with BlocBuilder to read actual configurations
                    BlocBuilder<OnboardingBloc, OnboardingState>(
                      builder: (context, state) {
                        // Extract actual configurations
                        Map<String, dynamic> userSelections = {};
                        if (state is OnboardingStepActive) {
                          userSelections = state.userSelections;
                        } else if (state is OnboardingCompleted) {
                          userSelections = state.appliedConfigurations;
                        }

                        debugPrint(
                            '🔍 [DEBUG] OnboardingCompletePage - userSelections: $userSelections');

                        return AnimatedBuilder(
                          animation: _fadeAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset:
                                  Offset(0, 30 * (1 - _fadeAnimation.value)),
                              child: Opacity(
                                opacity: _fadeAnimation.value,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  // Reduced padding
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        colorScheme.surfaceContainerHighest
                                            .withValues(alpha: 0.8),
                                        colorScheme.surfaceContainer
                                            .withValues(alpha: 0.5),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    // Reduced radius
                                    border: Border.all(
                                      color: colorScheme.outline
                                          .withValues(alpha: 0.1),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.shadow
                                            .withValues(alpha: 0.05),
                                        blurRadius: 15, // Reduced shadow
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            // Reduced padding
                                            decoration: BoxDecoration(
                                              color: colorScheme.primary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.check_circle_outline,
                                              color: colorScheme.primary,
                                              size: 18, // Reduced size
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          // Reduced space
                                          Expanded(
                                            // Added Expanded to prevent overflow
                                            child: Text(
                                              'onboarding.onboarding_your_setup'
                                                  .tr(),
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                // Changed from titleLarge
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Reduced space

                                      // 🎨 Theme selection (always configured)
                                      _buildSetupItem(
                                        context,
                                        Icons.palette_outlined,
                                        'onboarding.onboarding_setup_theme_configured'
                                            .tr(),
                                        isConfigured:
                                            true, // Theme is always configured since user can't skip
                                      ),

                                      // 🔧 CONDITIONAL: Backup configuration (only show if actually configured)
                                      if (userSelections['backupEnabled'] ==
                                          true) ...[
                                        const SizedBox(height: 12),
                                        // Reduced space
                                        _buildSetupItem(
                                          context,
                                          Icons.cloud_done_outlined,
                                          'onboarding.onboarding_setup_backup_configured'
                                              .tr(),
                                          isConfigured: true,
                                        ),
                                        const SizedBox(height: 12),
                                        // Reduced space
                                        _buildSetupItem(
                                          context,
                                          Icons.shield_outlined,
                                          'onboarding.onboarding_setup_protection_active'
                                              .tr(),
                                          isConfigured: true,
                                        ),
                                      ] else ...[
                                        // Show that backup was skipped
                                        const SizedBox(height: 12),
                                        // Reduced space
                                        _buildSetupItem(
                                          context,
                                          Icons.cloud_off_outlined,
                                          'onboarding.onboarding_setup_backup_skipped'
                                              .tr(),
                                          isConfigured: false,
                                        ),
                                      ],

                                      // 🔧 Optional: Add message about being able to configure later if skipped
                                      if (userSelections['backupEnabled'] !=
                                          true) ...[
                                        const SizedBox(height: 12),
                                        // Reduced space
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          // Reduced padding
                                          decoration: BoxDecoration(
                                            color: colorScheme
                                                .surfaceContainerHighest
                                                .withValues(alpha: 0.5),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: colorScheme.outline
                                                  .withValues(alpha: 0.2),
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start, // Changed alignment
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color: colorScheme.primary,
                                                size: 14, // Reduced size
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'onboarding.onboarding_setup_backup_later_info'
                                                      .tr(),
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                    fontSize:
                                                        12, // Reduced font size
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    // Spacer that adapts to remaining space
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),

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
                                  borderRadius: BorderRadius.circular(12),
                                  // Reduced radius
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 15, // Reduced shadow
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: widget.onStartApp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    // Reduced padding
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'onboarding.onboarding_start_app'.tr(),
                                    style: TextStyle(
                                      fontSize: 16, // Reduced font size
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

                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🔧 UPDATED: Modified to accept isConfigured parameter and show different styles
  Widget _buildSetupItem(BuildContext context, IconData icon, String text,
      {required bool isConfigured}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      // Changed to start alignment
      children: [
        Container(
          width: 32, // Reduced size
          height: 32,
          decoration: BoxDecoration(
            color: isConfigured
                ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8), // Reduced radius
          ),
          child: Icon(
            icon,
            color: isConfigured
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            size: 18, // Reduced size
          ),
        ),
        const SizedBox(width: 12), // Reduced spacing
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              // Changed from bodyLarge
              color: isConfigured
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              fontSize: 14, // Explicit font size for consistency
            ),
            maxLines: 2, // Allow text to wrap
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(3), // Reduced padding
          decoration: BoxDecoration(
            color: isConfigured
                ? colorScheme.primary.withValues(alpha: 0.1)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isConfigured ? Icons.check : Icons.close,
            color: isConfigured
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            size: 14, // Reduced size
          ),
        ),
      ],
    );
  }
}
