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
  });
}
