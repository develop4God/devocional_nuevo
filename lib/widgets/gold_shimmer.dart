// lib/widgets/gold_shimmer.dart
//
// Animated gold highlight used to draw attention to the next waiting
// encounter and to the "open all encounters" offer button.

import 'package:flutter/material.dart';

/// Base gold shared by every gold highlight in the app.
const goldAccent = Color(0xFFD9A62E);
const _goldShine = Color(0xFFFFF3C4);

/// Dark brown that stays readable on top of the gold gradient.
const goldOnGold = Color(0xFF3E2A00);

/// Dark warm overlay painted over the next waiting (locked) encounter card.
const goldLockOverlayGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xD9000000), Color(0xE62A2110)],
);

/// Lock icon colour on top of [goldLockOverlayGradient].
const goldLockIconColor = Color(0xFFFFE08A);

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
      colors: [goldAccent, _goldShine, goldAccent],
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

/// A call-to-action button filled with the shimmering gold gradient.
class GoldShimmerButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double borderRadius;

  const GoldShimmerButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return GoldShimmer(
      filled: true,
      borderRadius: borderRadius,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: goldOnGold,
          disabledForegroundColor: goldOnGold,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}

/// Lock icon inside a glowing gold ring, used on the next waiting encounter.
class GoldLockBadge extends StatelessWidget {
  final double iconSize;
  final double padding;

  const GoldLockBadge({super.key, this.iconSize = 32, this.padding = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.5),
        border: Border.all(color: goldAccent, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x66D9A62E), blurRadius: 18, spreadRadius: 2),
        ],
      ),
      child: Icon(
        Icons.lock_rounded,
        color: goldLockIconColor,
        size: iconSize,
      ),
    );
  }
}

/// Small shimmering gold pill carrying a short hint text.
class GoldHintPill extends StatelessWidget {
  final String text;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const GoldHintPill({
    super.key,
    required this.text,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return GoldShimmer(
      filled: true,
      borderRadius: 20,
      child: Padding(
        padding: padding,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: goldOnGold,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}
