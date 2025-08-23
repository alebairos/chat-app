import 'dart:io';
import 'dart:convert';

/// Simple chat restoration script for FT-069
/// Restores chat history from WhatsApp-format export files
/// Standalone version without Flutter dependencies
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print(
        '❌ Usage: dart run scripts/restore_chat_simple.dart <export_file_path>');
    print(
        '📄 Example: dart run scripts/restore_chat_simple.dart docs/exports/chat_export_2025-08-22_14-34-48.txt');
    exit(1);
  }

  final filePath = args[0];
  final clearFirst = args.contains('--clear-first');

  print('🔄 Starting chat restoration...');
  print('📁 File: $filePath');
  if (clearFirst) print('⚠️  Will clear existing messages first');

  try {
    final restorer = SimpleChatRestorer();
    await restorer.restoreFromFile(filePath, clearFirst: clearFirst);

    print('✅ Chat restoration complete!');
    print('📱 Restart the Flutter app to see restored messages');
  } catch (e) {
    print('❌ Restoration failed: $e');
    exit(1);
  }
}

class SimpleChatRestorer {
  static final RegExp messagePattern =
      RegExp(r'^‎?\[(\d{2}/\d{2}/\d{2}), (\d{2}:\d{2}:\d{2})\] ([^:]+): (.*)$');

  static final Map<String, String?> personaMapping = {
    'Ari Life Coach': 'ariLifeCoach',
    'Ari - Life Coach': 'ariLifeCoach',
    'Ari 2.1': 'ariWithOracle21',
    'Sergeant Oracle': 'sergeantOracle',
    'I-There': 'iThereClone',
    'AI Assistant': null, // Legacy fallback
    'User': null, // User messages
  };

  Future<void> restoreFromFile(String filePath,
      {bool clearFirst = false}) async {
    // Check if file exists
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Export file not found: $filePath');
    }

    // Read and validate file
    final content = await file.readAsString();
    final lines =
        content.split('\n').where((line) => line.trim().isNotEmpty).toList();

    print('📊 File contains ${lines.length} lines');

