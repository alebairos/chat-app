import 'package:shared_preferences/shared_preferences.dart';

/// Manages onboarding state and first-install detection
class OnboardingManager {
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding_v1';

  /// Check if user should see onboarding flow
  static Future<bool> shouldShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_hasSeenOnboardingKey) ?? false);
  }

  /// Mark onboarding as completed
  static Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, true);
  }

  /// Reset onboarding state (for testing or re-showing)
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasSeenOnboardingKey);
  }
}
