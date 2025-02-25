import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai_clone/services/claude_service.dart';
import 'package:character_ai_clone/services/life_plan_mcp_service.dart';
import 'package:character_ai_clone/config/config_loader.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'claude_service_test.mocks.dart';

@GenerateMocks([http.Client, LifePlanMCPService])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  print('\n🚀 Starting Life Plan MCP Integration Tests');

  late MockClient mockClient;
  late MockLifePlanMCPService mockMCP;
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
    mockMCP = MockLifePlanMCPService();
    service = ClaudeService(
      client: mockClient,
      lifePlanMCP: mockMCP,
    );
    print('✓ Mock client and MCP service initialized');
    print('✓ Claude service created with mock dependencies');
  });

  group('Life Plan MCP Integration', () {
    test('processes life plan commands through MCP', () async {
      print('\n🧪 Testing life plan command processing...');
      final command =
          json.encode({'action': 'get_goals_by_dimension', 'dimension': 'SF'});
      print('📤 Sending command: $command');

      when(mockMCP.processCommand(command)).thenAnswer((_) {
        print('📡 Mock MCP processing command');
        final response = json.encode({
          'status': 'success',
          'data': [
            {
              'dimension': 'SF',
              'id': 'G1',
              'description': 'Test Goal',
              'trackId': 'T1'
            }
          ]
        });
        print('📥 MCP response: $response');
        return response;
      });
      print('✓ Mock MCP response configured');

      final response = await service.sendMessage(command);
      print('📥 Service response received: $response');

      final decoded = json.decode(response);
      print('🔍 Decoded response: $decoded');

      expect(decoded['status'], equals('success'),
          reason: 'Response status should be success');
      verify(mockMCP.processCommand(command)).called(1);
      print('✓ Test completed successfully');
    });

    test('falls back to normal message processing if MCP fails', () async {
      print('\n🧪 Testing MCP failure fallback...');
      final command = json.encode({'action': 'invalid_command'});
      print('📤 Sending invalid command: $command');

      when(mockMCP.processCommand(command)).thenAnswer((_) {
        print('📡 Mock MCP throwing error');
        throw Exception('MCP Error');
      });
      print('✓ Mock MCP error configured');

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
      )).thenAnswer((_) async {
        print('📡 Mock Claude API called');
        final response = http.Response(
          json.encode({
            'content': [
              {'text': 'Fallback response'}
            ]
          }),
          200,
        );
        print('📥 Claude API response: ${response.body}');
        return response;
      });
      print('✓ Mock Claude API response configured');

      final response = await service.sendMessage(command);
      print('📥 Service response received: $response');

      expect(response, contains('Missing required parameter'),
          reason:
              'Response should contain error message about missing parameter');
      expect(response, contains('MCP Error'),
          reason: 'Response should contain MCP error message');
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
      print('📥 Service response received: $response');

      expect(response, equals('Normal response'),
          reason: 'Response should match expected normal response');
      verifyNever(mockMCP.processCommand(any));
      print('✓ Test completed successfully');
    });
  });
}
