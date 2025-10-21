import 'package:isar/isar.dart';

part 'user_settings_model.g.dart';

/// Model for storing user settings and app state
@collection
class UserSettingsModel {
  Id id = Isar.autoIncrement;

  // Onboarding tracking
  bool hasCompletedOnboarding = false;
  String onboardingVersion = 'v1'; // Allow for future onboarding versions
  DateTime? onboardingCompletedAt;

  // User profile
  String? userName;
  DateTime? userCreatedAt;

  // App preferences
  bool hasSeenWelcome = false;
  String? lastActivePersona;

  // Metadata
  late DateTime createdAt;
  late DateTime updatedAt;

  UserSettingsModel() {
    final now = DateTime.now();
    createdAt = now;
    updatedAt = now;
  }

  /// Create initial user settings
  UserSettingsModel.initial({
    this.hasCompletedOnboarding = false,
    this.onboardingVersion = 'v1',
    this.userName,
    this.hasSeenWelcome = false,
    this.lastActivePersona,
  }) {
    final now = DateTime.now();
    createdAt = now;
    updatedAt = now;
    userCreatedAt = now;
  }

  /// Mark onboarding as completed
  UserSettingsModel markOnboardingComplete() {
    hasCompletedOnboarding = true;
    onboardingCompletedAt = DateTime.now();
    updatedAt = DateTime.now();
    return this;
  }

  /// Reset onboarding status (for testing or re-showing)
  UserSettingsModel resetOnboarding() {
    hasCompletedOnboarding = false;
    onboardingCompletedAt = null;
    updatedAt = DateTime.now();
    return this;
  }

  /// Update user name
  UserSettingsModel setUserName(String name) {
    userName = name;
    updatedAt = DateTime.now();
    return this;
  }

  /// Clear all user data (for reset functionality)
  UserSettingsModel reset() {
    hasCompletedOnboarding = false;
    onboardingCompletedAt = null;
    userName = null;
    hasSeenWelcome = false;
    lastActivePersona = null;
    updatedAt = DateTime.now();
    return this;
  }

  @override
  String toString() =>
      'UserSettingsModel(onboarding: $hasCompletedOnboarding, user: $userName, created: ${createdAt.toIso8601String()})';
}