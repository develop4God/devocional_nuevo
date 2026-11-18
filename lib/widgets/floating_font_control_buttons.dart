import 'package:devocional_nuevo/controllers/font_size_controller.dart';
import 'package:devocional_nuevo/extensions/string_extensions.dart';
import 'package:flutter/material.dart';

/// Bottom panel to pick the devotional font size among named stops.
class FloatingFontControlButtons extends StatelessWidget {
  static const Key decreaseButtonKey = Key('font_decrease_button');
  static const Key increaseButtonKey = Key('font_increase_button');

  static const double _buttonSize = 64;
  static const double _smallGlyphSize = 18;
  static const double _bigGlyphSize = 32;
  static const double _minTouchTarget = 56;

  /// i18n keys of the step names, aligned with [FontSizeController.fontSizeStops]
  static const List<String> _stepNameKeys = [
    'bible.font_step_normal',
    'bible.font_step_large',
    'bible.font_step_larger',
    'bible.font_step_very_large',
    'bible.font_step_maximum',
  ];

  static final RegExp _latinLetter = RegExp(r'[A-Za-z]');

  /// App bar icon that opens this panel. The default icon draws a Latin "A+",
  /// so languages whose translated glyph is not Latin get a neutral icon.
  static IconData appBarIcon() => _latinLetter.hasMatch('bible.font_glyph'.tr())
      ? Icons.text_increase_outlined
      : Icons.zoom_in;

  final double currentFontSize;
  final ValueChanged<double> onSizeSelected;
  final VoidCallback onReset;
  final VoidCallback onClose;

  const FloatingFontControlButtons({
    super.key,
    required this.currentFontSize,
    required this.onSizeSelected,
    required this.onReset,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stops = FontSizeController.fontSizeStops;
    final index = stops.indexOf(FontSizeController.snapToStop(currentFontSize));
    final canIncrease = index < stops.length - 1;
    final canDecrease = index > 0;
    final title = 'bible.font_size_label'.tr();
    final stepName = _stepNameKeys[index].tr();

    return Stack(
      children: [
        // Tap outside to close
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onClose,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Material(
            elevation: 16,
            color: colorScheme.surface,
            shadowColor: colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              side: BorderSide(color: colorScheme.primary, width: 2),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  stepName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(
                            minWidth: _minTouchTarget,
                            minHeight: _minTouchTarget,
                          ),
                          tooltip: 'bible.font_reset'.tr(),
                          onPressed: onReset,
                          icon: const Icon(Icons.undo),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(
                            minWidth: _minTouchTarget,
                            minHeight: _minTouchTarget,
                          ),
                          iconSize: 28,
                          tooltip: 'bible.close'.tr(),
                          onPressed: onClose,
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _stepButton(
                          key: decreaseButtonKey,
                          tooltip: 'bible.decrease_font'.tr(),
                          glyphSize: _smallGlyphSize,
                          onPressed: canDecrease
                              ? () => onSizeSelected(stops[index - 1])
                              : null,
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 12,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 16,
                              ),
                              tickMarkShape: const RoundSliderTickMarkShape(
                                tickMarkRadius: 4,
                              ),
                            ),
                            child: MergeSemantics(
                              child: Semantics(
                                label: title,
                                child: Slider(
                                  min: 0,
                                  max: (stops.length - 1).toDouble(),
                                  divisions: stops.length - 1,
                                  value: index.toDouble(),
                                  semanticFormatterCallback: (_) => stepName,
                                  onChanged: (v) =>
                                      onSizeSelected(stops[v.round()]),
                                ),
                              ),
                            ),
                          ),
                        ),
                        _stepButton(
                          key: increaseButtonKey,
                          tooltip: 'bible.increase_font'.tr(),
                          glyphSize: _bigGlyphSize,
                          onPressed: canIncrease
                              ? () => onSizeSelected(stops[index + 1])
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepButton({
    required Key key,
    required String tooltip,
    required double glyphSize,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: _buttonSize,
      height: _buttonSize,
      child: Tooltip(
        message: tooltip,
        child: FilledButton(
          key: key,
          style: FilledButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
          ),
          onPressed: onPressed,
          child: Text(
            'bible.font_glyph'.tr(),
            style: TextStyle(fontSize: glyphSize, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
