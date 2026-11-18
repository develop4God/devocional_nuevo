import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller for managing devotional font size preferences.
///
/// Encapsulates font size loading, persistence, and bounds checking.
/// Follows Single Responsibility Principle - only manages font size state.
class FontSizeController extends ChangeNotifier {
  /// SharedPreferences key for persisting font size
  static const String _prefKey = 'devocional_font_size';

  /// Selectable font sizes (five named steps in the font size panel)
  static const List<double> fontSizeStops = [16.0, 20.0, 24.0, 28.0, 32.0];

  /// Minimum font size allowed
  static const double minFontSize = 16.0;

  /// Maximum font size allowed
  static const double maxFontSize = 32.0;

  /// Default font size
  static const double defaultFontSize = 16.0;

  /// Nearest stop for [size]; ties resolve to the lower stop.
  /// Maps legacy saved values (e.g. 12.0, 17.0, 40.0) onto the current stops.
  static double snapToStop(double size) {
    var nearest = fontSizeStops.first;
    for (final stop in fontSizeStops) {
      if ((stop - size).abs() < (nearest - size).abs()) nearest = stop;
    }
    return nearest;
  }

  double _fontSize = defaultFontSize;
  bool _showControls = false;

  /// Current font size
  double get fontSize => _fontSize;

  /// Whether font controls are visible
  bool get showControls => _showControls;

  /// Whether font size can be increased
  bool get canIncrease => _fontSize < maxFontSize;

  /// Whether font size can be decreased
  bool get canDecrease => _fontSize > minFontSize;

  /// Load saved font size from SharedPreferences, snapped to the nearest stop
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = snapToStop(prefs.getDouble(_prefKey) ?? defaultFontSize);
    notifyListeners();
  }

  /// Set the font size to the stop nearest to [size] and persist it
  Future<void> setFontSize(double size) async {
    final snapped = snapToStop(size);
    if (snapped == _fontSize) return;
    _fontSize = snapped;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefKey, _fontSize);
  }

  /// Move to the next stop, clamped to [maxFontSize]
  Future<void> increase() async {
    if (!canIncrease) return;
    await setFontSize(
        fontSizeStops[fontSizeStops.indexOf(snapToStop(_fontSize)) + 1]);
  }

  /// Move to the previous stop, clamped to [minFontSize]
  Future<void> decrease() async {
    if (!canDecrease) return;
    await setFontSize(
        fontSizeStops[fontSizeStops.indexOf(snapToStop(_fontSize)) - 1]);
  }

  /// Restore the default font size
  Future<void> reset() => setFontSize(defaultFontSize);

  /// Toggle visibility of font size controls
  void toggleControls() {
    _showControls = !_showControls;
    notifyListeners();
  }

  /// Hide font size controls
  void hideControls() {
    if (!_showControls) return;
    _showControls = false;
    notifyListeners();
  }
}
