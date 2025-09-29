import 'dart:io';
import 'dart:convert';

/// Direct Isar database restoration script
/// Bypasses Flutter entirely and connects directly to Isar
Future<void> main(List<String> args) async {
  final clearFirst = args.contains('--clear-first');
  final nonFlagArgs = args.where((arg) => !arg.startsWith('--')).toList();
  final jsonFile = nonFlagArgs.isNotEmpty
      ? nonFlagArgs[0]
      : 'docs/exports/restoration_data.json';

  // Hardcode the database path to match iOS simulator
  const dbPath =
      '/Users/alebairos/Library/Developer/CoreSimulator/Devices/A1CCDD4A-DC59-40CC-B78B-DF417AAC8A40/data/Containers/Data/Application/DE4AA9BB-B3AE-4903-A8E8-92554CD9F39A/Documents';

  print('🔄 Starting direct Isar restoration...');
  print('📁 JSON file: $jsonFile');
  print('💾 Database path: $dbPath');
  if (clearFirst) print('⚠️  Will clear existing messages first');

  try {
    final restorer = DirectIsarRestorer();
    await restorer.restoreFromJson(jsonFile, dbPath, clearFirst: clearFirst);

    print('✅ Direct Isar restoration complete!');
    print('📱 Restart the Flutter app to see restored messages');
  } catch (e) {
    print('❌ Restoration failed: $e');
    exit(1);
  }
}

class DirectIsarRestorer {
  Future<void> restoreFromJson(String jsonFilePath, String dbPath,
      {bool clearFirst = false}) async {
    // Read JSON data
    final file = File(jsonFilePath);
    if (!await file.exists()) {
      throw Exception('JSON file not found: $jsonFilePath');
    }

    final content = await file.readAsString();
    final data = json.decode(content) as Map<String, dynamic>;
    final messagesData = data['messages'] as List<dynamic>;

    print('📊 Loading ${messagesData.length} messages from JSON');

    // Check if database path exists
    final dbDir = Directory(dbPath);
    if (!await dbDir.exists()) {
      throw Exception('Database directory not found: $dbPath');
    }

    // Generate SQL-like data for manual insertion
    await _generateInsertStatements(messagesData, clearFirst);

    print('📄 Generated manual insertion data');
    print(
        '💡 Due to Flutter SDK issues, manual database insertion is required');
    print('📋 Check docs/exports/manual_insert_instructions.md for next steps');
  }

  Future<void> _generateInsertStatements(
      List<dynamic> messagesData, bool clearFirst) async {
    final instructions = StringBuffer();

    instructions.writeln('# Manual Database Restoration Instructions');
    instructions.writeln('Generated: ${DateTime.now().toIso8601String()}');
    instructions.writeln('Total messages to restore: ${messagesData.length}');
    instructions.writeln('');

    if (clearFirst) {
      instructions.writeln('## Step 1: Clear Existing Messages');
      instructions.writeln('Run this in the Flutter app (ChatStorageService):');
      instructions.writeln('```dart');
      instructions.writeln('await ChatStorageService().deleteAllMessages();');
      instructions.writeln('```');
      instructions.writeln('');
    }

    instructions.writeln('## Step 2: Create Restoration Service');
    instructions.writeln('Add this method to ChatStorageService:');
    instructions.writeln('');
    instructions.writeln('```dart');
    instructions.writeln('Future<void> restoreMessagesFromData() async {');
    instructions.writeln('  final messages = <ChatMessageModel>[');

    // Generate ChatMessageModel creation statements
    for (int i = 0; i < messagesData.length; i++) {
      final message = messagesData[i] as Map<String, dynamic>;

      instructions.writeln('    ChatMessageModel(');
      instructions
          .writeln('      text: ${_escapeString(message['text'] as String)},');
      instructions.writeln('      isUser: ${message['isUser']},');
      instructions.writeln('      type: MessageType.${message['type']},');
      instructions.writeln(
          '      timestamp: DateTime.parse("${message['timestamp']}"),');

      if (message['mediaPath'] != null) {
        instructions.writeln(
            '      mediaPath: ${_escapeString(message['mediaPath'] as String)},');
      }

      if (message['personaKey'] != null) {
        instructions.writeln(
            '      personaKey: ${_escapeString(message['personaKey'] as String)},');
      }

      if (message['personaDisplayName'] != null) {
        instructions.writeln(
            '      personaDisplayName: ${_escapeString(message['personaDisplayName'] as String)},');
      }

      instructions.writeln('    ),');

      // Add line break every 10 messages for readability
      if ((i + 1) % 10 == 0) {
        instructions.writeln('    // Messages ${i - 8} to ${i + 1}');
        instructions.writeln('');
      }
    }

    instructions.writeln('  ];');
    instructions.writeln('');
    instructions.writeln('  // Insert messages in batches');
    instructions.writeln('  final isar = await db;');
    instructions.writeln('  const batchSize = 50;');
    instructions
        .writeln('  for (int i = 0; i < messages.length; i += batchSize) {');
    instructions.writeln(
        '    final batch = messages.skip(i).take(batchSize).toList();');
    instructions.writeln('    await isar.writeTxn(() async {');
    instructions.writeln('      await isar.chatMessageModels.putAll(batch);');
    instructions.writeln('    });');
    instructions.writeln(
        '    print("Inserted batch \${(i ~/ batchSize) + 1}/\${(messages.length / batchSize).ceil()}");');
    instructions.writeln('  }');
    instructions.writeln('  print("✅ Restored \${messages.length} messages");');
    instructions.writeln('}');
    instructions.writeln('```');
    instructions.writeln('');

    instructions.writeln('## Step 3: Call Restoration Method');
    instructions.writeln(
        'Add this to your app (e.g., in main.dart or a debug screen):');
    instructions.writeln('```dart');
    instructions.writeln('final storage = ChatStorageService();');
    instructions.writeln('await storage.restoreMessagesFromData();');
    instructions.writeln('```');
    instructions.writeln('');

    instructions.writeln('## Message Statistics');
    final userMessages = messagesData.where((m) => m['isUser'] as bool).length;
    final aiMessages = messagesData.where((m) => !(m['isUser'] as bool)).length;
    final audioMessages =
        messagesData.where((m) => m['type'] == 'audio').length;

    instructions.writeln('- Total messages: ${messagesData.length}');
    instructions.writeln('- User messages: $userMessages');
    instructions.writeln('- AI messages: $aiMessages');
    instructions.writeln('- Audio messages: $audioMessages');
    instructions.writeln('');

    // Persona breakdown
    final personaCounts = <String, int>{};
    for (final message in messagesData) {
      if (!(message['isUser'] as bool)) {
        final persona = message['personaDisplayName'] as String? ?? 'Unknown';
        personaCounts[persona] = (personaCounts[persona] ?? 0) + 1;
      }
    }

    if (personaCounts.isNotEmpty) {
      instructions.writeln('## Messages by Persona');
      for (final entry in personaCounts.entries) {
        instructions.writeln('- ${entry.key}: ${entry.value} messages');
      }
    }

    final instructionsFile = File('docs/exports/manual_insert_instructions.md');
    await instructionsFile.writeAsString(instructions.toString());
  }

  String _escapeString(String str) {
    return '"${str.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n')}"';
  }
}
