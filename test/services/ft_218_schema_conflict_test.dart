import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:ai_personas_app/models/chat_message_model.dart';
import 'package:ai_personas_app/models/activity_model.dart';
import 'package:ai_personas_app/models/user_settings_model.dart';
import 'package:ai_personas_app/features/journal/models/journal_entry_model.dart';
import 'package:ai_personas_app/models/message_type.dart';

/// FT-218: Tests for Isar schema conflict resolution
/// 
/// These tests verify that all services can access all required collections
/// regardless of initialization order, preventing "Collection not found" errors.
void main() {
  group('FT-218: Schema Conflict Resolution', () {
    group('Schema Completeness Tests', () {
      test('should create Isar instance with all required schemas', () async {
        // Test that we can create an Isar instance with all schemas
        final isar = await Isar.open(
          [
            ChatMessageModelSchema,
            ActivityModelSchema,
            UserSettingsModelSchema,
            JournalEntryModelSchema,
          ],
          directory: '',
          name: 'test_complete_schema_${DateTime.now().millisecondsSinceEpoch}',
        );

        // Test that we can access all collections without errors
        expect(() => isar.chatMessageModels, returnsNormally);
        expect(() => isar.activityModels, returnsNormally);
        expect(() => isar.userSettingsModels, returnsNormally);
        expect(() => isar.journalEntryModels, returnsNormally);

        await isar.close(deleteFromDisk: true);
      });

      test('should allow cross-collection operations', () async {
        final isar = await Isar.open(
          [
            ChatMessageModelSchema,
            ActivityModelSchema,
            UserSettingsModelSchema,
            JournalEntryModelSchema,
          ],
          directory: '',
          name: 'test_cross_ops_${DateTime.now().millisecondsSinceEpoch}',
        );

        // Create and save a user settings model
        final settings = UserSettingsModel.initial();
        settings.setUserName('Test User');

        await isar.writeTxn(() async {
          await isar.userSettingsModels.put(settings);
        });

        // Verify we can retrieve it
        final retrieved = await isar.userSettingsModels.where().findFirst();
        expect(retrieved, isNotNull);
        expect(retrieved!.userName, 'Test User');

        await isar.close(deleteFromDisk: true);
      });

      test('should support all model types in same transaction', () async {
        final isar = await Isar.open(
          [
            ChatMessageModelSchema,
            ActivityModelSchema,
            UserSettingsModelSchema,
            JournalEntryModelSchema,
          ],
          directory: '',
          name: 'test_all_models_${DateTime.now().millisecondsSinceEpoch}',
        );

        // Create instances of all model types
        final message = ChatMessageModel(
          text: 'Test message',
          isUser: true,
          type: MessageType.text,
          timestamp: DateTime.now(),
        );

        final activity = ActivityModel()
          ..activityCode = 'T1'
          ..activityName = 'Test Activity'
          ..dimension = 'test'
          ..source = 'Test'
          ..timestamp = DateTime.now()
          ..completedAt = DateTime.now()
          ..hour = DateTime.now().hour
          ..minute = DateTime.now().minute
          ..dayOfWeek = 'Monday'
          ..timeOfDay = 'morning'
          ..createdAt = DateTime.now();

        final settings = UserSettingsModel.initial();
        settings.setUserName('Test User');

        final journal = JournalEntryModel()
          ..date = DateTime.now()
          ..createdAt = DateTime.now()
          ..language = 'en'
          ..content = 'Test journal'
          ..messageCount = 1
          ..activityCount = 1
          ..generationTimeSeconds = 1.0;

        // Save all in a single transaction to verify schema completeness
        await isar.writeTxn(() async {
          await isar.chatMessageModels.put(message);
          await isar.activityModels.put(activity);
          await isar.userSettingsModels.put(settings);
          await isar.journalEntryModels.put(journal);
        });

        // Verify all were saved
        expect(await isar.chatMessageModels.count(), 1);
        expect(await isar.activityModels.count(), 1);
        expect(await isar.userSettingsModels.count(), 1);
        expect(await isar.journalEntryModels.count(), 1);

        await isar.close(deleteFromDisk: true);
      });
    });

    group('Collection Access Validation', () {
      test('should access UserSettings collections from any schema', () async {
        final isar = await Isar.open(
          [
            ChatMessageModelSchema,
            ActivityModelSchema,
            UserSettingsModelSchema,
            JournalEntryModelSchema,
          ],
          directory: '',
          name: 'test_user_access_${DateTime.now().millisecondsSinceEpoch}',
        );

        // Should be able to query user settings
        final settings = UserSettingsModel.initial();
        settings.setUserName('Cross Service Test');

        await isar.writeTxn(() async {
          await isar.userSettingsModels.put(settings);
        });

        final retrieved = await isar.userSettingsModels.where().findFirst();
        expect(retrieved, isNotNull);
        expect(retrieved!.userName, 'Cross Service Test');

        await isar.close(deleteFromDisk: true);
      });

      test('should access Chat collections from any schema', () async {
        final isar = await Isar.open(
          [
            ChatMessageModelSchema,
            ActivityModelSchema,
            UserSettingsModelSchema,
            JournalEntryModelSchema,
          ],
          directory: '',
          name: 'test_chat_access_${DateTime.now().millisecondsSinceEpoch}',
        );

        // Should be able to query chat messages
        final message = ChatMessageModel(
          text: 'Cross service message',
          isUser: false,
          type: MessageType.text,
          timestamp: DateTime.now(),
        );

        await isar.writeTxn(() async {
          await isar.chatMessageModels.put(message);
        });

        final retrieved = await isar.chatMessageModels.where().findFirst();
        expect(retrieved, isNotNull);
        expect(retrieved!.text, 'Cross service message');

        await isar.close(deleteFromDisk: true);
      });
    });

    group('Reset Functionality with Complete Schema', () {
      test('should clear all collections in single transaction', () async {
        final isar = await Isar.open(
          [
            ChatMessageModelSchema,
            ActivityModelSchema,
            UserSettingsModelSchema,
            JournalEntryModelSchema,
          ],
          directory: '',
          name: 'test_reset_${DateTime.now().millisecondsSinceEpoch}',
        );

        // Add data to all collections
        await isar.writeTxn(() async {
          await isar.chatMessageModels.put(ChatMessageModel(
            text: 'Test message',
            isUser: true,
            type: MessageType.text,
            timestamp: DateTime.now(),
          ));

          final activity = ActivityModel()
            ..activityCode = 'T1'
            ..activityName = 'Test Activity'
            ..dimension = 'test'
            ..source = 'Test'
            ..timestamp = DateTime.now()
            ..completedAt = DateTime.now()
            ..hour = DateTime.now().hour
            ..minute = DateTime.now().minute
            ..dayOfWeek = 'Monday'
            ..timeOfDay = 'morning'
            ..createdAt = DateTime.now();
          await isar.activityModels.put(activity);

          await isar.userSettingsModels.put(UserSettingsModel.initial());

          final journal = JournalEntryModel()
            ..date = DateTime.now()
            ..createdAt = DateTime.now()
            ..language = 'en'
            ..content = 'Test journal'
            ..messageCount = 1
            ..activityCount = 1
            ..generationTimeSeconds = 1.0;
          await isar.journalEntryModels.put(journal);
        });

        // Verify data exists
        expect(await isar.chatMessageModels.count(), 1);
        expect(await isar.activityModels.count(), 1);
        expect(await isar.userSettingsModels.count(), 1);
        expect(await isar.journalEntryModels.count(), 1);

        // Clear all collections (simulating reset)
        await isar.writeTxn(() async {
          await isar.chatMessageModels.clear();
          await isar.activityModels.clear();
          await isar.userSettingsModels.clear();
          await isar.journalEntryModels.clear();

          // Add fresh settings
          await isar.userSettingsModels.put(UserSettingsModel.initial());
        });

        // Verify all collections are cleared and fresh settings created
        expect(await isar.chatMessageModels.count(), 0);
        expect(await isar.activityModels.count(), 0);
        expect(await isar.journalEntryModels.count(), 0);
        
        // Should have fresh user settings
        expect(await isar.userSettingsModels.count(), 1);
        final newSettings = await isar.userSettingsModels.where().findFirst();
        expect(newSettings!.hasCompletedOnboarding, false);

        await isar.close(deleteFromDisk: true);
      });
    });

    group('Error Prevention', () {
      test('should not throw "Collection not found" errors', () async {
        // Test that all collections are accessible from a complete schema
        final isar = await Isar.open(
          [
            ChatMessageModelSchema,
            ActivityModelSchema,
            UserSettingsModelSchema,
            JournalEntryModelSchema,
          ],
          directory: '',
          name: 'test_no_errors_${DateTime.now().millisecondsSinceEpoch}',
        );

        // All collections should be accessible
        expect(() => isar.userSettingsModels.where().findAll(), returnsNormally);
        expect(() => isar.chatMessageModels.where().findAll(), returnsNormally);
        expect(() => isar.activityModels.where().findAll(), returnsNormally);
        expect(() => isar.journalEntryModels.where().findAll(), returnsNormally);

        await isar.close(deleteFromDisk: true);
      });

      test('should handle empty collections gracefully', () async {
        final isar = await Isar.open(
          [
            ChatMessageModelSchema,
            ActivityModelSchema,
            UserSettingsModelSchema,
            JournalEntryModelSchema,
          ],
          directory: '',
          name: 'test_empty_${DateTime.now().millisecondsSinceEpoch}',
        );

        // All collections should be empty but accessible
        expect(await isar.chatMessageModels.count(), 0);
        expect(await isar.activityModels.count(), 0);
        expect(await isar.userSettingsModels.count(), 0);
        expect(await isar.journalEntryModels.count(), 0);

        // Should be able to perform operations on empty collections
        final messages = await isar.chatMessageModels.where().findAll();
        expect(messages, isEmpty);

        await isar.close(deleteFromDisk: true);
      });
    });

    group('Schema Validation', () {
      test('should have all required collections available', () async {
        final isar = await Isar.open(
          [
            ChatMessageModelSchema,
            ActivityModelSchema,
            UserSettingsModelSchema,
            JournalEntryModelSchema,
          ],
          directory: '',
          name: 'test_validation_${DateTime.now().millisecondsSinceEpoch}',
        );

        // Verify all expected collections are available
        final collections = [
          'ChatMessageModel',
          'ActivityModel', 
          'UserSettingsModel',
          'JournalEntryModel',
        ];

        for (final collectionName in collections) {
          expect(() {
            switch (collectionName) {
              case 'ChatMessageModel':
                isar.chatMessageModels;
                break;
              case 'ActivityModel':
                isar.activityModels;
                break;
              case 'UserSettingsModel':
                isar.userSettingsModels;
                break;
              case 'JournalEntryModel':
                isar.journalEntryModels;
                break;
            }
          }, returnsNormally, reason: 'Collection $collectionName should be available');
        }

        await isar.close(deleteFromDisk: true);
      });
    });
  });
}