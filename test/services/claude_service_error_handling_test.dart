import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_personas_app/services/claude_service.dart';
import 'package:ai_personas_app/config/config_loader.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

@GenerateMocks([http.Client, ConfigLoader])
import '../helpers/claude_service_error_handling_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  print('\n🚀 Starting Claude Service Error Handling Tests');

  late MockClient mockClient;
  late MockConfigLoader mockConfigLoader;
  late ClaudeService service;

  setUpAll(() {
    print('\n📝 Setting up test environment...');
    dotenv.testLoad(fileInput: '''
ANTHROPIC_API_KEY=test_key
CLAUDE_API_URL=https://api.anthropic.com/v1/messages
''');
    print('✓ Environment variables loaded');
  });

  setUp(() {
    print('\n🔄 Setting up test case...');
    mockClient = MockClient();
    mockConfigLoader = MockConfigLoader();

    when(mockConfigLoader.loadSystemPrompt())
        .thenAnswer((_) async => 'Test system prompt');

    service = ClaudeService(
      client: mockClient,
      configLoader: mockConfigLoader,
    );
    print('✓ Mock client initialized');
    print('✓ Claude service created with mock dependencies');
  });

  group('Claude Service Error Handling', () {
    test('handles overloaded_error gracefully', () async {
      print('\n🧪 Testing overloaded_error handling...');
      const message = 'Hello';
      print('📤 Sending message: $message');

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
      )).thenAnswer((_) async {
        print('📡 Mock Claude API called');
        final response = http.Response(
          json.encode({
            'type': 'error',
            'error': {'type': 'overloaded_error', 'message': 'Overloaded'}
          }),
          429,
        );
        print('📥 Claude API error response: ${response.body}');
        return response;
      });
      print('✓ Mock Claude API error response configured');

      final response = await service.sendMessage(message);
      print('📥 Service response received: $response');

      // FT-153: Verify graceful fallback message instead of technical error
      expect(response,
          "I'm processing a lot of requests right now. Let me get back to you with a thoughtful response in just a moment.",
          reason:
              'Response should be a graceful fallback message, not a technical error');
      print('✓ Test completed successfully');
    });

    test('handles rate_limit_error gracefully', () async {
      print('\n🧪 Testing rate_limit_error handling...');
      const message = 'Hello';
      print('📤 Sending message: $message');

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
      )).thenAnswer((_) async {
        print('📡 Mock Claude API called');
        final response = http.Response(
          json.encode({
            'type': 'error',
            'error': {
              'type': 'rate_limit_error',
              'message': 'Rate limit exceeded'
            }
          }),
          429,
        );
        print('📥 Claude API error response: ${response.body}');
        return response;
      });
      print('✓ Mock Claude API error response configured');

      final response = await service.sendMessage(message);
      print('📥 Service response received: $response');

      // FT-153: Verify graceful fallback message instead of technical error
      expect(response,
          "I'm processing a lot of requests right now. Let me get back to you with a thoughtful response in just a moment.",
          reason:
              'Response should be a graceful fallback message, not a technical error');
      print('✓ Test completed successfully');
    });

    test('handles authentication_error gracefully', () async {
      print('\n🧪 Testing authentication_error handling...');
      const message = 'Hello';
      print('📤 Sending message: $message');

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
      )).thenAnswer((_) async {
        print('📡 Mock Claude API called');
        final response = http.Response(
          json.encode({
            'type': 'error',
            'error': {
              'type': 'authentication_error',
              'message': 'Invalid API key'
            }
          }),
          401,
        );
        print('📥 Claude API error response: ${response.body}');
        return response;
      });
      print('✓ Mock Claude API error response configured');

      final response = await service.sendMessage(message);
      print('📥 Service response received: $response');

      expect(response, 'Authentication failed. Please check your API key.',
          reason:
              'Response should be a user-friendly authentication error message');
      print('✓ Test completed successfully');
    });

    test('handles network errors gracefully', () async {
      print('\n🧪 Testing network error handling...');
      const message = 'Hello';
      print('📤 Sending message: $message');

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
      )).thenThrow(http.ClientException('Connection refused'));
      print('✓ Mock network error configured');

      final response = await service.sendMessage(message);
      print('📥 Service response received: $response');

      expect(response,
          'Unable to connect to Claude. Please check your internet connection.',
          reason: 'Response should be a user-friendly network error message');
      print('✓ Test completed successfully');
    });

    test('handles server errors gracefully', () async {
      print('\n🧪 Testing server error handling...');
      const message = 'Hello';
      print('📤 Sending message: $message');

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
      )).thenAnswer((_) async {
        print('📡 Mock Claude API called');
        final response = http.Response(
          'Internal Server Error',
          500,
        );
        print('📥 Claude API error response: ${response.body}');
        return response;
      });
      print('✓ Mock Claude API error response configured');

      final response = await service.sendMessage(message);
      print('📥 Service response received: $response');

      expect(response,
          'Claude service is temporarily unavailable. Please try again later.',
          reason: 'Response should be a user-friendly server error message');
      print('✓ Test completed successfully');
    });

    test('handles unknown errors gracefully', () async {
      print('\n🧪 Testing unknown error handling...');
      const message = 'Hello';
      print('📤 Sending message: $message');

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
      )).thenAnswer((_) async {
        print('📡 Mock Claude API called');
        final response = http.Response(
          json.encode({
            'type': 'error',
            'error': {
              'type': 'unknown_error',
              'message': 'Something went wrong'
            }
          }),
          400,
        );
        print('📥 Claude API error response: ${response.body}');
        return response;
      });
      print('✓ Mock Claude API error response configured');

      final response = await service.sendMessage(message);
      print('📥 Service response received: $response');

      expect(response, 'Claude error: Something went wrong',
          reason:
              'Response should include the original error message in a user-friendly format');
      print('✓ Test completed successfully');
    });
  });
}
