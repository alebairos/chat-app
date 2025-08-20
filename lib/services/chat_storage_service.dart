import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/chat_message_model.dart';
import '../models/message_type.dart';
import 'dart:typed_data';
import '../utils/path_utils.dart';

class ChatStorageService {
  late Future<Isar> db;

  ChatStorageService() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [ChatMessageModelSchema],
        directory: dir.path,
      );
    }

    return Future.value(Isar.getInstance());
  }

  Future<void> saveMessage({
    required String text,
    required bool isUser,
    required MessageType type,
    Uint8List? mediaData,
    String? mediaPath,
    Duration? duration,
  }) async {
    final isar = await db;

    // Convert absolute path to relative path if needed
    String? relativePath;
    if (type == MessageType.audio && mediaPath != null) {
      // Verify audio file exists
      final file = File(mediaPath);
      if (!await file.exists()) {
        throw Exception('Audio file not found at $mediaPath');
      }

      // Convert to relative path if it's an absolute path
      if (PathUtils.isAbsolutePath(mediaPath)) {
        relativePath = await PathUtils.absoluteToRelative(mediaPath);
        if (relativePath == null) {
          throw Exception('Failed to convert absolute path to relative path');
        }
      } else {
        // It's already a relative path
        relativePath = mediaPath;
      }
    }

    final message = ChatMessageModel(
      text: text,
      isUser: isUser,
      type: type,
      timestamp: DateTime.now(),
      mediaData: mediaData?.toList(),
      mediaPath: relativePath, // Store the relative path
      duration: duration,
    );

    await isar.writeTxn(() async {
      await isar.chatMessageModels.put(message);
    });
  }

  Future<List<ChatMessageModel>> getMessages({
    int? limit,
    DateTime? before,
  }) async {
    final isar = await db;
    final query = isar.chatMessageModels.where();

    List<ChatMessageModel> messages;
    if (before != null) {
      messages = await query
          .filter()
          .timestampLessThan(before)
          .sortByTimestampDesc()
          .limit(limit ?? 50)
          .findAll();
    } else {
      messages = await query.sortByTimestampDesc().limit(limit ?? 50).findAll();
    }

    return messages;
  }

  Future<void> deleteMessage(Id id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      final message = await isar.chatMessageModels.get(id);
      if (message != null && message.isUser) {
        // Delete the audio file if it exists
        if (message.type == MessageType.audio && message.mediaPath != null) {
          try {
            // Convert relative path to absolute if needed
            String absolutePath;
            if (PathUtils.isAbsolutePath(message.mediaPath!)) {
              absolutePath = message.mediaPath!;
            } else {
              absolutePath =
                  await PathUtils.relativeToAbsolute(message.mediaPath!);
            }

            final file = File(absolutePath);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            print('Error deleting audio file: $e');
            // Continue with message deletion even if file deletion fails
          }
        }
        // Delete the message from the database
        await isar.chatMessageModels.delete(id);
      }
    });
  }

  Future<void> editMessage(Id id, String newText) async {
    final isar = await db;
    await isar.writeTxn(() async {
      final message = await isar.chatMessageModels.get(id);
      if (message != null && message.isUser) {
        // Only allow editing user messages
        message.text = newText;
        message.timestamp =
            DateTime.now(); // Update timestamp to mark as edited
        await isar.chatMessageModels.put(message);
      }
    });
  }

  Future<void> deleteAllMessages() async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.chatMessageModels.clear();
    });
  }

  Future<List<ChatMessageModel>> searchMessages(String query) async {
    final isar = await db;
    return await isar.chatMessageModels
        .where()
        .filter()
        .textContains(query, caseSensitive: false)
        .sortByTimestampDesc()
        .findAll();
  }

  /// Migrate existing messages with absolute paths to relative paths
  Future<void> migratePathsToRelative() async {
    final isar = await db;
    final messages = await isar.chatMessageModels
        .where()
        .filter()
        .mediaPathIsNotNull()
        .findAll();

    int migratedCount = 0;
    await isar.writeTxn(() async {
      for (final message in messages) {
        if (message.mediaPath != null &&
            PathUtils.isAbsolutePath(message.mediaPath!)) {
          final relativePath =
              await PathUtils.absoluteToRelative(message.mediaPath!);
          if (relativePath != null) {
            message.mediaPath = relativePath;
            await isar.chatMessageModels.put(message);
            migratedCount++;
          }
        }
      }
    });

    print('Migrated $migratedCount paths from absolute to relative');
  }

  /// Migrate existing AI messages to include persona metadata
  Future<void> migrateToPersonaMetadata() async {
    final isar = await db;

    // Check if migration is needed by looking for AI messages without persona data
    final messagesWithoutPersona = await isar.chatMessageModels
        .where()
        .filter()
        .isUserEqualTo(false) // Only AI messages
        .and()
        .personaKeyIsNull() // Without persona data
        .findAll();

    if (messagesWithoutPersona.isEmpty) {
      // Migration already completed or no AI messages
      return;
    }

    print(
        'Found ${messagesWithoutPersona.length} AI messages without persona data, migrating...');

    int migratedCount = 0;
    await isar.writeTxn(() async {
      for (final message in messagesWithoutPersona) {
        // For legacy messages, we can't determine exact persona
        // Use a generic fallback that won't confuse users
        final updatedMessage = message.copyWith(
          personaKey: 'unknown',
          personaDisplayName: 'AI Assistant',
        );
        await isar.chatMessageModels.put(updatedMessage);
        migratedCount++;
      }
    });

    print('Migrated $migratedCount AI messages to include persona metadata');
  }

  Future<void> close() async {
    final isar = await db;
    await isar.close();
  }
}
