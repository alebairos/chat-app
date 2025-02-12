import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:character_ai_clone/services/claude_service.dart';
import 'package:character_ai_clone/services/life_plan_mcp_service.dart';
import 'package:character_ai_clone/config/config_loader.dart';
import 'claude_service_test.mocks.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

@GenerateMocks([http.Client, LifePlanMCPService])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  print('\n🚀 Starting Claude Service Tests');

  late MockClient mockClient;
  late MockLifePlanMCPService mockMCP;
  late ClaudeService service;

  Future<String> mockSystemPrompt() async => 'Test system prompt';

  ConfigLoader createMockConfigLoader() {
    final loader = ConfigLoader();
    loader.setLoadSystemPromptImpl(mockSystemPrompt);
    return loader;
  }

  setUpAll(() {
    print('\n📝 Setting up test environment...');
    dotenv.testLoad(fileInput: '''
      ANTHROPIC_API_KEY=test_key
    ''');
    print('✓ Environment variables loaded');
  });

  setUp(() {
    print('\n🔄 Setting up test case...');
    mockClient = MockClient();
    mockMCP = MockLifePlanMCPService();
    print('✓ Mock client and MCP initialized');

    final configLoader = ConfigLoader();
    configLoader.setLoadSystemPromptImpl(mockSystemPrompt);
    print('✓ ConfigLoader initialized with mock system prompt');

    service = ClaudeService(
      client: mockClient,
      lifePlanMCP: mockMCP,
      configLoader: configLoader,
    );
    print('✓ Claude Service initialized');
  });

  group('ClaudeService', () {
    test('maintains conversation history', () async {
      print('\n🧪 Testing conversation history maintenance...');

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
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

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
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

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
      )).thenThrow(Exception('Network error'));
      print('✓ Mock network error configured');

      final response = await service.sendMessage('Hello');
      print('📥 Error response received: $response');

      final decoded = json.decode(response);
      print('🔍 Decoded error response: $decoded');

      expect(decoded['status'], equals('error'));
      expect(decoded['message'], contains('Unable to connect to Claude'));
      expect(decoded['message'], contains('Network error'));

      print(
          '📊 Conversation history length: ${service.conversationHistory.length}');
      expect(service.conversationHistory.length, equals(1));
      print('✓ Test completed successfully');
    });

    test('handles API errors gracefully', () async {
      print('\n🧪 Testing API error handling...');

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
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

      final decoded = json.decode(response);
      print('🔍 Decoded error response: $decoded');

      expect(decoded['status'], equals('error'));
      expect(
          decoded['message'], contains('Failed to get response from Claude'));
      expect(decoded['message'], contains('Rate limit exceeded'));

      print(
          '📊 Conversation history length: ${service.conversationHistory.length}');
      expect(service.conversationHistory.length, equals(1));
      print('✓ Test completed successfully');
    });

    test('handles malformed JSON response gracefully', () async {
      print('\n🧪 Testing malformed JSON handling...');

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
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

      final decoded = json.decode(response);
      print('🔍 Decoded error response: $decoded');

      expect(decoded['status'], equals('error'));
      expect(decoded['message'], contains('Unable to connect to Claude'));
      expect(decoded['message'], contains('FormatException'));

      print('✓ Test completed successfully');
    });

    test('handles empty response gracefully', () async {
      print('\n🧪 Testing empty response handling...');

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
      )).thenAnswer((_) async {
        print('📡 Mock empty response');
        return http.Response('', 200);
      });
      print('✓ Mock empty response configured');

      final response = await service.sendMessage('Hello');
      print('📥 Error response received: $response');

      final decoded = json.decode(response);
      print('🔍 Decoded error response: $decoded');

      expect(decoded['status'], equals('error'));
      expect(decoded['message'], contains('Unable to connect to Claude'));
      expect(decoded['message'], contains('FormatException'));

      print('✓ Test completed successfully');
    });
  });

  group('Life Plan MCP Integration', () {
    test('processes life plan commands through MCP', () async {
      print('\n🧪 Testing life plan command processing...');
      final command =
          json.encode({'action': 'get_goals_by_dimension', 'dimension': 'SF'});
      print('📤 Sending command: $command');

      when(mockMCP.processCommand(command)).thenReturn(json.encode({
        'status': 'success',
        'data': [
          {
            'dimension': 'SF',
            'id': 'G1',
            'description': 'Test Goal',
            'trackId': 'T1'
          }
        ]
      }));
      print('✓ Mock MCP response configured');

      final response = await service.sendMessage(command);
      print('📥 Received response: $response');

      final decoded = json.decode(response);
      print('🔍 Decoded response: $decoded');

      expect(decoded['status'], equals('success'));
      verify(mockMCP.processCommand(command)).called(1);
      print('✓ Test completed successfully');
    });

    test('falls back to normal message processing if MCP fails', () async {
      print('\n🧪 Testing MCP failure fallback...');
      final command = json.encode({'action': 'invalid_command'});
      print('📤 Sending invalid command: $command');

      when(mockMCP.processCommand(command)).thenThrow(Exception('MCP Error'));
      print('✓ Mock MCP error configured');

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
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

      final decoded = json.decode(response);
      print('🔍 Decoded error response: $decoded');

      expect(decoded['status'], equals('error'));
      expect(decoded['message'], contains('MCP Error'));
      print('✓ Test completed successfully');
    });

    test('processes normal messages without MCP', () async {
      print('\n🧪 Testing normal message processing...');
      final message = 'Hello';
      print('📤 Sending message: $message');

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
      )).thenAnswer((_) async {
        print('📡 Mock Claude API called');
        return http.Response(
          json.encode({
            'content': [
              {'text': 'Normal response'}
            ]
          }),
          200,
        );
      });
      print('✓ Mock Claude API response configured');

      final response = await service.sendMessage(message);
      print('📥 Received response: $response');

      expect(response, equals('Normal response'));
      verifyNever(mockMCP.processCommand(any));
      print('✓ Test completed successfully');
    });
  });
}
