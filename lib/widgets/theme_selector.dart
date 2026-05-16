import 'package:devocional_nuevo/utils/constants/theme_constants.dart';
import 'package:flutter/material.dart';

typedef ThemeChangedCallback = void Function(String selectedTheme);

const _kThemeOrder = [
  'Deep Purple',
  'Gray',
  'Pink',
  'Cyan',
  'Green',
  'Light Blue',
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
  Color _colorFor(String family) {
    final brightnessKey =
        widget.brightness == Brightness.light ? 'light' : 'dark';
    return appThemeFamilies[family]?[brightnessKey]?.colorScheme.primary ??
        Colors.grey;
  }

  Color get _pillColor => widget.brightness == Brightness.light
      ? const Color(0xFFF2F2F7)
      : const Color(0xFF2C2C2E);

  Color get _iconColor =>
      widget.brightness == Brightness.light ? Colors.black54 : Colors.white70;

  List<String> get _visibleThemes {
    final others =
        _kThemeOrder.where((t) => t != widget.selectedTheme).toList();
    return [widget.selectedTheme, ...others.take(2)];
  }

  List<String> get _peekThemes {
    final others =
        _kThemeOrder.where((t) => t != widget.selectedTheme).toList();
    return others.skip(2).toList();
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) => _ThemeBottomSheet(
        selectedTheme: widget.selectedTheme,
        brightness: widget.brightness,
        colorFor: _colorFor,
        onSelect: (family) {
          widget.onThemeChanged(family);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final peek = _peekThemes;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: _pillColor,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ..._visibleThemes.map((family) {
            final isSelected = family == widget.selectedTheme;
            final color = _colorFor(family);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: GestureDetector(
                onTap: isSelected
                    ? () => _openSheet(context)
                    : () => widget.onThemeChanged(family),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withAlpha(130),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(Icons.check_rounded, size: 18, color: _iconColor)
                      : null,
                ),
              ),
            );
          }),

          const Spacer(flex: 1),

          // Overlapping peek stack
          if (peek.isNotEmpty)
            GestureDetector(
              onTap: () => _openSheet(context),
              child: SizedBox(
                width: 20.0 + (peek.length - 1) * 12.0,
                height: 42,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: peek.asMap().entries.map((e) {
                    return Positioned(
                      left: e.key * 12.0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _colorFor(e.value),
                          shape: BoxShape.circle,
                          border: Border.all(color: _pillColor, width: 1.2),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          const SizedBox(width: 6),

          // Chevron
          GestureDetector(
            onTap: () => _openSheet(context),
            child: Padding(
              padding: const EdgeInsets.only(left: 2, right: 4),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: _iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeBottomSheet extends StatelessWidget {
  final String selectedTheme;
  final Brightness brightness;
  final Color Function(String) colorFor;
  final void Function(String) onSelect;

  const _ThemeBottomSheet({
    required this.selectedTheme,
    required this.brightness,
    required this.colorFor,
    required this.onSelect,
  });

  Color get _sheetColor => brightness == Brightness.light
      ? const Color(0xFFF2F2F7)
      : const Color(0xFF2C2C2E);

  Color get _iconColor =>
      brightness == Brightness.light ? Colors.black54 : Colors.white70;

  @override
  Widget build(BuildContext context) {
    final ordered = [
      selectedTheme,
      ..._kThemeOrder.where((t) => t != selectedTheme),
    ];

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: _sheetColor,
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: _iconColor.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            LayoutBuilder(
              builder: (context, constraints) {
                final count = ordered.length;
                const spacing = 10.0;
                final circleSize =
                    ((constraints.maxWidth - spacing * (count - 1)) / count)
                        .clamp(48.0, 72.0);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ordered.map((family) {
                    final isSelected = family == selectedTheme;
                    final color = colorFor(family);

                    return GestureDetector(
                      onTap: () => onSelect(family),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: circleSize,
                        height: circleSize,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withAlpha(140),
                                    blurRadius: 14,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check_rounded,
                                size: circleSize * 0.42,
                                color: _iconColor,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
