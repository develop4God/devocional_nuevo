import 'package:devocional_nuevo/blocs/backup_bloc.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_bloc.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_event.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_models.dart';
import 'package:devocional_nuevo/blocs/onboarding/onboarding_state.dart';
import 'package:devocional_nuevo/pages/onboarding/onboarding_backup_configuration_page.dart';
import 'package:devocional_nuevo/pages/onboarding/onboarding_complete_page.dart';
import 'package:devocional_nuevo/pages/onboarding/onboarding_theme_selection_page.dart';
import 'package:devocional_nuevo/pages/onboarding/onboarding_welcome_page.dart';
import 'package:devocional_nuevo/providers/theme_provider.dart';
import 'package:devocional_nuevo/services/onboarding_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class OnboardingFlow extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingFlow({super.key, required this.onComplete});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  late OnboardingBloc _onboardingBloc;

  @override
  void initState() {
    super.initState();

    // Initialize OnboardingBloc with required dependencies
    // Use try-catch to handle missing providers gracefully
    ThemeProvider? themeProvider;
    BackupBloc? backupBloc;

    try {
      themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    } catch (e) {
      debugPrint('⚠️ ThemeProvider not found in context, using fallback');
    }

    try {
      backupBloc = context.read<BackupBloc?>();
    } catch (e) {
      debugPrint('⚠️ BackupBloc not found in context, continuing without it');
    }

    _onboardingBloc = OnboardingBloc(
      onboardingService: OnboardingService.instance,
      themeProvider: themeProvider ?? _createFallbackThemeProvider(),
      backupBloc: backupBloc,
    );

    // Initialize onboarding flow
    _onboardingBloc.add(const InitializeOnboarding());
  }

  /// Create a fallback ThemeProvider for testing
  ThemeProvider _createFallbackThemeProvider() {
    debugPrint('⚠️ [ONBOARDING_FLOW] Using fallback ThemeProvider for testing');
    final fallbackProvider = ThemeProvider();

    // Initialize with default values to prevent null errors
    try {
      // Ensure the provider has a valid default state
      fallbackProvider.initializeDefaults();
    } catch (e) {
      debugPrint(
          '⚠️ [ONBOARDING_FLOW] Fallback provider initialization failed: $e');
    }

    return fallbackProvider;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _onboardingBloc.close();
    super.dispose();
  }

  void _handleStepNavigation(int targetStep) {
    _onboardingBloc.add(ProgressToStep(targetStep));
  }

  void _handleSkip() {
    _onboardingBloc.add(const SkipCurrentStep());
  }

  void _handleBack() {
    _onboardingBloc.add(const GoToPreviousStep());
  }

  void _handleComplete() {
    _onboardingBloc.add(const CompleteOnboarding());
  }

  void _animateToPage(int pageIndex) {
    // Only animate if PageController is attached and the widget is mounted
    if (_pageController.hasClients && mounted) {
      _pageController.animateToPage(
        pageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showErrorDialog(BuildContext context, OnboardingError error) {
    if (!mounted) return; // Safety check before showing dialog
    if (!context.mounted) return; // Context safety check
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
          size: 48,
        ),
        title: const Text('Onboarding Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.message),
            if (error.errorContext?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                'Details: ${error.errorContext}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (mounted && context.mounted) {
                _onboardingBloc.add(const InitializeOnboarding());
              }
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (mounted) {
                widget.onComplete(); // Skip onboarding on persistent errors
              }
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: BlocProvider<OnboardingBloc>(
        create: (context) => _onboardingBloc,
        child: BlocConsumer<OnboardingBloc, OnboardingState>(
          listener: (context, state) {
            if (!mounted) return; // Safety check for async state updates
            
            if (state is OnboardingStepActive) {
              // Animate to the current step page
              _animateToPage(state.currentStepIndex);
            } else if (state is OnboardingCompleted) {
              // Onboarding completed, call the completion callback
              widget.onComplete();
            } else if (state is OnboardingError) {
              // Show detailed error dialog instead of just snackbar
              _showErrorDialog(context, state);
            }
          },
        builder: (context, state) {
          if (state is OnboardingLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (state is OnboardingCompleted) {
            // This should not be reached due to the listener, but provide fallback
            return const Scaffold(
              body: Center(
                child: Text('Onboarding completed!'),
              ),
            );
          }

          if (state is OnboardingError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading onboarding',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        _onboardingBloc.add(const InitializeOnboarding());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is OnboardingStepActive) {
            return Scaffold(
              body: Column(
                children: [
                  // Progress indicator
                  if (state.currentStepIndex <
                      OnboardingSteps.defaultSteps.length - 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      child: Row(
                        children: List.generate(
                            OnboardingSteps.defaultSteps.length - 1, (index) {
                          return Expanded(
                            child: Container(
                              margin: EdgeInsets.only(
                                  right: index <
                                          OnboardingSteps.defaultSteps.length -
                                              2
                                      ? 8
                                      : 0),
                              height: 4,
                              decoration: BoxDecoration(
                                color: index <= state.currentStepIndex
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .outline
                                        .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                  // Pages
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        OnboardingWelcomePage(
                          onNext: () => _handleStepNavigation(1),
                          onSkip: _handleSkip,
                        ),
                        OnboardingThemeSelectionPage(
                          onNext: () => _handleStepNavigation(2),
                          onBack: _handleBack,
                          onSkip: _handleSkip,
                        ),
                        OnboardingBackupConfigurationPage(
                          onNext: () => _handleStepNavigation(3),
                          onBack: _handleBack,
                          onSkip: () => _handleStepNavigation(3),
                        ),
                        OnboardingCompletePage(onStartApp: _handleComplete),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // Default fallback for initial state
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    ), // Closes Directionality widget child
    ); // Closes Directionality widget
  }
}
