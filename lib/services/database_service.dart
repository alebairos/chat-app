import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/chat_message_model.dart';
import '../models/activity_model.dart';
import '../models/user_settings_model.dart';
import '../features/journal/models/journal_entry_model.dart';

/// Centralized database service that manages Isar instance lifecycle
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();
  DatabaseService._();

  Isar? _isar;
  Future<Isar>? _initFuture;

  /// Get the database instance, initializing if necessary
  Future<Isar> get database async {
    if (_isar != null && _isar!.isOpen) {
      return _isar!;
    }

    // If initialization is already in progress, wait for it
    if (_initFuture != null) {
      return await _initFuture!;
    }

    // Start initialization
    _initFuture = _initializeDatabase();
    return await _initFuture!;
  }

  /// Initialize the database
  Future<Isar> _initializeDatabase() async {
    try {
      // Close existing instance if it exists
      if (_isar != null) {
        await _isar!.close();
        _isar = null;
      }

      final dir = await getApplicationDocumentsDirectory();
      _isar = await Isar.open(
        [
          ChatMessageModelSchema,
          ActivityModelSchema,
          UserSettingsModelSchema,
          JournalEntryModelSchema
        ],
        directory: dir.path,
      );

      return _isar!;
    } catch (e) {
      _initFuture = null;
      rethrow;
    } finally {
      _initFuture = null;
    }
  }

  /// Close the database and reinitialize it (for use after reset operations)
  Future<void> reinitializeDatabase() async {
    try {
      // Close current instance
      if (_isar != null) {
        await _isar!.close();
        _isar = null;
      }

      // Clear any pending initialization
      _initFuture = null;

      // Small delay to ensure everything is cleaned up
      await Future.delayed(const Duration(milliseconds: 100));

      // Force reinitialization on next access
      await database;
    } catch (e) {
      // If there's an error, reset everything and try again
      _isar = null;
      _initFuture = null;
      await Future.delayed(const Duration(milliseconds: 500));
      await database;
    }
  }

  /// Check if the database is currently open and accessible
  bool get isOpen => _isar != null && _isar!.isOpen;

  /// Clear all data and reinitialize (for reset functionality)
  Future<void> clearAllDataAndReinitialize() async {
    try {
      print('RESET: 🔄 Starting database reset...');

      // First, ensure we have a fresh database instance
      if (_isar != null && !_isar!.isOpen) {
        print('RESET: 🔄 Database is closed, reinitializing...');
        _isar = null;
        _initFuture = null;
      }

      final db = await database;
      print('RESET: 📱 Database instance obtained (isOpen: ${db.isOpen})');

      if (!db.isOpen) {
        print('RESET: ❌ Database is not open, forcing reinitialization...');
        await reinitializeDatabase();
        final newDb = await database;
        return await _performDataClear(newDb);
      }

      return await _performDataClear(db);

    } catch (e) {
      print('RESET: ❌ Database reset failed: $e');

      // If we get an "instance closed" error, try to recover
      if (e.toString().contains('already been closed')) {
        print('RESET: 🔄 Attempting recovery from closed instance...');
        try {
          _isar = null;
          _initFuture = null;
          await Future.delayed(const Duration(milliseconds: 100));
          final recoveredDb = await database;
          return await _performDataClear(recoveredDb);
        } catch (recoveryError) {
          print('RESET: ❌ Recovery failed: $recoveryError');
          rethrow;
        }
      }
      rethrow;
    }
  }

  /// Perform the actual data clearing operations
  Future<void> _performDataClear(Isar db) async {
    // Check counts before clearing
    try {
      final messagesBefore = await db.chatMessageModels.count();
      final activitiesBefore = await db.activityModels.count();
      final settingsBefore = await db.userSettingsModels.count();
      print('RESET: 📊 Before reset: Messages=$messagesBefore, Activities=$activitiesBefore, Settings=$settingsBefore');
    } catch (e) {
      print('RESET: ⚠️ Error counting before: $e');
    }

    // Clear all data in a single transaction
    print('RESET: 🗑️ Starting clear transaction...');
    await db.writeTxn(() async {
      // Clear all collections
      await db.userSettingsModels.clear();
      print('RESET: ✅ User settings cleared');

      await db.chatMessageModels.clear();
      print('RESET: ✅ Chat messages cleared');

      await db.activityModels.clear();
      print('RESET: ✅ Activities cleared');

      // Try to clear journal entries (may not exist)
      try {
        await db.journalEntryModels.clear();
        print('RESET: ✅ Journal entries cleared');
      } catch (e) {
        print('RESET: ℹ️ Journal entries not found (OK): $e');
      }
    });

    // Check counts after clearing
    try {
      final messagesAfter = await db.chatMessageModels.count();
      final activitiesAfter = await db.activityModels.count();
      final settingsAfter = await db.userSettingsModels.count();
      print('RESET: 📊 After clearing: Messages=$messagesAfter, Activities=$activitiesAfter, Settings=$settingsAfter');
    } catch (e) {
      print('RESET: ⚠️ Error counting after: $e');
    }

    // Small delay to ensure transaction is committed
    await Future.delayed(const Duration(milliseconds: 100));

    // Create fresh initial user settings in a separate transaction
    print('RESET: 🆕 Creating fresh settings...');
    await db.writeTxn(() async {
      final newSettings = UserSettingsModel.initial();
      await db.userSettingsModels.put(newSettings);
      print('RESET: ✅ Created fresh settings: hasCompletedOnboarding=${newSettings.hasCompletedOnboarding}');
    });

    // Verify the settings were saved
    try {
      final finalSettings = await db.userSettingsModels.where().findFirst();
      print('RESET: 🔍 Final settings: hasCompletedOnboarding=${finalSettings?.hasCompletedOnboarding}');
    } catch (e) {
      print('RESET: ⚠️ Error verifying settings: $e');
    }

    print('RESET: ✅ Database reset complete!');
  }
}