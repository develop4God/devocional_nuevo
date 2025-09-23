import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _remoteConfigOnboardingKey = 'enable_onboarding_flow';

  static OnboardingService? _instance;

  OnboardingService._internal();

  static OnboardingService get instance {
    _instance ??= OnboardingService._internal();
    return _instance!;
  }

  /// Check if onboarding has been completed
  Future<bool> isOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingCompleteKey) ?? false;
    } catch (e) {
      // If there's an error reading preferences, assume onboarding is not complete
      return false;
    }
  }

  /// Mark onboarding as complete
  Future<void> setOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompleteKey, true);
    } catch (e) {
      // Handle error silently - app should continue to work
      print('Failed to save onboarding completion status: $e');
    }
  }

  /// Check if onboarding flow is enabled via Firebase Remote Config
  Future<bool> isOnboardingEnabled() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      // Set default values
      await remoteConfig.setDefaults({_remoteConfigOnboardingKey: true});

      // Try to fetch and activate
      await remoteConfig.fetchAndActivate();

      // Get the value
      return remoteConfig.getBool(_remoteConfigOnboardingKey);
    } catch (e) {
      // If Firebase Remote Config fails, default to true (onboarding enabled)
      print(
        'Failed to fetch remote config, defaulting to onboarding enabled: $e',
      );
      return true;
    }
  }

  /// Check if we should show onboarding flow
  /// Returns true if onboarding is enabled AND not yet completed
  Future<bool> shouldShowOnboarding() async {
    final isEnabled = await isOnboardingEnabled();
    if (!isEnabled) {
      return false;
    }

    final isComplete = await isOnboardingComplete();
    return !isComplete;
  }

  /// Reset onboarding status (for testing or re-showing)
  Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingCompleteKey);
    } catch (e) {
      print('Failed to reset onboarding status: $e');
    }
  }
}
