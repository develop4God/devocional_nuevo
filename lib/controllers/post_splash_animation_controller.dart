import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Manages the one-time post-splash Lottie animation display.
///
/// Handles random animation selection, precaching, and timed
/// auto-dismiss. Follows Single Responsibility Principle: only
/// responsible for post-splash animation state.
class PostSplashAnimationController extends ChangeNotifier {
  /// Duration to show the animation before auto-hiding
  static const animationDuration = Duration(seconds: 7);

  /// Width of the Lottie animation widget
  static const animationWidth = 200.0;

  /// Default fallback animation asset
  static const fallbackAsset = 'assets/lottie/happy_bird.json';

  /// Available Lottie animation assets
  static const List<String> lottieAssets = [
    'assets/lottie/bird_love.json',
    'assets/lottie/confetti.json',
    'assets/lottie/happy_bird.json',
    'assets/lottie/dog_walking.json',
    'assets/lottie/book_animation.json',
    'assets/lottie/plant.json',
  ];

  static bool _hasBeenShown = false;

  String? _selectedAsset;
  bool _isVisible = false;

  /// The randomly selected Lottie asset path
  String get selectedAsset => _selectedAsset ?? fallbackAsset;

  /// Whether the animation is currently visible
  bool get isVisible => _isVisible;

  /// Initialize: pick a random animation and start the timed display.
  ///
  /// The animation is only shown once per app session (static flag).
  /// [onDismiss] is called when the animation should be hidden —
  /// use it to trigger `setState` in the host widget.
  void initialize({required VoidCallback onDismiss}) {
    _pickRandomAsset();

    if (!_hasBeenShown) {
      _isVisible = true;
      _hasBeenShown = true;
      notifyListeners();

      Future.delayed(animationDuration, () {
        _isVisible = false;
        notifyListeners();
        onDismiss();
      });
    }
  }

  /// Precache all Lottie animation assets for smooth rendering.
  Future<void> precacheAnimations() async {
    try {
      await Future.wait([
        rootBundle.load('assets/lottie/fire.json'),
        ...lottieAssets.map((asset) => rootBundle.load(asset)),
      ]);
      debugPrint('✅ Lottie animations precached successfully');
    } catch (e) {
      debugPrint('⚠️ Error precaching Lottie animations: $e');
    }
  }

  void _pickRandomAsset() {
    final random = Random();
    _selectedAsset = lottieAssets[random.nextInt(lottieAssets.length)];
  }

  /// Reset the static flag (useful for testing).
  @visibleForTesting
  static void resetShownFlag() {
    _hasBeenShown = false;
  }
}
