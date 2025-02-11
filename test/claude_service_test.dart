import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../lib/services/claude_service.dart';
import '../lib/config/config_loader.dart';
import 'mock_config_loader.dart';
import 'claude_service_test.mocks.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

@GenerateMocks([http.Client])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.testLoad(fileInput: '''
      ANTHROPIC_API_KEY=test_key
    ''');
    // Replace the real ConfigLoader with our mock
    ConfigLoader.loadSystemPromptImpl = MockConfigLoader.loadSystemPrompt;
  });

  group('ClaudeService', () {
    late ClaudeService service;
    late MockClient mockClient;

    setUp(() async {
      mockClient = MockClient();
      service = ClaudeService(client: mockClient);
    });

    test('maintains conversation history', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'content': [
                {'text': 'First response'}
              ]
            }),
            200,
          ));

      // Send first message
      final firstResponse = await service.sendMessage('Hello');
      expect(firstResponse, equals('First response'));
      expect(service.conversationHistory.length,
          equals(2)); // User message + Assistant response

      // Verify first message includes correct history
      verify(mockClient.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: argThat(
          predicate((Map<String, String> headers) =>
              headers['Content-Type'] == 'application/json; charset=utf-8' &&
              headers['Accept'] == 'application/json; charset=utf-8' &&
              headers['anthropic-version'] == '2023-06-01' &&
              headers['x-api-key'] != null),
          named: 'headers',
        ),
        body: jsonEncode({
          'model': 'claude-3-opus-20240229',
          'max_tokens': 1024,
          'messages': [
            {
              'role': 'system',
              'content': 'Test system prompt',
            },
            {
              'role': 'user',
              'content': 'Hello',
            }
          ],
        }),
        encoding: utf8,
      )).called(1);

      // Setup mock for second message
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'content': [
                {'text': 'Second response'}
              ]
            }),
            200,
          ));

      // Send second message
      final secondResponse = await service.sendMessage('How are you?');
      expect(secondResponse, equals('Second response'));
      expect(service.conversationHistory.length,
          equals(4)); // Two user messages + two assistant responses

      // Verify second message includes full history
      verify(mockClient.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: argThat(
          predicate((Map<String, String> headers) =>
              headers['Content-Type'] == 'application/json; charset=utf-8' &&
              headers['Accept'] == 'application/json; charset=utf-8' &&
              headers['anthropic-version'] == '2023-06-01' &&
              headers['x-api-key'] != null),
          named: 'headers',
        ),
        body: jsonEncode({
          'model': 'claude-3-opus-20240229',
          'max_tokens': 1024,
          'messages': [
            {
              'role': 'system',
              'content': 'Test system prompt',
            },
            {
              'role': 'user',
              'content': 'Hello',
            },
            {
              'role': 'assistant',
              'content': 'First response',
            },
            {
              'role': 'user',
              'content': 'How are you?',
            }
          ],
        }),
        encoding: utf8,
      )).called(1);
    });

    test('clears conversation history', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'content': [
                {'text': 'Response'}
              ]
            }),
            200,
          ));

      await service.sendMessage('Hello');
      expect(service.conversationHistory.length, equals(2));

      service.clearConversation();
      expect(service.conversationHistory.length, equals(0));
    });

    test('handles network errors gracefully', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
      )).thenThrow(Exception('Network error'));

      final response = await service.sendMessage('Hello');
      expect(response, startsWith('Error: Unable to connect to Claude'));
      expect(service.conversationHistory.length,
          equals(1)); // Only user message is added
    });

    test('handles API errors gracefully', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
      )).thenAnswer((_) async => http.Response(
            'Rate limit exceeded',
            429,
          ));

      final response = await service.sendMessage('Hello');
      expect(response, startsWith('Error: Unable to connect to Claude'));
      expect(service.conversationHistory.length,
          equals(1)); // Only user message is added
    });

    test('handles malformed JSON response gracefully', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
      )).thenAnswer((_) async => http.Response(
            '{malformed json',
            200,
          ));

      final response = await service.sendMessage('Hello');
      expect(response, startsWith('Error: Unable to connect to Claude'));
    });

    test('handles empty response gracefully', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
      )).thenAnswer((_) async => http.Response('', 200));

      final response = await service.sendMessage('Hello');
      expect(response, startsWith('Error: Unable to connect to Claude'));
    });
  });
}
