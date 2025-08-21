// bubble_constants.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sistema global de burbujas - Solo importar y usar
/// Uso: MiWidget().newBubble, MiWidget().updatedBubble, Icon().newIconBadge

// Constantes centralizadas para futuras implementaciones
class BubbleConstants {
  // Duraciones
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration delayBeforeShow = Duration(milliseconds: 100);

  // Colores
  //static const Color newFeatureColor = Color(0xFF4CAF50); verde para nuevo
  static const Color newFeatureColor =
      Color(0xFFF44336); //rojo temporal para que se vea
  static const Color updatedFeatureColor = Color(0xFF2196F3);
  static const Color notificationColor = Color(0xFFFF5722);

  // Posiciones para diferentes tipos de widgets
  static const double widgetBubbleTop = -2;
  static const double widgetBubbleRight = -60;
  static const double iconBadgeTop = -4;
  static const double iconBadgeRight = -4;

  // Tamaños
  static const double widgetBubbleRadius = 12;
  static const double iconBadgeSize = 12;
  static const double iconBadgeRadius = 4;

  // Estilos de texto
  static const TextStyle widgetBubbleTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle iconBadgeTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 9,
    fontWeight: FontWeight.w700,
  );

  // Sombras
  static final List<BoxShadow> bubbleShadow = [
    BoxShadow(
      color: Colors.black.withAlpha(38),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
}

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

  // Para notificar cambios
  final Set<VoidCallback> _listeners = {};

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  Future<void> markBubbleAsShownAndNotify(String bubbleId) async {
    await markBubbleAsShown(bubbleId);
    _notifyListeners();
  }
}

