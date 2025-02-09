import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import '../lib/services/chat_storage_service.dart';
import '../lib/models/message_type.dart';
import 'dart:typed_data';

class MockPathProvider
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => '.';

  @override
  Future<String?> getApplicationSupportPath() async => '.';

  @override
  Future<String?> getApplicationCachePath() async => '.';

  @override
  Future<String?> getExternalStoragePath() async => '.';

  @override
  Future<List<String>?> getExternalCachePaths() async => ['.'];

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async =>
      ['.'];

  @override
  Future<String?> getDownloadsPath() async => '.';

  @override
  Future<String?> getLibraryPath() async => '.';

  @override
  Future<String?> getTempPath() async => '.';

  @override
  Future<String?> getTemporaryPath() async => '.';
}

void main() {
  late ChatStorageService storage;

  setUpAll(() async {
    PathProviderPlatform.instance = MockPathProvider();
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    storage = ChatStorageService();
  });

  tearDown(() async {
    final isar = await storage.db;
    await isar.close(deleteFromDisk: true);
  });

  group('ChatStorageService', () {
    test('saves and retrieves text message', () async {
      await storage.saveMessage(
        text: 'Hello, world!',
        isUser: true,
        type: MessageType.text,
      );

      final messages = await storage.getMessages();
      expect(messages.length, 1);
      expect(messages.first.text, 'Hello, world!');
      expect(messages.first.isUser, true);
      expect(messages.first.type, MessageType.text);
    });

    test('saves and retrieves audio message', () async {
      final audioData = Uint8List.fromList([1, 2, 3, 4]);
      await storage.saveMessage(
        text: 'Audio transcription',
        isUser: true,
        type: MessageType.audio,
        mediaData: audioData,
        mediaPath: 'audio.m4a',
        duration: const Duration(seconds: 30),
      );

      final messages = await storage.getMessages();
      expect(messages.length, 1);
      expect(messages.first.type, MessageType.audio);
      expect(messages.first.mediaData, audioData);
      expect(messages.first.mediaPath, 'audio.m4a');
      expect(messages.first.duration?.inSeconds, 30);
    });

    test('retrieves messages in descending order', () async {
      await storage.saveMessage(
        text: 'First message',
        isUser: true,
        type: MessageType.text,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      await storage.saveMessage(
        text: 'Second message',
        isUser: false,
        type: MessageType.text,
      );

      final messages = await storage.getMessages();
      expect(messages.length, 2);
      expect(messages.first.text, 'Second message');
      expect(messages.last.text, 'First message');
    });

    test('deletes message by id', () async {
      await storage.saveMessage(
        text: 'Delete me',
        isUser: true,
        type: MessageType.text,
      );

      final messages = await storage.getMessages();
      expect(messages.length, 1);

      await storage.deleteMessage(messages.first.id);
      final afterDelete = await storage.getMessages();
      expect(afterDelete.isEmpty, true);
    });

    test('deletes all messages', () async {
      await storage.saveMessage(
        text: 'Message 1',
        isUser: true,
        type: MessageType.text,
      );

      await storage.saveMessage(
        text: 'Message 2',
        isUser: false,
        type: MessageType.text,
      );

      final beforeDelete = await storage.getMessages();
      expect(beforeDelete.length, 2);

      await storage.deleteAllMessages();
      final afterDelete = await storage.getMessages();
      expect(afterDelete.isEmpty, true);
    });

    test('searches messages by text', () async {
      await storage.saveMessage(
        text: 'Find this message',
        isUser: true,
        type: MessageType.text,
      );

      await storage.saveMessage(
        text: 'Different content',
        isUser: true,
        type: MessageType.text,
      );

      final searchResults = await storage.searchMessages('Find');
      expect(searchResults.length, 1);
      expect(searchResults.first.text, 'Find this message');
    });

    test('limits number of messages returned', () async {
      for (var i = 0; i < 10; i++) {
        await storage.saveMessage(
          text: 'Message $i',
          isUser: true,
          type: MessageType.text,
        );
      }

      final messages = await storage.getMessages(limit: 5);
      expect(messages.length, 5);
    });

    test('filters messages before timestamp', () async {
      await storage.saveMessage(
        text: 'Old message',
        isUser: true,
        type: MessageType.text,
      );

      final cutoffTime = DateTime.now();
      await Future.delayed(const Duration(milliseconds: 100));

      await storage.saveMessage(
        text: 'New message',
        isUser: true,
        type: MessageType.text,
      );

      final oldMessages = await storage.getMessages(before: cutoffTime);
      expect(oldMessages.length, 1);
      expect(oldMessages.first.text, 'Old message');
    });

    test('handles pagination correctly', () async {
      // Create 25 messages
      for (var i = 0; i < 25; i++) {
        await storage.saveMessage(
          text: 'Message $i',
          isUser: true,
          type: MessageType.text,
        );
        // Add small delay to ensure distinct timestamps
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Get first page (20 messages)
      final firstPage = await storage.getMessages(limit: 20);
      expect(firstPage.length, 20);
      expect(firstPage.first.text, 'Message 24');
      expect(firstPage.last.text, 'Message 5');

      // Get second page using last message timestamp
      final secondPage = await storage.getMessages(
        limit: 20,
        before: firstPage.last.timestamp,
      );
      expect(secondPage.length, 5);
      expect(secondPage.first.text, 'Message 4');
      expect(secondPage.last.text, 'Message 0');
    });

    test('handles empty pages gracefully', () async {
      // Create 5 messages
      for (var i = 0; i < 5; i++) {
        await storage.saveMessage(
          text: 'Message $i',
          isUser: true,
          type: MessageType.text,
        );
      }

      // Get first page
      final firstPage = await storage.getMessages(limit: 10);
      expect(firstPage.length, 5);

      // Try to get second page
      final secondPage = await storage.getMessages(
        limit: 10,
        before: firstPage.last.timestamp,
      );
      expect(secondPage.isEmpty, true);
    });

    test('maintains message order during pagination', () async {
      final timestamps = <DateTime>[];

      // Create 30 messages with controlled timestamps
      for (var i = 0; i < 30; i++) {
        final timestamp = DateTime.now();
        timestamps.add(timestamp);

        await storage.saveMessage(
          text: 'Message $i',
          isUser: true,
          type: MessageType.text,
        );

        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Get messages in pages
      final page1 = await storage.getMessages(limit: 10);
      final page2 = await storage.getMessages(
        limit: 10,
        before: page1.last.timestamp,
      );
      final page3 = await storage.getMessages(
        limit: 10,
        before: page2.last.timestamp,
      );

      // Verify each page has correct size
      expect(page1.length, 10);
      expect(page2.length, 10);
      expect(page3.length, 10);

      // Verify messages are in correct order
      for (var i = 0; i < 9; i++) {
        expect(
          page1[i].timestamp.isAfter(page1[i + 1].timestamp),
          true,
          reason: 'Messages in page 1 should be in descending order',
        );
        expect(
          page2[i].timestamp.isAfter(page2[i + 1].timestamp),
          true,
          reason: 'Messages in page 2 should be in descending order',
        );
        expect(
          page3[i].timestamp.isAfter(page3[i + 1].timestamp),
          true,
          reason: 'Messages in page 3 should be in descending order',
        );
      }

      // Verify page boundaries
      expect(
        page1.last.timestamp.isAfter(page2.first.timestamp),
        true,
        reason:
            'Last message of page 1 should be newer than first message of page 2',
      );
      expect(
        page2.last.timestamp.isAfter(page3.first.timestamp),
        true,
        reason:
            'Last message of page 2 should be newer than first message of page 3',
      );
    });
  });

  group('Concurrency Tests', () {
    test('maintains message order during concurrent saves', () async {
      final futures = <Future>[];

      // Simulate multiple concurrent message saves
      for (var i = 0; i < 5; i++) {
        futures.add(storage.saveMessage(
          text: 'Concurrent message $i',
          isUser: true,
          type: MessageType.text,
        ));
        // Force a small delay to ensure concurrent execution
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Wait for all saves to complete
      await Future.wait(futures);

      // Verify messages are in correct order
      final messages = await storage.getMessages();
      expect(messages.length, 5);

      // Verify timestamps are in descending order
      for (var i = 0; i < messages.length - 1; i++) {
        expect(
          messages[i].timestamp.isAfter(messages[i + 1].timestamp),
          true,
          reason: 'Messages should be in reverse chronological order',
        );
      }
    });

    test('handles concurrent delete and edit operations', () async {
      // Create a message to test with
      await storage.saveMessage(
        text: 'Original message',
        isUser: true,
        type: MessageType.text,
      );

      final messages = await storage.getMessages();
      final messageId = messages.first.id;

      // Simulate concurrent delete and edit
      final futures = <Future>[
        storage.deleteMessage(messageId),
        storage.saveMessage(
          text: 'Edited message',
          isUser: true,
          type: MessageType.text,
        ),
      ];

      await Future.wait(futures);

      // Verify message was deleted
      final afterOperations = await storage.getMessages();
      expect(
        afterOperations.any((m) => m.id == messageId),
        false,
        reason: 'Original message should be deleted',
      );
    });
  });
}
