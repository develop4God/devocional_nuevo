import 'package:devocional_nuevo/utils/theme_constants.dart';
import 'package:flutter/material.dart';

typedef ThemeChangedCallback = void Function(String selectedTheme);

const _kThemeOrder = [
  'Cyan',
  'Green',
  'Pink',
  'Light Blue',
  'Deep Purple',
  'Gray',
];

class ThemeSelectorCircleGrid extends StatefulWidget {
  final String selectedTheme;
  final ThemeChangedCallback onThemeChanged;
  final Brightness brightness;

  const ThemeSelectorCircleGrid({
    super.key,
    required this.selectedTheme,
    required this.onThemeChanged,
    this.brightness = Brightness.light,
  });

  @override
  State<ThemeSelectorCircleGrid> createState() =>
      _ThemeSelectorCircleGridState();
}

class _ThemeSelectorCircleGridState extends State<ThemeSelectorCircleGrid> {
  bool _expanded = false;

  Color _colorFor(String family) {
    final brightnessKey =
        widget.brightness == Brightness.light ? 'light' : 'dark';
    return appThemeFamilies[family]?[brightnessKey]?.colorScheme.primary ??
        Colors.grey;
  }

  Color get _pillColor => widget.brightness == Brightness.light
      ? const Color(0xFFF2F2F7)
      : const Color(0xFF2C2C2E);

  void _toggle() => setState(() => _expanded = !_expanded);

  void _select(String family) {
    widget.onThemeChanged(family);
    setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 280),
      crossFadeState:
          _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: _buildCollapsed(),
      secondChild: _buildExpanded(),
    );
  }

  Widget _buildCollapsed() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: _pillColor,
        borderRadius: BorderRadius.circular(36),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _kThemeOrder.map((family) {
          final isSelected = family == widget.selectedTheme;
          final color = _colorFor(family);
          final size = isSelected ? 52.0 : 28.0;

          return GestureDetector(
            onTap: isSelected ? _toggle : () => _select(family),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withAlpha(140),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpanded() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: _pillColor,
        borderRadius: BorderRadius.circular(36),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ..._kThemeOrder.map((family) {
            final isSelected = family == widget.selectedTheme;
            final color = _colorFor(family);

            return GestureDetector(
              onTap: () => _select(family),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 2.5)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withAlpha(160),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.brightness == Brightness.light
                    ? Colors.black.withAlpha(20)
                    : Colors.white.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: widget.brightness == Brightness.light
                    ? Colors.black87
                    : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
