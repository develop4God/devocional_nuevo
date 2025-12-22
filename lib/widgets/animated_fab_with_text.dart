import 'package:flutter/material.dart';

class AnimatedFabWithText extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final Duration showDuration;
  final Gradient gradient;
  final Color textColor;
  final Color iconColor;
  final double? width;
  final double height;

  const AnimatedFabWithText({
    super.key,
    required this.onPressed,
    required this.text,
    this.showDuration = const Duration(seconds: 4),
    required this.gradient,
    required this.textColor,
    required this.iconColor,
    this.width,
    this.height = 56,
  });

  @override
  State<AnimatedFabWithText> createState() => _AnimatedFabWithTextState();
}

class _AnimatedFabWithTextState extends State<AnimatedFabWithText> {
  bool _showText = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _showText = true);
      Future.delayed(widget.showDuration, () {
        if (mounted) setState(() => _showText = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calcular el ancho basado en el texto si no se especifica
    final screenWidth = MediaQuery.of(context).size.width;

    // Usar el 95% del ancho disponible con un mínimo de 140px
    final calculatedWidth = (screenWidth * 0.95).clamp(140.0, double.infinity);
    final maxWidth = widget.width ?? calculatedWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      height: widget.height,
      constraints: BoxConstraints(
        maxWidth: _showText ? maxWidth : widget.height,
        minWidth: widget.height,
      ),
      decoration: BoxDecoration(
        gradient: widget.gradient,
        borderRadius: BorderRadius.circular(widget.height / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(widget.height / 2),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _showText ? 16.0 : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_showText && widget.text.isNotEmpty)
                  Flexible(
                    child: AnimatedOpacity(
                      opacity: _showText ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          widget.text,
                          style: TextStyle(
                            color: widget.textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                Icon(
                  Icons.add,
                  color: widget.iconColor,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}