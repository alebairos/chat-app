import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/chat_message_model.dart';
import '../models/message_type.dart';
import 'dart:typed_data';

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

    // Verify audio file exists if it's an audio message
    if (type == MessageType.audio && mediaPath != null) {
      final file = File(mediaPath);
      if (!await file.exists()) {
        throw Exception('Audio file not found at $mediaPath');
      }
    }

    final message = ChatMessageModel(
      text: text,
      isUser: isUser,
      type: type,
      timestamp: DateTime.now(),
      mediaData: mediaData?.toList(),
      mediaPath: mediaPath,
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

    if (before != null) {
      return query
          .filter()
          .timestampLessThan(before)
          .sortByTimestampDesc()
          .limit(limit ?? 50)
          .findAll();
    }

    return query.sortByTimestampDesc().limit(limit ?? 50).findAll();
  }

  Future<void> deleteMessage(Id id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      final message = await isar.chatMessageModels.get(id);
      if (message != null && message.isUser) {
        // Delete the audio file if it exists
        if (message.type == MessageType.audio && message.mediaPath != null) {
          final file = File(message.mediaPath!);
          if (await file.exists()) {
            await file.delete();
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

  Future<void> close() async {
    final isar = await db;
    await isar.close();
  }
}
