#!/usr/bin/env dart

import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../lib/models/goal_model.dart';
import '../lib/models/chat_message_model.dart';
import '../lib/models/activity_model.dart';
import '../lib/features/journal/models/journal_entry_model.dart';

/// Simple script to check if there are any goals in the database
Future<void> main() async {
  try {
    print('🔍 Checking for goals in the database...');

    // Get the app documents directory (same as the app uses)
    final dir = await getApplicationDocumentsDirectory();
    print('📁 Database directory: ${dir.path}');

    // Open the same database the app uses
    final isar = await Isar.open(
      [
        ChatMessageModelSchema,
        ActivityModelSchema,
        GoalModelSchema,
        JournalEntryModelSchema
      ],
      directory: dir.path,
    );

    // Count total goals
    final totalGoals = await isar.goalModels.count();
    print('📊 Total goals in database: $totalGoals');

    if (totalGoals > 0) {
      // Get all goals
      final goals = await isar.goalModels.where().findAll();
      print('🎯 Found goals:');
      for (final goal in goals) {
        print('  - ID: ${goal.id}');
        print('    Code: ${goal.objectiveCode}');
        print('    Name: ${goal.objectiveName}');
        print('    Active: ${goal.isActive}');
        print('    Created: ${goal.createdAt}');
        print('');
      }
    } else {
      print('❌ No goals found in database');

      // Let's also check what other data exists
      final messageCount = await isar.chatMessageModels.count();
      final activityCount = await isar.activityModels.count();
      final journalCount = await isar.journalEntryModels.count();

      print('📊 Other data in database:');
      print('  - Messages: $messageCount');
      print('  - Activities: $activityCount');
      print('  - Journal entries: $journalCount');
    }

    await isar.close();
    print('✅ Database check complete');
  } catch (e) {
    print('❌ Error checking database: $e');
    exit(1);
  }
}
