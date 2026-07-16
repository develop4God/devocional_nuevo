import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../../blocs/backup_bloc.dart';
import '../../blocs/backup_state.dart';
import '../../blocs/onboarding/onboarding_bloc.dart';
import '../../blocs/onboarding/onboarding_event.dart';

class OnboardingCompletePage extends StatefulWidget {
  final VoidCallback onStartApp;
  final VoidCallback onBack;

  const OnboardingCompletePage({
    super.key,
    required this.onStartApp,
    required this.onBack,
  });

  @override
  State<OnboardingCompletePage> createState() => _OnboardingCompletePageState();
}

class _OnboardingCompletePageState extends State<OnboardingCompletePage>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _pulseController;
  late AnimationController _confettiController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  bool _showConfetti = true;

  @override
  void initState() {
    super.initState();

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(seconds: 4),
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

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _celebrationController.forward();
    _pulseController.repeat(reverse: true);
    _confettiController.forward().whenComplete(() {
      if (mounted) {
        setState(() => _showConfetti = false);
      }
    });
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _pulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Container(
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
              minimum: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  // Navigation header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: BlocBuilder<BackupBloc, BackupState>(
                      builder: (context, backupState) {
                        // Once Google Drive backup is connected there is
                        // nothing left to change by going back — disable Back
                        // so the user can't re-trigger the sign-in flow from
                        // the final confirmation screen.
                        final isBackupConnected =
                            backupState is BackupLoaded &&
                            backupState.isAuthenticated;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            TextButton(
                              onPressed: isBackupConnected
                                  ? null
                                  : widget.onBack,
                              child: Text(
                                'onboarding.onboarding_back'.tr(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxHeight < 700;
                        final isVeryCompact = constraints.maxHeight < 560;
                        final heroHeight = isVeryCompact
                            ? 90.0
                            : (isCompact ? 130.0 : 200.0);
                        final sectionSpacing = isVeryCompact
                            ? 12.0
                            : (isCompact ? 20.0 : 40.0);
                        final smallSpacing = isVeryCompact ? 8.0 : 16.0;

                        return SingleChildScrollView(
                          physics: isVeryCompact
                              ? const NeverScrollableScrollPhysics()
                              : null,
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                              maxHeight: isVeryCompact
                                  ? constraints.maxHeight
                                  : double.infinity,
                            ),
                            child: IntrinsicHeight(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Celebration animation
                                  AnimatedBuilder(
                                    animation: Listenable.merge([
                                      _scaleAnimation,
                                      _pulseAnimation,
                                    ]),
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale:
                                            _scaleAnimation.value *
                                            _pulseAnimation.value,
                                        child: child,
                                      );
                                    },
                                    child: SizedBox(
                                      height: heroHeight,
                                      width: heroHeight,
                                      child: Lottie.asset(
                                        'assets/lottie/celebration.json',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: sectionSpacing),

                                  // Title with animation
                                  AnimatedBuilder(
                                    animation: _fadeAnimation,
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: Offset(
                                          0,
                                          20 * (1 - _fadeAnimation.value),
                                        ),
                                        child: Opacity(
                                          opacity: _fadeAnimation.value,
                                          child: Text(
                                            'onboarding.onboarding_complete_title'
                                                .tr(),
                                            style: theme.textTheme.headlineLarge
                                                ?.copyWith(
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

                                  SizedBox(height: smallSpacing),

                                  // Subtitle
                                  AnimatedBuilder(
                                    animation: _fadeAnimation,
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: Offset(
                                          0,
                                          20 * (1 - _fadeAnimation.value),
                                        ),
                                        child: Opacity(
                                          opacity: _fadeAnimation.value,
                                          child: Text(
                                            'onboarding.onboarding_complete_subtitle'
                                                .tr(),
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
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

                                  SizedBox(height: sectionSpacing),

                                  // Setup summary card - Consulta BackupBloc directamente
                                  BlocBuilder<BackupBloc, BackupState>(
                                    buildWhen: (previous, current) {
                                      // Construir en el primer estado Y cuando sea BackupLoaded
                                      return previous is BackupInitial ||
                                          current is BackupLoaded;
                                    },
                                    builder: (context, backupState) {
                                      bool isBackupConfigured = false;

                                      if (backupState is BackupLoaded) {
                                        isBackupConfigured =
                                            backupState.isAuthenticated &&
                                            backupState.autoBackupEnabled;
                                      }

                                      debugPrint(
                                        '🔍 [COMPLETE] isBackupConfigured: $isBackupConfigured',
                                      );

                                      return AnimatedBuilder(
                                        animation: _fadeAnimation,
                                        builder: (context, child) {
                                          return Transform.translate(
                                            offset: Offset(
                                              0,
                                              30 * (1 - _fadeAnimation.value),
                                            ),
                                            child: Opacity(
                                              opacity: _fadeAnimation.value,
                                              child: _buildSetupSummaryCard(
                                                context,
                                                isBackupConfigured,
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),

                                  SizedBox(height: sectionSpacing),

                                  // Start button
                                  AnimatedBuilder(
                                    animation: _fadeAnimation,
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: Offset(
                                          0,
                                          20 * (1 - _fadeAnimation.value),
                                        ),
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
                                                borderRadius:
                                                    BorderRadius.circular(16),
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
                                                onPressed: () {
                                                  context
                                                      .read<OnboardingBloc>()
                                                      .add(
                                                        const CompleteOnboarding(),
                                                      );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  shadowColor:
                                                      Colors.transparent,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 18,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                ),
                                                child: Text(
                                                  'onboarding.onboarding_start_app'
                                                      .tr(),
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: theme
                                                        .elevatedButtonTheme
                                                        .style
                                                        ?.foregroundColor
                                                        ?.resolve({}),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  SizedBox(height: smallSpacing),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showConfetti)
            IgnorePointer(
              child: FadeTransition(
                opacity: ReverseAnimation(
                  CurvedAnimation(
                    parent: _confettiController,
                    curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
                  ),
                ).drive(Tween(begin: 0.0, end: 1.0)),
                child: SizedBox.expand(
                  child: Lottie.asset(
                    'assets/lottie/confetti.json',
                    fit: BoxFit.cover,
                    repeat: false,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSetupSummaryCard(BuildContext context, bool isBackupConfigured) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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

          // 1. Theme configuration
          _buildSetupItem(
            context,
            Icons.palette_outlined,
            'onboarding.onboarding_setup_theme_configured'.tr(),
            true,
          ),

          const SizedBox(height: 16),

          // 2. Backup status
          if (isBackupConfigured)
            _buildSetupItem(
              context,
              Icons.cloud_done_outlined,
              'onboarding.onboarding_setup_backup_configured'.tr(),
              true,
            )
          else
            _buildSetupItem(
              context,
              Icons.settings_outlined,
              'onboarding.onboarding_setup_backup_later_info'.tr(),
              false,
            ),
        ],
      ),
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
}
