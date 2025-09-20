// lib/widgets/animated_donation_header.dart - VERSIÓN OPTIMIZADA
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
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    // Partículas flotantes - reducidas y más lentas
    _particleController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();

    // Pulso del ícono - más lento y suave
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

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
    final screenSize = MediaQuery.of(context).size;

    // 🔥 CORRECCIÓN PRINCIPAL: Altura adaptativa para prevenir overflow
    final adaptiveHeight = widget.height.clamp(
      120.0, // Mínimo
      screenSize.height * 0.3, // Máximo 30% de la pantalla
    );

    return Container(
      height: adaptiveHeight, // ← CAMBIO PRINCIPAL
      width: double.infinity, // ← AGREGADO: Evita overflow horizontal
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
          clipBehavior: Clip.hardEdge, // ← AGREGADO: Fuerza el clipping
          children: [
            // Ondas animadas de fondo
            ..._buildAnimatedWaves(screenSize.width),

            // Partículas flotantes
            ..._buildFloatingParticles(screenSize.width, adaptiveHeight),

            // Contenido principal
            _buildMainContent(adaptiveHeight),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAnimatedWaves(double screenWidth) {
    return List.generate(
      2,
      (index) => AnimatedBuilder(
        animation: _waveAnimation,
        builder: (context, child) {
          final offset = (index * 0.5) % 1.0;
          final animValue = (_waveAnimation.value + offset) % 1.0;

          return Positioned(
            top: 60.0 + (index * 40),
            // 🔥 CORRECCIÓN: Usar ancho de pantalla para cálculo
            left: -80 + ((screenWidth + 160) * animValue) - (index * 40),
            child: Transform.rotate(
              angle: sin(_waveAnimation.value * pi + index) * 0.05,
              child: Container(
                width: 250,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08 - (index * 0.02)),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildFloatingParticles(
      double screenWidth, double containerHeight) {
    return List.generate(
      8,
      (index) => AnimatedBuilder(
        animation: _particleAnimation,
        builder: (context, child) {
          final offset = (index * 0.25) % 1.0;
          final animValue = (_particleAnimation.value + offset) % 1.0;
          final yOffset = sin(_particleAnimation.value * pi + index) * 15;

          // 🔥 CORRECCIÓN: Asegurar que las partículas estén dentro del contenedor
          final topPosition =
              (40 + (index * 22.0) + yOffset).clamp(0.0, containerHeight - 10);

          return Positioned(
            top: topPosition,
            // 🔥 CORRECCIÓN: Usar ancho de pantalla para cálculo
            left: -10 + ((screenWidth + 20) * animValue),
            child: Container(
              width: 2 + (index % 3) * 1.0,
              height: 2 + (index % 3) * 1.0,
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                    alpha: 0.3 +
                        (sin(_particleAnimation.value * 2 * pi + index) * 0.2)),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 2,
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

  Widget _buildMainContent(double containerHeight) {
    // 🔥 NUEVO: Contenido adaptativo según altura disponible
    final isCompact = containerHeight < 180;

    return Padding(
      padding: EdgeInsets.all(isCompact ? 16 : 24), // ← Padding adaptativo
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícono con pulso y halo
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              // 🔥 NUEVO: Tamaño adaptativo del ícono
              final iconSize = isCompact ? 50.0 : 70.0;
              final haloSize = isCompact ? 80.0 : 100.0;

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Halo exterior
                  Container(
                    width: haloSize + (15 * _pulseAnimation.value),
                    height: haloSize + (15 * _pulseAnimation.value),
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
                      width: iconSize,
                      height: iconSize,
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
                      child: Icon(
                        Icons.favorite,
                        size: isCompact ? 24 : 32, // ← Tamaño adaptativo
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          SizedBox(height: isCompact ? 16 : 24), // ← Espaciado adaptativo

          // Título
          Flexible(
            // ← AGREGADO: Previene overflow de texto
            child: Text(
              'donate.gratitude_title'.tr(),
              style: widget.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                fontSize: isCompact ? 18 : null,
                // ← Tamaño adaptativo
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 2, // ← AGREGADO: Limita líneas
              overflow: TextOverflow.ellipsis, // ← AGREGADO: Maneja overflow
            ),
          ),

          SizedBox(height: isCompact ? 8 : 12), // ← Espaciado adaptativo

          // Descripción
          Flexible(
            // ← AGREGADO: Previene overflow de texto
            child: Text(
              'donate.description'.tr(),
              style: widget.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
                fontSize: isCompact ? 13 : null, // ← Tamaño adaptativo
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: isCompact ? 2 : 3, // ← AGREGADO: Líneas adaptativas
              overflow: TextOverflow.ellipsis, // ← AGREGADO: Maneja overflow
            ),
          ),
        ],
      ),
    );
  }
}