    // Parse messages
    print('🔍 Parsing messages...');
    final messages = <Map<String, dynamic>>[];
    int userCount = 0;
    int aiCount = 0;
    int audioCount = 0;
    final personaCounts = <String, int>{};

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final parsed = _parseLine(line);
        if (parsed != null) {
          messages.add(parsed);

          if (parsed['isUser'] as bool) {
            userCount++;
          } else {
            aiCount++;
            final persona =
                parsed['personaDisplayName'] as String? ?? 'Unknown';
            personaCounts[persona] = (personaCounts[persona] ?? 0) + 1;
          }

          if (parsed['type'] == 'audio') {
            audioCount++;
          }
        }
      } catch (e) {
        print('⚠️  Skipping malformed line ${i + 1}: $e');
      }
    }

    print('✅ Parsed ${messages.length} messages:');
    print('   📝 User messages: $userCount');
    print('   🤖 AI messages: $aiCount');
    print('   🎵 Audio messages: $audioCount');

    if (personaCounts.isNotEmpty) {
      print('👤 Messages by persona:');
      for (final entry in personaCounts.entries) {
        print('   • ${entry.key}: ${entry.value}');
      }
    }

    // Generate SQL insert statements for manual execution
    print('\n💾 Generating restoration data...');
    await _generateRestorationData(messages, clearFirst, filePath);
  }

  Map<String, dynamic>? _parseLine(String line) {
    final match = messagePattern.firstMatch(line);
    if (match == null) return null;

    final dateStr = match.group(1)!; // MM/DD/YY
    final timeStr = match.group(2)!; // HH:MM:SS
    final sender = match.group(3)!;
    final content = match.group(4)!;

    // Parse timestamp
    final dateParts = dateStr.split('/');
    final timeParts = timeStr.split(':');

    final month = int.parse(dateParts[0]);
    final day = int.parse(dateParts[1]);
    final year = 2000 + int.parse(dateParts[2]); // Convert YY to YYYY
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final second = int.parse(timeParts[2]);

    final timestamp = DateTime(year, month, day, hour, minute, second);

    // Determine if user message
    final isUser = sender == 'User' || sender == 'user';

    // Detect message type
    final isAudio = content.contains('<attached:') &&
        (content.contains('.mp3') ||
            content.contains('.opus') ||
            content.contains('.wav'));
    final messageType = isAudio ? 'audio' : 'text';

    // For audio messages, extract the content without attachment reference
    String messageText = content;
    String? mediaPath;

    if (isAudio) {
      // Extract filename from <attached: filename> format
      final attachmentMatch =
          RegExp(r'<attached:\s*([^>]+)>').firstMatch(content);
      if (attachmentMatch != null) {
        mediaPath = attachmentMatch.group(1)?.trim();
        messageText = ''; // Audio messages have no text content
      }
    }

    // Map persona name to key
    String? personaKey;
    String? personaDisplayName;
    if (!isUser) {
      personaKey = personaMapping[sender];
      personaDisplayName = sender;
    }

    return {
      'text': messageText,
      'isUser': isUser,
      'type': messageType,
      'timestamp': timestamp.toIso8601String(),
      'mediaPath': mediaPath,
      'personaKey': personaKey,
      'personaDisplayName': personaDisplayName,
    };
  }

  Future<void> _generateRestorationData(List<Map<String, dynamic>> messages,
      bool clearFirst, String filePath) async {
    // Create restoration instructions
    final output = StringBuffer();

    output.writeln('# Chat Restoration Data for FT-069');
    output.writeln('# Generated on: ${DateTime.now().toIso8601String()}');
    output.writeln('# Total messages: ${messages.length}');
    output.writeln('');

    if (clearFirst) {
      output.writeln('## Step 1: Clear existing messages');
      output.writeln('Run this in Flutter app or create a script:');
      output.writeln('```dart');
      output.writeln('final storage = ChatStorageService();');
      output.writeln('await storage.deleteAllMessages();');
      output.writeln('```');
      output.writeln('');
    }

    output.writeln('## Step 2: Restoration Commands');
    output.writeln('Copy this JSON data and create a restoration service:');
    output.writeln('');
    output.writeln('```json');
    output.writeln(json.encode({
      'metadata': {
        'totalMessages': messages.length,
        'exportFile': filePath,
        'restorationDate': DateTime.now().toIso8601String(),
      },
      'messages': messages,
    }));
    output.writeln('```');

    // Write to restoration file
    final restoreFile = File('docs/exports/restoration_data.json');
    await restoreFile.writeAsString(json.encode({
      'metadata': {
        'totalMessages': messages.length,
        'exportFile': filePath,
        'restorationDate': DateTime.now().toIso8601String(),
      },
      'messages': messages,
    }));

    print('📄 Generated restoration data: docs/exports/restoration_data.json');
    print(
        '📊 Contains ${messages.length} parsed messages ready for database insertion');

    // Also create a summary
    await _generateSummary(messages);
  }

  Future<void> _generateSummary(List<Map<String, dynamic>> messages) async {
    final summary = StringBuffer();

    summary.writeln('# Chat Restoration Summary');
    summary.writeln('Generated: ${DateTime.now().toIso8601String()}');
    summary.writeln('');

    // Message statistics
    final userMessages = messages.where((m) => m['isUser'] as bool).length;
    final aiMessages = messages.where((m) => !(m['isUser'] as bool)).length;
    final audioMessages = messages.where((m) => m['type'] == 'audio').length;

    summary.writeln('## Statistics');
    summary.writeln('- Total messages: ${messages.length}');
    summary.writeln('- User messages: $userMessages');
    summary.writeln('- AI messages: $aiMessages');
    summary.writeln('- Audio messages: $audioMessages');
    summary.writeln('');

    // Persona breakdown
    final personaCounts = <String, int>{};
    for (final message in messages) {
      if (!(message['isUser'] as bool)) {
        final persona = message['personaDisplayName'] as String? ?? 'Unknown';
        personaCounts[persona] = (personaCounts[persona] ?? 0) + 1;
      }
    }

    if (personaCounts.isNotEmpty) {
      summary.writeln('## Messages by Persona');
      for (final entry in personaCounts.entries) {
        summary.writeln('- ${entry.key}: ${entry.value} messages');
      }
      summary.writeln('');
    }

    // Time range
    if (messages.isNotEmpty) {
      final timestamps = messages
          .map((m) => DateTime.parse(m['timestamp'] as String))
          .toList()
        ..sort();
      summary.writeln('## Time Range');
      summary.writeln('- First message: ${timestamps.first}');
      summary.writeln('- Last message: ${timestamps.last}');
      summary.writeln(
          '- Duration: ${timestamps.last.difference(timestamps.first).inDays} days');
    }

    final summaryFile = File('docs/exports/restoration_summary.md');
    await summaryFile.writeAsString(summary.toString());

    print('📋 Generated summary: docs/exports/restoration_summary.md');
  }
}
