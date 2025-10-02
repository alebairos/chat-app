import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:ai_personas_app/features/journal/models/journal_entry_model.dart';
import 'package:ai_personas_app/models/chat_message_model.dart';
import 'package:ai_personas_app/models/activity_model.dart';

void main() {
  group('FT-165 Journal Entry Model', () {
    late Isar testDatabase;

    setUp(() async {
      // Create a fresh in-memory database for each test
      // Include all schemas that the main app uses
      testDatabase = await Isar.open(
        [JournalEntryModelSchema, ChatMessageModelSchema, ActivityModelSchema],
        directory: '',
        name: 'test_journal_${DateTime.now().millisecondsSinceEpoch}',
      );
    });

    tearDown(() async {
      await testDatabase.close(deleteFromDisk: true);
    });

    test('should create journal entry with correct properties', () async {
      // Arrange - Create a simple journal entry
      final entry = JournalEntryModel.create(
        date: DateTime(2025, 10, 1),
        language: 'pt_BR',
        content: 'oi, é seu reflexo aqui. hoje foi um dia interessante...',
        messageCount: 5,
        activityCount: 3,
        generationTimeSeconds: 2.5,
      );

      // Assert - Verify properties are set correctly
      expect(entry.date, equals(DateTime(2025, 10, 1)));
      expect(entry.language, equals('pt_BR'));
      expect(entry.content, contains('reflexo aqui'));
      expect(entry.messageCount, equals(5));
      expect(entry.activityCount, equals(3));
      expect(entry.generationTimeSeconds, equals(2.5));
      expect(entry.createdAt, isNotNull);
    });

    test('should save and retrieve journal entry from database', () async {
      // Arrange - Create a journal entry
      final entry = JournalEntryModel.create(
        date: DateTime(2025, 10, 1),
        language: 'pt_BR',
        content: 'teste de entrada no diário',
        messageCount: 3,
        activityCount: 2,
        generationTimeSeconds: 1.5,
      );

      // Act - Save to database
      await testDatabase.writeTxn(() async {
        await testDatabase.journalEntryModels.put(entry);
      });

      // Retrieve from database
      final retrieved = await testDatabase.journalEntryModels
          .where()
          .filter()
          .dateEqualTo(DateTime(2025, 10, 1))
          .and()
          .languageEqualTo('pt_BR')
          .findFirst();

      // Assert - Verify the entry was saved and retrieved correctly
      expect(retrieved, isNotNull, reason: 'Journal entry should be found');
      expect(retrieved!.content, equals('teste de entrada no diário'));
      expect(retrieved.language, equals('pt_BR'));
      expect(retrieved.messageCount, equals(3));
      expect(retrieved.activityCount, equals(2));
    });

    test('should handle different languages for same date', () async {
      // Arrange - Create entries in different languages for same date
      final date = DateTime(2025, 10, 1);

      final ptEntry = JournalEntryModel.create(
        date: date,
        language: 'pt_BR',
        content: 'entrada em português',
        messageCount: 3,
        activityCount: 2,
        generationTimeSeconds: 1.5,
      );

      final enEntry = JournalEntryModel.create(
        date: date,
        language: 'en_US',
        content: 'entry in english',
        messageCount: 3,
        activityCount: 2,
        generationTimeSeconds: 1.8,
      );

      // Act - Save both entries
      await testDatabase.writeTxn(() async {
        await testDatabase.journalEntryModels.put(ptEntry);
        await testDatabase.journalEntryModels.put(enEntry);
      });

      // Retrieve each by language
      final ptResult = await testDatabase.journalEntryModels
          .where()
          .filter()
          .dateEqualTo(date)
          .and()
          .languageEqualTo('pt_BR')
          .findFirst();

      final enResult = await testDatabase.journalEntryModels
          .where()
          .filter()
          .dateEqualTo(date)
          .and()
          .languageEqualTo('en_US')
          .findFirst();

      // Assert - Each language should return its own entry
      expect(ptResult, isNotNull);
      expect(ptResult!.content, equals('entrada em português'));
      expect(ptResult.language, equals('pt_BR'));

      expect(enResult, isNotNull);
      expect(enResult!.content, equals('entry in english'));
      expect(enResult.language, equals('en_US'));
    });

    test('should provide correct time ago strings', () async {
      // Arrange - Create entries with different dates
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final threeDaysAgo = today.subtract(const Duration(days: 3));

      final todayEntry = JournalEntryModel.create(
        date: today,
        language: 'pt_BR',
        content: 'hoje',
        messageCount: 1,
        activityCount: 1,
        generationTimeSeconds: 1.0,
      );

      final yesterdayEntry = JournalEntryModel.create(
        date: yesterday,
        language: 'en_US',
        content: 'yesterday',
        messageCount: 1,
        activityCount: 1,
        generationTimeSeconds: 1.0,
      );

      final oldEntry = JournalEntryModel.create(
        date: threeDaysAgo,
        language: 'pt_BR',
        content: 'antigo',
        messageCount: 1,
        activityCount: 1,
        generationTimeSeconds: 1.0,
      );

      // Assert - Check time ago strings
      expect(todayEntry.getTimeAgo('pt_BR'), equals('hoje'));
      expect(todayEntry.getTimeAgo('en_US'), equals('today'));

      expect(yesterdayEntry.getTimeAgo('pt_BR'), equals('ontem'));
      expect(yesterdayEntry.getTimeAgo('en_US'), equals('yesterday'));

      expect(oldEntry.getTimeAgo('pt_BR'), equals('3 dias atrás'));
      expect(oldEntry.getTimeAgo('en_US'), equals('3 days ago'));
    });
  });
}
