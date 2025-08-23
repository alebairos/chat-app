#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

/// Standalone script to restore chat messages
/// This bypasses Flutter SDK issues by generating restoration code
/// that can be executed within the Flutter app context
Future<void> main(List<String> args) async {
  print('🔧 Chat Restoration Script');
  print('========================');
  
  // Check if restoration data exists
  final dataFile = File('docs/exports/restoration_data.json');
  if (!await dataFile.exists()) {
    print('❌ Error: restoration_data.json not found');
    print('   Expected location: docs/exports/restoration_data.json');
    print('   Run the parsing script first to generate this file.');
    exit(1);
  }
  
  // Parse the restoration data
  final jsonString = await dataFile.readAsString();
  final data = json.decode(jsonString) as Map<String, dynamic>;
  final messages = data['messages'] as List<dynamic>;
  
  print('📊 Found ${messages.length} messages to restore');
  
  // Generate Flutter-compatible restoration code
  final codeFile = File('scripts/generated_restore_code.dart');
  final buffer = StringBuffer();
  
  buffer.writeln('// Generated restoration code - copy this into your Flutter app');
  buffer.writeln('// Usage: Call this method from anywhere in your app');
  buffer.writeln('');
  buffer.writeln('import \'package:isar/isar.dart\';');
  buffer.writeln('import \'../models/chat_message_model.dart\';');
  buffer.writeln('import \'../models/message_type.dart\';');
  buffer.writeln('import \'../services/chat_storage_service.dart\';');
  buffer.writeln('');
  buffer.writeln('Future<void> executeRestoration() async {');
  buffer.writeln('  print(\'🔄 Starting chat restoration...\');');
  buffer.writeln('  ');
  buffer.writeln('  final storage = ChatStorageService();');
  buffer.writeln('  final isar = await storage.db;');
  buffer.writeln('  ');
  buffer.writeln('  // Verify activities exist before clearing messages');
  buffer.writeln('  final activityCount = await isar.activityModels.count();');
  buffer.writeln('  print(\'📊 Current activities: \$activityCount\');');
  buffer.writeln('  ');
  buffer.writeln('  // Clear existing messages only');
  buffer.writeln('  await isar.writeTxn(() async {');
  buffer.writeln('    await isar.chatMessageModels.clear();');
  buffer.writeln('  });');
  buffer.writeln('  print(\'🗑️ Cleared existing messages\');');
  buffer.writeln('  ');
  buffer.writeln('  // Create restoration messages');
  buffer.writeln('  final messages = <ChatMessageModel>[');
  
  // Generate message objects
  for (int i = 0; i < messages.length; i++) {
    final msg = messages[i] as Map<String, dynamic>;
    
    buffer.writeln('    ChatMessageModel(');
    buffer.writeln('      text: ${_dartStringLiteral(msg['text'] as String)},');
    buffer.writeln('      isUser: ${msg['isUser']},');
    buffer.writeln('      type: MessageType.${msg['type'] == 'audio' ? 'audio' : 'text'},');
    buffer.writeln('      timestamp: DateTime.parse(\'${msg['timestamp']}\'),');
    
    if (msg['mediaPath'] != null) {
      buffer.writeln('      mediaPath: ${_dartStringLiteral(msg['mediaPath'] as String)},');
    }
    
    if (msg['personaKey'] != null) {
      buffer.writeln('      personaKey: ${_dartStringLiteral(msg['personaKey'] as String)},');
    }
    
    if (msg['personaDisplayName'] != null) {
      buffer.writeln('      personaDisplayName: ${_dartStringLiteral(msg['personaDisplayName'] as String)},');
    }
    
    buffer.writeln('    )${i < messages.length - 1 ? ',' : ''}');
  }
  
  buffer.writeln('  ];');
  buffer.writeln('  ');
  buffer.writeln('  // Insert in batches');
  buffer.writeln('  const batchSize = 50;');
  buffer.writeln('  for (int i = 0; i < messages.length; i += batchSize) {');
  buffer.writeln('    final batch = messages.skip(i).take(batchSize).toList();');
  buffer.writeln('    await isar.writeTxn(() async {');
  buffer.writeln('      await isar.chatMessageModels.putAll(batch);');
  buffer.writeln('    });');
  buffer.writeln('    print(\'💾 Batch \${(i ~/ batchSize) + 1}/\${(messages.length / batchSize).ceil()}\');');
  buffer.writeln('  }');
  buffer.writeln('  ');
  buffer.writeln('  // Verify restoration');
  buffer.writeln('  final finalMessageCount = await isar.chatMessageModels.count();');
  buffer.writeln('  final finalActivityCount = await isar.activityModels.count();');
  buffer.writeln('  ');
  buffer.writeln('  print(\'✅ Restoration complete!\');');
  buffer.writeln('  print(\'📊 Messages: \$finalMessageCount\');');
  buffer.writeln('  print(\'🎯 Activities: \$finalActivityCount\');');
  buffer.writeln('  ');
  buffer.writeln('  if (finalActivityCount != activityCount) {');
  buffer.writeln('    print(\'⚠️ WARNING: Activity count changed!\');');
  buffer.writeln('  }');
  buffer.writeln('}');
  
  // Write the generated code
  await codeFile.writeAsString(buffer.toString());
  
  print('✅ Generated restoration code: ${codeFile.path}');
  print('');
  print('📋 Next Steps:');
  print('1. Copy the generated code from: scripts/generated_restore_code.dart');
  print('2. Add it to a new method in your Flutter app');
  print('3. Call executeRestoration() from anywhere in your app');
  print('4. Or add a button in your UI to trigger it');
  print('');
  print('💡 Example usage in your app:');
  print('   ElevatedButton(');
  print('     onPressed: () async {');
  print('       await executeRestoration();');
  print('       ScaffoldMessenger.of(context).showSnackBar(');
  print('         SnackBar(content: Text(\'Chat restored!\')),');
  print('       );');
  print('     },');
  print('     child: Text(\'Restore Chat\'),');
  print('   )');
}

/// Converts a string to a Dart string literal with proper escaping
String _dartStringLiteral(String value) {
  return '\'${value.replaceAll('\'', '\\\'').replaceAll('\n', '\\n').replaceAll('\r', '\\r')}\'';
}
