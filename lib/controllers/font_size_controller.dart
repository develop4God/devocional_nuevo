import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller for managing devotional font size preferences.
///
/// Encapsulates font size loading, persistence, and bounds checking.
/// Follows Single Responsibility Principle - only manages font size state.
class FontSizeController extends ChangeNotifier {
  /// SharedPreferences key for persisting font size
  static const String _prefKey = 'devocional_font_size';

  /// Minimum font size allowed
  static const double minFontSize = 12.0;

  /// Maximum font size allowed
  static const double maxFontSize = 28.0;

  /// Default font size
  static const double defaultFontSize = 16.0;

  /// Font size adjustment step
  static const double fontSizeStep = 1.0;

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

  /// Load saved font size from SharedPreferences
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble(_prefKey) ?? defaultFontSize;
    notifyListeners();
  }

  /// Increase font size by one step, clamped to [maxFontSize]
  Future<void> increase() async {
    if (!canIncrease) return;
    _fontSize += fontSizeStep;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefKey, _fontSize);
  }

  /// Decrease font size by one step, clamped to [minFontSize]
  Future<void> decrease() async {
    if (!canDecrease) return;
    _fontSize -= fontSizeStep;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefKey, _fontSize);
  }

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
