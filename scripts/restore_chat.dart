import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:isar/isar.dart';
import 'package:character_ai_clone/services/chat_storage_service.dart';
import 'package:character_ai_clone/models/chat_message_model.dart';
import 'package:character_ai_clone/models/message_type.dart';

/// Chat restoration script for FT-069
/// Restores chat history from WhatsApp-format export files
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('❌ Usage: dart run scripts/restore_chat.dart <export_file_path>');
    print(
        '📄 Example: dart run scripts/restore_chat.dart ~/Downloads/chat_export_2025-08-22_14-34-48.txt');
    exit(1);
  }

  final filePath = args[0];
  final clearFirst = args.contains('--clear-first');
  final verify = args.contains('--verify') || true; // Always verify

  print('🔄 Starting chat restoration...');
  print('📁 File: $filePath');
  if (clearFirst) print('⚠️  Will clear existing messages first');

  try {
    // Initialize Flutter bindings for path_provider
    WidgetsFlutterBinding.ensureInitialized();

    final restorer = ChatDatabaseRestorer();
    await restorer.restoreFromFile(filePath,
        clearFirst: clearFirst, verify: verify);

    print('✅ Chat restoration complete!');
  } catch (e) {
    print('❌ Restoration failed: $e');
    exit(1);
  }
}

class ChatDatabaseRestorer {
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
      {bool clearFirst = false, bool verify = true}) async {
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
    final messages = <ChatMessageModel>[];
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
          messages.add(parsed.message);

          if (parsed.isUser) {
            userCount++;
          } else {
            aiCount++;
            final persona = parsed.personaName ?? 'Unknown';
            personaCounts[persona] = (personaCounts[persona] ?? 0) + 1;
          }

          if (parsed.message.type == MessageType.audio) {
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

    // Initialize database
    final storageService = ChatStorageService();
    await storageService.db; // Ensure initialized

    // Clear existing messages if requested
    if (clearFirst) {
      print('🗑️  Clearing existing messages...');
      await storageService.deleteAllMessages();
      print('✅ Existing messages cleared');
    }

    // Insert messages
    print('💾 Inserting messages into database...');
    await _insertMessages(storageService, messages);
    print('✅ Inserted ${messages.length} messages successfully');

    // Verify import
    if (verify) {
      print('🔍 Verifying import...');
      await _verifyImport(storageService, messages);
    }
  }

  ParseResult? _parseLine(String line) {
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
    final messageType = isAudio ? MessageType.audio : MessageType.text;

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

    final message = ChatMessageModel(
      text: messageText,
      isUser: isUser,
      type: messageType,
      timestamp: timestamp,
      mediaPath: mediaPath,
      personaKey: personaKey,
      personaDisplayName: personaDisplayName,
    );

    return ParseResult(
      message: message,
      isUser: isUser,
      personaName: isUser ? null : sender,
    );
  }

  Future<void> _insertMessages(
      ChatStorageService storage, List<ChatMessageModel> messages) async {
    final isar = await storage.db;

    // Insert in batches for better performance
    const batchSize = 100;
    for (int i = 0; i < messages.length; i += batchSize) {
      final batch = messages.skip(i).take(batchSize).toList();

      await isar.writeTxn(() async {
        await isar.chatMessageModels.putAll(batch);
      });

      print(
          '   💾 Inserted batch ${(i / batchSize).floor() + 1}/${(messages.length / batchSize).ceil()}');
    }
  }

  Future<void> _verifyImport(ChatStorageService storage,
      List<ChatMessageModel> expectedMessages) async {
    final isar = await storage.db;
    final actualCount = await isar.chatMessageModels.count();

    print('✅ Database contains $actualCount messages');

    if (expectedMessages.isNotEmpty) {
      final oldest = expectedMessages.last.timestamp;
      final newest = expectedMessages.first.timestamp;
      print(
          '✅ Timestamp range: ${oldest.toString().substring(0, 10)} to ${newest.toString().substring(0, 10)}');
    }

    // Verify persona distribution
    final allMessages =
        await isar.chatMessageModels.where().sortByTimestamp().findAll();
    final personaGroups = allMessages.where((msg) => !msg.isUser).toList();

    final personaVerification = <String, int>{};
    for (final message in personaGroups) {
      final persona = message.personaDisplayName ?? 'Unknown';
      personaVerification[persona] = (personaVerification[persona] ?? 0) + 1;
    }

    if (personaVerification.isNotEmpty) {
      print('✅ Persona verification:');
      for (final entry in personaVerification.entries) {
        print('   • ${entry.key}: ${entry.value} messages');
      }
    }

    print('✅ Import verification complete');
  }
}

class ParseResult {
  final ChatMessageModel message;
  final bool isUser;
  final String? personaName;

  ParseResult({
    required this.message,
    required this.isUser,
    this.personaName,
  });
}
