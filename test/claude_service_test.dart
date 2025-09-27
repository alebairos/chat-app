import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:ai_personas_app/services/claude_service.dart';
import 'package:ai_personas_app/services/system_mcp_service.dart';
import 'package:ai_personas_app/config/config_loader.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Replace Mockito mocks with Mocktail mocks
class MockHttpClient extends Mock implements http.Client {}

class MockSystemMCPService extends Mock implements SystemMCPService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  print('\n🚀 Starting Claude Service Tests');

  late MockHttpClient mockClient;
  late MockSystemMCPService mockMCP;
  late ClaudeService service;

  Future<String> mockSystemPrompt() async => 'Test system prompt';

  // Mock helper function removed - ConfigLoader is created inline in setUp

  setUpAll(() {
    print('\n📝 Setting up test environment...');
    dotenv.testLoad(fileInput: '''
      ANTHROPIC_API_KEY=test_key
    ''');
    print('✓ Environment variables loaded');

    // Register fallback values for Mocktail
    registerFallbackValue(Uri.parse('https://example.com'));
    registerFallbackValue(<String, String>{});
    registerFallbackValue('');
    registerFallbackValue(utf8);
  });

  setUp(() {
    print('\n🔄 Setting up test case...');
    mockClient = MockHttpClient();
    mockMCP = MockSystemMCPService();
    print('✓ Mock client and MCP initialized');

    final configLoader = ConfigLoader();
    configLoader.setLoadSystemPromptImpl(mockSystemPrompt);
    print('✓ ConfigLoader initialized with mock system prompt');

    service = ClaudeService(
      client: mockClient,
      systemMCP: mockMCP,
      configLoader: configLoader,
    );
    print('✓ Claude Service initialized');
  });

  group('ClaudeService', () {
    test('maintains conversation history', () async {
      print('\n🧪 Testing conversation history maintenance...');

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
            encoding: any(named: 'encoding'),
          )).thenAnswer((_) async {
        print('📡 Mock Claude API called');
        return http.Response(
          jsonEncode({
            'content': [
              {'text': 'First response'}
            ]
          }),
          200,
        );
      });
      print('✓ Mock API response configured');

      final firstResponse = await service.sendMessage('Hello');
      print('📥 First response received: $firstResponse');
      expect(firstResponse, equals('First response'));

      print(
          '📊 Conversation history length: ${service.conversationHistory.length}');
      expect(service.conversationHistory.length, equals(2));
      print('✓ Test completed successfully');
    });

    test('clears conversation history', () async {
      print('\n🧪 Testing conversation history clearing...');

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
            encoding: any(named: 'encoding'),
          )).thenAnswer((_) async {
        print('📡 Mock Claude API called');
        return http.Response(
          jsonEncode({
            'content': [
              {'text': 'Response'}
            ]
          }),
          200,
        );
      });
      print('✓ Mock API response configured');

      await service.sendMessage('Hello');
      print('📊 Initial history length: ${service.conversationHistory.length}');
      expect(service.conversationHistory.length, equals(2));

      service.clearConversation();
      print('🧹 History cleared');
      print('📊 Final history length: ${service.conversationHistory.length}');
      expect(service.conversationHistory.length, equals(0));
      print('✓ Test completed successfully');
    });

    test('handles network errors gracefully', () async {
      print('\n🧪 Testing network error handling...');

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
            encoding: any(named: 'encoding'),
          )).thenThrow(Exception('Network error'));
      print('✓ Mock network error configured');

      final response = await service.sendMessage('Hello');
      print('📥 Error response received: $response');

      expect(response, contains('Unable to get a response from Claude'));

      print(
          '📊 Conversation history length: ${service.conversationHistory.length}');
      expect(service.conversationHistory.length, equals(1));
      print('✓ Test completed successfully');
    });

    test('handles API errors gracefully', () async {
      print('\n🧪 Testing API error handling...');

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
            encoding: any(named: 'encoding'),
          )).thenAnswer((_) async {
        print('📡 Mock API error response');
        return http.Response(
          'Rate limit exceeded',
          429,
        );
      });
      print('✓ Mock API error configured');

      final response = await service.sendMessage('Hello');
      print('📥 Error response received: $response');

      expect(
          response,
          equals(
              "I'm processing a lot of requests right now. Let me get back to you with a thoughtful response in just a moment."));

      print(
          '📊 Conversation history length: ${service.conversationHistory.length}');
      expect(service.conversationHistory.length, equals(1));
      print('✓ Test completed successfully');
    });

    test('handles malformed JSON response gracefully', () async {
      print('\n🧪 Testing malformed JSON handling...');

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
            encoding: any(named: 'encoding'),
          )).thenAnswer((_) async {
        print('📡 Mock malformed JSON response');
        return http.Response(
          '{malformed json',
          200,
        );
      });
      print('✓ Mock malformed JSON configured');

      final response = await service.sendMessage('Hello');
      print('📥 Error response received: $response');

      expect(response, contains('Unable to get a response from Claude'));

      print('✓ Test completed successfully');
    });

    test('handles empty response gracefully', () async {
      print('\n🧪 Testing empty response handling...');

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
            encoding: any(named: 'encoding'),
          )).thenAnswer((_) async {
        print('📡 Mock empty response');
        return http.Response('', 200);
      });
      print('✓ Mock empty response configured');

      final response = await service.sendMessage('Hello');
      print('📥 Error response received: $response');

      expect(response, contains('Unable to get a response from Claude'));

      print('✓ Test completed successfully');
    });
  });

  group('System MCP Integration', () {
    test('processes system commands through MCP', () async {
      print('\n🧪 Testing system command processing...');
      final command = json.encode({'action': 'get_current_time'});
      print('📤 Sending command: $command');

      when(() => mockMCP.processCommand(command))
          .thenAnswer((_) async => json.encode({
                'status': 'success',
                'data': {
                  'current_time': '2025-01-02T15:30:00Z',
                  'formatted_time': 'Thursday, January 2, 2025 at 3:30 PM',
                  'timezone': 'UTC'
                }
              }));
      print('✓ Mock MCP response configured');

      final response = await service.sendMessage(command);
      print('📥 Received response: $response');

      final decoded = json.decode(response);
      print('🔍 Decoded response: $decoded');

      expect(decoded['status'], equals('success'));
      verify(() => mockMCP.processCommand(command)).called(1);
      print('✓ Test completed successfully');
    });

    test('falls back to normal message processing if MCP fails', () async {
      print('\n🧪 Testing MCP failure fallback...');
      final command = json.encode({'action': 'invalid_command'});
      print('📤 Sending invalid command: $command');

      when(() => mockMCP.processCommand(command))
          .thenAnswer((_) async => throw Exception('MCP Error'));
      print('✓ Mock MCP error configured');

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
            encoding: any(named: 'encoding'),
          )).thenAnswer((_) async {
        print('📡 Mock Claude API called');
        return http.Response(
          json.encode({
            'content': [
              {'text': 'Fallback response'}
            ]
          }),
          200,
        );
      });
      print('✓ Mock Claude API response configured');

      final response = await service.sendMessage(command);
      print('📥 Received response: $response');

      expect(response, contains('Error processing system command'));
      expect(response, contains('MCP Error'));

      print('✓ Test completed successfully');
    });

    test('processes normal messages without MCP', () async {
      print('\n🧪 Testing normal message processing...');
      const message = 'Hello';
      print('📤 Sending message: $message');

      // SystemMCP should not be called for normal messages
      // No stubbing needed since regular messages don't trigger MCP commands

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
            encoding: any(named: 'encoding'),
          )).thenAnswer((_) async {
        print('📡 Mock Claude API called');
        final response = http.Response(
          json.encode({
            'content': [
              {'text': 'Normal response'}
            ]
          }),
          200,
        );
        print('📥 Claude API response: ${response.body}');
        return response;
      });
      print('✓ Mock Claude API response configured');

      final response = await service.sendMessage(message);
      print('📥 Received response: $response');

      expect(response, equals('Normal response'),
          reason: 'Response should match expected normal response');

      // Verify that SystemMCP was not called for regular messages
      verifyNever(() => mockMCP.processCommand(any()));
      print('✓ Test completed successfully');
    });
  });
}
