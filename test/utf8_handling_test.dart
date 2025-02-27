import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:character_ai_clone/widgets/chat_input.dart';
import 'package:character_ai_clone/services/chat_storage_service.dart';
import 'package:character_ai_clone/models/message_type.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:isar/isar.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class MockPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      Directory.systemTemp.path;

  @override
  Future<String?> getApplicationCachePath() async => Directory.systemTemp.path;

  @override
  Future<String?> getApplicationSupportPath() async =>
      Directory.systemTemp.path;

  @override
  Future<String?> getDownloadsPath() async => Directory.systemTemp.path;

  @override
  Future<List<String>?> getExternalCachePaths() async =>
      [Directory.systemTemp.path];

  @override
  Future<List<String>?> getExternalStoragePaths(
          {StorageDirectory? type}) async =>
      [Directory.systemTemp.path];

  @override
  Future<String?> getLibraryPath() async => Directory.systemTemp.path;

  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UTF-8 Text Handling', () {
    late TextEditingController controller;
    late Directory tempDir;
    late MockPathProviderPlatform mockPlatform;

    setUpAll(() async {
      mockPlatform = MockPathProviderPlatform();
      PathProviderPlatform.instance = mockPlatform;

      // Set up temporary directory for Isar
      tempDir = await Directory.systemTemp.createTemp();

      // Initialize Isar for testing
      await Isar.initializeIsarCore(download: true);
    });

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    tearDownAll(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('handles Portuguese characters in ChatInput', (tester) async {
      bool sendPressed = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChatInput(
            controller: controller,
            onSend: () {
              if (controller.text.trim().isNotEmpty) {
                sendPressed = true;
              }
            },
            onSendAudio: (_, __) {},
          ),
        ),
      ));

      // Test various Portuguese characters
      const testText = 'ação reação função maçã português';
      await tester.enterText(find.byType(TextField), testText);
      await tester.pump();

      expect(controller.text, equals(testText));
      expect(find.text(testText), findsOneWidget);

      // Test sending
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump();
      expect(sendPressed, isTrue);
    });

    group('Storage Service Tests', () {
      late ChatStorageService storageService;
      late Directory testDir;

      setUp(() async {
        // Create a unique test directory for each test
        testDir = Directory(path.join(
            tempDir.path, 'test_${DateTime.now().millisecondsSinceEpoch}'));
        await testDir.create();

        // Initialize storage service with test directory
        storageService = ChatStorageService();
        await storageService.openDB();

        // Clear any existing messages
        print('🧹 Clearing database before test');
        await storageService.deleteAllMessages();
      });

      tearDown(() async {
        print('🧹 Cleaning up after test');
        await storageService.close();
        if (testDir.existsSync()) {
          await testDir.delete(recursive: true);
        }
      });

      test('storage service preserves Portuguese characters', () async {
        const originalText = 'ação reação função maçã português';

        // Save message with Portuguese characters
        await storageService.saveMessage(
          text: originalText,
          isUser: true,
          type: MessageType.text,
        );

        // Retrieve the message
        final messages = await storageService.getMessages(limit: 1);
        expect(messages.length, equals(1));
        expect(messages.first.text, equals(originalText));

        // Test editing with Portuguese characters
        const editedText = 'edição alteração português';
        await storageService.editMessage(messages.first.id, editedText);

        final editedMessages = await storageService.getMessages(limit: 1);
        expect(editedMessages.first.text, equals(editedText));
      });

      test('storage service handles search with Portuguese characters',
          () async {
        print('\n🧪 Starting Portuguese characters search test');

        const text1 = 'palavra específica teste';
        const text2 = 'outra função teste';
        const text3 = 'mais uma específica diferente';

        print('📝 Test messages:');
        print('1️⃣ "$text1"');
        print('2️⃣ "$text2"');
        print('3️⃣ "$text3"');

        print('\n💾 Saving test messages...');
        // Save messages with Portuguese characters
        await storageService.saveMessage(
          text: text1,
          isUser: true,
          type: MessageType.text,
        );
        await storageService.saveMessage(
          text: text2,
          isUser: true,
          type: MessageType.text,
        );
        await storageService.saveMessage(
          text: text3,
          isUser: true,
          type: MessageType.text,
        );
        print('✓ Messages saved');

        print('\n🔍 Testing search for "específica"...');
        // Search for exact word match (case-insensitive)
        final results = await storageService.searchMessages('específica');
        print(
            '📊 Found ${results.length} results: ${results.map((m) => '"${m.text}"').join(', ')}');
        expect(results.length, equals(2),
            reason: 'Should find "específica" in both messages');
        expect(results.map((m) => m.text).toSet(), equals({text1, text3}),
            reason:
                'Should match both messages containing the word "específica"');
        print('✓ First search test passed');

        print('\n🔍 Testing search for "função"...');
        // Search for unique word
        final results2 = await storageService.searchMessages('função');
        print(
            '📊 Found ${results2.length} results: ${results2.map((m) => '"${m.text}"').join(', ')}');
        expect(results2.length, equals(1),
            reason: 'Should find exactly one message with "função"');
        expect(results2.first.text, equals(text2),
            reason: 'Should match the message containing "função"');
        print('✓ Second search test passed');

        print('\n🔍 Testing case-insensitive search for "FUNÇÃO"...');
        // Search with uppercase (case-insensitive)
        final results3 = await storageService.searchMessages('FUNÇÃO');
        print(
            '📊 Found ${results3.length} results: ${results3.map((m) => '"${m.text}"').join(', ')}');
        expect(results3.length, equals(1),
            reason: 'Should find one message with "função" case-insensitive');
        expect(results3.first.text, equals(text2),
            reason:
                'Should match the message containing "função" regardless of case');
        print('✓ Third search test passed');

        print('\n✅ All search tests completed');
      });
    });
  });
}
