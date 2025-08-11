// bubble_constants.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sistema global de burbujas - Solo importar y usar
/// Uso: MiWidget().newBubble o MiWidget().updatedBubble

// Clase para manejar el estado global de las burbujas
class _BubbleManager {
  static final _BubbleManager _instance = _BubbleManager._internal();

  factory _BubbleManager() => _instance;

  _BubbleManager._internal();

  final Set<String> _shownBubbles = <String>{};
  SharedPreferences? _prefs;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    final shown = _prefs!.getStringList('shown_bubbles') ?? [];
    _shownBubbles.addAll(shown);
  }

  Future<bool> shouldShowBubble(String bubbleId) async {
    await _initPrefs();
    return !_shownBubbles.contains(bubbleId);
  }

  Future<void> markBubbleAsShown(String bubbleId) async {
    await _initPrefs();
    _shownBubbles.add(bubbleId);
    await _prefs!.setStringList('shown_bubbles', _shownBubbles.toList());
  }
}

// Widget de la burbuja
class _BubbleOverlay extends StatefulWidget {
  final Widget child;
  final String text;
  final String bubbleId;
  final Color bubbleColor;

  const _BubbleOverlay({
    required this.child,
    required this.text,
    required this.bubbleId,
    required this.bubbleColor,
  });

  @override
  State<_BubbleOverlay> createState() => _BubbleOverlayState();
}

class _BubbleOverlayState extends State<_BubbleOverlay>
    with TickerProviderStateMixin {
  bool _showBubble = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkIfShouldShow();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300), // Más rápido y sutil
      vsync: this,
    );

    // Fade + Escala - Máxima sutileza
    _scaleAnimation = Tween<double>(
      begin: 0.8, // Empieza un poco más grande (más sutil)
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic, // Suave y natural
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic, // Mismo curve para sincronizar
    ));
  }

  Future<void> _checkIfShouldShow() async {
    final shouldShow = await _BubbleManager().shouldShowBubble(widget.bubbleId);
    if (shouldShow && mounted) {
      setState(() => _showBubble = true);
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        _animationController.forward();
      }
    }
  }

  // Reemplaza SOLO el método build del _BubbleOverlayState:

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (_showBubble)
          Positioned(
            top: -2,
            right: -60,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.bubbleColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(38),
                            // 0.15 * 255 ≈ 38
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

// Extensiones súper simples - Solo estas dos líneas necesitas usar
extension BubbleExtensions on Widget {
  /// Agrega burbuja "Nuevo" - Uso: MiWidget().newBubble
  Widget get newBubble {
    final bubbleId = 'new_${runtimeType.toString()}_$hashCode';
    return _BubbleOverlay(
      bubbleId: bubbleId,
      text: 'Nuevo',
      bubbleColor: const Color(0xFF4CAF50), // Verde para "Nuevo"
      child: this,
    );
  }

  /// Agrega burbuja "Actualizado" - Uso: MiWidget().updatedBubble
  Widget get updatedBubble {
    final bubbleId = 'updated_${runtimeType.toString()}_$hashCode';
    return _BubbleOverlay(
      bubbleId: bubbleId,
      text: 'Actualizado',
      bubbleColor: const Color(0xFF2196F3), // Azul para "Actualizado"
      child: this,
    );
  }
}
