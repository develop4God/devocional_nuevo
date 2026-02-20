import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PetHeroSection extends StatelessWidget {
  final String? profileName;
  final bool showPetHint;
  final VoidCallback onTap;
  final dynamic selectedPet; // Using dynamic or your Pet model
  final dynamic selectedTheme; // Using dynamic or your Theme model

  const PetHeroSection({
    super.key,
    this.profileName,
    required this.showPetHint,
    required this.onTap,
    required this.selectedPet,
    required this.selectedTheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: selectedTheme.colors as List<Color>,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (selectedTheme.colors as List<Color>)
                  .first
                  .withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.wb_sunny_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'messages.welcome_name'.tr(
                              {'name': profileName ?? ''},
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Pet Animation
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: Transform.scale(
                        scale: 1.4,
                        child: Lottie.asset(
                          selectedPet.lottieAsset as String,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                selectedPet.emoji as String,
                                style: const TextStyle(fontSize: 48),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (showPetHint)
              Positioned(
                right: -20,
                bottom: -30,
                child: IgnorePointer(
                  child: SizedBox(
                    height: 110,
                    width: 110,
                    child: Lottie.asset(
                      'assets/lottie/tap_screen.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
