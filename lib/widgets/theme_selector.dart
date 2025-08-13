import 'package:devocional_nuevo/utils/theme_constants.dart';
import 'package:flutter/material.dart';

typedef ThemeChangedCallback = void Function(String selectedTheme);

class ThemeSelectorCircleGrid extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final themeFamilies = appThemeFamilies.keys.toList();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1,
      children: themeFamilies.map((family) {
        final themeData = appThemeFamilies[family]
            ?[brightness == Brightness.light ? 'light' : 'dark'];
        final primaryColor = themeData?.colorScheme.primary ?? Colors.grey;

        final isSelected = family == selectedTheme;

        return GestureDetector(
          onTap: () => onThemeChanged(family),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: primaryColor, width: 3)
                      : Border.all(color: Colors.transparent, width: 3),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryColor.withAlpha((255 * 0.4).round()),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? Center(
                        child: Icon(Icons.check, color: Colors.white, size: 24),
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  family,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? primaryColor
                        : Theme.of(context).colorScheme.onSurface.withAlpha(
                              (255 * 0.7).round(),
                            ),
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
