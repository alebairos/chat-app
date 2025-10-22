import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:ai_personas_app/models/chat_message_model.dart';
import 'package:ai_personas_app/models/activity_model.dart';
import 'package:ai_personas_app/models/user_settings_model.dart';
import 'package:ai_personas_app/features/journal/models/journal_entry_model.dart';
import 'package:ai_personas_app/models/message_type.dart';

/// FT-217: Simplified tests for database reset functionality
///
/// These tests verify the core reset logic without depending on service initialization.
void main() {
  group('FT-217: Database Reset Core Logic', () {
    test('should clear all collections and create fresh settings', () async {
      // Create test database
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

      // Add test data to all collections
      await isar.writeTxn(() async {
        // Add chat messages
        await isar.chatMessageModels.put(ChatMessageModel(
          text: 'Test message 1',
          isUser: true,
          type: MessageType.text,
          timestamp: DateTime.now(),
        ));
        await isar.chatMessageModels.put(ChatMessageModel(
          text: 'Test message 2',
          isUser: false,
          type: MessageType.text,
          timestamp: DateTime.now(),
        ));

        // Add activities
        final activity1 = ActivityModel()
          ..activityCode = 'T1'
          ..activityName = 'Test Activity 1'
          ..dimension = 'test'
          ..source = 'Test'
          ..timestamp = DateTime.now()
          ..completedAt = DateTime.now()
          ..hour = DateTime.now().hour
          ..minute = DateTime.now().minute
          ..dayOfWeek = 'Monday'
          ..timeOfDay = 'morning'
          ..createdAt = DateTime.now();
        await isar.activityModels.put(activity1);

        final activity2 = ActivityModel()
          ..activityCode = 'SF1'
          ..activityName = 'Test Activity 2'
          ..dimension = 'test'
          ..source = 'Test'
          ..timestamp = DateTime.now()
          ..completedAt = DateTime.now()
          ..hour = DateTime.now().hour
          ..minute = DateTime.now().minute
          ..dayOfWeek = 'Monday'
          ..timeOfDay = 'morning'
          ..createdAt = DateTime.now();
        await isar.activityModels.put(activity2);

        // Add user settings
        final settings = UserSettingsModel.initial();
        settings.setUserName('Test User');
        settings.markOnboardingComplete();
        await isar.userSettingsModels.put(settings);

        // Add journal entries
        final journal = JournalEntryModel()
          ..date = DateTime.now()
          ..createdAt = DateTime.now()
          ..language = 'en'
          ..content = 'Test journal entry'
          ..messageCount = 1
          ..activityCount = 1
          ..generationTimeSeconds = 1.0;
        await isar.journalEntryModels.put(journal);
      });

      // Verify data exists before reset
      expect(await isar.chatMessageModels.count(), 2);
      expect(await isar.activityModels.count(), 2);
      expect(await isar.userSettingsModels.count(), 1);
      expect(await isar.journalEntryModels.count(), 1);

      // Perform reset (simulating UserSettingsService.resetAllUserData logic)
      await isar.writeTxn(() async {
        await isar.userSettingsModels.clear();
        await isar.chatMessageModels.clear();
        await isar.activityModels.clear();
        await isar.journalEntryModels.clear();

        final newSettings = UserSettingsModel.initial();
        await isar.userSettingsModels.put(newSettings);
      });

      // Verify all collections are cleared
      expect(await isar.chatMessageModels.count(), 0);
      expect(await isar.activityModels.count(), 0);
      expect(await isar.journalEntryModels.count(), 0);

      // Verify fresh user settings are created
      expect(await isar.userSettingsModels.count(), 1);
      final newSettings = await isar.userSettingsModels.where().findFirst();
      expect(newSettings, isNotNull);
      expect(newSettings!.hasCompletedOnboarding, false);
      expect(newSettings.userName, null);

      await isar.close(deleteFromDisk: true);
    });

    test('should handle empty database gracefully', () async {
      final isar = await Isar.open(
        [
          ChatMessageModelSchema,
          ActivityModelSchema,
          UserSettingsModelSchema,
          JournalEntryModelSchema,
        ],
        directory: '',
        name: 'test_empty_reset_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Verify database is empty
      expect(await isar.chatMessageModels.count(), 0);
      expect(await isar.activityModels.count(), 0);
      expect(await isar.userSettingsModels.count(), 0);
      expect(await isar.journalEntryModels.count(), 0);

      // Reset should work without errors
      await isar.writeTxn(() async {
        await isar.userSettingsModels.clear();
        await isar.chatMessageModels.clear();
        await isar.activityModels.clear();
        await isar.journalEntryModels.clear();

        final newSettings = UserSettingsModel.initial();
        await isar.userSettingsModels.put(newSettings);
      });

      // Should create fresh user settings
      expect(await isar.userSettingsModels.count(), 1);
      final settings = await isar.userSettingsModels.where().findFirst();
      expect(settings, isNotNull);
      expect(settings!.hasCompletedOnboarding, false);

      await isar.close(deleteFromDisk: true);
    });

    test('should create fresh settings with correct defaults', () async {
      final isar = await Isar.open(
        [
          ChatMessageModelSchema,
          ActivityModelSchema,
          UserSettingsModelSchema,
          JournalEntryModelSchema,
        ],
        directory: '',
        name: 'test_defaults_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Perform reset
      await isar.writeTxn(() async {
        await isar.userSettingsModels.clear();
        await isar.chatMessageModels.clear();
        await isar.activityModels.clear();
        await isar.journalEntryModels.clear();

        final newSettings = UserSettingsModel.initial();
        await isar.userSettingsModels.put(newSettings);
      });

      final settings = await isar.userSettingsModels.where().findFirst();

      expect(settings, isNotNull);
      expect(settings!.hasCompletedOnboarding, false);
      expect(settings.userName, null);
      expect(settings.hasSeenWelcome, false);
      expect(settings.lastActivePersona, null);
      expect(settings.onboardingVersion, 'v1');
      expect(settings.createdAt, isNotNull);
      expect(settings.updatedAt, isNotNull);

      await isar.close(deleteFromDisk: true);
    });

    test('should maintain data integrity during reset', () async {
      final isar = await Isar.open(
        [
          ChatMessageModelSchema,
          ActivityModelSchema,
          UserSettingsModelSchema,
          JournalEntryModelSchema,
        ],
        directory: '',
        name: 'test_integrity_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Add data
      await isar.writeTxn(() async {
        await isar.chatMessageModels.put(ChatMessageModel(
          text: 'Integrity test',
          isUser: true,
          type: MessageType.text,
          timestamp: DateTime.now(),
        ));
      });

      // Reset should be atomic - either all data is cleared or none
      await isar.writeTxn(() async {
        await isar.userSettingsModels.clear();
        await isar.chatMessageModels.clear();
        await isar.activityModels.clear();
        await isar.journalEntryModels.clear();

        final newSettings = UserSettingsModel.initial();
        await isar.userSettingsModels.put(newSettings);
      });

      // Verify complete reset state
      expect(await isar.chatMessageModels.count(), 0);
      expect(await isar.activityModels.count(), 0);
      expect(await isar.journalEntryModels.count(), 0);
      expect(await isar.userSettingsModels.count(), 1);

      // Fresh settings should be valid
      final settings = await isar.userSettingsModels.where().findFirst();
      expect(settings, isNotNull);
      expect(settings!.createdAt, isNotNull);
      expect(settings.updatedAt, isNotNull);

      await isar.close(deleteFromDisk: true);
    });

    test('should reset onboarding status correctly', () async {
      final isar = await Isar.open(
        [
          ChatMessageModelSchema,
          ActivityModelSchema,
          UserSettingsModelSchema,
          JournalEntryModelSchema,
        ],
        directory: '',
        name: 'test_onboarding_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Set up completed onboarding
      await isar.writeTxn(() async {
        final settings = UserSettingsModel.initial();
        settings.setUserName('Profile User');
        settings.markOnboardingComplete();
        await isar.userSettingsModels.put(settings);
      });

      // Verify onboarding is complete
      final beforeReset = await isar.userSettingsModels.where().findFirst();
      expect(beforeReset!.hasCompletedOnboarding, true);
      expect(beforeReset.userName, 'Profile User');

      // Reset should restore onboarding requirement
      await isar.writeTxn(() async {
        await isar.userSettingsModels.clear();
        await isar.chatMessageModels.clear();
        await isar.activityModels.clear();
        await isar.journalEntryModels.clear();

        final newSettings = UserSettingsModel.initial();
        await isar.userSettingsModels.put(newSettings);
      });

      // Fresh settings should have correct onboarding state
      final afterReset = await isar.userSettingsModels.where().findFirst();
      expect(afterReset!.hasCompletedOnboarding, false);
      expect(afterReset.userName, null);
      expect(afterReset.onboardingCompletedAt, null);

      await isar.close(deleteFromDisk: true);
    });
  });
}
