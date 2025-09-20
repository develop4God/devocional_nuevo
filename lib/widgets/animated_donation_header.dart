// lib/widgets/animated_donation_header.dart
import 'dart:math';

import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';

class AnimatedDonationHeader extends StatefulWidget {
  final double height;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  const AnimatedDonationHeader({
    super.key,
    this.height = 240,
    required this.textTheme,
    required this.colorScheme,
  });

  @override
  State<AnimatedDonationHeader> createState() => _AnimatedDonationHeaderState();
}

class _AnimatedDonationHeaderState extends State<AnimatedDonationHeader>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _particleController;
  late AnimationController _pulseController;

  late Animation<double> _waveAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Ondas de fondo - más lentas para mejor rendimiento
    _waveController = AnimationController(
      duration: const Duration(seconds: 6), // Era 4, ahora 6
      vsync: this,
    )..repeat();

    // Partículas flotantes - reducidas y más lentas
    _particleController = AnimationController(
      duration: const Duration(seconds: 12), // Era 8, ahora 12
      vsync: this,
    )..repeat();

    // Pulso del ícono - más lento y suave
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3), // Era 2, ahora 3
      vsync: this,
    )..repeat(reverse: true);

    // Crear animaciones
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _waveController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            widget.colorScheme.primary.withValues(alpha: 0.9),
            widget.colorScheme.secondary.withValues(alpha: 0.8),
            widget.colorScheme.tertiary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: widget.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Ondas animadas de fondo
            ..._buildAnimatedWaves(),

            // Partículas flotantes
            ..._buildFloatingParticles(),

            // Contenido principal
            _buildMainContent(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAnimatedWaves() {
    // Solo 2 ondas en lugar de 3
    return List.generate(
      2,
      (index) => AnimatedBuilder(
        animation: _waveAnimation,
        builder: (context, child) {
          final offset = (index * 0.5) % 1.0; // Más espaciadas
          final animValue = (_waveAnimation.value + offset) % 1.0;

          return Positioned(
            top: 60.0 + (index * 40),
            left: -80 + (360 * animValue) - (index * 40),
            child: Transform.rotate(
              angle: sin(_waveAnimation.value * pi + index) * 0.05,
              // Menos rotación
              child: Container(
                width: 250, // Más pequeñas
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                      alpha: 0.08 - (index * 0.02)), // Menos opacidad
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildFloatingParticles() {
    // Reducidas de 12 a 8 partículas para mejor rendimiento
    return List.generate(
      8,
      (index) => AnimatedBuilder(
        animation: _particleAnimation,
        builder: (context, child) {
          final offset = (index * 0.25) % 1.0; // Más espaciadas
          final animValue = (_particleAnimation.value + offset) % 1.0;
          final yOffset = sin(_particleAnimation.value * pi + index) *
              15; // Menos movimiento vertical

          return Positioned(
            top: 40 + (index * 22.0) + yOffset,
            left: -10 + (380 * animValue),
            child: Container(
              width: 2 + (index % 3) * 1.0, // Más pequeñas
              height: 2 + (index % 3) * 1.0,
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                    alpha: 0.3 +
                        (sin(_particleAnimation.value * 2 * pi + index) *
                            0.2) // Menos intensidad
                    ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    // Menos glow
                    blurRadius: 2,
                    // Menos blur
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícono con pulso y halo
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Halo exterior
                  Container(
                    width: 100 + (15 * _pulseAnimation.value),
                    height: 100 + (15 * _pulseAnimation.value),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(
                              alpha: 0.1 * (1 - _pulseAnimation.value)),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Contenedor del ícono
                  Transform.scale(
                    scale: 1.0 + (0.1 * _pulseAnimation.value),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Título
          Text(
            'donate.gratitude_title'.tr(),
            style: widget.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Descripción
          Text(
            'donate.description'.tr(),
            style: widget.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
