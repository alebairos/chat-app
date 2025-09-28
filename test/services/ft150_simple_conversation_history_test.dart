import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:ai_personas_app/services/claude_service.dart';
import 'package:ai_personas_app/services/chat_storage_service.dart';
import 'package:ai_personas_app/models/message_type.dart';
import '../mocks/mock_client.dart';
import '../mock_config_loader.dart';

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
  }) async => ['.'];

  @override
  Future<String?> getLibraryPath() async => '.';

  @override
  Future<String?> getTemporaryPath() async => '.';

  @override
  Future<String?> getDownloadsPath() async => '.';
}

void main() {
  group('FT-150-Simple Conversation History Loading', () {
    late ChatStorageService storageService;
    late ClaudeService claudeService;

    setUpAll(() async {
      // Initialize Flutter test binding and mock path provider
      TestWidgetsFlutterBinding.ensureInitialized();
      PathProviderPlatform.instance = MockPathProvider();
    });

    setUp(() async {
      // Initialize storage service
      storageService = ChatStorageService();
      
      // Clear any existing messages
      await storageService.deleteAllMessages();
    });

    testWidgets('loads recent conversation history on initialization', (tester) async {
      // Setup: Add messages to storage
      await storageService.saveMessage(
        text: 'Acabei de beber água', 
        isUser: true, 
        type: MessageType.text
      );
      await storageService.saveMessage(
        text: 'Ótimo! Continue assim!', 
        isUser: false, 
        type: MessageType.text
      );
      await storageService.saveMessage(
        text: 'Como está minha hidratação?', 
        isUser: true, 
        type: MessageType.text
      );

      // Test: Initialize service with storage
      claudeService = ClaudeService(
        client: MockClient(),
        configLoader: MockConfigLoader(),
        storageService: storageService,
        audioEnabled: false,
      );
      
      await claudeService.initialize();

      // Verify: History loaded (should have 3 messages in reverse order)
      expect(claudeService.conversationHistory.length, equals(3));
      
      // Check first message (oldest)
      expect(claudeService.conversationHistory[0]['role'], equals('user'));
      expect(claudeService.conversationHistory[0]['content'][0]['text'], equals('Acabei de beber água'));
      
      // Check second message
      expect(claudeService.conversationHistory[1]['role'], equals('assistant'));
      expect(claudeService.conversationHistory[1]['content'][0]['text'], equals('Ótimo! Continue assim!'));
      
      // Check third message (newest)
      expect(claudeService.conversationHistory[2]['role'], equals('user'));
      expect(claudeService.conversationHistory[2]['content'][0]['text'], equals('Como está minha hidratação?'));
    });

    testWidgets('handles empty message history gracefully', (tester) async {
      // Test: Initialize service with no messages
      claudeService = ClaudeService(
        client: MockClient(),
        configLoader: MockConfigLoader(),
        storageService: storageService,
        audioEnabled: false,
      );
      
      await claudeService.initialize();

      // Verify: Empty history handled gracefully
      expect(claudeService.conversationHistory.length, equals(0));
    });

    testWidgets('limits history to 5 messages', (tester) async {
      // Setup: Add 7 messages to storage
      for (int i = 1; i <= 7; i++) {
        await storageService.saveMessage(
          text: 'Message $i', 
          isUser: i % 2 == 1, 
          type: MessageType.text
        );
      }

      // Test: Initialize service
      claudeService = ClaudeService(
        client: MockClient(),
        configLoader: MockConfigLoader(),
        storageService: storageService,
        audioEnabled: false,
      );
      
      await claudeService.initialize();

      // Verify: Only 5 most recent messages loaded
      expect(claudeService.conversationHistory.length, equals(5));
      
      // Check that we got the 5 most recent messages (3, 4, 5, 6, 7)
      expect(claudeService.conversationHistory[0]['content'][0]['text'], equals('Message 3'));
      expect(claudeService.conversationHistory[4]['content'][0]['text'], equals('Message 7'));
    });

    testWidgets('works without storage service', (tester) async {
      // Test: Initialize service without storage service
      claudeService = ClaudeService(
        client: MockClient(),
        configLoader: MockConfigLoader(),
        storageService: null, // No storage service
        audioEnabled: false,
      );
      
      await claudeService.initialize();

      // Verify: Graceful degradation - no crash, empty history
      expect(claudeService.conversationHistory.length, equals(0));
    });

    tearDown(() async {
      // Clean up
      await storageService.deleteAllMessages();
    });
  });
}
