// lib/widgets/encounter/gold_shimmer.dart
//
// Animated gold highlight used to draw attention to the next waiting
// encounter and to the "open all encounters" offer button.

import 'package:flutter/material.dart';

const _gold = Color(0xFFD9A62E);
const _goldShine = Color(0xFFFFF3C4);

/// Paints a gold gradient whose bright band sweeps across [child] on a loop.
///
/// With [filled] false only a thin border ring is painted over the child;
/// with [filled] true the gradient fills the shape behind the child.
/// The sweep is frozen when the platform asks to reduce animations.
class GoldShimmer extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final bool filled;

  const GoldShimmer({
    super.key,
    required this.child,
    this.borderRadius = 32,
    this.filled = false,
  });

  @override
  State<GoldShimmer> createState() => _GoldShimmerState();
}

class _GoldShimmerState extends State<GoldShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final painter = _GoldShimmerPainter(
          progress: _controller.value,
          borderRadius: widget.borderRadius,
          filled: widget.filled,
        );
        return CustomPaint(
          key: const ValueKey('gold_shimmer'),
          painter: widget.filled ? painter : null,
          foregroundPainter: widget.filled ? null : painter,
          child: child,
        );
      },
    );
  }
}

class _GoldShimmerPainter extends CustomPainter {
  final double progress;
  final double borderRadius;
  final bool filled;

  const _GoldShimmerPainter({
    required this.progress,
    required this.borderRadius,
    required this.filled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_gold, _goldShine, _gold],
    ).createShader(rect.shift(Offset(size.width * (progress * 2 - 1), 0)));

    final paint = Paint()
      ..shader = shader
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 3;
    final inset = filled ? 0.0 : paint.strokeWidth / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(inset),
        Radius.circular(borderRadius),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_GoldShimmerPainter old) =>
      old.progress != progress ||
      old.borderRadius != borderRadius ||
      old.filled != filled;
}
