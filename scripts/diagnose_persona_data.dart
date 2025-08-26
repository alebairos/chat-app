import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../lib/models/chat_message_model.dart';
import '../lib/models/message_type.dart';

Future<void> main() async {
  print('🔍 Diagnosing persona data in chat messages...\n');

  try {
    // Get the application documents directory
    final dir = await getApplicationDocumentsDirectory();

    // Open the database
    final isar = await Isar.open(
      [ChatMessageModelSchema],
      directory: dir.path,
    );

    // Get all messages
    final allMessages = await isar.chatMessageModels.where().findAll();
    print('📊 Total messages found: ${allMessages.length}\n');

    if (allMessages.isEmpty) {
      print('❌ No messages found in database');
      await isar.close();
      return;
    }

    // Analyze persona data
    int userMessages = 0;
    int aiMessages = 0;
    int aiWithPersona = 0;
    int aiWithoutPersona = 0;

    final personaCounts = <String, int>{};
    final recentMessages = <ChatMessageModel>[];

    for (final message in allMessages) {
      if (message.isUser) {
        userMessages++;
      } else {
        aiMessages++;

        if (message.personaDisplayName != null &&
            message.personaDisplayName!.isNotEmpty &&
            message.personaDisplayName != 'unknown') {
          aiWithPersona++;
          final persona = message.personaDisplayName!;
          personaCounts[persona] = (personaCounts[persona] ?? 0) + 1;
        } else {
          aiWithoutPersona++;
        }
      }

      // Collect recent messages for detailed inspection
      if (recentMessages.length < 10) {
        recentMessages.add(message);
      }
    }

    // Sort recent messages by timestamp (most recent first)
    recentMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    print('📈 Summary:');
    print('  👤 User messages: $userMessages');
    print('  🤖 AI messages: $aiMessages');
    print('  ✅ AI with persona data: $aiWithPersona');
    print('  ❌ AI without persona data: $aiWithoutPersona');
    print('');

    if (personaCounts.isNotEmpty) {
      print('👥 Persona distribution:');
      personaCounts.forEach((persona, count) {
        print('  • $persona: $count messages');
      });
      print('');
    }

    print('🔍 Recent messages (most recent first):');
    for (int i = 0; i < recentMessages.length && i < 10; i++) {
      final msg = recentMessages[i];
      final timestamp =
          msg.timestamp.toString().substring(0, 19); // Remove microseconds
      final sender =
          msg.isUser ? 'User' : (msg.personaDisplayName ?? 'AI (no persona)');
      final preview =
          msg.text.length > 50 ? '${msg.text.substring(0, 50)}...' : msg.text;

      print('  ${i + 1}. [$timestamp] $sender: $preview');
      if (!msg.isUser) {
        print('     personaKey: ${msg.personaKey ?? "null"}');
        print('     personaDisplayName: ${msg.personaDisplayName ?? "null"}');
      }
      print('');
    }

    // Check if ConfigLoader is accessible for current persona
    print('🎯 Diagnosis:');
    if (aiWithoutPersona > 0) {
      print('  ⚠️  Found $aiWithoutPersona AI messages without persona data');
      print(
          '     This could be the reason personas aren\'t showing in exports');
    }

    if (aiWithPersona > 0) {
      print('  ✅ Found $aiWithPersona AI messages WITH persona data');
      print('     Export should work for these messages');
    }

    await isar.close();
  } catch (e) {
    print('❌ Error diagnosing database: $e');
    exit(1);
  }
}
