import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedFabWithText extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final Duration showDuration;
  final Color fabColor;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final double? width;
  final double height;

  const AnimatedFabWithText({
    super.key,
    required this.onPressed,
    required this.text,
    this.showDuration = const Duration(seconds: 3),
    required this.fabColor,
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    this.width,
    this.height = 56,
  });

  @override
  State<AnimatedFabWithText> createState() => _AnimatedFabWithTextState();
}

class _AnimatedFabWithTextState extends State<AnimatedFabWithText>
    with SingleTickerProviderStateMixin {
  bool _showText = false;
  Timer? _initialDelayTimer;
  Timer? _hideTextTimer;

  @override
  void initState() {
    super.initState();
    // Pequeño delay para que se vea primero solo el círculo
    _initialDelayTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _showText = true);
        _hideTextTimer = Timer(widget.showDuration, () {
          if (mounted) setState(() => _showText = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _initialDelayTimer?.cancel();
    _hideTextTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final calculatedWidth = (screenWidth * 0.95).clamp(140.0, double.infinity);
    final maxWidth = widget.width ?? calculatedWidth;

    return SizedBox(
      height: widget.height,
      child: Stack(
        alignment: Alignment.centerRight,
        clipBehavior: Clip.none,
        children: [
          // Contenedor de texto expandible (detrás)
          if (_showText)
            Positioned(
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                height: widget.height,
                width: _showText ? maxWidth : 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(widget.height / 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onPressed,
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 20,
                          right: widget.height + 4,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedOpacity(
                            opacity: _showText ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 400),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_circle,
                                  color: widget.textColor,
                                  size: 50,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // FAB circular (siempre visible, al frente)
          Positioned(
            right: 0,
            child: Container(
              width: widget.height,
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.fabColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: widget.onPressed,
                  customBorder: const CircleBorder(),
                  child: Center(
                    child: Icon(
                      Icons.add,
                      color: widget.iconColor,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
