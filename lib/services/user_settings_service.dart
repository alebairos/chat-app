import 'package:isar/isar.dart';
import '../models/user_settings_model.dart';
import 'database_service.dart';

/// Service for managing user settings and app state using Isar database
class UserSettingsService {
  static final UserSettingsService _instance = UserSettingsService._internal();
  factory UserSettingsService() => _instance;
  UserSettingsService._internal();

  /// Get the database instance through the centralized service
  Future<Isar> get _database => DatabaseService.instance.database;

  /// Get or create user settings
  Future<UserSettingsModel> _getUserSettings() async {
    final isar = await _database;

    // Try to get existing settings
    UserSettingsModel? settings = await isar.userSettingsModels
        .where()
        .findFirst();

    if (settings == null) {
      // Create initial settings
      settings = UserSettingsModel.initial();
      await isar.writeTxn(() async {
        await isar.userSettingsModels.put(settings!);
      });
    }

    return settings;
  }

  /// Check if user should see onboarding flow
  Future<bool> shouldShowOnboarding() async {
    final settings = await _getUserSettings();
    print('RESET: 👤 User settings: hasCompletedOnboarding=${settings.hasCompletedOnboarding}');
    final shouldShow = !settings.hasCompletedOnboarding;
    print('RESET: 🔍 Should show onboarding: $shouldShow');
    return shouldShow;
  }

  /// Mark onboarding as completed
  Future<void> markOnboardingComplete() async {
    final isar = await _database;
    final settings = await _getUserSettings();

    settings.markOnboardingComplete();

    await isar.writeTxn(() async {
      await isar.userSettingsModels.put(settings);
    });
  }

  /// Reset onboarding state (for testing or re-showing)
  Future<void> resetOnboarding() async {
    final isar = await _database;
    final settings = await _getUserSettings();

    settings.resetOnboarding();

    await isar.writeTxn(() async {
      await isar.userSettingsModels.put(settings);
    });
  }

  /// Get user name
  Future<String?> getUserName() async {
    final settings = await _getUserSettings();
    return settings.userName;
  }

  /// Set user name
  Future<void> setUserName(String name) async {
    final isar = await _database;
    final settings = await _getUserSettings();

    settings.setUserName(name);

    await isar.writeTxn(() async {
      await isar.userSettingsModels.put(settings);
    });
  }

  /// Get last active persona
  Future<String?> getLastActivePersona() async {
    final settings = await _getUserSettings();
    return settings.lastActivePersona;
  }

  /// Set last active persona
  Future<void> setLastActivePersona(String personaKey) async {
    final isar = await _database;
    final settings = await _getUserSettings();

    settings.lastActivePersona = personaKey;
    settings.updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.userSettingsModels.put(settings);
    });
  }

  /// Reset all user data (for complete app reset)
  Future<void> resetAllUserData() async {
    print('RESET: 💾 UserSettingsService calling DatabaseService...');
    // Use the centralized database service method that handles reinitialization
    await DatabaseService.instance.clearAllDataAndReinitialize();
    print('RESET: ✅ UserSettingsService reset completed');
  }

  /// Get user settings for debugging/admin purposes
  Future<UserSettingsModel> getUserSettings() async {
    return await _getUserSettings();
  }
}