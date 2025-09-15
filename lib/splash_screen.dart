import 'dart:math';

import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:devocional_nuevo/pages/devocionales_page.dart'; // CAMBIADO: Importar página principal
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // Partículas luminosas
  static const int numParticles = 30; // Número de partículas luminosas
  static const double particleMinSize = 5.0;
  static const double particleMaxSize = 6.0;
  static const double particleAreaWidth = 400.0;
  static const double particleAreaHeight = 100.0;

  late List<_Particle> particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1500,
      ), // Duracion de la animación del fade
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Inicializa las partículas luminosas
    final rnd = Random();
    particles = List.generate(numParticles, (i) {
      return _Particle(
        x: rnd.nextDouble() * particleAreaWidth,
        y: rnd.nextDouble() * particleAreaHeight,
        size: particleMinSize +
            rnd.nextDouble() * (particleMaxSize - particleMinSize),
        speed: 0.4 + rnd.nextDouble() * 0.8,
        opacity: 0.5 + rnd.nextDouble() * 0.5,
        angle: rnd.nextDouble() * 2 * pi,
        color: Colors.white,
      );
    });

    _controller.forward(); // Inicia la animación visual
    _navigateToNextScreen(); // Llama al metodo para manejar la navegación
  }

  // Maneja la navegacion a la siguiente pantalla después de un retraso
  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 7000));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const DevocionalesPage(),
          // Added fade transition as requested
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Fade transition from splash to devotionals
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Actualiza posiciones de partículas para animación
  List<_Particle> _updateParticles(double time) {
    final List<_Particle> result = [];
    for (final p in particles) {
      double y = p.y - p.speed * sin(time + p.angle) * 4.8;
      double x = p.x + cos(time / 1.7 + p.angle) * 3.2;
      double opacity = p.opacity * (0.7 + 0.3 * sin(time + p.angle * 2));
      result.add(
        _Particle(
          x: x,
          y: y,
          size: p.size,
          speed: p.speed,
          opacity: opacity,
          angle: p.angle,
          color: p.color,
        ),
      );
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Capa de la imagen de fondo
          FadeTransition(
            opacity: _fadeAnimation,
            child: Image.asset(
              'assets/images/splash_background.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          // 2. Capa del texto superpuesto con partículas luminosas
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 150),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 2 * pi),
                    duration: const Duration(seconds: 5),
                    curve: Curves.linear,
                    builder: (context, value, child) {
                      final updatedParticles = _updateParticles(value * 1.5);
                      return SizedBox(
                        width: particleAreaWidth,
                        height: particleAreaHeight,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Partículas luminosas
                            ...updatedParticles.map(
                              (p) => Positioned(
                                left: p.x,
                                top: p.y,
                                child: Opacity(
                                  opacity: p.opacity,
                                  child: Container(
                                    width: p.size,
                                    height: p.size,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: p.color,
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.transparent,
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Texto principal centrado en el Stack
                            Center(
                              child: Text(
                                'app.preparing'.tr(),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dancingScript(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                  shadows: [
                                    const Shadow(
                                      offset: Offset(2.0, 2.0),
                                      blurRadius: 5.0,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Clase para partículas luminosas
class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final double angle;
  final Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.angle,
    required this.color,
  });
}
