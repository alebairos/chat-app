import 'user_settings_service.dart';

/// Manages onboarding state and first-install detection using Isar database
class OnboardingManager {
  static final UserSettingsService _settingsService = UserSettingsService();

  /// Check if user should see onboarding flow
  static Future<bool> shouldShowOnboarding() async {
    return await _settingsService.shouldShowOnboarding();
  }

  /// Mark onboarding as completed
  static Future<void> markOnboardingComplete() async {
    await _settingsService.markOnboardingComplete();
  }

  /// Reset onboarding state (for testing or re-showing)
  static Future<void> resetOnboarding() async {
    await _settingsService.resetOnboarding();
  }

  /// Reset all user data (for complete app reset)
  static Future<void> resetAllUserData() async {
    print('RESET: 🎯 OnboardingManager calling UserSettingsService...');
    await _settingsService.resetAllUserData();
    print('RESET: ✅ OnboardingManager reset completed');
  }
}
