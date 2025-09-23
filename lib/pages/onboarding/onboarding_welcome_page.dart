import 'dart:math' as math;

import 'package:devocional_nuevo/utils/localization_extension.dart';
import 'package:flutter/material.dart';

class OnboardingWelcomePage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const OnboardingWelcomePage({
    super.key,
    required this.onNext,
    required this.onSkip,
  });

  @override
  State<OnboardingWelcomePage> createState() => _OnboardingWelcomePageState();
}

class _OnboardingWelcomePageState extends State<OnboardingWelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _heartController;
  late AnimationController _particleController;
  late Animation<double> _heartGlow;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();

    _heartController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _heartGlow = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );

    _heartController.repeat(reverse: true);
    _particleController.repeat();
  }

  @override
  void dispose() {
    _heartController.dispose();
    _particleController.dispose();
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
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: widget.onSkip,
                    child: Text('onboarding_skip'.tr()),
                  ),
                ),
              ),

              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated heart with particles
                      SizedBox(
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Floating particles
                            ...List.generate(6, (index) {
                              return AnimatedBuilder(
                                animation: _particleAnimation,
                                builder: (context, child) {
                                  final angle =
                                      (index * 60.0) * (math.pi / 180);
                                  final radius =
                                      80 + (20 * _particleAnimation.value);
                                  final x = radius * math.cos(angle);
                                  final y = radius * math.sin(angle);

                                  return Transform.translate(
                                    offset: Offset(x, y),
                                    child: Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),

                            // Animated heart
                            AnimatedBuilder(
                              animation: _heartGlow,
                              builder: (context, child) {
                                return Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(
                                              _heartGlow.value * 0.3,
                                            ),
                                        blurRadius: 20 * _heartGlow.value,
                                        spreadRadius: 5 * _heartGlow.value,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.favorite,
                                    size: 80,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Welcome title
                      Text(
                        'onboarding_welcome_title'.tr(),
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
                        'onboarding_welcome_subtitle'.tr(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                              height: 1.5,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // Next button
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onNext,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'onboarding_next'.tr(),
                      style: const TextStyle(fontSize: 16),
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
}