// Widget de burbuja genérica (para texto)
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
      duration: BubbleConstants.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _checkIfShouldShow() async {
    final shouldShow = await _BubbleManager().shouldShowBubble(widget.bubbleId);
    if (shouldShow && mounted) {
      setState(() => _showBubble = true);
      await Future.delayed(BubbleConstants.delayBeforeShow);
      if (mounted) {
        _animationController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (_showBubble)
          Positioned(
            top: BubbleConstants.widgetBubbleTop,
            right: BubbleConstants.widgetBubbleRight,
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
                        borderRadius: BorderRadius.circular(
                            BubbleConstants.widgetBubbleRadius),
                        boxShadow: BubbleConstants.bubbleShadow,
                      ),
                      child: Text(
                        widget.text,
                        style: BubbleConstants.widgetBubbleTextStyle,
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

// Widget de badge para íconos (círculo pequeño)
class _IconBadgeOverlay extends StatefulWidget {
  final Widget child;
  final String bubbleId;
  final Color badgeColor;

  const _IconBadgeOverlay({
    required this.child,
    required this.bubbleId,
    required this.badgeColor,
  });

  @override
  State<_IconBadgeOverlay> createState() => _IconBadgeOverlayState();
}

class _IconBadgeOverlayState extends State<_IconBadgeOverlay>
    with TickerProviderStateMixin {
  bool _showBadge = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkIfShouldShow();
    // Escuchar cambios del bubble manager
    _BubbleManager().addListener(_onBubbleChanged);
  }

  void _onBubbleChanged() {
    _checkIfShouldShowAndUpdate();
  }

  Future<void> _checkIfShouldShowAndUpdate() async {
    final shouldShow = await _BubbleManager().shouldShowBubble(widget.bubbleId);
    if (mounted) {
      setState(() => _showBadge = shouldShow);
      if (!shouldShow && _animationController.isCompleted) {
        _animationController.reverse();
      }
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: BubbleConstants.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _checkIfShouldShow() async {
    final shouldShow = await _BubbleManager().shouldShowBubble(widget.bubbleId);
    if (shouldShow && mounted) {
      setState(() => _showBadge = true);
      await Future.delayed(BubbleConstants.delayBeforeShow);
      if (mounted) {
        _animationController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (_showBadge)
          Positioned(
            top: BubbleConstants.iconBadgeTop,
            right: BubbleConstants.iconBadgeRight,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      width: BubbleConstants.iconBadgeSize,
                      height: BubbleConstants.iconBadgeSize,
                      decoration: BoxDecoration(
                        color: widget.badgeColor,
                        shape: BoxShape.circle,
                        boxShadow: BubbleConstants.bubbleShadow,
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
    _BubbleManager().removeListener(_onBubbleChanged);
    _animationController.dispose();
    super.dispose();
  }
}

// Extensiones súper simples - Solo estas líneas necesitas usar
extension BubbleExtensions on Widget {
  /// Agrega burbuja "Nuevo" - Uso: MiWidget().newBubble
  Widget get newBubble {
    final bubbleId = 'new_${runtimeType.toString()}_$hashCode';
    return _BubbleOverlay(
      bubbleId: bubbleId,
      text: 'Nuevo',
      bubbleColor: BubbleConstants.newFeatureColor,
      child: this,
    );
  }

  /// Agrega burbuja "Actualizado" - Uso: MiWidget().updatedBubble
  Widget get updatedBubble {
    final bubbleId = 'updated_${runtimeType.toString()}_$hashCode';
    return _BubbleOverlay(
      bubbleId: bubbleId,
      text: 'Actualizado',
      bubbleColor: BubbleConstants.updatedFeatureColor,
      child: this,
    );
  }
}

// Extensión específica para íconos
extension IconBubbleExtensions on Icon {
  /// Agrega badge circular "nuevo" para íconos - Uso: Icon(Icons.star).newIconBadge
  Widget get newIconBadge {
    final bubbleId =
        'icon_new_${icon.toString()}_${semanticLabel ?? 'unknown'}';
    return _IconBadgeOverlay(
      bubbleId: bubbleId,
      badgeColor: BubbleConstants.newFeatureColor,
      child: this,
    );
  }

  /// Agrega badge circular "actualizado" para íconos - Uso: Icon(Icons.star).updatedIconBadge
  Widget get updatedIconBadge {
    final bubbleId =
        'icon_updated_${icon.toString()}_${semanticLabel ?? 'unknown'}';
    return _IconBadgeOverlay(
      bubbleId: bubbleId,
      badgeColor: BubbleConstants.updatedFeatureColor,
      child: this,
    );
  }

  /// Agrega badge circular de notificación para íconos - Uso: Icon(Icons.star).notificationIconBadge
  Widget get notificationIconBadge {
    final bubbleId =
        'icon_notification_${icon.toString()}_${semanticLabel ?? 'unknown'}';
    return _IconBadgeOverlay(
      bubbleId: bubbleId,
      badgeColor: BubbleConstants.notificationColor,
      child: this,
    );
  }
}

// Clase utilitaria para marcar burbujas como vistas manualmente
class BubbleUtils {
  /// Marcar una burbuja como vista manualmente con notificación
  /// Uso: BubbleUtils.markAsShown('icon_new_IconData(U+0E567)_unknown');
  static Future<void> markAsShown(String bubbleId) async {
    await _BubbleManager().markBubbleAsShownAndNotify(bubbleId);
  }

  /// Obtener el ID que usaría un ícono específico
  /// Uso: BubbleUtils.getIconBubbleId(Icons.emoji_events_outlined, 'new');
  static String getIconBubbleId(IconData icon, String type,
      {String? semanticLabel}) {
    return 'icon_${type}_${icon.toString()}_${semanticLabel ?? 'unknown'}';
  }
}

// EJEMPLOS DE USO:
/*

// Para widgets normales (como antes):
Text('Hola mundo').newBubble
Card(child: Text('Contenido')).updatedBubble

// Para íconos (NUEVO):
Icon(Icons.star).newIconBadge
Icon(Icons.settings).updatedIconBadge
Icon(Icons.notifications).notificationIconBadge

// Para marcar como visto manualmente cuando navegas:
IconButton(
  onPressed: () async {
    // Marcar como visto antes de navegar
    await BubbleUtils.markAsShown(
      BubbleUtils.getIconBubbleId(Icons.emoji_events_outlined, 'new')
    );

    Navigator.push(context, MaterialPageRoute(
      builder: (context) => const ProgressPage(),
    ));
  },
  icon: Icon(Icons.emoji_events_outlined).newIconBadge,
)

*/
