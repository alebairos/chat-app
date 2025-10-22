import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_settings_model.dart';
import '../models/chat_message_model.dart';
import '../models/activity_model.dart';
import '../features/journal/models/journal_entry_model.dart';

/// Service for managing user settings and app state using Isar database
class UserSettingsService {
  static final UserSettingsService _instance = UserSettingsService._internal();
  factory UserSettingsService() => _instance;
  UserSettingsService._internal() {
    _initDatabase();
  }

  late Future<Isar> _database;

  /// Initialize the database connection
  void _initDatabase() {
    _database = _openDatabase();
  }

  /// Open the database with all required schemas
  Future<Isar> _openDatabase() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [
          ChatMessageModelSchema,
          ActivityModelSchema,
          UserSettingsModelSchema,
          JournalEntryModelSchema,
        ],
        directory: dir.path,
      );
    }
    return Future.value(Isar.getInstance());
  }

  /// Get the database instance, initializing if necessary
  Future<Isar> get database async {
    try {
      final isar = await _database;
      // Check if the instance is still open
      if (isar.isOpen) {
        return isar;
      } else {
        // Database was closed, reinitialize
        _initDatabase();
        return await _database;
      }
    } catch (e) {
      // Database initialization failed, reinitialize
      _initDatabase();
      return await _database;
    }
  }

  /// Get or create user settings
  Future<UserSettingsModel> _getUserSettings() async {
    final isar = await database;

    // Try to get existing settings
    UserSettingsModel? settings =
        await isar.userSettingsModels.where().findFirst();

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
    print(
        'RESET: 👤 User settings: hasCompletedOnboarding=${settings.hasCompletedOnboarding}');
    final shouldShow = !settings.hasCompletedOnboarding;
    print('RESET: 🔍 Should show onboarding: $shouldShow');
    return shouldShow;
  }

  /// Mark onboarding as completed
  Future<void> markOnboardingComplete() async {
    final isar = await database;
    final settings = await _getUserSettings();

    settings.markOnboardingComplete();

    await isar.writeTxn(() async {
      await isar.userSettingsModels.put(settings);
    });
  }

  /// Reset onboarding state (for testing or re-showing)
  Future<void> resetOnboarding() async {
    final isar = await database;
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
    final isar = await database;
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
    final isar = await database;
    final settings = await _getUserSettings();

    settings.lastActivePersona = personaKey;
    settings.updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.userSettingsModels.put(settings);
    });
  }

  /// Reset all user data (for complete app reset)
  Future<void> resetAllUserData() async {
    print('RESET: 💾 UserSettingsService starting reset...');
    final isar = await database;

    await isar.writeTxn(() async {
      // Clear all collections
      await isar.userSettingsModels.clear();
      await isar.chatMessageModels.clear();
      await isar.activityModels.clear();

      // Try to clear journal entries (may not exist)
      try {
        await isar.journalEntryModels.clear();
      } catch (e) {
        print('RESET: ℹ️ Journal entries not found (OK): $e');
      }

      // Create fresh user settings
      final newSettings = UserSettingsModel.initial();
      await isar.userSettingsModels.put(newSettings);
    });

    // Close the current database instance to ensure clean restart
    await isar.close();
    print('RESET: 🔄 Database closed for clean restart');

    // Reinitialize for next access
    _initDatabase();

    print('RESET: ✅ UserSettingsService reset completed');
  }

  /// Get user settings for debugging/admin purposes
  Future<UserSettingsModel> getUserSettings() async {
    return await _getUserSettings();
  }
}
