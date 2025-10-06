import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../lib/models/chat_message_model.dart';
import '../lib/models/activity_model.dart';
import '../lib/features/goals/models/goal_model.dart';
import '../lib/features/journal/models/journal_entry_model.dart';

Future<void> main() async {
  print('🔍 Querying recent chat messages...');

  try {
    // Get documents directory (same as app uses)
    final dir = await getApplicationDocumentsDirectory();
    print('📁 Database directory: ${dir.path}');

    // Open Isar database with same schema as app
    final isar = await Isar.open(
      [
        ChatMessageModelSchema,
        ActivityModelSchema,
        GoalModelSchema,
        JournalEntryModelSchema
      ],
      directory: dir.path,
    );

    print('✅ Database opened successfully');

    // Get last 10 messages
    final messages = await isar.chatMessageModels
        .where()
        .sortByTimestampDesc()
        .limit(10)
        .findAll();

    print('\n📝 Last 10 messages:');
    print('=' * 50);

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final speaker = msg.isUser ? 'USER' : 'ASSISTANT';
      final timestamp = msg.timestamp.toString().substring(0, 19);

      print('${i + 1}. [$timestamp] $speaker:');
      print('   "${msg.text}"');
      print('');
    }

    // Also check goals
    print('\n🎯 Current goals:');
    print('=' * 30);

    final goals = await isar.goalModels.where().findAll();
    for (final goal in goals) {
      print(
          'Goal ID ${goal.id}: ${goal.objectiveCode} - ${goal.objectiveName}');
      print('  Created: ${goal.createdAt}');
      print('  Active: ${goal.isActive}');
      print('');
    }

    await isar.close();
    print('✅ Database closed');
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}
