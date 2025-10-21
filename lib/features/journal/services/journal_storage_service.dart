import 'package:isar/isar.dart';
import '../models/journal_entry_model.dart';
import '../../../services/chat_storage_service.dart';
import '../../../utils/logger.dart';

/// Service for managing journal entry storage and retrieval
class JournalStorageService {
  static final Logger _logger = Logger();

  /// Get or initialize the database instance (uses main app database)
  static Future<Isar> _getDatabase() async {
    try {
      // Use the main app database through ChatStorageService
      final chatStorage = ChatStorageService();
      return await chatStorage.db;
    } catch (e) {
      _logger.error('JournalStorage: Failed to get database: $e');
      rethrow;
    }
  }

  /// Save a journal entry to the database
  static Future<void> saveJournalEntry(JournalEntryModel entry) async {
    try {
      final isar = await _getDatabase();
      await isar.writeTxn(() async {
        await isar.journalEntryModels.put(entry);
      });

      _logger.info(
          'JournalStorage: Saved journal entry for ${entry.date} in ${entry.language}');
    } catch (e) {
      _logger.error('JournalStorage: Failed to save journal entry: $e');
      rethrow;
    }
  }

  /// Get journal entries with flexible filtering
  static Future<List<JournalEntryModel>> getJournalEntries({
    DateTime? startDate,
    DateTime? endDate,
    String? language,
    int? limit,
  }) async {
    try {
      final isar = await _getDatabase();
      List<JournalEntryModel> results;

      // Build query based on filters
      if (startDate != null && endDate != null && language != null) {
        results = await isar.journalEntryModels
            .where()
            .filter()
            .dateBetween(startDate, endDate)
            .and()
            .languageEqualTo(language)
            .sortByDate()
            .findAll();
      } else if (startDate != null && endDate != null) {
        results = await isar.journalEntryModels
            .where()
            .filter()
            .dateBetween(startDate, endDate)
            .sortByDate()
            .findAll();
      } else if (startDate != null && language != null) {
        results = await isar.journalEntryModels
            .where()
            .filter()
            .dateGreaterThan(startDate)
            .and()
            .languageEqualTo(language)
            .sortByDate()
            .findAll();
      } else if (startDate != null) {
        results = await isar.journalEntryModels
            .where()
            .filter()
            .dateGreaterThan(startDate)
            .sortByDate()
            .findAll();
      } else if (endDate != null && language != null) {
        results = await isar.journalEntryModels
            .where()
            .filter()
            .dateLessThan(endDate)
            .and()
            .languageEqualTo(language)
            .sortByDate()
            .findAll();
      } else if (endDate != null) {
        results = await isar.journalEntryModels
            .where()
            .filter()
            .dateLessThan(endDate)
            .sortByDate()
            .findAll();
      } else if (language != null) {
        results = await isar.journalEntryModels
            .where()
            .filter()
            .languageEqualTo(language)
            .sortByDate()
            .findAll();
      } else {
        results = await isar.journalEntryModels.where().sortByDate().findAll();
      }

      // Sort in descending order (most recent first) and apply limit
      results.sort((a, b) => b.date.compareTo(a.date));
      if (limit != null && results.length > limit) {
        results = results.take(limit).toList();
      }

      _logger
          .debug('JournalStorage: Retrieved ${results.length} journal entries');
      return results;
    } catch (e) {
      _logger.error('JournalStorage: Failed to get journal entries: $e');
      return [];
    }
  }

  /// Get recent journal entries for context consistency
  static Future<List<JournalEntryModel>> getRecentJournalContext({
    required DateTime beforeDate,
    required String language,
    int limit = 3,
    int maxDaysBack = 7,
  }) async {
    try {
      final isar = await _getDatabase();
      final startDate = beforeDate.subtract(Duration(days: maxDaysBack));

      final results = await isar.journalEntryModels
          .where()
          .filter()
          .dateBetween(startDate, beforeDate)
          .and()
          .languageEqualTo(language)
          .sortByDate()
          .findAll();

      // Sort in descending order (most recent first) and apply limit
      results.sort((a, b) => b.date.compareTo(a.date));
      final limitedResults = results.take(limit).toList();

      _logger.debug(
          'JournalStorage: Retrieved ${limitedResults.length} recent entries for context');
      return limitedResults;
    } catch (e) {
      _logger.error('JournalStorage: Failed to get recent journal context: $e');
      return [];
    }
  }

  /// Get a specific journal entry for a date and language
  static Future<JournalEntryModel?> getJournalForDate(
      DateTime date, String language) async {
    try {
      final isar = await _getDatabase();

      // Normalize date to start of day for comparison
      final normalizedDate = DateTime(date.year, date.month, date.day);

      final result = await isar.journalEntryModels
          .where()
          .filter()
          .dateEqualTo(normalizedDate)
          .and()
          .languageEqualTo(language)
          .sortByCreatedAtDesc()
          .findFirst();

      if (result != null) {
        _logger.debug(
            'JournalStorage: Found journal entry for $normalizedDate in $language');
      }

      return result;
    } catch (e) {
      _logger.error('JournalStorage: Failed to get journal for date: $e');
      return null;
    }
  }

  /// Delete a journal entry
  static Future<bool> deleteJournalEntry(int id) async {
    try {
      final isar = await _getDatabase();
      final success = await isar.writeTxn(() async {
        return await isar.journalEntryModels.delete(id);
      });

      if (success) {
        _logger.info('JournalStorage: Deleted journal entry with id $id');
      }

      return success;
    } catch (e) {
      _logger.error('JournalStorage: Failed to delete journal entry: $e');
      return false;
    }
  }

  /// Get total count of journal entries
  static Future<int> getJournalCount({String? language}) async {
    try {
      final isar = await _getDatabase();

      if (language != null) {
        final results = await isar.journalEntryModels
            .where()
            .filter()
            .languageEqualTo(language)
            .findAll();
        return results.length;
      } else {
        final results = await isar.journalEntryModels.where().findAll();
        return results.length;
      }
    } catch (e) {
      _logger.error('JournalStorage: Failed to get journal count: $e');
      return 0;
    }
  }

  /// Check if database is available and accessible
  static Future<bool> isDatabaseAvailable() async {
    try {
      final isar = await _getDatabase();
      await isar.journalEntryModels.where().limit(1).findAll();
      return true;
    } catch (e) {
      _logger.warning('JournalStorage: Database not available: $e');
      return false;
    }
  }
}
