import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:character_ai_clone/services/claude_service.dart';
import 'package:character_ai_clone/services/chat_storage_service.dart';
import 'package:character_ai_clone/models/chat_message_model.dart';
import 'package:character_ai_clone/models/message_type.dart';
import 'package:character_ai_clone/config/config_loader.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

// Mock classes
class MockClient extends Mock implements http.Client {}

class MockChatStorageService extends Mock implements ChatStorageService {}

class MockConfigLoader extends Mock implements ConfigLoader {}

void main() {
  group('ClaudeService Time Context Integration', () {
    late MockClient mockClient;
    late MockChatStorageService mockStorageService;
    late MockConfigLoader mockConfigLoader;
    late ClaudeService claudeService;

    setUpAll(() {
      // Load test environment variables
      dotenv.testLoad(fileInput: '''
        ANTHROPIC_API_KEY=test_key
        ANTHROPIC_MODEL=claude-3-5-sonnet-latest
      ''');
    });

    setUp(() {
      mockClient = MockClient();
      mockStorageService = MockChatStorageService();
      mockConfigLoader = MockConfigLoader();

      // Register fallback values for mocktail
      registerFallbackValue(Uri.parse('https://example.com'));

      claudeService = ClaudeService(
        client: mockClient,
        storageService: mockStorageService,
        configLoader: mockConfigLoader,
        audioEnabled: false, // Disable audio for simpler testing
      );

      // Mock config loader responses
      when(() => mockConfigLoader.loadSystemPrompt())
          .thenAnswer((_) async => 'Test system prompt');
      when(() => mockConfigLoader.activePersonaKey).thenReturn('testPersona');
      when(() => mockConfigLoader.activePersonaDisplayName)
          .thenAnswer((_) async => 'Test Persona');
    });

    group('Time Context Integration', () {
      test(
          'should include time context in system prompt when recent message exists',
          () async {
        // Arrange
        final now = DateTime.now();
        final recentMessage = now.subtract(const Duration(hours: 2));

        final mockMessage = ChatMessageModel(
          text: 'Previous message',
          isUser: true,
          type: MessageType.text,
          timestamp: recentMessage,
        );

        when(() => mockStorageService.getMessages(limit: 1))
            .thenAnswer((_) async => [mockMessage]);

        when(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
              encoding: any(named: 'encoding'),
            )).thenAnswer((_) async => http.Response(
              jsonEncode({
                'content': [
                  {'text': 'Response with time context'}
                ]
              }),
              200,
            ));

        // Act
        final response = await claudeService.sendMessage('Hello');

        // Assert
        expect(response, equals('Response with time context'));

        // Verify that the system prompt included time context
        final capturedCall = verify(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: captureAny(named: 'body'),
              encoding: any(named: 'encoding'),
            )).captured.first as String;

        final requestBody = jsonDecode(capturedCall);
        final systemPrompt = requestBody['system'] as String;

        expect(systemPrompt,
            contains('Conversation resuming after a short break'));
        expect(systemPrompt, contains('Current context: It is'));
        expect(systemPrompt, contains('Test system prompt'));
      });

      test('should include only current time context when no previous messages',
          () async {
        // Arrange
        when(() => mockStorageService.getMessages(limit: 1))
            .thenAnswer((_) async => []);

        when(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
              encoding: any(named: 'encoding'),
            )).thenAnswer((_) async => http.Response(
              jsonEncode({
                'content': [
                  {'text': 'First conversation response'}
                ]
              }),
              200,
            ));

        // Act
        final response = await claudeService.sendMessage('Hello');

        // Assert
        expect(response, equals('First conversation response'));

        // Verify that only current time context is included
        final capturedCall = verify(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: captureAny(named: 'body'),
              encoding: any(named: 'encoding'),
            )).captured.first as String;

        final requestBody = jsonDecode(capturedCall);
        final systemPrompt = requestBody['system'] as String;

        expect(systemPrompt, contains('Current context: It is'));
        expect(systemPrompt, isNot(contains('resuming')));
        expect(systemPrompt, contains('Test system prompt'));
      });

      test('should handle storage service errors gracefully', () async {
        // Arrange
        when(() => mockStorageService.getMessages(limit: 1))
            .thenThrow(Exception('Storage error'));

        when(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
              encoding: any(named: 'encoding'),
            )).thenAnswer((_) async => http.Response(
              jsonEncode({
                'content': [
                  {'text': 'Response despite storage error'}
                ]
              }),
              200,
            ));

        // Act
        final response = await claudeService.sendMessage('Hello');

        // Assert
        expect(response, equals('Response despite storage error'));

        // Verify that current time context is still included
        final capturedCall = verify(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: captureAny(named: 'body'),
              encoding: any(named: 'encoding'),
            )).captured.first as String;

        final requestBody = jsonDecode(capturedCall);
        final systemPrompt = requestBody['system'] as String;

        expect(systemPrompt, contains('Current context: It is'));
      });

      test('should work without storage service dependency', () async {
        // Arrange
        final claudeServiceNoStorage = ClaudeService(
          client: mockClient,
          configLoader: mockConfigLoader,
          audioEnabled: false,
          // No storage service provided
        );

        when(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
              encoding: any(named: 'encoding'),
            )).thenAnswer((_) async => http.Response(
              jsonEncode({
                'content': [
                  {'text': 'Response without storage service'}
                ]
              }),
              200,
            ));

        // Act
        final response = await claudeServiceNoStorage.sendMessage('Hello');

        // Assert
        expect(response, equals('Response without storage service'));

        // Verify that current time context is still included
        final capturedCall = verify(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: captureAny(named: 'body'),
              encoding: any(named: 'encoding'),
            )).captured.first as String;

        final requestBody = jsonDecode(capturedCall);
        final systemPrompt = requestBody['system'] as String;

        expect(systemPrompt, contains('Current context: It is'));
        expect(systemPrompt, isNot(contains('resuming')));
      });

      test('should include different time contexts for different gaps',
          () async {
        // Test yesterday gap
        final now = DateTime.now();
        final yesterdayMessage = ChatMessageModel(
          text: 'Yesterday message',
          isUser: true,
          type: MessageType.text,
          timestamp: now.subtract(const Duration(days: 1)),
        );

        when(() => mockStorageService.getMessages(limit: 1))
            .thenAnswer((_) async => [yesterdayMessage]);

        when(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
              encoding: any(named: 'encoding'),
            )).thenAnswer((_) async => http.Response(
              jsonEncode({
                'content': [
                  {'text': 'Yesterday response'}
                ]
              }),
              200,
            ));

        // Act
        final response = await claudeService.sendMessage('Hello');

        // Assert
        expect(response, equals('Yesterday response'));

        final capturedCall = verify(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: captureAny(named: 'body'),
              encoding: any(named: 'encoding'),
            )).captured.first as String;

        final requestBody = jsonDecode(capturedCall);
        final systemPrompt = requestBody['system'] as String;

        expect(systemPrompt, contains('Conversation resuming from yesterday'));
        expect(systemPrompt, contains('Current context: It is'));
      });

      test('should preserve MCP data integration with time context', () async {
        // Arrange
        final now = DateTime.now();
        final recentMessage = ChatMessageModel(
          text: 'Previous message',
          isUser: true,
          type: MessageType.text,
          timestamp: now.subtract(const Duration(hours: 1)),
        );

        when(() => mockStorageService.getMessages(limit: 1))
            .thenAnswer((_) async => [recentMessage]);

        when(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
              encoding: any(named: 'encoding'),
            )).thenAnswer((_) async => http.Response(
              jsonEncode({
                'content': [
                  {'text': 'Response with both contexts'}
                ]
              }),
              200,
            ));

        // Act - send a non-MCP message to verify time context works alongside MCP logic
        final response = await claudeService.sendMessage('Regular message');

        // Assert
        expect(response, equals('Response with both contexts'));

        final capturedCall = verify(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: captureAny(named: 'body'),
              encoding: any(named: 'encoding'),
            )).captured.first as String;

        final requestBody = jsonDecode(capturedCall);
        final systemPrompt = requestBody['system'] as String;

        // Should have time context at the beginning
        expect(systemPrompt,
            contains('Conversation resuming after a short break'));
        expect(systemPrompt, contains('Current context: It is'));
        // Should have system prompt in the middle
        expect(systemPrompt, contains('Test system prompt'));
        // Should not have MCP data for non-MCP messages
        expect(systemPrompt, isNot(contains('MCP database')));
      });

      test('should validate timestamps before using them', () async {
        // Arrange - create a future timestamp (invalid)
        final futureTimestamp = DateTime.now().add(const Duration(minutes: 5));
        final invalidMessage = ChatMessageModel(
          text: 'Future message',
          isUser: true,
          type: MessageType.text,
          timestamp: futureTimestamp,
        );

        when(() => mockStorageService.getMessages(limit: 1))
            .thenAnswer((_) async => [invalidMessage]);

        when(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
              encoding: any(named: 'encoding'),
            )).thenAnswer((_) async => http.Response(
              jsonEncode({
                'content': [
                  {'text': 'Response with invalid timestamp'}
                ]
              }),
              200,
            ));

        // Act
        final response = await claudeService.sendMessage('Hello');

        // Assert
        expect(response, equals('Response with invalid timestamp'));

        final capturedCall = verify(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: captureAny(named: 'body'),
              encoding: any(named: 'encoding'),
            )).captured.first as String;

        final requestBody = jsonDecode(capturedCall);
        final systemPrompt = requestBody['system'] as String;

        // Should only include current time context (no gap context for invalid timestamp)
        expect(systemPrompt, contains('Current context: It is'));
        expect(systemPrompt, isNot(contains('resuming')));
      });
    });
  });
}
