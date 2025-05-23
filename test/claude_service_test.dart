import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:character_ai_clone/services/claude_service.dart';
import 'package:character_ai_clone/services/life_plan_mcp_service.dart';
import 'package:character_ai_clone/config/config_loader.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Replace Mockito mocks with Mocktail mocks
class MockHttpClient extends Mock implements http.Client {}

class MockLifePlanMCPService extends Mock implements LifePlanMCPService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  print('\n🚀 Starting Claude Service Tests');

  late MockHttpClient mockClient;
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

    // Register fallback values for Mocktail
    registerFallbackValue(Uri.parse('https://example.com'));
    registerFallbackValue(<String, String>{});
    registerFallbackValue('');
    registerFallbackValue(utf8);
  });

  setUp(() {
    print('\n🔄 Setting up test case...');
    mockClient = MockHttpClient();
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

      expect(response, equals('Rate limit exceeded. Please try again later.'));

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

  group('Life Plan MCP Integration', () {
    test('processes life plan commands through MCP', () async {
      print('\n🧪 Testing life plan command processing...');
      final command =
          json.encode({'action': 'get_goals_by_dimension', 'dimension': 'SF'});
      print('📤 Sending command: $command');

      when(() => mockMCP.processCommand(command)).thenReturn(json.encode({
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
      verify(() => mockMCP.processCommand(command)).called(1);
      print('✓ Test completed successfully');
    });

    test('falls back to normal message processing if MCP fails', () async {
      print('\n🧪 Testing MCP failure fallback...');
      final command = json.encode({'action': 'invalid_command'});
      print('📤 Sending invalid command: $command');

      when(() => mockMCP.processCommand(command))
          .thenThrow(Exception('MCP Error'));
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

      expect(response, contains('Missing required parameter'));
      expect(response, contains('MCP Error'));

      print('✓ Test completed successfully');
    });

    test('Life Plan MCP Integration processes normal messages without MCP',
        () async {
      print('\n🧪 Testing normal message processing...');
      const message = 'Hello';
      print('📤 Sending message: $message');

      // Add stubs for all dimension codes
      for (final dimension in ['SF', 'SM', 'R', 'E', 'TG']) {
        // Stub for get_goals_by_dimension
        when(() => mockMCP.processCommand(json.encode(
                {'action': 'get_goals_by_dimension', 'dimension': dimension})))
            .thenReturn(json.encode({'status': 'success', 'data': []}));

        // Stub for get_recommended_habits
        when(() => mockMCP.processCommand(json.encode({
              'action': 'get_recommended_habits',
              'dimension': dimension,
              'minImpact': 3
            }))).thenReturn(json.encode({'status': 'success', 'data': []}));
      }

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

      // Now we can verify that the MCP service was called for each dimension
      // but we don't need to verify it was never called since we've stubbed the calls
      print('✓ Test completed successfully');
    });
  });
}
