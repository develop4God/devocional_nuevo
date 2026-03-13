// lib/pages/encounters/encounter_welcome_page.dart
//
// Welcome screen shown once — the very first time the user opens the
// Encounters tab. Mirrors the visual language of EncounterIntroPage:
// full-screen image, gradient overlay, cinematic text reveal, gold CTA.
//
// After tapping "Comenzar", SharedPreferences key 'encounter_welcome_seen'
// is set to true and this page is never shown again.

import 'package:devocional_nuevo/pages/encounters/encounters_list_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EncounterWelcomePage extends StatefulWidget {
  const EncounterWelcomePage({super.key});

  @override
  State<EncounterWelcomePage> createState() => _EncounterWelcomePageState();
}

class _EncounterWelcomePageState extends State<EncounterWelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Mirrors EncounterIntroPage interval pattern:
  // image fades in first, content slides + fades after
  late Animation<double> _imageOpacity;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _imageOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    _contentFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.85, curve: Curves.easeIn),
    );

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onBegin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('encounter_welcome_seen', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => const EncountersListPage(),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0e1a),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. CINEMATIC BACKGROUND IMAGE
          FadeTransition(
            opacity: _imageOpacity,
            child: Image.asset(
              'assets/encounters/encounters_welcome.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF0a0e1a)),
            ),
          ),

          // 2. GRADIENT OVERLAY — dark at bottom, light touch at top
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.05),
                  const Color(0xFF0a0e1a).withValues(alpha: 0.92),
                  const Color(0xFF0a0e1a),
                ],
                stops: const [0.0, 0.25, 0.62, 1.0],
              ),
            ),
          ),

          // 3. DECORATIVE ORB — gold glow bottom-left, mirrors intro page
          Positioned(
            bottom: -80,
            left: -120,
            child: _Orb(
              color: const Color(0xFFFFD700).withValues(alpha: 0.12),
              size: 420,
            ),
          ),

          // 4. MAIN CONTENT
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),

                // Text + tagline block
                FadeTransition(
                  opacity: _contentFade,
                  child: SlideTransition(
                    position: _contentSlide,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Line 1
                          const Text(
                            'Ellos lo encontraron.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              letterSpacing: -1.0,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Line 2
                          const Text(
                            'Cambiaron para siempre.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              letterSpacing: -1.0,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Line 3 — gold accent
                          const Text(
                            'El mismo Jesús. Aquí. Ahora.',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              letterSpacing: -1.0,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Subtitle
                          Text(
                            'Historias reales. El Jesús real.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ),

                // 5. GOLD CTA BUTTON — identical to EncounterIntroPage
                FadeTransition(
                  opacity: _contentFade,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                    child: SizedBox(
                      width: double.infinity,
                      height: 72,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFB8860B),
                              Color(0xFFFFD700),
                              Color(0xFFFFFFE0),
                              Color(0xFFFFD700),
                              Color(0xFFB8860B),
                            ],
                            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700)
                                  .withValues(alpha: 0.6),
                              blurRadius: 24,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: const Color(0xFFFFD700)
                                  .withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _onBegin,
                            borderRadius: BorderRadius.circular(24),
                            splashColor: Colors.white.withValues(alpha: 0.3),
                            highlightColor: Colors.white.withValues(alpha: 0.1),
                            child: const Center(
                              child: Text(
                                'COMENZAR',
                                style: TextStyle(
                                  color: Color(0xFF0a0e1a),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Reused from encounter_intro_page.dart — identical implementation
class _Orb extends StatelessWidget {
  final Color color;
  final double size;

  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size / 2,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}
