import 'package:devocional_nuevo/pages/onboarding/onboarding_backup_configuration_page.dart';
import 'package:devocional_nuevo/pages/onboarding/onboarding_complete_page.dart';
import 'package:devocional_nuevo/pages/onboarding/onboarding_theme_selection_page.dart';
import 'package:devocional_nuevo/pages/onboarding/onboarding_welcome_page.dart';
import 'package:devocional_nuevo/services/onboarding_service.dart';
import 'package:flutter/material.dart';

class OnboardingFlow extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingFlow({super.key, required this.onComplete});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      setState(() {
        _currentPage++;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToEnd() {
    setState(() {
      _currentPage = 3;
    });
    _pageController.animateToPage(
      3,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _completeOnboarding() async {
    await OnboardingService.instance.setOnboardingComplete();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Progress indicator
          if (_currentPage < 3)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                      height: 4,
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.3),
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
                OnboardingWelcomePage(onNext: _nextPage, onSkip: _skipToEnd),
                OnboardingThemeSelectionPage(
                  onNext: _nextPage,
                  onBack: _previousPage,
                  onSkip: _skipToEnd,
                ),
                OnboardingBackupConfigurationPage(
                  onNext: _nextPage,
                  onBack: _previousPage,
                  onSkip: _nextPage,
                ),
                OnboardingCompletePage(onStartApp: _completeOnboarding),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
