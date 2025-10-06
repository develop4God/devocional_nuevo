import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/widgets/donate/animated_donation_header.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OnboardingWelcomePage extends StatefulWidget {
  final VoidCallback onNext;

  const OnboardingWelcomePage({
    super.key,
    required this.onNext,
  });

  @override
  State<OnboardingWelcomePage> createState() => _OnboardingWelcomePageState();
}

class _OnboardingWelcomePageState extends State<OnboardingWelcomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque, // Responds everywhere on the screen
        onTap: widget.onNext,
        child: Container(
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
                // Main content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated header
                        AnimatedDonationHeader(
                          height: 200,
                          textTheme: Theme.of(context).textTheme,
                          colorScheme: Theme.of(context).colorScheme,
                        ),
                        const SizedBox(height: 48),

                        // Welcome title
                        Text(
                          'onboarding.onboarding_welcome_title'.tr(),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Welcome subtitle
                        Text(
                          'onboarding.onboarding_welcome_subtitle'.tr(),
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                    height: 1.5,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Tip for user (tap)
                        Text(
                          'onboarding.onboarding_touch_screen'.tr(),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24),

                        // Lottie animation for tap feedback
                        Lottie.asset(
                          'assets/lottie/tap_screen.json',
                          height: 150,
                          repeat: true,
                          animate: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
